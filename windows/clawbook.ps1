<#
.SYNOPSIS
  clawbook-lehre - Arbeitsrechner für die Arbeit mit KI-Agenten unter Windows.

.DESCRIPTION
  Verwaltet den clawbook-Container über WSLC (WSL-Container), ohne
  Administrator-Rechte:
    - Image holen, Container und Home-Volume anlegen und starten
    - SSH-Schlüssel nach Windows holen und SSH für VS Code einrichten
    - das Home sichern (mitnehmen), importieren, zurücksetzen

  Normalerweise startet man es über den Befehl von der Startseite des
  Repositorys; ohne Parameter erscheint ein Menü.

  Umgebungsvariable CLAWBOOK_NOPAUSE=1: bei Fehlern nicht auf Enter warten
  (für automatische Tests).

.PARAMETER Action
  start, update, export, import, ssh, status, stop, reset - ohne Angabe: Menü.

.PARAMETER Image
  Image, Vorgabe ghcr.io/schlingensiepen/clawbook-lehre:latest

.PARAMETER File
  Sicherungsdatei für -Action import bzw. Zieldatei für -Action export.
#>
# Invoke-Wslc and Invoke-WslcWithDots forward wslc command lines verbatim,
# so their arguments are positional by design.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '')]
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
# The marker lines must stay byte-identical: they locate existing blocks.
$MarkBegin = '# >>> clawbook (verwaltet von clawbook.ps1 - nicht von Hand aendern)'
$MarkEnd = '# <<< clawbook'

# Shown whenever the container does not come up in time.
$TimeoutHint = "Der Container braucht länger als sonst. Warte eine Minute und wähle dann im Menü [1] ‚starten und verbinden‘."
$LongWaitHint = 'Das kann einige Minuten dauern – bitte nicht abbrechen.'

foreach ($d in @($AppDir, $LogDir, $UserDir, $ExchangeDir, $BackupDir, $SshDir)) {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
}
$LogFile = Join-Path $LogDir ("clawbook-{0}.log" -f (Get-Date -Format 'yyyyMMdd'))
$Utf8NoBom = New-Object Text.UTF8Encoding $false
$WslcPath = 'wslc'

# --- Helpers -------------------------------------------------------------
function Hide-Secret([string]$Text) {
  # Replaces every private key block (also a truncated one) by a placeholder.
  if (-not $Text) { return $Text }
  return [regex]::Replace($Text,
    '(?s)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----.*?(?:-----END [A-Z0-9 ]*PRIVATE KEY-----|\z)',
    '[privater Schlüssel entfernt]')
}

function Log($Text) {
  # Central place for the log file: UTF-8, private keys always removed.
  $line = "{0} {1}`r`n" -f (Get-Date -Format 'HH:mm:ss'), (Hide-Secret "$Text")
  try { [IO.File]::AppendAllText($LogFile, $line, $Utf8NoBom) } catch { $null = $_ }
}
function Say($Text, $Color = 'Gray') { Write-Host $Text -ForegroundColor $Color; Log $Text }

function Wait-BeforeExit {
  # Keeps the window open so the message stays readable; never blocks tests.
  if ($env:CLAWBOOK_NOPAUSE -eq '1') { return }
  if (-not [Environment]::UserInteractive) { return }
  try { if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { return } }
  catch { return }
  $null = Read-Host 'Drücke Enter, um zu beenden'
}
function Exit-WithError { Log '=== exit 1'; Wait-BeforeExit; exit 1 }
function Fail($Text) { Say "FEHLER: $Text" 'Red'; Say "Protokoll: $LogFile" 'Red'; Exit-WithError }

function Invoke-Wslc {
  # Runs wslc; returns @{ Code; Out }. Never throws on native stderr.
  $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  $out = & $WslcPath @args 2>&1 | ForEach-Object { "$_" } | Out-String
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  Log ("wslc {0} -> {1}`n{2}" -f ($args -join ' '), $code, $out.Trim())
  return @{ Code = $code; Out = $out.Trim() }
}

