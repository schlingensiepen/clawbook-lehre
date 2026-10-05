# Installation: clawbook starten und verbinden

Stand: 2026-10-05

Diese Anleitung bringt clawbook auf deinen Windows-Rechner:
Du führst einen Befehl aus, wartest, bis der Arbeitsrechner
läuft, und verbindest dich dann mit Terminal, VS Code und
Bildschirm. Administrator-Rechte brauchst du dafür nicht.
Plane für den ersten Durchlauf etwa eine Stunde ein; das
meiste davon ist Wartezeit beim Herunterladen.

Wenn du noch nicht weißt, was clawbook ist, oder ein Wort
nicht kennst (Container, Image, Volume, SSH, Port …): Der
[Wegweiser](README.md) erklärt das Projekt und die
Begriffe.

Schreibweise in dieser Anleitung: Pfade wie
`%USERPROFILE%\clawbook` sind Windows-Pfade;
`%USERPROFILE%` steht für dein Benutzerprofil, meist
`C:\Users\<dein-name>`. So kannst du sie in die Adresszeile
des Windows-Explorers einfügen. In PowerShell heißt
dasselbe `$env:USERPROFILE`.

## 1. Voraussetzungen

Du brauchst:

- **Windows 11 oder Windows 10** mit **WSL ab Version
  3.0.1** (Prüfung unten).
- Den **OpenSSH-Client** von Windows (Prüfung unten).
- **Platz auf der Festplatte**: Das Image ist mehrere
  Gigabyte groß, und dein Home-Verzeichnis im Container
  wächst mit deinen Projekten. Rechne mit mindestens 20 GB
  freiem Platz.
- **Internetzugang** zu GitHub und zu `ghcr.io` (dort
  liegt das Image). Für den ersten Start werden einige GB
  geladen: Nimm eine stabile Verbindung (Hochschule,
  zu Hause), nicht das WLAN im Zug oder einen
  Handy-Hotspot.

### WSL prüfen

PowerShell öffnen: Startmenü, „PowerShell" eintippen,
Enter. Dann eingeben:

```powershell
wsl --version
```

Die erste Zeile zeigt die WSL-Version. Das Skript nennt sie
später „WSLC-Version" — es ist dieselbe Nummer. Ist sie
älter als 3.0.1, aktualisierst du WSL mit:

```powershell
wsl --update
```

Das geht **ohne** Administrator-Rechte. Das Skript aus dem
nächsten Schritt fragt dich das auch selbst, wenn die
Version zu alt ist.

Zeigt `wsl --version` einen Fehler oder ist der Befehl
unbekannt, ist WSL auf dem Rechner noch gar nicht
installiert. Die **erstmalige Installation** von WSL
(`wsl --install`) kann Administrator-Rechte brauchen und
einen Neustart. Auf einem Hochschul-Rechner wende dich dann
an die IT oder an die Betreuung deiner Lehrveranstaltung;
auf deinem eigenen Rechner führst du den Befehl in einer
PowerShell „als Administrator" aus und startest Windows
danach neu.

### OpenSSH-Client prüfen

```powershell
ssh -V
```

Erscheint eine Versionsnummer (`OpenSSH_…`), ist alles da.
Kommt „nicht erkannt", fehlt der OpenSSH-Client: Unter
„Einstellungen → System → Optionale Features" (bei
Windows 10: „Apps → Optionale Features") nach „OpenSSH"
suchen und den **OpenSSH-Client** hinzufügen. Das geht
meist ohne Administrator-Rechte; wenn nicht, IT fragen.

### Wenn die Hochschule etwas blockiert

Auf Hochschul-Rechnern kann einiges gesperrt sein: der
Zugriff auf GitHub oder `ghcr.io` (Proxy, Firewall), das
Ausführen von PowerShell-Skripten, oder der Virenschutz
meldet den Befehl aus Abschnitt 2. Das kannst du nicht
selbst lösen. Notiere die Meldung (Foto oder kopierter
Text) und wende dich an die Betreuung deiner
Lehrveranstaltung; sie klärt es mit der IT.

## 2. Der eine Befehl

Alles Weitere erledigt ein Verwaltungs-Skript. Du musst es
nicht herunterladen oder installieren: Ein Befehl holt
immer die aktuelle Fassung und startet sie. Derselbe
Befehl dient später auch zum Starten, Aktualisieren und
Sichern.

