# Enhanced error formatting with colors and structured output
{lib}: let
  # ANSI color codes for terminal output
  colors = {
    reset = "\033[0m";
    bold = "\033[1m";
    dim = "\033[2m";

    # Foreground colors
    red = "\033[31m";
    green = "\033[32m";
    yellow = "\033[33m";
    blue = "\033[34m";
    magenta = "\033[35m";
    cyan = "\033[36m";
    white = "\033[37m";
    gray = "\033[90m";

    # Background colors
    bgRed = "\033[41m";
    bgGreen = "\033[42m";
    bgYellow = "\033[43m";
    bgBlue = "\033[44m";

    # Bright colors
    brightRed = "\033[91m";
    brightGreen = "\033[92m";
    brightYellow = "\033[93m";
    brightBlue = "\033[94m";
    brightMagenta = "\033[95m";
    brightCyan = "\033[96m";
  };

  # Color helper functions
  colorize = color: text: "${color}${text}${colors.reset}";

  red = colorize colors.red;
  green = colorize colors.green;
  yellow = colorize colors.yellow;
  blue = colorize colors.blue;
  cyan = colorize colors.cyan;
  bold = colorize colors.bold;
  dim = colorize colors.dim;

  # Semantic color functions
  error = text: "${colors.brightRed}❌ ${text}${colors.reset}";
  warning = text: "${colors.brightYellow}⚠️  ${text}${colors.reset}";
  success = text: "${colors.brightGreen}✅ ${text}${colors.reset}";
  info = text: "${colors.brightBlue}ℹ️  ${text}${colors.reset}";
  debug = text: "${colors.gray}🔧 ${text}${colors.reset}";
  security = text: "${colors.brightMagenta}🔒 ${text}${colors.reset}";

  # Icons and symbols
  icons = {
    error = "❌";
    warning = "⚠️ ";
    success = "✅";
    info = "ℹ️ ";
    debug = "🔧";
    security = "🔒";
    performance = "⚡";
    config = "📋";
    file = "📄";
    directory = "📁";
    git = "🌿";
    rocket = "🚀";
    sparkles = "✨";
    fire = "🔥";
    thinking = "🤔";
    lightbulb = "💡";
    gear = "⚙️ ";
    target = "🎯";
    shield = "🛡️ ";
    key = "🔑";
    lock = "🔐";
    unlock = "🔓";
  };

  # Box drawing characters for structured output
  box = {
    topLeft = "┌";
    topRight = "┐";
    bottomLeft = "└";
    bottomRight = "┘";
    horizontal = "─";
    vertical = "│";
    cross = "┼";
    tee = {
      down = "┬";
      up = "┴";
      right = "├";
      left = "┤";
    };
  };

  # Generate a horizontal line with specified width
  horizontalLine = width: char: lib.concatStrings (lib.genList (_: char) width);

  # Create a bordered box around text
  createBox = title: content: let
    lines = lib.splitString "\n" content;
    maxWidth = lib.foldl (max: line: lib.max max (lib.stringLength line)) 0 lines;
    titleWidth = lib.stringLength title;
    boxWidth = lib.max maxWidth (titleWidth + 4);

    topLine = "${box.topLeft}${horizontalLine (boxWidth + 2) box.horizontal}${box.topRight}";
    titleLine = "${box.vertical} ${bold title}${lib.fixedWidthString (boxWidth - titleWidth) " " ""}${box.vertical}";
    separator = "${box.tee.right}${horizontalLine (boxWidth + 2) box.horizontal}${box.tee.left}";
    bottomLine = "${box.bottomLeft}${horizontalLine (boxWidth + 2) box.horizontal}${box.bottomRight}";

    contentLines =
      lib.map (
        line: "${box.vertical} ${line}${lib.fixedWidthString (boxWidth - lib.stringLength line) " " ""} ${box.vertical}"
      )
      lines;
  in
    lib.concatStringsSep "\n" ([topLine titleLine separator] ++ contentLines ++ [bottomLine]);

  # Format a list of items with consistent indentation
  formatList = prefix: items:
    lib.concatMapStringsSep "\n" (item: "  ${prefix} ${item}") items;

  # Format errors with enhanced styling
  formatErrors = errors:
    if errors == []
    then ""
    else let
      formattedErrors = lib.map (error: "• ${error}") errors;
      content = lib.concatStringsSep "\n" formattedErrors;
    in
      createBox "${error "Validation Errors"}" content;

  # Format warnings with enhanced styling
  formatWarnings = warnings:
    if warnings == []
    then ""
    else let
      formattedWarnings = lib.map (warning: "• ${warning}") warnings;
      content = lib.concatStringsSep "\n" formattedWarnings;
    in
      createBox "${warning "Warnings"}" content;

  # Format recommendations with enhanced styling
  formatRecommendations = recommendations:
    if recommendations == []
    then ""
    else let
      formattedRecommendations = lib.map (recommendation: "• ${recommendation}") recommendations;
      content = lib.concatStringsSep "\n" formattedRecommendations;
    in
      createBox "${info "Recommendations"}" content;

  # Format security report with full styling
  formatSecurityReport = report: let
    status =
      if report.isValid
      then "${success "Security validation passed"}"
      else "${error "Security validation failed"}";

    parts = lib.filter (part: part != "") [
      status
      (formatErrors report.errors)
      (formatWarnings report.warnings)
      (formatRecommendations report.recommendations)
    ];
  in
    lib.concatStringsSep "\n\n" parts;

  # Format deprecation warnings with migration guidance
  formatDeprecationWarnings = warnings:
    if warnings == []
    then ""
    else let
      header = "${warning "Deprecated Configuration Detected"}";
      migrationNote = "${info "Migration required before v3.0"}";
      formattedWarnings = lib.map (w: "• ${w}") warnings;
      content = lib.concatStringsSep "\n" ([migrationNote ""] ++ formattedWarnings);
    in
      createBox header content;

  # Format configuration summary with colors
  formatConfigSummary = config: let
    items = [
      "${icons.file} Project Root: ${cyan config.projectRootFile}"
      "${icons.gear} Auto-Detection: ${
        if config.autoDetection.enable
        then green "enabled"
        else red "disabled"
      }"
      "${icons.performance} Performance: ${yellow config.behavior.performance}"
      "${icons.target} Incremental: ${
        if config.incremental.enable
        then green "enabled (${config.incremental.mode})"
        else red "disabled"
      }"
      "${icons.directory} Cache: ${blue config.incremental.cache}"
    ];
    content = lib.concatStringsSep "\n" items;
  in
    createBox "${icons.config} Configuration Summary" content;

  # Format formatter status with visual indicators
  formatFormatterStatus = formatters: let
    formatFormatter = name: enabled:
      if enabled
      then "${icons.success} ${bold name}: ${green "enabled"}"
      else "${icons.error} ${name}: ${dim "disabled"}";

    formatterList = lib.mapAttrsToList formatFormatter formatters;
    content = lib.concatStringsSep "\n" formatterList;
  in
    createBox "${icons.gear} Formatter Status" content;

  # Generate colored shell output
  generateShellOutput = sections:
    lib.concatStringsSep "\n\n" (lib.filter (section: section != "") sections);

  # Progress bar generator
  generateProgressBar = current: total: width: let
    percentage =
      if total > 0
      then (current * 100) / total
      else 100;
    filled = (current * width) / total;
    filledChars = lib.genList (_: "█") (lib.toInt filled);
    emptyChars = lib.genList (_: "░") (width - lib.toInt filled);
    bar = lib.concatStrings (filledChars ++ emptyChars);
    percentText = "${toString (lib.toInt percentage)}%";
  in "${cyan bar} ${bold percentText}";

  # Terminal capability detection
  supportsColorCheck = ''[[ -t 1 && "''${TERM:-}" != "dumb" ]]'';