function ConvertTo-ArgumentString([string[]]$List) {
  # Builds a Windows command line (CommandLineToArgvW rules) from single arguments.
  $quoted = foreach ($a in $List) {
    if ($a -eq '') { '""' }
    elseif ($a -match '[\s"]') {
      '"' + (($a -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"'
    } else { $a }
  }
  return ($quoted -join ' ')
}

function Invoke-WslcWithDots {
  # Like Invoke-Wslc, but prints a dot every five seconds while wslc runs.
  $list = @($args | ForEach-Object { "$_" })
  $outFile = [IO.Path]::GetTempFileName()
  $errFile = [IO.Path]::GetTempFileName()
  try {
    $p = Start-Process -FilePath $WslcPath -ArgumentList (ConvertTo-ArgumentString $list) `
      -NoNewWindow -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $null = $p.Handle  # keeps ExitCode available after the process ends
    while (-not $p.WaitForExit(5000)) { Write-Host -NoNewline '.' }
    $p.WaitForExit()
    Write-Host ''
    $code = $p.ExitCode
    $out = ("{0}`n{1}" -f (Get-Content -Raw -Encoding UTF8 -LiteralPath $outFile),
      (Get-Content -Raw -Encoding UTF8 -LiteralPath $errFile)).Trim()
  } finally {
    Remove-Item -Force -LiteralPath $outFile, $errFile -ErrorAction SilentlyContinue
  }
  Log ("wslc {0} -> {1}`n{2}" -f ($list -join ' '), $code, $out)
  return @{ Code = $code; Out = $out }
}

function Invoke-Visible($FilePath, [string[]]$ArgList) {
  # Runs a program with its own output directly in the console (progress
  # stays visible); returns the exit code.
  Log ("{0} {1} (Ausgabe direkt im Fenster)" -f $FilePath, ($ArgList -join ' '))
  $p = Start-Process -FilePath $FilePath -ArgumentList (ConvertTo-ArgumentString $ArgList) -NoNewWindow -Wait -PassThru
  Log ("{0} {1} -> {2}" -f $FilePath, ($ArgList -join ' '), $p.ExitCode)
  return $p.ExitCode
}

function Test-NativeOk($FilePath, [string[]]$ArgList) {
  # True if the program runs and exits with 0; output is discarded.
  $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { $null = & $FilePath @ArgList 2>&1; $ok = ($LASTEXITCODE -eq 0) }
  catch { $ok = $false }
  $ErrorActionPreference = $prev
  return $ok
}

function Read-YesNo($Prompt, [bool]$DefaultYes) {
  $a = Read-Host $Prompt
  if ($null -eq $a) { $a = '' }
  $a = $a.Trim()
  if ($a -eq '') { return $DefaultYes }
  return ($a -match '^[jJyY]')
}

function Test-Wslc {
  if (-not (Get-Command wslc -ErrorAction SilentlyContinue)) {
    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    $hasWsl = $wsl -and ((Test-NativeOk $wsl.Source @('--version')) -or (Test-NativeOk $wsl.Source @('--status')))
    if (-not $hasWsl) {
      Say 'WSL (Windows-Subsystem für Linux) ist auf diesem Rechner nicht installiert.' 'Yellow'
      Say 'Installiere es in PowerShell mit:  wsl --install' 'Yellow'
      Say 'Dafür braucht man unter Umständen Administrator-Rechte. Hast du sie nicht, frag die IT deiner Hochschule.' 'Yellow'
      Say 'Starte Windows danach neu und führe den Befehl von der Startseite erneut aus.' 'Yellow'
      Exit-WithError
    }
    Say 'WSL ist installiert, aber zu alt: Das Werkzeug wslc (WSL-Container) fehlt noch.' 'Yellow'
    Update-Wsl
  }
  $script:WslcPath = (Get-Command wslc).Source
  $v = (Invoke-Wslc version).Out
  $ver = if ($v -match '(\d+\.\d+\.\d+)') { [version]$Matches[1] } else { [version]'0.0.0' }
  if ($ver -lt $MinWslc) {
    Say "Deine WSL-Version ist zu alt: wslc $ver, nötig ist mindestens $MinWslc." 'Yellow'
    Update-Wsl
  }
  if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Say 'Hinweis: Der OpenSSH-Client (Befehl ssh) fehlt auf diesem Rechner. Ohne ihn klappen ssh clawbook und VS Code nicht.' 'Yellow'
    Say 'Installiere ihn über Einstellungen → System → Optionale Features → OpenSSH-Client.' 'Yellow'
    Say 'Geht das nicht (fehlende Rechte), frag die IT deiner Hochschule.' 'Yellow'
  }
}

