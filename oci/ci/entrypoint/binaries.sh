#!/usr/bin/env bash

set -eu

#########################
# Variables
#########################

#########################
# Functions (binary specific)
#########################

function run_brakeman() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_BRAKEMAN:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_buildah() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_BUILDAH:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		cat <<-EOF
			Buildah requires the following environment variables to be set.

			- \$X
			- \$Y   
			- \$Z

		EOF

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_clair() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_CLAIR:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_cosign() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_COSIGN:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_flawfinder() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_FLAWFINDER:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_gitleaks() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_GITLEAKS:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_gosec() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_GOSEC:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_govc() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_GOVC:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_grype() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_GRYPE:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_hadolint() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_HADOLINT:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_helm() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_HELM:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_kics() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_KICS:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_kube-linter() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_KUBE_LINTER:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_kubectl() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_KUBECTL:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_kubesec() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_KUBESEC:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_license_finder() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_LICENSE_FINDER:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_packer() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_PACKER:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_secretscanner() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_SECRETSCANNER:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_shellcheck() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_SHELLCHECK:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_skopeo() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_SKOPEO:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_synk() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_SYNK:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_tflint() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_TFLINT:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_tfsec() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_TFSEC:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

function run_trivy() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local TRIVY_OUTPUT
	local TRIVY_IMAGE_NAME
	local -A TRIVY_IMAGE_VULNS

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_TRIVY:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	# Mandatory environment variables
	checkVarEmpty "CI_REGISTRY" "Registry" && exit 1
	checkVarEmpty "CI_IMAGE_NAME" "Image Name" && exit 1
	checkVarEmpty "CI_IMAGE_TAG" "Image Tag" && exit 1

	mkdir --parents "${TRIVY_HOME}" || {
		writeLog "ERROR" "Unable to continue, failed to create ${TRIVY_HOME}"
		exit 1
	}

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		cat <<-EOF
			This Trivy wrapper script is designed to be used with vRealize Codestream.

			Trivy is run within a container with no access to a local Docker socket.

			Therefore, a container image is expected to be available locally or Trivy is to be run in client mode.

			The following environment variables are required to be set:

			- \$CI_REGISTRY_USERNAME
			- \$CI_REGISTRY_PASSWORD
			- \$CI_REGISTRY
			- \$CI_IMAGE_NAME
			- \$CI_IMAGE_TAG

			The following environment variables are optional:

			- \$TRIVY_REPORT_THRESHOLD

			For example; they might be set to the following:

			- CI_REGISTRY_USERNAME=registry-bot
			- CI_REGISTRY_PASSWORD=supersecret
			- CI_REGISTRY=registry.example.com/library
			- CI_IMAGE_NAME=example/image
			- CI_IMAGE_TAG=latest

			- TRIVY_REPORT_THRESHOLD=high

			Additional arguments and overrides can be passed as shown below.

		EOF

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			exit 1
		}

		exit 0

		;;

	esac

	TRIVY_IMAGE_NAME="${CI_REGISTRY}/${CI_IMAGE_NAME}:${CI_IMAGE_TAG}"

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" image ${TRIVY_IMAGE_NAME} -- || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		exit 1
	}

}

writeLog "DEBUG" "Sourced required binary functions"

#########################
# EOF
#########################
