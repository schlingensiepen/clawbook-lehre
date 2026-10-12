# Agenten-Ausstattung: Werkzeuge für alle Agenten

Stand: 2026-10-12

Im clawbook sind fünf Coding-Agenten installiert: Claude
Code (`claude`), Codex (`codex`), GitHub Copilot CLI
(`copilot`), OpenCode (`opencode`) und Antigravity
(`agy`). Damit jeder von ihnen die Werkzeuge im
Container auch benutzen kann, trägt clawbook sie bei
allen Agenten ein, und zwar je nach Werkzeug als

- **MCP-Server**: ein Dienst, der dem Agenten Werkzeuge
  anbietet (Browser steuern, im Wiki suchen, Oberflächen
  entwerfen),
- **Skill**: eine kurze Anleitung, die der Agent liest,
  wenn er ein Werkzeug braucht,
- **Anweisung**: ein kurzer Text in der allgemeinen
  Anweisungsdatei des Agenten, der sagt, welche
  Werkzeuge es im Container gibt.

Jeder Abschnitt dieser Seite sagt, zu welcher Art er
gehört:

- **Das erledigt clawbook**: passiert von selbst. Hier
  steht, was geschieht und woran Sie es sehen.
- **Das tun Sie selbst**: geht nicht automatisch, zum
  Beispiel einen Schlüssel beim Anbieter erzeugen.
- **Falls die Automatik nicht geht**: nur nötig, wenn
  etwas schiefgeht oder Sie einen Schritt bewusst von
  Hand machen wollen.

## Was ankommt

| Name | Art | Voraussetzung |
|---|---|---|
| `playwright` | MCP-Server: Browser (Chromium) ohne Fenster | keine |
| `stitch` | MCP-Server: Google Stitch, Oberflächen-Entwürfe | Schlüssel `STITCH_API_KEY` |
| `wikijs` | MCP-Server: das Wiki des Kurses | `WIKIJS_URL` und `WIKIJS_API_KEY` |
| `playwright-cli` | Skill: Browser per Kommandozeile | keine |
| `notebooklm` | Skill: NotebookLM per Kommandozeile | keine (zum Benutzen die NotebookLM-Anmeldung, siehe [Google](setup/google.md)) |
| `graphify` | Skill: Wissensgraph aus Code und Dokumenten, je Agent die passende Fassung | keine |
| `werkzeuge` | Anweisung: welche Werkzeuge im Container sind | keine |

Kurse und Technikpakete ([Kurse und
Technikpakete](kurse-und-pakete.md)) können weitere
Einträge mitbringen. Sie kommen auf demselben Weg bei
allen Agenten an.

## Das erledigt clawbook

**Wann:** bei jedem Start des Containers, im
Hintergrund nach der Wiederherstellung der Pakete (die
Anmeldung per SSH wartet nicht darauf), nach jedem
`clawbook pakete add` und `clawbook pakete remove` und
nach jedem `clawbook agenten schluessel`. Von Hand
jederzeit mit:

```bash
clawbook agenten sync
```

Der Abgleich ist wiederholbar: Ist alles eingetragen,
meldet er „Alles aktuell, nichts geändert.“ und
schreibt keine Datei neu.

**Wohin:** nur in Ihre Benutzer-Einstellungen im
Home-Verzeichnis, nie in ein Projekt (dort landete es
sonst in Git).

| Agent | MCP-Server | Skills | Anweisung |
|---|---|---|---|
| Claude Code | `~/.claude.json` (über `claude mcp`) | `~/.claude/skills/` | Block in `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/config.toml` | `~/.agents/skills/` | Block in `~/.codex/AGENTS.md` |
| Copilot CLI | `~/.copilot/mcp-config.json` (über `copilot mcp`) | `~/.agents/skills/` | Block in `~/.copilot/copilot-instructions.md` |
| OpenCode | `~/.config/opencode/opencode.json` | `~/.agents/skills/` | Block in `~/.config/opencode/AGENTS.md` |
| Antigravity | `~/.gemini/config/mcp_config.json` (über `agy mcp`) | `~/.gemini/config/skills/` | eigene Datei `~/.gemini/config/rules/clawbook.md` |

Der Block steht zwischen den Zeilen
`<!-- >>> clawbook agenten sync >>> -->` und
`<!-- <<< clawbook agenten sync <<< -->`. Was Sie darin
ändern, überschreibt der nächste Abgleich. Eigene
Anweisungen schreiben Sie in dieselbe Datei, aber
außerhalb des Blocks.

