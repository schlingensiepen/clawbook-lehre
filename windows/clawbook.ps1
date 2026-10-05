<#
.SYNOPSIS
  clawbook-lehre - Arbeitsrechner fuer die Arbeit mit KI-Agenten unter Windows.

.DESCRIPTION
  Verwaltet den clawbook-Container ueber WSLC (WSL-Container), ohne
  Administrator-Rechte:
    - Image holen, Container und Home-Volume anlegen und starten
    - SSH-Schluessel nach Windows holen und SSH fuer VS Code einrichten
    - das Home sichern (mitnehmen), importieren, zuruecksetzen

  Normalerweise startet man es ueber den Befehl von der Startseite des
  Repositorys; ohne Parameter erscheint ein Menue.

.PARAMETER Action
  start, update, export, import, ssh, status, stop, reset - ohne Angabe: Menue.

.PARAMETER Image
  Image, Vorgabe ghcr.io/schlingensiepen/clawbook-lehre:latest

.PARAMETER File
  Sicherungsdatei fuer -Action import bzw. Zieldatei fuer -Action export.
#>
[CmdletBinding()]
param(
  [ValidateSet('', 'start', 'update', 'export', 'import', 'ssh', 'status', 'stop', 'reset')]
  [string]$Action = '',
  [string]$Image = 'ghcr.io/schlingensiepen/clawbook-lehre:latest',
  [string]$File = ''
)

$ErrorActionPreference = 'Stop'

# --- Settings -------------------------------------------------------------
$Container = 'clawbook'
$Volume = 'clawbook-home'
$VolumeBytes = '100000000000'
$SshPort = 2222
$RdpPort = 3390
$HelperImage = 'debian:trixie-slim'
$MinWslc = [version]'3.0.1'

$AppDir = Join-Path $env:LOCALAPPDATA 'clawbook'
$LogDir = Join-Path $AppDir 'logs'
$UserDir = Join-Path $env:USERPROFILE 'clawbook'
$ExchangeDir = Join-Path $UserDir 'austausch'
$BackupDir = Join-Path $UserDir 'sicherungen'
$SshDir = Join-Path $env:USERPROFILE '.ssh'
$KeyFile = Join-Path $SshDir 'clawbook'
$SshConfig = Join-Path $SshDir 'config'
$KnownHosts = Join-Path $SshDir 'known_hosts_clawbook'
$MarkBegin = '# >>> clawbook (verwaltet von clawbook.ps1 - nicht von Hand aendern)'
$MarkEnd = '# <<< clawbook'

foreach ($d in @($AppDir, $LogDir, $UserDir, $ExchangeDir, $BackupDir, $SshDir)) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
}
$LogFile = Join-Path $LogDir ("clawbook-{0}.log" -f (Get-Date -Format 'yyyyMMdd'))

# --- Helpers -------------------------------------------------------------
function Log($Text) {
  Add-Content -Path $LogFile -Value ("{0} {1}" -f (Get-Date -Format 'HH:mm:ss'), $Text)
}
function Say($Text, $Color = 'Gray') { Write-Host $Text -ForegroundColor $Color; Log $Text }
function Fail($Text) { Say "FEHLER: $Text" 'Red'; Say "Protokoll: $LogFile" 'Red'; exit 1 }

function Invoke-Wslc {
  # Runs wslc; returns @{ Code; Out }. Never throws on native stderr.
  $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  $out = & wslc @args 2>&1 | ForEach-Object { "$_" } | Out-String
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  Log ("wslc {0} -> {1}`n{2}" -f ($args -join ' '), $code, $out.Trim())
  return @{ Code = $code; Out = $out.Trim() }
}

