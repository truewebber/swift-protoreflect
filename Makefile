# Makefile for Swift project

# Default target: show help
.DEFAULT_GOAL := help

# --- Variables --------------------------------------------------
# Default Swift toolchain - can be overridden via environment variable or command line
# e.g., make lint SWIFT_TOOLCHAIN=org.swift.592202312111a
SWIFT_TOOLCHAIN ?= 

# Define Swift commands with toolchain
ifeq ($(strip $(SWIFT_TOOLCHAIN)),)
  # Use default toolchain if not specified
  SWIFT_FORMAT := swift format
  SWIFT_TEST   := swift test
else
  # Use specified toolchain
  SWIFT_FORMAT := /usr/bin/xcrun --toolchain $(SWIFT_TOOLCHAIN) --run swift format
  SWIFT_TEST   := /usr/bin/xcrun --toolchain $(SWIFT_TOOLCHAIN) --run swift test
endif

# --- Targets ----------------------------------------------------

## Show help (usage) for this Makefile
help:
	@echo "Available targets:"
	@echo "  make lint                     - Lint the Swift code (non-destructive check)."
	@echo "  make format                   - Format the Swift code in-place."
	@echo "  make test                     - Run unit tests."
	@echo "  make coverage                 - Generate a code coverage report."
	@echo "  make coverage-detailed        - Generate a detailed code coverage report."
	@echo "  make list-toolchains          - List available Swift toolchains."
	@echo ""
	@echo "Environment variables:"
	@echo "  SWIFT_TOOLCHAIN               - Swift toolchain identifier (default: system default)"
	@echo "                                  Example: make lint SWIFT_TOOLCHAIN=org.swift.592202312111a"
	@echo ""
	@echo "Run 'make list-toolchains' to see available toolchains on your system."

## Lint the Swift code (non-destructive check)
lint:
	@echo "Running swift-format in lint mode..."
	$(SWIFT_FORMAT) lint -s --configuration .swift-format.json --recursive ./
	@echo "Lint complete."

## Format the Swift code in-place
format:
	@echo "Running swift-format in format mode..."
	$(SWIFT_FORMAT) --configuration .swift-format.json --recursive -i ./
	@echo "Format complete."

## Run tests
test:
	@echo "Running swift test..."
	$(SWIFT_TEST) -q --filter SwiftProtoReflectTests
	@echo "Tests complete."

bench:
	@echo "Running swift test..."
	$(SWIFT_TEST) -q --filter SwiftProtoReflectBenchmarks
	@echo "Tests complete."

## Generate a code coverage report
coverage:
	@echo "Generating code coverage report..."
	./coverage-report.sh
	@echo "Coverage report complete. See docs/SwiftProtoReflect_Coverage_Report.md for details."

## List available Swift toolchains
list-toolchains:
	@echo "\033[1mSwift Toolchains Available on Your System\033[0m"
	@echo "------------------------------------------------"
	@echo ""
	@echo "\033[1m1. Default Xcode Toolchain:\033[0m"
	@swift --version | head -n 1
	@echo ""
	
	@if [ -d "/Library/Developer/Toolchains/" ]; then \
		echo "\033[1m2. Additional Toolchains:\033[0m"; \
		echo ""; \
		found=0; \
		for toolchain in $$(find /Library/Developer/Toolchains/ -type d -name "*.xctoolchain" -not -path "*/\.*" | sort); do \
			if [ ! -L "$$toolchain" ]; then \
				info_plist="$$toolchain/Info.plist"; \
				if [ -f "$$info_plist" ]; then \
					bundle_id=$$(plutil -extract CFBundleIdentifier raw "$$info_plist" 2>/dev/null); \
					if [ "$$?" -eq 0 ] && [ -n "$$bundle_id" ]; then \
						found=1; \
						toolchain_name=$$(basename "$$toolchain" .xctoolchain); \
						echo "  \033[1m$$toolchain_name\033[0m"; \
						echo "    • Location:  $$toolchain"; \
						echo "    • Bundle ID: \033[36m$$bundle_id\033[0m"; \
						echo "    • Usage:     make lint SWIFT_TOOLCHAIN=$$bundle_id"; \
						echo ""; \
					fi; \
				fi; \
			fi; \
		done; \
		if [ $$found -eq 0 ]; then \
			echo "  No valid toolchains found in /Library/Developer/Toolchains/"; \
		fi; \
	else \
		echo "\033[1m2. Additional Toolchains:\033[0m"; \
		echo "  No toolchains directory found at /Library/Developer/Toolchains/"; \
	fi