**Was bleibt:** MCP-Server, Skills und Anweisungen, die
Sie selbst unter einem anderen Namen angelegt haben,
fasst clawbook nicht an. In
`~/.clawbook/agenten-stand.json` merkt es sich, welche
Einträge es selbst angelegt hat, und ändert oder
entfernt nur diese. Gibt es schon einen Eintrag mit
demselben Namen, etwa einen `playwright`-Server, den Sie
früher von Hand eingetragen haben, ersetzt clawbook ihn
und meldet „übernommen“. Einen Skill mit demselben Namen
und anderem Inhalt legt es vorher in
`~/.clawbook/agenten/sicherung/` ab.

**Woran Sie es sehen:**

```bash
clawbook agenten
```

Dasselbe zeigt Menüpunkt **10** „Agenten-Ausstattung“
im clawbook-Menü. Sie sehen eine Tabelle mit einer
Zeile je Eintrag und einer Spalte je Agent:

- `ja`: eingetragen,
- `SCHLÜSSEL`: ein Schlüssel fehlt, der Eintrag wartet,
- `FEHLT` oder `ANDERS`: kommt beim nächsten Abgleich,
- `-`: für diesen Agenten nicht vorgesehen.

Darunter steht, welche Schlüssel gesetzt sind (nie ihre
Werte) und wann der letzte Abgleich lief. Die Agenten
selbst zeigen ihre MCP-Server mit `claude mcp list`,
`codex mcp list`, `copilot mcp list`, `opencode mcp
list` und `agy mcp list`.

Ein Agent liest seine Einstellungen nur beim Start.
Läuft er gerade, beenden Sie ihn nach einer Änderung mit
`/exit` und starten ihn neu.

## Das tun Sie selbst: Schlüssel für Stitch und Wiki.js

Den Schlüssel erzeugt der Anbieter: für Stitch Google
(siehe [Google](setup/google.md), „Beim Anbieter“), für
Wiki.js der Kurs (siehe
[Kurs-Dienste](setup/kurs-dienste.md)). Im Container
geben Sie ihn einmal ein:

```bash
clawbook agenten schluessel STITCH_API_KEY
```

clawbook fragt „Wert für STITCH_API_KEY (Eingabe bleibt
unsichtbar):“. Fügen Sie den Schlüssel ein (er bleibt
unsichtbar) und drücken Sie Enter. clawbook speichert
ihn in `~/.clawbook/secrets`, einer Datei, die nur Sie
lesen können, trägt Stitch gleich bei allen Agenten ein
und meldet zum Beispiel „Claude Code: MCP stitch
eingetragen“.

Für Wiki.js sind es zwei Werte, die Adresse und der
Schlüssel:

```bash
clawbook agenten schluessel WIKIJS_URL       # Wert z. B. https://wiki.example.org
clawbook agenten schluessel WIKIJS_API_KEY
```

Ohne weiteres bekommt der Agent nur Werkzeuge zum
Lesen. Soll er im Wiki auch Seiten anlegen und ändern
dürfen, setzen Sie zusätzlich:

```bash
clawbook agenten schluessel WIKIJS_ENABLE_EDIT   # Wert: true
```

Ändern: denselben Befehl noch einmal aufrufen.
Entfernen, zum Beispiel:

```bash
clawbook agenten schluessel STITCH_API_KEY --entfernen
```

Dann nimmt clawbook auch den Stitch-Server bei allen
Agenten wieder heraus. Im clawbook-Menü geht beides
über Punkt 10, dann `k`.

**Wie die Agenten an den Schlüssel kommen:** In den
Einstellungen der Agenten steht nur ein Verweis wie
`${STITCH_API_KEY}`, nicht der Schlüssel selbst. Der
Agent liest den Wert beim Start aus seiner Umgebung.
Dafür setzt der Container alle Schlüssel aus
`~/.clawbook/secrets` in jedem Terminal als
Umgebungsvariablen: per SSH, im Terminal von VS Code und
in tmux. Ein neues Terminal hat den Schlüssel sofort; in
einem schon offenen Terminal laden Sie ihn mit:

```bash
. /etc/profile.d/clawbook-secrets.sh
```

Weil die Schlüssel so in jedem Programm ankommen, nimmt
clawbook keine an, die die Anmeldung eines Agenten
umstellen würden (zum Beispiel `ANTHROPIC_API_KEY`,
`OPENAI_API_KEY`, `GH_TOKEN`); siehe
[Setup](setup/README.md), „Drei Regeln für Schlüssel und
Zugänge“.

