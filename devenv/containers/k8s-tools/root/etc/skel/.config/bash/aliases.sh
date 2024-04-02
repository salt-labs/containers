#!/usr/bin/env bash

##################################################
# Name: aliases
# Description: Aliases loaded into the shell at startup
##################################################

##################
# Colorize
##################

# NOTE: ls -F uses these:
#   @ symbolic link
#   * executable
#   = socket
#   | named pipe
#   > door
#   / directory

# Use colours when possible
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias lla='ls -la'
alias llA='ls -lA'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

###################
# Dates
###################

# Dates for international timezones
alias date-utc='date --utc'
alias date-aus='export TZ=Australia/Sydney && date && export TZ=${TIMEZONE}'
alias date-dub='export TZ=Europe/Dublin && date && export TZ=${TIMEZONE}'
alias date-usa='export TZ=America/Lima && date && export TZ=${TIMEZONE}'

###################
# Git
###################

alias glog='git log --pretty="format:* %as %h %G? %aN - %s"'
alias glist='git ls-tree --full-tree -r --name-only'
alias git_tree_pull="find . -mindepth 1 -maxdepth 1 -type d -print -exec git -C {} pull \;"

##################
# Fonts
##################

alias fonts='fc-list --format="%{family[0]}\n" | sort | uniq'
