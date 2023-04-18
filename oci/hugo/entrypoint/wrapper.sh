#!/usr/bin/env bash

set -euo pipefail

#########################
# Variables
#########################

export LOGLEVEL="${LOGLEVEL:=INFO}"
export GIT_REPO="${GIT_REPO:-}"

#########################
# Constants
#########################

export SCRIPT="${0##*/}"
export WORKDIR="/workdir"
export PUBLIC_DIR="/public"
export REQ_BINS=(
	"hugo"
	"git"
)

#########################
# Functions
#########################

function create_workdir() {
	if [[ ! -d ${WORKDIR} ]]; then
		writeLog "INFO" "Creating working directory ${WORKDIR}"
		mkdir --parents "${WORKDIR}" || {
			writeLog "ERROR" "Failed to create working directory ${WORKDIR}"
			return 1
		}
	else
		writeLog "INFO" "Working directory ${WORKDIR} detected"
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
	fi
	return 0
}

function update_or_clone_repo() {
	# If a folder named "src" exists, run git pull to update the repo.
	if [[ -d "${WORKDIR}/src" ]]; then
		writeLog "INFO" "Updating git repository"
		git -C "${WORKDIR}/src" pull || {
			writeLog "ERROR" "Failed to update git repository"
			return 1
		}
	else
		writeLog "INFO" "Cloning git repository"
		git clone "${GIT_REPO}" src || {
			writeLog "ERROR" "Failed to clone git repository"
			return 1
		}
	fi
	return 0
}

function build_site() {
	writeLog "INFO" "Building site"
	_pushd "src"
	hugo --destination "${PUBLIC_DIR}" || {
		writeLog "ERROR" "Failed to build site"
		_popd
		return 1
	}
	_popd
	return 0
}

#########################
# Main
#########################

# Check log level
checkLogLevel "${LOGLEVEL}" || exit 1

# Check required binaries
checkReqs || exit 1

# Create working directory
create_workdir || exit 1

# Create public directory
create_publicdir || exit 1

# Change to the working directory
cd "${WORKDIR}"

# Ensure required environment variables are set
checkVarEmpty "GIT_REPO" "Git repository" && exit 1

# Update or clone the git repository
update_or_clone_repo || exit 1

# Build the site
build_site || exit 1
