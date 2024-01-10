#!/usr/bin/env bash

##################################################
# Name: logging
# Description: Contains the logging related functions
##################################################

function checkLog() {

	# Ensures that the provided log file exists or sets a default.
	# Will create the parent directories if required.

	local FILE="${1}"

	# Set a default log file location if not specified
	if [[ ${FILE:-EMPTY} == "EMPTY" ]]; then
		echo "WARNING: checkLog function was not passed a log location, setting default to be in /tmp"
		FILE="/tmp/${SCRIPT:-unknown}.log"
		export LOG_FILE=${FILE}
	fi

	# Does the parent directory for the log file exist?
	PARENT=$(dirname "${FILE}")
	if [[ ! -d ${PARENT} ]]; then

		if [[ ${LOG_LEVEL} == "DEBUG" ]]; then
			echo "DEBUG: Creating new log file parent directory ${PARENT}"
		fi

		mkdir -p "${PARENT}"
		checkResult $? || {
			echo "ERROR: Failed to create log directory"
			return 1
		}

	fi

	if [[ ! -f ${FILE} ]]; then

		touch "${FILE}" || {
			echo "ERROR: Failed to create logfile ${FILE}"
			return 1
		}

	fi

	return 0

}

function checkLogLevel() {

	# The global log level LOG_LEVEL should be defined in bashrc or will default to INFO.
	# This function ensures that the global log level is using a supported name.

	# Only the following log levels are supported.
	#   DEBUG
	#   INFO or INFORMATION
	#   WARN or WARNING
	#   ERR or ERROR

	# Global log level
	export LOG_LEVEL="${LOG_LEVEL:=INFO}"

	# Local log level
	local LEVEL="${1}"

	# POSIX be gone!
	# LEVEL="$( echo "${1}" | tr '[:lower:]' '[:upper:]' )"
	case "${LEVEL^^}" in

	"DEBUG" | "TRACE")
		LOG_LEVEL="DEBUG"
		;;

	"INFO" | "INFORMATION")
		LOG_LEVEL="INFO"
		;;

	"WARN" | "WARNING")
		LOG_LEVEL="WARN"
		;;

	"ERR" | "ERROR")
		LOG_LEVEL="ERR"
		;;

	*)
		LOG_LEVEL="INFO"
		;;

	esac

	# Re-export the LOG_LEVEL using a supported name.
	export LOG_LEVEL

	return 0

}

