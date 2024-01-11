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

function tanzu_tools_cli_envs() {

	local ENVIRONMENT="${TANZU_TOOLS_ENVIRONMENT_NAME:-default}"
	local TANZU_CLI_HOME_DEFAULT="${HOME}/.config/tanzu"
	local TANZU_CLI_HOME="${TANZU_CLI_HOME:-$HOME/.config/tanzu-envs/$ENVIRONMENT}"

	# If this function has been called, we assume the user knows what they are doing.
	writeLog "INFO" "Configuring Tanzu Tools environment folder symlink"

	# 1. Take a backup of the existing Tanzu CLI folder if present, or this could get ugly fast.
	if [[ -s ${TANZU_CLI_HOME_DEFAULT} ]]; then

		writeLog "DEBUG" "The Tanzu CLI directory is already a symlink, taking no action."

	elif [[ -d ${TANZU_CLI_HOME_DEFAULT} ]]; then

		writeLog "INFO" "Taking a backup of the existing Tanzu CLI directory"

		mv "${HOME}/.config/tanzu" "${HOME}/.config/tanzu.bak" || {

			writeLog "ERROR" "Failed to take a backup of the Tanzu CLI directory, aborting"
			return 1

		}

	fi

	# 2. Make sure the specified home directory exists.
	if [[ ! -d ${TANZU_CLI_HOME} ]]; then

		writeLog "INFO" "Creating new Tanzu CLI home at location ${TANZU_CLI_HOME}"

		mkdir -p "${TANZU_CLI_HOME}" || {

			writeLog "ERROR" "Failed to create the Tanzu CLI home directory ${TANZU_CLI_HOME}"
			return 1

		}

	fi

	# 3. Create a symlink to the OG location.
	writeLog "INFO" "Creating a symlink from ${TANZU_CLI_HOME} to ${TANZU_CLI_HOME_DEFAULT}"
	ln \
		--symbolic \
		--force \
		--no-target-directory \
		"${TANZU_CLI_HOME}" "${TANZU_CLI_HOME_DEFAULT}" || {
		writeLog "ERROR" "Failed to create Tanzu CLI symlink from ${TANZU_CLI_HOME} to ${TANZU_CLI_HOME_DEFAULT}"
		return 1
	}

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
	unset NUM

	writeLog "DEBUG" "Loaded ${#SITES_ARRAY[@]} sites into array"
	writeLog "DEBUG" "Sites: ${SITES_ARRAY[*]}"
	writeLog "DEBUG" "Options: ${OPTIONS[*]}"

	if [[ ! ${#OPTIONS[@]} -gt 0 ]]; then

		writeLog "ERROR" "No sites were specified, aborting"
		return 1

	fi

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

	# Export a variable into the environment with the site name.
	# This is used by downstream scripts.
	export TANZU_TOOLS_SITE_NAME="${SITES_ARRAY[$VALUE]}"

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
	TANZU_TOOLS_CLI_DEFAULT_URL=$(tanzu plugin source list --output yaml | yq '.[] | select(.name == "default") | .image')

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
	TANZU_TOOLS_CLI_READY=FALSE

	# We use a fake lock file to determine if the CLI has been "initialized".
	TANZU_TOOLS_INIT_LOCK="${HOME}/.config/tanzu/.tanzu-init.lock"
	if [[ -f ${TANZU_TOOLS_INIT_LOCK} ]]; then

		writeLog "INFO" "The Tanzu CLI has already been initialized"
		TANZU_TOOLS_CLI_READY=TRUE
		return 0

	fi

	# Make sure that the interactive parts are not run in a VSCode remote env.
	if [[ ${ENVIRONMENT_VSCODE:-EMPTY} == "CONTAINER" ]]; then

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
			TANZU_TOOLS_CLI_READY=TRUE

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

	# Install all plugins recommended by the active contexts
	# only if the global flag is enabled and the local check.
	if [[ ${TANZU_TOOLS_SYNC_PLUGINS:-FALSE} != "TRUE" ]]; then

		writeLog "WARN" "Tanzu Tools plugin sync is disabled as the TANZU_TOOLS_SYNC_PLUGINS variable is set to ${TANZU_TOOLS_SYNC_PLUGINS:-FALSE}"

	elif [[ ${TANZU_TOOLS_CLI_PLUGIN_SYNC:-FALSE} != "TRUE" ]]; then

		writeLog "WARN" "Tanzu Tools plugin sync is skipped as the TANZU_TOOLS_CLI_PLUGIN_SYNC variable is set to ${TANZU_TOOLS_CLI_PLUGIN_SYNC:-FALSE}"

	else

		writeLog "INFO" "Installing Tanzu CLI plugins from the active context"

		tanzu plugin sync 1>>"${LOG_FILE}" 2>&1 || {
			writeLog "ERROR" "Failed to synchronise Tanzu CLI plugins"
			return 1
		}

	fi

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

	rsync \
		--archive \
		--verbose \
		"${YTT_LIB}" "${YTT_LIB_TKG}" \
		1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to sync ytt library from ${YTT_LIB} to ${YTT_LIB_TKG}"
		return 1
	}

	return 0

}

function tanzu_tools_sync_vendor() {

	# This is the location to push into.
	local VENDOR_DIR="${TANZU_TOOLS_SYNC_VENDOR_DIR:-vendor}"

	# These files are relative to the location of the vendor directory.
	local VENDIR_FILE_CONFIG="${TANZU_TOOLS_SYNC_VENDOR_CONFIG:-vendir.yml}"

	# The lock file will share the same name with modified extension.
	local VENDIR_FILE_LOCK="${VENDIR_FILE_CONFIG/.yml/.lock.yml}"

	# And just in case YAML != YML
	local VENDIR_FILE_LOCK="${VENDIR_FILE_LOCK/.yaml/.lock.yaml}"

	# Are the vendored dependencies pined
	local VENDIR_LOCKED="${TANZU_TOOLS_SYNC_VENDOR_LOCKED:-FALSE}"

	# There will likely be more args in the future.
	local VENDIR_ARGS=()

	# Confirm the vendor directory already exists.
	if [[ ! -d ${VENDOR_DIR} ]]; then
		writeLog "ERROR" "The vendor directory ${VENDOR_DIR} does not exist"
		return 1
	fi

	# Confirm the vendir file already exists.
	if [[ ! -f ${VENDIR_FILE_CONFIG} ]]; then
		writeLog "ERROR" "The vendir config file ${VENDIR_FILE_CONFIG} does not exist"
		return 1
	fi

	# Confirm the vendir lock-file already exists.
	if [[ ! -f ${VENDIR_FILE_LOCK} ]]; then
		writeLog "ERROR" "The vendir lock file ${VENDIR_FILE_LOCK} does not exist"
		return 1
	fi

	# To lock or not to lock, that is the question.
	if [[ ${VENDIR_LOCKED^^} == "TRUE" ]]; then
		VENDIR_ARGS+=("--locked")
	fi

	# shellcheck disable=SC2068
	vendir sync \
		--chdir "${VENDOR_DIR}" \
		--file "${VENDIR_FILE_CONFIG}" \
		--lock-file "${VENDIR_FILE_LOCK}" \
		${VENDIR_ARGS[@]:-} \
		--yes 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to run vendir sync"
		return 1
	}

	return 0

}

function tanzu_tools_path_vendor() {

	# This is the location to start from.
	local VENDOR_DIR="${TANZU_TOOLS_SYNC_VENDOR_DIR:-.}"

	# The vendir configuration will place all files into 'vendor'
	local VENDOR_DIR="${VENDOR_DIR}/vendor"

	# It's opinionated, but lets look for scripts in 'scripts'
	local SCRIPTS_HOME="${VENDOR_DIR}/scripts"

	# If the directory does not exist, no point continuing.
	if [[ ! -d ${VENDOR_DIR} ]]; then
		writeLog "DEBUG" "No vendor directory ${VENDOR_DIR}, skipping add to PATH"
		return 0
	fi

	# It's opinionated, but lets look for scripts in 'scripts'
	if [[ ! -d ${SCRIPTS_HOME} ]]; then
		writeLog "DEBUG" "No scripts directory ${SCRIPTS_HOME}, skipping add to PATH"
		return 0
	else
		writeLog "DEBUG" "Adding folder ${SCRIPTS_HOME} to PATH"
		export PATH="${SCRIPTS_HOME}:${PATH}"
	fi

	while IFS= read -r -d '' FOLDER; do

		writeLog "DEBUG" "Adding folder ${FOLDER} to the PATH"
		export PATH="${FOLDER}:${PATH}"

	done < <(find "${SCRIPTS_HOME}" -mindepth 1 -maxdepth 1 -type d -print0)
	# TODO: How deep should scripts be allowed to be nested?

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

function tanzu_tools_cli_context() {

	# If this is enabled, 'tanzu plugin sync' will be executed.
	TANZU_TOOLS_CLI_PLUGIN_SYNC=TRUE

	local -A CLI_CONTEXTS=()
	local CLI_CONTEXT
	local CLI_CONTEXT_SELECTED
	local VALUE
	local RETURN_CODE
	local PINNIPED_KUBECONFIG
	local OPTIONS=()
	local COUNT=0

	# Capture all available contexts into a dialog menu.
	while IFS=' ' read -r CLI_CONTEXT || [ -n "$CLI_CONTEXT" ]; do

		# Strip any whitespace
		CLI_CONTEXT=$(echo "${CLI_CONTEXT}" | xargs echo -n)

		# Increment the counter
		((COUNT++))

		# Add the CLI context into the associative array
		CLI_CONTEXTS[$COUNT]="$CLI_CONTEXT"

		# Add the CLI context into the menu options.
		OPTIONS+=(
			"${COUNT}" "${CLI_CONTEXTS[$COUNT]}"
		)

		writeLog "INFO" "Added Tanzu CLI context ${CLI_CONTEXT} into menu option ${COUNT}"

	done < <(tanzu context list -o yaml | yq .[].name)
	unset COUNT

	writeLog "DEBUG" "Loaded ${#CLI_CONTEXTS[@]} Tanzu CLI contexts into associative array"
	writeLog "DEBUG" "Contexts: ${CLI_CONTEXTS[*]}"
	writeLog "DEBUG" "Options: ${OPTIONS[*]}"

	if [[ ! ${#OPTIONS[@]} -gt 0 ]]; then

		writeLog "INFO" "No Tanzu CLI contexts found, skipping."
		TANZU_TOOLS_CLI_PLUGIN_SYNC=FALSE
		return 0

	fi

	# Present the user with a menu to select their context.
	dialogMenu "Tanzu CLI context" "Select the Tanzu CLI context to authenticate against:"

	#  0 = Yes
	#  1 = No
	#  2 = Help
	#  3 = Extra
	# -1 = Error

	VALUE=$("${CMD[@]}" "${BOX_OPTIONS[@]}" "${OPTIONS[@]}" 2>&1 >/dev/tty)
	RETURN_CODE=$?

	writeLog "DEBUG" "Dialog value: ${VALUE:-EMPTY}"
	writeLog "DEBUG" "Dialog return: ${RETURN_CODE:-EMPTY}"

	writeLog "DEBUG" "${CLI_CONTEXTS[@]}"

	case "${RETURN_CODE}" in

	0)

		CLI_CONTEXT_SELECTED="${CLI_CONTEXTS[$VALUE]}"
		writeLog "INFO" "The user selected the option ${VALUE} on the Tanzu CLI context menu which is $CLI_CONTEXT_SELECTED"

		;;

	1)

		writeLog "WARN" "The user selected NO on the Tanzu CLI context menu, aborting"
		TANZU_TOOLS_CLI_PLUGIN_SYNC=FALSE
		return 0

		;;

	2)

		# TODO: Do we need to implement help?
		writeLog "WARN" "The user selected HELP on the Tanzu CLI context menu, aborting"
		TANZU_TOOLS_CLI_PLUGIN_SYNC=FALSE
		return 0

		;;

	3)

		writeLog "WARN" "Unhandled selection 'extra' on the Tanzu CLI context menu, aborting with error"
		TANZU_TOOLS_CLI_PLUGIN_SYNC=FALSE
		return 0

		;;

	-1)

		writeLog "ERROR" "Error processing user selection on the Tanzu CLI context menu, aborting with error"
		TANZU_TOOLS_CLI_PLUGIN_SYNC=FALSE
		return 1

		;;

	255)

		writeLog "WARN" "Timeout waiting for user selection on the Tanzu CLI context menu, aborting"
		TANZU_TOOLS_CLI_PLUGIN_SYNC=FALSE
		return 0

		;;

	*)

		writeLog "ERROR" "Unhandled return code ${RETURN_CODE} while processing user selection on the Tanzu CLI context menu, aborting with error"
		TANZU_TOOLS_CLI_PLUGIN_SYNC=FALSE
		return 1

		;;

	esac

	# If the context pinniped, start a new session.
	if grep -s pinniped <<<"${CLI_CONTEXT_SELECTED}" 1>/dev/null 2>&1; then

		# Obtain the kubeconfig path for the selected context.
		export CLI_CONTEXT_SELECTED
		PINNIPED_KUBECONFIG=$(tanzu context list -o yaml | yq --expression '.[] | select(.name == env(CLI_CONTEXT_SELECTED)).kubeconfigpath')

		writeLog "INFO" "A Pinniped context was selection, starting Authentication session with kubeconfig ${PINNIPED_KUBECONFIG}"

		tanzu_tools_pinniped_session "${PINNIPED_KUBECONFIG}" || {
			writeLog "ERROR" "Failed to start Pinniped session!"
			TANZU_TOOLS_CLI_PLUGIN_SYNC=FALSE
			return 1
		}

	fi

	# Now, finally use the given context.
	tanzu context use "${CLI_CONTEXT_SELECTED}" 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to use Tanzu CLI context ${CLI_CONTEXT_SELECTED}"
		TANZU_TOOLS_CLI_PLUGIN_SYNC=FALSE
		return 1
	}

	return 0

}

