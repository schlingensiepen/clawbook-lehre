# Pflege: starten, aktualisieren, Daten behalten

Stand: 2026-10-12

Diese Anleitung beschreibt den Alltag mit clawbook.
Voraussetzung ist, dass die [Installation](installation.md)
einmal durchgelaufen ist. Begriffe wie Container, Image und
Volume erklärt der [Wegweiser](README.md#begriffe).
Meldungen des Verwaltungs-Skripts stehen hier wörtlich in
Anführungszeichen. Das Skript spricht Sie mit „du" an; so
steht es auch in den Zitaten.

Inhalt:

1. [Täglich starten](#1-täglich-starten)
2. [Anhalten](#2-anhalten)
3. [Aktualisieren](#3-aktualisieren)
4. [Wo Ihre Daten liegen](#4-wo-ihre-daten-liegen)
5. [Sicherung schreiben („mitnehmen")](#5-sicherung-schreiben-mitnehmen)
6. [Auf einen anderen Rechner umziehen](#6-auf-einen-anderen-rechner-umziehen)
7. [Importieren, wenn schon ein Home da ist](#7-importieren-wenn-schon-ein-home-da-ist)
8. [Zurücksetzen](#8-zurücksetzen)
9. [Auf Hochschul- und Poolrechnern](#9-auf-hochschul--und-poolrechnern)
10. [Status, SSH und Protokolle](#10-status-ssh-und-protokolle)
11. [Für Fortgeschrittene](#11-für-fortgeschrittene) — ohne
    Menü, andere Image-Version, Testmodus, Mutagen
12. [Wenn etwas nicht geht](#wenn-etwas-nicht-geht)

Alles läuft über denselben Befehl wie bei der Installation.
Er holt jedes Mal die aktuelle Fassung des
Verwaltungs-Skripts und zeigt dann ein Menü:

```powershell
irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
```

Sobald Ihr Home-Volume existiert, sieht das Menü so aus.
In der Klammer steht der Zustand des Containers: „läuft",
„angehalten" oder „noch nicht angelegt" — Letzteres ist
normal nach einem Zurücksetzen und heißt nicht, dass Ihre
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
  [9] VS Code starten und verbinden (VSCodePack)
 [10] VSCodePack installieren oder aktualisieren
  [0] beenden
Auswahl [1]
```

Achten Sie auf den Unterschied zwischen **[3] mitnehmen**
(schreibt eine Sicherung, ändert nichts) und **[4]
importieren** (ersetzt Ihr Home durch eine Sicherung).
Das Skript fragt bei [4] nach, bevor es etwas ersetzt.

Die Punkte [9] und [10] betreffen das eigene VS Code für
clawbook, das VSCodePack; die
[Installation](installation.md), Abschnitt 5, erklärt
beide ausführlich.

## 1. Täglich starten

1. PowerShell öffnen, den Befehl oben einfügen (Rechtsklick)
   und ausführen.
2. Enter drücken — das wählt **starten und verbinden**.
3. Warten, bis der grüne Kasten „clawbook läuft." erscheint.
   Das geht jetzt deutlich schneller als beim ersten Mal,
   meist unter einer Minute.
4. Verbinden wie gewohnt: in einem neuen PowerShell-Fenster
   `ssh clawbook` (es öffnet sich das clawbook-Menü; mit
   `0` kommen Sie in die Eingabezeile), oder `mstsc
   /v:localhost:3390` für den Bildschirm.

Für VS Code geht es noch kürzer: Menüpunkt **[9] VS Code
starten und verbinden (VSCodePack)** startet den Container,
falls nötig, und öffnet dann VS Code. Ohne PowerShell
erledigt dasselbe der Eintrag **„clawbook VS Code"** im
Startmenü.

**Nach dem Abmelden oder einem Neustart von Windows läuft
der Container nicht mehr** — WSL kann Container nicht von
selbst wieder starten. Deshalb beginnt jeder Arbeitstag mit
diesem Befehl (oder dem Startmenü-Eintrag). Ihre Daten
sind davon nicht betroffen; sie liegen im Home-Volume und
sind nach dem Start wieder da, samt Projekten und
Anmeldungen.

## 2. Anhalten

Menüpunkt **[7] anhalten** hält den Container an. Das ist
nicht nötig, bevor Sie Windows herunterfahren — aber
sinnvoll, wenn Sie Arbeitsspeicher brauchen oder der
Container länger nicht gebraucht wird. Laufende Programme
im Container (Agenten, Editor-Sitzungen) werden dabei
beendet; speichern Sie vorher. Ein Neustart geht wie in
Abschnitt 1.

## 3. Aktualisieren

Von Zeit zu Zeit gibt es ein neues Image mit neueren
Versionen der Werkzeuge. Die Werkzeuge im Container
aktualisieren sich absichtlich **nicht selbst**; so
arbeiten alle im Kurs mit demselben, geprüften Stand. Die
Betreuung Ihrer Lehrveranstaltung sagt Ihnen, wann es
ein neues Image gibt.

**Vorher:**

1. Offene Dateien in VS Code speichern, laufende Agenten
   beenden (`/exit`), die SSH-Verbindung mit `exit`
   verlassen. Das Skript erinnert Sie noch einmal daran:
   „Laufende Programme im Container werden beendet.
   Speichere offene Dateien und beende Agenten." und
   fragt „Jetzt aktualisieren? [J/n]" — Enter bestätigt.
2. Eine Sicherung schreiben (Menüpunkt [3], Abschnitt 5).
   Beim Aktualisieren bleibt Ihr Home erhalten; eine
   Sicherung ist trotzdem ratsam und kostet nur ein paar
   Minuten.

**Dann** Menüpunkt **[2] auf das neueste Image
aktualisieren**. Das Skript zeigt seine Schritte als
„[1/4] …" bis „[4/4] …":

1. Es lädt die neueste Fassung des Images (wieder mehrere
   Gigabyte, mit Fortschrittsanzeige; nur die geänderten
   Teile werden wirklich übertragen). Nicht abbrechen,
   Fenster offen lassen.
2. Lief der Container, speichert es zuerst den Stand des
   Containers in Ihr Home — welche Image-Version und
   welche Pakete installiert sind — und meldet „Stand
   gespeichert (~/.clawbook/stand.json im Home)." Dann
   hält es den Container an und entfernt ihn.
3. Es legt den Container mit dem neuen Image neu an.
4. Es richtet SSH neu ein und zeigt den grünen Kasten.

**Ihr Home bleibt dabei erhalten.** Grund: Die Werkzeuge
liegen im Image außerhalb von `/home/student`; Ihre
Projekte, Einstellungen und Anmeldungen liegen im
Home-Volume. Beim Aktualisieren wird nur der Container
ausgetauscht, das Volume wird unverändert wieder
eingehängt. Ihr SSH-Schlüssel bleibt derselbe; VS Code und
GitHub kennen ihn weiter.

Was **nicht** erhalten bleibt: alles, was Sie außerhalb
des Home-Verzeichnisses installiert haben (zum Beispiel mit
`sudo apt install`). Installieren Sie eigene Pakete
deshalb in Ihr Home oder in Projekt-Umgebungen:
Python-Pakete in eine virtuelle Umgebung im Projekt
(`uv venv`), Node-Pakete mit `npm install` im
Projektordner.

Das VS Code aus dem VSCodePack aktualisiert Menüpunkt [2]
nicht mit; dafür gibt es **[10]** (siehe
[Installation](installation.md), Abschnitt 5).

## 4. Wo Ihre Daten liegen

Alles, was Sie im Container anlegen oder einrichten, liegt
in `/home/student`, und dieses Verzeichnis liegt im
**Home-Volume** `clawbook-home`. Unter Windows ist das
Volume eine einzige große Datei (eine virtuelle Festplatte,
bis 100 GB), die WSL verwaltet. Ihre Projekte liegen darin
unter `~/source/<Bereich>/<Projekt>`, zum Beispiel das
Beispielprojekt `~/source/samples/primer`.

Deshalb sehen Sie Ihre Projekte **nicht als Ordner im
Windows-Explorer**. Das ist Absicht, aus zwei Gründen:

- **Tempo.** Im Volume sind Dateizugriffe aus dem
  Container um ein Vielfaches schneller als in einem
  eingebundenen Windows-Ordner — bei vielen kleinen
  Dateien (`node_modules`, Git) um den Faktor 100.
- **Rechte.** Linux-Programme brauchen Dateirechte, die
  Windows-Ordner nicht bieten; SSH zum Beispiel verweigert
  einen Schlüssel mit falschen Rechten.

Die Datei des Volumes sollten Sie **nicht selbst
kopieren**: Solange WSL läuft, ist sie gesperrt, und ein
Zurückkopieren scheitert. Zum Sichern und Mitnehmen gibt es
den Weg in Abschnitt 5.

Zugriff auf Ihre Dateien von Windows aus haben Sie über
**VS Code** (Menüpunkt [9], siehe
[Installation](installation.md), Abschnitt 5), über den
**Austauschordner** `%USERPROFILE%\clawbook\austausch` für
einzelne Dateien und — als Zusatz — über Mutagen
(Abschnitt 11).

Nicht im Home-Volume liegt das VSCodePack: Es liegt unter
Windows in `%LOCALAPPDATA%\clawbook\vscode\` und gehört
deshalb auch nicht zur Sicherung.

## 5. Sicherung schreiben („mitnehmen")

Menüpunkt **[3] mitnehmen: Home als Sicherung speichern**:

1. Lief der Container, speichert das Skript zuerst den
   Stand des Containers (Image-Version, Pakete) in Ihr
   Home und meldet „Stand gespeichert
   (~/.clawbook/stand.json im Home)." So weiß die
   Sicherung später, aus welchem Stand sie stammt
   (Abschnitt 6).
2. Es hält den Container an, damit die Sicherung in sich
   stimmig ist. Speichern Sie also vorher offene Dateien
   und beenden Sie Agenten.
3. Es prüft, ob genug Platz frei ist (etwas mehr als die
   Größe Ihres Homes). Reicht der Platz nicht, meldet es
   das und startet den Container wieder.
4. Es schreibt Ihr komplettes Home in die Datei

   ```text
   %USERPROFILE%\clawbook\sicherungen\home-<datum>.tar
   ```

   zum Beispiel `home-2026-10-12-143012.tar` (Datum,
   Uhrzeit mit Sekunden). Solange es schreibt, zeigt es
   alle fünf Sekunden einen Punkt — bei einem Home von
   einigen Gigabyte dauert das ein paar Minuten. Nicht
   abbrechen. Am Ende steht „Sicherung geschrieben: …".
5. Lief der Container vorher, startet das Skript ihn
   wieder — auch, wenn die Sicherung scheitert.

Ein `.tar` ist ein Archiv, das Dateien samt ihren
Linux-Rechten enthält — deshalb dieses Format und nicht
ein einfaches Kopieren.

**Die Sicherung enthält Ihre Anmeldungen bei allen
Werkzeugen und Ihren privaten SSH-Schlüssel.** Wer die
Datei hat, kann in Ihrem Namen arbeiten. Behandeln Sie sie
wie ein Passwort: nicht per E-Mail verschicken, nicht in
einen geteilten Cloud-Ordner legen, nach dem Umzug auf dem
Zwischenspeicher löschen.

Sichern Sie regelmäßig — vor einer Aktualisierung, vor
Experimenten, am Ende einer Projektphase. Die Dateien sind
groß und sammeln sich an: Jede Sicherung, jeder Import und
jedes Zurücksetzen legt eine neue ab. Sie dürfen alle
löschen, die Sie nicht mehr brauchen; sicher ist es, die
jeweils neueste zu behalten und eine, die Sie als „guten
Stand" kennen.

## 6. Auf einen anderen Rechner umziehen

Ihr ganzer Stand passt in eine Datei. So nehmen Sie ihn
mit, zum Beispiel vom Rechner im Pool nach Hause und
zurück. Auch auf Ihrem eigenen Windows-Rechner zu Hause
nehmen Sie denselben Befehl wie an der Hochschule — der
Weg mit Docker oder podman unter
[Eigener Rechner](privat/README.md) ist nur eine
Alternative für später.

1. Auf dem **alten** Rechner eine Sicherung schreiben
   (Abschnitt 5).
2. Die Datei `home-<datum>.tar` auf einen USB-Stick oder
   einen verschlüsselten Speicher kopieren (siehe Warnung
   in Abschnitt 5). Die Datei ist oft größer als 4 GB:
   Ein Stick im Format **FAT32** kann sie nicht
   aufnehmen. Nehmen Sie einen Stick mit **exFAT** oder
   **NTFS** (im Explorer: Rechtsklick auf den Stick →
   Eigenschaften zeigt das Format) und genug freiem Platz.
3. Auf dem **neuen** Rechner den Befehl von oben
   ausführen. WSL muss dort die Voraussetzungen erfüllen
   (siehe [Installation](installation.md), Abschnitt 1).
4. Im ersten Menü **[2] aus einer Sicherung importieren**
   wählen. Das Skript fragt „Nummer wählen oder den
   vollständigen Pfad zu einer Sicherung eingeben". Geben
   Sie den **vollständigen Pfad** der Datei ein, zum
   Beispiel `E:\home-2026-10-12-143012.tar`.
   Anführungszeichen (etwa vom Explorer-Befehl „Als Pfad
   kopieren") stören nicht. Oder: die Datei vorher nach
   `%USERPROFILE%\clawbook\sicherungen\` legen — den Ordner
   legt das Skript beim ersten Aufruf an, also einmal den
   Befehl ausführen, mit `0` beenden, Datei kopieren,
   Befehl erneut ausführen — dann erscheint sie in der
   Liste, und Sie geben ihre Nummer ein.
5. Das Skript prüft die Datei („[1/5] Prüfe die Sicherung
   …") und zeigt, aus welchem Stand sie stammt:

   ```text
   Stand der Sicherung:
     Datum:    12.10.2026 14:30
     Build:    <Commit-Kennung des Images>
     Kennung:  clawbook
     Pakete:   keine
   ```

   „Datum" ist der Zeitpunkt der Sicherung, „Build" das
   Image, mit dem sie entstand, „Kennung" der Kurs (bei
   `clawbook`: kein besonderer Kurs), „Pakete" die
   installierten Zusatzpakete. So erkennen Sie, ob Sie
   die richtige Datei gewählt haben. Ältere Sicherungen
   haben diese Angaben noch nicht; dann fehlt der Block,
   und der Import läuft trotzdem.
6. Warten. Das Skript lädt das Image, legt ein neues
   Volume an, entpackt die Sicherung hinein (alle fünf
   Sekunden ein Punkt), startet den Container und richtet
   SSH mit dem Schlüssel aus der Sicherung ein — „[2/5]"
   bis „[5/5]". Am Ende meldet es „Import geprüft:
   Schlüssel und ~/source sind da."

Danach ist alles wie auf dem alten Rechner: Projekte,
Anmeldungen (auch bei GitHub), Einstellungen im Container.
Nur das VSCodePack liegt unter Windows und reist nicht
mit: Wählen Sie auf dem neuen Rechner einmal **[9]**; das
Skript bietet dann die Installation an.

## 7. Importieren, wenn schon ein Home da ist

Menüpunkt **[4] aus einer Sicherung importieren** gibt es
auch, wenn auf dem Rechner schon ein Home-Volume existiert —
etwa um zu einem früheren Stand zurückzukehren.

Das Skript prüft die Datei und zeigt ihren Stand wie in
Abschnitt 6. Dann fragt es: „Dein jetziges Home wird durch
die Sicherung ersetzt. Es wird vorher automatisch
gesichert. Weiter? [j/N]" — nur `j` setzt fort, Enter
bricht ab. Es **sichert dann zuerst automatisch das
vorhandene Home** (bei laufendem Container auch hier mit
„Stand gespeichert …"), bevor es das Volume ersetzt.
Sie verlieren also nichts; der alte Stand liegt danach
als weitere `home-<datum>.tar` im Sicherungsordner.
Der Rest läuft wie in Abschnitt 6.

**Wenn der Import fehlschlägt** (Datei beschädigt oder
keine clawbook-Sicherung): Das Skript nennt Ihnen die
automatische Sicherung, die es gerade geschrieben hat.
Den Befehl erneut ausführen, **[4]** wählen und diese
Datei nehmen — dann sind Sie wieder auf dem Stand von
vorher.

Weil der importierte Stand seinen eigenen
Container-Fingerabdruck mitbringt, vergisst das Skript den
bisher bekannten und lernt ihn beim nächsten Verbinden neu
— deshalb erscheint nach einem Import einmal die Meldung
„Permanently added …", keine Warnung.

## 8. Zurücksetzen

Menüpunkt **[8] zurücksetzen (Home neu, vorher Sicherung)**
setzt den Container auf den Anfangszustand zurück: neues,
leeres Home, keine Anmeldungen, keine Projekte (nur wieder
das Beispielprojekt `samples/primer`), ein neuer
SSH-Schlüssel (das Skript ersetzt den Schlüssel unter
Windows gleich mit). Es fragt zur Sicherheit „Wirklich
zurücksetzen? Zum Bestätigen ‚ja' eingeben" und schreibt
vorher eine Sicherung.

Nach dem Zurücksetzen gehen Sie das [Setup](setup/README.md)
der Werkzeuge erneut durch — oder Sie importieren später
wieder die Sicherung (Abschnitt 7). Beim ersten
`ssh clawbook` danach fragt der Container wieder nach der
GitHub-Anmeldung; dabei laden Sie auch den neuen
SSH-Schlüssel zu GitHub hoch. Den alten Eintrag können Sie
unter <https://github.com/settings/keys> löschen.

## 9. Auf Hochschul- und Poolrechnern

Auf Rechnern der Hochschule gelten oft Regeln, die Sie
nicht sehen: Manche setzen sich beim Abmelden oder über
Nacht zurück, manche legen Ihr Profil auf einem Server ab
und begrenzen seine Größe. clawbook legt seine Daten in
Ihrem Windows-Profil ab (das Volume mit mehreren Gigabyte,
die Sicherungen, der Schlüssel, das VSCodePack). Deshalb:

1. **Prüfen Sie am zweiten Tag**, ob Ihr Stand noch da
   ist: Befehl ausführen, [1], `ssh clawbook`, nachsehen,
   ob `~/source` Ihre Projekte enthält. Wenn nicht, setzt
   sich der Rechner zurück — dann arbeiten Sie dort nur
   mit einer Sicherung auf einem **USB-Stick** (unten)
   und importieren sie jeden Tag neu (Abschnitt 6,
   Punkt 4).
2. **Sichern Sie auf einen USB-Stick**, nicht ins Profil
   — so bleibt das Profil klein, und Ihre Logins liegen
   nicht auf einem Server der Hochschule. Der Stick muss
   **exFAT** oder **NTFS** formatiert sein (FAT32 nimmt
   keine Dateien über 4 GB). Dafür gibt es die Sicherung
   direkt auf ein anderes Laufwerk:

   ```powershell
   powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\clawbook\clawbook.ps1" -Action export -File "E:\clawbook\home-2026-10-12.tar"
   ```

   `E:` durch den Laufwerksbuchstaben Ihres Sticks
   ersetzen; den Ordner legt das Skript an. Der Dateiname
   soll mit `home-` beginnen und auf `.tar` enden, dann
   findet ihn der Import später in einer Liste. Der
   Befehl startet die gespeicherte Fassung des Skripts
   ohne Menü (mehr dazu in Abschnitt 11) und tut sonst
   dasselbe wie Menüpunkt [3]. Alternativ: Menüpunkt [3]
   und die Datei danach aus
   `%USERPROFILE%\clawbook\sicherungen\` auf den Stick
   verschieben.
3. **Löschen Sie alte Sicherungen** im Profil regelmäßig
   (Abschnitt 5) und bewahren Sie den Stick sicher auf —
   er enthält Ihre Logins.
4. **Fehlt das VSCodePack** nach einem Zurücksetzen des
   Rechners, richtet [9] es wieder ein (Download etwa
   150 MB, entpackt etwa 1 GB).
5. **Bildschirm (Remotedesktop)** nur auf Rechnern nutzen,
   an denen nicht gleichzeitig andere angemeldet sind
   (siehe [Installation](installation.md), Abschnitt 6).

Wenn Sie nicht wissen, wie Ihr Poolrechner eingestellt
ist: Betreuung Ihrer Lehrveranstaltung fragen.

## 10. Status, SSH und Protokolle

**[6] Status anzeigen** zeigt eine Liste und danach
wieder das Menü. Die Zeilen bedeuten:

| Zeile | Bedeutung |
|---|---|
| „Home-Volume:" | „vorhanden" oder „noch nicht angelegt" |
| „Container:" | „läuft", „angehalten" oder „noch nicht angelegt" |
| „SSH-Port:" | „offen (2222)" oder „zu" |
| „Gewünschtes Image:" | das Image, das das Skript benutzen soll, normalerweise `…:latest` |
| „Benutztes Image:" | das Image, mit dem der Container tatsächlich läuft |
| „Schnittstelle:" | Version der Verbindung zwischen Skript und Container (nur bei laufendem Container) |
| „Build:" | Kennung und Datum des Images; daran erkennt die Betreuung die Image-Version (nur bei laufendem Container) |
| „Sicherungen:" | Anzahl und Größe Ihrer Sicherungen |
| „VSCodePack:" | Kennung des VSCodePacks (`clawbook`, wenn kein Kurs gewählt ist) |
| „VS Code im Pack:" | installierte VS-Code-Version oder „noch nicht installiert (Menüpunkt [10])" |
| „Neuestes VS Code:" | neueste Version bei Microsoft, mit „– aktualisieren mit Menüpunkt [10]", wenn Ihre älter ist |

Steht bei „Schnittstelle:" „keine (älteres Image –
aktualisieren mit Menüpunkt [2])", ist das Image älter als
das Skript. Das Skript arbeitet trotzdem; aktualisieren
Sie bei Gelegenheit mit [2] (Abschnitt 3). Dasselbe sagt
die Meldung „Hinweis: Das Image im Container ist älter als
dieses Skript. Aktualisiere es mit Menüpunkt [2]."

Die Zeile „Neuestes VS Code:" fehlt, wenn Microsoft nicht
schnell genug antwortet; das ist kein Fehler.

**[5] SSH für VS Code neu einrichten** holt den Schlüssel
frisch aus dem Container und schreibt
`%USERPROFILE%\.ssh\clawbook` und den Eintrag in
`%USERPROFILE%\.ssh\config` neu. Nützlich, wenn Sie an
diesen Dateien etwas verändert haben oder `ssh clawbook`
plötzlich nach einem Passwort fragt. Läuft der Container
nicht, sagt das Skript „Der Container läuft nicht – ich
starte ihn zuerst." und startet ihn.

**Protokolle:** Jeder Lauf des Skripts schreibt in
`%LOCALAPPDATA%\clawbook\logs\clawbook-JJJJMMTT-HHMM.log`
(eine Datei pro Lauf, die neuesten 30 bleiben); den Pfad
nennt es am Anfang und bei jedem Fehler. Scheitert der
Download des Images, steht die Meldung von `wslc` im
Protokoll. Ihren privaten Schlüssel schwärzt es darin. Sie
dürfen das Protokoll an die Betreuung schicken — werfen
Sie vorher kurz einen Blick hinein.

## 11. Für Fortgeschrittene

Dieser Abschnitt ist nicht nötig, um mit clawbook zu
arbeiten.

### Ohne Menü: eine Aktion direkt ausführen

Setzen Sie vor dem gewohnten Befehl die Variable
`CLAWBOOK_ACTION`; sie gilt nur für dieses
PowerShell-Fenster:

```powershell
$env:CLAWBOOK_ACTION = 'status'
irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
```

Mögliche Werte: `start`, `update`, `export` (Sicherung
schreiben), `import`, `ssh`, `status`, `stop`, `reset`,
`vscode` (wie Menüpunkt [9]) und `vscode-install` (wie
Menüpunkt [10]). `import` und `reset` fragen auch so nach,
bevor sie etwas ersetzen. Entfernen Sie die Variable
wieder mit `Remove-Item Env:CLAWBOOK_ACTION`, sonst führt
jeder weitere Aufruf in diesem Fenster dieselbe Aktion
aus.

Um bei `export` oder `import` eine Datei anzugeben
(`-File`), starten Sie die gespeicherte Fassung des
Skripts direkt (`-ExecutionPolicy Bypass` ist nötig, weil
Windows heruntergeladene Skripte sonst nicht ausführt):

```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\clawbook\clawbook.ps1" -Action import -File "E:\clawbook\home-2026-10-12.tar"
```

Beachten Sie: So läuft die **gespeicherte** Fassung. Der
Befehl von der Startseite holt vorher immer die neueste.

### Eine andere Image-Version benutzen (Testmodus)

Macht ein neues Image Probleme, oder sollen Sie einen
Testkandidaten ausprobieren, können Sie für einen Aufruf
eine bestimmte Version wählen. Die Kennung (`<tag>`)
bekommen Sie von der Betreuung:

```powershell
$env:CLAWBOOK_IMAGE = 'ghcr.io/schlingensiepen/clawbook-lehre:<tag>'
irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
```

Im Menü heißt Punkt [2] dann nicht mehr „auf das neueste
Image aktualisieren", sondern **„[2] auf das Image <tag>
wechseln (Testmodus)"**. Wählen Sie ihn: Das Skript legt
den Container mit dieser Version an, Ihr Home bleibt.
„[6] Status anzeigen" zeigt die Version unter „Gewünschtes
Image" und „Benutztes Image".

Die Einstellung gilt nur für dieses PowerShell-Fenster
(oder bis `Remove-Item Env:CLAWBOOK_IMAGE`). Der nächste
normale Aufruf nimmt wieder `:latest`; der Container läuft
aber mit der gewählten Version weiter, bis Sie im
normalen Menü **[2] auf das neueste Image aktualisieren**
wählen.

### Skript aus einem anderen Stand laden

`CLAWBOOK_REF` bestimmt, aus welchem Branch oder Tag des
Repositorys das Verwaltungs-Skript und die
Kursbeschreibungen für das VSCodePack geladen werden
(Vorgabe `main`). Das brauchen Sie nur, wenn die
Betreuung Sie bittet, einen Teststand auszuprobieren.
Laden Sie dann auch den Einstiegsbefehl aus demselben
Stand:

```powershell
$env:CLAWBOOK_REF = '<ref>'
irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/<ref>/get-clawbook.ps1 | iex
```

Das Skript meldet dann „clawbook: Testmodus, lade aus
<ref>". Zurück zum Normalfall: `Remove-Item
Env:CLAWBOOK_REF` oder ein neues PowerShell-Fenster.
`CLAWBOOK_REF` und `CLAWBOOK_IMAGE` lassen sich
kombinieren.

### Dateien im Windows-Explorer mit Mutagen

Für den Alltag reicht VS Code. Wenn Sie Ihre
Projektdateien aber zusätzlich unter Windows haben wollen —
für ein Programm, das nicht in den Container schauen kann,
etwa Office oder den Explorer —, können Sie **Mutagen**
benutzen. Mutagen hält einen Windows-Ordner und einen
Ordner im Container in **beide Richtungen** synchron, über
die SSH-Verbindung `clawbook`. Es ist eine einzelne `.exe`
ohne Installation und braucht keine Administrator-Rechte.

1. Von der Mutagen-Website (<https://mutagen.io>, Bereich
   Downloads) das Windows-Paket laden und die `mutagen.exe`
   in einen Ordner entpacken, zum Beispiel
   `%USERPROFILE%\clawbook\mutagen\`.
2. In PowerShell eine Synchronisation anlegen. Ordner wie
   `node_modules` und `.venv` nehmen Sie aus: Sie sind
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
   einem Neustart von Windows starten Sie Mutagen mit
   `.\mutagen.exe daemon start` wieder.

Die Kopie unter Windows ist eine **Kopie** — die Wahrheit
liegt im Container. Ändern Sie eine Datei nur auf **einer**
Seite. Wird dieselbe Datei auf beiden Seiten geändert,
meldet Mutagen einen Konflikt (sichtbar in
`.\mutagen.exe sync list`) und überschreibt keine der beiden
Fassungen, bis Sie ihn auflösen. Nach einem Import oder
Zurücksetzen die Synchronisation beenden und neu anlegen.

## Wenn etwas nicht geht

- **`ssh clawbook`: „Connection refused"** — der Container
  läuft nicht (zum Beispiel nach einem Neustart von
  Windows). Den Befehl ausführen, Enter.
- **Menü zeigt „(Container: noch nicht angelegt)", obwohl
  Sie gestern gearbeitet haben** — normal nach einem
  Zurücksetzen oder Import; das Volume mit Ihren Daten ist
  da. „starten und verbinden" legt den Container neu an.
- **„Zu wenig Platz in …"** beim Sichern — Platz schaffen
  (alte Sicherungen löschen) oder direkt auf einen
  USB-Stick sichern (Abschnitt 9). Der Container läuft
  danach wieder.
- **„Hinweis: Der Stand (~/.clawbook/stand.json) ließ sich
  nicht speichern. Es geht trotzdem weiter."** — kein
  Grund zur Sorge: Die Sicherung oder Aktualisierung läuft
  normal weiter; nur die Angaben unter „Stand der
  Sicherung" fehlen später.
- **„Keine gültige Sicherung gewählt."** — beim Import eine
  Nummer aus der Liste oder einen vollständigen Pfad
  eingeben; die Datei muss existieren.
- **Import fehlgeschlagen** — Abschnitt 7: mit [4] die
  automatische Sicherung zurückholen, die das Skript
  genannt hat.
- **„Hinweis: Im importierten Home fehlt ~/source oder der
  Schlüssel."** — die Sicherung ist unvollständig oder
  stammt nicht von clawbook. Der Container läuft trotzdem;
  prüfen Sie mit `ssh clawbook`, was da ist. Ihr
  vorheriger Stand liegt als automatische Sicherung im
  Sicherungsordner.
- **Nach dem Aktualisieren fehlt ein Werkzeug** —
  `clawbook check` (oder Menüpunkt 2 im clawbook-Menü)
  im Container zeigt es; melden Sie es bei der Betreuung
  Ihrer Lehrveranstaltung. Bis es ein korrigiertes Image
  gibt, hilft eine ältere Version (Abschnitt 11). Eigene
  Installationen außerhalb des Homes sind nach einer
  Aktualisierung weg (Abschnitt 3).
- **„Der Container braucht länger als sonst …"** — eine
  Minute warten, Befehl erneut, Enter. Mehr dazu in der
  [Installation](installation.md), „Wenn etwas nicht
  geht".
- **Probleme mit VS Code oder dem VSCodePack** — siehe
  [Installation](installation.md), „VS Code und
  VSCodePack".
- **Protokoll gesucht** — `%LOCALAPPDATA%\clawbook\logs\`;
  das Skript nennt den Pfad am Anfang jedes Laufs.
