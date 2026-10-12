# Kurs-Dienste: Wiki.js-MCP und Docling

Stand: 2026-10-12

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> such dir den aktuellen Weg auf der Seite des Anbieters
> selbst.

Zwei Dienste laufen nicht bei einem Anbieter und nicht
in deinem Container, sondern **zentral im Kurs**.
Adresse und Zugang bekommst du von der Kursleitung —
auf dieser Seite stehen nur Platzhalter.

- **Wiki.js** ist das Wiki des Kurses. Über den
  **Wiki.js-MCP** können die Agenten darin suchen,
  Seiten lesen und — wenn Sie es erlauben — Seiten
  anlegen und ändern. Ein MCP-Server ist ein kleines
  Programm, das dem Agenten Werkzeuge anbietet; dieses
  hier ist im Image installiert (`wikijs-mcp-edit`), und
  clawbook trägt es bei allen Agenten ein, sobald
  Adresse und Schlüssel gesetzt sind.
- **Docling** wandelt Dokumente (PDF, Word, Scans) in
  Markdown um. Der WorkspaceManager `wsm` nutzt es bei
  `wsm update`, um die Originale aus `raw/` als Text
  nach `input/` zu bringen. Docling braucht viel
  Rechenleistung; deshalb läuft es als Server im Kurs
  und nicht im Container. Ohne Docling funktioniert
  `wsm` vollständig — nur die Konvertierung fällt aus.

**Kosten:** keine; beides stellt der Kurs.

## Beim Anbieter

Hier ist der „Anbieter" der Kurs. Du bekommst von der
Kursleitung:

- für Wiki.js die **Adresse** (im Folgenden
  `https://wiki.example.org`) und einen
  **API-Schlüssel** — ein langes Token, das der Kurs
  für dich im Wiki erzeugt; es hat ein Ablaufdatum und
  ist **persönlich**: nicht an andere weitergeben,
  nicht in Chats oder Repositories;
- für Docling die **Adresse** des Servers (im
  Folgenden `http://docling.example.org:5001`).

Eventuell sagt die Kursleitung dazu, dass du ein
**VPN** brauchst: eine Verbindung, die deinen Rechner
ins Netz der Hochschule holt, damit Dienste erreichbar
sind, die nicht im offenen Internet stehen. Das VPN
richtest du unter Windows ein (Anleitung der
Hochschule); der Container nutzt dann automatisch
dieselbe Verbindung.

Hast du Adresse und Schlüssel noch nicht, überspringe
diese Seite; alles andere im clawbook funktioniert
ohne.

## Im clawbook

### Wiki.js-MCP für alle Agenten

**Das tun Sie selbst:** Adresse und Schlüssel einmal
im Container eingeben. clawbook fragt jeweils nach dem
Wert; die Eingabe bleibt unsichtbar und landet nicht in
der Befehlshistorie.

```bash
clawbook agenten schluessel WIKIJS_URL       # Wert: https://wiki.example.org
clawbook agenten schluessel WIKIJS_API_KEY   # Wert: Ihr Schlüssel
```

Die Adresse ohne Pfad angeben, also ohne `/graphql` am
Ende. Damit bekommen die Agenten nur Werkzeuge zum
**Lesen** — für den Anfang genau richtig, denn so kann
kein Agent im Wiki versehentlich etwas ändern. Sollen
sie auch Seiten anlegen und ändern dürfen, zusätzlich:

```bash
clawbook agenten schluessel WIKIJS_ENABLE_EDIT   # Wert: true
```

Zurück zu nur lesen: `clawbook agenten schluessel
WIKIJS_ENABLE_EDIT --entfernen`. Alles geht auch im
clawbook-Menü, Punkt 10, dann `k`.

**Das erledigt clawbook:** Sobald `WIKIJS_URL` und
`WIKIJS_API_KEY` gesetzt sind, trägt es den Server
`wikijs` bei Claude Code, Codex, Copilot CLI, OpenCode
und Antigravity ein und meldet je Agent „MCP wikijs
eingetragen“. Die Werte stehen nur in
`~/.clawbook/secrets` (nur für Sie lesbar); die Agenten
bekommen sie in jedem neuen Terminal als
Umgebungsvariablen. Einzelheiten:
[Agenten-Ausstattung](../agenten-ausstattung.md).
Laufende Agenten bitte neu starten.

**Falls die Automatik nicht geht:** den Server von Hand
nur bei Claude Code eintragen. Der Schlüssel wird
vorher unsichtbar abgefragt (Muster in der
[Übersicht](README.md), Regel 2); die Werte landen in
`~/.claude.json`, `-s user` heißt: gilt in allen Ihren
Projekten. Nur lesen:

```bash
read -rs KEY
claude mcp add -s user wikijs \
  -e WIKIJS_URL=https://wiki.example.org \
  -e WIKIJS_API_KEY="$KEY" \
  -- wikijs-mcp-edit
unset KEY
```

