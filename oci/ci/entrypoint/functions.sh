#!/usr/bin/env bash

set -eu

#########################
# Variables
#########################

#########################
# Functions (common)
#########################

function _pushd() {

	local DIR="${1}"

	pushd "${DIR}" 1>/dev/null || {
		writeLog "ERROR" "Failed to push directory to ${DIR}"
		return 1
	}

}

function _popd() {

	popd 1>/dev/null || {
		writeLog "ERROR" "Failed to pop directory back"
		return 1
	}

}

function usage() {

	local MESSAGE="${1:-}"

	clear || true

	cat <<-EOF
		${MESSAGE:-Usage information for $SCRIPT}

		usage: ${0##*/} <binary_name> <binary_args>

		The following binaries are currently enabled:

		$(for BIN in "${ENABLED_BINARIES[@]}"; do printf "    - %s\n" "${BIN}"; done)

		Each binary has a global disable flag if required to disable/skip a step.

		    \$DISABLE_<binary_name>="TRUE"

		    DISABLE_TRIVY="TRUE"

		Each binary also has specific usage information available by running:

		    <binary_name> --help

	EOF

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

function checkReqs() {

	# Make sure all the required binaries are available within the path
	for BIN in "${REQ_BINS[@]}"; do
		writeLog "DEBUG" "Checking for dependant binary ${BIN}"
		checkBin "${BIN}" || {
			writeLog "ERROR" "Please install the ${BIN} binary on this system in order to run ${SCRIPT}"
			return 1
		}
	done

	return 0

}

function checkPermissions() {

	# Checks if the user is running as root

	if [ "${EUID}" -ne 0 ]; then
		return 1
	else
		return 0
	fi

}

function checkLogLevel() {

	# Only the following log levels are supported.
	#   DEBUG
	#   INFO or INFORMATION
	#   WARN or WARNING
	#   ERR or ERROR

	local LEVEL="${1}"
	export LOGLEVEL="${LOGLEVEL:=INFO}"

	# POSIX be gone!
	# LOGLEVEL="$( echo "${1}" | tr '[:lower:]' '[:upper:]' )"
	case "${LEVEL^^}" in

	"DEBUG" | "TRACE")

		export LOGLEVEL="DEBUG"

		;;

	"INFO" | "INFORMATION")

		export LOGLEVEL="INFO"

		;;

	"WARN" | "WARNING")

		export LOGLEVEL="WARN"

		;;

	"ERR" | "ERROR")

		export LOGLEVEL="ERR"

		;;

	*)

		writeLog "INFO" "An unknown log level of ${LEVEL^^} was provided, defaulting to INFO"
		export LOGLEVEL="INFO"

		;;

	esac

	return 0

}

function writeLog() {

	local LEVEL="${1}"
	local MESSAGE="${2}"

	export LOGLEVEL="${LOGLEVEL:=INFO}"

	case "${LEVEL^^}" in

	"DEBUG" | "TRACE")

		LEVEL="DEBUG"

		# Do not show debug messages if the level is > debug
		if [ ! "${LEVEL^^}" = "${LOGLEVEL^^}" ]; then
			return 0
		fi

		;;

	"INFO" | "INFORMATION")

		LEVEL="INFO"

		# Do not show info messages if the level is > info
		if [ "${LOGLEVEL^^}" = "WARN" ] || [ "${LOGLEVEL^^}" = "ERR" ]; then
			return 0
		fi

		;;

	"WARN" | "WARNING")

		LEVEL="WARN"

		# Do not show warn messages if the level is > warn
		if [ "${LOGLEVEL^^}" = "ERR" ]; then
			return 0
		fi

		;;

	"ERR" | "ERROR")

		LEVEL="ERR"

		# Errors are always shown

		;;

	*)

		MESSAGE="Unknown log level ${LEVEL^^} provided to log function. Valid options are DEBUG, INFO, WARN, ERR"
		LEVEL="ERR"

		;;

	esac

	echo "$(date +"%Y/%m/%d %H:%M:%S") [${LEVEL^^}] ${MESSAGE}"

	return 0

}

