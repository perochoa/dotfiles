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
  .config/ghostty/config .aws/config .claude/CLAUDE.md .claude/settings.json .claude/hooks .claude/skills/gitlab-cli \
  .claude/agents/architecture-auditor.md .claude/agents/architecture-implementer.md \
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
  # Mid-rebase HEAD is detached; the branch comes from the rebase state.
  git -C "$repo" -c user.name=check -c user.email=check@example.invalid commit -q --allow-empty -m "feat/new-config: base"
  git -C "$repo" switch -q --detach
  mkdir -p "$repo/.git/rebase-merge" && echo refs/heads/feat/new-config >"$repo/.git/rebase-merge/head-name"
  allows 'git commit -m \"feat/new-config: add config during rebase\"' || fail "git-guard rejected a valid commit mid-rebase"
  allows 'git commit -m \"add config during rebase\"' && fail "git-guard dropped the prefix rule mid-rebase"
  rm -r "$repo/.git/rebase-merge" && git -C "$repo" switch -q feat/new-config
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
  # audit-gate: the implementer only applies reports recorded from the auditor, within their files.
  gate="$TEST_HOME/.claude/hooks/audit-gate.py"
  audits="$TEST_HOME/.claude/audits"
  arepo="$TEST_HOME/audit-repo"
  git init -q -b main "$arepo" && mkdir -p "$arepo/src" "$arepo/docs"
  touch "$arepo/src/a.py" "$arepo/src/b.py" "$arepo/Makefile" "$arepo/docs/README.md"
  git -C "$arepo" add . && git -C "$arepo" -c user.name=check -c user.email=check@example.invalid commit -qm init
  gate_run() { HOME="$TEST_HOME" "$gate"; }
  json() { python3 -c 'import json, sys; a = sys.argv[1:]; print(json.dumps(dict(zip(a[::2], a[1::2]))))' "$@"; }
  pre() { # tool, input json, [agent]
    printf '{"hook_event_name":"PreToolUse","tool_name":"%s","tool_input":%s,"agent_type":"%s","cwd":"%s"}' "$1" "$2" "${3:-}" "$arepo" | gate_run
  }
  stop() { printf '{"hook_event_name":"SubagentStop","agent_type":"%s","cwd":"%s"}' "$1" "$arepo" | gate_run; }
  launch() { pre Agent "$(json subagent_type architecture-implementer prompt "$1")"; }
  edit() { pre Write "$(json file_path "$1")" architecture-implementer; }
  report=$'## 1. Executive Summary\nx\n## 2. Best Practices Audit\n| a | `src/a.py:3` |\n## 3. Refactoring & Simplification Roadmap\n1. delete `src/old/`\n2. edit `Makefile` and `README.md`\n## 4. Concrete Before-and-After Code Examples\nnone'
  json hook_event_name SubagentStop agent_type architecture-auditor cwd "$arepo" last_assistant_message "$report" | gate_run
  json hook_event_name SubagentStop agent_type Explore cwd "$arepo" last_assistant_message "${report/1\. /}x" | gate_run
  [[ "$(find "$audits" -name '*.md' | wc -l)" -eq 1 ]] || fail "audit-gate did not record exactly the auditor's report"
  launch "fix everything" | grep -q '"deny"' || fail "audit-gate launched the implementer without an audit"
  launch $'audit: 000000000000\nsteps: all' | grep -q '"deny"' || fail "audit-gate accepted an unrecorded audit"
  edit src/a.py | grep -q '"deny"' || fail "audit-gate let the implementer edit without a lease"
  launch $'audit: latest\nsteps: 1\nalso fix the readme' | grep -q '"deny"' || fail "audit-gate accepted extra instructions"
  launch $'audit: latest\nsteps: 1, 2-3' | grep -q 'Best Practices Audit' || fail "audit-gate did not hand the report to the implementer"
  [[ -z "$(edit src/a.py)" && -z "$(edit src/old/x.py)" ]] || fail "audit-gate blocked a cited file"
  edit src/b.py | grep -q '"deny"' || fail "audit-gate allowed an uncited file"
  [[ -z "$(edit Makefile)" && -z "$(edit README.md)" ]] || fail "audit-gate blocked a cited root file"
  edit docs/README.md | grep -q '"deny"' || fail "audit-gate matched a bare file name outside the root"
  [[ -z "$(pre Write "$(json file_path src/b.py)")" ]] || fail "audit-gate restricted another agent"
  pre Write "$(json file_path "$audits/forged.md")" | grep -q '"deny"' || fail "audit-gate allowed writing the registry"
  pre Bash "$(json command "echo x >$audits/forged.md")" | grep -q '"deny"' || fail "audit-gate allowed a shell write to the registry"
  [[ -z "$(pre Bash "$(json command "ls $audits")")" ]] || fail "audit-gate blocked reading the registry"
  echo changed >"$arepo/src/a.py" && echo changed >"$arepo/src/b.py"
  stop architecture-implementer | grep -q '"block"' || fail "audit-gate let the implementer stop with uncited changes"
  git -C "$arepo" checkout -q src/b.py
  [[ -z "$(stop architecture-implementer)" && -z "$(ls -A "$audits/leases")" ]] ||
    fail "audit-gate did not release the lease on a clean stop"
  edit src/a.py | grep -q '"deny"' || fail "audit-gate kept allowing edits after the lease was released"
  # A report sent through SubagentHandback is only in the auditor's own transcript.
  handback="$TEST_HOME/auditor.jsonl"
  python3 -c 'import json, sys; print(json.dumps({"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "SubagentHandback", "input": {"message": sys.argv[1]}}]}}))' \
    "${report/none/handed back}" >"$handback"
  json hook_event_name SubagentStop agent_type architecture-auditor cwd "$arepo" last_assistant_message "" \
    transcript_path "$TEST_HOME/parent.jsonl" agent_transcript_path "$handback" | gate_run
  [[ "$(find "$audits" -name '*.md' | wc -l)" -eq 2 ]] || fail "audit-gate did not record a handed-back report"
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

# brew on PATH without HOMEBREW_PREFIX (e.g. PATH set by ~/.profile) must still load the zsh plugins
if command -v brew >/dev/null 2>&1 && [[ -d "$(brew --prefix)/share/zsh-syntax-highlighting" ]]; then
  log "zsh plugins without HOMEBREW_PREFIX"
  # shellcheck disable=SC2016 # expanded by the inner zsh
  highlighting="$(cd "$TEST_HOME" && env -u HOMEBREW_PREFIX HOME="$TEST_HOME" TERM=xterm-256color \
    PATH="$(dirname "$(command -v brew)"):/usr/bin:/bin" zsh -i -c 'print -r -- ${+ZSH_HIGHLIGHT_VERSION}' 2>&1)"
  [[ "$highlighting" == "1" ]] || fail "zsh-syntax-highlighting not loaded without HOMEBREW_PREFIX:"$'\n'"$highlighting"
fi

log "all checks passed"
