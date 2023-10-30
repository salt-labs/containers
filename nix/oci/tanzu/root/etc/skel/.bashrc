#!/usr/bin/env bash

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in

*i*) ;;

*) return ;;

esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth
HISTFILESIZE=100000
HISTIGNORE='sops'
HISTSIZE=10000

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot-}" ] && [ -r /etc/debian_chroot ]; then
	debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
	if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
		# We have color support; assume it's compliant with Ecma-48
		# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
		# a case would tend to support setf rather than setaf.)
		color_prompt=yes
	else
		color_prompt=
	fi
fi

if [ "$color_prompt" = yes ]; then
	PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
	PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm* | rxvt*)
	PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
	;;
*) ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then

	if [[ -r ~/.dircolors ]]; then
		eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
	fi

	alias ls='ls --color=auto'
	alias dir='dir --color=auto'
	alias vdir='vdir --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'

	#colored GCC warnings and errors
	export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
	# shellcheck disable=SC1090
	. ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		# shellcheck disable=SC1091
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		# shellcheck disable=SC1091
		. /etc/bash_completion
	elif [ -f /etc/profile.d/bash_completion.sh ]; then
		# shellcheck disable=SC1091
		. /etc/profile.d/bash_completion.sh
	fi
fi

#########################
# Custom
#########################

# shellcheck disable=SC1091
source functions.sh || {
	echo "Failed to import required common functions!"
	exit 1
}

# Make sure the wrappers are the first in the PATH
if [[ -d "/run/wrappers/bin" ]]; then

	writeLog "DEBUG" "Wrappers dir found, checking PATH"

	if ! grep "/run/wrappers/bin" <<<"${PATH}"; then

		writeLog "DEBUG" "Adding wrappers dir to PATH"
		export PATH=/run/wrappers/bin:$PATH

	else

		writeLog "DEBUG" "Wrappers dir already in PATH"

	fi

else

	writeLog "DEBUG" "Wrappers dir not found"

fi

# Load all the custom scripts.
if [[ -d "${HOME}/.config/bash" ]]; then

	for FILE in "${HOME}/.config/bash/"*.sh; do

		writeLog "DEBUG" "Sourcing file ${FILE}"
		if [[ -r ${FILE} ]]; then

			# shellcheck disable=SC1090
			source "${FILE}" || {
				writeLog "ERROR" "Failed to load file ${FILE}"
			}

		fi

	done
	unset FILE

fi

# Make sure that the interactive parts are not run in a a VSCode remote env.
if [[ ${ENVIRONMENT_VSCODE^^} == "CONTAINER" ]]; then

	writeLog "INFO" "Devcontainer running, skipping interactive config"

else

	# Starship
	if [[ ${ENABLE_STARSHIP:-FALSE} == "TRUE" ]]; then

		writeLog "INFO" "Launching Starship"

		# shellcheck disable=SC1090
		source <(/bin/starship init bash)

	else

		writeLog "DEBUG" "Starship prompt is disabled"

	fi

fi

writeLog "INFO" "Logging into Tanzu Tools environment: ${ENVIRONMENT_VSCODE}"

#########################
# Tanzu
#########################

# shellcheck disable=SC1091
source tanzu.sh || {
	writeLog "ERROR" "Failed to launch Tanzu CLI script"
	exit 1
}
