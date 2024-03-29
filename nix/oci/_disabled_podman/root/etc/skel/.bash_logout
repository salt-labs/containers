# ~/.bash_logout: executed by bash(1) when login shell exits.

# when leaving the console clear the screen to increase privacy

if [ "$SHLVL" = 1 ]; then
	[ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi

echo "$(date '+%Y/%m/%d %T'): INFO: Logout of Devcontainer Environment: ${ENVIRONMENT_VSCODE}" >> "/tmp/environment.log"
