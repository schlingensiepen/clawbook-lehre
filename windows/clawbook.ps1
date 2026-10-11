<#
.SYNOPSIS
  clawbook-lehre - Arbeitsrechner für die Arbeit mit KI-Agenten unter Windows.

.DESCRIPTION
  Verwaltet den clawbook-Container über WSLC (WSL-Container), ohne
  Administrator-Rechte:
    - Image holen, Container und Home-Volume anlegen und starten
    - SSH-Schlüssel nach Windows holen und SSH für VS Code einrichten
    - das Home sichern (mitnehmen), importieren, zurücksetzen
    - ein portables VS Code (VSCodePack) bei Microsoft laden, einrichten
      und mit dem Container verbinden

  Normalerweise startet man es über den Befehl von der Startseite des
  Repositorys; ohne Parameter erscheint ein Menü.

  Umgebungsvariable CLAWBOOK_NOPAUSE=1: bei Fehlern nicht auf Enter warten
  (für automatische Tests).
  Umgebungsvariable CLAWBOOK_REF: Branch oder Tag des Repositorys, aus dem
  Dateien geladen werden (Vorgabe main; für Tests).

.PARAMETER Action
  start, update, export, import, ssh, status, stop, reset, vscode,
  vscode-install - ohne Angabe: Menü.

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
  [ValidateSet('', 'start', 'update', 'export', 'import', 'ssh', 'status', 'stop', 'reset', 'vscode', 'vscode-install')]
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

# VSCodePack: portable VS Code per course id (DEC-054). The course
# description comes from the product repository for now; course packages
# will provide it from inside the container later.
$PackRoot = Join-Path $AppDir 'vscode'
$CourseFile = Join-Path $AppDir 'kurs.txt'
$DefaultCourse = 'clawbook'
$DefaultFolder = '/home/student/source'
# Branch or tag for raw downloads (tests); checked in the main part.
$Ref = if ($env:CLAWBOOK_REF) { "$env:CLAWBOOK_REF".Trim() } else { 'main' }
$RawBase = "https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/$Ref"
$CourseWebBase = "$RawBase/windows/vscodepack"
$VsCodeApi = 'https://update.code.visualstudio.com/api/update/win32-x64-archive/stable/latest'
$VsCodeLatest = 'https://update.code.visualstudio.com/latest/win32-x64-archive/stable'
$ShortcutName = 'clawbook VS Code.lnk'

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
  Say ' 2. VS Code: Befehl erneut ausführen, Menüpunkt [9] (richtet beim'
  Say '    ersten Mal ein eigenes VS Code ein), oder im eigenen VS Code:'
  Say '    Remote-SSH → clawbook → Ordner /home/student/source'
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
  Show-PackStatus
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

# --- VSCodePack ------------------------------------------------------------
function Enable-Tls12 {
  # Windows PowerShell 5.1 may still default to older TLS versions.
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  } catch { $null = $_ }
}

function Get-CourseId {
  # Course id remembered in kurs.txt; "clawbook" means: no course.
  $id = ''
  if (Test-Path -LiteralPath $CourseFile) { $id = ([IO.File]::ReadAllText($CourseFile)).Trim() }
  if ($id -notmatch '^[a-z0-9][a-z0-9-]{0,63}$') { $id = $DefaultCourse }
  return $id
}

function Set-CourseId([string]$Id) {
  [IO.File]::WriteAllText($CourseFile, "$Id`r`n", $Utf8NoBom)
}

function Get-CourseDir([string]$Id) { return (Join-Path $PackRoot $Id) }

function Get-CourseJsonFromWeb([string]$Id) {
  # Course description from the product repository on GitHub.
  Enable-Tls12
  $uri = "$CourseWebBase/$Id.json"
  Log "Kursbeschreibung laden: $uri"
  $prev = $ProgressPreference; $ProgressPreference = 'SilentlyContinue'
  try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 30 -Uri $uri }
  finally { $ProgressPreference = $prev }
  return [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
}

# Sources for the course description, tried in order; each returns the JSON
# text or throws. Later a source reading the course package inside the
# container (/usr/share/clawbook/kurse/<id>/vscode.json) goes in front.
$CourseSources = @(
  @{ Name = 'GitHub'; Get = { param($Id) Get-CourseJsonFromWeb $Id } }
)

