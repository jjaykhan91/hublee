# GitHub setup

One-time configuration for pushing and pulling **hublee** as [jjaykhan91](https://github.com/jjaykhan91).

| Setting | Value |
|---------|--------|
| GitHub username | `jjaykhan91` |
| Git email | `jjaykhan91@gmail.com` |
| Remote repo | `https://github.com/jjaykhan91/hublee` |
| SSH remote (after setup) | `git@github.com:jjaykhan91/hublee.git` |

## Automated setup (recommended)

**Prerequisites:** [Git for Windows](https://git-scm.com/download/win) (includes `ssh-keygen` and `ssh`). GitHub CLI (`gh`) is already installed on this machine.

Run:

```powershell
cd C:\Users\MightK\hublee
.\scripts\configure-github.ps1
```

The script will:

1. Set global git `user.name` and `user.email`
2. Enable Windows **Git Credential Manager** for HTTPS fallback
3. Create an Ed25519 SSH key (if you do not have one)
4. Add `github.com` to `~/.ssh/config`
5. Log you into GitHub via browser (`gh auth login`)
6. Upload the SSH public key to your GitHub account
7. Point `origin` at the SSH URL

When prompted in the browser, sign in as **jjaykhan91**.

## Manual setup

If you prefer to run steps yourself:

### 1. Git identity

```powershell
git config --global user.name "jjaykhan91"
git config --global user.email "jjaykhan91@gmail.com"
git config --global init.defaultBranch main
git config --global credential.helper manager
```

### 2. GitHub CLI

```powershell
# Add to PATH if gh is not found (restart terminal after)
$env:Path = "C:\Program Files\GitHub CLI;" + $env:Path

gh auth login --hostname github.com --git-protocol ssh --web
gh auth status
```

### 3. SSH key

```powershell
ssh-keygen -t ed25519 -C "jjaykhan91@gmail.com" -f "$env:USERPROFILE\.ssh\id_ed25519"
```

Add the public key at [github.com/settings/ssh/new](https://github.com/settings/ssh/new), or:

```powershell
gh ssh-key add "$env:USERPROFILE\.ssh\id_ed25519.pub" --title "hublee-laptop"
```

Test:

```powershell
ssh -T git@github.com
# Expected: Hi jjaykhan91! You've successfully authenticated...
```

### 4. Remote URL

```powershell
cd C:\Users\MightK\hublee
git remote set-url origin git@github.com:jjaykhan91/hublee.git
git remote -v
```

## Daily Git workflow

```powershell
git status
git add .
git commit -m "Describe your change"
git push
```

Create a pull request (after pushing a branch):

```powershell
git checkout -b my-feature
# ... commits ...
git push -u origin my-feature
gh pr create
```

## Verify everything

```powershell
git config --global --list | Select-String "user\.|credential"
gh auth status
ssh -T git@github.com
git -C C:\Users\MightK\hublee remote -v
```

## Troubleshooting

### `ssh-keygen` not recognized

Git for Windows includes OpenSSH at `C:\Program Files\Git\usr\bin`. The setup script adds this automatically. If you run commands manually, prepend PATH:

```powershell
$env:Path = "C:\Program Files\Git\usr\bin;" + $env:Path
```

Or enable **OpenSSH Client** in Windows: Settings → Apps → Optional features → Add a feature.

### `gh` not recognized

GitHub CLI installs to `C:\Program Files\GitHub CLI`. Add it to user PATH:

```powershell
[Environment]::SetEnvironmentVariable(
  "Path",
  "C:\Program Files\GitHub CLI;" + [Environment]::GetEnvironmentVariable("Path", "User"),
  "User"
)
```

Restart the terminal.

### `Permission denied (publickey)` on push

- Confirm the key is listed at [github.com/settings/keys](https://github.com/settings/keys)
- Re-run `.\scripts\configure-github.ps1` or `gh ssh-key add ...`
- Ensure remote uses SSH: `git@github.com:jjaykhan91/hublee.git`

### HTTPS instead of SSH

The default remote is HTTPS (`https://github.com/jjaykhan91/hublee.git`). That works with `gh auth login` and Credential Manager — no SSH key required. SSH is recommended for fewer password prompts.

### Branch name

This repo tracks **`master`** on GitHub. Use `git push origin master` unless you rename the default branch.

## See also

- [DEVELOPMENT.md](DEVELOPMENT.md) — Flutter project setup
- [GitHub CLI docs](https://cli.github.com/manual/)