function Update-Wsl {
  # Offers "wsl --update" (works without administrator rights), then ends.
  if (Read-YesNo 'Jetzt mit „wsl --update“ aktualisieren? Das geht ohne Administrator-Rechte. [J/n]' $true) {
    $wsl = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wsl) { $null = Invoke-Visible $wsl.Source @('--update') }
    Say 'Führe danach den Befehl von der Startseite erneut aus.' 'Yellow'
  } else {
    Say 'Aktualisiere WSL selbst mit:  wsl --update   (geht ohne Administrator-Rechte)' 'Yellow'
    Say 'Führe danach den Befehl von der Startseite erneut aus.' 'Yellow'
  }
  Exit-WithError
}

function Get-State {
  $vol = (Invoke-Wslc volume inspect $Volume).Code -eq 0
  $c = Invoke-Wslc inspect $Container
  $exists = $c.Code -eq 0 -and $c.Out -match '"Id"'
  $running = $exists -and ($c.Out -match '"Running"\s*:\s*true')
  return @{ Volume = $vol; Exists = $exists; Running = $running; Inspect = $c.Out }
}

function Test-Port($Port) {
  try { $t = New-Object Net.Sockets.TcpClient; $t.Connect('127.0.0.1', $Port); $t.Close(); return $true }
  catch { return $false }
}

function Assert-PortsFree {
  # Called only while our container is not running: an open port then
  # belongs to another program.
  foreach ($port in @($SshPort, $RdpPort)) {
    $busy = $true
    for ($i = 0; $i -lt 3; $i++) {
      if (-not (Test-Port $port)) { $busy = $false; break }
      Start-Sleep -Seconds 2
    }
    if ($busy) {
      $fmt = 'Port {0} ist schon von einem anderen Programm belegt. clawbook braucht die Ports {1} (SSH) und {2} (Remotedesktop). ' +
        'Beende das andere Programm oder starte Windows neu und versuche es dann erneut.'
      Fail ($fmt -f $port, $SshPort, $RdpPort)
    }
  }
}

function Wait-Ssh {
  Say 'Warte auf den Container (beim ersten Start bis zu drei Minuten) ...'
  $deadline = (Get-Date).AddMinutes(3)
  while ((Get-Date) -lt $deadline) {
    if (Test-Port $SshPort) {
      # sshd answers; give the init step a moment to finish writing the key.
      for ($i = 0; $i -lt 30; $i++) {
        if ((Invoke-Wslc exec $Container test -s /home/student/.ssh/id_ed25519).Code -eq 0) { Write-Host ''; return }
        Write-Host -NoNewline '.'
        Start-Sleep -Seconds 2
      }
      Write-Host ''
      return
    }
    Write-Host -NoNewline '.'
    Start-Sleep -Seconds 3
  }
  Write-Host ''
  $logs = (Hide-Secret (Invoke-Wslc logs $Container).Out) -split "`n" |
    Where-Object { $_ -notmatch '^[A-Za-z0-9+/=]{30,}$' -and $_ -notmatch 'PRIVATE KEY' } |
    Select-Object -Last 20
  if ($logs) { Write-Host ("Letzte Meldungen des Containers:`n" + ($logs -join "`n")) -ForegroundColor DarkGray }
  Fail $TimeoutHint
}