function checkVarEmpty() {

	# Returns true if the variable is empty

	# NOTICE:
	#	Pass this function the string NAME of the variable
	#	Not the expanded contents of the variable itself.

	local VAR_NAME="${1}"
	local VAR_DESC="${2}"

	if [[ ${!VAR_NAME:-EMPTY} == "EMPTY" ]]; then
		writeLog "ERROR" "The variable ${VAR_DESC} is empty."
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

function gitConfig() {

	# Configure a basic user so git will work without complaints
	local GIT_VERSION

	# The current git version has proved useful to have in the logs.
	GIT_VERSION=$(git --version)
	writeLog "INFO" "Configuring ${GIT_VERSION}"

	git config --global user.email "${GIT_ACTOR:-user}@users.noreply.github.com" || {
		writeLog "ERROR" "Failed to configure the git user email"
		return 1
	}

	git config --global user.name "GitHub Actions" || {
		writeLog "ERROR" "Failed to configure the git user name"
		return 1
	}

	return 0

}

function gitFetchAll() {

	# Fetch all the Git tags

	writeLog "INFO" "Fetching all Git tags"

	git fetch --prune --tags --prune-tags --all || {
		writeLog "ERROR" "Failed to fetch git tags"
		return 1
	}

	return 0

}

function getCalVer() {

	# Determines the current Calendar Version in the provided scheme.

	# Parameters
	local SCHEME="${1}"
	local SPLIT="${2}"
	local SPLIT_MOD="${3}"

	# Defaults
	local GIT_DIR="${GIT_DIR:=.git/}"
	SCHEME="${SCHEME:=YYYY.0M.0D.GEN}"
	SPLIT="${SPLIT:=.}"
	SPLIT_MOD="${SPLIT_MOD:=$SPLIT}"

	# The user provided CalVer
	local -a ARR_SCHEME_VER
	local -a ARR_MOD_VER
	local MAJOR_VER
	local MINOR_VER
	local MICRO_VER
	local MOD_VER

	# Temp variables
	local MAJOR_VER_TEMP
	local MINOR_VER_TEMP
	local MICRO_VER_TEMP
	local MOD_VER_TEMP

	# The Git tag CalVer
	local -a ARR_SCHEME_TAG
	local -a ARR_MOD_TAG
	local MAJOR_TAG
	local MINOR_TAG
	local MICRO_TAG
	local MOD_TAG
	local TAG

	# The variables for matching
	local MAJOR_MATCH="FALSE"
	local MINOR_MATCH="FALSE"
	local MICRO_MATCH="FALSE"
	local MOD_MATCH="FALSE"

	# Get the latest tag across ALL branches (excluding Semantic Version tags)
	TAG="$(git --git-dir="${GIT_DIR}" describe --tags --match "[0-9]*" --abbrev=0 "$(git rev-list --tags --max-count=1)" 2>/dev/null)"

	writeLog "DEBUG" "Previous Git Tag: ${TAG}"

	# Split the schemes in to MAJOR MINOR MICRO MODIFIER
	mapfile -t -d "${SPLIT}" ARR_SCHEME_VER <<<"${SCHEME}"
	mapfile -t -d "${SPLIT}" ARR_SCHEME_TAG <<<"${TAG}"

	# Place the split into individual variables
	MAJOR_VER="${ARR_SCHEME_VER[0]}"
	MINOR_VER="${ARR_SCHEME_VER[1]}"
	MICRO_VER="${ARR_SCHEME_VER[2]}"
	MOD_VER="${ARR_SCHEME_VER[3]}"

	# Do the same for the Git Tag
	MAJOR_TAG="${ARR_SCHEME_TAG[0]}"
	MINOR_TAG="${ARR_SCHEME_TAG[1]}"
	MICRO_TAG="${ARR_SCHEME_TAG[2]}"
	MOD_TAG="${ARR_SCHEME_TAG[3]}"

	# If the MODIFIER is empty, split MICRO again by SPLIT_MOD
	mapfile -t -d "${SPLIT_MOD}" ARR_MOD_VER <<<"${MICRO_VER}"
	mapfile -t -d "${SPLIT_MOD}" ARR_MOD_TAG <<<"${MICRO_TAG}"

	# Re-split the Version into MICRO and MOD (only if MOD is empty)
	MICRO_VER="${ARR_MOD_VER[0]}"
	MOD_VER="${MOD_VER:=${ARR_MOD_VER[1]}}"

	# Re-split the Tag into MICRO and MOD (only if MOD is empty)
	MICRO_TAG="${ARR_MOD_TAG[0]}"
	MOD_TAG="${MOD_TAG:=${ARR_MOD_TAG[1]}}"

	# Strip all new lines
	MAJOR_VER="${MAJOR_VER//$'\n'/}"
	MINOR_VER="${MINOR_VER//$'\n'/}"
	MICRO_VER="${MICRO_VER//$'\n'/}"
	MOD_VER="${MOD_VER//$'\n'/}"

	# Strip all new lines
	MAJOR_TAG="${MAJOR_TAG//$'\n'/}"
	MINOR_TAG="${MINOR_TAG//$'\n'/}"
	MICRO_TAG="${MICRO_TAG//$'\n'/}"
	MOD_TAG="${MOD_TAG//$'\n'/}"

	writeLog "DEBUG" "SPLIT: ${SPLIT:-EMPTY} SPLIT_MOD: ${SPLIT_MOD:-EMPTY}"
	writeLog "DEBUG" "CalVer Scheme MAJOR: ${MAJOR_VER:-EMPTY} MINOR: ${MINOR_VER:-EMPTY} MICRO: ${MICRO_VER:-EMPTY} MODIFIER: ${MOD_VER:-EMPTY}"
	writeLog "DEBUG" "Git Tag Scheme MAJOR: ${MAJOR_TAG:-EMPTY} MINOR: ${MINOR_TAG:-EMPTY} MICRO: ${MICRO_TAG:-EMPTY} MODIFIER: ${MOD_TAG:-EMPTY}"

	# Process MAJOR
	if [ "${MAJOR_VER^^}" != "GEN" ] && [ "${MAJOR_VER:-EMPTY}" != "EMPTY" ]; then
		writeLog "DEBUG" "Converting MAJOR ${MAJOR_VER} into date format"
		MAJOR_VER_TEMP=$(date +"$(getDateFormat "${MAJOR_VER}")")
		MAJOR_VER="${MAJOR_VER_TEMP:-$MAJOR_VER}"
		MAJOR_VER="${MAJOR_VER//date/}"
	fi

	# Process MINOR
	if [ "${MINOR_VER^^}" != "GEN" ] && [ "${MINOR_VER:-EMPTY}" != "EMPTY" ]; then
		writeLog "DEBUG" "Converting MINOR ${MINOR_VER} into date format"
		MINOR_VER_TEMP=$(date +"$(getDateFormat "${MINOR_VER}")")
		MINOR_VER="${MINOR_VER_TEMP:-$MINOR_VER}"
		MINOR_VER="${MINOR_VER//date/}"
	fi

	# Process MICRO
	if [ "${MICRO_VER^^}" != "GEN" ] && [ "${MICRO_VER:-EMPTY}" != "EMPTY" ]; then
		writeLog "DEBUG" "Converting MICRO ${MICRO_VER} into date format"
		MICRO_VER_TEMP=$(date +"$(getDateFormat "${MICRO_VER}")")
		MICRO_VER="${MICRO_VER_TEMP:-$MICRO_VER}"
		MICRO_VER="${MICRO_VER//date/}"
	fi

	# Process MOD
	if [ "${MOD_VER^^}" != "GEN" ] && [ "${MOD_VER:-EMPTY}" != "EMPTY" ]; then
		writeLog "DEBUG" "Converting MODIFIER ${MOD_VER} into date format"
		MOD_VER_TEMP=$(date +"$(getDateFormat "${MOD_VER}")")
		MOD_VER="${MOD_VER_TEMP:-$MOD_VER}"
		MOD_VER="${MOD_VER//date/}"
	fi

	# Determine if there is a potential tag clash
	[ "${MAJOR_VER:-EMPTY}" = "${MAJOR_TAG}" ] && {
		MAJOR_MATCH="TRUE"
		writeLog "DEBUG" "MAJOR Matched existing tag!"
	}
	[ "${MINOR_VER:-EMPTY}" = "${MINOR_TAG}" ] && {
		MINOR_MATCH="TRUE"
		writeLog "DEBUG" "MINOR Matched existing tag!"
	}
	[ "${MICRO_VER:-EMPTY}" = "${MICRO_TAG}" ] && {
		MICRO_MATCH="TRUE"
		writeLog "DEBUG" "MICRO Matched existing tag!"
	}
	[ "${MOD_VER:-EMPTY}" = "${MOD_TAG}" ] && {
		MOD_MATCH="TRUE"
		writeLog "DEBUG" "MODIFIER Matched existing tag!"
	}

	# The Calendar Versioning scheme stipulates that;
	#   RULE 1) Both MAJOR MINOR must be CalVer dates
	#   RULE 2) MICRO can be date or a generated number
	#   RULE 3) MODIFIER is optional string OR generated number

	# If both MAJOR and MINOR are the same, there is risk of tag collision
	if [ "${MAJOR_MATCH}" == "TRUE" ] && [ "${MINOR_MATCH}" == "TRUE" ]; then

		writeLog "DEBUG" "Collision for MAJOR MINOR"

		# If MOD is a GEN, then increment by 1 to avoid the collision
		if [ "${MOD_VER^^}" == "GEN" ]; then

			# If MOD is empty, start from 0
			if [ "${MOD_TAG:-EMPTY}" == "EMPTY" ]; then

				writeLog "DEBUG" "Resetting MODIFIER to 0"
				MOD_VER="0"

			## If there is a previous tag, however MICRO isn't a match, start from 0
			elif [ "${MICRO_MATCH}" != "TRUE" ]; then

				# Its a brand new CalVer
				writeLog "DEBUG" "Resetting MODIFIER to 0"
				MOD_VER="0"

			# If there is a previous tag and MICRO was a match, increment
			elif [ "${MICRO_MATCH}" == "TRUE" ]; then

				writeLog "DEBUG" "Incrementing MODIFIER from Tag ${MOD_TAG}"
				MOD_VER="$(printf %01d $((MOD_TAG + 1)))"

			else

				# Edge case not considered?
				writeLog "WARN" "POSSIBLE EDGE CASE DETECTED"
				MOD_VER="0"

			fi

		# If MICRO is a GEN, then increment by 1 to avoid the collision
		elif [ "${MICRO_VER^^}" == "GEN" ]; then

			# If MICRO is empty, start from 0
			if [ "${MICRO_TAG:-EMPTY}" == "EMPTY" ]; then

				writeLog "DEBUG" "Resetting MICRO to 0"
				MICRO_VER="0"

			# Only increment if MOD if not being incremented
			elif [ "${MOD_VER^^}" != "GEN" ]; then

				writeLog "DEBUG" "Incrementing MICRO from Tag ${MICRO_TAG}"
				MICRO_VER="$(printf %01d $((MICRO_TAG + 1)))"

			fi

		# If neither MICRO or MODIFIER are GENs, only care if there was going to be a total CalVer collision
		elif [ "${MAJOR_MATCH}" == "TRUE" ] && [ "${MINOR_MATCH}" == "TRUE" ] && [ "${MICRO_MATCH}" == "TRUE" ] && [ "${MOD_MATCH}" == "TRUE" ]; then

			# There was a Tag collision which cannot be avoided
			if [ "${TAGS_FORCE:-FALSE}" == "TRUE" ]; then
				writeLog "WARN" "TAG COLLISION DETECTED: Existing tag will be moved to HEAD"
			else
				writeLog "WARN" "TAG COLLISION DETECTED: Tag force is not enabled so no tag will be applied."
			fi

		else

			writeLog "DEBUG" "No collision for MAJOR MINOR MICRO MODIFIER"

		fi

	else

		# It's a brand new Calendatr Versioning day, start from 0
		writeLog "DEBUG" "No Collision for MAJOR MINOR"

		if [ "${MICRO_VER^^}" == "GEN" ]; then
			writeLog "DEBUG" "Resetting MICRO to 0"
			MICRO_VER="0"
		fi

		if [ "${MOD_VER^^}" == "GEN" ]; then
			writeLog "DEBUG" "Resetting MODIFIER to 0"
			MOD_VER="0"
		fi

	fi

	# Build the final result carefully, as there could be edge cases and some could be empty
	CALVER="${MAJOR_VER}"
	CALVER="${CALVER:+$CALVER$SPLIT$MINOR_VER}"
	CALVER="${CALVER:+$CALVER$SPLIT$MICRO_VER}"
	# MODIFIER is optional
	MOD_VER="${MOD_VER:+$SPLIT_MOD$MOD_VER}"
	CALVER="${CALVER:+$CALVER$MOD_VER}"

	writeLog "DEBUG" "Final CalVer: ${CALVER}"
	export CALVER
	return 0

}

function getDateFormat() {

	# Converts the user scheme into a format accepted by the date command

	local FORMAT="${1}"
	local DATE_FORMAT

	case "${FORMAT}" in

	YYYY)
		# Full year - 2006, 2016, 2106
		DATE_FORMAT="%Y"
		;;

	YY)
		# Short year - 6, 16, 106
		DATE_FORMAT="%-y"
		;;

	0Y)
		# Zero-padded year - 06, 16, 106
		DATE_FORMAT="%y"
		;;

	MM)
		# Short month - 1, 2 ... 11, 12
		DATE_FORMAT="%-m"
		;;

	0M)
		# Zero-padded month - 01, 02 ... 11, 12
		DATE_FORMAT="%m"
		;;

	WW)
		# Short week (since start of year) - 1, 2, 33, 52
		DATE_FORMAT="%-U"
		;;

	0W)
		# Zero-padded week - 01, 02, 33, 52
		DATE_FORMAT="%U"
		;;

	DD)
		# Short day - 1, 2 ... 30, 31
		DATE_FORMAT="%-d"
		;;

	0D)
		# Zero-padded day - 01, 02 ... 30, 31
		DATE_FORMAT="%d"
		;;

	*)
		# Strip the invalid passed format so date command doesn't bork
		DATE_FORMAT=""
		;;

	esac

	echo "${DATE_FORMAT}"

	return 0

}

