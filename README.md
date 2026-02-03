# SwiftProtoReflect

A Swift library for dynamic Protocol Buffers message manipulation without pre-compiled schemas.

[![Platform](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftruewebber%2Fswift-protoreflect%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/truewebber/swift-protoreflect)
[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftruewebber%2Fswift-protoreflect%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/truewebber/swift-protoreflect)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](LICENSE)
[![Coverage](https://img.shields.io/badge/Test%20Coverage-94%25-green.svg?style=flat)](#quality-metrics)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/truewebber/swift-protoreflect)

## Overview

SwiftProtoReflect enables runtime manipulation of Protocol Buffers messages without requiring code generation from `.proto` files. This is useful for building generic tools, API gateways, data processors, and other applications that need to work with protobuf schemas dynamically.

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/truewebber/swift-protoreflect.git", from: "4.0.0")
]
```

> **⚠️ Important:** We strongly recommend using version 4.0.0 or higher. Earlier versions included heavy gRPC dependencies that have been removed for a lighter, more focused library.

## Basic Usage

### Creating Messages Dynamically

```swift
import SwiftProtoReflect

// Define a message schema at runtime
let personSchema = try MessageDescriptor.builder("Person")
    .addField("name", number: 1, type: .string)
    .addField("age", number: 2, type: .int32)
    .addField("emails", number: 3, type: .string, label: .repeated)
    .build()

// Create and populate a message
let message = try MessageFactory().createMessage(from: personSchema)
try message.set("name", value: "Alice")
try message.set("age", value: 25)
try message.set("emails", value: ["alice@example.com"])

// Serialize to binary or JSON
let binaryData = try BinarySerializer().serialize(message: message)
let jsonString = try JSONSerializer().serialize(message: message)
```

### Working with Well-Known Types

```swift
// Timestamps
let now = Date()
let timestampMessage = try now.toTimestampMessage()
let backToDate = try timestampMessage.toDate()

// JSON-like structures
let data: [String: Any] = ["user": "john", "active": true]
let structMessage = try data.toStructMessage()

// Type erasure
let anyMessage = try message.packIntoAny()
let unpackedMessage = try anyMessage.unpackFromAny(to: personSchema)
```

## Features

- **Dynamic Message Creation**: Create and manipulate protobuf messages at runtime
- **Schema Definition**: Build message descriptors programmatically
- **Serialization**: Binary and JSON serialization/deserialization
- **Well-Known Types**: Support for Google's standard protobuf types
- **Swift Protobuf Compatibility**: Convert between static and dynamic messages
- **Type Registry**: Centralized type management and lookup

## Examples

The library includes 38 working examples demonstrating various use cases:

```bash
git clone https://github.com/truewebber/swift-protoreflect.git
cd swift-protoreflect/examples

# Basic examples
swift run HelloWorld
swift run FieldTypes
swift run TimestampDemo

# Advanced examples
swift run ApiGateway
swift run MessageTransform
swift run ValidationFramework
```

Examples are organized by topic:
- **Basic Usage** (4 examples): Getting started
- **Dynamic Messages** (6 examples): Message manipulation
- **Serialization** (5 examples): Binary and JSON formats
- **Registry** (4 examples): Type management
- **Well-Known Types** (8 examples): Google standard types
- **Advanced** (6 examples): Complex patterns
- **Real-World** (5 examples): Production scenarios

## Requirements

- Swift 5.9+
- macOS 12.0+ / iOS 15.0+
- **Recommended:** SwiftProtoReflect 4.0.0+

## Dependencies

- [SwiftProtobuf](https://github.com/apple/swift-protobuf) 1.29.0+

## Documentation

- **[Architecture Guide](docs/ARCHITECTURE.md)**: Technical implementation details
- **[Migration Guide](MIGRATION_GUIDE.md)**: Migrating from static Swift Protobuf

## Use Cases

- Generic protobuf tools (viewers, debuggers, converters)
- API gateways with dynamic message routing
- Data processing pipelines with runtime schema handling
- Testing tools that generate data for arbitrary schemas
- Configuration systems using protobuf schemas

## Integration with Swift Protobuf

SwiftProtoReflect works alongside existing Swift Protobuf code:

```swift
// Convert static to dynamic
let staticMessage = Person.with { /* ... */ }
let dynamicMessage = try staticMessage.toDynamicMessage()

// Convert dynamic to static
let staticMessage: Person = try dynamicMessage.toStaticMessage()
```

## Testing

The library has comprehensive test coverage covering all functionality and edge cases.

## License

MIT License. See [LICENSE](LICENSE) for details.
