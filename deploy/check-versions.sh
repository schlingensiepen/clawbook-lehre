#!/bin/bash
# Compares the pinned versions in deploy/versions.env with the newest
# releases and prints a Markdown table. Exit code is always 0: the report
# informs, raising a version is a deliberate change.
#
#   deploy/check-versions.sh [path/to/versions.env]

set -uo pipefail

FILE=${1:-deploy/versions.env}

# shellcheck source=/dev/null
. "${FILE}"

npm_latest()  { npm view "$1" version 2>/dev/null; }
pypi_latest() { curl -fsSL "https://pypi.org/pypi/$1/json" | jq -r .info.version; }
gh_latest()   { curl -fsSL "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name | sed 's/^v//'; }
node22_latest() {
  curl -fsSL https://nodejs.org/dist/index.json \
    | jq -r '[.[] | select(.version | startswith("v22."))][0].version' | sed 's/^v//'
}

echo "| Werkzeug | festgelegt | neueste | Hinweis |"
echo "|---|---|---|---|"

row() {
  local name=$1 pinned=$2 latest=$3 note=""
  if [ -z "${latest}" ] || [ "${latest}" = null ]; then
    note="nicht ermittelbar"
  elif [ "${latest}" != "${pinned}" ]; then
    note="**neuer verfügbar**"
  fi
  echo "| ${name} | ${pinned} | ${latest} | ${note} |"
}

row "s6-overlay"     "${S6_OVERLAY_VERSION}"     "$(gh_latest just-containers/s6-overlay)"
row "Node.js 22"     "${NODE_VERSION}"           "$(node22_latest)"
row "uv"             "${UV_VERSION}"             "$(gh_latest astral-sh/uv)"
row "GitHub CLI"     "${GH_VERSION}"             "$(gh_latest cli/cli)"
row "Claude Code"    "${CLAUDE_CODE_VERSION}"    "$(npm_latest @anthropic-ai/claude-code)"
row "Codex"          "${CODEX_VERSION}"          "$(npm_latest @openai/codex)"
row "Copilot CLI"    "${COPILOT_VERSION}"        "$(npm_latest @github/copilot)"
row "OpenCode"       "${OPENCODE_VERSION}"       "$(npm_latest opencode-ai)"
row "Playwright"     "${PLAYWRIGHT_VERSION}"     "$(npm_latest playwright)"
row "Playwright CLI" "${PLAYWRIGHT_CLI_VERSION}" "$(npm_latest @playwright/cli)"
row "Playwright MCP" "${PLAYWRIGHT_MCP_VERSION}" "$(npm_latest @playwright/mcp)"
row "Wiki.js MCP"    "${WIKIJS_MCP_VERSION}"     "$(npm_latest @cahaseler/wikijs-mcp)"
row "Graphify"       "${GRAPHIFY_VERSION}"       "$(pypi_latest graphifyy)"
row "notebooklm-py"  "${NOTEBOOKLM_VERSION}"     "$(pypi_latest notebooklm-py)"

exit 0
