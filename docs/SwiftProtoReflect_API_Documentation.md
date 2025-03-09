# SwiftProtoReflect API Documentation

This document provides detailed API documentation for the SwiftProtoReflect library, focusing on the core descriptor types implemented in Sprint 1.

## Core Descriptor Types

### ProtoFieldDescriptor

`ProtoFieldDescriptor` represents a single field within a Protocol Buffer message. It contains all the metadata needed to correctly serialize, deserialize, and validate field values.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The name of the field as defined in the Protocol Buffer schema. |
| `number` | `Int` | The field number as defined in the Protocol Buffer schema. Field numbers uniquely identify fields within a message when serialized to the binary wire format. |
| `type` | `ProtoFieldType` | The data type of the field (e.g., int32, string, message). |
| `isRepeated` | `Bool` | Indicates whether the field is a repeated field (array). |
| `isMap` | `Bool` | Indicates whether the field is a map field. |
| `defaultValue` | `ProtoValue?` | The default value for the field, if any. |
| `messageType` | `ProtoMessageDescriptor?` | For message-type fields, the descriptor of the message type. |

#### Methods

| Method | Description |
|--------|-------------|
| `init(name:number:type:isRepeated:isMap:defaultValue:messageType:)` | Creates a new field descriptor with the specified properties. |
| `isValid()` | Checks if the field descriptor is valid according to Protocol Buffer rules. |

#### Example

```swift
let fieldDescriptor = ProtoFieldDescriptor(
    name: "user_id",
    number: 1,
    type: .int64,
    isRepeated: false,
    isMap: false
)

// For a message field
let addressDescriptor = ProtoMessageDescriptor(...)
let addressField = ProtoFieldDescriptor(
    name: "address",
    number: 2,
    type: .message,
    isRepeated: false,
    isMap: false,
    defaultValue: nil,
    messageType: addressDescriptor
)
```

### ProtoMessageDescriptor

`ProtoMessageDescriptor` represents a Protocol Buffer message type, containing information about its fields, nested enums, and nested messages.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `fullName` | `String` | The fully qualified name of the message type. |
| `fields` | `[ProtoFieldDescriptor]` | The fields defined in the message. |
| `enums` | `[ProtoEnumDescriptor]` | The enum types defined within this message. |
| `nestedMessages` | `[ProtoMessageDescriptor]` | The message types defined within this message. |

#### Methods

| Method | Description |
|--------|-------------|
| `init(fullName:fields:enums:nestedMessages:)` | Creates a new message descriptor with the specified properties. |
| `isValid()` | Checks if the message descriptor is valid according to Protocol Buffer rules. |
| `field(named:)` | Returns the field with the specified name, or nil if not found. |
| `field(at:)` | Returns the field at the specified index, or nil if the index is out of bounds. |

#### Example

```swift
let personDescriptor = ProtoMessageDescriptor(
    fullName: "Person",
    fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "emails", number: 3, type: .string, isRepeated: true, isMap: false)
    ],
    enums: [],
    nestedMessages: []
)

// Access fields
let nameField = personDescriptor.field(named: "name")
let ageField = personDescriptor.field(at: 1) // 0-based index
```

### ProtoEnumDescriptor

`ProtoEnumDescriptor` represents a Protocol Buffer enum type, containing information about its values.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The name of the enum type. |
| `values` | `[ProtoEnumValueDescriptor]` | The values defined in the enum. |

#### Methods

| Method | Description |
|--------|-------------|
| `init(name:values:)` | Creates a new enum descriptor with the specified properties. |
| `isValid()` | Checks if the enum descriptor is valid according to Protocol Buffer rules. |
| `value(named:)` | Returns the enum value with the specified name, or nil if not found. |
| `value(withNumber:)` | Returns the enum value with the specified number, or nil if not found. |

#### Example

```swift
let statusEnum = ProtoEnumDescriptor(
    name: "Status",
    values: [
        ProtoEnumValueDescriptor(name: "UNKNOWN", number: 0),
        ProtoEnumValueDescriptor(name: "ACTIVE", number: 1),
        ProtoEnumValueDescriptor(name: "INACTIVE", number: 2)
    ]
)

// Access values
let activeValue = statusEnum.value(named: "ACTIVE")
let unknownValue = statusEnum.value(withNumber: 0)
```

### ProtoEnumValueDescriptor

`ProtoEnumValueDescriptor` represents a single value within a Protocol Buffer enum.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The name of the enum value. |
| `number` | `Int` | The numeric value of the enum value. |

#### Methods

| Method | Description |
|--------|-------------|
| `init(name:number:)` | Creates a new enum value descriptor with the specified properties. |
| `isValid()` | Checks if the enum value descriptor is valid according to Protocol Buffer rules. |

