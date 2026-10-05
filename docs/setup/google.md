# Google: Antigravity, NotebookLM, Stitch

Stand: 2026-10-05

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> such dir den aktuellen Weg auf der Seite des Anbieters
> selbst.

Mit einem Google-Konto nutzt du im clawbook drei
Dinge:

- **Antigravity CLI** (`agy`) — Googles Coding-Agent im
  Terminal mit Gemini-Modellen, vergleichbar mit Claude
  Code.
- **NotebookLM** (`notebooklm`) — Googles
  Recherche-Werkzeug: Du legst Quellen (PDF, Webseiten)
  in ein Notizbuch und stellst Fragen dazu oder lässt
  Zusammenfassungen, Podcasts und Quizze erzeugen. Im
  clawbook steuerst du es von der Kommandozeile, und
  Claude Code kann es über den Skill `/notebooklm`
  nutzen.
- **Stitch** — Googles Werkzeug für
  Oberflächen-Entwürfe aus Textbeschreibungen. Claude
  Code spricht damit über einen **MCP-Server**, einen
  Dienst im Netz, der dem Agenten Werkzeuge anbietet.
  Im Container ist dafür nichts zu installieren.

**Kosten (Stand 2026-10-05):** Alle drei haben eine
kostenlose Stufe mit einem Google-Konto. Antigravity:
kostenloser Plan mit wöchentlichen Limits, mehr mit
Google AI Pro oder Ultra
(<https://antigravity.google/pricing>). NotebookLM:
kostenlos mit 100 Notizbüchern und 50 Quellen je
Notizbuch, mehr über die Google-AI-Pläne
(<https://support.google.com/notebooklm/answer/16213268>).
Stitch: kostenlos mit einem monatlichen Kontingent an
Entwürfen; Google kündigt bezahlte Stufen an. Für
Studierende ab 18 Jahren bietet Google ein Jahr
**Google AI Plus** kostenlos an, mit Nachweis des
Studierendenstatus, gültig bis 31.12.2026
(<https://gemini.google/students/>); der Plan erhöht
laut Google-Hilfe unter anderem die NotebookLM-Limits.
Nach dem Gratisjahr wird der Plan kostenpflichtig,
wenn du ihn nicht kündigst — Datum in den Kalender.
Für den Kurs reichen die kostenlosen Stufen.

Menüpfade unten gelten zum genannten Stand; Google
baut seine Oberflächen oft um.

## Beim Anbieter

1. Ein Google-Konto anlegen oder das bestehende
   nutzen. Überlege, ob du dein privates Konto für
   Kursarbeit nehmen willst oder ein eigenes anlegst —
   NotebookLM-Notizbücher und Stitch-Projekte hängen am
   Konto. Zwei-Faktor-Anmeldung einschalten
   (Google-Konto → Sicherheit).
2. Optional das Studierenden-Angebot prüfen:
   <https://gemini.google/students/>, dort den
   Nachweis hochladen.
3. Für **Stitch** einen API-Schlüssel erzeugen:
   <https://stitch.withgoogle.com> öffnen, mit dem
   Google-Konto anmelden, oben rechts das Profilbild →
   **Settings**, Abschnitt **API Keys** → **Create API
   Key**. Den Schlüssel sofort kopieren und wie ein
   Passwort behandeln. Ein Google-Cloud-Projekt ist
   dafür nicht nötig.

Antigravity und NotebookLM brauchen keine Vorbereitung
beim Anbieter; die Anmeldung passiert im clawbook.

## Im clawbook

### Antigravity CLI

`agy` liest und ändert Dateien in dem Ordner, in dem
du es startest. Deshalb in einen Projektordner
wechseln:

```bash
cd ~/source/<Thema>/<Projekt>
agy
```

Beim ersten Start wählst du die Anmeldung mit dem
Google-Konto. Weil du per SSH verbunden bist, erkennt
`agy` das und zeigt einen Link: im Browser unter
Windows öffnen, Google-Konto wählen, Zugriff erlauben
(siehe [Übersicht](README.md), „So klappt die
Anmeldung im Browser"). Der Browser zeigt einen Code,
den du ins Terminal einfügst. Danach startet die
Oberfläche; `agy "Frage"` erledigt eine Aufgabe und
beendet sich. Verlassen mit `/exit`, abmelden mit
`/logout`.

### NotebookLM

NotebookLM kennt keine Gerätecodes: Die Anmeldung
läuft über ein echtes Browserfenster, das **im
Container** geöffnet wird. Dafür hat der Container
einen eigenen Bildschirm, den du per Remote-Desktop
siehst (siehe [Installation](../installation.md),
Abschnitt 6). Du arbeitest mit zwei Fenstern:

- **Fenster A** — dein Terminal im Container (VS Code
  oder `ssh clawbook`; Eingabeaufforderung
  `student@…`).
- **Fenster B** — die Remotedesktopverbindung, die
  den Bildschirm des Containers zeigt.

1. **Unter Windows** (nicht im Container) Fenster B
   öffnen — in PowerShell:

   ```powershell
   mstsc /v:localhost:3390
   ```

   Die Zertifikatswarnung bestätigen (das Zertifikat
   ist selbst ausgestellt, der Bildschirm ist nur von
   deinem Rechner aus erreichbar); ein Passwort gibt
   es nicht. Fenster B zeigt einen leeren Bildschirm
   mit einer Leiste oben.

2. In **Fenster A** die Anmeldung starten:

   ```bash
   notebooklm login
   ```

3. In **Fenster B** öffnet sich ein Chromium-Fenster
   mit der Google-Anmeldung. Dort anmelden (E-Mail,
   Passwort, Zwei-Faktor-Code), bis NotebookLM
   geladen ist.

4. Zurück in **Fenster A**: den Hinweisen des
   Programms folgen — es speichert die Anmeldung und
   beendet sich.

5. In **Fenster A, immer danach:**

   ```bash
   notebooklm-fix-cookies
   ```

   Warum: Google hat NotebookLM auf eine neue Adresse
   umgezogen (`notebook.google.com`), das
   Kommandozeilen-Werkzeug erwartet die Anmeldedaten
   aber noch unter der alten. Das Skript kopiert sie
   um. Ohne diesen Schritt meldet jeder Befehl
   „Authentication expired", obwohl die Anmeldung
   geklappt hat.

6. Fenster B kannst du schließen; das trennt nur die
   Anzeige.

Die Anmeldung läuft nach einiger Zeit ab; dann die
Schritte 1 bis 5 wiederholen. Die Daten liegen in
`~/.notebooklm/` — nicht weitergeben.

### Stitch als MCP-Server für Claude Code

Den Schlüssel aus dem Abschnitt „Beim Anbieter" trägst
du einmal in Claude Code ein. Damit er nicht in der
Befehlshistorie landet, fragst du ihn erst unsichtbar
ab (Muster in der [Übersicht](README.md), Regel 2):

```bash
read -rs KEY
claude mcp add -s user stitch --transport http \
  --header "X-Goog-Api-Key: $KEY" \
  https://stitch.googleapis.com/mcp
unset KEY
```

`-s user` heißt: gilt für alle deine Projekte;
gespeichert in `~/.claude.json`. Mehr ist nicht zu tun:
Der Dienst läuft bei Google. In Claude Code bittest du
danach in natürlicher Sprache um Entwürfe („Entwirf
mit Stitch eine Anmeldeseite für …"); der Agent nutzt
die Stitch-Werkzeuge selbst.

## Prüfen

Antigravity: `agy` starten; erscheint die Oberfläche
ohne Anmeldeaufforderung, bist du angemeldet.

NotebookLM:

```bash
notebooklm list
```

zeigt deine Notizbücher (bei einem neuen Konto eine
leere Liste, aber keinen Fehler).

Stitch:

```bash
claude mcp list
```

zeigt `stitch` mit „Connected". In einer
Claude-Code-Sitzung zeigt `/mcp` die Werkzeuge des
Servers.

## Typische Fehler

- **`notebooklm list` meldet „Authentication expired",
  obwohl du dich gerade angemeldet hast** →
  `notebooklm-fix-cookies` vergessen. Nachholen.
- **`notebooklm login` öffnet kein Fenster in
  Fenster B** → Normalerweise weiß das Terminal über
  die Variable `DISPLAY=:0`, wo der Bildschirm ist.
  Prüfe mit `echo $DISPLAY`; ist die Ausgabe leer,
  rufe `DISPLAY=:0 notebooklm login` auf oder nutze
  das Terminal-Symbol in der Leiste von Fenster B.
- **Remote-Desktop meldet „Verbindung fehlgeschlagen"**
  → Läuft der Container? Die Adresse ist
  `localhost:3390`, nicht `3389`. Siehe
  [Installation](../installation.md) und
  [Pflege](../pflege.md).
- **Google verweigert die Anmeldung im Chromium des
  Containers („Dieser Browser ist möglicherweise nicht
  sicher")** → Nochmal versuchen; die
  Zwei-Faktor-Anmeldung im Google-Konto erhöht Googles
  Vertrauen in den Login. Hilft das nicht, frag im
  Kurs.
- **`agy` zeigt keinen Link, sondern versucht einen
  Browser zu starten** → Per `ssh clawbook` neu
  verbinden; `agy` erkennt die SSH-Sitzung an deren
  Umgebungsvariablen.
- **`claude mcp list` zeigt `stitch` als „Failed to
  connect"** → Schlüssel falsch kopiert oder in Stitch
  gelöscht. Mit `claude mcp remove -s user stitch`
  entfernen und neu eintragen; Anführungszeichen um
  den Header beachten.
- **Fehler „Incompatible auth server: does not support
  dynamic client registration"** → Claude Code hat den
  Schlüssel-Header ignoriert und versucht eine andere
  Anmeldung. Das ist ein bekanntes Problem von Claude
  Code. Eintrag prüfen (`claude mcp get stitch` muss
  den Header zeigen) und neu anlegen; tritt es
  weiterhin auf, melde es im Kurs — das Image bekommt
  dann eine neuere Claude-Code-Version.
- **Stitch antwortet mit Kontingent-Fehler** → Das
  monatliche Kontingent ist verbraucht. Bis zum
  Monatswechsel warten oder bei Google nach bezahlten
  Stufen sehen.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben. Bei NotebookLM in dieser
Reihenfolge prüfen: Fenster B zeigt den Bildschirm?
`echo $DISPLAY` gibt `:0`? `notebooklm-fix-cookies`
gelaufen? Bei Stitch `claude mcp get stitch`. Im Kurs
melden mit Befehl und Meldung — ohne Schlüssel und
ohne Dateien aus `~/.notebooklm/`. Probleme mit dem
Google-Konto selbst (gesperrt, Zwei-Faktor verloren)
kann nur Google lösen.