function ConvertFrom-CourseJson([string]$Text, [string]$Id) {
  # Parses and checks a course description (format 1); returns a hashtable.
  try { $d = $Text.TrimStart([char]0xFEFF) | ConvertFrom-Json }
  catch { Fail ('Die Kursbeschreibung für „{0}“ ist fehlerhaft (kein gültiges JSON).' -f $Id) }
  if ("$($d.format)" -ne '1') {
    Fail ('Die Kursbeschreibung für „{0}“ hat das Format {1}; dieses Skript kennt nur Format 1. Hole dir das neueste Skript mit dem Befehl von der Startseite.' -f $Id, $d.format)
  }
  if ("$($d.kennung)" -ne $Id) { Fail ('Die Kursbeschreibung passt nicht zur Kennung „{0}“ (sie nennt „{1}“).' -f $Id, $d.kennung) }
  $folder = "$($d.ordner)"
  if ($folder -notmatch '^/[A-Za-z0-9._/-]*$') { $folder = $DefaultFolder }
  $win = @(); $cont = @()
  if ($d.windows) { $win = @($d.windows.erweiterungen | Where-Object { $_ } | ForEach-Object { "$_" }) }
  if ($d.container) { $cont = @($d.container.erweiterungen | Where-Object { $_ } | ForEach-Object { "$_" }) }
  # Extension ids end up on a cmd.exe command line: allow only plain ids.
  foreach ($e in @($win + $cont)) {
    if ($e -notmatch '^[A-Za-z0-9][A-Za-z0-9-]*\.[A-Za-z0-9][A-Za-z0-9.-]*(@[A-Za-z0-9.-]+)?$') {
      Fail ('Die Kursbeschreibung für „{0}“ enthält eine ungültige Erweiterung: {1}' -f $Id, $e)
    }
  }
  $settings = [ordered]@{}
  if ($d.einstellungen) { foreach ($p in $d.einstellungen.PSObject.Properties) { $settings[$p.Name] = $p.Value } }
  $title = if ($d.titel) { "$($d.titel)" } else { $Id }
  return @{ Id = $Id; Title = $title; Folder = $folder; Windows = $win; Container = $cont; Settings = $settings }
}

function Read-CourseDescription([string]$Id, [switch]$PreferCache) {
  # Loads the course description from the first source that answers and
  # keeps a copy next to the pack; falls back to that copy when offline.
  # $null if neither works.
  $cache = Join-Path (Get-CourseDir $Id) 'vscode.json'
  $hasCache = Test-Path -LiteralPath $cache
  if ($PreferCache -and $hasCache) { return (ConvertFrom-CourseJson ([IO.File]::ReadAllText($cache)) $Id) }
  $text = $null
  foreach ($src in $CourseSources) {
    try {
      $text = & $src.Get $Id
      if ($text) { Log "Kursbeschreibung aus Quelle $($src.Name)"; break }
    } catch { Log ("Kursbeschreibung aus {0} nicht ladbar: {1}" -f $src.Name, $_.Exception.Message) }
  }
  if ($text) {
    $course = ConvertFrom-CourseJson $text $Id
    New-Item -ItemType Directory -Force -Path (Get-CourseDir $Id) | Out-Null
    [IO.File]::WriteAllText($cache, $text, $Utf8NoBom)
    return $course
  }
  if ($hasCache) {
    Say 'Die Kursbeschreibung ließ sich gerade nicht laden; ich nehme die zuletzt gespeicherte.' 'Yellow'
    return (ConvertFrom-CourseJson ([IO.File]::ReadAllText($cache)) $Id)
  }
  return $null
}

function Get-PackVersions([string]$Id) {
  # Installed packs (folders vscode-<version> with Code.exe), newest first.
  $dir = Get-CourseDir $Id
  if (-not (Test-Path -LiteralPath $dir)) { return @() }
  $list = foreach ($f in @(Get-ChildItem -LiteralPath $dir -Directory)) {
    if ($f.Name -match '^vscode-(\d+\.\d+\.\d+)$' -and (Test-Path -LiteralPath (Join-Path $f.FullName 'Code.exe'))) {
      [pscustomobject]@{ Version = [version]$Matches[1]; Path = $f.FullName }
    }
  }
  return @($list | Sort-Object Version -Descending)
}

