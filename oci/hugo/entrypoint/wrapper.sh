#!/usr/bin/env bash

set -euo pipefail

#########################
# Variables
#########################

export LOGLEVEL="${LOGLEVEL:=INFO}"
export GIT_REPO="${GIT_REPO:-}"
export GIT_BRANCH="${GIT_BRANCH:-}"

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

	# If a folder named "src" exists and is a valid git repository, run git pull to update the repo.
	if [[ -d "${WORKDIR}/src" ]] && git -C "${WORKDIR}/src" rev-parse --is-inside-work-tree >/dev/null 2>&1; then

		# Make sure the correct branch is checked out
		if [[ -n ${GIT_BRANCH} ]]; then
			writeLog "INFO" "Checking out branch ${GIT_BRANCH}"
			git -C "${WORKDIR}/src" checkout "${GIT_BRANCH}" || {
				writeLog "ERROR" "Failed to checkout branch ${GIT_BRANCH}"
				return 1
			}
		fi

		# Update the repo
		writeLog "INFO" "Updating git repository"
		git -C "${WORKDIR}/src" pull || {
			writeLog "ERROR" "Failed to update git repository"
			return 1
		}

	else

		# Remove the "src" directory if it's not a valid git repository
		if [[ -d "${WORKDIR}/src" ]]; then
			writeLog "WARNING" "The 'src' directory exists but is not a valid git repository. Removing it."
			rm -rf "${WORKDIR}/src"
		fi

		# Clone the repo
		writeLog "INFO" "Cloning git repository"
		git clone "${GIT_REPO}" src || {
			writeLog "ERROR" "Failed to clone git repository"
			return 1
		}

		# If a branch is specified, check it out
		if [[ -n ${GIT_BRANCH} ]]; then
			writeLog "INFO" "Checking out branch ${GIT_BRANCH}"
			git -C "${WORKDIR}/src" checkout "${GIT_BRANCH}" || {
				writeLog "ERROR" "Failed to checkout branch ${GIT_BRANCH}"
				return 1
			}
		fi

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
checkLogLevel "${LOGLEVEL}" || {
	writeLog "ERROR" "Invalid log level ${LOGLEVEL}"
	exit 1
}

# Check required binaries
checkReqs || {
	writeLog "ERROR" "Missing required binaries"
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

# Change to the working directory
cd "${WORKDIR}" || {
	writeLog "ERROR" "Failed to change to working directory ${WORKDIR}"
	exit 5
}

# Ensure required environment variables are set
checkVarEmpty "GIT_REPO" "Git repository" && exit 6

# Update or clone the git repository
update_or_clone_repo || {
	writeLog "ERROR" "Failed to update or clone git repository"
	exit 7
}

# Build the site
build_site || {
	writeLog "ERROR" "Failed to build site"
	exit 8
}
