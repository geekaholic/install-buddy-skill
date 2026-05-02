# install-buddy

A Claude Code skill that installs software packages using the right native package manager for your OS — Homebrew on macOS, and apt/dnf/pacman/zypper/apk on Linux. Shows you every command before running it. Refuses destructive operations.

[![Rebuild bundle](https://github.com/geekaholic/install-buddy-skill/actions/workflows/bundle.yml/badge.svg)](https://github.com/geekaholic/install-buddy-skill/actions/workflows/bundle.yml)

---

## Install

```bash
curl -fsSL https://github.com/geekaholic/install-buddy-skill/raw/main/dist/install-buddy.tar.gz \
  | tar -xz -C ~/.claude/skills/
```

**Manual steps:**
1. Download [`dist/install-buddy.tar.gz`](dist/install-buddy.tar.gz)
2. Extract: `tar -xzf install-buddy.tar.gz -C ~/.claude/skills/`
3. Verify: `ls ~/.claude/skills/install-buddy/SKILL.md`

Claude Code auto-discovers skills with valid frontmatter in `~/.claude/skills/` — no additional config needed.

---

## Usage

Install a single package:
```
/install-buddy htop
```

Install from a config file:
```
/install-buddy ./my-stack.yaml
```

Or just describe what you want — the skill triggers on natural language too:
```
install ripgrep and fd on this machine
set up my dev tools from ~/dotfiles/packages.yaml
```

---

## What it does

1. **Detects your OS and package manager** — runs `scripts/detect_os.sh`, handles macOS (brew) and major Linux distros
2. **Resolves the right package name** — `fd` is `fd-find` on apt, `nodejs` vs `node`, etc. See [`references/package-name-map.md`](references/package-name-map.md)
3. **Shows the exact command before running it** — you confirm, then it executes
4. **Reports results honestly** — versions, already-installed status, failures, anything rejected by safeguards

### Supported platforms

| OS | Package manager |
|---|---|
| macOS | brew |
| Debian, Ubuntu, Mint, Pop!_OS | apt |
| Fedora, RHEL, CentOS, Rocky | dnf (yum fallback) |
| Arch, CachyOS, Manjaro, EndeavourOS | pacman |
| openSUSE, SLES | zypper |
| Alpine | apk |

---

## Config file format

For bulk installs, create a YAML (or JSON) file and pass its path to the skill:

```yaml
packages:
  # Simple: same name on all managers
  - htop
  - ripgrep

  # With per-manager name overrides
  - name: fd
    apt: fd-find
    dnf: fd-find

  # Platform-gated and cask installs
  - name: rectangle
    brew: rectangle
    cask: true
    only_on: [macos]
```

Supported override keys: `brew`, `cask` (boolean), `apt`, `dnf`, `pacman`, `zypper`, `apk`

Platform gate values for `only_on`: `macos`, `linux`, `debian`, `ubuntu`, `fedora`, `arch`, `alpine`, `opensuse`

See [`assets/example-config.yaml`](assets/example-config.yaml) for the full example.

---

## Safeguards

The skill will never:
- Run removal/uninstall commands unless you explicitly asked for removal
- Add third-party repos or taps without showing the change and asking first
- Accept package names with shell metacharacters (validated against `^[A-Za-z0-9._+@-]+$`)
- Use `curl | sh` as a fallback
- `sudo brew` on macOS
- Run a global upgrade (`apt upgrade`, `brew upgrade`) — those need their own confirmation
- Reinstall silently if a package is already present
- Accept `--force`, `--break-system-packages`, or similar flags unless you typed them explicitly

Full rationale: [`references/safeguards.md`](references/safeguards.md)

---

## Local development

```bash
git clone https://github.com/geekaholic/install-buddy-skill
cd install-buddy

# Enable the pre-commit hook (rebuilds the bundle automatically before each commit)
git config core.hooksPath .githooks

# Rebuild the bundle manually
make bundle

# Verify bundle contents
make check-bundle
```

The `dist/install-buddy.tar.gz` is committed to the repo. When you push changes to any source file, GitHub Actions rebuilds it and commits the updated bundle back to `main`.

> **Note:** If your repo has branch protection on `main` that blocks the `GITHUB_TOKEN` from pushing, create a PAT with `contents: write` scope, store it as the repo secret `BUNDLE_PAT`, and update the `token:` field in `.github/workflows/bundle.yml`.

---

## License

MIT — see [LICENSE](LICENSE)
