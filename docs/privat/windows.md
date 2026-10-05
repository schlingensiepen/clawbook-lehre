# Windows: clawbook dauerhaft auf dem eigenen Rechner

Stand: 2026-10-05

**Nicht vom Kurs getestet.** Dieser Weg ist für deinen
eigenen Windows-Rechner, auf dem du Administrator bist. Der
getestete Weg für Windows ist die
[Installation](../installation.md) mit WSLC — auch auf dem
eigenen Rechner. Wann sich dieser Weg trotzdem lohnt,
steht in der [Übersicht](README.md).

Diese Seite beschreibt **Docker Desktop** (Abschnitte
1–9). Am Ende stehen zwei Alternativen: der Hauptweg mit
automatischem Start (Abschnitt 10) und — für
Fortgeschrittene — Podman Desktop (Abschnitt 11).

Wo du welchen Befehl eingibst: Befehle in
`powershell`-Blöcken laufen **auf deinem Windows-Rechner**.
Nach `ssh clawbook` bist du **im Container**; das erkennst
du an der Eingabeaufforderung `student@…:~$`, und Befehle
stehen dann in `bash`-Blöcken. Mit `exit` bist du wieder
unter Windows.

## 1. Voraussetzungen

- **Windows 10 oder 11, 64 Bit**, mit WSL 2. Docker
  Desktop nutzt WSL 2 als Unterbau (laut
  Docker-Dokumentation: Windows 10 ab 22H2, Windows 11 ab
  23H2, WSL ab 2.1.5, 8 GB RAM). Prüfen in PowerShell mit
  `wsl --version`; fehlt WSL, installiert es
  `wsl --install` in einer PowerShell „als Administrator",
  danach Windows neu starten. Das erstmalige Einrichten
  von WSL 2 braucht laut Docker Administrator-Rechte —
  einmalig pro Rechner.
- **Hardware-Virtualisierung** im BIOS/UEFI aktiviert
  (bei den meisten Rechnern schon der Fall).
- **Mindestens 20 GB** freier Platz.
- **Lizenz** (Stand Oktober 2026, prüfe selbst): Docker
  Desktop ist laut Docker kostenlos für „personal use,
  education, and non-commercial open source projects"
  sowie Firmen unter 250 Beschäftigten und 10 Mio. USD
  Umsatz. Als Studierende mit eigenem Rechner fällst du
  darunter. Beim ersten Start musst du die
  Docker-Nutzungsbedingungen akzeptieren; die aktuellen
  Bedingungen stehen unter
  <https://www.docker.com/pricing/faq/>.

## 2. Docker Desktop installieren

1. Installer laden von
   <https://docs.docker.com/desktop/setup/install/windows-install/>
   und ausführen. Der Installer fragt zwei Dinge:
   - **Installationsart:** „per-user" (Vorgabe, empfohlen)
     installiert nach `%LOCALAPPDATA%\Programs\DockerDesktop`
     und „requires no administrator privileges"; „all
     users" fragt nach Administrator-Rechten. Nimm
     „per-user".
   - **Unterbau:** „Use WSL 2 instead of Hyper-V"
     angehakt lassen.
2. Docker Desktop starten, die Nutzungsbedingungen
   akzeptieren. Ein Docker-Konto brauchst du nicht; „Skip"
   bzw. „Continue without signing in" wählen.
3. In Docker Desktop unter **Settings → General** das
   Häkchen **„Start Docker Desktop when you sign in to
   your computer"** setzen. Ohne das Häkchen läuft der
   Container nach einem Neustart erst, wenn du Docker
   Desktop von Hand öffnest.
4. Prüfen — in PowerShell:

   ```powershell
   docker version
   ```

   Zeigt es einen „Server"-Abschnitt, läuft Docker.

## 3. Container anlegen und starten

Alles Folgende in PowerShell (kein Administrator nötig).

```powershell
docker volume create clawbook-home
docker run -d --name clawbook `
  --restart unless-stopped `
  -p 127.0.0.1:2222:22 `
  -p 127.0.0.1:3390:3389 `
  -e CLAWBOOK_SAMBA=0 `
  -v clawbook-home:/home/student `
  ghcr.io/schlingensiepen/clawbook-lehre:latest
```

