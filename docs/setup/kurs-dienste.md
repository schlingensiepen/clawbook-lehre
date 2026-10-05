# Kurs-Dienste: Wiki.js-MCP und Docling

Stand: 2026-10-05

Zwei Dienste laufen nicht bei einem Anbieter und nicht
in deinem Container, sondern **zentral im Kurs**.
Adresse und Zugang bekommst du von der Kursleitung —
auf dieser Seite stehen nur Platzhalter.

- **Wiki.js** ist das Wiki des Kurses. Über den
  **Wiki.js-MCP** kann Claude Code darin suchen, Seiten
  lesen und — wenn du es erlaubst — Seiten anlegen und
  ändern. Ein MCP-Server ist ein kleines Programm, das
  dem Agenten Werkzeuge anbietet; dieses hier ist im
  Image installiert (`wikijs-mcp-edit`) und muss nur
  noch mit Adresse und Schlüssel verbunden werden.
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

### Wiki.js-MCP für Claude Code eintragen

Es gibt zwei Varianten — **führe nur eine aus**. Der
Schlüssel wird vorher unsichtbar abgefragt, damit er
nicht in der Befehlshistorie landet (Muster in der
[Übersicht](README.md), Regel 2). Die Werte landen in
`~/.claude.json` in deinem Home-Verzeichnis, nicht in
`~/.bashrc`; `-s user` heißt: gilt in allen deinen
Projekten.

**Variante A — nur lesen** (für den Anfang):

```bash
read -rs KEY
claude mcp add -s user wikijs \
  -e WIKIJS_URL=https://wiki.example.org \
  -e WIKIJS_API_KEY="$KEY" \
  -- wikijs-mcp-edit
unset KEY
```

**Variante B — lesen und schreiben:** zusätzlich die
Variable `WIKIJS_ENABLE_EDIT=true`. Ohne sie bietet der
Server dem Agenten nur Lese-Werkzeuge an, und der
Agent kann im Wiki nichts versehentlich ändern.

```bash
read -rs KEY
claude mcp add -s user wikijs \
  -e WIKIJS_URL=https://wiki.example.org \
  -e WIKIJS_API_KEY="$KEY" \
  -e WIKIJS_ENABLE_EDIT=true \
  -- wikijs-mcp-edit
unset KEY
```

Zum Wechsel von A nach B (oder zurück) zuerst
`claude mcp remove -s user wikijs`, dann die andere
Variante eintragen.

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
claude mcp list
```

zeigt `wikijs` mit „Connected". In einer
Claude-Code-Sitzung `/mcp` eingeben: Der Server listet
Werkzeuge wie `search_pages` und `get_page` — und nur
bei Variante B auch `create_page` und `update_page`.
Dann den Agenten bitten: „Suche im Wiki nach …".

Docling:

```bash
wsm config --validate
```

meldet, dass die Konfiguration gültig ist. Lege dann
eine Testdatei (ein kleines PDF, das dir gehört) in
`raw/` eines Projekts und führe `wsm update` aus; in
`input/raw/` erscheint die Markdown-Fassung.

## Typische Fehler

- **`claude mcp list` zeigt `wikijs` als „Failed to
  connect"** → Adresse oder Schlüssel falsch, oder das
  Wiki ist gerade nicht erreichbar. Adresse im Browser
  unter Windows öffnen; wenn das Wiki da ist, Eintrag
  mit `claude mcp get wikijs` prüfen, entfernen und neu
  anlegen. Die Adresse ohne Pfad angeben, also ohne
  `/graphql` am Ende.
- **Der Agent kann lesen, aber „create_page" gibt es
  nicht** → Das ist Absicht bei Variante A. Für
  Schreibzugriff auf Variante B wechseln.
- **Nach einigen Wochen schlagen Wiki-Zugriffe mit
  „401" oder „unauthorized" fehl** → Der Schlüssel ist
  abgelaufen. Neuen Schlüssel bei der Kursleitung
  holen, Eintrag entfernen und neu anlegen.
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
Kursleitung weiß Bescheid. Sonst `claude mcp get
wikijs` und `wsm config --validate`. Im Kurs melden
mit Befehl und Meldung, ohne den Schlüssel; ein
abgelaufener oder verlorener Schlüssel wird dort
ersetzt.
