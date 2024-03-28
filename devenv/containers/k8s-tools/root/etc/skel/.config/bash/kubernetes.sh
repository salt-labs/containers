#! /usr/bin/env bash

function k8s_get_cert() {

	# Reads the certifcate from the server in base64
	# format for Kubernetes without having to remember
	# the OpenSSL flags.

	local SERVER="$1"
	local REGEX='^[A-Za-z0-9_-]+:[0-9]+$'

	if [[ ${SERVER:-EMPTY} == "EMPTY" ]]; then

		writeLog "ERROR" "Please provide a SERVER:PORT as argument 1"
		return 1

	elif [[ ! ${SERVER} =~ ${REGEX} ]]; then

		writeLog "ERROR" "Please provide the server and port in the format SERVER:PORT"
		return 1

	fi

	openssl storeutl -certs <(openssl s_client -connect "${SERVER}" -showcerts) || {

		writeLog "ERROR" "Failed to read the certificate from ${SERVER}"
		return 1

	}

	return 0

}
