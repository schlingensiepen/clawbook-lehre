# Werkzeuge im clawbook-Container

Diese Sitzung läuft in clawbook, einem Linux-Container (Debian) für die
Arbeit mit KI-Agenten. Benutzer `student`, Home `/home/student`, Projekte
unter `~/source`. Antworten an die Nutzerin oder den Nutzer auf Deutsch,
sofern nicht anders gewünscht.

- `clawbook`: Verwaltung des Containers. `clawbook check` prüft die
  Werkzeuge, `clawbook pakete katalog` zeigt Kurse und Technikpakete,
  `clawbook agenten status` zeigt MCP-Server, Skills und Schlüssel der
  Agenten.
- `wsm` (WorkspaceManager): legt Projekte unter `~/source` an, startet
  Agenten in tmux; `wsm update` wandelt Dokumente aus `raw/` nach `input/`.
- Playwright: `playwright-cli` steuert Chromium von der Kommandozeile
  (Skill `playwright-cli`, sparsam im Kontext); der MCP-Server `playwright`
  bietet dasselbe als Werkzeuge an. Chromium liegt im Image, ein Fenster
  gibt es nur auf dem Remotedesktop.
- NotebookLM: `notebooklm` (Skill `notebooklm`). Anmeldung macht die
  Nutzerin oder der Nutzer selbst (`notebooklm login`, prüfen mit
  `clawbook notebooklm`).
- graphify: Wissensgraph aus Code und Dokumenten (Skill `graphify`,
  Ausgabe in `graphify-out/`).
- `uv` für Python-Projekte (`uv add`, `uv run`) und Python-Werkzeuge
  (`uv tool install`), Python 3, Node.js mit npm, `gh` (GitHub CLI), git,
  tmux.
- Systemweite Installationen (`apt`, `pip install` ins System,
  `npm install -g`) gehen bei einem neuen Image verloren. Abhängigkeiten
  gehören ins Projekt.
- Weitere Werkzeuge (Java, .NET, Datenbanken, PlatformIO …) kommen als
  Technikpaket: `clawbook pakete add <name> --yes` (nur nach Rückfrage bei
  der Nutzerin oder dem Nutzer). Installierte Technikpakete können eigene
  Hinweise mitbringen; sie stehen gegebenenfalls unter diesem Abschnitt.
