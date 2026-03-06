# Builds and zips the self-contained app-image for the CURRENT OS (Windows).
# Output: dist\Google-windows.zip

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

.\gradlew.bat --no-daemon clean jpackage

$distDir = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

$zipPath = Join-Path $distDir 'AnonyChat-windows.zip'
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }

# jpackage output on Windows is usually a folder like build\jpackage\Google\
$srcPath = Join-Path $root 'build\jpackage'

Compress-Archive -Path $srcPath -DestinationPath $zipPath
Write-Host "Wrote: $zipPath"
