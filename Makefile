# Makefile for Swift project

# Default target: show help
.DEFAULT_GOAL := help

# --- Variables --------------------------------------------------
SWIFT_FORMAT := swift format
SWIFT_TEST   := swift test

# --- Targets ----------------------------------------------------

## Show help (usage) for this Makefile
help:
	@echo "Available targets:"
	@echo "  make lint         - Lint the Swift code (non-destructive check)."
	@echo "  make format       - Format the Swift code in-place."
	@echo "  make test         - Run unit tests."
	@echo "  make docker-test  - Run tests in a Docker container with Swift 5.9."
	@echo "  make docker-lint  - Run lint in a Docker container with Swift 5.9."

## Lint the Swift code (non-destructive check)
lint:
	@echo "Running swift-format in lint mode..."
	$(SWIFT_FORMAT) lint --configuration .swift-format.json --recursive ./
	@echo "Lint complete."

## Format the Swift code in-place
format:
	@echo "Running swift-format in format mode..."
	$(SWIFT_FORMAT) --configuration .swift-format.json --recursive -i ./
	@echo "Format complete."

## Run tests
test:
	@echo "Running swift test..."
	$(SWIFT_TEST) -q
	@echo "Tests complete."
