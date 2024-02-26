#!/usr/bin/env bash

##################################################
# Name: k8s_tools_tanzu.sh
# Description: Tanzu helper functions.
##################################################

# No phoning home from the Tanzu CLI is allowed.
export TANZU_CLI_CEIP_OPT_IN_PROMPT_ANSWER="no"

# ytt library location
export YTT_LIB="/usr/lib/ytt/"

# These variables are passed in as Docker arguments or defaults are set here if missing.
export TANZU_CLI_PLUGIN_INVENTORY_TAG="${TANZU_CLI_PLUGIN_INVENTORY_TAG:-latest}"
export TANZU_CLI_PLUGIN_GROUP_TKG_TAG="${TANZU_CLI_PLUGIN_GROUP_TKG_TAG:-latest}"

# Downstream scripts need the TKG_VERSION
export TKG_VERSION="${TANZU_CLI_PLUGIN_GROUP_TKG_TAG}"

function k8s_tools_distro_launch() {

	writeLog "DEBUG" "Resetting variables"

	unset TANZU_CLI_READY
	unset TANZU_CLI_OCI_URL
	unset TANZU_CLI_PLUGIN_SYNC
	unset TKG_CUSTOM_IMAGE_REPOSITORY

	# Make sure job control is on
	set -m

	dialogProgress "${K8S_TOOLS_TITLE}: Launching..." "10"

	# HACK: Multi-environments are tough, sometimes you need to
	# 		use an isolated and totally separate configuration for each.
	if [[ ${TANZU_CLI_SYMLINK_ENABLED:-FALSE} == "TRUE" ]]; then

		tanzu_cli_envs || {
			MESSAGE="Failed to configure Tanzu CLI environments"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1
		}

	fi

	dialogProgress "${K8S_TOOLS_TITLE}: Launching..." "20"

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

	dialogProgress "${K8S_TOOLS_TITLE}: Launching..." "30"

	# If this is the first time, an initialization process is required
	# to accept the EULA and disable the Telemetry
	tanzu_cli_init || {

		MESSAGE="Failed to initialize the Tanzu CLI"
		writeLog "ERROR" "${MESSAGE}"
		dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
		return 1

	}

	if [[ ${TANZU_CLI_READY:-FALSE} == "TRUE" ]]; then

		dialogProgress "Tanzu CLI: Launching..." "40"

		# Apply user customizations based on provided variables.
		# The user customizations function displays it's own dialog boxes.
		tanzu_cli_custom || {
			MESSAGE="Failed to set the Tanzu CLI user customisations"
			writeLog "ERROR" "${MESSAGE}"
			return 1
		}

		dialogProgress "${K8S_TOOLS_TITLE}: Launching..." "50"

		# Ask the user to select the Tanzu CLI context work in and authenticate against.
		# If this fails, the process can continue but we cannot sync the plugins without auth.
		tanzu_cli_context || {
			MESSAGE="Failed to enter the selected Tanzu CLI context, skipping plugin sync if enabled."
			writeLog "WARNING" "${MESSAGE}"
			TANZU_CLI_PLUGIN_SYNC=FALSE
		}

		dialogProgress "${K8S_TOOLS_TITLE}: Launching..." "60"

		# Download the Tanzu CLI plugins.
		tanzu_cli_plugins || {
			MESSAGE="Failed to download the Tanzu CLI plugins"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1
		}

		dialogProgress "${K8S_TOOLS_TITLE}: Launching..." "75"

	else

		writeLog "WARN" "Tanzu CLI: Not ready... skipping plugin downloads"

	fi

	dialogProgress "${K8S_TOOLS_TITLE}: Launching..." "100"

	tput clear

}

##################################################
# Tanzu CLI
##################################################