1. PowerShell öffnen (kein Administrator nötig).
2. Diesen Befehl kopieren, in PowerShell mit **Rechtsklick**
   einfügen und mit Enter ausführen:

   ```powershell
   irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
   ```

   `irm` lädt das Skript aus dem Internet, `iex` führt es
   aus. Das Skript landet unter
   `%LOCALAPPDATA%\clawbook\clawbook.ps1`; dort kannst du
   es jederzeit nachlesen. Als Erstes nennt es den Pfad
   seines Protokolls („Protokoll: …") — den brauchst du
   nur, wenn etwas schiefgeht.

3. Das Skript prüft WSL und den OpenSSH-Client und sagt
   dir, wenn etwas fehlt (dann zurück zu Abschnitt 1).
   Ist WSL zu alt, bietet es `wsl --update` an: mit
   Enter bestätigen, danach den Befehl erneut ausführen.
4. Es erscheint ein Menü. Beim allerersten Mal sieht es
   so aus:

   ```text
   clawbook – was möchtest du tun?
     [1] neu einrichten (Vorgabe)
     [2] aus einer Sicherung importieren
     [0] beenden
   Auswahl [1]
   ```

   Enter drücken (oder `1` eingeben) wählt **neu
   einrichten**. Punkt 2 brauchst du nur, wenn du schon
   eine Sicherung von einem anderen Rechner mitbringst —
   das steht in der [Pflege-Anleitung](pflege.md),
   Abschnitt 6.

Erscheint stattdessen eine **rote Fehlermeldung**: nicht
schließen — das Skript wartet mit „Drücke Enter, um zu
beenden", damit du den Text lesen kannst. Schau in den
Abschnitt „Wenn etwas nicht geht" am Ende dieser Seite.

## 3. Was beim ersten Start passiert

**Jetzt musst du nichts tun, nur warten.** Das Skript sagt
dir, was es gerade tut:

- **Image laden** — das Image ist die fertige Vorlage des
  Arbeitsrechners mit allen Werkzeugen. Es ist **mehrere
  Gigabyte** groß. Das Skript zeigt den Fortschritt des
  Downloads und sagt dazu: „Das kann 5 bis 20 Minuten
  dauern – bitte nicht abbrechen und das Fenster offen
  lassen." Genau das: nicht `Strg+C` drücken, das Fenster
  nicht schließen, WLAN oder Netzkabel nicht trennen. Der
  Download passiert nur beim ersten Mal und bei einer
  Aktualisierung. Ein kleines Hilfsimage für spätere
  Sicherungen wird gleich mitgeladen.
- **Home-Volume anlegen** — ein Volume ist ein eigener
  Speicherbereich für deine Daten, getrennt vom Image.
  Darin liegt dein Home-Verzeichnis `/home/student` mit
  allem, was du später einrichtest. Es überlebt
  Aktualisierungen des Images.
- **Container anlegen und starten** — der Container ist
  das laufende Exemplar des Images.
- **Warten auf den Container** — der erste Start
  („Kaltstart") dauert **bis zu drei Minuten**, weil der
  Container seine Schlüssel erzeugt. Das Skript wartet und
  meldet sich dann.
- **SSH einrichten** — damit du dich verbinden kannst
  (Erklärung im nächsten Abschnitt).

Am Ende zeigt das Skript einen grünen Kasten „clawbook
läuft." mit den nächsten Schritten als nummerierte Liste:
Terminal, VS Code, Bildschirm. Diesen Kasten siehst du bei
jedem Start wieder; die Abschnitte 4 bis 6 erklären die
drei Schritte ausführlich.

### Was das Skript auf deinem Rechner eingerichtet hat

- **Einen SSH-Schlüssel** unter `%USERPROFILE%\.ssh\clawbook`.
  SSH ist das Verfahren, mit dem du dich von Windows aus
  im Container anmeldest. Statt eines Passworts dient eine
  Schlüsseldatei; sie ist nur für deinen Windows-Benutzer
  lesbar. Behandle sie wie ein Passwort: nicht kopieren,
  nicht verschicken.
- **Den Host `clawbook`** in der Datei
  `%USERPROFILE%\.ssh\config`. Damit weiß SSH, dass
  `clawbook` den Container auf deinem eigenen Rechner
  (Adresse `127.0.0.1`, Port 2222) meint und welchen
  Schlüssel es nehmen soll. Der Eintrag steht zwischen
  zwei Markierungszeilen; das Skript pflegt ihn selbst,
  ändere ihn nicht von Hand.
- **Den Austauschordner** `%USERPROFILE%\clawbook\austausch`.
  Er ist im Container als `~/austausch` sichtbar — der
  einzige Ordner, den Windows und Container gemeinsam
  sehen (Abschnitt 7). `~` ist im Container die Abkürzung
  für dein Home-Verzeichnis `/home/student`.
- **Den Ordner für Sicherungen**
  `%USERPROFILE%\clawbook\sicherungen` (siehe
  [Pflege](pflege.md)).

## 4. Verbinden im Terminal

Öffne ein **neues** PowerShell-Fenster (das Fenster mit
dem Menü kannst du offen lassen oder mit `0` beenden) und
gib ein:

```powershell
ssh clawbook
```

Beim allerersten Verbinden merkt sich SSH den Container als
bekannten Rechner und zeigt „Permanently added …" — das ist
normal und kommt nicht wieder.

Du bist jetzt im Container angemeldet, als Benutzer
`student`. Die Eingabeaufforderung wechselt von `PS C:\…>`
zu `student@…:~$`. Alles, was du hier eingibst, läuft im
Container, nicht unter Windows. Mit `exit` kommst du
zurück nach PowerShell; der Container läuft weiter.

## 5. Verbinden mit VS Code

Mit Visual Studio Code bearbeitest du deine Projekte im
Container so, als lägen sie unter Windows: Der Editor
läuft unter Windows, Dateien, Terminal und Git aber im
Container. Das ist schneller und zuverlässiger, als die
Dateien nach Windows zu kopieren.

VS Code gibt es auf Deutsch und auf Englisch; die Menüs
stehen hier in beiden Sprachen.

1. VS Code installieren, falls noch nicht geschehen
   (<https://code.visualstudio.com>, „User Installer",
   braucht keine Administrator-Rechte).
2. Die Erweiterung **Remote - SSH** installieren: links
   die Ansicht „Erweiterungen (Extensions)" öffnen
   (Symbol mit den vier Quadraten oder `Strg+Umschalt+X`),
   nach `Remote - SSH` suchen, die Erweiterung von
   Microsoft wählen, „Installieren (Install)". Ist der
   Marktplatz auf deinem Rechner gesperrt (vorinstalliertes
   VS Code der Hochschule), wende dich an die Betreuung
   deiner Lehrveranstaltung.
3. Befehlspalette öffnen (`F1` oder `Strg+Umschalt+P`),
   **Remote-SSH: Mit Host verbinden… (Connect to Host…)**
   wählen und `clawbook` anklicken. VS Code nutzt den
   Eintrag, den das Skript in die SSH-Config geschrieben
   hat.
4. Es öffnet sich ein **neues Fenster**. Beim ersten Mal
   fragt VS Code unter Umständen nach dem Betriebssystem
   des Ziels — **Linux** — und ob du den Fingerabdruck des
   Hosts annehmen willst — **Continue**. Dann installiert
   es seinen Server-Teil im Container (einige hundert
   Megabyte, in deinem Home-Verzeichnis; bleibt bei
   Aktualisierungen erhalten). Unten links läuft ein
   Fortschritt; das dauert beim ersten Mal ein bis zwei
   Minuten.
5. **Ordner öffnen**: Menü „Datei → Ordner öffnen…
   (File → Open Folder…)". Oben erscheint ein Eingabefeld
   mit einem Pfad; dort `/home/student/source` eintragen
   und mit „OK" bestätigen. **Der Ordner ist anfangs leer;
   das ist richtig** — hier entstehen deine Projekte.
6. Die Frage **„Vertrauen Sie den Autoren der Dateien in
   diesem Ordner? (Do you trust the authors …?)"** mit
   „Ja, ich vertraue den Autoren (Yes, I trust the
   authors)" beantworten. Es ist dein eigener Ordner.
7. Terminal im Container: Menü „Terminal → Neues Terminal
   (New Terminal)". Es läuft im Container als `student`,
   genau wie `ssh clawbook`.

Unten links in VS Code steht jetzt „SSH: clawbook" — daran
erkennst du, dass du im Container arbeitest. Beim nächsten
Mal reichen Schritt 3 und „Datei → Zuletzt verwendet
öffnen (Open Recent)".

## 6. Den Bildschirm des Containers sehen

Der Container hat einen eigenen grafischen Bildschirm. Du
brauchst ihn nur selten: für **Anmeldungen im Browser**,
die ein Werkzeug **im Container** öffnet (zum Beispiel
NotebookLM — die meisten Werkzeuge nutzen stattdessen
deinen Browser unter Windows, siehe [Setup](setup/README.md)),
oder wenn ein Agent dir eine Webseite zeigen will.

1. Unter Windows das Programm „Remotedesktopverbindung"
   starten — am schnellsten in PowerShell:

   ```powershell
   mstsc /v:localhost:3390
   ```

2. Die **Zertifikatsfrage** mit „Ja" beantworten. Das
   Zertifikat hat der Container beim ersten Start selbst
   ausgestellt; Windows kennt es deshalb nicht. Es sichert
   nur die Verbindung zwischen deinem Windows und deinem
   Container auf demselben Rechner.
3. Ein Passwort gibt es nicht. Fragt Windows trotzdem nach
   Benutzername und Passwort: Abbrechen und erneut
   verbinden; hilft das nicht, melde dich bei der
   Betreuung deiner Lehrveranstaltung.

Warum kein Passwort in Ordnung ist: Der Bildschirm ist nur
unter `127.0.0.1` erreichbar, also nur von dem Rechner aus,
auf dem der Container läuft — nicht aus dem Netz. Und im
Container gibt es nichts, was nicht dir gehört: nur die
Anmeldungen, die du selbst dort einrichtest. **Nicht
geeignet** ist das für Rechner, an denen gleichzeitig
andere Personen angemeldet sind (Terminalserver, geteilte
Sitzungen): Dort könnte jeder Angemeldete `localhost:3390`
öffnen. Nutze den Bildschirm dann nicht oder frage die
Betreuung.

Oben in der Leiste findest du zwei Symbole: **Chromium**
(der Browser) und ein **Terminal**. Beide laufen als
`student`. Wenn du das Remotedesktop-Fenster schließt,
trennst du nur die Anzeige; Browser und Container laufen
weiter.

## 7. Der Austauschordner

`%USERPROFILE%\clawbook\austausch` unter Windows ist im
Container `~/austausch`. Was du dort ablegst, sehen beide
Seiten — in beide Richtungen. Er ist gedacht für
gelegentliche Übergaben: eine PDF für den Agenten, ein
Ergebnis für eine Abgabe. Lösche den Windows-Ordner nicht;
im Container erschiene `~/austausch` dann leer.

Deine Projekte gehören **nicht** in den Austauschordner,
sondern nach `~/source` im Home-Volume. Gründe: Im
Austauschordner sind Dateizugriffe aus dem Container
vielfach langsamer, Linux-Dateirechte lassen sich dort
nicht setzen, und Werkzeuge, die auf Dateiänderungen
reagieren (Entwicklungsserver, Tests im Watch-Modus),
bekommen Änderungen von der Windows-Seite nicht mit.

## 8. Erste Schritte im Container

Verbinde dich mit `ssh clawbook` oder im VS-Code-Terminal
und prüfe, ob alle Werkzeuge da sind:

```bash
clawbook-check
```

Die Ausgabe ist eine Tabelle mit allen Werkzeugen und
ihren Versionen. Steht irgendwo `FEHLT`, stimmt etwas mit
dem Image nicht — melde es bei der Betreuung deiner
Lehrveranstaltung.

Deine Projekte legst du unter `~/source` an. Dafür gibt es
im Container den WorkspaceManager mit dem Befehl `wsm`,
der Projektordner anlegt und Agenten darin startet;
`wsm --help` zeigt seine Möglichkeiten.

Die KI-Werkzeuge sind installiert, aber noch nicht
angemeldet — die Zugänge gehören dir und kommen nicht aus
dem Image. Wie du jeden Account anlegst und jedes Werkzeug
anmeldest, steht im [Setup](setup/README.md). Das ist der
nächste Schritt.

## Wenn etwas nicht geht

Das Skript schreibt alles, was es tut, in ein Protokoll
unter `%LOCALAPPDATA%\clawbook\logs\` und nennt den Pfad
am Anfang jedes Laufs und bei jeder Fehlermeldung. Deinen
privaten Schlüssel schwärzt es darin („[privater Schlüssel
entfernt]"), du darfst das Protokoll also an die Betreuung
schicken — wirf trotzdem vorher kurz einen Blick hinein.
Bei einem Fehler bleibt das Fenster offen („Drücke Enter,
um zu beenden"), damit du die Meldung lesen kannst.

- **Rote Meldung sofort nach dem Einfügen des Befehls**
  (Skripte gesperrt, Virenschutz, kein Zugriff auf
  GitHub) — siehe Abschnitt 1, „Wenn die Hochschule etwas
  blockiert".
- **Das Skript sagt, WSL fehlt** und empfiehlt
  `wsl --install` — das kann Administrator-Rechte
  brauchen, siehe Abschnitt 1.
- **Das Skript sagt, die WSLC-Version ist zu alt** — mit
  Enter bestätigen, es ruft `wsl --update` auf (ohne
  Administrator-Rechte). Danach den Befehl aus Abschnitt 2
  erneut ausführen.
- **Das Skript sagt, der `ssh`-Befehl fehlt** — den
  OpenSSH-Client hinzufügen, siehe Abschnitt 1.
- **„Der Container braucht länger als sonst. Warte eine
  Minute und wähle dann im Menü [1] ‚starten und
  verbinden'."** — genau das tun: eine Minute warten, den
  Befehl erneut ausführen, Enter. Der Container läuft im
  Hintergrund meist schon an. Bleibt die Meldung beim
  zweiten Mal, das Protokoll an die Betreuung schicken.
- **Das Skript meldet, Port 2222 oder 3390 sei belegt** —
  ein anderes Programm (oder ein zweiter Benutzer auf
  demselben Rechner) nutzt den Port schon. Alle anderen
  Programme beenden und erneut versuchen; sonst Betreuung.
- **`ssh clawbook` meldet „Connection refused"** — der
  Container läuft nicht. Den Befehl aus Abschnitt 2
  ausführen, Enter. Nach dem Abmelden oder einem Neustart
  von Windows ist das immer nötig, siehe
  [Pflege](pflege.md), Abschnitt 1.
- **`ssh clawbook` fragt nach einem Passwort** — der
  Schlüssel unter Windows passt nicht zum Container. Im
  Menü **[5] SSH für VS Code neu einrichten** wählen; das
  schreibt Schlüssel und Config neu.
- **„Could not resolve hostname clawbook"** — der Eintrag
  in `%USERPROFILE%\.ssh\config` fehlt. Ebenfalls Menü [5].
- **Warnung „REMOTE HOST IDENTIFICATION HAS CHANGED"** —
  der Container hat einen anderen Fingerabdruck als beim
  letzten Mal (passiert nur, wenn er außerhalb des Skripts
  neu angelegt wurde). Die Datei
  `%USERPROFILE%\.ssh\known_hosts_clawbook` löschen, dann
  Menü [5].
- **VS Code bleibt beim Verbinden hängen** — erst prüfen,
  ob `ssh clawbook` in PowerShell geht. Wenn ja: in VS Code
  Befehlspalette, „Remote-SSH: VS Code Server auf Host
  beenden… (Kill VS Code Server on Host…)" ausführen und
  erneut verbinden.
- **Remotedesktop zeigt nur Schwarz oder bricht ab** —
  ein paar Sekunden warten und erneut verbinden; der
  Bildschirm startet kurz nach SSH. Läuft der Container
  (`ssh clawbook` geht)?
- **Alles ist sehr langsam** — liegen deine Dateien in
  `~/austausch` statt in `~/source`? Siehe Abschnitt 7.

## Anhang: Ohne WSLC — mit podman in einer WSL-Distribution

**Nur für Fortgeschrittene oder auf Anweisung der
Betreuung.** Dies ist ein Ausweichweg für den Fall, dass
WSLC auf deinem Rechner nicht geht oder nicht erlaubt ist.
Das Verwaltungs-Skript und sein Menü nutzt du dann nicht;
du gibst alle Befehle selbst ein, und die
[Pflege-Anleitung](pflege.md) gilt nur sinngemäß. Für den
Normalfall gilt die Anleitung oben. Wenn du unsicher bist,
frag die Betreuung deiner Lehrveranstaltung, bevor du hier
anfängst.

Du brauchst eine WSL-Distribution (zum Beispiel Debian oder
Ubuntu) in WSL 2 und darin das Passwort deines
Linux-Benutzers (für `sudo`). Prüfen in PowerShell mit
`wsl --list --verbose`; eine Zeile mit `VERSION 2` genügt.

**podman installieren** — in der WSL-Distribution (zum
Beispiel „Debian" im Startmenü):

```bash
sudo apt update
sudo apt install -y podman
podman --version
```

Das `sudo` betrifft nur die Linux-Distribution; unter
Windows brauchst du dafür keine Rechte. Damit die
Dateifreigabe (Samba, Port 445) als normaler Benutzer
funktioniert, einmalig erlauben:

```bash
echo 'net.ipv4.ip_unprivileged_port_start=445' \
  | sudo tee /etc/sysctl.d/90-clawbook.conf
sudo sysctl --system
```

**Volume anlegen und Container starten** (im Hintergrund,
damit dein Terminal frei bleibt):

```bash
podman volume create clawbook-home
podman run -d --name clawbook \
  -p 127.0.0.1:2222:22 \
  -p 127.0.0.1:3390:3389 \
  -p 445:445 \
  -v clawbook-home:/home/student \
  ghcr.io/schlingensiepen/clawbook-lehre:latest
```

`-p 127.0.0.1:2222:22` macht SSH unter `localhost:2222`
erreichbar, `-p 127.0.0.1:3390:3389` den Bildschirm unter
`localhost:3390`, `-p 445:445` die Dateifreigabe;
`-v clawbook-home:/home/student` legt dein Home ins
Volume.

**Schlüssel und Passwort finden:** Beim Start schreibt der
Container einen Kasten mit den Verbindungsdaten, deinem
**privaten SSH-Schlüssel** und dem **Passwort für die
Dateifreigabe** in sein Protokoll. Anzeigen mit:

```bash
podman logs clawbook
```

**SSH einrichten:** Den Schlüssel vollständig (von
`-----BEGIN OPENSSH PRIVATE KEY-----` bis
`-----END OPENSSH PRIVATE KEY-----`) unter Windows als
Datei `%USERPROFILE%\.ssh\clawbook` speichern und in
`%USERPROFILE%\.ssh\config` denselben Block eintragen, den
sonst das Skript schreibt:

```text
Host clawbook
  HostName 127.0.0.1
  Port 2222
  User student
  IdentityFile ~/.ssh/clawbook
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
  UserKnownHostsFile ~/.ssh/known_hosts_clawbook
```

Danach gehen `ssh clawbook`, VS Code (Abschnitt 5) und der
Bildschirm (Abschnitt 6) wie oben beschrieben.

**Dateien im Windows-Explorer:** Das Home ist als
Windows-Freigabe erreichbar — über die IP-Adresse der
WSL-Distribution, denn Port 445 auf `localhost` belegt
Windows selbst. In WSL `hostname -I` eingeben; die erste
Adresse (zum Beispiel `172.27.112.5`) im Explorer als
`\\172.27.112.5\student` öffnen, Benutzer `student`,
Passwort aus `podman logs clawbook`. Die Adresse kann sich
nach einem Neustart von Windows ändern.

**Anhalten und starten:** `podman stop clawbook` hält den
Container an, `podman start clawbook` startet ihn wieder.
Nach einem Neustart von Windows ist `podman start clawbook`
nötig.

**Neues Image:** `podman pull …:latest`, dann
`podman rm -f clawbook` und den `podman run`-Befehl von
oben erneut ausführen — das Volume und damit dein Stand
bleiben.

**Sichern und mitnehmen** — die Datei landet im aktuellen
Verzeichnis; nimm dasselbe Namensschema wie das Skript,
damit beide Wege zusammenpassen:

```bash
podman volume export clawbook-home --output home-2026-10-05-120000.tar
# auf einem anderen Rechner:
podman volume create clawbook-home
podman volume import clawbook-home home-2026-10-05-120000.tar
```

Das Archiv enthält deine Logins und deinen privaten
Schlüssel — behandle es wie ein Passwort.

**Wenn etwas nicht geht (podman-Weg):** „Port 445 nicht
erlaubt" → die `sysctl`-Einstellung oben fehlt. Explorer
findet die Freigabe nicht → IP mit `hostname -I` prüfen,
läuft der Container (`podman ps`)? Warnung „REMOTE HOST
IDENTIFICATION HAS CHANGED" → tritt nur nach einem neuen
Volume auf; die Datei
`%USERPROFILE%\.ssh\known_hosts_clawbook` löschen.
