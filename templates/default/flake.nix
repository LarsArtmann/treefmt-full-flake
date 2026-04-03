{
  description = "Project using treefmt-flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-flake.url = "github:LarsArtmann/treefmt-full-flake";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.treefmt-flake.flakeModules.default
      ];

      treefmtFlake = {
        projectRootFile = "flake.nix";
        autoDetection.enable = true;

        formatters = {
          nix.enable = true;
          web.enable = true;
          python.enable = true;
          shell.enable = true;
          yaml.enable = true;
          markdown.enable = true;
          json.enable = true;
        };

        behavior = {
          performance = "balanced";
          allowMissingFormatter = false;
          enableDefaultExcludes = true;
        };
      };

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          buildInputs = [config.treefmt.build.wrapper];
          shellHook = ''
            echo "Development environment ready"
            echo "Run 'nix fmt' to format all files"
          '';
        };
      };
    };
}
