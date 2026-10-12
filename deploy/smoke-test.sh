#!/bin/bash
# Smoke test of a built clawbook-lehre image ("start the thing").
#
#   deploy/smoke-test.sh <image> [expected-commit]
#
# Starts the image with a fresh home volume and checks: healthcheck, all
# tools (clawbook-check), build stamp, SSH login as "student" with the key
# from the home volume, the CLI clawbook (JSON interface), the menu on SSH
# login and the GitHub question (also in front of wsm), the agent equipment
# (MCP servers, skills and instructions in all five agents, keys via
# "clawbook agenten schluessel", own entries kept, second sync idle), RDP
# port and
# XWayland display, browsers for playwright-cli, Playwright-MCP and
# notebooklm as "student", Samba share
# (read/write with the shown password), and that keys survive recreating
# the container with the same home volume. Then the packages: source and
# key in the image, catalog of the real source clawbook-apt (needs the
# internet), kurs-inf installed and in the VS Code description, and the
# restore after recreating the container - online from the apt cache in the
# home volume, then without any network.
#
# Needs: docker, ssh, ssh-keygen. smbclient is used when installed,
# otherwise a throwaway Debian container provides it.
# Uses host ports 127.0.0.1:2222, :3390 and :4445; other ports via
# SMOKE_SSH_PORT, SMOKE_RDP_PORT, SMOKE_SMB_PORT.

set -euo pipefail

IMAGE=${1:?usage: smoke-test.sh <image> [expected-commit]}
EXPECTED_COMMIT=${2:-}
NAME=clawbook-smoke-$$
VOLUME=${NAME}-home
WORK=$(mktemp -d)
SSH_PORT=${SMOKE_SSH_PORT:-2222}
RDP_PORT=${SMOKE_RDP_PORT:-3390}
SMB_PORT=${SMOKE_SMB_PORT:-4445}

cleanup() {
  docker rm -f "${NAME}" >/dev/null 2>&1 || true
  docker volume rm "${VOLUME}" >/dev/null 2>&1 || true
  rm -rf "${WORK}"
}
trap cleanup EXIT

fail() {
  echo "::error::$1"
  docker logs "${NAME}" 2>&1 | tail -n 80 || true
  exit 1
}

run_container() {
  docker run -d --name "${NAME}" \
    -p "127.0.0.1:${SSH_PORT}:22" -p "127.0.0.1:${RDP_PORT}:3389" \
    -p "127.0.0.1:${SMB_PORT}:445" \
    -v "${VOLUME}:/home/student" "${IMAGE}" >/dev/null
}

wait_healthy() {
  local status=unknown
  for _ in $(seq 1 60); do
    status=$(docker inspect -f '{{.State.Health.Status}}' "${NAME}")
    [ "${status}" = healthy ] && return 0
    sleep 2
  done
  fail "container did not become healthy (status: ${status})"
}

ssh_run() {
  ssh -i "${WORK}/key" -p "${SSH_PORT}" -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o LogLevel=ERROR \
      student@127.0.0.1 "$@"
}

smb() {
  if command -v smbclient >/dev/null; then
    (cd "${WORK}" && smbclient "$@")
  else
    docker run --rm --network host -v "${WORK}:/work" -w /work debian:trixie-slim \
      bash -c 'apt-get update -qq >/dev/null && apt-get install -y -qq smbclient >/dev/null && smbclient "$@"' \
      smbclient "$@"
  fi
}

docker volume create "${VOLUME}" >/dev/null
run_container
wait_healthy
echo "healthy"

docker exec "${NAME}" clawbook-check || fail "clawbook-check reported missing tools"
if [ -n "${EXPECTED_COMMIT}" ]; then
  docker exec "${NAME}" grep -q "commit=${EXPECTED_COMMIT}" /etc/clawbook-build \
    || fail "build stamp does not match ${EXPECTED_COMMIT}"
fi

# SSH with the key the init step created.
docker cp "${NAME}:/home/student/.ssh/id_ed25519" "${WORK}/key" >/dev/null
chmod 600 "${WORK}/key"
first=$(ssh-keygen -lf "${WORK}/key")
# (capture first: "docker logs | grep -q" fails under pipefail when grep
# stops reading early)
logs=$(docker logs "${NAME}" 2>&1)
grep -q "BEGIN OPENSSH PRIVATE KEY" <<<"${logs}" \
  || fail "start script did not show the private key"
ssh_run 'whoami && clawbook-check --quiet && tmux -V' || fail "SSH login as student failed"
echo "ssh ok"

# CLI clawbook: JSON interface (as student via SSH and as root via exec).
json_ok() {
  # $1 = JSON text, $2 = Python expression over d that must be true
  docker exec -i "${NAME}" python3 -c \
    "import json,sys; d=json.load(sys.stdin); sys.exit(0 if ($2) else 1)" <<<"$1"
}
out=$(ssh_run 'clawbook status --json') || fail "clawbook status --json failed"
json_ok "${out}" 'int(d["schnittstelle"]) >= 1 and all(d["dienste"].values())' \
  || fail "clawbook status --json: invalid JSON, interface < 1 or a service down"
out=$(docker exec "${NAME}" clawbook status --json) || fail "clawbook status --json as root failed"
json_ok "${out}" 'd["benutzer"] == "student"' || fail "clawbook status --json as root: bad JSON"
out=$(ssh_run 'clawbook check --json') || fail "clawbook check --json reported missing tools"
json_ok "${out}" 'isinstance(d, list) and len(d) > 0 and all(t["ok"] for t in d)' \
  || fail "clawbook check --json: invalid JSON"
ssh_run 'rm -f ~/.clawbook/stand.json && clawbook stand --write >/dev/null' \
  || fail "clawbook stand --write failed"
out=$(ssh_run 'cat ~/.clawbook/stand.json') || fail "clawbook stand --write wrote no stand.json"
json_ok "${out}" 'd["format"] == 2 and d["kurse"] == [] and d["pakete"] == [] and d["ausstehend"] == [] and "kennung" not in d' \
  || fail "stand.json: unexpected content"
