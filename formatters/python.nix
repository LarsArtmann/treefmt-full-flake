{
  # Python formatters
  black = {
    enable = true;
    includes = ["*.py"];
    priority = 1; # Run first
  };

  isort = {
    enable = true;
    includes = ["*.py"];
    priority = 2; # Run after black
  };

  ruff-format = {
    enable = true;
    includes = ["*.py"];
    priority = 3; # Run after black and isort
  };
}
