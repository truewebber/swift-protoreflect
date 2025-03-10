# SwiftProtoReflect API Documentation

## Overview

SwiftProtoReflect is a Swift library for dynamic Protocol Buffer handling, enabling developers to work with protobuf messages without pre-compiled schemas. It builds directly on Apple's SwiftProtobuf library, extending it with dynamic capabilities while maintaining full compatibility with its static, generated code approach.

This document provides comprehensive documentation for the SwiftProtoReflect API, focusing on the core components and their usage.

## Table of Contents

1. [Core Components](#core-components)
2. [Value Representation](#value-representation)
3. [Dynamic Message Handling](#dynamic-message-handling)
4. [Field Access](#field-access)
5. [Facade API](#facade-api)
6. [Best Practices](#best-practices)

## Core Components

SwiftProtoReflect consists of several core components that work together to provide dynamic Protocol Buffer handling:

- **ProtoValue**: Represents any valid Protocol Buffer field value, including primitive types, strings, bytes, nested messages, repeated fields, and maps.
- **ProtoDynamicMessage**: A dynamic implementation of a Protocol Buffer message that can be created and manipulated at runtime.
- **ProtoFieldDescriptor**: Describes a field in a Protocol Buffer message, including its name, number, type, and other metadata.
- **ProtoMessageDescriptor**: Describes a Protocol Buffer message type, including its fields, nested types, and other metadata.
- **ProtoEnumDescriptor**: Describes a Protocol Buffer enum type, including its values and metadata.
- **ProtoFieldPath**: A utility for accessing fields in dynamic messages using path notation.
- **DescriptorRegistry**: A registry for Protocol Buffer descriptors, allowing lookup by name or number.

## Value Representation

### ProtoValue

`ProtoValue` is an enum that can represent any valid Protocol Buffer field value. It provides type-safe access to values and supports conversion between different types.

#### Creating Values

```swift
// Create primitive values
let intValue = ProtoValue.intValue(42)
let uintValue = ProtoValue.uintValue(42)
let floatValue = ProtoValue.floatValue(3.14)
let doubleValue = ProtoValue.doubleValue(3.14)
let boolValue = ProtoValue.boolValue(true)
let stringValue = ProtoValue.stringValue("Hello, world!")
let bytesValue = ProtoValue.bytesValue(Data([0, 1, 2]))

// Create enum values
let enumValue = ProtoValue.enumValue(name: "VALUE", number: 1, enumDescriptor: enumDescriptor)

// Create message values
let messageValue = ProtoValue.messageValue(dynamicMessage)

// Create repeated values
let repeatedValue = ProtoValue.repeatedValue([intValue, intValue, intValue])

// Create map values
let mapValue = ProtoValue.mapValue(["key1": stringValue, "key2": stringValue])
```

#### Accessing Values

```swift
// Access primitive values
if let value = intValue.getInt() {
    print("Int value: \(value)")
}

if let value = stringValue.getString() {
    print("String value: \(value)")
}

// Access enum values
if let (name, number, descriptor) = enumValue.getEnum() {
    print("Enum value: \(name) (\(number))")
}

// Access message values
if let message = messageValue.getMessage() {
    print("Message type: \(message.descriptor().fullName)")
}

// Access repeated values
if let values = repeatedValue.getRepeated() {
    print("Repeated values: \(values.count)")
}

// Access map values
if let entries = mapValue.getMap() {
    print("Map entries: \(entries.count)")
}
```

#### Type Conversion

`ProtoValue` provides methods for converting between different types:

```swift
// Convert to Int32
if let value = stringValue.asInt32() {
    print("Converted to Int32: \(value)")
}

// Convert to String
let stringRepresentation = intValue.asString()
print("String representation: \(stringRepresentation)")

// Convert to a specific type
if let convertedValue = intValue.convertTo(targetType: .string) {
    print("Converted to string: \(convertedValue.getString()!)")
}
```

#### Validation

`ProtoValue` provides methods for validating values against field descriptors:

```swift
// Check if a value is valid for a field
let isValid = intValue.isValid(for: fieldDescriptor)

// Check if a value is valid as a map key
let isValidKey = stringValue.isValidMapKey(for: keyFieldType)
```

## Dynamic Message Handling

### ProtoDynamicMessage

`ProtoDynamicMessage` is a dynamic implementation of a Protocol Buffer message that can be created and manipulated at runtime without generated code.

#### Creating Messages

```swift
// Create a dynamic message from a descriptor
let message = ProtoDynamicMessage(descriptor: personDescriptor)

// Create a dynamic message with initial values
let initialValues: [Int: ProtoValue] = [
    1: .stringValue("John Doe"),
    2: .intValue(30)
]
let message = ProtoDynamicMessage(descriptor: personDescriptor, initialValues: initialValues)
```

#### Setting Field Values

```swift
// Set a field by descriptor
message.set(field: nameField, value: .stringValue("John Doe"))

// Set a field by name
message.set(fieldName: "name", value: .stringValue("John Doe"))

// Set a field by number
message.set(fieldNumber: 1, value: .stringValue("John Doe"))
```

#### Getting Field Values

```swift
// Get a field by descriptor
if let name = message.get(field: nameField)?.getString() {
    print("Name: \(name)")
}

// Get a field by name
if let name = message.get(fieldName: "name")?.getString() {
    print("Name: \(name)")
}

// Get a field by number
if let name = message.get(fieldNumber: 1)?.getString() {
    print("Name: \(name)")
}
```

#### Checking Field Presence

```swift
// Check if a field is set by descriptor
if message.has(field: nameField) {
    print("Name is set")
}

// Check if a field is set by name
if message.has(fieldName: "name") {
    print("Name is set")
}

// Check if a field is set by number
if message.has(fieldNumber: 1) {
    print("Name is set")
}
```

#### Clearing Fields

```swift
// Clear a field by descriptor
message.clear(field: nameField)

// Clear a field by name
message.clear(fieldName: "name")

// Clear a field by number
message.clear(fieldNumber: 1)

// Clear all fields
message.clearAll()
```

#### Working with Nested Messages

```swift
// Create a nested message
let address = message.createNestedMessage(for: addressField)
address.set(field: streetField, value: .stringValue("123 Main St"))
address.set(field: cityField, value: .stringValue("Anytown"))

// Set the nested message on the parent
message.setNestedMessage(field: addressField, message: address)

// Get a nested message
if let address = message.getNestedMessage(field: addressField) {
    let street = address.get(field: streetField)?.getString()
    let city = address.get(field: cityField)?.getString()
    print("Address: \(street!), \(city!)")
}
```

#### Working with Repeated Fields

```swift
// Set a repeated field
message.set(field: phonesField, value: .repeatedValue([
    .stringValue("555-1234"),
    .stringValue("555-5678")
]))

// Add to a repeated field
message.add(toRepeatedField: phonesField, value: .stringValue("555-9012"))

// Get a repeated field
if let phones = message.get(field: phonesField)?.getRepeated() {
    for phone in phones {
        print("Phone: \(phone.getString()!)")
    }
}

// Get an element from a repeated field
if let phone = message.get(fromRepeatedField: phonesField, at: 0)?.getString() {
    print("First phone: \(phone)")
}

// Count elements in a repeated field
let phoneCount = message.count(ofRepeatedField: phonesField)
```

#### Working with Map Fields

```swift
// Set a map field
message.set(field: attributesField, value: .mapValue([
    "height": .stringValue("6'0\""),
    "weight": .stringValue("180lbs")
]))

// Set a map entry
message.set(inMapField: attributesField, key: "hair_color", value: .stringValue("brown"))

// Get a map field
if let attributes = message.get(field: attributesField)?.getMap() {
    for (key, value) in attributes {
        print("\(key): \(value.getString()!)")
    }
}

// Get a map entry
if let height = message.get(fromMapField: attributesField, key: "height")?.getString() {
    print("Height: \(height)")
}

// Remove a map entry
message.remove(fromMapField: attributesField, key: "weight")

// Count entries in a map field
let attributeCount = message.count(ofMapField: attributesField)
```

#### Validation

```swift
// Check if a message is valid
if message.isValid() {
    print("Message is valid")
} else {
    print("Message is invalid")
}
```

## Field Access

### ProtoFieldPath

`ProtoFieldPath` is a utility for accessing fields in dynamic messages using path notation, including support for nested fields, repeated fields, and map fields.

#### Creating Field Paths

```swift
// Create a simple field path
let namePath = ProtoFieldPath(path: "name")

// Create a nested field path
let streetPath = ProtoFieldPath(path: "address.street")

// Create a repeated field path
let phonePath = ProtoFieldPath(path: "phones[0]")

// Create a map field path
let heightPath = ProtoFieldPath(path: "attributes['height']")

// Create a complex path
let workPhoneNumberPath = ProtoFieldPath(path: "contacts[0].phones['work'].number")
```

#### Getting Values

```swift
// Get a value using a path
if let name = namePath.getValue(from: message)?.getString() {
    print("Name: \(name)")
}

// Get a nested value
if let street = streetPath.getValue(from: message)?.getString() {
    print("Street: \(street)")
}

// Get a value from a repeated field
if let phone = phonePath.getValue(from: message)?.getString() {
    print("Phone: \(phone)")
}

// Get a value from a map field
if let height = heightPath.getValue(from: message)?.getString() {
    print("Height: \(height)")
}
```

#### Setting Values

```swift
// Set a value using a path
namePath.setValue(.stringValue("Jane Doe"), in: message)

// Set a nested value
streetPath.setValue(.stringValue("456 Oak Ave"), in: message)

// Set a value in a repeated field
phonePath.setValue(.stringValue("555-9012"), in: message)

// Set a value in a map field
heightPath.setValue(.stringValue("5'10\""), in: message)
```

#### Clearing Values

```swift
// Clear a value using a path
namePath.clearValue(in: message)

// Clear a nested value
streetPath.clearValue(in: message)

// Clear a value in a repeated field
phonePath.clearValue(in: message)

// Clear a value in a map field
heightPath.clearValue(in: message)
```

#### Checking Value Presence

```swift
// Check if a value exists
if namePath.hasValue(in: message) {
    print("Name is set")
}

// Check if a nested value exists
if streetPath.hasValue(in: message) {
    print("Street is set")
}

// Check if a value in a repeated field exists
if phonePath.hasValue(in: message) {
    print("Phone is set")
}

// Check if a value in a map field exists
if heightPath.hasValue(in: message) {
    print("Height is set")
}
```

## Facade API

The `ProtoReflect` class provides a high-level API for working with dynamic Protocol Buffer messages, making it easier to perform common operations.

### Creating Messages

```swift
// Create a dynamic message
let message = ProtoReflect.createMessage(withTypeName: "Person")

// Create a message builder
let builder = ProtoReflect.createMessageBuilder(withTypeName: "Person")
builder.set("name", value: "John Doe")
builder.set("age", value: 30)
let message = builder.build()
```

### Registering Descriptors

```swift
// Register a file descriptor
ProtoReflect.registerFileDescriptor(fileDescriptor)

// Register a message descriptor
ProtoReflect.registerMessageDescriptor(messageDescriptor)

// Register an enum descriptor
ProtoReflect.registerEnumDescriptor(enumDescriptor)
```

### Serialization and Deserialization

```swift
// Serialize a message to binary format
let data = try ProtoReflect.serialize(message)

// Deserialize a message from binary format
let message = try ProtoReflect.deserialize(data, asType: "Person")

// Serialize a message to JSON format
let jsonData = try ProtoReflect.serializeJSON(message)

// Deserialize a message from JSON format
let message = try ProtoReflect.deserializeJSON(jsonData, asType: "Person")
```

## Best Practices

### 1. Use Descriptors Efficiently

Descriptors are the foundation of dynamic Protocol Buffer handling. Create them once and reuse them to improve performance.

```swift
// Create descriptors once
let personDescriptor = ProtoMessageDescriptor(...)
let addressDescriptor = ProtoMessageDescriptor(...)

// Reuse descriptors for multiple messages
let person1 = ProtoDynamicMessage(descriptor: personDescriptor)
let person2 = ProtoDynamicMessage(descriptor: personDescriptor)
```

### 2. Validate Input

When setting field values dynamically, validate that the values match the expected types to avoid runtime errors.

```swift
// Validate values before setting them
if value.isValid(for: fieldDescriptor) {
    message.set(field: fieldDescriptor, value: value)
} else {
    print("Invalid value for field: \(fieldDescriptor.name)")
}
```

### 3. Use Field Paths for Complex Access

Field paths provide a convenient way to access nested fields, repeated fields, and map fields.

```swift
// Use field paths for complex access
let path = ProtoFieldPath(path: "person.address.street")
let street = path.getValue(from: message)?.getString()
```

### 4. Handle Errors Gracefully

Dynamic message handling can lead to runtime errors. Handle errors gracefully to provide a better user experience.

```swift
// Handle errors gracefully
do {
    let data = try ProtoReflect.serialize(message)
    // Use serialized data
} catch {
    print("Error serializing message: \(error)")
}
```

### 5. Consider Performance

Dynamic message handling is generally slower than using generated code. Consider performance implications for your application.

```swift
// Use caching for frequently accessed values
let cachedDescriptor = descriptorRegistry.messageDescriptor(forTypeName: "Person")
```

### 6. Combine Static and Dynamic Approaches

SwiftProtoReflect is designed to work alongside SwiftProtobuf's static, generated code approach. Use the approach that best fits your needs for each part of your application.

```swift
// Convert between static and dynamic messages
let dynamicMessage = ProtoReflect.createDynamicMessage(from: staticMessage)
let staticMessage = ProtoReflect.createStaticMessage(from: dynamicMessage, as: Person.self)
``` 