function Test-Wslc {
  if (-not (Get-Command wslc -ErrorAction SilentlyContinue)) {
    Say 'WSLC (WSL-Container) ist auf diesem Rechner nicht vorhanden.' 'Yellow'
    Say 'WSL installieren bzw. aktualisieren:  wsl --install   oder   wsl --update' 'Yellow'
    Say 'Danach diesen Befehl erneut ausfuehren.' 'Yellow'
    exit 1
  }
  $v = (Invoke-Wslc version).Out
  $ver = if ($v -match '(\d+\.\d+\.\d+)') { [version]$Matches[1] } else { [version]'0.0.0' }
  if ($ver -lt $MinWslc) {
    Say "WSLC-Version $ver ist zu alt (mindestens $MinWslc)." 'Yellow'
    $a = Read-Host 'Jetzt mit "wsl --update" aktualisieren? [J/n]'
    if ($a -notmatch '^[nN]') {
      & wsl --update
      Say 'Bitte den Befehl danach erneut ausfuehren.' 'Yellow'
    }
    exit 1
  }
}

function Get-State {
  $vol = (Invoke-Wslc volume inspect $Volume).Code -eq 0
  $c = Invoke-Wslc inspect $Container
  $exists = $c.Code -eq 0 -and $c.Out -match '"Id"'
  $running = $exists -and ($c.Out -match '"Running"\s*:\s*true')
  return @{ Volume = $vol; Exists = $exists; Running = $running }
}

function Test-Port($Port) {
  try { $t = New-Object Net.Sockets.TcpClient; $t.Connect('127.0.0.1', $Port); $t.Close(); return $true }
  catch { return $false }
}

function Wait-Ssh {
  Say 'Warte auf den Container (beim ersten Start bis zu drei Minuten) ...'
  $deadline = (Get-Date).AddMinutes(3)
  while ((Get-Date) -lt $deadline) {
    if (Test-Port $SshPort) {
      # sshd answers; give the init step a moment to finish writing the key.
      for ($i = 0; $i -lt 30; $i++) {
        if ((Invoke-Wslc exec $Container test -s /home/student/.ssh/id_ed25519).Code -eq 0) { return }
        Start-Sleep -Seconds 2
      }
      return
    }
    Start-Sleep -Seconds 3
  }
  $logs = (Invoke-Wslc logs $Container).Out -split "`n" |
    Where-Object { $_ -notmatch '^[A-Za-z0-9+/=]{30,}$' -and $_ -notmatch 'PRIVATE KEY' } |
    Select-Object -Last 20
  Fail ("Der Container antwortet nicht auf Port $SshPort.`n" + ($logs -join "`n"))
}

function Ensure-Image {
  if ((Invoke-Wslc image inspect $Image).Code -ne 0) {
    Say "Lade das Image $Image (einige GB, einmalig) ..." 'Cyan'
    $r = Invoke-Wslc pull $Image
    if ($r.Code -ne 0) { Fail "Image konnte nicht geladen werden:`n$($r.Out)" }
  }
}

function Ensure-Volume {
  if ((Invoke-Wslc volume inspect $Volume).Code -ne 0) {
    Say "Lege das Home-Volume $Volume an ..."
    $r = Invoke-Wslc volume create --driver vhd -o "SizeBytes=$VolumeBytes" $Volume
    if ($r.Code -ne 0) { Fail "Volume konnte nicht angelegt werden:`n$($r.Out)" }
  }
}

function New-Container {
  Ensure-Image
  Ensure-Volume
  $r = Invoke-Wslc run -d --name $Container `
    -p "127.0.0.1:${SshPort}:22" -p "127.0.0.1:${RdpPort}:3389" `
    -v "${Volume}:/home/student" -v "${ExchangeDir}:/home/student/austausch" `
    -e "CLAWBOOK_SSH_PORT=$SshPort" -e "CLAWBOOK_RDP_PORT=$RdpPort" `
    $Image
  if ($r.Code -ne 0) { Fail "Container konnte nicht gestartet werden:`n$($r.Out)" }
}

