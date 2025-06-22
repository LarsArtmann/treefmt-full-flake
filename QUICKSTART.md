# ⚡ Quick Start: Format ANY codebase in 2 minutes

> **🎯 Get production-ready formatting with 15+ formatters in under 2 minutes**

## 🚨 Current Status: Private Beta

This project is currently **private**. Choose the access method that works for you:

---

## 🚀 Method 1: Self-Contained Template (RECOMMENDED)

**✅ Works immediately • ✅ No external dependencies • ✅ Perfect for testing**

```bash
# Step 1: Clone the repository
git clone git@github.com:LarsArtmann/treefmt-full-flake.git
cd treefmt-full-flake

# Step 2: Create a test project
mkdir ../test-treefmt && cd ../test-treefmt

# Step 3: Initialize with self-contained template
nix flake init -t ../treefmt-full-flake#local-development

# Step 4: Test it works immediately!
echo "console.log('hello world');" > test.js
nix fmt  # Formats your test.js file!

# Step 5: See what you got
nix flake show  # Shows all available formatters
```

**🎉 That's it! You now have a working formatter setup.**

---

## 🔧 Method 2: SSH Access (If you have repository access)

```bash
# Step 1: Create new project directory
mkdir my-project && cd my-project

# Step 2: Initialize with template
nix flake init -t git+ssh://git@github.com/LarsArtmann/treefmt-full-flake

# Step 3: Edit the template to set your source
# Edit flake.nix and replace the url with your preferred access method

# Step 4: Test it works
echo "def hello(): pass" > test.py
nix fmt  # Formats your test.py file!
```

---

## 📁 Method 3: Local Integration (For existing projects)

```bash
# Step 1: Clone treefmt-flake somewhere accessible
git clone git@github.com:LarsArtmann/treefmt-full-flake.git ~/tools/treefmt-full-flake

# Step 2: Add to your existing project's flake.nix
```

Add to your `flake.nix` inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Add treefmt-flake
    treefmt-flake = {
      url = "path:/home/user/tools/treefmt-full-flake";  # Use your actual path
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} {
    imports = [
      inputs.treefmt-flake.flakeModule
    ];

    # Enable formatters you need
    treefmtFlake = {
      projectRootFile = "flake.nix";
      formatters = {
        nix.enable = true;        # Nix files
        web.enable = true;        # JS/TS/CSS
        python.enable = true;     # Python files
        yaml.enable = true;       # YAML files
        markdown.enable = true;   # Markdown files
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

**Note**: The self-contained template includes these formatters:

- ✅ **Nix**: alejandra
- ✅ **Web**: prettier (JS, TS, JSON, CSS, HTML, MD)
- ✅ **Shell**: shfmt
- ✅ **YAML**: yamlfmt

For more formatters (Python, Rust, etc.), use the full templates or configure manually.

---

## 🎯 What You Get Out of the Box

### 📋 **Formatters Available**

**Self-Contained Template** (works immediately):

- **Nix**: `alejandra`
- **Web**: `prettier` (JavaScript, TypeScript, CSS, JSON, HTML, Markdown)
- **Shell**: `shfmt`
- **YAML**: `yamlfmt`

**Full Templates** (require configuration, 15+ formatters):

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
- **Performance tracking**: See timing and file statistics

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

**Solution**: Make sure you've cloned the repository and are using the correct path:

```bash
ls ./treefmt-full-flake/templates/  # Should show template directories
```

### ❌ "error: access denied"

**Solution**: Use local clone method instead of SSH:

```bash
git clone git@github.com:LarsArtmann/treefmt-full-flake.git
nix flake init -t ./treefmt-full-flake#local-development
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

## 🌍 Future: Public Release

**Coming Q3 2025**: When the repository becomes public, usage will be even simpler:

```bash
# Future public access (not available yet)
nix flake init -t github:LarsArtmann/treefmt-full-flake#local-development
```

**Want to help with the public release?**

- Test the current access methods and report issues
- Provide feedback on the user experience
- Check out the [open issues](https://github.com/LarsArtmann/treefmt-full-flake/issues)

---

## ✅ Success! What Next?

1. **🎨 Customize your configuration** - Enable only the formatters you need
2. **⚡ Set up IDE integration** - Format on save in your editor
3. **🚀 Add to CI/CD** - Ensure consistent formatting in your pipeline
4. **📖 Read the full [README](./README.md)** - Discover advanced features

**Happy formatting!** 🎉
