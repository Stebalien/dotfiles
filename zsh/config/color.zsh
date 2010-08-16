#!/bin/zsh
autoload colors zsh/terminfo
if [[ "$terminfo[colors]" -ge 8 ]]; then
    colors
    
    # ls
    alias ls='ls -hF --color=auto --group-directories-first'
    eval $(dircolors -b)
    
    # Grep
    export GREP_OPTIONS="--color=auto --binary-files=without-match --directories=skip"
    
    # Diff
    function diff() {
        if [[ -t 1 ]]; then
            colordiff $@
        else
            command diff $@
        fi
    }
    # Less
    LESS_TERMCAP_mb=$'\E[01;31m'
    LESS_TERMCAP_md=$'\E[01;38;5;74m'
    LESS_TERMCAP_me=$'\E[0m'
    LESS_TERMCAP_se=$'\E[0m'
    LESS_TERMCAP_so=$'\E[38;5;246m'
    LESS_TERMCAP_ue=$'\E[0m'
    LESS_TERMCAP_us=$'\E[04;38;5;146m'
fi