ssh_run "test \"\$(stat -c %U ~/.clawbook/stand.json)\" = student" \
  || fail "stand.json does not belong to student"
out=$(ssh_run 'clawbook kurs vscode clawbook --json') || fail "clawbook kurs vscode clawbook failed"
json_ok "${out}" 'd["format"] == 1 and d["kennung"] == "clawbook"' \
  || fail "clawbook kurs vscode clawbook: unexpected content"
# The built-in course description must match windows/vscodepack/clawbook.json.
pack_json=$(dirname "$0")/../windows/vscodepack/clawbook.json
if [ -f "${pack_json}" ]; then
  docker exec -i "${NAME}" python3 -c \
    'import json,sys; a=json.load(open("/usr/share/clawbook/kurse/clawbook/vscode.json")); sys.exit(0 if a == json.load(sys.stdin) else 1)' \
    <"${pack_json}" || fail "built-in course description differs from windows/vscodepack/clawbook.json"
fi
rc=0; out=$(ssh_run 'clawbook pakete --json') || rc=$?
if [ "${rc}" != 2 ] || ! json_ok "${out}" '"fehler" in d'; then
  fail "clawbook pakete --json without subcommand: expected exit 2 and a usage error"
fi
rc=0; out=$(ssh_run 'clawbook pakete add kurs-inf --json') || rc=$?
if [ "${rc}" != 2 ] || ! json_ok "${out}" '"--yes" in d["fehler"]'; then
  fail "clawbook pakete add without terminal and --yes did not refuse"
fi
out=$(ssh_run 'clawbook kurse --json') || fail "clawbook kurse --json failed"
json_ok "${out}" 'd == {"kurse": []}' || fail "clawbook kurse --json: expected no courses"
ssh_run 'clawbook key show --json' >/dev/null || fail "clawbook key show --json failed"
# The status interface stays as the Windows script knows it.
out=$(ssh_run 'clawbook status --json')
json_ok "${out}" 'sorted(d) == ["aufgerufen_als", "benutzer", "build", "dienste", "home", "image", "paket_cache", "schnittstelle", "wiederherstellung_details"] and d["schnittstelle"] == 2 and d["wiederherstellung_details"]["zustand"] == "keine"' \
  || fail "clawbook status --json: fields changed"
echo "cli ok"

# GitHub, menu on login, wsm wrapper. No gh login exists in the test, so
# every interactive path starts with the GitHub question.
ssh_tty() {
  # $1 = input typed into the terminal, rest = remote command (none: login)
  local input=$1; shift
  printf '%b' "${input}" | timeout 90 ssh -tt -i "${WORK}/key" -p "${SSH_PORT}" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
    student@127.0.0.1 "$@" 2>&1
}
# --json and missing terminals never ask.
# has PATTERN: the last output contains PATTERN (extended regex).
has() { grep -qE -- "$1" <<<"${out}"; }
out=$(ssh_tty '' 'clawbook github login --json; echo "rc=$?"')
if ! has 'rc=2' || ! has '"fehler"'; then
  fail "clawbook github login --json did not refuse at once: ${out}"
fi
out=$(ssh_tty '' 'clawbook github status --json; echo "rc=$?"')
if ! has '"angemeldet": false' || ! has 'rc=1'; then
  fail "clawbook github status --json: unexpected: ${out}"
fi
out=$(ssh_run 'clawbook </dev/null; echo "rc=$?"') || fail "clawbook without terminal failed"
if ! has 'rc=0' || has 'GitHub-Anmeldung'; then
  fail "clawbook without terminal asked for GitHub: ${out}"
fi
# "ssh clawbook <command>" (also with a terminal) gets no menu.
out=$(ssh_tty '' 'echo marker-ok')
if ! has 'marker-ok' || has 'clawbook - Menü|GitHub-Anmeldung'; then
  fail "menu shown for ssh with a command: ${out}"
fi
out=$(ssh_run 'echo marker-ok')
[ "${out}" = marker-ok ] || fail "ssh with a command printed more than its output: ${out}"
# Interactive login: GitHub question first (cancel), then the menu (end).
out=$(ssh_tty '2\n0\nexit\n')
if ! has 'GitHub-Anmeldung' || ! has 'clawbook - Menü' || ! has 'jederzeit wieder mit: clawbook'; then
  fail "SSH login did not open GitHub question and menu: ${out}"
fi
# Menu item 8 switches the menu on login off; the next login stays quiet.
ssh_tty '2\n8\n0\nexit\n' >/dev/null
ssh_run 'test -e ~/.clawbook/menue-beim-login-aus' || fail "menu item 8 did not switch the login menu off"
out=$(ssh_tty 'exit\n')
if has 'clawbook - Menü|GitHub-Anmeldung' || ! has 'öffnest du mit: clawbook'; then
  fail "menu shown although switched off: ${out}"
fi
ssh_tty '2\n8\n0\n' 'clawbook' >/dev/null
ssh_run 'test ! -e ~/.clawbook/menue-beim-login-aus' || fail "menu item 8 did not switch the login menu on again"
# wsm: wrapper in /usr/local/bin, real entry point elsewhere.
ssh_run 'test -x /opt/clawbook/tool-bin/wsm && head -c 2 /usr/local/bin/wsm | grep -q "#!"' \
  || fail "wsm wrapper or real wsm missing"
ssh_run 'wsm --help' >/dev/null || fail "wsm --help without terminal failed"
out=$(ssh_tty '2\nn\n' 'wsm; echo "rc=$?"')
if ! has 'richtet sich jetzt zum ersten Mal ein' || ! has 'rc=1'; then
  fail "wsm wrapper did not ask for GitHub first: ${out}"
fi
ssh_run 'test ! -e ~/.workspacemanager.yml' || fail "a wsm configuration was created"
echo "login ok"