function gitChangelog() {

	local TAG
	export CHANGELOG

	# Defaults
	local GIT_DIR="${GIT_DIR:=.git/}"

	# Get the latest tag across ALL branches
	TAG="$(git --git-dir="${GIT_DIR}" describe --tags "$(git rev-list --tags --max-count=1)" 2>/dev/null)"
	writeLog "DEBUG" "Previous Git Tag: ${TAG}"

	# If there is no tags, just get the full history
	if [ "${TAG:-EMPTY}" == "EMPTY" ]; then

		writeLog "INFO" "No tags found, gathering full commit history"

		CHANGELOG=$(git --git-dir="${GIT_DIR}" log --pretty=format:"${GIT_PRETTY_FORMAT}")

		checkResult $? || {
			writeLog "ERROR" "Failed to obtain change log for full commit history"
			return 1
		}

	else

		writeLog "INFO" "Getting change log from HEAD back to ${TAG}"

		CHANGELOG=$(git --git-dir="${GIT_DIR}" log "${TAG}"..HEAD --pretty=format:"${GIT_PRETTY_FORMAT}")

		checkResult $? || {
			writeLog "ERROR" "Failed to obtain change log between HEAD and ${TAG}"
			return 1
		}

	fi

	if [ ! "${CHANGELOG:-EMPTY}" == "EMPTY" ]; then

		writeLog "INFO" "Recording changelog"

		export CHANGELOG

	else

		writeLog "WARN" "Changelog variable is empty, setting the last commit notes as the changelog"
		CHANGELOG=$(git --git-dir="${GIT_DIR}" log -n1 --pretty=format:"${GIT_PRETTY_FORMAT}")

		# If the changelog is still empty, something has gone really wrong :/
		if [ "${CHANGELOG:-EMPTY}" == "EMPTY" ]; then

			writeLog "ERROR" "Failed to obtain changelog!"
			return 1

		fi

		export CHANGELOG

	fi

	return 0

}