Was die Teile bedeuten:

- `docker volume create clawbook-home` — legt das
  Home-Volume an. `-v clawbook-home:/home/student` hängt
  es als Home ein. **Diese Zeile ist die wichtigste:** Das
  Image bringt kein eigenes Volume mit. Vergisst du sie,
  liegt dein Home im Container selbst und ist beim
  nächsten `docker rm` weg.
- `-d` — der Container läuft im Hintergrund.
- `--restart unless-stopped` — die **Neustart-Richtlinie**:
  Docker startet den Container wieder, wenn Docker
  startet (also nach jedem Neustart von Windows) — außer
  du hast ihn selbst mit `docker stop` angehalten.
- `-p 127.0.0.1:2222:22` — SSH ist unter `localhost:2222`
  erreichbar; `-p 127.0.0.1:3390:3389` — der Bildschirm
  unter `localhost:3390`. Beide nur von deinem Rechner aus.
- `-e CLAWBOOK_SAMBA=0` — blendet die Dateifreigabe
  (Samba) in der Start-Anzeige aus. Der Windows-Explorer
  öffnet Freigaben nur über Port 445, und den belegt
  Windows auf deinem Rechner selbst; eine Freigabe des
  Containers auf einem anderen Port kann der Explorer
  nicht öffnen. Zu deinen Dateien kommst du deshalb über
  VS Code (Abschnitt 5).

