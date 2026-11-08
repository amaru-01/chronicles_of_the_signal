<#
.SYNOPSIS
  Checks that the built Windows .exe contains everything the game loads.

.DESCRIPTION
  Release templates cannot start on a chosen scene, so this runs the Godot editor binary against
  the pack embedded in the .exe (--main-pack) from an empty folder, so only the PACKED files are
  visible. Any file the export forgot (the district maps and quests.json are not Godot resources
  and must be in the preset's include filter) shows up as a load error.

  The scenes autosave, so the script backs up your real save.json first and restores it afterwards.

.EXAMPLE
  powershell -File tools/smoke_exe.ps1
#>
param(
    [string]$Godot = "E:\Godot\Godot_v4.7.2-stable_win64.exe",
    [string]$Exe = "build\windows\ChroniclesOfTheSignal.exe"
)

$root = Split-Path -Parent $PSScriptRoot
$exePath = Join-Path $root $Exe
if (-not (Test-Path $exePath)) { throw "Build the .exe first: powershell -File tools/build_windows.ps1" }

$work = Join-Path $env:TEMP "chronicles_smoke"
New-Item -ItemType Directory -Force $work | Out-Null
$save = Join-Path $env:APPDATA "Godot\app_userdata\Chronicles of the Signal\save.json"
$backup = Join-Path $work "save_backup.json"
$hadSave = Test-Path $save
if ($hadSave) { Copy-Item $save $backup -Force }

$scenes = @(
    "res://ui/title_screen.tscn", "res://scenes3d/intro_3d.tscn", "res://scenes3d/hub_3d.tscn",
    "res://scenes3d/district_01_3d.tscn", "res://scenes3d/district_02_3d.tscn",
    "res://scenes3d/district_03_3d.tscn", "res://scenes3d/relay_tower_3d.tscn", "res://ui/end_screen.tscn"
)
$failed = 0
try {
    foreach ($scene in $scenes) {
        $name = Split-Path $scene -Leaf
        $out = Join-Path $work "$name.out"
        $p = Start-Process $Godot -WorkingDirectory $work -PassThru -RedirectStandardOutput $out -RedirectStandardError "$out.err" `
            -ArgumentList @("--main-pack", "`"$exePath`"", $scene, "--quit-after", "200")
        if (-not $p.WaitForExit(90000)) { $p.Kill(); Write-Host "FAIL  $name (timed out)"; $failed++; continue }
        $errors = Select-String -Path $out, "$out.err" -Pattern "ERROR|Failed|not found|Cannot" |
            ForEach-Object Line | Where-Object { $_ -notmatch "still in use" }
        if ($errors) { Write-Host "FAIL  $name"; $errors | Select-Object -First 3 | ForEach-Object { Write-Host "        $_" }; $failed++ }
        else { Write-Host "ok    $name" }
    }
}
finally {
    if ($hadSave) { Copy-Item $backup $save -Force }
}
if ($failed -gt 0) { Write-Host "$failed scene(s) failed."; exit 1 }
Write-Host "All $($scenes.Count) scenes load from the packed .exe."
