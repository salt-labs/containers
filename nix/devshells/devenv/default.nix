{
  inputs,
  pkgs,
  ...
}:
inputs.devenv.lib.mkShell {
  inherit inputs;
  inherit pkgs;

  modules = [
    {
      # https://devenv.sh/reference/options/

      packages = with pkgs; [
        figlet
        hello

        nixpkgs-fmt
        statix
        cachix
        nil

        sops
        #sops-init-gpg-key
        #sops-import-keys-hook
        ssh-to-age
        ssh-to-pgp
        age

        bashInteractive
        bash-completion
        shellcheck
        dialog
        tree

        ccid
        hidapi
        libfido2
        libu2f-host
        libusb-compat-0_1
        libusb1
        opensc
        pam_u2f
        pcsclite
        pinentry
        socat

        kind
        kubectl
        dive
        ytt
        kapp
        vendir
      ];

      env = {
        DEVENV_DEVSHELL_ROOT = builtins.toString ./.;
      };

      enterShell = ''
        # Linters
        export HUNSPELL_CONFIG=''${PROJECT_DIR}/.linters/config/hunspell.conf
        export PRETTIER_CONFIG=''${PROJECT_DIR}/.linters/config/.prettierrc.yaml
        export YAMLLINT_CONFIG_FILE=''${PROJECT_DIR}/.linters/config/.yamllint.yml

        figlet ''${PROJECT_SHELL:-Unknown}

        hello \
          --greeting \
          "
          Welcome ''${USER}!

          Project: ''${PROJECT_NAME:-Unknown}
          Shell: ''${PROJECT_SHELL:-Unknown}
          Directory: ''${PROJECT_DIR:-Unknown}
          "
      '';

      pre-commit = {
        default_stages = ["commit"];

        excludes = ["README.md"];

        hooks = {
          # Nix
          alejandra.enable = true;
          nixfmt.enable = false;
          nixpkgs-fmt.enable = false;
          deadnix.enable = false;
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
          hunspell.enable = false;
          typos.enable = true;

          # Git commit messages
          commitizen.enable = true;

          # Docker
          hadolint.enable = true;

          # Dhall
          dhall-format.enable = false;

          # Markdown
          markdownlint = {
            enable = true;
          };
          mdsh.enable = true;

          # Common
          prettier.enable = true;

          # YAML
          yamllint.enable = true;

          # Terraform
          terraform-format.enable = false;

          # Haskell
          hlint.enable = false;
        };

        settings = {
          deadnix = {
            noUnderscore = true;
          };

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
              MD013 = false;

              # Inline HTML
              MD033 = false;

              # List marker spaces.
              # Disabled for use with prettier.
              MD030 = false;
            };
          };

          prettier = {
            output = "check";
            write = true;
          };

          typos = {
            format = "long";
            diff = true;
            write = false;
          };

          yamllint = {
            configPath = ".linters/config/.yamllint.yml";
          };
        };
      };

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

      devenv = {
        flakesIntegration = true;
        #warnOnNewVersion = true;
      };

      dotenv = {
        enable = true;
        filename = ".env";
      };

      difftastic.enable = true;

      #hosts = {"example.com" = "1.1.1.1";};

      languages = {
        cue = {
          enable = false;
          package = pkgs.cue;
        };

        gawk = {enable = true;};

        go = {
          enable = false;
          package = pkgs.go;
        };

        nix = {enable = true;};

        python = {
          enable = true;
          package = pkgs.python3;

          poetry = {
            enable = true;
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

      starship = {
        enable = true;
        package = pkgs.starship;
        config = {
          enable = true;
          path = "/home/$USER/.config/starship.toml";
        };
      };
    }
  ];
}
