param(
  [string]$InnoCompiler = "ISCC.exe",
  [string]$BuildOutputDir = "C:\tmp\facturation_installer_build"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseExe = Join-Path $projectRoot "build\windows\x64\runner\Release\facturation_app.exe"
$scriptPath = Join-Path $PSScriptRoot "facturation_app.iss"
$distDir = Join-Path $projectRoot "dist"
$setupFileName = "Facturation-Setup-1.0.0.exe"
$builtSetup = Join-Path $BuildOutputDir $setupFileName
$finalSetup = Join-Path $distDir $setupFileName

if (-not (Test-Path -LiteralPath $releaseExe)) {
  throw "Build Windows introuvable. Lance d'abord: flutter build windows"
}

New-Item -ItemType Directory -Force -Path $BuildOutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

if (Test-Path -LiteralPath $builtSetup) {
  Remove-Item -LiteralPath $builtSetup -Force
}

& $InnoCompiler "/O$BuildOutputDir" $scriptPath

if (-not (Test-Path -LiteralPath $builtSetup)) {
  throw "Compilation terminee, mais installateur introuvable: $builtSetup"
}

Copy-Item -LiteralPath $builtSetup -Destination $finalSetup -Force
Write-Host "Installateur cree: $finalSetup"
