{
  description = "Project using minimal treefmt-full-flake configuration";

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
      
      # Configure minimal formatter set
      treefmtFlake = {
        enableNix = true;
        enableMarkdown = true;
        enableYaml = true;
        
        # Configure project root
        projectRootFile = "flake.nix";
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
        };
      };
    };
}
