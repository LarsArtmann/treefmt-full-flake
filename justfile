# treefmt-full-flake Justfile
# Developer commands following HOW_TO_NIX principles

# List available commands
default:
    @just --list

# Dogfood: Run all self-validation
# This ensures the project follows its own policies
dogfood:
    @echo "═══════════════════════════════════════════════════════════════"
    @echo "  RUNNING SELF-VALIDATION (Dogfood)"
    @echo "═══════════════════════════════════════════════════════════════"
    @echo ""
    @echo "Step 1/4: Checking formatting..."
    @nix fmt -- --check
    @echo ""
    @echo "Step 2/4: Running flake checks..."
    @nix flake check
    @echo ""
    @echo "Step 3/4: Running integration tests..."
    @nix build .#test-validation 2>/dev/null || ./tests/run-all-tests.sh
    @echo ""
    @echo "Step 4/4: Running branching-flow linters..."
    @branching-flow all .
    @echo ""
    @echo "═══════════════════════════════════════════════════════════════"
    @echo "  ✓ SELF-VALIDATION PASSED"
    @echo "═══════════════════════════════════════════════════════════════"

# Format all files in the repository using Nix
format:
    @echo "Formatting all files..."
    @nix fmt
    @echo "All formatting complete!"

# Check if all files are properly formatted
format-check:
    @echo "Checking formatting..."
    @nix fmt -- --check
    @echo "Formatting check passed!"

# Run flake checks (includes formatting validation)
check: format-check
    @echo "Running flake checks..."
    @nix flake check
    @echo "All code quality checks complete!"

# Run the test suite
test:
    @echo "Running test suite..."
    @nix build .#test-validation 2>/dev/null || ./tests/run-all-tests.sh

# Run tests in parallel
test-parallel:
    @echo "Running tests in parallel..."
    @./tests/run-tests-parallel.sh

# Setup git hooks
setup-hooks:
    @echo "Installing pre-commit hook..."
    @./scripts/setup-hooks.sh
    @echo "Git hooks installed!"

# Clean test artifacts
clean:
    @echo "Cleaning test artifacts..."
    @./scripts/cleanup-test-artifacts.sh
    @echo "Clean complete!"

# Build the project
build:
    @echo "Building project..."
    @nix build

# Development shell with all tools
dev:
    @echo "Entering development shell..."
    @nix develop

# Run a specific test
run-test test:
    @echo "Running test: {{test}}..."
    @./tests/{{test}}

# Generate test report
test-report:
    @echo "Generating test report..."
    @./tests/generate-test-report.sh

# Measure performance
benchmark:
    @echo "Running performance benchmarks..."
    @./tests/performance/measure-performance.sh

# Update flake inputs
update:
    @echo "Updating flake inputs..."
    @nix flake update

# Run performance tracking
perf:
    @echo "Running performance tracking..."
    @./tests/performance/measure-performance.sh