function tanzu_tools_pinniped_session() {

	# Checks to see if a Pinniped session has been started
	# or otherwise attempts to create one.

	#local PINNIPED_CONFIG_DIR="${HOME}/.config/pinniped"
	local PINNIPED_HOME_DIR="${HOME}/.pinniped"
	local PINNIPED_KUBECONFIG="${1}"

	# Check if the global feature flag is enabled first or skip this code path.
	if [[ ${TANZU_TOOLS_ENABLE_PINNIPED:-FALSE} != "TRUE" ]]; then

		writeLog "WARN" "Pinniped session has been disable due to global variable TANZU_TOOLS_ENABLE_PINNIPED being set to ${TANZU_TOOLS_ENABLE_PINNIPED:-FALSE}"
		return 0

	fi

	# Is the Pinniped binary available?
	checkBin pinniped || {
		writeLog "ERROR" "The Pinniped CLI is not available in the PATH"
		return 1
	}

	# Does the Pinniped home directory exist
	if [[ ! -d ${PINNIPED_HOME_DIR} ]]; then
		writeLog "ERROR" "The Pinniped home directory does not exist at ${PINNIPED_HOME_DIR}"
		return 1
	fi

	# Does the provided kubeconfig file exist
	if [[ ! -f ${PINNIPED_KUBECONFIG} ]]; then
		writeLog "ERROR" "The provided Pinniped kubeconfig file does not exist. Please check the file ${PINNIPED_KUBECONFIG}"
		return 1
	fi

	# Start a Pinniped session using the provided kubeconfig
	tput clear

	showHeader "Pinniped session"

	pinniped whoami \
		--timeout 300s \
		--kubeconfig "${PINNIPED_KUBECONFIG}" ||
		{
			writeLog "ERROR" "Failed to start a Pinniped session"
			return 1
		}

	tput clear

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
	unset TANZU_TOOLS_CLI_READY
	unset TANZU_TOOLS_CLI_OCI_URL
	unset TANZU_TOOLS_CLI_PLUGIN_SYNC
	unset TKG_CUSTOM_IMAGE_REPOSITORY

	# Make sure job control is on
	set -m

	dialogProgress "Tanzu Tools: Launching..." "10"

	# HACK: Multi-environments are tough, sometimes you need to
	# 		use an isolated and totally separate configuration for each.
	if [[ ${TANZU_TOOLS_CLI_HACK_SYMLINK_ENABLED:-FALSE} == "TRUE" ]]; then
		tanzu_tools_cli_envs || {
			MESSAGE="Failed to configure Tanzu CLI environments"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1
		}
	fi

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

	if [[ ${TANZU_TOOLS_CLI_READY:-FALSE} == "TRUE" ]]; then

		dialogProgress "Tanzu Tools: Launching..." "30"

		# Apply user customizations based on provided variables.
		# The user customizations function displays it's own dialog boxes.
		tanzu_tools_cli_custom || {
			MESSAGE="Failed to set the Tanzu CLI user customisations"
			writeLog "ERROR" "${MESSAGE}"
			return 1
		}

		dialogProgress "Tanzu Tools: Launching..." "40"

		# Ask the user to select the Tanzu CLI context work in and authenticate against.
		# If this fails, the process can continue but we cannot sync the plugins without auth.
		tanzu_tools_cli_context || {
			MESSAGE="Failed to enter the selected Tanzu CLI context, skipping plugin sync if enabled."
			writeLog "WARNING" "${MESSAGE}"
			TANZU_TOOLS_CLI_PLUGIN_SYNC=FALSE
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

		# Use vendir to sync vendored dependencies
		if [[ ${TANZU_TOOLS_SYNC_VENDOR:-FALSE} == "TRUE" ]]; then

			tanzu_tools_sync_vendor || {
				MESSAGE="Failed to sync vendored dependencies with vendir"
				writeLog "ERROR" "${MESSAGE}"
				dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
				return 1
			}

			# If there is vendored scripts, add them to the path.
			tanzu_tools_path_vendor || {
				MESSAGE="Failed to update the PATH variable for vendored dependencies"
				writeLog "ERROR" "${MESSAGE}"
				dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
				return 1
			}

		else

			writeLog "INFO" "Tanzu Tools is not enabled to sync vendored depencendies, skipping."

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
