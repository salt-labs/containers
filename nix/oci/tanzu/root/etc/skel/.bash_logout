#!/usr/bin/env bash

# ~/.bash_logout: executed by bash(1) when login shell exits.

# when leaving the console clear the screen to increase privacy

if [ "$SHLVL" = 1 ]; then
	[ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

# HACK: Need to fix the UID > 65535 issue
chmod -R 0777 /home/tanzu || {
	writeLog "ERROR" "Failed to chmod 0777 on /home/tanzu"
	#exit 1
}

writeLog "INFO" "Logging out of Tanzu Tools environment: ${ENVIRONMENT_VSCODE}"
