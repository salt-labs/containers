#!/usr/bin/env bash

if [[ ${ENABLE_DEBUG:-FALSE} == "TRUE" ]]; then
	set -x
fi

# Make sure that the interactive parts are not run in a a VSCode container env.
# VSCode handles it's own userID mapping and mounts.
if [[ ${ENVIRONMENT_VSCODE^^} == "CONTAINER" ]]; then

	while true; do
		echo "$(date '+%Y/%m/%d %T'): INFO: Devcontainer environment is running..." | tee -a "/tmp/environment.log"
		sleep 300
	done

fi

# If the container is run as root, then we need to setup the user.
if [[ "${UID}" -eq 0  ]]; then

	echo "$(date '+%Y/%m/%d %T'): INFO: Running as root user, performing user setup steps..." | tee -a "/tmp/environment.log"

	# --env HOST_UID=$(id -u)
	if [[ "${HOST_UID:-EMPTY}" == "EMPTY" ]]; then
		echo "ERROR: When running as 'root' please set the 'HOST_UID' env" >&2
		exit 1
	else
		echo "INFO: Setting 'tanzu' user UID to '${HOST_UID}'" | tee -a "/tmp/environment.log"
	fi

	# --env HOST_GID=$(id -g)
	if [[ "${HOST_GID:-EMPTY}" == "EMPTY" ]]; then
		echo "ERROR: When running as 'root' please set the 'HOST_GID' env" >&2
		exit 1
	else
		echo "INFO: Setting 'tanzu' user GID to '${HOST_GID}'" | tee -a "/tmp/environment.log"
	fi

	# Create the required bindFS directories.
	mkdir --parents /home/tanzu-bindfs || {
		echo "ERROR: Failed to create required bindFS directory '/home/tanzu-bindfs'"
		exit 1
	}

	# Option 1. --cap-add SYS_ADMIN
	# Option 2. --privileged
	# Option 3. --device /dev/fuse
	# Setup the bindFS mounts to re-mount with the correct permissions as the 'tanzu' user.
	modprobe fuse || {
		echo "ERROR: Failed to load the 'fuse' kernel module. Did you forget '--cap-add SYS_ADMIN'"
		exit 1
	}
	bindfs \
		--force-user=tanzu \
		--force-group=tanzu \
		--create-for-user=1000 \
		--create-for-group=1000 \
		--chown-ignore \
		--chgrp-ignore \
		/home/tanzu /home/tanzu-bindfs || {
		echo "ERROR: Failed to setup bindFS mount for '/home/tanzu'"
		exit 1
	}

	#CMD_PREFIX="exec sudo -u -H tanzu --"
	#CMD_PREFIX="exec doas --"
	CMD_PREFIX="exec su - tanzu --command"

fi

# If a custom CMD was provided, run that and not the interactive loop.
if [[ $# -gt 0 ]]; then

	${CMD_PREFIX:-} "$@"

else

	${CMD_PREFIX:-} /usr/bin/env bash --login -i

	echo "CRASHED"
	sleep 30

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
				${CMD_PREFIX:-} /usr/bin/env bash --login -i || true

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

	figlet -f slant "Goodbye!"
	exit 0

fi
