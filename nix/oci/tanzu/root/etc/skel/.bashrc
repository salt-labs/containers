#!/usr/bin/env bash

if [[ -f "/etc/profile" ]]; then

	echo "Loading global shell profile..."
	. "/etc/profile"

fi

if [[ -n ${BASH_VERSION} ]]; then

	if [[ -f "${HOME}/.profile" ]]; then

		echo "Loading user shell profile..."
		. "${HOME}/.profile"

	fi

	# shellcheck disable=SC1090
	source <(/bin/starship init bash --print-full-init)

fi
