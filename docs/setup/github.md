# GitHub: git, gh und Copilot CLI

Stand: 2026-10-12

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> suchen Sie den aktuellen Weg bitte selbst auf der
> Seite des Anbieters.

Mit einem GitHub-Konto bekommen Sie drei Dinge auf
einmal: einen Ort für Ihre Repositories (`git`), das
Kommandozeilen-Werkzeug `gh` für GitHub selbst und —
über das Studierenden-Programm — den Coding-Agenten
**GitHub Copilot CLI** (`copilot`). Auch der
WorkspaceManager `wsm` legt neue Projekte über `gh` auf
GitHub an.

**Kosten:** Das GitHub-Konto ist kostenlos. Copilot
ist für verifizierte Studierende im Plan
„Copilot Student" kostenlos (Teil des GitHub Student
Developer Pack; Quelle:
<https://education.github.com/pack> und
<https://docs.github.com/en/copilot/get-started/plans>,
Stand 2026-10-05). Ohne Studierenden-Nachweis gibt es
den Plan „Copilot Free" mit kleinem Kontingent; Copilot
Pro kostet laut derselben Seite 10 US-Dollar im Monat
und verlängert sich automatisch (Kündigung unter
Settings → Billing). Für den Kurs brauchen Sie kein
bezahltes Copilot.

## Beim Anbieter

### Konto anlegen

