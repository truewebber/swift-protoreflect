# SwiftProtoReflect Documentation Examples

This document provides examples of documentation standards for the SwiftProtoReflect project, serving as a template for consistent documentation across the codebase.

## API Documentation Examples

### Class Documentation

```swift
/// A descriptor for a Protocol Buffer field, containing metadata about the field's name, type, and other properties.
///
/// `ProtoFieldDescriptor` represents a single field within a Protocol Buffer message. It contains
/// all the metadata needed to correctly serialize, deserialize, and validate field values.
///
/// Example:
/// ```swift
/// let fieldDescriptor = ProtoFieldDescriptor(
///     name: "user_id",
///     number: 1,
///     type: .int64,
///     isRepeated: false,
///     isMap: false
/// )
/// ```
///
/// - Note: Field numbers must be positive and unique within a message.
/// - Important: For message-type fields, you must provide a `messageType` descriptor.
public class ProtoFieldDescriptor: Hashable {
    // Properties and methods...
}
```

### Method Documentation

```swift
/// Creates a new dynamic Protocol Buffer message based on the provided descriptor.
///
/// This method instantiates a new `ProtoDynamicMessage` that conforms to the structure
/// defined by the message descriptor. The resulting message will have no field values set
/// initially.
///
/// Example:
/// ```swift
/// let personDescriptor = ProtoMessageDescriptor(
///     fullName: "Person",
///     fields: [
///         ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
///         ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false)
///     ],
///     enums: [],
///     nestedMessages: []
/// )
///
/// let person = ProtoReflect.createMessage(from: personDescriptor)
/// person.set(field: personDescriptor.fields[0], value: .stringValue("Alice"))
/// person.set(field: personDescriptor.fields[1], value: .intValue(30))
/// ```
///
/// - Parameter descriptor: The message descriptor defining the structure of the message to create.
/// - Returns: A new dynamic message instance conforming to the provided descriptor.
/// - Note: The returned message will have no field values set initially.
public static func createMessage(from descriptor: ProtoMessageDescriptor) -> ProtoMessage {
    // Implementation...
}
```

### Property Documentation

```swift
/// The name of the field as defined in the Protocol Buffer schema.
///
/// This name corresponds to the field name in the `.proto` file. For example, a field defined as
/// `string user_name = 1;` in a `.proto` file would have the name "user_name".
///
/// - Note: Field names must be non-empty and should follow Protocol Buffer naming conventions.
public let name: String

/// The field number as defined in the Protocol Buffer schema.
///
/// Field numbers uniquely identify fields within a message when serialized to the binary wire format.
/// Valid field numbers are positive integers.
///
/// - Note: Field numbers 1-15 use one byte in the wire format, while numbers 16-2047 use two bytes.
///   For frequently used fields, prefer numbers 1-15 for efficiency.
public let number: Int
```

### Protocol Documentation

```swift
/// Represents a Protocol Buffer message that can be dynamically manipulated at runtime.
///
/// The `ProtoMessage` protocol defines the core interface for working with Protocol Buffer messages
/// in a dynamic manner, without requiring generated code from `.proto` files. Implementations of this
/// protocol provide access to message fields and support serialization/deserialization.
///
/// Example usage:
/// ```swift
/// // Assuming we have a message and its descriptor
/// let value = message.get(field: descriptor.field(named: "user_id"))
/// if let userId = value?.getInt() {
///     print("User ID: \(userId)")
/// }
///
/// // Setting a field value
/// message.set(field: descriptor.field(named: "user_id"), value: .intValue(42))
/// ```
public protocol ProtoMessage {
    // Methods...
}
```

## README Example Sections

### Installation Section

```markdown
## Installation

### Swift Package Manager

Add SwiftProtoReflect to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/username/swift-protoreflect.git", from: "1.0.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftProtoReflect"]
)
```

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'SwiftProtoReflect', '~> 1.0.0'
```

Then run:

```bash
pod install
```
```

### Quick Start Guide

```markdown
## Quick Start

### Defining a Message Structure

