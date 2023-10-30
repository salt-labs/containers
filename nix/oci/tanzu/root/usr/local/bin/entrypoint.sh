#!/usr/bin/env bash

export ENTRYPOINT_EXECUTED="TRUE"

if [[ ${ENABLE_DEBUG:-FALSE} == "TRUE" ]]; then
	set -x
fi

# Make sure that the interactive parts are not run in a a VSCode container env.
# VSCode handles it's own userID mapping and mounts.
if [[ ${ENVIRONMENT_VSCODE^^} == "CONTAINER" ]]; then

	while true; do
		echo "$(date '+%Y/%m/%d %T'): INFO: Devcontainer environment is running..."
		sleep 300
	done

	exit 0

fi

function start_shell() {

	# If a custom CMD was provided, run that and not the interactive shell.
	if [[ $# -gt 0 ]]; then

		exec sudo --user=tanzu --set-home --preserve-env -- "$@" || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to start shell for user 'tanzu'" | tee -a "/tmp/environment.log"
			return 1
		}

	elif [[ ${UID} -eq 0 ]]; then

		exec sudo --user=tanzu --set-home --preserve-env -- bash --login -i || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to start shell for user 'tanzu'" | tee -a "/tmp/environment.log"
			return 1
		}

	else

		exec sudo --user=tanzu --set-home --preserve-env -- bash --login -i || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to start shell for user 'tanzu'" | tee -a "/tmp/environment.log"
			return 1
		}

	fi

	return 0

}

# Make sure the wrappers are the first in the PATH
if [[ -d "/run/wrappers/bin" ]]; then
	if ! grep "/run/wrappers/bin" <<<"${PATH}"; then
		export PATH=/run/wrappers/bin:$PATH
	fi
fi

# If running as root, setup the 'tanzu' user to match host user.
# https://www.joyfulbikeshedding.com/blog/2021-03-15-docker-and-the-host-filesystem-owner-matching-problem.html
if [[ ${UID} -eq 0 ]]; then

	# Make tmp shared between all users.
	chmod 1777 /tmp || {
		echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to set permissions on '/tmp'" | tee -a "/tmp/environment.log"
		exit 1
	}

	# Make sure there is a shared log file.
	if [[ ! -f "/tmp/environment.log" ]]; then
		touch /tmp/environment.log || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to create log file '/tmp/environment.log' A writeable /tmp is required!"
			exit 1
		}
	fi

	# Always ensure the environment log is all users writable.
	chmod 777 /tmp/environment.log || {
		echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to set permissions on '/tmp/environment.log'"
		exit 1
	}

	# If a HOST_UID and HOST_GID is provided, do the janky permissions setup...
	if [[ ${HOST_UID:-EMPTY} == "EMPTY" ]] || [[ ${HOST_GID:-EMPTY} == "EMPTY" ]]; then

		echo "$(date '+%Y/%m/%d %T'): ERROR: This container requires you to pass the '\${HOST_UID}' and '\${HOST_GID}' variables" | tee -a "/tmp/environment.log"
		exit 1

	fi

	# Add the Tanzu group using the provided GID
	groupadd \
		tanzu \
		--gid "${HOST_GID}" ||
		{
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to create 'tanzu' group with GID '${HOST_GID}'" | tee -a "/tmp/environment.log"
			exit 1
		}

	# Add the Tanzu user using the provided UID
	useradd \
		--uid "${HOST_UID}" \
		--gid "${HOST_GID}" \
		--comment "Tanzu CLI" \
		--home /home/tanzu \
		--shell /bin/bash \
		--groups tanzu,docker \
		--no-user-group \
		--no-create-home \
		tanzu ||
		{
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to create 'tanzu' user with UID '${HOST_UID}'" | tee -a "/tmp/environment.log"
			exit 1
		}

	# Create an in initial home from the template if it doesn't exist.
	if [[ ! -f "/home/tanzu/.profile" ]]; then

		rsync -a /etc/skel/ /home/tanzu --copy-links || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to copy profile template for user 'tanzu'" | tee -a "/tmp/environment.log"
			exit 1
		}

		# Ensure the permissions are correct
		chown --recursive tanzu:tanzu /home/tanzu || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to reset permissions for user 'tanzu'" | tee -a "/tmp/environment.log"
			exit 1
		}

		chmod --recursive 0751 /home/tanzu || {
			echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to reset permissions for user 'tanzu'" | tee -a "/tmp/environment.log"
			exit 1
		}

	else

		echo "$(date '+%Y/%m/%d %T'): INFO: A profile already exists for user 'tanzu'" | tee -a "/tmp/environment.log"

	fi

	# If the docker socket was mounted, make sure the user can access it.
	DOCKER_GROUP_ID=$(getent group docker | cut -d: -f3)
	if [[ -S /var/run/docker.sock ]]; then

		DOCKER_SOCKET_ID=$(stat -c '%g' /var/run/docker.sock)

		# If the docker socket group id does not match the docker group id, change the group id.
		if [[ ${DOCKER_GROUP_ID} -ne ${DOCKER_SOCKET_ID} ]]; then

			echo "$(date '+%Y/%m/%d %T'): INFO: Updating docker socket group id to '${DOCKER_SOCKET_ID}'" | tee -a "/tmp/environment.log"

			groupmod --gid "${DOCKER_SOCKET_ID}" docker || {
				echo "$(date '+%Y/%m/%d %T'): ERROR: Failed to set 'docker' group GID to '${DOCKER_SOCKET_ID}'" | tee -a "/tmp/environment.log"
				exit 1
			}

		fi

		echo "$(date '+%Y/%m/%d %T'): INFO: Setting up Sub IDs and GIDs for 'tanzu'" | tee -a "/tmp/environment.log"
		echo "tanzu:3000000000:65535" >/etc/subuid || exit 1
		echo "tanzu:3000000000:65535" >/etc/subgid || exit 1
		chmod 0644 /etc/subuid /etc/subgid || exit 1

	fi

fi

# Perform group and user check
grpck || {
	echo "$(date '+%Y/%m/%d %T'): ERROR: Group check failed. Please check the contents of /etc/group." | tee -a "/tmp/environment.log"
	exit 1
}
pwck || {
	echo "$(date '+%Y/%m/%d %T'): ERROR: User check failed. Please check the contents of /etc/passwd." | tee -a "/tmp/environment.log"
	exit 1
}

# Start a new login shell with any modified UID or GIDs applied.
start_shell "$@" || true

# Start a fresh shell session.
SHELL_COUNTER=0
while true; do

	((SHELL_COUNTER = SHELL_COUNTER + 1))
	if [[ ${SHELL_COUNTER} -ge 3 ]]; then
		printf "\n"
		echo "It seems that today is not your day, why not take a break?"
		sleep 3
	fi

	# If bash exits, ask if we should restart or break and exit.
	printf "\n"
	echo "Your current shell session in this container has ended"

	if [[ -f "/tmp/environment.log" ]]; then
		printf "\n"
		echo "Displaying session logs"
		cat "/tmp/environment.log"
	fi

	printf "\n"
	read -r -p "Would you like to start a new shell session? y/n: " CHOICE

	clear

	case $CHOICE in

	[Yy]*)

		echo "Restarting shell..."
		start_shell "$@" || true

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
