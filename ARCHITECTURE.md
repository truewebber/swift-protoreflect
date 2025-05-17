# SwiftProtoReflect - Architecture Overview

## 1. Introduction

SwiftProtoReflect is a Swift library providing dynamic reflection capabilities for Protocol Buffers. This document outlines the architectural decisions, project structure, and implementation approach that will guide development.

## 2. High-Level Architecture

SwiftProtoReflect utilizes a layered architecture with the following components:

```
┌───────────────────────────────────────────────────────────────┐
│                      Public API Layer                         │
├───────────────┬───────────────────────────┬───────────────────┤
│ Descriptor    │ Message                   │ Service           │
│ Management    │ Manipulation              │ Reflection        │
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

- **Swift 6**: Utilizing the latest language features for performance and safety
- **SwiftProtobuf**: Apple's Swift Protobuf library for wire format compatibility and low-level operations
- **Swift Concurrency**: Leveraging async/await for efficient asynchronous operations
- **Swift Macros**: For compile-time optimization where appropriate
- **No Runtime Dependencies**: Self-contained operation without external runtime requirements

## 4. Core Modules

### 4.1 Descriptor System
- **FileDescriptor**: Manages proto file metadata and symbols
- **MessageDescriptor**: Describes message structure and fields
- **FieldDescriptor**: Contains field metadata (type, name, number, options)
- **EnumDescriptor**: Defines enum types and values
- **ServiceDescriptor**: Describes gRPC service definitions

### 4.2 Dynamic Message
- **DynamicMessage**: Runtime representation of a protobuf message
- **MessageFactory**: Creates message instances from descriptors
- **FieldAccessor**: Type-safe field access and modification

### 4.3 Serialization
- **BinarySerializer**: Binary format serialization (wire format)
- **BinaryDeserializer**: Binary format deserialization
- **JSONAdapter**: JSON format conversion

### 4.4 Reflection Registry
- **TypeRegistry**: Central registry for all known types
- **DescriptorPool**: Manages descriptor dependencies and resolution

### 4.5 Service Layer
- **DynamicServiceClient**: Client for dynamically calling gRPC methods
- **MethodInvoker**: Handles method invocation with dynamic messages

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
- **Service Discovery**: Dynamic service and method discovery

### 5.3 Integration Points

The library will use several specific integration mechanisms:

1. **Binary Format Delegation**
   ```swift
   // Our DynamicMessage will delegate to Swift Protobuf for binary encoding
   func serializedData() throws -> Data {
     // Convert to compatible format and use Swift Protobuf's serialization
     let protoMessage = createSwiftProtobufMessage()
     return try protoMessage.serializedData()
   }
   ```

2. **Descriptor Conversion**
   ```swift
   // Converting between our descriptors and Swift Protobuf's descriptors
   extension MessageDescriptor {
     // Convert from Swift Protobuf descriptor to our dynamic descriptor
     init(swiftProtobufDescriptor: Google_Protobuf_DescriptorProto) {
       // Conversion logic
     }
     
     // Convert to Swift Protobuf descriptor when needed
     func toSwiftProtobufDescriptor() -> Google_Protobuf_DescriptorProto {
       // Conversion logic
     }
   }
   ```

3. **Field Value Handling**
   ```swift
   // Use Swift Protobuf's WireFormat for encoding field values
   func encodeField(number: Int, value: Any, to buffer: inout [UInt8]) throws {
     // Delegate to Swift Protobuf's encoding logic for the appropriate type
   }
   ```

### 5.4 Bridging Static and Dynamic Types

For interoperability with existing Swift Protobuf code, we'll provide conversion mechanisms:

```swift
// Convert from dynamic message to static Swift Protobuf message
extension DynamicMessage {
  func toStaticMessage<T: SwiftProtobuf.Message>() throws -> T {
    // Conversion logic
  }
  
  // Create dynamic message from static Swift Protobuf message
  static func fromStaticMessage<T: SwiftProtobuf.Message>(_ message: T) throws -> DynamicMessage {
    // Conversion logic
  }
}
```

## 6. Public API Design

The primary API interfaces will include:

```swift
// Creating a dynamic message
let message = DynamicMessage(descriptor: personDescriptor)

