# GitHub: git, gh und Copilot CLI

Stand: 2026-10-05

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> such dir den aktuellen Weg auf der Seite des Anbieters
> selbst — das gehört zur Übung.

Mit einem GitHub-Konto bekommst du drei Dinge auf
einmal: einen Ort für deine Repositories (`git`), das
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
Settings → Billing). Für den Kurs brauchst du kein
bezahltes Copilot.

## Beim Anbieter

### Konto anlegen

1. Auf <https://github.com> ein Konto anlegen
   („Sign up"). Nimm einen Benutzernamen, den du auch
   in zwei Jahren noch tragen willst — er steht in
   jeder Repository-Adresse.
2. Die E-Mail-Adresse bestätigen.
3. Die **Zwei-Faktor-Anmeldung** einschalten
   (Settings → Password and authentication). Wähle eine
   Authenticator-App auf dem Handy (zum Beispiel die
   von Microsoft, Google oder eine freie wie Aegis) —
   nicht SMS. GitHub zeigt dabei einmalig
   **Wiederherstellungscodes**: speichere sie an einem
   sicheren Ort außerhalb des Handys. Verlierst du
   Handy und Codes, ist das Konto weg.

### Student Developer Pack beantragen

Das **GitHub Student Developer Pack** bündelt
kostenlose Angebote für Studierende, darunter den
Copilot-Plan für Studierende.

1. <https://education.github.com/pack> öffnen,
   „Sign up for Student Developer Pack" wählen.
2. Im Antrag deine Hochschule angeben und einen
   Nachweis hochladen. GitHub akzeptiert laut
   Anleitung zum Beispiel ein Foto des
   Studierendenausweises mit aktuellem Datum, einen
   Stundenplan oder eine Immatrikulationsbescheinigung
   (Quelle:
   <https://docs.github.com/en/education/about-github-education/github-education-for-students/apply-to-github-education-as-a-student>,
   Stand 2026-10-05). Voraussetzung: mindestens
   13 Jahre alt und in einem Studien- oder
   Ausbildungsgang eingeschrieben. Wenn deine Hochschule
   dir eine Hochschul-E-Mail-Adresse gibt, trage sie
   vorher im GitHub-Konto ein — das beschleunigt die
   Prüfung.
3. Warten. Die Prüfung kann einige Tage dauern; du
   bekommst eine E-Mail.
4. Nach der Freischaltung: Settings → Copilot prüfen.
   Dort sollte der Plan „Copilot Student" angeboten
   werden oder schon aktiv sein. Der Plan enthält laut
   GitHub unbegrenzte Code-Vervollständigungen und ein
   monatliches Kontingent an „AI Credits" für Chat und
   Agenten, bei automatischer Modellwahl. GitHub
   prüft den Studierenden-Status regelmäßig neu.

## Im clawbook

### git: deinen Namen eintragen

Jeder Commit trägt Name und E-Mail-Adresse. Trage
beides einmal ein; die Werte landen in
`~/.gitconfig` in deinem Home-Verzeichnis:

```bash
git config --global user.name "Vorname Nachname"
git config --global user.email "du@example.org"
```

**Achtung bei der E-Mail-Adresse:** Sie steht in
jedem Commit, und in einem öffentlichen Repository
kann sie jeder lesen — auch Jahre später. GitHub bietet
dir deshalb unter Settings → Emails eine Adresse der
Form `<zahl>+<name>@users.noreply.github.com` an.
Trage **diese** als `user.email` ein; GitHub ordnet
dir die Commits trotzdem zu. Setze dort auch den Haken
„Keep my email addresses private".

### gh: bei GitHub anmelden

`gh` ist die Kommandozeile für GitHub (Repositories
anlegen, Issues, Pull Requests). Die Anmeldung gibt
auch `git` den Zugang zu deinen Repositories mit, so
dass `git push` ohne weitere Passwörter klappt.

```bash
gh auth login
```

`gh` stellt Fragen; antworte so:

- „Where do you use GitHub?" → **GitHub.com**
- „What is your preferred protocol for Git
  operations?" → **HTTPS**
- „Authenticate Git with your GitHub credentials?" →
  **Yes**
- „How would you like to authenticate?" →
  **Login with a web browser**

Dann zeigt `gh` einen achtstelligen Code und die
Adresse `https://github.com/login/device`. Öffne die
Adresse im Browser unter Windows, gib den Code ein und
erlaube den Zugriff (siehe
[Übersicht](README.md), „So klappt die Anmeldung im
Browser"). Zurück im Terminal meldet `gh`
„Logged in as <dein-name>".

Der Zugang liegt danach in `~/.config/gh/` —
nicht weitergeben.

### Copilot CLI anmelden

Copilot CLI ist ein Coding-Agent im Terminal: Er liest
und ändert Dateien im Ordner, in dem du ihn startest,
und führt dort Befehle aus. Starte ihn deshalb in
einem Projektordner — für den ersten Test in einem
leeren Übungsordner:

```bash
mkdir -p ~/source/uebung && cd ~/source/uebung
copilot
```

Beim ersten Start fragt das Programm, ob du diesem
Ordner vertraust („Trust this folder?"). Die Frage
heißt: Darf der Agent hier Dateien lesen und ändern?
Für deinen eigenen Projektordner: ja. Dann fordert es
dich auf, `/login` einzugeben. Tippe

```text
/login
```

und folge der Anzeige: wieder ein Code und die
Adresse `https://github.com/login/device` für den
Browser unter Windows. Voraussetzung ist ein aktiver
Copilot-Plan — bei dir der Studierenden-Plan. Ohne
Plan schlägt die Anmeldung fehl oder der Agent
antwortet nicht. Verlassen mit `/exit`.

Der Zugang liegt danach in `~/.copilot/`.

## Prüfen

```bash
gh auth status
```

zeigt „Logged in to github.com account <dein-name>"
und „Git operations protocol: https".

```bash
git config --global --list
```

zeigt `user.name` und `user.email`.

Für Copilot: im Übungsordner `copilot` starten und
eine kleine Aufgabe stellen, zum Beispiel „Lege eine
Datei hallo.txt mit einem Gruß an". Fragt der Agent
nach Erlaubnis und legt die Datei an, ist alles
eingerichtet. Das Kontingent siehst du in deinem
GitHub-Konto unter Settings → Copilot.

## Typische Fehler

- **`gh auth login` zeigt den Code, aber der Browser
  öffnet sich nicht** → Das ist im Container normal.
  Öffne `https://github.com/login/device` selbst
  unter Windows und gib den Code ein.
- **`git push` fragt nach Benutzername und Passwort**
  → `gh auth login` wurde nicht mit „Authenticate Git
  with your GitHub credentials? Yes" beantwortet, oder
  das Repository ist per SSH-Adresse eingebunden.
  Einmal `gh auth setup-git` ausführen; dann im
  Projektordner (`cd ~/source/<projekt>`) die
  Remote-Adresse mit `git remote -v` prüfen: sie
  sollte mit `https://github.com/` beginnen.
- **Copilot CLI meldet, dass kein Copilot-Zugang
  besteht** → Der Studierenden-Plan ist noch nicht
  freigeschaltet (Antrag in Prüfung) oder du bist mit
  einem anderen GitHub-Konto angemeldet. In
  `copilot` mit `/logout` abmelden, dann `/login`
  mit dem richtigen Konto.
- **Der Antrag auf das Student Developer Pack wird
  abgelehnt** → Meist fehlt ein lesbarer Nachweis
  mit aktuellem Datum oder die Hochschul-E-Mail ist
  nicht im Konto eingetragen. Nachweis ergänzen und
  neu beantragen.
- **`gh` sagt „To get started with GitHub CLI, please
  run: gh auth login"** → Du bist im Container noch
  nicht angemeldet. Das passiert auch, wenn du ein
  neues Home-Volume angelegt hast: dann sind alle
  Zugänge weg und müssen neu eingerichtet werden
  (siehe [Pflege](../pflege.md)).
- **Zwei-Faktor-Code wird nicht akzeptiert** → Die Uhr
  des Handys geht falsch (Authenticator-Codes hängen
  an der Uhrzeit) — automatische Zeit einschalten.
  Sonst Wiederherstellungscode verwenden.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben, dann `gh auth status`
und `git config --global --list` ausführen. Bleibt es
beim Fehler: im Kurs melden mit Befehl und Meldung —
ohne den achtstelligen Anmeldecode und ohne Inhalte
aus `~/.config/gh/`. Fragen zum Studierenden-Antrag
beantwortet nur GitHub Education
(<https://education.github.com>); der Kurs kann die
Prüfung nicht beschleunigen.
