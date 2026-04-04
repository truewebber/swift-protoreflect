# SwiftProtoReflect - Architecture Overview

## 1. Introduction

SwiftProtoReflect is a Swift library providing dynamic reflection capabilities for Protocol Buffers. This document outlines the architectural decisions, project structure, and implementation approach that guides development.

## 2. High-Level Architecture

SwiftProtoReflect utilizes a layered architecture with the following components:

```
┌───────────────────────────────────────────────────────────────┐
│                      Public API Layer                         │
├───────────────┬───────────────────────────┬───────────────────┤
│ Descriptor    │ Message                   │ Integration       │
│ Management    │ Manipulation              │ Layer             │
├───────────────┼───────────────────────────┼───────────────────┤
│               │    Core Reflection Layer  │                   │
├───────────────┼───────────────────────────┼───────────────────┤
│ Type System   │ Serialization/            │ Extension         │
│               │ Deserialization           │ Support           │
└───────────────┴───────────────────────────┴───────────────────┘
       │               │                           │
       │               │                           │
       ▼               ▼                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   Swift Protobuf Layer                      │
└─────────────────────────────────────────────────────────────┘
```

## 3. Key Technologies and Dependencies

- **Swift 5.9+**: Utilizing mature language features for performance and safety
- **SwiftProtobuf 1.29.0+**: Apple's Swift Protobuf library for wire format compatibility and low-level operations
- **Platforms**: macOS 12.0+, iOS 15.0+
- **No Additional Runtime Dependencies**: Self-contained operation with minimal external requirements

## 4. Core Modules

### 4.1 Descriptor System
- **FileDescriptor**: Manages proto file metadata, symbols, and syntax version (proto2/proto3)
- **MessageDescriptor**: Describes message structure and fields with nested type/enum support
- **FieldDescriptor**: Contains field metadata (type, name, number, options, map entry info, proto3Optional)
- **EnumDescriptor**: Defines enum types and values with proto3 validation (zero-value requirement)
- **ServiceDescriptor**: Describes gRPC service definitions with method introspection
- **DescriptorParent**: Protocol implemented by `FileDescriptor` and `MessageDescriptor` to provide a typed parent context; enables `MessageDescriptor` and `EnumDescriptor` to derive their fully-qualified `fullName`, `syntax`, and `fileDescriptorPath` from the parent without `Any?` casts

### 4.2 Dynamic Message
- **DynamicMessage**: Runtime representation of a protobuf message with field validation and unknown fields storage
- **MessageFactory**: Creates message instances from descriptors with syntax-aware validation
- **FieldAccessor**: Type-safe field access and modification with error handling

### 4.3 Serialization
- **BinarySerializer**: Binary format serialization (wire format) with ZigZag encoding and unknown fields passthrough
- **BinaryDeserializer**: Binary format deserialization with wire type validation, unknown fields preservation, and recursive nested message support. Requires `TypeRegistry` (via `DeserializationOptions`) for nested/sibling message resolution.
- **JSONSerializer**: JSON format with proto3 canonical encoding (int64 as string, bytes as base64, enums as names, includeDefaultValues). Requires `TypeRegistry` (via `JSONSerializationOptions`) for enum name resolution.
- **JSONDeserializer**: JSON format parsing with enum name resolution, type validation, and error recovery. Requires `TypeRegistry` (via `JSONDeserializationOptions`) for enum and nested message resolution.

> **Note:** All serializers and deserializers require a `TypeRegistry` passed through their options. The no-argument constructors `BinaryDeserializer()`, `JSONDeserializer()`, and `JSONSerializer()` are deprecated. TypeRegistry is consulted first (primary lookup by fully-qualified name); `nestedMessage(named:)` / `nestedEnum(named:)` serves as a deprecated fallback that will be removed in a future major version.

### 4.4 Reflection Registry
- **TypeRegistry**: Central registry for all known types with concurrent access support. Acts as a **required dependency** for all serializers and deserializers — register all message and enum types before performing serialization or deserialization of messages with non-scalar fields.
- **DescriptorPool**: Manages descriptor dependencies and resolution with caching

