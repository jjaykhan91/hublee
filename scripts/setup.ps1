# Hublee local setup — run from repo root: .\scripts\setup.ps1
$ErrorActionPreference = "Stop"

$flutterBin = "$env:USERPROFILE\flutter\bin"
if (-not (Test-Path "$flutterBin\flutter.bat")) {
    Write-Host "Flutter not found at $flutterBin" -ForegroundColor Red
    Write-Host "Install: https://docs.flutter.dev/get-started/install/windows"
    exit 1
}

$env:Path = "$flutterBin;" + $env:Path
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Flutter:" -ForegroundColor Cyan
flutter --version

$devMode = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
if ($devMode -ne 1) {
    Write-Host ""
    Write-Host "Developer Mode is OFF. Flutter needs symlink support on Windows." -ForegroundColor Yellow
    Write-Host "Enable: Settings > System > For developers > Developer Mode"
    Write-Host "Or run: start ms-settings:developers"
    Write-Host ""
}

Write-Host "Installing dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host ""
Write-Host "Running tests..." -ForegroundColor Cyan
flutter test

Write-Host ""
Write-Host "Doctor summary:" -ForegroundColor Cyan
flutter doctor

Write-Host ""
Write-Host "Ready. Run the app:" -ForegroundColor Green
Write-Host "  flutter run -d chrome    # Web (no extra tools)"
Write-Host "  flutter run -d windows   # Desktop (requires Visual Studio C++ workload)"
Write-Host ""
Write-Host "Tip: Add Flutter to PATH permanently:"
Write-Host "  $flutterBin"