Lesen und schreiben: zusätzlich
`-e WIKIJS_ENABLE_EDIT=true` vor `--`. Zum Wechsel
zuerst `claude mcp remove -s user wikijs`. Die Wege für
die anderen Agenten stehen in der
[Agenten-Ausstattung](../agenten-ausstattung.md).

### Docling-Adresse für wsm eintragen

`wsm` liest seine Einstellungen aus
`~/.workspacemanager.yml`. Die Datei entsteht beim
ersten Start von `wsm` automatisch (siehe
[Ohne Account](ohne-account.md)); darin steht
`docling_servers: []` — kein Server. Öffne die Datei
in VS Code (geht aus dem Terminal der
Remote-SSH-Sitzung heraus):

```bash
code ~/.workspacemanager.yml
```

Oder im Terminal mit `nano ~/.workspacemanager.yml`
(speichern Strg+O, Enter; verlassen Strg+X). Die
Zeile `docling_servers: []` ersetzen durch

```yaml
docling_servers:
  - http://docling.example.org:5001
```

Prüfen, ob die Datei noch gültig ist:

```bash
wsm config --validate
```

## Prüfen

Wiki.js:

```bash
clawbook agenten
claude mcp list
```

Der erste Befehl zeigt in der Zeile `wikijs` bei jedem
Agenten `ja` (bei `SCHLÜSSEL` fehlt noch ein Wert), der
zweite `wikijs` mit „Connected". In einer
Claude-Code-Sitzung `/mcp` eingeben: Der Server listet
Werkzeuge wie `search_pages` und `get_page` — und nur
mit `WIKIJS_ENABLE_EDIT=true` auch `create_page` und
`update_page`. Dann den Agenten bitten: „Suche im Wiki
nach …".

Docling:

```bash
wsm config --validate
```

meldet, dass die Konfiguration gültig ist. Lege dann
eine Testdatei (ein kleines PDF, das dir gehört) in
`raw/` eines Projekts und führe `wsm update` aus; in
`input/raw/` erscheint die Markdown-Fassung.

## Typische Fehler

- **`clawbook agenten` zeigt bei `wikijs`
  `SCHLÜSSEL`** → `WIKIJS_URL` oder `WIKIJS_API_KEY`
  fehlt noch (siehe oben).
- **`claude mcp list` zeigt `wikijs` als „Failed to
  connect"** → Adresse oder Schlüssel falsch, das Wiki
  gerade nicht erreichbar, oder das Terminal ist älter
  als der Schlüssel (neues Terminal öffnen, Agent neu
  starten). Adresse im Browser unter Windows öffnen;
  wenn das Wiki da ist, die Werte mit `clawbook agenten
  schluessel WIKIJS_URL` bzw. `WIKIJS_API_KEY` neu
  setzen. Die Adresse ohne Pfad angeben, also ohne
  `/graphql` am Ende.
- **Der Agent kann lesen, aber „create_page" gibt es
  nicht** → Das ist Absicht, solange
  `WIKIJS_ENABLE_EDIT` nicht auf `true` steht.
- **Nach einigen Wochen schlagen Wiki-Zugriffe mit
  „401" oder „unauthorized" fehl** → Der Schlüssel ist
  abgelaufen. Neuen Schlüssel bei der Kursleitung
  holen und mit `clawbook agenten schluessel
  WIKIJS_API_KEY` setzen.
- **`wsm update` meldet „Keine Docling-Server
  konfiguriert … nur .md-Dateien werden kopiert"** →
  `docling_servers` ist noch leer. Adresse eintragen
  (siehe oben).
- **`wsm update` meldet „Docling-Server nicht
  erreichbar"** → Adresse vertippt, Server gerade aus,
  oder du bist nicht im Netz des Kurses. Die Adresse
  im Browser unter Windows prüfen; wenn der Kurs ein
  VPN vorgibt, muss es unter Windows verbunden sein.
- **`wsm config --validate` meldet einen YAML-Fehler**
  → Einrückung prüfen: zwei Leerzeichen vor dem
  Bindestrich, keine Tabulatoren.
- **`code` meldet „command not found"** → Du bist
  per `ssh clawbook` verbunden, nicht im Terminal von
  VS Code. Dort gibt es `code` nicht; nimm `nano`.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben, dann prüfen, ob die
Adresse im Browser unter Windows erreichbar ist — wenn
nicht, liegt es am Netz (VPN) oder am Server, und die
Kursleitung weiß Bescheid. Sonst `clawbook agenten`,
`claude mcp get wikijs` und `wsm config --validate`. Im
Kurs melden mit Befehl und Meldung, ohne den Schlüssel; ein
abgelaufener oder verlorener Schlüssel wird dort
ersetzt.
