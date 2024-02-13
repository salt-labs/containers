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

function k8s_tools_setup_gpg_and_pass() {

	export GNUPGHOME="${HOME}/.gnupg"

	local GPG_USER="Container User"
	local GPG_TEMP

	# Ensure that keyboxd is disabled as this is currently buggy.
	if [[ -f "${GNUPGHOME}/common.conf" ]]; then

		writeLog "WARN" "Disabling gpg keyboxd"
		sed -i "s/^use-keyboxd/#use-keyboxd/g" "${GNUPGHOME}/common.conf" || true

	fi

	# Reload the gpg-agent
	gpg-connect-agent --verbose reloadagent /bye 1>>"${LOG_FILE}" 2>&1 || {

		writeLog "ERROR" "Failed to start the gpg agent"
		return 1

	}

	# NOTE: If you need to clear the pass store.
	# 		pass rm -r docker-credential-helpers

	# If gpg is already setup, skip this function.
	if gpg --list-keys "$GPG_USER" >/dev/null 2>&1; then

		writeLog "INFO" "Existing gpg key found for $GPG_USER"
		return 0

	else

		writeLog "WARN" "No existing gpg key found for $GPG_USER, creating one now..."

	fi

	# Create a temporary working space.
	GPG_TEMP="$(mktemp -d)"

	cat <<-EOF >"${GPG_TEMP}/gpg_key.conf"
		%echo Generating a basic OpenPGP key
		Key-Type: eddsa
		Key-Curve: Ed25519
		Key-Usage: cert
		Subkey-Type: ecdh
		Subkey-Curve: Curve25519
		Subkey-Usage: encrypt
		Name-Real: ${GPG_USER}
		Name-Comment: ${GPG_USER}
		Name-Email: user@container.lan
		Expire-Date: 0
		%no-ask-passphrase
		%no-protection
		%commit
		%echo done
	EOF

	writeLog "INFO" "Generating gpg key"

	gpg2 --verbose --batch --generate-key "${GPG_TEMP}/gpg_key.conf" || {

		writeLog "ERROR" "Failed to generate gpg key"
		return 1

	}

	writeLog "INFO" "Listing gpg keys"

	gpg --list-keys 1>>"${LOG_FILE}" 2>&1 || {

		writeLog "ERROR" "Failed to show gpg keys"
		return 1

	}

	writeLog "INFO" "Initializing the pass CLI"

	pass init "${GPG_USER}" || {

		writeLog "ERROR" "Failed to initialize the pass CLI for user ${GPG_USER}"
		return 1

	}

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

	# Storing secrets in plaintext is bad, setup gpg so ephemeral OCI secrets can at least use pass.
	k8s_tools_setup_gpg_and_pass || {

		MESSAGE="Failed to setup gpg for the Container user."
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
