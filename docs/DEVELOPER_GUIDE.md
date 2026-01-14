# SwiftProtoReflect Developer Guide

## Important - Read This First!

**ATTENTION:** After each commit, you lose all memory of previous work. This document will help you quickly restore context and continue development.

## Version Information

**Current Version:** 4.0.0+  
**Recommended for Production:** 4.0.0 or higher

> **⚠️ Version 4.0.0 Breaking Changes:**  
> - Removed all gRPC dependencies (grpc-swift, swift-nio, swift-log)
> - Removed ServiceClient (users can integrate DynamicMessage with any gRPC library)
> - Library is now focused purely on Protocol Buffers reflection
> - Only dependency: SwiftProtobuf 1.29.0+

## Workflow Considering Memory Loss

1. **First thing after returning to the project:**
   - Read PROJECT_STATE.md file to understand current status
   - Check "Active Tasks" and "Latest Updates" sections
   - Run `git log -5` to see what was done in recent commits

2. **Before starting work:**
   - Identify task from PROJECT_STATE.md
   - Study the structure of the corresponding module and its _README.md
   - Run tests to see what works
   - Check current test coverage (`make coverage`)

3. **During work:**
   - Comment code so your "future self" can understand the logic
   - Make small atomic changes
   - Update _README.md of the module you're working on
   - **Strive for maximum test coverage** - this is critically important for library quality
     - Current achievement: 94.37% (excellent!)
     - Target for new modules: 90%+ (close to 100%)
     - Exceptions allowed for paths with `fatalError` or other untestable conditions
   - Follow established design patterns for codebase consistency
   - Use Equatable for all core data types
   - Strictly type APIs, minimize use of Any where possible

4. **Before each commit (mandatory!):**
   - Update PROJECT_STATE.md, marking completed tasks
   - Run `make test && make coverage` and ensure all tests pass with sufficient coverage
   - Make detailed commit message with module prefix: `[Module] What was done - Why it was done this way - What's next`
   - Run `./Scripts/update-state.sh` after commit to update "Latest Updates" section

## General Development Principles

1. **API Design**
   - Create intuitive API
   - Use named parameters for improved readability
   - Prefer methods with explicit naming, avoid method overloads without clear distinctions
   - Document all public APIs with DocC comments

2. **Type Safety**
   - Maximize use of Swift's type system to prevent compile-time errors
   - Explicitly handle errors through throws/try
   - Limit use of force unwrapping (!) to cases where it's absolutely safe

3. **Performance**
   - Optimize critical code paths
   - Minimize data copying where possible
   - Use data structures appropriate for operation characteristics

4. **Testing**
   - Write tests in parallel with code, not after
   - Test edge cases and boundary conditions
   - Create tests that verify not only functionality but also correct error handling

## Project Structure

