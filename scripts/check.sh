#!/usr/bin/env bash
set -euo pipefail

# Validate the repo: lint scripts, syntax-check zsh, then bootstrap into a throwaway $HOME
# and confirm an interactive zsh starts cleanly. Used by CI on macOS and Fedora; safe to run locally.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { echo "==> $*"; }
fail() {
  echo "FAIL: $*" >&2
  exit 1
}

cd "$ROOT_DIR"

bash_scripts() {
  printf '%s\n' bootstrap.sh scripts/*.sh bin/*.sh ai/skills/*/scripts/*.sh
}

if command -v shellcheck >/dev/null 2>&1; then
  log "shellcheck"
  # shellcheck disable=SC2046 # word splitting of the file list is intended
  shellcheck -x -P SCRIPTDIR $(bash_scripts)
else
  log "shellcheck not installed; skipping lint"
fi

log "bash syntax"
for f in $(bash_scripts); do
  bash -n "$f" || fail "bash syntax: $f"
done

log "zsh syntax"
zsh -n shell/zshrc shell/*.zsh shell/zshrc.local.template

python_files() {
  printf '%s\n' ai/claude/hooks/*.py ai/skills/*/scripts/*.py
}

if command -v python3 >/dev/null 2>&1; then
  log "python syntax"
  # shellcheck disable=SC2046 # word splitting of the file list is intended
  python3 -c 'import ast, sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]' $(python_files) ||
    fail "python syntax"
fi

# `ruff --version` instead of `command -v`: a pyenv shim exists even when the active env lacks ruff.
if ruff --version >/dev/null 2>&1; then
  log "ruff"
  # Pinned rule set (pyflakes + syntax errors) so results don't depend on the ruff version or user config.
  # shellcheck disable=SC2046 # word splitting of the file list is intended
  ruff check --quiet --isolated --no-cache --select E4,E7,E9,F $(python_files)
else
  log "ruff not installed; skipping python lint"
fi

# Fresh machine simulation: copy the repo into a temporary $HOME, then drop every git-ignored
# file (*.local, *.local.yaml, private/, ...) from the copy so templates are exercised.
TEST_HOME="$(mktemp -d)"
trap 'rm -rf "$TEST_HOME"' EXIT
mkdir -p "$TEST_HOME/.config"
cp -R "$ROOT_DIR" "$TEST_HOME/.config/dotfiles"
TEST_HOME="$(cd "$TEST_HOME" && pwd -P)"
[[ "$(git -C "$TEST_HOME/.config/dotfiles" rev-parse --show-toplevel)" == "$TEST_HOME/.config/dotfiles" ]] ||
  fail "repo copy does not resolve to its own worktree; refusing to git clean"
git -C "$TEST_HOME/.config/dotfiles" clean -fdXq

# Pre-existing configs with the same basename must both survive as backups.
mkdir -p "$TEST_HOME/.config/git" "$TEST_HOME/.config/ghostty"
echo old-git >"$TEST_HOME/.config/git/config"
echo old-ghostty >"$TEST_HOME/.config/ghostty/config"

log "bootstrap (fresh)"
HOME="$TEST_HOME" "$TEST_HOME/.config/dotfiles/bootstrap.sh" --skip-shell >/dev/null

log "backups"
for backup in .config/git/config:old-git .config/ghostty/config:old-ghostty; do
  grep -qx "${backup#*:}" "$TEST_HOME"/.backups/dotfiles/*/"${backup%%:*}" || fail "backup lost: ~/${backup%%:*}"
done

log "bootstrap (idempotent)"
rerun="$(HOME="$TEST_HOME" "$TEST_HOME/.config/dotfiles/bootstrap.sh" --skip-shell)"
if grep -E '^(Linking|Backing up)' <<<"$rerun"; then
  fail "second bootstrap run changed links"
fi

log "symlinks"
for link in .zshrc .gitconfig .config/git/config .tmux.conf .config/starship.toml .config/nvim \
  .config/ghostty/config .claude/CLAUDE.md .claude/settings.json .claude/hooks .claude/skills/python-patterns \
  .copilot/copilot-instructions.md .agents/skills \
  .local/bin/clip .local/bin/awsme-sso; do
  [[ -L "$TEST_HOME/$link" && -e "$TEST_HOME/$link" ]] || fail "missing or broken link: ~/$link"
done

log "local files from templates"
for local in git/gitconfig.local aws/config.local kube/config.eks.local.yaml shell/zshrc.local; do
  [[ -f "$TEST_HOME/.config/dotfiles/$local" ]] || fail "not created from template: $local"
done

log "claude hooks"
if command -v python3 >/dev/null 2>&1; then
  hook="$TEST_HOME/.claude/hooks/git-guard.py"
  repo="$TEST_HOME/hook-repo"
  git init -q -b main "$repo"
  allows() { printf '{"tool_input":{"command":"%s"},"cwd":"%s"}' "$1" "$repo" | "$hook" 2>/dev/null; }
  allows 'git commit -m \"add config\"' && fail "git-guard allowed a commit on main"
  allows 'git switch -c feat/new-config' || fail "git-guard rejected a valid branch name"
  allows 'git switch -c New_Config' && fail "git-guard allowed a badly named branch"
  git -C "$repo" switch -q -c feat/new-config
  allows 'git commit -m \"feat/new-config: add config\"' || fail "git-guard rejected a valid commit"
  allows 'git commit -m \"feat/new-config: Add config\"' && fail "git-guard allowed an uppercase message"
  allows 'git push origin feat/new-config:main' && fail "git-guard allowed a push to main"
  # Claude Code may run hooks with macOS's /usr/bin/python3 (3.9): the guard must still load and block.
  if [[ "$(uname -s)" == Darwin ]] && xcode-select -p >/dev/null 2>&1 && [[ -x /usr/bin/python3 ]] &&
    [[ "$(/usr/bin/python3 -c 'import sys; print(sys.executable)')" != "$(python3 -c 'import sys; print(sys.executable)')" ]]; then
    rc=0
    printf '{"tool_input":{"command":"git commit -m \\"feat/new-config: Add config\\""},"cwd":"%s"}' "$repo" |
      /usr/bin/python3 -I "$hook" 2>/dev/null || rc=$?
    [[ $rc -eq 2 ]] || fail "git-guard did not block under /usr/bin/python3 (exit $rc)"
  fi
  [[ -f "$TEST_HOME/.config/dotfiles/ai/corrections.local.md" ]] || fail "corrections log not created from template"
  printf '{"prompt":"never do that again"}' | "$TEST_HOME/.claude/hooks/correction-check.py" | grep -q correction-check ||
    fail "correction-check hook ignored a correction"
  [[ -z "$(printf '{"prompt":"list the files"}' | "$TEST_HOME/.claude/hooks/correction-check.py")" ]] ||
    fail "correction-check hook fired on a normal prompt"
  handoff="$TEST_HOME/.claude/hooks/session-handoff.py"
  starts() { printf '{"cwd":"%s"}' "$1" | "$handoff"; }
  mkdir -p "$repo/.handoff" && echo "# goal: new config" >"$repo/.handoff/feat-new-config.md"
  starts "$repo" | grep -q "goal: new config" || fail "session-handoff did not load the branch doc"
  grep -qx "/.handoff/" "$repo/.git/info/exclude" || fail "session-handoff did not exclude .handoff/"
  [[ -z "$(git -C "$repo" status --porcelain)" ]] || fail "local .handoff/ shows up in git status"
  shared="$TEST_HOME/handoff-shared" && git init -q -b main "$shared" && touch "$shared/AGENTS.md"
  git -C "$shared" add AGENTS.md
  starts "$shared" | grep -q "Mode: committed" || fail "session-handoff missed a tracked AGENTS.md"
  ! grep -qx "/.handoff/" "$shared/.git/info/exclude" || fail "session-handoff excluded a committed .handoff/"
  [[ -z "$(starts "$TEST_HOME")" ]] || fail "session-handoff printed outside a git repo"
else
  log "python3 not installed; skipping claude hook tests"
fi

log "git config layers"
[[ "$(HOME="$TEST_HOME" git config --global --get user.name)" == "John Doe" ]] || fail "identity not read from ~/.gitconfig"
[[ "$(HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" git config --get alias.st)" == "status" ]] ||
  fail "shared aliases not read from ~/.config/git/config"

log "interactive zsh startup"
startup_output="$(cd "$TEST_HOME" && HOME="$TEST_HOME" TERM=xterm-256color zsh -i -c 'print -r -- "AWS=$AWS_CONFIG_FILE"' 2>&1)"
[[ "$startup_output" == "AWS=$TEST_HOME/.config/dotfiles/aws/config.local" ]] ||
  fail "zsh startup printed errors or did not set AWS_CONFIG_FILE:"$'\n'"$startup_output"

log "all checks passed"
