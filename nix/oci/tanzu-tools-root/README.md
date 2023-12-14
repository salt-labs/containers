# Tanzu Tools

## Table of Contents

- [Tanzu Tools](#tanzu-tools)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Variables](#variables)
  - [Registry Configuration](#registry-configuration)
    - [1. Proxy server](#1-proxy-server)
    - [2. Multi-Site](#2-multi-site)
    - [3. Custom Registry](#3-custom-registry)
    - [4. Pull-through Cache](#4-pull-through-cache)
    - [5. Direct internet](#5-direct-internet)

## Overview

The Tanzu Tools container image bundles common tooling for working with Tanzu Kubernetes Grid.

_This version runs the container as `root` and is expected to be used from Docker or Podman in a `rootless` configuration so that the files permissions of root inside the container (id 0) will match the file permissions of the user outside the container (id -u)._

## Variables

| Variable                             | Description                                                                             | Default | Example                                                                 |
| :----------------------------------- | :-------------------------------------------------------------------------------------- | :-----: | :---------------------------------------------------------------------- |
| LOG_LEVEL                            | The log level                                                                           |  INFO   | DEBUG, INFO, WARN, ERR                                                  |
| TANZU_TOOLS_LAUNCH                   | Enable to launch the dialog menu on start                                               |  TRUE   | TRUE, FALSE                                                             |
| TANZU_TOOLS_ENABLE_PROXY_SCRIPT      | Enable to run a user-provided `scripts/proxy.sh`                                        |  FALSE  | TRUE, FALSE                                                             |
| TANZU_TOOLS_ENABLE_STARSHIP          | Enable the Starship prompt                                                              |  FALSE  | TRUE, FALSE                                                             |
| TANZU_TOOLS_DIALOG_THEME             | Select the theme for dialog menus                                                       | default | See the [.dialogrc](nix/oci/tanzu-tools/root/etc/skel/.dialogrc) folder |
| TANZU_TOOLS_SYNC_YTT_LIB             | **DEPRECATED:** Enable to sync the user ytt library into the TKG 04_user_customizations |  FALSE  | TRUE, FALSE                                                             |
| TANZU_TOOLS_CLI_PLUGIN_INVENTORY_TAG | The tag for the OCI inventory                                                           | latest  | latest, 2023.11.09                                                      |
| TANZU_TOOLS_CLI_PLUGIN_GROUP_TKG_TAG | The tag for the TKG Carvel Packages                                                     | latest  | latest, v2.20, v2.3.0, v2.3.1                                           |
| TANZU_TOOLS_SITES_ENABLED            | See _Registry Configuration_                                                            |  FALSE  | TRUE, FALSE                                                             |
| TANZU_TOOLS_SITES                    | See _Registry Configuration_                                                            |  Empty  | site_1,site_2,site_3                                                    |
| TANZU_TOOLS_SITE_SITE_NAME_REGISTRY  | See _Registry Configuration_                                                            |  Empty  | harbor.site_a.mydomain                                                  |
| TANZU_TOOLS_CUSTOM_REGISTRY          | See _Registry Configuration_                                                            |  Empty  | harbor.mydomain                                                         |
| TANZU_TOOLS_PULL_THROUGH_CACHE       | See _Registry Configuration_                                                            |  Empty  | harbor.dmz                                                              |

## Registry Configuration

There are 5 supported configuration modes in order of precedence. Each mode requires a different set of docker variables described below.

### 1. Proxy server

If you need to configure a proxy server, perform this configuration.

- Create a script `scripts/.proxy.sh` that has a function `proxy_on`

```bash
function proxy_on() {

    export HTTP_PROXY=http://proxy.mydomain:3128

    # etcetera...
}
```

- Next, enable the feature flag via docker environment variables.

```bash
TANZU_TOOLS_ENABLE_PROXY_SCRIPT=TRUE
```

### 2. Multi-Site

If you have multiple TKG deployments which are connected to different registries this is the configuration you need.

_When enabled, this configuration overrides all those below it._

- First, enable the feature flag to activate the code path.

```bash
TANZU_TOOLS_SITES_ENABLED=TRUE
```

- Next, define the list of sites in a comma-separated docker environment variable.

```bash
# NOTE: This example has dashes in the names...
TANZU_TOOLS_SITES=site-1,site-2
```

- Then, for each site set the variable for the registry like so.

```bash
# NOTE: The variable names must be all in uppercase and any dashes '-' converted to an underscore.
TANZU_TOOLS_SITE_SITE_1_NAME_REGISTRY=harbor.site-1.mydomain
TANZU_TOOLS_SITE_SITE_2_NAME_REGISTRY=harbor.site-2.mydomain
```

- When launching the container, you will be asked in a dialog screen which site you are going to administer.

### 3. Custom Registry

If you have a single Container Registry for use across all TKG deployments, use this configuration.

_When enabled, this configuration overrides all those below it._

- Provide your custom Container Registry

```bash
TANZU_TOOLS_CUSTOM_REGISTRY=harbor.mydomain
```

### 4. Pull-through Cache

If you have internet connectivity in the environment and use a pull-through cache, use this configuration.

_When enabled, this configuration overrides all those below it._

- Provide your pull-through cache which is prefixed to all OCI URLs.

```bash
TANZU_TOOLS_PULL_THROUGH_CACHE=harbor.dmz.mydomain
```

### 5. Direct internet

If you have a direct internet connection then simply set none of these variables which is the default option.
