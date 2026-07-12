# Red Hollow - run all headless test suites
# Usage:
#   .\tools\test_all.ps1
#   .\tools\test_all.ps1 -GodotExe "C:\Path\To\Godot_v4.7-stable_win64.exe"

param(
    [string]$GodotExe = ""
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
Write-Host "Running headless test runner..."
Write-Host ""

& $GodotPath --headless --path $ProjectRoot --script res://scripts/tests/test_runner.gd
$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "All suites passed (exit 0)."
} else {
    Write-Host "Test runner failed (exit $exitCode)."
}

exit $exitCode
