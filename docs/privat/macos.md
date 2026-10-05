# macOS: clawbook auf dem eigenen Mac

Stand: 2026-10-05

**Nicht vom Kurs getestet.** Das Image ist für Windows mit
WSLC gebaut und wird dort geprüft. Auf dem Mac läuft es in
einer kleinen Linux-Maschine, die Docker Desktop, OrbStack
oder podman für dich anlegen. Wann sich dieser Weg lohnt,
steht in der [Übersicht](README.md).

Wo du welchen Befehl eingibst: Befehle in `bash`-Blöcken
laufen **im Terminal deines Macs**, solange nichts anderes
dabeisteht. Nach `ssh clawbook` bist du **im Container**;
das erkennst du an der Eingabeaufforderung `student@…:~$`.
Mit `exit` bist du wieder auf dem Mac.

## 0. Zuerst lesen: Apple Silicon oder Intel?

Das Image gibt es **nur für `linux/amd64`**, also für
Intel/AMD-Prozessoren. Welcher Mac du hast, steht unter
Apple-Menü → „Über diesen Mac": „Chip Apple M…" ist
**Apple Silicon**, „Prozessor Intel …" ist **Intel**.

- **Intel-Mac:** Das Image läuft nativ. Alles Weitere gilt
  ohne Einschränkung.
- **Apple Silicon (M1, M2, M3, M4 …):** Der Prozessor
  spricht eine andere Sprache (`arm64`). Jedes Programm im
  Container muss übersetzt werden — mit **Rosetta**
  (Apples Übersetzer, schnell) oder **QEMU** (Emulation,
  sehr langsam). Das heißt ehrlich:
  - **Es ist langsamer.** Mit Rosetta spürbar, mit QEMU
    kaum benutzbar. Der Kaltstart dauert länger, der
    Browser im Container ruckelt, `npm install` und Tests
    brauchen ein Vielfaches.
  - **Es kann einzelne Programme geben, die nicht
    laufen.** Rosetta übersetzt nicht alles; Fehler wie
    „exec format error" oder abstürzende Prozesse sind
    möglich. Wir haben das **nicht getestet**.
  - **Rosetta einschalten ist Pflicht**, sonst nimmt dein
    Werkzeug QEMU. Wie, steht beim jeweiligen Werkzeug.
  - Einmalig Rosetta installieren, falls noch nicht da:

    ```bash
    softwareupdate --install-rosetta --agree-to-license
    ```

Wenn du einen Apple-Silicon-Mac hast und einen
Windows-Rechner oder einen Linux-Rechner in Reichweite,
ist der oft die bessere Wahl. Ein Image für `arm64` gibt
es derzeit nicht.

## 1. Werkzeug wählen

| Werkzeug | Kosten (Stand Oktober 2026, prüfe selbst) | Rosetta für `amd64` | Bemerkung |
|---|---|---|---|
| **Docker Desktop** | kostenlos für „personal use, education" (Docker-Bedingungen akzeptieren) | ja, Einstellung setzen | am weitesten verbreitet, viele Anleitungen im Netz |
| **OrbStack** | kostenlos für „personal, non-commercial use" | ja, automatisch | leichtgewichtig, schnell, nur für Mac |
| **podman** | frei (Apache-Lizenz), kein Konto | ja, beim Anlegen der Maschine einschalten | Befehle wie Docker mit `podman` statt `docker`; am wenigsten erprobt |