function Get-LatestVsCode([int]$TimeoutSec = 30, [switch]$NoFallback) {
  # Newest stable Windows ZIP from Microsoft: @{ Version; Url; Sha256 }
  # (Sha256 empty when only the fallback answered); $null if unreachable.
  Enable-Tls12
  try {
    $j = Invoke-RestMethod -UseBasicParsing -TimeoutSec $TimeoutSec -Uri $VsCodeApi
    if ("$($j.productVersion)" -match '^\d+\.\d+\.\d+$' -and "$($j.url)" -match '^https://') {
      Log ("VS Code neueste Version {0}: {1} sha256 {2}" -f $j.productVersion, $j.url, $j.sha256hash)
      return @{ Version = "$($j.productVersion)"; Url = "$($j.url)"; Sha256 = "$($j.sha256hash)" }
    }
    Log "Update-Schnittstelle: unerwartete Antwort"
  } catch { Log ("Update-Schnittstelle nicht erreichbar: {0}" -f $_.Exception.Message) }
  if ($NoFallback) { return $null }
  # Fallback (documented link): it redirects to the versioned file name.
  $loc = ''
  try {
    $req = [Net.HttpWebRequest]::Create($VsCodeLatest)
    $req.Method = 'HEAD'
    $req.AllowAutoRedirect = $false
    $req.Timeout = $TimeoutSec * 1000
    $resp = $req.GetResponse()
    try { $loc = "$($resp.Headers['Location'])" } finally { $resp.Close() }
  } catch [Net.WebException] {
    if ($_.Exception.Response) { $loc = "$($_.Exception.Response.Headers['Location'])" }
    else { Log ("Download-Link nicht erreichbar: {0}" -f $_.Exception.Message) }
  } catch { Log ("Download-Link nicht erreichbar: {0}" -f $_.Exception.Message) }
  if ($loc -match '^https://' -and $loc -match 'VSCode-win32-x64-(\d+\.\d+\.\d+)\.zip$') {
    Log "VS Code neueste Version $($Matches[1]) (Rückfall über Weiterleitung): $loc"
    return @{ Version = $Matches[1]; Url = $loc; Sha256 = '' }
  }
  return $null
}

function Test-PackRunning([string]$Id) {
  # True if a Code.exe from this course's pack folder is running.
  $dir = Get-CourseDir $Id
  $p = @(Get-Process -Name Code -ErrorAction SilentlyContinue |
      Where-Object { $_.Path -and $_.Path.StartsWith($dir, [StringComparison]::OrdinalIgnoreCase) })
  return ($p.Count -gt 0)
}

function Save-Download($Url, $Target) {
  # curl.exe (part of Windows 10/11) shows a progress bar; without it
  # Invoke-WebRequest runs without its bar, which slows 5.1 down a lot.
  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if ($curl) {
    $code = Invoke-Visible $curl.Source @('-L', '--fail', '--retry', '3', '--progress-bar', '-o', $Target, $Url)
    return ($code -eq 0)
  }
  Enable-Tls12
  Say 'Lade ohne Fortschrittsanzeige – bitte warten ...'
  $prev = $ProgressPreference; $ProgressPreference = 'SilentlyContinue'
  try { Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Target; return $true }
  catch { Log ("Download fehlgeschlagen: {0}" -f $_.Exception.Message); return $false }
  finally { $ProgressPreference = $prev }
}

function Test-MicrosoftSignature($File) {
  # Valid Authenticode signature issued to Microsoft Corporation?
  if (-not (Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue)) {
    Log 'Get-AuthenticodeSignature fehlt'
    return $false
  }
  $sig = Get-AuthenticodeSignature -LiteralPath $File
  $subject = if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { '' }
  Log ("Signatur {0}: {1} / {2}" -f $File, $sig.Status, $subject)
  return ("$($sig.Status)" -eq 'Valid' -and $subject -match '(^|,\s*)O=Microsoft Corporation(,|$)')
}

function Move-PackData($Target, $Previous) {
  # Portable mode: all settings and extensions live in data\. It moves to
  # the new version; the old version stays as a fallback without it.
  $newData = Join-Path $Target 'data'
  if (Test-Path -LiteralPath $newData) { return }
  $oldData = if ($Previous) { Join-Path $Previous 'data' } else { '' }
  if ($oldData -and (Test-Path -LiteralPath $oldData)) {
    try { Move-Item -LiteralPath $oldData -Destination $newData }
    catch {
      Log ("data verschieben: {0}" -f $_.Exception.Message)
      Fail "Deine VS-Code-Daten ließen sich nicht übernehmen (läuft VS Code noch?). Sie liegen unverändert in $oldData. Schließe alle VS-Code-Fenster und versuche es dann erneut."
    }
    Say 'Deine Erweiterungen und Einstellungen sind in die neue Version umgezogen.'
  } else {
    New-Item -ItemType Directory -Force -Path $newData | Out-Null
  }
}

