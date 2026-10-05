# clawbook auf dem eigenen Rechner

Stand: 2026-10-05

Diese Anleitungen richten sich an dich, wenn du clawbook auf
**deinem eigenen Rechner** einrichten willst — einem Rechner,
auf dem du Administrator bist und auf dem alles dauerhaft
eingerichtet bleiben darf. Dann kannst du Docker oder podman
installieren, und der Container startet von selbst mit dem
Rechner.

**Wichtig vorweg:** Die Wege auf diesen Seiten sind **nicht
vom Kurs getestet**. Das Image ist dasselbe wie im Hauptweg
und wird dort geprüft; die Installation von Docker, podman
und Co. auf deinem Rechner und das Zusammenspiel damit
haben wir nicht durchgespielt. Rechne damit, dass du an
der einen oder anderen Stelle selbst nachlesen musst. Wenn
du einen Weg erfolgreich gegangen bist oder an einer
Stelle hängst, sag es der Betreuung deiner
Lehrveranstaltung — das hilft allen. Nutzt du clawbook
außerhalb einer Lehrveranstaltung, öffne ein Issue im
GitHub-Repository des Projekts
(`schlingensiepen/clawbook-lehre`).

## Wann dieser Weg, wann der Hauptweg

Der **Hauptweg** ist die [Installation](../installation.md)
unter Windows mit WSLC: ein Befehl, ein Menü, keine
Administrator-Rechte, nichts wird dauerhaft im System
installiert. Er ist für Hochschul-Rechner gedacht, geht
aber genauso auf deinem eigenen Windows-Rechner. Wenn du
unsicher bist, nimm ihn — er ist getestet.

Dieser Weg lohnt sich, wenn mindestens eins zutrifft:

- Dein Rechner läuft unter **macOS oder Linux**. Dort gibt
  es WSLC nicht.
- Du willst, dass der Container **von selbst wieder läuft**,
  wenn du den Rechner neu startest oder dich neu anmeldest.
  Im Hauptweg musst du ihn nach jedem Neustart von Windows
  mit dem Befehl neu starten.
- Du hast **Administrator-Rechte** und willst Docker oder
  podman ohnehin auf dem Rechner haben.

## Was anders ist als im Hauptweg

| Thema | Hauptweg (WSLC) | Eigener Rechner |
|---|---|---|
| Werkzeug | WSLC, Bestandteil von WSL | Docker oder podman, selbst installiert |
| Bedienung | Verwaltungs-Skript mit Menü | Befehle im Terminal (diese Anleitungen) |
| Nach Neustart | Container von Hand starten | Container startet von selbst (Neustart-Richtlinie) |
| Projekte | nur im Home-Volume | im Home-Volume; unter Linux auch als Ordner des Rechners |
| Dateifreigabe (Samba) | nicht verfügbar | unter Linux und macOS möglich; unter Windows nicht (Explorer öffnet Freigaben nur über Port 445, den Windows selbst belegt) |
| Sicherung | Menüpunkt „mitnehmen" | `tar`-Befehl; Format ist dasselbe |

Gleich bleibt alles im Container: der Benutzer `student`,
die Werkzeuge, `clawbook-check`, das Home-Volume
`clawbook-home`, SSH auf Port 2222, der Bildschirm auf
Port 3390. Die Anleitungen zum [Setup](../setup/README.md)
der Accounts und Werkzeuge gelten unverändert. Auch eine
Sicherung (`home-<datum>.tar`) aus dem Hauptweg kannst du
hier importieren und umgekehrt.

## Was das Image braucht

Egal mit welchem Werkzeug — der Container braucht immer
dasselbe:

- **Image:** `ghcr.io/schlingensiepen/clawbook-lehre:latest`,
  nur für `linux/amd64` (Intel/AMD-Prozessoren). Auf
  Apple-Silicon-Macs läuft es nur übersetzt, siehe
  [macOS](macos.md).
- **Home-Volume** `clawbook-home`, eingehängt als
  `/home/student`. Darin liegen deine Anmeldungen, dein
  SSH-Schlüssel und deine Projekte unter `~/source`. Ein
  Volume ist ein Speicherbereich, den Docker oder podman
  verwaltet; er überlebt das Entfernen des Containers und
  damit jede Aktualisierung des Images.
