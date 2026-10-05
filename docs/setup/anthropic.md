# Anthropic: Claude Code

Stand: 2026-10-05

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> such dir den aktuellen Weg auf der Seite des Anbieters
> selbst.

**Claude Code** (`claude`) ist der Coding-Agent von
Anthropic im Terminal: Er liest dein Projekt, ändert
Dateien, führt Befehle aus und spricht über MCP mit
weiteren Diensten (Stitch, Wiki.js, Playwright). Im
Kurs ist er das Hauptwerkzeug; der WorkspaceManager
`wsm` startet ihn in deinen Projekten.

**Kosten:** Claude Code ist kostenpflichtig. Es braucht
ein Claude-Abo (Pro oder Max) oder ein Konto auf der
Claude-Plattform mit Guthaben; der kostenlose
Claude-Plan enthält Claude Code **nicht**. Preise laut
<https://claude.com/pricing> (Stand 2026-10-05):
Pro 20 US-Dollar im Monat (17 US-Dollar bei
Jahreszahlung), Max ab 100 US-Dollar im Monat.
Einen Rabatt für einzelne Studierende gibt es nach
unserer Recherche nicht; „Claude for Education" ist
ein Vertrag mit der ganzen Hochschule
(<https://claude.com/solutions/education>). Frag im
Kurs, ob deine Hochschule teilnimmt und ob Claude Code
für den Kurs verpflichtend ist — zum Kennenlernen von
Agenten reichen auch die kostenlosen Wege in der
[Übersicht](README.md).

Zwei Wege zum Zugang:

- **Abo:** fester Monatsbetrag, Nutzung bis zu einem
  Kontingent, das sich alle paar Stunden erneuert. Der
  einfachere Weg; die Kosten sind planbar.
- **Guthaben nach Verbrauch (Claude Console):** Du
  lädst Guthaben auf und zahlst pro verarbeitetem Token
  (Textbaustein). Bei intensiver Agenten-Nutzung ist
  das schnell teurer als das Abo, und du musst den
  Verbrauch im Blick behalten. Sinnvoll, wenn du nur
  gelegentlich arbeitest oder denselben Zugang auch
  in anderen Werkzeugen brauchst.

## Beim Anbieter

### Weg 1: Claude-Abo

1. Auf <https://claude.ai> ein Konto anlegen
   (E-Mail oder Google-Konto).
2. Unter <https://claude.com/pricing> den Plan
   **Pro** wählen und das Abo abschließen. Pro reicht
   für Kursarbeit; Max lohnt erst, wenn du täglich
   stundenlang Agenten laufen lässt.
3. **Das Abo verlängert sich monatlich automatisch.**
   Kündigen kannst du jederzeit unter
   <https://claude.ai> → Settings → Billing; trag dir
   das Datum in den Kalender ein, zum Beispiel das
   Semesterende.

### Weg 2: Claude Console

1. Auf <https://platform.claude.com> ein Konto
   anlegen.
2. Unter „Billing" Guthaben aufladen, zum Beispiel
   10 US-Dollar. Dort **automatisches Nachladen
   („auto-reload") ausschalten** und ein
   monatliches Ausgabenlimit setzen — dann ist der
   höchste mögliche Schaden das, was du eingezahlt
   hast.
3. Einen API-Schlüssel brauchst du für Claude Code
   **nicht**: Es meldet sich mit deinem Console-Konto
   im Browser an. Erzeuge einen Schlüssel nur, wenn ein
   anderes Werkzeug ihn braucht (zum Beispiel
   [OpenCode](opencode.md)) — unter „API Keys", mit
   Namen (etwa `opencode`) und, wenn angeboten, mit
   Ablaufdatum; sofort kopieren, er wird nur einmal
   angezeigt.

## Im clawbook

Claude Code arbeitet im Ordner, in dem du es startest:
Es liest dort Dateien, ändert sie und führt Befehle
aus. Starte es deshalb in einem Projektordner — für
den ersten Test im Beispielprojekt:

```bash
cd ~/source/Sample/primer
claude
```

Beim ersten Start fragt Claude Code nach dem
Farbschema und dann nach der Anmeldung:

- **Claude account with subscription** — für Weg 1.
- **Anthropic Console account** — für Weg 2; dann
  „Sign in with your Console account" wählen, nicht
  „Create an API key".

Claude Code versucht, einen Browser zu öffnen. Im
Container geht das nicht; drücke `c`, um die
Anmelde-Adresse in die Zwischenablage zu kopieren,
oder kopiere den angezeigten Link (siehe
[Übersicht](README.md), „So klappt die Anmeldung im
Browser"). Öffne ihn im Browser unter Windows, melde
dich an und erlaube den Zugriff. Der Browser zeigt
dann einen Code; den fügst du im Terminal bei „Paste
code here if prompted" ein. Claude Code meldet „Login
successful".

Danach fragt es, ob du dem Ordner vertraust („Trust
this folder?"). Das heißt: Darf der Agent hier
Dateien lesen und ändern? Für deinen eigenen
Projektordner: ja. Verlassen mit `/exit`.

Der Zugang liegt danach in
`~/.claude/.credentials.json`; Einstellungen und
MCP-Dienste in `~/.claude/` und `~/.claude.json`.
Nichts davon weitergeben.

**Warum nicht `ANTHROPIC_API_KEY`:** Claude Code
prüft beim Start, ob diese Umgebungsvariable gesetzt
ist. Wenn ja, bietet es an, den Schlüssel zu benutzen
— und rechnet dann **pro Token über das Guthaben**
ab, auch wenn du ein Abo hast (Quelle:
<https://code.claude.com/docs/en/authentication>,
Abschnitt „Authentication precedence"). Setze die
Variable deshalb nicht in `~/.bashrc`. Wenn ein
anderes Werkzeug einen Anthropic-Schlüssel braucht,
trage ihn in dessen eigener Konfiguration ein (zum
Beispiel [OpenCode](opencode.md)).

## Prüfen

In einer laufenden Claude-Code-Sitzung:

```text
/status
```

zeigt die Anmeldemethode („Login method"), die
E-Mail-Adresse und den Plan. Bei Weg 1 steht dort dein
Claude-Konto; bei Weg 2 der Console-Zugang. Steht dort
ein API-Schlüssel, obwohl du ein Abo hast, lies den
Abschnitt oben.

Außerhalb der Sitzung:

```bash
claude --version
claude doctor
```

`claude doctor` prüft Installation und Einstellungen,
ohne eine Sitzung zu starten.

## Typische Fehler

- **„Login expired · Please run /login"** → Die
  Anmeldung ist abgelaufen. In der Sitzung `/login`
  eingeben und den Ablauf wiederholen. Claude Code
  warnt drei Tage vorher beim Start.
- **Der Browser unter Windows zeigt nach der Anmeldung
  nur einen Code statt „Login successful"** → Das ist
  im Container der Normalfall: Code kopieren und im
  Terminal einfügen.
- **Claude Code rechnet über Guthaben ab, obwohl du
  ein Abo hast** → Irgendwo ist `ANTHROPIC_API_KEY`
  gesetzt. Prüfen mit `env | grep ANTHROPIC`; den
  Eintrag aus `~/.bashrc` oder `~/.profile`
  entfernen, neu verbinden (`exit`, dann wieder
  `ssh clawbook`) und in Claude Code `/status`
  prüfen.
- **„Claude Code requires a Pro, Max, Team, Enterprise,
  or Console account"** → Du hast dich mit dem
  kostenlosen Claude-Plan angemeldet. Abo abschließen
  oder Weg 2 wählen, dann `/logout` und `/login`.
- **Mit falschem Konto angemeldet** → `/logout` in der
  Sitzung, dann `claude` neu starten; die Anmeldung
  beginnt von vorn.
- **Ein neues Home-Volume, und alles ist weg** → Die
  Zugänge liegen im Home-Verzeichnis. Mit einem neuen
  Volume fängst du bei der Anmeldung von vorn an; wie
  du dein Home vorher sicherst und mitnimmst, steht in
  [Pflege](../pflege.md), Abschnitte 5 und 6.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben, dann `claude doctor` und
in der Sitzung `/status`. Bleibt es beim Fehler: im
Kurs melden mit der Ausgabe von `claude doctor` und
der Fehlermeldung — ohne Anmeldecode und ohne Inhalte
aus `~/.claude/`. Fragen zu Abrechnung und Abo klärt
nur Anthropic (<https://support.claude.com>).
