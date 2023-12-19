# Tanzu Environments

In configurations with multiple environments from the same codebase, it might be desirable to have different configuration paths for different reasons.

At present, there isn't a `TANZU_CLI_HOME` variable or anyway I can determine to make this easier so this is a quick hack.

Reference; https://github.com/vmware-tanzu/tanzu-cli/issues/620

## Usage

1. Create a folder with your environment name

```bash
mkdir -p ~/.config/tanzu-env/MY_ENVIRONMENT
```

2. Set the environment variable and launch the container

```bash
TANZU_TOOLS_ENVIRONMENT=MY_ENVIRONMENT
```

If no variable is set, a "default" folder is symlinked as the default environment.
