# Place this file at the place:  ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

if [ $(whoami) != root ]
then
	PS1="\[\033[0;33m\]➜ \[\033[0;36m\]\u\[\033[0;32m\]@\[\033[0;32m\]\h\[\033[0;33m\]<\t> \[\033[00;35m\]\w\[\033[0;36m\] $ \[\033[0m\]"
else
	PS1="\[\033[0;33m\]➜ \[\033[0;31m\]\u\[\033[0;32m\]@\[\033[0;32m\]\h\[\033[0;33m\]<\t> \[\033[00;35m\]\w\[\033[0;31m\] # \[\033[0m\]"
fi

# PS1='[\u@\h \W]\$ '
