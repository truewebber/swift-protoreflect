#!/bin/bash

# coverage-report.sh
# A script to generate a test coverage report for SwiftProtoReflect using lcov

set -e  # Exit immediately if a command exits with a non-zero status

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Add Homebrew bin directory to PATH
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

echo -e "${YELLOW}Generating test coverage report for SwiftProtoReflect...${NC}"

# Directory for coverage data
COVERAGE_DIR=".build/coverage"
REPORT_FILE="docs/SwiftProtoReflect_Coverage_Report.md"

# Create coverage directory if it doesn't exist
mkdir -p "$COVERAGE_DIR"
mkdir -p "docs"

# Check if lcov is installed
if ! command -v lcov &> /dev/null; then
    echo -e "${RED}Error: lcov not installed. Install with 'brew install lcov'.${NC}"
    exit 1
fi

# Run tests with code coverage enabled
echo -e "${YELLOW}Running tests with code coverage enabled...${NC}"
swift test --enable-code-coverage --filter SwiftProtoReflectTests

# Find the coverage data
PROFDATA=$(find .build -name "*.profdata" | head -n 1)
if [ -z "$PROFDATA" ]; then
    echo -e "${RED}Error: Could not find coverage data (.profdata file)${NC}"
    exit 1
fi

echo -e "${YELLOW}Found coverage data: ${PROFDATA}${NC}"

# Find the executable
XCTEST_PATH=$(find .build -name "*.xctest" | head -n 1)
if [ -z "$XCTEST_PATH" ]; then
    echo -e "${RED}Error: Could not find test executable (.xctest file)${NC}"
    exit 1
fi

# Get the path to the actual executable inside the .xctest package
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    XCTEST_EXEC="$XCTEST_PATH/Contents/MacOS/$(basename "$XCTEST_PATH" .xctest)"
else
    # Linux
    XCTEST_EXEC="$XCTEST_PATH"
fi

echo -e "${YELLOW}Found test executable: ${XCTEST_EXEC}${NC}"

# Generate coverage data in lcov format
echo -e "${YELLOW}Generating coverage data in lcov format...${NC}"
LCOV_INFO="$COVERAGE_DIR/coverage.lcov"
xcrun llvm-cov export -instr-profile="$PROFDATA" "$XCTEST_EXEC" -format=lcov > "$LCOV_INFO"

# Check if we have coverage data
if [ ! -s "$LCOV_INFO" ]; then
    echo -e "${RED}Error: No coverage data generated${NC}"
    exit 1
fi

# Generate summary report
echo -e "${YELLOW}Generating summary report...${NC}"
SUMMARY_FILE="$COVERAGE_DIR/summary.txt"
lcov --summary "$LCOV_INFO" > "$SUMMARY_FILE"

# Extract only SwiftProtoReflect files (exclude external dependencies)
echo -e "${YELLOW}Extracting SwiftProtoReflect files...${NC}"
PROJECT_LCOV="$COVERAGE_DIR/project_coverage.lcov"
lcov --extract "$LCOV_INFO" "**/Sources/SwiftProtoReflect/**" --output-file "$PROJECT_LCOV"

# Generate summary for project files
PROJECT_SUMMARY="$COVERAGE_DIR/project_summary.txt"
lcov --summary "$PROJECT_LCOV" > "$PROJECT_SUMMARY"

# Extract coverage by component
echo -e "${YELLOW}Extracting coverage by component...${NC}"

# Core
lcov --extract "$PROJECT_LCOV" "**/Core/**" --output-file "$COVERAGE_DIR/core_coverage.lcov"
lcov --summary "$COVERAGE_DIR/core_coverage.lcov" > "$COVERAGE_DIR/core_summary.txt"

# Utils
lcov --extract "$PROJECT_LCOV" "**/Utils/**" --output-file "$COVERAGE_DIR/utils_coverage.lcov"
lcov --summary "$COVERAGE_DIR/utils_coverage.lcov" > "$COVERAGE_DIR/utils_summary.txt"

# Reflection
lcov --extract "$PROJECT_LCOV" "**/Reflection/**" --output-file "$COVERAGE_DIR/reflection_coverage.lcov"
lcov --summary "$COVERAGE_DIR/reflection_coverage.lcov" > "$COVERAGE_DIR/reflection_summary.txt"

# Generate HTML reports
echo -e "${YELLOW}Generating HTML reports...${NC}"
genhtml "$PROJECT_LCOV" --output-directory "$COVERAGE_DIR/html_report"

# Parse the summary to extract coverage percentages
LINE_COVERAGE=$(grep "lines" "$PROJECT_SUMMARY" | grep -o "[0-9]\+\.[0-9]\+%" | head -1 | tr -d '%')
FUNCTION_COVERAGE=$(grep "functions" "$PROJECT_SUMMARY" | grep -o "[0-9]\+\.[0-9]\+%" | head -1 | tr -d '%')

