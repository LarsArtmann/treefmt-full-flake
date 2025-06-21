# ⚡ Quick Start: Format ANY codebase in 2 minutes

> **🚀 Get enterprise-grade code formatting with 15+ formatters in under 2 minutes**

## 🎯 What You'll Get

✨ **15+ formatters** for Nix, JavaScript, Python, Rust, YAML, Markdown, and more\
⚡ **10-100x faster** formatting with incremental mode\
🔧 **Zero configuration** - smart defaults that just work\
🎨 **IDE integration** - format-on-save for JetBrains, VS Code, Neovim

---

## 🚀 Method 1: Template Magic (30 seconds)

**Copy, paste, done!** Use our pre-built template:

```bash
# Create new project with treefmt already configured
nix flake init -t github:LarsArtmann/treefmt-full-flake
or
nix flake init -t git+ssh://git@github.com/LarsArtmann/treefmt-full-flake (works for private repos)

# Test it works (formats this file!)
nix fmt

# See what formatters you got
nix flake show
```

**✅ You're done!** Your project now has professional formatting.

---

## 🛠️ Method 2: Add to Existing Project (90 seconds)

### Step 1: Add to your `flake.nix` (30 seconds)

Drop this into your `inputs` section:

```nix
treefmt-flake = {
  url = "github:LarsArtmann/treefmt-full-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Step 2: Import and enable (30 seconds)

Add to your flake:

```nix
imports = [
  inputs.treefmt-flake.flakeModule
];

treefmtFlake = {
  nix = true;        # Format .nix files
  web = true;        # Format JS/TS/CSS
  python = true;     # Format Python
  shell = true;      # Format shell scripts
  yaml = true;       # Format YAML
  markdown = true;   # Format Markdown
  json = true;       # Format JSON

  # Optional: Use deterministic nixfmt-rfc-style instead of alejandra
  # nixFormatter = "nixfmt-rfc-style";
};
```

### Step 3: Test it works! (30 seconds)

```bash
# Format everything
nix fmt

# Just check (fail if changes needed)
nix fmt -- --fail-on-change
```

**🎉 Success!** You now have industrial-strength formatting.

---

## 🔥 Instant Demo: See It Work

Create some messy files and watch the magic:

```bash
# Create a messy JavaScript file
cat > test.js << 'EOF'
const  x={a:1,b:2};if(x.a>0){console.log("hello world");}
EOF

# Create messy Nix code
cat > test.nix << 'EOF'
{pkgs}:{foo=1;bar=pkgs.hello;}
EOF

# Watch treefmt clean it up
nix fmt

# Check the results
cat test.js test.nix
```

**Before**: Unreadable mess\
**After**: Perfectly formatted, consistent code

---

## ⚡ Supercharge It: Pro Tips

**Want even more power?** Here are some advanced techniques:

```bash
# Format specific files only
nix fmt path/to/file.js path/to/other.nix

# Check formatting (fail if changes needed)
nix fmt -- --fail-on-change

# Use in CI/CD pipelines
nix fmt -- --fail-on-change
```

**🚀 Want 10-100x faster incremental formatting?**
Check out our [Complete Template](./templates/complete/flake.nix) for advanced configurations including git-based incremental formatting!

---

## 🎨 IDE Integration: Format-on-Save

### JetBrains (IntelliJ, WebStorm, PyCharm)

```bash
# One-line setup
nix build && echo "Add File Watcher: Program: ./result/bin/treefmt, Args: \$FilePath\$"
```

### VS Code

```bash
# Coming soon - meanwhile use Command Palette: "Nix Fmt"
```

### Neovim

```lua
-- Add to your config
vim.keymap.set('n', '<leader>f', ':!nix fmt<CR>')
```

---

## 🎊 What Just Happened?

You now have **enterprise-grade formatting** with:

| Language                  | Formatters                 | What It Does                             |
| ------------------------- | -------------------------- | ---------------------------------------- |
| **Nix**                   | alejandra, deadnix, statix | Clean syntax, remove dead code, lint     |
| **JavaScript/TypeScript** | biome                      | Format, lint, organize imports           |
| **Python**                | black, isort, ruff         | PEP8 formatting, import sorting, linting |
| **Rust**                  | rustfmt                    | Official Rust formatting                 |
| **Shell**                 | shfmt, shellcheck          | POSIX formatting, syntax checking        |
| **YAML**                  | yamlfmt                    | Consistent YAML formatting               |
| **Markdown**              | mdformat                   | Clean markdown with numbered headings    |
| **JSON**                  | jsonfmt, jq                | Pretty-print and validate JSON           |

---

## 🚀 Next Level: Power Features

Ready to level up? Check out these advanced features:

### 📁 **Templates & Examples**

```bash
nix flake init -t github:LarsArtmann/treefmt-full-flake#complete  # Full power
nix flake init -t github:LarsArtmann/treefmt-full-flake#minimal  # Just basics
```

### ⚡ **Performance Modes**

- `fast` - Skip expensive checks (development)
- `balanced` - Smart performance (default)
- `thorough` - Full validation (CI/CD)

### 🔧 **Custom Configuration**

- Override formatter options
- Add custom formatters
- Configure excludes and includes
- Set up pre-commit hooks

### 🤖 **CI/CD Integration**

```yaml
# GitHub Actions
- run: nix fmt -- --fail-on-change # Fail if unformatted
```

---

## 📚 Learn More

- **[Full Documentation](./README.md)** - All features and options
- **[Incremental Formatting](./INCREMENTAL.md)** - 10-100x performance guide
- **[JetBrains Integration](./docs/jetbrains-integration.md)** - Detailed IDE setup
- **[Templates](./templates/)** - Ready-to-use project templates

---

## 🆘 Troubleshooting

### "command not found: nix"

```bash
# Install Nix first
curl -L https://nixos.org/nix/install | sh
```

### "error: flake not found"

```bash
# Enable flakes
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "formatters missing"

```bash
# Let treefmt download them
nix develop  # Enters shell with all formatters
```

### "permission denied"

```bash
# Make sure treefmt is executable
nix build && chmod +x result/bin/treefmt
```

---

## 🎉 You Did It!

**Congratulations!** You now have:

✅ Professional code formatting across 8+ languages\
✅ Lightning-fast incremental formatting\
✅ IDE integration ready to go\
✅ Enterprise-grade tooling for any project size

**Ready to format the world?** 🌍✨

---

> **💡 Pro Tip**: Star the repo and share with your team - consistent formatting makes everyone's life better!

**[⭐ Star on GitHub](https://github.com/LarsArtmann/treefmt-full-flake)** | **[🐛 Report Issues](https://github.com/LarsArtmann/treefmt-full-flake/issues)** | **[💬 Discussions](https://github.com/LarsArtmann/treefmt-full-flake/discussions)**
