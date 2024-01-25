#!/usr/bin/env bash

##################################################
# Name: k8s_tools.sh
# Description: Kubernetes tools helper functions.
##################################################

function k8s_tools_proxy() {

	# Allow proxy customizations via a user provided script.

	# HACK: A better method is needed.
	# Check for a user-proviced proxy settings script.
	if [[ ${K8S_TOOLS_ENABLE_PROXY_SCRIPT:-FALSE} == "TRUE" ]]; then

		if [[ -f "${WORKDIR}/scripts/proxy.sh" ]]; then

			writeLog "INFO" "Loading proxy settings from ${WORKDIR}/scripts/proxy.sh"

			# shellcheck disable=SC1091
			source "${WORKDIR}/scripts/proxy.sh" 1>>"${LOG_FILE}" 2>&1 || {
				writeLog "ERROR" "Failed to load proxy settings!"
			}

			proxy_on 1>>"${LOG_FILE}" 2>&1 || {
				writeLog "ERROR" "Failed to enable proxy settings!"
			}

		else

			writeLog "ERROR" "Proxy settings are enabled but ${WORKDIR}/scripts/proxy.sh does not exist. Have you mounted the bind volume?"
			return 1

		fi

	else

		writeLog "INFO" "Proxy script is disabled, assuming direct internet access or isolated environment."

	fi

	return 0

}

function k8s_tools_bash_completions() {

	dialogProgress "${K8S_TOOLS_TITLE}: Loading bash completions..." "25"

	# Binaries we need to source manual bash completions from.
	declare -r BINS=(
		clusterctl
		helm
		imgpkg
		kapp
		kctrl
		kubectl
		kustomize
		tanzu
		ytt
	)
	# TODO: vendir
	# vendir issue: https://github.com/carvel-dev/vendir/issues/275
	# The workaround is fragile...

	dialogProgress "${K8S_TOOLS_TITLE}: Loading bash completions..." "50"

	if shopt -q progcomp; then

		for BIN in "${BINS[@]}"; do

			# shellcheck disable=SC1090
			source <(${BIN} completion bash) || {
				writeLog "WARN" "Failed to source bash completion for ${BIN}, skipping..."
			}

		done

	fi

	dialogProgress "${K8S_TOOLS_TITLE}: Loading bash completions..." "100"

	return 0

}

# The main entrypoint.
function k8s_tools_launch() {

	dialogProgress "${K8S_TOOLS_TITLE}: Launching..." "0"

	# Some environments have proxy servers...
	k8s_tools_proxy || {
		MESSAGE="Failed to run user proxy configuration"
		writeLog "ERROR" "${MESSAGE}"
		dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
		return 1
	}

	# Run the necessary script based on the Kubernetes distro.
	# shellcheck disable=SC1090
	source "k8s_tools_${K8S_TOOLS_DISTRO:=undefined}.sh" || {

		MESSAGE="Failed to source necessary functions for Kubernetes distro ${K8S_TOOLS_DISTRO}"
		writeLog "ERROR" "${MESSAGE}"
		dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
		return 1

	}

	# Each distro has it's own launch function as the entrypoint.
	k8s_tools_distro_launch || {

		MESSAGE="Failed to launch configuration for Kubernetes distro ${K8S_TOOLS_DISTRO}"
		writeLog "ERROR" "${MESSAGE}"
		dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
		return 1

	}

}
export -f k8s_tools_launch
