# SwiftProtoReflect API Documentation

This document provides detailed API documentation for the SwiftProtoReflect library, focusing on the dynamic Protocol Buffer handling capabilities built on top of Apple's SwiftProtobuf library.

## Architecture Overview

SwiftProtoReflect extends Apple's SwiftProtobuf library with dynamic message handling capabilities. Rather than creating parallel implementations of Protocol Buffer concepts, we build directly on SwiftProtobuf's types and wire format implementation.

```
┌─────────────────────────────────────────────────────────────┐
│                     Your Application                         │
└───────────────┬─────────────────────────┬───────────────────┘
                │                         │
                ▼                         ▼
┌───────────────────────────┐ ┌─────────────────────────────┐
│    Generated Swift Code    │ │      SwiftProtoReflect      │
│    (Static Approach)       │ │     (Dynamic Approach)      │
└───────────────┬───────────┘ └─────────────┬───────────────┘
                │                           │
                ▼                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      SwiftProtobuf                           │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### DynamicMessage

`DynamicMessage` is the central class for dynamic Protocol Buffer handling. It wraps a message descriptor and provides dynamic access to fields.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `descriptor` | `MessageDescriptor` | The descriptor defining the message structure. |
| `storage` | `[Int: Any]` | Internal storage for field values, keyed by field number. |

#### Methods

| Method | Description |
|--------|-------------|
| `init(descriptor: MessageDescriptor)` | Creates a new dynamic message based on the provided descriptor. |
| `get(fieldName: String) -> Any?` | Gets the value of a field by its name. |
| `get(fieldNumber: Int) -> Any?` | Gets the value of a field by its number. |
| `get(field: FieldDescriptor) -> Any?` | Gets the value of a field using its descriptor. |
| `set(fieldName: String, value: Any) throws` | Sets the value of a field by its name. |
| `set(fieldNumber: Int, value: Any) throws` | Sets the value of a field by its number. |
| `set(field: FieldDescriptor, value: Any) throws` | Sets the value of a field using its descriptor. |
| `has(fieldName: String) -> Bool` | Checks if a field has a value by its name. |
| `has(fieldNumber: Int) -> Bool` | Checks if a field has a value by its number. |
| `has(field: FieldDescriptor) -> Bool` | Checks if a field has a value using its descriptor. |
| `clear()` | Clears all field values. |
| `clearField(name: String)` | Clears the value of a field by its name. |
| `clearField(number: Int)` | Clears the value of a field by its number. |
| `clearField(field: FieldDescriptor)` | Clears the value of a field using its descriptor. |
| `serializedData() throws -> Data` | Serializes the message to binary format using SwiftProtobuf's serialization. |
| `jsonUTF8Data() throws -> Data` | Serializes the message to JSON format using SwiftProtobuf's serialization. |
| `textFormatString() throws -> String` | Serializes the message to text format using SwiftProtobuf's serialization. |

#### Example

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let messageDescriptor = try DescriptorRegistry.shared.messageDescriptor(forTypeName: "example.Person")

// Create dynamic message
let person = DynamicMessage(descriptor: messageDescriptor)

// Set field values
try person.set(fieldName: "name", value: "John Doe")
try person.set(fieldName: "age", value: 30)

// Get field values
if let name = person.get(fieldName: "name") as? String {
    print("Name: \(name)")
}

// Serialize to binary format
let data = try person.serializedData()

// Create a new message and deserialize
let newPerson = try DynamicMessage(descriptor: messageDescriptor, serializedData: data)
```

### MessageDescriptor

`MessageDescriptor` is a wrapper for SwiftProtobuf's `Google_Protobuf_DescriptorProto` that provides a more convenient API for working with message descriptors.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The name of the message. |
| `fullName` | `String` | The fully qualified name of the message, including package. |
| `fields` | `[FieldDescriptor]` | The fields defined in the message. |
| `oneofs` | `[OneofDescriptor]` | The oneof fields defined in the message. |
| `nestedTypes` | `[MessageDescriptor]` | Nested message types defined within this message. |
| `enumTypes` | `[EnumDescriptor]` | Enum types defined within this message. |

