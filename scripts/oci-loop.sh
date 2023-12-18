#!/usr/bin/env bash

# Name: oci-loop.sh
# Description: Small inner-loop for building OCI images.

clear

set -euo pipefail

# Allow users to override docker vs podman.
OCI_TOOL="${OCI_TOOL:-docker}"

# Docker args --env-file
declare DOCKER_ENV_FILES=()

#########################
# Functions
#########################

function troubleshooting_tips() {

	cat <<-EOF

		Troubleshooting Tips

		Here are some troubleshooting tips to try modifying the script with.

		# Test with SELinux disabled
		--security-opt label=disable

		# Test with AppArmor disabled
		--security-opt apparmor=unconfined

		# Test with unrestricted syscalls
		--security-opt seccomp=unconfined

		# Test with unmasked filesystems
		--security-opt unmask=all

		# Test with network namespace isolation disabled
		--net=host

		# Test with PID and IPC namespace isolation disabled
		--pid=host --ipc=host

		# Test with passing in required devices
		--device /dev/fuse

		# Test with just certain capabilities like; SYSADMIN, SYS_PTRACE, MKNOD, NET_BIND_SERVICE, NET_BROADCAST, NET_ADMIN, NET_RAW, CAP_IPC_LOCK
		--cap-add=sys_admin,sys_ptrace,mknod

		# Test with full privs
		--privileged

		# And finally, try with root
		sudo podman ...
	EOF

	return 0

}

#########################
# Pre-flight checks
#########################

if [[ ${1:-EMPTY} == "EMPTY" ]]; then
	echo 'Provide the OCI image name as parameter #1'
	exit 1
else
	OCI_NAME=$1
fi

if ! type "${OCI_TOOL}" >/dev/null 2>&1; then
	echo "Unable to find container tool ${OCI_TOOL}"
	exit 1
fi

#########################
# Main
#########################

# Stage the files so Nix picks up the changes.
git add --all || {
	echo "Failed to stage git files"
	exit 1
}

# Build the container image
nix build \
	--impure \
	.#packages.\"x86_64-linux.x86_64-linux\"."${OCI_NAME}" \
	--json |
	jq '.[0].outputs.out' || {
	echo "Failed to build OCI image"
	exit 1
}

# Load the result into the local container image store.
"${OCI_TOOL}" load <result || {
	echo "Failed to load OCI image"
	exit 1
}

# Add extra .env variables if present.
if [[ -f .env ]]; then
	DOCKER_ENV_FILES+=("--env-file .env")
fi

# Test it with the flags that suit the tool.
case "${OCI_TOOL}" in

"docker")

	# shellcheck disable=SC2068
	"${OCI_TOOL}" \
		--log-level=info \
		container \
		run \
		-it \
		--rm \
		--name "test-${OCI_NAME}" \
		${DOCKER_ENV_FILES[@]-} \
		--privileged \
		--security-opt label=disable \
		--security-opt apparmor=unconfined \
		--security-opt seccomp=unconfined \
		--device /dev/fuse \
		--mount "type=bind,source=${XDG_RUNTIME_DIR}/docker.sock,target=/var/run/docker.sock" \
		"${OCI_NAME}:latest" || RESULT=1

	;;

"podman")

	# shellcheck disable=SC2068
	"${OCI_TOOL}" \
		--log-level=info \
		container \
		run \
		-it \
		--rm \
		--name "test-${OCI_NAME}" \
		${DOCKER_ENV_FILES[@]-} \
		--privileged \
		--security-opt label=disable \
		--security-opt apparmor=unconfined \
		--security-opt seccomp=unconfined \
		--device /dev/fuse \
		--mount "type=bind,source=${XDG_RUNTIME_DIR}/podman/podman.sock,target=/var/run/docker.sock,relabel=shared,U=true" \
		localhost/"${OCI_NAME}:latest" || RESULT=1

	;;

esac

if [[ ${RESULT:-0} -ne 0 ]]; then

	echo "Testing ${OCI_NAME} has failed!"

	troubleshooting_tips

	exit 1

fi

exit 0
