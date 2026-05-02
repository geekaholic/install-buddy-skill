# Cross-manager package name differences

A non-exhaustive list of CLI tools that ship under different names depending
on the package manager. When a user asks for one of these by its
"common" name, look here first before searching.

| Common name | brew | apt | dnf | pacman | zypper | apk |
|---|---|---|---|---|---|---|
| fd | fd | fd-find | fd-find | fd | fd | fd |
| bat | bat | bat | bat | bat | bat | bat |
| ripgrep | ripgrep | ripgrep | ripgrep | ripgrep | ripgrep | ripgrep |
| node | node | nodejs | nodejs | nodejs | nodejs | nodejs |
| python | python@3 | python3 | python3 | python | python3 | python3 |
| pip | — (bundled) | python3-pip | python3-pip | python-pip | python3-pip | py3-pip |
| docker | — (cask: docker) | docker.io | docker | docker | docker | docker |
| neovim | neovim | neovim | neovim | neovim | neovim | neovim |
| fzf | fzf | fzf | fzf | fzf | fzf | fzf |
| jq | jq | jq | jq | jq | jq | jq |
| gh (GitHub CLI) | gh | gh | gh | github-cli | gh | github-cli |
| vscode | visual-studio-code (cask) | code (via repo) | code (via repo) | visual-studio-code-bin (AUR) | — | — |
| 1password-cli | 1password-cli | 1password-cli (via repo) | 1password-cli (via repo) | 1password-cli (AUR) | — | — |
| podman | podman | podman | podman | podman | podman | podman |
| kubectl | kubectl (or kubernetes-cli) | kubectl (via repo) | kubectl (via repo) | kubectl | kubernetes-client | — |
| helm | helm | helm (via repo) | helm | helm | helm | helm |

## Notes

- `fd-find` on Debian/Ubuntu installs the binary as `fdfind` to avoid colliding
  with an unrelated tool. Mention this to the user after install if they're on
  apt — they may want to alias `fd=fdfind`.
- `python` on Arch is Python 3; there's no separate `python3` package.
- `gh` on Arch lives in `community` as `github-cli`. The `gh` name is
  unrelated.
- VS Code, Docker Desktop, 1Password GUI, and similar GUI apps usually require
  adding a third-party repo on Linux. That's a Safeguard #2 event — show the
  repo addition to the user and ask before doing it.
- This list is incomplete on purpose. When in doubt, run the manager's search
  command and surface the candidates rather than guessing.
