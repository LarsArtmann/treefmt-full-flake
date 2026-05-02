package main

import (
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

type Config struct {
	ProjectRoot string
	Formatters  []string
	Incremental bool
}

type FormatterResult struct {
	Name      string
	Formatted int
	Failed    int
	ErrorMsg  string
}

type ValidationError struct {
	Field   string
	Message string
}

func (e ValidationError) Error() string {
	return e.Field + ": " + e.Message
}

func loadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	cfg := &Config{
		ProjectRoot: ".",
		Formatters:  []string{},
		Incremental: false,
	}

	content := string(data)
	for _, line := range strings.Split(content, "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		value := strings.Trim(strings.TrimSpace(parts[1]), "\"")

		switch key {
		case "projectRoot":
			cfg.ProjectRoot = value
		case "formatters":
			cfg.Formatters = strings.Split(value, ",")
		case "incremental":
			cfg.Incremental = value == "true"
		}
	}

	return cfg, nil
}

func validationError(field, message string) error {
	return ValidationError{Field: field, Message: message}
}

func validateConfig(cfg *Config) error {
	if cfg.ProjectRoot == "" {
		return validationError("ProjectRoot", "cannot be empty")
	}

	absPath, err := filepath.Abs(cfg.ProjectRoot)
	if err != nil {
		return validationError("ProjectRoot", err.Error())
	}
	cfg.ProjectRoot = absPath

	if len(cfg.Formatters) == 0 {
		return validationError("Formatters", "at least one formatter must be specified")
	}

	if slices.Contains(cfg.Formatters, "") {
		return validationError("Formatters", "formatter name cannot be empty")
	}

	return nil
}

func runFormatters(cfg *Config) ([]FormatterResult, error) {
	results := make([]FormatterResult, 0, len(cfg.Formatters))

	for _, formatter := range cfg.Formatters {
		result := FormatterResult{
			Name:      formatter,
			Formatted: 0,
			Failed:    0,
		}

		switch formatter {
		case "alejandra", "nixfmt", "biome", "black":
			result.Formatted = 10
		default:
			result.Failed = 1
			result.ErrorMsg = "unknown formatter"
		}

		results = append(results, result)
	}

	return results, nil
}

func printResults(results []FormatterResult) {
	for _, result := range results {
		if result.ErrorMsg != "" {
			fmt.Printf("  %s: ERROR - %s\n", result.Name, result.ErrorMsg)
		} else {
			fmt.Printf("  %s: formatted=%d, failed=%d\n", result.Name, result.Formatted, result.Failed)
		}
	}
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format, args...)
	os.Exit(1)
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: treefmt-test-helper <config-file>")
		fmt.Println("Environment variables:")
		fmt.Println("  TREEFMT_VERBOSE=1  Enable verbose output")
		os.Exit(1)
	}

	cfg, err := loadConfig(os.Args[1])
	if err != nil {
		fatal("Error loading config: %v\n", err)
	}

	if err := validateConfig(cfg); err != nil {
		fatal("Error validating config: %v\n", err)
	}

	verbose := os.Getenv("TREEFMT_VERBOSE") == "1"
	if verbose {
		fmt.Printf("Running formatters in %s\n", cfg.ProjectRoot)
		fmt.Printf("Incremental mode: %v\n", cfg.Incremental)
	}

	results, err := runFormatters(cfg)
	if err != nil {
		fatal("Error running formatters: %v\n", err)
	}

	if verbose {
		fmt.Println("\nFormatter results:")
	}
	printResults(results)
}
