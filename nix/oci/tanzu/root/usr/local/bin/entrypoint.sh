#! /usr/bin/env bash

clear

# Launch an interactive shell session.
/bin/bash -i

while true; do

	clear

	# If bash exits, ask if we should restart or break and exit.
	echo -e "\n"
	echo "Your current shell session in this container has terminated."
	read -r -p "Start a new shell session? y/n: " CHOICE

	case $CHOICE in

	[Yy]*)

		echo "Restarting shell..."

		# Launch an interactive shell session.
		/bin/bash -i

		;;

	[Nn]*)

		echo "Exiting..."
		break

		;;

	*)

		echo "Please answer yes or no."
		sleep 3

		;;

	esac

done

clear
figlet "Goodbye!"

exit 0
