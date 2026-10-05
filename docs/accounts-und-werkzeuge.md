# Accounts und Werkzeuge

Im Image sind die Werkzeuge installiert — die
**Zugänge** dazu bringst du selbst mit. Diese Liste
zeigt für jedes Werkzeug, welchen Account du brauchst,
wie du ihn bekommst und wie du das Werkzeug in deinem
Container in Betrieb nimmst.

Warum nicht fertig eingerichtet: Ein Login gehört dir.
Im Image steckt deshalb kein Zugang, und alles, was du
einrichtest, landet in deinem Home-Verzeichnis (siehe
„Den Arbeitsrechner unter Windows starten",
Abschnitt 6) — es bleibt bei dir und überlebt neue
Image-Versionen.

> **Stand:** im Aufbau. Prüfe die Angebote der
> Anbieter selbst — Preise und Bildungsangebote ändern
> sich.

## Übersicht

| Werkzeug | Account | Kosten für Studierende |
|---|---|---|
| Git, GitHub CLI (`gh`) | GitHub | kostenlos |
| GitHub Copilot CLI (`copilot`) | GitHub mit Copilot-Abo | über das GitHub Student Developer Pack |
| Claude Code (`claude`) | Anthropic (Claude-Abo oder API-Schlüssel) | kostenpflichtig |
| Codex (`codex`) | OpenAI (ChatGPT-Abo oder API-Schlüssel) | kostenpflichtig |
| OpenCode (`opencode`) | Schlüssel eines KI-Anbieters, z.B. OpenRouter | je nach Anbieter |
| OpenRouter (für OpenCode u.a.) | OpenRouter | Guthaben nach Verbrauch, einige Modelle kostenlos |
| Antigravity (`agy`) | Google | Google-Account |
| NotebookLM (`notebooklm`) | Google | Google-Account |
| Google Stitch (MCP) | Google Cloud mit API-Schlüssel | Google-Cloud-Projekt |
| Wiki.js (MCP) | Zugang zur Wiki-Instanz des Kurses | über den Kurs |
| Playwright, Graphify, uv, Node.js, Python | — | kostenlos |

Alle folgenden Befehle gibst du **im Container** ein,
verbunden per SSH als `student`.

## GitHub und `gh`