#### Methods

| Method | Description |
|--------|-------------|
| `init(descriptor: Google_Protobuf_DescriptorProto, fullName: String)` | Creates a new message descriptor from a SwiftProtobuf descriptor. |
| `fieldByName(_ name: String) -> FieldDescriptor?` | Gets a field descriptor by its name. |
| `fieldByNumber(_ number: Int) -> FieldDescriptor?` | Gets a field descriptor by its number. |
| `isExtensible() -> Bool` | Checks if the message supports extensions. |

#### Example

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let messageDescriptor = try DescriptorRegistry.shared.messageDescriptor(forTypeName: "example.Person")

// Access descriptor properties
print("Message name: \(messageDescriptor.name)")
print("Full name: \(messageDescriptor.fullName)")

// Access fields
for field in messageDescriptor.fields {
    print("Field \(field.number): \(field.name) (\(field.type))")
}

// Look up a specific field
if let nameField = messageDescriptor.fieldByName("name") {
    print("Name field number: \(nameField.number)")
}
```

### FieldDescriptor

`FieldDescriptor` is a wrapper for SwiftProtobuf's `Google_Protobuf_FieldDescriptorProto` that provides a more convenient API for working with field descriptors.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The name of the field. |
| `number` | `Int` | The field number. |
| `type` | `FieldType` | The type of the field. |
| `isRepeated` | `Bool` | Whether the field is repeated. |
| `isMap` | `Bool` | Whether the field is a map. |
| `isRequired` | `Bool` | Whether the field is required. |
| `defaultValue` | `Any?` | The default value of the field, if any. |
| `containingOneof` | `OneofDescriptor?` | The oneof descriptor if this field is part of a oneof. |
| `messageType` | `MessageDescriptor?` | The message descriptor if this field is a message type. |
| `enumType` | `EnumDescriptor?` | The enum descriptor if this field is an enum type. |

#### Methods

| Method | Description |
|--------|-------------|
| `init(descriptor: Google_Protobuf_FieldDescriptorProto, parent: MessageDescriptor)` | Creates a new field descriptor from a SwiftProtobuf descriptor. |
| `isValidValue(_ value: Any) -> Bool` | Checks if a value is valid for this field. |
| `wireFormat() -> WireFormat` | Gets the wire format for this field. |

#### Example

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let messageDescriptor = try DescriptorRegistry.shared.messageDescriptor(forTypeName: "example.Person")

// Get a field descriptor
if let nameField = messageDescriptor.fieldByName("name") {
    // Access field properties
    print("Field name: \(nameField.name)")
    print("Field number: \(nameField.number)")
    print("Field type: \(nameField.type)")
    
    // Check if a value is valid for this field
    let isValid = nameField.isValidValue("John Doe")
    print("Is valid value: \(isValid)")
}
```

### EnumDescriptor

`EnumDescriptor` is a wrapper for SwiftProtobuf's `Google_Protobuf_EnumDescriptorProto` that provides a more convenient API for working with enum descriptors.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The name of the enum. |
| `fullName` | `String` | The fully qualified name of the enum, including package. |
| `values` | `[EnumValueDescriptor]` | The values defined in the enum. |

#### Methods

| Method | Description |
|--------|-------------|
| `init(descriptor: Google_Protobuf_EnumDescriptorProto, fullName: String)` | Creates a new enum descriptor from a SwiftProtobuf descriptor. |
| `valueByName(_ name: String) -> EnumValueDescriptor?` | Gets an enum value descriptor by its name. |
| `valueByNumber(_ number: Int) -> EnumValueDescriptor?` | Gets an enum value descriptor by its number. |

#### Example

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get an enum descriptor from the registry
let enumDescriptor = try DescriptorRegistry.shared.enumDescriptor(forTypeName: "example.Gender")

// Access enum properties
print("Enum name: \(enumDescriptor.name)")
print("Full name: \(enumDescriptor.fullName)")

// Access enum values
for value in enumDescriptor.values {
    print("Value \(value.number): \(value.name)")
}

