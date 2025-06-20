#!/usr/bin/env bash
set -euo pipefail

echo "Testing alejandra formatting behavior..."

# Create test file 1 - short args
cat > test1.nix << 'EOF'
{pkgs,lib,...}:
{
  enable = true;
}
EOF

# Create test file 2 - longer args
cat > test2.nix << 'EOF'
{pkgs,lib,config,options,...}:
{
  enable = true;
}
EOF

echo -e "\n=== Test 1: Short args ==="
echo "Before:"
cat test1.nix
echo -e "\nAfter:"
alejandra test1.nix 2>/dev/null
cat test1.nix

echo -e "\n=== Test 2: Longer args ==="
echo "Before:"
cat test2.nix
echo -e "\nAfter:"
alejandra test2.nix 2>/dev/null
cat test2.nix

# Cleanup
rm -f test1.nix test2.nix