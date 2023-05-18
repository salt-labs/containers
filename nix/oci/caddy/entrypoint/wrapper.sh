#!/usr/bin/env bash

set -euo pipefail

#########################
# Variables
#########################

export LOGLEVEL="${LOGLEVEL:=INFO}"
export GIT_REPO="${GIT_REPO:-}"
export CADDY_CONFIG="${CADDY_CONFIG:-/etc/caddy/Caddyfile}"
export CADDY_RELOAD="FALSE"

#########################
# Constants
#########################

export SCRIPT="${0##*/}"
export LAST_UPDATE=0
export WORKDIR="/workdir"
export PUBLIC_DIR="/public"
export RESTART_TRIGGER="${WORKDIR}/restart-trigger"
export REQ_BINS=(
	"caddy"
)

#########################
# Functions
#########################

function create_workdir() {
	if [ ! -d "${WORKDIR}" ]; then
		writeLog "INFO" "Creating working directory ${WORKDIR}"
		mkdir -p "${WORKDIR}" || {
			writeLog "ERROR" "Failed to create working directory ${WORKDIR}"
			return 1
		}
	else
		writeLog "INFO" "Working directory ${WORKDIR} already exists"
	fi
	return 0
}

function create_publicdir() {
	if [ ! -d "${PUBLIC_DIR}" ]; then
		writeLog "INFO" "Creating public directory ${PUBLIC_DIR}"
		mkdir -p "${PUBLIC_DIR}" || {
			writeLog "ERROR" "Failed to create public directory ${PUBLIC_DIR}"
			return 1
		}
	else
		writeLog "INFO" "Public directory ${PUBLIC_DIR} already exists"
	fi
	return 0
}

function check_caddy_config() {
	if [ ! -f "${CADDY_CONFIG}" ]; then
		writeLog "ERROR" "Caddy config file ${CADDY_CONFIG} does not exist"
		return 1
	else
		writeLog "INFO" "Caddy config file ${CADDY_CONFIG} exists"
	fi
	return 0
}

function create_trigger() {

	# If there is no restart trigger, create an empty file.
	if [[ ! -f ${RESTART_TRIGGER} ]]; then
		writeLog "INFO" "Creating restart trigger file ${RESTART_TRIGGER}"
		touch "${RESTART_TRIGGER}" || {
			writeLog "ERROR" "Failed to create restart trigger file ${RESTART_TRIGGER}"
			exit 1
		}
	else
		writeLog "INFO" "Restart trigger file ${RESTART_TRIGGER} already exists"
	fi
	return 0

}

function wait_for_index() {

	local READY="FALSE"

	while [[ ${READY} != "TRUE" ]]; do

		if [[ -f "${PUBLIC_DIR}/index.html" ]]; then
			writeLog "INFO" "Public directory ${PUBLIC_DIR} is ready to be served"
			READY="TRUE"
		else
			writeLog "INFO" "Waiting for public directory ${PUBLIC_DIR} to contain index.html"
			sleep 60
		fi

	done

	return 0

}

function serve_with_caddy() {

	writeLog "INFO" "Validating Caddy config file ${CADDY_CONFIG}"

	caddy validate --config "${CADDY_CONFIG}" || {
		writeLog "ERROR" "Failed to validate Caddy config file ${CADDY_CONFIG}"
		return 1
	}

	writeLog "INFO" "Starting Caddy server with config: ${CADDY_CONFIG}"

	caddy start --config "${CADDY_CONFIG}" || {
		writeLog "ERROR" "Failed to start Caddy server with config ${CADDY_CONFIG}"
		return 1
	}

	return 0

}

function check_restart_trigger() {

	local NOW
	local LAST_COMMIT
	local PREV_COMMIT

	writeLog "INFO" "Checking for updates to restart trigger ${RESTART_TRIGGER}"

	NOW=$(date +%s)
	LAST_COMMIT=$(git -C "${WORKDIR}/src" rev-parse HEAD)
	PREV_COMMIT=$(cat "${RESTART_TRIGGER}")

	writeLog "INFO" "Last commit: ${LAST_COMMIT:-EMPTY}, Previous commit: ${PREV_COMMIT:-EMPTY}"

	if [ "${LAST_COMMIT:-EMPTY_1}" != "${PREV_COMMIT:-EMPTY_2}" ]; then

		echo "${LAST_COMMIT}" >"${RESTART_TRIGGER}"
		export CADDY_RELOAD="TRUE"

		writeLog "INFO" "A git commit update was detected."

	else

		writeLog "INFO" "No git commit update detected."

	fi

	LAST_UPDATE="${NOW}"
	return 0

}

function cleanup() {

	writeLog "WARN" "Caught Trap signal, attempting to gracefully shutting down Caddy..."

	caddy stop || {
		writeLog "ERROR" "Failed to stop Caddy process ${CADDY_PID}"
		exit 1
	}

	writeLog "INFO" "Caddy has stopped, exiting."

	exit 0

}

#########################
# Main
#########################

# Setup a trap.
trap cleanup SIGTERM

# Check log level
checkLogLevel "${LOGLEVEL}" || {
	writeLog "ERROR" "Invalid log level: ${LOGLEVEL}"
	exit 1
}

# Check required binaries
checkReqs || {
	writeLog "ERROR" "Failed to find required binaries"
	exit 2
}

# Create working directory
create_workdir || {
	writeLog "ERROR" "Failed to create working directory"
	exit 3
}

# Create public directory
create_publicdir || {
	writeLog "ERROR" "Failed to create public directory"
	exit 4
}

# Check Caddy config file
check_caddy_config || {
	writeLog "ERROR" "Failed to find Caddy config file"
	exit 5
}

# Change to the working directory
cd "${WORKDIR}" || {
	writeLog "ERROR" "Failed to change to working directory ${WORKDIR}"
	exit 6
}

create_trigger || {
	writeLog "ERROR" "Failed to create restart trigger"
	exit 7
}

# Ensure required environment variables are set
checkVarEmpty "GIT_REPO" "Git repository" && exit 8

# Wait for Public directory to be ready
wait_for_index || {
	writeLog "ERROR" "Failed to wait for public directory"
	exit 9
}

# Serve files with Caddy in the background
serve_with_caddy || {
	writeLog "ERROR" "Failed to serve files with Caddy"
	exit 10
}

# Loop to check for restart trigger updates
while true; do

	check_restart_trigger || {
		writeLog "WARN" "Failed to check the restart trigger, retrying in 60 seconds"
	}

	if [[ ${CADDY_RELOAD} == "TRUE" ]]; then
		writeLog "INFO" "A Caddy reload has been triggered"
		caddy reload --config "${CADDY_CONFIG}" || {
			writeLog "ERROR" "Failed to reload Caddy server with config ${CADDY_CONFIG}"
			exit 1
		}
	fi

	sleep 60

done
