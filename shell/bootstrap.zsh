#!/bin/zsh

dotfiles_shell_dir="${0:A:h}"

source "${dotfiles_shell_dir}/env.zsh"
source "${dotfiles_shell_dir}/aliases.zsh"
source "${dotfiles_shell_dir}/functions.zsh"
source "${dotfiles_shell_dir}/terminal.zsh"

# Machine-specific overrides (untracked; matches *.local in .gitignore)
[[ -r "${dotfiles_shell_dir}/zshrc.local" ]] && source "${dotfiles_shell_dir}/zshrc.local"
