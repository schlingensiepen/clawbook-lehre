# OpenCode mit verschiedenen Anbietern

Stand: 2026-10-05

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> such dir den aktuellen Weg auf der Seite des Anbieters
> selbst.

**OpenCode** (`opencode`) ist ein quelloffener
Coding-Agent im Terminal. Sein Unterschied zu Claude
Code, Codex und Copilot: Er ist an keinen Anbieter
gebunden. Du meldest einen oder mehrere Anbieter an
und wechselst in der Sitzung zwischen deren Modellen.
Das macht ihn zum Werkzeug für Vergleiche: dieselbe
Aufgabe mit verschiedenen Modellen.

**Kosten:** OpenCode selbst ist kostenlos. Du
bezahlst den Anbieter, dessen Modell du benutzt — über
einen der Zugänge, die du auf den anderen Seiten
einrichtest. Der einfachste Einstieg ist
[OpenRouter](openrouter.md): ein Schlüssel, viele
Modelle, einige davon kostenlos.

## Beim Anbieter

Du brauchst keinen eigenen OpenCode-Account, sondern
mindestens einen dieser Zugänge:

| Anbieter in OpenCode | Was du brauchst | Seite |
|---|---|---|
| OpenRouter | API-Schlüssel | [OpenRouter](openrouter.md) |
| OpenAI | ChatGPT Plus oder Pro, oder API-Schlüssel | [OpenAI](openai.md) |
| Anthropic | nur API-Schlüssel aus der Claude Console | [Anthropic](anthropic.md) |
| GitHub Copilot | GitHub-Konto mit Copilot-Plan | [GitHub](github.md) |

Was die Anbieter erlauben (Stand 2026-10-05):

- **OpenAI** erlaubt ausdrücklich, das
  ChatGPT-Kontingent in Partnerprogrammen zu nutzen
  („Sign in with ChatGPT"); OpenCode ist Partner. Das
  gilt nur für Plus und Pro, nicht für den kostenlosen
  Plan, und du kannst in ChatGPT unter Settings →
  Usage je App ein Wochenlimit setzen (Quelle:
  <https://help.openai.com/en/articles/20001542-using-your-chatgpt-plan-in-other-apps-and-sites>).
- **Anthropic verbietet** die Nutzung eines
  Claude-Pro/Max-Abos in Fremdprogrammen; OpenCode hat
  diesen Anmeldeweg entfernt und schreibt in seiner
  Doku: „Anthropic explicitly prohibits this"
  (<https://opencode.ai/docs/providers/>). Für
  Anthropic-Modelle in OpenCode brauchst du also einen
  API-Schlüssel mit Guthaben aus der Claude Console —
  oder du nimmst sie über OpenRouter.
- **GitHub** schließt im kostenlosen Studierenden-Plan
  „Drittanbieter-Agenten" aus
  (<https://docs.github.com/en/copilot/get-started/plans>).
  Ob OpenCode über deinen Copilot-Zugang Modelle
  bekommt, probierst du am besten aus; die Copilot CLI
  selbst funktioniert mit dem Plan auf jeden Fall.

## Im clawbook

### Anbieter anmelden

```bash
opencode auth login
```

OpenCode zeigt eine Liste der Anbieter; mit den
Pfeiltasten auswählen oder den Namen tippen. Schlüssel
gibst du in der Abfrage des Programms ein, nicht im
Befehl — so landen sie nicht in der Historie. Dann je
nach Anbieter:

- **OpenRouter:** Schlüssel einfügen, Enter.
- **OpenAI:** „ChatGPT Plus/Pro" wählen; OpenCode
  zeigt einen Link für die Anmeldung im Browser unter
  Windows (siehe [Übersicht](README.md), „So klappt
  die Anmeldung im Browser"). Oder „API key" wählen
  und den Schlüssel einfügen.
- **Anthropic:** „API key" wählen und den Schlüssel
  aus der Claude Console einfügen. So landet er in
  OpenCodes eigener Datei — und nicht als
  `ANTHROPIC_API_KEY` in deiner Shell, wo er Claude
  Code auf Token-Abrechnung umstellen würde (siehe
  [Anthropic](anthropic.md)).
- **GitHub Copilot:** OpenCode zeigt einen Code und
  die Adresse `https://github.com/login/device`;
  im Browser unter Windows eingeben.

Den Befehl kannst du mehrfach ausführen, für jeden
Anbieter einmal. Alle Zugänge liegen in
`~/.local/share/opencode/auth.json` — nicht
weitergeben.

### Starten und Modell wählen

OpenCode liest und ändert Dateien in dem Ordner, in
dem du es startest, und führt dort Befehle aus.
Deshalb immer in einen Projektordner wechseln:

```bash
cd ~/source/<Thema>/<Projekt>
opencode
```

In der Oberfläche `/models` eingeben und ein Modell
auswählen; die Kennungen haben die Form
`anbieter/modell`, zum Beispiel
`openrouter/<modellname>`. OpenCode merkt sich die
Wahl. Mit `/connect` erreichst du die
Anbieter-Anmeldung auch aus der Sitzung heraus.
Verlassen mit `/exit`.

Gespräche speichert OpenCode lokal in deinem
Home-Verzeichnis; eine feste Konfiguration
(Standardmodell, erlaubte Modelle) kannst du bei Bedarf
in `~/.config/opencode/opencode.json` ablegen — nötig
ist das nicht.

## Prüfen

```bash
opencode auth list
```

listet die angemeldeten Anbieter.

```bash
opencode models openrouter
```

zeigt die Modelle, die über diesen Anbieter verfügbar
sind (ohne Argument: alle Anbieter). Erscheint eine
Liste, ist der Zugang gültig.

## Typische Fehler

- **`opencode` startet, aber bei der ersten Frage kommt
  „no providers configured" oder eine
  Anmeldefehlermeldung** → Kein Anbieter angemeldet
  oder Schlüssel ungültig. `opencode auth list`
  prüfen, mit `opencode auth login` nachholen.
- **Modell aus der Liste antwortet mit `402` oder
  `429`** → Guthaben oder Tageslimit beim Anbieter
  erschöpft; siehe [OpenRouter](openrouter.md). Anderes
  Modell wählen.
- **Du findest keine Anmeldung mit dem Claude-Abo** →
  Gibt es nicht mehr, siehe oben. API-Schlüssel oder
  OpenRouter nehmen; für das Abo ist Claude Code da.
- **Copilot-Modelle fehlen oder lehnen ab** → Der
  Studierenden-Plan erlaubt eventuell keine
  Drittanbieter-Agenten (siehe oben). Nimm für OpenCode
  einen anderen Anbieter; Copilot nutzt du über die
  Copilot CLI.
- **Anbieter entfernen** → `opencode auth logout`
  und den Anbieter wählen.
- **Modellliste veraltet** → `opencode models --refresh`
  lädt die Liste neu.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben, dann `opencode auth list`
und `opencode models`. Meist liegt es nicht an
OpenCode, sondern am Anbieter dahinter — die Lösung
steht dann auf dessen Seite ([OpenRouter](openrouter.md),
[OpenAI](openai.md), [Anthropic](anthropic.md),
[GitHub](github.md)). Im Kurs melden mit Anbieter,
Modellkennung und Meldung — ohne Inhalte aus
`~/.local/share/opencode/auth.json`.
