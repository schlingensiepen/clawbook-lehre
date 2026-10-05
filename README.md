# clawbook-lehre

Ein Container-Image eines Arbeitsrechners für die
Arbeit mit KI-Agenten — mit einer Anleitung, wie man
es benutzt.

> **Stand:** im Aufbau. Image und Anleitung entstehen
> gerade; dieses Repository ist noch nicht für den
> Einsatz gedacht.

## Schnellstart unter Windows

PowerShell öffnen (kein Administrator nötig), diesen
Befehl einfügen und ausführen:

```powershell
irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
```

Der Befehl lädt das aktuelle Verwaltungs-Skript und
zeigt ein Menü: beim ersten Mal „neu einrichten", danach
„starten", „aktualisieren", „mitnehmen" und mehr.
Voraussetzung ist WSL ab Version 3.0.1 (`wsl --update`).

## Was entsteht hier?

Ein vorbereiteter Arbeitsrechner als Container: die
üblichen Entwicklungswerkzeuge, mehrere
KI-Agenten-Werkzeuge mit ihren Anbindungen, ein
grafischer Zugang per Remote-Desktop und
Dateizugriff aus dem Netz. Wer damit arbeiten will,
soll nicht jedes Werkzeug einzeln einrichten müssen,
sondern ein erprobtes Setup auf einmal bekommen.

Das Image wird über GitHub Actions gebaut und unter
`ghcr.io/schlingensiepen/clawbook-lehre` veröffentlicht.

## Anleitungen

- [Den Arbeitsrechner unter Windows starten](docs/starten-unter-wsl.md)
  — podman in WSL, Container starten, per SSH
  verbinden, Bildschirm per Remote-Desktop, Dateien
  per Windows-Freigabe, eigenen Stand behalten
- [Accounts und Werkzeuge](docs/accounts-und-werkzeuge.md)
  — welche Zugänge du brauchst und wie du jedes
  Werkzeug einrichtest

## Aufbau des Repositorys

- `deploy/Containerfile` — Bauanleitung des Images
- `deploy/versions.env` — festgelegte Versionen aller
  Werkzeuge; ein wöchentlicher Workflow meldet neuere
- `deploy/rootfs/` — Dateien, die ins Image kopiert
  werden: Start-Schritt (`etc/cont-init.d`), Dienste
  SSH, Bildschirm (Weston-RDP) und Samba
  (`etc/services.d`, gestartet von s6-overlay),
  Prüfskript, Voreinstellungen
- `.github/workflows/` — Bau mit Rauchtest und
  Versions-Bericht

Selbst bauen (mit podman):

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
