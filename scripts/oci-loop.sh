#!/usr/bin/env bash

# Name: oci-loop.sh
# Description: Small inner-loop for building OCI images.

clear

set -euo pipefail

if [[ "${1:-EMPTY}" == "EMPTY" ]];
then
    echo "Provide the OCI image name as \$1"
    exit 1
else
    OCI_NAME=$1
fi

if type podman > /dev/null 2>&1;
then
    TOOL=podman
elif type docker > /dev/null 2?&1;
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
    --json \
    | jq '.[0].outputs.out' || {
        echo "Failed to build OCI image"
        exit 1
    }

"${TOOL}" load < result || {
    echo "Failed to load OCI image"
    exit 1
}

"${TOOL}" run \
    -it \
    --rm \
    --name temp \
    --cap-add=sys_admin,sys_ptrace,mknod \
    --security-opt label=disable \
    --device /dev/fuse \
    localhost/"${OCI_NAME}:latest"
