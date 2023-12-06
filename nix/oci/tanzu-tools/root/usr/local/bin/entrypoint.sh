#!/usr/bin/env bash

if [[ ${ENABLE_DEBUG:-FALSE} == "TRUE" ]]; then
	set -x
fi

#set -e
set -u
set -o pipefail

#########################
# Variables
#########################

# The name of the script used in logs.
export SCRIPT="tanzu-tools"

# No phoning home is allowed.
export TANZU_CLI_CEIP_OPT_IN_PROMPT_ANSWER="no"

# Write all logs to file.
export LOG_DESTINATION="${LOG_DESTINATION:-file}"
export LOG_FILE="${LOG_FILE:-/tmp/$SCRIPT.log}"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Interactive loop
export TANZU_TOOLS_RUN=FALSE

# Dialog theme
export DIALOGRC="${HOME}/.dialogrc/${TANZU_TOOLS_DIALOG_THEME}"

# Preload libnss for uid > 65535
#export LD_PRELOAD=/lib/lib-sssd/libnss_sss.so.2

#########################
# Dependencies
#########################

# shellcheck disable=SC1091
source functions.sh || {
	echo "Failed to import required common functions!"
	exit 1
}

# shellcheck disable=SC1091
source dialog.sh || {
	writeLog "ERROR" "Failed to import required dialog functions!"
	exit_script 1
}

#########################
# Checks
#########################

# Make sure that the interactive parts are not run in a a VSCode container env.
# VSCode handles it's own userID mapping and mounts.
if [[ ${ENVIRONMENT_VSCODE^^} == "CONTAINER" ]]; then

	while true; do

		writeLog "INFO "INFO: Devcontainer environment is running...
		sleep 300

	done

	writeLog "INFO" "Finished"

	exit 0

fi

#########################
# Functions
#########################