function Remove-OldPacks([string]$Id) {
  # Keeps the newest version and one older as fallback; removes the rest
  # and leftovers of interrupted runs.
  $dir = Get-CourseDir $Id
  foreach ($t in @(Get-ChildItem -LiteralPath $dir -Directory | Where-Object { $_.Name -like 'vscode-*.tmp' })) {
    Remove-Item -Recurse -Force -LiteralPath $t.FullName -ErrorAction SilentlyContinue
  }
  $all = @(Get-ChildItem -LiteralPath $dir -Directory | Where-Object { $_.Name -match '^vscode-\d+\.\d+\.\d+$' } |
      Sort-Object { [version]($_.Name -replace '^vscode-', '') } -Descending)
  foreach ($old in @($all | Select-Object -Skip 2)) {
    Say "Lösche die alte Version $($old.Name) ..."
    try { Remove-Item -Recurse -Force -LiteralPath $old.FullName }
    catch {
      Log ("Löschen {0}: {1}" -f $old.FullName, $_.Exception.Message)
      Say "Die alte Version $($old.Name) ließ sich nicht ganz löschen. Das ist nicht schlimm; beim nächsten Aktualisieren versuche ich es wieder." 'Yellow'
    }
  }
}

function Invoke-PackCli($Cmd, [string[]]$ArgList) {
  # Runs the pack's bin\code.cmd (never "code" from PATH); returns @{ Code; Out }.
  $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  $out = & $Cmd @ArgList 2>&1 | ForEach-Object { "$_" } | Out-String
  $code = $LASTEXITCODE
  $ErrorActionPreference = $prev
  Log ("{0} {1} -> {2}`n{3}" -f $Cmd, ($ArgList -join ' '), $code, $out.Trim())
  return @{ Code = $code; Out = $out.Trim() }
}

function Install-PackExtensions($Pack, [string[]]$Ids) {
  # Installs or updates the Windows-side extensions; returns the number of failures.
  $cmd = Join-Path $Pack 'bin\code.cmd'
  $failed = 0
  foreach ($e in @($Ids)) {
    Say "Installiere oder aktualisiere die Erweiterung $e ..."
    $r = Invoke-PackCli $cmd @('--install-extension', $e, '--force')
    if ($r.Out) { Write-Host $r.Out -ForegroundColor DarkGray }
    if ($r.Code -ne 0) {
      Say "Die Erweiterung $e ließ sich nicht installieren. Einzelheiten stehen im Protokoll." 'Yellow'
      $failed++
    }
  }
  return $failed
}

function Skip-JsoncSpace([string]$T, [int]$i) {
  # Skips whitespace and comments; returns the next index, -1 for an open /* comment.
  while ($i -lt $T.Length) {
    $c = $T[$i]
    if ([char]::IsWhiteSpace($c)) { $i++; continue }
    if ($c -eq '/' -and $i + 1 -lt $T.Length) {
      if ($T[$i + 1] -eq '/') {
        $n = $T.IndexOf("`n", $i)
        if ($n -lt 0) { return $T.Length }
        $i = $n + 1; continue
      }
      if ($T[$i + 1] -eq '*') {
        $n = $T.IndexOf('*/', $i + 2)
        if ($n -lt 0) { return -1 }
        $i = $n + 2; continue
      }
    }
    break
  }
  return $i
}

