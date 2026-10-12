# Installation: clawbook starten und verbinden

Stand: 2026-10-11

Diese Anleitung bringt clawbook auf Ihren Windows-Rechner:
Sie führen einen Befehl aus, warten, bis der Arbeitsrechner
läuft, und verbinden sich dann mit Terminal, VS Code und
Bildschirm. Administrator-Rechte brauchen Sie dafür nicht.
Planen Sie für den ersten Durchlauf etwa eine Stunde ein;
das meiste davon ist Wartezeit beim Herunterladen.

Wenn Sie noch nicht wissen, was clawbook ist, oder ein Wort
nicht kennen (Container, Image, Volume, SSH, Port …): Der
[Wegweiser](README.md) erklärt das Projekt und die
Begriffe.

Schreibweise in dieser Anleitung: Pfade wie
`%USERPROFILE%\clawbook` sind Windows-Pfade;
`%USERPROFILE%` steht für Ihr Benutzerprofil, meist
`C:\Users\<ihr-name>`. So können Sie sie in die Adresszeile
des Windows-Explorers einfügen. In PowerShell heißt
dasselbe `$env:USERPROFILE`. Meldungen des
Verwaltungs-Skripts stehen hier wörtlich in
Anführungszeichen. Das Skript spricht Sie mit „du" an; so
steht es auch in den Zitaten.

## 1. Voraussetzungen