function tanzu_cli_nuke() {

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

function tanzu_cli_envs() {

	local ENVIRONMENT="${TANZU_CLI_ENVIRONMENT:-default}"
	local TANZU_CLI_HOME_DEFAULT="${HOME}/.config/tanzu"
	local TANZU_CLI_HOME="${TANZU_CLI_HOME:-$HOME/.config/tanzu-envs/$ENVIRONMENT}"

	# If this function has been called, we assume the user knows what they are doing.
	writeLog "INFO" "Configuring ${K8S_TOOLS_TITLE} environment folder symlink"

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

function tanzu_cli_custom() {

	# Runs the correct functions based on user provided variables.

	# There are 5 supported options for the Tanzu CLI OCI Registry that we need to deal with.
	# In order of preference they are:
	#
	#	1. If multi-site is active, go through that nonsense first.
	# 	2. If a custom registry is provided, use it as fall back option 1.
	# 	3. If a pull-through cache is provided, use it as fall back option 2.
	# 	4. If no pull-through or custom registry is provided, and a Proxy is needed, create `scripts/proxy.sh` as per the docs.
	# 	5. If no pull-through or custom registry is provided, pull direct from the internet as last resort.

	local TANZU_CLI_DEFAULT_URL

	dialogProgress "Tanzu CLI: Applying user customizations..." "0"

	# HACK: Reset the plugin URL to defaults each run.
	tanzu plugin source init 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to initialize the Tanzu CLI plugin source."
		return 1
	}

	# Capture existing OCI URL as the default.
	TANZU_CLI_DEFAULT_URL=$(tanzu plugin source list --output yaml | yq '.[] | select(.name == "default") | .image')

	# Strip the current inventory image tag.
	TANZU_CLI_OCI_URL="${TANZU_CLI_DEFAULT_URL%:*}"

	# Add the user provided image tag.
	TANZU_CLI_OCI_URL="${TANZU_CLI_OCI_URL}:${TANZU_CLI_PLUGIN_INVENTORY_TAG}"

	export TANZU_CLI_OCI_URL

	writeLog "DEBUG" "The current Tanzu CLI OCI URL is ${TANZU_CLI_OCI_URL}"

	dialogProgress "Tanzu CLI: Applying user customizations..." "10"

	#########################
	# 1. Multi-Site
	#########################

	if [[ ${TANZU_SITES_ENABLED:-FALSE} == "TRUE" ]]; then

		tanzu_multi_site || {

			MESSAGE="Failed to configure ${K8S_TOOLS_TITLE} for multi-site!"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1

		}

	#########################
	# 2. Custom Registry
	#########################

	elif [[ ${TANZU_CUSTOM_REGISTRY:-EMPTY} != "EMPTY" ]]; then

		tanzu_registry_custom || {

			MESSAGE="Failed to configure ${K8S_TOOLS_TITLE} with a custom registry"
			writeLog "ERROR" "${MESSAGE}"
			dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
			return 1

		}

	#########################
	# 3. Pull-through cache
	#########################

	elif [[ ${TANZU_PULL_THROUGH_CACHE:-EMPTY} != "EMPTY" ]]; then

		tanzu_registry_cache || {

			MESSAGE="Failed to configure ${K8S_TOOLS_TITLE} with a pull-through registry cache"
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
	tanzu plugin source update default --uri "${TANZU_CLI_OCI_URL}" 1>>"${LOG_FILE}" 2>&1 || {

		MESSAGE="Failed to update plugin source to ${TANZU_CLI_OCI_URL}. Please check connectivity"
		writeLog "ERROR" "${MESSAGE}"
		dialogMsgBox "ERROR" "${MESSAGE}.\n\nReview the session logs for further information."
		return 1

	}

	dialogProgress "Tanzu CLI: Apply user customizations..." "100"

	return 0

}

function tanzu_cli_init() {

	# Initialize the Tanzu CLI for first time users.
	TANZU_CLI_READY=FALSE

	# We use a fake lock file to determine if the CLI has been "initialized".
	TANZU_CLI_INIT_LOCK="${HOME}/.config/tanzu/.tanzu-init.lock"

	if [[ -f ${TANZU_CLI_INIT_LOCK} ]]; then

		writeLog "INFO" "The Tanzu CLI has already been initialized"
		TANZU_CLI_READY=TRUE
		return 0

	fi

	# Make sure that the interactive parts are not run in a VSCode remote env.
	if [[ ${K8S_TOOLS_ENVIRONMENT:-EMPTY} == "CONTAINER" ]]; then

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

			tanzu_cli_nuke || {
				writeLog "ERROR" "Failed to initialize the Tanzu CLI"
				break
			}

			dialogProgress "Tanzu CLI: Initializing..." "50"

			# Finished, write the lock and exit the loop.
			cat <<-EOF >"${TANZU_CLI_INIT_LOCK}"

				The Tanzu CLI was successfully initialized on $(date)

				You can remove this lock file for the initialization process to run again on next launch.

			EOF

			dialogProgress "Tanzu CLI: Initializing..." "100"
			TANZU_CLI_READY=TRUE

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

function tanzu_cli_plugins() {

	dialogProgress "Tanzu CLI: Downloading Plugins..." "25"

	# Install all plugins recommended by the active contexts
	# only if the global flag is enabled and the local check.
	if [[ ${TANZU_CLI_SYNC_PLUGINS:-FALSE} != "TRUE" ]]; then

		writeLog "WARN" "${K8S_TOOLS_TITLE} plugin sync is disabled as the TANZU_CLI_SYNC_PLUGINS variable is set to ${TANZU_CLI_SYNC_PLUGINS:-FALSE}"

	elif [[ ${TANZU_CLI_PLUGIN_SYNC:-FALSE} != "TRUE" ]]; then

		writeLog "WARN" "${K8S_TOOLS_TITLE} plugin sync is skipped as the TANZU_CLI_PLUGIN_SYNC variable is set to ${TANZU_CLI_PLUGIN_SYNC:-FALSE}"

	else

		writeLog "INFO" "Installing Tanzu CLI plugins from the active context"

		tanzu plugin sync 1>>"${LOG_FILE}" 2>&1 || {
			writeLog "ERROR" "Failed to synchronise Tanzu CLI plugins"
			return 1
		}

	fi

	dialogProgress "Tanzu CLI: Downloading Plugins..." "50"

	# Add the VMWare TKG group of plugins at the configured version to match the CLI.
	tanzu plugin install --group "vmware-tkg/default:${TANZU_CLI_PLUGIN_GROUP_TKG_TAG}" 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to install the Tanzu plugin group vmware-tkg/default:${TANZU_CLI_PLUGIN_GROUP_TKG_TAG}"
		return 1
	}

	dialogProgress "Tanzu CLI: Downloading Plugins..." "100"

	return 0

}

function tanzu_cli_context() {

	# If this is enabled, 'tanzu plugin sync' will be executed.
	TANZU_CLI_PLUGIN_SYNC=TRUE

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
		TANZU_CLI_PLUGIN_SYNC=FALSE
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
		TANZU_CLI_PLUGIN_SYNC=FALSE
		return 0

		;;

	2)

		# TODO: Do we need to implement help?
		writeLog "WARN" "The user selected HELP on the Tanzu CLI context menu, aborting"
		TANZU_CLI_PLUGIN_SYNC=FALSE
		return 0

		;;

	3)

		writeLog "WARN" "Unhandled selection 'extra' on the Tanzu CLI context menu, aborting with error"
		TANZU_CLI_PLUGIN_SYNC=FALSE
		return 0

		;;

	-1)

		writeLog "ERROR" "Error processing user selection on the Tanzu CLI context menu, aborting with error"
		TANZU_CLI_PLUGIN_SYNC=FALSE
		return 1

		;;

	255)

		writeLog "WARN" "Timeout waiting for user selection on the Tanzu CLI context menu, aborting"
		TANZU_CLI_PLUGIN_SYNC=FALSE
		return 0

		;;

	*)

		writeLog "ERROR" "Unhandled return code ${RETURN_CODE} while processing user selection on the Tanzu CLI context menu, aborting with error"
		TANZU_CLI_PLUGIN_SYNC=FALSE
		return 1

		;;

	esac

	# If the context pinniped, start a new session.
	if grep -s pinniped <<<"${CLI_CONTEXT_SELECTED}" 1>/dev/null 2>&1; then

		# Obtain the kubeconfig path for the selected context.
		export CLI_CONTEXT_SELECTED
		PINNIPED_KUBECONFIG=$(tanzu context list -o yaml | yq --expression '.[] | select(.name == env(CLI_CONTEXT_SELECTED)).kubeconfigpath')

		writeLog "INFO" "A Pinniped context was selected, starting Authentication session with kubeconfig ${PINNIPED_KUBECONFIG}"

		tanzu_pinniped_session "${PINNIPED_KUBECONFIG}" || {
			writeLog "ERROR" "Failed to start Pinniped session!"
			TANZU_CLI_PLUGIN_SYNC=FALSE
			return 1
		}

	fi

	# Now, finally use the given context.
	tanzu context use "${CLI_CONTEXT_SELECTED}" 1>>"${LOG_FILE}" 2>&1 || {
		writeLog "ERROR" "Failed to use Tanzu CLI context ${CLI_CONTEXT_SELECTED}"
		TANZU_CLI_PLUGIN_SYNC=FALSE
		return 1
	}

	return 0

}

