# Ohne Account: Playwright, Graphify, uv, Node.js, Python, wsm

Stand: 2026-10-12

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> suchen Sie den aktuellen Weg bitte selbst auf der
> Seite des Anbieters.

Diese Werkzeuge brauchen keinen Zugang bei einem
Anbieter. Sie sind im Image installiert und
funktionieren sofort. Zwei davon — Playwright und
Graphify — melden Sie einmal bei Claude Code an,
damit der Agent sie benutzen kann (den Skill für
`playwright-cli` richtet der Container schon selbst
ein); das dauert eine Minute und steht hier Schritt
für Schritt.

**Kosten:** keine. (Graphify nutzt für Dokumente das
Modell Ihres Agenten, also dessen Kontingent.)

## Beim Anbieter

Nichts zu tun.

## Im clawbook

### Playwright: Browser für den Agenten

Playwright steuert einen Browser ohne Fenster
(Chromium ist im Image). Damit kann ein Agent
Webseiten lesen, Formulare ausfüllen, Screenshots
machen. Es gibt zwei Wege, und der erste ist der
sparsamere:

**`playwright-cli`** — ein Kommandozeilen-Werkzeug,
das der Agent wie jeden anderen Befehl aufruft. Es
belastet den Kontext des Agenten (seinen
„Arbeitsspeicher" an Text) deutlich weniger als der
MCP-Server, weil keine großen Werkzeugbeschreibungen
geladen werden. Claude Code erfährt davon über einen
**Skill** — eine kurze Anleitung. Den richtet der
Container beim ersten Start einmal in Ihrem
Home-Verzeichnis ein (`~/.claude/skills/playwright-cli`,
dazu `~/.playwright/cli.config.json` mit Chromium als
Browser); Claude Code findet ihn damit in jedem
Projekt. Sie müssen nichts tun.

Von Hand brauchen Sie den Befehl nur, wenn Sie den
Skill gelöscht haben (im Home) oder ihn in einem
einzelnen Projekt haben wollen (im Projektordner):

```bash
cd ~                       # oder: cd ~/source/<Bereich>/<Projekt>
playwright-cli install --skills
```

Danach reicht es, den Agenten zu bitten: „Öffne mit
playwright-cli die Seite … und sag mir, was dort
steht." (Den Agenten dürfen Sie duzen.) Von Hand sieht das so aus:

```bash
playwright-cli open https://example.org
playwright-cli snapshot        # Seite als Text mit Element-Kennungen
playwright-cli close
```

**Playwright-MCP** — der MCP-Server, wenn der Agent
länger auf einer Seite arbeiten soll und den Zustand
zwischen Schritten halten muss. Für Claude Code
eintragen:

```bash
claude mcp add -s user playwright -- playwright-mcp --headless
```

`--headless` heißt: ohne Fenster. Ohne diese Option
würde Playwright ein Browserfenster auf dem Bildschirm
des Containers öffnen — das ist nur zum Zuschauen per
Remote-Desktop nützlich. Dasselbe gilt für
`playwright-cli open --headed …`: Das Fenster erscheint
auf dem Bildschirm des Containers (siehe
[Installation](../installation.md), Abschnitt 6).

Beide Werkzeuge nähmen von sich aus Google Chrome, das
im Image fehlt. Die Variable
`PLAYWRIGHT_MCP_BROWSER=chromium` (im Image gesetzt)
stellt sie auf das mitgelieferte Chromium um.

### Graphify: Wissensgraph aus Code und Dokumenten

Graphify liest ein Projekt (Code, Markdown, PDF) und
baut daraus einen Graphen aus Begriffen und ihren
Beziehungen, den der Agent dann befragen kann. Code
wird lokal zerlegt, ohne Modell; für Dokumente nutzt
Graphify das Modell des Agenten, in dem es läuft. Für
Claude Code eintragen:

```bash
graphify install --platform claude
```

Danach gibt es in Claude Code den Befehl
`/graphify .`, der den Graphen des aktuellen
Projektordners nach `graphify-out/` schreibt. Für
andere Agenten:

```bash
graphify install --platform codex
graphify install --platform opencode
graphify install --platform antigravity
```

Auch ohne Agent, im Projektordner:

```bash
cd ~/source/<Bereich>/<Projekt>
graphify .                       # Graph bauen
graphify explain "<Begriff>"     # einen Knoten erklären
graphify path "<Begriff A>" "<Begriff B>"
```

### uv, Python, Node.js

Alles installiert und direkt nutzbar:

```bash
python --version
uv --version
node --version
npm --version
```

**Eigene Pakete** installieren Sie nicht ins System,
sondern in Ihr Projekt oder Ihr Home-Verzeichnis.
Grund: Das System liegt im Image und wird bei einer
neuen Image-Version ersetzt; Ihr Home-Verzeichnis
bleibt.

Python-Projekt mit `uv` (schneller Ersatz für `pip`
und `venv`):

```bash
cd ~/source/<Bereich>/<Projekt>
uv init          # nur bei neuem Projekt: pyproject.toml anlegen
uv add requests  # Abhängigkeit hinzufügen
uv run python main.py
```

`uv` legt dabei eine virtuelle Umgebung `.venv` im
Projekt an, ein eigener Python-Ordner nur für dieses
Projekt. Ein Python-Werkzeug für überall (zum Beispiel
ein Linter):

```bash
uv tool install ruff
```

Node.js-Projekt:

```bash
cd ~/source/<Bereich>/<Projekt>
npm init -y
npm install <paket>
```

`npm install -g` (global) vermeiden; global
installierte Pakete liegen im Image und gehen beim
nächsten Image-Update verloren.

### WorkspaceManager wsm

`wsm` verwaltet Ihre Projekte: Er legt sie unter
`~/source` an, erzeugt das Repository auf GitHub
(über `gh`), startet Claude Code darin in einer
tmux-Sitzung und wandelt mit `wsm update` Dokumente
aus `raw/` um (dafür braucht er den Docling-Server des
Kurses, siehe [Kurs-Dienste](kurs-dienste.md)).

**Zuerst [GitHub](github.md) einrichten**, dann `wsm`
zum ersten Mal starten. Grund: Beim ersten Start liest
`wsm` Ihren GitHub-Benutzernamen aus `gh` sowie Name
und E-Mail aus `git config` und schreibt sie in
`~/.workspacemanager.yml`. Die GitHub-Anmeldung bietet
Ihnen der Container schon beim ersten `ssh clawbook`
an. Haben Sie sie übersprungen, fragt `wsm` beim
ersten Start zuerst danach („1 Jetzt bei GitHub
anmelden (empfohlen)" oder „2 Abbrechen"). Brechen Sie
ab, warnt `wsm`, dass sonst „student" als GitHub-Name
eingetragen wird, und fragt „Trotzdem mit wsm
fortfahren? [j/N]". Enter heißt nein: `wsm` startet
nicht, und Sie melden sich mit `clawbook github login`
an. Mit `j` geht es weiter — dann fragt `wsm` nach dem
Benutzernamen und trägt ohne Eingabe `student` ein,
also einen falschen Namen, und das Anlegen von
Repositories auf GitHub scheitert. Passiert das doch,
tragen Sie den richtigen Namen unter `locations → git → user` in die
Datei ein (`code ~/.workspacemanager.yml` im
VS-Code-Terminal).

```bash
wsm            # Menü
wsm --help     # alle Befehle
```

Die Einstellungen liegen in `~/.workspacemanager.yml`;
voreingestellt sind Bereiche unter `~/source`, etwa
`~/source/github` für eigene Projekte, `~/source/samples`
und `~/source/sandbox`.

**Ältere Konfiguration:** Hat eine frühere Version von
`wsm` die Datei angelegt, kennt sie nur den einen Ordner
`~/source`. Das erkennt der Container und fragt einmal —
im `clawbook`-Menü nach der GitHub-Prüfung oder beim
nächsten Start von `wsm`: „Ihre
WorkspaceManager-Konfiguration (~/.workspacemanager.yml)
ist veraltet … Konfiguration jetzt erneuern? [J/n]".
Mit Enter wird die alte Datei als
`~/.workspacemanager.yml.alt-<Datum>` gesichert, und
`wsm` schreibt seine neue Standard-Konfiguration mit
Ihrem GitHub-Namen. Ihre Projekte unter `~/source`
bleiben, wo sie sind; eigene Änderungen aus der alten
Datei (etwa eine Docling-Adresse) übertragen Sie von
Hand. Mit `n` bleibt alles, wie es ist, und die Frage
kommt nicht wieder; später erneuern Sie mit
`clawbook wsm erneuern`. Die Erneuerung braucht die
GitHub-Anmeldung. Eine
tmux-Sitzung, die `wsm` gestartet hat, verlassen Sie mit
`Strg+B`, dann `D` — sie läuft weiter (siehe
[Übersicht](README.md), „Wie Sie ein Programm wieder
verlassen").

Hinweis zur Zwischenablage: `wsm` kann unter Windows
Dateien aus der Zwischenablage nach `raw/` übernehmen.
Im Container geht das nicht — Programme im Container
sehen die Windows-Zwischenablage nicht. Davon
unberührt ist das Kopieren und Einfügen von **Text im
Terminal**, das funktioniert. Dateien für `raw/`
legen Sie direkt dort ab, zum Beispiel per Ziehen in
den Explorer von VS Code oder über den
Austauschordner (siehe [Installation](../installation.md),
Abschnitt 7).

## Prüfen

```bash
clawbook check
```

zeigt jede Zeile mit Version — `playwright-cli`,
`playwright-mcp`, `graphify`, `python`, `uv`, `node`
müssen dabei sein. Außerdem:

```bash
claude mcp list        # playwright: Connected
wsm config --validate  # Konfiguration gültig
```

In Claude Code zeigt `/mcp` den Playwright-Server und
`/graphify` erscheint in der Befehlsliste, wenn Sie
`/` tippen.

## Typische Fehler

- **`claude mcp list` zeigt `playwright` als „Failed
  to connect"** → Eintrag prüfen mit
  `claude mcp get playwright`: der Befehl muss
  `playwright-mcp` mit `--headless` sein. Entfernen
  (`claude mcp remove -s user playwright`) und neu
  anlegen.
- **Der Browser startet nicht („Executable doesn't
  exist", „is not installed" oder „Chromium
  distribution 'chrome' is not found")** → Chromium für
  Playwright liegt im Image unter `/opt/ms-playwright`.
  `env | grep PLAYWRIGHT` prüfen:
  `PLAYWRIGHT_BROWSERS_PATH` muss `/opt/ms-playwright`
  sein, `PLAYWRIGHT_MCP_BROWSER` muss `chromium` sein.
  Fehlt die zweite Variable oder meldet
  `playwright-cli install --skills` „permission denied"
  für `/opt/ms-playwright`, ist das Image älter als die
  Korrektur dieses Fehlers: Image aktualisieren
  ([Pflege](../pflege.md), Abschnitt 3).
- **`/graphify` fehlt in Claude Code** →
  `graphify install --platform claude` noch nicht
  ausgeführt, oder Claude Code lief dabei noch. Claude
  Code beenden (`/exit`) und neu starten.
- **`graphify .` bricht bei PDFs ab oder fragt nach
  einem Schlüssel** → Für Dokumente braucht Graphify
  ein Modell. Nutzen Sie `/graphify .` innerhalb von
  Claude Code (dann nimmt es dessen Modell) statt
  `graphify .` von der Kommandozeile.
- **`pip install` meldet „externally-managed-environment"**
  → Debian schützt das System-Python. Nehmen Sie
  `uv add` im Projekt oder `uv tool install` für Werkzeuge.
- **`wsm` meldet „Konfigurationsdatei nicht
  gefunden"** → Die Datei wurde gelöscht. `wsm`
  erneut starten; es legt sie neu an. Oder
  `wsm config --init` für die Abfrage aller Werte.
- **`wsm` kann kein Repository auf GitHub anlegen** →
  `clawbook github status` prüfen (siehe
  [GitHub](github.md)) und den Benutzernamen in
  `~/.workspacemanager.yml` mit Ihrem GitHub-Namen
  vergleichen.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben, dann `clawbook check`:
Steht dort `FEHLT`, liegt es am Image — melden. Sonst
`claude mcp list`, `claude mcp get playwright` und
`wsm config --validate`. Bei `wsm` hilft oft schon ein
Blick in `~/.workspacemanager.yml` (GitHub-Name,
Einrückung). Im Kurs melden mit Befehl und
vollständiger Meldung.
