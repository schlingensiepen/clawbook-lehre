# Linux: clawbook auf dem eigenen Rechner

Stand: 2026-10-05

**Nicht vom Kurs getestet.** Das Image ist für Windows mit
WSLC gebaut und wird dort geprüft. Unter Linux läuft es
nativ — ohne virtuelle Maschine, mit denselben Dateirechten
wie dein Benutzer. Wann sich dieser Weg lohnt, steht in der
[Übersicht](README.md).

Du hast zwei Möglichkeiten:

- **Docker** (Abschnitt 2) — ein Dienst mit Systemrechten;
  Autostart des Containers per Neustart-Richtlinie.
  Einfach, aber: Wer `docker` aufrufen darf, hat damit
  Root-Rechte auf dem Rechner.
- **podman** (Abschnitt 3) — läuft „rootless" als dein
  Benutzer, kein Dienst mit Systemrechten; Autostart über
  systemd („Quadlet"). Mehr Einrichtung, und **dieser Weg
  ist besonders ungetestet**: Das Image startet als root
  (Prozess-Verwalter, SSH, Bildschirm, Samba), und das
  Zusammenspiel mit rootless podman haben wir nicht
  ausprobiert.

Die Abschnitte ab 4 gelten für beide. Voraussetzungen:
ein x86-64-Rechner (`uname -m` zeigt `x86_64`; das Image
gibt es nur für `linux/amd64`), eine gängige Distribution
mit systemd, mindestens 20 GB frei.

Wo du welchen Befehl eingibst: Befehle in `bash`-Blöcken
laufen **auf deinem Rechner**, solange nichts anderes
dabeisteht. Nach `ssh clawbook` bist du **im Container**;
das erkennst du an der Eingabeaufforderung `student@…:~$`.
Mit `exit` bist du wieder auf deinem Rechner.

## 1. Entscheiden: Projekte im Volume oder als Ordner?

Im Hauptweg liegen deine Projekte im Home-Volume, weil
Windows-Ordner im Container langsam sind und keine
Linux-Dateirechte kennen. Unter Linux fällt beides weg:
Ein **Ordner deines Rechners** im Container ist genauso
schnell wie das Volume, und die Rechte stimmen, wenn die
Benutzernummern passen. Du kannst also `~/source` auf
deinem Rechner direkt als `/home/student/source`
einbinden — dann siehst und bearbeitest du deine Projekte
auch außerhalb des Containers, mit jedem Programm.

**Nur den Projektordner einhängen, nie dein ganzes Home.**
Im Container laufen KI-Agenten mit vollen Schreibrechten
und passwortlosem `sudo`. Was du einhängst, können sie
ändern und löschen. `~/source` ist dafür gedacht;
`~/.ssh`, Dokumente oder dein Home insgesamt nicht.

Der Benutzer `student` im Container hat die
**Benutzernummer (UID) 1000**. Prüfe deine eigene:

```bash
id -u
```

- **1000** (der erste angelegte Benutzer auf den meisten
  Distributionen): Mit Docker passen die Rechte direkt.
  Mit podman brauchst du zusätzlich `--userns=keep-id`
  (siehe Abschnitt 3; der Befehl dort enthält es).
- **Eine andere Nummer:** Mit podman geht es trotzdem —
  `--userns=keep-id:uid=1000,gid=1000` bildet deinen
  Benutzer auf `student` ab. Mit Docker gehören die
  Dateien im Ordner dann einem anderen Benutzer als dir;
  lass den Ordner weg und bleib beim Volume.

Das **Home selbst** bleibt in jedem Fall im Volume
`clawbook-home` — dort liegen Anmeldungen und Schlüssel,
und so bleibt die Sicherung zum Hauptweg kompatibel.

## 2. Weg A: Docker

### Installieren

Am einfachsten ist das Paket deiner Distribution; unter
Debian und Ubuntu heißt es `docker.io`:

```bash
sudo apt update
sudo apt install docker.io
sudo systemctl enable --now docker
```

Es ist meist etwas älter als Dockers eigene Pakete; für
clawbook reicht es. Willst du die aktuelle Fassung, folge
der Anleitung für deine Distribution unter
<https://docs.docker.com/engine/install/> (Dockers
Paket-Repository; die Pakete heißen dann `docker-ce`,
`docker-ce-cli`, `containerd.io`). Fedora: `sudo dnf
install docker` bzw. ebenfalls die Docker-Anleitung.

