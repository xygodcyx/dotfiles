export ZSH="$HOME/.oh-my-zsh"

# ZSH_THEME="jonathan"
# ZSH_THEME="trapd00r"
ZSH_THEME="nicoulaj"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf z)

source $ZSH/oh-my-zsh.sh

[ -s "/home/lyorn/.bun/_bun" ] && source "/home/lyorn/.bun/_bun"

# pnpm
export PNPM_HOME="/home/lyorn/.local/share/pnpm"
# bun
export BUN_INSTALL="$HOME/.bun"
# rust
export RUST_INSTALL="$HOME/.cargo"
#platform-tools
# export PLATFORM_TOOLS="/home/lyorn/Apps/platform-tools"
#path
export PATH="/home/lyorn/.local/bin:$BUN_INSTALL/bin:$RUST_INSTALL/bin:$PNPM_HOME/bin:$PNPM_HOME:$PATH:"

# pnpm
export PNPM_HOME="/home/lyorn/.local/share/pnpm"

case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

export PATH="$HOME/Hardware/Esp/xtensa-esp32-elf/bin:$PATH"
export PATH="$HOME/Apps/Weport-1.0.0-x64:$PATH"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
export PATH="$HOME/Code/DevEnv/flutter/bin:$PATH"

export CHROME_EXECUTABLE="/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=/app/bin/chrome com.google.Chrome --password-store=basic
"

export ANDROID_HOME=~/Android/Sdk
export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

export PATH="$HOME/.volta/bin:$PATH"

#alias


alias cr="cargo run"
alias cc="cargo check"
alias cb="cargo build"
alias cbr="cargo build --release"
alias e="exit"
alias n="nvim"
alias m="make"
alias ll='ls -lh'
alias la='ls -lah'
alias snvim='sudo -E nvim'
alias sn='sudo -E nvim'

eval "$(direnv hook zsh)"

function help(){
    bash -c "help $@"
}

#bind
# bindkey '^ ' autosuggest-accept

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
