#!/usr/bin/env bash

set -eu

#########################
# Functions (common)
#########################

function _pushd() {

	local DIR="${1}"

	pushd "${DIR}" 1>/dev/null || {
		writeLog "ERROR" "Failed to push directory to ${DIR}"
		return 1
	}

}

function _popd() {

	popd 1>/dev/null || {
		writeLog "ERROR" "Failed to pop directory back"
		return 1
	}

}

function usage() {

	local MESSAGE="${1:-}"

	cat <<-EOF

		${MESSAGE:-Usage information for $SCRIPT}

		usage: ${0##*/} <binary_name> <binary_args>

		The following binaries are currently enabled:

		$(for BIN in "${ENABLED_BINARIES[@]}"; do printf "    - %s\n" "${BIN}"; done)

		Each binary has a global disable flag if required to disable/skip a step.

		    \$DISABLE_<binary_name>="TRUE"

		    DISABLE_TRIVY="TRUE"

		Each binary also has specific usage information available by running:

		    <binary_name> --help


	EOF

}

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
	export LOGLEVEL="${LOGLEVEL:=INFO}"

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

	local LEVEL="${1}"
	local MESSAGE="${2}"

	export LOGLEVEL="${LOGLEVEL:=INFO}"

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

	# NOTICE:
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

function gitConfig() {

	# Configure a basic user so git will work without complaints
	local GIT_VERSION

	# The current git version has proved useful to have in the logs.
	GIT_VERSION=$(git --version)
	writeLog "INFO" "Configuring ${GIT_VERSION}"

	git config --global user.email "${GIT_ACTOR:-user}@users.noreply.github.com" || {
		writeLog "ERROR" "Failed to configure the git user email"
		return 1
	}

	git config --global user.name "GitHub Actions" || {
		writeLog "ERROR" "Failed to configure the git user name"
		return 1
	}

	return 0

}

function gitFetchAll() {

	# Fetch all the Git tags

	writeLog "INFO" "Fetching all Git tags"

	git fetch --prune --tags --prune-tags --all || {
		writeLog "ERROR" "Failed to fetch git tags"
		return 1
	}

	return 0

}

writeLog "DEBUG" "Sourced required common functions"

#########################
# EOF
#########################
