#!/bin/zsh

#typeset -ga precmd_functions
#typeset -ga chpwd_functions

# git branch
#export __CURRENT_GIT_BRANCH=
#parse_git_branch() {
#        [[ $(git status -s 2>/dev/null |wc -l) -gt 0 ]] && local color="%{$fg[yellow]%}" || local color="%{$fg[green]%}"
#        git branch --no-color 2> /dev/null \
#            | sed -ne "s/^\* \(.*\)$/${color} (\1${changed})%{$reset_color%}/p"
#}
#
#precmd_functions+='zsh_precmd_update_git_vars'
#zsh_precmd_update_git_vars() {
#        case "$(history $(($HISTCMD-1)))" in 
#                *git*)
#                export __CURRENT_GIT_BRANCH="$(parse_git_branch)"
#                ;;
#        esac
#}
#
#chpwd_functions+='zsh_chpwd_update_git_vars'
#zsh_chpwd_update_git_vars() {
#        export __CURRENT_GIT_BRANCH="$(parse_git_branch)"
#}
#
#get_git_prompt_info() {
#        echo "$__CURRENT_GIT_BRANCH"
#}

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

#PROMPT="
#%{$fg_bold[black]%}┌╸%{$fg_no_bold[blue]%}%n%{$fg_bold[black]%}╺─╸%{$fg_no_bold[cyan]%}%~\$(get_git_prompt_info)%{$fg_bold[black]%}╺%{$fg[green]%}%(1j: %j:)
#%{$fg_bold[black]%}└─╍ %{$reset_color%}"
PROMPT="
%{$fg_bold[black]%}┌╸%{$fg_no_bold[blue]%}%n%{$fg_bold[black]%}╺─╸%{$fg_no_bold[cyan]%}%~\${vcs_info_msg_0_}%{$fg_bold[black]%}╺%{$fg[green]%}%(1j: %j:)
%{$fg_bold[black]%}└─\$(sudo -n true 2>/dev/null && echo '%{$fg[green]%}')╍ %{$reset_color%}"


PROMPT2="%{$fg_bold[black]%}[s[1A├[1B[1D└─╍ %{$reset_color%}"
