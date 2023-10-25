#!/usr/bin/env bash

# Name: oci-loop.sh
# Description: Small inner-loop for building OCI images.

clear

set -euo pipefail

if [[ ${1:-EMPTY} == "EMPTY" ]]; then
	echo 'Provide the OCI image name as $1'
	exit 1
else
	OCI_NAME=$1
fi

if type podman >/dev/null 2>&1; then
	TOOL=podman
elif
	type docker 2? >/dev/null &
	1
then
	TOOL=docker
else
	echo "No supported container tool found!"
	exit 1
fi

git add --all || {
	echo "Failed to stage git files"
	exit 1
}

nix build \
	--impure \
	.#packages.\"x86_64-linux.x86_64-linux\"."${OCI_NAME}" \
	--json |
	jq '.[0].outputs.out' || {
	echo "Failed to build OCI image"
	exit 1
}

"${TOOL}" load <result || {
	echo "Failed to load OCI image"
	exit 1
}

"${TOOL}" run \
	-it \
	--rm \
	--name temp \
    --privileged \
    --security-opt label=disable \
    --security-opt apparmor=unconfined \
    --security-opt seccomp=unconfined \
	localhost/"${OCI_NAME}:latest"

# Troubleshooting

# Test with SELinux disabled
# --security-opt label=disable

# Test with AppArmor disabled
# --security-opt apparmor=unconfined

# Test with unrestricted syscalls
# --security-opt seccomp=unconfined

# Test with unmasked filesystems
# --security-opt unmask=all

# Test with network namespace isolation disabled
# --net=host

# Test with PID and IPC namespace isolation disabled
# --pid=host --ipc=host

# Test with passing in required devices
# --device /dev/fuse

# Test with just certain capabilities
# SYSADMIN, SYS_PTRACE, MKNOD, NET_BIND_SERVICE, NET_BROADCAST, NET_ADMIN, NET_RAW, CAP_IPC_LOCK
# --cap-add=sys_admin,sys_ptrace,mknod

# Test with full privs
# --privileged

# And finally, try with root
# sudo podman ...
