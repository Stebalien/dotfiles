#!/bin/zsh

sp_info() {
    if sudo -n true 2>/dev/null; then
        sp_arr="%{$fg[red]%}>"
    else
        sp_arr="%{$fg[blue]%}>"
    fi
}

bat_info() {
    local now=$(</sys/class/power_supply/BAT0/charge_now)
    local full=$(</sys/class/power_supply/BAT0/charge_full_design)

    if [[ $(((now*100)/full)) -lt 5 ]]; then
        bat_arr="%{$fg[yellow]%}>"
    else
        bat_arr=">"
    fi
}

# GIT
autoload -Uz vcs_info
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '%F{8}+%F{3}s'
zstyle ':vcs_info:*' unstagedstr '%F{8}+%F{1}u'
zstyle ':vcs_info:*' actionformats '%F{8}:%F{10}%b%c%u%F{8}|%F{1}%a%F{8}%f'
zstyle ':vcs_info:*' formats       '%F{8}:%F{10}%b%c%u%F{8}%f'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
zstyle ':vcs_info:*' enable git
precmd () { 
    vcs_info
    sp_info
    bat_info
}

setopt PROMPT_SUBST

PROMPT="
%{$fg_bold[black]%}[%{$fg_no_bold[blue]%}%~\${vcs_info_msg_0_}%{$fg_bold[black]%}]%{$fg[green]%}%(1j: %j:)
%{$fg_bold[black]%}>\${bat_arr}\${sp_arr} %{$reset_color%}"


PROMPT2="%{$fg_bold[black]%}%_ >> %{$reset_color%}"
