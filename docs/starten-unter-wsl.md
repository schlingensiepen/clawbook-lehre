# Den Arbeitsrechner unter Windows starten

Diese Anleitung zeigt, wie du das Image unter Windows
mit WSL und podman startest, dich per SSH verbindest
und deinen eigenen Stand behältst.

> **Stand:** im Aufbau. Die Anleitung beschreibt das
> erste Image: Werkzeuge und SSH-Zugang. Grafische
> Oberfläche (Browser per Remote-Desktop) und
> Dateizugriff per Windows-Freigabe folgen.

## Worum es geht

Das Image ist ein vorbereiteter Linux-Arbeitsrechner:
Git, Node.js, Python und mehrere KI-Agenten-Werkzeuge
sind schon installiert. Du startest ihn als
**Container** in WSL, dem Linux-Subsystem von Windows.
Gearbeitet wird als Benutzer `student`, verbunden per
SSH — so können auch Werkzeuge wie ein
Terminal-Verwalter unter Windows mehrere
tmux-Sitzungen im Container öffnen.

Warum so: Für den Start brauchst du unter Windows
**keine Administrator-Rechte** — der Container läuft
als normaler Benutzer (podman „rootless"), und alle
Verbindungen gehen über `localhost`.

## 1. WSL bereitstellen

Du brauchst eine WSL-Distribution, z.B. Debian oder
Ubuntu, in WSL 2.

_(Abschnitt in Arbeit: ob WSL auf deinem Rechner schon
eingerichtet ist und wie du es sonst bekommst — die
erstmalige Installation von WSL kann
Administrator-Rechte brauchen.)_

Prüfen, ob WSL da ist — in PowerShell:

```powershell
wsl --list --verbose
```

Eine Distribution mit `VERSION 2` genügt.

## 2. podman in WSL installieren

Öffne deine WSL-Distribution (z.B. „Debian" im
Startmenü) und installiere podman:

```bash
sudo apt update
sudo apt install -y podman
podman --version
```

Das `sudo` hier betrifft nur die Linux-Distribution in
WSL — dort bist du selbst Administrator, unter Windows
brauchst du dafür keine Rechte.

## 3. Das Image holen und starten

Zuerst ein **Volume** für dein Home-Verzeichnis
anlegen. Darin liegt alles, was du im Container
einrichtest: Logins der Werkzeuge, Einstellungen,
deine Projekte, dein SSH-Schlüssel.

```bash
podman volume create clawbook-home
```

Dann den Container starten:

```bash
podman run -it --name clawbook \
  -p 127.0.0.1:2222:22 \
  -v clawbook-home:/home/student \
  ghcr.io/schlingensiepen/clawbook-lehre:latest
```

Was die Teile bedeuten:

- `-it` — du bekommst gleich eine Shell im Container.
- `-p 127.0.0.1:2222:22` — der SSH-Server im Container
  ist unter Windows als `localhost:2222` erreichbar.
  Nicht Port 22: den kann Windows selbst belegen, dann
  käme deine Verbindung beim falschen Dienst an.
- `-v clawbook-home:/home/student` — dein
  Home-Verzeichnis liegt im Volume und überlebt
  Neustarts und neue Image-Versionen.

Beim Start zeigt der Container einen Kasten mit den
Verbindungsdaten und deinem **privaten SSH-Schlüssel**.
Beim allerersten Start wird der Schlüssel erzeugt,
danach wird derselbe wieder angezeigt.

## 4. Per SSH verbinden

Den angezeigten privaten Schlüssel speicherst du unter
Windows als Datei, z.B.
`%USERPROFILE%\.ssh\clawbook` — vollständig, von
`-----BEGIN OPENSSH PRIVATE KEY-----` bis
`-----END OPENSSH PRIVATE KEY-----`.

Dann in PowerShell oder Windows Terminal:

```powershell
ssh -i $env:USERPROFILE\.ssh\clawbook -p 2222 student@localhost
```

Bequemer mit einem Eintrag in
`%USERPROFILE%\.ssh\config`:

```text
Host clawbook
  HostName localhost
  Port 2222
  User student
  IdentityFile ~/.ssh/clawbook
```

Danach genügt `ssh clawbook` — auch für Werkzeuge, die
SSH-Verbindungen und tmux-Sitzungen verwalten.

Im Container prüfst du mit `clawbook-check`, ob alle
Werkzeuge da sind.

## 5. Beenden und wieder starten

- Die Shell aus Schritt 3 mit `exit` verlassen — der
  Container stoppt.
- Wieder starten (mit Shell):

  ```bash
  podman start -ai clawbook
  ```

- Nur im Hintergrund laufen lassen (für SSH genügt
  das):

  ```bash
  podman start clawbook
  ```

## 6. Deinen Stand behalten und wiederverwenden

**Der Normalfall: das Volume.** Alles in
`/home/student` liegt im Volume `clawbook-home`. Die
Werkzeuge legen ihre Logins und Sitzungen dort ab
(z.B. `~/.claude`, `~/.codex`, `~/.copilot`,
`~/.config/gh`, `~/.notebooklm`). Für eine neue
Image-Version löschst du nur den Container und
startest neu — dein Stand bleibt:

```bash
podman pull ghcr.io/schlingensiepen/clawbook-lehre:latest
podman rm clawbook
podman run -it --name clawbook -p 127.0.0.1:2222:22 \
  -v clawbook-home:/home/student \
  ghcr.io/schlingensiepen/clawbook-lehre:latest
```

Die Werkzeuge selbst liegen außerhalb des
Home-Verzeichnisses; deshalb bringt ein neues Image
wirklich neue Versionen mit, ohne deine Einstellungen
anzufassen.

**Sichern oder weitergeben: das Volume exportieren.**

```bash
podman volume export clawbook-home --output clawbook-home.tar
# auf einem anderen Rechner:
podman volume create clawbook-home
podman volume import clawbook-home clawbook-home.tar
```

Achtung: Das Archiv enthält deine Logins und deinen
privaten Schlüssel — behandle es wie ein Passwort.

**Den ganzen Container als eigenes Image speichern.**
Wenn du außerhalb deines Home-Verzeichnisses etwas
installiert hast (z.B. mit `sudo apt install`), geht
das beim Neu-Erstellen des Containers verloren. Dann
kannst du den Container als eigenes Image festhalten:

```bash
podman commit clawbook mein-clawbook:2026-10
```

und später statt des offiziellen Images
`mein-clawbook:2026-10` starten. Nachteil: Updates des
offiziellen Images bekommst du so nicht mehr.

## Wenn etwas nicht geht

- **`ssh` meldet „Connection refused"** — läuft der
  Container? `podman ps` in WSL zeigt es.
- **`ssh` fragt nach einem Passwort** — der Schlüssel
  wurde nicht gefunden oder nicht vollständig
  gespeichert; `-i` und Dateiinhalt prüfen.
- **Warnung „REMOTE HOST IDENTIFICATION HAS CHANGED"**
  — das passiert nur, wenn du das Volume neu angelegt
  hast; dann den Eintrag für `[localhost]:2222` aus
  `%USERPROFILE%\.ssh\known_hosts` entfernen.
