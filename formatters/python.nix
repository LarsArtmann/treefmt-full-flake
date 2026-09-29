{
  # Python formatters
  # One formatter per concern: isort orders imports, ruff-format does all
  # code formatting (it is black-compatible). Running black AND ruff-format
  # on the same glob made black a silent no-op that ruff-format reverted.
  isort = {
    enable = true;
    includes = [ "*.py" ];
    priority = 1; # Import order first...
  };

  ruff-format = {
    enable = true;
    includes = [ "*.py" ];
    priority = 2; # ...then full formatting
  };
}
