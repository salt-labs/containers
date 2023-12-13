#!/usr/bin/env bash

##################################################
# Name: tanzu_tools
# Description: Tanzu Tools specific helper functions
##################################################

function tanzu_tools_proxy() {

	# Allow proxy customizations via a user provided script.

	# HACK: A better method is needed.
	# Check for a user-proviced proxy settings script.
	if [[ ${TANZU_TOOLS_ENABLE_PROXY_SCRIPT:-FALSE} == "TRUE" ]]; then

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

		writeLog "INFO" "Proxy script is disabled, assuming direct internet access for now."

	fi

	return 0

}

function tanzu_tools_cli_nuke() {

	# Starts the Tanzu CLI from a clean slate

	dialogProgress "Tanzu CLI: Initializing..." "5"

	tanzu config eula accept 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to accept the Tanzu CLI EULA"
		return 1
	}

	dialogProgress "Tanzu CLI: Initializing..." "10"

	tanzu plugin clean 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to clean the Tanzu CLI plugins, please correct the issue and initialize on your own."
		return 1
	}

	dialogProgress "Tanzu CLI: Initializing..." "15"

	tanzu init 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to initialize the Tanzu CLI configuration. Please try again"
		return 1
	}

	dialogProgress "Tanzu CLI: Initializing..." "20"

	tanzu plugin source init 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to initialize the Tanzu CLI plugin source. Please try again"
		return 1
	}

	dialogProgress "Tanzu CLI: Initializing..." "25"

	return 0

}

