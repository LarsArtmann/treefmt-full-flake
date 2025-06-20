{
  # nixfmt - Now uses nixfmt-rfc-style by default (deterministic)
  nixfmt = {
    enable = true;
    includes = ["**/*.nix"];
    priority = 1; # Run first
  };

  # Nix dead code eliminator
  deadnix = {
    enable = true;
    includes = ["**/*.nix"];
    priority = 2; # Run after nixfmt
  };

  # Nix linter
  statix = {
    enable = true;
    includes = ["**/*.nix"];
    priority = 3; # Run after nixfmt and deadnix
  };
}