# After the GitHub login, with a stand-in for gh (logged in as octo-student,
# id 4242, no name) and a separate global git config: git identity and the
# renewal of an old wsm configuration (single location ~/source).
# shellcheck disable=SC2016 # expands on the container side
FAKE='PATH=/tmp/fake-gh:$PATH GIT_CONFIG_GLOBAL=/tmp/fake-gitconfig'
ssh_run 'mkdir -p /tmp/fake-gh && cat > /tmp/fake-gh/gh && chmod +x /tmp/fake-gh/gh' <<'SH'
#!/bin/sh
case "$*" in
  "auth status"*) echo "github.com"; echo "  Logged in to github.com account octo-student"; exit 0 ;;
  "auth token"*) echo "gho_stand-in" ;;
  "api user --jq .login") echo "octo-student" ;;
  "api user") echo '{"login": "octo-student", "id": 4242, "name": ""}' ;;
  *) exit 1 ;;
esac
SH
out=$(ssh_run "${FAKE} clawbook github identitaet --json") || fail "clawbook github identitaet --json failed: ${out}"
json_ok "${out}" 'd["name"] == "octo-student" and d["email"] == "4242+octo-student@users.noreply.github.com" and d["aktion"] == "setzen" and not d["gesetzt"]' \
  || fail "git identity: unexpected proposal: ${out}"
out=$(ssh_tty '\n' "${FAKE} clawbook github identitaet; git config --file /tmp/fake-gitconfig user.email")
if ! has 'Diese Angaben für Git übernehmen\? \[J/n\]' || ! has '^4242\+octo-student@users\.noreply\.github\.com'; then
  fail "git identity was not set after Enter: ${out}"
fi
ssh_run 'git config --file /tmp/fake-gitconfig user.name "Someone Else"'
out=$(ssh_tty '\n' "${FAKE} clawbook github identitaet; git config --file /tmp/fake-gitconfig user.name")
if ! has 'Die Angaben aus GitHub übernehmen\? \[j/N\]' || ! has '^Someone Else'; then
  fail "git identity overwrote a different name without consent: ${out}"
fi
out=$(ssh_run "${FAKE} clawbook github identitaet --yes --json 2>/dev/null; git config --file /tmp/fake-gitconfig user.name")
if ! has '"gesetzt": false' || ! has '^Someone Else'; then
  fail "clawbook github identitaet --yes overwrote a different name: ${out}"
fi
ssh_run '! git config --global user.name' >/dev/null || fail "git identity test touched ~/.gitconfig"
ssh_run 'cat > ~/.workspacemanager.yml' <<'YML'
locations:
- path: ~/source
  git:
    url: ssh://git@github.com
    user: student
wsl:
  distro: Ubuntu
YML
out=$(ssh_run 'clawbook wsm status --json') || fail "clawbook wsm status --json failed"
json_ok "${out}" 'd["vorhanden"] and d["veraltet"] and not d["nicht_mehr_fragen"]' \
  || fail "old wsm configuration not detected: ${out}"
out=$(ssh_tty 'n\n' "${FAKE} clawbook wsm erneuern --vor-wsm; echo \"rc=\$?\"")
if ! has 'WorkspaceManager-Konfiguration .* ist veraltet' || ! has 'fragt nicht wieder' || ! has 'rc=0'; then
  fail "wsm renewal was not offered: ${out}"
fi
ssh_run 'test -e ~/.clawbook/wsm-konfiguration-behalten && grep -q "path: ~/source$" ~/.workspacemanager.yml' \
  || fail "declining the wsm renewal left no marker or changed the configuration"
out=$(ssh_tty '' "${FAKE} clawbook wsm erneuern --vor-wsm; echo \"rc=\$?\"")
if has 'veraltet' || ! has 'rc=0'; then
  fail "wsm renewal asked again after no: ${out}"
fi
out=$(ssh_run "${FAKE} clawbook wsm erneuern --yes --json") || fail "clawbook wsm erneuern --yes failed: ${out}"
json_ok "${out}" 'd["erneuert"] and not d["veraltet"] and ".workspacemanager.yml.alt-" in d["sicherung"]' \
  || fail "wsm renewal: unexpected result: ${out}"
# shellcheck disable=SC2016 # expands on the container side
ssh_run 'set -e; f=~/.workspacemanager.yml
  grep -q "path: ~/source/github" "$f"; grep -q "path: ~/source/sandbox" "$f"
  grep -q "user: octo-student" "$f"; grep -q "email: 4242+octo-student@users.noreply.github.com" "$f"
  grep -q "path: ~/source$" "$f".alt-*
  test -f ~/source/samples/primer/README.md' \
  || fail "new wsm configuration, backup or projects not as expected"
ssh_run "${FAKE} /opt/clawbook/tool-bin/wsm config --validate" >/dev/null \
  || fail "wsm does not accept the renewed configuration"
ssh_run 'rm -rf /tmp/fake-gh /tmp/fake-gitconfig ~/.workspacemanager.yml ~/.workspacemanager.yml.alt-*'
# (~/.clawbook belongs to root; clawbook writes its markers there via sudo)
docker exec "${NAME}" rm -f /home/student/.clawbook/wsm-konfiguration-behalten
echo "git identity and wsm renewal ok"

# NotebookLM: without a login "nicht_angemeldet" (in check and as command,
# also as root); stored cookies only for notebook.google.com count as
# incomplete, and the repair copies them.
out=$(ssh_run 'clawbook check --json') || fail "clawbook check --json failed"
json_ok "${out}" '[t.get("zustand") for t in d if t["name"] == "notebooklm-anmeldung"] == ["nicht_angemeldet"]' \
  || fail "clawbook check --json: NotebookLM entry missing: ${out}"
rc=0; out=$(ssh_run 'clawbook notebooklm --json') || rc=$?
if [ "${rc}" != 1 ] || ! json_ok "${out}" 'd["zustand"] == "nicht_angemeldet"'; then
  fail "clawbook notebooklm --json: expected nicht_angemeldet: ${out}"
fi
rc=0; out=$(docker exec "${NAME}" clawbook notebooklm --json) || rc=$?
if [ "${rc}" != 1 ] || ! json_ok "${out}" 'd["zustand"] == "nicht_angemeldet"'; then
  fail "clawbook notebooklm --json as root: ${out}"
fi
out=$(ssh_tty '' 'clawbook notebooklm; echo "rc=$?"')
if ! has 'notebooklm login' || ! has 'rc=1'; then
  fail "clawbook notebooklm does not explain the login: ${out}"
