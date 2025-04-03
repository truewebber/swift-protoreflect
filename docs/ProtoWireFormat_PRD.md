# Protocol Buffer Wire Format - Product Requirements Document

## Overview

This document describes requirements for implementing Protocol Buffer wire format support in Swift, specifically targeting **proto3** format only. The implementation will provide dynamic message handling capabilities while maintaining compatibility with SwiftProtobuf's runtime library.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Application                       │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                     SwiftProtoReflect                       │
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │   Descriptor    │    │    Dynamic      │                 │
│  │   Registry      │    │    Message      │                 │
│  └────────┬────────┘    └────────┬────────┘                 │
│           │                       │                          │
│  ┌────────▼────────┐    ┌────────▼────────┐                 │
│  │    Type         │    │   Wire Format   │                 │
│  │    System       │    │     Module      │                 │
│  └────────┬────────┘    └────────┬────────┘                 │
│           │                       │                          │
└───────────┼───────────────────────┼───────────────────────┬─┘
            │                       │                        │
┌───────────▼───────────────────────▼────────────────────┐  │
│                     SwiftProtobuf                       │  │
│  ┌─────────────────┐    ┌─────────────────┐           │  │
│  │    Message      │    │  Binary Wire    │           │  │
│  │   Descriptor    │    │     Format      │           │  │
│  └─────────────────┘    └─────────────────┘           │  │
└─────────────────────────────────────────────────────┬─┘  │
                                                      │    │
┌─────────────────────────────────────────────────────▼────▼┐
│                     Swift Runtime                          │
└─────────────────────────────────────────────────────────┬─┘
```

## Goals

1. Implement Protocol Buffer wire format serialization and deserialization for proto3
2. Provide dynamic message handling capabilities
3. Maintain compatibility with SwiftProtobuf ecosystem
4. Ensure high performance and reliability

## Non-Goals

1. Support for proto2 format and features:
   - Required fields
   - Groups
   - Default field values
   - Complex extension mechanisms
2. Custom binary formats
3. Custom type systems

## Core Components

### 1. Descriptor Registry
- Manages Protocol Buffer descriptors
- Caches parsed descriptors
- Provides type information lookup
- Thread-safe descriptor access

### 2. Type System
- Maps Protocol Buffer types to Swift types
- Handles type validation
- Manages type conversion
- Supports proto3 type constraints

### 3. Dynamic Message
- Represents runtime Protocol Buffer messages
- Manages field access and modification
- Handles proto3 default values
- Supports reflection

### 4. Wire Format Module
- Implements binary serialization
- Handles deserialization
- Manages buffer operations
- Optimizes performance

## Requirements

### Core Functionality

1. Message Handling
   - Dynamic field access by field number
   - Support for all proto3 field types
   - Proper handling of default values (proto3 semantics)
   - Support for nested messages

2. Wire Format
   - Full proto3 wire format compatibility
   - Packed repeated fields for numeric types (proto3 default)
   - Proper field number and wire type encoding
   - Unknown fields preservation

3. Type System
   - All proto3 scalar types
   - Enums (proto3 style - first value must be zero)
   - Bytes
   - Messages
   - Maps
   - Repeated fields (always packed for numeric types)

### Memory Management

1. Buffer Strategy
```swift
public final class BufferPool {
    // Configurable buffer sizes
    static let smallMessageSize = 1024    // 1KB
    static let mediumMessageSize = 1_048_576  // 1MB
    static let largeMessageSize = 52_428_800  // 50MB
    
    // Buffer management
    func acquire(size: Int) -> Buffer
    func release(_ buffer: Buffer)
    
    // Pool statistics
    var stats: PoolStatistics { get }
}
```

2. Memory Limits
   - Maximum message size: 50MB
   - Maximum buffer pool size: 256MB
   - Maximum descriptor cache: 10,000 entries
   - Maximum nesting depth: 100 levels

### Error Handling

```swift
public enum ProtoWireFormatError: Error {
    // Type Errors
    case typeMismatch(expected: ProtoFieldType, got: ProtoFieldType)
    case invalidFieldNumber(number: Int)
    case wireTypeMismatch(expected: Int, got: Int)
    
    // Validation Errors
    case messageTooLarge(size: Int, max: Int)
    case nestingTooDeep(depth: Int, max: Int)
    case invalidUtf8String
    case invalidMapKey(reason: String)
    
    // Format Errors
    case truncatedMessage
    case malformedVarint
    case invalidTag
    
