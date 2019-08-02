# ~/.bashrc: executed by bash(1) for non-login shells.

export TERM=xterm-256color
export PS1='\u@\h: \e[33;1m\W\e[0m\$ '

# The following lines make `ls' colorized:
export LS_OPTIONS='--color=auto'
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'

# More and more useful history:
export HISTSIZE=50000
export HISTFILESIZE="${HISTSIZE}"
export HISTTIMEFORMAT="[%F %T] "
# Prefix command with a space to keep it out of history:
HISTCONTROL=ignorespace