fi
ssh_run 'mkdir -p ~/.notebooklm/profiles/default && cat > ~/.notebooklm/profiles/default/storage_state.json' <<'JSON'
{"cookies": [
 {"name": "SID", "value": "stand-in", "domain": ".google.com", "path": "/", "expires": -1, "httpOnly": false, "secure": true, "sameSite": "Lax"},
 {"name": "__Secure-1PSIDTS", "value": "stand-in", "domain": ".google.com", "path": "/", "expires": -1, "httpOnly": true, "secure": true, "sameSite": "Lax"},
 {"name": "OSID", "value": "new", "domain": "notebook.google.com", "path": "/", "expires": -1, "httpOnly": true, "secure": true, "sameSite": "Lax"}],
 "origins": []}
JSON
out=$(ssh_run 'clawbook check --json') || fail "clawbook check --json failed"
json_ok "${out}" '[t.get("zustand") for t in d if t["name"] == "notebooklm-anmeldung"] == ["unvollstaendig"]' \
  || fail "clawbook check --json: incomplete NotebookLM login not detected: ${out}"
rc=0; out=$(ssh_run 'clawbook notebooklm --json') || rc=$?
json_ok "${out}" 'd["zustand"] == "unvollstaendig" and d["reparierbar"] and "repariert" not in d' \
  || fail "clawbook notebooklm --json: expected unvollstaendig, repairable: ${out}"
rc=0; out=$(ssh_run 'clawbook notebooklm --yes --json') || rc=$?
json_ok "${out}" 'd["repariert"] and not d["reparierbar"]' \
  || fail "clawbook notebooklm --yes did not repair the cookies: ${out}"
ssh_run 'grep -q "notebooklm.google.com" ~/.notebooklm/profiles/default/storage_state.json && rm -rf ~/.notebooklm' \
  || fail "notebooklm-fix-cookies did not copy the cookies"
echo "notebooklm ok"

# Sample project in the WorkspaceManager layout, a git repo owned by student.
ssh_run 'git -C ~/source/samples/primer log --oneline -1 && test -f ~/source/samples/primer/README.md' \
  || fail "sample project ~/source/samples/primer missing"
echo "sample ok"

# Agent equipment: after the start the service has carried MCP servers,
# skills and instructions into all five agents; Stitch and Wiki.js wait
# for their keys.
agenten_done() {
  for _ in $(seq 1 90); do
    out=$(ssh_run 'clawbook agenten status --json' 2>/dev/null) || true
    json_ok "${out}" 'd["letzter_sync"] is not None' 2>/dev/null && return 0
    sleep 2
  done
  return 1
}
agenten_done || fail "agent sync did not run after the start: ${out}"
json_ok "${out}" 'all(r["agenten"][a] == "eingetragen" for r in d["eintraege"] if r["name"] in ("playwright", "playwright-cli", "notebooklm", "graphify", "werkzeuge") for a in ("claude", "codex", "copilot", "opencode", "agy")) and {r["name"] for r in d["eintraege"]} >= {"playwright", "stitch", "wikijs", "playwright-cli", "notebooklm", "graphify", "werkzeuge"} and all(set(r["agenten"].values()) == {"schluessel_fehlt"} for r in d["eintraege"] if r["name"] in ("stitch", "wikijs")) and d["letzter_sync"]["ok"]' \
  || fail "clawbook agenten status: unexpected after the start: ${out}"
# shellcheck disable=SC2016 # expands on the container side
ssh_run 'set -e
  claude mcp list </dev/null | grep -q "^playwright: playwright-mcp --headless"
  codex mcp list --json </dev/null | python3 -c "import json,sys; sys.exit(0 if any(s[\"name\"] == \"playwright\" for s in json.load(sys.stdin)) else 1)"
  copilot mcp list --json </dev/null | python3 -c "import json,sys; sys.exit(0 if \"playwright\" in json.load(sys.stdin)[\"mcpServers\"] else 1)"
  timeout 120 opencode mcp list </dev/null 2>&1 | grep -q "playwright"
  agy mcp list </dev/null | grep -q "^playwright "
  for s in playwright-cli notebooklm graphify; do
    for d in ~/.claude/skills ~/.agents/skills ~/.gemini/config/skills; do test -f "$d/$s/SKILL.md"; done
  done
  for f in ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.copilot/copilot-instructions.md ~/.config/opencode/AGENTS.md; do
    grep -q ">>> clawbook agenten sync >>>" "$f"; grep -q "WorkspaceManager" "$f"
  done
  grep -q "trigger: always_on" ~/.gemini/config/rules/clawbook.md
  grep -q "WorkspaceManager" ~/.gemini/config/rules/clawbook.md
  ! claude mcp get stitch </dev/null >/dev/null 2>&1
  ! grep -q stitch ~/.codex/config.toml ~/.copilot/mcp-config.json ~/.config/opencode/opencode.json ~/.gemini/config/mcp_config.json
  test ! -e ~/CLAUDE.md && test ! -e ~/.opencode && test ! -e ~/GEMINI.md
  test -z "$(find ~ -maxdepth 3 -user root -not -path "$HOME/.clawbook*")"' \
  || fail "agent equipment after the start: MCP, skills or instructions missing, Stitch present or files of root in the home"
out=$(ssh_run 'clawbook agenten sync') || fail "clawbook agenten sync failed: ${out}"
if ! has 'Alles aktuell, nichts geändert' || ! has 'stitch .*fehlt STITCH_API_KEY' || ! has 'clawbook agenten schluessel STITCH_API_KEY'; then
  fail "clawbook agenten sync: expected no change and the missing Stitch key: ${out}"
fi
# Own entries with other names survive (also comments in Codex' TOML and
# OpenCode's JSONC); then the key for Stitch, given on stdin.
# shellcheck disable=SC2016 # expands on the container side
ssh_run 'set -e
  claude mcp add -s user eigener -- echo eigen </dev/null >/dev/null
  printf "\n# eigener Kommentar\n[mcp_servers.eigener]\ncommand = \"echo\"\n" >> ~/.codex/config.toml
  copilot mcp add eigener -- echo eigen </dev/null >/dev/null
  agy mcp add eigener echo eigen </dev/null >/dev/null
  python3 - <<PY
