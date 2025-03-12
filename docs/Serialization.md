# Protocol Buffer Serialization in SwiftProtoReflect

This document provides an overview of the serialization and deserialization capabilities in SwiftProtoReflect, with examples of how to use these features in your code.

## Overview

SwiftProtoReflect provides a robust implementation of Protocol Buffer serialization and deserialization for dynamic messages. The library supports all primitive field types defined in the Protocol Buffer specification and handles complex scenarios like nested messages, repeated fields, and maps.

The serialization functionality is implemented in the `ProtoWireFormat` struct, which provides methods for converting between `ProtoMessage` instances and binary wire format data.

## Basic Serialization

### Serializing a Message

To serialize a dynamic message to binary format:

```swift
// Create a message descriptor
let personDescriptor = ProtoMessageDescriptor(
    fullName: "Person",
    fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "email", number: 3, type: .string, isRepeated: false, isMap: false)
    ],
    enums: [],
    nestedMessages: []
)

// Create a dynamic message
let person = ProtoDynamicMessage(descriptor: personDescriptor)
person.set(fieldName: "name", value: .stringValue("John Doe"))
person.set(fieldName: "age", value: .intValue(30))
person.set(fieldName: "email", value: .stringValue("john.doe@example.com"))

// Serialize the message to binary format
if let data = ProtoWireFormat.marshal(message: person) {
    // Use the serialized data
    print("Serialized data size: \(data.count) bytes")
} else {
    print("Serialization failed")
}
```

### Deserializing a Message

To deserialize binary data back to a dynamic message:

```swift
// Assuming we have binary data and a message descriptor
let binaryData: Data = ... // Binary data from somewhere
let personDescriptor: ProtoMessageDescriptor = ... // Message descriptor

// Deserialize the binary data
if let person = ProtoWireFormat.unmarshal(data: binaryData, messageDescriptor: personDescriptor) as? ProtoDynamicMessage {
    // Access the deserialized fields
    if let name = person.get(fieldName: "name")?.getString() {
        print("Name: \(name)")
    }
    
    if let age = person.get(fieldName: "age")?.getInt() {
        print("Age: \(age)")
    }
    
    if let email = person.get(fieldName: "email")?.getString() {
        print("Email: \(email)")
    }
} else {
    print("Deserialization failed")
}
```

## Supported Field Types

SwiftProtoReflect supports all primitive field types defined in the Protocol Buffer specification:

- **Integer Types**: int32, int64, uint32, uint64, sint32, sint64, fixed32, fixed64, sfixed32, sfixed64
- **Floating-Point Types**: float, double
- **Boolean Type**: bool
- **String Type**: string
- **Bytes Type**: bytes
- **Enum Type**: enum
- **Message Type**: message (for nested messages)

### Example with Different Field Types

```swift
// Create a message descriptor with various field types
let messageDescriptor = ProtoMessageDescriptor(
    fullName: "AllTypes",
    fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "int64_field", number: 2, type: .int64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "uint32_field", number: 3, type: .uint32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "uint64_field", number: 4, type: .uint64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sint32_field", number: 5, type: .sint32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sint64_field", number: 6, type: .sint64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "fixed32_field", number: 7, type: .fixed32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "fixed64_field", number: 8, type: .fixed64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sfixed32_field", number: 9, type: .sfixed32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sfixed64_field", number: 10, type: .sfixed64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "float_field", number: 11, type: .float, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "double_field", number: 12, type: .double, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 13, type: .bool, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 14, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bytes_field", number: 15, type: .bytes, isRepeated: false, isMap: false)
    ],
    enums: [],
    nestedMessages: []
)

// Create a message with values for each field type
let message = ProtoDynamicMessage(descriptor: messageDescriptor)
message.set(fieldName: "int32_field", value: .intValue(42))
message.set(fieldName: "int64_field", value: .intValue(9223372036854775807)) // Max Int64
message.set(fieldName: "uint32_field", value: .uintValue(4294967295)) // Max UInt32
message.set(fieldName: "uint64_field", value: .uintValue(18446744073709551615)) // Max UInt64
message.set(fieldName: "sint32_field", value: .intValue(-42))
message.set(fieldName: "sint64_field", value: .intValue(-9223372036854775808)) // Min Int64
message.set(fieldName: "fixed32_field", value: .uintValue(42))
message.set(fieldName: "fixed64_field", value: .uintValue(42))
message.set(fieldName: "sfixed32_field", value: .intValue(-42))
message.set(fieldName: "sfixed64_field", value: .intValue(-42))
message.set(fieldName: "float_field", value: .floatValue(3.14159))
message.set(fieldName: "double_field", value: .doubleValue(2.71828))
message.set(fieldName: "bool_field", value: .boolValue(true))
message.set(fieldName: "string_field", value: .stringValue("Hello, Protocol Buffers!"))
message.set(fieldName: "bytes_field", value: .bytesValue(Data([0x00, 0x01, 0x02, 0x03, 0xFF])))

// Serialize the message
if let data = ProtoWireFormat.marshal(message: message) {
    print("Serialized data size: \(data.count) bytes")
    
    // Deserialize the message
    if let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage {
        // Access the deserialized fields
        print("int32_field: \(deserializedMessage.get(fieldName: "int32_field")?.getInt() ?? 0)")
        print("string_field: \(deserializedMessage.get(fieldName: "string_field")?.getString() ?? "")")
        print("bool_field: \(deserializedMessage.get(fieldName: "bool_field")?.getBool() ?? false)")
    }
}
```