Alle drei stellen dir den Befehl `docker` bzw. `podman` im
Terminal bereit. Die Abschnitte 3 bis 9 sind für alle
gleich; nur die Installation (Abschnitt 2) unterscheidet
sich. Du brauchst mindestens 20 GB freien Platz und
macOS in einer aktuellen Version (Docker Desktop
unterstützt laut Docker „the current and two previous
major macOS releases"). Lizenzbedingungen ändern sich;
prüfe sie vor der Installation auf der Seite des
Anbieters.

## 2. Installation

### Docker Desktop

1. Laden von
   <https://docs.docker.com/desktop/setup/install/mac-install/>
   — die Fassung **für deinen Chip** (Apple Silicon oder
   Intel). `.dmg` öffnen, Docker in „Programme" ziehen,
   starten, Nutzungsbedingungen akzeptieren; ein Konto
   brauchst du nicht.
2. **Settings → General:**
   - **„Start Docker Desktop when you sign in to your
     computer"** einschalten — sonst läuft der Container
     nach einem Neustart erst, wenn du Docker öffnest.
   - Nur Apple Silicon: bei **„Choose Virtual Machine
     Manager (VMM)"** das **Apple Virtualization
     framework** wählen. Dockers eigener „Docker VMM"
     unterstützt laut Docker-Dokumentation kein Rosetta;
     `amd64`-Container wären dann sehr langsam.
   - Nur Apple Silicon: **„Use Rosetta for x86_64/amd64
     emulation on Apple Silicon"** einschalten.
   - „Apply & restart".
3. **Settings → Resources:** clawbook mindestens 4 CPU-Kerne
   und 6–8 GB Arbeitsspeicher geben; die Vorgaben sind
   knapp.
4. Prüfen im Terminal: `docker version` zeigt einen
   „Server"-Abschnitt.

### OrbStack

1. Laden von <https://orbstack.dev> und in „Programme"
   ziehen, oder im Terminal `brew install orbstack`
   (falls du Homebrew nutzt). Starten; der Befehl `docker`
   wird mitinstalliert und auf OrbStack eingestellt.
2. Auf Apple Silicon nutzt OrbStack laut Dokumentation
   Rosetta für `amd64`-Images von selbst; es gibt nichts
   einzustellen.
3. In den OrbStack-Einstellungen prüfen, dass OrbStack bei
   der Anmeldung startet, damit der Container nach einem
   Neustart von selbst läuft.
4. Prüfen: `docker version`.

### podman

1. Installer laden von <https://podman.io> (oder Podman
   Desktop von <https://podman-desktop.io>, das podman
   mitbringt und ein Fenster dazu). Das Podman-Projekt
   rät von `brew install podman` ab, es geht aber.
2. Eine Maschine anlegen und starten — auf Apple Silicon
   mit Rosetta:

   ```bash
   podman machine init --rosetta --cpus 4 --memory 8192 --disk-size 60
   podman machine start
   podman info
   ```

   Auf einem Intel-Mac die Option `--rosetta` weglassen.
   Ob Rosetta schon Vorgabe ist, hängt von der
   podman-Version ab; die Option schadet nicht.
3. **Nach jedem Neustart des Macs** muss die Maschine
   laufen und der Container gestartet werden — das ist
   bei podman der verlässliche Weg:

   ```bash
   podman machine start
   podman start clawbook
   ```

   Podman Desktop startet die Maschine mit „Start on
   login" und „Autostart engine on launch" in seinen
   Einstellungen selbst; den Container startest du
   trotzdem mit `podman start clawbook`. Lass bei podman
   die Zeile `--restart unless-stopped` im Befehl unten
   weg; sie greift in der Maschine nicht zuverlässig.

In allen Befehlen unten steht `docker`; mit podman
ersetzt du es durch `podman`.

## 3. Container anlegen und starten

```bash
docker volume create clawbook-home
docker run -d --name clawbook \
  --platform linux/amd64 \
  --restart unless-stopped \
  -p 127.0.0.1:2222:22 \
  -p 127.0.0.1:3390:3389 \
  -p 127.0.0.1:4445:445 \
  -v clawbook-home:/home/student \
  ghcr.io/schlingensiepen/clawbook-lehre:latest
```

Was die Teile bedeuten:

- `docker volume create clawbook-home` — legt das
  Home-Volume an; `-v clawbook-home:/home/student` hängt
  es als Home ein. **Diese Zeile ist die wichtigste:** Das
  Image bringt kein eigenes Volume mit. Vergisst du sie,
  liegt dein Home im Container selbst und ist beim
  nächsten `docker rm` weg.