**Ausnahme Antigravity:** Antigravity kann keine
Verweise auflösen. Den Stitch-Schlüssel schreibt
clawbook dort deshalb im Klartext in
`~/.gemini/config/mcp_config.json` und macht die Datei
nur für Sie lesbar. Behandeln Sie diese Datei wie ein
Passwort: nicht weitergeben, nie in ein Repository.
Wiki.js betrifft das nicht, denn Antigravity reicht
seine Umgebungsvariablen an den Wiki.js-Server weiter.

## Für Fortgeschrittene: eigene Einträge

Eigene Einträge legen Sie als JSON-Datei in
`~/.clawbook/agenten.d/` ab, zum Beispiel
`~/.clawbook/agenten.d/mein-server.json`. Danach
`clawbook agenten sync`. Ein Eintrag mit demselben
Namen wie einer aus dem Image ersetzt diesen. Eine Datei
enthält einen Eintrag oder eine Liste von Einträgen.

Einen Eintrag des Images abschalten (hier den
Playwright-MCP; clawbook nimmt ihn bei allen Agenten
heraus):

```json
{"name": "playwright", "aus": true}
```

Ein eigener MCP-Server, lokal gestartet (`stdio`):

```json
{
  "art": "mcp",
  "name": "mein-server",
  "transport": "stdio",
  "command": "mein-mcp",
  "args": ["--option"],
  "env": {"MEIN_TOKEN": "${MEIN_TOKEN}"},
  "benoetigt": ["MEIN_TOKEN"]
}
```

Ein MCP-Server im Netz (`http`) mit Schlüssel im Header:

```json
{
  "art": "mcp",
  "name": "mein-dienst",
  "transport": "http",
  "url": "https://mcp.example.org/mcp",
  "headers": {"X-Api-Key": "${MEIN_DIENST_KEY}"},
  "benoetigt": ["MEIN_DIENST_KEY"]
}
```

Ein eigener Skill aus einem Ordner mit `SKILL.md` und
eine eigene Anweisung:

```json
[
  {"art": "skill", "name": "mein-skill",
   "quelle": {"verzeichnis": "/home/student/skills/mein-skill"}},
  {"art": "anweisung", "name": "meine-regeln",
   "text": "Antworte immer mit einem Satz Zusammenfassung am Ende.",
   "reihenfolge": 90}
]
```

Die Felder im Überblick:

- `art`: `mcp`, `skill` oder `anweisung`; `name`:
  Kleinbuchstaben, Ziffern, `.`, `_`, `-`.
- `agenten` (optional): nur für diese Agenten, aus
  `claude`, `codex`, `copilot`, `opencode`, `agy`.
- Schlüssel nur als Verweis `${NAME}`; der Wert kommt
  aus `~/.clawbook/secrets` (`clawbook agenten
  schluessel NAME`). Fehlt ein Name aus `benoetigt`,
  lässt clawbook den ganzen Eintrag weg und meldet das;
  fehlt ein anderer Verweis, entfällt nur diese eine
  Variable bzw. dieser Header.
- Skill-`quelle`: `verzeichnis` (ein Ordner für alle),
  `verzeichnis_je_ziel`, `befehl` (ein Befehl, der den
  Skill anlegt) oder `befehl_je_ziel`. Ziele sind die
  drei gemeinsamen Skill-Ordner `claude`
  (`~/.claude/skills`), `agents` (`~/.agents/skills`) und
  `antigravity` (`~/.gemini/config/skills`). Ein Befehl
  läuft mit einem leeren Wegwerf-Home und -Arbeitsordner;
  clawbook übernimmt daraus nur den Skill-Ordner.
- Anweisung: `text` oder `datei` (absoluter Pfad),
  `reihenfolge` (kleinere Zahl steht weiter oben).

Technikpakete legen ihre Einträge im selben Format unter
`/usr/share/clawbook/agenten.d/<paket>.json` ab.

## Falls die Automatik nicht geht

Zuerst `clawbook agenten sync` aufrufen und die
Meldungen lesen; meist steht dort, was fehlt. Wollen Sie
einen Agenten trotzdem von Hand einrichten, sind das die
Wege, hier am Beispiel Playwright-MCP und Stitch.
Einträge mit denselben Namen übernimmt der nächste
automatische Abgleich; soll er das nicht, schalten Sie
den Eintrag ab (siehe oben, `"aus": true`).

**Claude Code:**

```bash
claude mcp add -s user playwright -- playwright-mcp --headless
read -rs KEY
claude mcp add -s user --transport http stitch \
  https://stitch.googleapis.com/mcp \
  --header "X-Goog-Api-Key: $KEY"
unset KEY
```