// Look up a specific value
if let maleValue = enumDescriptor.valueByName("MALE") {
    print("MALE value number: \(maleValue.number)")
}
```

### DescriptorRegistry

`DescriptorRegistry` provides utilities for managing and accessing descriptors.

#### Methods

| Method | Description |
|--------|-------------|
| `add(fileDescriptor: Google_Protobuf_FileDescriptorProto) throws` | Registers a file descriptor for later use. |
| `messageDescriptor(forTypeName: String) throws -> MessageDescriptor` | Gets a message descriptor by its fully qualified name. |
| `enumDescriptor(forTypeName: String) throws -> EnumDescriptor` | Gets an enum descriptor by its fully qualified name. |

#### Example

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Create a registry
let registry = DescriptorRegistry()

// Register a file descriptor
let fileDescriptor = Google_Protobuf_FileDescriptorProto.with {
    $0.name = "person.proto"
    $0.package = "example"
    // ... set up the descriptor ...
}
try registry.add(fileDescriptor: fileDescriptor)

// Get a message descriptor
let personDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Use the descriptor to create a dynamic message
let person = DynamicMessage(descriptor: personDescriptor)
```

### MessageConverter

`MessageConverter` provides utilities for converting between generated SwiftProtobuf messages and dynamic messages.

#### Methods

| Method | Description |
|--------|-------------|
| `fromMessage<M: Message>(_ message: M) throws -> DynamicMessage` | Converts a generated SwiftProtobuf message to a dynamic message. |
| `toMessage<M: Message>(dynamicMessage: DynamicMessage) throws -> M` | Converts a dynamic message to a generated SwiftProtobuf message type. |

#### Example

```swift
import SwiftProtobuf
import SwiftProtoReflect
import GeneratedProtos

// Using generated code from protoc + SwiftProtobuf
var person = Person()
person.name = "Alice"
person.age = 30

// Convert to dynamic message
let dynamicPerson = try MessageConverter.fromMessage(person)

// Modify dynamically
try dynamicPerson.set(fieldName: "email", value: "alice@example.com")

// Convert back to generated type
let updatedPerson = try MessageConverter.toMessage(dynamicMessage: dynamicPerson) as Person
print("Updated person: \(updatedPerson)")
```

## Working with Generated Code

SwiftProtoReflect is designed to work seamlessly with code generated by protoc and the SwiftProtobuf plugin.

### Accessing Descriptors from Generated Code

```swift
import SwiftProtobuf
import SwiftProtoReflect
import GeneratedProtos

// Get the descriptor set from generated code
let descriptorSet = Person_protoDescriptor

// Register with the registry
let registry = DescriptorRegistry()
try registry.add(descriptorSet: descriptorSet)

// Get the message descriptor
let personDescriptor = try registry.messageDescriptor(forTypeName: "Person")

// Create a dynamic message
let dynamicPerson = DynamicMessage(descriptor: personDescriptor)
```

### Converting Between Static and Dynamic Messages

```swift
import SwiftProtobuf
import SwiftProtoReflect
import GeneratedProtos

// Create a generated message
var person = Person()
person.name = "Alice"
person.age = 30

// Convert to dynamic message
let dynamicPerson = try MessageConverter.fromMessage(person)

// Modify the dynamic message
try dynamicPerson.set(fieldName: "email", value: "alice@example.com")

// Convert back to generated type
let updatedPerson = try MessageConverter.toMessage(dynamicMessage: dynamicPerson) as Person
print("Name: \(updatedPerson.name), Age: \(updatedPerson.age)")
```

## Reflection and Introspection

SwiftProtoReflect provides rich reflection capabilities for exploring message structures at runtime.

### Exploring Message Structure

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a message descriptor
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Explore fields
for field in messageDescriptor.fields {
    print("Field: \(field.name), Number: \(field.number), Type: \(field.type)")
    
    // Check if it's a message type
    if let messageType = field.messageType {
        print("  Message type: \(messageType.name)")
    }
    
    // Check if it's repeated
    if field.isRepeated {
        print("  Repeated field")
    }
    
    // Check if it's a map
    if field.isMap {
        print("  Map field")
    }
}
```

### Dynamic Field Access

```swift
// Create a dynamic message
let person = DynamicMessage(descriptor: personDescriptor)

