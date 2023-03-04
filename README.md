# DevSecOps

## Overview

A collection of small container images used for CI tooling.

**NOTE:** In order for use in vRealise Aria, Codestream requires that each container has at least the following available;

    - Shell (bash, sh, etc.)
    - curl or wget

This is in order for the container to be able to download and run the codestream agent binary on each launch to communicate back with vRA.

## Builds

![Containers](https://img.shields.io/github/actions/workflow/status/salt-labs/containers/nix-container.yml?label=Containers&style=for-the-badge)

## Tags

The following tags are available for each container:

| Tag | Description |
| :--: | :----------- |
| latest | The latest development release of the container. These come direct from PRs. |
| calver | A calendar versioned release of the container. These are released automatically when PRs are merged. |
