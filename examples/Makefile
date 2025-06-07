# SwiftProtoReflect Examples Makefile

.PHONY: help setup build clean run-all run-basic run-dynamic run-serialization run-registry run-wellknown run-grpc run-advanced run-realworld demo list-examples check-example

# Цвета для вывода
GREEN = \033[0;32m
YELLOW = \033[1;33m  
RED = \033[0;31m
BLUE = \033[0;34m
PURPLE = \033[0;35m
CYAN = \033[0;36m
NC = \033[0m # No Color

# Переменные
BUILD_CONFIG = release
LIBRARY_PATH = ../.build/$(BUILD_CONFIG)
SWIFT_FLAGS = -I $(LIBRARY_PATH) -L $(LIBRARY_PATH) -lSwiftProtoReflect

help:
	@echo "$(GREEN)SwiftProtoReflect Examples$(NC)"
	@echo "============================="
	@echo ""
	@echo "$(YELLOW)🚀 Quick Start:$(NC)"
	@echo "  $(BLUE)make setup$(NC)          - Build SwiftProtoReflect library"
	@echo "  $(BLUE)make run-all$(NC)        - Run all examples with progress report"  
	@echo "  $(BLUE)make demo$(NC)           - Interactive demo mode"
	@echo ""
	@echo "$(YELLOW)📚 Examples by Category:$(NC)"
	@echo "  $(BLUE)make run-basic$(NC)      - 🔰 Basic usage examples (4 examples)"
	@echo "  $(BLUE)make run-dynamic$(NC)    - 🔧 Dynamic messages examples (5 examples)"
	@echo "  $(BLUE)make run-serialization$(NC) - 💾 Serialization examples (6 examples)"
	@echo "  $(BLUE)make run-registry$(NC)   - 🗂 Registry examples (4 examples)"
	@echo "  $(BLUE)make run-wellknown$(NC)  - ⭐ Well-known types examples (8 examples)"
	@echo "  $(BLUE)make run-grpc$(NC)       - 🌐 gRPC examples (5 examples)"
	@echo "  $(BLUE)make run-advanced$(NC)   - 🚀 Advanced examples (6 examples)"
	@echo "  $(BLUE)make run-realworld$(NC)  - 🏢 Real-world examples (5 examples)"
	@echo ""
	@echo "$(YELLOW)🛠 Utilities:$(NC)"
	@echo "  $(BLUE)make list-examples$(NC)  - List all available examples"
	@echo "  $(BLUE)make check-example$(NC)  - Run specific example (use EXAMPLE=path)"
	@echo "  $(BLUE)make clean$(NC)          - Clean build artifacts"
	@echo ""
	@echo "$(YELLOW)💡 Examples:$(NC)"
	@echo "  $(PURPLE)make check-example EXAMPLE=01-basic-usage/hello-world.swift$(NC)"
	@echo "  $(PURPLE)make run-basic          # Run all basic examples$(NC)"

setup:
	@echo "$(YELLOW)🔨 Building SwiftProtoReflect library...$(NC)"
	@cd .. && swift build -c $(BUILD_CONFIG)
	@echo "$(GREEN)✅ Library built successfully!$(NC)"

build: setup

run-all: setup
	@echo "$(GREEN)🚀 Running all SwiftProtoReflect examples...$(NC)"
	@echo "$(BLUE)This will run all 43 examples across 8 categories$(NC)"
	@echo ""
	@./run-all.sh

run-basic: setup
	@echo "$(GREEN)🔰 Running basic usage examples...$(NC)"
	@echo "$(BLUE)Learning the fundamentals of SwiftProtoReflect$(NC)"
	@echo ""
	@for example in 01-basic-usage/*.swift; do \
		if [ -f "$$example" ]; then \
			echo "$(YELLOW)▶ Running $$(basename $$example .swift)...$(NC)"; \
			swift $(SWIFT_FLAGS) "$$example" || exit 1; \
			echo ""; \
		fi; \
	done
	@echo "$(GREEN)✅ Basic examples completed!$(NC)"

run-dynamic: setup
	@echo "$(GREEN)🔧 Running dynamic messages examples...$(NC)"  
	@echo "$(BLUE)Advanced dynamic message manipulation$(NC)"
	@echo ""
	@for example in 02-dynamic-messages/*.swift; do \
		if [ -f "$$example" ]; then \
			echo "$(YELLOW)▶ Running $$(basename $$example .swift)...$(NC)"; \
			swift $(SWIFT_FLAGS) "$$example" || exit 1; \
			echo ""; \
		fi; \
	done
	@echo "$(GREEN)✅ Dynamic messages examples completed!$(NC)"

run-serialization: setup
	@echo "$(GREEN)💾 Running serialization examples...$(NC)"
	@echo "$(BLUE)Binary and JSON serialization/deserialization$(NC)"
	@echo ""
	@for example in 03-serialization/*.swift; do \
		if [ -f "$$example" ]; then \
			echo "$(YELLOW)▶ Running $$(basename $$example .swift)...$(NC)"; \
			swift $(SWIFT_FLAGS) "$$example" || exit 1; \
			echo ""; \
		fi; \
	done
	@echo "$(GREEN)✅ Serialization examples completed!$(NC)"

run-registry: setup
	@echo "$(GREEN)🗂 Running registry examples...$(NC)"
	@echo "$(BLUE)Centralized type management and discovery$(NC)"
	@echo ""
	@for example in 04-registry/*.swift; do \
		if [ -f "$$example" ]; then \
			echo "$(YELLOW)▶ Running $$(basename $$example .swift)...$(NC)"; \
			swift $(SWIFT_FLAGS) "$$example" || exit 1; \
			echo ""; \
		fi; \
	done
	@echo "$(GREEN)✅ Registry examples completed!$(NC)"

run-wellknown: setup
	@echo "$(GREEN)⭐ Running well-known types examples...$(NC)"
	@echo "$(BLUE)Google Protocol Buffers standard types$(NC)"
	@echo ""
	@for example in 05-well-known-types/*.swift; do \
		if [ -f "$$example" ]; then \
			echo "$(YELLOW)▶ Running $$(basename $$example .swift)...$(NC)"; \
			swift $(SWIFT_FLAGS) "$$example" || exit 1; \
			echo ""; \
		fi; \
	done
	@echo "$(GREEN)✅ Well-known types examples completed!$(NC)"

run-grpc: setup
	@echo "$(GREEN)🌐 Running gRPC examples...$(NC)"
	@echo "$(BLUE)Dynamic gRPC client functionality$(NC)"
	@echo ""
	@for example in 06-grpc/*.swift; do \
		if [ -f "$$example" ]; then \
			echo "$(YELLOW)▶ Running $$(basename $$example .swift)...$(NC)"; \
			swift $(SWIFT_FLAGS) "$$example" || exit 1; \
			echo ""; \
		fi; \
	done
	@echo "$(GREEN)✅ gRPC examples completed!$(NC)"

run-advanced: setup
	@echo "$(GREEN)🚀 Running advanced examples...$(NC)"
	@echo "$(BLUE)Complex integration scenarios and optimizations$(NC)"
	@echo ""
	@for example in 07-advanced/*.swift; do \
		if [ -f "$$example" ]; then \
			echo "$(YELLOW)▶ Running $$(basename $$example .swift)...$(NC)"; \
			swift $(SWIFT_FLAGS) "$$example" || exit 1; \
			echo ""; \
		fi; \
	done
	@echo "$(GREEN)✅ Advanced examples completed!$(NC)"

run-realworld: setup
	@echo "$(GREEN)🏢 Running real-world examples...$(NC)"
	@echo "$(BLUE)Production-ready architectural patterns$(NC)"
	@echo ""
	@for example in 08-real-world/*.swift; do \
		if [ -f "$$example" ]; then \
			echo "$(YELLOW)▶ Running $$(basename $$example .swift)...$(NC)"; \
			swift $(SWIFT_FLAGS) "$$example" || exit 1; \
			echo ""; \
		fi; \
	done
	@echo "$(GREEN)✅ Real-world examples completed!$(NC)"

demo: setup
	@echo "$(GREEN)🎮 Starting interactive demo...$(NC)"
	@if [ -f "./interactive-demo.sh" ]; then \
		./interactive-demo.sh; \
	else \
		echo "$(RED)❌ Interactive demo script not found$(NC)"; \
		echo "$(YELLOW)Run 'make run-all' for automated execution$(NC)"; \
	fi

clean:
	@echo "$(YELLOW)🧹 Cleaning build artifacts...$(NC)"
	@cd .. && swift package clean
	@echo "$(GREEN)✅ Clean completed!$(NC)"

# Утилити команды
check-example: setup
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)❌ Please specify EXAMPLE variable$(NC)"; \
		echo "$(YELLOW)Usage: make check-example EXAMPLE=01-basic-usage/hello-world.swift$(NC)"; \
		echo ""; \
		echo "$(BLUE)Available examples:$(NC)"; \
		find . -name "*.swift" -not -path "./shared/*" | sort | sed 's|^\./||' | head -10; \
		echo "$(YELLOW)... and more. Use 'make list-examples' for full list$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(EXAMPLE)" ]; then \
		echo "$(RED)❌ Example file not found: $(EXAMPLE)$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)🔍 Checking $(EXAMPLE)...$(NC)"
	@echo "$(BLUE)$(shell head -n 5 $(EXAMPLE) | grep "Описание:" | sed 's/.*Описание: //' | sed 's/ \*\/.*//g')$(NC)"
	@echo ""
	@swift $(SWIFT_FLAGS) $(EXAMPLE)
	@echo ""
	@echo "$(GREEN)✅ Example completed successfully!$(NC)"

list-examples:
	@echo "$(GREEN)📋 Available examples:$(NC)"
	@echo ""
	@echo "$(YELLOW)🔰 Basic Usage (01-basic-usage/):$(NC)"
	@find 01-basic-usage -name "*.swift" 2>/dev/null | sort | sed 's|^|  |' || echo "  (No examples yet)"
	@echo ""
	@echo "$(YELLOW)🔧 Dynamic Messages (02-dynamic-messages/):$(NC)"
	@find 02-dynamic-messages -name "*.swift" 2>/dev/null | sort | sed 's|^|  |' || echo "  (No examples yet)"
	@echo ""
	@echo "$(YELLOW)💾 Serialization (03-serialization/):$(NC)"
	@find 03-serialization -name "*.swift" 2>/dev/null | sort | sed 's|^|  |' || echo "  (No examples yet)"
	@echo ""
	@echo "$(YELLOW)🗂 Registry (04-registry/):$(NC)"
	@find 04-registry -name "*.swift" 2>/dev/null | sort | sed 's|^|  |' || echo "  (No examples yet)"
	@echo ""
	@echo "$(YELLOW)⭐ Well-Known Types (05-well-known-types/):$(NC)"
	@find 05-well-known-types -name "*.swift" 2>/dev/null | sort | sed 's|^|  |' || echo "  (No examples yet)"
	@echo ""
	@echo "$(YELLOW)🌐 gRPC (06-grpc/):$(NC)"
	@find 06-grpc -name "*.swift" 2>/dev/null | sort | sed 's|^|  |' || echo "  (No examples yet)"
	@echo ""
	@echo "$(YELLOW)🚀 Advanced (07-advanced/):$(NC)"
	@find 07-advanced -name "*.swift" 2>/dev/null | sort | sed 's|^|  |' || echo "  (No examples yet)"
	@echo ""
	@echo "$(YELLOW)🏢 Real-World (08-real-world/):$(NC)"
	@find 08-real-world -name "*.swift" 2>/dev/null | sort | sed 's|^|  |' || echo "  (No examples yet)"
	@echo ""
	@echo "$(BLUE)Total examples: $(shell find . -name "*.swift" -not -path "./shared/*" | wc -l | tr -d ' ')$(NC)"

# Проверка системы
check-system:
	@echo "$(YELLOW)🔍 System Check$(NC)"
	@echo "$(BLUE)Checking Swift version...$(NC)"
	@swift --version || (echo "$(RED)❌ Swift not found$(NC)"; exit 1)
	@echo ""
	@echo "$(BLUE)Checking if SwiftProtoReflect library exists...$(NC)"
	@if [ -d "$(LIBRARY_PATH)" ]; then \
		echo "$(GREEN)✅ Library path exists: $(LIBRARY_PATH)$(NC)"; \
		ls -la $(LIBRARY_PATH)/ | head -5; \
	else \
		echo "$(RED)❌ Library not found. Run 'make setup' first$(NC)"; \
	fi

# Статистика примеров
stats:
	@echo "$(GREEN)📊 Examples Statistics$(NC)"
	@echo ""
	@echo "$(YELLOW)Examples by category:$(NC)"
	@echo "  🔰 Basic Usage: $(shell find 01-basic-usage -name "*.swift" 2>/dev/null | wc -l | tr -d ' ') examples"
	@echo "  🔧 Dynamic Messages: $(shell find 02-dynamic-messages -name "*.swift" 2>/dev/null | wc -l | tr -d ' ') examples"
	@echo "  💾 Serialization: $(shell find 03-serialization -name "*.swift" 2>/dev/null | wc -l | tr -d ' ') examples"
	@echo "  🗂 Registry: $(shell find 04-registry -name "*.swift" 2>/dev/null | wc -l | tr -d ' ') examples"
	@echo "  ⭐ Well-Known Types: $(shell find 05-well-known-types -name "*.swift" 2>/dev/null | wc -l | tr -d ' ') examples"
	@echo "  🌐 gRPC: $(shell find 06-grpc -name "*.swift" 2>/dev/null | wc -l | tr -d ' ') examples"
	@echo "  🚀 Advanced: $(shell find 07-advanced -name "*.swift" 2>/dev/null | wc -l | tr -d ' ') examples"
	@echo "  🏢 Real-World: $(shell find 08-real-world -name "*.swift" 2>/dev/null | wc -l | tr -d ' ') examples"
	@echo ""
	@echo "$(BLUE)Total: $(shell find . -name "*.swift" -not -path "./shared/*" | wc -l | tr -d ' ') examples$(NC)"
	@echo "$(BLUE)Target: 43 examples$(NC)"
