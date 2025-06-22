{
  description = "Local development template with treefmt (self-contained)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        # Self-contained treefmt configuration 
        # This works immediately without external dependencies
        treefmt = {
          projectRootFile = "flake.nix";
          
          # Enable common formatters that work out of the box
          programs = {
            # Nix formatting
            alejandra.enable = true;
            
            # Web development (if needed)
            prettier = {
              enable = true;
              includes = ["*.js" "*.ts" "*.json" "*.css" "*.html" "*.md"];
            };
            
            # Shell scripts
            shfmt.enable = true;
            
            # YAML files
            yamlfmt.enable = true;
          };
        };

        # Create a development shell with all tools
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Formatters are provided by treefmt-nix
            config.treefmt.build.wrapper
            
            # Add any additional development tools here
            pkgs.git
          ];

          shellHook = ''
            echo "🎉 Local development environment ready!"
            echo ""
            echo "Available commands:"
            echo "  nix fmt                      - Format all files"
            echo "  nix fmt -- --check           - Check formatting without changes"
            echo "  nix fmt -- --fail-on-change  - Exit 1 if formatting needed"
            echo ""
            echo "This template works immediately without external dependencies!"
            echo "To add more formatters, edit the treefmt.programs section in flake.nix"
            echo ""
          '';
        };
      };
    };
}