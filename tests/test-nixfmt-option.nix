# Test configuration demonstrating nixfmt-rfc-style option
{
  imports = [../flake-module.nix];

  # Test 1: Default (alejandra)
  test-default = {
    treefmtFlake = {
      nix = true;
    };
    # Should use alejandra
  };

  # Test 2: Explicitly set alejandra
  test-alejandra = {
    treefmtFlake = {
      nix = true;
      nixFormatter = "alejandra";
    };
  };

  # Test 3: Use nixfmt-rfc-style
  test-nixfmt = {
    treefmtFlake = {
      nix = true;
      nixFormatter = "nixfmt-rfc-style";
    };
    # Should use nixfmt instead of alejandra
  };
}
