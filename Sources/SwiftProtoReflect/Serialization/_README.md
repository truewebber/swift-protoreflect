# Serialization Module

This module handles serialization and deserialization of Protocol Buffers messages. It provides:

- Binary serialization to wire format
- Deserialization from binary format
- JSON serialization according to Protocol Buffers JSON mapping
- JSON deserialization according to Protocol Buffers JSON mapping

## Module Status

- [x] **BinarySerializer** ✅ - fully implemented with 90.77% test coverage
- [x] **BinaryDeserializer** ✅ - fully implemented with 89.69% test coverage
- [x] **WireFormat** ✅ - common definitions for Protocol Buffers wire types
- [x] **JSONSerializer** ✅ - fully implemented with 81.85% test coverage
- [x] **JSONDeserializer** ✅ - fully implemented with 60.25% test coverage

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

### JSONSerializer
- JSON serialization according to official Protocol Buffers JSON mapping
- Support for all scalar types with correct JSON representation
- Special values: Infinity, -Infinity, NaN for float/double
- Repeated fields as JSON arrays
- Map fields as JSON objects
- Nested messages as nested JSON objects
- Bytes fields as base64 strings
- int64/uint64 as strings in JSON (according to specification)
- Configurable serialization options (field names, formatting)

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

### WireFormat
- Public WireType definitions for shared usage
- Compliance with Protocol Buffers wire format standard

## Interactions with Other Modules

- **Dynamic**: for working with dynamic messages
- **Descriptor**: for getting type metadata during serialization/deserialization
- **Bridge**: for integration with Swift Protobuf serialization

## Test Coverage

- **BinarySerializer**: 90.77% code coverage (27 tests)
- **BinaryDeserializer**: 89.69% code coverage (20 tests)
- **JSONSerializer**: 81.85% code coverage (16 tests)
- **JSONDeserializer**: 60.25% code coverage (24 tests)
- **Round-trip testing**: all field types verified for serialization/deserialization compatibility

## JSON Round-trip Compatibility

The module ensures full compatibility between JSONSerializer and JSONDeserializer:
- **Message → JSON → Message**: data preserved without loss
- **All field types**: scalar, repeated, map, nested messages
- **Special values**: float/double special cases
- **Data formats**: correct handling of base64, numeric strings, boolean values
- **Options**: support for various serialization/deserialization settings
