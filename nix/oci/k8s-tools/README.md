# Kubernetes Tools

## Table of Contents

- [Kubernetes Tools](#kubernetes-tools)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Variable](#variable)
    - [Common](#common)
    - [Dependencies](#dependencies)
    - [Tanzu CLI](#tanzu-cli)
    - [Tanzu Hacks](#tanzu-hacks)
    - [Tanzu Sites](#tanzu-sites)
  - [Registry Configuration](#registry-configuration)
    - [1. Proxy server](#1-proxy-server)
    - [2. Multi-Site](#2-multi-site)
    - [3. Custom Registry](#3-custom-registry)
    - [4. Pull-through Cache](#4-pull-through-cache)
    - [5. Direct internet](#5-direct-internet)

## Overview

The Kubernetes Tools container image bundles common tooling for working with Kubernetes and Tanzu Kubernetes Grid.

_This version runs the container as `root` and is expected to be used from Docker or Podman in a `rootless` configuration so that the files permissions of root inside the container (id 0) will match the file permissions of the user outside the container (id -u)._

## Variable

### Common

Kubernetes Tools variables.

| Variable                      | Description                                      |     Default      | Example                                                                 |
| :---------------------------- | :----------------------------------------------- | :--------------: | :---------------------------------------------------------------------- |
| LOG_LEVEL                     | The log level                                    |       INFO       | DEBUG, INFO, WARN, ERR                                                  |
| K8S_TOOLS_LAUNCH              | Enable to launch the dialog menu on start        |       TRUE       | TRUE, FALSE                                                             |
| K8S_TOOLS_ENABLE_PROXY_SCRIPT | Enable to run a user-provided `scripts/proxy.sh` |      FALSE       | TRUE, FALSE                                                             |
| K8S_TOOLS_ENABLE_STARSHIP     | Enable the Starship prompt                       |      FALSE       | TRUE, FALSE                                                             |
| K8S_TOOLS_DIALOG_THEME        | Select the theme for dialog menus                |     default      | See the [.dialogrc](nix/oci/tanzu-tools/root/etc/skel/.dialogrc) folder |
| K8S_TOOLS_DISTRO              | Define for distro specific customisations.       |     vanilla      | vanilla, tanzu                                                          |
| K8S_TOOLS_NAME                | A custom name.                                   |    k8s-tools     | k8s-tools, tanzu-tools, carvel-tools                                    |
| K8S_TOOLS_TITLE               | A custom title.                                  | Kubernetes Tools | Tanzu Tools                                                             |

### Dependencies

You can use `vendir` to automatically pull your vendored dependencies during launch.

| VENDOR_ENABLED   | Enable to run 'vendir sync' on launch               |   FALSE    | TRUE, FALSE         |
| VENDOR_DIR       | The location where the vendor folder is created.    |   vendor   | /workdir            |
| VENDOR_CONFIG    | The config file for the vendir CLI                  | vendir.yml | .vendir/config.yaml |
| VENDOR_LOCKED    | A boolean to enable locked vendored dependencies    |   FALSE    | TRUE, FALSE         |

### Tanzu CLI

Tanzu CLI specific variables.

| Variable                       | Description                                 | Default | Example                       |
| :----------------------------- | :------------------------------------------ | :-----: | :---------------------------- |
| TANZU_CLI_PLUGIN_INVENTORY_TAG | The tag for the OCI inventory               | latest  | latest, 2023.11.09            |
| TANZU_CLI_PLUGIN_GROUP_TKG_TAG | The tag for the TKG Carvel Packages         | latest  | latest, v2.20, v2.3.0, v2.3.1 |
| TANZU_CLI_SYMLINK_ENABLED      | Enable to use a multi-env symlink hack.     |  FALSE  | TRUE, FALSE                   |
| TANZU_CLI_SYNC_PLUGINS         | Enable to run 'tanzu plugin sync' on launch |  FALSE  | TRUE, FALSE                   |

### Tanzu Hacks

Tanzu _hack_ specific variables.

| Variable               | Description                                         |  Default   | Example             |
| :--------------------- | :-------------------------------------------------- | :--------: | :------------------ |
| TANZU_PINNIPED_ENABLED | Enable in Pinniped environments to login on startup |   FALSE    | TRUE, FALSE         |

### Tanzu Sites

Multi-Site specific variables for _Tanzu_

| Variable                     | Description                  | Default | Example                |
| :--------------------------- | :--------------------------- | :-----: | :--------------------- |
| TANZU_SITES_ENABLED          | See _Registry Configuration_ |  FALSE  | TRUE, FALSE            |
| TANZU_SITES                  | See _Registry Configuration_ |  Empty  | site_1,site_2,site_3   |
| TANZU_SITE_SITENAME_REGISTRY | See _Registry Configuration_ |  Empty  | harbor.site_a.mydomain |
| TANZU_CUSTOM_REGISTRY        | See _Registry Configuration_ |  Empty  | harbor.mydomain        |
| TANZU_PULL_THROUGH_CACHE     | See _Registry Configuration_ |  Empty  | harbor.dmz             |

## Registry Configuration

There are 5 supported configuration modes in order of precedence. Each mode requires a different set of docker variables described below.

### 1. Proxy server

If you need to configure a proxy server to access the internet, perform this configuration.

- Create a script `scripts/.proxy.sh` that has a function `proxy_on`

```bash
function proxy_on() {

    export HTTP_PROXY=http://proxy.mydomain:3128

    # etcetera...
}
```

- Next, enable the feature flag via docker environment variables.

```bash
K8S_TOOLS_ENABLE_PROXY_SCRIPT=TRUE
```

### 2. Multi-Site

If you have multiple TKG deployments which are connected to different registries this is the configuration you need.

_When enabled, this configuration overrides all those below it._

- First, enable the feature flag to activate the code path.

```bash
TANZU_SITES_ENABLED=TRUE
```

- Next, define the list of sites in a comma-separated docker environment variable.

```bash
# NOTE: This example has dashes in the names...
TANZU_SITES=site-1,site-2
```

- Then, for each site set the variable for the registry like so.

```bash
# NOTE: The variable names must be all in uppercase and any dashes '-' converted to an underscore.

# If you use a pull-through cache
TANZU_SITE_SITE_1_NAME_PULL_THROUGH_CACHE=harbor.site-1.mydomain
TANZU_SITE_SITE_2_NAME_PULL_THROUGH_CACHE=harbor.site-2.mydomain

# Or, if you use isolated cluster mode
TANZU_SITE_SITE_1_NAME_REGISTRY=harbor.site-1.mydomain
TANZU_SITE_SITE_2_NAME_REGISTRY=harbor.site-2.mydomain
```

- When launching the container, you will be asked in a dialog screen which site you are going to administer.

### 3. Custom Registry

If you have a single Container Registry for use across all TKG deployments, use this configuration.

_When enabled, this configuration overrides all those below it._

- Provide your custom Container Registry

```bash
TANZU_CUSTOM_REGISTRY=harbor.mydomain
```

### 4. Pull-through Cache

If you have internet connectivity in the environment and use a global pull-through cache, use this configuration.

_When enabled, this configuration overrides all those below it._

- Provide your pull-through cache which is prefixed to all OCI URLs.

```bash
TANZU_PULL_THROUGH_CACHE=harbor.dmz.mydomain
```

### 5. Direct internet

If you have a direct internet connection then simply set none of these variables which is the default option.
