// ProtoEnumDescriptor describes an enum type within a protobuf message, including its values and names.
class ProtoEnumDescriptor {
	// Name of the enum type.
	let name: String

	// List of enum value descriptors in the enum.
	let values: [ProtoEnumValueDescriptor]

	// Constructor for ProtoEnumDescriptor.
	init(name: String, values: [ProtoEnumValueDescriptor]) {
		self.name = name
		self.values = values
	}

	// Retrieves an enum value by name.
	func value(named name: String) -> ProtoEnumValueDescriptor? {
		return values.first { $0.name == name }
	}

	// Retrieves an enum value by number.
	func value(by number: Int) -> ProtoEnumValueDescriptor? {
		return values.first { $0.number == number }
	}

	// Verifies if the enum descriptor is valid.
	func isValid() -> Bool {
		return !name.isEmpty && !values.isEmpty
	}
}
