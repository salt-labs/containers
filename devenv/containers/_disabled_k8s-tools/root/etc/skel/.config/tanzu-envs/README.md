# Tanzu Environments

In configurations with multiple environments from the same codebase, it might be desirable to have different configuration paths that use an entirely different folder tree, for times when the versions of TKG are way out of sync or plugins don't match.

At present, there isn't a `TANZU_CLI_HOME` variable or anyway I can determine to make this easier so this is a quick hack to solve for this use case.

For additional info, see the [GitHub issue #620](https://github.com/vmware-tanzu/tanzu-cli/issues/620)

## Usage

1. Enable the feature flag by passing the following environment variable into the container.

    ```bash
    TANZU_CLI_SYMLINK_ENABLED=TRUE
    ```

1. In your bind directory, create a folder with your environment name

    ```bash
    mkdir -p tanzu-cli/home/.config/tanzu-env/MY_ENVIRONMENT
    ```

1. Set the environment variable name and pass to the container to match the folder and launch the container

    ```bash
    TANZU_CLI_ENVIRONMENT=MY_ENVIRONMENT

    docker run <other flags> --env "TANZU_CLI_ENVIRONMENT=${TANZU_CLI_ENVIRONMENT}"
    ```

    **NOTE:** _If no variable is set, an environment name of "default" is assumed._
