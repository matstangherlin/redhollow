# Red Hollow - Beta Asset Manifest report
# Usage:
#   .\tools\report_beta_assets.ps1
#   .\tools\report_beta_assets.ps1 -GodotExe "C:\Path\To\Godot_v4.7-stable_win64.exe"
#   .\tools\report_beta_assets.ps1 -OutFile ".\docs\_beta_asset_report.txt"

param(
    [string]$GodotExe = "",
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

function Resolve-GodotExe {
    param([string]$Candidate)
    if (-not [string]::IsNullOrWhiteSpace($Candidate) -and (Test-Path $Candidate)) {
        return (Resolve-Path $Candidate).Path
    }
    $cmd = Get-Command "godot" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $default = "C:\Users\Stan\Documents\Godot_v4.7-stable_win64.exe"
    if (Test-Path $default) { return $default }
    throw "Godot executable not found. Pass -GodotExe with full path."
}

$GodotPath = Resolve-GodotExe $GodotExe
Write-Host "Godot: $GodotPath"
Write-Host "Generating beta asset manifesto report..."
Write-Host ""

$tmpOut = Join-Path $env:TEMP ("red_hollow_beta_asset_report_{0}.txt" -f [guid]::NewGuid().ToString("N"))
& $GodotPath --headless --path $ProjectRoot --script res://scripts/art/beta_asset_report_cli.gd *>&1 |
    Tee-Object -FilePath $tmpOut
$exitCode = $LASTEXITCODE

if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
    $dest = if ([System.IO.Path]::IsPathRooted($OutFile)) { $OutFile } else { Join-Path $ProjectRoot $OutFile }
    $dir = Split-Path -Parent $dest
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    Copy-Item -Force $tmpOut $dest
    Write-Host ""
    Write-Host "Copied report to: $dest"
}

Remove-Item -Force $tmpOut -ErrorAction SilentlyContinue

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "Report completed (exit 0)."
} else {
    Write-Host "Report failed (exit $exitCode)."
}

exit $exitCode