### 4.5 Integration Layer
- **Bridge System**: Bidirectional conversion between static and dynamic messages with Visitor-based descriptor extraction
- **Well-Known Types**: 18 supported types including Timestamp, Duration, Empty, FieldMask, Struct, Value, ListValue, Any, and all 9 wrapper types
- **Static Interoperability**: Seamless integration with existing Swift Protobuf code

## 5. Swift Protobuf Integration

### 5.1 Integration Strategy
SwiftProtoReflect leverages Swift Protobuf's mature implementation while providing a dynamic layer on top of it. This section defines how our library interacts with Swift Protobuf components.

### 5.2 Responsibilities Breakdown

#### Swift Protobuf Responsibilities
- **Wire Format Encoding/Decoding**: Low-level binary serialization and deserialization
- **JSON Format Support**: JSON encoding and decoding routines
- **Protocol Compliance**: Ensuring wire format compatibility with the Protocol Buffers specification
- **Generated Message Wrappers**: Support for converting between static and dynamic messages

#### SwiftProtoReflect Responsibilities
- **Dynamic Type System**: Runtime representation of Protocol Buffer types
- **Descriptor Construction**: Building descriptors at runtime from various sources
- **Reflection API**: Dynamic field access and message manipulation
- **Message Creation**: Runtime message instantiation from descriptors

### 5.3 Integration Points

The library uses several specific integration mechanisms:

1. **Binary Format Delegation**
   ```swift
   // Our serializers delegate to Swift Protobuf for wire format compatibility
   func serialize(message: DynamicMessage) throws -> Data {
     // Use optimized binary encoding with full wire format support
     return try BinarySerializer().serialize(message: message)
   }
   ```

2. **Descriptor Conversion**
   ```swift
   // Converting between our descriptors and Swift Protobuf's descriptors
   extension MessageDescriptor {
     // Convert from Swift Protobuf descriptor to our dynamic descriptor
     static func fromSwiftProtobuf(_ descriptor: Descriptor) throws -> MessageDescriptor {
       return try DescriptorBridge.convert(descriptor)
     }
   }
   ```

3. **Bridge Operations**
   ```swift
   // Bidirectional conversion between static and dynamic messages
   extension DynamicMessage {
     func toStaticMessage<T: SwiftProtobuf.Message>() throws -> T {
       return try StaticMessageBridge.convertToStatic(self)
     }
   }
   ```

### 5.4 Bridging Static and Dynamic Types

For interoperability with existing Swift Protobuf code, we provide conversion mechanisms:

```swift
// Convert from dynamic message to static Swift Protobuf message
extension DynamicMessage {
  func toStaticMessage<T: SwiftProtobuf.Message>() throws -> T {
    // Conversion logic with type validation
  }
  
  // Create dynamic message from static Swift Protobuf message
  static func fromStaticMessage<T: SwiftProtobuf.Message>(_ message: T) throws -> DynamicMessage {
    // Conversion logic with schema generation
  }
}
```

## 6. Public API Design

The primary API interfaces include:

```swift
// Creating a dynamic message
let message = try MessageFactory().createMessage(from: personDescriptor)

// Setting field values with type safety
try message.set("name", value: "John Doe")
try message.set("age", value: Int32(30))

// Getting field values with explicit typing
let name: String = try message.get("name")
let age: Int32 = try message.get("age")

// Serialization — TypeRegistry is required for all serializers/deserializers
let registry = TypeRegistry()
// Register nested/sibling types if your message has message or enum fields:
// try registry.registerMessage(addressDescriptor)
// try registry.registerEnum(statusEnum)

let binaryData = try BinarySerializer().serialize(message: message)
let jsonData = try JSONSerializer(options: .init(typeRegistry: registry)).serialize(message)

// Deserialization
let parsedMessage = try BinaryDeserializer(options: .init(typeRegistry: registry))
    .deserialize(binaryData, using: personDescriptor)

// Converting between static and dynamic
let staticMessage: Person = try message.toStaticMessage()
let dynamicFromStatic = try DynamicMessage.fromStatic(staticPerson)
```

