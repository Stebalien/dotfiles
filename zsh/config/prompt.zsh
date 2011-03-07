#!/bin/zsh

typeset -ga precmd_functions
typeset -ga chpwd_functions

# git branch
export __CURRENT_GIT_BRANCH=
parse_git_branch() {
        [[ $(git status -s 2>/dev/null |wc -l) -gt 0 ]] && local color="%{$fg[yellow]%}" || local color="%{$fg[green]%}"
        git branch --no-color 2> /dev/null \
            | sed -ne "s/^\* \(.*\)$/${color} (\1${changed})%{$reset_color%}/p"
}

precmd_functions+='zsh_precmd_update_git_vars'
zsh_precmd_update_git_vars() {
        case "$(history $(($HISTCMD-1)))" in 
                *git*)
                export __CURRENT_GIT_BRANCH="$(parse_git_branch)"
                ;;
        esac
}

chpwd_functions+='zsh_chpwd_update_git_vars'
zsh_chpwd_update_git_vars() {
        export __CURRENT_GIT_BRANCH="$(parse_git_branch)"
}

get_git_prompt_info() {
        echo "$__CURRENT_GIT_BRANCH"
}

setopt PROMPT_SUBST

PROMPT="
%{$fg_bold[black]%}┌╸%{$fg_no_bold[blue]%}%n%{$fg_bold[black]%}╺─╸%{$fg_no_bold[cyan]%}%~\$(get_git_prompt_info)%{$fg_bold[black]%}╺%{$fg[green]%}%(1j: %j:)
%{$fg_bold[black]%}└─╍ %{$reset_color%}"
# \$(sudo -n true 2>/dev/null && echo '%{$fg[green]%}')

PROMPT2="%{$fg_bold[black]%}[s[1A├[1B[1D└─╍ %{$reset_color%}"