Damit du `docker` ohne `sudo` aufrufen kannst, nimmst du
dich in die Gruppe `docker` auf. Die Mitgliedschaft gilt
ab der nächsten Anmeldung; für die laufende Sitzung hilft
`newgrp docker`:

```bash
sudo usermod -aG docker "$USER"
newgrp docker
docker version
```

**Hinweis von Docker:** Die Gruppe `docker` gewährt
„root-level privileges". Auf deinem eigenen Rechner ist
das vertretbar, auf einem geteilten nicht.

Nimm **Docker Engine**, nicht „Docker Desktop for Linux":
Letzteres startet eine zusätzliche virtuelle Maschine,
die hier nur bremst.

### Container anlegen und starten

```bash
mkdir -p ~/source
docker volume create clawbook-home
docker run -d --name clawbook \
  --restart unless-stopped \
  -p 127.0.0.1:2222:22 \
  -p 127.0.0.1:3390:3389 \
  -p 127.0.0.1:4445:445 \
  -v clawbook-home:/home/student \
  -v "$HOME/source:/home/student/source" \
  ghcr.io/schlingensiepen/clawbook-lehre:latest
```

Was die Teile bedeuten:

- `docker volume create clawbook-home` — das Home-Volume;
  `-v clawbook-home:/home/student` hängt es als Home ein.
  **Diese Zeile ist die wichtigste:** Das Image bringt
  kein eigenes Volume mit. Vergisst du sie, liegt dein
  Home im Container selbst und ist beim nächsten
  `docker rm` weg.
- `-d` — läuft im Hintergrund.
- `--restart unless-stopped` — die **Neustart-Richtlinie**:
  Docker startet den Container beim Systemstart wieder,
  außer du hast ihn selbst mit `docker stop` angehalten.
- `-p 127.0.0.1:2222:22` — SSH unter `localhost:2222`;
  `-p 127.0.0.1:3390:3389` — der Bildschirm unter
  `localhost:3390`; `-p 127.0.0.1:4445:445` — die
  Dateifreigabe Samba unter `localhost:4445`. Alle nur von
  deinem Rechner aus erreichbar; den Bildschirm (ohne
  Passwort) niemals auf anderen Adressen veröffentlichen.
  Samba ist optional — Zeile weglassen und
  `-e CLAWBOOK_SAMBA=0` mitgeben, wenn du sie nicht willst.
  Beachte: Die Freigabe zeigt das **ganze Home** von
  `student`, auch Anmeldungen und Schlüssel; mit dem
  Ordner aus Abschnitt 1 brauchst du sie kaum.
- `-v "$HOME/source:/home/student/source"` — dein Ordner
  `~/source` als Projektordner im Container (Abschnitt 1).
  Weglassen, wenn du beim Volume bleibst. Auf Fedora und
  anderen Systemen mit SELinux `:Z` anhängen
  (`…:/home/student/source:Z`), sonst darf der Container
  nicht hinein. `:Z` ändert die SELinux-Kennzeichnung
  aller Dateien im Ordner — **niemals** an dein Home oder
  einen Systemordner hängen.

Weiter mit Abschnitt 4.

## 3. Weg B: podman (ungetestet)

### Installieren

podman ist in den meisten Distributionen enthalten:

```bash
sudo apt install podman        # Debian, Ubuntu
sudo dnf install podman        # Fedora
podman --version
```

Du brauchst **podman ab 4.6** — ab dieser Version kennt
Quadlet (der Autostart über systemd) den Eintrag
`UserNS=`. Das haben Debian 13 (5.4), Ubuntu ab 24.04
(4.9) und Fedora. **Debian 12 hat podman 4.3** ohne
Quadlet: Nimm dort den Docker-Weg (Abschnitt 2).

