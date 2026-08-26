# Prepare GitHub secrets for Play closed-testing uploads.
# Run from the repo root: .\scripts\prep-play-github-secrets.ps1
#
# Prints the base64 keystore (and copies it to the clipboard when possible).
# It does not print keystore passwords — copy those from android/key.properties.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

$keystore = Join-Path $repoRoot "android\upload-keystore.jks"
$keyProps = Join-Path $repoRoot "android\key.properties"

if (-not (Test-Path $keystore)) {
    Write-Host "Missing $keystore" -ForegroundColor Red
    Write-Host "That file is gitignored and lives only on this PC. Generate it once if needed (docs/PLAY_STORE.md)."
    exit 1
}

$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystore))
try {
    Set-Clipboard -Value $base64
    $clipNote = "Copied PLAY_KEYSTORE_BASE64 to the clipboard."
} catch {
    $clipNote = "Clipboard unavailable — copy the base64 block below."
}

Write-Host ""
Write-Host "Add these repository secrets at:" -ForegroundColor Cyan
Write-Host "  https://github.com/jjaykhan91/hublee/settings/secrets/actions"
Write-Host ""
Write-Host "  PLAY_KEYSTORE_BASE64   $clipNote"
Write-Host "  PLAY_STORE_PASSWORD    storePassword from android/key.properties"
Write-Host "  PLAY_KEY_PASSWORD      keyPassword from android/key.properties"
Write-Host "  PLAY_KEY_ALIAS         keyAlias from android/key.properties (usually upload)"
Write-Host "  PLAY_SERVICE_ACCOUNT_JSON   full JSON of the Play API service-account key"
Write-Host ""
Write-Host "Never commit android/key.properties, the .jks, or the JSON key."
Write-Host ""
Write-Host "PLAY_KEYSTORE_BASE64 ($((Get-Item $keystore).Length) bytes):" -ForegroundColor Cyan
Write-Host $base64

if (Test-Path $keyProps) {
    Write-Host ""
    Write-Host "key.properties found. Open it locally to copy the three password/alias secrets." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "android/key.properties not found. You still need PLAY_STORE_PASSWORD, PLAY_KEY_PASSWORD, and PLAY_KEY_ALIAS." -ForegroundColor Yellow
}