import json
p = "/home/student/.config/opencode/opencode.json"
d = json.load(open(p))
d["mcp"]["eigener"] = {"type": "local", "command": ["echo", "eigen"]}
open(p, "w").write(json.dumps(d, indent=2).replace("{\n", "{\n  // eigener Kommentar\n", 1) + "\n")
PY' || fail "could not add own MCP entries"
out=$(ssh_run 'printf "smoke-schluessel-4711\n" | clawbook agenten schluessel STITCH_API_KEY') \
  || fail "clawbook agenten schluessel STITCH_API_KEY failed: ${out}"
if ! has 'Schlüssel STITCH_API_KEY gespeichert' || ! has 'Claude Code: +MCP stitch eingetragen' || has 'smoke-schluessel-4711'; then
  fail "clawbook agenten schluessel: unexpected output (or the key was shown): ${out}"
fi
# shellcheck disable=SC2016 # expands on the container side
ssh_run 'set -e
  test "$(stat -c "%U %a" ~/.clawbook/secrets)" = "student 600"
  python3 - <<PY
import json, tomllib
h = "/home/student/"
claude = json.load(open(h + ".claude.json"))["mcpServers"]
assert claude["stitch"]["headers"] == {"X-Goog-Api-Key": "\${STITCH_API_KEY}"}, claude
codex = tomllib.load(open(h + ".codex/config.toml", "rb"))["mcp_servers"]
assert codex["stitch"]["env_http_headers"] == {"X-Goog-Api-Key": "STITCH_API_KEY"}, codex
copilot = json.load(open(h + ".copilot/mcp-config.json"))["mcpServers"]
assert copilot["stitch"]["headers"] == {"X-Goog-Api-Key": "\${STITCH_API_KEY}"}, copilot
oc_text = open(h + ".config/opencode/opencode.json").read()
assert "// eigener Kommentar" in oc_text and "{env:STITCH_API_KEY}" in oc_text, oc_text
agy = json.load(open(h + ".gemini/config/mcp_config.json"))["mcpServers"]
assert agy["stitch"]["headers"] == {"X-Goog-Api-Key": "smoke-schluessel-4711"}, agy
for servers in (claude, codex, copilot, agy):
    assert "eigener" in servers and "playwright" in servers, servers
assert "eigener" in oc_text
assert "# eigener Kommentar" in open(h + ".codex/config.toml").read()
PY
  test "$(stat -c %a ~/.gemini/config/mcp_config.json)" = 600
  codex mcp list --json </dev/null >/dev/null
  timeout 120 opencode mcp list </dev/null 2>&1 | grep -q stitch' \
  || fail "Stitch not carried into every agent, or own entries lost"
