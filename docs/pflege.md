# Pflege: starten, aktualisieren, Daten behalten

Stand: 2026-10-05

Diese Anleitung beschreibt den Alltag mit clawbook.
Voraussetzung ist, dass die [Installation](installation.md)
einmal durchgelaufen ist. Begriffe wie Container, Image und
Volume erklärt der [Wegweiser](README.md#begriffe).

Inhalt:

1. [Täglich starten](#1-täglich-starten)
2. [Anhalten](#2-anhalten)
3. [Aktualisieren](#3-aktualisieren)
4. [Wo deine Daten liegen](#4-wo-deine-daten-liegen)
5. [Sicherung schreiben („mitnehmen")](#5-sicherung-schreiben-mitnehmen)
6. [Auf einen anderen Rechner umziehen](#6-auf-einen-anderen-rechner-umziehen)
7. [Importieren, wenn schon ein Home da ist](#7-importieren-wenn-schon-ein-home-da-ist)
8. [Zurücksetzen](#8-zurücksetzen)
9. [Auf Hochschul- und Poolrechnern](#9-auf-hochschul--und-poolrechnern)
10. [Status, SSH und Protokolle](#10-status-ssh-und-protokolle)
11. [Für Fortgeschrittene](#11-für-fortgeschrittene) — ohne
    Menü, ältere Image-Version, Mutagen
12. [Wenn etwas nicht geht](#wenn-etwas-nicht-geht)

Alles läuft über denselben Befehl wie bei der Installation.
Er holt jedes Mal die aktuelle Fassung des
Verwaltungs-Skripts und zeigt dann ein Menü:

```powershell
irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
```

Sobald dein Home-Volume existiert, sieht das Menü so aus.
In der Klammer steht der Zustand des Containers: „läuft",
„angehalten" oder „noch nicht angelegt" — Letzteres ist
normal nach einem Zurücksetzen und heißt nicht, dass deine
Daten fehlen; die liegen im Volume.

```text
clawbook – was möchtest du tun?
  (Container: angehalten)
  [1] starten und verbinden (Vorgabe)
  [2] auf das neueste Image aktualisieren
  [3] mitnehmen: Home als Sicherung speichern
  [4] aus einer Sicherung importieren
  [5] SSH für VS Code neu einrichten
  [6] Status anzeigen
  [7] anhalten
  [8] zurücksetzen (Home neu, vorher Sicherung)
  [0] beenden
Auswahl [1]
```

Achte auf den Unterschied zwischen **[3] mitnehmen**
(schreibt eine Sicherung, ändert nichts) und **[4]
importieren** (ersetzt dein Home durch eine Sicherung).
Das Skript fragt bei [4] nach, bevor es etwas ersetzt.

## 1. Täglich starten

1. PowerShell öffnen, den Befehl oben einfügen (Rechtsklick)
   und ausführen.
2. Enter drücken — das wählt **starten und verbinden**.
3. Warten, bis der grüne Kasten „clawbook läuft." erscheint.
   Das geht jetzt deutlich schneller als beim ersten Mal,
   meist unter einer Minute.
4. Verbinden wie gewohnt, in einem neuen PowerShell-Fenster
   `ssh clawbook`, in VS Code „Remote-SSH: Mit Host
   verbinden… (Connect to Host…)" → `clawbook`, oder
   `mstsc /v:localhost:3390` für den Bildschirm.

**Nach dem Abmelden oder einem Neustart von Windows läuft
der Container nicht mehr** — WSL kann Container nicht von
selbst wieder starten. Deshalb beginnt jeder Arbeitstag mit
diesem Befehl. Deine Daten sind davon nicht betroffen;
sie liegen im Home-Volume und sind nach dem Start wieder
da, samt Projekten und Anmeldungen.

## 2. Anhalten

Menüpunkt **[7] anhalten** hält den Container an. Das ist
nicht nötig, bevor du Windows herunterfährst — aber
sinnvoll, wenn du Arbeitsspeicher brauchst oder der
Container länger nicht gebraucht wird. Laufende Programme
im Container (Agenten, Editor-Sitzungen) werden dabei
beendet; speichere vorher. Ein Neustart geht wie in
Abschnitt 1.

## 3. Aktualisieren

Von Zeit zu Zeit gibt es ein neues Image mit neueren
Versionen der Werkzeuge. Die Werkzeuge im Container
aktualisieren sich absichtlich **nicht selbst**; so
arbeiten alle im Kurs mit demselben, geprüften Stand. Die
Betreuung sagt dir, wann es ein neues Image gibt.

**Vorher:**

1. Offene Dateien in VS Code speichern, laufende Agenten
   beenden (`/exit`), die SSH-Verbindung mit `exit`
   verlassen. Das Skript sagt es dir auch noch einmal:
   „Laufende Programme im Container werden beendet.
   Speichere offene Dateien und beende Agenten." und
   fragt „[J/n]" — Enter bestätigt.
2. Eine Sicherung schreiben (Menüpunkt [3], Abschnitt 5).
   Das Aktualisieren hat im Test nie Daten verloren, aber
   eine Sicherung kostet nur ein paar Minuten.

**Dann** Menüpunkt **[2] auf das neueste Image
aktualisieren**. Das Skript zeigt seine Schritte als
„[1/4] …" bis „[4/4] …":

1. Es lädt die neueste Fassung des Images (wieder mehrere
   Gigabyte, mit Fortschrittsanzeige; nur die geänderten
   Teile werden wirklich übertragen). Nicht abbrechen,
   Fenster offen lassen.
2. Es hält den Container an und entfernt ihn.
3. Es legt den Container mit dem neuen Image neu an.
4. Es richtet SSH neu ein und zeigt den grünen Kasten.

**Dein Home bleibt dabei erhalten.** Grund: Die Werkzeuge
liegen im Image außerhalb von `/home/student`; deine
Projekte, Einstellungen und Anmeldungen liegen im
Home-Volume. Beim Aktualisieren wird nur der Container
ausgetauscht, das Volume wird unverändert wieder
eingehängt. Dein SSH-Schlüssel bleibt derselbe, VS Code
verbindet sich danach ohne weitere Fragen.

Was **nicht** erhalten bleibt: alles, was du außerhalb des
Home-Verzeichnisses installiert hast (zum Beispiel mit
`sudo apt install`). Installiere eigene Pakete deshalb in
dein Home oder in Projekt-Umgebungen: Python-Pakete in
eine virtuelle Umgebung im Projekt (`uv venv`), Node-Pakete
mit `npm install` im Projektordner.

## 4. Wo deine Daten liegen

Alles, was du im Container anlegst oder einrichtest, liegt
in `/home/student`, und dieses Verzeichnis liegt im
**Home-Volume** `clawbook-home`. Unter Windows ist das
Volume eine einzige große Datei (eine virtuelle Festplatte,
bis 100 GB), die WSL verwaltet.

Deshalb siehst du deine Projekte **nicht als Ordner im
Windows-Explorer**. Das ist Absicht, aus zwei Gründen:

- **Tempo.** Im Volume sind Dateizugriffe aus dem
  Container um ein Vielfaches schneller als in einem
  eingebundenen Windows-Ordner — bei vielen kleinen
  Dateien (`node_modules`, Git) um den Faktor 100.
- **Rechte.** Linux-Programme brauchen Dateirechte, die
  Windows-Ordner nicht bieten; SSH zum Beispiel verweigert
  einen Schlüssel mit falschen Rechten.

Die Datei des Volumes solltest du **nicht selbst kopieren**:
Solange WSL läuft, ist sie gesperrt, und ein Zurückkopieren
scheitert. Zum Sichern und Mitnehmen gibt es den Weg in
Abschnitt 5.

Zugriff auf deine Dateien von Windows aus hast du über
**VS Code** (siehe [Installation](installation.md),
Abschnitt 5), über den **Austauschordner**
`%USERPROFILE%\clawbook\austausch` für einzelne Dateien
und — als Zusatz — über Mutagen (Abschnitt 11).

## 5. Sicherung schreiben („mitnehmen")

Menüpunkt **[3] mitnehmen: Home als Sicherung speichern**:

1. Das Skript hält den Container an, damit die Sicherung
   in sich stimmig ist. Speichere also vorher offene
   Dateien und beende Agenten.
2. Es prüft, ob genug Platz frei ist (etwas mehr als die
   Größe deines Homes). Reicht der Platz nicht, meldet es
   das und startet den Container wieder.
3. Es schreibt dein komplettes Home in die Datei

   ```text
   %USERPROFILE%\clawbook\sicherungen\home-<datum>.tar
   ```

   zum Beispiel `home-2026-10-05-143012.tar` (Datum, Uhrzeit
   mit Sekunden). Solange es schreibt, zeigt es alle fünf
   Sekunden einen Punkt — bei einem Home von einigen
   Gigabyte dauert das ein paar Minuten. Nicht abbrechen.

4. Lief der Container vorher, startet das Skript ihn
   wieder — auch, wenn die Sicherung scheitert.

Ein `.tar` ist ein Archiv, das Dateien samt ihren
Linux-Rechten enthält — deshalb dieses Format und nicht
ein einfaches Kopieren.

**Die Sicherung enthält deine Anmeldungen bei allen
Werkzeugen und deinen privaten SSH-Schlüssel.** Wer die
Datei hat, kann in deinem Namen arbeiten. Behandle sie wie
ein Passwort: nicht per E-Mail verschicken, nicht in einen
geteilten Cloud-Ordner legen, nach dem Umzug auf dem
Zwischenspeicher löschen.

Sichere regelmäßig — vor einer Aktualisierung, vor
Experimenten, am Ende einer Projektphase. Die Dateien sind
groß und sammeln sich an: Jede Sicherung, jeder Import und
jedes Zurücksetzen legt eine neue ab. Du darfst alle
löschen, die du nicht mehr brauchst; sicher ist es, die
jeweils neueste zu behalten und eine, die du als „guten
Stand" kennst.

## 6. Auf einen anderen Rechner umziehen

Dein ganzer Stand passt in eine Datei. So nimmst du ihn
mit, zum Beispiel vom Laptop auf den Rechner im Labor:

1. Auf dem **alten** Rechner eine Sicherung schreiben
   (Abschnitt 5).
2. Die Datei `home-<datum>.tar` auf einen USB-Stick oder
   einen verschlüsselten Speicher kopieren (siehe Warnung
   in Abschnitt 5).
3. Auf dem **neuen** Rechner den Befehl von oben
   ausführen. WSL muss dort die Voraussetzungen erfüllen
   (siehe [Installation](installation.md), Abschnitt 1).
4. Im ersten Menü **[2] aus einer Sicherung importieren**
   wählen. Das Skript fragt „Nummer wählen oder den
   vollständigen Pfad zu einer Sicherung eingeben". Den
   **vollständigen Pfad** der Datei eingeben, zum Beispiel
   `E:\home-2026-10-05-143012.tar`. Anführungszeichen
   (etwa vom Explorer-Befehl „Als Pfad kopieren") stören
   nicht. Oder: die Datei vorher nach
   `%USERPROFILE%\clawbook\sicherungen\` legen — den Ordner
   legt das Skript beim ersten Aufruf an, also einmal den
   Befehl ausführen, mit `0` beenden, Datei kopieren,
   Befehl erneut ausführen — dann erscheint sie in der
   Liste und du gibst ihre Nummer ein.
5. Warten. Das Skript prüft die Datei, lädt das Image, legt
   ein neues Volume an, entpackt die Sicherung hinein
   (alle fünf Sekunden ein Punkt), startet den Container
   und richtet SSH mit dem Schlüssel aus der Sicherung
   ein. Am Ende meldet es „Import geprüft: Schlüssel und
   ~/source sind da."

Danach ist alles wie auf dem alten Rechner: Projekte,
Anmeldungen, VS-Code-Einstellungen. Nur VS Code selbst und
die Erweiterung „Remote - SSH" musst du auf dem neuen
Rechner einmal einrichten.

## 7. Importieren, wenn schon ein Home da ist

Menüpunkt **[4] aus einer Sicherung importieren** gibt es
auch, wenn auf dem Rechner schon ein Home-Volume existiert —
etwa um zu einem früheren Stand zurückzukehren.

Das Skript fragt vorher: „Dein jetziges Home wird durch die
Sicherung ersetzt. Es wird vorher automatisch gesichert.
Weiter? [j/N]" — nur `j` setzt fort, Enter bricht ab. Es
**sichert dann zuerst automatisch das vorhandene Home**,
bevor es das Volume ersetzt. Du verlierst also nichts; der
alte Stand liegt danach als weitere `home-<datum>.tar` im
Sicherungsordner. Der Rest läuft wie in Abschnitt 6.

**Wenn der Import fehlschlägt** (Datei beschädigt oder
keine clawbook-Sicherung): Das Skript nennt dir die
automatische Sicherung, die es gerade geschrieben hat. Den
Befehl erneut ausführen, **[4]** wählen und diese Datei
nehmen — dann bist du wieder auf dem Stand von vorher.

Weil der importierte Stand seinen eigenen
Container-Fingerabdruck mitbringt, vergisst das Skript den
bisher bekannten und lernt ihn beim nächsten Verbinden neu
— deshalb erscheint nach einem Import einmal die Meldung
„Permanently added …", keine Warnung.

## 8. Zurücksetzen

Menüpunkt **[8] zurücksetzen (Home neu, vorher Sicherung)**
setzt den Container auf den Anfangszustand zurück: neues,
leeres Home, keine Anmeldungen, keine Projekte, ein neuer
SSH-Schlüssel (das Skript ersetzt den Schlüssel unter
Windows gleich mit). Es fragt zur Sicherheit „Wirklich
zurücksetzen? Zum Bestätigen ‚ja‘ eingeben" und schreibt
vorher eine Sicherung.

Nach dem Zurücksetzen musst du das [Setup](setup/README.md)
der Werkzeuge erneut durchgehen — oder du importierst
später wieder die Sicherung (Abschnitt 7).

## 9. Auf Hochschul- und Poolrechnern

Auf Rechnern der Hochschule gelten oft Regeln, die du nicht
siehst: Manche setzen sich beim Abmelden oder über Nacht
zurück, manche legen dein Profil auf einem Server ab und
begrenzen seine Größe. clawbook legt seine Daten in deinem
Windows-Profil ab (das Volume mit mehreren Gigabyte, die
Sicherungen, der Schlüssel). Deshalb:

1. **Prüfe am zweiten Tag**, ob dein Stand noch da ist:
   Befehl ausführen, [1], `ssh clawbook`, nachsehen, ob
   `~/source` deine Projekte enthält. Wenn nicht, setzt
   sich der Rechner zurück — dann arbeitest du dort nur
   mit Sicherung auf einem **USB-Stick** (unten) und
   importierst sie jeden Tag neu (Abschnitt 6, Punkt 4).
2. **Sichere auf einen USB-Stick**, nicht ins Profil —
   so bleibt das Profil klein, und deine Logins liegen
   nicht auf einem Server der Hochschule. Dafür gibt es
   die Sicherung direkt auf ein anderes Laufwerk:

   ```powershell
   powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\clawbook\clawbook.ps1" -Action export -File "E:\clawbook\home-2026-10-05.tar"
   ```

   `E:` durch den Laufwerksbuchstaben deines Sticks
   ersetzen; den Ordner legt das Skript an. Der Dateiname
   soll mit `home-` beginnen und auf `.tar` enden, dann
   findet ihn der Import später in einer Liste. Der
   Befehl startet die gespeicherte Fassung des Skripts
   ohne Menü (mehr dazu in Abschnitt 11) und tut sonst
   dasselbe wie Menüpunkt [3]. Alternativ: Menüpunkt [3]
   und die Datei danach aus
   `%USERPROFILE%\clawbook\sicherungen\` auf den Stick
   verschieben.
3. **Lösche alte Sicherungen** im Profil regelmäßig
   (Abschnitt 5) und bewahre den Stick sicher auf — er
   enthält deine Logins.
4. **Bildschirm (Remotedesktop)** nur auf Rechnern nutzen,
   an denen nicht gleichzeitig andere angemeldet sind
   (siehe [Installation](installation.md), Abschnitt 6).

Wenn du nicht weißt, wie dein Poolrechner eingestellt ist:
Betreuung deiner Lehrveranstaltung fragen.

## 10. Status, SSH und Protokolle

- **[6] Status anzeigen** zeigt, ob Home-Volume und
  Container da sind („noch nicht angelegt", „angehalten",
  „läuft"), ob der SSH-Port 2222 offen ist, welches Image
  gewünscht ist (normalerweise `…:latest`) und welches der
  Container tatsächlich benutzt, aus welchem Build es
  stammt (Datum und Kennung, mit der die Betreuung die
  Image-Version erkennt) sowie Anzahl und Größe deiner
  Sicherungen. Danach erscheint das Menü erneut.
- **[5] SSH für VS Code neu einrichten** holt den Schlüssel
  frisch aus dem Container und schreibt
  `%USERPROFILE%\.ssh\clawbook` und den Eintrag in
  `%USERPROFILE%\.ssh\config` neu. Nützlich, wenn du an
  diesen Dateien etwas verändert hast oder `ssh clawbook`
  plötzlich nach einem Passwort fragt. Läuft der Container
  nicht, sagt das Skript „Der Container läuft nicht – ich
  starte ihn zuerst." und startet ihn.
- **Protokolle:** Jeder Lauf des Skripts schreibt in
  `%LOCALAPPDATA%\clawbook\logs\clawbook-<datum>.log`
  (eine Datei pro Tag); den Pfad nennt es am Anfang und
  bei jedem Fehler. Deinen privaten Schlüssel schwärzt es
  darin. Du darfst das Protokoll an die Betreuung
  schicken — wirf vorher kurz einen Blick hinein.

## 11. Für Fortgeschrittene

Dieser Abschnitt ist nicht nötig, um mit clawbook zu
arbeiten.

### Ohne Menü: eine Aktion direkt ausführen

Setze vor dem gewohnten Befehl die Variable
`CLAWBOOK_ACTION`; sie gilt nur für dieses
PowerShell-Fenster:

```powershell
$env:CLAWBOOK_ACTION = 'status'
irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
```

Mögliche Werte: `start`, `update`, `export` (Sicherung
schreiben), `import`, `ssh`, `status`, `stop`, `reset`.
`import` und `reset` fragen auch so nach, bevor sie etwas
ersetzen.

Um bei `export` oder `import` eine Datei anzugeben
(`-File`), startest du die gespeicherte Fassung des
Skripts direkt (`-ExecutionPolicy Bypass` ist nötig, weil
Windows heruntergeladene Skripte sonst nicht ausführt):

```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\clawbook\clawbook.ps1" -Action import -File "E:\clawbook\home-2026-10-05.tar"
```

Beachte: So läuft die **gespeicherte** Fassung. Der Befehl
von der Startseite holt vorher immer die neueste.

### Eine ältere Image-Version benutzen

Macht ein neues Image Probleme, kannst du für einen Aufruf
eine bestimmte Version wählen. Die Kennung (`<tag>`)
bekommst du von der Betreuung:

```powershell
$env:CLAWBOOK_IMAGE = 'ghcr.io/schlingensiepen/clawbook-lehre:<tag>'
irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
```

Dann im Menü **[2] aktualisieren** wählen — das legt den
Container mit dieser Version an, das Home bleibt. Die
Einstellung gilt nur für dieses PowerShell-Fenster; der
nächste normale Aufruf nimmt wieder `:latest`, und ein
späteres [2] holt wieder das neueste Image.

### Dateien im Windows-Explorer mit Mutagen

Für den Alltag reicht VS Code. Wenn du deine Projektdateien
aber zusätzlich unter Windows haben willst — für ein
Programm, das nicht in den Container schauen kann, etwa
Office oder den Explorer — kannst du **Mutagen** benutzen.
Mutagen hält einen Windows-Ordner und einen Ordner im
Container in **beide Richtungen** synchron, über die
SSH-Verbindung `clawbook`. Es ist eine einzelne `.exe`
ohne Installation und braucht keine Administrator-Rechte.

1. Von der Mutagen-Website (<https://mutagen.io>, Bereich
   Downloads) das Windows-Paket laden und die `mutagen.exe`
   in einen Ordner entpacken, zum Beispiel
   `%USERPROFILE%\clawbook\mutagen\`.
2. In PowerShell eine Synchronisation anlegen. Ordner wie
   `node_modules` und `.venv` nimmst du aus: Sie sind
   riesig, Windows kann mit ihrem Inhalt nichts anfangen,
   und sie werden im Container neu erzeugt.

   ```powershell
   cd $env:USERPROFILE\clawbook\mutagen
   .\mutagen.exe sync create --name clawbook-source `
     --ignore node_modules --ignore .venv --ignore __pycache__ `
     clawbook:/home/student/source $env:USERPROFILE\clawbook\source
   ```

3. Prüfen mit `.\mutagen.exe sync list`; beenden mit
   `.\mutagen.exe sync terminate clawbook-source`. Nach
   einem Neustart von Windows startest du Mutagen mit
   `.\mutagen.exe daemon start` wieder.

Die Kopie unter Windows ist eine **Kopie** — die Wahrheit
liegt im Container. Ändere eine Datei nur auf **einer**
Seite. Wird dieselbe Datei auf beiden Seiten geändert,
meldet Mutagen einen Konflikt (sichtbar in
`.\mutagen.exe sync list`) und überschreibt keine der beiden
Fassungen, bis du ihn auflöst. Nach einem Import oder
Zurücksetzen die Synchronisation beenden und neu anlegen.

## Wenn etwas nicht geht

- **`ssh clawbook`: „Connection refused"** — der Container
  läuft nicht (zum Beispiel nach einem Neustart von
  Windows). Den Befehl ausführen, Enter.
- **Menü zeigt „(Container: noch nicht angelegt)", obwohl
  du gestern gearbeitet hast** — normal nach einem
  Zurücksetzen oder Import; das Volume mit deinen Daten
  ist da. „starten und verbinden" legt den Container neu
  an.
- **„Zu wenig Platz in …"** beim Sichern — Platz schaffen
  (alte Sicherungen löschen) oder direkt auf einen
  USB-Stick sichern (Abschnitt 9). Der Container läuft
  danach wieder.
- **„Keine gültige Sicherung gewählt."** — beim Import eine
  Nummer aus der Liste oder einen vollständigen Pfad
  eingeben; die Datei muss existieren.
- **Import fehlgeschlagen** — Abschnitt 7: mit [4] die
  automatische Sicherung zurückholen, die das Skript
  genannt hat.
- **„Hinweis: Im importierten Home fehlt ~/source oder der
  Schlüssel."** — die Sicherung ist unvollständig oder
  stammt nicht von clawbook. Der Container läuft trotzdem;
  prüfe mit `ssh clawbook`, was da ist. Dein vorheriger
  Stand liegt als automatische Sicherung im
  Sicherungsordner.
- **Nach dem Aktualisieren fehlt ein Werkzeug** —
  `clawbook-check` im Container zeigt es; melde es bei der
  Betreuung deiner Lehrveranstaltung. Bis es ein
  korrigiertes Image gibt, hilft eine ältere Version
  (Abschnitt 11). Eigene Installationen außerhalb des
  Homes sind nach einer Aktualisierung weg (Abschnitt 3).
- **„Der Container braucht länger als sonst …"** — eine
  Minute warten, Befehl erneut, Enter. Mehr dazu in der
  [Installation](installation.md), „Wenn etwas nicht
  geht".
- **Protokoll gesucht** — `%LOCALAPPDATA%\clawbook\logs\`;
  das Skript nennt den Pfad am Anfang jedes Laufs.
