# Safeguards: rationale and edge cases

The rules in SKILL.md are short on purpose. This file explains why, and how
to handle the cases that look like exceptions but aren't.

## Why no auto-removal

A user asking to install package X is not asking to remove anything. Even when
a package conflicts with something already installed, the right move is to
*report* the conflict and let the user decide. Package managers will sometimes
suggest removing conflicts (`apt` is especially eager about this in
`autoremove`); never accept those suggestions on the user's behalf.

If the user explicitly says "remove jq" or "uninstall htop" in the current
turn, that's a separate intent and removal is fine — but still preview the
command first.

## Why no third-party repos without confirmation

Adding a repo or tap means trusting that publisher to push code that will run
as root on the user's machine, possibly forever. That's a much bigger decision
than "install this one tool." Always show:
- The exact `add-apt-repository` / `dnf config-manager --add-repo` /
  `brew tap` command
- The URL of the repo
- What it provides

…and wait for explicit confirmation. If the user declines, fall back to
"this package isn't available from your default repos — here are the options"
rather than secretly adding the repo anyway.

## Why no `curl | sh`

Three reasons:
1. The script's contents change between when it's audited and when it runs.
2. There's no rollback story. The system manager at least knows what it
   installed.
3. Users who genuinely want to do this can do it themselves in one line. The
   skill's job is to use *managed* installs.

If a tool is genuinely only distributed as a `curl | sh` script (some Rust
toolchains, some cloud SDKs), say so and let the user invoke it explicitly.

## Why no `--break-system-packages`

`pip install --break-system-packages` exists because PEP 668 made distros
mark their Python installs as externally-managed. Ignoring that protection
inside an install skill is exactly the wrong default — it routes around a
guard the OS put in place. If the user wants Python packages, suggest
`pipx`, a virtualenv, or `uv` instead. If they explicitly typed
`--break-system-packages` themselves, that's their call.

## The shell metacharacter rule

Package names are validated against `^[A-Za-z0-9._+@-]+$`. The `+` and `@`
are there because some legitimate package names use them
(`g++`, `gcc-12`, `@scoped/things` — though scoped names are an npm thing,
not a system manager thing).

If a name fails the regex, refuse it and tell the user which entry was
suspicious. Don't sanitize silently — the user should know their config has
a problem.

## sudo handling

On Linux, system package managers need root. The skill should:
- Run `sudo apt install …` with sudo in the command
- Show the `sudo` in the preview so the user knows they'll be prompted
- Not cache or retain credentials beyond what `sudo` itself does
- Never write a sudoers entry, never edit `/etc/sudoers.d/*`

On macOS, `brew` explicitly does not want to run as root. `sudo brew install`
is a known-bad pattern that breaks things. Refuse if the user asks for it.

## "Already installed" handling

Before running an install, check if the package is present:
- brew: `brew list --versions <name>` (exit 0 if installed)
- apt: `dpkg -s <name>` (exit 0 if installed)
- dnf: `rpm -q <name>` (exit 0 if installed)
- pacman: `pacman -Qi <name>` (exit 0 if installed)
- zypper: `rpm -q <name>` (exit 0 if installed)
- apk: `apk info -e <name>` (prints name if installed, empty if not)

If installed, report the version and ask whether to skip, reinstall, or
upgrade. Default to skip on bulk runs unless the user said otherwise.