# The key reaches every kind of shell: ssh with a command, login shell,
# interactive shell, docker exec (BASH_ENV) - but never root.
# shellcheck disable=SC2016 # expands on the container side
out=$(ssh_run 'echo "cmd=$STITCH_API_KEY"
  env -i HOME=/home/student PATH=/usr/bin:/bin bash -lc "echo login=\$STITCH_API_KEY"
  env -i HOME=/home/student PATH=/usr/bin:/bin PS1=x bash -ic "echo interactive=\$STITCH_API_KEY" 2>/dev/null
  tmux new-session -d -s keytest "echo tmux=\$STITCH_API_KEY > /tmp/keytest; sleep 1"; sleep 2; cat /tmp/keytest; rm -f /tmp/keytest')
for kind in cmd login interactive tmux; do
  has "^${kind}=smoke-schluessel-4711$" || fail "STITCH_API_KEY missing in the ${kind} shell: ${out}"
done
# shellcheck disable=SC2016 # expands on the container side
[ "$(docker exec -u student "${NAME}" bash -c 'echo "$STITCH_API_KEY"')" = smoke-schluessel-4711 ] \
  || fail "STITCH_API_KEY missing for docker exec as student"
# shellcheck disable=SC2016 # expands on the container side
[ -z "$(docker exec "${NAME}" bash -c 'echo "${STITCH_API_KEY:-}"')" ] \
  || fail "root sees the student's key"
out=$(ssh_run 'clawbook agenten status; clawbook agenten status --json')
has 'smoke-schluessel-4711' && fail "clawbook agenten status shows the key"
# A second sync changes nothing (files identical).
before=$(ssh_run 'md5sum ~/.claude.json ~/.codex/config.toml ~/.copilot/mcp-config.json ~/.config/opencode/opencode.json ~/.gemini/config/mcp_config.json ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.gemini/config/rules/clawbook.md')
out=$(ssh_run 'clawbook agenten sync --json') || fail "second clawbook agenten sync failed: ${out}"
json_ok "${out}" 'not d["geaendert"] and d["ok"] and [w["name"] for w in d["weggelassen"]] == ["wikijs"]' \
  || fail "second clawbook agenten sync changed something: ${out}"
[ "$(ssh_run 'md5sum ~/.claude.json ~/.codex/config.toml ~/.copilot/mcp-config.json ~/.config/opencode/opencode.json ~/.gemini/config/mcp_config.json ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.gemini/config/rules/clawbook.md')" = "${before}" ] \
  || fail "second clawbook agenten sync rewrote files"
# The key never shows up outside ~/.clawbook/secrets (backups in
# ~/.clawbook/agenten/sicherung may hold it, 0600) nor in the start log.
# shellcheck disable=SC2016 # expands on the container side
ssh_run 'test "$(stat -c %a ~/.clawbook/agenten-stand.json)" = 600 && ! grep -rq smoke-schluessel-4711 --exclude=secrets --exclude-dir=sicherung --exclude-dir=apt ~/.clawbook 2>/dev/null' \
  || fail "the key appears in ~/.clawbook outside secrets, or agenten-stand.json is not 0600"
docker logs "${NAME}" 2>&1 | grep -q smoke-schluessel-4711 && fail "the key appears in the container log"
# A broken config.toml of the student: sync reports it and leaves the file
# byte for byte as it is (here while removing the key, so a change is due).
# shellcheck disable=SC2016 # expands on the container side
ssh_run 'cp ~/.codex/config.toml /tmp/config.toml.ok && printf "\n[kaputt\n" >> ~/.codex/config.toml && md5sum ~/.codex/config.toml > /tmp/config.toml.md5'
rc=0; out=$(ssh_run 'clawbook agenten schluessel STITCH_API_KEY --entfernen --json') || rc=$?
if [ "${rc}" != 1 ] || ! json_ok "${out}" 'not d["sync"]["ok"] and d["sync"]["agenten"]["codex"]["fehler"] and "MCP stitch entfernt" in d["sync"]["agenten"]["claude"]["aenderungen"]'; then
  fail "sync with a broken config.toml: expected ok=false and a Codex error: ${out}"
fi
ssh_run 'md5sum -c --quiet /tmp/config.toml.md5 && cp /tmp/config.toml.ok ~/.codex/config.toml && clawbook agenten sync >/dev/null' \
  || fail "sync changed a broken config.toml, or the sync after repairing it failed"
ssh_run '! grep -q stitch ~/.codex/config.toml ~/.copilot/mcp-config.json ~/.config/opencode/opencode.json ~/.gemini/config/mcp_config.json && ! claude mcp get stitch </dev/null >/dev/null 2>&1 && claude mcp get eigener </dev/null >/dev/null' \
  || fail "Stitch not removed after the key was removed, or own entries lost"
echo "agent equipment ok"

# RDP: Weston answers and XWayland provides display :0.
timeout 5 bash -c "exec 3<>/dev/tcp/127.0.0.1/${RDP_PORT}" \
  || fail "RDP port ${RDP_PORT} does not answer"
docker exec "${NAME}" pgrep -x weston >/dev/null || fail "weston is not running"
docker exec "${NAME}" bash -c \
  'for _ in $(seq 1 20); do DISPLAY=:0 xhost >/dev/null 2>&1 && exit 0; sleep 1; done; exit 1' \
  || fail "XWayland display :0 is not available"
echo "rdp ok"

# Browsers as student, without root and without internet (data: URLs):
# playwright-cli (skills, headless, on display :0), Playwright-MCP over
# stdio, and the Python Playwright of notebooklm (headless and on :0).
# shellcheck disable=SC2016 # expands on the container side
ssh_run 'set -e; d=$(mktemp -d); cd "$d"
  # "open" starts a background daemon: its output goes to a file (the ssh
  # channel must not stay open), and every exit closes all its browsers.
  trap '"'"'rc=$?; [ $rc = 0 ] || cat "$d/cli.log" 2>/dev/null
    timeout 30 playwright-cli close-all >/dev/null 2>&1; cd /; rm -rf "$d"; exit $rc'"'"' EXIT
  timeout 120 playwright-cli install --skills >>"$d/cli.log" 2>&1
  test -f .claude/skills/playwright-cli/SKILL.md
  timeout 90 playwright-cli open "data:text/html,<title>cli-smoke</title>ok" >>"$d/cli.log" 2>&1 </dev/null
  timeout 30 playwright-cli eval document.title 2>>"$d/cli.log" | grep -q cli-smoke
  timeout 30 playwright-cli close >>"$d/cli.log" 2>&1
  timeout 90 playwright-cli open --headed "data:text/html,<title>cli-headed</title>ok" >>"$d/cli.log" 2>&1 </dev/null
  timeout 30 playwright-cli eval document.title 2>>"$d/cli.log" | grep -q cli-headed
  timeout 30 playwright-cli close >>"$d/cli.log" 2>&1' || fail "playwright-cli could not open a page as student"
echo "playwright-cli ok"
# shellcheck disable=SC2016 # expands on the container side
ssh_run 'cd "$(mktemp -d)" && timeout 120 python3 -' <<'PY' || fail "Playwright-MCP could not open a page"
import json, os, signal, subprocess, sys
p = subprocess.Popen(["playwright-mcp", "--headless", "--isolated"],
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True,
                     start_new_session=True)
def call(i, method, params=None):
    p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": i, "method": method,
                              "params": params or {}}) + "\n")
    p.stdin.flush()
    for line in p.stdout:
        m = json.loads(line)
        if m.get("id") == i:
            return m
    sys.exit("playwright-mcp ended early")
