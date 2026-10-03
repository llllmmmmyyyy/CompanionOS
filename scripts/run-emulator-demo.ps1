param([string]$Phone = '127.0.0.1:5555', [string]$Tv = '127.0.0.1:5557', [switch]$Build)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$studioRoot = $null
foreach ($registryRoot in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')) {
  $entry = Get-ItemProperty "$registryRoot\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like '*DevEco*' -and $_.InstallLocation } | Select-Object -First 1
  if ($entry) { $studioRoot = $entry.InstallLocation; break }
}
if (-not $studioRoot) { throw 'DevEco Studio installation was not found.' }
$hdc = Join-Path $studioRoot 'sdk\default\openharmony\toolchains\hdc.exe'
$node = (Get-Command node.exe).Source
if ([int]((& $node --version).TrimStart('v').Split('.')[0]) -lt 22) { throw 'Backend requires Node.js 22 or newer.' }
foreach ($device in @($Phone, $Tv)) {
  $api = (& $hdc -t $device shell param get const.ohos.apiversion).Trim()
  if ($LASTEXITCODE -ne 0 -or $api -notmatch '^\d+$') { throw "Cannot contact emulator $device" }
  $deviceType = (& $hdc -t $device shell param get const.product.devicetype).Trim()
  if ($device -eq $Phone -and ([int]$api -lt 21 -or $deviceType -eq 'tv')) { throw 'Phone must use API 21+ and must not be the TV target.' }
  if ($device -eq $Tv -and ([int]$api -lt 19 -or $deviceType -ne 'tv')) { throw 'TV target must be a TV device using API 19+.' }
}
Push-Location $projectRoot
try {
  if ($Build) { & (Join-Path $PSScriptRoot 'build.ps1') -RunChecks; & (Join-Path $PSScriptRoot 'build.ps1') -Module tventry }
  Push-Location backend
  try {
    if (-not (Test-Path node_modules/typescript)) { & npm.cmd ci; if ($LASTEXITCODE -ne 0) { throw 'Backend dependency installation failed' } }
    & npm.cmd run build; if ($LASTEXITCODE -ne 0) { throw 'Backend build failed' }
  } finally { Pop-Location }
  New-Item -ItemType Directory artifacts -Force | Out-Null
  $healthy = $false
  try { $healthy = (Invoke-RestMethod 'http://127.0.0.1:8787/health' -TimeoutSec 2).protocolVersion -eq 1 } catch {}
  if (-not $healthy) {
    $backendProcess = Start-Process -FilePath $node -ArgumentList '--env-file-if-exists=.env', 'dist/server.js' -WorkingDirectory (Join-Path $projectRoot 'backend') -WindowStyle Hidden -PassThru |
      Select-Object -First 1
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
      Start-Sleep -Milliseconds 250
      try { $healthy = (Invoke-RestMethod 'http://127.0.0.1:8787/health' -TimeoutSec 1).protocolVersion -eq 1 } catch {}
      if ($healthy) { break }
    }
    if (-not $healthy) { throw "Backend did not start. Inspect the console with npm start in backend. Process $($backendProcess.Id)." }
  }
  foreach ($device in @($Phone, $Tv)) {
    $tasks = (& $hdc -t $device fport ls) -join "`n"
    if ($tasks -match ([regex]::Escape($device) + '\s+tcp:18080 tcp:8787\s+\[Reverse\]')) {
      Write-Output "Reusing reverse forward for $device"
    } else {
      $forwardResult = (& $hdc -t $device rport tcp:18080 tcp:8787) -join "`n"
      if ($forwardResult -match 'TCP Port listen failed at 18080') {
        # HDC can omit the second device's same-port task from its global list even while its listener works.
        Write-Output "Port 18080 is already listening on $device. Reusing it; app connection must verify the route."
      } elseif ($forwardResult -notmatch 'Forwardport result:OK') { throw "Port forwarding failed for $device`: $forwardResult" }
    }
  }
  $tvHap = Join-Path $projectRoot 'tventry\build\tv\outputs\default\tventry-default-unsigned.hap'
  $phoneHap = Join-Path $projectRoot 'entry\build\default\outputs\default\entry-default-unsigned.hap'
  foreach ($hap in @($tvHap, $phoneHap)) { if (-not (Test-Path -LiteralPath $hap)) { throw "HAP missing: $hap. Run again with -Build." } }
  $tvInstall = (& $hdc -t $Tv install $tvHap) -join "`n"
  $phoneInstall = (& $hdc -t $Phone install $phoneHap) -join "`n"
  if ($tvInstall -notmatch 'install bundle successfully' -or $phoneInstall -notmatch 'install bundle successfully') { throw "Installation failed: $tvInstall $phoneInstall" }
  # HDC can print a failure while returning zero; require actual launch success below.
  $tvResult = & $hdc -t $Tv shell aa start -a TvAbility -b com.example.companionos
  $phoneResult = & $hdc -t $Phone shell aa start -a EntryAbility -b com.example.companionos
  if (($tvResult -join "`n") -notmatch 'start ability successfully' -or ($phoneResult -join "`n") -notmatch 'start ability successfully') { throw "Launch failed: $tvResult $phoneResult" }
  Write-Output 'Both applications launched. Phone: Play on TV > Connect to Emulator TV. Backend: http://127.0.0.1:18080, room: family-demo.'
} finally { Pop-Location }
