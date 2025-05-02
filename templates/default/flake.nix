{
  description = "Project using treefmt-full-flake";

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
      
      # Configure which formatter groups to enable
      treefmtFlake = {
        enableNix = true;
        enableWeb = true;
        enablePython = true;
        enableShell = true;
        enableYaml = true;
        enableMarkdown = true;
        enableJson = true;
        
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
      };
    };
}