function Skip-JsoncString([string]$T, [int]$i) {
  # $i points at the opening quote; returns the index after the closing one, -1 if open.
  $i++
  while ($i -lt $T.Length) {
    $c = $T[$i]
    if ($c -eq '\') { $i += 2; continue }
    if ($c -eq '"') { return $i + 1 }
    $i++
  }
  return -1
}

function Skip-JsoncValue([string]$T, [int]$i) {
  # Returns the index after the value starting at $i, -1 on a syntax error.
  if ($i -ge $T.Length) { return -1 }
  $c = $T[$i]
  if ($c -eq '"') { return (Skip-JsoncString $T $i) }
  if ($c -eq '{' -or $c -eq '[') {
    $depth = 0
    while ($i -lt $T.Length) {
      $c = $T[$i]
      if ($c -eq '"') {
        $i = Skip-JsoncString $T $i
        if ($i -lt 0) { return -1 }
        continue
      }
      if ($c -eq '/') {
        $j = Skip-JsoncSpace $T $i
        if ($j -lt 0) { return -1 }
        if ($j -gt $i) { $i = $j; continue }
      }
      if ($c -eq '{' -or $c -eq '[') { $depth++ }
      elseif ($c -eq '}' -or $c -eq ']') {
        $depth--
        if ($depth -eq 0) { return $i + 1 }
      }
      $i++
    }
    return -1
  }
  $start = $i
  while ($i -lt $T.Length -and "$($T[$i])" -match '[A-Za-z0-9.+-]') { $i++ }
  if ($i -eq $start) { return -1 }
  return $i
}

function Get-JsoncMembers([string]$T) {
  # Top-level members of a JSON object that may contain comments and
  # trailing commas (settings.json). Returns @{ Members = @(@{ Key;
  # KeyStart; Start; End }); Close = index of the final brace; NeedComma },
  # or $null if the text is not such an object.
  $i = Skip-JsoncSpace $T 0
  if ($i -lt 0 -or $i -ge $T.Length -or $T[$i] -ne '{') { return $null }
  $i++
  $members = New-Object Collections.ArrayList
  $needComma = $false
  while ($true) {
    $i = Skip-JsoncSpace $T $i
    if ($i -lt 0 -or $i -ge $T.Length) { return $null }
    $c = $T[$i]
    if ($c -eq '}') {
      if ((Skip-JsoncSpace $T ($i + 1)) -ne $T.Length) { return $null }
      return @{ Members = $members.ToArray(); Close = $i; NeedComma = $needComma }
    }
    if ($c -eq ',') { $needComma = $false; $i++; continue }
    if ($c -ne '"') { return $null }
    $keyEnd = Skip-JsoncString $T $i
    if ($keyEnd -lt 0) { return $null }
    $key = $T.Substring($i + 1, $keyEnd - $i - 2)
    $keyStart = $i
    $i = Skip-JsoncSpace $T $keyEnd
    if ($i -lt 0 -or $i -ge $T.Length -or $T[$i] -ne ':') { return $null }
    $vs = Skip-JsoncSpace $T ($i + 1)
    if ($vs -lt 0) { return $null }
    $ve = Skip-JsoncValue $T $vs
    if ($ve -lt 0) { return $null }
    [void]$members.Add(@{ Key = $key; KeyStart = $keyStart; Start = $vs; End = $ve })
    $needComma = $true
    $i = $ve
  }
}

function ConvertTo-JsonValue($Value) {
  if ($null -eq $Value) { return 'null' }
  if ($Value -is [bool]) { if ($Value) { return 'true' } else { return 'false' } }
  return (ConvertTo-Json -InputObject $Value -Depth 10 -Compress)
}

function Set-JsoncValues([string]$Text, $Values) {
  # Sets the given top-level keys in a settings.json text and leaves all
  # other content (other settings, comments, layout) as it is. $null if
  # the text cannot be read as an object.
  if ("$Text".Trim() -eq '') { $Text = '{}' }
  $doc = Get-JsoncMembers $Text
  if ($null -eq $doc) { return $null }
  $nl = if ($Text.Contains("`r`n")) { "`r`n" } else { "`n" }
  $indent = "`t"
  if ($doc.Members.Count -gt 0) {
    $ks = $doc.Members[0].KeyStart
    $ls = $Text.LastIndexOf("`n", [Math]::Max($ks - 1, 0)) + 1
    $lead = $Text.Substring($ls, $ks - $ls)
    if ($lead -match '^[ \t]+$') { $indent = $lead }
  }
  $edits = New-Object Collections.ArrayList
  $missing = New-Object Collections.ArrayList
  foreach ($k in @($Values.Keys)) {
    $json = ConvertTo-JsonValue $Values[$k]
    $hits = @($doc.Members | Where-Object { $_.Key -ceq $k })
    if ($hits.Count -gt 0) {
      foreach ($h in $hits) { [void]$edits.Add(@{ Pos = $h.Start; Len = $h.End - $h.Start; Text = $json }) }
    } else {
      [void]$missing.Add(('{0}{1}: {2}' -f $indent, (ConvertTo-Json -InputObject ([string]$k) -Compress), $json))
    }
  }
  if ($missing.Count -gt 0) {
    if ($doc.NeedComma) { [void]$edits.Add(@{ Pos = $doc.Members[-1].End; Len = 0; Text = ',' }) }
    $pos = $doc.Close
    $j = $pos - 1
    while ($j -ge 0 -and ($Text[$j] -eq ' ' -or $Text[$j] -eq "`t")) { $j-- }
    $body = ($missing -join (',' + $nl)) + $nl
    if ($j -ge 0 -and $Text[$j] -eq "`n") { $pos = $j + 1 } else { $body = $nl + $body }
    [void]$edits.Add(@{ Pos = $pos; Len = 0; Text = $body })
  }
  foreach ($e in @($edits | Sort-Object { $_.Pos } -Descending)) {
    $Text = $Text.Remove($e.Pos, $e.Len).Insert($e.Pos, $e.Text)
  }
  return $Text
}

function Set-PackSettings($Pack, $Course) {
  # Writes the course settings and remote.SSH.defaultExtensions into the
  # pack's settings.json; the student's own settings stay untouched.
  $userDir = Join-Path $Pack 'data\user-data\User'
  New-Item -ItemType Directory -Force -Path $userDir | Out-Null
  $file = Join-Path $userDir 'settings.json'
  $values = [ordered]@{}
  foreach ($k in @($Course.Settings.Keys)) { $values[$k] = $Course.Settings[$k] }
  $values['remote.SSH.defaultExtensions'] = [object[]]@($Course.Container)
  $text = if (Test-Path -LiteralPath $file) { [IO.File]::ReadAllText($file) } else { '' }
  $new = Set-JsoncValues $text $values
  if ($null -eq $new) {
    $bak = '{0}.{1}.bak' -f $file, (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item -LiteralPath $file -Destination $bak
    Say "Deine settings.json ließ sich nicht lesen. Ich habe sie nach $bak gesichert und neu angelegt." 'Yellow'
    $new = Set-JsoncValues '' $values
  }
  if ($new -ne $text) { [IO.File]::WriteAllText($file, $new, $Utf8NoBom) }
  Log "settings.json gesetzt: $(@($values.Keys) -join ', ')"
}

function Set-PackShortcut($Pack) {
  # Start menu entry of the current user; no administrator rights needed.
  # It runs this script with -Action vscode, so the container starts first.
  # Normal window: questions and error messages stay visible.
  try {
    $dir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $script = Join-Path $AppDir 'clawbook.ps1'
    $sc = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $dir $ShortcutName))
    $sc.TargetPath = $ps
    $sc.Arguments = ConvertTo-ArgumentString @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script, '-Action', 'vscode')
    $sc.WorkingDirectory = $AppDir
    $sc.WindowStyle = 1
    $sc.IconLocation = (Join-Path $Pack 'Code.exe') + ',0'
    $sc.Description = 'clawbook starten und VS Code (VSCodePack) verbinden'
    $sc.Save()
    Say 'Verknüpfung „clawbook VS Code“ im Startmenü angelegt. Sie startet zuerst den Container und dann VS Code.' 'Green'
  } catch {
    Log ("Verknüpfung: {0}" -f $_.Exception.Message)
    Say 'Die Verknüpfung im Startmenü ließ sich nicht anlegen. Starte VS Code dann über Menüpunkt [9].' 'Yellow'
  }
}

