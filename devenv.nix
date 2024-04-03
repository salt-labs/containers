###############
# Devenv
#
# Reference: https://devenv.sh/reference/options/
###############
{pkgs, lib, config, ...}: {

  ###############
  # Environment - https://devenv.sh/basics/
  ###############

  env = {
    PROJECT_SHELL = "devenv";
    HUNSPELL_CONFIG = ".linters/config/hunspell.conf";
    PRETTIER_CONFIG = ".linters/config/.prettierrc.yaml";
    YAMLLINT_CONFIG_FILE = ".linters/config/.yamllint.yml";
  };

  dotenv = {
    enable = false;
    filename = ".env";
    disableHint = false;
  };

  ################
  # Devenv
  ################

  devenv = {
    warnOnNewVersion = true;
  };

  ###############
  # Cachix
  ###############

  cachix = {
    pull = [
      "pre-commit-hooks"
      "salt-labs"
    ];
    push = [
      "salt-labs"
    ];
  };

  ###############
  # Packages - https://devenv.sh/packages/
  ###############

  packages = with pkgs; [
    figlet
    git
    hello
  ];

  ###############
  # Scripts - https://devenv.sh/scripts/
  ###############

  enterShell = "";

  scripts.welcome.exec = ''
    #!/usr/bin/env bash

    figlet ''${PROJECT_SHELL}

    echo "Hello $USER, welcome to ''${PROJECT_SHELL}"
  '';

  ###############
  # git -  https://devenv.sh/pre-commit-hooks/
  ###############

  difftastic = {
    enable = false;
  };

  pre-commit = {
    default_stages = ["commit"];

    excludes = ["README.md"];

    hooks = {
      # Nix
      alejandra.enable = false;
      nixfmt.enable = false;
      nixpkgs-fmt.enable = false;
      deadnix.enable = false;
      statix.enable = false;

      # GitHub Actions
      actionlint.enable = false;

      # Ansible
      ansible-lint.enable = false;

      # Python
      autoflake.enable = false;
      black.enable = false;
      flake8.enable = false;
      pylint.enable = false;
      ruff.enable = false;

      # Bash
      bats.enable = false;
      shellcheck.enable = false;
      shfmt.enable = false;

      # Rust
      cargo-check.enable = false;
      clippy.enable = false;
      rustfmt.enable = false;

      # Go
      gofmt.enable = false;
      gotest.enable = false;
      govet.enable = false;
      revive.enable = false;
      staticcheck.enable = false;

      # Spelling
      hunspell.enable = false;
      typos = {
        enable = false;
        settings = {
          format = "long";
          diff = true;
          write = false;
        };
      };

      # Git commit messages
      commitizen.enable = false;

      # Docker
      hadolint.enable = false;

      # Dhall
      dhall-format.enable = false;

      # Markdown
      markdownlint = {
        enable = false;
      #  settings = {
      #    config = {
      #      # No hard tabs allowed.
      #      no-hard-tabs = true;

      #      # Unordered list intendation.
      #      MD007 = {
      #        indent = 2;
      #      };

      #      # Training spaces
      #      MD009 = {
      #        br_spaces = 2;
      #      };

      #      # Line length
      #      MD013 = false;

      #      # Inline HTML
      #      MD033 = false;

      #      # List marker spaces.
      #      # Disabled for use with prettier.
      #      MD030 = false;
      #    };
      #  };
      };
      mdsh.enable = false;

      # Common
      prettier = {
        enable = false;
        settings = {
          check = true;
          list-different = false;
          write = true;
        };
      };

      # YAML
      yamllint = {
        enable = false;
        settings = {
          configPath = ".linters/config/.yamllint.yml";
        };
      };

      # Terraform
      terraform-format.enable = false;

      # Haskell
      hlint.enable = false;
    };

    settings = {
      markdownlint = {
        config = {

          # No hard tabs allowed.
          no-hard-tabs = true;

          # Unordered list intendation.
          MD007 = {
            indent = 2;
          };

          # Training spaces
          MD009 = {
            br_spaces = 2;
          };

          # Line length
          MD013 = {
            line_length = 120;
          };

          # List marker spaces.
          # Disabled for use with prettier.
          MD030 = false;

          # Inline HTML
          MD033 = false;

          # Bare URLs
          MD034 = false;
        };
      };
    };
  };

  ###############
  # Languages - https://devenv.sh/languages/
  ###############

  languages = {

    cue = {
      enable = false;
      package = pkgs.cue;
    };

    gawk = {enable = false;};

    go = {
      enable = false;
      package = pkgs.go;
    };

    nix = {enable = false;};

    python = {
      enable = false;
      package = pkgs.python3;

      poetry = {
        enable = false;
        package = pkgs.poetry;
      };

      venv = {enable = true;};
    };

    rust = {
      enable = false;
      channel = "stable";
    };

    terraform = {
      enable = false;
      package = pkgs.terraform;
    };
  };

  ###############
  # Processes - https://devenv.sh/processes/
  ###############

  # https://devenv.sh/processes/
  # processes.ping.exec = "ping example.com";\

  ###############
  # Services
  ###############

  ###############
  # Shell
  ###############

  starship = {
    enable = true;
    package = pkgs.starship;
    config = {
      enable = true;
      path = "/home/$USER/.config/starship.toml";
    };
  };

  ################
  # Containers
  ################

  container = {
    isBuilding = false;
  };

  ###############
  # Devcontainer - https://devenv.sh/integrations/codespaces-devcontainer/
  ###############

  devcontainer = {
    enable = true;

    settings = {
      customizations = {
        vscode = {
          extensions = [
            "exiasr.hadolint"
            "nhoizey.gremlins"
            "esbenp.prettier-vscode"
            "github.copilot"
            "github.vscode-github-actions"
            "kamadorueda.alejandra"
            "ms-azuretools.vscode-docker"
            "pinage404.nix-extension-pack"
            "redhat.vscode-yaml"
            "timonwong.shellcheck"
            "tuxtina.json2yaml"
            "vscodevim.vim"
            "wakatime.vscode-wakatime"
          ];
        };
      };
    };
  };

  ###############
  # Tests - https://devenv.sh/tests/
  ###############

  enterTest = ''
    echo "Running tests..."
  '';

}
