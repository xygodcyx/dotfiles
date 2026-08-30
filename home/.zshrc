export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="jonathan"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf z)

source $ZSH/oh-my-zsh.sh

[ -s "/home/lyorn/.bun/_bun" ] && source "/home/lyorn/.bun/_bun"

# pnpm
export PNPM_HOME="/home/lyorn/.local/share/pnpm"
# bun
export BUN_INSTALL="$HOME/.bun"
# rust
export RUST_INSTALL="$HOME/.cargo"
#path
export PATH="/home/lyorn/.local/bin:$BUN_INSTALL/bin:$RUST_INSTALL/bin:$PNPM_HOME/bin:$PNPM_HOME:$PATH:"

# pnpm
export PNPM_HOME="/home/lyorn/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

#alias

alias cr="cargo run"
alias cc="cargo check"
alias cb="cargo build"
alias cbr="cargo build --release"