function Install-VsCodePack {
  # Menu [10] and -Action vscode-install.
  $id = Get-CourseId
  $course = Read-CourseDescription $id
  if (-not $course) { Fail ('Die Kursbeschreibung für „{0}“ ließ sich nicht laden. Prüfe deine Internetverbindung und versuche es dann erneut.' -f $id) }
  Set-CourseId $id
  Say ("VSCodePack für: {0} (Kennung {1})" -f $course.Title, $id) 'Cyan'
  $dir = Get-CourseDir $id
  New-Item -ItemType Directory -Force -Path $dir | Out-Null

  Say 'Prüfe bei Microsoft, welche VS-Code-Version die neueste ist ...'
  $latest = Get-LatestVsCode
  if (-not $latest) { Fail 'Ich konnte bei Microsoft nicht nachsehen, welche VS-Code-Version die neueste ist. Prüfe deine Internetverbindung und versuche es dann erneut.' }
  $installed = @(Get-PackVersions $id)
  $target = Join-Path $dir ("vscode-{0}" -f $latest.Version)
  $previous = @($installed | Where-Object { $_.Path -ne $target } | Select-Object -First 1)
  $prevPath = if ($previous.Count -gt 0) { $previous[0].Path } else { '' }

  if (Test-Path -LiteralPath (Join-Path $target 'Code.exe')) {
    Say ("VS Code {0} ist schon installiert und aktuell. Ich gleiche nur Erweiterungen und Einstellungen ab." -f $latest.Version) 'Green'
  } else {
    if (Test-PackRunning $id) { Fail 'VS Code aus dem VSCodePack läuft noch. Schließe alle VS-Code-Fenster und versuche es dann erneut.' }
    Remove-OldPacks $id
    $free = Get-FreeBytes $dir
    if ($free -ge 0 -and $free -lt 1GB) {
      Fail ("Zu wenig Platz in {0}: VS Code braucht etwa 1 GB, frei sind {1:N1} GB. Schaffe Platz und versuche es dann erneut." -f $dir, ($free / 1GB))
    }
    $zip = Join-Path $dir ("VSCode-win32-x64-{0}.zip" -f $latest.Version)
    $tmp = "$target.tmp"
    Remove-Item -Force -LiteralPath $zip -ErrorAction SilentlyContinue

    if ($prevPath) { Say ("Installiert ist VS Code {0}; neu ist {1}." -f $installed[0].Version, $latest.Version) }
    Say ("[1/4] Lade VS Code {0} direkt bei Microsoft (etwa 150 MB)." -f $latest.Version) 'Cyan'
    Say 'Das dauert je nach Verbindung ein bis zehn Minuten – bitte nicht abbrechen und das Fenster offen lassen.' 'Cyan'
    if (-not (Save-Download $latest.Url $zip) -or -not (Test-Path -LiteralPath $zip)) {
      Remove-Item -Force -LiteralPath $zip -ErrorAction SilentlyContinue
      Fail 'Der Download von VS Code ist fehlgeschlagen. Prüfe deine Internetverbindung und versuche es dann erneut.'
    }

    Say '[2/4] Prüfe die heruntergeladene Datei ...' 'Cyan'
    if ($latest.Sha256) {
      $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash
      if ($hash -ne $latest.Sha256) {
        Log "SHA-256 erwartet $($latest.Sha256), erhalten $hash"
        Remove-Item -Force -LiteralPath $zip -ErrorAction SilentlyContinue
        Fail 'Die heruntergeladene Datei ist beschädigt (die Prüfsumme stimmt nicht). Ich habe sie gelöscht. Versuche es erneut.'
      }
    } else {
      Log 'Keine Prüfsumme verfügbar (Rückfall-Weg); es bleibt die Signaturprüfung.'
    }

    Say '[3/4] Entpacke VS Code. Das dauert ein bis drei Minuten ...' 'Cyan'
    $prev = $ProgressPreference; $ProgressPreference = 'SilentlyContinue'
    try { Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force }
    catch {
      Log ("Entpacken: {0}" -f $_.Exception.Message)
      Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
      Fail 'Das Entpacken von VS Code ist fehlgeschlagen. Einzelheiten stehen im Protokoll.'
    } finally {
      $ProgressPreference = $prev
      Remove-Item -Force -LiteralPath $zip -ErrorAction SilentlyContinue
    }
    $exe = Join-Path $tmp 'Code.exe'
    if (-not (Test-Path -LiteralPath $exe) -or -not (Test-MicrosoftSignature $exe)) {
      Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
      Fail 'Code.exe trägt keine gültige Signatur von Microsoft. Ich habe die entpackten Dateien wieder gelöscht. Versuche es später erneut.'
    }
    Rename-Item -LiteralPath $tmp -NewName (Split-Path -Leaf $target)
    Say '[4/4] Richte VS Code ein ...' 'Cyan'
  }

  if (Test-PackRunning $id) {
    Say 'Hinweis: VS Code aus dem VSCodePack läuft gerade. Neue Einstellungen wirken nach einem Neustart von VS Code.' 'Yellow'
  }
  Move-PackData $target $prevPath
  $failed = Install-PackExtensions $target $course.Windows
  Set-PackSettings $target $course
  Remove-OldPacks $id
  Set-PackShortcut $target
  if ($failed -gt 0) {
    Say 'Nicht alle Erweiterungen ließen sich installieren. Wähle später noch einmal Menüpunkt [10].' 'Yellow'
  }
  Say ("VSCodePack bereit: VS Code {0} in {1}" -f $latest.Version, $target) 'Green'
  Say 'Starten mit Menüpunkt [9] oder über „clawbook VS Code“ im Startmenü.' 'Green'
}