function gitTag() {

	# Applies the provided Git tag

	# Parameters
	local TAG="${1}"
	local FORCE="${2}"

	# Defaults
	local GIT_DIR="${GIT_DIR:=.git/}"

	# If no tag was provided, just return without doing anything
	checkVarEmpty "TAG" "Git Tag" && return 0

	writeLog "INFO" "Applying Git tag ${TAG}"

	# Apply the tag
	if [ "${FORCE:-FALSE}" == "TRUE" ]; then

		git --git-dir="${GIT_DIR}" \
			tag --annotate --no-sign --force --message "Release ${TAG}" "${TAG}" ||
			{
				writeLog "ERROR" "Unable to apply tag ${TAG}"
				return 1
			}

	else

		git --git-dir="${GIT_DIR}" \
			tag --annotate --no-sign --message "Release ${TAG}" "${TAG}" ||
			{
				writeLog "ERROR" "Unable to apply tag ${TAG}. Force is not enabled"
				return 0
			}

	fi

	writeLog "INFO" "Listing available Git tags"

	# List current tags
	git --git-dir="${GIT_DIR}" \
		tag --list -n1 ||
		{
			writeLog "ERROR" "Failed to list tags"
			return 1
		}

	writeLog "INFO" "Pushing new Git tag ${TAG} to origin"

	# Push the changes back
	git --git-dir="${GIT_DIR}" \
		push origin --force --tags ||
		{
			writeLog "ERROR" "Failed to push tag ${TAG} to origin"
			return 1
		}

	return 0

}