// Set field values dynamically
try person.set(fieldName: "name", value: "John")

// Get field values dynamically
for field in person.descriptor.fields {
    if let value = person.get(field: field) {
        print("\(field.name): \(value)")
    }
}
```

## Best Practices

1. **Use Generated Code When Possible**: For known message types, use the generated SwiftProtobuf code for better type safety and performance.

2. **Dynamic Approach for Unknown Schemas**: Use SwiftProtoReflect's dynamic capabilities when working with messages whose schema is not known at compile time.

3. **Combine Both Approaches**: Take advantage of the seamless conversion between static and dynamic approaches to use each where it makes the most sense.

4. **Register Descriptors Early**: If working with descriptors from .proto files, register them with DescriptorRegistry early in your application lifecycle.

5. **Validate Input**: When setting field values dynamically, validate that the values match the expected types to avoid runtime errors.

## Performance Considerations

1. **Dynamic vs. Static**: Dynamic message handling is generally slower than using generated code. Use generated code for performance-critical paths.

2. **Caching**: Cache descriptors and dynamic messages when possible to avoid repeated lookups and conversions.

3. **Batch Operations**: When converting between static and dynamic messages, batch operations to minimize overhead.

4. **Memory Usage**: Dynamic messages may use more memory than generated messages. Monitor memory usage in your application.

5. **Lazy Loading**: Use lazy loading for nested messages to improve performance when working with large message structures.

## Working with Descriptors

### Loading Multiple File Descriptors

The `DescriptorRegistry` supports loading multiple file descriptors, which is useful when working with complex Protocol Buffer schemas that span multiple files.

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Create a registry
let registry = DescriptorRegistry()

// Method 1: Load multiple file descriptors individually
let fileDescriptor1 = Google_Protobuf_FileDescriptorProto.with {
    $0.name = "person.proto"
    $0.package = "example"
    // ... set up the descriptor ...
}

let fileDescriptor2 = Google_Protobuf_FileDescriptorProto.with {
    $0.name = "address.proto"
    $0.package = "example"
    // ... set up the descriptor ...
}

// Add each file descriptor to the registry
try registry.add(fileDescriptor: fileDescriptor1)
try registry.add(fileDescriptor: fileDescriptor2)

// Method 2: Load from a FileDescriptorSet containing multiple file descriptors
let url = URL(fileURLWithPath: "path/to/descriptor_set.bin")
let data = try Data(contentsOf: url)
let fileDescriptorSet = try Google_Protobuf_FileDescriptorSet(serializedData: data)

// Add all file descriptors from the set
for fileDescriptor in fileDescriptorSet.file {
    try registry.add(fileDescriptor: fileDescriptor)
}

// Method 3: Load from multiple generated Swift code files
// Each generated Swift file typically has a static descriptor
try registry.add(descriptorSet: Person_protoDescriptor)
try registry.add(descriptorSet: Address_protoDescriptor)
```

The registry handles dependencies between file descriptors automatically. If a file descriptor references types defined in another file descriptor, the registry will resolve these references as long as all the necessary file descriptors have been added.

### Working with Services and RPC

SwiftProtoReflect provides support for working with Protocol Buffer services and RPC methods through the `ServiceDescriptor` and `MethodDescriptor` classes.

#### ServiceDescriptor

`ServiceDescriptor` is a wrapper for SwiftProtobuf's `Google_Protobuf_ServiceDescriptorProto` that provides a more convenient API for working with service descriptors.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The name of the service. |
| `fullName` | `String` | The fully qualified name of the service, including package. |
| `methods` | `[MethodDescriptor]` | The methods defined in the service. |

#### Methods

