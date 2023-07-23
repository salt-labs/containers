set -m

if [[ ${ENABLE_DEBUG:-FALSE} == "TRUE" ]]; then
	set -x
fi

# Variables
export YTT_LIB="/usr/lib/ytt/"
export TANZU_CLI_PLUGIN_SOURCE_TAG="${TANZU_PLUGIN_SOURCE_TAG:-latest}"
export TANZU_CLI_PLUGIN_GROUP_TKG_TAG="${TANZU_CLI_PLUGIN_GROUP_TKG_TAG:-latest}"

# HACK: A better method is needed.
# Check for a proxy settings script.
if [[ ${ENABLE_PROXY_SCRIPT:-FALSE} == "TRUE" ]]; then

	if [[ -f "${WORKDIR}/scripts/proxy.sh" ]]; then

		echo "$(date '+%Y/%m/%d %T'): INFO: Loading proxy settings from ${WORKDIR}/scripts/proxy.sh"

		# shellcheck disable=SC1091
		source "${WORKDIR}/scripts/proxy.sh" || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to load proxy settings!"
		}

		proxy_on || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to enable proxy settings!"
		}

	else

		echo "$(date '+%Y/%m/%d %T'): ERROR: Proxy settings are enabled but ${WORKDIR}/scripts/proxy.sh does not exist. Have you mounted the bind volume?"
		sleep 3
		exit 1

	fi

else

	echo "$(date '+%Y/%m/%d %T'): INFO: Proxy script is not enabled, assuming direct internet access."

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
if [[ ${ENVIRONMENT_VSCODE^^} == "CONTAINER" ]]; then

	echo "$(date '+%Y/%m/%d %T'): INFO: Devcontainer is running, skipping Tanzu init." | tee -a "/tmp/environment.log"

else

	# Initialise the Tanzu CLI
	if [[ ${TANZU_CLI_INIT_DONE:-FALSE} == "TRUE" ]]; then

		echo "$(date '+%Y/%m/%d %T'): INFO: Tanzu CLI is already initialised."

	else

		while true; do

			printf "\n"
			read -r -p "Initialise the Tanzu CLI? y/n: " CHOICE

			case "$CHOICE" in

				[Yy]*)

					echo "$(date '+%Y/%m/%d %T'): INFO: Initialising Tanzu CLI..."

					tanzu plugin clean || {
						echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to clean the Tanzu CLI plugins"
					}

					tanzu init || {
						echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to initialise the Tanzu CLI configuration"
					}

					# There are 3 options for the Tanzu CLI OCI registry in preference order:
					# 	1. A custom registry is provided, use it.
					# 	2. A pull-through cache is provided, use it.
					# 	3. No pull-through or custom registry is provided, pull direct from internet.

					# Capture existing OCI URL
					TANZU_CLI_OCI_URL="$(tanzu plugin source list --output yaml | yq .[].image)"

					# Strip the image tag.
					TANZU_CLI_OCI_URL="${TANZU_CLI_OCI_URL%:*}"

					# Add the user provided image tag.
					TANZU_CLI_OCI_URL="${TANZU_CLI_OCI_URL}:${TANZU_CLI_PLUGIN_SOURCE_TAG}"

					echo "$(date '+%Y/%m/%d %T'): INFO: Tanzu CLI OCI URL set to ${TANZU_CLI_OCI_URL}"

					# If there is a custom registry, use it as priority.
					if [[ ${TANZU_CUSTOM_REGISTRY:-EMPTY} != "EMPTY" ]]; then

						echo "$(date '+%Y/%m/%d %T'): INFO: Custom registry provided, using ${TANZU_CUSTOM_REGISTRY}"

						# Strip the VMware registry prefix.
						TANZU_CLI_OCI_URL="${TANZU_CLI_OCI_URL#*projects.registry.vmware.com}"

						# Add the custom registry OCI URL.
						TANZU_CLI_OCI_URL="${TANZU_CUSTOM_REGISTRY}${TANZU_CLI_OCI_URL}"

						echo "$(date '+%Y/%m/%d %T'): INFO: Custom registry OCI URL set to ${TANZU_CLI_OCI_URL}"

					elif [[ ${TANZU_PULL_THROUGH_CACHE:-EMPTY} != "EMPTY" ]]; then

						# Add the pull-through prefix
						TANZU_CLI_OCI_URL="${TANZU_PULL_THROUGH_CACHE}/${TANZU_CLI_OCI_URL}"

						echo "$(date '+%Y/%m/%d %T'): INFO: Pull-through cache OCI URL set to ${TANZU_CLI_OCI_URL}"

					else

						echo "$(date '+%Y/%m/%d %T'): INFO: No custom registry or pull-through cache provided, pulling direct from internet."

					fi

					echo "$(date '+%Y/%m/%d %T'): INFO: Updating Tanzu CLI plugin source..."

					# Add the pull-through cache OCI URL and update the plugin cache.
					tanzu plugin source update \
						default \
						--uri "${TANZU_CLI_OCI_URL}" || {
						echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to update plugin source to ${TANZU_CLI_OCI_URL}"
					}

					echo "$(date '+%Y/%m/%d %T'): INFO: Installing Tanzu CLI plugin group vmware-tkg/default:${TANZU_CLI_PLUGIN_GROUP_TKG_TAG}"

					# Add the VMWare TKG group of plugins at the configured version to match the CLI.
					tanzu plugin install \
						--group "vmware-tkg/default:${TANZU_CLI_PLUGIN_GROUP_TKG_TAG}" || {
						echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to install the Tanzu plugin group vmware-tkg/default:${TANZU_CLI_PLUGIN_GROUP_TKG_TAG}"
					}

					tanzu plugin sync || {
						echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to synchronise Tanzu CLI plugins"
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

			# shellcheck disable=SC1090
			source <(${BIN} completion bash) || {
				echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to source bash completion for ${BIN}, skipping..."
			}

		done

	fi

	figlet "Tanzu CLI"

fi
