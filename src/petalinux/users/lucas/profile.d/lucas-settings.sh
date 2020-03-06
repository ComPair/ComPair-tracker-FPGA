#!/bin/bash

##export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '
export PS1="[\[\e[36m\]\u\[\e[m\]@\[\e[36m\]\h\[\e[m\]] \w\$ "

alias ls='ls --color=auto'
alias ll='ls -l'

alias python=python3

export ZYNQ=$HOME/zynq
export LOCAL=$HOME/local

export CFLAGS="-I$LOCAL/include -I$ZYNQ/include"
export CXXFLAGS="-I$LOCAL/include -I$ZYNQ/include"
export LDFLAGS="-L$LOCAL/lib -L$ZYNQ/lib"

export LD_LIBRARY_PATH=$LOCAL/lib:$ZYNQ/lib:${LD_LIBRARY_PATH}

export PATH=$ZYNQ/bin:$LOCAL/bin:$PATH