function Start-Clawbook {
  $s = Get-State
  if ($s.Running) { Say 'Der Container laeuft bereits.' }
  elseif ($s.Exists) {
    Say 'Starte den Container ...'
    $r = Invoke-Wslc start $Container
    if ($r.Code -ne 0) { Fail "Start fehlgeschlagen:`n$($r.Out)" }
  } else {
    Say 'Lege den Container an ...'
    New-Container
  }
  Wait-Ssh
  Set-Ssh
  Show-Connect
}

function Stop-Clawbook {
  $s = Get-State
  if ($s.Running) { Say 'Halte den Container an ...'; $null = Invoke-Wslc stop $Container }
}

function Remove-ClawbookContainer {
  $s = Get-State
  if ($s.Exists) { $null = Invoke-Wslc rm -f $Container }
}

function Set-Ssh {
  # Private key: readable only by the current user (OpenSSH for Windows
  # refuses keys that others can read).
  $r = Invoke-Wslc exec $Container cat /home/student/.ssh/id_ed25519
  if ($r.Out -notmatch 'BEGIN OPENSSH PRIVATE KEY') { Fail 'Der SSH-Schluessel liess sich nicht lesen.' }
  if (Test-Path $KeyFile) {
    & icacls $KeyFile /grant:r "$($env:USERNAME):(F)" | Out-Null
    Remove-Item -Force $KeyFile
  }
  [IO.File]::WriteAllText($KeyFile, (($r.Out -replace "`r`n", "`n").Trim() + "`n"))
  & icacls $KeyFile /inheritance:r /grant:r "$($env:USERNAME):(R)" | Out-Null

  $block = @(
    $MarkBegin,
    'Host clawbook',
    '  HostName 127.0.0.1',
    "  Port $SshPort",
    '  User student',
    '  IdentityFile ~/.ssh/clawbook',
    '  IdentitiesOnly yes',
    '  StrictHostKeyChecking accept-new',
    '  UserKnownHostsFile ~/.ssh/known_hosts_clawbook',
    $MarkEnd
  ) -join "`n"
  $text = if (Test-Path $SshConfig) { [IO.File]::ReadAllText($SshConfig) } else { '' }
  $pattern = '(?s)' + [regex]::Escape($MarkBegin) + '.*?' + [regex]::Escape($MarkEnd)
  if ($text -match $pattern) { $text = [regex]::Replace($text, $pattern, $block) }
  else { $text = ($text.TrimEnd() + "`n`n" + $block + "`n").TrimStart() }
  [IO.File]::WriteAllText($SshConfig, $text)
  Say "SSH eingerichtet: Schluessel $KeyFile, Host 'clawbook' in $SshConfig" 'Green'
}

function Show-Connect {
  Write-Host ''
  Say '================================================================' 'Green'
  Say ' clawbook laeuft.' 'Green'
  Say '================================================================' 'Green'
  Say ' Terminal:        ssh clawbook'
  Say ' VS Code:         Erweiterung "Remote - SSH" -> "Connect to Host" -> clawbook'
  Say '                  Ordner: /home/student/source'
  Say " Bildschirm:      mstsc /v:localhost:$RdpPort   (Zertifikatswarnung bestaetigen)"
  Say " Austauschordner: $ExchangeDir  (im Container: ~/austausch)"
  Say " Sicherungen:     $BackupDir"
  Say '================================================================' 'Green'
  Write-Host ''
}

function Show-Status {
  $s = Get-State
  Say ("Home-Volume:  {0}" -f $(if ($s.Volume) { 'vorhanden' } else { 'fehlt' }))
  Say ("Container:    {0}" -f $(if ($s.Running) { 'laeuft' } elseif ($s.Exists) { 'angehalten' } else { 'fehlt' }))
  Say ("SSH-Port:     {0}" -f $(if (Test-Port $SshPort) { "offen ($SshPort)" } else { 'zu' }))
  Say ("Image:        {0}" -f $Image)
  if ($s.Running) {
    $b = Invoke-Wslc exec $Container cat /etc/clawbook-build
    Say ("Build:        {0}" -f (($b.Out -split "`n") -join ', '))
  }
}

