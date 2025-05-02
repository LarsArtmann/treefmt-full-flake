{
  description = "Project using complete treefmt-full-flake configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    
    # Import the treefmt-full-flake
    treefmt-full-flake = {
      url = "github:LarsArtmann/treefmt-full-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
      
      imports = [
        # Import the treefmt-full-flake module
        inputs.treefmt-full-flake.flakeModule
      ];
      
      # Enable all formatter groups
      treefmtFlake = {
        enableNix = true;
        enableWeb = true;
        enablePython = true;
        enableShell = true;
        enableRust = true;
        enableYaml = true;
        enableMarkdown = true;
        enableJson = true;
        enableMisc = true;
        
        # Configure project root
        projectRootFile = "flake.nix";
        
        # Enable global excludes
        enableGlobalExcludes = true;
        
        # Don't allow missing formatters
        allowMissingFormatter = false;
      };
      
      perSystem = {
        config,
        pkgs,
        ...
      }: {
        # Create a development shell with all tools
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Formatters
            config.treefmt.build.wrapper
          ];
          
          shellHook = ''
            echo "Welcome to the project development environment!"
            echo ""
            echo "Available commands:"
            echo "  nix fmt                - Format all files"
            echo "  nix fmt -- --check     - Check formatting without changing files"
            echo ""
          '';
        };
        
        # Example of extending the configuration with custom formatters
        treefmt.programs = {
          # Add any project-specific formatter configurations here
        };
      };
    };
}
