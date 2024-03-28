#!/usr/bin/env bash

if [[ ${DEBUG_ENABLED:-FALSE} == "TRUE" ]]; then
	set -x
fi

#set -e
set -u
set -o pipefail

#########################
# Variables
#########################

# The name of the script used in logs.
export SCRIPT="${K8S_TOOLS_NAME:-k8s-tools}"

# Dialog boxes
export K8S_TOOLS_NAME="${K8S_TOOLS_NAME:-k8s-tools}"
export K8S_TOOLS_TITLE="${K8S_TOOLS_TITLE:-Kubernetes Tools}"

# Write all logs to file.
export LOG_DESTINATION="${LOG_DESTINATION:-file}"
export LOG_FILE="${LOG_FILE:-/tmp/$SCRIPT.log}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Interactive loop
export K8S_TOOLS_RUN=FALSE

# Dialog theme
export DIALOGRC="${HOME}/.dialogrc/${K8S_TOOLS_DIALOG_THEME:-default}"

# Preload libnss for uid > 65535
#export LD_PRELOAD=/lib/lib-sssd/libnss_sss.so.2

#########################
# Dependencies
#########################

# shellcheck disable=SC1091
source functions.sh || {
	echo "Failed to import required common functions!"
	exit 1
}

# shellcheck disable=SC1091
source dialog.sh || {
	writeLog "ERROR" "Failed to import required dialog functions!"
	exit_script 1
}

#########################
# Checks
#########################

# Make sure that the interactive parts are not run in a a VSCode container env.
# VSCode handles it's own userID mapping and mounts.
if [[ ${K8S_TOOLS_ENVIRONMENT^^} == "VSCODE" ]]; then

	while true; do

		writeLog "INFO "INFO: Devcontainer environment is running...
		sleep 60

	done

	writeLog "INFO" "Finished"

	exit 0

fi

#########################
# Setup
#########################

# In-case a user is bringing their own bind volume.
if [[ ! -f "/root/.profile" ]]; then

	writeLog "DEBUG" "Copying root users profile"

	rsync \
		--archive \
		--verbose \
		--copy-links \
		--exclude .config/tanzu-envs/ \
		--exclude .config/bash/custom.sh \
		/etc/skel/ /root \
		1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to rsync the root user's profile"
		exit_script 1
	}

else

	writeLog "INFO" "A profile already exists for user 'root', skipping setup"

fi

chown -R root:root /root || {
	writeLog "ERROR" "Failed to set owner to user 'root' on /root"
	exit_script 1
}

#########################
# Main
#########################

# Start a new login shell with any modified UID or GIDs applied.
dialogProgress "${K8S_TOOLS_TITLE}: Starting Shell..." "100"

if start_shell "$@"; then
	SHELL_EXIT_CODE=$?
	writeLog "INFO" "The initial shell session has terminated successfully."
else
	SHELL_EXIT_CODE=$?
	writeLog "ERROR" "The initial shell session has terminated with exit code ${SHELL_EXIT_CODE}"
fi

while true; do

	if [[ ${SHELL_EXIT_CODE:-0} -ne 0 ]]; then
		show_logs || true
		read -r -p "Press any key to continue."
	fi

	dialogYesNo "${K8S_TOOLS_TITLE}: Session Ended" "Would you like to start a new session?"

	#  0 = Yes
	#  1 = No
	#  2 = Help
	#  3 = Extra
	# -1 = Error

	"${CMD[@]}" "${BOX_OPTIONS[@]}" "${OPTIONS[@]}"
	RETURN_CODE=$?

	writeLog "DEBUG" "Dialog return: ${RETURN_CODE:-EMPTY}"

	case "${RETURN_CODE:-EMPTY}" in

	0) # YES

		writeLog "DEBUG" "Return code was ${RETURN_CODE}, user selected YES to starting new shell session"

		dialogProgress "${K8S_TOOLS_TITLE}: Starting Shell..." "100"

		if start_shell "$@"; then
			SHELL_EXIT_CODE=$?
			writeLog "INFO" "The shell session has terminated successfully."
		else
			SHELL_EXIT_CODE=$?
			writeLog "ERROR" "The shell session has terminated with exit code ${SHELL_EXIT_CODE}"
		fi

		;;

	1) # NO

		writeLog "DEBUG" "Return code was ${RETURN_CODE}, the user selected NO to starting new shell session."

		dialogProgress "${K8S_TOOLS_TITLE}: Exiting Shell..." "100"
		sleep 0.5

		break

		;;

	*) # NO IDEA

		writeLog "WARN" "Return code was ${RETURN_CODE}, the user either hit escape or there was an unhandled error starting new shell session"

		dialogProgress "${K8S_TOOLS_TITLE}: Only YES or NO are valid answers." "0"
		sleep 3

		;;

	esac

done

tput clear

figlet -c -f slant "Goodbye!"

exit 0
