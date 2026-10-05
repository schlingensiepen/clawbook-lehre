# Wegweiser

Stand: 2026-10-05

## Was ist clawbook?

clawbook ist ein fertig eingerichteter Linux-Arbeitsrechner
für die Arbeit mit KI-Agenten, verpackt als Container-Image.
Git, Node.js, Python und mehrere Agenten-Werkzeuge (Claude
Code, Codex, GitHub Copilot CLI, OpenCode und weitere)
sind schon installiert und aufeinander abgestimmt. Du
startest ihn auf deinem Windows-Rechner mit einem einzigen
Befehl — ohne Administrator-Rechte — und arbeitest darin
per Terminal, VS Code und Remotedesktop. Deine Projekte
und Anmeldungen liegen in einem eigenen Speicherbereich,
der neue Versionen des Images überlebt und sich als eine
Datei auf einen anderen Rechner mitnehmen lässt.

## In dieser Reihenfolge

1. **[Installation](installation.md)** — Voraussetzungen
   prüfen, den einen Befehl ausführen, verbinden mit
   Terminal, VS Code und Bildschirm. Einmalig, etwa eine
   Stunde inklusive Herunterladen.
2. **[Setup](setup/README.md)** — Accounts bei den
   Anbietern anlegen und jedes Werkzeug im Container
   anmelden. Die Zugänge gehören dir und stecken nicht im
   Image.
3. **[Pflege](pflege.md)** — täglich starten,
   aktualisieren, sichern und auf einen anderen Rechner
   umziehen.

Auf einem **eigenen Rechner**, auf dem alles dauerhaft
eingerichtet bleiben darf, gibt es außerdem einen Weg mit
Docker oder podman für Windows, macOS und Linux:
[Eigener Rechner](privat/README.md). Er ist nicht vom
Kurs getestet.

Bei Problemen: Jede Seite hat am Ende einen Abschnitt
„Wenn etwas nicht geht". Wenn der nicht weiterhilft, wende
dich an die Betreuung deiner Lehrveranstaltung.

## Begriffe

Die Wörter, die in Installation und Pflege immer wieder
vorkommen. Begriffe rund um die KI-Werkzeuge (Agent,
API-Schlüssel, Token, MCP-Server, Umgebungsvariable)
erklärt das [Setup](setup/README.md).

- **Image** — die fertige Vorlage des Arbeitsrechners:
  Linux samt allen Werkzeugen, als eine Datei von mehreren
  Gigabyte. Du änderst sie nicht; neue Versionen kommen
  vom Kurs.
- **Container** — das laufende Exemplar des Images auf
  deinem Rechner, ein abgeschlossener Linux-Rechner, den
  Windows wie ein Programm startet und anhält. Ein neues
  Image ergibt einen neuen Container.
- **Volume** — ein eigener Speicherbereich, den WSL für den
  Container verwaltet; unter Windows eine einzige große
  Datei. Das Home-Volume `clawbook-home` enthält dein
  Home-Verzeichnis und überlebt neue Images.
- **Home-Verzeichnis, `~`** — dein persönlicher Ordner im
  Container, `/home/student`. Die Tilde `~` ist in Befehlen
  die Abkürzung dafür: `~/source` heißt
  `/home/student/source`. Dort liegen deine Projekte, deine
  Einstellungen und die Anmeldungen der Werkzeuge.
- **Terminal, PowerShell, Container-Terminal** — ein
  Terminal ist ein Fenster, in das du Befehle tippst.
  PowerShell ist das Terminal von Windows (`PS C:\…>`);
  Befehle dafür stehen in `powershell`-Blöcken. Nach
  `ssh clawbook` oder in VS Code bist du im Terminal des
  Containers (`student@…:~$`); Befehle dafür stehen in
  `bash`-Blöcken.
- **SSH** — das Verfahren, mit dem du dich von Windows aus
  im Container anmeldest. Statt eines Passworts dient eine
  Schlüsseldatei (`%USERPROFILE%\.ssh\clawbook`), die das
  Skript anlegt. `ssh clawbook` stellt die Verbindung her.
- **Port** — eine Nummer, unter der ein Dienst auf einem
  Rechner erreichbar ist. Der Container bietet SSH unter
  Port 2222 und den Bildschirm unter Port 3390 an — nur
  auf deinem eigenen Rechner (`localhost` bzw.
  `127.0.0.1`), nicht im Netz.
- **WSL, WSLC** — das Windows-Subsystem für Linux, ein
  Bestandteil von Windows, der Linux-Programme ausführt.
  WSLC ist der Teil davon, der Container verwaltet; das
  Skript nutzt ihn. Beide haben dieselbe Versionsnummer.
- **Remotedesktop** — das Windows-Programm
  „Remotedesktopverbindung" (`mstsc`), mit dem du den
  Bildschirm des Containers siehst: einen Browser und ein
  Terminal, für Anmeldungen im Browser des Containers.
- **Austauschordner** — der einzige Ordner, den Windows und
  Container gemeinsam sehen: `%USERPROFILE%\clawbook\austausch`
  bzw. `~/austausch`. Für einzelne Dateien, nicht für
  Projekte.
- **Sicherung** — dein komplettes Home als eine Datei
  `home-<datum>.tar` unter
  `%USERPROFILE%\clawbook\sicherungen\`. Enthält Logins und
  Schlüssel; wie ein Passwort behandeln.
- **wsm** — der WorkspaceManager, ein Befehl im Container,
  der Projektordner unter `~/source` anlegt und Agenten
  darin startet.
