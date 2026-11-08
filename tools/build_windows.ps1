<#
.SYNOPSIS
  Builds the Windows release of Chronicles of the Signal and zips it for itch.io.

.DESCRIPTION
  Exports the "Windows Desktop" preset (a single .exe with the game embedded), copies the
  README beside it and writes build/ChroniclesOfTheSignal-windows.zip. The build/ folder and
  *.zip are git-ignored.

  Needs the Windows export templates for your Godot version (Editor > Manage Export
  Templates > Download and Install). The script stops with a clear message if they are missing.

.EXAMPLE
  powershell -File tools/build_windows.ps1 -Godot "E:\Godot\Godot_v4.7.2-stable_win64.exe"
#>
param(
    [string]$Godot = "E:\Godot\Godot_v4.7.2-stable_win64.exe",
    [string]$Preset = "Windows Desktop"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $Godot)) { throw "Godot not found at $Godot (use -Godot <path>)" }

# The Windows godot.exe is a GUI program: it prints nothing to a plain pipe, so redirect to a file.
$versionFile = Join-Path $env:TEMP "godot_version.txt"
Start-Process $Godot -ArgumentList "--version" -Wait -NoNewWindow -RedirectStandardOutput $versionFile
$version = (Get-Content $versionFile -Raw).Trim()        # e.g. 4.7.2.stable.official.ed1daf0bf
$short = ($version -split "\.")[0..3] -join "."         # e.g. 4.7.2.stable
$templates = Join-Path $env:APPDATA "Godot\export_templates\$short"
if (-not (Test-Path (Join-Path $templates "windows_release_x86_64.exe"))) {
    throw "Windows export templates are missing in $templates. In the editor: Editor > Manage Export Templates > Download and Install."
}

$outDir = Join-Path $root "build\windows"
if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
New-Item -ItemType Directory -Force $outDir | Out-Null

Write-Host "Exporting '$Preset'..."
# Start-Process -Wait because godot.exe is a GUI program (a plain call neither waits nor sets an
# exit code). The preset name has a space, so it needs its own quotes.
$log = Join-Path $env:TEMP "godot_export.log"
$proc = Start-Process $Godot -Wait -PassThru -NoNewWindow -RedirectStandardOutput $log -RedirectStandardError "$log.err" `
    -ArgumentList @("--headless", "--path", "`"$root`"", "--export-release", "`"$Preset`"", "`"$(Join-Path $outDir 'ChroniclesOfTheSignal.exe')`"")
if ($proc.ExitCode -ne 0) {
    Get-Content $log, "$log.err" | Where-Object { $_ -match "ERROR" } | ForEach-Object { Write-Host $_ }
    throw "Export failed (exit code $($proc.ExitCode)). See $log"
}

$exe = Join-Path $outDir "ChroniclesOfTheSignal.exe"
if (-not (Test-Path $exe)) { throw "Export finished but $exe was not created" }

Copy-Item (Join-Path $root "README.md") $outDir
$zip = Join-Path $root "build\ChroniclesOfTheSignal-windows.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path (Join-Path $outDir "*") -DestinationPath $zip

$size = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Host "Done: $zip ($size MB)"
Write-Host "SHA256: $((Get-FileHash $zip).Hash)"
