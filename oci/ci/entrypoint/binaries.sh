#!/bin/bash

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"

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

writeLog "DEBUG" "Sourced required binary functions"

#########################
# EOF
#########################