- **Sources/SwiftProtoReflect/** - main library code:
  - **Descriptor/** - protobuf message descriptor system
  - **Dynamic/** - dynamic representation and message manipulation
  - **Serialization/** - serialization/deserialization
  - **Registry/** - centralized type management
  - **Service/** - gRPC interaction
  - **Bridge/** - Swift Protobuf integration
  - **Integration/** - Well-Known Types support and advanced integration

- **Tests/SwiftProtoReflectTests/** - tests, structure matches modules
  - **Descriptor/** - descriptor system tests
  - **Dynamic/** - dynamic message tests
  - **Serialization/** - serialization tests
  - **Registry/** - type registry tests
  - **Service/** - service client tests
  - **Bridge/** - integration tests
  - **Integration/** - Well-Known Types and advanced integration tests
  - **Performance/** - performance tests
  - **Compatibility/** - Swift Protobuf compatibility tests
  - **TestUtils/** - testing utilities
  - **Fixtures/** - test data
  - **Mocks/** - test mocks

## Development Phases

### Current State: ALL MAIN PHASES COMPLETED ✅

**COMPLETED:**
- ✅ **Foundation Phase** - fully completed (Descriptor System, Dynamic Module, Registry Module)
- ✅ **Serialization Phase** - fully completed (Binary + JSON serialization/deserialization)
- ✅ **Bridge Phase** - fully completed (Static/dynamic message conversion)
- ✅ **Service Phase** - fully completed (Dynamic gRPC client)
- ✅ **Integration Phase** - fully completed (ALL Well-Known Types):
  - ✅ WellKnownTypes Foundation (base infrastructure)
  - ✅ TimestampHandler (google.protobuf.Timestamp)
  - ✅ DurationHandler (google.protobuf.Duration)  
  - ✅ EmptyHandler (google.protobuf.Empty)
  - ✅ FieldMaskHandler (google.protobuf.FieldMask)
  - ✅ StructHandler (google.protobuf.Struct)
  - ✅ ValueHandler (google.protobuf.Value)
  - ✅ AnyHandler (google.protobuf.Any)

**Overall test coverage: 94%+** (866 tests passing)

**🎉 PROJECT READY FOR PRODUCTION USE**

### ✅ Fully Completed Components

**ALL Well-Known Types implemented and tested:**

1. **TimestampHandler (google.protobuf.Timestamp) - COMPLETED ✅**
   - Full support for timestamps with nanosecond precision
   - Conversion between Foundation.Date and Timestamp
   - Round-trip compatibility
   - 23 tests with high coverage

2. **DurationHandler (google.protobuf.Duration) - COMPLETED ✅**
   - Support for time intervals
   - Conversion between Foundation.TimeInterval and Duration
   - Correct handling of negative values
   - 29 tests with full coverage

3. **EmptyHandler (google.protobuf.Empty) - COMPLETED ✅**
   - Minimalist support for empty messages
   - Singleton pattern optimization
   - 15 tests with 100% coverage

4. **FieldMaskHandler (google.protobuf.FieldMask) - COMPLETED ✅**
   - Support for field masks for partial updates
   - Path operations (union, intersection, covers)
   - 30 tests with high coverage

5. **StructHandler (google.protobuf.Struct) - COMPLETED ✅**
   - Full support for dynamic JSON-like structures
   - Conversion between Dictionary<String, Any> and StructValue
   - Support for nested structures and arrays
   - 21 tests with 83%+ region coverage

6. **ValueHandler (google.protobuf.Value) - COMPLETED ✅**
   - Foundation for google.protobuf.Struct
   - Support for all value types (null, number, string, bool, struct, list)
   - Tight integration with StructHandler
   - 14 tests with full coverage of main scenarios

7. **AnyHandler (google.protobuf.Any) - COMPLETED ✅**
   - Full support for type erasure for arbitrary typed messages
   - Pack/unpack operations with TypeRegistry integration
   - URL validation and type resolution
   - All tests cover edge cases and performance

### 📋 Possible Future Development Directions

**Phase 4 - Optional Extensions (if needed):**
- Protocol Buffers extensions support
- Custom options handling
- Reflection API improvements
- Performance optimizations for specific use cases

**Phase 5 - Ecosystem Integration (if needed):**
- Advanced debugging tools
- IDE integration support
- Additional convenience APIs

## Code Conventions

- Follow Swift code style from neighboring files
- Use DocC format documentation with /// for public API
- Add tests for each new functionality
- **High test coverage required** - use `make coverage` for verification
  - Unreachable paths (e.g., with `fatalError`) may be excluded from 100% coverage requirement
  - Important: add comment explaining why specific path is not covered by tests

## Testing and Error Handling

### Test Structure

Each test file should contain:
1. **Initialization tests** - verify correct object initialization with different parameters
2. **Main functionality tests** - verify core functions and methods
3. **Boundary condition tests** - verify behavior in edge cases
4. **Error tests** - verify correct error throwing
5. **Performance tests** (optional) - for critical code paths

### Testing Critical Failures

Some functions use `fatalError()` to handle invalid states that shouldn't occur during normal operation. These paths are difficult or impossible to test with standard means.

Examples of untestable code paths:
- Checking presence of required parameters in constructors
- Validating types that should have corresponding type names
- Checking structural integrity of composite objects

For such paths:
1. Add clear comment explaining why `fatalError` occurs
2. Use tests to verify correct usage cases
3. Use special expectations (XCTExpectFailure) where applicable

### Code Coverage Requirements

The established minimum code coverage threshold is 90%. For critically important components, strive for coverage close to 100%.

Use the following commands to check coverage:
```bash
make coverage      # General coverage report
```

## Useful Commands

```bash
# Status checking
git log -5                      # Last 5 commits
git diff HEAD~1                 # What changed in last commit

# Development
make lint                       # Code checking
make format                     # Code formatting
swift test                      # Run tests
make coverage                   # Check test coverage

# Creating new components
./Scripts/setup-module.sh Integration StructHandler  # Creates component file templates

# State updates
./Scripts/update-state.sh       # Update PROJECT_STATE.md
```

## Creating New Components

To quickly create file templates for new components, use the script:

```bash
./Scripts/setup-module.sh <Module Name> <Component Name>
```

The script automatically:
- Creates .swift component file with code template in corresponding module
- Creates test file for the component
- Updates module's _README.md, adding new component to the list
- Reminds to update PROJECT_STATE.md and make commit

Example:
```bash
./Scripts/setup-module.sh Integration StructHandler
```