Beim ersten Mal lädt Docker zuerst das Image (mehrere
Gigabyte, einige Minuten). Der erste Start („Kaltstart")
dauert danach bis zu drei Minuten: Der Container erzeugt
seine Schlüssel. Prüfen:

```powershell
docker ps
docker logs clawbook
```

`docker ps` zeigt den Container; in der Spalte „STATUS"
steht nach dem Kaltstart `(healthy)` — das Image prüft
selbst, ob seine Dienste antworten. **Warte, bis
`docker logs clawbook` den Kasten mit den Verbindungsdaten
zeigt** — vorher gibt es den SSH-Schlüssel noch nicht.
Der Kasten nennt deinen **privaten SSH-Schlüssel**; er
kommt bei jedem Start wieder. Nicht weitergeben.

## 4. SSH einrichten

SSH ist das Verfahren, mit dem du dich im Container
anmeldest — statt eines Passworts mit einer
Schlüsseldatei. Der Schlüssel liegt im Container; du
kopierst ihn nach Windows und schützt die Datei.

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.ssh" | Out-Null
docker cp clawbook:/home/student/.ssh/id_ed25519 "$env:USERPROFILE\.ssh\clawbook"
icacls "$env:USERPROFILE\.ssh\clawbook" /inheritance:r /grant:r "$($env:USERDOMAIN)\$($env:USERNAME):R"
```

`docker cp` kopiert die Datei unverändert (eine
Umleitung mit `>` in PowerShell kann die Kodierung
verändern, dann lehnt SSH den Schlüssel ab). `icacls`
macht die Datei nur für deinen Windows-Benutzer lesbar;
SSH verweigert Schlüssel, die andere lesen könnten.

Dann in die Datei `%USERPROFILE%\.ssh\config` (anlegen,
falls sie fehlt; Editor: `notepad $env:USERPROFILE\.ssh\config`)
diesen Block eintragen:

```text
Host clawbook
  HostName 127.0.0.1
  Port 2222
  User student
  IdentityFile ~/.ssh/clawbook
  IdentitiesOnly yes
```

Prüfen:

```powershell
ssh clawbook
```

Beim ersten Mal merkt sich SSH den Container als bekannten
Rechner („Permanently added …"). **Ab hier bist du im
Container**, als `student`; die Eingabeaufforderung zeigt
`student@…:~$`. Dort:

```bash
clawbook-check
```

zeigt, ob alle Werkzeuge da sind. `exit` bringt dich
zurück nach Windows.

## 5. VS Code und Bildschirm

Beides geht genau wie im Hauptweg — siehe
[Installation](../installation.md), Abschnitte 5 und 6:

- **VS Code:** Erweiterung „Remote - SSH", „Connect to
  Host…" → `clawbook`, Ordner `/home/student/source`.
- **Bildschirm:** `mstsc /v:localhost:3390`,
  Zertifikatswarnung bestätigen, kein Passwort.

**Nur auf einem Rechner, den du allein benutzt:** Der
Bildschirm hat kein Passwort. Jeder, der sich an deinem
Rechner anmelden kann, kommt damit in den Container — und
dort gibt es passwortloses `sudo` und deine Anmeldungen.
Auf einem Rechner mit mehreren Benutzern die Zeile
`-p 127.0.0.1:3390:3389` weglassen.

## 6. Accounts und Werkzeuge einrichten

Die KI-Werkzeuge sind installiert, aber nicht angemeldet.
Wie du jeden Account anlegst und jedes Werkzeug anmeldest,
steht im [Setup](../setup/README.md). Die Befehle dort
gibst du **im Container** ein (nach `ssh clawbook` oder im
VS-Code-Terminal). Alles, was du einrichtest, landet im
Home-Volume.

## 7. Alltag: starten, anhalten, Status

Nach einem Neustart von Windows startet Docker Desktop
(Häkchen aus Abschnitt 2) und mit ihm der Container. Du
musst nichts tun; `ssh clawbook` geht, sobald der Status
`(healthy)` ist.

```powershell
docker ps                 # läuft der Container?
docker stop clawbook      # anhalten (bleibt angehalten, auch nach Neustart)
docker start clawbook     # wieder starten (Neustart-Richtlinie gilt wieder)
docker logs clawbook      # Start-Kasten und Meldungen
```

## 8. Aktualisieren

Ein neues Image bringt neuere Werkzeuge. Du entfernst den
Container und legst ihn mit demselben Volume neu an — das
Home bleibt, **wenn es im Volume liegt**. Deshalb vorher
prüfen und sichern:

0. **Sicherung schreiben** (Abschnitt 9). Immer.
1. **Prüfen, dass das Home im Volume liegt:**

   ```powershell
   docker inspect clawbook --format '{{json .Mounts}}'
   ```

   In der Ausgabe muss `"Name":"clawbook-home"` mit
   `"Destination":"/home/student"` stehen. Fehlt das,
   liegt dein Home im Container — dann **nicht**
   entfernen, sondern erst retten:
   `docker exec clawbook tar -C /home/student -cpf /tmp/home.tar .`
   und `docker cp clawbook:/tmp/home.tar .`.

2. Neues Image ziehen, Container anhalten und entfernen,
   neu anlegen:

   ```powershell
   docker pull ghcr.io/schlingensiepen/clawbook-lehre:latest
   docker stop clawbook
   docker rm clawbook
   docker run -d --name clawbook `
     --restart unless-stopped `
     -p 127.0.0.1:2222:22 `
     -p 127.0.0.1:3390:3389 `
     -e CLAWBOOK_SAMBA=0 `
     -v clawbook-home:/home/student `
     ghcr.io/schlingensiepen/clawbook-lehre:latest
   ```

   Danach optional `docker image prune` — das löscht
   alte, nicht mehr benutzte Image-Schichten.

Dein SSH-Schlüssel bleibt derselbe; VS Code verbindet sich
danach ohne weitere Fragen. Was **nicht** bleibt: alles,
was du außerhalb des Homes installiert hast (etwa mit
`sudo apt install`) — siehe [Pflege](../pflege.md),
Abschnitt 3.

## 9. Sichern und mitnehmen

Die Sicherung ist ein `tar`-Archiv deines Homes. Es hat
dasselbe Format wie die Sicherungen des Verwaltungs-Skripts
(`home-<datum>.tar`), du kannst es also auch dort
importieren — und umgekehrt. Ein Hilfscontainer (ein
kleines Debian) packt das Volume; vorher den Container
anhalten, damit die Sicherung in sich stimmig ist.

```powershell
$ziel = "$env:USERPROFILE\clawbook\sicherungen"
New-Item -ItemType Directory -Force $ziel | Out-Null
$datei = "home-$(Get-Date -Format yyyy-MM-dd-HHmm).tar"
docker stop clawbook
docker run --rm -v clawbook-home:/h -v "${ziel}:/out" docker.io/library/debian:trixie-slim `
  tar -C /h -cpf "/out/$datei" .
docker start clawbook
```

**Die Sicherung enthält deine Anmeldungen und deinen
privaten SSH-Schlüssel.** Behandle sie wie ein Passwort.
Lege den Ordner **nicht** in einen Cloud-Ordner (OneDrive,
Dropbox, iCloud); prüfe, dass `%USERPROFILE%\clawbook`
nicht von OneDrive erfasst wird. Ein Umzug per USB-Stick
oder verschlüsseltem Speicher ist der richtige Weg.

### Importieren

Auf diesem oder einem anderen Rechner: leeres Volume
anlegen, Archiv hineinpacken, Container anlegen. Existiert
schon ein Volume, vorher sichern (oben), dann Container
und Volume entfernen — **`docker volume rm` ist
unwiderruflich**, danach ist das alte Home weg:

```powershell
docker stop clawbook
docker rm clawbook
docker volume rm clawbook-home
```

Dann importieren — `<deine-datei>.tar` durch den Namen
deiner Sicherung ersetzen:

```powershell
$ziel = "$env:USERPROFILE\clawbook\sicherungen"
docker volume create clawbook-home
docker run --rm -v clawbook-home:/h -v "${ziel}:/in" docker.io/library/debian:trixie-slim `
  tar -C /h -xpf "/in/<deine-datei>.tar"
```

Danach den `docker run`-Befehl aus Abschnitt 3 ausführen
und SSH wie in Abschnitt 4 einrichten — der Schlüssel aus
der Sicherung ist jetzt der gültige. Hat der Rechner den
Container schon einmal gekannt, meldet SSH „REMOTE HOST
IDENTIFICATION HAS CHANGED"; dann:

```powershell
ssh-keygen -R "[127.0.0.1]:2222"
```

## 10. Alternative: Hauptweg mit automatischem Start

Du kannst auch einfach beim [Hauptweg](../installation.md)
bleiben — er läuft auf dem eigenen Rechner genauso — und
nur den Start nach der Anmeldung automatisieren. WSLC
kennt keine Neustart-Richtlinie; stattdessen lässt du
Windows das Verwaltungs-Skript bei jeder Anmeldung mit der
Aktion `start` aufrufen. **Nur, wenn du das
Verwaltungs-Skript und seine Parameter kennst** (siehe
[Pflege](../pflege.md), Abschnitt 9) — und nicht
getestet. Einmalig, in PowerShell:

```powershell
$skript = "$env:LOCALAPPDATA\clawbook\clawbook.ps1"
schtasks /Create /TN clawbook-start /SC ONLOGON /RL LIMITED `
  /TR "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$skript`" -Action start"
```

Voraussetzung: Die Installation ist einmal durchgelaufen,
damit das Skript unter `%LOCALAPPDATA%\clawbook\` liegt.
Die Aufgabe startet die **gespeicherte** Fassung des
Skripts; neue Fassungen holst du weiterhin mit dem Befehl
von der Startseite. Entfernen mit
`schtasks /Delete /TN clawbook-start /F`.

## 11. Für Fortgeschrittene: Podman Desktop

Podman ist frei (Apache-Lizenz) und braucht kein Konto und
keine Nutzungsbedingungen. Unter Windows läuft es ebenfalls
in einer WSL-2-Maschine („Podman machine"). Die Befehle
sind dieselben wie oben mit `podman` statt `docker` —
aber dieser Weg ist **noch weniger erprobt** als Docker
Desktop, und der automatische Start nach einem Neustart
fehlt.

1. Podman Desktop installieren von
   <https://podman-desktop.io/docs/installation/windows-install>
   (Installer oder `winget install RedHat.Podman-Desktop`;
   die Dokumentation nennt Administrator-Rechte als
   Voraussetzung). Beim ersten Start bietet es an, Podman
   selbst zu installieren und eine Maschine anzulegen —
   zustimmen; die Vorgabe ist „rootless". Das reicht: Alle
   Ports von clawbook liegen über 1024.
2. In **Settings → Preferences** die Punkte „Start on
   login" und „Autostart engine on launch" eingeschaltet
   lassen — dann läuft die Podman-Maschine nach der
   Anmeldung von selbst.
3. Volume und Container anlegen, ohne Neustart-Richtlinie:

   ```powershell
   podman volume create clawbook-home
   podman run -d --name clawbook `
     -p 127.0.0.1:2222:22 `
     -p 127.0.0.1:3390:3389 `
     -e CLAWBOOK_SAMBA=0 `
     -v clawbook-home:/home/student `
     ghcr.io/schlingensiepen/clawbook-lehre:latest
   ```

4. Schlüssel holen mit `podman cp` (sonst wie Abschnitt 4),
   VS Code und Bildschirm wie Abschnitt 5. Ob der Container
   läuft, prüfst du mit `podman ps` und
   `podman healthcheck run clawbook` (Rückgabewert 0 =
   gesund) oder einfach mit `ssh clawbook`.

**Nach jedem Neustart von Windows** startest du den
Container von Hand — das ist hier der verlässliche Weg:

```powershell
podman start clawbook
```

(Eine Neustart-Richtlinie wie bei Docker greift in
rootless Podman-Maschinen unter Windows nicht zuverlässig;
darum ist sie oben weggelassen.) Aktualisieren und Sichern
gehen wie in den Abschnitten 8 und 9 mit `podman` statt
`docker`.

## Wenn etwas nicht geht

- **`docker version` zeigt keinen „Server"** — Docker
  Desktop läuft nicht; aus dem Startmenü öffnen und
  warten, bis das Wal-Symbol ruhig ist. Beim ersten Start
  nach der Installation kann Docker eine WSL-Aktualisierung
  verlangen.
- **„port is already allocated"** bei `docker run` — Port
  2222 oder 3390 ist belegt, zum Beispiel vom Container
  des Hauptwegs (WSLC). Den anderen Container anhalten
  oder hier andere Ports nehmen; dann
  `-e CLAWBOOK_SSH_PORT=<port>` bzw.
  `-e CLAWBOOK_RDP_PORT=<port>` mitgeben, damit der
  Start-Kasten die richtigen Nummern zeigt, und die
  SSH-Config anpassen.
- **`ssh clawbook`: „Connection refused"** — der Container
  läuft nicht oder ist noch im Kaltstart: `docker ps`,
  `docker logs clawbook`.
- **`ssh clawbook` fragt nach einem Passwort** oder meldet
  „Permissions … are too open" — Schlüsseldatei fehlt,
  ist unvollständig (zu früh kopiert, vor dem Kasten im
  Log) oder hat falsche Rechte: Abschnitt 4 wiederholen.
- **„Could not resolve hostname clawbook"** — der Block
  in `%USERPROFILE%\.ssh\config` fehlt oder die Datei
  heißt `config.txt`. Im Explorer die Endung prüfen.
- **Remotedesktop zeigt nur Schwarz** — ein paar Sekunden
  warten und neu verbinden; der Bildschirm startet kurz
  nach SSH.
- **Nach einem Neustart läuft der Container nicht** —
  Häkchen „Start Docker Desktop when you sign in" gesetzt?
  Wurde der Container mit `docker stop` angehalten? Dann
  gilt die Neustart-Richtlinie erst nach `docker start`
  wieder.
- **Alles ist sehr langsam** — Docker Desktop unter
  **Settings → Resources** mehr Arbeitsspeicher und
  CPU-Kerne geben; die Vorgabe ist für clawbook knapp.

Kommst du nicht weiter, wende dich an die Betreuung deiner
Lehrveranstaltung. Nutzt du clawbook außerhalb einer
Lehrveranstaltung, öffne ein Issue im GitHub-Repository
des Projekts (`schlingensiepen/clawbook-lehre`).
