#!/usr/bin/env bash

##################################################
# Name: color
# Description: Yes, its the american spelling in this context.
##################################################

# Feature flag for color to be enabled
# only if tput is in the PATH.
declare -x COLOR_ENABLED

if checkBin tput; then
	COLOR_ENABLED=TRUE
else
	COLOR_ENABLED=FALSE
fi

# Colour GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Foreground Colours

declare -x fgRed
fgRed="\001$(tput setaf 1)\002"

declare -x fgGreen
fgGreen="\001$(tput setaf 2)\002"

declare -x fgBlue
fgBlue="\001$(tput setaf 4)\002"

declare -x fgMagenta
fgMagenta="\001$(tput setaf 5)\002"

declare -x fgYellow
fgYellow="\001$(tput setaf 3)\002"

declare -x fgCyan
fgCyan="\001$(tput setaf 6)\002"

declare -x fgWhite
fgWhite="\001$(tput setaf 7)\002"

declare -x fgBlack
fgBlack="\001$(tput setaf 0)\002"

# Background Colours

declare -x bgRed
bgRed="\001$(tput setab 1)\002"

declare -x bgGreen
bgGreen="\001$(tput setab 2)\002"

declare -x bgBlue
bgBlue="\001$(tput setab 4)\002"

declare -x bgMagenta
bgMagenta="\001$(tput setab 5)\002"

declare -x bgYellow
bgYellow="\001$(tput setab 3)\002"

declare -x bgCyan
bgCyan="\001$(tput setab 6)\002"

declare -x bgWhite
bgWhite="\001$(tput setab 7)\002"

declare -x bgBlack
bgBlack="\001$(tput setab 0)\002"

# Other Colours

declare -x bgBlink
bgBlink="\001$(tput blink)\002"

# Reset

declare -x fgReset
fgReset="\001$(tput sgr0)\002"

declare -x bgReset
bgReset="\001$(tput sgr0)\002"
