# SwiftProtoReflect Documentation Examples

This document provides practical examples of using the SwiftProtoReflect library for dynamic Protocol Buffer handling. These examples demonstrate the core functionality of the library and how it integrates with Apple's SwiftProtobuf.

## Table of Contents

1. [Installation](#installation)
2. [Basic Usage](#basic-usage)
3. [Dynamic Message Handling](#dynamic-message-handling)
4. [Serialization and Deserialization](#serialization-and-deserialization)
5. [Working with Descriptors](#working-with-descriptors)
6. [Conversion Between Static and Dynamic Messages](#conversion-between-static-and-dynamic-messages)
7. [Reflection and Introspection](#reflection-and-introspection)
8. [Advanced Usage](#advanced-usage)
9. [Best Practices](#best-practices)

## Installation

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/SwiftProtoReflect.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.20.0")
]
```

### CocoaPods

```ruby
# Podfile
pod 'SwiftProtoReflect', '~> 1.0'
pod 'SwiftProtobuf', '~> 1.20'
```

## Basic Usage Examples

### Creating a Dynamic Message

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Create a dynamic message
let person = DynamicMessage(descriptor: messageDescriptor)

// Set field values
try person.set(fieldName: "name", value: "John Doe")
try person.set(fieldName: "age", value: 30)

// Get field values
if let name = person.get(fieldName: "name") as? String {
    print("Name: \(name)")
}

if let age = person.get(fieldName: "age") as? Int32 {
    print("Age: \(age)")
}
```

### Working with Nested Messages

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get descriptors from the registry
let registry = DescriptorRegistry.shared
let personDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")
let addressDescriptor = try registry.messageDescriptor(forTypeName: "example.Address")

// Create a dynamic address message
let address = DynamicMessage(descriptor: addressDescriptor)
try address.set(fieldName: "street", value: "123 Main St")
try address.set(fieldName: "city", value: "Anytown")
try address.set(fieldName: "zipCode", value: "12345")

// Create a dynamic person message with the nested address
let person = DynamicMessage(descriptor: personDescriptor)
try person.set(fieldName: "name", value: "John Doe")
try person.set(fieldName: "address", value: address)

// Access nested fields
if let address = person.get(fieldName: "address") as? DynamicMessage,
   let city = address.get(fieldName: "city") as? String {
    print("City: \(city)")
}
```

### Working with Repeated Fields

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared
let personDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Create a dynamic message
let person = DynamicMessage(descriptor: personDescriptor)
try person.set(fieldName: "name", value: "John Doe")

// Add phone numbers (repeated field)
var phoneNumbers: [String] = []
phoneNumbers.append("555-1234")
phoneNumbers.append("555-5678")
try person.set(fieldName: "phoneNumbers", value: phoneNumbers)

// Access repeated field
if let numbers = person.get(fieldName: "phoneNumbers") as? [String] {
    for number in numbers {
        print("Phone: \(number)")
    }
}

// Add another phone number
if var numbers = person.get(fieldName: "phoneNumbers") as? [String] {
    numbers.append("555-9012")
    try person.set(fieldName: "phoneNumbers", value: numbers)
}
```

### Working with Map Fields

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared
let personDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Create a dynamic message
let person = DynamicMessage(descriptor: personDescriptor)
try person.set(fieldName: "name", value: "John Doe")

// Add attributes (map field)
var attributes: [String: String] = [:]
attributes["hair"] = "brown"
attributes["eyes"] = "blue"
try person.set(fieldName: "attributes", value: attributes)

// Access map field
if let attrs = person.get(fieldName: "attributes") as? [String: String] {
    for (key, value) in attrs {
        print("\(key): \(value)")
    }
}

// Add another attribute
if var attrs = person.get(fieldName: "attributes") as? [String: String] {
    attrs["height"] = "180cm"
    try person.set(fieldName: "attributes", value: attrs)
}
```

## Serialization and Deserialization

### Binary Format

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Create and populate a dynamic message
let person = DynamicMessage(descriptor: messageDescriptor)
try person.set(fieldName: "name", value: "John Doe")
try person.set(fieldName: "age", value: 30)

// Serialize to binary format
let binaryData = try person.serializedData()

// Deserialize from binary format
let deserializedPerson = try DynamicMessage(descriptor: messageDescriptor, serializedData: binaryData)
if let name = deserializedPerson.get(fieldName: "name") as? String {
    print("Deserialized name: \(name)")
}
```

### JSON Format

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Create and populate a dynamic message
let person = DynamicMessage(descriptor: messageDescriptor)
try person.set(fieldName: "name", value: "John Doe")
try person.set(fieldName: "age", value: 30)

// Serialize to JSON format
let jsonData = try person.jsonUTF8Data()

// Deserialize from JSON format
let deserializedPerson = try DynamicMessage(descriptor: messageDescriptor, jsonUTF8Data: jsonData)
if let name = deserializedPerson.get(fieldName: "name") as? String {
    print("Deserialized name: \(name)")
}

// Get JSON string
if let jsonString = String(data: jsonData, encoding: .utf8) {
    print("JSON: \(jsonString)")
}
```

### Text Format

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Create and populate a dynamic message
let person = DynamicMessage(descriptor: messageDescriptor)
try person.set(fieldName: "name", value: "John Doe")
try person.set(fieldName: "age", value: 30)

// Get text format string
let textFormat = try person.textFormatString()
print("Text format: \(textFormat)")

// Parse from text format
let deserializedPerson = try DynamicMessage(descriptor: messageDescriptor, textFormatString: textFormat)
if let name = deserializedPerson.get(fieldName: "name") as? String {
    print("Deserialized name: \(name)")
}
```

## Working with Descriptors

### Loading Descriptors from File Descriptor Sets

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Load a file descriptor set from a file
let url = URL(fileURLWithPath: "path/to/descriptor_set.bin")
let data = try Data(contentsOf: url)
let fileDescriptorSet = try Google_Protobuf_FileDescriptorSet(serializedData: data)

// Register the file descriptors
let registry = DescriptorRegistry()
for fileDescriptor in fileDescriptorSet.file {
    try registry.add(fileDescriptor: fileDescriptor)
}

// Now you can get descriptors by name
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")
```

### Exploring Message Structure

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Print message information
print("Message name: \(messageDescriptor.name)")
print("Full name: \(messageDescriptor.fullName)")

// Explore fields
for field in messageDescriptor.fields {
    print("Field \(field.number): \(field.name) (\(field.type))")
    
    if field.isRepeated {
        print("  Repeated field")
    }
    
    if field.isMap {
        print("  Map field")
    }
    
    if let messageType = field.messageType {
        print("  Message type: \(messageType.name)")
    }
    
    if let enumType = field.enumType {
        print("  Enum type: \(enumType.name)")
        for value in enumType.values {
            print("    Value \(value.number): \(value.name)")
        }
    }
}

// Explore nested types
for nestedType in messageDescriptor.nestedTypes {
    print("Nested type: \(nestedType.name)")
}

// Explore enum types
for enumType in messageDescriptor.enumTypes {
    print("Enum type: \(enumType.name)")
}
```

### Loading Multiple File Descriptors

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Create a registry
let registry = DescriptorRegistry()

// Method 1: Load multiple file descriptors individually
let personFileDescriptor = Google_Protobuf_FileDescriptorProto.with {
    $0.name = "person.proto"
    $0.package = "example"
    // ... set up the descriptor ...
}

let addressFileDescriptor = Google_Protobuf_FileDescriptorProto.with {
    $0.name = "address.proto"
    $0.package = "example"
    // ... set up the descriptor ...
}

// Add each file descriptor to the registry
try registry.add(fileDescriptor: personFileDescriptor)
try registry.add(fileDescriptor: addressFileDescriptor)

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

// Now you can get descriptors for types defined in any of the loaded files
let personDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")
let addressDescriptor = try registry.messageDescriptor(forTypeName: "example.Address")
```

### Working with Services and RPC

```swift
import SwiftProtobuf
import SwiftProtoReflect
import GRPC

// Get a service descriptor from the registry
let registry = DescriptorRegistry.shared
let serviceDescriptor = try registry.serviceDescriptor(forTypeName: "example.GreeterService")

// Explore service information
print("Service name: \(serviceDescriptor.name)")
print("Full name: \(serviceDescriptor.fullName)")

// Explore methods
for method in serviceDescriptor.methods {
    print("Method: \(method.name)")
    print("  Input type: \(method.inputType)")
    print("  Output type: \(method.outputType)")
    print("  Client streaming: \(method.isClientStreaming)")
    print("  Server streaming: \(method.isServerStreaming)")
}

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

### Client Streaming RPC Example

```swift
import SwiftProtobuf
import SwiftProtoReflect
import GRPC

// Create a dynamic client streaming RPC call
func clientStreamingCall(
    service: String,
    method: String,
    requests: [DynamicMessage],
    registry: DescriptorRegistry,
    channel: GRPCChannel
) async throws -> DynamicMessage {
    // Get service and method descriptors
    let serviceDescriptor = try registry.serviceDescriptor(forTypeName: service)
    guard let methodDescriptor = serviceDescriptor.methodByName(method) else {
        throw ServiceError.methodNotFound(method)
    }
    
    // Verify this is a client streaming method
    guard methodDescriptor.isClientStreaming else {
        throw ServiceError.notClientStreaming(method)
    }
    
    // Get output message descriptor
    let outputDescriptor = try registry.messageDescriptor(forTypeName: methodDescriptor.outputType)
    
    // Create a client streaming call
    let call = channel.makeClientStreamingCall(
        path: "/\(serviceDescriptor.fullName)/\(methodDescriptor.name)"
    )
    
    // Send all requests
    for request in requests {
        let requestData = try request.serializedData()
        try await call.sendMessage(requestData)
    }
    
    // Close the stream and wait for response
    try await call.sendEnd()
    let responseData = try await call.responsePromise.get()
    
    // Deserialize response
    return try DynamicMessage(descriptor: outputDescriptor, serializedData: responseData)
}

// Usage example
let registry = DescriptorRegistry.shared
let channel = GRPCChannel(host: "example.com", port: 443)

// Create request messages
let requestDescriptor = try registry.messageDescriptor(forTypeName: "example.NumberRequest")
var requests: [DynamicMessage] = []

for i in 1...5 {
    let request = DynamicMessage(descriptor: requestDescriptor)
    try request.set(fieldName: "number", value: Int32(i))
    requests.append(request)
}

// Make client streaming RPC call
let response = try await clientStreamingCall(
    service: "example.CalculatorService",
    method: "Sum",
    requests: requests,
    registry: registry,
    channel: channel
)

// Access response
if let sum = response.get(fieldName: "sum") as? Int32 {
    print("Sum: \(sum)")
}
```

### Server Streaming RPC Example

```swift
import SwiftProtobuf
import SwiftProtoReflect
import GRPC

// Create a dynamic server streaming RPC call
func serverStreamingCall(
    service: String,
    method: String,
    request: DynamicMessage,
    registry: DescriptorRegistry,
    channel: GRPCChannel
) async throws -> AsyncThrowingStream<DynamicMessage, Error> {
    // Get service and method descriptors
    let serviceDescriptor = try registry.serviceDescriptor(forTypeName: service)
    guard let methodDescriptor = serviceDescriptor.methodByName(method) else {
        throw ServiceError.methodNotFound(method)
    }
    
    // Verify this is a server streaming method
    guard methodDescriptor.isServerStreaming else {
        throw ServiceError.notServerStreaming(method)
    }
    
    // Get output message descriptor
    let outputDescriptor = try registry.messageDescriptor(forTypeName: methodDescriptor.outputType)
    
    // Serialize request
    let requestData = try request.serializedData()
    
    // Create a server streaming call
    let call = channel.makeServerStreamingCall(
        path: "/\(serviceDescriptor.fullName)/\(methodDescriptor.name)",
        request: requestData
    )
    
    // Return an async stream of dynamic messages
    return AsyncThrowingStream { continuation in
        Task {
            do {
                for try await responseData in call.responseStream {
                    let dynamicMessage = try DynamicMessage(
                        descriptor: outputDescriptor,
                        serializedData: responseData
                    )
                    continuation.yield(dynamicMessage)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

// Usage example
let registry = DescriptorRegistry.shared
let channel = GRPCChannel(host: "example.com", port: 443)

// Create request message
let requestDescriptor = try registry.messageDescriptor(forTypeName: "example.RangeRequest")
let request = DynamicMessage(descriptor: requestDescriptor)
try request.set(fieldName: "start", value: Int32(1))
try request.set(fieldName: "end", value: Int32(10))

// Make server streaming RPC call
let responseStream = try await serverStreamingCall(
    service: "example.NumberService",
    method: "GetRange",
    request: request,
    registry: registry,
    channel: channel
)

// Process response stream
for try await response in responseStream {
    if let number = response.get(fieldName: "number") as? Int32 {
        print("Received number: \(number)")
    }
}
```

## Integration with Generated Code

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

## Advanced Usage

### Dynamic Enum Handling

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get descriptors from the registry
let registry = DescriptorRegistry.shared
let personDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")
let genderEnumDescriptor = try registry.enumDescriptor(forTypeName: "example.Gender")

// Create a dynamic message
let person = DynamicMessage(descriptor: personDescriptor)
try person.set(fieldName: "name", value: "John Doe")

// Set enum value by number
try person.set(fieldName: "gender", value: 1) // MALE = 1

// Get enum value
if let genderValue = person.get(fieldName: "gender") as? Int32,
   let genderName = genderEnumDescriptor.valueByNumber(Int(genderValue))?.name {
    print("Gender: \(genderName)")
}

// Set enum value by name
if let maleValue = genderEnumDescriptor.valueByName("MALE")?.number {
    try person.set(fieldName: "gender", value: maleValue)
}
```

### Working with Extensions

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get descriptors from the registry
let registry = DescriptorRegistry.shared
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Message")

// Create a dynamic message
let message = DynamicMessage(descriptor: messageDescriptor)
try message.set(fieldName: "name", value: "Test Message")

// Set extension field
try message.setExtension(extensionName: "example.custom_string", value: "Extension value")

// Get extension field
if let extensionValue = try message.getExtension(extensionName: "example.custom_string") as? String {
    print("Extension value: \(extensionValue)")
}
```

### Handling Unknown Fields

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Create a dynamic message
let person = DynamicMessage(descriptor: messageDescriptor)
try person.set(fieldName: "name", value: "John Doe")

// Serialize to binary format
let binaryData = try person.serializedData()

// Modify the descriptor (simulate schema evolution)
let newMessageDescriptor = try registry.messageDescriptor(forTypeName: "example.NewPerson")

// Deserialize with the new descriptor
let newPerson = try DynamicMessage(descriptor: newMessageDescriptor, serializedData: binaryData)

// Access unknown fields
let unknownFields = newPerson.unknownFields
for (fieldNumber, _) in unknownFields {
    print("Unknown field number: \(fieldNumber)")
}
```

## Performance Optimization

### Caching Descriptors

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Create a descriptor cache
class DescriptorCache {
    private var messageDescriptors: [String: MessageDescriptor] = [:]
    private let registry = DescriptorRegistry()
    
    func messageDescriptor(forTypeName typeName: String) throws -> MessageDescriptor {
        if let descriptor = messageDescriptors[typeName] {
            return descriptor
        }
        
        let descriptor = try registry.messageDescriptor(forTypeName: typeName)
        messageDescriptors[typeName] = descriptor
        return descriptor
    }
    
    func registerFileDescriptor(_ fileDescriptor: Google_Protobuf_FileDescriptorProto) throws {
        try registry.add(fileDescriptor: fileDescriptor)
    }
}

// Use the cache
let cache = DescriptorCache()
let descriptor = try cache.messageDescriptor(forTypeName: "example.Person")
```

### Batch Processing

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Process a batch of messages
func processBatch(data: [Data]) throws -> [DynamicMessage] {
    var results: [DynamicMessage] = []
    
    for messageData in data {
        let message = try DynamicMessage(descriptor: messageDescriptor, serializedData: messageData)
        // Process the message...
        results.append(message)
    }
    
    return results
}
```

## Best Practices

### Error Handling

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared

do {
    let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")
    let person = DynamicMessage(descriptor: messageDescriptor)
    
    // Set field values with proper error handling
    do {
        try person.set(fieldName: "name", value: "John Doe")
        try person.set(fieldName: "age", value: 30)
    } catch let error as FieldError {
        switch error {
        case .fieldNotFound(let name):
            print("Field not found: \(name)")
        case .invalidType(let name, let value, let expectedType):
            print("Invalid type for field \(name): got \(type(of: value)), expected \(expectedType)")
        default:
            print("Field error: \(error)")
        }
    }
    
    // Serialize with proper error handling
    do {
        let data = try person.serializedData()
        // Use the data...
    } catch {
        print("Serialization error: \(error)")
    }
} catch {
    print("Descriptor error: \(error)")
}
```

### Type Safety

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Get a descriptor from the registry
let registry = DescriptorRegistry.shared
let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")

// Create a dynamic message
let person = DynamicMessage(descriptor: messageDescriptor)

// Get field descriptor to check type
if let nameField = messageDescriptor.fieldByName("name") {
    if nameField.type == .string {
        try person.set(field: nameField, value: "John Doe")
    }
}

// Validate value before setting
if let ageField = messageDescriptor.fieldByName("age"),
   ageField.isValidValue(30) {
    try person.set(field: ageField, value: 30)
}
```

### Memory Management

```swift
import SwiftProtobuf
import SwiftProtoReflect

// Process large batches of messages efficiently
func processLargeDataSet(dataChunks: [Data], typeName: String) throws {
    let registry = DescriptorRegistry.shared
    let messageDescriptor = try registry.messageDescriptor(forTypeName: typeName)
    
    // Process in chunks to manage memory
    for (index, chunk) in dataChunks.enumerated() {
        autoreleasepool {
            do {
                let message = try DynamicMessage(descriptor: messageDescriptor, serializedData: chunk)
                // Process the message...
                print("Processed chunk \(index)")
            } catch {
                print("Error processing chunk \(index): \(error)")
            }
        }
    }
}
```

## Thread Safety

```swift
import SwiftProtobuf
import SwiftProtoReflect
import Dispatch

// Thread-safe descriptor registry
class ThreadSafeDescriptorRegistry {
    private let registry = DescriptorRegistry()
    private let queue = DispatchQueue(label: "com.example.descriptorRegistry", attributes: .concurrent)
    
    func add(fileDescriptor: Google_Protobuf_FileDescriptorProto) throws {
        try queue.sync(flags: .barrier) {
            try registry.add(fileDescriptor: fileDescriptor)
        }
    }
    
    func messageDescriptor(forTypeName typeName: String) throws -> MessageDescriptor {
        return try queue.sync {
            try registry.messageDescriptor(forTypeName: typeName)
        }
    }
}

// Use the thread-safe registry
let safeRegistry = ThreadSafeDescriptorRegistry()
DispatchQueue.concurrentPerform(iterations: 10) { index in
    do {
        let descriptor = try safeRegistry.messageDescriptor(forTypeName: "example.Person")
        let message = DynamicMessage(descriptor: descriptor)
        // Use the message...
    } catch {
        print("Error in thread \(index): \(error)")
    }
}
```

## Conclusion

These examples demonstrate the core functionality of SwiftProtoReflect for dynamic Protocol Buffer handling. By building on Apple's SwiftProtobuf library, SwiftProtoReflect provides a powerful yet familiar API for working with Protocol Buffers dynamically.

For more detailed information, refer to the [API Documentation](SwiftProtoReflect_API_Documentation.md) and the [Technical Roadmap](SwiftProtoReflect_Technical_Roadmap.md). 