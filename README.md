# clawbook-lehre

Stand: 2026-10-05

Ein Container-Image eines fertig eingerichteten
Arbeitsrechners für die Arbeit mit KI-Agenten — und eine
Anleitung für Studierende, wie man ihn unter Windows ohne
Administrator-Rechte startet, pflegt und mitnimmt.

Das Projekt ist noch im Aufbau: Befehle, Menüs und
Anleitungen können sich noch ändern; die Anleitungen gelten
zum oben genannten Stand.

## Schnellstart unter Windows

PowerShell öffnen (kein Administrator nötig), diesen Befehl
einfügen (Rechtsklick) und mit Enter ausführen:

```powershell
irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
```

Der Befehl lädt das aktuelle Verwaltungs-Skript und zeigt
ein Menü: beim ersten Mal „neu einrichten", danach
„starten", „aktualisieren", „mitnehmen" und mehr.
Voraussetzung ist WSL ab Version 3.0.1 (`wsl --version`
zeigt sie, `wsl --update` aktualisiert ohne
Administrator-Rechte). Was dann passiert und wie du dich
verbindest, steht in der [Installation](docs/installation.md).

## Anleitungen

- [Wegweiser](docs/README.md) — was clawbook ist, in
  welcher Reihenfolge du die Anleitungen liest, und die
  wichtigsten Begriffe
- [Installation](docs/installation.md) — Voraussetzungen,
  der eine Befehl, verbinden mit Terminal, VS Code und
  Bildschirm
- [Setup](docs/setup/README.md) — Accounts je Anbieter
  anlegen und die Werkzeuge im Container anmelden
- [Pflege](docs/pflege.md) — täglich starten,
  aktualisieren, sichern, auf einen anderen Rechner
  umziehen
- [Eigener Rechner](docs/privat/README.md) — clawbook
  dauerhaft mit Docker oder podman unter Windows, macOS
  oder Linux (nicht vom Kurs getestet)

Bei Problemen hilft der Abschnitt „Wenn etwas nicht geht"
am Ende jeder Seite — und sonst die Betreuung deiner
Lehrveranstaltung.

## Empfehlung: tmux-helper

Agenten laufen im Container gern lange in
tmux-Sitzungen. [tmux-helper](https://github.com/schlingensiepen/tmux-helper)
öffnet diese Sitzungen unter Windows als Tabs im Windows
Terminal und verbindet sie per SSH — auch mit
`clawbook`. Er ist ein eigenes Projekt mit eigenem
Installationsbefehl und gehört nicht zum Image.

## Was entsteht hier?

Ein vorbereiteter Arbeitsrechner als Container: die
üblichen Entwicklungswerkzeuge, mehrere KI-Agenten-Werkzeuge
mit ihren Anbindungen, ein grafischer Zugang per
Remotedesktop und ein Verwaltungs-Skript für Windows, das
Start, Aktualisierung und Sicherung übernimmt. Wer damit
arbeiten will, soll nicht jedes Werkzeug einzeln einrichten
müssen, sondern ein erprobtes Setup auf einmal bekommen.

Das Image wird über GitHub Actions gebaut und unter
`ghcr.io/schlingensiepen/clawbook-lehre` veröffentlicht.

## Für Entwickler

Dieser Teil ist für alle, die am Image oder am Skript
mitarbeiten; Studierende brauchen ihn nicht.

### Aufbau des Repositorys

- `get-clawbook.ps1` — der Einstieg: lädt das
  Verwaltungs-Skript nach `%LOCALAPPDATA%\clawbook` und
  startet es
- `windows/clawbook.ps1` — das Verwaltungs-Skript: Menü
  und Aktionen (starten, aktualisieren, mitnehmen,
  importieren, SSH einrichten, Status, anhalten,
  zurücksetzen) über WSLC
- `deploy/Containerfile` — Bauanleitung des Images
- `deploy/versions.env` — festgelegte Versionen aller
  Werkzeuge; ein wöchentlicher Workflow meldet neuere
- `deploy/rootfs/` — Dateien, die ins Image kopiert
  werden: Start-Schritt (`etc/cont-init.d`), Dienste
  SSH, Bildschirm (Weston-RDP) und Samba
  (`etc/services.d`, gestartet von s6-overlay),
  Prüfskript `clawbook-check`, Voreinstellungen
- `deploy/smoke-test.sh`, `deploy/check-versions.sh` —
  Rauchtest des gebauten Images und Versions-Bericht
- `.github/workflows/` — Bau mit Lint und Rauchtest,
  Veröffentlichung, wöchentlicher Versions-Bericht
- `docs/` — die Anleitungen; der Anhang der
  [Installation](docs/installation.md) beschreibt einen
  Ausweichweg mit podman in einer WSL-Distribution

### Selbst bauen

Mit podman:

```bash
podman build -f deploy/Containerfile \
  $(grep -v '^#' deploy/versions.env | grep . | sed 's/^/--build-arg /') \
  -t clawbook-lehre .
```

## Lizenz

© 2026 Jörn Schlingensiepen

- Quelltext (Container-Definition, Skripte,
  Workflows): [Apache License 2.0](LICENSE)
- Dokumentation: [Creative Commons Namensnennung 4.0
  International (CC BY 4.0)](LICENSE-docs)

Namensnennung bei Weiterverwendung der Dokumentation:
„Jörn Schlingensiepen, clawbook-lehre, CC BY 4.0".
