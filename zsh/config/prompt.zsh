#!/bin/zsh

# GIT
autoload -Uz vcs_info
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '%F{8}+%F{3}s'
zstyle ':vcs_info:*' unstagedstr '%F{8}+%F{1}u'
zstyle ':vcs_info:*' actionformats ' %F{8}[%F{10}%b%c%u%F{8}|%F{1}%a%F{8}]%f'
zstyle ':vcs_info:*' formats       ' %F{8}[%F{10}%b%c%u%F{8}]%f'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
zstyle ':vcs_info:*' enable git
precmd () { vcs_info }

setopt PROMPT_SUBST

PROMPT="
%{$fg_bold[black]%}┌╸%{$fg_no_bold[blue]%}%n%{$fg_bold[black]%}╺─╸%{$fg_no_bold[cyan]%}%~\${vcs_info_msg_0_}%{$fg_bold[black]%}╺%{$fg[green]%}%(1j: %j:)
%{$fg_bold[black]%}└─\$(sudo -n true 2>/dev/null && echo '%{$fg[green]%}')╍ %{$reset_color%}"


PROMPT2="%{$fg_bold[black]%}[s[1A├[1B[1D└─╍ %{$reset_color%}"