## Complex Field Types

### Repeated Fields

Repeated fields are serialized as multiple occurrences of the same field number in the binary format:

```swift
// Create a message descriptor with a repeated field
let messageDescriptor = ProtoMessageDescriptor(
    fullName: "RepeatedExample",
    fields: [
        ProtoFieldDescriptor(name: "repeated_string", number: 1, type: .string, isRepeated: true, isMap: false)
    ],
    enums: [],
    nestedMessages: []
)

// Create a message with a repeated field
let message = ProtoDynamicMessage(descriptor: messageDescriptor)
message.set(
    fieldName: "repeated_string",
    value: .repeatedValue([
        .stringValue("First"),
        .stringValue("Second"),
        .stringValue("Third")
    ])
)

// Serialize the message
if let data = ProtoWireFormat.marshal(message: message) {
    // Deserialize the message
    if let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage {
        // Access the repeated field
        if let repeatedValues = deserializedMessage.get(fieldName: "repeated_string")?.getRepeated() {
            for (index, value) in repeatedValues.enumerated() {
                if let stringValue = value.getString() {
                    print("Value \(index): \(stringValue)")
                }
            }
        }
    }
}
```

### Nested Messages

Nested messages are serialized as length-delimited fields:

```swift
// Create a nested message descriptor
let addressDescriptor = ProtoMessageDescriptor(
    fullName: "Address",
    fields: [
        ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "zip", number: 3, type: .string, isRepeated: false, isMap: false)
    ],
    enums: [],
    nestedMessages: []
)

// Create a message descriptor with a nested message field
let personDescriptor = ProtoMessageDescriptor(
    fullName: "Person",
    fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "address", number: 2, type: .message, isRepeated: false, isMap: false, messageType: addressDescriptor)
    ],
    enums: [],
    nestedMessages: [addressDescriptor]
)

// Create the nested address message
let address = ProtoDynamicMessage(descriptor: addressDescriptor)
address.set(fieldName: "street", value: .stringValue("123 Main St"))
address.set(fieldName: "city", value: .stringValue("Anytown"))
address.set(fieldName: "zip", value: .stringValue("12345"))

// Create the person message with the nested address
let person = ProtoDynamicMessage(descriptor: personDescriptor)
person.set(fieldName: "name", value: .stringValue("John Doe"))
person.set(fieldName: "address", value: .messageValue(address))

// Serialize the message
if let data = ProtoWireFormat.marshal(message: person) {
    // Deserialize the message
    if let deserializedPerson = ProtoWireFormat.unmarshal(data: data, messageDescriptor: personDescriptor) as? ProtoDynamicMessage {
        // Access the top-level field
        print("Name: \(deserializedPerson.get(fieldName: "name")?.getString() ?? "")")
        
        // Access the nested message field
        if let addressValue = deserializedPerson.get(fieldName: "address"),
           let addressMessage = addressValue.getMessage() as? ProtoDynamicMessage {
            print("Street: \(addressMessage.get(fieldName: "street")?.getString() ?? "")")
            print("City: \(addressMessage.get(fieldName: "city")?.getString() ?? "")")
            print("ZIP: \(addressMessage.get(fieldName: "zip")?.getString() ?? "")")
        }
    }
}
```

### Map Fields

Map fields are serialized as repeated message fields with key-value pairs:

```swift
// Create field descriptors for the map entry
let keyFieldDescriptor = ProtoFieldDescriptor(
    name: "key",
    number: 1,
    type: .string,
    isRepeated: false,
    isMap: false
)

let valueFieldDescriptor = ProtoFieldDescriptor(
    name: "value",
    number: 2,
    type: .int32,
    isRepeated: false,
    isMap: false
)

// Create a message descriptor for the map entry
let entryDescriptor = ProtoMessageDescriptor(
    fullName: "MapExample.StringToIntMapEntry",
    fields: [keyFieldDescriptor, valueFieldDescriptor],
    enums: [],
    nestedMessages: []
)

// Create a field descriptor for a map field
let mapFieldDescriptor = ProtoFieldDescriptor(
    name: "string_to_int_map",
    number: 1,
    type: .message,
    isRepeated: true,
    isMap: true,
    messageType: entryDescriptor
)

// Create a message descriptor with the map field
let messageDescriptor = ProtoMessageDescriptor(
    fullName: "MapExample",
    fields: [mapFieldDescriptor],
    enums: [],
    nestedMessages: [entryDescriptor]
)

// Create a dynamic message with the map field
let message = ProtoDynamicMessage(descriptor: messageDescriptor)

// Create a map with entries
var mapEntries: [String: ProtoValue] = [:]
mapEntries["one"] = .intValue(1)
mapEntries["two"] = .intValue(2)
mapEntries["three"] = .intValue(3)

// Set the map field
message.set(field: mapFieldDescriptor, value: .mapValue(mapEntries))

// Serialize the message
if let data = ProtoWireFormat.marshal(message: message) {
    // Deserialize the message
    if let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage {
        // Access the map field
        if let mapValue = deserializedMessage.get(field: mapFieldDescriptor),
           case .mapValue(let entries) = mapValue {
            for (key, value) in entries {
                print("\(key): \(value.getInt() ?? 0)")
            }
        }
    }
}
```

## Error Handling

The serialization and deserialization methods include error handling to ensure data integrity:

- `marshal` returns `nil` if serialization fails due to invalid field values or other errors.
- `unmarshal` returns `nil` if deserialization fails due to corrupted data or other errors.

For more detailed error handling, you can use the `validateFieldValue` method to validate field values before serialization:

```swift
do {
    try ProtoWireFormat.validateFieldValue(field: fieldDescriptor, value: fieldValue)
    // Field value is valid
} catch let error as ProtoWireFormatError {
    switch error {
    case .typeMismatch:
        print("Type mismatch: The field value type doesn't match the field type")
    case .unsupportedType:
        print("Unsupported type: The field type is not supported")
    case .validationError(let fieldName, let reason):
        print("Validation error for field '\(fieldName)': \(reason)")
    default:
        print("Other error: \(error)")
    }
}
```

## Performance Considerations

The serialization and deserialization implementation in SwiftProtoReflect is designed to be efficient, but there are some performance considerations to keep in mind:

- **Message Size**: Serializing and deserializing large messages can be memory-intensive. Consider breaking large messages into smaller chunks if possible.
- **Repeated Fields**: Repeated fields with many elements can impact performance. Consider using pagination or streaming for large collections.
- **Nested Messages**: Deeply nested messages can increase serialization and deserialization time. Try to keep message structures reasonably flat.
- **Field Types**: Some field types (like strings and bytes) require more processing than others (like integers and booleans). Choose field types appropriately for your data.

## SwiftProtobuf Integration

SwiftProtoReflect is designed to be compatible with Apple's SwiftProtobuf library. The wire format implementation follows the Protocol Buffer specification, ensuring interoperability with other Protocol Buffer implementations.

If you have a SwiftProtobuf message type available, you can convert between SwiftProtobuf messages and dynamic messages:

```swift
// Convert from SwiftProtobuf message to dynamic message
func convertToSwiftProtoReflect<T: SwiftProtobuf.Message>(swiftProtoMessage: T, descriptor: ProtoMessageDescriptor) -> ProtoDynamicMessage {
    // Serialize the SwiftProtobuf message
    let data = try! swiftProtoMessage.serializedData()
    
    // Deserialize to a dynamic message
    return ProtoWireFormat.unmarshal(data: data, messageDescriptor: descriptor) as! ProtoDynamicMessage
}

// Convert from dynamic message to SwiftProtobuf message
func convertToSwiftProtobuf<T: SwiftProtobuf.Message>(dynamicMessage: ProtoDynamicMessage) -> T? {
    // Serialize the dynamic message
    guard let data = ProtoWireFormat.marshal(message: dynamicMessage) else {
        return nil
    }
    
    // Deserialize to a SwiftProtobuf message
    return try? T(serializedData: data)
}
```

## Conclusion

The serialization and deserialization capabilities in SwiftProtoReflect provide a flexible and powerful way to work with Protocol Buffer messages dynamically. By supporting all primitive field types and complex structures like nested messages, repeated fields, and maps, the library enables a wide range of use cases for dynamic Protocol Buffer handling in Swift applications. 