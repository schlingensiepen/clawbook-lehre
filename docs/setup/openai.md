# OpenAI: Codex

Stand: 2026-10-05

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> such dir den aktuellen Weg auf der Seite des Anbieters
> selbst.

**Codex** (`codex`) ist der Coding-Agent von OpenAI im
Terminal. Er arbeitet wie Claude Code im Ordner, in
dem du ihn startest, mit den Modellen von OpenAI. Im
Kurs ist er die zweite Meinung: ein anderes Modell, das
Code prüft oder eine Aufgabe parallel bearbeitet. Du
brauchst ihn nicht zwingend, aber er ist leicht
eingerichtet und mit dem kostenlosen ChatGPT-Plan
nutzbar.

**Kosten:** Codex läuft über dein **ChatGPT-Konto**.
Laut OpenAI enthalten alle ChatGPT-Pläne ein
Codex-Kontingent, auch der kostenlose Plan in kleinem
Umfang; mehr gibt es mit Go (8 US-Dollar im Monat),
Plus (20 US-Dollar) und Pro (ab 100 US-Dollar)
(Quelle: <https://learn.chatgpt.com/docs/pricing>,
Stand 2026-10-05). Alternativ zahlst du mit einem
API-Schlüssel pro Token. Ein dauerhaftes
Studierenden-Angebot für Deutschland konnten wir zum
Stand nicht belegen; OpenAI hat in der Vergangenheit
zeitlich begrenzte Aktionen für Studierende angeboten
— prüfe <https://openai.com/chatgpt/pricing/> und
frag im Kurs, ob deine Hochschule ChatGPT Edu hat.

## Beim Anbieter

### Weg 1: ChatGPT-Konto

1. Auf <https://chatgpt.com> ein Konto anlegen oder
   das bestehende nutzen.
2. Zum Ausprobieren reicht der kostenlose Plan. Wenn
   das Kontingent nicht reicht, unter „Upgrade" einen
   Plan wählen. **Abos verlängern sich monatlich
   automatisch**; kündigen unter Settings →
   Subscription, Datum in den Kalender.

### Weg 2: API-Schlüssel

1. Auf <https://platform.openai.com> ein Konto
   anlegen, unter „Billing" Guthaben aufladen.
   Automatisches Nachladen („auto recharge")
   ausschalten und unter „Limits" ein monatliches
   Ausgabenlimit setzen.
2. Unter „API keys" einen Schlüssel erzeugen und
   sofort kopieren — er wird nur einmal angezeigt.

Abgerechnet wird dann pro Token zu den API-Preisen,
unabhängig von deinem ChatGPT-Plan.

## Im clawbook

### Weg 1: mit dem ChatGPT-Konto anmelden

Weil im Container kein Browser läuft, nutzt du die
Anmeldung per Gerätecode:

```bash
codex login --device-auth
```

Codex zeigt einen Link und einen Code. Öffne den Link
im Browser unter Windows, melde dich bei ChatGPT an
und gib den Code ein (siehe [Übersicht](README.md),
„So klappt die Anmeldung im Browser"). Codex meldet im
Terminal, dass die Anmeldung geklappt hat. Der Zugang
liegt danach in `~/.codex/auth.json` — behandle die
Datei wie ein Passwort; Codex erneuert die Anmeldung
von selbst.

### Weg 2: mit API-Schlüssel anmelden

Den Schlüssel gibst du nicht im Befehl ein, sondern
unsichtbar über `read -rs` (Muster in der
[Übersicht](README.md), Regel 2):

```bash
read -rs KEY
echo "$KEY" | codex login --with-api-key
unset KEY
```

Nach der ersten Zeile den Schlüssel einfügen und Enter
drücken; es erscheint nichts, das ist richtig. Trage
den Schlüssel **nicht** in `~/.bashrc` ein.

### Starten

Codex liest und ändert Dateien in dem Ordner, in dem
du es startest, und führt dort Befehle aus. Deshalb
immer in einen Projektordner wechseln:

```bash
cd ~/source/<dein-projekt>
codex                              # interaktiv
codex "Beschreibe dieses Projekt"  # eine Aufgabe, dann Ende
```

Beim ersten Start in einem Ordner fragt Codex, ob du
dem Ordner vertraust — für deinen eigenen
Projektordner: ja. Verlassen mit `/exit`.

## Prüfen

```bash
codex login status
```

zeigt, ob und womit du angemeldet bist („Logged in
using ChatGPT" oder „using API key").

```bash
codex doctor
```

prüft Anmeldung, Netzwerk und Sandbox in einem
Durchgang.

## Typische Fehler

- **`codex login` ohne `--device-auth` bleibt hängen
  oder meldet, dass der Browser nicht geöffnet werden
  kann** → Im Container gibt es keinen Browser. Immer
  `codex login --device-auth` verwenden.
- **„Usage limit reached"** oder ähnliche Meldung →
  Das Kontingent deines ChatGPT-Plans ist für diesen
  Zeitraum verbraucht. Warten, bis es sich erneuert,
  oder den Plan erhöhen. Mit API-Schlüssel gibt es
  kein Kontingent, aber jede Anfrage kostet.
- **Codex nutzt den API-Schlüssel, obwohl du dich mit
  ChatGPT angemeldet hast** → Eine Umgebungsvariable
  `OPENAI_API_KEY` ist gesetzt. Prüfen mit
  `env | grep OPENAI`, Eintrag aus `~/.bashrc`
  entfernen, neu verbinden.
- **Anmeldung verloren nach neuem Home-Volume** →
  `~/.codex/` liegt im Home-Verzeichnis. Mit neuem
  Volume einfach `codex login --device-auth`
  wiederholen.
- **Konto wechseln** → `codex logout`, dann neu
  anmelden.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben, dann `codex doctor`.
Bleibt es beim Fehler: im Kurs melden mit der Ausgabe
von `codex doctor` und der Fehlermeldung — ohne
Gerätecode und ohne `~/.codex/auth.json`. Fragen zu
Kontingent und Abo klärt nur OpenAI
(<https://help.openai.com>).
