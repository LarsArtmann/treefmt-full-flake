{
  # Shell script formatter
  shfmt = {
    enable = true;
    includes = ["*.sh"];
    priority = 1; # Run first for shell files
  };

  # Shell script linter
  shellcheck = {
    enable = true;
    includes = ["*.sh"];
    priority = 2; # Run after shfmt
  };
}
