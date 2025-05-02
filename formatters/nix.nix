{
  # Nix formatters configuration
  alejandra = {
    enable = true;
    includes = ["**/*.nix"];
    priority = 1; # Run first
  };

  # Nix dead code eliminator
  deadnix = {
    enable = true;
    includes = ["**/*.nix"];
    priority = 2; # Run after alejandra
  };

  # Nix linter
  statix = {
    enable = true;
    includes = ["**/*.nix"];
    priority = 3; # Run after alejandra and deadnix
  };
}
