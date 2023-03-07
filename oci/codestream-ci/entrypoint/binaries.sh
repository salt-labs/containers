#!/usr/bin/env bash

set -eu

#########################
# Variables
#########################

#########################
# Functions (binary specific)
#########################

function run_git_clone() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_GIT_CLONE:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		cat <<-EOF

			The following environment variables are required:

			- CI_GIT_REPO
			- CI_GIT_BRANCH
			- CI_GIT_SRC

			The following environment variables are optional:

			- CI_GIT_BRANCH     (default: main)
			- CI_GIT_USER
			- CI_GIT_TOKEN
			- CI_GIT_SSH_KEY

		EOF

		git --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			return 1
		}

		return 0

		;;

	esac

	# START

	checkVarEmpty "CI_GIT_REPO" "URL to git source" && return 1
	checkVarEmpty "CI_GIT_BRANCH" "Git branch to clone" && return 1
	checkVarEmpty "CI_GIT_SRC" "Source code directory" && return 1

	if [[ -d ${CI_GIT_SRC} ]]; then
		writeLog "WARN" "Source directory already exists, cleaning..."
		rm -rf "${CI_GIT_SRC}"
	fi

	if [[ ${CI_GIT_USER:-EMPTY} != "EMPTY" ]] && [[ ${CI_GIT_TOKEN:-EMPTY} != "EMPTY" ]]; then
		# If CI_GIT_USER and CI_GIT_TOKEN are set, use them to authenticate

		writeLog "DEBUG" "Using CI_GIT_USER and CI_GIT_TOKEN to authenticate"

		# Split the CI_GIT_REPO into the protocol and the rest
		local CI_GIT_PROTOCOL="${CI_GIT_REPO%%://*}"
		local CI_GIT_PATH="${CI_GIT_REPO#*://}"

		git clone \
			--branch "${CI_GIT_BRANCH}" \
			"${CI_GIT_PROTOCOL}://${CI_GIT_USER}:${CI_GIT_TOKEN}@${CI_GIT_PATH}" \
			"${CI_GIT_SRC}" || {
			writeLog "ERROR" "Failed to clone git repository!"
			return 1
		}

	elif [[ -n ${CI_GIT_SSH_KEY:-} ]]; then
		# If CI_GIT_SSH_KEY is set, use it to authenticate

		writeLog "DEBUG" "Using CI_GIT_SSH_KEY to authenticate"

		# Create SSH key
		mkdir --parents "${CI_BIN_HOME}/.ssh"
		echo "${CI_GIT_SSH_KEY}" >"${CI_BIN_HOME}/.ssh/id_rsa"
		chmod 600 "${CI_BIN_HOME}/.ssh/id_rsa"

		# Create SSH config
		cat <<-EOF >"${CI_BIN_HOME}/.ssh/config"
			Host *
				StrictHostKeyChecking no
				UserKnownHostsFile=/dev/null
		EOF

		# Clone git repository
		git clone \
			--branch "${CI_GIT_BRANCH}" \
			"git@${CI_GIT_REPO}" \
			"${CI_GIT_SRC}" || {
			writeLog "ERROR" "Failed to clone git repository!"
			return 1
		}

	else
		# Otherwise, use no authentication

		writeLog "DEBUG" "Using no authentication for git clone"

		git clone \
			--branch "${CI_GIT_BRANCH}" \
			"${CI_GIT_REPO}" \
			"${CI_GIT_SRC}" || {
			writeLog "ERROR" "Failed to clone git repository!"
			return 1
		}

	fi

	return 0

}

