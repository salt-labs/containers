#!/usr/bin/env bash

if [[ ${ENABLE_DEBUG:-FALSE} == "TRUE" ]]; then
	set -x
fi

# shellcheck disable=SC1091
source functions.sh || {
	echo "Failed to import required common functions!"
	exit 1
}

# Make sure that the interactive parts are not run in a a VSCode container env.
# VSCode handles it's own userID mapping and mounts.
if [[ ${ENVIRONMENT_VSCODE^^} == "CONTAINER" ]]; then

	while true; do
		writeLog "INFO "INFO: Devcontainer environment is running...
		sleep 300
	done

	exit 0

fi

function start_shell() {

	# If a custom CMD was provided, run that and not the interactive shell.
	if [[ $# -gt 0 ]]; then

		writeLog "INFO" "Running user provided CMD"

		sudo --user=tanzu --set-home --preserve-env -- "$@" || {
			writeLog "ERROR" "Failed to start shell for user 'tanzu'"
			return 1
		}

	elif [[ ${UID} -eq 0 ]]; then

		writeLog "INFO" "Switching to 'tanzu' user"

		sudo --user=tanzu --set-home --preserve-env -- bash --login -i || {
			writeLog "ERROR" "Failed to start shell for user 'tanzu'"
			return 1
		}

	else

		writeLog "INFO" "Starting shall as $USER"

		bash --login -i || {
			writeLog "ERROR" "Failed to start shell for user $USER"
			return 1
		}

	fi

	return 0

}

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
		exit 1
	}

	# Make sure there is a shared log file.
	if [[ ! -f ${LOG_FILE} ]]; then
		writeLog "DEBUG" "Creating new log file ${LOG_FILE}"
		touch "${LOG_FILE}" || {
			writeLog "ERROR" "Failed to create a new log file at ${LOG_FILE}. Are the permissions valid?"
			exit 1
		}
	fi

	# Always ensure the environment log is all users writable.
	chmod 0777 "${LOG_FILE}" || {
		writeLog "ERROR" "Failed to set permissions on the log file ${LOG_FILE}"
		exit 1
	}

	# If a HOST_UID and HOST_GID is provided, do the janky permissions setup...
	if [[ ${HOST_UID:-EMPTY} == "EMPTY" ]] || [[ ${HOST_GID:-EMPTY} == "EMPTY" ]]; then

		writeLog "ERROR" "This container requires you to pass the '\${HOST_UID}' and '\${HOST_GID}' variables"
		exit 1

	fi

	writeLog "DEBUG" "Adding Tanzu group with user provided GID ${HOST_GID}"

	groupadd \
		tanzu \
		--gid "${HOST_GID}" || {
		writeLog "ERROR" "Failed to create 'tanzu' group with GID ${HOST_GID}"
		exit 1
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
		writeLog "ERROR" "ailed to create 'tanzu' user with UID ${HOST_UID}"
		exit 1
	}

	writeLog "DEBUG" "Checking for Tanzu user home"

	if [[ ! -f "/home/tanzu/.profile" ]]; then

		writeLog "DEBUG" "Copying Tanzu users profile"

		rsync -a /etc/skel/ /home/tanzu --copy-links || {
			writeLog "ERROR" "Failed to rsync the Tanzu user's profile"
			exit 1
		}

		writeLog "DEBUG" "Setting home permissions for Tanzu user"

		chown --recursive tanzu:tanzu /home/tanzu || {
			writeLog "ERROR" "Failed to set owner to user 'tanzu' on /home/tanzu"
			#exit 1
		}

		chmod --recursive 0751 /home/tanzu || {
			writeLog "ERROR" "Failed to chmod 0751 on /home/tanzu"
			#exit 1
		}

		# HACK: Need to fix the UID > 65535 issue
		chmod --recursive 0777 /home/tanzu || {
			writeLog "ERROR" "Failed to chmod 0777 on /home/tanzu"
			#exit 1
		}

	else

		writeLog "INFO" "A profile already exists for user 'tanzu', skipping setup"

	fi

	# If the docker socket was mounted, make sure the user can access it.
	DOCKER_GROUP_ID=$(getent group docker | cut -d: -f3)
	if [[ -S /var/run/docker.sock ]]; then

		writeLog "INFO" "Docker socket present, checking permissions"

		DOCKER_SOCKET_ID=$(stat -c '%g' /var/run/docker.sock)

		# If the docker socket group id does not match the docker group id, change the group id.
		if [[ ${DOCKER_GROUP_ID} -ne ${DOCKER_SOCKET_ID} ]]; then

			writeLog "INFO" "Updating docker socket group id to ${DOCKER_SOCKET_ID}"

			groupmod --gid "${DOCKER_SOCKET_ID}" docker || {
				writeLog "ERRPR" "Failed to set 'docker' group GID to ${DOCKER_SOCKET_ID}"
				exit 1
			}

		fi

		writeLog "INFO" "Updating Sub IDs and and GIDs for 'tanzu'"

		echo "tanzu:3000000000:65535" >/etc/subuid || exit 1
		echo "tanzu:3000000000:65535" >/etc/subgid || exit 1
		chmod 0644 /etc/subuid /etc/subgid || exit 1

	fi

fi

# Perform group and user check
grpck || {
	writeLog "ERROR" "Group check failed. Please check the contents of /etc/group."
	exit 1
}
pwck || {
	writeLog "ERROR" "User check failed. Please check the contents of /etc/passwd."
	exit 1
}

# Start a new login shell with any modified UID or GIDs applied.
start_shell "$@" || {
	SHELL_EXIT_CODE=$?
}

SHELL_COUNTER=0
while true; do

	((SHELL_COUNTER = SHELL_COUNTER + 1))
	if [[ ${SHELL_COUNTER} -ge 3 ]]; then
		printf "\n"
		echo "big ooof! That's 3x failed sessions, you're out!"
		exit 1
	fi

	# If bash exits, ask if we should restart or break and exit.
	printf "\n"
	echo "Your current shell session in this container has ended."

	if [[ -f ${LOG_FILE} ]] && [[ ${SHELL_EXIT_CODE:-0} -ne 0 ]]; then
		printf "\n"
		echo "Displaying session logs"
		cat "${LOG_FILE}" || true
	fi

	printf "\n"
	read -r -p "Would you like to start a new shell session? y/n: " CHOICE

	clear

	case $CHOICE in

	[Yy]*)

		echo "Restarting shell..."
		start_shell "$@" || {
			SHELL_EXIT_CODE=$?
		}

		;;

	[Nn]*)

		echo "Exiting..."
		break 1

		;;

	*)

		echo "Please answer yes or no."
		sleep 1

		;;

	esac

done

figlet -f slant "Goodbye!"
exit 0