#### Example

```swift
let activeValue = ProtoEnumValueDescriptor(name: "ACTIVE", number: 1)
```

## ProtoFieldType

`ProtoFieldType` is an enumeration of the possible field types in Protocol Buffers.

### Cases

| Case | Description |
|------|-------------|
| `double` | 64-bit floating point number. |
| `float` | 32-bit floating point number. |
| `int32` | 32-bit signed integer. |
| `int64` | 64-bit signed integer. |
| `uint32` | 32-bit unsigned integer. |
| `uint64` | 64-bit unsigned integer. |
| `sint32` | 32-bit signed integer with zigzag encoding. |
| `sint64` | 64-bit signed integer with zigzag encoding. |
| `fixed32` | 32-bit unsigned integer with fixed encoding. |
| `fixed64` | 64-bit unsigned integer with fixed encoding. |
| `sfixed32` | 32-bit signed integer with fixed encoding. |
| `sfixed64` | 64-bit signed integer with fixed encoding. |
| `bool` | Boolean value. |
| `string` | UTF-8 encoded string. |
| `bytes` | Arbitrary sequence of bytes. |
| `message` | Nested message. |
| `enum` | Enumeration value. |

### Example

```swift
let intField = ProtoFieldDescriptor(name: "count", number: 1, type: .int32, isRepeated: false, isMap: false)
let stringField = ProtoFieldDescriptor(name: "name", number: 2, type: .string, isRepeated: false, isMap: false)
let boolField = ProtoFieldDescriptor(name: "isActive", number: 3, type: .bool, isRepeated: false, isMap: false)
```

## ProtoValue

`ProtoValue` represents a value that can be stored in a Protocol Buffer field.

### Cases

| Case | Associated Value | Description |
|------|------------------|-------------|
| `doubleValue` | `Double` | A 64-bit floating point value. |
| `floatValue` | `Float` | A 32-bit floating point value. |
| `intValue` | `Int64` | A signed integer value. |
| `uintValue` | `UInt64` | An unsigned integer value. |
| `boolValue` | `Bool` | A boolean value. |
| `stringValue` | `String` | A string value. |
| `bytesValue` | `Data` | A binary data value. |
| `messageValue` | `ProtoMessage` | A nested message value. |
| `enumValue` | `Int` | An enum value (represented by its number). |
| `arrayValue` | `[ProtoValue]` | An array of values (for repeated fields). |
| `mapValue` | `[String: ProtoValue]` | A map of values (for map fields). |

### Methods

| Method | Description |
|--------|-------------|
| `getDouble()` | Returns the value as a Double, or nil if not a double value. |
| `getFloat()` | Returns the value as a Float, or nil if not a float value. |
| `getInt()` | Returns the value as an Int64, or nil if not an int value. |
| `getUInt()` | Returns the value as a UInt64, or nil if not a uint value. |
| `getBool()` | Returns the value as a Bool, or nil if not a bool value. |
| `getString()` | Returns the value as a String, or nil if not a string value. |
| `getBytes()` | Returns the value as Data, or nil if not a bytes value. |
| `getMessage()` | Returns the value as a ProtoMessage, or nil if not a message value. |
| `getEnum()` | Returns the value as an Int, or nil if not an enum value. |
| `getArray()` | Returns the value as an array of ProtoValue, or nil if not an array value. |
| `getMap()` | Returns the value as a map of String to ProtoValue, or nil if not a map value. |

### Example

```swift
// Create values
let intValue = ProtoValue.intValue(42)
let stringValue = ProtoValue.stringValue("Hello, world!")
let boolValue = ProtoValue.boolValue(true)

// Extract values
if let intVal = intValue.getInt() {
    print("Int value: \(intVal)")
}

if let stringVal = stringValue.getString() {
    print("String value: \(stringVal)")
}

if let boolVal = boolValue.getBool() {
    print("Bool value: \(boolVal)")
}
```

## Validation

All descriptor types implement validation logic to ensure they conform to Protocol Buffer rules:

### ProtoFieldDescriptor Validation

- Name must not be empty
- Field number must be positive
- For message-type fields, messageType must not be nil
- For enum-type fields, enumType must not be nil

### ProtoMessageDescriptor Validation

- Full name must not be empty
- No duplicate field numbers
- All fields must be valid
- All nested messages must be valid
- All enums must be valid

### ProtoEnumDescriptor Validation

- Name must not be empty
- No duplicate value numbers
- No duplicate value names
- All values must be valid

### ProtoEnumValueDescriptor Validation

- Name must not be empty 