# Test configuration demonstrating nixfmt-rfc-style option
{
  # Test 1: Default formatter (nixfmt-rfc-style)
  test-default = {
    treefmtFlake = {
      formatters.nix.enable = true;
    };
  };

  # Test 2: Explicitly set alejandra
  test-alejandra = {
    treefmtFlake = {
      formatters.nix = {
        enable = true;
        formatter = "alejandra";
      };
    };
  };

  # Test 3: Use nixfmt-rfc-style
  test-nixfmt = {
    treefmtFlake = {
      formatters.nix = {
        enable = true;
        formatter = "nixfmt-rfc-style";
      };
    };
  };
}
