# Zugänge einrichten: Übersicht

Stand: 2026-10-12

Im clawbook sind die Werkzeuge schon installiert. Was
fehlt, sind die **Zugänge**: Accounts, Logins und
Schlüssel bei den Anbietern der KI-Dienste. Die
gehören Ihnen, deshalb stecken sie nicht im Image. Sie
richten sie einmal ein; sie landen in Ihrem
Home-Verzeichnis und bleiben auch dann erhalten, wenn
Sie eine neue Version des Images starten (siehe
[Pflege](../pflege.md), Abschnitt 3).

Diese Seite sagt Ihnen, welche Accounts Sie wofür
brauchen, was sie kosten, in welcher Reihenfolge Sie
am besten vorgehen und was die wichtigsten Begriffe
bedeuten. Die Einzelheiten stehen auf je einer Seite
pro Anbieter.

Werkzeuge für einzelne Lehrveranstaltungen — etwa Java,
.NET, Datenbanken oder PlatformIO für den ESP32 — sind
nicht von Anfang an im Image. Sie kommen mit einem
**Kurs**, den Sie hinzufügen: im Verwaltungs-Skript mit
Menüpunkt [11] „Kurse und Technikpakete" oder nach
`ssh clawbook` im clawbook-Menü (Punkt 6). Einen Account
brauchen Sie dafür nicht. Wie das geht, steht in
[Kurse und Technikpakete](../kurse-und-pakete.md). Nicht
verwechseln mit den [Kurs-Diensten](kurs-dienste.md)
weiter unten: Das sind Zugänge zu Diensten, die zentral
im Kurs laufen (Wiki.js und Docling).

Jede Setup-Seite kennzeichnet ihre Schritte auf drei
Arten:

- **Das erledigt clawbook** — passiert von selbst; die
  Seite sagt, woran Sie den Erfolg sehen.
- **Das tun Sie selbst** — geht nicht automatisch, etwa
  ein Konto anlegen oder einen Schlüssel beim Anbieter
  erzeugen (meist im Abschnitt „Beim Anbieter“).
- **Falls die Automatik nicht geht** — nur nötig, wenn
  etwas schiefgeht oder Sie es bewusst von Hand machen.

Die Webseiten der Anbieter ändern sich: Menüpfade und
Bezeichnungen auf den Setup-Seiten gelten zum
genannten Stand und können inzwischen etwas anders
heißen.

## Zuerst: GitHub

Beginnen Sie mit **[GitHub](github.md)**. Die
Anmeldung bei GitHub kommt im Container sogar von
selbst: Beim ersten `ssh clawbook` fragt der Container
danach, noch bevor das clawbook-Menü erscheint. Halten
Sie dafür Ihr GitHub-Konto bereit; wie die Anmeldung
abläuft, steht auf der [GitHub-Seite](github.md).

Erst danach starten Sie den WorkspaceManager `wsm`: Er
übernimmt beim ersten Start Ihren GitHub-Namen. Die
Reihenfolge aller Accounts steht unten unter
„Empfohlene Reihenfolge".

## Begriffe, die auf allen Seiten vorkommen