// Setting field values
try message.set(fieldName: "name", value: "John Doe")
try message.set(fieldNumber: 1, value: "John Doe")

// Getting field values
let name: String = try message.get(fieldName: "name")

// Serialization
let binaryData = try message.serializedData()
let jsonString = try message.jsonString()

// Deserialization
let message = try DynamicMessage.parse(data: binaryData, descriptor: personDescriptor)

// Converting between static and dynamic
let staticMessage: Person = try message.toStaticMessage()
let dynamicFromStatic = try DynamicMessage.fromStaticMessage(staticPerson)
```

## 7. Performance Considerations

- **Descriptor Caching**: Optimize descriptor lookup and resolution
- **Binary Encoding/Decoding**: Leverage Swift Protobuf's optimized implementation
- **Memory Management**: Careful management of reference cycles and memory usage
- **Type-Specialized Paths**: Generate specialized code paths for common field types
- **Minimal Conversion**: Reduce conversions between our types and Swift Protobuf types when possible

## 8. Project Structure

```
Sources/
  ├── SwiftProtoReflect/
  │   ├── Descriptor/
  │   │   ├── FileDescriptor.swift
  │   │   ├── MessageDescriptor.swift
  │   │   ├── FieldDescriptor.swift
  │   │   ├── EnumDescriptor.swift
  │   │   └── ServiceDescriptor.swift
  │   ├── Dynamic/
  │   │   ├── DynamicMessage.swift
  │   │   ├── MessageFactory.swift
  │   │   └── FieldAccessor.swift
  │   ├── Serialization/
  │   │   ├── BinarySerializer.swift
  │   │   ├── BinaryDeserializer.swift
  │   │   └── JSONAdapter.swift
  │   ├── Registry/
  │   │   ├── TypeRegistry.swift
  │   │   └── DescriptorPool.swift
  │   ├── Service/
  │   │   ├── DynamicServiceClient.swift
  │   │   └── MethodInvoker.swift
  │   ├── Bridge/
  │   │   ├── StaticMessageBridge.swift
  │   │   └── DescriptorBridge.swift
  │   └── Errors/
  │       └── ReflectionError.swift
  └── Examples/
      └── BasicUsage.swift
Tests/
  └── SwiftProtoReflectTests/
      ├── DescriptorTests/
      ├── DynamicMessageTests/
      ├── SerializationTests/
      ├── BridgeTests/
      └── ServiceTests/
```

## 9. Development Phases

1. **Foundation Phase**: Core descriptor and message implementations
2. **Serialization Phase**: Binary and JSON serialization/deserialization integration with Swift Protobuf
3. **Bridge Phase**: Develop static/dynamic message conversion capabilities
4. **Service Phase**: Dynamic service client implementation
5. **Integration Phase**: Integration with existing Swift Protobuf ecosystem
6. **Performance Optimization**: Benchmarking and optimization

## 10. Design Decisions

### Why Swift Protobuf as a Dependency?
Swift Protobuf provides a mature, well-tested implementation of Protocol Buffers wire format encoding and decoding. By leveraging this, we:
1. Ensure wire format compatibility with the standard Protocol Buffers implementation
2. Benefit from performance optimizations in the serialization layer
3. Provide seamless interoperability with generated Swift Protobuf code
4. Focus our development on reflection capabilities rather than reinventing serialization

### Internal Type Registry vs. On-Demand Resolution
The library will utilize a central type registry to manage descriptor dependencies efficiently, with on-demand resolution for improved performance when handling large descriptor sets.

### Error Handling Strategy
API will use Swift's throw/catch mechanism for error handling, with specific error types for better diagnostics.

## 11. Conclusion

This architecture provides a foundation for implementing the Protocol Buffers reflection capabilities outlined in the requirements. By clearly delineating responsibilities between our reflection layer and Swift Protobuf's serialization capabilities, we create a library that balances performance, usability, and maintainability while adhering to Swift's idioms and best practices.