## 7. Performance Considerations

- **Descriptor Caching**: Optimize descriptor lookup and resolution with LRU caching
- **Binary Encoding/Decoding**: Leverage Swift Protobuf's optimized implementation
- **Memory Management**: Careful management of reference cycles and memory usage patterns
- **Type-Specialized Paths**: Optimized code paths for common field types and operations
- **Minimal Conversion**: Reduce conversions between our types and Swift Protobuf types
- **Concurrent Access**: Thread-safe operations for high-throughput scenarios

## 8. Project Structure

```
Sources/SwiftProtoReflect/          # 29 source files
├── Descriptor/                     # Proto descriptor types
│   ├── DescriptorOption.swift      # Descriptor option values
│   ├── DescriptorParent.swift      # Protocol for parent context (FileDescriptor/MessageDescriptor)
│   ├── EnumDescriptor.swift        # Enum types with proto3 validation
│   ├── FieldDescriptor.swift       # Field metadata (type, proto3Optional, mapEntryInfo)
│   ├── FileDescriptor.swift        # File-level metadata with syntax tracking
│   ├── MessageDescriptor.swift     # Message schema with nested types
│   ├── OneofDescriptor.swift       # Oneof field grouping
│   └── ServiceDescriptor.swift     # gRPC service definitions
├── Dynamic/                        # Runtime message manipulation
│   ├── DynamicMessage.swift        # Message representation with unknown fields
│   ├── FieldAccessor.swift         # Type-safe field operations
│   └── MessageFactory.swift        # Creation and syntax-aware validation
├── Serialization/                  # Binary and JSON serialization
│   ├── BinarySerializer.swift      # Binary encoding with unknown fields passthrough
│   ├── BinaryDeserializer.swift    # Binary decoding with nested message support
│   ├── JSONSerializer.swift        # JSON with proto3 canonical encoding
│   ├── JSONDeserializer.swift      # JSON with enum name resolution
│   └── WireFormat.swift            # Wire type definitions
├── Registry/                       # Type management
│   ├── TypeRegistry.swift          # Central type registry (actor)
│   └── DescriptorPool.swift        # Descriptor dependency resolution
├── Bridge/                         # Static/Dynamic interoperability
│   ├── StaticMessageBridge.swift   # Message conversion with Visitor extraction
│   └── DescriptorBridge.swift      # Descriptor conversion with syntax support
└── Integration/                    # Well-Known Types (18 types)
    ├── WellKnownTypes.swift        # Registry and type name constants
    ├── TimestampHandler.swift      # google.protobuf.Timestamp
    ├── DurationHandler.swift       # google.protobuf.Duration
    ├── EmptyHandler.swift          # google.protobuf.Empty
    ├── FieldMaskHandler.swift      # google.protobuf.FieldMask
    ├── StructHandler.swift         # google.protobuf.Struct
    ├── ValueHandler.swift          # google.protobuf.Value
    ├── ListValueHandler.swift      # google.protobuf.ListValue
    ├── AnyHandler.swift            # google.protobuf.Any
    └── WrapperHandlers.swift       # All 9 wrapper types

Tests/SwiftProtoReflectTests/       # 85 test files, 1689 tests
├── Descriptor/                     # Descriptor system tests (13 files)
├── Dynamic/                        # Dynamic message tests (7 files)
├── Serialization/                  # Serialization tests (13 files)
├── Registry/                       # Registry tests (4 files)
├── Bridge/                         # Bridge tests (10 files)
├── Integration/                    # Well-Known Types tests (11 files)
├── Spec/                           # Proto3 spec compliance tests (3 files)
├── Compatibility/                  # Cross-platform / C++ compat tests (3 files)
├── Error/                          # Error handling tests (1 file)
├── Performance/                    # Performance benchmarks (3 files)
├── Fixtures/                       # Test data
├── Mocks/                          # Test mocks
└── TestUtils/                      # Test helpers
```

## 9. Development Phases

