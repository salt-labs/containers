set -m

if [[ ${ENABLE_DEBUG:-FALSE} == "TRUE" ]]; then
	set -x
fi

# Variables
export YTT_LIB="/usr/lib/ytt/"
export TANZU_CLI_PLUGIN_GROUP_TKG_VERSION="${TANZU_CLI_PLUGIN_GROUP_TKG_VERSION:-latest}"

# HACK: A better method is needed.
# Check for a proxy settings script.
if [[ ${ENABLE_PROXY_SCRIPT:-FALSE} == "TRUE" ]]; then

	if [[ -f "${WORKDIR}/scripts/proxy.sh" ]]; then

		echo "INFO: Loading proxy settings from ${WORKDIR}/scripts/proxy.sh"

		source "${WORKDIR}/scripts/proxy.sh" || {
			echo "ERROR: Failed to load proxy settings!"
		}

		proxy_on || {
			echo "ERROR: Failed to enable proxy settings!"
		}

	else

		echo "ERROR: Proxy settings are enabled but ${WORKDIR}/scripts/proxy.sh does not exist. Have you mounted the bind volume?"
		sleep 3
		exit 1

	fi

else

	echo "INFO: Proxy script is not enabled, assuming direct internet access."

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

# Make sure that the interactive parts are not run in a a VSCode remote env.
if [[ "${ENVIRONMENT_VSCODE^^}" == "REMOTE" ]]; then

	echo "$(date '+%Y/%m/%d %T'): INFO: VSCode remote environment detected, skipping interactive parts." | tee -a "/tmp/vscode-remote-env.log"

else

	# Initialise the Tanzu CLI
	if [[ ${TANZU_CLI_INIT_DONE:-FALSE} == "TRUE" ]]; then

		echo "INFO: Tanzu CLI is already initialised."

	else

		while true; do

			printf "\n"
			read -r -p "Initialise the Tanzu CLI? y/n: " CHOICE

			case "$CHOICE" in

				[Yy]*)

					echo "INFO: Initialising Tanzu CLI..."

					tanzu plugin clean || {
						echo "ERROR: Failed to clean the Tanzu CLI plugins"
					}

					tanzu init || {
						echo "ERROR: Failed to initialise the Tanzu CLI configuration"
					}

					# There are 3 options for the Tanzu CLI OCI registry in preference order:
					# 	1. A custom registry is provided, use it.
					# 	2. A pull-through cache is provided, use it.
					# 	3. No pull-through or custom registry is provided, pull direct from internet.

					# If there is a custom registry, use it as priority.
					if [[ ${TANZU_CUSTOM_REGISTRY:-EMPTY} != "EMPTY" ]]; then

						echo "INFO: Custom registry provided, using ${TANZU_CUSTOM_REGISTRY}"

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
							echo "ERROR: Failed to update plugin configuration to use the provided custom registry."
						}

					elif [[ ${TANZU_PULL_THROUGH_CACHE:-EMPTY} != "EMPTY" ]]; then

						echo "INFO: Pull-through prefix provided, prefixing ${TANZU_PULL_THROUGH_CACHE}"

						# Capture existing OCI URL
						TANZU_CLI_OCI_URL="$(tanzu plugin source list --output yaml | yq .[].image)"

						# Add the pull-through prefix
						TANZU_CLI_OCI_URL="${TANZU_PULL_THROUGH_CACHE}/${TANZU_CLI_OCI_URL}"

						# Add the pull-through cache OCI URL and update the plugin cache.
						tanzu plugin source update \
							default \
							--uri "${TANZU_CLI_OCI_URL}" || {
							echo "ERROR: Failed to update plugin configuration to use the provided pull-through cache."
						}

					else

						echo "INFO: No custom registry or pull-through cache provided, pulling direct from internet."

					fi

					# Add the VMWare TKG group of plugins at the configured version to match the CLI.
					tanzu plugin install \
						--group "vmware-tkg/default:${TANZU_CLI_PLUGIN_GROUP_TKG_VERSION}" || {
						echo "ERROR: Failed to install the Tanzu plugin group vmware-tkg/default:${TANZU_CLI_PLUGIN_GROUP_TKG_VERSION}"
					}

					tanzu plugin sync || {
						echo "ERROR: Failed to synchronise Tanzu CLI plugins"
					}

					break

					;;

				[Nn]*)

					break

					;;

				*)

					echo "Please answer yes or no."

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

		for BIN in "${BINS[@]}"; do

			source <(${BIN} completion bash) || {
				echo "ERROR: Failed to source bash completion for ${BIN}, skipping..."
			}

		done

	fi

	figlet "Tanzu CLI"

fi