function Invoke-Pull($Name) {
  # Registry connections from inside WSL sometimes time out on the first
  # attempt, so try a few times before giving up.
  $attempts = 3
  for ($i = 1; $i -le $attempts; $i++) {
    $code = Invoke-Visible $WslcPath @('pull', $Name)
    if ($code -eq 0) { return }
    if ($i -lt $attempts) {
      Say "Der Download hat nicht geklappt (Versuch $i von $attempts). Ich versuche es in 15 Sekunden erneut ..." 'Yellow'
      Start-Sleep -Seconds 15
    }
  }
  Say 'Mögliche Ursachen: keine Internetverbindung, ein aktives VPN, ein Proxy oder eine Firewall der Hochschule.' 'Yellow'
  Say 'Prüfen kannst du die Verbindung mit:  curl.exe -sI https://ghcr.io/v2/   (kommt eine Antwort wie „HTTP/1.1 401“ oder „405“, ist ghcr.io erreichbar).' 'Yellow'
  Say 'Für den ersten Download brauchst du eine stabile Verbindung – WLAN im Zug oder ein Handy-Hotspot reichen oft nicht.' 'Yellow'
  Fail "Das Image $Name ließ sich nicht laden. Prüfe deine Internetverbindung und versuche es dann erneut."
}

function Ensure-HelperImage {
  # Small image for tar/du in backups; loaded early so a backup later does
  # not suddenly need the internet.
  if ((Invoke-Wslc image inspect $HelperImage).Code -ne 0) {
    Say "Lade das kleine Hilfs-Image $HelperImage (für Sicherungen, nur beim ersten Mal) ..." 'Cyan'
    Invoke-Pull $HelperImage
  }
}

function Ensure-Image {
  if ((Invoke-Wslc image inspect $Image).Code -ne 0) {
    Say 'Lade das Image (einige GB, nur beim ersten Mal). Das kann 5 bis 20 Minuten dauern – bitte nicht abbrechen und das Fenster offen lassen.' 'Cyan'
    Say "Image: $Image" 'Cyan'
    Invoke-Pull $Image
  }
  Ensure-HelperImage
}

function Ensure-Volume($FailHint = '') {
  if ((Invoke-Wslc volume inspect $Volume).Code -ne 0) {
    Say "Lege das Home-Volume $Volume an ..."
    $r = Invoke-Wslc volume create --driver vhd -o "SizeBytes=$VolumeBytes" $Volume
    if ($r.Code -ne 0) { Fail "Das Home-Volume ließ sich nicht anlegen.$FailHint" }
  }
}

function New-Container {
  Ensure-Image
  Ensure-Volume
  $r = Invoke-Wslc run -d --name $Container `
    -p "127.0.0.1:${SshPort}:22" -p "127.0.0.1:${RdpPort}:3389" `
    -v "${Volume}:/home/student" -v "${ExchangeDir}:/home/student/austausch" `
    -e "CLAWBOOK_SSH_PORT=$SshPort" -e "CLAWBOOK_RDP_PORT=$RdpPort" -e 'CLAWBOOK_SAMBA=0' `
    $Image
  if ($r.Code -ne 0) { Fail "Der Container ließ sich nicht anlegen:`n$($r.Out)" }
}