function Start-VsCodePack {
  # Menu [9] and -Action vscode: container first, then the newest pack.
  $id = Get-CourseId
  if (-not (Get-State).Running) {
    Say 'Der Container läuft nicht – ich starte ihn zuerst.' 'Yellow'
    Start-Clawbook
  } elseif (-not (Test-Path -LiteralPath $KeyFile)) {
    Set-Ssh
  }
  $packs = @(Get-PackVersions $id)
  if ($packs.Count -eq 0) {
    Say 'Das VSCodePack (ein eigenes VS Code für clawbook) ist noch nicht installiert.' 'Yellow'
    if (-not (Read-YesNo 'Jetzt installieren? Dafür lädt das Skript VS Code (etwa 150 MB) direkt bei Microsoft. [J/n]' $true)) {
      Say 'Abgebrochen.'
      return
    }
    Install-VsCodePack
    $packs = @(Get-PackVersions $id)
    if ($packs.Count -eq 0) { Fail 'Das VSCodePack ist nach der Installation nicht zu finden.' }
  }
  $course = Read-CourseDescription $id -PreferCache
  $folder = if ($course) { $course.Folder } else { $DefaultFolder }
  $exe = Join-Path $packs[0].Path 'Code.exe'
  $argLine = ConvertTo-ArgumentString @('--remote', 'ssh-remote+clawbook', $folder)
  Say ("Starte VS Code {0} und verbinde es mit clawbook (Ordner {1}) ..." -f $packs[0].Version, $folder) 'Cyan'
  Log "$exe $argLine"
  Start-Process -FilePath $exe -ArgumentList $argLine -WorkingDirectory $packs[0].Path | Out-Null
  Say 'VS Code öffnet sich in einem eigenen Fenster. Beim ersten Verbinden richtet es sich im Container ein; das dauert ein bis zwei Minuten.' 'Green'
}

