#!/usr/bin/env bash

if [[ ${ENABLE_DEBUG:-FALSE} == "TRUE" ]]; then
	set -x
fi

# Start a fresh shell session.
/usr/bin/env bash --login -i || true

# Make sure that the interactive parts are not run in a a VSCode remote env.
if [[ "${ENVIRONMENT_VSCODE^^}" == "REMOTE" ]]; then

	echo "$(date '+%Y/%m/%d %T'): INFO: VSCode remote environment detected, skipping interactive parts." | tee -a "/tmp/vscode-remote-env.log"

else

	while true; do

		clear

		# If bash exits, ask if we should restart or break and exit.
		printf "\n"
		echo "Your current shell session in this container has terminated."
		read -r -p "Start a new shell session? y/n: " CHOICE

		case $CHOICE in

			[Yy]*)

				echo "Restarting shell..."
				/usr/bin/env bash --login -i || true

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
