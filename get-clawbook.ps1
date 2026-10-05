# clawbook-lehre - entry point.
#
# Usage (PowerShell, no administrator rights needed):
#   irm https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/get-clawbook.ps1 | iex
#
# Downloads the current management script to %LOCALAPPDATA%\clawbook and
# starts it. Everything else is decided in its menu. Running the command
# again always fetches the newest version.
#
# Optional, for tests and power users (set before running the command):
#   $env:CLAWBOOK_ACTION = 'status'   # start|update|export|import|ssh|status|stop|reset
#   $env:CLAWBOOK_IMAGE  = 'ghcr.io/schlingensiepen/clawbook-lehre:v0.4.0-rc.1'

& {
  $ErrorActionPreference = 'Stop'
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  $base = 'https://raw.githubusercontent.com/schlingensiepen/clawbook-lehre/main/windows'
  $dir = Join-Path $env:LOCALAPPDATA 'clawbook'
  $target = Join-Path $dir 'clawbook.ps1'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null

  Write-Host 'clawbook: lade das Verwaltungs-Skript ...'
  $tmp = "$target.download"
  Invoke-WebRequest -UseBasicParsing -Uri "$base/clawbook.ps1" -OutFile $tmp
  Move-Item -Force $tmp $target

  # Process-scoped bypass: works without administrator rights and does not
  # change the machine's execution policy.
  $shell = (Get-Process -Id $PID).Path
  $params = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $target)
  if ($env:CLAWBOOK_ACTION) { $params += @('-Action', $env:CLAWBOOK_ACTION) }
  if ($env:CLAWBOOK_IMAGE) { $params += @('-Image', $env:CLAWBOOK_IMAGE) }
  & $shell @params
}