##################################################
# Tanzu Sites
##################################################

function tanzu_multi_site() {

	# Allows the user to select the site they are working with.

	local -A SITES_ARRAY=()
	local SITE
	local VALUE
	local RETURN_CODE
	local OPTIONS=()
	local NUM=0

	# There are two modes of operation; pull-through-cache or isolated-cluster.
	local ENABLE_ISOLATED_CLUSTER_MODE=FALSE
	local ENABLE_PULL_THROUGH_CACHE=FALSE

	# Docker env doesn't support arrays. The users needs to provide a CSV variable.
	# If the user has provided a list of sites.
	if [[ ${TANZU_SITES:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "Failed to configure Multi-Site support"
		writeLog "ERROR" "In order to use Multi-Site support you must provide a comma-separated value of sites in the variable named 'TANZU_SITES'"
		return 1
	else
		writeLog "INFO" "Processing sites ${TANZU_SITES}"
	fi

	while IFS="," read -rd, SITE || [ -n "$SITE" ]; do

		# Strip any whitespace
		SITE=$(echo "${SITE}" | xargs echo -n)

		if [[ ${SITE:-EMPTY} == "EMPTY" ]]; then
			writeLog "ERROR" "Error processing site variable. Please check the contents of the TANZU_SITES variable is correct."
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

	done < <(printf "%s\n" "${TANZU_SITES}")
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

	# TODO: Handle additional edge cases.
	case "${RETURN_CODE}" in

	"1")

		writeLog "WARN" "The user selected NO on the multi-site configuration dialog. Aborting configuration."
		dialogMsgBox "WARNING" "Unable to continue as the cancel button was selected. Aborting configuration."
		exit 0

		;;

	"255")

		writeLog "WARN" "Timeout during site selection dialog. Aborting configuration"
		dialogMsgBox "WARNING" "Timeout during site selection dialog. Aborting configuration"
		exit 0

		;;

	"0")

		if [[ ${VALUE:-EMPTY} == "EMPTY" ]]; then

			writeLog "ERROR" "Error during site selection dialog. The value for the site was empty"
			return 1

		fi

		# OK

		;;

	*)

		writeLog "ERROR" "Unhandled error during site selection dialog"
		return 1

		;;

	esac

	writeLog "DEBUG" "Checking variables for site ${SITES_ARRAY[$VALUE]}"

	# Export a variable into the environment with the site name.
	TANZU_SITE_NAME="${SITES_ARRAY[$VALUE]}"

	# Build the variable name as a string
	VAR_PULL_THROUGH_CACHE="TANZU_SITE_${SITES_ARRAY[$VALUE]}_PULL_THROUGH_CACHE"
	VAR_REGISTRY="TANZU_SITE_${SITES_ARRAY[$VALUE]}_REGISTRY"
	VAR_CLI_PLUGIN_INVENTORY_TAG="TANZU_SITE_${SITES_ARRAY[$VALUE]}_CLI_PLUGIN_INVENTORY_TAG"
	VAR_CLI_PLUGIN_GROUP_TKG_TAG="TANZU_SITE_${SITES_ARRAY[$VALUE]}_CLI_PLUGIN_GROUP_TKG_TAG"

	# Convert string to uppercase
	VAR_REGISTRY=${VAR_REGISTRY^^}
	VAR_PULL_THROUGH_CACHE=${VAR_PULL_THROUGH_CACHE^^}
	VAR_CLI_PLUGIN_INVENTORY_TAG=${VAR_CLI_PLUGIN_INVENTORY_TAG^^}
	VAR_CLI_PLUGIN_GROUP_TKG_TAG=${VAR_CLI_PLUGIN_GROUP_TKG_TAG^^}

	# Replace any dashes with underscores
	VAR_REGISTRY=${VAR_REGISTRY//-/_}
	VAR_PULL_THROUGH_CACHE=${VAR_PULL_THROUGH_CACHE//-/_}
	VAR_CLI_PLUGIN_INVENTORY_TAG=${VAR_CLI_PLUGIN_INVENTORY_TAG//-/_}
	VAR_CLI_PLUGIN_GROUP_TKG_TAG=${VAR_CLI_PLUGIN_GROUP_TKG_TAG//-/_}

	# Replace any spaces with underscores
	VAR_REGISTRY=${VAR_REGISTRY// /_}
	VAR_PULL_THROUGH_CACHE=${VAR_PULL_THROUGH_CACHE// /_}
	VAR_CLI_PLUGIN_INVENTORY_TAG=${VAR_CLI_PLUGIN_INVENTORY_TAG// /_}
	VAR_CLI_PLUGIN_GROUP_TKG_TAG=${VAR_CLI_PLUGIN_GROUP_TKG_TAG// /_}

	##########
	# Pull-through cache or Isolated Cluster?
	##########

	# You can only use either a pull-through cache registry or use isolated-cluster mode.

	if checkVarEmpty "${VAR_PULL_THROUGH_CACHE}" "Pull-through cache for site ${SITES_ARRAY[$VALUE]}"; then

		writeLog "WARN" "Pull-through cache is missing for site, checking for registry variable"

		if checkVarEmpty "${VAR_REGISTRY}" "Container registry for site ${SITES_ARRAY[$VALUE]}"; then

			dialogMsgBox "ERROR" "A required site variable is missing. Please set either the variable named ${VAR_PULL_THROUGH_CACHE} or ${VAR_REGISTRY}"
			return 1

		else

			# Were using isolated cluster mode.
			ENABLE_ISOLATED_CLUSTER_MODE=TRUE

			# Obtain the current contents of the variable
			REGISTRY="${!VAR_REGISTRY:-EMPTY}"

			# Double check our work.
			if [[ ${REGISTRY} == "EMPTY" ]]; then
				writeLog "ERROR" "Error encounted obtaining the variable contents for site ${SITES_ARRAY[$VALUE]}. The variable is meant to be named ${VAR_REGISTRY}"
				return 1
			else
				writeLog "DEBUG" "The site ${SITES_ARRAY[$VALUE]} has a registry value of ${REGISTRY}"
			fi

		fi

	else

		# Were using a pull-through cache
		ENABLE_PULL_THROUGH_CACHE=TRUE

		# Obtain the current contents of the variable
		PULL_THROUGH_CACHE="${!VAR_PULL_THROUGH_CACHE:-EMPTY}"

		# Double check our work.
		if [[ ${PULL_THROUGH_CACHE} == "EMPTY" ]]; then
			writeLog "ERROR" "Error encounted obtaining the variable contents for site ${SITES_ARRAY[$VALUE]}. The variable is meant to be named ${VAR_PULL_THROUGH_CACHE}"
			return 1
		else
			writeLog "DEBUG" "The site ${SITES_ARRAY[$VALUE]} has a pull-through cache value of ${PULL_THROUGH_CACHE}"
		fi

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
			TANZU_CLI_PLUGIN_INVENTORY_TAG="${CLI_PLUGIN_INVENTORY_TAG}"
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
			TANZU_CLI_PLUGIN_GROUP_TKG_TAG="${CLI_PLUGIN_GROUP_TKG_TAG}"
		fi

	fi

	##########
	# Export variables
	##########

	# If were using a pull-through cache
	if [[ ${ENABLE_PULL_THROUGH_CACHE} == "TRUE" ]]; then

		writeLog "INFO" "Exporting variables for pull-through cache mode"

		# Add the pull-through prefix to the Tanzu CLI URL
		TANZU_CLI_OCI_URL="${PULL_THROUGH_CACHE}/${TANZU_CLI_OCI_URL}"

		# Add the pull-through prefix to the TKG URL
		TKG_CUSTOM_IMAGE_REPOSITORY="${PULL_THROUGH_CACHE}/projects.registry.vmware.com/tkg"

	# Else if were using isolated cluster mode
	elif [[ ${ENABLE_ISOLATED_CLUSTER_MODE} == "TRUE" ]]; then

		writeLog "INFO" "Exporting variables for isolated-cluster-mode"

		# Strip the VMware registry prefix.
		TANZU_CLI_OCI_URL="${TANZU_CLI_OCI_URL#*projects.registry.vmware.com}"

		# Add the multi-site registry OCI URL to the Tanzu CLI URL
		TANZU_CLI_OCI_URL="${REGISTRY}${TANZU_CLI_OCI_URL}"

		# Add the multi-site registry OCI URL to the TKG URL
		TKG_CUSTOM_IMAGE_REPOSITORY="${REGISTRY}/tkg"

	# Catch unhandled error
	else

		dialogMsgBox "ERROR" "Unhandled error determining if using pull-through cache or isolated cluster mode. Log a bug with the session logs."
		return 1

	fi

	# Export the correct registry variables for the selected site.
	TKG_VERSION="${TANZU_CLI_PLUGIN_GROUP_TKG_TAG}"

	# Strip the current inventory image tag.
	TANZU_CLI_OCI_URL="${TANZU_CLI_OCI_URL%:*}"

	# Add the user provided image tag.
	TANZU_CLI_OCI_URL="${TANZU_CLI_OCI_URL}:${TANZU_CLI_PLUGIN_INVENTORY_TAG}"

	# Export the final results
	export TANZU_SITE_NAME
	export TKG_VERSION TANZU_CLI_PLUGIN_GROUP_TKG_TAG TANZU_CLI_PLUGIN_INVENTORY_TAG
	export TANZU_CLI_OCI_URL TKG_CUSTOM_IMAGE_REPOSITORY

	writeLog "INFO" "The site registry URL for Tanzu CLI has been set to ${TANZU_CLI_OCI_URL}"

	writeLog "INFO" "The custom registry URL for TKG has been set to ${TKG_CUSTOM_IMAGE_REPOSITORY}"

	return 0

}

function tanzu_registry_custom() {

	# Sets the registry based on user provided variables

	writeLog "INFO" "A custom image registry was provided, using ${TANZU_CUSTOM_REGISTRY}"

	# Strip the VMware registry prefix.
	TANZU_CLI_OCI_URL="${TANZU_CLI_OCI_URL#*projects.registry.vmware.com}"

	# Add the custom registry OCI URL to the Tanzu CLI URL
	TANZU_CLI_OCI_URL="${TANZU_CUSTOM_REGISTRY}${TANZU_CLI_OCI_URL}"

	# Add the custom registry OCI URL to the TKG URL
	TKG_CUSTOM_IMAGE_REPOSITORY="${TANZU_CUSTOM_REGISTRY}/tkg"

	# Export the final results
	export TANZU_CLI_OCI_URL TKG_CUSTOM_IMAGE_REPOSITORY

	writeLog "INFO" "The custom registry URL for Tanzu CLI has been set to ${TANZU_CLI_OCI_URL}"

	writeLog "INFO" "The custom registry URL for TKG has been set to ${TKG_CUSTOM_IMAGE_REPOSITORY}"

	return 0

}

function tanzu_registry_cache() {

	# Sets the registry cache based on user provided variables

	writeLog "INFO" "Configuring the Tanzu CLI with a pull-through cache of ${TANZU_PULL_THROUGH_CACHE}"

	# Add the pull-through prefix to the Tanzu CLI URL
	TANZU_CLI_OCI_URL="${TANZU_PULL_THROUGH_CACHE}/${TANZU_CLI_OCI_URL}"

	# Add the pull-through prefix to the TKG URL
	TKG_CUSTOM_IMAGE_REPOSITORY="${TANZU_PULL_THROUGH_CACHE}/projects.registry.vmware.com/tkg"

	# Export the final results
	export TANZU_CLI_OCI_URL TKG_CUSTOM_IMAGE_REPOSITORY

	writeLog "INFO" "The pull-through cache URL for Tanzu CLI has been set to ${TANZU_CLI_OCI_URL}"

	writeLog "INFO" "The pull-through cache URL for TKG has been set to ${TKG_CUSTOM_IMAGE_REPOSITORY}"

	return 0

}

function tanzu_pinniped_session() {

	# Checks to see if a Pinniped session has been started
	# or otherwise attempts to create one.

	#local PINNIPED_CONFIG_DIR="${HOME}/.config/pinniped"
	local PINNIPED_HOME_DIR="${HOME}/.pinniped"
	local PINNIPED_KUBECONFIG="${1}"

	# Check if the global feature flag is enabled first or skip this code path.
	if [[ ${TANZU_PINNIPED_ENABLED:-FALSE} != "TRUE" ]]; then

		writeLog "WARN" "Pinniped session has been disabled due to global variable TANZU_PINNIPED_ENABLED being set to ${TANZU_PINNIPED_ENABLED:-FALSE}"
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

	figlet -f "${FIGLET_FONT:-standard}" "Pinniped"

	pinniped whoami \
		--timeout 300s \
		--kubeconfig "${PINNIPED_KUBECONFIG}" ||
		{
			writeLog "ERROR" "Failed to start a Pinniped session"
			return 1
		}

	export KUBECONFIG="${PINNIPED_KUBECONFIG}"

	tput clear

	return 0

}
