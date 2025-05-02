{
  # JavaScript/TypeScript formatter
  biome = {
    enable = true;
    includes = ["**/*.js" "**/*.jsx" "**/*.ts" "**/*.tsx"];
    priority = 1;
  };
  
  # CSS-specific configuration with Tailwind v4 support
  biome.css = {
    enable = true;
    options = ["--print-width" "100"];
    includes = ["**/*.css" "**/*.scss" "**/*.sass" "**/*.less"];
    priority = 1;
  };
}