in {
  inherit
    colors
    colorize
    red
    green
    yellow
    blue
    cyan
    bold
    dim
    error
    warning
    success
    info
    debug
    security
    icons
    box
    horizontalLine
    createBox
    formatList
    formatErrors
    formatWarnings
    formatRecommendations
    formatSecurityReport
    formatDeprecationWarnings
    formatConfigSummary
    formatFormatterStatus
    generateShellOutput
    generateProgressBar
    supportsColorCheck
    ;

  # Utility functions
  utils = {
    inherit colorize;

    # Check if terminal supports colors
    supportsColor = supportsColorCheck;

    # Conditional color wrapper
    maybeColor = color: text: ''
      if ${supportsColorCheck}; then
        echo "${colorize color text}"
      else
        echo "${text}"
      fi
    '';

    # Strip ANSI codes for non-color terminals
    stripColors = text:
      builtins.replaceStrings
      (lib.attrValues colors)
      (lib.genList (_: "") (lib.length (lib.attrValues colors)))
      text;

    # Enhanced string utilities using lib.strings
    stringUtils = {
      # Normalize whitespace using lib.strings functions
      normalizeWhitespace = text: 
        lib.strings.trim (builtins.replaceStrings ["\t" "\n" "\r"] [" " " " " "] text);
      
      # Capitalize first letter
      capitalize = text:
        if lib.stringLength text > 0
        then lib.toUpper (lib.substring 0 1 text) + lib.substring 1 (-1) text
        else text;
      
      # Convert to kebab-case
      toKebabCase = text:
        lib.toLower (builtins.replaceStrings [" " "_"] ["-" "-"] text);
      
      # Truncate text with ellipsis
      truncate = maxLength: text:
        if lib.stringLength text <= maxLength
        then text
        else lib.substring 0 (maxLength - 3) text + "...";
    };
  };

  # Generators using lib.generators for complex formatting
  generators = {
    # Generate formatted JSON with indentation
    toColoredJSON = attrs: lib.generators.toJSON {} attrs;

    # Generate formatted YAML-like output with custom indentation
    toFormattedConfig = attrs:
      lib.generators.toPretty {
        allowPrettyValues = true;
        multiline = true;
        indent = "  ";
      }
      attrs;

    # Generate shell-escaped strings for safe output
    toShellVar = name: value: "${name}=${lib.strings.escapeShellArg (toString value)}";

    # Generate key-value pairs with alignment
    toKeyValue = attrs:
      lib.generators.toKeyValue {
        mkKeyValue = k: v: "${k} = ${lib.generators.toPretty {} v}";
      }
      attrs;

    # Generate INI-style configuration
    toINI = lib.generators.toINI {};

    # Generate Git config style output
    toGitConfig = attrs:
      lib.generators.toGitINI {} attrs;

    # Generate formatted list with bullets
    toBulletList = items: prefix:
      lib.concatMapStringsSep "\n" (item: "${prefix}${item}") items;

    # Generate markdown table from structured data  
    toMarkdownTable = headers: rows:
      let
        headerRow = "| ${lib.concatStringsSep " | " headers} |";
        separatorRow = "| ${lib.concatStringsSep " | " (lib.map (_: "---") headers)} |";
        dataRows = lib.map (row: 
          "| ${lib.concatStringsSep " | " (lib.map (h: toString (row.${h} or "")) headers)} |"
        ) rows;
      in
        lib.concatStringsSep "\n" ([headerRow separatorRow] ++ dataRows);

    # Generate configuration diff using lib.generators  
    toConfigDiff = oldConfig: newConfig:
      lib.generators.toPretty {
        allowPrettyValues = true;
        multiline = true;
        indent = "  ";
      } {
        before = oldConfig;
        after = newConfig;
        changes = lib.filterAttrs (k: v: (oldConfig.${k} or null) != v) newConfig;
      };

    # Generate structured logs using lib.generators
    toStructuredLog = level: component: message: data:
      lib.generators.toJSON {} {
        timestamp = "\${$(date -u +\"%Y-%m-%dT%H:%M:%S.%3NZ\")}";
        level = level;
        component = component;
        message = message;
        data = data;
      };
  };

  # Pre-built formatting functions for common use cases
  prebuilt = {
    # Security validation output
    securityValidation = report:
      generateShellOutput [
        (formatSecurityReport report)
      ];

    # Full validation report
    validationReport = {
      security,
      deprecation,
      config,
      formatters,
    }:
      generateShellOutput [
        (formatConfigSummary config)
        (formatFormatterStatus formatters)
        (formatSecurityReport security)
        (formatDeprecationWarnings deprecation)
      ];

    # Error summary
    errorSummary = {
      errors,
      warnings,
      recommendations,
    }:
      generateShellOutput [
        (formatErrors errors)
        (formatWarnings warnings)
        (formatRecommendations recommendations)
      ];
  };

  # Metadata
  meta = {
    description = "Enhanced error formatting with colors and structured output";
    version = "1.0.0";
    features = [
      "ANSI color support"
      "Structured error formatting"
      "Box drawing for visual hierarchy"
      "Icon-based status indicators"
      "Progress bars and visual elements"
      "Terminal capability detection"
      "lib.generators integration"
    ];
  };
}
