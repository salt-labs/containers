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

      packages = with pkgs; [
        figlet
        hello

        nixpkgs-fmt
        statix
        cachix
        nil

        hunspell
        hunspellDicts.en_AU

        sops
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
        docker-slim
      ];

      env = {
        DEVENV_DEVSHELL_ROOT = builtins.toString ./.;
      };

      enterShell = ''
        # Linters
        export HUNSPELL_CONFIG=''${PROJECT_DIR}/.linters/config/hunspell.conf
        export PRETTIER_CONFIG=''${PROJECT_DIR}/.linters/config/.prettierrc.yaml
        export YAMLLINT_CONFIG_FILE=''${PROJECT_DIR}/.linters/config/.yamllint.yml

        figlet containers

        hello \
          --greeting \
          "
          Welcome ''${USER}!
          "
      '';

      git-hooks = {
        excludes = [
          ".cache"
          ".devenv"
          ".direnv"
          "vendor"
        ];
        hooks = {
          actionlint.enable = true;
          check-json.enable = true;
          check-merge-conflicts.enable = true;
          check-shebang-scripts-are-executable.enable = true;
          check-symlinks.enable = true;
          check-yaml.enable = true;
          commitizen.enable = true;
          convco.enable = true;
          deadnix.enable = true;
          dialyzer.enable = true;
          editorconfig-checker.enable = true;
          gofmt.enable = true;
          golangci-lint.enable = true;
          golines.enable = true;
          gotest.enable = true;
          govet.enable = true;
          gptcommit.enable = true;
          markdownlint = {
            enable = true;
            settings = {
              configuration = {
                MD013 = {
                  line_length = 180;
                };
                MD033 = {
                  allowed_elements = [
                  ];
                };
              };
            };
          };
          mixed-line-endings.enable = true;
          nixfmt-rfc-style.enable = true;
          pre-commit-hook-ensure-sops.enable = true;
          prettier = {
            enable = true;
            excludes = [
            ];
          };
          pretty-format-json.enable = true;
          revive = {
            enable = true;
            fail_fast = false;
          };
          ripsecrets.enable = true;
          shellcheck.enable = true;
          shfmt.enable = true;
          staticcheck.enable = true;
          statix.enable = true;
          trim-trailing-whitespace.enable = true;
          trufflehog.enable = true;
          typos.enable = true;
          yamllint = {
            enable = true;
            settings = {
              configuration = ''
                extends: relaxed
                rules:
                  line-length: disable
                  indentation: enable
              '';
            };
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
      };

      dotenv = {
        enable = true;
        filename = ".env";
      };

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

      starship.enable = true;
    }
  ];
}
