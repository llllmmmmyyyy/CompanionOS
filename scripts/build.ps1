param([switch]$RunChecks, [switch]$Clean, [string]$ProjectDirectory = '', [ValidateSet('entry', 'tventry')][string]$Module = 'entry')
$ErrorActionPreference = 'Stop'
if ($ProjectDirectory) { $projectRoot = (Resolve-Path -LiteralPath $ProjectDirectory).Path }
elseif ($PSScriptRoot) { $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path }
else { $projectRoot = (Get-Location).Path }
$scriptRoot = Join-Path $projectRoot 'scripts'
$registryRoots = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
$studioRoot = $null
foreach ($registryRoot in $registryRoots) {
  $entries = Get-ItemProperty "$registryRoot\*" -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like '*DevEco*' -and $_.InstallLocation }
  foreach ($entry in $entries) {
    $infoPath = Join-Path $entry.InstallLocation 'product-info.json'
    if (Test-Path -LiteralPath $infoPath) {
      $info = Get-Content -LiteralPath $infoPath -Raw | ConvertFrom-Json
      if ($info.name -eq 'DevEco Studio') { $studioRoot = $entry.InstallLocation; break }
    }
  }
  if ($studioRoot) { break }
}
if (-not $studioRoot) { throw 'DevEco Studio was not found through the Windows registry.' }
$node = Join-Path $studioRoot 'tools\node\node.exe'
$hvigor = Join-Path $studioRoot 'tools\hvigor\bin\hvigorw.js'
$sdk = Join-Path $studioRoot 'sdk'
$compiler = Join-Path $sdk 'default\openharmony\ets\build-tools\ets-loader\node_modules\typescript\lib\typescript.js'
foreach ($tool in @($node, $hvigor, (Join-Path $studioRoot 'jbr\bin\java.exe'))) {
  if (-not (Test-Path -LiteralPath $tool)) { throw "Required DevEco tool is missing: $tool" }
}
$originalPath = $env:Path
$originalJava = $env:JAVA_HOME
$originalSdk = $env:DEVECO_SDK_HOME
$artifactRoot = Join-Path $projectRoot 'artifacts'
New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null
Push-Location $projectRoot
try {
  # These changes apply only to this process. Persistent user/machine PATH is untouched.
  $env:JAVA_HOME = Join-Path $studioRoot 'jbr'
  $env:DEVECO_SDK_HOME = $sdk
  $env:Path = "$(Join-Path $studioRoot 'jbr\bin');$(Join-Path $studioRoot 'tools\node');$(Join-Path $studioRoot 'tools\ohpm\bin');$originalPath"
  # Windows PowerShell represents native stderr warnings as ErrorRecords; use the actual exit code.
  $ErrorActionPreference = 'Continue'
  $product = if ($Module -eq 'tventry') { 'tablet' } else { 'default' }
  [string[]]$buildTasks = @('assembleHap')
  if ($Clean) { $buildTasks = @('clean', 'assembleHap') }
  & $node $hvigor --mode module -p "product=$product" -p "module=$Module@default" -p buildMode=debug @buildTasks --no-daemon 2>&1 |
    Tee-Object -FilePath (Join-Path $artifactRoot "build-$Module.txt")
  $ErrorActionPreference = 'Stop'
  if ($LASTEXITCODE -ne 0) { throw "HAP build failed with exit code $LASTEXITCODE" }
  if ($RunChecks) {
    & $node (Join-Path $scriptRoot 'test-domain.cjs') $compiler |
      Tee-Object -FilePath (Join-Path $artifactRoot 'tests.txt')
    if ($LASTEXITCODE -ne 0) { throw 'Domain checks failed' }
    & $node (Join-Path $scriptRoot 'test-work.cjs') $compiler |
      Tee-Object -FilePath (Join-Path $artifactRoot 'tests.txt') -Append
    if ($LASTEXITCODE -ne 0) { throw 'Work-session checks failed' }
    & $node (Join-Path $scriptRoot 'test-parent-summary.cjs') $compiler |
      Tee-Object -FilePath (Join-Path $artifactRoot 'tests.txt') -Append
    if ($LASTEXITCODE -ne 0) { throw 'Parent summary checks failed' }
    & $node (Join-Path $scriptRoot 'test-games.cjs') $compiler |
      Tee-Object -FilePath (Join-Path $artifactRoot 'tests.txt') -Append
    if ($LASTEXITCODE -ne 0) { throw 'Interactive game checks failed' }
    & $node (Join-Path $scriptRoot 'test-world.cjs') $compiler |
      Tee-Object -FilePath (Join-Path $artifactRoot 'tests.txt') -Append
    if ($LASTEXITCODE -ne 0) { throw 'Tablet world checks failed' }
    & $node (Join-Path $scriptRoot 'test-services.cjs') $compiler |
      Tee-Object -FilePath (Join-Path $artifactRoot 'tests.txt') -Append
    if ($LASTEXITCODE -ne 0) { throw 'Mocked-service checks failed' }
    & $node (Join-Path $scriptRoot 'test-tv.cjs') $compiler |
      Tee-Object -FilePath (Join-Path $artifactRoot 'tests.txt') -Append
    if ($LASTEXITCODE -ne 0) { throw 'TV/AI host checks failed' }
    & $node (Join-Path $scriptRoot 'test-emulator.cjs') $compiler |
      Tee-Object -FilePath (Join-Path $artifactRoot 'tests.txt') -Append
    if ($LASTEXITCODE -ne 0) { throw 'Emulator protocol/client checks failed' }
  }
  $hap = Join-Path $projectRoot "$Module\build\$product\outputs\default\$Module-default-unsigned.hap"
  if (-not (Test-Path -LiteralPath $hap)) { throw 'Expected unsigned HAP was not produced.' }
  Write-Output "Unsigned HAP: $hap"
  Get-FileHash -LiteralPath $hap -Algorithm SHA256
} finally {
  Pop-Location
  $env:Path = $originalPath
  $env:JAVA_HOME = $originalJava
  $env:DEVECO_SDK_HOME = $originalSdk
}
