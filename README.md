# SwiftProtoReflect

SwiftProtoReflect is a Swift library for dynamic Protocol Buffer handling, enabling developers to work with protobuf messages without pre-compiled schemas. It builds directly on Apple's SwiftProtobuf library, extending it with dynamic capabilities while maintaining full compatibility with its static, generated code approach.

## Features

- **Dynamic Message Handling**: Create, modify, and access Protocol Buffer messages at runtime without generated code.
- **Type-Safe Value Representation**: Work with Protocol Buffer values in a type-safe manner using the `ProtoValue` enum.
- **Field Path Access**: Access nested fields, repeated fields, and map fields using path notation.
- **Validation**: Validate values against field descriptors to ensure type safety.
- **Conversion**: Convert between different Protocol Buffer types when possible.
- **Serialization**: Serialize and deserialize dynamic messages to and from binary and JSON formats.
- **Compatibility**: Seamlessly convert between dynamic messages and generated Swift types.

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
dependencies: [
	.package(url: "https://github.com/yourusername/swift-protoreflect.git", from: "1.0.0")
]
```

## Usage

### Creating a Dynamic Message

```swift
import SwiftProtoReflect

// Create a message descriptor
let personDescriptor = ProtoMessageDescriptor(
	fullName: "example.Person",
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

// Set field values
person.set(fieldName: "name", value: ProtoValue.stringValue("John Doe"))
person.set(fieldName: "age", value: ProtoValue.intValue(30))
person.set(fieldName: "email", value: ProtoValue.stringValue("john.doe@example.com"))

// Get field values
if let name = person.get(fieldName: "name")?.getString() {
	print("Name: \(name)")
}

if let age = person.get(fieldName: "age")?.getInt() {
	print("Age: \(age)")
}
```

### Working with Nested Messages

```swift
// Create an address descriptor
let addressDescriptor = ProtoMessageDescriptor(
	fullName: "example.Address",
	fields: [
		ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
		ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
		ProtoFieldDescriptor(name: "zip", number: 3, type: .string, isRepeated: false, isMap: false)
	],
	enums: [],
	nestedMessages: []
)

// Add an address field to the person descriptor
let addressField = ProtoFieldDescriptor(
	name: "address", 
	number: 4, 
	type: .message, 
	isRepeated: false, 
	isMap: false, 
	messageType: addressDescriptor
)
personDescriptor.addField(addressField)

// Create a nested message
let address = person.createNestedMessage(for: addressField)
address.set(fieldName: "street", value: ProtoValue.stringValue("123 Main St"))
address.set(fieldName: "city", value: ProtoValue.stringValue("Anytown"))
address.set(fieldName: "zip", value: ProtoValue.stringValue("12345"))

// Set the nested message on the parent
person.setNestedMessage(field: addressField, message: address)

// Get a nested message
if let address = person.getNestedMessage(field: addressField) {
	if let street = address.get(fieldName: "street")?.getString() {
		print("Street: \(street)")
	}
}
```

### Working with Repeated Fields

```swift
// Add a repeated field to the person descriptor
let phonesField = ProtoFieldDescriptor(
	name: "phones", 
	number: 5, 
	type: .string, 
	isRepeated: true, 
	isMap: false
)
personDescriptor.addField(phonesField)

// Set a repeated field
person.set(field: phonesField, value: ProtoValue.repeatedValue([
	ProtoValue.stringValue("555-1234"),
	ProtoValue.stringValue("555-5678")
]))

// Add to a repeated field
person.add(toRepeatedField: phonesField, value: ProtoValue.stringValue("555-9012"))

// Get a repeated field
if let phones = person.get(field: phonesField)?.getRepeated() {
	for phone in phones {
		if let phoneNumber = phone.getString() {
			print("Phone: \(phoneNumber)")
		}
	}
}
```

### Working with Map Fields

```swift
// Add a map field to the person descriptor
let attributesField = ProtoFieldDescriptor(
	name: "attributes", 
	number: 6, 
	type: .message, 
	isRepeated: false, 
	isMap: true
)
personDescriptor.addField(attributesField)

// Set a map field
person.set(field: attributesField, value: ProtoValue.mapValue([
	"height": ProtoValue.stringValue("6'0\""),
	"weight": ProtoValue.stringValue("180lbs")
]))

// Set a map entry
person.set(inMapField: attributesField, key: "hair_color", value: ProtoValue.stringValue("brown"))

// Get a map field
if let attributes = person.get(field: attributesField)?.getMap() {
	for (key, value) in attributes {
		if let attributeValue = value.getString() {
			print("\(key): \(attributeValue)")
		}
	}
}
```

### Using Field Paths

```swift
// Create field paths
let namePath = ProtoFieldPath(path: "name")
let streetPath = ProtoFieldPath(path: "address.street")
let phonePath = ProtoFieldPath(path: "phones[0]")
let heightPath = ProtoFieldPath(path: "attributes['height']")

// Get values using paths
if let name = namePath.getValue(from: person)?.getString() {
	print("Name: \(name)")
}

if let street = streetPath.getValue(from: person)?.getString() {
	print("Street: \(street)")
}

// Set values using paths
namePath.setValue(ProtoValue.stringValue("Jane Doe"), in: person)
streetPath.setValue(ProtoValue.stringValue("456 Oak Ave"), in: person)
```

### Validation

```swift
// Check if a value is valid for a field
let nameField = personDescriptor.field(named: "name")!
let isValid = ProtoValue.stringValue("John Doe").isValid(for: nameField)
print("Is valid: \(isValid)")

// Validate a message
let isMessageValid = person.isValid()
print("Is message valid: \(isMessageValid)")
```

### Serialization

```swift
// Serialize to binary format
let binaryData = try person.serializedData()

// Deserialize from binary format
let deserializedPerson = try ProtoDynamicMessage(descriptor: personDescriptor, serializedData: binaryData)

// Serialize to JSON format
let jsonData = try person.jsonUTF8Data()

// Deserialize from JSON format
let jsonDeserializedPerson = try ProtoDynamicMessage(descriptor: personDescriptor, jsonUTF8Data: jsonData)
```

## Documentation

For more detailed documentation, see the [API Documentation](docs/SwiftProtoReflect_API_Documentation.md).

## License

SwiftProtoReflect is released under the MIT License. See [LICENSE](LICENSE) for details.
