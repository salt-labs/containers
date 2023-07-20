#!/usr/bin/env bash

set -m

# Variables
export YTT_LIB="/usr/lib/ytt/"

# HACK: A better method is needed.
# Check for a proxy settings script.
if [[ ${ENABLE_PROXY_SCRIPT:-FALSE} == "TRUE" ]]; then

	if [[ -f "${WORKDIR}/scripts/proxy.sh" ]]; then

		echo "Loading proxy settings from ${WORKDIR}/scripts/proxy.sh"

		source "${WORKDIR}/scripts/proxy.sh" || {
			echo "Failed to load proxy settings"
			exit 1
		}

		proxy_on || {
			echo "Failed to enable proxy settings"
			exit 1
		}

	else

		echo "Proxy settings are enabled but ${WORKDIR}/scripts/proxy.sh does not exist. Have you mounted the bind volume?"
		exit 1

	fi

else

	echo "The Proxy script is not enabled, assuming direct internet access."

fi

# We need more than one check due to bind mounts.
# The rules that define whether the CLI has been "initialized" are:
if [[ -f "${HOME}/.config/tanzu/config.yaml" ]]; then

	if [[ -d "${HOME}/.config/tanzu/tkg" ]]; then

		if [[ -f "${HOME}/.config/tanzu/tkg/config.yaml" ]]; then
			TANZU_CLI_INIT_DONE="TRUE"
		fi

	fi

fi

# Initialise the Tanzu CLI
if [[ ${TANZU_CLI_INIT_DONE:-FALSE} == "TRUE" ]]; then

	echo "Tanzu CLI is already initialised."

else

	while true; do

		clear
		read -r -p "Initialise the Tanzu CLI? y/n: " CHOICE

		case $CHOICE in

		[Yy]*)

			echo "Initialising Tanzu CLI..."

			tanzu plugin clean || {
				echo "Failed to clean the Tanzu CLI plugins"
			}

			# HACK: A better method is needed, perhaps interactive 'tanzu plugin source'
			if [[ ${TANZU_PULL_THROUGH_CACHE:-EMPTY} == "EMPTY" ]]; then

				echo "No pull-through prefix provided, using default."

			else

				echo "Pull-through prefix provided, prefixing ${TANZU_PULL_THROUGH_CACHE}"

				# Capture existing OCI URL
				TANZU_CLI_OCI_URL="$(cat "${HOME}/.config/tanzu/config.yaml" | yq '.clientOptions.cli.discoverySources.[0].oci.image')"

				# Add the pull-through cache OCI URL
				tanzu plugin source add \
					--name pull-through-cache \
					--type oci \
					--uri "${TANZU_PULL_THROUGH_CACHE}/${TANZU_CLI_OCI_URL}" || {
					echo "Failed to add the pull-through cache Tanzu CLI plugin source"
				}

			fi

			tanzu init || {
				echo "Failed to initialise the Tanzu CLI using configured sources."
				echo "Please check network connectivity and try running 'tanzu init' again."
			}

			tanzu plugin sync || {
				echo "Failed to synchronise Tanzu CLI plugins"
			}

			break

			;;

		[Nn]*)

			echo "Skipping Tanzu CLI initialisation"
			break

			;;

		*)

			echo "Please answer yes or no."
			sleep 3

			;;

		esac
	done
fi

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
# The workaround is fragile.

if shopt -q progcomp; then

	echo "Loading bash completions into current shell..."

	for BIN in "${BINS[@]}"; do

		source <(${BIN} completion bash) || {
			echo "Failed to source bash completion for ${BIN}, skipping."
		}

	done

fi

figlet "Tanzu CLI"
