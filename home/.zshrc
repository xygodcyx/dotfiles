export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="jonathan"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf z)

source $ZSH/oh-my-zsh.sh

[ -s "/home/lyorn/.bun/_bun" ] && source "/home/lyorn/.bun/_bun"
# bun
export BUN_INSTALL="$HOME/.bun"
# rust
export RUST_INSTALL="$HOME/.cargo"
#path
export PATH="$BUN_INSTALL/bin:$RUST_INSTALL/bin:$PATH:"
