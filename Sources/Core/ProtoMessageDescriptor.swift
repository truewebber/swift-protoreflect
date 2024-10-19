// ProtoMessageDescriptor describes the structure of a protobuf message, including its fields, enums, and nested messages.
class ProtoMessageDescriptor {
	// Full name of the protobuf message.
	let fullName: String

	// List of field descriptors in the message.
	let fields: [ProtoFieldDescriptor]

	// Enum descriptors used in the message.
	let enums: [ProtoEnumDescriptor]

	// Nested message descriptors.
	let nestedMessages: [ProtoMessageDescriptor]

	// Constructor for ProtoMessageDescriptor.
	init(fullName: String, fields: [ProtoFieldDescriptor], enums: [ProtoEnumDescriptor], nestedMessages: [ProtoMessageDescriptor]) {
		self.fullName = fullName
		self.fields = fields
		self.enums = enums
		self.nestedMessages = nestedMessages
	}

	// Retrieves a field descriptor by name.
	func field(named name: String) -> ProtoFieldDescriptor? {
		return fields.first { $0.name == name }
	}

	// Retrieves a field descriptor by index.
	func field(at index: Int) -> ProtoFieldDescriptor? {
		guard index < fields.count else { return nil }
		return fields[index]
	}

	// Verifies if the descriptor is valid.
	func isValid() -> Bool {
		return !fullName.isEmpty
	}
}

