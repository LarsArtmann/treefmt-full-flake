{
  # JavaScript/TypeScript/JSON formatter
  biome = {
    enable = true;
    includes = [
      "*.js"
      "*.jsx"
      "*.ts"
      "*.tsx"
      "*.css"
      "*.scss"
      "*.sass"
      "*.less"
      "*.json"
      "*.jsonc"
    ];
    # Vendored minified libraries: reformatting/linting them is pure churn
    # (biome's check exits 1 on lint findings in code no human wrote —
    # template-justfile's htmx.min.js surfaced 200+ after the treefmt-nix
    # bump that un-broke biome's config schema).
    excludes = [ "*.min.js" ];
    priority = 1;
  };
}
