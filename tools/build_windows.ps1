# Red Hollow - Windows build (local beta)
# Usage:
#   .\tools\build_windows.ps1 -GodotExe "C:\Path\To\Godot_v4.7-stable_win64.exe"

param(
    [string]$GodotExe = "",
    [switch]$SkipTests,
    [switch]$DebugOnly,
    [switch]$ReleaseOnly
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
$BuildDir = Join-Path $ProjectRoot "builds\windows"
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

$GitHash = "unknown"
$GitShort = "unknown"
try {
    $GitHash = (git rev-parse HEAD).Trim()
    $GitShort = (git rev-parse --short HEAD).Trim()
} catch {
    Write-Warning "Git hash unavailable."
}

$TestExit = 0
$TestSummary = "skipped"
if (-not $SkipTests) {
    Write-Host "=== Running headless test runner ==="
    & $GodotPath --headless --path $ProjectRoot --script res://scripts/tests/test_runner.gd
    $TestExit = $LASTEXITCODE
    if ($TestExit -ne 0) {
        Write-Warning "Test runner exit code $TestExit - release build is NOT QA-approved."
    }
    $TestSummary = if ($TestExit -eq 0) { "pass" } else { "fail" }
}

Write-Host "=== Importing project ==="
& $GodotPath --headless --path $ProjectRoot --import
if ($LASTEXITCODE -ne 0) { throw "Godot import failed with exit $LASTEXITCODE" }

$Exports = @()
if (-not $ReleaseOnly) {
    Write-Host "=== Export Windows Beta Debug ==="
    & $GodotPath --headless --path $ProjectRoot --export-debug "Windows Beta Debug"
    if ($LASTEXITCODE -ne 0) { throw "Debug export failed with exit $LASTEXITCODE" }
    $Exports += "red-hollow-0.2.0-beta.1-debug.exe"
}

if (-not $DebugOnly) {
    Write-Host "=== Export Windows Beta Release ==="
    & $GodotPath --headless --path $ProjectRoot --export-release "Windows Beta Release"
    if ($LASTEXITCODE -ne 0) { throw "Release export failed with exit $LASTEXITCODE" }
    $Exports += "red-hollow-0.2.0-beta.1-release.exe"
}

$Manifest = @{
    game_version = "0.2.0-beta.1"
    save_format_version = 1
    settings_format_version = 1
    build_channel = "local-beta"
    git_commit = $GitHash
    git_commit_short = $GitShort
    built_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    godot_version = "4.7"
    test_runner = $TestSummary
    qa_release_approved = ($TestExit -eq 0)
    exports = $Exports
    notes = "Local beta only - not Steam, not public release."
}

$ManifestPath = Join-Path $BuildDir "build-manifest.json"
$Manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $ManifestPath -Encoding UTF8

Write-Host ""
Write-Host "Build complete."
Write-Host "Manifest: $ManifestPath"
foreach ($exe in $Exports) {
    Write-Host "  $(Join-Path $BuildDir $exe)"
}

if ($TestExit -ne 0) {
    Write-Host ""
    Write-Host "WARNING: Do not distribute release build as approved - tests failed."
    exit 2
}

exit 0
