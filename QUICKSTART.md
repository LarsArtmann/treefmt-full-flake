# ⚡ Quick Start: Format ANY codebase in 2 minutes

> **🎯 Get production-ready formatting with 15+ formatters in under 2 minutes**

## 🚀 Quick Start

---

```bash
# Step 1: Create new project directory
mkdir my-project && cd my-project

# Step 2: Initialize with template
nix flake init -t github:LarsArtmann/treefmt-full-flake

# Step 3: Test it works
echo "def hello(): pass" > test.py
nix fmt  # Formats your test.py file!
```

**🎉 That's it! You now have a working formatter setup.**

---

## 📁 Method 2: Add to Existing Project

Add to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Add treefmt-flake
    treefmt-flake = {
      url = "github:LarsArtmann/treefmt-full-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} {
    imports = [
      inputs.treefmt-flake.flakeModules.default
    ];

    # Enable formatters you need
    treefmtFlake = {
      projectRootFile = "flake.nix";
      formatters = {
        nix.enable = true;
        web.enable = true;
        python.enable = true;
        yaml.enable = true;
        markdown.enable = true;
      };
    };
  };
}
```

---

## 🧪 Test Your Setup

Create test files to verify everything works:

```bash
# Test Nix formatting
echo "{ foo = 1; }" > test.nix

# Test JavaScript formatting
echo "const x='hello';" > test.js

# Test Markdown formatting
echo "# Test\n\nSome  spaced    text" > test.md

# Test YAML formatting
echo "key:value" > test.yml

# Format all files
nix fmt

# Check that files were formatted
git diff  # Should show formatting changes
```

**Note**: The default template includes these formatters:

- ✅ **Nix**: alejandra
- ✅ **Web**: prettier (JS, TS, JSON, CSS, HTML, MD)
- ✅ **Shell**: shfmt
- ✅ **YAML**: yamlfmt

For more formatters (Python, Rust, etc.), use the full templates or configure manually.

---

## 🎯 What You Get Out of the Box

### 📋 **Formatters Available**

**Default Template** (works immediately):

- **Nix**: `alejandra` (or `nixfmt-rfc-style`)
- **Web**: `biome` (JavaScript, TypeScript, CSS, JSON)
- **Python**: `black`, `isort`, `ruff`
- **Rust**: `rustfmt`
- **YAML**: `yamlfmt`
- **Markdown**: `mdformat`
- **JSON**: `jq`, custom formatters
- **TOML**: `taplo`
- **Protocol Buffers**: `buf`
- **Shell**: `shfmt`, `shellcheck`

### 🛠️ **Built-in Tools**

```bash
nix fmt                    # Format all files
nix fmt -- --check         # Check formatting without changes
nix develop                # Enter dev shell with all tools
treefmt-status            # Show configuration summary (if available)
```

### ⚡ **Performance Features**

- **Incremental formatting**: Only format changed files
- **Parallel processing**: Format multiple files simultaneously
- **Smart caching**: Skip files that haven't changed

---

## 🚀 Advanced Usage

### Enable All Formatters

```nix
treefmtFlake = {
  formatters = {
    nix.enable = true;
    web.enable = true;
    python.enable = true;
    shell.enable = true;
    rust.enable = true;
    yaml.enable = true;
    markdown.enable = true;
    json.enable = true;
    misc.enable = true;  # Includes TOML, Protocol Buffers, etc.
  };
};
```

### Performance Optimization

```nix
treefmtFlake = {
  # Enable incremental formatting for large projects
  incremental = {
    enable = true;
    mode = "auto";  # or "git" or "cache"
  };

  # Performance tuning
  behavior = {
    performance = "balanced";  # or "fast" or "thorough"
  };
};
```

---

## 🐛 Troubleshooting

### ❌ "error: cannot find template"

**Solution**: Ensure you're using the correct GitHub URL:

```bash
nix flake init -t github:LarsArtmann/treefmt-full-flake
```

### ❌ Formatting not working

**Solution**: Check your configuration and test with a simple file:

```bash
echo "def test():pass" > test.py && nix fmt && cat test.py
# Should show formatted Python code
```

### 🔍 Get Help

```bash
nix flake show                    # See all available templates
nix develop                       # Enter dev shell
nix fmt -- --help               # See treefmt options
```

---

## ✅ Success! What Next?

1. **🎨 Customize your configuration** - Enable only the formatters you need
2. **⚡ Set up IDE integration** - Format on save in your editor
3. **🚀 Add to CI/CD** - Ensure consistent formatting in your pipeline
4. **📖 Read the full [README](./README.md)** - Discover advanced features

**Happy formatting!** 🎉