# If we couldn't extract the coverage, set it to 0
if [ -z "$LINE_COVERAGE" ]; then
    LINE_COVERAGE="0.00"
fi

if [ -z "$FUNCTION_COVERAGE" ]; then
    FUNCTION_COVERAGE="0.00"
fi

# Generate Markdown report
echo -e "${YELLOW}Generating Markdown report...${NC}"
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")

cat > "$REPORT_FILE" << EOL
# SwiftProtoReflect Test Coverage Report

This report provides an overview of the test coverage for the SwiftProtoReflect project.

## Overall Coverage

**Line Coverage: ${LINE_COVERAGE}%**
**Function Coverage: ${FUNCTION_COVERAGE}%**

$(if (( $(echo "$LINE_COVERAGE >= 90" | bc -l) )); then
    echo "✅ **Meets the 90% coverage requirement**"
else
    echo "❌ **Does not meet the 90% coverage requirement**"
fi)

## Coverage by Component

| Component | Line Coverage % | Function Coverage % |
|-----------|-----------------|---------------------|
EOL

# Add component coverage data
for component in core utils reflection; do
    COMPONENT_LINE_COVERAGE=$(grep "lines" "$COVERAGE_DIR/${component}_summary.txt" | grep -o "[0-9]\+\.[0-9]\+%" | head -1 | tr -d '%')
    COMPONENT_FUNCTION_COVERAGE=$(grep "functions" "$COVERAGE_DIR/${component}_summary.txt" | grep -o "[0-9]\+\.[0-9]\+%" | head -1 | tr -d '%')
    
    # If we couldn't extract the coverage, set it to 0
    if [ -z "$COMPONENT_LINE_COVERAGE" ]; then
        COMPONENT_LINE_COVERAGE="0.00"
    fi
    
    if [ -z "$COMPONENT_FUNCTION_COVERAGE" ]; then
        COMPONENT_FUNCTION_COVERAGE="0.00"
    fi
    
    # Capitalize the component name
    COMPONENT_NAME=$(echo "$component" | sed 's/\b\(.\)/\u\1/g')
    
    echo "| $COMPONENT_NAME | $COMPONENT_LINE_COVERAGE% | $COMPONENT_FUNCTION_COVERAGE% |" >> "$REPORT_FILE"
done

# Add detailed coverage information
cat >> "$REPORT_FILE" << EOL

## Test Coverage Assessment

Based on the coverage analysis, here's an assessment of the project's test coverage:

1. **Overall Line Coverage**: The project has ${LINE_COVERAGE}% line coverage, which $(if (( $(echo "$LINE_COVERAGE >= 90" | bc -l) )); then echo "meets"; else echo "does not meet"; fi) the 90% requirement.

2. **Function Coverage**: The project has ${FUNCTION_COVERAGE}% function coverage.

3. **Key Components Coverage**:
   - Core types (ProtoValue, ProtoFieldDescriptor, ProtoMessageDescriptor)
   - Dynamic message implementation
   - Field access utilities
   - Error handling
   - Validation logic
   - Serialization/deserialization

4. **Areas with Strong Coverage**:
   - Files with >90% coverage are well-tested and robust
   - Core functionality has comprehensive test coverage

5. **Areas for Improvement**:
   - Files with <80% coverage need additional tests
   - Complex conditional logic may need more edge case testing

## Recommendations

To maintain and improve test coverage:

1. Add tests for any new functionality added to the project
2. Focus on improving coverage for files with lower percentages
3. Add more edge case tests for complex conditional logic
4. Consider adding integration tests for end-to-end workflows
5. Review error handling paths to ensure they are tested

## How Code Coverage is Measured

This report uses LCOV to measure:

- **Line Coverage**: The percentage of code lines that were executed during tests
- **Function Coverage**: The percentage of functions that were called during tests

Code coverage helps identify untested code but doesn't guarantee the quality of tests.
High coverage should be combined with thoughtful test design that verifies correct behavior.

## Detailed Coverage Information

A detailed HTML coverage report is available at:
\`.build/coverage/html_report/index.html\`

EOL

# Add timestamp to the report
echo -e "\n\n*Report generated on $CURRENT_DATE*" >> "$REPORT_FILE"

echo -e "${GREEN}Coverage report generated: ${REPORT_FILE}${NC}"
echo -e "${YELLOW}Overall coverage: ${LINE_COVERAGE}%${NC}"

# Check if coverage meets the requirement
if (( $(echo "$LINE_COVERAGE >= 90" | bc -l) )); then
    echo -e "${GREEN}✅ Coverage meets the 90% requirement${NC}"
else
    echo -e "${RED}❌ Coverage does not meet the 90% coverage requirement${NC}"
fi

echo -e "${GREEN}Done!${NC}"