function run_brakeman() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_BRAKEMAN:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		cat <<-EOF

			The following environment variables are required:

			- CI_GIT_SRC

			The following environment variables are optional:

			- TODO

		EOF

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			return 1
		}

		return 0

		;;

	esac

	# START

	checkVarEmpty "CI_GIT_SRC" "Source code directory" && return 1

	# Look for all Ruby source files
	local FIND_LINES
	FIND_LINES=$(
		find "${CI_GIT_SRC}" \
			\( -name '*.rb' -o -name 'Gemfile' \) \
			! \( -name '.nope' \) \
			-print \
			-quit 2>/dev/null |
			wc -l 2>/dev/null
	)
	if [[ ! ${FIND_LINES} -gt 0 ]]; then

		writeLog "WARN" "No Ruby source files found, skipping brakeman run..."
		return 0

	fi

	writeLog "INFO" "Running brakeman..."

	brakeman \
		"${BIN_ARGS[@]:-}" \
		--color \
		--run-all-checks \
		--output "${CI_BIN_HOME}/brakeman.json" \
		--output "${CI_BIN_HOME}/brakeman.html" \
		--output "${CI_BIN_HOME}/brakeman.md" \
		--force \
		--path "${CI_GIT_SRC}"

	# NOTE: This is where you would upload results...

	return 0

}

function run_buildah() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_BUILDAH:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		cat <<-EOF

			The following environment variables are required:

			- CI_GIT_SRC
			- CI_IMAGE_REGISTRY
			- CI_IMAGE_NAME

			The following environment variables are optional:

			- CI_IMAGE_TAG  (default: latest)

		EOF

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			return 1
		}

		return 0

		;;

	esac

	# START

	checkVarEmpty "CI_GIT_SRC" "Source code directory" && return 1
	checkVarEmpty "CI_IMAGE_REGISTRY" "Image registry" && return 1
	checkVarEmpty "CI_IMAGE_NAME" "Image name" && return 1

	_pushd "${CI_GIT_SRC}"

	buildah images || {
		writeLog "ERROR" "Failed to list existing images!"
		return 1
	}

	writeLog "WARN" "TODO: Build image using buildah here..."

	buildah images || {
		writeLog "ERROR" "Failed to list existing images!"
		return 1
	}

	_popd

	return 0

}

function run_clair() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_cosign() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_flawfinder() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_FLAWFINDER:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		cat <<-EOF

			The following environment variables are required:

			- CI_GIT_SRC

			The following environment variables are optional:

			- CI_SAST_SARIF_FILE                (default: flawfinder.sarif)
			- CI_SAST_SARIF_URL               (default: none)

		EOF

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			return 1
		}

		return 0

		;;

	esac

	# START

	checkVarEmpty "CI_GIT_SRC" "Source code directory" && return 1

	# Look for all C/C++ source files
	local FIND_LINES
	FIND_LINES=$(
		find "${CI_GIT_SRC}" \
			\( -name '*.c' -o -name '*.c++' -o -name '*.cc' -o -name '*.cp' -o -name '*.cpp' -o -name '*.cxx' \) \
			! \( -name '.nope' \) \
			-print \
			-quit 2>/dev/null |
			wc -l 2>/dev/null
	)
	if [[ ! ${FIND_LINES} -gt 0 ]]; then

		writeLog "WARN" "No C/C++ source files found, skipping flawfinder run..."
		return 0

	fi

	writeLog "INFO" "Running flawfinder..."

	flawfinder "${CI_GIT_SRC}" "${BIN_ARGS[@]:-}"

	flawfinder --sarif "${CI_GIT_SRC}" >"${CI_BIN_HOME}/${CI_SAST_SARIF_FILE:=flawfinder.sarif}" || {
		writeLog "ERROR" "Failed to geherate sarif report for flawfinder."
		return 1
	}

	# NOTE: This is where you would upload results...

	return 0

}

