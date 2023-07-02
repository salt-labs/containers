#!/usr/bin/env bash

##################################################
# Name: functions.sh
# Description: useful shell functions
##################################################

#########################
# Common
#########################

function checkBin() {

	# Checks the binary name is available in the path

	local COMMAND="$1"

	#if ( command -v "${COMMAND}" 1> /dev/null ) ; # command breaks with aliases
	if (type -P "${COMMAND}" &>/dev/null); then
		writeLog "DEBUG" "The command $COMMAND is available in the Path"
		return 0
	else
		writeLog "DEBUG" "The command $COMMAND is not available in the Path"
		return 1
	fi

}

function checkReqs() {

	# Make sure all the required binaries are available within the path
	for BIN in "${REQ_BINS[@]}"; do
		writeLog "DEBUG" "Checking for dependant binary ${BIN}"
		checkBin "${BIN}" || {
			writeLog "ERROR" "Please install the ${BIN} binary on this system in order to run ${SCRIPT}"
			return 1
		}
	done

	return 0

}

function checkPermissions() {

	# Checks if the user is running as root

	if [ "${EUID}" -ne 0 ]; then
		return 1
	else
		return 0
	fi

}

function checkLogLevel() {

	# Only the following log levels are supported.
	#   DEBUG
	#   INFO or INFORMATION
	#   WARN or WARNING
	#   ERR or ERROR

	local LEVEL="${1}"
	export LOGLEVEL

	# POSIX be gone!
	# LOGLEVEL="$( echo "${1}" | tr '[:lower:]' '[:upper:]' )"
	case "${LEVEL^^}" in

	"DEBUG" | "TRACE")

		export LOGLEVEL="DEBUG"

		;;

	"INFO" | "INFORMATION")

		export LOGLEVEL="INFO"

		;;

	"WARN" | "WARNING")

		export LOGLEVEL="WARN"

		;;

	"ERR" | "ERROR")

		export LOGLEVEL="ERR"

		;;

	*)

		writeLog "INFO" "An unknown log level of ${LEVEL^^} was provided, defaulting to INFO"
		export LOGLEVEL="INFO"

		;;

	esac

	return 0

}

function writeLog() {

	local LEVEL
	local MESSAGE

	if [[ ${1:-EMPTY} == "EMPTY" ]]; then
		LEVEL="INFO"
	else
		LEVEL="${1}"
	fi

	if [[ ${2:-EMPTY} == "EMPTY" ]]; then
		MESSAGE="No message provided to log function"
	else
		MESSAGE="${2}"
	fi

	case "${LEVEL^^}" in

	"DEBUG" | "TRACE")

		LEVEL="DEBUG"

		# Do not show debug messages if the level is > debug
		if [ ! "${LEVEL^^}" = "${LOGLEVEL^^}" ]; then
			return 0
		fi

		;;

	"INFO" | "INFORMATION")

		LEVEL="INFO"

		# Do not show info messages if the level is > info
		if [ "${LOGLEVEL^^}" = "WARN" ] || [ "${LOGLEVEL^^}" = "ERR" ]; then
			return 0
		fi

		;;

	"WARN" | "WARNING")

		LEVEL="WARN"

		# Do not show warn messages if the level is > warn
		if [ "${LOGLEVEL^^}" = "ERR" ]; then
			return 0
		fi

		;;

	"ERR" | "ERROR")

		LEVEL="ERR"

		# Errors are always shown

		;;

	*)

		MESSAGE="Unknown log level ${LEVEL^^} provided to log function. Valid options are DEBUG, INFO, WARN, ERR"
		LEVEL="ERR"

		;;

	esac

	echo "$(date +"%Y/%m/%d %H:%M:%S") [${LEVEL^^}] ${MESSAGE}"

	return 0

}

