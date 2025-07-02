{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let

  pkgsUnstable = import inputs.nixpkgs-unstable {
    config.allowUnfree = true;
  };

  packagesUnstable = with pkgsUnstable; [
  ];

  packages = with pkgs; [
    bashInteractive
  ];

  devPackages = with pkgs; [
    # Common
    convco
    figlet
    git
    gnutar
    hello
    jq
    just
    sshuttle
    wget
    yq-go

    # Security
    trivy
  ];

in
{
  name = "containers";

  env = {
    PROJECT = config.name;
  };

  cachix = {
    enable = true;
    pull = [
      "salt-labs"
    ];
    push = "salt-labs";
  };

  devenv = {
    warnOnNewVersion = true;
  };

  dotenv = {
    enable = true;
    disableHint = false;
  };

  difftastic = {
    enable = true;
  };

  packages =
    packages
    ++ packagesUnstable
    ++ lib.optionals (!config.container.isBuilding || config.name == "devenv") devPackages;

  enterShell = ''
    figlet -f starwars -w 180 $PROJECT

    hello --greeting="Hello ''${USER:-user}, welcome to the $PROJECT project!"

    echo ""
    echo "#########################"
    echo "#### Helper scripts #####"
    echo "#########################"
    echo ""
    ${pkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' <<EOF | ${pkgs.util-linuxMinimal}/bin/column -t | ${pkgs.gnused}/bin/sed -e 's|^|🦾 |' -e 's|••| |g'
    ${lib.generators.toKeyValue { } (lib.mapAttrs (_name: value: value.description) config.scripts)}
    EOF
    echo ""
    echo "#########################"
  '';

  languages = {
    nix = {
      enable = true;
    };
    shell = {
      enable = true;
    };
    opentofu = {
      enable = true;
    };
  };

  git-hooks = {
    excludes = [
      ".cache"
      ".devenv"
      ".direnv"
      ".git"
      ".vscode"
      "bundle"
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
              line_length = 500;
            };
            MD033 = {
              allowed_elements = [
                "a"
                "br"
                "nobr"
                "pre"
                "sup"
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
          "module/README.md"
        ];
      };
      # Use prettier instead.
      pretty-format-json.enable = false;
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
      trufflehog.enable = false;
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

  starship = {
    enable = true;
    config = {
      enable = false;
    };
  };

  devcontainer = {
    enable = true;
    settings = {
      customizations = {
        vscode = {
          extensions = [
            "arrterian.nix-env-selector"
            "brettm12345.nixfmt-vscode"
            "dotenv.dotenv-vscode"
            "esbenp.prettier-vscode"
            "exiasr.hadolint"
            "github.vscode-github-actions"
            "github.vscode-pull-request-github"
            "gruntfuggly.todo-tree"
            "hediet.vscode-drawio"
            "jnoortheen.nix-ide"
            "johnpapa.vscode-peacock"
            "mkhl.direnv"
            "ms-azuretools.vscode-docker"
            "ms-kubernetes-tools.vscode-kubernetes-tools"
            "nhoizey.gremlins"
            "pinage404.nix-extension-pack"
            "redhat.vscode-yaml"
            "streetsidesoftware.code-spell-checker"
            "tamasfe.even-better-toml"
            "tekumura.typos-vscode"
            "timonwong.shellcheck"
            "tuxtina.json2yaml"
            "vscodevim.vim"
            "waderyan.gitblame"
            "wakatime.vscode-wakatime"
            "yzhang.markdown-all-in-one"
          ];
        };
      };
    };
  };

  enterTest = ''
    echo "Running devenv tests..."
  '';

  outputs = {
  };

  container = {
    isBuilding = false;
  };

}
