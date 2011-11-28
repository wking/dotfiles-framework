# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen!

# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
    # Shell is non-interactive.  Be done now!
    return
fi

#source .bashrc.d/local_paths

# If not running interactively, don't do anything else
[ -z "$PS1" ] && return

# don't put duplicate line in the history and ignore lines starting
# with a space.  See bash(1).
export HISTCONTROL=ignoreboth

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

source .bashrc.d/environment
#source .bashrc.d/screen
#source .bashrc.d/completion
#source .bashrc.d/nobeep
#source .bashrc.d/lesspipe
source .bashrc.d/ssh_agent
source .bashrc.d/gpg_agent

# load aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

source "${DOTFILES_DIR}/src/.bashrc.d/dotfiles"
