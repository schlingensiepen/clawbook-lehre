# Ohne Account: Playwright, Graphify, uv, Node.js, Python, wsm

Stand: 2026-10-05

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> such dir den aktuellen Weg auf der Seite des Anbieters
> selbst.

Diese Werkzeuge brauchen keinen Zugang bei einem
Anbieter. Sie sind im Image installiert und
funktionieren sofort. Zwei davon — Playwright und
Graphify — musst du einmal bei Claude Code anmelden,
damit der Agent sie benutzen kann; das dauert eine
Minute und steht hier Schritt für Schritt.

**Kosten:** keine. (Graphify nutzt für Dokumente das
Modell deines Agenten, also dessen Kontingent.)

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
**Skill** — eine kurze Anleitung, die du einmal
installierst:

```bash
playwright-cli install --skills
```

Danach reicht es, den Agenten zu bitten: „Öffne mit
playwright-cli die Seite … und sag mir, was dort
steht." Von Hand sieht das so aus:

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
Remote-Desktop nützlich.

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
cd ~/source/<Thema>/<Projekt>
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

**Eigene Pakete** installierst du nicht ins System,
sondern in dein Projekt oder dein Home-Verzeichnis.
Grund: Das System liegt im Image und wird bei einer
neuen Image-Version ersetzt; dein Home-Verzeichnis
bleibt.

Python-Projekt mit `uv` (schneller Ersatz für `pip`
und `venv`):

```bash
cd ~/source/<Thema>/<Projekt>
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
cd ~/source/<Thema>/<Projekt>
npm init -y
npm install <paket>
```

`npm install -g` (global) vermeiden; global
installierte Pakete liegen im Image und gehen beim
nächsten Image-Update verloren.

### WorkspaceManager wsm

`wsm` verwaltet deine Projekte: Er legt sie unter
`~/source` an, erzeugt das Repository auf GitHub
(über `gh`), startet Claude Code darin in einer
tmux-Sitzung und wandelt mit `wsm update` Dokumente
aus `raw/` um (dafür braucht er den Docling-Server des
Kurses, siehe [Kurs-Dienste](kurs-dienste.md)).

**Zuerst [GitHub](github.md) einrichten**, dann `wsm`
zum ersten Mal starten. Grund: Beim ersten Start liest
`wsm` deinen GitHub-Benutzernamen aus `gh` sowie Name
und E-Mail aus `git config` und schreibt sie in
`~/.workspacemanager.yml`. Ist `gh` noch nicht
angemeldet, fragt `wsm` einmal nach dem Benutzernamen
und schlägt `student` vor — dann steht ein falscher
Name in der Datei, und das Anlegen von Repositories
auf GitHub scheitert. Passiert das doch, trägst du den
richtigen Namen unter `locations → git → user` in die
Datei ein (`code ~/.workspacemanager.yml` im
VS-Code-Terminal).

```bash
wsm            # Menü
wsm --help     # alle Befehle
```

Die Einstellungen liegen in `~/.workspacemanager.yml`;
der Speicherort `~/source` ist voreingestellt. Eine
tmux-Sitzung, die `wsm` gestartet hat, verlässt du mit
`Strg+B`, dann `D` — sie läuft weiter (siehe
[Übersicht](README.md), „Wie du ein Programm wieder
verlässt").

Hinweis zur Zwischenablage: `wsm` kann unter Windows
Dateien aus der Zwischenablage nach `raw/` übernehmen.
Im Container geht das nicht — Programme im Container
sehen die Windows-Zwischenablage nicht. Davon
unberührt ist das Kopieren und Einfügen von **Text im
Terminal**, das funktioniert. Dateien für `raw/`
legst du direkt dort ab, zum Beispiel per Ziehen in
den Explorer von VS Code oder über den
Austauschordner (siehe [Installation](../installation.md),
Abschnitt 7).

## Prüfen

```bash
clawbook-check
```

zeigt jede Zeile mit Version — `playwright-cli`,
`playwright-mcp`, `graphify`, `python`, `uv`, `node`
müssen dabei sein. Außerdem:

```bash
claude mcp list        # playwright: Connected
wsm config --validate  # Konfiguration gültig
```

In Claude Code zeigt `/mcp` den Playwright-Server und
`/graphify` erscheint in der Befehlsliste, wenn du
`/` tippst.

## Typische Fehler

- **`claude mcp list` zeigt `playwright` als „Failed
  to connect"** → Eintrag prüfen mit
  `claude mcp get playwright`: der Befehl muss
  `playwright-mcp` mit `--headless` sein. Entfernen
  (`claude mcp remove -s user playwright`) und neu
  anlegen.
- **Der Browser startet nicht („Executable doesn't
  exist")** → Chromium für Playwright liegt im Image
  unter `/opt/ms-playwright`. Diese Meldung erscheint,
  wenn jemand `playwright install` im Home-Verzeichnis
  ausgeführt oder die Variable
  `PLAYWRIGHT_BROWSERS_PATH` überschrieben hat.
  `env | grep PLAYWRIGHT` prüfen; der Wert muss
  `/opt/ms-playwright` sein.
- **`/graphify` fehlt in Claude Code** →
  `graphify install --platform claude` noch nicht
  ausgeführt, oder Claude Code lief dabei noch. Claude
  Code beenden (`/exit`) und neu starten.
- **`graphify .` bricht bei PDFs ab oder fragt nach
  einem Schlüssel** → Für Dokumente braucht Graphify
  ein Modell. Nutze `/graphify .` innerhalb von Claude
  Code (dann nimmt es dessen Modell) statt `graphify .`
  von der Kommandozeile.
- **`pip install` meldet „externally-managed-environment"**
  → Debian schützt das System-Python. Nimm `uv add`
  im Projekt oder `uv tool install` für Werkzeuge.
- **`wsm` meldet „Konfigurationsdatei nicht
  gefunden"** → Die Datei wurde gelöscht. `wsm`
  erneut starten; es legt sie neu an. Oder
  `wsm config --init` für die Abfrage aller Werte.
- **`wsm` kann kein Repository auf GitHub anlegen** →
  `gh auth status` prüfen (siehe [GitHub](github.md))
  und den Benutzernamen in `~/.workspacemanager.yml`
  mit deinem GitHub-Namen vergleichen.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben, dann `clawbook-check`:
Steht dort `FEHLT`, liegt es am Image — melden. Sonst
`claude mcp list`, `claude mcp get playwright` und
`wsm config --validate`. Bei `wsm` hilft oft schon ein
Blick in `~/.workspacemanager.yml` (GitHub-Name,
Einrückung). Im Kurs melden mit Befehl und
vollständiger Meldung.
