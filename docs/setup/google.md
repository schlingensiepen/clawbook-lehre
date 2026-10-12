# Google: Antigravity, NotebookLM, Stitch

Stand: 2026-10-12

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> suchen Sie den aktuellen Weg bitte selbst auf der
> Seite des Anbieters.

Mit einem Google-Konto nutzen Sie im clawbook drei
Dinge:

- **Antigravity CLI** (`agy`) — Googles Coding-Agent im
  Terminal mit Gemini-Modellen, vergleichbar mit Claude
  Code.
- **NotebookLM** (`notebooklm`) — Googles
  Recherche-Werkzeug: Sie legen Quellen (PDF, Webseiten)
  in ein Notizbuch und stellen Fragen dazu oder lassen
  Zusammenfassungen, Podcasts und Quizze erzeugen. Im
  clawbook steuern Sie es von der Kommandozeile, und
  alle Agenten können es über den Skill `notebooklm`
  nutzen (den richtet clawbook ein, siehe
  [Agenten-Ausstattung](../agenten-ausstattung.md)).
- **Stitch** — Googles Werkzeug für
  Oberflächen-Entwürfe aus Textbeschreibungen. Die
  Agenten sprechen damit über einen **MCP-Server**,
  einen Dienst im Netz, der dem Agenten Werkzeuge
  anbietet. Im Container ist dafür nichts zu
  installieren; clawbook trägt Stitch bei allen Agenten
  ein, sobald Sie den Schlüssel gesetzt haben.

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
wenn Sie ihn nicht kündigen — Datum in den Kalender.
Für den Kurs reichen die kostenlosen Stufen.

Menüpfade unten gelten zum genannten Stand; Google
baut seine Oberflächen oft um.

## Beim Anbieter

**Das tun Sie selbst** — das lässt sich nicht
automatisieren:

1. Ein Google-Konto anlegen oder das bestehende
   nutzen. Überlegen Sie, ob Sie Ihr privates Konto für
   Kursarbeit nehmen wollen oder ein eigenes anlegen —
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
Sie es starten. Deshalb in einen Projektordner
wechseln:

```bash
cd ~/source/<Bereich>/<Projekt>
agy
```