```swift
import SwiftProtoReflect

// Define a message descriptor
let personDescriptor = ProtoMessageDescriptor(
    fullName: "Person",
    fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "emails", number: 3, type: .string, isRepeated: true, isMap: false)
    ],
    enums: [],
    nestedMessages: []
)

// Create a dynamic message
var person = ProtoReflect.createMessage(from: personDescriptor)

// Set field values
person.set(field: personDescriptor.field(named: "name")!, value: .stringValue("John Doe"))
person.set(field: personDescriptor.field(named: "age")!, value: .intValue(30))
person.set(field: personDescriptor.field(named: "emails")!, value: .arrayValue([
    .stringValue("john@example.com"),
    .stringValue("jdoe@work.com")
]))

// Serialize to binary format
if let data = ProtoReflect.marshal(message: person) {
    // Use the serialized data
    print("Serialized data size: \(data.count) bytes")
    
    // Deserialize from binary format
    if let deserializedPerson = ProtoReflect.unmarshal(data: data, descriptor: personDescriptor) {
        let name = deserializedPerson.get(field: personDescriptor.field(named: "name")!)?.getString()
        print("Deserialized name: \(name ?? "unknown")")
    }
}
```
```

## CONTRIBUTING.md Example

```markdown
# Contributing to SwiftProtoReflect

Thank you for your interest in contributing to SwiftProtoReflect! This document provides guidelines and instructions for contributing.

## Code Style

SwiftProtoReflect follows the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and uses SwiftLint to enforce consistent code style.

Key style points:
- Use 4 spaces for indentation
- Keep line length to 100 characters or less
- Use camelCase for variable and function names
- Use PascalCase for type names
- Include comprehensive documentation comments for all public APIs

## Pull Request Process

1. Fork the repository and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure all tests pass and the code lints without errors
4. Update the documentation if needed
5. Submit a pull request

## Pull Request Template

When submitting a pull request, please use the provided template and ensure you:

- Describe the changes you've made
- Link to any related issues
- Indicate the type of change (bugfix, feature, etc.)
- Verify that you've completed the checklist items

## Development Workflow

1. Write tests first (TDD approach)
2. Implement the feature or fix
3. Ensure code coverage meets requirements (90%+ for new code)
4. Document your code with DocC comments
5. Run SwiftLint and address any issues
6. Submit your PR

## Reporting Issues

When reporting issues, please include:

- A clear and descriptive title
- A detailed description of the issue
- Steps to reproduce the behavior
- Expected behavior
- Actual behavior
- Environment information (Swift version, OS, etc.)

## License

By contributing to SwiftProtoReflect, you agree that your contributions will be licensed under the project's MIT license.
```

## GitHub Actions Workflow Example

```yaml
name: Swift

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Swift
      uses: swift-actions/setup-swift@v1
      with:
        swift-version: '6.0'
    
    - name: Build
      run: swift build -v
    
    - name: Run tests
      run: swift test -v --enable-code-coverage
    
    - name: SwiftLint
      run: |
        brew install swiftlint
        swiftlint
    
    - name: Convert coverage report
      run: |
        xcrun llvm-cov export -format="lcov" .build/debug/SwiftProtoReflectPackageTests.xctest/Contents/MacOS/SwiftProtoReflectPackageTests -instr-profile .build/debug/codecov/default.profdata > coverage.lcov
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.lcov
        fail_ci_if_error: true
```

## Pull Request Template Example

```markdown
## Description
<!-- Describe the changes you've made -->

## Related Issue
<!-- Link to the issue this PR addresses, if applicable -->

## Type of Change
<!-- Mark the appropriate option with an "x" -->
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code cleanup or refactoring

## Checklist
<!-- Mark completed items with an "x" -->
- [ ] I have read the CONTRIBUTING document
- [ ] My code follows the code style of this project
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] I have updated the documentation accordingly
- [ ] I have verified that my changes don't introduce memory leaks
- [ ] I have checked that my changes meet performance requirements
- [ ] I have commented my code, particularly in hard-to-understand areas

## Additional Information
<!-- Any additional information about the PR -->
``` 