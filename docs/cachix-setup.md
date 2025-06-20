# Cachix Setup Guide

This guide explains how to set up Cachix for faster CI builds in the treefmt-full-flake project.

## What is Cachix?

Cachix is a binary cache service for Nix that dramatically speeds up builds by sharing compiled artifacts between CI runs and developers.

## Setup Instructions

### 1. Create a Cachix Account

1. Go to [cachix.org](https://cachix.org) and sign up
2. Create a new cache named `treefmt-full-flake`

### 2. Generate an Auth Token

1. Go to your Cachix account settings
2. Generate a new auth token with write access
3. Copy the token (you'll need it for the next step)

### 3. Add GitHub Secret

1. Go to the GitHub repository settings
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `CACHIX_AUTH_TOKEN`
5. Value: Paste your Cachix auth token
6. Click "Add secret"

### 4. Enable Cachix in CI

The CI workflows are already configured to use Cachix. Once you add the `CACHIX_AUTH_TOKEN` secret, the workflows will automatically:

- Pull cached build artifacts before building
- Push new build artifacts after successful builds (only on main/master branch)

## Local Development

To use Cachix locally:

```bash
# Install cachix
nix-env -iA cachix -f https://cachix.org/api/v1/install

# Configure the cache
cachix use treefmt-full-flake

# Optional: Sign in to push to cache
cachix authtoken YOUR_AUTH_TOKEN
```

## Benefits

With Cachix enabled, you can expect:

- **CI builds**: 5-10x faster (from ~5 minutes to ~30 seconds)
- **Local builds**: Instant when artifacts are cached
- **Bandwidth savings**: No need to rebuild common dependencies

## Monitoring Cache Usage

Visit `https://app.cachix.org/cache/treefmt-full-flake` to see:

- Cache size and usage
- Recent pushes
- Download statistics

## Troubleshooting

### CI not using cache

Check that:
1. `CACHIX_AUTH_TOKEN` secret is set correctly
2. The cache name matches in workflows (`treefmt-full-flake`)
3. The Cachix action version is up to date

### Local builds not using cache

Ensure you've run:
```bash
cachix use treefmt-full-flake
```

This adds the cache to your Nix configuration.