function Get-FreeBytes($Path) {
  $drive = (Get-Item $Path).PSDrive
  return [int64]$drive.Free
}

function Export-Home($Target) {
  $s = Get-State
  if (-not $s.Volume) { Fail 'Es gibt kein Home-Volume zum Sichern.' }
  if (-not $Target) { $Target = Join-Path $BackupDir ("home-{0}.tar" -f (Get-Date -Format 'yyyy-MM-dd-HHmm')) }
  $dir = Split-Path -Parent $Target
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $name = Split-Path -Leaf $Target
  $wasRunning = $s.Running
  Stop-Clawbook
  # Size check: home size (approx.) against free space.
  $du = Invoke-Wslc run --rm -v "${Volume}:/h" $HelperImage du -sb /h
  $need = if ($du.Out -match '^(\d+)') { [int64]$Matches[1] } else { 0 }
  $free = Get-FreeBytes $dir
  if ($need -gt 0 -and $need * 1.1 -gt $free) {
    Fail ("Zu wenig Platz in {0}: benoetigt etwa {1:N1} GB, frei {2:N1} GB." -f $dir, ($need / 1GB), ($free / 1GB))
  }
  Say ("Sichere das Home ({0:N1} GB) nach {1} ..." -f ($need / 1GB), $Target) 'Cyan'
  $r = Invoke-Wslc run --rm -v "${Volume}:/h" -v "${dir}:/out" $HelperImage tar -C /h -cpf "/out/$name" .
  if ($r.Code -ne 0 -or -not (Test-Path $Target)) { Fail "Sicherung fehlgeschlagen:`n$($r.Out)" }
  Say "Sicherung geschrieben: $Target" 'Green'
  if ($wasRunning) { Start-Clawbook }
  return $Target
}

function Select-Backup {
  $files = Get-ChildItem -Path $BackupDir -Filter 'home-*.tar' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if ($files) {
    Say 'Vorhandene Sicherungen:'
    for ($i = 0; $i -lt $files.Count; $i++) {
      Say ("  [{0}] {1}  ({2:N1} GB, {3})" -f ($i + 1), $files[$i].Name, ($files[$i].Length / 1GB), $files[$i].LastWriteTime)
    }
  }
  $a = Read-Host 'Nummer waehlen oder vollstaendigen Pfad zu einer Sicherung eingeben'
  if ($a -match '^\d+$' -and $files -and [int]$a -ge 1 -and [int]$a -le $files.Count) { return $files[[int]$a - 1].FullName }
  if ($a -and (Test-Path $a)) { return (Resolve-Path $a).Path }
  Fail 'Keine gueltige Sicherung gewaehlt.'
}

function Import-Home($Source) {
  if (-not $Source) { $Source = Select-Backup }
  if (-not (Test-Path $Source)) { Fail "Datei nicht gefunden: $Source" }
  $s = Get-State
  if ($s.Volume) {
    Say 'Sichere zuerst das vorhandene Home, damit nichts verloren geht ...' 'Cyan'
    $null = Export-Home ''
  }
  Stop-Clawbook
  Remove-ClawbookContainer
  if ($s.Volume) { $null = Invoke-Wslc volume rm $Volume }
  Ensure-Volume
  $dir = Split-Path -Parent (Resolve-Path $Source).Path
  $name = Split-Path -Leaf $Source
  Say "Spiele $Source ein ..." 'Cyan'
  $r = Invoke-Wslc run --rm -v "${Volume}:/h" -v "${dir}:/in" $HelperImage tar -C /h -xpf "/in/$name"
  if ($r.Code -ne 0) { Fail "Import fehlgeschlagen:`n$($r.Out)" }
  if (Test-Path $KnownHosts) { Remove-Item -Force $KnownHosts }
  Start-Clawbook
  $check = Invoke-Wslc exec $Container bash -c 'test -s /home/student/.ssh/id_ed25519 && test -d /home/student/source && echo OK'
  if ($check.Out -match 'OK') { Say 'Import geprueft: Schluessel und ~/source sind da.' 'Green' }
  else { Say 'Hinweis: im importierten Home fehlt ~/source oder der Schluessel.' 'Yellow' }
}

