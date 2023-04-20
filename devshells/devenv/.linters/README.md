# linters

## Overview

Linter configuration files for use as a git submodule

## Usage

Add this repository as a submodule to your project:

```bash
# For HTTPS
git submodule add https://github.com/salt-labs/linters .linters

# For SSH
git submodule add git@github.com:salt-labs/linters.git .linters
```

Then, point your linters to the configuration files in the `config` directory.

- If you wish to update to the latest changes

```bash
git submodule update --init --remote

# Stage, commit, push and merge the changes.
```
