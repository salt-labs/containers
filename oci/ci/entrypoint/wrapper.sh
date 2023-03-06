#!/bin/bash

set -eu

#########################
# Variables
#########################

declare -A COMMANDS

export SCRIPT="${0##*/}"
export LOGLEVEL="${LOGLEVEL:=DEBUG}"

COMMANDS=(
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