function tanzu_tools_multi_site() {

	# Allows the user to select the site they are working with.

	local -A SITES_ARRAY=()
	local SITE
	local VALUE
	local RETURN_CODE
	local OPTIONS=()
	local NUM=0

	# Docker env doesn't support arrays. The users needs to provide a CSV variable.
	# If the user has provided a list of sites.
	if [[ ${TANZU_TOOLS_SITES:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "Failed to configure Multi-Site support"
		writeLog "ERROR" "In order to use Multi-Site support you must provide a comma-separated value of sites in the variable named 'TANZU_TOOLS_SITES'"
		return 1
	else
		writeLog "INFO" "Processing sites ${TANZU_TOOLS_SITES}"
	fi

	while IFS="," read -rd, SITE || [ -n "$SITE" ]; do

		# Strip any whitespace
		SITE=$(echo "${SITE}" | xargs echo -n)

		if [[ ${SITE:-EMPTY} == "EMPTY" ]]; then
			writeLog "ERROR" "Error processing site variable. Please check the contents of the TANZU_TOOLS_SITES variable is correct."
			return 1
		else
			writeLog "DEBUG" "Processing site ${SITE}"
		fi

		NUM=$((NUM + 1))
		SITES_ARRAY[$NUM]=${SITE}
		OPTIONS+=(
			"${NUM}" "${SITES_ARRAY[$NUM]}"
		)

		writeLog "INFO" "Added site ${SITE} into array slot ${NUM}"

	done < <(printf "%s\n" "${TANZU_TOOLS_SITES}")

	writeLog "DEBUG" "Sites: ${SITES_ARRAY[*]}"
	writeLog "DEBUG" "Options: ${OPTIONS[*]}"

	dialogMenu "Sites" "Please select your site for Administration:"

	#  0 = Yes
	#  1 = No
	#  2 = Help
	#  3 = Extra
	# -1 = Error

	VALUE=$("${CMD[@]}" "${BOX_OPTIONS[@]}" "${OPTIONS[@]}" 2>&1 >/dev/tty)
	RETURN_CODE=$?

	writeLog "DEBUG" "Dialog value: ${VALUE:-EMPTY}"
	writeLog "DEBUG" "Dialog return: ${RETURN_CODE:-EMPTY}"

	# TODO: Handle edge cases.
	if [[ ${RETURN_CODE:-0} -eq 1 ]]; then

		writeLog "WARN" "The user selected NO on the multi-site configuration adialog. Aborting configuration."
		dialogMsgBox "WARNING" "Unable to continue as the cancel button was selected. Aborting configuration."
		exit 0

	elif [[ ${RETURN_CODE:-0} -eq 255 ]]; then

		writeLog "WARN" "Timeout during site selection dialog. Aborting configuration"
		dialogMsgBox "WARNING" "Timeout during site selection dialog. Aborting configuration"
		exit 0

	elif [[ ${VALUE:-EMPTY} == "EMPTY" ]]; then

		writeLog "ERROR" "Error during site selection dialog. The value for the site was empty"
		return 1

	elif [[ ${RETURN_CODE:-0} -ne 0 ]]; then

		writeLog "ERROR" "Unhandled error during site selection dialog"
		return 1

	fi

	writeLog "DEBUG" "Checking variables for site ${SITES_ARRAY[$VALUE]}"

	# Build the variable name as a string
	VAR_REGISTRY="TANZU_TOOLS_SITE_${SITES_ARRAY[$VALUE]}_REGISTRY"
	VAR_CLI_PLUGIN_INVENTORY_TAG="TANZU_TOOLS_SITE_${SITES_ARRAY[$VALUE]}_CLI_PLUGIN_INVENTORY_TAG"
	VAR_CLI_PLUGIN_GROUP_TKG_TAG="TANZU_TOOLS_SITE_${SITES_ARRAY[$VALUE]}_CLI_PLUGIN_GROUP_TKG_TAG"

	# Convert string to uppercase
	VAR_REGISTRY=${VAR_REGISTRY^^}
	VAR_CLI_PLUGIN_INVENTORY_TAG=${VAR_CLI_PLUGIN_INVENTORY_TAG^^}
	VAR_CLI_PLUGIN_GROUP_TKG_TAG=${VAR_CLI_PLUGIN_GROUP_TKG_TAG^^}

	# Replace any dashes with underscores
	VAR_REGISTRY=${VAR_REGISTRY//-/_}
	VAR_CLI_PLUGIN_INVENTORY_TAG=${VAR_CLI_PLUGIN_INVENTORY_TAG//-/_}
	VAR_CLI_PLUGIN_GROUP_TKG_TAG=${VAR_CLI_PLUGIN_GROUP_TKG_TAG//-/_}

	# Replace any spaces with underscores
	VAR_REGISTRY=${VAR_REGISTRY// /_}
	VAR_CLI_PLUGIN_INVENTORY_TAG=${VAR_CLI_PLUGIN_INVENTORY_TAG// /_}
	VAR_CLI_PLUGIN_GROUP_TKG_TAG=${VAR_CLI_PLUGIN_GROUP_TKG_TAG// /_}

	##########
	# Registry
	##########

	# The Registry variable is not optional when using multi-site.

	# Check whether the variable is empty or not.
	if checkVarEmpty "${VAR_REGISTRY}" "Container registry for site ${SITES_ARRAY[$VALUE]}"; then
		dialogMsgBox "ERROR" "The required site variable is missing. Please set the variable named ${VAR_REGISTRY}"
		return 1
	fi

	# Obtain the current contents of the variable
	REGISTRY="${!VAR_REGISTRY:-EMPTY}"

	# Double check our work.
	if [[ ${REGISTRY} == "EMPTY" ]]; then
		writeLog "ERROR" "Error encounted obtaining the variable contents for site ${SITES_ARRAY[$VALUE]}. The variable is meant to be named ${VAR_REGISTRY}"
		return 1
	else
		writeLog "DEBUG" "The site ${SITES_ARRAY[$VALUE]} has a registry value of ${REGISTRY}"
	fi

	##########
	# Versions
	##########

	# The versions tags are optional when using multi-site.

	# Check whether the Inventory tag variable is empty or not.
	if checkVarEmpty "${VAR_CLI_PLUGIN_INVENTORY_TAG}" "Tanzu CLI Inventory tag for site ${SITES_ARRAY[$VALUE]}"; then

		writeLog "INFO" "The Tanzu CLI Inventory tag for site ${SITES_ARRAY[$VALUE]} is empty, using default"

	else

		# Obtain the current contents of the variable
		CLI_PLUGIN_INVENTORY_TAG="${!VAR_CLI_PLUGIN_INVENTORY_TAG:-EMPTY}"

		# Double check our work.
		if [[ ${CLI_PLUGIN_INVENTORY_TAG} == "EMPTY" ]]; then
			writeLog "ERROR" "Error encounted obtaining the variable contents for site ${SITES_ARRAY[$VALUE]}. The variable is meant to be named ${VAR_CLI_PLUGIN_INVENTORY_TAG}"
			return 1
		else
			writeLog "INFO" "The site ${SITES_ARRAY[$VALUE]} has a Tanzu CLI Inventory tag value of ${CLI_PLUGIN_INVENTORY_TAG}"
			export TANZU_TOOLS_CLI_PLUGIN_INVENTORY_TAG="${CLI_PLUGIN_INVENTORY_TAG}"
		fi

	fi

	# Check whether the TKG version tag variable is empty or not.
	if checkVarEmpty "${VAR_CLI_PLUGIN_GROUP_TKG_TAG}" "Tanzu CLI TKG version tag for site ${SITES_ARRAY[$VALUE]}"; then

		writeLog "INFO" "The Tanzu CLI TKG version tag for site ${SITES_ARRAY[$VALUE]} is empty, using default"

	else

		# Obtain the current contents of the variable
		CLI_PLUGIN_GROUP_TKG_TAG="${!VAR_CLI_PLUGIN_GROUP_TKG_TAG:-EMPTY}"

		# Double check our work.
		if [[ ${CLI_PLUGIN_GROUP_TKG_TAG} == "EMPTY" ]]; then
			writeLog "ERROR" "Error encounted obtaining the variable contents for site ${SITES_ARRAY[$VALUE]}. The variable is meant to be named ${VAR_CLI_PLUGIN_GROUP_TKG_TAG}"
			return 1
		else
			writeLog "INFO" "The site ${SITES_ARRAY[$VALUE]} has a Tanzu CLI TKG version tag value of ${CLI_PLUGIN_GROUP_TKG_TAG}"
			export TANZU_TOOLS_CLI_PLUGIN_GROUP_TKG_TAG="${CLI_PLUGIN_GROUP_TKG_TAG}"
		fi

	fi

	##########
	# Export variables
	##########

	# Export the correct registry variables for the selected site.

	# Strip the VMware registry prefix.
	TANZU_TOOLS_CLI_OCI_URL="${TANZU_TOOLS_CLI_OCI_URL#*projects.registry.vmware.com}"

	# Add the multi-site registry OCI URL to the Tanzu CLI URL
	TANZU_TOOLS_CLI_OCI_URL="${REGISTRY}${TANZU_TOOLS_CLI_OCI_URL}"

	# Strip the current inventory image tag.
	TANZU_TOOLS_CLI_OCI_URL="${TANZU_TOOLS_CLI_OCI_URL%:*}"

	# Add the user provided image tag.
	TANZU_TOOLS_CLI_OCI_URL="${TANZU_TOOLS_CLI_OCI_URL}:${TANZU_TOOLS_CLI_PLUGIN_INVENTORY_TAG}"

	# Add the multi-site registry OCI URL to the TKG URL
	export TKG_CUSTOM_IMAGE_REPOSITORY="${REGISTRY}/tkg"

	writeLog "INFO" "The site registry URL for Tanzu CLI has been set to ${TANZU_TOOLS_CLI_OCI_URL}"

	writeLog "INFO" "The custom registry URL for TKG has been set to ${TKG_CUSTOM_IMAGE_REPOSITORY}"

	return 0

}

function tanzu_tools_registry_custom() {

	# Sets the registry based on user provided variables

	writeLog "INFO" "A custom image registry was provided, using ${TANZU_TOOLS_CUSTOM_REGISTRY}"

	# Strip the VMware registry prefix.
	TANZU_TOOLS_CLI_OCI_URL="${TANZU_TOOLS_CLI_OCI_URL#*projects.registry.vmware.com}"

	# Add the custom registry OCI URL to the Tanzu CLI URL
	TANZU_TOOLS_CLI_OCI_URL="${TANZU_TOOLS_CUSTOM_REGISTRY}${TANZU_TOOLS_CLI_OCI_URL}"

	# Add the custom registry OCI URL to the TKG URL
	export TKG_CUSTOM_IMAGE_REPOSITORY="${TANZU_TOOLS_CUSTOM_REGISTRY}/tkg"

	writeLog "INFO" "The custom registry URL for Tanzu CLI has been set to ${TANZU_TOOLS_CLI_OCI_URL}"

	writeLog "INFO" "The custom registry URL for TKG has been set to ${TKG_CUSTOM_IMAGE_REPOSITORY}"

	return 0

}

function tanzu_tools_registry_cache() {

	# Sets the registry cache based on user provided variables

	writeLog "INFO" "Configuring the Tanzu CLI with a pull-through cache of ${TANZU_TOOLS_PULL_THROUGH_CACHE}"

	# Add the pull-through prefix to the Tanzu CLI URL
	TANZU_TOOLS_CLI_OCI_URL="${TANZU_TOOLS_PULL_THROUGH_CACHE}/${TANZU_TOOLS_CLI_OCI_URL}"

	# Add the pull-through prefix to the TKG URL
	export TKG_CUSTOM_IMAGE_REPOSITORY="${TANZU_TOOLS_PULL_THROUGH_CACHE}/projects.registry.vmware.com/tkg"

	writeLog "INFO" "The pull-through cache URL for Tanzu CLI has been set to ${TANZU_TOOLS_CLI_OCI_URL}"

	writeLog "INFO" "The pull-through cache URL for TKG has been set to ${TKG_CUSTOM_IMAGE_REPOSITORY}"

	return 0

}

function tanzu_tools_cli_custom() {

	# Runs the correct functions based on user provided variables.

	# There are 4 supported options for the Tanzu CLI OCI Registry that we need to deal with.
	# In order of preference they are:
	#	1. If multi-site is active, go through that nonsense.
	# 	2. If a custom registry is provided, use it.
	# 	3. If a pull-through cache is provided, use it.
	# 	4. If no pull-through or custom registry is provided, pull direct from the internet.

	dialogProgress "Tanzu CLI: Applying user customizations..." "0"

	# HACK: Reset the plugin URL to defaults each run.
	tanzu plugin source init 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to initialize the Tanzu CLI plugin source."
		return 1
	}

	# Capture existing OCI URL as the default.
	TANZU_TOOLS_CLI_DEFAULT_URL="$(tanzu plugin source list --output yaml | yq .[].image)"

	# Strip the current inventory image tag.
	TANZU_TOOLS_CLI_OCI_URL="${TANZU_TOOLS_CLI_DEFAULT_URL%:*}"

	# Add the user provided image tag.
	TANZU_TOOLS_CLI_OCI_URL="${TANZU_TOOLS_CLI_OCI_URL}:${TANZU_TOOLS_CLI_PLUGIN_INVENTORY_TAG}"

	writeLog "DEBUG" "The default Tanzu CLI OCI URL is ${TANZU_TOOLS_CLI_OCI_URL}"

	dialogProgress "Tanzu CLI: Applying user customizations..." "10"

	#########################
	# 1. Multi-Site
	#########################

	if [[ ${TANZU_TOOLS_SITES_ENABLED:-FALSE} == "TRUE" ]]; then

		tanzu_tools_multi_site || {

			MESSAGE="Failed to configure Tanzu Tools for multi-site!"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1

		}

	#########################
	# 2. Custom Registry
	#########################

	elif [[ ${TANZU_TOOLS_CUSTOM_REGISTRY:-EMPTY} != "EMPTY" ]]; then

		tanzu_tools_registry_custom || {

			MESSAGE="Failed to configure Tanzu Tools with a custom registry"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1

		}

	#########################
	# 3. Pull-through cache
	#########################

	elif [[ ${TANZU_TOOLS_PULL_THROUGH_CACHE:-EMPTY} != "EMPTY" ]]; then

		tanzu_tools_registry_cache || {

			MESSAGE="Failed to configure Tanzu Tools with a pull-through registry cache"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1

		}

	#########################
	# 4. Direct internet
	#########################

	else

		writeLog "INFO" "No custom registry or pull-through cache provided, pulling images direct from the internet."

	fi

	#########################
	# End
	#########################

	# Now that the container registry has been configured, update the variables and plugins.
	tanzu plugin source update default --uri "${TANZU_TOOLS_CLI_OCI_URL}" 1>>"${LOG_FILE}" 2>&1 || {

		MESSAGE="Failed to update plugin source to ${TANZU_TOOLS_CLI_OCI_URL}. Please check connectivity"
		writeLog "ERROR" "${MESSAGE}"
		dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
		return 1

	}

	dialogProgress "Tanzu CLI: Apply user customizations..." "100"

	return 0

}

function tanzu_tools_cli_init() {

	# Initialize the Tanzu CLI for first time users.
	TANZU_TOOLS_IS_READY=FALSE

	# We use a fake lock file to determine if the CLI has been "initialized".
	TANZU_TOOLS_INIT_LOCK="${HOME}/.config/tanzu/.tanzu-init.lock"
	if [[ -f ${TANZU_TOOLS_INIT_LOCK} ]]; then

		writeLog "INFO" "The Tanzu CLI has already been initialized"
		TANZU_TOOLS_IS_READY=TRUE
		return 0

	fi

	# Make sure that the interactive parts are not run in a VSCode remote env.
	if [[ ${ENVIRONMENT_VSCODE^^} == "CONTAINER" ]]; then

		writeLog "INFO" "Devcontainer is running, skipping Tanzu init."
		return 0

	fi

	# START: Interactive loop
	while true; do

		dialogYesNo "Tanzu CLI" "Initialize the Tanzu CLI?"

		#  0 = Yes
		#  1 = No
		#  2 = Help
		#  3 = Extra
		# -1 = Error

		"${CMD[@]}" "${BOX_OPTIONS[@]}"
		RETURN_CODE=$?

		writeLog "DEBUG" "Dialog return: ${RETURN_CODE:-EMPTY}"

		case "${RETURN_CODE:-EMPTY}" in

		0) # YES

			writeLog "DEBUG" "User selected YES to initialize Tanzu CLI"

			dialogProgress "Tanzu CLI: Initializing..." "0"

			tanzu_tools_cli_nuke || {
				writeLog "ERROR" "Failed to initialize the Tanzu CLI"
				break
			}

			dialogProgress "Tanzu CLI: Initializing..." "50"

			# Finished, write the lock and exit the loop.
			cat <<-EOF >"${TANZU_TOOLS_INIT_LOCK}"

				The Tanzu CLI was successfully initialized on $(date)

				You can remove this lock file for the initialization process to run again on next launch.

			EOF

			dialogProgress "Tanzu CLI: Initializing..." "100"
			TANZU_TOOLS_IS_READY=TRUE

			break

			;;

		1) # NO

			writeLog "DEBUG" "User selected NO to initialize Tanzu CLI"

			dialogProgress "Tanzu CLI: Initialization skipped" "100"

			break

			;;

		255) # Cancel

			writeLog "DEBUG" "User cancelled initialize Tanzu CLI, asking again"

			dialogProgress "Tanzu CLI: Initialization cancelled" "100"

			;;

		*) # ERROR (*)

			writeLog "ERROR" "An error occurred while initializing the Tanzu CLI. The return code was ${RETURN_CODE:-EMPTY}. Re-trying..."

			dialogMsgBox "ERROR" "An error occurred while initializing the Tanzu CLI. Please OK to try again."

			;;

		esac

	done
	# END: Interactive loop

	tput clear

	return 0

}

function tanzu_tools_cli_plugins() {

	dialogProgress "Tanzu CLI: Downloading Plugins..." "25"

	# Install all plugins recommended by the active contexts.
	tanzu plugin sync 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to synchronise Tanzu CLI plugins"
		return 1
	}

	dialogProgress "Tanzu CLI: Downloading Plugins..." "50"

	# Add the VMWare TKG group of plugins at the configured version to match the CLI.
	tanzu plugin install --group "vmware-tkg/default:${TANZU_TOOLS_CLI_PLUGIN_GROUP_TKG_TAG}" 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to install the Tanzu plugin group vmware-tkg/default:${TANZU_TOOLS_CLI_PLUGIN_GROUP_TKG_TAG}"
		return 1
	}

	dialogProgress "Tanzu CLI: Downloading Plugins..." "100"

	return 0

}

function tanzu_tools_sync_ytt_lib() {

	# Rsync the users ytt library into the TKG location.
	# NOTE: As of TKG v2.x user provided ytt customizations are being phased out.

	local YTT_LIB_TKG="$HOME/.config/tanzu/tkg/providers/ytt/04_user_customizations"

	writeLog "INFO" "Syncing the user provided ytt library into the TKG location."

	# There must be an existing user YTT_LIB variable and the folder must exist.
	# If this has been provided via a bind variables, it is the users responsibility
	# to ensure the permissions allow access or this process will fail.
	if [[ ${YTT_LIB:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "The YTT_LIB variable is not defined, unable to continue!"
		return 1
	elif [[ ! -d ${YTT_LIB} ]]; then
		writeLog "ERROR" "The configured ytt library was not found at ${YTT_LIB}"
		return 1
	fi

	rsync -av "${YTT_LIB}" "${YTT_LIB_TKG}" || {
		writeLog "ERROR" "Failed to sync ytt library from ${YTT_LIB} to ${YTT_LIB_TKG}"
		return 1
	}

	return 0

}

function tanzu_tools_sync_scripts() {

	local VENDIR_FILE_CONFIG="${TANZU_TOOLS_SYNC_SCRIPTS_CONFIG:-vendir.yml}"
	local VENDIR_FILE_LOCK="${TANZU_TOOLS_SYNC_SCRIPTS_LOCK:-vendir.lock.yml}"

	local VENDOR_DIR="${TANZU_TOOLS_SYNC_VENDOR_DIR:-/vendor}"

	# Confirm the vendor directory already exists.
	if [[ ! -d ${VENDOR_DIR} ]]; then
		writeLog "ERROR" "The vendor directory ${VENDOR_DIR} does not exist"
		return 1
	fi

	# Confirm the vendir file already exists but the lock is optional.
	if [[ ! -f ${VENDIR_FILE} ]]; then
		writeLog "ERROR" "The vendir file ${VENDIR_FILE} does not exist"
		return 1
	fi

	vendir sync \
		--file "${VENDIR_FILE_CONFIG}" \
		--chdir "${VENDOR_DIR}" \
		"${VENDIR_FILE_LOCK:+--lock-file $VENDIR_FILE_LOCK}" \
		"${VENDIR_FILE_LOCK:+--locked}" \
		--yes || {
		writeLog "ERROR" "Failed to run vendir sync"
		return 1
	}

	return 0

}

function tanzu_tools_bash_completions() {

	dialogProgress "Tanzu CLI: Loading bash completions..." "25"

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

	dialogProgress "Tanzu CLI: Loading bash completions..." "50"

	if shopt -q progcomp; then

		for BIN in "${BINS[@]}"; do

			# shellcheck disable=SC1090
			source <(${BIN} completion bash) || {
				writeLog "WARN" "Failed to source bash completion for ${BIN}, skipping..."
			}

		done

	fi

	dialogProgress "Tanzu CLI: Loading bash completions..." "100"

	return 0

}

# The main function.
function tanzu_tools_launch() {

	dialogProgress "Tanzu Tools: Launching..." "0"

	# Tanzu Tools variables
	export YTT_LIB="/usr/lib/ytt/"

	# These variables are passed in as Docker arguments or defaults are set here if missing.
	export TANZU_TOOLS_CLI_PLUGIN_INVENTORY_TAG="${TANZU_TOOLS_CLI_PLUGIN_INVENTORY_TAG:-latest}"
	export TANZU_TOOLS_CLI_PLUGIN_GROUP_TKG_TAG="${TANZU_TOOLS_CLI_PLUGIN_GROUP_TKG_TAG:-latest}"

	writeLog "DEBUG" "Resetting variables"
	unset TANZU_TOOLS_IS_READY
	unset TANZU_TOOLS_CLI_OCI_URL
	unset TKG_CUSTOM_IMAGE_REPOSITORY

	# Make sure job control is on
	set -m

	dialogProgress "Tanzu Tools: Launching..." "10"

	# Some environments have proxy servers...
	tanzu_tools_proxy || {
		MESSAGE="Failed to run user proxy configuration"
		writeLog "ERROR" "${MESSAGE}"
		dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
		return 1
	}

	dialogProgress "Tanzu Tools: Launching..." "20"

	# If this is the first time, an initialization process is required
	# to accept the EULA and disable the Telemetry
	tanzu_tools_cli_init || {
		MESSAGE="Failed to initialize the Tanzu CLI"
		writeLog "ERROR" "${MESSAGE}"
		dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
		return 1
	}

	if [[ ${TANZU_TOOLS_IS_READY:-FALSE} == "TRUE" ]]; then

		dialogProgress "Tanzu Tools: Launching..." "30"

		# Apply user customizations based on provided variables.
		# The user customizations function displays it's own dialog boxes.
		tanzu_tools_cli_custom || {
			MESSAGE="Failed to set the Tanzu CLI user customisations"
			writeLog "ERROR" "${MESSAGE}"
			return 1
		}

		dialogProgress "Tanzu Tools: Launching..." "50"

		# Download the Tanzu CLI plugins.
		tanzu_tools_cli_plugins || {
			MESSAGE="Failed to download the Tanzu CLI plugins"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1
		}

		dialogProgress "Tanzu Tools: Launching..." "75"

		# RSync the users ytt library into TKG
		if [[ ${TANZU_TOOLS_SYNC_YTT_LIB:-FALSE} == "TRUE" ]]; then

			tanzu_tools_sync_ytt_lib || {
				MESSAGE="Failed to sync ytt library"
				writeLog "ERROR" "${MESSAGE}"
				dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
				return 1
			}

		else

			writeLog "INFO" "Tanzu Tools is not enabled to sync the ytt library, skipping."

		fi

		# Use vendir to pull pinned scripts.
		if [[ ${TANZU_TOOLS_SYNC_SCRIPTS:-FALSE} == "TRUE" ]]; then

			tanzu_tools_sync_scripts || {
				MESSAGE="Failed to sync scripts"
				writeLog "ERROR" "${MESSAGE}"
				dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
				return 1
			}

		else

			writeLog "INFO" "Tanzu Tools is not enabled to sync scripts, skipping."

		fi

	else

		writeLog "WARN" "Tanzu Tools is not ready, skipping plugin downloads"

	fi

	# Source the bash completions for all the associated tooling.
	tanzu_tools_bash_completions || {
		MESSAGE="Failed to source Tanzu Tools bash completions"
		writeLog "ERROR" "${MESSAGE}"
		dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
		return 1
	}

	dialogProgress "Tanzu Tools: Launching..." "100"

	tput clear
	figlet "Tanzu Tools"

}

export -f tanzu_tools_launch