> **Studieren Sie an der TH Ingolstadt?** In den CIP-Pools
> sind WSL und WSLC bereits installiert. Wollen Sie
> clawbook woanders nutzen, folgen Sie den Hinweisen zur
> [Installation zu Hause](#wsl-zu-hause-installieren).

Sie brauchen:

- **Windows 11 oder Windows 10** mit **WSL ab Version
  3.0.1** (Prüfung unten). WSL, das „Windows-Subsystem
  für Linux", ist ein Bestandteil von Windows, der
  Linux-Programme ausführt. WSLC ist der Teil davon, der
  Container verwaltet; er bringt den Befehl `wslc` mit,
  den das Skript nutzt. Beide haben dieselbe
  Versionsnummer.
- Den **OpenSSH-Client** von Windows (Prüfung unten).
- **Platz auf der Festplatte**: Das Image ist mehrere
  Gigabyte groß, und Ihr Home-Verzeichnis im Container
  wächst mit Ihren Projekten. Rechnen Sie mit mindestens
  20 GB freiem Platz; das VS Code aus Abschnitt 5 braucht
  noch einmal etwa 1 GB.
- **Internetzugang** zu GitHub, zu `ghcr.io` (dort liegt
  das Image) und zu Microsoft (dort holt das Skript
  VS Code). Für den ersten Start werden einige GB
  geladen: Nehmen Sie eine stabile Verbindung
  (Hochschule, zu Hause), nicht das WLAN im Zug oder
  einen Handy-Hotspot.

### WSL prüfen

Windows PowerShell öffnen: Startmenü, „PowerShell"
eintippen, Enter. Es öffnet sich ein Fenster (meist mit
blauem Hintergrund), in dem jede Zeile mit `PS C:\…>`
beginnt — das ist das Terminal von Windows. Dort
eingeben:

```powershell
wsl --version
```

Die erste Zeile zeigt die WSL-Version. Das Skript prüft
später dieselbe Versionsreihe über den Befehl `wslc` und
meldet, wenn sie nicht reicht: „Deine WSL-Version ist zu
alt: wslc 3.x.y, nötig ist mindestens 3.0.1." Ist die
Version älter als 3.0.1, aktualisieren Sie WSL mit:

```powershell
wsl --update
```

Das geht **ohne** Administrator-Rechte. Das Skript aus dem
nächsten Schritt bietet Ihnen das auch selbst an, wenn
die Version zu alt ist; folgen Sie dann seinen Hinweisen.

Zeigt `wsl --version` einen Fehler oder ist der Befehl
unbekannt, ist WSL auf dem Rechner noch gar nicht
installiert. Auf einem Hochschul-Rechner wenden Sie sich
dann an die IT oder an die Betreuung Ihrer
Lehrveranstaltung; auf Ihrem eigenen Rechner hilft der
nächste Abschnitt.

### WSL zu Hause installieren

Auf Ihrem eigenen Windows-Rechner richten Sie WSL und
WSLC einmalig selbst ein. Nur der erste Schritt braucht
Administrator-Rechte.

1. PowerShell **als Administrator** öffnen: Startmenü,
   „PowerShell" eintippen, Rechtsklick → „Als
   Administrator ausführen". Dann:

   ```powershell
   wsl --install --no-distribution
   ```

   Das installiert WSL ohne eine eigene
   Linux-Distribution (die brauchen Sie für clawbook
   nicht). Das Skript empfiehlt an dieser Stelle das
   kürzere `wsl --install` — das geht genauso, installiert
   aber zusätzlich Ubuntu, das nur Platz kostet. Danach
   **Windows neu starten**.
2. Eine normale PowerShell öffnen (ohne Administrator)
   und WSL auf den neuesten Stand bringen — damit kommt
   auch WSLC (der Befehl `wslc`):

   ```powershell
   wsl --update
   ```

3. Prüfen:

   ```powershell
   wsl --version
   wslc version
   ```

   Beide müssen mindestens **3.0.1** zeigen. Meldet
   PowerShell, `wslc` sei nicht erkannt, obwohl das Update
   durchgelaufen ist: Das Fenster schließen, ein neues
   PowerShell-Fenster öffnen und noch einmal prüfen — ein
   offenes Fenster kennt neu hinzugekommene Befehle noch
   nicht.

Klappt Schritt 1 nicht, weil die Virtualisierung
ausgeschaltet ist (Meldung mit „Virtual Machine Platform"
oder „Virtualisierung"), muss sie im BIOS/UEFI des
Rechners eingeschaltet werden; die Microsoft-Anleitung
dazu: <https://learn.microsoft.com/windows/wsl/install>.

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
Zugriff auf GitHub, `ghcr.io` oder die Download-Server
von Microsoft (Proxy, Firewall), das Ausführen von
PowerShell-Skripten, oder der Virenschutz meldet den
Befehl aus Abschnitt 2. Das können Sie nicht selbst
lösen. Notieren Sie die Meldung (Foto oder kopierter
Text) und wenden Sie sich an die Betreuung Ihrer
Lehrveranstaltung; sie klärt es mit der IT.

## 2. Der eine Befehl

Alles Weitere erledigt ein Verwaltungs-Skript. Sie müssen
es nicht herunterladen oder installieren: Ein Befehl holt
immer die aktuelle Fassung und startet sie. Derselbe
Befehl dient später auch zum Starten, Aktualisieren und
Sichern.

1. Windows PowerShell öffnen (kein Administrator nötig;
   Fenster mit `PS C:\…>`, siehe Abschnitt 1).
2. Diesen Befehl kopieren, in PowerShell mit **Rechtsklick**
   (oder `Strg+V`) einfügen und mit Enter ausführen:

   ```powershell
   irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
   ```

   `irm` lädt das Skript aus dem Internet, `iex` führt es
   aus. Das Skript landet unter
   `%LOCALAPPDATA%\clawbook\clawbook.ps1`; dort können Sie
   es jederzeit nachlesen. Als Erstes nennt es den Pfad
   seines Protokolls („Protokoll: …") — den brauchen Sie
   nur, wenn etwas schiefgeht.

3. Das Skript prüft WSL und den OpenSSH-Client und sagt
   Ihnen, wenn etwas fehlt (dann zurück zu Abschnitt 1).
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
   einrichten**. Punkt 2 brauchen Sie nur, wenn Sie schon
   eine Sicherung von einem anderen Rechner mitbringen —
   das steht in der [Pflege-Anleitung](pflege.md),
   Abschnitt 6.

**Das Skript endet nach jeder Menüwahl.** Wenn Sie es
erneut brauchen — gleich für VS Code in Abschnitt 5 und
später für jeden Start —, führen Sie denselben Befehl
noch einmal aus: im selben PowerShell-Fenster die
**Pfeiltaste nach oben** drücken (holt den letzten Befehl
zurück) und Enter, oder den Befehl erneut einfügen. Sobald
VS Code eingerichtet ist, gibt es außerdem den Eintrag
„clawbook VS Code" im Startmenü, der Container und VS Code
in einem Zug startet (Abschnitt 5).

Erscheint stattdessen eine **rote Fehlermeldung**: nicht
schließen — das Skript wartet mit „Drücke Enter, um zu
beenden", damit Sie den Text lesen können. Schauen Sie in
den Abschnitt „Wenn etwas nicht geht" am Ende dieser
Seite.

## 3. Was beim ersten Start passiert

**Jetzt müssen Sie nichts tun, nur warten.** Das Skript
sagt Ihnen, was es gerade tut:

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
  Speicherbereich für Ihre Daten, getrennt vom Image.
  Darin liegt Ihr Home-Verzeichnis `/home/student` mit
  allem, was Sie später einrichten. Es überlebt
  Aktualisierungen des Images.
- **Container anlegen und starten** — der Container ist
  das laufende Exemplar des Images.
- **Warten auf den Container** — der erste Start
  („Kaltstart") dauert **bis zu drei Minuten**, weil der
  Container seine Schlüssel erzeugt. Das Skript wartet und
  meldet sich dann.
- **SSH einrichten** — damit Sie sich verbinden können
  (Erklärung im nächsten Abschnitt).

Am Ende zeigt das Skript einen grünen Kasten „clawbook
läuft. So geht es weiter:" mit drei nummerierten
Schritten: „1. Terminal: Öffne ein neues
PowerShell-Fenster und gib ein: ssh clawbook",
„2. VS Code: Befehl erneut ausführen, Menüpunkt [9]
(richtet beim ersten Mal ein eigenes VS Code ein), oder im
eigenen VS Code: Remote-SSH → clawbook → Ordner
/home/student/source" und „3. Remotedesktop:
mstsc /v:localhost:3390". Diesen Kasten sehen Sie bei
jedem Start wieder; die Abschnitte 4 bis 6 erklären die
drei Schritte ausführlich. Danach endet das Skript.

### Das Menü ab dem zweiten Aufruf

Die Menüpunkte [9] und [10] für VS Code gibt es erst, wenn
der erste Start aus diesem Abschnitt einmal durchgelaufen
ist (das Home-Volume also vorhanden ist). Ab dann zeigt
der Befehl aus Abschnitt 2 das vollständige Menü:

```text
clawbook – was möchtest du tun?
  (Container: läuft)
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

Für die Installation brauchen Sie daraus nur Punkt [9]
(Abschnitt 5); alles andere erklärt die
[Pflege-Anleitung](pflege.md).

### Was das Skript auf Ihrem Rechner eingerichtet hat

- **Einen SSH-Schlüssel** unter `%USERPROFILE%\.ssh\clawbook`.
  SSH ist das Verfahren, mit dem Sie sich von Windows aus
  im Container anmelden. Statt eines Passworts dient eine
  Schlüsseldatei; sie ist nur für Ihren Windows-Benutzer
  lesbar. Behandeln Sie sie wie ein Passwort: nicht
  kopieren, nicht verschicken.
- **Den Host `clawbook`** in der Datei
  `%USERPROFILE%\.ssh\config`. Damit weiß SSH, dass
  `clawbook` den Container auf Ihrem eigenen Rechner
  (Adresse `127.0.0.1`, Port 2222) meint und welchen
  Schlüssel es nehmen soll. Der Eintrag steht zwischen
  zwei Markierungszeilen; das Skript pflegt ihn selbst,
  ändern Sie ihn nicht von Hand.
- **Den Austauschordner** `%USERPROFILE%\clawbook\austausch`.
  Er ist im Container als `~/austausch` sichtbar — der
  einzige Ordner, den Windows und Container gemeinsam
  sehen (Abschnitt 7). `~` ist im Container die Abkürzung
  für Ihr Home-Verzeichnis `/home/student`.
- **Den Ordner für Sicherungen**
  `%USERPROFILE%\clawbook\sicherungen` (siehe
  [Pflege](pflege.md)).

Das eigene VS Code (Abschnitt 5) kommt erst mit
Menüpunkt [9] dazu.

## 4. Verbinden im Terminal

Öffnen Sie ein **neues** PowerShell-Fenster (das Fenster,
in dem das Skript lief, lassen Sie am besten offen — Sie
brauchen es in Abschnitt 5 gleich wieder) und geben Sie
ein:

```powershell
ssh clawbook
```

Beim allerersten Verbinden merkt sich SSH den Container als
bekannten Rechner und zeigt „Permanently added …" — das ist
normal und kommt nicht wieder.

Sie sind jetzt im Container angemeldet, als Benutzer
`student`. Die Eingabeaufforderung wechselt von `PS C:\…>`
zu `student@…:~$`. Alles, was Sie hier eingeben, läuft im
Container, nicht unter Windows. Mit `exit` kommen Sie
zurück nach PowerShell; der Container läuft weiter.

Für die tägliche Arbeit brauchen Sie dieses Terminal nicht
unbedingt: VS Code (Abschnitt 5) bringt ein eigenes
Terminal mit, das genauso im Container läuft.

## 5. Verbinden mit VS Code

Mit Visual Studio Code bearbeiten Sie Ihre Projekte im
Container so, als lägen sie unter Windows: Der Editor
läuft unter Windows, Dateien, Terminal und Git aber im
Container. Das ist schneller und zuverlässiger, als die
Dateien nach Windows zu kopieren.

Das Verwaltungs-Skript richtet dafür ein eigenes,
fertig eingestelltes VS Code ein — das **VSCodePack**. Es
liegt getrennt von allem, was sonst auf dem Rechner
installiert ist, braucht keine Administrator-Rechte, hat
die Erweiterung **Remote - SSH** schon an Bord, kennt
`clawbook` als Linux-Rechner und sendet keine
Nutzungsdaten an Microsoft (Telemetrie aus). Ein
VS Code, das Sie vielleicht schon haben, bleibt
unberührt.

Zur Lizenz: VS Code ist kostenlos, aber Microsoft gibt
es unter eigenen Bedingungen heraus. Deshalb verteilt
das Projekt VS Code nicht selbst — das Skript lädt es
bei jeder Installation direkt bei Microsoft, auf Ihren
Rechner und in Ihrem Namen. Für Sie ändert das nichts;
es erklärt nur, warum der Download etwas dauert.

VS Code gibt es auf Deutsch und auf Englisch; das
VSCodePack startet zunächst auf Englisch. Die Menüs stehen
hier deshalb in beiden Sprachen.

### VS Code starten und verbinden

Alles in einem Durchlauf: Menüpunkt [9] richtet das
VSCodePack beim ersten Mal selbst ein und startet dann
VS Code. Planen Sie dafür **etwa 5 bis 15 Minuten** ein
(Download und Einrichten im Container) und lassen Sie das
PowerShell-Fenster so lange offen.

1. Den Befehl aus Abschnitt 2 erneut ausführen
   (Pfeiltaste nach oben, Enter) und im Menü `9`
   eingeben: **[9] VS Code starten und verbinden
   (VSCodePack)**. Läuft der Container nicht, startet das
   Skript ihn zuerst („Der Container läuft nicht – ich
   starte ihn zuerst.").
2. Beim ersten Mal meldet das Skript „Das VSCodePack (ein
   eigenes VS Code für clawbook) ist noch nicht
   installiert." und fragt „Jetzt installieren? Dafür
   lädt das Skript VS Code (etwa 150 MB) direkt bei
   Microsoft. [J/n]" — mit **Enter** bestätigen. Das
   sehen Sie dabei:
   - „[1/4] Lade VS Code … direkt bei Microsoft (etwa
     150 MB)." — „Das dauert je nach Verbindung ein bis
     zehn Minuten – bitte nicht abbrechen und das Fenster
     offen lassen."
   - „[2/4] Prüfe die heruntergeladene Datei …" — das
     Skript vergleicht die Prüfsumme mit der Angabe von
     Microsoft und kontrolliert die digitale Signatur von
     `Code.exe`. Nur eine Datei, die wirklich von Microsoft
     stammt, wird weiterverwendet.
   - „[3/4] Entpacke VS Code. Das dauert ein bis drei
     Minuten …" — nach
     `%LOCALAPPDATA%\clawbook\vscode\clawbook\vscode-<version>`.
   - „[4/4] Richte VS Code ein …" — installiert die
     Erweiterung Remote - SSH, setzt die Einstellungen
     und legt im Startmenü den Eintrag **„clawbook VS
     Code"** an: „Verknüpfung ‚clawbook VS Code' im
     Startmenü angelegt. Sie startet zuerst den Container
     und dann VS Code."
   - Zum Schluss grün: „VSCodePack bereit: VS Code … in …"
3. Das Skript meldet „Starte VS Code … und verbinde es
   mit clawbook (Ordner /home/student/source) …". VS Code
   öffnet sich in einem **eigenen Fenster**, schon
   verbunden mit `clawbook` und mit geöffnetem Ordner
   `/home/student/source`. Eine Frage nach dem
   Fingerabdruck des Hosts kommt meist nicht; falls doch:
   **Continue**.
4. Beim ersten Verbinden installiert VS Code seinen
   Server-Teil im Container (einige hundert Megabyte, in
   Ihrem Home-Verzeichnis; bleibt bei Aktualisierungen des
   Images erhalten). Unten links läuft ein Fortschritt;
   das dauert ein bis zwei Minuten.
5. Die Frage **„Vertrauen Sie den Autoren der Dateien in
   diesem Ordner? (Do you trust the authors …?)"** mit
   „Ja, ich vertraue den Autoren (Yes, I trust the
   authors)" beantworten. Es ist Ihr eigener Ordner. Haben
   Sie die Frage versehentlich weggeklickt, arbeitet
   VS Code im **eingeschränkten Modus (Restricted Mode)**
   — so steht es dann unten in der Leiste. Klicken Sie
   darauf und wählen Sie „Vertrauen (Trust)".
6. Links im Explorer sehen Sie das Beispielprojekt
   `Sample/primer` — hier entstehen Ihre Projekte, nach
   dem Schema `~/source/<Thema>/<Projekt>` (Abschnitt 8).
7. Terminal im Container: Menü „Terminal → Neues Terminal
   (New Terminal)". Es läuft im Container als `student`,
   genau wie `ssh clawbook`.

Unten links in VS Code steht jetzt „SSH: clawbook" — daran
erkennen Sie, dass Sie im Container arbeiten. Beim
nächsten Mal genügt wieder Menüpunkt [9] — oder, ohne
PowerShell, der Eintrag **„clawbook VS Code"** im
Startmenü: Er startet den Container und dann VS Code.

### Vorbereiten oder aktualisieren: Menüpunkt [10]

**[10] VSCodePack installieren oder aktualisieren** macht
dieselbe Einrichtung wie Schritt 2 oben, nur ohne den
Container — zum Beispiel, um VS Code schon vorzubereiten,
während das Image noch lädt, oder um später eine neue
Version zu holen. Am Ende fragt das Skript „VS Code jetzt
starten und mit clawbook verbinden? [J/n]"; Enter startet
VS Code wie bei [9].

Das VS Code aus dem VSCodePack aktualisiert sich nicht von
selbst. Wählen Sie dafür gelegentlich wieder [10] — etwa,
wenn **[6] Status anzeigen** die Zeile „Neuestes VS Code:
… – aktualisieren mit Menüpunkt [10]" zeigt. Schließen Sie
vorher alle VS-Code-Fenster. Das Skript lädt die neue
Version, Ihre Erweiterungen und Einstellungen ziehen um
(„Deine Erweiterungen und Einstellungen sind in die neue
Version umgezogen."), und die vorige Version bleibt als
Rückfall liegen; ältere räumt das Skript weg. Ist die
installierte Version schon die neueste, gleicht [10] nur
Erweiterungen und Einstellungen ab.

### Ausweichweg: VS Code selbst installieren

Wenn das VSCodePack auf Ihrem Rechner nicht geht (zum
Beispiel, weil die Hochschule den Download bei Microsoft
sperrt) oder Sie schon ein eigenes VS Code nutzen und
dabei bleiben wollen, verbinden Sie es von Hand. Das
Verwaltungs-Skript hat dafür alles vorbereitet: Der Host
`clawbook` steht in Ihrer SSH-Config.

1. VS Code installieren, falls noch nicht geschehen
   (<https://code.visualstudio.com>, „User Installer",
   braucht keine Administrator-Rechte).
2. Die Erweiterung **Remote - SSH** installieren: links
   die Ansicht „Erweiterungen (Extensions)" öffnen
   (Symbol mit den vier Quadraten oder `Strg+Umschalt+X`),
   nach `Remote - SSH` suchen, die Erweiterung von
   Microsoft wählen, „Installieren (Install)". Ist der
   Marktplatz auf Ihrem Rechner gesperrt (vorinstalliertes
   VS Code der Hochschule), wenden Sie sich an die
   Betreuung Ihrer Lehrveranstaltung.
3. Befehlspalette öffnen (`F1` oder `Strg+Umschalt+P`),
   **Remote-SSH: Mit Host verbinden… (Connect to Host…)**
   wählen und `clawbook` anklicken. VS Code nutzt den
   Eintrag, den das Skript in die SSH-Config geschrieben
   hat.
4. Es öffnet sich ein **neues Fenster**. Beim ersten Mal
   fragt VS Code unter Umständen nach dem Betriebssystem
   des Ziels — **Linux** — und ob Sie den Fingerabdruck
   des Hosts annehmen wollen — **Continue**. Dann
   installiert es seinen Server-Teil im Container (einige
   hundert Megabyte, in Ihrem Home-Verzeichnis; bleibt bei
   Aktualisierungen erhalten). Unten links läuft ein
   Fortschritt; das dauert beim ersten Mal ein bis zwei
   Minuten.
5. **Ordner öffnen**: Menü „Datei → Ordner öffnen…
   (File → Open Folder…)". Oben erscheint ein Eingabefeld
   mit einem Pfad; dort `/home/student/source` eintragen
   und mit „OK" bestätigen. Darin liegt anfangs nur das
   Beispielprojekt `Sample/primer` — hier entstehen
   Ihre Projekte.
6. Die Frage **„Vertrauen Sie den Autoren der Dateien in
   diesem Ordner? (Do you trust the authors …?)"** mit
   „Ja, ich vertraue den Autoren (Yes, I trust the
   authors)" beantworten. Es ist Ihr eigener Ordner.
7. Terminal im Container: Menü „Terminal → Neues Terminal
   (New Terminal)". Es läuft im Container als `student`,
   genau wie `ssh clawbook`.

Auch hier steht unten links „SSH: clawbook". Beim nächsten
Mal reichen Schritt 3 und „Datei → Zuletzt verwendet
öffnen (Open Recent)". Denken Sie daran, den Container
vorher zu starten (Befehl aus Abschnitt 2, Enter).

Sieht Ihr Kurs weitere Erweiterungen vor (zum Beispiel
für Java), nennt sie die Anleitung Ihres Kurses. Mit dem
VSCodePack kommen sie automatisch; auf diesem Ausweichweg
installieren Sie sie selbst.

## 6. Den Bildschirm des Containers sehen

Der Container hat einen eigenen grafischen Bildschirm. Sie
brauchen ihn nur selten: für **Anmeldungen im Browser**,
die ein Werkzeug **im Container** öffnet (zum Beispiel
NotebookLM — die meisten Werkzeuge nutzen stattdessen
Ihren Browser unter Windows, siehe [Setup](setup/README.md)),
oder wenn ein Agent Ihnen eine Webseite zeigen will.

1. Unter Windows das Programm „Remotedesktopverbindung"
   starten — am schnellsten in PowerShell:

   ```powershell
   mstsc /v:localhost:3390
   ```

2. Die **Zertifikatsfrage** mit „Ja" beantworten. Das
   Zertifikat hat der Container beim ersten Start selbst
   ausgestellt; Windows kennt es deshalb nicht. Es sichert
   nur die Verbindung zwischen Ihrem Windows und Ihrem
   Container auf demselben Rechner.
3. Ein Passwort gibt es nicht. Fragt Windows trotzdem nach
   Benutzername und Passwort: Abbrechen und erneut
   verbinden; hilft das nicht, melden Sie sich bei der
   Betreuung Ihrer Lehrveranstaltung.

Warum kein Passwort in Ordnung ist: Der Bildschirm ist nur
unter `127.0.0.1` erreichbar, also nur von dem Rechner aus,
auf dem der Container läuft — nicht aus dem Netz. Und im
Container gibt es nichts, was nicht Ihnen gehört: nur die
Anmeldungen, die Sie selbst dort einrichten. **Nicht
geeignet** ist das für Rechner, an denen gleichzeitig
andere Personen angemeldet sind (Terminalserver, geteilte
Sitzungen): Dort könnte jeder Angemeldete `localhost:3390`
öffnen. Nutzen Sie den Bildschirm dann nicht oder fragen
Sie die Betreuung.

Oben in der Leiste finden Sie zwei Symbole: **Chromium**
(der Browser) und ein **Terminal**. Beide laufen als
`student`. Wenn Sie das Remotedesktop-Fenster schließen,
trennen Sie nur die Anzeige; Browser und Container laufen
weiter.

## 7. Der Austauschordner

`%USERPROFILE%\clawbook\austausch` unter Windows ist im
Container `~/austausch`. Was Sie dort ablegen, sehen beide
Seiten — in beide Richtungen. Er ist gedacht für
gelegentliche Übergaben: eine PDF für den Agenten, ein
Ergebnis für eine Abgabe. Löschen Sie den Windows-Ordner
nicht; im Container erschiene `~/austausch` dann leer.

Ihre Projekte gehören **nicht** in den Austauschordner,
sondern nach `~/source` im Home-Volume. Gründe: Im
Austauschordner sind Dateizugriffe aus dem Container
vielfach langsamer, Linux-Dateirechte lassen sich dort
nicht setzen, und Werkzeuge, die auf Dateiänderungen
reagieren (Entwicklungsserver, Tests im Watch-Modus),
bekommen Änderungen von der Windows-Seite nicht mit.

## 8. Erste Schritte im Container

Verbinden Sie sich mit `ssh clawbook` oder im
VS-Code-Terminal und prüfen Sie, ob alle Werkzeuge da
sind:

```bash
clawbook-check
```

Die Ausgabe ist eine Tabelle mit allen Werkzeugen und
ihren Versionen. Steht irgendwo `FEHLT`, stimmt etwas mit
dem Image nicht — melden Sie es bei der Betreuung Ihrer
Lehrveranstaltung.

Dieselbe Prüfung erreichen Sie auch über den Befehl
`clawbook`: Ohne Parameter zeigt er ein kleines Menü
(Status, Werkzeuge prüfen, Schlüssel anzeigen, Stand
anzeigen). `clawbook-check` funktioniert weiterhin und ist
eine Abkürzung für `clawbook check`.

Ihre Projekte liegen unter `~/source`, sortiert nach
Thema: `~/source/<Thema>/<Projekt>`, jedes Projekt ein
eigenes Git-Repository. Ein erstes Beispiel ist schon da:
`~/source/Sample/primer` — dort können Sie gefahrlos
ausprobieren. Neue Projekte legt der WorkspaceManager mit
dem Befehl `wsm` in genau dieser Struktur an und startet
Agenten darin; `wsm --help` zeigt seine Möglichkeiten.

Die KI-Werkzeuge sind installiert, aber noch nicht
angemeldet — die Zugänge gehören Ihnen und kommen nicht
aus dem Image. Wie Sie jeden Account anlegen und jedes
Werkzeug anmelden, steht im [Setup](setup/README.md). Das
ist der nächste Schritt.

## Wenn etwas nicht geht

Das Skript schreibt alles, was es tut, in ein Protokoll
unter `%LOCALAPPDATA%\clawbook\logs\` und nennt den Pfad
am Anfang jedes Laufs und bei jeder Fehlermeldung. Ihren
privaten Schlüssel schwärzt es darin („[privater Schlüssel
entfernt]"), Sie dürfen das Protokoll also an die
Betreuung schicken — werfen Sie trotzdem vorher kurz einen
Blick hinein. Bei einem Fehler bleibt das Fenster offen
(„Drücke Enter, um zu beenden"), damit Sie die Meldung
lesen können.

### Start und Verbindung

- **Rote Meldung sofort nach dem Einfügen des Befehls**
  (Skripte gesperrt, Virenschutz, kein Zugriff auf
  GitHub) — siehe Abschnitt 1, „Wenn die Hochschule etwas
  blockiert".
- **„WSL (Windows-Subsystem für Linux) ist auf diesem
  Rechner nicht installiert."** — das Skript empfiehlt
  dann `wsl --install`; das kann Administrator-Rechte
  brauchen. Folgen Sie Abschnitt 1, „WSL zu Hause
  installieren" (dort mit `--no-distribution`, das spart
  Platz; beides führt zum Ziel).
- **„Deine WSL-Version ist zu alt: wslc …, nötig ist
  mindestens 3.0.1."** — das Skript fragt „Jetzt mit
  ‚wsl --update' aktualisieren? Das geht ohne
  Administrator-Rechte. [J/n]": Bestätigen Sie mit Enter
  und führen Sie danach den Befehl aus Abschnitt 2 erneut
  aus. Dasselbe gilt für „WSL ist installiert, aber zu
  alt: Das Werkzeug wslc (WSL-Container) fehlt noch."
- **„Der OpenSSH-Client (Befehl ssh) fehlt auf diesem
  Rechner."** — fügen Sie den OpenSSH-Client hinzu, siehe
  Abschnitt 1.
- **„Der Container braucht länger als sonst. Warte eine
  Minute und wähle dann im Menü [1] ‚starten und
  verbinden'."** — tun Sie genau das: eine Minute warten,
  den Befehl erneut ausführen, Enter. Der Container läuft
  im Hintergrund meist schon an. Bleibt die Meldung beim
  zweiten Mal, schicken Sie das Protokoll an die
  Betreuung.
- **„Port 2222 ist schon von einem anderen Programm
  belegt. clawbook braucht die Ports 2222 (SSH) und 3390
  (Remotedesktop). Beende das andere Programm oder starte
  Windows neu und versuche es dann erneut."** (oder
  dasselbe für Port 3390) — ein anderes Programm oder ein
  zweiter Benutzer auf demselben Rechner nutzt den Port.
  Beenden Sie die anderen Programme oder starten Sie
  Windows neu und versuchen Sie es dann erneut; hilft das
  nicht, fragen Sie die Betreuung.
- **`ssh clawbook` meldet „Connection refused"** — der
  Container läuft nicht. Führen Sie den Befehl aus
  Abschnitt 2 aus und drücken Sie Enter. Nach dem
  Abmelden oder einem Neustart von Windows ist das immer
  nötig, siehe [Pflege](pflege.md), Abschnitt 1.
- **`ssh clawbook` fragt nach einem Passwort** — der
  Schlüssel unter Windows passt nicht zum Container.
  Wählen Sie im Menü **[5] SSH für VS Code neu
  einrichten**; das schreibt Schlüssel und Config neu.
- **„Could not resolve hostname clawbook"** — der Eintrag
  in `%USERPROFILE%\.ssh\config` fehlt. Ebenfalls Menü [5].
- **Warnung „REMOTE HOST IDENTIFICATION HAS CHANGED"** —
  der Container hat einen anderen Fingerabdruck als beim
  letzten Mal (passiert nur, wenn er außerhalb des Skripts
  neu angelegt wurde). Löschen Sie die Datei
  `%USERPROFILE%\.ssh\known_hosts_clawbook` und wählen
  Sie dann Menü [5].
- **Remotedesktop zeigt nur Schwarz oder bricht ab** —
  warten Sie ein paar Sekunden und verbinden Sie sich
  erneut; der Bildschirm startet kurz nach SSH. Prüfen
  Sie, ob der Container läuft (`ssh clawbook` geht).
- **Alles ist sehr langsam** — liegen Ihre Dateien in
  `~/austausch` statt in `~/source`? Siehe Abschnitt 7.

### VS Code und VSCodePack

- **„Ich konnte bei Microsoft nicht nachsehen, welche
  VS-Code-Version die neueste ist."** oder **„Der Download
  von VS Code ist fehlgeschlagen."** — prüfen Sie die
  Internetverbindung und wählen Sie [9] (oder [10])
  erneut. Klappt es auch an einer stabilen Verbindung
  nicht, sperrt vermutlich die Hochschule die
  Download-Server von Microsoft: Notieren Sie die Meldung,
  fragen Sie die Betreuung und nehmen Sie einstweilen den
  Ausweichweg aus Abschnitt 5.
- **„Die Kursbeschreibung für ‚clawbook' ließ sich nicht
  laden."** — das Skript holt eine kleine Beschreibung
  von GitHub (welche Erweiterungen und Einstellungen das
  VSCodePack bekommt). GitHub ist gerade nicht erreichbar;
  versuchen Sie es später erneut.
- **„Die heruntergeladene Datei ist beschädigt (die
  Prüfsumme stimmt nicht). Ich habe sie gelöscht."** —
  der Download ist unterwegs kaputtgegangen. Wählen Sie
  einfach noch einmal [9] oder [10].
- **„Code.exe trägt keine gültige Signatur von Microsoft.
  Ich habe die entpackten Dateien wieder gelöscht."** —
  die entpackte Datei stammt nicht nachweislich von
  Microsoft; das Skript installiert sie absichtlich
  nicht. Versuchen Sie es später erneut. Kommt die
  Meldung wieder, verändert vermutlich ein Proxy oder
  Virenschutz den Download — fragen Sie die Betreuung und
  nehmen Sie einstweilen den Ausweichweg.
- **„Zu wenig Platz in …: VS Code braucht etwa 1 GB, frei
  sind … GB."** — schaffen Sie auf dem Laufwerk mit
  `%LOCALAPPDATA%` Platz (Papierkorb leeren, Downloads
  aufräumen) und wählen Sie [9] oder [10] erneut.
- **„VS Code aus dem VSCodePack läuft noch. Schließe alle
  VS-Code-Fenster und versuche es dann erneut."** — beim
  Aktualisieren muss VS Code geschlossen sein. Schließen
  Sie alle VS-Code-Fenster und wählen Sie dann [10].
  Dasselbe gilt für „Deine VS-Code-Daten ließen sich
  nicht übernehmen (läuft VS Code noch?)": Ihre
  Einstellungen sind unverändert, nur der Umzug in die
  neue Version wartet.
- **„Hinweis: VS Code aus dem VSCodePack läuft gerade.
  Neue Einstellungen wirken nach einem Neustart von
  VS Code."** — kein Fehler: Schließen Sie VS Code einmal
  und starten Sie es wieder.
- **„Nicht alle Erweiterungen ließen sich installieren.
  Wähle später noch einmal Menüpunkt [10]."** — der
  Marktplatz von VS Code war nicht erreichbar. Wiederholen
  Sie [10] später; ohne Remote - SSH kommt keine
  Verbindung zustande. Bleibt es dabei, ist der
  Marktplatz vermutlich gesperrt — fragen Sie die
  Betreuung.
- **„Die Verknüpfung im Startmenü ließ sich nicht
  anlegen."** — kein Problem: Starten Sie VS Code dann
  immer über Menüpunkt [9].
- **VS Code bleibt beim Verbinden hängen** — prüfen Sie
  zuerst, ob `ssh clawbook` in PowerShell geht. Wenn ja:
  Öffnen Sie in VS Code die Befehlspalette (`F1`), führen
  Sie „Remote-SSH: VS Code Server auf Host beenden… (Kill
  VS Code Server on Host…)" aus und verbinden Sie sich
  erneut ([9] oder, beim Ausweichweg, „Mit Host
  verbinden…").
- **VS Code öffnet sich, aber unten links steht nicht
  „SSH: clawbook"** — die Verbindung ist nicht zustande
  gekommen. Schließen Sie das Fenster, prüfen Sie, ob
  `ssh clawbook` geht (sonst Menü [5]), und wählen Sie
  dann [9] erneut.
- **Unten in der Leiste steht „Eingeschränkter Modus
  (Restricted Mode)"** — die Vertrauensfrage wurde
  weggeklickt. Klicken Sie darauf und wählen Sie
  „Vertrauen (Trust)" (Abschnitt 5, Schritt 5).

## Anhang: Ohne WSLC — mit podman in einer WSL-Distribution

**Nur für Fortgeschrittene oder auf Anweisung der
Betreuung.** Dies ist ein Ausweichweg für den Fall, dass
WSLC auf Ihrem Rechner nicht geht oder nicht erlaubt ist.
Das Verwaltungs-Skript und sein Menü nutzen Sie dann
nicht; Sie geben alle Befehle selbst ein, und die
[Pflege-Anleitung](pflege.md) gilt nur sinngemäß. Auch das
VSCodePack gibt es auf diesem Weg nicht; für VS Code
nehmen Sie den Ausweichweg aus Abschnitt 5. Für den
Normalfall gilt die Anleitung oben. Wenn Sie unsicher
sind, fragen Sie die Betreuung Ihrer Lehrveranstaltung,
bevor Sie hier anfangen.

Sie brauchen eine WSL-Distribution (zum Beispiel Debian
oder Ubuntu) in WSL 2 und darin das Passwort Ihres
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
Windows brauchen Sie dafür keine Rechte. Damit die
Dateifreigabe (Samba, Port 445) als normaler Benutzer
funktioniert, einmalig erlauben:

```bash
echo 'net.ipv4.ip_unprivileged_port_start=445' \
  | sudo tee /etc/sysctl.d/90-clawbook.conf
sudo sysctl --system
```

**Volume anlegen und Container starten** (im Hintergrund,
damit Ihr Terminal frei bleibt):

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
`-v clawbook-home:/home/student` legt Ihr Home ins
Volume.

**Schlüssel und Passwort finden:** Beim Start schreibt der
Container einen Kasten mit den Verbindungsdaten, Ihrem
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

Danach gehen `ssh clawbook`, VS Code (Abschnitt 5,
Ausweichweg) und der Bildschirm (Abschnitt 6) wie oben
beschrieben.

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
oben erneut ausführen — das Volume und damit Ihr Stand
bleiben.

**Sichern und mitnehmen** — die Datei landet im aktuellen
Verzeichnis; nehmen Sie dasselbe Namensschema wie das
Skript, damit beide Wege zusammenpassen:

```bash
podman volume export clawbook-home --output home-2026-10-05-120000.tar
# auf einem anderen Rechner:
podman volume create clawbook-home
podman volume import clawbook-home home-2026-10-05-120000.tar
```

Das Archiv enthält Ihre Logins und Ihren privaten
Schlüssel — behandeln Sie es wie ein Passwort.

**Wenn etwas nicht geht (podman-Weg):** „Port 445 nicht
erlaubt" → die `sysctl`-Einstellung oben fehlt. Explorer
findet die Freigabe nicht → IP mit `hostname -I` prüfen,
läuft der Container (`podman ps`)? Warnung „REMOTE HOST
IDENTIFICATION HAS CHANGED" → tritt nur nach einem neuen
Volume auf; die Datei
`%USERPROFILE%\.ssh\known_hosts_clawbook` löschen.
