#!/usr/bin/env bash
# detect_os.sh — print OS and best package manager for install-buddy.
# Output: two lines, OS=<id> and MGR=<manager>. Always exits 0; if it
# can't figure something out, it emits OS=unknown or MGR=unknown so the
# caller can surface that to the user instead of silently failing.

set -u

os_id="unknown"
mgr="unknown"

case "$(uname -s)" in
  Darwin)
    os_id="macos"
    if command -v brew >/dev/null 2>&1; then
      mgr="brew"
    else
      mgr="missing-brew"
    fi
    ;;
  Linux)
    if [ -r /etc/os-release ]; then
      # shellcheck disable=SC1091
      . /etc/os-release
      os_id="${ID:-unknown}"
      id_like="${ID_LIKE:-}"
    else
      id_like=""
    fi

    # Pick manager by id, then by id_like, then by what's actually on PATH.
    case "$os_id" in
      debian|ubuntu|linuxmint|pop|raspbian)
        mgr="apt" ;;
      fedora|rhel|centos|rocky|almalinux|fedora-asahi-remix)
        mgr="dnf" ;;
      arch|cachyos|manjaro|endeavouros)
        mgr="pacman" ;;
      opensuse*|sles)
        mgr="zypper" ;;
      alpine)
        mgr="apk" ;;
      *)
        case " $id_like " in
          *" debian "*)  mgr="apt" ;;
          *" fedora "*|*" rhel "*) mgr="dnf" ;;
          *" arch "*)    mgr="pacman" ;;
          *" suse "*)    mgr="zypper" ;;
          *)
            # last-ditch: probe PATH
            for c in apt dnf pacman zypper apk yum; do
              if command -v "$c" >/dev/null 2>&1; then mgr="$c"; break; fi
            done
            ;;
        esac
        ;;
    esac

    # Verify the chosen manager actually exists on PATH.
    if [ "$mgr" != "unknown" ] && ! command -v "$mgr" >/dev/null 2>&1; then
      # dnf -> yum fallback for old RHEL
      if [ "$mgr" = "dnf" ] && command -v yum >/dev/null 2>&1; then
        mgr="yum"
      else
        mgr="missing-$mgr"
      fi
    fi
    ;;
  *)
    os_id="unsupported-$(uname -s)"
    ;;
esac

echo "OS=$os_id"
echo "MGR=$mgr"