function start_shell() {

	# If run as root is enabled drop into a root shell.
	if [[ ${RUN_AS_ROOT:-FALSE} == "TRUE" ]]; then

		writeLog "INFO" "Dropping into a root user shell"

		bash --login -i || {
			writeLog "ERROR" "Failed to start shell for user 'root'"
			return 1
		}

	# If a custom CMD was provided, run that and not the interactive shell.
	elif [[ $# -gt 0 ]]; then

		writeLog "INFO" "Running user provided CMD"

		sudo --user=tanzu --set-home --preserve-env -- "$@" || {
			writeLog "ERROR" "Failed to start shell for user 'tanzu'"
			return 1
		}

	# if you are root but run as root is not enabled,
	elif [[ ${UID} -eq 0 ]]; then

		writeLog "INFO" "Switching to 'tanzu' user"

		sudo --user=tanzu --set-home --preserve-env -- bash --login -i || {
			writeLog "ERROR" "Failed to start shell for user 'tanzu'"
			return 1
		}

	# Not sure what purpose this serves yet with no other users in the container.
	else

		writeLog "INFO" "Starting shall as $USER"

		bash --login -i || {
			writeLog "ERROR" "Failed to start shell for user $USER"
			return 1
		}

	fi

	return 0

}

#########################
# Setup
#########################

# Make sure the wrappers are the first in the PATH
if [[ -d "/run/wrappers/bin" ]]; then

	writeLog "DEBUG" "Wrappers dir found, checking PATH"

	if ! grep "/run/wrappers/bin" <<<"${PATH}"; then

		writeLog "DEBUG" "Adding wrappers dir to PATH"
		export PATH=/run/wrappers/bin:$PATH

	else

		writeLog "DEBUG" "Wrappers dir already in PATH"

	fi

else

	writeLog "DEBUG" "Wrappers dir not found"

fi

# If running as root, setup the 'tanzu' user to match host user.
# https://www.joyfulbikeshedding.com/blog/2021-03-15-docker-and-the-host-filesystem-owner-matching-problem.html
if [[ ${UID} -eq 0 ]]; then

	writeLog "DEBUG" "Running as root"

	# Make tmp shared between all users.
	chmod 1777 /tmp || {
		writeLog "ERROR" "Failed to set permissions on '/tmp'"
		exit_script 1
	}

	# Make sure there is a shared log file.
	if [[ ! -f ${LOG_FILE} ]]; then
		writeLog "DEBUG" "Creating new log file ${LOG_FILE}"
		touch "${LOG_FILE}" || {
			writeLog "ERROR" "Failed to create a new log file at ${LOG_FILE}. Are the permissions valid?"
			exit_script 1
		}
	fi

	# Always ensure the environment log is all users writable.
	chmod 0777 "${LOG_FILE}" || {
		writeLog "ERROR" "Failed to set permissions on the log file ${LOG_FILE}"
		exit_script 1
	}

	# If this flag was provided, we will run as the root user.
	# This is useful in a docker rootless setup where the root user
	# inside the container is auto-mapped to the local system user.
	if [[ ${RUN_AS_ROOT:-FALSE} == "TRUE" ]]; then

		if [[ ! -f "/root/.profile" ]]; then

			writeLog "DEBUG" "Copying root users profile"

			rsync -a /etc/skel/ /root --copy-links || {
				writeLog "ERROR" "Failed to rsync the root user's profile"
				exit_script 1
			}

		else

			writeLog "INFO" "A profile already exists for user 'root', skipping setup"

		fi

		chown -R root:root /root || {
			writeLog "ERROR" "Failed to set owner to user 'root' on /root"
			exit_script 1
		}

		chmod -R 0751 /root || {
			writeLog "ERROR" "Failed to chmod 0751 on /root"
			exit_script 1
		}

	else

		# If a HOST_UID and HOST_GID is provided, do the janky permissions setup...
		if [[ ${HOST_UID:-EMPTY} == "EMPTY" ]] || [[ ${HOST_GID:-EMPTY} == "EMPTY" ]]; then

			writeLog "ERROR" "This container requires you to pass the '\${HOST_UID}' and '\${HOST_GID}' variables"
			exit_script 1

		fi

		writeLog "DEBUG" "Adding Tanzu group with user provided GID ${HOST_GID}"

		groupadd \
			tanzu \
			--gid "${HOST_GID}" || {
			writeLog "ERROR" "Failed to create 'tanzu' group with GID ${HOST_GID}"
			exit_script 1
		}

		writeLog "DEBUG" "Adding Tanzu user with user provided UID ${HOST_UID}"

		useradd \
			--uid "${HOST_UID}" \
			--gid "${HOST_GID}" \
			--comment "Tanzu CLI" \
			--home /home/tanzu \
			--shell /bin/bash \
			--groups tanzu,docker \
			--no-user-group \
			--no-create-home \
			tanzu || {
			writeLog "ERROR" "Failed to create 'tanzu' user with UID ${HOST_UID}"
			exit_script 1
		}

		writeLog "DEBUG" "Checking for Tanzu user home"

		if [[ ! -f "/home/tanzu/.profile" ]]; then

			writeLog "DEBUG" "Copying Tanzu users profile"

			rsync -a /etc/skel/ /home/tanzu --copy-links || {
				writeLog "ERROR" "Failed to rsync the Tanzu user's profile"
				exit_script 1
			}

		else

			writeLog "INFO" "A profile already exists for user 'tanzu', skipping setup"

		fi

		writeLog "DEBUG" "Setting home permissions for Tanzu user"

		chown -R tanzu:tanzu /home/tanzu || {
			writeLog "ERROR" "Failed to set owner to user 'tanzu' on /home/tanzu"
			exit_script 1
		}

		chmod -R 0751 /home/tanzu || {
			writeLog "ERROR" "Failed to chmod 0751 on /home/tanzu"
			exit_script 1
		}

		# HACK: Need to fix the error 'invalid parameter' when UID > 65535
		#chmod -R 0777 /home/tanzu || {
		#	writeLog "ERROR" "Failed to chmod 0777 on /home/tanzu"
		#	exit_script 1
		#}

		# If the docker socket was mounted, make sure the user can access it.
		DOCKER_GROUP_ID=$(getent group docker | cut -d: -f3)
		if [[ -S /var/run/docker.sock ]]; then

			writeLog "INFO" "Docker socket present, checking permissions"

			DOCKER_SOCKET_ID=$(stat -c '%g' /var/run/docker.sock)

			# If the docker socket group id does not match the docker group id, change the group id.
			if [[ ${DOCKER_GROUP_ID} -ne ${DOCKER_SOCKET_ID} ]]; then

				writeLog "INFO" "Updating docker socket group id to ${DOCKER_SOCKET_ID}"

				groupmod --gid "${DOCKER_SOCKET_ID}" docker || {
					writeLog "ERROR" "Failed to set 'docker' group GID to ${DOCKER_SOCKET_ID}"
					exit_script 1
				}

			fi

			writeLog "INFO" "Updating Sub IDs and and GIDs for 'tanzu'"

			echo "tanzu:3000000000:65535" >/etc/subuid || exit_script 1
			echo "tanzu:3000000000:65535" >/etc/subgid || exit_script 1
			chmod 0644 /etc/subuid /etc/subgid || exit_script 1

		fi

	fi

else

	writeLog "WARN" "Not running as root, skipping user setup..."

fi

# Perform group and user check
grpck || {
	writeLog "ERROR" "Group check failed. Please check the contents of /etc/group."
	exit_script 1
}
pwck || {
	writeLog "ERROR" "User check failed. Please check the contents of /etc/passwd."
	exit_script 1
}

#########################
# Main
#########################

# Start a new login shell with any modified UID or GIDs applied.
dialogProgress "Tanzu Tools: Starting Shell..." "100"

if start_shell "$@"; then
	SHELL_EXIT_CODE=$?
	writeLog "INFO" "The initial shell session has terminated successfully."
else
	SHELL_EXIT_CODE=$?
	writeLog "ERROR" "The initial shell session has terminated with exit code ${SHELL_EXIT_CODE}"
fi

while true; do

	if [[ ${SHELL_EXIT_CODE:-0} -ne 0 ]]; then
		show_logs || true
		read -r -p "Press any key to continue."
	fi

	dialogYesNo "Tanzu Tools: Session Ended" "Would you like to start a new session?"

	#  0 = Yes
	#  1 = No
	#  2 = Help
	#  3 = Extra
	# -1 = Error

	"${CMD[@]}" "${BOX_OPTIONS[@]}" "${OPTIONS[@]}"
	RETURN_CODE=$?

	writeLog "DEBUG" "Dialog return: ${RETURN_CODE:-EMPTY}"

	case "${RETURN_CODE:-EMPTY}" in

	0) # YES

		writeLog "DEBUG" "Return code was ${RETURN_CODE}, user selected YES to starting new shell session"

		dialogProgress "Tanzu Tools: Starting Shell..." "100"

		if start_shell "$@"; then
			SHELL_EXIT_CODE=$?
			writeLog "INFO" "The shell session has terminated successfully."
		else
			SHELL_EXIT_CODE=$?
			writeLog "ERROR" "The shell session has terminated with exit code ${SHELL_EXIT_CODE}"
		fi

		;;

	1) # NO

		writeLog "DEBUG" "Return code was ${RETURN_CODE}, the user selected NO to starting new shell session."

		dialogProgress "Tanzu Tools: Exiting Shell..." "100"
		sleep 0.5

		break

		;;

	*) # NO IDEA

		writeLog "WARN" "Return code was ${RETURN_CODE}, the user either hit escape or there was an unhandled error starting new shell session"

		dialogProgress "Tanzu Tools: Only YES or NO are valid answers." "0"
		sleep 3

		;;

	esac

done

tput clear

figlet -f slant "Goodbye!"

exit 0