Rootless braucht Subuid-Bereiche für deinen Benutzer;
die Pakete legen sie normalerweise an (`grep "$USER"
/etc/subuid` zeigt eine Zeile). Fehlt sie:
`sudo usermod --add-subuids 100000-165535
--add-subgids 100000-165535 "$USER"`.

### Zum Ausprobieren: von Hand starten

```bash
mkdir -p ~/source
podman volume create clawbook-home
podman run -d --name clawbook \
  --userns=keep-id:uid=1000,gid=1000 \
  --user root \
  -p 127.0.0.1:2222:22 \
  -p 127.0.0.1:3390:3389 \
  -p 127.0.0.1:4445:445 \
  -v clawbook-home:/home/student \
  -v "$HOME/source:/home/student/source" \
  ghcr.io/schlingensiepen/clawbook-lehre:latest
```

Die Teile bedeuten dasselbe wie bei Docker (Abschnitt 2),
mit drei Unterschieden:

- `--userns=keep-id:uid=1000,gid=1000` — rootless podman
  gibt dem Container eigene Benutzernummern; ohne diese
  Option wäre `student` im Container auf deinem Rechner
  ein fremder Benutzer und dürfte nicht in `~/source`
  schreiben. Mit der Option ist `student` = du. Bleibst du
  beim Volume ohne Ordner, kannst du die Option (und
  `--user root`) weglassen.
