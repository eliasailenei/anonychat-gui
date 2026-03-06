# Builds universaljni.dll for Windows (PowerShell).
# Requires: a C compiler (MSVC cl.exe or clang-cl) and JAVA_HOME set.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

if (-not $env:JAVA_HOME) {
  throw "JAVA_HOME must be set to your JDK home"
}

$inc = Join-Path $env:JAVA_HOME "include"
$wininc = Join-Path $inc "win32"

# Example using clang-cl (recommended if available):
# clang-cl /LD /I $inc /I $wininc universaljni.c /Fe:universaljni.dll

# Example using MSVC cl.exe:
cl.exe /LD /I "$inc" /I "$wininc" universaljni.c /Fe:universaljni.dll

Write-Host "Built: $here\universaljni.dll"
