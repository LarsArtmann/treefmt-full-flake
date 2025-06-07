# JetBrains Configuration Files

This directory contains ready-to-use JetBrains IDE configuration files for treefmt integration.

## Files

- `treefmt.xml` - File Watcher configurations for various file types
- `setup-jetbrains.sh` - Automated setup script
- Example `.idea` configurations

## Quick Setup

From your project root:

```bash
# Download and run the setup script
curl -sSL https://raw.githubusercontent.com/LarsArtmann/treefmt-full-flake/master/docs/jetbrains-configs/setup-jetbrains.sh | bash
```

## Manual Setup

1. Copy the desired XML configuration to your project's `.idea` directory
2. Adjust paths if necessary
3. Restart your JetBrains IDE

## Import File Watcher

1. Go to **Settings → Tools → File Watchers**
2. Click the **Import** button
3. Select `treefmt.xml` from this directory
4. Enable the watchers you want to use

## Customization

Edit the XML files to:

- Change file type associations
- Modify command arguments
- Add environment variables
- Adjust performance settings

## Troubleshooting

If File Watchers don't work:

1. Ensure `nix build` has been run in your project
2. Check that `./result/bin/treefmt` exists
3. Verify file permissions
4. Check IDE Event Log for errors
