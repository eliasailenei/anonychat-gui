# Builds a self-contained app-image for the CURRENT OS (Windows).
# Output: build\jpackage\AnonyChat\ (folder)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

# Gradle wrapper (no Gradle install required)
.\gradlew.bat --no-daemon clean jpackage

# Copy the built image into bin\windows so Program.java picks it up.
if (Test-Path "$root\build\jpackage\AnonyChat") {
    if (Test-Path "$root\bin\windows") { Remove-Item -Recurse -Force "$root\bin\windows" }
    New-Item -ItemType Directory -Force -Path "$root\bin\windows" | Out-Null
    Copy-Item -Recurse -Force "$root\build\jpackage\AnonyChat\*" "$root\bin\windows\"
}

Write-Host ""
Write-Host "Built app-image under: $root\build\jpackage"
