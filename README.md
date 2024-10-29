# SwiftProtoReflect

**SwiftProtoReflect** is a Swift library for dynamically handling Protocol Buffer (protobuf) messages. With `SwiftProtoReflect`, you can:
- Define protobuf message structures dynamically without requiring `.proto` files.
- Serialize (marshal) and deserialize (unmarshal) protobuf messages to and from binary wire format.
- Access and manipulate message fields dynamically.

## Features
- **Dynamic Message Handling**: Create and manipulate protobuf messages without pre-compiling `.proto` files.
- **Serialization/Deserialization**: Supports protobuf wire format encoding and decoding.
- **Reflection Support**: Access message fields dynamically using descriptors.

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
  - [Defining Message Descriptors](#defining-message-descriptors)
  - [Creating and Manipulating Dynamic Messages](#creating-and-manipulating-dynamic-messages)
  - [Marshaling and Unmarshaling](#marshaling-and-unmarshaling)
- [Examples](#examples)
- [License](#license)

---

## Installation

### Swift Package Manager (SPM)
Add `SwiftProtoReflect` to your `Package.swift` file:

```swift
dependencies: [
	.package(url: "https://github.com/truewebber/swift-protoreflect.git", from: "1.0.0")
]
```

Or, if using Xcode, go to **File > Add Packages** and add the repository URL.

---

## Usage

### Defining Message Descriptors

To use the library, start by defining a `ProtoMessageDescriptor` for your protobuf message. This descriptor defines the message’s fields, names, types, and numbers.

```swift
import SwiftProtoReflect

let messageDescriptor = ProtoMessageDescriptor(
	fullName: "Person",
	fields: [
		ProtoFieldDescriptor(name: "id", number: 1, type: .int32, isRepeated: false, isMap: false),
		ProtoFieldDescriptor(name: "name", number: 2, type: .string, isRepeated: false, isMap: false),
		ProtoFieldDescriptor(name: "isActive", number: 3, type: .bool, isRepeated: false, isMap: false)
	],
	enums: [],
	nestedMessages: []
)
```

### Creating and Manipulating Dynamic Messages

Use `ProtoReflect.createMessage(from:)` to create a `ProtoDynamicMessage` based on your descriptor. You can set and retrieve field values dynamically.

```swift
// Create a dynamic message using ProtoReflect
var dynamicMessage = ProtoReflect.createMessage(from: messageDescriptor)

// Set values for fields
dynamicMessage.set(field: messageDescriptor.fields[0], value: .intValue(101))  // Set "id" field
dynamicMessage.set(field: messageDescriptor.fields[1], value: .stringValue("Alice"))  // Set "name" field
dynamicMessage.set(field: messageDescriptor.fields[2], value: .boolValue(true))  // Set "isActive" field
```

Retrieve values:

```swift
// Retrieve values dynamically
if let idValue = dynamicMessage.get(field: messageDescriptor.fields[0])?.getInt() {
	print("ID: \(idValue)")  // Output: ID: 101
}
if let nameValue = dynamicMessage.get(field: messageDescriptor.fields[1])?.getString() {
	print("Name: \(nameValue)")  // Output: Name: Alice
}
```

### Marshaling and Unmarshaling

You can serialize (`marshal`) the message to binary protobuf wire format and deserialize (`unmarshal`) it back into a `ProtoDynamicMessage`.

```swift
// Marshal the message to protobuf wire format using ProtoReflect
if let wireData = ProtoReflect.marshal(message: dynamicMessage) {
	print("Serialized Data: \(wireData)")
}

// Unmarshal the protobuf wire format back into a ProtoDynamicMessage
if let unmarshaledMessage = ProtoReflect.unmarshal(data: wireData!, descriptor: messageDescriptor) {
	if let idValue = unmarshaledMessage.get(field: messageDescriptor.fields[0])?.getInt() {
		print("Unmarshaled ID: \(idValue)")  // Output: Unmarshaled ID: 101
	}
	if let nameValue = unmarshaledMessage.get(field: messageDescriptor.fields[1])?.getString() {
		print("Unmarshaled Name: \(nameValue)")  // Output: Unmarshaled Name: Alice
	}
}
```

### Reflection Utilities

Use `ProtoReflect.describe(message:)` to print a description of the message structure.

```swift
// Describe the message structure
let messageDescription = ProtoReflect.describe(message: dynamicMessage)
print("Message Description:\n\(messageDescription)")
```

---

## Examples

### Example: Full Workflow with ProtoReflect

```swift
import SwiftProtoReflect

// 1. Define a message descriptor
let messageDescriptor = ProtoMessageDescriptor(
	fullName: "ExampleMessage",
	fields: [
		ProtoFieldDescriptor(name: "id", number: 1, type: .int32, isRepeated: false, isMap: false),
		ProtoFieldDescriptor(name: "name", number: 2, type: .string, isRepeated: false, isMap: false)
	],
	enums: [],
	nestedMessages: []
)

// 2. Create a dynamic message with ProtoReflect
var dynamicMessage = ProtoReflect.createMessage(from: messageDescriptor)
dynamicMessage.set(field: messageDescriptor.fields[0], value: .intValue(101))
dynamicMessage.set(field: messageDescriptor.fields[1], value: .stringValue("Alice"))

// 3. Serialize the message to protobuf wire format
if let wireData = ProtoReflect.marshal(message: dynamicMessage) {
	print("Serialized Data: \(wireData)")
	
	// 4. Deserialize the message back into a ProtoDynamicMessage
	if let unmarshaledMessage = ProtoReflect.unmarshal(data: wireData, descriptor: messageDescriptor) {
		let id = unmarshaledMessage.get(field: messageDescriptor.fields[0])?.getInt()
		let name = unmarshaledMessage.get(field: messageDescriptor.fields[1])?.getString()
		print("Unmarshaled ID: \(id ?? 0), Name: \(name ?? "")")
	}
}

// 5. Describe the message structure
let description = ProtoReflect.describe(message: dynamicMessage)
print("Message Structure:\n\(description)")
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