1. Auf <https://github.com> ein Konto anlegen
   („Sign up"). Nehmen Sie einen Benutzernamen, den
   Sie auch in zwei Jahren noch tragen wollen — er
   steht in jeder Repository-Adresse.
2. Die E-Mail-Adresse bestätigen.
3. Die **Zwei-Faktor-Anmeldung** einschalten
   (Settings → Password and authentication). Wählen
   Sie eine Authenticator-App auf dem Handy (zum
   Beispiel die von Microsoft, Google oder eine freie
   wie Aegis) — nicht SMS. GitHub zeigt dabei einmalig
   **Wiederherstellungscodes**: Speichern Sie sie an
   einem sicheren Ort außerhalb des Handys. Verlieren
   Sie Handy und Codes, ist das Konto weg.

### Student Developer Pack beantragen

Das **GitHub Student Developer Pack** bündelt
kostenlose Angebote für Studierende, darunter den
Copilot-Plan für Studierende.

1. <https://education.github.com/pack> öffnen,
   „Sign up for Student Developer Pack" wählen.
2. Im Antrag Ihre Hochschule angeben und einen
   Nachweis hochladen. GitHub akzeptiert laut
   Anleitung zum Beispiel ein Foto des
   Studierendenausweises mit aktuellem Datum, einen
   Stundenplan oder eine Immatrikulationsbescheinigung
   (Quelle:
   <https://docs.github.com/en/education/about-github-education/github-education-for-students/apply-to-github-education-as-a-student>,
   Stand 2026-10-05). Voraussetzung: mindestens
   13 Jahre alt und in einem Studien- oder
   Ausbildungsgang eingeschrieben. Wenn Ihre
   Hochschule Ihnen eine Hochschul-E-Mail-Adresse
   gibt, tragen Sie sie vorher im GitHub-Konto ein —
   das beschleunigt die Prüfung.
3. Warten. Die Prüfung kann einige Tage dauern; Sie
   bekommen eine E-Mail.
4. Nach der Freischaltung: Settings → Copilot prüfen.
   Dort sollte der Plan „Copilot Student" angeboten
   werden oder schon aktiv sein. Der Plan enthält laut
   GitHub unbegrenzte Code-Vervollständigungen und ein
   monatliches Kontingent an „AI Credits" für Chat und
   Agenten, bei automatischer Modellwahl. GitHub
   prüft den Studierenden-Status regelmäßig neu.

## Im clawbook

### Erst GitHub, dann wsm

Melden Sie sich im Container **zuerst bei GitHub an**
und starten Sie erst danach den WorkspaceManager
`wsm`. Grund: Beim ersten Start schreibt `wsm` seine
Einstellungen in `~/.workspacemanager.yml` und
übernimmt dabei Ihren GitHub-Namen aus der Anmeldung.
Fehlt die Anmeldung, steht dort ein falscher Name, und
`wsm` kann keine Repositories auf GitHub anlegen.

Damit Sie das nicht vergessen, hilft der Container
nach: Die Anmeldung kommt beim ersten `ssh clawbook`
von selbst (nächster Abschnitt). Und starten Sie `wsm`
zum ersten Mal ohne GitHub-Anmeldung, fragt er zuerst
nach GitHub („1 Jetzt bei GitHub anmelden (empfohlen)"
oder „2 Abbrechen"), bevor er sich einrichtet. Brechen
Sie dort ab, fragt `wsm` noch einmal „Trotzdem mit wsm
fortfahren? [j/N]". Antworten Sie mit Enter (nein) und
melden Sie sich zuerst an; mit `j` trägt `wsm` den
falschen Namen „student" ein.

### Bei GitHub anmelden: beim ersten `ssh clawbook`

Wenn Sie sich mit `ssh clawbook` im Container anmelden
und noch nicht bei GitHub angemeldet sind, erklärt der
Befehl `clawbook` zuerst die Anmeldung und bietet sie
an. Die Meldungen von `clawbook` sprechen Sie mit „du"
an; so stehen sie auch hier in den Zitaten.

```text
GitHub-Anmeldung
----------------
Du bist in clawbook noch nicht bei GitHub angemeldet. ...

  1  Jetzt bei GitHub anmelden (empfohlen)
  2  Abbrechen – weiter zum Menü (beim nächsten Start frage ich wieder)
Deine Wahl [1]:
```

Drücken Sie **Enter** (oder `1`). Die Anmeldung
übernimmt das Werkzeug `gh`; es fragt auf Englisch:

1. **„Upload your SSH public key to your GitHub
   account?"** → wählen Sie mit den Pfeiltasten
   `/home/student/.ssh/id_ed25519.pub` und drücken Sie
   Enter. Das ist der SSH-Schlüssel Ihres Containers;
   GitHub lernt ihn dabei kennen, und `git` arbeitet
   danach über SSH ohne Passwort.
2. **„Title for your SSH key"** → Enter genügt.
3. `gh` zeigt einen Code wie `ABCD-1234` und bittet,
   Enter zu drücken. Drücken Sie Enter. Statt einen
   Browser zu öffnen, zeigt der Container die Adresse:
   „Adresse für den Browser unter Windows:
   https://github.com/login/device".
4. Öffnen Sie <https://github.com/login/device> im
   **Browser unter Windows**, melden Sie sich bei
   GitHub an, geben Sie den Code ein und erlauben Sie
   den Zugriff („Authorize"). Das Terminal wartet,
   bis Sie im Browser fertig sind. Wie das Kopieren im
   Terminal geht, steht in der
   [Übersicht](README.md), „So klappt die Anmeldung im
   Browser".
5. Zurück im Terminal meldet `clawbook`: „Bei GitHub
   angemeldet als <Ihr-Name>." Gleich danach schlägt
   es Name und E-Mail-Adresse für `git` vor (nächster
   Abschnitt). Danach erscheint das clawbook-Menü; mit
   `0` kommen Sie in die normale Eingabezeile.

**Noch kein GitHub-Konto?** Dann legen Sie es jetzt
an, wie oben unter [Konto anlegen](#konto-anlegen)
beschrieben — im Browser unter Windows, etwa fünf
Minuten. Lassen Sie das Terminal mit der Frage so lange
offen und drücken Sie danach Enter. Den
Studierenden-Antrag (Student Developer Pack) brauchen
Sie für die Anmeldung nicht; er kann später folgen.

Wählen Sie `2`, geht es ohne Anmeldung weiter zum
Menü; beim nächsten `ssh clawbook` fragt `clawbook`
wieder. Jederzeit nachholen können Sie die Anmeldung
mit Menüpunkt **7 „GitHub anmelden"** oder mit:

```bash
clawbook github login
```

Der Zugang liegt danach in `~/.config/gh/` — nicht
weitergeben.

**Und jetzt?** Bestätigen Sie die Angaben für `git`
(nächster Abschnitt). Danach können Sie den
WorkspaceManager `wsm` zum ersten Mal starten (siehe
[Installation](../installation.md), Abschnitt 8).

### git: Name und E-Mail-Adresse

Jeder Commit trägt einen Namen und eine
E-Mail-Adresse. Das übernimmt die Anmeldung für Sie:
Direkt nach „Bei GitHub angemeldet als …" zeigt
`clawbook` die Angaben aus Ihrem GitHub-Konto — den
Namen, den Sie dort eingetragen haben (ohne Namen Ihren
GitHub-Benutzernamen), und eine Adresse der Form
`<zahl>+<name>@users.noreply.github.com`:

```text
Git trägt in jeden Commit einen Namen und eine E-Mail-Adresse ein.
Aus Ihrem GitHub-Konto:
  Name:   Erika Beispiel
  E-Mail: 12345678+erika-beispiel@users.noreply.github.com
  (die Noreply-Adresse von GitHub; Ihre echte E-Mail-Adresse bleibt privat)
Diese Angaben für Git übernehmen? [J/n]
```

Drücken Sie **Enter**; `clawbook` trägt beides mit
`git config --global` in `~/.gitconfig` in Ihrem
Home-Verzeichnis ein. Stehen dort schon andere Angaben,
zeigt `clawbook` alte und neue nebeneinander und fragt
„Die Angaben aus GitHub übernehmen? [j/N]" — hier heißt
Enter nein, Ihre Angaben bleiben. Haben Sie die Frage
verpasst, bietet Menüpunkt **7 „GitHub-Anmeldung
prüfen"** sie erneut an, solange Name oder E-Mail
fehlen; jederzeit geht es auch mit:

```bash
clawbook github identitaet
```

**Von Hand** (wenn Sie andere Angaben wollen oder
etwas nicht klappt):

```bash
git config --global user.name "Vorname Nachname"
git config --global user.email "name@example.org"
```

**Achtung bei der E-Mail-Adresse:** Sie steht in
jedem Commit, und in einem öffentlichen Repository
kann sie jeder lesen — auch Jahre später. Deshalb
schlägt `clawbook` die Noreply-Adresse vor; GitHub
zeigt sie Ihnen auch unter Settings → Emails. Tragen
Sie von Hand ebenfalls **diese** als `user.email` ein;
GitHub ordnet Ihnen die Commits trotzdem zu. Setzen
Sie dort auch den Haken „Keep my email addresses
private".

### Kürzer: von Hand mit gh

Wenn Sie `gh` schon kennen, können Sie sich auch
direkt anmelden, zum Beispiel im VS-Code-Terminal:

```bash
gh auth login --hostname github.com --git-protocol ssh --web
```

Die Fragen sind dieselben wie oben: Schlüssel
`/home/student/.ssh/id_ed25519.pub` hochladen, Titel
mit Enter, Code unter <https://github.com/login/device>
eingeben. Am Ende meldet `gh` „Logged in as
<Ihr-Name>". Beim ersten `ssh -T git@github.com` (siehe
„Prüfen") fragt SSH auf diesem Weg einmal, ob es
GitHub vertrauen soll — antworten Sie mit `yes`. Der
Weg über `clawbook` trägt GitHub dagegen schon vorher
als bekannten Rechner ein.

### Neuer SSH-Schlüssel: neu bei GitHub hinterlegen

GitHub kennt den Schlüssel, den Sie bei der Anmeldung
hochgeladen haben. Erzeugen Sie im Container einen
neuen (`clawbook key new` oder Menüpunkt 3, dann `n`),
klappt Git über SSH erst wieder, wenn Sie den neuen
Schlüssel bei GitHub hinterlegen. `clawbook` erinnert
Sie daran und nennt den Befehl:

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --title clawbook
```

Den alten Eintrag löschen Sie unter
<https://github.com/settings/keys>. Meldet `gh`, dass
ihm dafür die Berechtigung fehlt, holen Sie sie zuerst
mit `gh auth refresh -s admin:public_key` (wieder mit
Code im Browser).

### Copilot CLI anmelden

Copilot CLI ist ein Coding-Agent im Terminal: Er liest
und ändert Dateien im Ordner, in dem Sie ihn starten,
und führt dort Befehle aus. Starten Sie ihn deshalb in
einem Projektordner — für den ersten Test im
Beispielprojekt:

```bash
cd ~/source/samples/primer
copilot
```

Beim ersten Start fragt das Programm, ob Sie diesem
Ordner vertrauen („Trust this folder?"). Die Frage
heißt: Darf der Agent hier Dateien lesen und ändern?
Für Ihren eigenen Projektordner: ja. Dann fordert es
Sie auf, `/login` einzugeben. Tippen Sie

```text
/login
```

und folgen Sie der Anzeige: wieder ein Code und die
Adresse `https://github.com/login/device` für den
Browser unter Windows. Voraussetzung ist ein aktiver
Copilot-Plan — bei Ihnen der Studierenden-Plan. Ohne
Plan schlägt die Anmeldung fehl oder der Agent
antwortet nicht. Verlassen mit `/exit`.

Der Zugang liegt danach in `~/.copilot/`.

## Prüfen

Im clawbook-Menü (`clawbook` eingeben) steht oben
„GitHub: angemeldet als <Ihr-Name>". Menüpunkt **7
„GitHub-Anmeldung prüfen"** zeigt mehr: ob Ihr
SSH-Schlüssel bei GitHub hinterlegt ist („SSH-Schlüssel
bei GitHub: hinterlegt") und was `gh` über die
Anmeldung sagt; fehlen Name oder E-Mail für `git`,
bietet er sie an. Dasselbe ohne Menü:

```bash
clawbook github status
```

Ob Git über SSH klappt, prüfen Sie direkt:

```bash
ssh -T git@github.com
```

Die Antwort „Hi <Ihr-Name>! You've successfully
authenticated, but GitHub does not provide shell
access." heißt: alles in Ordnung (das „no shell
access" ist normal).

```bash
git config --global --list
```

zeigt `user.name` und `user.email` (nach der
Anmeldung über `clawbook` die Angaben aus GitHub).

Für Copilot: im Beispielprojekt `copilot` starten und
eine kleine Aufgabe stellen, zum Beispiel „Lege eine
Datei hallo.txt mit einem Gruß an". Fragt der Agent
nach Erlaubnis und legt die Datei an, ist alles
eingerichtet. Das Kontingent sehen Sie in Ihrem
GitHub-Konto unter Settings → Copilot.

## Typische Fehler

- **Der Code erscheint, aber kein Browser öffnet
  sich** → Das ist im Container normal. Öffnen Sie
  <https://github.com/login/device> selbst im Browser
  unter Windows und geben Sie den Code ein.
- **„Die GitHub-Anmeldung hat nicht geklappt. Du
  kannst sie im Menü wiederholen."** → Code zu spät
  eingegeben oder im Browser abgebrochen. Menüpunkt 7
  wählen oder `clawbook github login` eingeben und
  neu beginnen.
- **Nach der Anmeldung: „Hinweis: GitHub kennt den
  SSH-Schlüssel dieses Containers noch nicht."** → Sie
  haben beim Hochladen „Skip" gewählt, oder GitHub hat
  den Schlüssel noch nicht übernommen. Hinterlegen Sie
  ihn mit den beiden Befehlen, die der Hinweis nennt:

  ```bash
  gh auth refresh -s admin:public_key
  gh ssh-key add ~/.ssh/id_ed25519.pub --title clawbook
  ```

- **`git push` oder `git clone` meldet „Permission
  denied (publickey)"** → GitHub kennt Ihren aktuellen
  SSH-Schlüssel nicht, etwa nach `clawbook key new`
  oder nach einem Zurücksetzen. Schlüssel hinterlegen
  wie im Abschnitt „Neuer SSH-Schlüssel".
- **`git push` fragt nach Benutzername und Passwort**
  → Das Repository ist über eine `https://`-Adresse
  eingebunden, und `git` kennt die Anmeldung von `gh`
  nicht. Einmal `gh auth setup-git` ausführen. Im
  Projektordner (`cd ~/source/<Bereich>/<Projekt>`)
  zeigt `git remote -v` die Adresse.
- **`wsm` hat einen falschen GitHub-Namen** (zum
  Beispiel `student`) → `wsm` wurde vor der
  GitHub-Anmeldung eingerichtet. Tragen Sie Ihren
  GitHub-Namen in `~/.workspacemanager.yml` unter
  `locations → git → user` ein (siehe
  [Ohne Account](ohne-account.md), Abschnitt zu `wsm`).
- **Copilot CLI meldet, dass kein Copilot-Zugang
  besteht** → Der Studierenden-Plan ist noch nicht
  freigeschaltet (Antrag in Prüfung), oder Sie sind
  mit einem anderen GitHub-Konto angemeldet. In
  `copilot` mit `/logout` abmelden, dann `/login`
  mit dem richtigen Konto.
- **Der Antrag auf das Student Developer Pack wird
  abgelehnt** → Meist fehlt ein lesbarer Nachweis
  mit aktuellem Datum, oder die Hochschul-E-Mail ist
  nicht im Konto eingetragen. Nachweis ergänzen und
  neu beantragen.
- **Die GitHub-Frage kommt wieder, obwohl Sie schon
  angemeldet waren** → Sie haben ein neues Home
  (Zurücksetzen oder neuer Rechner ohne Sicherung):
  Dann sind alle Zugänge weg und müssen neu
  eingerichtet werden (siehe [Pflege](../pflege.md)).
  Melden Sie sich neu an; der neue SSH-Schlüssel wird
  dabei gleich mit hochgeladen.
- **Zwei-Faktor-Code wird nicht akzeptiert** → Die Uhr
  des Handys geht falsch (Authenticator-Codes hängen
  an der Uhrzeit) — automatische Zeit einschalten.
  Sonst einen Wiederherstellungscode verwenden.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben, dann
`clawbook github status`, `ssh -T git@github.com` und
`git config --global --list` ausführen. Bleibt es beim
Fehler: im Kurs melden mit Befehl und Meldung — ohne
den Anmeldecode und ohne Inhalte aus `~/.config/gh/`.
Fragen zum Studierenden-Antrag beantwortet nur GitHub
Education (<https://education.github.com>); der Kurs
kann die Prüfung nicht beschleunigen.
