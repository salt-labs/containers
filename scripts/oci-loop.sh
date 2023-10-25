#!/usr/bin/env bash

# Name: oci-loop.sh
# Description: Small inner-loop for building OCI images.

clear

set -euo pipefail

if [[ ${1:-EMPTY} == "EMPTY" ]]; then
	echo "Defaulting to docker"
    OCI_TOOL="docker"
else
	OCI_TOOL=$1
fi

if [[ ${2:-EMPTY} == "EMPTY" ]]; then
	echo 'Provide the OCI image name as parameter #2'
	exit 1
else
	OCI_NAME=$2
fi

if ! type "${OCI_TOOL}" > /dev/null 2>&1;
then
    echo "Unable to find container tool ${OCI_TOOL}"
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

"${OCI_TOOL}" load <result || {
	echo "Failed to load OCI image"
	exit 1
}

case "${OCI_TOOL}" in

    "docker" )

        "${OCI_TOOL}" \
            --log-level=info \
            run \
            -it \
            --rm \
            --name "test-${OCI_NAME}" \
            --privileged \
            --security-opt label=disable \
            --security-opt apparmor=unconfined \
            --security-opt seccomp=unconfined \
            --device /dev/fuse \
            --mount type=bind,source="${XDG_RUNTIME_DIR}/docker.sock",target="/var/run/docker.sock" \
            "${OCI_NAME}:latest"
            #--user root \
            #"${OCI_NAME}:latest" \
            #/bin/bash

    ;;

    "podman" )

        "${OCI_TOOL}" \
        --log-level=info \
        run \
        -it \
        --rm \
        --name "test-${OCI_NAME}" \
        --privileged \
        --security-opt label=disable \
        --security-opt apparmor=unconfined \
        --security-opt seccomp=unconfined \
        --device /dev/fuse \
        --mount type=bind,source="${XDG_RUNTIME_DIR}/podman/podman.sock",target="/var/run/docker.sock,relabel=shared,U=true" \
        localhost/"${OCI_NAME}:latest"

    ;;

esac
 
# Scratch
#    --mount type=bind,source="${XDG_RUNTIME_DIR}/podman/podman.sock",target="/run/podman/podman.sock" \
#
#   --tmpfs /tmp \
#   --tmpfs /run \
#    -v "/run/user/$(id -u)":/run \
#    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
#	localhost/"${OCI_NAME}:latest"
# podman --remote run busybox echo hi
#
# podman run \
#   --security-opt label=disable \
#   --rm \
#   -ti \
#   -v $XDG_RUNTIME_DIR/podman/podman.sock:/var/run/docker.sock:z \
#   docker.io/library/docker run -ti --rm hello-world
#
#

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
