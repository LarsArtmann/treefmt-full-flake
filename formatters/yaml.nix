{
  # YAML formatter
  yamlfmt = {
    enable = true;
    options = ["-gitignore_excludes" "-formatter=retain_line_breaks_single=true"];
    includes = ["**/*.yaml" "**/*.yml"];
    priority = 1;
  };
}