function checkVarEmpty() {

	# Returns true if the variable is empty

	# NOTE:
	#	Pass this function the string NAME of the variable
	#	Not the expanded contents of the variable itself.

	local VAR_NAME="${1}"
	local VAR_DESC="${2}"

	if [[ ${!VAR_NAME:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "The variable ${VAR_DESC} is empty."
		return 0
	else
		writeLog "DEBUG" "The variable ${VAR_DESC} is not empty, it is set to ${!VAR_NAME}"
		return 1
	fi

}

function checkResult() {

	local RESULT="${1}"

	if [ "${RESULT}" -ne 0 ]; then
		return 1
	else
		return 0
	fi

}

#########################
# Specific
#########################

function build_container() {

	local BUILD_SYSTEM
	local HOST_SYSTEM
	local CONTAINER

	if [[ ${1:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "No build system provided to build_container function"
		return 1
	else
		BUILD_SYSTEM="${1}"
	fi

	if [[ ${2:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "No host system provided to build_container function"
		return 1
	else
		HOST_SYSTEM="${2}"
	fi

	if [[ ${3:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "No container provided to build_container function"
		return 1
	else
		CONTAINER="${2}"
	fi

	nix build --impure ".#packages.${BUILD_SYSTEM}.${HOST_SYSTEM}.${CONTAINER}" || {
		writeLog "ERROR" "Failed to build container ${CONTAINER}"
		exit 1
	}

}

function publish_container() {

	local OCI_ARCHIVE
	local IMAGE_NAME
	local IMAGE_TAG

	if [[ ${1:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "No OCI archive provided to publish_container function"
		return 1
	else
		OCI_ARCHIVE="${1}"
	fi

	if [[ ${2:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "No image name provided to publish_container function"
		return 1
	else
		IMAGE_NAME="${2}"
	fi

	if [[ ${3:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "No image tag provided to publish_container function"
		return 1
	else
		IMAGE_TAG="${3}"
	fi

	DESTINATION="${REGISTRY_PATH}/${IMAGE_NAME}"

	writeLog "INFO" "Publishing OCI image ${DESTINATION}:${IMAGE_TAG}"

	# Create the provided tag.
	skopeo copy \
		--dest-creds="${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}" \
		"docker-archive:${OCI_ARCHIVE}" \
		"docker://${DESTINATION}:${IMAGE_TAG}" || {
		writeLog "ERROR" "Failed to push OCI image ${IMAGE_NAME}:${IMAGE_TAG} to registry path ${DESTINATION}"
		exit 1
	}

	if [[ ${IMAGE_TAG} != "latest" ]]; then

		writeLog "INFO" "Publishing OCI image ${DESTINATION}:latest"

		# Always push a latest tag.
		skopeo copy \
			--dest-creds="${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}" \
			"docker-archive:${OCI_ARCHIVE}" \
			"docker://${DESTINATION}:latest" || {
			writeLog "ERROR" "Failed to push OCI image ${IMAGE_NAME}:${IMAGE_TAG} to registry path ${DESTINATION}"
			exit 1
		}

	fi

	return 0

}

function prefetch_files_lfs() {

	git lfs pull || {
		writeLog "ERROR" "Failed to pull LFS files"
		exit 1
	}

	git lfs status || {
		writeLog "ERROR" "Failed to check LFS files"
		exit 1
	}

	# Prefetch all the binaries into the Nix store.
	writeLog "INFO" "Prefetching all the binaries into the Nix store"

	FILES=()
	while IFS= read -r -d '' FILE; do

		FILES+=("$FILE")

	done < <(find bin -type f -print0)

	for FILE in "${FILES[@]}"; do

		writeLog "INFO" "Prefetching file into Nix store: ${FILE}"
		nix-prefetch-url "file://${PWD}/${FILE}"

	done

	COUNT="${#FILES[@]}"
	writeLog "INFO" "Prefetched ${COUNT} files into Nix store."

}

#########################
# Export
#########################

# Export common functions
export -f checkBin checkReqs checkPermissions checkLogLevel writeLog checkVarEmpty checkResult

# Export specific functions
export -f build_container publish_container

#########################
# End
#########################

writeLog "INFO" "Sourced and exported functions.sh"