    // Resource Errors
    case outOfMemory
    case bufferTooSmall
}
```

### Performance

1. Metrics
   - Serialization performance within 20% of static messages
   - Deserialization performance within 20% of static messages
   - Memory usage within 2x of static messages
   - Performance deviation < 10%

2. Scalability
   - Efficient handling of large messages
   - Memory-efficient repeated field handling
   - Optimized map operations

### Reliability

1. Thread Safety
   - Safe concurrent message access
   - Thread-safe descriptor handling
   - Atomic serialization/deserialization

2. Resource Management
   - Proper memory management
   - Resource cleanup
   - No memory leaks
   - Handle circular references

## Success Criteria

1. All unit tests pass, including:
   - Basic field operations
   - Wire format compatibility
   - Performance benchmarks
   - Memory usage tests

2. Performance targets met:
   - Serialization/deserialization within 20% of static messages
   - Memory usage within specified limits
   - Performance deviation < 10%

3. Integration verification:
   - Successful conversion between dynamic and static messages
   - Compatibility with existing SwiftProtobuf code
   - Proper error handling

## Delivery Phases

### Phase 1: Core Implementation
- Basic message handling
- Proto3 wire format support
- Essential field types

### Phase 2: Advanced Features
- Repeated fields (packed)
- Map fields
- Nested messages
- Unknown fields

### Phase 3: Performance
- Optimization
- Benchmarking
- Memory usage improvements

### Phase 4: Documentation
- API documentation
- Usage examples
- Integration guides

## Integration Requirements

### SwiftProtobuf Bridge API
```swift
public protocol SwiftProtobufBridge {
    func toSwiftProtobuf() -> Message
    static func fromSwiftProtobuf(_ message: Message) -> Self
}

public protocol DynamicMessage: SwiftProtobufBridge {
    // Field Access
    func getValue(_ fieldNumber: Int) throws -> Any
    func setValue(_ value: Any, forField fieldNumber: Int) throws
    
    // Type Information
    var descriptor: Google_Protobuf_DescriptorProto { get }
    
    // Validation
    func validate() throws
}
```

### Test Coverage Matrix

| Test Case | Requirements |
|-----------|--------------|
| testAllPrimitiveFieldTypes | - All proto3 primitive types<br>- Proper default values<br>- Type validation |
| testEnumFieldSerialization | - Proto3 enum semantics<br>- Unknown value handling<br>- Default (0) value |
| testRepeatedFieldTypes | - Empty repeated fields<br>- Packed encoding<br>- Type validation |
| testMapFieldSerialization | - Empty maps<br>- Key type validation<br>- Value type validation |
| testNestedMessageSerialization | - Deep nesting (up to 100 levels)<br>- Circular reference detection |
| testUnknownFields | - Field preservation<br>- Round-trip serialization |
| testLargeMessageSerialization | - Messages up to 50MB<br>- Memory efficiency |

### Performance Requirements

1. Serialization/Deserialization
   - Base Performance: Within 20% of SwiftProtobuf
   - Maximum Deviation: 10%
   - Measurement Methodology:
     ```swift
     struct PerformanceTest {
         static let sampleSize = 1000
         static let messageTypes = [
             "primitive": generatePrimitiveMessage(),
             "repeated": generateRepeatedMessage(),
             "map": generateMapMessage(),
             "nested": generateNestedMessage()
         ]
         static let messageSizes = [
             "small": 1024,      // 1KB
             "medium": 1048576,  // 1MB
             "large": 10485760   // 10MB
         ]
     }
     ```

2. Memory Usage
   - Peak Usage: Not exceeding 2x of static message
   - Allocation Pattern:
     ```swift
     struct MemoryLimits {
         static let maxMessageSize = 52_428_800  // 50MB
         static let maxBufferPoolSize = 268_435_456  // 256MB
         static let maxDescriptorCacheSize = 10_000
         static let maxNestingDepth = 100
     }
     ```

### Error Handling

```swift
public enum ProtoWireFormatError: Error {
    // Type Errors
    case typeMismatch(expected: ProtoFieldType, got: ProtoFieldType)
    case invalidFieldNumber(number: Int)
    case wireTypeMismatch(expected: Int, got: Int)
    
    // Validation Errors
    case messageTooLarge(size: Int, max: Int)
    case nestingTooDeep(depth: Int, max: Int)
    case invalidUtf8String
    case invalidMapKey(reason: String)
    
    // Format Errors
    case truncatedMessage
    case malformedVarint
    case invalidTag
    
    // Resource Errors
    case outOfMemory
    case bufferTooSmall
}
```

### Documentation Requirements

1. API Documentation
   - Full API reference with examples
   - Type and parameter documentation
   - Error handling guidelines
   - Thread safety notes

2. Integration Guide
   ```markdown
   ## Integration Steps
   1. Message Creation
   2. Field Access
   3. Serialization
   4. Error Handling
   5. Performance Optimization
   ```

3. Examples
   - Basic usage
   - Complex message handling
   - Error handling patterns
   - Performance optimization
   - SwiftProtobuf integration

## Success Criteria

1. Functionality
   - All test cases pass
   - Full proto3 compliance
   - Complete error handling
   - Thread safety verified

2. Performance
   - Serialization: Within 20% of SwiftProtobuf
   - Deserialization: Within 20% of SwiftProtobuf
   - Memory: Within 2x of static message
   - Deviation: < 10% across operations

3. Test Coverage
   - Unit tests: > 90%
   - Integration tests: > 85%
   - Performance tests: All message sizes
   - Error handling: All error cases

4. Documentation
   - Complete API reference
   - Integration guide
   - Example projects
   - Performance guidelines

## Delivery Phases

1. Core Implementation (2 weeks)
   - Basic message handling
   - Field access API
   - Initial serialization

2. Advanced Features (2 weeks)
   - Complex field types
   - Validation
   - Error handling

3. Performance Optimization (1 week)
   - Benchmarking
   - Optimization
   - Memory management

4. Documentation & Testing (1 week)
   - API documentation
   - Examples
   - Test coverage
   - Performance validation