function Update-Clawbook {
  Say "Lade die neueste Fassung von $Image ..." 'Cyan'
  $r = Invoke-Wslc pull $Image
  if ($r.Code -ne 0) { Fail "Aktualisierung fehlgeschlagen:`n$($r.Out)" }
  Stop-Clawbook
  Remove-ClawbookContainer
  Say 'Lege den Container mit dem neuen Image an (das Home bleibt erhalten) ...'
  New-Container
  Wait-Ssh
  Set-Ssh
  Show-Connect
}

function Reset-Clawbook {
  Say 'Zuruecksetzen loescht das Home im Container. Vorher wird es gesichert.' 'Yellow'
  $a = Read-Host 'Wirklich zuruecksetzen? Zum Bestaetigen "ja" eingeben'
  if ($a -ne 'ja') { Say 'Abgebrochen.'; return }
  $s = Get-State
  if ($s.Volume) { $null = Export-Home '' }
  Stop-Clawbook
  Remove-ClawbookContainer
  if ($s.Volume) { $null = Invoke-Wslc volume rm $Volume }
  if (Test-Path $KnownHosts) { Remove-Item -Force $KnownHosts }
  Start-Clawbook
}

function Show-Menu {
  while ($true) {
    $s = Get-State
    Write-Host ''
    Say 'clawbook - was moechtest du tun?' 'Cyan'
    if (-not $s.Volume) {
      Say '  [1] neu einrichten (Vorgabe)'
      Say '  [2] aus einer Sicherung importieren'
      Say '  [0] beenden'
      $a = Read-Host 'Auswahl [1]'
      switch ($a) {
        '' { Start-Clawbook; return }
        '1' { Start-Clawbook; return }
        '2' { Import-Home ''; return }
        '0' { return }
        default { Say 'Bitte 1, 2 oder 0 eingeben.' 'Yellow' }
      }
    } else {
      $state = if ($s.Running) { 'laeuft' } elseif ($s.Exists) { 'angehalten' } else { 'noch nicht angelegt' }
      Say "  (Container: $state)"
      Say '  [1] starten und verbinden (Vorgabe)'
      Say '  [2] auf das neueste Image aktualisieren'
      Say '  [3] mitnehmen: Home als Sicherung speichern'
      Say '  [4] aus einer Sicherung importieren'
      Say '  [5] SSH fuer VS Code neu einrichten'
      Say '  [6] Status anzeigen'
      Say '  [7] anhalten'
      Say '  [8] zuruecksetzen (Home neu, vorher Sicherung)'
      Say '  [0] beenden'
      $a = Read-Host 'Auswahl [1]'
      switch ($a) {
        '' { Start-Clawbook; return }
        '1' { Start-Clawbook; return }
        '2' { Update-Clawbook; return }
        '3' { $null = Export-Home ''; return }
        '4' { Import-Home ''; return }
        '5' { if (-not (Get-State).Running) { Start-Clawbook } else { Set-Ssh }; return }
        '6' { Show-Status }
        '7' { Stop-Clawbook; Say 'Angehalten.'; return }
        '8' { Reset-Clawbook; return }
        '0' { return }
        default { Say 'Bitte eine Zahl aus dem Menue eingeben.' 'Yellow' }
      }
    }
  }
}

# --- Main --------------------------------------------------------------
Log "=== clawbook.ps1 Action='$Action' Image='$Image'"
Test-Wslc
switch ($Action) {
  'start' { Start-Clawbook }
  'update' { Update-Clawbook }
  'export' { $null = Export-Home $File }
  'import' { Import-Home $File }
  'ssh' { Set-Ssh }
  'status' { Show-Status }
  'stop' { Stop-Clawbook }
  'reset' { Reset-Clawbook }
  default { Show-Menu }
}