Die Grundbegriffe — Container, Image, Volume,
Home-Verzeichnis und `~`, Terminal, SSH, Port,
WSL/WSLC, Remotedesktop — erklärt die
[Übersicht der Anleitungen](../README.md#begriffe).
Hier nur, was bei den Zugängen dazukommt:

- **Agent** — ein KI-Programm, das nicht nur
  antwortet, sondern handelt: Dateien liest und
  ändert, Befehle ausführt. Claude Code, Codex, Copilot
  CLI, OpenCode und Antigravity sind Agenten. Starten
  Sie sie deshalb in einem Projektordner, nicht
  irgendwo.
- **Repository, Commit** — ein Repository ist ein
  Projektordner, dessen Geschichte `git` aufzeichnet;
  ein Commit ist ein gespeicherter Stand mit Ihrem
  Namen daran. GitHub lagert Repositories im Netz.
- **API-Schlüssel, Token** — eine lange Zeichenkette,
  mit der sich ein Programm bei einem Dienst in Ihrem
  Namen anmeldet, oft auf Ihre Kosten. Ein Token ist
  dasselbe Prinzip, meist mit Ablaufdatum. Beides
  behandeln Sie wie ein Passwort.
- **Abo oder nach Verbrauch** — ein Abo kostet einen
  festen Betrag im Monat und enthält ein Kontingent,
  das sich regelmäßig erneuert. Beim Bezahlen nach
  Verbrauch („API-Guthaben", „Credits") laden Sie
  Guthaben auf, und jede Anfrage zieht davon ab — je
  nach Modell und Textmenge. Das Abo ist planbar, das
  Guthaben flexibel; mit einem Agenten, der viel Text
  verarbeitet, ist Guthaben schnell teurer.
- **Umgebungsvariable** — ein benannter Wert in Ihrer
  Terminal-Sitzung, den jedes dort gestartete Programm
  lesen kann, zum Beispiel `DISPLAY`. Variablen, die in
  `~/.bashrc` gesetzt werden, gelten in jeder neuen
  Sitzung — deshalb gehören Schlüssel nicht dorthin.
- **Skill** — eine kurze Anleitung, die ein Agent
  liest, um ein Werkzeug richtig zu benutzen (zum
  Beispiel `/notebooklm`, `/graphify`). Sie liegt als
  Datei in Ihrem Home-Verzeichnis.
- **MCP-Server** — ein Dienst, der einem Agenten
  zusätzliche Werkzeuge anbietet (im Wiki suchen,
  Webseiten öffnen, Oberflächen entwerfen). Die
  MCP-Server und Skills des Images trägt clawbook bei
  allen Agenten selbst ein; für Stitch und Wiki.js
  geben Sie nur einen Schlüssel ein. Siehe
  [Agenten-Ausstattung](../agenten-ausstattung.md).
- **tmux** — ein Programm, das mehrere
  Terminal-Sitzungen im Container am Leben hält, auch
  wenn Ihre Verbindung abbricht. `wsm` startet
  Agenten darin.

## Wo Sie die Befehle eingeben

Alle Befehle in den Setup-Seiten geben Sie **im
Container** ein, als Benutzer `student`. Dafür gibt es
zwei Wege, die beide in der
[Installation](../installation.md) beschrieben sind:

- das Terminal in VS Code, nachdem Sie sich mit dem
  Host `clawbook` verbunden haben (Menü „Terminal →
  New Terminal"; unten links steht „SSH: clawbook"),
  oder
- PowerShell unter Windows, darin `ssh clawbook`. Dort
  öffnet sich zuerst das clawbook-Menü; mit `0`
  kommen Sie in die Eingabezeile.

Woran Sie erkennen, wo Sie sind: Im Container beginnt
die Eingabeaufforderung mit `student@…`; in PowerShell
mit `PS C:\…`. Befehle für den Container stehen auf
diesen Seiten in `bash`-Blöcken, Befehle für Windows
in `powershell`-Blöcken. Meldet `ssh clawbook`
„Connection refused", läuft der Container nicht —
starten Sie ihn wie in [Pflege](../pflege.md),
Abschnitt 1.

## So klappt die Anmeldung im Browser

Fast alle Werkzeuge melden Sie über eine Webseite an.
Weil der Container kein Browserfenster vor Ihnen
öffnen kann, zeigen sie einen **Link** und meist einen
**Code** im Terminal. Sie öffnen den Link in Ihrem
Browser unter Windows, melden sich an, geben den Code
ein — oder kopieren einen Code zurück ins Terminal.

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
  Markieren Sie sie bis zum letzten Zeichen, sonst
  fehlt ein Stück, und die Seite meldet einen Fehler.

Nur NotebookLM braucht den Browser **im Container**;
dafür gibt es den Bildschirm per Remote-Desktop, siehe
[Google](google.md).

## Wie Sie ein Programm wieder verlassen

- Agenten (`claude`, `codex`, `copilot`, `opencode`,
  `agy`): `/exit` eingeben; notfalls zweimal `Strg+C`.
- tmux-Sitzung (zum Beispiel von `wsm` gestartet):
  `Strg+B`, loslassen, dann `D` — die Sitzung läuft im
  Hintergrund weiter, Sie kommen zurück ins Terminal.
- clawbook-Menü: `0`.
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
| [Kurs-Dienste](kurs-dienste.md) | Wiki.js-MCP, Docling für `wsm update` | Adresse und Schlüssel bekommen Sie im Kurs |
| [Ohne Account](ohne-account.md) | Playwright, Graphify, `uv`, Node.js, Python, `wsm` | kostenlos |

**Sie müssen nichts kaufen, um anzufangen.** Zum
Ausprobieren genügen die kostenlosen Wege: Copilot CLI
nach Freischaltung des Studierenden-Plans, Codex mit
dem kostenlosen ChatGPT-Plan, Antigravity und
NotebookLM mit einem Google-Konto, OpenRouter mit
`:free`-Modellen. Welche Werkzeuge im Kurs
verpflichtend sind und ob die Hochschule Zugänge
stellt, sagt Ihnen die Kursleitung. Preise und
Angebote ändern sich; jede Anbieter-Seite nennt Quelle
und Datum — prüfen Sie vor einer Zahlung die Seite des
Anbieters.

Wenn Sie etwas Kostenpflichtiges abschließen, gilt auf
allen Seiten dasselbe:

- **Abos verlängern sich automatisch.** Tragen Sie
  sich das Kündigungsdatum in den Kalender ein; wie Sie
  kündigen, steht auf der jeweiligen Seite.
- **Bei Guthaben nach Verbrauch:** automatisches
  Nachladen ausschalten und ein Ausgabenlimit setzen.
  Dann ist der höchste mögliche Schaden das, was Sie
  eingezahlt haben.

## Empfohlene Reihenfolge

1. **[GitHub](github.md)** — zuerst. Die Anmeldung im
   Container bietet `clawbook` beim ersten
   `ssh clawbook` von selbst an. GitHub kommt zuerst,
   weil `git` und `gh` die Basis für alles andere
   sind, weil `wsm` Ihren GitHub-Namen beim ersten
   Start aus der Anmeldung übernimmt (sonst steht dort
   ein falscher Name) und weil der
   Studierenden-Antrag ein paar Tage dauern kann.
   Stellen Sie ihn gleich am Anfang.
2. **Ein Coding-Agent.** Im Kurs arbeiten wir vor
   allem mit **Claude Code**; die MCP-Dienste (Stitch,
   Wiki.js, Playwright) richtet clawbook aber bei allen
   Agenten ein. Für Claude Code brauchen Sie
   [Anthropic](anthropic.md). Wer erst einmal nichts
   ausgeben will, startet mit der Copilot CLI aus dem
   Student Developer Pack ([GitHub](github.md)) oder
   mit Codex ([OpenAI](openai.md)).
3. **[Google](google.md)** — Antigravity und
   NotebookLM sind mit einem Google-Konto kostenlos
   nutzbar; Stitch brauchen Sie erst, wenn es um
   Oberflächen-Entwürfe geht.
4. **Optional:** [OpenRouter](openrouter.md) und
   [OpenCode](opencode.md), wenn Sie mehrere Modelle
   verschiedener Anbieter ausprobieren wollen.
5. **[Kurs-Dienste](kurs-dienste.md)** — sobald Sie
   Adresse und Schlüssel im Kurs bekommen haben.
6. **[Ohne Account](ohne-account.md)** — Playwright
   und Graphify kennenlernen (eingetragen sind sie
   schon, siehe
   [Agenten-Ausstattung](../agenten-ausstattung.md))
   und `wsm` zum ersten Mal starten (nach GitHub); das
   dauert ein paar Minuten.

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
   Schlüssel statt Ihres Abos und rechnet pro Token
   ab (siehe [Anthropic](anthropic.md)). Einzige
   Ausnahme: Schlüssel für MCP-Server (Stitch, Wiki.js)
   speichert `clawbook agenten schluessel` in
   `~/.clawbook/secrets`, und der Container setzt sie in
   jedem Terminal — so finden alle Agenten sie. Das
   widerspricht der Regel nur scheinbar: Diese Schlüssel
   gelten nur für einen bestimmten Dienst (Stitch,
   Wiki.js) und stellen nicht um, wie ein Agent sich
   anmeldet oder abrechnet. Schlüssel für die Anmeldung
   der Agenten selbst nimmt der Befehl deshalb nicht an. Siehe
   [Agenten-Ausstattung](../agenten-ausstattung.md).
2. **Nie im Befehl tippen.** Alles, was Sie im
   Terminal eingeben, landet in der Befehlshistorie
   (`~/.bash_history`). Wo ein Schlüssel in einen
   Befehl gehört, nutzen die Seiten dieses Muster:

   ```bash
   read -rs KEY
   ```

   Nach Enter wartet das Terminal, ohne etwas
   anzuzeigen. Fügen Sie den Schlüssel ein (er bleibt
   unsichtbar) und drücken Sie Enter. Im folgenden
   Befehl steht dann `"$KEY"` statt des Schlüssels,
   und zum Schluss löscht `unset KEY` die Variable
   wieder.
3. **Nie weitergeben.** Die Dateien mit Ihren
   Zugängen — `~/.claude.json`,
   `~/.claude/.credentials.json`,
   `~/.codex/auth.json`, `~/.config/gh/`,
   `~/.local/share/opencode/auth.json`, `~/.notebooklm/`,
   `~/.clawbook/secrets`, `~/.gemini/config/mcp_config.json`
   — gehören nie in ein Repository (`git add` prüfen),
   nie in eine Hilfe-Anfrage, nie in einen Chat. Wer
   sie hat, arbeitet auf Ihre Rechnung. Und umgekehrt:
   Laden Sie keine Daten anderer Personen und keine
   Prüfungsunterlagen in KI-Dienste, ohne dass der Kurs
   das ausdrücklich vorsieht.

## Wenn Sie prüfen wollen, was eingerichtet ist

```bash
clawbook check          # sind alle Werkzeuge da?
clawbook github status  # GitHub
clawbook agenten        # MCP-Server, Skills, Schlüssel je Agent
claude mcp list         # MCP-Dienste für Claude Code
opencode auth list      # Anbieter in OpenCode
```

`clawbook check` erreichen Sie auch über das
clawbook-Menü (Punkt 2), die GitHub-Prüfung über
Punkt 7. Der ältere Befehl `clawbook-check` tut
dasselbe wie `clawbook check`.

Die Werkzeuge selbst melden Sie mit den Befehlen auf
den jeweiligen Seiten an; dort steht auch, woran Sie
erkennen, dass es geklappt hat.

## Wenn etwas nicht geht

Jede Anbieter-Seite hat einen Abschnitt „Typische
Fehler" mit Symptom und Lösung — dort zuerst
nachsehen. Danach in dieser Reihenfolge:

1. Sind Sie im Container (`student@…`) oder in
   PowerShell? Die Befehle der Setup-Seiten gelten nur
   im Container.
2. `clawbook check` — fehlt ein Werkzeug, liegt es am
   Image, nicht an Ihnen: melden.
3. Hilfe im Kurs holen. Nennen Sie dabei die Seite,
   den genauen Befehl und die vollständige
   Fehlermeldung — aber **nie** einen Schlüssel, Code
   aus einer Anmeldung oder den Inhalt einer
   Zugangsdatei.
