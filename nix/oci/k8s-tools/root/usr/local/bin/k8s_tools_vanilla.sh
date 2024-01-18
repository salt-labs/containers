#!/usr/bin/env bash

##################################################
# Name: k8s_tools_vanilla.sh
# Description: Kubernetes helper functions.
##################################################

function k8s_tools_distro_launch() {

	# Make sure job control is on
	set -m

	dialogProgress "${TANZU_TITLE}: Launching..." "10"

	# TODO: Do Kubernetes stuff here...

	dialogProgress "${TANZU_TITLE}: Launching..." "100"

	tput clear
	figlet "${TANZU_TITLE}"

}
