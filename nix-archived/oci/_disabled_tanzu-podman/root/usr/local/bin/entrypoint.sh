#!/usr/bin/env bash

if [[ ${ENABLE_DEBUG:-FALSE} == "TRUE" ]]; then
	set -x
fi

export ENTRYPOINT_EXECUTED="TRUE"

# Make sure that the interactive parts are not run in a a VSCode container env.
# VSCode handles it's own userID mapping and mounts.
if [[ ${ENVIRONMENT_VSCODE^^} == "CONTAINER" ]]; then

	while true; do
		echo "$(date '+%Y/%m/%d %T'): INFO: Devcontainer environment is running..." | tee -a "/tmp/environment.log"
		sleep 300
	done

fi

# If the container is run as root, then we need to setup the user.
if [[ ${UID} -eq 0 ]]; then

	echo "$(date '+%Y/%m/%d %T'): INFO: Running as root user, performing user setup steps..." | tee -a "/tmp/environment.log"

	# Make tmp shared between all users.
	chmod 1777 /tmp || {
		echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to set permissions on '/tmp'"
		exit 1
	}

	# Always ensure the environment log is all users writable.
	chmod 777 /tmp/environment.log || {
		echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to set permissions on '/tmp/environment.log'"
		exit 1
	}

	# --env HOST_UID=$(id -u)
	if [[ ${HOST_UID:-EMPTY} == "EMPTY" ]]; then
		echo "$(date '+%Y/%m/%d %T'): ERROR: When running as 'root' please set the 'HOST_UID' env" >&2
		exit 1
	fi

	# --env HOST_GID=$(id -g)
	if [[ ${HOST_GID:-EMPTY} == "EMPTY" ]]; then
		echo "$(date '+%Y/%m/%d %T'): ERROR: When running as 'root' please set the 'HOST_GID' env" >&2
		exit 1
	fi

	# There are two options the container will attempt.
	# Option 1. Map the host user to the container user.
	# Option 2. Attempt to use bindFS to re-mount the home directory with the correct permissions.

	# Option 1.

	# If the group named 'tanzu' does not have the same id, change it.
	OPTION_1_STATUS="SUCCESS"
	TANZU_TOOLS_GROUP_ID=$(getent group tanzu | cut -d: -f3)
	if [[ ${TANZU_TOOLS_GROUP_ID} -ne ${HOST_GID} ]]; then
		echo "$(date '+%Y/%m/%d %T'): INFO: Updating the container user 'tanzu' GID to '${HOST_GID}'" | tee -a "/tmp/environment.log"
		groupmod --gid "$HOST_GID" tanzu || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to set 'tanzu' group GID to '${HOST_GID}'"
			OPTION_1_STATUS="FAILED"
		}
	fi

	# If the user named 'tanzu' does not have the same id, change it.
	TANZU_TOOLS_USER_ID=$(id -u tanzu)
	if [[ ${TANZU_TOOLS_USER_ID} -ne ${HOST_UID} ]]; then
		echo "$(date '+%Y/%m/%d %T'): INFO: Updating the container user tanzu' UID to '${HOST_UID}'" | tee -a "/tmp/environment.log"
		usermod --uid "$HOST_UID" tanzu || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to set 'tanzu' user UID to '${HOST_UID}'"
			OPTION_1_STATUS="FAILED"
		}
	fi
	chown -R "${HOST_UID}:${HOST_GID}" /home/tanzu || {
		echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to set 'tanzu' user home directory permissions"
		OPTION_1_STATUS="FAILED"
	}

	# If the docker socket was mounted, make sure the user can access it.
	DOCKER_GROUP_ID=$(getent group docker | cut -d: -f3)
	if [[ -S /var/run/docker.sock ]]; then
		DOCKER_SOCKET_ID=$(stat -c '%g' /var/run/docker.sock)
		# If the docker socket group id does not match the docker group id, change the group id.
		if [[ ${DOCKER_GROUP_ID} -ne ${DOCKER_SOCKET_ID} ]]; then
			groupmod --gid "${DOCKER_SOCKET_ID}" docker || {
				echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to set 'docker' group GID to '${DOCKER_SOCKET_ID}'"
				OPTION_1_STATUS="FAILED"
			}
		fi
	fi

	# Option 2.

	# If Option 1 fails, attempt Option 2.
	if [[ ${OPTION_1_STATUS:-FAILED} != "SUCCESS" ]]; then

		echo "$(date '+%Y/%m/%d %T'): WARN: Using bindFS fallback method for user permissions" | tee -a "/tmp/environment.log"

		# Create the required bindFS directories.
		mkdir --parents /home/tanzu-bindfs || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to create required bindFS directory '/home/tanzu-bindfs'"
			exit 1
		}

		# Option 1. --cap-add SYS_ADMIN
		# Option 2. --privileged
		# Option 3. --device /dev/fuse
		# Setup the bindFS mounts to re-mount with the correct permissions as the 'tanzu' user.
		modprobe fuse || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to load the 'fuse' kernel module. Did you forget '--cap-add SYS_ADMIN'"
			exit 1
		}
		bindfs \
			--force-user=tanzu \
			--force-group=tanzu \
			--create-for-user="$(id -u tanzu)" \
			--create-for-group="$(getent group tanzu | cut -d: -f3)" \
			--chown-ignore \
			--chgrp-ignore \
			/home/tanzu /home/tanzu-bindfs || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to setup bindFS mount for '/home/tanzu'"
			exit 1
		}

	fi

	CMD_PREFIX=(
		"exec"
		"sudo"
		"--preserve-env"
		"--set-home"
		"--user"
		"tanzu"
		"--"
	)

fi

# Unfortunately, kind has a hard dependency on systemd...
#alias kind='systemd-run --user --scope --property=Delegate=yes kind'

# If a custom CMD was provided, run that and not the interactive loop.
if [[ $# -gt 0 ]]; then

	"${CMD_PREFIX[@]}" "$@"

else

	COMMAND=(
		"/usr/bin/env"
		"bash"
		"--login"
		"-i"
	)

	"${CMD_PREFIX[@]}" "${COMMAND[@]}" || true

	# Start a fresh shell session.
	while true; do

		clear

		# If bash exits, ask if we should restart or break and exit.
		printf "\n"
		echo "Your current shell session in this container has terminated."
		read -r -p "Start a new shell session? y/n: " CHOICE

		case $CHOICE in

		[Yy]*)

			echo "Restarting shell..."
			"${CMD_PREFIX[@]}" "${COMMAND[@]}" || true

			;;

		[Nn]*)

			echo "Exiting..."
			break

			;;

		*)

			echo "Please answer yes or no."
			sleep 1

			;;

		esac

	done

fi

figlet -f slant "Goodbye!"
exit 0