- **Ports**, nur auf `127.0.0.1` veröffentlicht, also nur
  von deinem Rechner aus erreichbar: `2222` → SSH (22),
  `3390` → Bildschirm per Remote-Desktop (3389, ohne
  Passwort — deshalb niemals auf anderen Adressen
  veröffentlichen, und auf einem Rechner mit mehreren
  Benutzern besser gar nicht: Jeder, der sich dort
  anmelden kann, käme damit in den Container, in dem es
  passwortloses `sudo` gibt). Optional `4445` →
  Dateifreigabe Samba (445); sie zeigt das ganze Home,
  auch Anmeldungen und Schlüssel. Unter Windows ist sie
  nicht nutzbar: Der Explorer öffnet Freigaben nur über
  Port 445, und den belegt Windows selbst.
- **Das Volume ist nicht im Image hinterlegt.** Vergisst
  du beim Anlegen `-v clawbook-home:/home/student`, liegt
  dein Home im Container und ist beim nächsten Entfernen
  weg. Die Seiten zeigen vor jedem Entfernen, wie du das
  prüfst — und sichern geht immer vorher.
- Unter Linux kannst du zusätzlich deinen Projektordner
  `~/source` einhängen — **nur diesen**, nie dein ganzes
  Home: Im Container laufen Agenten mit vollen
  Schreibrechten und passwortlosem `sudo`.
- **Platz:** Das Image ist mehrere Gigabyte groß; rechne
  mit mindestens 20 GB frei, mehr mit deinen Projekten.

Beim ersten Start erzeugt der Container einen SSH-Schlüssel
für `student` und zeigt die Verbindungsdaten **und den
privaten Schlüssel** im Log an. Den Schlüssel holst du auf
deinen Rechner und trägst ihn in deine SSH-Konfiguration
ein; danach geht `ssh clawbook` und VS Code „Remote - SSH"
genau wie im Hauptweg. Das steht Schritt für Schritt auf
der Seite deines Betriebssystems.

## Betriebssystem wählen

- **[Windows](windows.md)** — Docker Desktop als
  einfachster Weg; Alternativen: Podman Desktop oder der
  Hauptweg mit automatischem Start.
- **[macOS](macos.md)** — Docker Desktop, OrbStack oder
  podman. Auf Apple Silicon (M-Prozessoren) läuft das
  Image übersetzt und deutlich langsamer; die Seite sagt
  ehrlich, was das heißt.
- **[Linux](linux.md)** — Docker oder podman direkt, ohne
  virtuelle Maschine; Projekte als Ordner deines Rechners;
  Autostart per Neustart-Richtlinie bzw. systemd.

## Begriffe, die auf allen Seiten vorkommen

- **Image** — die fertige Vorlage des Arbeitsrechners mit
  allen Werkzeugen; wird heruntergeladen, nicht verändert.
- **Container** — das laufende Exemplar des Images. Er
  lässt sich jederzeit entfernen und aus dem Image neu
  anlegen; deine Daten sind im Volume, nicht im Container.
- **Volume** — ein von Docker/podman verwalteter
  Speicherbereich, hier dein Home.
- **Port veröffentlichen** (`-p`) — einen Dienst im
  Container unter einer Adresse und Portnummer deines
  Rechners erreichbar machen, zum Beispiel
  `127.0.0.1:2222` für SSH.
- **Neustart-Richtlinie** (`--restart`) — Docker/podman
  startet den Container nach einem Neustart des Rechners
  bzw. des Dienstes wieder, ohne dein Zutun.
- **Docker und podman** — zwei Programme, die Container
  ausführen. Die Befehle sind weitgehend gleich (`docker
  run` ↔ `podman run`). Docker braucht einen Dienst mit
  Systemrechten; podman nicht. Für clawbook taugen beide;
  die Seiten nennen jeweils beide Befehle, Docker ist der
  einfachere und besser beschriebene Weg.
- **rootless** — podman-Betriebsart, in der alles unter
  deinem normalen Benutzer läuft, ohne Dienst mit
  Systemrechten. „root" im Container ist dann nur im
  Container root; auf dem Rechner bleibt es dein Benutzer.
- **Quadlet** — podmans Verbindung zu systemd (dem
  Dienst-Verwalter von Linux): eine kleine Datei
  beschreibt den Container, systemd startet ihn beim
  Hochfahren und startet ihn neu, wenn er abstürzt.
- **Linger** — eine systemd-Einstellung, mit der deine
  Benutzer-Dienste (und damit der Container) schon beim
  Hochfahren starten und nach dem Abmelden weiterlaufen,
  nicht erst ab deiner Anmeldung.
- **SELinux** — ein Sicherheitssystem, das Fedora und
  verwandte Distributionen benutzen. Es verbietet
  Containern den Zugriff auf Ordner des Rechners, bis man
  den Ordner dafür kennzeichnet (`:Z` am Mount).
