# Kurse und Technikpakete

Stand: 2026-10-12

clawbook bringt von Anfang an alles mit, was Sie für die
Arbeit mit KI-Agenten brauchen: Git, Python, Node.js und
die Agenten-Werkzeuge. Braucht eine Lehrveranstaltung
mehr — Java, .NET, eine Datenbank, Werkzeuge für
Mikrocontroller —, holen Sie es sich als **Kurs** dazu.
Diese Seite erklärt, wie das geht, was dabei passiert und
was Sie tun, wenn etwas nicht klappt.

Voraussetzung ist, dass die [Installation](installation.md)
einmal durchgelaufen ist. Meldungen des Verwaltungs-Skripts
und des Befehls `clawbook` stehen hier wörtlich in
Anführungszeichen. Die neueren Meldungen sprechen Sie mit
„Sie" an, ältere und das Menü im Container noch mit „du";
so stehen sie auch in den Zitaten.

Inhalt:

1. [Was Kurse und Technikpakete sind](#1-was-kurse-und-technikpakete-sind)
2. [Einen Kurs hinzufügen](#2-einen-kurs-hinzufügen)
3. [Das VSCodePack zum Kurs](#3-das-vscodepack-zum-kurs)
4. [VS Code starten](#4-vs-code-starten)
5. [Einen Kurs entfernen](#5-einen-kurs-entfernen)
6. [Einzelne Technikpakete (für Fortgeschrittene)](#6-einzelne-technikpakete-für-fortgeschrittene)
7. [Nach einer Aktualisierung oder einem Import](#7-nach-einer-aktualisierung-oder-einem-import)
8. [Die Pakete im Überblick](#8-die-pakete-im-überblick)
9. [Dienste: PostgreSQL und Node-RED](#9-dienste-postgresql-und-node-red)
10. [Wenn etwas nicht geht](#wenn-etwas-nicht-geht)

## 1. Was Kurse und Technikpakete sind

- Ein **Technikpaket** bringt die Werkzeuge einer Technik
  mit, zum Beispiel `clawbook-java` mit Java, Maven und
  Gradle. Dazu gehört eine Liste von Erweiterungen, die
  VS Code im Container für diese Technik braucht.
- Ein **Kurs** ist eine Zusammenstellung von
  Technikpaketen für eine Lehrveranstaltung. Wer einen
  Kurs hinzufügt, bekommt alle seine Technikpakete auf
  einmal. Außerdem bringt der Kurs eine kleine
  Beschreibung mit, nach der das Verwaltungs-Skript ein
  eigenes VS Code für den Kurs einrichtet.

Wichtig für den Alltag:

- **Ein Container, mehrere Kurse.** Sie haben nur einen
  clawbook-Container. Darin können mehrere Kurse
  nebeneinander installiert sein. Brauchen zwei Kurse
  dasselbe Technikpaket, wird es nur einmal installiert.
- **Je Kurs ein eigenes VS Code.** Unter Windows richtet
  das Skript für jeden installierten Kurs ein eigenes
  VS Code ein, ein **VSCodePack**, mit den Erweiterungen
  und Einstellungen des Kurses. Dazu kommt das Grundpack
  `clawbook` für die Arbeit ohne Kurs. Alle VSCodePacks
  verbinden sich mit demselben Container und öffnen
  denselben Ordner `~/source`. Ihre Projekte sehen Sie
  also in jedem davon.
- **Ihr Home bleibt, wie es ist.** Kurse installieren
  Programme in den Container, nicht in Ihr
  Home-Verzeichnis. Ihre Projekte und Anmeldungen
  berühren sie nicht.

Kurse und Technikpakete kommen aus einer eigenen,
signierten Paketquelle des Projekts. Das Image vertraut
nur deren Schlüssel; fremde Quellen kommen auf diesem Weg
nicht in Ihren Container.

Derzeit liefert die Paketquelle drei Kurse als Beispiele
mit: `kurs-inf` (Ingenieurinformatik), `kurs-swe`
(Softwareengineering) und `kurs-iot` (IoT). Welche
Technikpakete darin stecken, zeigt die Tabelle in
Abschnitt 8. Welchen Kurs Sie brauchen, sagt Ihnen Ihre
Lehrveranstaltung.

## 2. Einen Kurs hinzufügen

Sie brauchen dafür eine Internetverbindung und, je nach
Kurs, einige Minuten Zeit. Es gibt zwei Wege zum selben
Menü:

- **Über das Verwaltungs-Skript (empfohlen):** den Befehl
  aus der [Installation](installation.md), Abschnitt 2,
  ausführen und **[11] Kurse und Technikpakete** wählen.
  Läuft der Container nicht, startet das Skript ihn
  zuerst („Der Container läuft nicht – ich starte ihn
  zuerst."). Der Vorteil: Danach richtet das Skript gleich
  das passende VS Code ein (Abschnitt 3).
- **Im Container:** in PowerShell `ssh clawbook`, im
  clawbook-Menü **6 Pakete und Kurse** wählen. Haben Sie
  das Menü schon geschlossen, öffnen Sie es mit dem Befehl
  `clawbook`; direkt in das Kurs-Menü führt
  `clawbook pakete`.

Zuerst meldet `clawbook` „Paketquellen werden aktualisiert
...". Dann zeigt es die Kurse; `[ ]` heißt „nicht
installiert", `[x]` heißt „installiert":

```text
Pakete und Kurse - Kurse
  Nummer: Kurs hinzufügen ([ ]) oder entfernen ([x]).
   1  [ ] kurs-inf               Kurs Ingenieurinformatik
   2  [ ] kurs-iot               Kurs IoT
   3  [ ] kurs-swe               Kurs Softwareengineering
   t  Technikpakete einzeln (für Fortgeschrittene)
   Enter  zurück
Deine Wahl:
```

Geben Sie die Nummer des Kurses ein und drücken Sie Enter.
`clawbook` bestätigt die Wahl, zum Beispiel „kurs-inf
hinzufügen (Kurs Ingenieurinformatik).", und übergibt an
die Paketverwaltung von Debian (`apt`). Die zeigt, welche
Pakete sie installiert und wie viel sie herunterlädt, und
fragt, ob sie fortfahren soll. Bestätigen Sie mit Enter.
Danach laufen viele Zeilen durch; das ist normal.

Am Ende meldet `clawbook` „Installiert: kurs-inf. Stand
gespeichert in /home/student/.clawbook/stand.json." und
„Für VS Code unter Windows: Das passende VSCodePack
richtet das Windows-Skript ein." In der Liste steht der
Kurs jetzt mit `[x]`. Mit Enter kommen Sie zurück.

**So viel wird heruntergeladen** (ungefähre Werte):

| Kurs | Download |
|---|---|
| `kurs-inf` | etwa 0,8 GB |
| `kurs-swe` | etwa 1,7 GB |
| `kurs-iot` | etwa 0,35 GB, dazu auf Wunsch PlatformIO mit etwa 6 GB (unten) |

Haben Sie schon einen Kurs, wird weniger geladen: Was ein
anderer Kurs bereits mitgebracht hat, ist schon da. Wer
zum Beispiel `kurs-swe` hat, bekommt `kurs-inf` fast ohne
Download.

Die heruntergeladenen Pakete bewahrt clawbook in Ihrem
Home auf (in `~/.clawbook/apt`). Damit stellt es Ihre
Kurse nach einer Aktualisierung wieder her, ohne alles
noch einmal zu laden (Abschnitt 7). Das kostet Platz im
Home in etwa der Größe der Downloads.

### PlatformIO vorladen (nur bei kurs-iot)

`kurs-iot` (genauer: das Technikpaket `clawbook-embedded`)
bringt PlatformIO mit, das Werkzeug für Programme auf
Mikrocontrollern wie dem ESP32. Für den ersten Build
braucht PlatformIO noch eine große Plattform mit Compiler.
Nach der Installation fragt `clawbook` deshalb:

```text
PlatformIO für ESP32 vorladen
-----------------------------
Für den ersten Build braucht PlatformIO die ESP32-Plattform (pioarduino mit
Arduino-Framework) samt Compiler: etwa 6 GB, die in deinem Home landen
(~/.platformio). Das dauert je nach Verbindung 2 bis 20 Minuten. Machst du
es jetzt, geht später der erste Build schnell und auch ohne Internet.
PlatformIO jetzt vorladen? [j/N]
```

- Antworten Sie mit `j`, wenn Sie eine stabile Verbindung
  und genug Platz haben. `clawbook` meldet „PlatformIO
  lädt jetzt die ESP32-Plattform (etwa 6 GB) und baut ein
  Testprojekt. Bitte warten ..." und am Ende
  „PlatformIO ist vorgeladen (…); ~/.platformio belegt
  …".
- Enter heißt „nein". Dann erscheint „PlatformIO
  vorladen (etwa 6 GB) später mit: clawbook pakete
  vorladen". Sie können das jederzeit nachholen:

  ```bash
  clawbook pakete vorladen
  ```

  Ohne Vorladen lädt PlatformIO die Plattform beim
  ersten Build selbst; der dauert dann entsprechend
  lange und braucht Internet.

Die etwa 6 GB liegen in Ihrem Home und sind deshalb auch
in jeder Sicherung enthalten (siehe [Pflege](pflege.md),
Abschnitt 5).

## 3. Das VSCodePack zum Kurs

Für jeden installierten Kurs richtet das
Verwaltungs-Skript ein eigenes VS Code ein. Haben Sie den
Kurs über **[11]** hinzugefügt, fragt das Skript direkt
danach, zum Beispiel:

```text
Im Container ist der Kurs „Ingenieurinformatik“ (kurs-inf) installiert, das passende VSCodePack fehlt. Jetzt einrichten? [J/n]
```

Enter bestätigt. Das Skript lädt VS Code bei Microsoft
(etwa 150 MB), prüft und entpackt es und richtet es ein —
dieselben Schritte „[1/4]" bis „[4/4]" wie bei der
[Installation](installation.md), Abschnitt 5. Jedes
VSCodePack ist ein eigenes VS Code und braucht unter
Windows etwa 1 GB Platz. Zum Schluss legt das Skript
einen eigenen Eintrag im Startmenü an:

```text
Verknüpfung „clawbook VS Code – Ingenieurinformatik“ im Startmenü angelegt. Sie startet zuerst den Container und dann VS Code.
```

Haben Sie den Kurs stattdessen im Container hinzugefügt
(über `ssh clawbook`), kommt dieselbe Frage beim nächsten
**[1] starten und verbinden** oder **[9] VS Code
starten**.

Sie können die VSCodePacks auch selbst einrichten:
**[10] VSCodePacks einrichten** öffnet ein Untermenü:

```text
VSCodePacks – was möchten Sie tun?
  [1] alle passend zum Container einrichten oder aktualisieren (Vorgabe)
  [2] ein einzelnes VSCodePack einrichten oder aktualisieren
  [3] ein VSCodePack entfernen
  [0] zurück
Auswahl [1]
```

Punkt [1] richtet das Grundpack und je installiertem Kurs
ein VSCodePack ein und bringt vorhandene auf den neuesten
Stand. Das ist auch der richtige Weg, wenn Ihnen in
VS Code Erweiterungen fehlen, nachdem Sie einen weiteren
Kurs oder ein Technikpaket hinzugefügt haben. Am Ende
meldet das Skript „… von … VSCodePacks sind bereit." und
fragt „VS Code jetzt starten und mit clawbook verbinden?
[J/n]".

## 4. VS Code starten

- **Menüpunkt [9] VS Code starten.** Gibt es mehrere
  VSCodePacks, fragt das Skript, welches Sie starten
  möchten. Vorgeschlagen ist das, das Sie zuletzt
  gestartet haben; Enter übernimmt den Vorschlag:

  ```text
  Welches VS Code möchten Sie starten?
    [1] clawbook (ohne Kurs) (clawbook)
    [2] Ingenieurinformatik (kurs-inf)
    [0] abbrechen
  Auswahl [2]
  ```

- **Startmenü.** Jedes VSCodePack hat einen eigenen
  Eintrag: „clawbook VS Code" für das Grundpack,
  „clawbook VS Code – Ingenieurinformatik" und so weiter
  für die Kurse. Der Eintrag startet zuerst den Container
  und dann VS Code.

Welches VSCodePack Sie öffnen, ist für Ihre Dateien egal:
Alle zeigen denselben Container und dieselben Projekte.
Sie unterscheiden sich in den Erweiterungen und
Einstellungen. Nehmen Sie für die Arbeit in einer
Lehrveranstaltung das VSCodePack dieses Kurses.

## 5. Einen Kurs entfernen

Im selben Menü wie in Abschnitt 2 (**[11]** oder im
Container Menüpunkt 6) die Nummer des Kurses mit `[x]`
eingeben. `clawbook` erklärt:

```text
kurs-inf entfernen. Technikpakete, die sonst niemand braucht, gehen mit;
deine Dateien im Home bleiben.
```

`apt` zeigt, was es entfernt, und fragt nach; Enter
bestätigt. Technikpakete, die ein anderer installierter
Kurs noch braucht, bleiben. Am Ende steht „Entfernt:
kurs-inf. Stand gespeichert in …".

Das passende VSCodePack entfernt das Skript nicht von
selbst; es fragt (nach [11] gleich danach, sonst beim
nächsten [1] oder [9]):

```text
Der Kurs „Ingenieurinformatik“ ist im Container nicht mehr installiert. Das VSCodePack entfernen? [j/N]
```

Nur `j` entfernt es, Enter behält es. Später geht das
mit **[10]**, dann **[3] ein VSCodePack entfernen**.

Was im Home bleibt, weil es Ihnen gehört: Ihre Projekte,
die Datenbank von PostgreSQL (`~/.local/share/postgresql`),
die Flows von Node-RED (`~/.node-red`) und eine
vorgeladene PlatformIO-Plattform (`~/.platformio`, etwa
6 GB). Brauchen Sie PlatformIO nicht mehr, geben die
etwa 6 GB so wieder frei:

```bash
rm -rf ~/.platformio
```

## 6. Einzelne Technikpakete (für Fortgeschrittene)

Normalerweise brauchen Sie keine einzelnen Technikpakete:
Kurse bringen ihre Pakete selbst mit. Wollen Sie trotzdem
nur eine Technik haben, etwa .NET ohne einen ganzen Kurs,
geben Sie in der Kursliste `t` ein:

```text
Technikpakete einzeln (für Fortgeschrittene)
  Nummer: Paket hinzufügen ([ ]) oder entfernen ([x]). Kurse bringen ihre Pakete selbst mit.
   1  [ ] clawbook-db-postgres   PostgreSQL 17 als Dienst für student
   2  [ ] clawbook-db-sqlite     SQLite: sqlite3 und SQLite-Explorer für VS Code
   3  [ ] clawbook-dotnet        .NET SDK 10.0 mit dotnet-ef
  …
   Enter  zurück
```

Technikpakete, die ein Kurs mitgebracht hat, stehen hier
schon mit `[x]`. Vorsicht beim Entfernen: Ein Kurs
braucht seine Technikpakete. Entfernen Sie eines davon,
nimmt `apt` den Kurs mit. Lesen Sie deshalb, was `apt`
vor der Frage auflistet, und brechen Sie ab, wenn dort
ein Kurs steht.

Ein einzelnes Technikpaket bekommt kein eigenes
VSCodePack. Seine Erweiterungen kommen in alle
VSCodePacks, sobald Sie sie mit **[10]**, dann **[1]**,
aktualisieren.

Dasselbe geht ohne Menü:

```bash
clawbook pakete katalog                 # alle Kurse und Technikpakete
clawbook pakete add clawbook-dotnet     # hinzufügen
clawbook pakete remove clawbook-dotnet  # entfernen
clawbook kurse                          # installierte Kurse
```

`add` und `remove` fragen wie im Menü nach; mit `--yes`
laufen sie ohne Rückfrage. `clawbook --help` zeigt alle
Befehle.

Pakete, die Sie selbst mit `sudo apt install` aus anderen
Quellen installieren, kennt `clawbook` nicht. Sie gehen
bei der nächsten Aktualisierung verloren (siehe
[Pflege](pflege.md), Abschnitt 3).

## 7. Nach einer Aktualisierung oder einem Import

Kurse und Technikpakete liegen im Container, nicht in
Ihrem Home. Bei einer Aktualisierung (Menüpunkt [2])
entsteht ein neuer Container, und mit ihm wären sie weg.
Damit Sie nichts neu installieren müssen, merkt sich
`clawbook` in Ihrem Home, was installiert ist (in
`~/.clawbook/stand.json`), und spielt es im neuen
Container von selbst wieder ein. Dasselbe passiert nach
einem Import aus einer Sicherung, auch auf einem anderen
Rechner.

So läuft das ab:

- Die Pakete kommen aus dem Paket-Cache in Ihrem Home
  (Abschnitt 2). Liegen alle darin, geht das **ohne
  Internet** und meist in wenigen Minuten. Nur neuere
  Versionen werden nachgeladen.
- Die Wiederherstellung läuft **im Hintergrund**. Sie
  können sich währenddessen schon mit `ssh clawbook`
  anmelden; das clawbook-Menü zeigt dann die Zeile
  „Pakete nach neuem Image: werden eingespielt (…)" mit
  den Paketnamen. Bis sie fertig ist, fehlen im Container
  noch Werkzeuge.
- **[9] und [10] warten** auf die Wiederherstellung,
  damit VS Code nicht ohne seine Werkzeuge startet:

  ```text
  Im Container werden gerade die Kurse und Technikpakete wiederhergestellt (nach einer Aktualisierung oder einem Import). Ich warte, bis das fertig ist – höchstens 10 Minuten.
  Mit einer beliebigen Taste brechen Sie das Warten ab.
  ```

  Während des Wartens erscheint alle paar Sekunden ein
  Punkt. Ist alles da, meldet das Skript „Die Kurse und
  Technikpakete sind wiederhergestellt." und macht
  weiter.
- **[1] wartet nicht**, sondern verschiebt nur den
  Abgleich der VSCodePacks: „Im Container werden gerade
  die Kurse und Technikpakete wiederhergestellt. Den
  Abgleich mit den VSCodePacks macht das Skript beim
  nächsten Start von VS Code (Menüpunkt [9])."

Dauert es länger als 10 Minuten (langsame Verbindung)
oder haben Sie eine Taste gedrückt, geht das Skript
trotzdem weiter: „Die Wiederherstellung läuft im
Hintergrund weiter. Es geht trotzdem weiter; bis sie
fertig ist, fehlen im Container noch Werkzeuge. Fehlen
danach Erweiterungen in VS Code, richten Sie die
VSCodePacks mit Menüpunkt [10] erneut ein."

Den Fortschritt sehen Sie im Container mit `clawbook
status` (oder Menüpunkt 1) in der Zeile
„Wiederherstellung:" — mit „läuft", „fertig" oder
„FEHLER" — und ausführlich im Protokoll:

```bash
tail -f ~/.clawbook/restore.log
```

(`Strg+C` beendet die Anzeige, nicht die
Wiederherstellung.)

## 8. Die Pakete im Überblick

Technikpakete:

| Paket | Was es mitbringt | In den Kursen |
|---|---|---|
| `clawbook-python` | pytest und ruff für Python | — |
| `clawbook-java` | Java (OpenJDK 25), Maven, Gradle 9 | über `clawbook-spring` in `kurs-inf`, `kurs-swe` |
| `clawbook-spring` | Spring-Boot-CLI (`spring`), baut auf `clawbook-java` auf | `kurs-inf`, `kurs-swe` |
| `clawbook-dotnet` | .NET SDK 10.0 mit `dotnet-ef` (Entity Framework) | `kurs-swe` |
| `clawbook-db-postgres` | PostgreSQL 17 als Dienst (Abschnitt 9), `psql` | `kurs-swe` |
| `clawbook-db-sqlite` | SQLite (`sqlite3`) | `kurs-inf`, `kurs-swe` |
| `clawbook-webapi` | Web-APIs testen: `httpie`, `xh`, `hurl`, `curl` | alle drei |
| `clawbook-modeling` | PlantUML (`plantuml`) und Graphviz | `kurs-swe` |
| `clawbook-embedded` | PlatformIO (`pio`), `esptool`, pyserial | `kurs-iot` |
| `clawbook-iot` | MQTT-Clients (`mosquitto_pub`, `mosquitto_sub`), paho-mqtt für Python | `kurs-iot` |
| `clawbook-nodered` | Node-RED als Dienst (Abschnitt 9) | `kurs-iot` |
| `clawbook-security` | `nmap`, `tshark` (Netzwerk mitschneiden ohne `sudo`), `gnupg` | `kurs-iot` |

Wo es passt, bringt ein Technikpaket die
VS-Code-Erweiterungen für den Container mit, zum Beispiel
das Java-Erweiterungspaket, C# Dev Kit, PostgreSQL,
PlantUML oder PlatformIO IDE.

Kurse:

| Kurs | Titel | Download (ungefähr) |
|---|---|---|
| `kurs-inf` | Ingenieurinformatik: Java mit Spring Boot, Web-APIs, SQLite | 0,8 GB |
| `kurs-swe` | Softwareengineering: Java mit Spring Boot, .NET mit Entity Framework, PostgreSQL und SQLite, Web-APIs, Modellierung mit PlantUML | 1,7 GB |
| `kurs-iot` | IoT: ESP32 mit PlatformIO und Arduino, MQTT, Node-RED, Netzwerkanalyse, Web-APIs | 0,35 GB, PlatformIO auf Wunsch etwa 6 GB |

Die aktuelle Liste mit Versionen zeigt im Container:

```bash
clawbook pakete katalog
```

## 9. Dienste: PostgreSQL und Node-RED

Zwei Technikpakete bringen einen Dienst mit, der im
Container im Hintergrund läuft: sofort nach der
Installation und bei jedem Start des Containers. Beide
laufen als Ihr Benutzer `student` und sind **nur im
Container** erreichbar, nicht von Windows aus und nicht
aus dem Netz. Deshalb brauchen sie kein Passwort.

### PostgreSQL (`clawbook-db-postgres`, in `kurs-swe`)

Beim ersten Start legt der Dienst die Datenbank `student`
an; das dauert einige Sekunden. Danach genügt im
Terminal:

```bash
psql
```

`\q` beendet `psql`. Die Daten liegen in Ihrem Home
(`~/.local/share/postgresql/17`); sie überstehen
Aktualisierungen und sind in jeder Sicherung enthalten.
In VS Code und in Ihren Programmen verbinden Sie sich mit
Host `localhost`, Port `5432`, Benutzer `student`,
Datenbank `student`, ohne Passwort.

### Node-RED (`clawbook-nodered`, in `kurs-iot`)

Der Editor von Node-RED ist eine Webseite im Container
unter Port 1880. Ihr Browser unter Windows erreicht sie
über VS Code:

1. VS Code mit clawbook verbinden (Abschnitt 4).
2. Unten im Bereich mit dem Terminal den Reiter **Ports
   (PORTS)** öffnen. Steht dort schon `1880`, weiter mit
   Schritt 4.
3. **Port weiterleiten (Forward a Port)** wählen, `1880`
   eingeben, Enter.
4. Im Browser unter Windows <http://localhost:1880>
   öffnen (oder in der Zeile von Port 1880 auf das
   Weltkugel-Symbol klicken).

Die Weiterleitung besteht, solange VS Code verbunden ist.
Ihre Flows speichert Node-RED in `~/.node-red`, also in
Ihrem Home.

## Wenn etwas nicht geht

- **„Warnung: Keine Verbindung zum Internet: Die
  Paketquellen sind nicht erreichbar. clawbook arbeitet
  mit den zuletzt geladenen Paketlisten."** — prüfen Sie
  die Verbindung und versuchen Sie es erneut. Ohne
  Internet lässt sich nur installieren, was schon im
  Paket-Cache liegt.
- **„Die Paketquelle clawbook-apt kennt noch keine Pakete;
  aktualisieren mit: clawbook pakete katalog"** — die
  Paketliste wurde noch nie geladen, meist wegen fehlender
  Verbindung. Mit Internet erneut versuchen.
- **„Nicht in der Paketquelle: …"** — der Name ist
  vertippt, oder das Paket gibt es nicht mehr. Die
  richtigen Namen zeigt `clawbook pakete katalog`.
- **„Die Installation ist fehlgeschlagen oder wurde
  abgebrochen (apt-get …)."** — Sie haben die Frage von
  `apt` verneint, oder der Download ist abgebrochen.
  Wählen Sie den Kurs einfach noch einmal; was schon
  geladen ist, lädt `apt` nicht erneut.
- **„Hinweis: Die Wiederherstellung der Pakete läuft
  noch. Die Installation wartet, bis sie fertig ist; die
  Paketlisten werden dabei vielleicht nicht
  aktualisiert."** — kein Fehler: Nach einer
  Aktualisierung läuft noch die Wiederherstellung
  (Abschnitt 7); `clawbook` macht danach von selbst
  weiter. Bei **„Die Paketverwaltung ist gerade belegt
  (läuft eine Installation?)."** warten Sie ebenfalls,
  bis die andere Installation fertig ist, und versuchen
  es dann erneut.
- **„Das Menü für Kurse und Technikpakete gibt es erst
  mit einem neueren Image."** — das Image ist älter als
  das Skript. Aktualisieren Sie mit Menüpunkt [2]
  (siehe [Pflege](pflege.md), Abschnitt 3).
- **Im clawbook-Menü steht „Pakete nach neuem Image:
  FEHLER, siehe Status (1); erneut: clawbook
  wiederherstellen"**, oder das Skript meldet „Hinweis:
  Die Wiederherstellung der Kurse und Technikpakete im
  Container ist fehlgeschlagen. Prüfen Sie sie mit
  Menüpunkt [11]." — Menüpunkt 1 (`clawbook status`)
  nennt den Grund. Häufig ist es fehlendes Internet:
  „Ohne Internet gelingt das nur, wenn alle Pakete im
  Cache liegen." oder „Kein Netz, und im Paket-Cache
  fehlt etwas für: …". Sorgen Sie für eine Verbindung
  und starten Sie die Wiederherstellung im Container
  neu:

  ```bash
  clawbook wiederherstellen
  ```

  Ist alles da, meldet sie „Nichts wiederherzustellen:
  Alle Pakete aus dem Stand sind installiert."
- **Die Wiederherstellung dauert sehr lange** — sie lädt
  nach, was nicht im Cache liegt, etwa nach einem Umzug
  mit einer älteren Sicherung. Den Fortschritt zeigt
  `tail -f ~/.clawbook/restore.log`.
- **„Für den Kurs „…“ gibt es keine brauchbare
  Beschreibung aus dem Container. Dieses VSCodePack wird
  übersprungen. Ist der Kurs im Container installiert
  (Menüpunkt [11])?"** — der Kurs fehlt im Container,
  oder die Wiederherstellung ist noch nicht fertig.
  Prüfen Sie mit [11], ob der Kurs `[x]` hat. Meldet das
  Skript stattdessen „Die Kursbeschreibung für „…“ …"
  mit „Das VSCodePack „…“ wird übersprungen.", ist die
  Beschreibung des Kurses fehlerhaft oder zu neu für das
  Skript; führen Sie den Befehl von der Startseite
  erneut aus (er holt das neueste Skript) und melden Sie
  es sonst der Betreuung.
- **In VS Code fehlen Erweiterungen**, zum Beispiel nach
  einem weiteren Kurs, einem Technikpaket oder einer
  Aktualisierung — **[10]**, dann **[1]** wählen. Das
  Skript bringt alle VSCodePacks auf den Stand des
  Containers. Danach VS Code neu starten.
- **„Das Vorladen hat nicht geklappt (pio …). Später
  erneut: clawbook pakete vorladen"** — meist ist die
  Verbindung abgebrochen oder der Platz knapp. Mit
  stabiler Verbindung `clawbook pakete vorladen`
  wiederholen.
- **„PlatformIO fehlt: zuerst clawbook pakete add
  clawbook-embedded (oder kurs-iot)."** — PlatformIO
  kommt erst mit `kurs-iot` (Abschnitt 2).
- **`tshark` darf nach der Installation nicht
  mitschneiden** — das Recht dazu gilt ab der nächsten
  Anmeldung. Mit `exit` abmelden und neu verbinden.
- **`psql` meldet direkt nach der Installation, dass
  keine Verbindung möglich ist** — der Dienst legt beim
  ersten Start noch die Datenbank an. Einige Sekunden
  warten und erneut versuchen.
- **<http://localhost:1880> geht nicht** — ist VS Code
  verbunden und steht 1880 im Reiter „Ports"? Ist
  `kurs-iot` (oder `clawbook-nodered`) installiert?
- **Das Home wird voll** — `clawbook status` zeigt in
  der Zeile „Paket-Cache:", wie viel die aufbewahrten
  Pakete belegen; dazu kommt gegebenenfalls
  `~/.platformio`. Den Paket-Cache leeren Sie mit
  `sudo apt-get clean`. Dann braucht die nächste
  Wiederherstellung nach einer Aktualisierung aber
  wieder Internet und lädt alles neu.

Hilft das nicht, wenden Sie sich an die Betreuung Ihrer
Lehrveranstaltung. Nennen Sie dabei die genaue Meldung
und schicken Sie, wenn es um die Wiederherstellung geht,
die Datei `~/.clawbook/restore.log` mit.