Beim ersten Start wählen Sie die Anmeldung mit dem
Google-Konto. Weil Sie per SSH verbunden sind, erkennt
`agy` das und zeigt einen Link: im Browser unter
Windows öffnen, Google-Konto wählen, Zugriff erlauben
(siehe [Übersicht](README.md), „So klappt die
Anmeldung im Browser"). Der Browser zeigt einen Code,
den Sie ins Terminal einfügen. Danach startet die
Oberfläche; `agy "Frage"` erledigt eine Aufgabe und
beendet sich. Verlassen mit `/exit`, abmelden mit
`/logout`.

### NotebookLM

NotebookLM kennt keine Gerätecodes: Die Anmeldung
läuft über ein echtes Browserfenster, das **im
Container** geöffnet wird. Dafür hat der Container
einen eigenen Bildschirm, den Sie per Remote-Desktop
sehen (siehe [Installation](../installation.md),
Abschnitt 6). Sie arbeiten mit zwei Fenstern:

- **Fenster A** — Ihr Terminal im Container (VS Code
  oder `ssh clawbook`; Eingabeaufforderung
  `student@…`).
- **Fenster B** — die Remotedesktopverbindung, die
  den Bildschirm des Containers zeigt.

**Das erledigt clawbook:** `clawbook notebooklm` (im
clawbook-Menü Punkt **9**) prüft die Anmeldung. Fehlt
sie, fragt es „Jetzt anmelden (Chromium-Fenster auf dem
Remotedesktop)? [J/n]"; direkt geht es mit
`clawbook notebooklm anmelden`. clawbook öffnet dann in
Fenster B ein Chromium-Fenster mit der
Google-Anmeldung, erkennt selbst, wann Sie angemeldet
sind, speichert die Sitzung für das Werkzeug
`notebooklm`, passt sie an die neue Adresse von
NotebookLM an (Skript `notebooklm-fix-cookies`, siehe
unten) und prüft sie mit einer Anfrage an NotebookLM.

**Das tun Sie selbst:**

1. **Unter Windows** (nicht im Container) Fenster B
   öffnen — in PowerShell:

   ```powershell
   mstsc /v:localhost:3390
   ```

   Die Zertifikatswarnung bestätigen (das Zertifikat
   ist selbst ausgestellt, der Bildschirm ist nur von
   Ihrem Rechner aus erreichbar); ein Passwort gibt
   es nicht. Fenster B zeigt einen leeren Bildschirm
   mit einer Leiste oben.

2. In **Fenster A**:

   ```bash
   clawbook notebooklm
   ```

   und die Frage nach der Anmeldung mit Enter
   bestätigen. clawbook sagt: „Ich warte, bis die
   Anmeldung erkannt ist (höchstens 5 Minuten;
   Abbrechen mit Strg+C)."

3. In **Fenster B** erscheint ein Chromium-Fenster
   mit der Google-Anmeldung. Dort anmelden (E-Mail,
   Passwort, Zwei-Faktor-Code). Sie müssen nichts
   weiter tun: Sobald Google die Anmeldung bestätigt,
   meldet Fenster A „Anmeldung erkannt", lädt kurz
   NotebookLM, speichert und schließt das
   Chromium-Fenster.

4. Am Ende steht in Fenster A „NotebookLM: angemeldet
   als …; die Verbindung zu NotebookLM klappt."
   Fenster B können Sie schließen; das trennt nur die
   Anzeige.

Gibt es nach 5 Minuten keine Anmeldung, bricht clawbook
ab und ändert nichts; dasselbe nach Strg+C. Eine schon
gespeicherte Anmeldung sichert clawbook vor dem
Überschreiben (`storage_state.json.alt-<Zeit>` in
`~/.notebooklm/profiles/default/`).

Die Anmeldung läuft nach einiger Zeit ab; dann
`clawbook notebooklm` wiederholen. Ob Sie angemeldet
sind, zeigt jederzeit `clawbook notebooklm`. Auch
`clawbook check` hat eine Zeile „NotebookLM"
(angemeldet, unvollständig oder nicht angemeldet) —
dort ohne Anfrage an NotebookLM, also auch ohne
Internet. Die Daten liegen in `~/.notebooklm/` — nicht
weitergeben.

Warum die Anpassung an die neue Adresse: Google hat
NotebookLM auf `notebook.google.com` umgezogen, das
Kommandozeilen-Werkzeug erwartet die Anmeldedaten aber
noch unter der alten Adresse. Ohne die Anpassung meldet
jeder Befehl „Authentication expired", obwohl die
Anmeldung geklappt hat. Meldet `clawbook notebooklm`
„Die Anmeldung ist unvollständig" und fragt „Jetzt
reparieren? [J/n]", drücken Sie Enter.

**Falls die Automatik nicht geht:** von Hand mit dem
Werkzeug selbst. Bekanntes Problem: `notebooklm login`
hält die Startseite von `notebook.google.com` für
„angemeldet", meldet „Already logged in" und speichert
keine Google-Sitzung. So geht es trotzdem:

1. Fenster B öffnen (siehe oben).
2. In Fenster A Chromium mit dem Browserprofil von
   `notebooklm` auf der Google-Anmeldung öffnen (die
   erste Zeile sucht das Chromium, das `notebooklm`
   benutzt):

   ```bash
   CHROME=$(/opt/uv-tools/notebooklm-py/bin/python -c 'from playwright.sync_api import sync_playwright as s; p = s().start(); print(p.chromium.executable_path); p.stop()')
   DISPLAY=:0 "$CHROME" \
     --user-data-dir="$HOME/.notebooklm/profiles/default/browser_profile" \
     https://accounts.google.com/
   ```

3. In Fenster B anmelden, dann das Chromium-Fenster
   schließen.
4. In Fenster A `notebooklm login` aufrufen; danach
   `notebooklm-fix-cookies` und zur Prüfung
   `clawbook notebooklm`.

### Stitch für alle Agenten

**Das tun Sie selbst:** den Schlüssel aus dem
Abschnitt „Beim Anbieter“ einmal im Container eingeben
(wo, steht in der
[Übersicht](README.md#wo-sie-die-befehle-eingeben)).
Tippen Sie nur diese Zeile, ohne den Schlüssel dahinter:

```bash
clawbook agenten schluessel STITCH_API_KEY
```

clawbook fragt danach „Wert für STITCH_API_KEY (Eingabe
bleibt unsichtbar):“. Schlüssel einfügen (Rechtsklick
bzw. `Strg+Umschalt+V`, siehe
[Übersicht](README.md#so-klappt-die-anmeldung-im-browser);
es erscheint nichts auf dem Bildschirm), Enter. Er
landet in `~/.clawbook/secrets` (nur für Sie lesbar),
nicht in der Befehlshistorie. Setzen und Ändern geht
auch im clawbook-Menü (Punkt 10, dann `k`); entfernen
nur mit `clawbook agenten schluessel STITCH_API_KEY
--entfernen`. Die vollständige Ausgabe zeigt die
[Agenten-Ausstattung](../agenten-ausstattung.md).

**Das erledigt clawbook:** Gleich danach trägt es Stitch
bei Claude Code, Codex, Copilot CLI, OpenCode und
Antigravity ein und meldet je Agent „MCP stitch
eingetragen“. In den Einstellungen steht nur der
Verweis `${STITCH_API_KEY}`; den Wert bekommen die
Agenten in jedem neuen Terminal als Umgebungsvariable.
Nur Antigravity kann keine Verweise auflösen; dort steht
der Schlüssel im Klartext in
`~/.gemini/config/mcp_config.json`, die Datei ist nur
für Sie lesbar. Einzelheiten:
[Agenten-Ausstattung](../agenten-ausstattung.md).

Mehr ist nicht zu tun: Der Dienst läuft bei Google.
Starten Sie den Agenten (neu) und bitten Sie in
natürlicher Sprache um Entwürfe („Entwirf mit Stitch
eine Anmeldeseite für …“); der Agent nutzt die
Stitch-Werkzeuge selbst.

**Falls die Automatik nicht geht:** Stitch von Hand nur
bei Claude Code eintragen. Achtung: Auf diesem Weg steht
der Schlüssel im **Klartext** in `~/.claude.json` —
diese Datei also nie weitergeben (siehe
[Agenten-Ausstattung](../agenten-ausstattung.md),
„Diese Dateien nie weitergeben“). Den Schlüssel fragen
Sie dafür unsichtbar ab (Muster in der
[Übersicht](README.md#drei-regeln-für-schlüssel-und-zugänge),
Regel 2):

```bash
read -rs KEY
claude mcp add -s user --transport http stitch \
  https://stitch.googleapis.com/mcp \
  --header "X-Goog-Api-Key: $KEY"
unset KEY
```

Die Reihenfolge ist wichtig: `--header` steht am Ende.
Davor geschrieben, hält Claude Code auch die Adresse
für einen Header und bricht mit „missing required
argument 'commandOrUrl'" ab. `-s user` heißt: gilt für
alle Ihre Projekte; gespeichert in `~/.claude.json`. Die
Wege für die anderen Agenten stehen in der
[Agenten-Ausstattung](../agenten-ausstattung.md),
„Falls die Automatik nicht geht“.

## Prüfen

Antigravity: `agy` starten; erscheint die Oberfläche
ohne Anmeldeaufforderung, sind Sie angemeldet.

NotebookLM:

```bash
clawbook notebooklm
notebooklm list
```

Der erste Befehl muss „NotebookLM: angemeldet" melden;
der zweite zeigt Ihre Notizbücher (bei einem neuen
Konto eine leere Liste, aber keinen Fehler).

Stitch:

```bash
clawbook agenten
claude mcp list
```

Der erste Befehl zeigt in der Zeile `stitch` bei jedem
Agenten `ja`; steht dort `SCHLÜSSEL`, fehlt der
Schlüssel noch. Der zweite zeigt `stitch` mit
„Connected". In einer Claude-Code-Sitzung zeigt `/mcp`
die Werkzeuge des Servers. „Connected“ allein beweist
nicht, dass der Schlüssel stimmt (Stitch antwortet auf
die Probe auch mit falschem Schlüssel); erst ein
echter Entwurf zeigt es.

## Typische Fehler

- **`notebooklm list` meldet „Authentication expired",
  obwohl Sie sich gerade angemeldet haben** →
  `clawbook notebooklm` aufrufen und die Reparatur
  bestätigen. Meldet der Befehl danach weiter
  „unvollständig oder abgelaufen", melden Sie sich neu
  an; hilft auch das nicht, mit zurückgesetztem
  Browserprofil: `clawbook notebooklm anmelden --neu`.
- **`clawbook notebooklm anmelden` meldet „Kein
  Bildschirm erreichbar"** → Der Bildschirm des
  Containers läuft nicht. `clawbook status` zeigt, ob
  `weston` läuft; sonst den Container neu starten
  ([Pflege](../pflege.md)).
- **`clawbook notebooklm anmelden` meldet „Das
  Browserprofil von NotebookLM ist belegt"** → Ein
  Chromium-Fenster einer früheren Anmeldung ist noch
  offen. clawbook bietet an, es zu schließen (bzw. eine
  veraltete Sperre zu entfernen); mit Enter bestätigen.
- **Kein Chromium-Fenster in Fenster B** → Fenster B
  erst nach dem Start geöffnet? Das Fenster ist trotzdem
  da; sonst Fenster B schließen und neu verbinden.
- **`notebooklm login` sagt „Already logged in", aber
  `clawbook notebooklm` meldet „unvollständig"** → Das
  bekannte Problem von `notebooklm login`. Melden Sie
  sich mit `clawbook notebooklm anmelden` an.
- **Remote-Desktop meldet „Verbindung fehlgeschlagen"**
  → Läuft der Container? Die Adresse ist
  `localhost:3390`, nicht `3389`. Siehe
  [Installation](../installation.md) und
  [Pflege](../pflege.md).
- **Google verweigert die Anmeldung im Chromium des
  Containers („Dieser Browser ist möglicherweise nicht
  sicher")** → Nochmal versuchen; die
  Zwei-Faktor-Anmeldung im Google-Konto erhöht Googles
  Vertrauen in den Login. Hilft das nicht, wenden Sie
  sich an die Betreuung Ihrer Lehrveranstaltung.
- **`agy` zeigt keinen Link, sondern versucht einen
  Browser zu starten** → Per `ssh clawbook` neu
  verbinden; `agy` erkennt die SSH-Sitzung an deren
  Umgebungsvariablen.
- **`clawbook agenten` zeigt bei `stitch`
  `SCHLÜSSEL`** → Der Schlüssel ist noch nicht gesetzt:
  `clawbook agenten schluessel STITCH_API_KEY`.
- **`claude mcp list` warnt „Missing environment
  variables: STITCH_API_KEY"** → Das Terminal ist älter
  als der Schlüssel. Neues Terminal öffnen (oder
  `. /etc/profile.d/clawbook-secrets.sh`) und den Agenten
  neu starten.
- **Stitch-Aufträge scheitern, obwohl `stitch`
  „Connected" zeigt, oder „Failed to connect"** →
  Schlüssel falsch kopiert oder in Stitch gelöscht.
  Neuen Schlüssel erzeugen und mit `clawbook agenten
  schluessel STITCH_API_KEY` neu setzen.
- **Fehler „Incompatible auth server: does not support
  dynamic client registration"** → Claude Code hat den
  Schlüssel-Header ignoriert und versucht eine andere
  Anmeldung. Das ist ein bekanntes Problem von Claude
  Code. Eintrag prüfen (`claude mcp get stitch` muss
  den Header zeigen) und mit `clawbook agenten sync`
  neu anlegen lassen; tritt es weiterhin auf, melden Sie
  es der Betreuung Ihrer Lehrveranstaltung — das Image bekommt dann eine neuere
  Claude-Code-Version.
- **Stitch antwortet mit Kontingent-Fehler** → Das
  monatliche Kontingent ist verbraucht. Bis zum
  Monatswechsel warten oder bei Google nach bezahlten
  Stufen sehen.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben. Bei NotebookLM in dieser
Reihenfolge prüfen: Fenster B zeigt den Bildschirm?
`echo $DISPLAY` gibt `:0`? Was meldet `clawbook
notebooklm`? Bei Stitch `clawbook agenten` und `claude
mcp get stitch`. Im Kurs melden mit Befehl und Meldung —
ohne Schlüssel und ohne Dateien aus `~/.notebooklm/`,
`~/.clawbook/secrets` oder
`~/.gemini/config/mcp_config.json`. Probleme mit dem
Google-Konto selbst (gesperrt, Zwei-Faktor verloren)
kann nur Google lösen.