- `-d` — der Container läuft im Hintergrund.
- `--platform linux/amd64` — sagt ausdrücklich, dass das
  Image für `amd64` ist; auf Apple Silicon unterdrückt das
  Warnungen, auf Intel ändert es nichts.
- `--restart unless-stopped` — die **Neustart-Richtlinie**:
  Der Container startet wieder, sobald Docker startet,
  außer du hast ihn selbst mit `docker stop` angehalten.
  Bei podman weglassen (Abschnitt 2).
- `-p 127.0.0.1:2222:22` — SSH unter `localhost:2222`;
  `-p 127.0.0.1:3390:3389` — der Bildschirm unter
  `localhost:3390`; `-p 127.0.0.1:4445:445` — die
  Dateifreigabe (Samba) unter `localhost:4445`. Alle nur
  von deinem Mac aus erreichbar. Die Freigabe ist
  optional und zeigt das **ganze Home** von `student`,
  auch Anmeldungen und Schlüssel; lass die Zeile weg und
  gib `-e CLAWBOOK_SAMBA=0` mit, wenn du sie nicht willst.

Beim ersten Mal lädt Docker das Image (mehrere Gigabyte).
Der erste Start („Kaltstart") dauert danach bis zu drei
Minuten, auf Apple Silicon auch länger; der Container
erzeugt dabei seine Schlüssel. Prüfen:

```bash
docker ps
docker logs clawbook
```

**Warte, bis `docker logs clawbook` den Kasten mit den
Verbindungsdaten zeigt** — vorher gibt es den SSH-Schlüssel
noch nicht. Der Kasten nennt den **privaten SSH-Schlüssel**
und das **Passwort der Dateifreigabe**. Er ist für den
Hauptweg unter Windows formuliert (`mstsc`,
`%USERPROFILE%`, Samba über Port 445 und die IP der
WSL-Distribution); auf diesem Weg gilt stattdessen:
Bildschirm und SSH wie unten, Samba unter
`127.0.0.1:4445`.

Ob alles läuft: Bei Docker steht in `docker ps` nach dem
Kaltstart `(healthy)` — das Image prüft selbst, ob seine
Dienste antworten. Bei podman prüfst du mit
`podman healthcheck run clawbook` (Rückgabewert 0 =
gesund) oder einfach mit `ssh clawbook` im nächsten
Abschnitt.

## 4. SSH einrichten

Auf dem Mac:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
docker exec clawbook cat /home/student/.ssh/id_ed25519 > ~/.ssh/clawbook
chmod 600 ~/.ssh/clawbook
```

Dann diesen Block an `~/.ssh/config` anhängen (Datei
anlegen, falls sie fehlt):

```text
Host clawbook
  HostName 127.0.0.1
  Port 2222
  User student
  IdentityFile ~/.ssh/clawbook
  IdentitiesOnly yes
```

Prüfen mit `ssh clawbook` — beim ersten Mal „Permanently
added …". **Ab hier bist du im Container**, als `student`;
die Eingabeaufforderung zeigt `student@…:~$`. Dort:

```bash
clawbook-check
```

zeigt, ob alle Werkzeuge da sind. `exit` bringt dich
zurück auf den Mac.

## 5. VS Code und Bildschirm

- **VS Code:** wie in der [Installation](../installation.md),
  Abschnitt 5 — Erweiterung „Remote - SSH", „Connect to
  Host…" → `clawbook`, Ordner `/home/student/source`.
- **Bildschirm:** Auf dem Mac brauchst du einen
  Remote-Desktop-Client. Microsofts Client heißt im Mac
  App Store **„Windows App"** (früher „Microsoft Remote
  Desktop"). Dort einen PC hinzufügen mit Adresse
  `127.0.0.1:3390`, verbinden, die Zertifikatswarnung
  bestätigen; ein Passwort gibt es nicht. Oben in der
  Leiste findest du Chromium und ein Terminal, beide als
  `student`.

**Nur auf einem Mac, den du allein benutzt:** Der
Bildschirm hat kein Passwort. Jeder, der sich an deinem
Mac anmelden kann, kommt damit in den Container — und
dort gibt es passwortloses `sudo` und deine Anmeldungen.
Auf einem Mac mit mehreren Benutzern die Zeile
`-p 127.0.0.1:3390:3389` weglassen.

## 6. Dateien im Finder (optional)

Wenn du Samba veröffentlicht hast (Port 4445): im Finder
**Gehe zu → Mit Server verbinden** (`⌘K`) und eingeben:

```text
smb://127.0.0.1:4445/student
```

Benutzer `student`, Passwort aus dem Start-Kasten
(`docker logs clawbook`). Nicht getestet; falls der Finder
den Port nicht annimmt, bleibt VS Code der Weg zu deinen
Dateien. Projekte gehören in jedem Fall nach `~/source`
im Container, nicht in Ordner des Macs: Zugriffe aus dem
Container auf Mac-Ordner sind langsam.

## 7. Accounts und Werkzeuge einrichten

Wie jeder Account angelegt und jedes Werkzeug angemeldet
wird, steht im [Setup](../setup/README.md). Die Befehle
dort gibst du **im Container** ein (nach `ssh clawbook`
oder im VS-Code-Terminal). Links, die die Werkzeuge im
Terminal zeigen, öffnest du im Browser auf dem Mac; nur
NotebookLM braucht den Browser im Container über den
Bildschirm.

## 8. Alltag, aktualisieren

Nach einem Neustart des Macs startet dein Werkzeug (siehe
Abschnitt 2) und mit ihm der Container (podman: von Hand,
`podman start clawbook`).

```bash
docker ps                 # läuft er?
docker stop clawbook      # anhalten (bleibt angehalten)
docker start clawbook     # wieder starten
docker logs clawbook      # Start-Kasten und Meldungen
```

### Aktualisieren

Ein neues Image bringt neuere Werkzeuge. Du entfernst den
Container und legst ihn mit demselben Volume neu an — das
Home bleibt, **wenn es im Volume liegt**. Deshalb vorher
prüfen und sichern:

0. **Sicherung schreiben** (Abschnitt 9). Immer.
1. **Prüfen, dass das Home im Volume liegt:**

   ```bash
   docker inspect clawbook --format '{{json .Mounts}}'
   ```

   In der Ausgabe muss `"Name":"clawbook-home"` mit
   `"Destination":"/home/student"` stehen. Fehlt das,
   liegt dein Home im Container — dann **nicht**
   entfernen, sondern erst mit `docker exec clawbook tar
   -C /home/student -cpf - . > home-rettung.tar` sichern.

2. Neues Image ziehen, Container anhalten und entfernen:

   ```bash
   docker pull ghcr.io/schlingensiepen/clawbook-lehre:latest
   docker stop clawbook
   docker rm clawbook
   ```

   Danach den `docker run`-Befehl aus Abschnitt 3 erneut
   ausführen; optional `docker image prune`, das löscht
   alte, nicht mehr benutzte Image-Schichten.

Der SSH-Schlüssel bleibt derselbe. Was nicht bleibt:
Installationen außerhalb des Homes (siehe
[Pflege](../pflege.md), Abschnitt 3).

## 9. Sichern und mitnehmen

Ein `tar`-Archiv deines Homes, im selben Format wie die
Sicherungen des Windows-Skripts (`home-<datum>.tar`) —
also auch dort importierbar. Ein Hilfscontainer (ein
kleines Debian) packt das Volume und macht die Datei nur
für dich lesbar.

```bash
ziel="$HOME/clawbook/sicherungen"
mkdir -p "$ziel" && chmod 700 "$ziel"
datei="home-$(date +%Y-%m-%d-%H%M).tar"
docker stop clawbook
docker run --rm -v clawbook-home:/h -v "$ziel:/out" \
  docker.io/library/debian:trixie-slim \
  sh -c "tar -C /h -cpf /out/$datei . && chmod 600 /out/$datei"
docker start clawbook
```

**Das Archiv enthält deine Anmeldungen und deinen privaten
SSH-Schlüssel** — behandle es wie ein Passwort. Lege den
Ordner **nicht** in einen Cloud-Ordner (iCloud Drive,
Dropbox, OneDrive); prüfe, dass „Schreibtisch & Dokumente"
nicht über iCloud synchronisiert werden, wenn du einen
anderen Ordner wählst. Ein Umzug per USB-Stick oder
verschlüsseltem Speicher ist der richtige Weg.

### Importieren

Leeres Volume, Archiv entpacken, Container anlegen.
Existiert schon ein Volume, vorher sichern (oben), dann
Container und Volume entfernen — **`docker volume rm`
ist unwiderruflich**, danach ist das alte Home weg:

```bash
docker stop clawbook && docker rm clawbook
docker volume rm clawbook-home
```

Dann importieren — `<deine-datei>.tar` durch den Namen
deiner Sicherung ersetzen:

```bash
ziel="$HOME/clawbook/sicherungen"
docker volume create clawbook-home
docker run --rm -v clawbook-home:/h -v "$ziel:/in" \
  docker.io/library/debian:trixie-slim \
  tar -C /h -xpf /in/<deine-datei>.tar
```

Dann Abschnitt 3 (`docker run`) und Abschnitt 4 (SSH)
wiederholen. Meldet SSH danach „REMOTE HOST IDENTIFICATION
HAS CHANGED", die Zeile für `[127.0.0.1]:2222` aus
`~/.ssh/known_hosts` entfernen:

```bash
ssh-keygen -R "[127.0.0.1]:2222"
```

## Wenn etwas nicht geht

- **„exec format error"** oder der Container stoppt sofort
  (Apple Silicon) — Rosetta ist nicht aktiv: Docker
  Desktop auf Apple Virtualization framework + Rosetta
  umstellen (Abschnitt 2); bei podman die Maschine mit
  `--rosetta` neu anlegen (`podman machine rm`, dann
  `init`). Bleibt der Fehler, läuft dieses Image auf
  deinem Mac nicht.
- **Kaltstart dauert ewig** (Apple Silicon) — normal
  unter Übersetzung; `docker logs -f clawbook` zeigt, ob
  etwas passiert. Mehr CPU und RAM zuteilen (Abschnitt 2).
- **„port is already allocated"** — Port belegt; andere
  Ports nehmen und `-e CLAWBOOK_SSH_PORT=…` bzw.
  `-e CLAWBOOK_RDP_PORT=…` mitgeben, damit der
  Start-Kasten stimmt; SSH-Config anpassen.
- **`ssh clawbook`: „Connection refused"** — Container
  läuft nicht oder ist im Kaltstart: `docker ps`.
- **`ssh clawbook` fragt nach einem Passwort** — Schlüssel
  fehlt oder ist unvollständig (zu früh kopiert, vor dem
  Kasten im Log): Abschnitt 4 wiederholen; die Datei muss
  mit `-----BEGIN OPENSSH PRIVATE KEY-----` beginnen.
- **Nach dem Neustart läuft nichts** — startet dein
  Werkzeug bei der Anmeldung (Abschnitt 2)? Wurde der
  Container mit `docker stop` angehalten? Bei podman:
  `podman machine start`, dann `podman start clawbook`.

Kommst du nicht weiter, wende dich an die Betreuung deiner
Lehrveranstaltung. Nutzt du clawbook außerhalb einer
Lehrveranstaltung, öffne ein Issue im GitHub-Repository
des Projekts (`schlingensiepen/clawbook-lehre`).