try:
    call(1, "initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                           "clientInfo": {"name": "smoke", "version": "1"}})
    p.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n")
    r = call(2, "tools/call", {"name": "browser_navigate",
                               "arguments": {"url": "data:text/html,<title>mcp-smoke</title>ok"}})
    call(3, "tools/call", {"name": "browser_close", "arguments": {}})
    if "mcp-smoke" not in json.dumps(r) or r.get("result", {}).get("isError"):
        sys.exit(json.dumps(r)[:600])
finally:
    # Not ending on EOF is no failure: end the server and its Chromium.
    try:
        p.stdin.close()
        p.wait(timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        pass
    if p.poll() is None:
        os.killpg(p.pid, signal.SIGKILL)
        p.wait()
PY
echo "playwright-mcp ok"
ssh_run 'timeout 120 /opt/uv-tools/notebooklm-py/bin/python -' <<'PY' || fail "notebooklm: Playwright cannot start Chromium"
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    for headless in (True, False):
        b = p.chromium.launch(headless=headless)
        page = b.new_page()
        page.goto("data:text/html,<title>nlm-smoke</title>ok")
        assert page.title() == "nlm-smoke"
        b.close()
PY
echo "notebooklm browser ok"

# Samba: share "student" is writable with the password the start shows.
smb_pw=$(docker exec "${NAME}" cat /home/student/.clawbook/samba-password)
grep -qF "Passwort ${smb_pw}" <<<"${logs}" \
  || fail "start script did not show the Samba password"
echo smoke > "${WORK}/smoke.txt"
smb //127.0.0.1/student -p "${SMB_PORT}" -U "student%${smb_pw}" -c 'put smoke.txt; ls smoke.txt' \
  || fail "Samba share not usable"
docker exec "${NAME}" test -f /home/student/smoke.txt \
  || fail "file written via Samba is missing in the home directory"
echo "samba ok"

# Recreate the container from the same home: keys must survive.
docker rm -f "${NAME}" >/dev/null
run_container
wait_healthy
docker cp "${NAME}:/home/student/.ssh/id_ed25519" "${WORK}/key" >/dev/null
second=$(ssh-keygen -lf "${WORK}/key")
[ "${first}" = "${second}" ] || fail "SSH key changed after recreating the container"
ssh_run true || fail "SSH login failed after recreating the container"
# A deleted sample must not come back.
ssh_run 'rm -rf ~/source/samples' && docker restart "${NAME}" >/dev/null && wait_healthy
ssh_run 'test ! -e ~/source/samples' || fail "sample project was recreated after deletion"
echo "recreate ok"

# clawbook key new: new key pair, the new key logs in, the old one no longer.
cp "${WORK}/key" "${WORK}/oldkey"
ssh_run 'clawbook key new --yes --json' >/dev/null || fail "clawbook key new --yes failed"
docker cp "${NAME}:/home/student/.ssh/id_ed25519" "${WORK}/key" >/dev/null
[ "$(ssh-keygen -lf "${WORK}/key")" != "${second}" ] || fail "clawbook key new kept the old key"
ssh_run true || fail "SSH login with the new key failed"
ssh -i "${WORK}/oldkey" -p "${SSH_PORT}" -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o LogLevel=ERROR \
    student@127.0.0.1 true 2>/dev/null && fail "old key still logs in after clawbook key new"
echo "key new ok"

# --- Technology packages and courses (clawbook-apt) ------------------------
docker exec "${NAME}" bash -c 'test -s /usr/share/keyrings/clawbook-apt.gpg \
  && grep -q "^URIs: https://schlingensiepen.github.io/clawbook-apt" /etc/apt/sources.list.d/clawbook.sources \
  && grep -q "^Signed-By: /usr/share/keyrings/clawbook-apt.gpg" /etc/apt/sources.list.d/clawbook.sources' \
  || fail "package source clawbook-apt or its key missing in the image"
docker exec "${NAME}" bash -c 'apt-config dump | grep -q "Dir::Cache::archives \"/home/student/.clawbook/apt/archives/\"" \
  && test "$(stat -c %U /home/student/.clawbook/apt/archives/partial)" = _apt' \
  || fail "apt cache is not in the home volume"
out=$(ssh_run 'clawbook pakete katalog --json') || fail "clawbook pakete katalog --json failed: ${out}"
json_ok "${out}" 'd["aktualisiert"] and len(d["pakete"]) >= 15 and {"kurs-inf", "kurs-swe", "kurs-iot"} <= {p["name"] for p in d["pakete"] if p["art"] == "kurs"} and not any(p["installiert"] for p in d["pakete"])' \
  || fail "catalog does not show the 15 packages of clawbook-apt: ${out}"
# "clawbook pakete" on a terminal opens the menu (courses first); Enter leaves.
out=$(ssh_tty '\n' 'clawbook pakete; echo "rc=$?"')
if ! has 'Pakete und Kurse - Kurse' || ! has 'kurs-inf' || ! has 'Technikpakete einzeln' || ! has 'rc=0'; then
  fail "clawbook pakete did not open the package menu: ${out}"
fi
echo "catalog ok"
start=$(date +%s)
out=$(ssh_run 'clawbook pakete add kurs-inf --yes --json 2>/tmp/add.log') \
  || { ssh_run 'tail -n 30 /tmp/add.log' || true; fail "clawbook pakete add kurs-inf failed: ${out}"; }
json_ok "${out}" 'd["installiert"] == ["kurs-inf"] and d["vorladen"] is None' \
  || fail "clawbook pakete add kurs-inf: unexpected result: ${out}"
echo "kurs-inf installed in $(( $(date +%s) - start ))s"
ssh_run 'java -version 2>&1 | grep -q "25\." && mvn -v >/dev/null && gradle --version >/dev/null \
  && spring --version && sqlite3 --version >/dev/null && http --version >/dev/null \
  && xh --version >/dev/null && hurl --version >/dev/null' >/dev/null \
  || fail "kurs-inf: Java, Spring, SQLite or the web API tools missing"
out=$(ssh_run 'clawbook kurse --json')
json_ok "${out}" 'd["kurse"] == [{"kennung": "kurs-inf", "titel": "Ingenieurinformatik", "version": d["kurse"][0]["version"]}]' \
  || fail "clawbook kurse --json: kurs-inf missing: ${out}"
out=$(ssh_run 'clawbook kurs vscode kurs-inf --json') || fail "clawbook kurs vscode kurs-inf failed"
json_ok "${out}" 'd["format"] == 1 and d["kennung"] == "kurs-inf" and {"vscjava.vscode-java-pack", "vmware.vscode-boot-dev-pack", "zknpr.sqlite-explorer", "humao.rest-client"} <= set(d["container"]["erweiterungen"]) and "ms-vscode-remote.remote-ssh" in d["windows"]["erweiterungen"] and d["einstellungen"]["update.mode"] == "none"' \
  || fail "clawbook kurs vscode kurs-inf: Java/Spring extensions missing: ${out}"
out=$(ssh_run 'clawbook kurs vscode clawbook --json')
json_ok "${out}" 'd["kennung"] == "clawbook" and "vscjava.vscode-java-pack" in d["container"]["erweiterungen"]' \
  || fail "clawbook kurs vscode clawbook: extensions of the technology packages missing"
out=$(ssh_run 'cat ~/.clawbook/stand.json')
json_ok "${out}" 'd["kurse"] == ["kurs-inf"] and {p["name"]: p["manuell"] for p in d["pakete"]}.get("kurs-inf") is True and {p["name"]: p["manuell"] for p in d["pakete"]}.get("clawbook-java") is False' \
  || fail "stand.json not updated after pakete add: ${out}"
out=$(ssh_run 'clawbook status --json')
json_ok "${out}" 'd["paket_cache"]["bytes"] > 50 * 1024 * 1024 and "wiederherstellung" not in d' \
  || fail "apt cache in the home volume is (nearly) empty: ${out}"
echo "packages ok"

# New image (simulated): recreate the container with the same home. The
# restore runs in the background and must not delay SSH.
wait_restore() {
  # prints "clawbook status --json" once the restore has ended
  local st=""
  for _ in $(seq 1 180); do
    st=$(docker exec "${NAME}" clawbook status --json 2>/dev/null) || true
    if json_ok "${st}" 'd.get("wiederherstellung") in ("fertig", "fehler")' 2>/dev/null; then
      printf '%s' "${st}"
      return 0
    fi
    sleep 5
  done
  printf '%s' "${st}"
  return 1
}
restore_ok() {
  # $1 = what is tested; the last restore must be "fertig" and kurs-inf back
  local st
  st=$(wait_restore) || fail "$1: restore did not finish: ${st}"
  json_ok "${st}" 'd["wiederherstellung"] == "fertig"' \
    || { docker exec "${NAME}" tail -n 40 /home/student/.clawbook/restore.log || true
         fail "$1: restore failed: ${st}"; }
  docker exec -u student "${NAME}" bash -lc 'java -version 2>&1 | grep -q "25\." && spring --version >/dev/null && sqlite3 --version >/dev/null && test -d /usr/share/clawbook/kurse/kurs-inf' \
    || fail "$1: kurs-inf not back after the restore"
}
debs() {
  docker run --rm --entrypoint bash -v "${VOLUME}:/h" "${IMAGE}" -c 'ls /h/.clawbook/apt/archives/*.deb | sort'
}
cache_before=$(debs)

# 1. Online: everything comes from the apt cache (no new .deb in the cache).
docker rm -f "${NAME}" >/dev/null
run_container
wait_healthy
ssh_run true || fail "SSH login failed while the restore runs"
out=$(docker exec "${NAME}" clawbook status --json)
json_ok "${out}" 'd["wiederherstellung"] in ("läuft", "fertig") and d["wiederherstellung_details"]["pakete"] == ["kurs-inf"]' \
  || fail "restore was not started after recreating the container: ${out}"
LC_ALL=C grep -q '[^[:print:][:space:]]' <<<"${out}" && fail "clawbook status --json is not ASCII-only"
restore_ok "restore online"
[ "$(debs)" = "${cache_before}" ] || fail "restore downloaded packages again instead of using the apt cache"
echo "restore (apt cache) ok"

# 2. docker restart after a finished restore: nothing to do, no restart loop.
docker restart "${NAME}" >/dev/null
wait_healthy
sleep 8
out=$(docker exec "${NAME}" clawbook status --json)
json_ok "${out}" '"wiederherstellung" not in d and d["wiederherstellung_details"]["zustand"] == "keine"' \
  || fail "restore runs again after docker restart: ${out}"
docker exec "${NAME}" bash -c '/command/s6-svstat /run/service/clawbook-restore | grep -Eq "^down .* ([3-9]|[1-9][0-9]+) seconds"' \
  || fail "service clawbook-restore restarts in a loop: $(docker exec "${NAME}" /command/s6-svstat /run/service/clawbook-restore)"
echo "restart ok"

# 3. Without any network, package lists present.
docker rm -f "${NAME}" >/dev/null
docker run -d --name "${NAME}" --network none -v "${VOLUME}:/home/student" "${IMAGE}" >/dev/null
wait_healthy
restore_ok "restore offline"
echo "restore (offline) ok"

# 4. Without network AND without package lists, stand.json in format 1
#    (as written by images before interface 2): straight from the .deb files.
docker rm -f "${NAME}" >/dev/null
docker run --rm --entrypoint bash -v "${VOLUME}:/h" "${IMAGE}" -c '
  find /h/.clawbook/apt/lists -maxdepth 1 -type f -delete
  cat > /h/.clawbook/stand.json <<JSON
{"format": 1, "schnittstelle": 1, "kennung": "clawbook",
 "pakete": [{"name": "kurs-inf", "version": "0.8.0-1", "art": "kurs"}],
 "vscode": {"container": {"erweiterungen": []}}}
JSON
  chown 1000:1000 /h/.clawbook/stand.json'
docker run -d --name "${NAME}" --network none -v "${VOLUME}:/home/student" "${IMAGE}" >/dev/null
wait_healthy
restore_ok "restore offline without package lists (stand format 1)"
out=$(docker exec "${NAME}" cat /home/student/.clawbook/stand.json)
json_ok "${out}" 'd["format"] == 2 and d["kurse"] == ["kurs-inf"] and {p["name"]: p["manuell"] for p in d["pakete"]}.get("clawbook-java") is False' \
  || fail "stand.json after restore from format 1: ${out}"
echo "restore (format 1, no lists) ok"

# Removing the course takes its technology packages, nothing else.
before=$(docker exec "${NAME}" dpkg-query -W -f='${Package}\n' | sort)
out=$(docker exec -u student "${NAME}" clawbook pakete remove kurs-inf --yes --json 2>/dev/null) \
  || fail "clawbook pakete remove kurs-inf failed: ${out}"
json_ok "${out}" 'd["entfernt"] == ["kurs-inf"]' || fail "pakete remove: unexpected result: ${out}"
docker exec -u student "${NAME}" bash -c '! command -v spring && ! dpkg -l clawbook-java 2>/dev/null | grep -q ^ii' >/dev/null \
  || fail "pakete remove left the technology packages of kurs-inf behind"
after=$(docker exec "${NAME}" dpkg-query -W -f='${Package}\n' | sort)
gone=$(comm -23 <(echo "${before}") <(echo "${after}"))
image_pkgs=$(docker run --rm --entrypoint dpkg-query "${IMAGE}" -W -f='${Package}\n' | sort)
lost=$(comm -12 <(echo "${gone}") <(echo "${image_pkgs}"))
[ -z "${lost}" ] || fail "pakete remove removed packages of the image: ${lost}"
out=$(docker exec -u student "${NAME}" clawbook kurse --json)
json_ok "${out}" 'd == {"kurse": []}' || fail "kurs-inf still listed after remove"
echo "remove ok"

echo "Smoke test passed."
