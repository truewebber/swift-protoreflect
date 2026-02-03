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
	@echo "  make test-examples            - Run all 38 working examples to verify they work correctly."
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
	$(SWIFT_TEST) --enable-code-coverage --parallel --filter SwiftProtoReflectTests --disable-swift-testing
	@echo "Tests complete."

## Generate a code coverage report
coverage:
	@echo "Generating code coverage report..."
	xcrun llvm-profdata merge -sparse .build/arm64-apple-macosx/debug/codecov/*.profraw -o .build/arm64-apple-macosx/debug/codecov/merged.profdata
	xcrun llvm-cov report \
		.build/arm64-apple-macosx/debug/SwiftProtoReflectPackageTests.xctest/Contents/MacOS/SwiftProtoReflectPackageTests \
		-instr-profile=.build/arm64-apple-macosx/debug/codecov/merged.profdata \
		-name-regex="^Sources/SwiftProtoReflect/" \
		-ignore-filename-regex=".build|Tests|checkouts" \
		-use-color


## Run all 38 working examples to verify they work correctly
test-examples:
	@echo "Running all 38 working examples to verify they work correctly..."
	@echo "(Excluding ProtoREPL - interactive example that requires user input)"
	@cd examples && \
	examples=( \
		"HelloWorld" "FieldTypes" "SimpleMessage" "BasicDescriptors" \
		"ComplexMessages" "NestedOperations" "NestedTypes" "FieldManipulation" "MessageCloning" "ConditionalLogic" "PerformanceOptimization" \
		"ProtobufSerialization" "JsonConversion" "BinaryData" "Streaming" "Compression" \
		"TypeRegistry" "FileLoading" "DependencyResolution" "SchemaValidation" \
		"TimestampDemo" "DurationDemo" "EmptyDemo" "FieldMaskDemo" "StructDemo" "ValueDemo" "AnyDemo" "WellKnownRegistry" \
		"DescriptorBridge" "StaticMessageBridge" "BatchOperations" "MemoryOptimization" "ThreadSafety" "CustomExtensions" \
		"ConfigurationSystem" "ApiGateway" "MessageTransform" "ValidationFramework" \
	); \
	failed=(); \
	passed=0; \
	total=$${#examples[@]}; \
	echo "Found $$total examples to test..."; \
	echo ""; \
	for example in "$${examples[@]}"; do \
		printf "%-25s" "$$example"; \
		if swift run $$example >/dev/null 2>&1; then \
			echo "✅ PASSED"; \
			((passed++)); \
		else \
			echo "❌ FAILED"; \
			failed+=("$$example"); \
		fi; \
	done; \
	echo ""; \
	echo "Summary: $$passed/$$total examples passed"; \
	if [ $${#failed[@]} -eq 0 ]; then \
		echo "🎉 All working examples are passing!"; \
		echo ""; \
		echo "Note: Interactive examples are excluded from automated testing:"; \
		echo "  ProtoREPL - Interactive example (requires user input):"; \
		echo "    cd examples && swift run ProtoREPL"; \
	else \
		echo "❌ Failed examples:"; \
		for fail in "$${failed[@]}"; do \
			echo "  - $$fail"; \
		done; \
		echo ""; \
		echo "To debug a specific example, run:"; \
		echo "  cd examples && swift run <example_name>"; \
		exit 1; \
	fi

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
