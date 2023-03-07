#!/usr/bin/env bash

set -eu

#########################
# Variables (Codestream)
#########################

# These are expected to be injected by the Codestream CI environment.
WORKING_DIR="${WORKDIR:=workdir}"

# Injected when "auto inject parameters 'git' is enabled."
#GIT_SERVER_URL="${GIT_SERVER_URL:?GIT_SERVER_URL is required}"
#GIT_REPO_NAME="${GIT_REPO_NAME:?GIT_REPO_NAME is required}"
#GIT_BRANCH_NAME="${GIT_BRANCH_NAME:?GIT_BRANCH_NAME is required}"
#GIT_COMMIT_ID="${GIT_COMMIT_ID:?GIT_COMMIT_ID is required}"

#########################
# Variables (Common)
#########################

declare -A COMMANDS

export SCRIPT="${0##*/}"
export LOGLEVEL="${CI_LOG_LEVEL:=INFO}"

# The CI home is the working directory of the container.
# Relative to this location location, all logs, outputs and reports are written.
export CI_HOME="${PWD}/ci"

COMMANDS=(
	["git_clone"]="run_git_clone"
	["brakeman"]="run_brakeman"
	["buildah"]="run_buildah"
	["clair"]="run_clair"
	["cosign"]="run_cosign"
	["flawfinder"]="run_flawfinder"
	["gitleaks"]="run_gitleaks"
	["gosec"]="run_gosec"
	["govc"]="run_govc"
	["grype"]="run_grype"
	["hadolint"]="run_hadolint"
	["helm"]="run_helm"
	["kics"]="run_kics"
	["kube-linter"]="run_kube-linter"
	["kubectl"]="run_kubectl"
	["kubesec"]="run_kubesec"
	["license_finder"]="run_license_finder"
	["packer"]="run_packer"
	["secretscanner"]="run_secretscanner"
	["shellcheck"]="run_shellcheck"
	["skopeo"]="run_skopeo"
	["synk"]="run_synk"
	["tflint"]="run_tflint"
	["tfsec"]="run_tfsec"
	["trivy"]="run_trivy"
)

#########################
# Pre-flight checks
#########################

if [[ $# -eq 0 ]]; then

	usage 'ERROR: Please supply an enabled binary as $1'
	exit 1

else

	BIN="${1:-}"
	shift
	BIN_ARGS=("${@}")

fi

if [[ ! ${COMMANDS[${BIN}]+x} ]]; then

	usage "ERROR: The provided binary ${BIN} is not enabled."
	exit 2

else

	writeLog "INFO" "Running ${BIN} with args ${BIN_ARGS[*]:-none}"

	"run_${BIN}" "${BIN_ARGS[@]}" || {
		writeLog "ERROR" "Failed to run ${BIN} with args ${BIN_ARGS[*]:-none}"
		exit 3
	}

fi

writeLog "DEBUG" "Finished running ${BIN} with args ${BIN_ARGS[*]:-none}"

exit 0

#########################
# EOF
#########################
