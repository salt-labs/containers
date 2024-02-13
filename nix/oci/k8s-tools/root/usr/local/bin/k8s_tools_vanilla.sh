#!/usr/bin/env bash

##################################################
# Name: k8s_tools_vanilla.sh
# Description: Kubernetes helper functions.
##################################################

function k8s_tools_distro_launch() {

	# Make sure job control is on
	set -m

	dialogProgress "${K8S_TOOLS_TITLE}: Launching..." "10"

	# Use vendir to sync vendored dependencies
	if [[ ${VENDOR_ENABLED:-FALSE} == "TRUE" ]]; then

		vendor_sync || {
			MESSAGE="Failed to sync vendored dependencies with vendir"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1
		}

		# If there is vendored scripts, add them to the path.
		vendor_path || {
			MESSAGE="Failed to update the PATH variable for vendored dependencies"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1
		}

	else

		writeLog "INFO" "${K8S_TOOLS_TITLE} is not enabled to sync vendored depencendies, skipping."

	fi

	# TODO: Do Kubernetes stuff here...

	dialogProgress "${K8S_TOOLS_TITLE}: Launching..." "100"

	tput clear

}
