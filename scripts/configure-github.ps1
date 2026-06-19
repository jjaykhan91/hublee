# One-time GitHub setup for jjaykhan91
# Run from repo root: .\scripts\configure-github.ps1
#
# Configures: git identity, GitHub CLI auth, SSH key, and remote URL.
$ErrorActionPreference = "Stop"

$GitHubUser = "jjaykhan91"
$GitEmail = "jjaykhan91@gmail.com"
$RepoRoot = Split-Path $PSScriptRoot -Parent

function Add-ToPathIfPresent {
    param([string]$Dir)
    if ((Test-Path $Dir) -and ($env:Path -notlike "*$Dir*")) {
        $env:Path = "$Dir;" + $env:Path
    }
}

function Resolve-OpenSshBin {
  $candidates = @(
    "C:\Program Files\Git\usr\bin",
    "$env:ProgramFiles\Git\usr\bin",
    "$env:WINDIR\System32\OpenSSH"
  )
  foreach ($dir in $candidates) {
    if (Test-Path "$dir\ssh-keygen.exe") { return $dir }
  }
  return $null
}

# Git for Windows bundles OpenSSH (ssh-keygen, ssh) — often not on PATH.
$openSshBin = Resolve-OpenSshBin
if ($openSshBin) {
    Add-ToPathIfPresent $openSshBin
} else {
    Write-Host "OpenSSH not found. Install Git for Windows or enable" -ForegroundColor Red
    Write-Host "  Settings > Apps > Optional features > OpenSSH Client"
    Write-Host "  https://git-scm.com/download/win"
    exit 1
}

$sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
if (-not $sshKeygen) {
    Write-Host "ssh-keygen still not on PATH after adding $openSshBin" -ForegroundColor Red
    exit 1
}

# Ensure gh is on PATH (installed via winget)
$ghBin = "C:\Program Files\GitHub CLI"
if (Test-Path "$ghBin\gh.exe") {
    Add-ToPathIfPresent $ghBin
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*GitHub CLI*") {
        [Environment]::SetEnvironmentVariable(
            "Path",
            "$ghBin;" + $userPath,
            "User"
        )
        Write-Host "Added GitHub CLI to user PATH (restart terminal to pick up everywhere)." -ForegroundColor Cyan
    }
}

Write-Host "=== Git identity ===" -ForegroundColor Cyan
git config --global user.name $GitHubUser
git config --global user.email $GitEmail
git config --global init.defaultBranch main
git config --global credential.helper manager
Write-Host "  user.name  = $(git config --global user.name)"
Write-Host "  user.email = $(git config --global user.email)"

Write-Host ""
Write-Host "=== SSH key ===" -ForegroundColor Cyan
$sshDir = "$env:USERPROFILE\.ssh"
$keyPath = "$sshDir\id_ed25519"
New-Item -ItemType Directory -Force -Path $sshDir | Out-Null

if (-not (Test-Path $keyPath)) {
    ssh-keygen -t ed25519 -C $GitEmail -f $keyPath -N '""'
    Write-Host "Created new SSH key at $keyPath"
} else {
    Write-Host "SSH key already exists at $keyPath"
}

$configPath = "$sshDir\config"
$githubBlock = @"

Host github.com
  HostName github.com
  User git
  IdentityFile $keyPath
  IdentitiesOnly yes
"@

if (-not (Test-Path $configPath) -or (Get-Content $configPath -Raw) -notmatch "Host github\.com") {
    Add-Content -Path $configPath -Value $githubBlock
    Write-Host "Updated $configPath for github.com"
}

Write-Host ""
Write-Host "=== GitHub CLI login ===" -ForegroundColor Cyan
Write-Host "A browser window will open. Sign in as $GitHubUser and approve access."
gh auth login --hostname github.com --git-protocol ssh --web

Write-Host ""
Write-Host "=== Upload SSH key to GitHub ===" -ForegroundColor Cyan
$pubKey = Get-Content "$keyPath.pub" -Raw
Write-Host $pubKey
try {
    gh ssh-key add "$keyPath.pub" --title "hublee-$(hostname)-$(Get-Date -Format yyyy-MM-dd)"
    Write-Host "SSH key uploaded via gh."
} catch {
    Write-Host "Could not auto-upload key. Add it manually:" -ForegroundColor Yellow
    Write-Host "  https://github.com/settings/ssh/new"
}

Write-Host ""
Write-Host "=== Repo remote (SSH) ===" -ForegroundColor Cyan
Set-Location $RepoRoot
git remote set-url origin "git@github.com:${GitHubUser}/hublee.git"
Write-Host "  origin -> $(git remote get-url origin)"

Write-Host ""
Write-Host "=== Verify ===" -ForegroundColor Cyan
gh auth status
ssh -T git@github.com 2>&1

Write-Host ""
Write-Host "Done. You can push with:" -ForegroundColor Green
Write-Host "  git push -u origin master   # or main, depending on your default branch"
