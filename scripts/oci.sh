#!/usr/bin/env bash

set -euo pipefail

#########################
# Variables
#########################

export CONTAINER_BUILD="${CONTAINER_BUILD:-FALSE}"
export CONTAINER_PUBLISH="${CONTAINER_PUBLISH:-FALSE}"

# Get a script name for the logs
export SCRIPT=${0##*/}
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
export SCRIPT_DIR

export LOGLEVEL="DEBUG"

#########################
# Declarations
#########################

# All the required external binaries for this script to work.
declare -r REQ_BINS=(
	date
	echo
	git
	gpg
	jq
	skopeo
	tree
)
export REQ_BINS

#########################
# Pre-reqs
#########################

# Import the required functions
# shellcheck source=functions.sh
source "${SCRIPT_DIR}/functions.sh" || {
	echo "Failed to source dependant functions!"
	exit 1
}

checkLogLevel "${LOGLEVEL}" || {
	writeLog "ERROR" "Failed to check the log level"
	exit 1
}

checkReqs || {
	writeLog "ERROR" "Failed to check all requirements"
	exit 1
}

#########################
# Dependencies
#########################

# Make sure the required variables are present.

checkVarEmpty "REGISTRY" "Registry" && exit 1
checkVarEmpty "REGISTRY_NAMESPACE" "Registry Namespace" && exit 1
checkVarEmpty "REGISTRY_USERNAME" "Username" && exit 1
checkVarEmpty "REGISTRY_PASSWORD" "Password" && exit 1
checkVarEmpty "REGISTRY_PATH" "Registry Path" && exit 1
checkVarEmpty "IMAGE_NAME" "Image Name" && exit 1
checkVarEmpty "IMAGE_TAG" "Image Tag" && exit 1
checkVarEmpty "SYSTEM" "Nix system architecture" && exit 1

#########################
# Prepare
#########################

#prefetch_files_lfs || {
#	writeLog "ERROR" "Failed to prefetch files into the Nix store"
#	exit 1
#}

tree || true

#########################
# Build and Push
#########################

# Make sure there is a flake present.
if [[ ! -f "flake.nix" ]]; then
	writeLog "ERROR" "No flake.nix file found. Please make sure you are running this script from the root of the flake."
	exit 1
fi

writeLog "INFO" "Processing system images for ${IMAGE_NAME} ${SYSTEM}"

# Verify there is a package section in the flake matching the image.
PACKAGE_NAME=".\"packages\".\"${SYSTEM}\".\"${IMAGE_NAME}\" | keys[]"

nix flake show --json | jq -r "${PACKAGE_NAME}" || {
	writeLog "ERROR" "No package found for $IMAGE_NAME in $SYSTEM. Have you added it to flake.nix?"
	exit 1
}

if [[ ${CONTAINER_BUILD^^} == "TRUE" ]]; then

	writeLog "INFO" "Building container image ${IMAGE_NAME}"

	build_container "${SYSTEM}" "${IMAGE_NAME}" || {
		echo "Failed to build container image ${IMAGE_NAME}"
		exit 1
	}

	if [[ ${CONTAINER_PUBLISH^^} == "TRUE" ]]; then

		writeLog "INFO" "Publishing container image $IMAGE_NAME"

		publish_container "result" "${IMAGE_NAME}" "${IMAGE_TAG}" || {
			echo "Failed to publish container image ${IMAGE_NAME}:${IMAGE_TAG}"
			exit 1
		}

	else

		writeLog "INFO" "Skipping publishing container $CONTAINER"

	fi

else

	writeLog "INFO" "Skipping building container $CONTAINER"

fi

exit 0
