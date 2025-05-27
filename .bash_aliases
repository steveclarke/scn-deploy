# Source these by adding to your `~/.bashrc`:
# if [ -f ~/docker/scn/.bash_aliases ]; then
#     . ~/docker/scn/.bash_aliases
# fi

alias c="cd \$HOME/docker/scn"
alias ff="clear"
alias dc="docker compose"
alias dps="docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Networks}}\t{{.State}}'"