function run_gitleaks() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_gosec() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_govc() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_grype() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_hadolint() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_helm() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_kaniko() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_KANIKO:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	case "${BIN_ARGS[0]:-EMPTY}" in

	"--help" | "--usage")

		cat <<-EOF

			The following environment variables are required:

			- CI_GIT_SRC
			- CI_REGISTRY
			- CI_REGISTRY_USERNAME
			- CI_REGISTRY_PASSWORD
			- CI_IMAGE_NAME

			The following environment variables are optional:

			- CI_IMAGE_TAG                (default: latest)
			- CI_IMAGE_PLATFORM         (default: linux/amd64)
			- CI_IMAGE_DOCKERFILE      (default: Dockerfile)

		EOF

		"${BIN_NAME}" --help || {
			writeLog "ERROR" "Failed to run ${BIN_NAME} ${BIN_ARGS[*]:-none}"
			return 1
		}

		return 0

		;;

	esac

	# START

	checkVarEmpty "CI_GIT_SRC" "Source code directory" && return 1
	checkVarEmpty "CI_REGISTRY" "Image registry" && return 1
	checkVarEmpty "CI_REGISTRY_USERNAME" "Image registry username" && return 1
	checkVarEmpty "CI_REGISTRY_PASSWORD" "Image registry password" && return 1
	checkVarEmpty "CI_IMAGE_NAME" "Image name" && return 1

	writeLog "INFO" "Writing registry credentials to /kaniko/.docker/config.json"

	cat <<-EOF >/kaniko/.docker/config.json
		{
		  "auths": {
		    "${CI_REGISTRY}": {
		      "auth": "$(printf "%s:%s" "${CI_REGISTRY_USERNAME}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')"
		    }
		  }
		}
	EOF
	cat /kaniko/.docker/config.json

	writeLog "INFO" "Building image ${CI_REGISTRY}/${CI_IMAGE_NAME}:${CI_IMAGE_TAG:-latest}"

	executor \
		--context "${CI_GIT_SRC}" \
		--dockerfile "${CI_IMAGE_DOCKERFILE:-Dockerfile}" \
		--destination "${CI_REGISTRY}/${CI_IMAGE_NAME}:${CI_IMAGE_TAG:-latest}" \
		--platform "${CI_IMAGE_PLATFORM:-linux/amd64}" \
		--reproducible \
		--verbosity debug

	return 0

}

function run_kics() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_kube-linter() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_kubectl() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_kubesec() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_license_finder() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_packer() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_secretscanner() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_shellcheck() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_skopeo() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_synk() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_tflint() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_tfsec() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

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
			return 1
		}

		return 0

		;;

	esac

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

function run_trivy() {

	local BIN_NAME="${FUNCNAME[0]#run_}"
	local BIN_ARGS=("${@}")

	local TRIVY_OUTPUT
	local TRIVY_IMAGE_NAME
	local -A TRIVY_IMAGE_VULNS

	local CI_BIN_HOME="${CI_HOME}/${BIN_NAME}"
	mkdir --parents "${CI_BIN_HOME}"

	writeLog "DEBUG" "Entering ${FUNCNAME[0]}"
	writeLog "DEBUG" "${BIN_NAME} home set to ${CI_BIN_HOME}"

	if [[ ${DISABLE_TRIVY:-FALSE} == "TRUE" ]]; then
		writeLog "WARN" "${BIN_NAME} is disabled, skipping..."
		return 0
	fi

	# Mandatory environment variables
	checkVarEmpty "CI_REGISTRY" "Registry" && return 1
	checkVarEmpty "CI_IMAGE_NAME" "Image Name" && return 1
	checkVarEmpty "CI_IMAGE_TAG" "Image Tag" && return 1

	mkdir --parents "${TRIVY_HOME}" || {
		writeLog "ERROR" "Unable to continue, failed to create ${TRIVY_HOME}"
		return 1
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
			return 1
		}

		return 0

		;;

	esac

	TRIVY_IMAGE_NAME="${CI_REGISTRY}/${CI_IMAGE_NAME}:${CI_IMAGE_TAG}"

	"${BIN_NAME}" "${BIN_ARGS[@]:-}" image ${TRIVY_IMAGE_NAME} -- || {
		writeLog "ERROR" "Failed to run ${BIN_NAME}."
		return 1
	}

}

writeLog "DEBUG" "Sourced required binary functions"

#########################
# EOF
#########################