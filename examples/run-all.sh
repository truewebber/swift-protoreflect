#!/bin/bash

# SwiftProtoReflect Examples - Automated Runner
# Запускает все примеры с детальным отчетом о прогрессе и результатах

set -e

# Конфигурация
BUILD_CONFIG="release"
LIBRARY_PATH="../.build/${BUILD_CONFIG}"
SWIFT_FLAGS="-I ${LIBRARY_PATH} -L ${LIBRARY_PATH} -lSwiftProtoReflect"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Статистика
TOTAL_EXAMPLES=0
PASSED_EXAMPLES=0
FAILED_EXAMPLES=0
START_TIME=$(date +%s)

# Функция для красивого заголовка
print_header() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title}) / 2 ))
    
    echo -e "\n${BLUE}$(printf '═%.0s' $(seq 1 $width))${NC}"
    echo -e "${BLUE}$(printf '%*s' $padding)${WHITE}$title${BLUE}$(printf '%*s' $padding)${NC}"  
    echo -e "${BLUE}$(printf '═%.0s' $(seq 1 $width))${NC}\n"
}

# Функция для запуска категории примеров
run_category() {
    local category_path="$1"
    local category_name="$2"
    local category_icon="$3"
    local category_description="$4"
    
    if [ ! -d "$category_path" ]; then
        echo -e "${RED}❌ Directory not found: $category_path${NC}"
        return 1
    fi
    
    local swift_files=($(find "$category_path" -name "*.swift" | sort))
    
    if [ ${#swift_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No Swift files found in $category_path${NC}"
        return 0
    fi
    
    echo -e "${CYAN}${category_icon} ${category_name}${NC}"
    echo -e "${WHITE}${category_description}${NC}"
    echo -e "${BLUE}$(printf '─%.0s' $(seq 1 50))${NC}"
    
    local category_passed=0
    local category_failed=0
    
    for example_file in "${swift_files[@]}"; do
        local example_name=$(basename "$example_file" .swift)
        TOTAL_EXAMPLES=$((TOTAL_EXAMPLES + 1))
        
        echo -e -n "${YELLOW}🔄 Running ${example_name}... ${NC}"
        
        # Запуск примера с захватом вывода
        if output=$(timeout 30s swift $SWIFT_FLAGS "$example_file" 2>&1); then
            echo -e "${GREEN}✅ PASSED${NC}"
            PASSED_EXAMPLES=$((PASSED_EXAMPLES + 1))
            category_passed=$((category_passed + 1))
            
            # Показать краткий вывод для успешных примеров
            local first_line=$(echo "$output" | head -n 1)
            if [[ -n "$first_line" && ${#first_line} -lt 100 ]]; then
                echo -e "${WHITE}  → $first_line${NC}"
            fi
        else
            echo -e "${RED}❌ FAILED${NC}"
            FAILED_EXAMPLES=$((FAILED_EXAMPLES + 1))
            category_failed=$((category_failed + 1))
            
            # Показать краткую ошибку
            echo -e "${RED}  Error: $(echo "$output" | tail -n 2 | tr '\n' ' ')${NC}"
        fi
    done
    
    # Статистика по категории
    local total_in_category=$((category_passed + category_failed))
    echo -e "${BLUE}$(printf '─%.0s' $(seq 1 50))${NC}"
    echo -e "📊 Category Results: ${GREEN}${category_passed}/${total_in_category} passed${NC}"
    
    if [ $category_failed -gt 0 ]; then
        echo -e "                    ${RED}${category_failed} failed${NC}"
    fi
    
    echo ""
}

# Функция для проверки системы
check_system() {
    echo -e "${BLUE}🔍 System Check${NC}"
    
    # Проверка Swift
    if ! command -v swift &> /dev/null; then
        echo -e "${RED}❌ Swift not found. Please install Swift first.${NC}"
        exit 1
    fi
    
    local swift_version=$(swift --version | head -n1)
    echo -e "${GREEN}✓ Swift found: ${swift_version}${NC}"
    
    # Проверка, что мы в правильной директории
    if [ ! -f "../Package.swift" ]; then
        echo -e "${RED}❌ Error: Please run this script from the examples/ directory${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Running from correct directory${NC}"
    
    # Проверка библиотеки SwiftProtoReflect
    if [ ! -d "${LIBRARY_PATH}" ]; then
        echo -e "${YELLOW}⚠️  SwiftProtoReflect library not found, building...${NC}"
        cd .. && swift build -c $BUILD_CONFIG && cd examples
        if [ ! -d "${LIBRARY_PATH}" ]; then
            echo -e "${RED}❌ Failed to build SwiftProtoReflect library${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✓ SwiftProtoReflect library available at ${LIBRARY_PATH}${NC}"
    echo ""
}

# Главная функция
main() {
    print_header "SwiftProtoReflect Examples Runner"
    
    check_system
    
    echo -e "${CYAN}🚀 Starting comprehensive examples run...${NC}"
    echo -e "${WHITE}This will execute all SwiftProtoReflect examples across 8 categories${NC}"
    echo ""
    
    # Запуск примеров по категориям
    run_category "01-basic-usage" "Basic Usage" "🔰" "Learn the fundamentals of SwiftProtoReflect"
    run_category "02-dynamic-messages" "Dynamic Messages" "🔧" "Advanced dynamic message manipulation"
    run_category "03-serialization" "Serialization" "💾" "Binary and JSON serialization/deserialization"
    run_category "04-registry" "Type Registry" "🗂" "Centralized type management and discovery"
    run_category "05-well-known-types" "Well-Known Types" "⭐" "Google Protocol Buffers standard types"
    run_category "06-grpc" "gRPC Integration" "🌐" "Dynamic gRPC client functionality"
    run_category "07-advanced" "Advanced Features" "🚀" "Complex integration scenarios and optimizations"
    run_category "08-real-world" "Real-World Scenarios" "🏢" "Production-ready architectural patterns"
    
    # Финальная статистика
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    print_header "Final Results"
    
    echo -e "${WHITE}📊 Test Results Summary:${NC}"
    echo -e "   Total Examples: ${BLUE}${TOTAL_EXAMPLES}${NC}"
    echo -e "   Passed: ${GREEN}${PASSED_EXAMPLES}${NC}"
    echo -e "   Failed: ${RED}${FAILED_EXAMPLES}${NC}"
    
    if [ $TOTAL_EXAMPLES -gt 0 ]; then
        local success_rate=$(( PASSED_EXAMPLES * 100 / TOTAL_EXAMPLES ))
        echo -e "   Success Rate: ${GREEN}${success_rate}%${NC}"
    fi
    
    echo -e "   Execution Time: ${YELLOW}${DURATION}s${NC}"
    
    # Итоговое сообщение
    if [ $FAILED_EXAMPLES -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All examples passed successfully!${NC}"
        echo -e "${GREEN}   SwiftProtoReflect is working correctly.${NC}"
        
        if [ $TOTAL_EXAMPLES -lt 43 ]; then
            echo -e "\n${YELLOW}📝 Development Status:${NC}"
            echo -e "   Examples implemented: ${BLUE}${TOTAL_EXAMPLES}/43${NC}"
            echo -e "   Progress: ${GREEN}$(( TOTAL_EXAMPLES * 100 / 43 ))%${NC}"
        fi
    else
        echo -e "\n${RED}⚠️  Some examples failed.${NC}"
        echo -e "${RED}   Please check the errors above and fix any issues.${NC}"
        exit 1
    fi
    
    echo -e "\n${CYAN}📚 Next Steps:${NC}"
    echo -e "   • Explore individual examples: ${YELLOW}make run-basic${NC}"
    echo -e "   • Check specific example: ${YELLOW}make check-example EXAMPLE=path/to/example.swift${NC}"
    echo -e "   • Interactive mode: ${YELLOW}make demo${NC}"
    echo -e "   • View documentation: ${YELLOW}cat docs/getting-started.md${NC}"
    echo ""
}

# Обработка прерываний
cleanup() {
    echo -e "\n${RED}❌ Execution interrupted${NC}"
    echo -e "${YELLOW}Partial results: ${PASSED_EXAMPLES}/${TOTAL_EXAMPLES} examples passed${NC}"
    exit 1
}

trap cleanup INT TERM

# Справка
show_help() {
    echo "SwiftProtoReflect Examples Runner"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -q, --quiet    Quiet mode (less verbose output)"
    echo "  -v, --verbose  Verbose mode (show example output)"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all examples"
    echo "  $0 --quiet      # Run with minimal output"
    echo ""
}

# Обработка аргументов командной строки
QUIET_MODE=false
VERBOSE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Запуск
main "$@"
