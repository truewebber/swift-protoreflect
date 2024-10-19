// ProtoFieldDescriptor provides metadata for a specific field within a protobuf message, including its name, type, and other properties.
class ProtoFieldDescriptor: Hashable {
	// Name of the field.
	let name: String

	// Field number as defined in the .proto file.
	let number: Int

	// Field type, represented as ProtoFieldType.
	let type: ProtoFieldType

	// Indicates whether the field is repeated.
	let isRepeated: Bool

	// Indicates whether the field is a map type.
	let isMap: Bool

	// Default value of the field.
	let defaultValue: ProtoValue?

	// Descriptor for message fields (for nested message types).
	let messageType: ProtoMessageDescriptor?

	// Constructor for ProtoFieldDescriptor.
	init(name: String, number: Int, type: ProtoFieldType, isRepeated: Bool, isMap: Bool, defaultValue: ProtoValue? = nil, messageType: ProtoMessageDescriptor? = nil) {
		self.name = name
		self.number = number
		self.type = type
		self.isRepeated = isRepeated
		self.isMap = isMap
		self.defaultValue = defaultValue
		self.messageType = messageType
	}

	// Conformance to the Hashable protocol.
	static func == (lhs: ProtoFieldDescriptor, rhs: ProtoFieldDescriptor) -> Bool {
		return lhs.name == rhs.name && lhs.number == rhs.number && lhs.type == rhs.type
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(number)
		hasher.combine(type)
	}

	// Verifies if the field descriptor is valid.
	func isValid() -> Bool {
		return !name.isEmpty && number > 0
	}
}