**Account:** kostenlos auf <https://github.com>.
Für Studierende lohnt das **GitHub Student Developer
Pack** (<https://education.github.com/pack>): Es
enthält unter anderem GitHub Copilot. Die Freischaltung
mit dem Studierenden-Nachweis kann einige Tage dauern.

**Einrichten:**

```bash
git config --global user.name "Vorname Nachname"
git config --global user.email "du@example.org"
gh auth login
```

`gh auth login` fragt nach: GitHub.com, Protokoll
HTTPS, Anmeldung „Login with a web browser". Es zeigt
einen Code; den gibst du unter Windows im Browser auf
der angezeigten Seite ein. Prüfen: `gh auth status`.

## GitHub Copilot CLI

**Account:** GitHub-Account mit aktivem Copilot-Zugang
(für Studierende über das Student Developer Pack).

**Einrichten:**

```bash
copilot
```

Im Programm `/login` eingeben und dem angezeigten
Ablauf im Browser folgen.

## Claude Code

**Account:** ein Claude-Abo bei Anthropic
(<https://claude.ai>) oder ein API-Schlüssel aus der
Anthropic Console. Mit Abo zahlst du einen festen
Betrag, mit API-Schlüssel nach Verbrauch.

**Einrichten:**

```bash
claude
```

Beim ersten Start fragt Claude Code nach der
Anmeldung und zeigt einen Link; im Browser anmelden und
den Code zurück ins Terminal kopieren.

**Wichtig:** Setze die Umgebungsvariable
`ANTHROPIC_API_KEY` nur, wenn du bewusst nach Verbrauch
abrechnen willst. Ist sie gesetzt, nutzt Claude Code
den Schlüssel statt deines Abos — auch dann, wenn
eigentlich ein anderes Werkzeug sie gebraucht hätte.

## Codex

**Account:** ein ChatGPT-Abo bei OpenAI oder ein
OpenAI-API-Schlüssel. Mit Abo zählt die Nutzung gegen
dein ChatGPT-Kontingent.

**Einrichten:**

```bash
codex login --device-auth
```

Es erscheinen ein Link und ein Code; im Browser
anmelden und den Code eingeben.

## OpenCode

**Account:** ein Zugang bei einem KI-Anbieter, den
OpenCode unterstützt (z.B. Anthropic, OpenAI, Google).

**Einrichten:**

```bash
opencode auth login
```

und den Anbieter auswählen. OpenCode speichert den
Zugang in seiner eigenen Konfiguration in deinem
Home-Verzeichnis. Trage API-Schlüssel **nicht** in die
`~/.bashrc` ein — vor allem nicht `ANTHROPIC_API_KEY`
(siehe Claude Code).

## OpenRouter

**Account:** auf <https://openrouter.ai>. OpenRouter
bietet mit **einem** API-Schlüssel Zugang zu vielen
Modellen verschiedener Anbieter; abgerechnet wird nach
Verbrauch über ein Guthaben, das du vorher auflädst.
Einige Modelle sind kostenlos nutzbar.

**Einrichten** für OpenCode:

```bash
opencode auth login
```

und „OpenRouter" als Anbieter wählen, dann den
Schlüssel eingeben. Wie bei allen Schlüsseln: nicht in
die `~/.bashrc` schreiben.

## Antigravity

**Account:** ein Google-Account.

**Einrichten:**

```bash
agy
```

Beim ersten Aufruf führt `agy` durch die Anmeldung bei
Google.

## NotebookLM

**Account:** ein Google-Account; NotebookLM selbst
nutzt du unter <https://notebooklm.google.com>.

**Einrichten:** Die Anmeldung braucht einen Browser.

```bash
notebooklm login
notebooklm-fix-cookies
notebooklm list
```

`notebooklm-fix-cookies` muss nach **jeder** Anmeldung
laufen: Google hat NotebookLM auf eine neue Adresse
umgezogen, das Kommandozeilen-Werkzeug erwartet die
Anmeldedaten aber noch unter der alten. Ohne diesen
Schritt meldet jeder Befehl „Authentication expired",
obwohl die Anmeldung geklappt hat.

`notebooklm login` öffnet den Browser auf dem
Bildschirm des Containers — verbinde dich vorher per
Remote-Desktop (`localhost:3390`, siehe „Den
Arbeitsrechner unter Windows starten", Schritt 5) und
melde dich dort bei Google an.

Die Anmeldung läuft nach einiger Zeit ab; dann die drei
Befehle wiederholen.

## Google Stitch (MCP)

**Account:** ein Google-Cloud-Projekt mit
API-Schlüssel (Google Cloud Console → APIs & Dienste →
Anmeldedaten).

**Einrichten** für Claude Code:

```bash
claude mcp add stitch --transport http \
  --header "X-Goog-Api-Key: <dein-schlüssel>" \
  https://stitch.googleapis.com/mcp
```

Den Schlüssel gibst du nur hier ein; er wird in deiner
Claude-Code-Konfiguration im Home-Verzeichnis
gespeichert.

## Wiki.js (MCP)

**Account:** Im Laufe des Semesters gibt es eine
Wiki.js-Instanz für den Kurs. Adresse und API-Schlüssel
bekommst du dort.

**Einrichten** für Claude Code (Werte aus dem Kurs
einsetzen):

```bash
claude mcp add -s user wikijs \
  -e WIKIJS_URL=https://wiki.example.org \
  -e WIKIJS_API_KEY=<schlüssel-aus-dem-kurs> \
  -- wikijs-mcp-edit
```

Schreibzugriffe auf das Wiki sind nur möglich, wenn
zusätzlich `-e WIKIJS_ENABLE_EDIT=true` gesetzt ist —
ohne diese Angabe kann der Agent nur lesen.

## Playwright

**Account:** keiner. Playwright steuert einen
Browser (Chromium, im Image enthalten) ohne Fenster.

**Einrichten** als Werkzeug für Claude Code:

```bash
claude mcp add playwright -- playwright-mcp --headless
```

Für einzelne Aufgaben ist das Kommandozeilen-Werkzeug
`playwright-cli` sparsamer als der MCP-Server: Es
braucht deutlich weniger Kontext des Agenten.

## Graphify

**Account:** keiner. Graphify baut aus Code und
Dokumenten einen Wissensgraphen.

**Einrichten** für Claude Code:

```bash
graphify install --platform claude
```

Für andere Agenten gibt es `--platform codex`,
`--platform opencode` und `--platform antigravity`.

## Node.js, Python, uv

Kein Account nötig. `node`, `npm`, `python`, `uv` und
`pipx` sind installiert; eigene Pakete installierst du
in dein Home-Verzeichnis oder in Projekt-Umgebungen
(`uv venv`), dann bleiben sie bei Image-Updates
erhalten.