| Method | Description |
|--------|-------------|
| `init(descriptor: Google_Protobuf_ServiceDescriptorProto, fullName: String)` | Creates a new service descriptor from a SwiftProtobuf descriptor. |
| `methodByName(_ name: String) -> MethodDescriptor?` | Gets a method descriptor by its name. |

#### MethodDescriptor

`MethodDescriptor` is a wrapper for SwiftProtobuf's `Google_Protobuf_MethodDescriptorProto` that provides a more convenient API for working with method descriptors.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The name of the method. |
| `fullName` | `String` | The fully qualified name of the method, including service name. |
| `inputType` | `String` | The fully qualified name of the input message type. |
| `outputType` | `String` | The fully qualified name of the output message type. |
| `isClientStreaming` | `Bool` | Whether the method is client streaming. |
| `isServerStreaming` | `Bool` | Whether the method is server streaming. |

#### Methods

| Method | Description |
|--------|-------------|
| `init(descriptor: Google_Protobuf_MethodDescriptorProto, serviceFullName: String)` | Creates a new method descriptor from a SwiftProtobuf descriptor. |

#### Example: Accessing Service and Method Descriptors

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a service descriptor from the registry
let registry = DescriptorRegistry.shared
let serviceDescriptor = try registry.serviceDescriptor(forTypeName: "example.GreeterService")

// Access service properties
print("Service name: \(serviceDescriptor.name)")
print("Full name: \(serviceDescriptor.fullName)")

// Access methods
for method in serviceDescriptor.methods {
    print("Method: \(method.name)")
    print("  Input type: \(method.inputType)")
    print("  Output type: \(method.outputType)")
    print("  Client streaming: \(method.isClientStreaming)")
    print("  Server streaming: \(method.isServerStreaming)")
}

// Look up a specific method
if let sayHelloMethod = serviceDescriptor.methodByName("SayHello") {
    print("Found method: \(sayHelloMethod.fullName)")
}
```

#### Example: Making Dynamic RPC Calls

To make RPC calls using dynamic messages, you would typically integrate with a gRPC client library like grpc-swift. Here's a conceptual example:

```swift
import SwiftProtobuf
import SwiftProtoReflect
import GRPC

// Create a dynamic service client
class DynamicServiceClient {
    let channel: GRPCChannel
    let registry: DescriptorRegistry
    
    init(channel: GRPCChannel, registry: DescriptorRegistry) {
        self.channel = channel
        self.registry = registry
    }
    
    func call(service: String, method: String, request: DynamicMessage) async throws -> DynamicMessage {
        // Get service descriptor
        let serviceDescriptor = try registry.serviceDescriptor(forTypeName: service)
        
        // Get method descriptor
        guard let methodDescriptor = serviceDescriptor.methodByName(method) else {
            throw ServiceError.methodNotFound(method)
        }
        
        // Get output message descriptor
        let outputDescriptor = try registry.messageDescriptor(forTypeName: methodDescriptor.outputType)
        
        // Serialize request
        let requestData = try request.serializedData()
        
        // Make RPC call
        let responseData = try await channel.makeUnaryCall(
            path: "/\(serviceDescriptor.fullName)/\(methodDescriptor.name)",
            requestData: requestData
        )
        
        // Deserialize response
        return try DynamicMessage(descriptor: outputDescriptor, serializedData: responseData)
    }
}

// Usage example
let registry = DescriptorRegistry.shared
let channel = GRPCChannel(host: "example.com", port: 443)
let client = DynamicServiceClient(channel: channel, registry: registry)

// Create request message
let requestDescriptor = try registry.messageDescriptor(forTypeName: "example.HelloRequest")
let request = DynamicMessage(descriptor: requestDescriptor)
try request.set(fieldName: "name", value: "World")

// Make RPC call
let response = try await client.call(
    service: "example.GreeterService", 
    method: "SayHello", 
    request: request
)

// Access response
if let message = response.get(fieldName: "message") as? String {
    print("Response: \(message)")
}
```

This example demonstrates how to use SwiftProtoReflect's dynamic message capabilities with gRPC to make RPC calls without generated code. The actual implementation would depend on the specific gRPC client library being used. 