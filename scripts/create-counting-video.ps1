param([string]$Ffmpeg = '')
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $Ffmpeg) { $Ffmpeg = Join-Path $projectRoot 'artifacts/media-tools/node_modules/@ffmpeg-installer/win32-x64/ffmpeg.exe' }
if (-not (Test-Path -LiteralPath $Ffmpeg)) { throw 'Supply -Ffmpeg with an installed ffmpeg executable. Normal builds use the committed video.' }
$frames = Join-Path $projectRoot 'artifacts/counting-frames'
New-Item -ItemType Directory -Path $frames -Force | Out-Null
Add-Type -AssemblyName System.Drawing
$green = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#559867'))
$dark = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#203C31'))
$font = [System.Drawing.Font]::new('Arial',42,[System.Drawing.FontStyle]::Bold)
$numberFont = [System.Drawing.Font]::new('Arial',84,[System.Drawing.FontStyle]::Bold)
try {
  foreach ($number in 1..5) {
    $bitmap = [System.Drawing.Bitmap]::new(1280,720); $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
      $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
      $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#E6F0E9'))
      $graphics.DrawString('Dino Counting Adventure',$font,$dark,180,38)
      $graphics.DrawString([string]$number,$numberFont,$dark,580,130)
      foreach ($index in 0..($number-1)) {
        $x=80+$index*230
        $graphics.FillEllipse($green,$x,370,150,110)
        $graphics.FillEllipse($green,$x+103,310,74,80)
        $graphics.FillEllipse($dark,$x+148,331,9,9)
        $graphics.FillRectangle($green,$x+26,447,24,57)
        $graphics.FillRectangle($green,$x+102,447,24,57)
        $graphics.FillPolygon($green,[System.Drawing.Point[]]@([System.Drawing.Point]::new($x+22,390),[System.Drawing.Point]::new($x-32,355),[System.Drawing.Point]::new($x,442)))
      }
      $graphics.DrawString(('Count together: '+$number+' dinosaurs.'),$font,$dark,245,565)
      $bitmap.Save((Join-Path $frames ('count-'+$number+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $graphics.Dispose(); $bitmap.Dispose() }
  }
} finally { $green.Dispose();$dark.Dispose();$font.Dispose();$numberFont.Dispose() }
$output = Join-Path $projectRoot 'entry/src/main/resources/rawfile/counting.mp4'
& $Ffmpeg -y -framerate 0.5 -i (Join-Path $frames 'count-%d.png') -r 15 -c:v libx264 -pix_fmt yuv420p -movflags +faststart $output
if ($LASTEXITCODE -ne 0) { throw 'Counting-video encoding failed' }
Copy-Item -LiteralPath $output -Destination (Join-Path $projectRoot 'tventry/src/main/resources/rawfile/counting.mp4')
Write-Output 'Original ten-second offline counting video created for both native apps.'
