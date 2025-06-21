{lib}: let
  # Security validation functions for treefmt configuration
  # Debug configuration - can be enabled via environment variable
  debugEnabled = builtins.getEnv "TREEFMT_DEBUG_SECURITY" == "1";

  # Enhanced debug tracing using lib.debug
  traceSecurityCheck = name: value: result:
    if debugEnabled
    then
      lib.debug.traceSeqN 2 {
        check = name;
        input = value;
        valid = result.isValid;
        errors = result.errors or [];
      }
      result
    else result;

  # Path traversal prevention
  validatePath = path: let
    # Check for directory traversal attempts
    hasDotDot = lib.hasInfix ".." path;
    hasNullBytes = lib.hasInfix "\x00" path;

    # Check for suspicious patterns
    suspiciousPatterns = [
      "../"
      "..\\"
      "~/"
      "$HOME"
      "\${" # Prevent nix expression injection
      "$(" # Prevent command substitution
      "`" # Prevent backtick execution
    ];

    hasSuspiciousPattern = lib.any (pattern: lib.hasInfix pattern path) suspiciousPatterns;

    result = {
      isValid = !hasDotDot && !hasNullBytes && !hasSuspiciousPattern;
      errors =
        lib.optionals hasDotDot ["Path contains directory traversal: '${path}'"]
        ++ lib.optionals hasNullBytes ["Path contains null bytes: '${path}'"]
        ++ lib.optionals hasSuspiciousPattern ["Path contains suspicious patterns: '${path}'"];
    };
  in
    traceSecurityCheck "validatePath" path result;

  # Validate shell command arguments to prevent injection
  validateShellArg = arg: let
    # Characters that could be used for command injection
    dangerousChars = [
      ";"
      "|"
      "&"
      ">"
      "<"
      "`"
      "$"
      "("
      ")"
      "{"
      "}"
      "["
      "]"
      "*"
      "?"
      "~"
      "!"
      "#"
    ];

    # Check for dangerous patterns
    hasDangerousChars = lib.any (char: lib.hasInfix char arg) dangerousChars;

    # Allow safe patterns (alphanumeric, dashes, dots, slashes for paths)
    isSafePattern = lib.all (
      c:
        lib.elem c (
          lib.stringToCharacters "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._/=:"
        )
    ) (lib.stringToCharacters arg);
    result = {
      isValid = !hasDangerousChars && isSafePattern;
      errors = lib.optionals (!isSafePattern || hasDangerousChars) [
        "Argument contains potentially dangerous characters: '${arg}'"
      ];
    };
  in
    traceSecurityCheck "validateShellArg" arg result;

  # Validate file patterns to prevent expansion attacks
  validateFilePattern = pattern: let
    # Check for dangerous glob patterns
    dangerousPatterns = [
      "/**" # Root filesystem traversal
      "~/*" # Home directory traversal
      "$*" # Variable expansion
      "`*" # Command substitution
      "*$(.*)*" # Command substitution in glob
    ];

    isDangerous =
      lib.any (
        dangerous: lib.hasInfix dangerous pattern || lib.match dangerous pattern != null
      )
      dangerousPatterns;

    # Ensure pattern doesn't start with dangerous paths
    hasUnsafePath = lib.hasPrefix "/" pattern || lib.hasPrefix "~" pattern;
    result = {
      isValid = !isDangerous && !hasUnsafePath;
      errors =
        lib.optionals isDangerous ["File pattern contains dangerous expansion: '${pattern}'"]
        ++ lib.optionals hasUnsafePath ["File pattern uses unsafe absolute path: '${pattern}'"];
    };
  in
    traceSecurityCheck "validateFilePattern" pattern result;

  # Sanitize string for safe shell usage
  sanitizeForShell = str:
    lib.trivial.pipe str [
      # Remove dangerous shell metacharacters
      (
        s:
          lib.replaceStrings
          [
            ";"
            "|"
            "&"
            ">"
            "<"
            "`"
            "$"
            "("
            ")"
            "{"
            "}"
            "["
            "]"
            "'"
            "\""
            "\\"
          ]
          (lib.genList (_: "") 16) # Generate list of empty strings
          
          s
      )
      # Trim whitespace
      lib.strings.trim
      # Trace result if debugging
      (
        s:
          if debugEnabled
          then lib.debug.trace "sanitizeForShell: '${str}' -> '${s}'" s
          else s
      )
    ];

  # Validate cache directory path
  validateCacheDir = cachePath: let
    pathValidation = validatePath cachePath;

    # Additional cache-specific checks
    isRelative = !lib.hasPrefix "/" cachePath;

    # Preferred: relative paths or standard cache locations
    isRecommendedLocation =
      isRelative
      || lib.hasPrefix "~/.cache" cachePath
      || lib.hasPrefix "/var/cache" cachePath
      || lib.hasPrefix "/tmp" cachePath;

    warnings = lib.optionals (!isRecommendedLocation && pathValidation.isValid) [
      "Cache directory '${cachePath}' is not in a standard cache location. Consider using ~/.cache/treefmt or a relative path."
    ];
  in {
    inherit (pathValidation) isValid;
    inherit (pathValidation) errors;
    inherit warnings;
  };

  # Validate git options for security
  validateGitOptions = gitOpts: let
    errors = [];
    warnings = [];

    # Validate branch name
    branchValidation =
      if gitOpts.branch != null
      then validateShellArg gitOpts.branch
      else {
        isValid = true;
        errors = [];
      };

    # Validate commit hash if provided
    commitValidation =
      if gitOpts.sinceCommit != null
      then let
        # Git commits should be alphanumeric hashes
        isValidCommit = lib.all (c: lib.elem c (lib.stringToCharacters "abcdef0123456789")) (
          lib.stringToCharacters gitOpts.sinceCommit
        );
      in {
        isValid = isValidCommit && (lib.stringLength gitOpts.sinceCommit >= 7);
        errors =
          lib.optionals (!isValidCommit) [
            "Git commit hash contains invalid characters: '${gitOpts.sinceCommit}'"
          ]
          ++ lib.optionals (lib.stringLength gitOpts.sinceCommit < 7) [
            "Git commit hash too short: '${gitOpts.sinceCommit}'"
          ];
      }
      else {
        isValid = true;
        errors = [];
      };
  in {
    isValid = branchValidation.isValid && commitValidation.isValid;
    errors = branchValidation.errors ++ commitValidation.errors;
    inherit warnings;
  };

  # Comprehensive security validation for entire config
  validateSecurity = cfg: let
    # Validate basic string options
    projectRootValidation = validatePath cfg.projectRootFile;

    # Validate cache directory if incremental is enabled
    cacheValidation =
      if cfg.incremental.enable
      then validateCacheDir cfg.incremental.cache
      else {
        isValid = true;
        errors = [];
        warnings = [];
      };

    # Validate git options
    gitValidation = validateGitOptions (cfg.git or cfg.gitOptions or {});

    # Collect all validation results
    allErrors = projectRootValidation.errors ++ cacheValidation.errors ++ gitValidation.errors;
    allWarnings = cacheValidation.warnings ++ gitValidation.warnings;

    # Additional security recommendations
    recommendations =
      lib.optionals (cfg.behavior.allowMissingFormatter or cfg.allowMissingFormatter or false) [
        "Security: allowMissingFormatter=true may execute unknown commands. Consider installing all required formatters explicitly."
      ]
      ++ lib.optionals (cfg.incremental.enable && cfg.incremental.gitBased) [
        "Security: git-based incremental formatting executes git commands. Ensure you trust the git repository."
      ];
  in {
    isValid = allErrors == [];
    errors = allErrors;
    warnings = allWarnings;
    inherit recommendations;

    # Format all security messages
    formatSecurityReport = let
      formatSection = title: messages:
        if messages == []
        then ""
        else "\n🔒 ${title}:\n${lib.concatMapStringsSep "\n" (msg: "  ⚠️  ${msg}") messages}";
    in
      (formatSection "SECURITY ERRORS" allErrors)
      + (formatSection "SECURITY WARNINGS" allWarnings)
      + (formatSection "SECURITY RECOMMENDATIONS" recommendations);
  };

  # Create secure shell script wrapper
  createSecureWrapper = scriptContent: ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Security: Set secure PATH
    export PATH="/usr/bin:/bin:/usr/local/bin"

    # Security: Clear dangerous environment variables
    unset IFS
    unset CDPATH
    unset BASH_ENV
    unset ENV

    # Security: Set secure umask
    umask 022

    # Security: Verify we're in a safe directory
    if [[ "$PWD" =~ \.\./|\$|\` ]]; then
      echo "❌ Security Error: Current directory path contains unsafe characters"
      exit 1
    fi

    # Execute main script content
    ${scriptContent}
  '';

  # Enhanced file existence check with security
  secureFileCheck = filePath: description: ''
    # Security: Validate file path
    if [[ "${filePath}" =~ \.\./|\$|\` ]]; then
      echo "❌ Security Error: ${description} path contains unsafe characters: ${filePath}"
      exit 1
    fi

    if [[ ! -e "${filePath}" ]]; then
      echo "⚠️  Warning: ${description} - file '${filePath}' not found"
      echo "   Consider verifying the path or updating configuration"
    fi
  '';
in {
  inherit
    validatePath
    validateShellArg
    validateFilePattern
    sanitizeForShell
    validateCacheDir
    validateGitOptions
    validateSecurity
    createSecureWrapper
    secureFileCheck
    ;

  # Export secure types
  secureTypes = {
    # Path type that prevents traversal
    securePath =
      lib.types.str
      // {
        check = x: let
          validation = validatePath x;
        in
          if validation.isValid
          then true
          else throw "Insecure path: ${lib.concatStringsSep ", " validation.errors}";
      };

    # Shell argument type that prevents injection
    secureShellArg =
      lib.types.str
      // {
        check = x: let
          validation = validateShellArg x;
        in
          if validation.isValid
          then true
          else throw "Insecure shell argument: ${lib.concatStringsSep ", " validation.errors}";
      };

    # File pattern type that prevents dangerous expansions
    secureFilePattern =
      lib.types.str
      // {
        check = x: let
          validation = validateFilePattern x;
        in
          if validation.isValid
          then true
          else throw "Insecure file pattern: ${lib.concatStringsSep ", " validation.errors}";
      };
  };
}
