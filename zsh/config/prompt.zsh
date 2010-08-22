#!/bin/zsh

typeset -ga preexec_functions
typeset -ga precmd_functions
typeset -ga chpwd_functions

# git branch
export __CURRENT_GIT_BRANCH=
parse_git_branch() {
        git branch --no-color 2> /dev/null \
            | sed -ne "s/^\* \(.*\)$/%{$fg[green]%} (\1)%{$reset_color%}/p"
}

preexec_functions+='zsh_preexec_update_git_vars'
zsh_preexec_update_git_vars() {
        case "$(history $HISTCMD)" in 
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
%{$fg[black]$bold_color%}┌╸%b%{$fg[blue]%}%n%{$fg[black]$bold_color%}╺─╸%b%{$fg[cyan]%}%~\$(get_git_prompt_info)%{$fg[black]$bold_color%}╺%{$fg[green]%}%(1j: %j:)
%{$fg[black]$bold_color%}└─\$(sudo -n true 2>/dev/null && echo '%{$fg[green]%}')╍ %{$reset_color%}"

PROMPT2="%{$fg[black]$bold_color%}│%_├╍ %{$reset_color%}"
