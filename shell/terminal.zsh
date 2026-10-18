#!/bin/zsh

setopt magicequalsubst
setopt nonomatch
setopt notify
setopt numericglobsort
setopt promptsubst

# Source a zsh plugin from Homebrew or the distro package location (e.g. Fedora's /usr/share).
__source_plugin() {
  local name="$1" file="$2" dir
  for dir in ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share} /usr/share /usr/local/share; do
    if [[ -r "$dir/$name/$file" ]]; then
      source "$dir/$name/$file"
      return 0
    fi
  done
  return 1
}

# zsh-autocomplete runs compinit itself; without it (e.g. not packaged by dnf), init completion here.
if ! __source_plugin zsh-autocomplete zsh-autocomplete.plugin.zsh; then
  autoload -Uz compinit && compinit
fi
__source_plugin zsh-autosuggestions zsh-autosuggestions.zsh
__source_plugin zsh-syntax-highlighting zsh-syntax-highlighting.zsh
unfunction __source_plugin

(( $+commands[starship] )) && source <(starship init zsh)

export PYENV_ROOT="$HOME/.pyenv"
export VIRTUAL_ENV_DISABLE_PROMPT="true" # starship shows the virtualenv instead
[[ -d $PYENV_ROOT/bin ]] && path=("$PYENV_ROOT/bin" $path)
if (( $+commands[pyenv] )); then
  source <(pyenv init -)
  (( $+commands[pyenv-virtualenv-init] )) && source <(pyenv virtualenv-init -)
fi