**Codex:** in `~/.codex/config.toml` (Codex liest den
Schlüssel aus der Umgebungsvariablen `STITCH_API_KEY`):

```toml
[mcp_servers.playwright]
command = "playwright-mcp"
args = ["--headless"]

[mcp_servers.stitch]
url = "https://stitch.googleapis.com/mcp"

[mcp_servers.stitch.env_http_headers]
X-Goog-Api-Key = "STITCH_API_KEY"
```

**Copilot CLI** (die einfachen Anführungszeichen
lassen `${STITCH_API_KEY}` als Verweis stehen):

```bash
copilot mcp add playwright -- playwright-mcp --headless
copilot mcp add --transport http \
  --header 'X-Goog-Api-Key: ${STITCH_API_KEY}' \
  stitch https://stitch.googleapis.com/mcp
```

**OpenCode:** in `~/.config/opencode/opencode.json`
unter `"mcp"`:

```json
"playwright": {"type": "local", "command": ["playwright-mcp", "--headless"]},
"stitch": {"type": "remote", "url": "https://stitch.googleapis.com/mcp",
           "headers": {"X-Goog-Api-Key": "{env:STITCH_API_KEY}"}, "oauth": false}
```

**Antigravity** (Schlüssel im Klartext, darum danach
`chmod`):

```bash
agy mcp add playwright -- playwright-mcp --headless
read -rs KEY
agy mcp add --header "X-Goog-Api-Key: $KEY" stitch https://stitch.googleapis.com/mcp
unset KEY
chmod 600 ~/.gemini/config/mcp_config.json
```

**Skills von Hand:** `playwright-cli` legt den Skill im
aktuellen Ordner an, deshalb zuerst `cd ~`. Die anderen
Befehle in einem leeren Ordner aufrufen, denn manche
legen zusätzlich Dateien im aktuellen Ordner an:

```bash
cd ~ && playwright-cli install --skills    # ~/.claude/skills
cd "$(mktemp -d)"
notebooklm skill install                   # ~/.claude/skills und ~/.agents/skills
graphify install --platform agents         # oder claude, antigravity
```

`graphify install --platform claude` hängt außerdem
einen Abschnitt an `~/.claude/CLAUDE.md` an; den können
Sie wieder löschen.

## Typische Fehler

- **`clawbook agenten` zeigt bei `stitch` oder `wikijs`
  `SCHLÜSSEL`** → Der Schlüssel ist noch nicht gesetzt:
  `clawbook agenten schluessel STITCH_API_KEY` (bzw.
  `WIKIJS_URL` und `WIKIJS_API_KEY`).
- **Der Agent kennt einen neuen Server oder Skill
  nicht** → Er lief schon vor dem Abgleich. Mit `/exit`
  beenden und neu starten.
- **`claude mcp list` warnt „Missing environment
  variables: STITCH_API_KEY“** → Das Terminal ist älter
  als der Schlüssel. Ein neues Terminal öffnen oder
  `. /etc/profile.d/clawbook-secrets.sh`, dann den
  Agenten neu starten.
- **Stitch zeigt „Connected“, aber jeder Auftrag
  scheitert (zum Beispiel mit „401“ oder „permission
  denied“)** → Der Schlüssel ist falsch oder in Stitch
  gelöscht. Stitch antwortet auf die Verbindungsprobe
  auch mit falschem Schlüssel; „Connected“ beweist also
  nichts. Schlüssel neu erzeugen und mit `clawbook
  agenten schluessel STITCH_API_KEY` neu setzen.
- **Meldung „Anfangsmarkierung ohne Endmarkierung“** →
  In einer Anweisungsdatei fehlt die Zeile
  `<!-- <<< clawbook agenten sync <<< -->`. Den alten
  Block samt Anfangszeile löschen und
  `clawbook agenten sync` aufrufen.
- **Meldung „MCP-Konfiguration nicht lesbar, nichts
  geändert“** → Eine eigene Änderung hat die genannte
  Datei ungültig gemacht (etwa ein Komma zu viel in
  `opencode.json` oder ein Tippfehler in
  `config.toml`). Fehler beheben, dann `clawbook agenten
  sync`.

## Wenn etwas nicht geht

Erst „Typische Fehler“ oben. Dann `clawbook agenten`:
Unter „Letzter Abgleich“ stehen die Fehler des letzten
Laufs. Im Kurs melden mit der Ausgabe von `clawbook
agenten sync`, aber **nie** mit einem Schlüssel und nie
mit dem Inhalt von `~/.clawbook/secrets` oder
`~/.gemini/config/mcp_config.json`.
