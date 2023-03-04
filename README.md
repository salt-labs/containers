# DevSecOps

## Overview

A collection of small container images used for CI tooling.

**NOTE:** In order to use in vRealise Aria, Codestream requires that each container has at least the following available;

    - Shell (bash, sh, etc.)
    - curl or wget

This is in order for the container to be able to download and run the codestream agent binary on each launch to communicate back with vRA.

## Builds

![Nix Container](https://img.shields.io/github/actions/workflow/status/salt-labs/devsecops/nix-container.yaml?branch=trunk&label=nix-container&style=for-the-badge)

## Containers

The currently included containers are as follows:

| Container                                                                  | What's included                      | Entrypoint | Image                                             |
| :--------------------------------------------------------------------------: | :------------------------------------ | :---------- | :------------------------------------------------- |
| [ci](https://github.com/salt-labs/devsecops/pkgs/container/devsecops%2Fci) | bash, curl, git, jq, unzip, wget, yq | bash       | `docker pull ghcr.io/salt-labs/devsecops/ci:latest` |
| [trivy](https:?/github.com/salt-labs/devsecops/pkgs/container/devsecops%2Ftrivy) | trivy | trivy | `docker pull ghcr.io/salt-labs/devsecops/trivy:latest` |

## Tags

The following tags are available for each container:

| Tag | Description |
| :--: | :----------- |
| latest | The latest development release of the container. These come direct from PRs. |
|
