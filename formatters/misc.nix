{
  # Protocol Buffers formatter
  buf = {
    enable = true;
    includes = [ "*.proto" ];
    priority = 1;
  };

  # TOML formatter
  taplo = {
    enable = true;
    includes = [ "*.toml" ];
    priority = 1;
  };

  # GitHub Actions workflow linter
  actionlint = {
    enable = true;
    includes = [
      ".github/workflows/*.yml"
      ".github/workflows/*.yaml"
    ];
    priority = 1;
  };

  # Justfile formatter
  just = {
    enable = true;
    includes = [
      "justfile"
      "Justfile"
      "*.just"
    ];
    priority = 1;
  };
}