1. **Foundation Phase**: Core descriptor and message implementations
2. **Serialization Phase**: Binary and JSON serialization/deserialization integration with Swift Protobuf
3. **Registry Phase**: Type management and descriptor pool implementation
4. **Bridge Phase**: Develop static/dynamic message conversion capabilities
5. **Integration Phase**: Well-Known Types support (18 types) and ecosystem integration
6. **Performance Phase**: Benchmarking and optimization
7. **Examples Phase**: Comprehensive examples and documentation
8. **Proto3 Compliance Phase**: Full proto3 spec conformance (syntax tracking, unknown fields, optional presence, JSON canonical encoding, enum validation, nested message deserialization)

## 10. Design Decisions

### Why Swift Protobuf as a Dependency?
Swift Protobuf provides a mature, well-tested implementation of Protocol Buffers wire format encoding and decoding. By leveraging this, we:
1. Ensure wire format compatibility with the standard Protocol Buffers implementation
2. Benefit from performance optimizations in the serialization layer
3. Provide seamless interoperability with generated Swift Protobuf code
4. Focus our development on reflection capabilities rather than reinventing serialization

### Internal Type Registry vs. On-Demand Resolution
The library utilizes a central type registry to manage descriptor dependencies efficiently, with on-demand resolution for improved performance when handling large descriptor sets.

### Error Handling Strategy
API uses Swift's throw/catch mechanism for error handling, with specific error types for better diagnostics and debugging.

### Well-Known Types Integration
Google's Well-Known Types are supported through a handler pattern that allows for:
- Type-safe conversions between Swift native types and Protocol Buffer representations
- Automatic registry integration for seamless usage
- 18 types supported: Timestamp, Duration, Empty, FieldMask, Struct, Value, ListValue, Any, and 9 wrapper types (DoubleValue, FloatValue, Int64Value, UInt64Value, Int32Value, UInt32Value, BoolValue, StringValue, BytesValue)
- Extensibility for custom well-known type implementations

### Concurrency and Thread Safety
The library design considers Swift's concurrency model:
- Immutable descriptors for thread-safe sharing
- Actor-isolated mutable state where necessary
- Concurrent access patterns for performance-critical operations

## 11. Memory Management

### Reference Cycles Prevention
- Weak references for parent-child relationships in descriptor hierarchies
- Careful management of closure captures in dynamic operations
- Explicit break cycles in factory and registry patterns

### Caching Strategy
- Intelligent caching of frequently accessed descriptors
- LRU eviction for large descriptor sets
- Memory pressure handling with automatic cleanup

## 12. Error Handling Architecture

### Error Categories
- **Descriptor Errors**: Schema definition and validation errors
- **Type Errors**: Field type mismatches and conversion errors  
- **Serialization Errors**: Binary and JSON format errors
- **Registry Errors**: Type registration and lookup errors
- **Well-Known Type Errors**: Standard type conversion and validation errors

### Error Context
Rich error context with:
- Specific error locations (field names, numbers)
- Type information for debugging
- Suggested fixes where possible
- Chain of error causes for complex operations

## 13. Testing Strategy

### Unit Testing
- Comprehensive coverage of all public APIs
- Edge case testing for error conditions
- Performance regression testing

### Integration Testing
- Round-trip compatibility with Swift Protobuf
- Cross-platform compatibility verification
- Real-world usage pattern validation

### Performance Testing
- Benchmarking against static Swift Protobuf
- Memory usage profiling
- Concurrent access performance validation

### Error Path Testing
- Comprehensive error condition coverage
- Type mismatch scenario validation
- Malformed data handling verification

## 14. Conclusion

This architecture provides a foundation for implementing comprehensive Protocol Buffers reflection capabilities. By clearly delineating responsibilities between our reflection layer and Swift Protobuf's serialization capabilities, we create a library that balances performance, usability, and maintainability while adhering to Swift's idioms and best practices.

The design emphasizes:
- **Flexibility**: Runtime schema handling and dynamic message manipulation
- **Performance**: Leveraging optimized Swift Protobuf foundations
- **Interoperability**: Seamless integration with existing Swift Protobuf codebases
- **Extensibility**: Well-defined patterns for future enhancements
- **Reliability**: Comprehensive error handling and testing strategies
