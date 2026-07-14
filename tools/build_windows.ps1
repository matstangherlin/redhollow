# Red Hollow - Windows RC / local beta build
# Usage:
#   .\tools\build_windows.ps1 -GodotExe "C:\Path\To\Godot_v4.7-stable_win64.exe"
#   .\tools\build_windows.ps1 -SkipTests   # package only (manifest marks tests skipped)

param(
    [string]$GodotExe = "",
    [switch]$SkipTests,
    [switch]$DebugOnly,
    [switch]$ReleaseOnly,
    [switch]$SkipZip
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$GameVersion = "0.2.0-beta.rc1"
$BuildNumber = "20260713.rc1"
$BuildChannel = "rc1-closed"
$DisplayName = "Red Hollow - Chapter Zero Beta RC1"
$DebugExeName = "red-hollow-$GameVersion-debug.exe"
$ReleaseExeName = "red-hollow-$GameVersion-release.exe"

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
$SuitesPassed = $null
$SuitesFailed = $null
if (-not $SkipTests) {
    Write-Host "=== Running headless test runner ==="
    $runnerLog = Join-Path $BuildDir "rc1-runner-summary.txt"
    & $GodotPath --headless --path $ProjectRoot --script res://scripts/tests/test_runner.gd 2>&1 |
        Tee-Object -FilePath $runnerLog
    $TestExit = $LASTEXITCODE
    if ($TestExit -ne 0) {
        Write-Warning "Test runner exit code $TestExit - RC is NOT QA-approved."
    }
    $TestSummary = if ($TestExit -eq 0) { "pass" } else { "fail" }
    $logText = Get-Content -Raw $runnerLog -ErrorAction SilentlyContinue
    if ($logText -match "Suites passed:\s*(\d+)") { $SuitesPassed = [int]$Matches[1] }
    if ($logText -match "Suites failed:\s*(\d+)") { $SuitesFailed = [int]$Matches[1] }
}

Write-Host "=== Importing project ==="
& $GodotPath --headless --path $ProjectRoot --import
if ($LASTEXITCODE -ne 0) { throw "Godot import failed with exit $LASTEXITCODE" }

$Exports = @()
$PckFiles = @()
if (-not $ReleaseOnly) {
    Write-Host "=== Export Windows Beta Debug ==="
    & $GodotPath --headless --path $ProjectRoot --export-debug "Windows Beta Debug"
    if ($LASTEXITCODE -ne 0) { throw "Debug export failed with exit $LASTEXITCODE" }
    $Exports += $DebugExeName
    $pck = Join-Path $BuildDir ($DebugExeName -replace "\.exe$", ".pck")
    if (Test-Path $pck) { $PckFiles += (Split-Path $pck -Leaf) }
}

if (-not $DebugOnly) {
    Write-Host "=== Export Windows Beta Release ==="
    & $GodotPath --headless --path $ProjectRoot --export-release "Windows Beta Release"
    if ($LASTEXITCODE -ne 0) { throw "Release export failed with exit $LASTEXITCODE" }
    $Exports += $ReleaseExeName
    $pck = Join-Path $BuildDir ($ReleaseExeName -replace "\.exe$", ".pck")
    if (Test-Path $pck) { $PckFiles += (Split-Path $pck -Leaf) }
}

$ZipName = $null
if (-not $SkipZip -and -not $DebugOnly) {
    Write-Host "=== Portable ZIP (release) ==="
    $portableDir = Join-Path $BuildDir "portable-rc1"
    if (Test-Path $portableDir) { Remove-Item -Recurse -Force $portableDir }
    New-Item -ItemType Directory -Force -Path $portableDir | Out-Null
    $relExe = Join-Path $BuildDir $ReleaseExeName
    if (-not (Test-Path $relExe)) { throw "Missing release exe for ZIP: $relExe" }
    Copy-Item $relExe (Join-Path $portableDir $ReleaseExeName)
    $relPck = Join-Path $BuildDir ($ReleaseExeName -replace "\.exe$", ".pck")
    if (Test-Path $relPck) {
        Copy-Item $relPck (Join-Path $portableDir (Split-Path $relPck -Leaf))
    }
    # Console-less release may still ship console companion from templates — copy siblings.
    Get-ChildItem $BuildDir -Filter ($ReleaseExeName -replace "\.exe$", ".*") |
        Where-Object { $_.Extension -in ".exe", ".pck", ".dll" -and $_.Name -ne $ReleaseExeName } |
        ForEach-Object { Copy-Item $_.FullName (Join-Path $portableDir $_.Name) -ErrorAction SilentlyContinue }

    @"
$DisplayName
Version: $GameVersion
Build number: $BuildNumber
Channel: $BuildChannel
Commit: $GitHash
Save version: 1
Not for Steam / not a public release.
See docs/RC1_REPORT.md and docs/RC1_KNOWN_LIMITATIONS.md in the repository.
"@ | Set-Content -Path (Join-Path $portableDir "README_RC1.txt") -Encoding UTF8

    $ZipName = "red-hollow-$GameVersion-$GitShort-portable.zip"
    $ZipPath = Join-Path $BuildDir $ZipName
    if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
    Compress-Archive -Path (Join-Path $portableDir "*") -DestinationPath $ZipPath -Force
    Write-Host "ZIP: $ZipPath"
}

$QaApproved = ($TestExit -eq 0)
$Manifest = @{
    display_name = $DisplayName
    game_version = $GameVersion
    build_number = $BuildNumber
    save_format_version = 1
    settings_format_version = 1
    content_manifest = "res://resources/content/manifests/beta_demo.tres"
    build_channel = $BuildChannel
    git_commit = $GitHash
    git_commit_short = $GitShort
    built_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    godot_version = "4.7"
    test_runner = $TestSummary
    suites_passed = $SuitesPassed
    suites_failed = $SuitesFailed
    qa_release_approved = $QaApproved
    classification = if ($QaApproved) { "PENDING_MANUAL_PLAYTHROUGH" } else { "REPROVADA" }
    steam_publish = $false
    public_release = $false
    exports = $Exports
    pck_files = $PckFiles
    portable_zip = $ZipName
    notes = "RC1 packaging for closed testing evaluation. Do not ship publicly. Do not approve with open P0."
}

$ManifestPath = Join-Path $BuildDir "build-manifest.json"
$Manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $ManifestPath -Encoding UTF8

Write-Host ""
Write-Host "Build complete."
Write-Host "Display: $DisplayName"
Write-Host "Manifest: $ManifestPath"
foreach ($exe in $Exports) {
    Write-Host "  $(Join-Path $BuildDir $exe)"
}
if ($ZipName) { Write-Host "  $(Join-Path $BuildDir $ZipName)" }

if ($TestExit -ne 0) {
    Write-Host ""
    Write-Host "WARNING: RC is REPROVADA for closed test sign-off - tests failed / prerequisites unmet."
    exit 2
}

exit 0