function getSemVer() {

	# Determine the next Semantic Version and then tag the current commit.

	local SEMVER_TYPE="$1"
	local PREFIX="$2"

	local SEMVER_ARRAY=""
	local MAJOR="0"
	local MINOR="0"
	local PATCH="0"

	# Get the latest tag across ALL branches (excluding Calendar Version tags)
	TAG="$(git --git-dir="${GIT_DIR}" describe --tags --match "${PREFIX}[0-9]*" --abbrev=0 "$(git rev-list --tags --max-count=1)" 2>/dev/null)"

	# Break the last Tag into MAJOR.MINOR.PATCH
	if [ "${TAG:-EMPTY}" == "EMPTY" ]; then

		# No existing Semantic Version tag was found
		writeLog "INFO" "No existing Semantic Version tag was found, defaulting to v0.0.0"

	else

		# Split the existing Semantic Version into separate parts
		IFS="." read -r -a SEMVER_ARRAY <<<"${TAG}"

		# Ensure the found tag is in the MAJOR.MINOR.PATCH format
		if [ "${#SEMVER_ARRAY[@]}" -ne 3 ]; then
			writeLog "ERROR" "The tag ${TAG} is not in the correct Semantic Version that was supplied, should be MAJOR.MINOR.PATCH"
			return 1
		fi

		# Strip the 'v' from the front of MAJOR
		if [[ ${SEMVER_ARRAY[0]} =~ ([vV]?)([0-9]+) ]]; then
			PREFIX="${BASH_REMATCH[1]}"
			MAJOR="${BASH_REMATCH[2]}"
		else
			MAJOR=""
		fi

		MINOR="${SEMVER_ARRAY[1]}"
		PATCH="${SEMVER_ARRAY[2]}"

	fi

	case "${SEMVER_TYPE^^}" in

	"MAJOR")
		MAJOR=$((MAJOR + 1))
		;;

	"MINOR")
		MINOR=$((MINOR + 1))
		;;

	"PATCH")
		PATCH=$((PATCH + 1))
		;;

	*)
		writeLog "ERROR" "Unknown Semantic Version type provided of $SEMVER_TYPE"
		return 1
		;;

	esac

	SEMVER="${PREFIX}${MAJOR}.${MINOR}.${PATCH}"

	writeLog "DEBUG" "Final SemVer: ${SEMVER}"
	export SEMVER
	return 0

}

writeLog "DEBUG" "Sourced required common functions"

#########################
# EOF
#########################
