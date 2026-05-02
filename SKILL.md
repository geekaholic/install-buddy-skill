---
name: install-buddy
description: Install software packages across macOS and Linux using the correct native package manager (Homebrew, apt, dnf, pacman, zypper, apk). Use this skill whenever the user wants to install one or more CLI tools, libraries, or applications, including bulk installs from a JSON or YAML config file. Trigger on phrases like "install X", "set up Y on this machine", "/install-buddy ...", or any time the user provides a list of packages to install. Always detects the host OS first, surfaces the exact command before running it, and refuses destructive operations.
---

# install-buddy

A "Software 3.0" wrapper around native package managers. The job is to install what the user asked for, on the OS they're actually running, with full transparency and conservative safeguards.

If the user invokes this skill via a slash command (e.g. `/install-buddy htop` or `/install-buddy ./my-stack.yaml`), treat the argument as either a single package name or a path to a config file — try the path first, fall back to package name.

## Workflow

### 1. Detect the OS and active package manager

Run `scripts/detect_os.sh` and parse the output. It prints two lines: `OS=<id>` and `MGR=<manager>`. If the script isn't executable for some reason, fall back to:

```bash
uname -s                          # Darwin or Linux
[ -f /etc/os-release ] && . /etc/os-release && echo "$ID $ID_LIKE"
```

Detection priority:

- **macOS (Darwin)**: prefer `brew`. If not installed, ask the user whether to install Homebrew before continuing — show them the official install command from https://brew.sh and wait for confirmation. Never auto-install Homebrew.
- **Debian / Ubuntu** (id=`debian`/`ubuntu`, or `id_like` contains `debian`): `apt`
- **Fedora / RHEL / CentOS** (id=`fedora`/`rhel`/`centos`, includes `fedora-asahi-remix`): `dnf` (fall back to `yum` if `dnf` is missing)
- **Arch / CachyOS** (id=`arch`/`cachyos`, or `id_like` contains `arch`): `pacman`. If `yay` or `paru` is installed, mention it as available for AUR packages, but never reach for the AUR without explicit user opt-in.
- **openSUSE** (id starts with `opensuse`): `zypper`
- **Alpine** (id=`alpine`): `apk`

If the detected manager isn't actually installed on the system, stop and tell the user — don't try to bootstrap one silently.

### 2. Resolve the package name for the active manager

Package names differ across managers (`fd-find` on apt, `fd` on brew/pacman/dnf; `bat` vs `bat-cat` on some distros; `nodejs` vs `node`). Before running any install:

1. Check whether the requested name exists for the active manager. Use the search command — `apt-cache search ^<name>$`, `brew search /^<name>$/`, `pacman -Ss "^<name>$"`, `dnf search <name>`, `apk search <name>`, `zypper search <name>`.
2. If the exact name isn't found but close candidates exist, list them and ask which one the user wants. Don't guess.
3. See `references/package-name-map.md` for known cross-manager name differences if you need a hint.

### 3. Show the command, then run

Before every install command, print the exact command that will run. Format:

```
About to run: brew install htop
Press enter to confirm, or tell me to change it.
```

Then execute it via the bash tool. Capture stdout and stderr and report the result honestly — including "already installed" outcomes and version numbers when available. Don't silently swallow errors or hide the raw output behind a summary.

### 4. Bulk installs from a config file

If the user provides a JSON or YAML file (or invokes the skill with a path argument), parse it as a list of install targets with optional per-OS overrides. See `assets/example-config.yaml` for the canonical schema. Two accepted shapes:

**Simple list:**
```yaml
packages:
  - htop
  - ripgrep
  - jq
```

**With per-manager overrides and platform gating:**
```yaml
packages:
  - name: fd
    apt: fd-find
    dnf: fd-find
  - name: visual-studio-code
    brew: visual-studio-code
    cask: true
    only_on: [macos]
  - name: neovim
    pacman: neovim
    apt: neovim
```

Recognized override keys: `brew`, `cask` (boolean, brew cask), `apt`, `dnf`, `pacman`, `zypper`, `apk`, plus `only_on` (list from `macos`, `linux`, `debian`, `ubuntu`, `fedora`, `arch`, `alpine`, `opensuse`) for platform gating. A package with `only_on` that excludes the current platform is skipped silently with a note in the final summary.

When processing a config file:

1. **Show the resolved plan first.** List each package with the command that *will* run, grouped by manager. Note anything that will be skipped due to `only_on`.
2. **Wait for explicit confirmation** before executing anything.
3. **Run sequentially**, not in parallel — a failure halfway through should be obvious and easy to recover from.
4. After each install, report success/failure inline. At the end, give a summary: N installed, M already present, K skipped (platform-gated), F failed.

## Safeguards

These are non-negotiable. They protect the user from a bad day. See `references/safeguards.md` for the rationale and edge cases.

1. **Never run `sudo rm`, `rm -rf`, package removal/uninstall commands, or anything destructive** unless the user explicitly asked for removal in the current turn. Installing one tool is not license to uninstall another.
2. **Never modify package manager configuration** — `/etc/apt/sources.list*`, `/etc/yum.repos.d/`, third-party Homebrew taps, custom Pacman repos — without showing the change and asking first. Adding a repo is a security event, not a step in an install.
3. **No shell metacharacter injection.** Package names must match `^[A-Za-z0-9._+@-]+$`. If a name from a config file contains anything else (semicolons, backticks, `$(`, pipes, redirects, spaces), refuse the entry and tell the user which line is suspicious.
4. **Never `curl | sh`** as a fallback installer. If a package isn't in the system manager, stop and let the user decide what to do.
5. **`sudo` only when the manager requires it** (apt/dnf/pacman/zypper/apk on Linux). Never `sudo brew`. When `sudo` is needed, include it in the preview command so the user sees it.
6. **No global upgrades.** `apt update` (refresh metadata) is fine. `apt upgrade`, `brew upgrade`, `pacman -Syu` (upgrade everything) is not — those are separate intents that need their own confirmation.
7. **If a package is already installed**, report the installed version and ask before reinstalling or upgrading.
8. **Refuse `--force`, `--allow-downgrades`, `--break-system-packages`, or similar flags** unless the user explicitly typed them in the current turn.

## Transparency

After every run, give a short summary:
- What was installed and via which manager
- Versions, if the manager reports them
- Anything skipped or failed, with the reason
- Any entries rejected by the safeguards above and why

Keep it short. The user is technical and reads `apt` output for fun.
