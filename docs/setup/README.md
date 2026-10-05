# Zugänge einrichten: Übersicht

Stand: 2026-10-05

Im clawbook sind die Werkzeuge schon installiert. Was
fehlt, sind die **Zugänge**: Accounts, Logins und
Schlüssel bei den Anbietern der KI-Dienste. Die
gehören dir, deshalb stecken sie nicht im Image. Du
richtest sie einmal ein; sie landen in deinem
Home-Verzeichnis und bleiben auch dann erhalten, wenn
du eine neue Version des Images startest (siehe
[Pflege](../pflege.md), Abschnitt 4).

Diese Seite sagt dir, welche Accounts du wofür
brauchst, was sie kosten, in welcher Reihenfolge du am
besten vorgehst und was die wichtigsten Begriffe
bedeuten. Die Einzelheiten stehen auf je einer Seite
pro Anbieter.

Die Webseiten der Anbieter ändern sich: Menüpfade und
Bezeichnungen auf den Setup-Seiten gelten zum
genannten Stand und können inzwischen etwas anders
heißen.

## Begriffe, die auf allen Seiten vorkommen

Die Grundbegriffe — Container, Image, Volume,
Home-Verzeichnis und `~`, Terminal, SSH, Port,
WSL/WSLC, Remotedesktop — erklärt die
[Übersicht der Anleitungen](../README.md#begriffe).
Hier nur, was bei den Zugängen dazukommt:

- **Agent** — ein KI-Programm, das nicht nur
  antwortet, sondern handelt: Dateien liest und
  ändert, Befehle ausführt. Claude Code, Codex, Copilot
  CLI, OpenCode und Antigravity sind Agenten. Starte
  sie deshalb in einem Projektordner, nicht irgendwo.
- **Repository, Commit** — ein Repository ist ein
  Projektordner, dessen Geschichte `git` aufzeichnet;
  ein Commit ist ein gespeicherter Stand mit deinem
  Namen daran. GitHub lagert Repositories im Netz.
- **API-Schlüssel, Token** — eine lange Zeichenkette,
  mit der sich ein Programm bei einem Dienst in deinem
  Namen anmeldet, oft auf deine Kosten. Ein Token ist
  dasselbe Prinzip, meist mit Ablaufdatum. Beides
  behandelst du wie ein Passwort.
- **Abo oder nach Verbrauch** — ein Abo kostet einen
  festen Betrag im Monat und enthält ein Kontingent,
  das sich regelmäßig erneuert. Beim Bezahlen nach
  Verbrauch („API-Guthaben", „Credits") lädst du
  Guthaben auf, und jede Anfrage zieht davon ab — je
  nach Modell und Textmenge. Das Abo ist planbar, das
  Guthaben flexibel; mit einem Agenten, der viel Text
  verarbeitet, ist Guthaben schnell teurer.
- **Umgebungsvariable** — ein benannter Wert in deiner
  Terminal-Sitzung, den jedes dort gestartete Programm
  lesen kann, zum Beispiel `DISPLAY`. Variablen, die in
  `~/.bashrc` gesetzt werden, gelten in jeder neuen
  Sitzung — deshalb gehören Schlüssel nicht dorthin.
- **Skill** — eine kurze Anleitung, die ein Agent
  liest, um ein Werkzeug richtig zu benutzen (zum
  Beispiel `/notebooklm`, `/graphify`). Sie liegt als
  Datei in deinem Home-Verzeichnis.
- **MCP-Server** — ein Dienst, der einem Agenten
  zusätzliche Werkzeuge anbietet (im Wiki suchen,
  Webseiten öffnen, Oberflächen entwerfen). Du trägst
  ihn einmal bei Claude Code ein, danach nutzt der
  Agent ihn selbst.
- **tmux** — ein Programm, das mehrere
  Terminal-Sitzungen im Container am Leben hält, auch
  wenn deine Verbindung abbricht. `wsm` startet
  Agenten darin.

## Wo du die Befehle eingibst

Alle Befehle in den Setup-Seiten gibst du **im
Container** ein, als Benutzer `student`. Dafür gibt es
zwei Wege, die beide in der
[Installation](../installation.md) beschrieben sind:

- das Terminal in VS Code, nachdem du dich per
  „Remote - SSH" mit dem Host `clawbook` verbunden hast
  (Menü „Terminal → New Terminal"; unten links steht
  „SSH: clawbook"), oder
- PowerShell unter Windows, darin `ssh clawbook`.

Woran du erkennst, wo du bist: Im Container beginnt
die Eingabeaufforderung mit `student@…`; in PowerShell
mit `PS C:\…`. Befehle für den Container stehen auf
diesen Seiten in `bash`-Blöcken, Befehle für Windows
in `powershell`-Blöcken. Meldet `ssh clawbook`
„Connection refused", läuft der Container nicht —
starte ihn wie in [Pflege](../pflege.md), Abschnitt 1.

## So klappt die Anmeldung im Browser

Fast alle Werkzeuge melden dich über eine Webseite an.
Weil der Container kein Browserfenster vor dir öffnen
kann, zeigen sie einen **Link** und meist einen
**Code** im Terminal. Du öffnest den Link in deinem
Browser unter Windows, meldest dich an, gibst den Code
ein — oder kopierst einen Code zurück ins Terminal.

Kopieren und Einfügen im Terminal:

- **PowerShell oder Windows Terminal:** Text mit der
  Maus markieren — das kopiert ihn schon. Ein
  Rechtsklick fügt den Inhalt der Zwischenablage ein.
- **VS-Code-Terminal:** Strg gedrückt halten und auf
  den Link klicken, dann öffnet er sich im Browser.
  Sonst markieren und `Strg+Umschalt+C` kopieren,
  `Strg+Umschalt+V` einfügen (ohne Umschalt wäre es
  im Terminal ein anderer Befehl).
- Lange Links werden im Terminal **umbrochen**.
  Markiere sie bis zum letzten Zeichen, sonst fehlt ein
  Stück und die Seite meldet einen Fehler.

Nur NotebookLM braucht den Browser **im Container**;
dafür gibt es den Bildschirm per Remote-Desktop, siehe
[Google](google.md).

## Wie du ein Programm wieder verlässt

- Agenten (`claude`, `codex`, `copilot`, `opencode`,
  `agy`): `/exit` eingeben; notfalls zweimal `Strg+C`.
- tmux-Sitzung (zum Beispiel von `wsm` gestartet):
  `Strg+B`, loslassen, dann `D` — die Sitzung läuft im
  Hintergrund weiter, du kommst zurück ins Terminal.
- Terminal im Container: `exit` beendet die
  SSH-Verbindung; der Container läuft weiter.

## Welche Accounts wofür

| Account | Werkzeuge im clawbook | Kosten für Studierende (Stand 2026-10-05) |
|---|---|---|
| [GitHub](github.md) | `git`, `gh`, Copilot CLI (`copilot`), `wsm` (legt Repositories an) | kostenlos; Copilot kostenlos über den Plan „Copilot Student" des GitHub Student Developer Pack |
| [Anthropic](anthropic.md) | Claude Code (`claude`) | kostenpflichtig: Abo Claude Pro oder Max, oder Guthaben nach Verbrauch; kein eigener Studierenden-Rabatt |
| [OpenAI](openai.md) | Codex (`codex`) | ChatGPT-Konto; schon der kostenlose Plan enthält laut OpenAI ein Codex-Kontingent, mehr mit Go/Plus/Pro |
| [OpenRouter](openrouter.md) | OpenCode und andere Werkzeuge mit OpenAI-kompatiblem Zugang | Guthaben nach Verbrauch; einige Modelle kostenlos mit Tageslimit |
| [OpenCode](opencode.md) | OpenCode (`opencode`) | kein eigener Account — nutzt einen der Zugänge oben |
| [Google](google.md) | Antigravity (`agy`), NotebookLM (`notebooklm`), Stitch (MCP) | Google-Konto; kostenlose Stufen für alle drei; ein Jahr Google AI Plus gratis für Studierende |
| [Kurs-Dienste](kurs-dienste.md) | Wiki.js-MCP, Docling für `wsm update` | Adresse und Schlüssel bekommst du im Kurs |
| [Ohne Account](ohne-account.md) | Playwright, Graphify, `uv`, Node.js, Python, `wsm` | kostenlos |

**Du musst nichts kaufen, um anzufangen.** Zum
Ausprobieren genügen die kostenlosen Wege: Copilot CLI
nach Freischaltung des Studierenden-Plans, Codex mit
dem kostenlosen ChatGPT-Plan, Antigravity und
NotebookLM mit einem Google-Konto, OpenRouter mit
`:free`-Modellen. Welche Werkzeuge im Kurs
verpflichtend sind und ob die Hochschule Zugänge
stellt, sagt dir die Kursleitung. Preise und Angebote
ändern sich; jede Anbieter-Seite nennt Quelle und
Datum — prüfe vor einer Zahlung die Seite des
Anbieters.

Wenn du etwas Kostenpflichtiges abschließt, gilt auf
allen Seiten dasselbe:

- **Abos verlängern sich automatisch.** Trag dir das
  Kündigungsdatum in den Kalender ein; wie du kündigst,
  steht auf der jeweiligen Seite.
- **Bei Guthaben nach Verbrauch:** automatisches
  Nachladen ausschalten und ein Ausgabenlimit setzen.
  Dann ist der höchste mögliche Schaden das, was du
  eingezahlt hast.

## Empfohlene Reihenfolge

1. **[GitHub](github.md)** — zuerst, weil `git` und
   `gh` die Basis für alles andere sind, weil `wsm`
   deinen GitHub-Namen beim ersten Start aus `gh`
   übernimmt (sonst steht dort ein falscher Name) und
   weil der Studierenden-Antrag ein paar Tage dauern
   kann. Stelle ihn gleich am Anfang.
2. **Ein Coding-Agent.** Im Kurs arbeiten wir vor
   allem mit **Claude Code**; die Anleitungen zu den
   MCP-Diensten (Stitch, Wiki.js, Playwright) sind
   dafür geschrieben. Dafür brauchst du
   [Anthropic](anthropic.md). Wer erst einmal nichts
   ausgeben will, startet mit der Copilot CLI aus dem
   Student Developer Pack ([GitHub](github.md)) oder
   mit Codex ([OpenAI](openai.md)).
3. **[Google](google.md)** — Antigravity und
   NotebookLM sind mit einem Google-Konto kostenlos
   nutzbar; Stitch brauchst du erst, wenn es um
   Oberflächen-Entwürfe geht.
4. **Optional:** [OpenRouter](openrouter.md) und
   [OpenCode](opencode.md), wenn du mehrere Modelle
   verschiedener Anbieter ausprobieren willst.
5. **[Kurs-Dienste](kurs-dienste.md)** — sobald du
   Adresse und Schlüssel im Kurs bekommen hast.
6. **[Ohne Account](ohne-account.md)** — Playwright
   und Graphify als Werkzeuge für Claude Code
   eintragen; das dauert eine Minute.

## Drei Regeln für Schlüssel und Zugänge

1. **Nie in `~/.bashrc` eintragen.** Jedes Werkzeug
   hat einen eigenen Ort für seinen Zugang (zum
   Beispiel `~/.claude`, `~/.codex`, `~/.config/gh`,
   `~/.local/share/opencode`). Dort gehört er hin, und
   dort fragen die Setup-Seiten ihn ab. Ein Schlüssel
   in `~/.bashrc` gilt für alle Programme in jeder
   Sitzung — auch für solche, die ihn gar nicht
   bekommen sollen. Besonders `ANTHROPIC_API_KEY`:
   Ist die Variable gesetzt, nimmt Claude Code den
   Schlüssel statt deines Abos und rechnet pro Token
   ab (siehe [Anthropic](anthropic.md)).
2. **Nie im Befehl tippen.** Alles, was du im Terminal
   eingibst, landet in der Befehlshistorie
   (`~/.bash_history`). Wo ein Schlüssel in einen
   Befehl gehört, nutzen die Seiten dieses Muster:

   ```bash
   read -rs KEY
   ```

   Nach Enter wartet das Terminal, ohne etwas
   anzuzeigen. Füge den Schlüssel ein (er bleibt
   unsichtbar) und drücke Enter. Im folgenden Befehl
   steht dann `"$KEY"` statt des Schlüssels, und zum
   Schluss löscht `unset KEY` die Variable wieder.
3. **Nie weitergeben.** Die Dateien mit deinen
   Zugängen — `~/.claude.json`,
   `~/.claude/.credentials.json`,
   `~/.codex/auth.json`, `~/.config/gh/`,
   `~/.local/share/opencode/auth.json`, `~/.notebooklm/`
   — gehören nie in ein Repository (`git add` prüfen),
   nie in eine Hilfe-Anfrage, nie in einen Chat. Wer
   sie hat, arbeitet auf deine Rechnung. Und umgekehrt:
   Lade keine Daten anderer Personen und keine
   Prüfungsunterlagen in KI-Dienste, ohne dass der Kurs
   das ausdrücklich vorsieht.

## Wenn du prüfen willst, was eingerichtet ist

```bash
clawbook-check        # sind alle Werkzeuge da?
gh auth status        # GitHub
claude mcp list       # MCP-Dienste für Claude Code
opencode auth list    # Anbieter in OpenCode
```

Die Werkzeuge selbst meldest du mit den Befehlen auf
den jeweiligen Seiten an; dort steht auch, woran du
erkennst, dass es geklappt hat.

## Wenn etwas nicht geht

Jede Anbieter-Seite hat einen Abschnitt „Typische
Fehler" mit Symptom und Lösung — dort zuerst
nachsehen. Danach in dieser Reihenfolge:

1. Bist du im Container (`student@…`) oder in
   PowerShell? Die Befehle der Setup-Seiten gelten nur
   im Container.
2. `clawbook-check` — fehlt ein Werkzeug, liegt es am
   Image, nicht an dir: melden.
3. Hilfe im Kurs holen. Nenne dabei die Seite, den
   genauen Befehl und die vollständige Fehlermeldung —
   aber **nie** einen Schlüssel, Code aus einer
   Anmeldung oder den Inhalt einer Zugangsdatei.
