# Serialization Module

This module handles serialization and deserialization of Protocol Buffers messages. It provides:

- Binary serialization to wire format
- Deserialization from binary format
- JSON serialization according to Protocol Buffers JSON mapping
- JSON deserialization according to Protocol Buffers JSON mapping

> **Required dependency:** All serializers and deserializers require a `TypeRegistry` passed
> through their options structs (`DeserializationOptions`, `JSONDeserializationOptions`,
> `JSONSerializationOptions`). TypeRegistry is the primary type-resolution mechanism for nested
> messages and enums. The no-argument constructors `BinaryDeserializer()`, `JSONDeserializer()`,
> and `JSONSerializer()` are **deprecated**.

## Quick Start

```swift
// 1. Build a TypeRegistry with all types your message references.
let registry = TypeRegistry()
try registry.registerMessage(addressDescriptor)   // if Msg has a message field
try registry.registerEnum(statusEnum)             // if Msg has an enum field

// For production use with FileDescriptors:
// let registry = TypeRegistry(fileDescriptors: [myFile, otherFile])

// 2. Serialize
let serializer = JSONSerializer(options: .init(typeRegistry: registry))
let jsonData = try serializer.serialize(message)

// 3. Deserialize
let deserializer = BinaryDeserializer(options: .init(typeRegistry: registry))
let decoded = try deserializer.deserialize(binaryData, using: descriptor)
```

## Module Status

- [x] **BinarySerializer** ✅ - fully implemented
- [x] **BinaryDeserializer** ✅ - fully implemented; TypeRegistry-primary resolution
- [x] **WireFormat** ✅ - common definitions for Protocol Buffers wire types
- [x] **JSONSerializer** ✅ - fully implemented; TypeRegistry-primary enum resolution
- [x] **JSONDeserializer** ✅ - fully implemented; TypeRegistry-primary enum/message resolution

## Type Resolution

All serializers and deserializers perform type resolution in this priority order:

1. **TypeRegistry** (primary) — looks up the type by fully-qualified name (e.g., `"pkg.Status"`).
2. **Structural nesting** (deprecated fallback) — falls back to `nestedMessage(named:)` /
   `nestedEnum(named:)` on the parent `MessageDescriptor`.

The deprecated fallback is retained for backward compatibility but **will be removed in a
future major version**. Migrate all type resolution to TypeRegistry.

## Implemented Components

### BinarySerializer
- Support for all Protocol Buffers scalar types
- Repeated fields (packed and non-packed)
- Map fields with various key and value types
- Nested messages and enum fields
- ZigZag encoding for sint32/sint64
- Wire format compatibility with Protocol Buffers standard

### BinaryDeserializer
- Round-trip deserialization with all field types
- Unknown field handling for backward compatibility
- ZigZag decoding
- Packed repeated fields handling
- Correct UTF-8 string validation
- Detailed error handling
- TypeRegistry-primary nested/sibling message resolution

### JSONSerializer
- JSON serialization according to official Protocol Buffers JSON mapping
- Support for all scalar types with correct JSON representation
- Special values: Infinity, -Infinity, NaN for float/double
- Repeated fields as JSON arrays
- Map fields as JSON objects
- Nested messages as nested JSON objects
- Bytes fields as base64 strings
- int64/uint64 as strings in JSON (according to specification)
- Configurable serialization options (field names, formatting, includeDefaultValues)
- TypeRegistry-primary enum name resolution

### JSONDeserializer
- JSON deserialization according to official Protocol Buffers JSON mapping
- Round-trip compatibility with JSONSerializer
- Support for all scalar types from JSON representation
- Special values: parsing "Infinity", "-Infinity", "NaN"
- Repeated fields from JSON arrays
- Map fields from JSON objects with key conversion
- Base64 decoding for bytes fields
- Strict typing with detailed validation errors
- Configurable options (ignoring unknown fields)
- Handling of both original and camelCase field names
- TypeRegistry-primary enum and nested message resolution

### WireFormat
- Public WireType definitions for shared usage
- Compliance with Protocol Buffers wire format standard

## Interactions with Other Modules

- **Registry**: TypeRegistry is a required input for all serializer/deserializer options
- **Dynamic**: for working with dynamic messages
- **Descriptor**: for getting type metadata during serialization/deserialization
- **Bridge**: for integration with Swift Protobuf serialization

## JSON Round-trip Compatibility

The module ensures full compatibility between JSONSerializer and JSONDeserializer:
- **Message → JSON → Message**: data preserved without loss
- **All field types**: scalar, repeated, map, nested messages
- **Special values**: float/double special cases
- **Data formats**: correct handling of base64, numeric strings, boolean values
- **Options**: support for various serialization/deserialization settings
