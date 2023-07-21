#!/usr/bin/env bash

set -m

# Variables
export YTT_LIB="/usr/lib/ytt/"
export TANZU_CLI_PLUGIN_GROUP_TKG_VERSION="v2.3.0"

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

			tanzu init || {
				echo "Failed to initialise the Tanzu CLI configuration"
			}

			# There are 3 options for the Tanzu CLI OCI registry in preference order:
			# 	1. A custom registry is provided, use it.
			# 	2. A pull-through cache is provided, use it.
			# 	3. No pull-through or custom registry is provided, pull direct from internet.

			# If there is a custom registry, use it as priority.
			if [[ ${TANZU_CUSTOM_REGISTRY:-EMPTY} != "EMPTY" ]]; then

				echo "Custom registry provided, using ${TANZU_CUSTOM_REGISTRY}"

				# Capture existing OCI URL
				TANZU_CLI_OCI_URL="$(tanzu plugin source list --output yaml | yq .[].image)"

				# Strip the VMware registry prefix.
				TANZU_CLI_OCI_URL="${TANZU_CLI_OCI_URL#*projects.registry.vmware.com}"

				# Add the custom registry OCI URL and update the plugin cache.
				TANZU_CLI_OCI_URL="${TANZU_CUSTOM_REGISTRY}${TANZU_CLI_OCI_URL}"

				# Update the plugin source and test pulling the image.
				tanzu plugin source update \
					default \
					--uri "${TANZU_CLI_OCI_URL}" || {
					echo "Failed to update plugin configuration to use the provided custom registry."
				}

			elif [[ ${TANZU_PULL_THROUGH_CACHE:-EMPTY} != "EMPTY" ]]; then

				echo "Pull-through prefix provided, prefixing ${TANZU_PULL_THROUGH_CACHE}"

				# Capture existing OCI URL
				TANZU_CLI_OCI_URL="$(tanzu plugin source list --output yaml | yq .[].image)"

				# Add the pull-through prefix
				TANZU_CLI_OCI_URL="${TANZU_PULL_THROUGH_CACHE}/${TANZU_CLI_OCI_URL}"

				# Add the pull-through cache OCI URL and update the plugin cache.
				tanzu plugin source update \
					default \
					--uri "${TANZU_CLI_OCI_URL}" || {
					echo "Failed to update plugin configuration to use the provided pull-through cache."
				}

			else

				echo "No custom registry or pull-through cache provided, pulling direct from internet."

			fi

			# Add the VMWare TKG group of plugins at the configured version to match the CLI.
			tanzu plugin install \
				--group vmware-tkg/default:${TANZU_CLI_PLUGIN_GROUP_TKG_VERSION} || {
				echo "Failed to install the Tanzu plugin group TKG ${TANZU_CLI_PLUGIN_GROUP_TKG_VERSION}"
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