function writeLog() {

	local LEVEL=$1    # The log level; DEBUG,INFO,WARN,ERROR
	local MESSAGE=$2  # The log message
	local DESTINATION # The log destination; stdout, file, all
	local APPEND      # Boolean whether to append existing log file.

	###############
	# Checks
	###############

	# The log level should be previously defined or defaults to INFO
	checkLogLevel "${LOG_LEVEL}" || {
		echo "Failed to check the global log level!"
		return 1
	}

	# The level provided cannot be empty.
	if [[ ${LEVEL:-EMPTY} == "EMPTY" ]]; then
		echo "Please provide a Log Level as parameter #1"
		return 1
	else
		#LEVEL=$(echo "${LEVEL}" | tr '[:lower:]' '[:upper:]')
		LEVEL="${LEVEL^^}"
	fi

	# The message provided cannot be empty.
	if [[ ${MESSAGE:-EMPTY} == "EMPTY" ]]; then
		echo "Please provide a Log Message as parameter #2"
		return 1
	fi

	###############
	# Level
	###############

	case "${LEVEL}" in

	"START" | "FRESH" | "NEW" | "CREATE")

		LEVEL="INFO"
		APPEND="FALSE"

		;;

	"DEBUG" | "TRACE")

		LEVEL="DEBUG"
		APPEND="TRUE"

		# Do not show debug messages if the level is > debug
		if [[ ${LEVEL} != "${LOG_LEVEL}" ]]; then
			return 0
		fi

		;;

	"INFO" | "INFORMATION")

		LEVEL="INFO"
		APPEND="TRUE"

		# Do not show info messages if the level is > info
		if [[ ${LOG_LEVEL} == "WARN" ]] || [[ ${LOG_LEVEL} == "ERR" ]]; then
			return 0
		fi

		;;

	"WARN" | "WARNING")

		LEVEL="WARN"
		APPEND="TRUE"

		# Do not show warning messages if the level is error.
		if [[ ${LOG_LEVEL} == "ERR" ]]; then
			return 0
		fi

		;;

	"ERR" | "ERROR")

		LEVEL="ERR"
		APPEND="TRUE"

		# Errors are always shown

		;;

	*)

		LEVEL="ERR"
		APPEND="TRUE"

		# Show a message to the user.
		MESSAGE="Unknown log level $LEVEL provided to log function. Valid level options are DEBUG, INFO, WARN, ERR, START"

		;;

	esac

	###############
	# Destination
	###############

	# Where are we sending logs?
	# Defaults to stdout unless globally defined
	#   stdout = stdout only
	#   file = file only
	#   all = both stdout and file
	DESTINATION="${LOG_DESTINATION:=stdout}"
	# macos bash v3 friendly.
	#DESTINATION=$(echo "${DESTINATION}" | tr '[:lower:]' '[:upper:]')

	case "${DESTINATION^^}" in

	"STDOUT")

		echo -e "$(date +"%Y/%m/%d %H:%M:%S") [$LEVEL] $MESSAGE"

		;;

	"FILE")

		checkLog "${LOG_FILE}" || {
			echo "Failed to check the log file at ${LOG_FILE}"
			return 1
		}

		if [[ ${APPEND:-TRUE} == "TRUE" ]]; then
			echo -e "$(date +"%Y/%m/%d %H:%M:%S") [$LEVEL] $MESSAGE" >>"${LOG_FILE}"
		else
			echo -e "$(date +"%Y/%m/%d %H:%M:%S") [$LEVEL] $MESSAGE" >"${LOG_FILE}"
		fi

		;;

	"ALL" | "BOTH")

		checkLog "${LOG_FILE}" || {
			echo "Failed to check the log file at ${LOG_FILE}"
			return 1
		}

		if [[ ${APPEND:-TRUE} == "TRUE" ]]; then
			echo -e "$(date +"%Y/%m/%d %H:%M:%S") [$LEVEL] $MESSAGE" | tee -a "${LOG_FILE}"
		else
			echo -e "$(date +"%Y/%m/%d %H:%M:%S") [$LEVEL] $MESSAGE" | tee "${LOG_FILE}"
		fi

		;;

	*)

		echo "Unknown Logging destination ${DESTINATION:-EMPTY}, defaulting to stdout"
		echo -e "$(date +"%Y/%m/%d %H:%M:%S") [$LEVEL] $MESSAGE"

		;;

	esac

	return 0

}

function showHeader() {

	local MESSAGE="${1}"

	echo -e "\n"
	echo -e "#########################"
	echo -e "${MESSAGE:-EMPTY}"
	echo -e "#########################"
	echo -e "\n"

	return 0

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

function checkVarEmpty() {

	# Returns true if the variable is empty

	# NOTE:
	#	Pass this function the string NAME of the variable
	#	Not the expanded contents of the variable itself.

	local VAR_NAME="${1}"
	local VAR_DESC="${2}"

	if [[ ${!VAR_NAME:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "The variable ${VAR_NAME} with description ${VAR_DESC} is empty."
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

function show_logs() {

	# If logs are being written, show them
	if [[ ${LOG_DESTINATION:-EMPTY} == "file" ]] || [[ ${LOG_DESTINATION:-EMPTY} == "all" ]]; then

		if [[ -f ${LOG_FILE} ]]; then

			echo -e "Tanzu Tools has exited with an error. Displaying a copy of the session log."

			echo -e "\nSTART: Show session logs...\n"

			cat "${LOG_FILE}"

			echo -e "\nEND: Show session logs...\n"

		fi

	fi

	return 0

}

function exit_script() {

	EXIT_CODE="$1"

	# Edge case, you forget to pass the exit code, assume error.
	if [[ ${EXIT_CODE:-EMPTY} == "EMPTY" ]]; then
		EXIT_CODE=99
	fi

	tput clear

	# If there was an error, show the session logs for debugging.
	if [[ ${EXIT_CODE:-0} -ne 0 ]]; then
		show_logs || true
	fi

	exit "${EXIT_CODE}"

}

export -f checkLog checkLogLevel writeLog
export -f checkBin checkVarEmpty checkResult
export -f show_logs exit_script