function Show-PackStatus {
  $id = Get-CourseId
  $packs = @(Get-PackVersions $id)
  Say ("VSCodePack:         Kennung {0}" -f $id)
  if ($packs.Count -gt 0) {
    Say ("VS Code im Pack:    {0} ({1})" -f $packs[0].Version, $packs[0].Path)
  } else {
    Say 'VS Code im Pack:    noch nicht installiert (Menüpunkt [10])'
  }
  # Only if Microsoft answers quickly; otherwise the line is left out.
  $latest = Get-LatestVsCode -TimeoutSec 3 -NoFallback
  if ($latest) {
    $hint = ''
    if ($packs.Count -gt 0 -and [version]$latest.Version -gt $packs[0].Version) { $hint = ' – aktualisieren mit Menüpunkt [10]' }
    Say ("Neuestes VS Code:  {0}{1}" -f $latest.Version, $hint)
  }
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
      Say '  [9] VS Code starten und verbinden (VSCodePack)'
      Say ' [10] VSCodePack installieren oder aktualisieren'
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
        '9' { Start-VsCodePack; return }
        '10' {
          Install-VsCodePack
          if (Read-YesNo 'VS Code jetzt starten und mit clawbook verbinden? [J/n]' $true) { Start-VsCodePack }
          return
        }
        '0' { return }
        default { Say 'Bitte eine Zahl aus dem Menü eingeben.' 'Yellow' }
      }
    }
  }
}

# --- Main --------------------------------------------------------------
Log "=== clawbook.ps1 Action='$Action' Image='$Image' Ref='$Ref'"
if ($Ref -notmatch '^[A-Za-z0-9._/-]+$') { Fail "CLAWBOOK_REF enthält unzulässige Zeichen: $Ref" }
Say "Protokoll: $LogFile" 'DarkGray'
try {
  # Installing the VSCodePack needs neither WSL nor the container.
  if ($Action -ne 'vscode-install') { Test-Wslc }
  switch ($Action) {
    'start' { Start-Clawbook }
    'update' { Update-Clawbook }
    'export' { $null = Export-Home $File }
    'import' { Import-Home $File }
    'ssh' { Update-Ssh }
    'status' { Show-Status }
    'stop' { Stop-Clawbook }
    'reset' { Reset-Clawbook }
    'vscode' { Start-VsCodePack }
    'vscode-install' { Install-VsCodePack }
    default { Show-Menu }
  }
} catch {
  Fail ("Unerwarteter Fehler: {0}" -f $_.Exception.Message)
}
