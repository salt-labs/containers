###############
# Devenv
#
# Reference: https://devenv.sh/reference/options/
###############
{pkgs, ...}: {
  ###############
  # Environment - https://devenv.sh/basics/
  ###############

  env = {
    GREET = "devenv";
    HUNSPELL_CONFIG = ".linters/config/hunspell.conf";
    PRETTIER_CONFIG = ".linters/config/.prettierrc.yaml";
    YAMLLINT_CONFIG_FILE = ".linters/config/.yamllint.yml";
  };

  dotenv = {
    enable = true;
    filename = ".env";
    disableHint = false;
  };

  unsetEnvVars = [
    "HOST_PATH"
    "NIX_BUILD_CORES"
    "__structuredAttrs"
    "buildInputs"
    "buildPhase"
    "builder"
    "depsBuildBuild"
    "depsBuildBuildPropagated"
    "depsBuildTarget"
    "depsBuildTargetPropagated"
    "depsHostHost"
    "depsHostHostPropagated"
    "depsTargetTarget"
    "depsTargetTargetPropagated"
    "doCheck"
    "doInstallCheck"
    "nativeBuildInputs"
    "out"
    "outputs"
    "patches"
    "phases"
    "preferLocalBuild"
    "propagatedBuildInputs"
    "propagatedNativeBuildInputs"
    "shell"
    "shellHook"
    "stdenv"
    "strictDeps"
  ];

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
    hello
    figlet
  ];

  ###############
  # Scripts - https://devenv.sh/scripts/
  ###############

  scripts.hello.exec = "echo hello from $GREET";

  enterShell = ''
    figlet ''${PROJECT_SHELL:-Unknown}

    hello \
      --greeting \
      "
      Welcome ''${USER}!

      Project: ''${PROJECT_NAME:-Unknown}
      Shell: ''${PROJECT_SHELL:-Unknown}
      Directory: ''${PROJECT_DIR:-Unknown}
  '';

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
  # git
  ###############

  difftastic = {
    enable = true;
  };

  ###############
  # Hooks - https://devenv.sh/pre-commit-hooks/
  ###############

  pre-commit = {
    default_stages = ["commit"];

    excludes = ["README.md"];

    hooks = {
      # Nix
      alejandra.enable = true;
      nixfmt.enable = false;
      nixpkgs-fmt.enable = false;
      deadnix = {
        enable = false;
      };
      statix.enable = true;

      # GitHub Actions
      actionlint.enable = true;

      # Ansible
      ansible-lint.enable = false;

      # Python
      autoflake.enable = false;
      black.enable = false;
      flake8.enable = false;
      pylint.enable = false;
      ruff.enable = false;

      # Bash
      bats.enable = true;
      shellcheck.enable = true;
      shfmt.enable = true;

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
      hunspell.enable = true;
      typos = {
        enable = true;
        settings = {
          format = "long";
          diff = true;
          write = false;
        };
      };

      # Git commit messages
      commitizen.enable = true;

      # Docker
      hadolint.enable = true;

      # Dhall
      dhall-format.enable = false;

      # Markdown
      markdownlint = {
        enable = true;
        settings = {
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
            MD013 = false;

            # Inline HTML
            MD033 = false;

            # List marker spaces.
            # Disabled for use with prettier.
            MD030 = false;
          };
        };
      };
      mdsh.enable = true;

      # Common
      prettier = {
        enable = true;
        settings = {
          check = true;
          list-different = false;
          write = true;
        };
      };

      # YAML
      yamllint = {
        enable = true;
        settings = {
          configPath = ".linters/config/.yamllint.yml";
        };
      };

      # Terraform
      terraform-format.enable = false;

      # Haskell
      hlint.enable = false;
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