- `--user root` — `keep-id` lässt den Startprozess sonst
  als dein Benutzer laufen („the init process within the
  container will run under the current user's UID … unless
  you explicitly set `--user`", podman-Dokumentation). Das
  Image muss aber als root starten: Der Prozess-Verwalter
  startet SSH, Bildschirm und Samba. „root" ist hier nur
  root **im Container**; auf deinem Rechner bleibt es dein
  Benutzer.
- **Kein `--restart`:** Bei rootless podman startet die
  Neustart-Richtlinie den Container nach einem Neustart
  des Rechners nicht zuverlässig; podman selbst rät für
  den Autostart zu systemd. Das richtest du im nächsten
  Schritt ein.

Auf Fedora und anderen SELinux-Systemen beim Ordner `:Z`
anhängen (nur dort, nie am Home). Ports über 1024 sind
rootless kein Problem.

### Autostart mit Quadlet

Quadlet ist podmans Verbindung zu systemd: Du beschreibst
den Container in einer kleinen Datei, systemd startet ihn
beim Hochfahren bzw. bei der Anmeldung und startet ihn
neu, wenn er abstürzt. Wenn du den Container oben von Hand
gestartet hast, erst entfernen: `podman stop clawbook &&
podman rm clawbook` (das Volume bleibt).

Datei `~/.config/containers/systemd/clawbook.container`
anlegen:

```ini
[Unit]
Description=clawbook - Arbeitsrechner fuer KI-Agenten

[Container]
Image=ghcr.io/schlingensiepen/clawbook-lehre:latest
ContainerName=clawbook
UserNS=keep-id:uid=1000,gid=1000
User=root
PublishPort=127.0.0.1:2222:22
PublishPort=127.0.0.1:3390:3389
PublishPort=127.0.0.1:4445:445
Volume=clawbook-home:/home/student
Volume=%h/source:/home/student/source

[Service]
Restart=always
TimeoutStartSec=900

[Install]
WantedBy=default.target
```

`%h` ist dein Home-Verzeichnis. Die Zeilen `UserNS`,
`User` und `Volume=%h/source…` weglassen, wenn du ohne
Ordner arbeitest; bei SELinux `:Z` an den Ordner anhängen.
`TimeoutStartSec=900` gibt dem ersten Start Zeit, das
Image zu laden.

Dann:

```bash
mkdir -p ~/source
systemctl --user daemon-reload
systemctl --user start clawbook
systemctl --user status clawbook
```

Beim ersten Start lädt podman das Image (mehrere
Gigabyte). `WantedBy=default.target` sorgt dafür, dass
systemd den Container mit deiner Benutzersitzung startet;
ein `enable` ist bei Quadlet nicht nötig. Dazu kommt
**Linger**: Mit Linger startet der Container schon beim
Hochfahren des Rechners und läuft nach dem Abmelden
weiter; ohne Linger startet er erst nach deiner Anmeldung
und endet mit dem Abmelden. Einmalig:

```bash
loginctl enable-linger "$USER"
```

Befehle für den Alltag mit Quadlet:

```bash
systemctl --user stop clawbook       # anhalten
systemctl --user start clawbook      # starten
systemctl --user restart clawbook    # neu anlegen (z.B. nach podman pull)
journalctl --user -u clawbook -e     # Meldungen
```

`podman ps`, `podman logs clawbook` und `podman exec`
funktionieren daneben wie gewohnt. In den Befehlen unten
steht `docker`; mit podman ersetzt du es durch `podman`.

## 4. Erster Start prüfen

```bash
docker ps
docker logs clawbook
```

Der erste Start („Kaltstart") dauert bis zu drei Minuten;
der Container erzeugt dabei seine Schlüssel. **Warte, bis
`docker logs clawbook` den Kasten mit den Verbindungsdaten
zeigt** — vorher gibt es den SSH-Schlüssel noch nicht.
Der Kasten nennt den **privaten SSH-Schlüssel** und das
**Passwort der Dateifreigabe**. Er ist für den Hauptweg
unter Windows formuliert (`mstsc`, `%USERPROFILE%`, Samba
über Port 445 und die IP der WSL-Distribution); auf diesem
Weg gilt stattdessen: Bildschirm und SSH wie unten, Samba
unter `127.0.0.1:4445`.

Ob alles läuft, zeigt bei Docker `docker ps`: Nach dem
Kaltstart steht in der Spalte „STATUS" `(healthy)` — das
Image prüft selbst, ob SSH, Bildschirm und Samba
antworten. Bei podman prüfst du mit
`podman healthcheck run clawbook` (keine Ausgabe und
Rückgabewert 0 heißt gesund) — oder einfach mit
`ssh clawbook` im nächsten Abschnitt.

## 5. SSH einrichten

Auf deinem Rechner:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
docker exec clawbook cat /home/student/.ssh/id_ed25519 > ~/.ssh/clawbook
chmod 600 ~/.ssh/clawbook
```

Diesen Block an `~/.ssh/config` anhängen (Datei anlegen,
falls sie fehlt):

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
zurück auf deinen Rechner.

## 6. VS Code, Bildschirm, Dateien

- **VS Code:** wie in der [Installation](../installation.md),
  Abschnitt 5 — Erweiterung „Remote - SSH", „Connect to
  Host…" → `clawbook`, Ordner `/home/student/source`.
  Hast du `~/source` eingebunden, kannst du den Ordner
  auch direkt lokal öffnen; Terminal und Werkzeuge hast du
  dann aber nur über die Remote-Verbindung.
- **Bildschirm:** Du brauchst einen Remote-Desktop-Client,
  zum Beispiel **Remmina** (Protokoll RDP, Server
  `127.0.0.1:3390`) oder FreeRDP im Terminal:

  ```bash
  xfreerdp3 /v:127.0.0.1:3390 /cert:ignore
  ```

  (Paket `freerdp3-x11` bzw. `freerdp`; bei älteren
  Versionen heißt der Befehl `xfreerdp`.) `/cert:ignore`
  übergeht die Warnung vor dem selbst ausgestellten
  Zertifikat — vertretbar, weil die Verbindung deinen
  Rechner nicht verlässt. Ein Passwort gibt es nicht.
  Oben in der Leiste: Chromium und ein Terminal, beide
  als `student`.

  **Nur auf einem Rechner, den du allein benutzt:** Der
  Bildschirm hat kein Passwort. Jeder, der sich an deinem
  Rechner anmelden kann, kommt damit in den Container —
  und dort gibt es passwortloses `sudo` und deine
  Anmeldungen. Auf einem Rechner mit mehreren Benutzern
  die Zeile `-p 127.0.0.1:3390:3389` weglassen.
- **Dateien:** Mit dem Ordner aus Abschnitt 1 liegen deine
  Projekte in `~/source` auf deinem Rechner. Die
  Samba-Freigabe (Port 4445) zeigt das ganze Home von
  `student`; Dateimanager wie GNOME „Dateien" nehmen
  `smb://127.0.0.1:4445/student` (Benutzer `student`,
  Passwort aus dem Start-Kasten) — nicht getestet.
  Zuverlässiger geht es mit `mount.cifs` (Paket
  `cifs-utils`):

  ```bash
  mkdir -p ~/clawbook-home
  sudo mount -t cifs //127.0.0.1/student ~/clawbook-home \
    -o port=4445,vers=3.0,user=student,uid="$(id -u)",gid="$(id -g)"
  # später wieder aushängen:
  sudo umount ~/clawbook-home
  ```

## 7. Accounts und Werkzeuge einrichten

Wie jeder Account angelegt und jedes Werkzeug angemeldet
wird, steht im [Setup](../setup/README.md). Die Befehle
dort gibst du **im Container** ein (nach `ssh clawbook`
oder im VS-Code-Terminal). Links aus dem Terminal öffnest
du im Browser deines Rechners; nur NotebookLM braucht den
Browser im Container über den Bildschirm.

## 8. Alltag und aktualisieren

Nach einem Neustart läuft der Container von selbst
(Docker: Neustart-Richtlinie; podman: Quadlet).

```bash
docker ps                 # läuft er?
docker stop clawbook      # anhalten (Docker; bleibt angehalten)
docker start clawbook     # wieder starten
docker logs clawbook      # Start-Kasten und Meldungen
```

Mit Quadlet nimmst du zum Anhalten und Starten
`systemctl --user stop|start clawbook`.

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

2. **Docker:** neues Image ziehen, Container anhalten und
   entfernen, neu anlegen:

   ```bash
   docker pull ghcr.io/schlingensiepen/clawbook-lehre:latest
   docker stop clawbook
   docker rm clawbook
   ```

   Dann den `docker run`-Befehl aus Abschnitt 2 erneut
   ausführen. Danach optional `docker image prune` — das
   löscht alte, nicht mehr benutzte Image-Schichten.

   **podman mit Quadlet:** Quadlet legt den Container bei
   jedem Start neu aus dem Image an; es genügt:

   ```bash
   podman pull ghcr.io/schlingensiepen/clawbook-lehre:latest
   systemctl --user restart clawbook
   ```

Der SSH-Schlüssel bleibt derselbe. Was nicht bleibt:
Installationen außerhalb des Homes (siehe
[Pflege](../pflege.md), Abschnitt 3).

## 9. Sichern und mitnehmen

Ein `tar`-Archiv deines Homes im selben Format wie die
Sicherungen des Windows-Skripts (`home-<datum>.tar`) —
also auch dort importierbar. Ein Hilfscontainer (ein
kleines Debian) packt das Volume; er läuft als root,
deshalb übergibt er die Datei am Ende an dich und macht
sie nur für dich lesbar. Vorher den Container anhalten
(Quadlet: `systemctl --user stop clawbook`).

```bash
ziel="$HOME/clawbook/sicherungen"
mkdir -p "$ziel" && chmod 700 "$ziel"
datei="home-$(date +%Y-%m-%d-%H%M).tar"
docker stop clawbook
docker run --rm -v clawbook-home:/h -v "$ziel:/out" \
  docker.io/library/debian:trixie-slim \
  sh -c "tar -C /h -cpf /out/$datei . && chown $(id -u):$(id -g) /out/$datei && chmod 600 /out/$datei"
docker start clawbook
```

Bei rootless podman gehört die Datei ohnehin dir; das
`chown` schadet nicht.

**Das Archiv enthält deine Anmeldungen und deinen privaten
SSH-Schlüssel** — behandle es wie ein Passwort. Lege den
Ordner **nicht** in einen Cloud-Ordner (Nextcloud,
Dropbox, OneDrive, iCloud); ein Umzug per USB-Stick oder
verschlüsseltem Speicher ist der richtige Weg.

Hast du `~/source` als Ordner eingebunden, ist er im
Archiv **nicht** enthalten (er liegt nicht im Volume) —
sichere ihn getrennt, etwa mit `tar` oder deinem üblichen
Backup. Beim Import auf einem Windows-Rechner landet er
dann nicht automatisch in `~/source`.

### Importieren

Leeres Volume, Archiv entpacken, Container anlegen.
Existiert schon ein Volume, vorher sichern (oben), dann
Container und Volume entfernen — **`docker volume rm`
ist unwiderruflich**, danach ist das alte Home weg:

```bash
docker stop clawbook && docker rm clawbook   # Quadlet: systemctl --user stop clawbook
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

Mit rootless podman gehören die entpackten Dateien danach
`student` nur, wenn du beim Import dieselbe
`--userns`-Einstellung nimmst wie beim Container
(`podman run --rm --userns=keep-id:uid=1000,gid=1000 …`).
Dann Container anlegen (Abschnitt 2 bzw. 3) und SSH
(Abschnitt 5) wiederholen. Meldet SSH „REMOTE HOST
IDENTIFICATION HAS CHANGED":

```bash
ssh-keygen -R "[127.0.0.1]:2222"
```

## Wenn etwas nicht geht

- **„permission denied" beim Aufruf von `docker`** — du
  bist nicht in der Gruppe `docker`, oder die
  Mitgliedschaft gilt noch nicht: `newgrp docker` oder
  neu anmelden.
- **`student` darf nicht in `~/source` schreiben** —
  Benutzernummern passen nicht (Abschnitt 1); bei podman
  fehlt `--userns=keep-id…`; bei SELinux fehlt `:Z`.
- **podman: Container stoppt sofort, Log meldet
  Rechtefehler** — fehlt `--user root` bzw. `User=root`
  neben `keep-id`? Ohne das startet der Prozess-Verwalter
  nicht als root.
- **Quadlet: `systemctl --user start clawbook` meldet
  „Unit clawbook.service not found"** — Datei liegt nicht
  unter `~/.config/containers/systemd/` oder endet nicht
  auf `.container`; nach Änderungen `daemon-reload`.
  Fehler in der Datei zeigt
  `/usr/lib/systemd/system-generators/podman-system-generator --user --dryrun`.
- **Container läuft nach Neustart nicht** (podman) —
  `loginctl enable-linger` gesetzt? `systemctl --user
  status clawbook` und `journalctl --user -u clawbook`
  zeigen, was passiert ist.
- **„port is already allocated"** — Port belegt; andere
  Ports nehmen und `-e CLAWBOOK_SSH_PORT=…` bzw.
  `-e CLAWBOOK_RDP_PORT=…` (Quadlet: `Environment=…`)
  mitgeben, damit der Start-Kasten stimmt; SSH-Config
  anpassen.
- **`ssh clawbook`: „Connection refused"** — Container
  läuft nicht oder ist im Kaltstart: `docker ps`.
- **`ssh clawbook` fragt nach einem Passwort** — Schlüssel
  fehlt, ist unvollständig (zu früh kopiert, vor dem
  Kasten im Log) oder hat nicht Rechte `600`: Abschnitt 5
  wiederholen.
- **`docker ps` zeigt `(unhealthy)`** — ein Dienst im
  Container antwortet nicht; `docker logs clawbook` lesen.
  Hast du Samba mit `-e CLAWBOOK_SAMBA=0` ausgeblendet,
  läuft der Dienst trotzdem; das ist nicht die Ursache.

Kommst du nicht weiter, wende dich an die Betreuung deiner
Lehrveranstaltung. Nutzt du clawbook außerhalb einer
Lehrveranstaltung, öffne ein Issue im GitHub-Repository
des Projekts (`schlingensiepen/clawbook-lehre`).
