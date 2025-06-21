# Template Testing Documentation

This directory contains comprehensive test suites for validating the treefmt-full-flake templates.

## Overview

The testing framework ensures that all templates (minimal, default, complete) work correctly by:

- Initializing templates in isolated environments
- Creating test files with formatting issues
- Running formatters and verifying corrections
- Testing development shells and additional features

## Test Structure

```
tests/
├── README.md                    # This documentation
├── run-all-tests.sh            # Master test runner
├── setup-ci.sh                 # CI environment setup
└── templates/
    ├── test-wrapper.sh         # Helper functions for CI mode
    ├── test-minimal.sh         # Tests minimal template
    ├── test-default.sh         # Tests default template
    └── test-complete.sh        # Tests complete template
```

## Running Tests

### Local Testing

Run all tests:

```bash
./tests/run-all-tests.sh
```

Run specific template test:

```bash
./tests/run-all-tests.sh minimal
./tests/run-all-tests.sh default
./tests/run-all-tests.sh complete
```

Run individual test directly:

```bash
./tests/templates/test-minimal.sh
```

### CI Testing

The tests automatically adapt for CI environments. The GitHub Actions workflow:

1. Runs `setup-ci.sh` to create mock repositories
1. Patches templates to use local file:// URLs instead of SSH
1. Executes tests with CI-specific configurations

## Test Coverage

### Minimal Template

- **Formatters**: Nix (alejandra), Markdown (mdformat), YAML (yamlfmt)
- **Features**: Basic formatting, development shell

### Default Template

- **Formatters**: All from minimal plus Python (black, isort, ruff), Web (biome), Shell (shfmt), JSON
- **Features**: Justfile integration, multi-language support

### Complete Template

- **Formatters**: All available formatters including Rust, TOML, Protocol Buffers, GitHub Actions
- **Features**: Incremental formatting, performance profiles, advanced configurations

## Test Steps

Each test follows this sequence:

1. **Template Initialization** - Creates template in temporary directory
1. **Git Repository Setup** - Initializes git for version control features
1. **File Verification** - Ensures template files exist
1. **Flake Metadata Check** - Validates flake configuration
1. **Test File Creation** - Creates files with formatting issues
1. **Flake Check** - Runs `nix flake check`
1. **Formatter Execution** - Runs `nix fmt`
1. **Format Verification** - Checks files were correctly formatted
1. **Format Check Mode** - Tests `--fail-on-change` flag
1. **Development Shell** - Validates shell environment

## CI Configuration

### SSH Repository Issue

Since the repository is private, CI environments need special handling:

1. **Mock Repository**: `setup-ci.sh` creates a local bare git repository
1. **Template Patching**: Creates `-ci` variants with `file://` URLs
1. **Dynamic Path Resolution**: `test-wrapper.sh` provides path selection logic

### Environment Variables

- `TREEFMT_TEST_CI_MODE` - Enables CI mode in tests
- `TREEFMT_FLAKE_MOCK_REPO` - Path to mock repository

## Troubleshooting

### Common Issues

**Test fails with "flake requires lock file changes"**

- Ensure git is initialized in test directory
- Check that flake inputs are properly locked

**Formatter not found**

- Verify formatter is enabled in template configuration
- Check that Nix cache is populated

**SSH authentication errors**

- Run `setup-ci.sh` to use mock repository
- Ensure templates use correct URL format

### Debug Mode

Run tests with bash debugging:

```bash
bash -x ./tests/templates/test-minimal.sh
```

Check test output in temporary directory (path shown in test output).

## Adding New Tests

To add tests for new formatters:

1. Add test files in appropriate test script
1. Create files with known formatting issues
1. Add verification checks after formatting
1. Update this documentation

Example:

```bash
# Create test file
cat > test.ext << 'EOF'
unformatted content
EOF

# After formatting, verify
if ! grep -q "expected formatted content" test.ext; then
    echo "Formatting failed"
    exit 1
fi
```

## GitHub Actions Integration

The workflow runs on:

- Push to master/main affecting templates or tests
- Pull requests with template/test changes
- Manual workflow dispatch

Tests run on both Ubuntu and macOS to ensure cross-platform compatibility.

## Performance Considerations

- Tests use timeouts to prevent hanging
- Temporary directories are cleaned up automatically
- Nix store paths are cached in CI
- Parallel test execution where possible

## Future Improvements

- [ ] Add performance benchmarking
- [ ] Test error scenarios and edge cases
- [ ] Add integration with real projects
- [ ] Create visual test result dashboard
- [ ] Add mutation testing for formatters
