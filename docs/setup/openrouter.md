# OpenRouter: ein Schlüssel für viele Modelle

Stand: 2026-10-05

> Die Anbieter ändern ihre Seiten, Menüs und Angebote
> laufend. Sieht etwas anders aus als hier beschrieben,
> such dir den aktuellen Weg auf der Seite des Anbieters
> selbst — das gehört zur Übung.

**OpenRouter** ist ein Vermittler: Mit einem einzigen
Konto und einem einzigen API-Schlüssel erreichst du
Modelle vieler Anbieter (OpenAI, Anthropic, Google,
Meta, Mistral und andere). Du brauchst ihn im Kurs vor
allem für [OpenCode](opencode.md), das damit zwischen
Modellen wechseln kann, ohne dass du bei jedem
Anbieter ein Konto hast. Jedes Werkzeug, das einen
„OpenAI-kompatiblen" Zugang annimmt, kann OpenRouter
nutzen.

**Kosten:** Abrechnung nach Verbrauch über ein
**Guthaben**, das du vorher auflädst; OpenRouter gibt
die Preise der Anbieter pro Million Token weiter und
berechnet beim Aufladen eine Gebühr (laut
<https://openrouter.ai/docs/faq>: 5,5 %, mindestens
0,80 US-Dollar, Stand 2026-10-05). Einige Modelle sind
**kostenlos** (Kennung endet auf `:free`), mit
Tageslimit: 50 Anfragen am Tag, solange du weniger als
10 US-Dollar Guthaben gekauft hast, danach 1.000
Anfragen am Tag (Quelle:
<https://openrouter.ai/docs/api-reference/limits>,
Stand 2026-10-05). Ein Studierenden-Angebot gibt es
nicht. Du kannst ohne Einzahlung mit den kostenlosen
Modellen anfangen; ob und wie viel du einzahlst,
entscheidest du nach deinem Bedarf — ein einmaliger
Kauf von 10 US-Dollar hebt das Tageslimit der
kostenlosen Modelle an.

## Beim Anbieter

1. Auf <https://openrouter.ai> ein Konto anlegen
   (Google-, GitHub-Konto oder E-Mail).
2. Optional unter „Credits" Guthaben aufladen. Dort
   **automatisches Nachladen („auto top-up")
   ausschalten**, damit nie mehr abgebucht wird, als du
   bewusst eingezahlt hast.
3. Unter „Keys" (<https://openrouter.ai/keys>) einen
   Schlüssel erzeugen: Namen vergeben (zum Beispiel
   `clawbook`) und ein **Ausgabenlimit** setzen —
   OpenRouter empfiehlt das für jeden Schlüssel, damit
   ein verlorener Schlüssel nicht dein ganzes Guthaben
   aufbrauchen kann. Den Schlüssel sofort kopieren.
4. Unter „Settings → Privacy" festlegen, ob Anbieter
   deine Eingaben zu Trainingszwecken verwenden dürfen;
   manche Modelle (vor allem kostenlose) stehen nur zur
   Verfügung, wenn du das erlaubst. Für Kursprojekte
   mit fremden Daten: nicht erlauben.

## Im clawbook

OpenRouter selbst hat kein Programm im Container. Du
trägst den Schlüssel in das Werkzeug ein, das ihn
nutzen soll — für OpenCode so:

```bash
opencode auth login
```

Als Anbieter **OpenRouter** auswählen und den
Schlüssel einfügen (die Eingabe ist hier eine
Abfrage des Programms, nicht Teil des Befehls — sie
landet nicht in der Historie). OpenCode speichert ihn
in `~/.local/share/opencode/auth.json`. Danach in
OpenCode mit `/models` ein Modell wählen; die
Kennungen beginnen mit `openrouter/`. Einzelheiten
unter [OpenCode](opencode.md).

Für andere Werkzeuge gilt dasselbe Muster: Schlüssel
in die Konfiguration des Werkzeugs, Basisadresse
`https://openrouter.ai/api/v1`. **Nicht** in
`~/.bashrc` eintragen.

## Prüfen

Der direkte Test ohne Werkzeug. Der Schlüssel wird
unsichtbar abgefragt (Muster in der
[Übersicht](README.md), Regel 2); `jq` formatiert die
Antwort lesbar:

```bash
read -rs KEY
curl -s https://openrouter.ai/api/v1/auth/key \
  -H "Authorization: Bearer $KEY" | jq .
unset KEY
```

Die Antwort zeigt Namen, Limit und bisherigen
Verbrauch des Schlüssels. Steht dort `"error"`, ist
der Schlüssel falsch oder widerrufen.

Verbrauch und Guthaben siehst du jederzeit auf
<https://openrouter.ai/activity>.

## Typische Fehler

- **Fehler `401` oder „No auth credentials found"** →
  Der Schlüssel ist falsch kopiert (Leerzeichen,
  fehlendes `sk-or-`) oder gelöscht. Auf der
  Keys-Seite prüfen, notfalls neu erzeugen und im
  Werkzeug ersetzen.
- **Fehler `402`** → Guthaben verbraucht oder
  negativ; dann scheitern auch kostenlose Modelle.
  Unter „Credits" aufladen.
- **Fehler `429` bei einem `:free`-Modell** → Das
  Tageslimit ist erreicht. Bis zum nächsten Tag warten,
  ein bezahltes Modell nehmen oder einmalig
  10 US-Dollar Guthaben kaufen für das höhere Limit.
- **Ein Modell antwortet „not available" oder fehlt in
  der Liste** → Entweder wegen deiner
  Privacy-Einstellung ausgeschlossen (siehe oben)
  oder der Anbieter hat es zurückgezogen. Anderes
  Modell wählen.
- **Schlüssel versehentlich veröffentlicht** (zum
  Beispiel in einem Commit) → Sofort auf der
  Keys-Seite löschen und einen neuen erzeugen. Das
  Ausgabenlimit begrenzt den Schaden, verhindert ihn
  aber nicht.

## Wenn etwas nicht geht

Erst „Typische Fehler" oben, dann den Schlüssel mit
dem Test unter „Prüfen" abfragen und auf
<https://openrouter.ai/activity> nachsehen, ob
Anfragen ankommen. Bleibt es beim Fehler: im Kurs
melden mit Modellkennung und Fehlercode — nie mit dem
Schlüssel; einen Schlüssel, den du irgendwo eingefügt
hast, danach auf der Keys-Seite löschen.