function Start-Clawbook {
  $s = Get-State
  if ($s.Running) { Say 'Der Container läuft bereits.' }
  elseif ($s.Exists) {
    Assert-PortsFree
    Say 'Starte den Container ...'
    $r = Invoke-Wslc start $Container
    if ($r.Code -ne 0) { Fail "Der Container ließ sich nicht starten:`n$($r.Out)" }
  } else {
    Assert-PortsFree
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

function Update-Ssh {
  # Menu [5] and -Action ssh: needs a running container.
  if (-not (Get-State).Running) {
    Say 'Der Container läuft nicht – ich starte ihn zuerst.' 'Yellow'
    Start-Clawbook
  } else {
    Set-Ssh
  }
}

function Set-Ssh {
  # Private key: readable only by the current user (OpenSSH for Windows
  # refuses keys that others can read).
  $r = Invoke-Wslc exec $Container cat /home/student/.ssh/id_ed25519
  if ($r.Out -notmatch 'BEGIN OPENSSH PRIVATE KEY') {
    Fail "Der SSH-Schlüssel ließ sich nicht aus dem Container lesen. $TimeoutHint"
  }
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
  Say "SSH eingerichtet: Schlüssel $KeyFile, Host 'clawbook' in $SshConfig" 'Green'
}

function Show-Connect {
  Write-Host ''
  Say '================================================================' 'Green'
  Say ' clawbook läuft. So geht es weiter:' 'Green'
  Say '================================================================' 'Green'
  Say ' 1. Terminal: Öffne ein neues PowerShell-Fenster und gib ein:'
  Say '       ssh clawbook'
  Say ' 2. VS Code: Remote-SSH → clawbook → Ordner /home/student/source'
  Say '    (dort liegt anfangs das Beispielprojekt Sample/primer)'
  Say " 3. Remotedesktop: mstsc /v:localhost:$RdpPort"
  Say '    Ohne Passwort. Fragt Windows nach dem Zertifikat: „Ja“ wählen.'
  Say ''
  Say " Austauschordner: $ExchangeDir  (im Container: ~/austausch)"
  Say " Sicherungen:     $BackupDir"
  Say '================================================================' 'Green'
  Write-Host ''
}

function Get-UsedImage($InspectText) {
  # Prefers a readable image name over a sha256 id from wslc inspect.
  $names = @([regex]::Matches("$InspectText", '"Image"\s*:\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
  $readable = @($names | Where-Object { $_ -notmatch '^sha256:' })
  if ($readable.Count -gt 0) { return $readable[0] }
  if ($names.Count -gt 0) { return $names[0] }
  return 'unbekannt'
}

function Show-Status {
  $s = Get-State
  Say ("Home-Volume:        {0}" -f $(if ($s.Volume) { 'vorhanden' } else { 'noch nicht angelegt' }))
  Say ("Container:          {0}" -f $(if ($s.Running) { 'läuft' } elseif ($s.Exists) { 'angehalten' } else { 'noch nicht angelegt' }))
  Say ("SSH-Port:           {0}" -f $(if (Test-Port $SshPort) { "offen ($SshPort)" } else { 'zu' }))
  Say ("Gewünschtes Image:  {0}" -f $Image)
  Say ("Benutztes Image:    {0}" -f $(if ($s.Exists) { Get-UsedImage $s.Inspect } else { 'noch nicht angelegt' }))
  if ($s.Running) {
    $b = Invoke-Wslc exec $Container cat /etc/clawbook-build
    Say ("Build:              {0}" -f (($b.Out -split "`n") -join ', '))
  }
  $files = @(Get-ChildItem -Path $BackupDir -Filter 'home-*.tar' -ErrorAction SilentlyContinue)
  if ($files.Count -eq 0) { Say ("Sicherungen:        keine (Ordner {0})" -f $BackupDir) }
  else {
    $sum = ($files | Measure-Object -Property Length -Sum).Sum
    Say ("Sicherungen:        {0} Datei(en), zusammen {1:N1} GB (Ordner {2})" -f $files.Count, ($sum / 1GB), $BackupDir)
  }
}

function Get-FreeBytes($Path) {
  # -1 if unknown (e.g. network path without drive letter).
  try {
    $drive = (Get-Item -LiteralPath $Path).PSDrive
    if ($drive) { return [int64]$drive.Free }
  } catch { $null = $_ }
  return [int64]-1
}

function Restart-AfterFailure([bool]$WasRunning) {
  # A failed backup must not leave a previously running container stopped.
  if (-not $WasRunning) { return }
  Say 'Starte den Container wieder ...'
  $r = Invoke-Wslc start $Container
  if ($r.Code -eq 0) { Say 'Der Container läuft wieder.' 'Green' }
  else { Say "Der Container ließ sich nicht wieder starten. Wähle im Menü [1] ‚starten und verbinden‘." 'Yellow' }
}

function Export-Home($Target, [switch]$NoRestart) {
  $s = Get-State
  if (-not $s.Volume) { Fail 'Es gibt noch kein Home-Volume, das sich sichern ließe.' }
  Ensure-HelperImage
  if ($Target) {
    $Target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$Target".Trim().Trim('"'))
  } else {
    $Target = Join-Path $BackupDir ("home-{0}.tar" -f (Get-Date -Format 'yyyy-MM-dd-HHmmss'))
  }
  $dir = Split-Path -Parent $Target
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $name = Split-Path -Leaf $Target
  $wasRunning = $s.Running
  Stop-Clawbook
  # Size check: home size (approx.) against free space.
  Say 'Prüfe, wie groß dein Home ist und ob genug Platz frei ist ...'
  $du = Invoke-WslcWithDots run --rm -v "${Volume}:/h" $HelperImage du -sb /h
  $need = if ($du.Out -match '^(\d+)') { [int64]$Matches[1] } else { 0 }
  $free = Get-FreeBytes $dir
  if ($need -gt 0 -and $free -ge 0 -and $need * 1.1 -gt $free) {
    Restart-AfterFailure $wasRunning
    Fail ("Zu wenig Platz in {0}: nötig sind etwa {1:N1} GB, frei sind {2:N1} GB. Schaffe Platz und versuche es dann erneut." -f $dir, ($need / 1GB), ($free / 1GB))
  }
  Say ("Sichere das Home (etwa {0:N1} GB) nach {1}." -f ($need / 1GB), $Target) 'Cyan'
  Say $LongWaitHint 'Cyan'
  $r = Invoke-WslcWithDots run --rm -v "${Volume}:/h" -v "${dir}:/out" $HelperImage tar -C /h -cpf "/out/$name" .
  if ($r.Code -ne 0 -or -not (Test-Path -LiteralPath $Target)) {
    # Never leave a half-written archive that looks like a valid backup.
    Remove-Item -Force -LiteralPath $Target -ErrorAction SilentlyContinue
    Restart-AfterFailure $wasRunning
    Fail 'Die Sicherung ist fehlgeschlagen. Einzelheiten stehen im Protokoll.'
  }
  Say "Sicherung geschrieben: $Target" 'Green'
  if ($wasRunning -and -not $NoRestart) { Start-Clawbook }
  return $Target
}

function Select-Backup {
  $files = @(Get-ChildItem -Path $BackupDir -Filter 'home-*.tar' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
  if ($files.Count -gt 0) {
    Say 'Vorhandene Sicherungen:'
    for ($i = 0; $i -lt $files.Count; $i++) {
      Say ("  [{0}] {1}  ({2:N1} GB, {3})" -f ($i + 1), $files[$i].Name, ($files[$i].Length / 1GB), $files[$i].LastWriteTime)
    }
  } else {
    Say "Im Ordner $BackupDir liegt noch keine Sicherung."
  }
  $a = Read-Host 'Nummer wählen oder den vollständigen Pfad zu einer Sicherung eingeben'
  if ($null -eq $a) { $a = '' }
  $a = $a.Trim().Trim('"')
  if ($a -match '^\d+$' -and [int]$a -ge 1 -and [int]$a -le $files.Count) { return $files[[int]$a - 1].FullName }
  if ($a -and (Test-Path -LiteralPath $a -PathType Leaf)) { return (Resolve-Path -LiteralPath $a).Path }
  Fail 'Keine gültige Sicherung gewählt.'
}

function Test-Archive($Dir, $Name) {
  # Readable tar with a clawbook home inside (./.ssh or ./source at top level)?
  # Returns 'ok', 'unreadable' or 'foreign'.
  $sh = 'if ! tar -tf "/in/$1" > /tmp/list 2> /tmp/err; then echo CLAWBOOK_UNREADABLE; head -n 5 /tmp/err; ' +
    'elif grep -qE "^(\./)?(\.ssh|source)(/|$)" /tmp/list; then echo CLAWBOOK_OK; else echo CLAWBOOK_FOREIGN; fi'
  $r = Invoke-WslcWithDots run --rm -v "${Dir}:/in" $HelperImage sh -c $sh sh $Name
  if ($r.Out -match 'CLAWBOOK_OK') { return 'ok' }
  if ($r.Out -match 'CLAWBOOK_FOREIGN') { return 'foreign' }
  return 'unreadable'
}

function Import-Home($Source) {
  if (-not $Source) { $Source = Select-Backup }
  $Source = "$Source".Trim().Trim('"')
  if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { Fail "Datei nicht gefunden: $Source" }
  $Source = (Resolve-Path -LiteralPath $Source).Path
  $dir = Split-Path -Parent $Source
  $name = Split-Path -Leaf $Source
  Ensure-HelperImage

  Say '[1/5] Prüfe die Sicherung ...' 'Cyan'
  Say $LongWaitHint 'Cyan'
  $check = Test-Archive $dir $name
  if ($check -eq 'unreadable') { Fail "Die Datei ist keine lesbare Sicherung: $Source`nDein Home ist unverändert." }
  if ($check -eq 'foreign') { Fail "Die Datei sieht nicht wie eine clawbook-Sicherung aus (kein .ssh oder source darin): $Source`nDein Home ist unverändert." }

  $s = Get-State
  if ($s.Volume) {
    if (-not (Read-YesNo 'Dein jetziges Home wird durch die Sicherung ersetzt. Es wird vorher automatisch gesichert. Weiter? [j/N]' $false)) {
      Say 'Abgebrochen. Dein Home ist unverändert.'
      return
    }
  }
  # Load the main image before anything is removed: no half state without internet.
  Ensure-Image

  $backup = $null
  if ($s.Volume) {
    Say '[2/5] Sichere zuerst dein jetziges Home, damit nichts verloren geht ...' 'Cyan'
    $backup = Export-Home '' -NoRestart
  } else {
    Say '[2/5] Kein Home vorhanden, es gibt nichts zu sichern.' 'Cyan'
  }
  $hint = ''
  if ($backup) {
    $hint = "`nDein vorheriges Home wurde vorher automatisch gesichert: $backup`nMit Menüpunkt [4] und dieser Datei holst du den alten Stand zurück."
  }

  Say '[3/5] Entferne den Container und das alte Home ...' 'Cyan'
  Stop-Clawbook
  Remove-ClawbookContainer
  if ($s.Volume) {
    $r = Invoke-Wslc volume rm $Volume
    if ($r.Code -ne 0) { Fail "Das alte Home-Volume ließ sich nicht entfernen.$hint" }
  }
  Ensure-Volume $hint

  Say "[4/5] Spiele $Source ein." 'Cyan'
  Say $LongWaitHint 'Cyan'
  $r = Invoke-WslcWithDots run --rm -v "${Volume}:/h" -v "${dir}:/in" $HelperImage tar -C /h -xpf "/in/$name"
  if ($r.Code -ne 0) { Fail "Das Entpacken der Sicherung ist fehlgeschlagen.$hint" }
  if (Test-Path $KnownHosts) { Remove-Item -Force $KnownHosts }

  Say '[5/5] Starte den Container und richte SSH ein ...' 'Cyan'
  Start-Clawbook
  $check = Invoke-Wslc exec $Container bash -c 'test -s /home/student/.ssh/id_ed25519 && test -d /home/student/source && echo OK'
  if ($check.Out -match 'OK') { Say 'Import geprüft: Schlüssel und ~/source sind da.' 'Green' }
  else { Say 'Hinweis: Im importierten Home fehlt ~/source oder der Schlüssel.' 'Yellow' }
}

function Update-Clawbook {
  Say 'Laufende Programme im Container werden beendet. Speichere offene Dateien und beende Agenten.' 'Yellow'
  Say 'Dein Home bleibt erhalten.' 'Yellow'
  if (-not (Read-YesNo 'Jetzt aktualisieren? [J/n]' $true)) { Say 'Abgebrochen.'; return }
  Say "[1/4] Lade die neueste Fassung von $Image." 'Cyan'
  Say 'Das kann einige Minuten dauern – bitte nicht abbrechen und das Fenster offen lassen.' 'Cyan'
  Invoke-Pull $Image
  Ensure-HelperImage
  Say '[2/4] Halte den Container an und entferne ihn (dein Home bleibt erhalten) ...' 'Cyan'
  Stop-Clawbook
  Remove-ClawbookContainer
  Say '[3/4] Lege den Container mit dem neuen Image an ...' 'Cyan'
  Assert-PortsFree
  New-Container
  Say '[4/4] Warte auf den Container und richte SSH ein ...' 'Cyan'
  Wait-Ssh
  Set-Ssh
  Show-Connect
}

function Reset-Clawbook {
  Say 'Zurücksetzen löscht dein Home im Container. Vorher wird es automatisch gesichert.' 'Yellow'
  Say 'Laufende Programme im Container werden beendet. Speichere offene Dateien und beende Agenten.' 'Yellow'
  $a = Read-Host 'Wirklich zurücksetzen? Zum Bestätigen „ja“ eingeben'
  if ("$a".Trim() -ne 'ja') { Say 'Abgebrochen.'; return }
  $s = Get-State
  $hint = ''
  if ($s.Volume) {
    Say '[1/4] Sichere dein Home ...' 'Cyan'
    $backup = Export-Home '' -NoRestart
    $hint = "`nDein Home wurde vorher gesichert: $backup`nMit Menüpunkt [4] und dieser Datei holst du den alten Stand zurück."
  } else {
    Say '[1/4] Kein Home vorhanden, es gibt nichts zu sichern.' 'Cyan'
  }
  Say '[2/4] Entferne den Container und das Home ...' 'Cyan'
  Stop-Clawbook
  Remove-ClawbookContainer
  if ($s.Volume) {
    $r = Invoke-Wslc volume rm $Volume
    if ($r.Code -ne 0) { Fail "Das Home-Volume ließ sich nicht entfernen.$hint" }
  }
  if (Test-Path $KnownHosts) { Remove-Item -Force $KnownHosts }
  Say '[3/4] Lege Container und neues Home an ...' 'Cyan'
  Assert-PortsFree
  New-Container
  Say '[4/4] Warte auf den Container und richte SSH ein ...' 'Cyan'
  Wait-Ssh
  Set-Ssh
  Show-Connect
}

function Show-Menu {
  while ($true) {
    $s = Get-State
    Write-Host ''
    Say 'clawbook – was möchtest du tun?' 'Cyan'
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
      $state = if ($s.Running) { 'läuft' } elseif ($s.Exists) { 'angehalten' } else { 'noch nicht angelegt' }
      Say "  (Container: $state)"
      Say '  [1] starten und verbinden (Vorgabe)'
      Say '  [2] auf das neueste Image aktualisieren'
      Say '  [3] mitnehmen: Home als Sicherung speichern'
      Say '  [4] aus einer Sicherung importieren'
      Say '  [5] SSH für VS Code neu einrichten'
      Say '  [6] Status anzeigen'
      Say '  [7] anhalten'
      Say '  [8] zurücksetzen (Home neu, vorher Sicherung)'
      Say '  [0] beenden'
      $a = Read-Host 'Auswahl [1]'
      switch ($a) {
        '' { Start-Clawbook; return }
        '1' { Start-Clawbook; return }
        '2' { Update-Clawbook; return }
        '3' { $null = Export-Home ''; return }
        '4' { Import-Home ''; return }
        '5' { Update-Ssh; return }
        '6' { Show-Status }
        '7' { Stop-Clawbook; Say 'Angehalten.'; return }
        '8' { Reset-Clawbook; return }
        '0' { return }
        default { Say 'Bitte eine Zahl aus dem Menü eingeben.' 'Yellow' }
      }
    }
  }
}

# --- Main --------------------------------------------------------------
Log "=== clawbook.ps1 Action='$Action' Image='$Image'"
Say "Protokoll: $LogFile" 'DarkGray'
try {
  Test-Wslc
  switch ($Action) {
    'start' { Start-Clawbook }
    'update' { Update-Clawbook }
    'export' { $null = Export-Home $File }
    'import' { Import-Home $File }
    'ssh' { Update-Ssh }
    'status' { Show-Status }
    'stop' { Stop-Clawbook }
    'reset' { Reset-Clawbook }
    default { Show-Menu }
  }
} catch {
  Fail ("Unerwarteter Fehler: {0}" -f $_.Exception.Message)
}
