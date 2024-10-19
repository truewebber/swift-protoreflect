// ProtoDynamicMessage is a concrete implementation of the ProtoMessage protocol.
// It allows dynamic handling of protobuf messages at runtime, storing field values and accessing them based on field descriptors.
class ProtoDynamicMessage: ProtoMessage {
	// The message descriptor for this dynamic message.
	let messageDescriptor: ProtoMessageDescriptor

	// A dictionary that maps field descriptors to their current values.
	var fields: [ProtoFieldDescriptor: ProtoValue]

	// Constructor for ProtoDynamicMessage.
	init(descriptor: ProtoMessageDescriptor) {
		self.messageDescriptor = descriptor
		self.fields = [:]
	}

	// Returns the message descriptor (schema information).
	func descriptor() -> ProtoMessageDescriptor {
		return messageDescriptor
	}

	// Retrieves the value of the specified field using its descriptor.
	func get(field: ProtoFieldDescriptor) -> ProtoValue? {
		return fields[field]
	}

	// Sets the value of the specified field.
	func set(field: ProtoFieldDescriptor, value: ProtoValue) {
		fields[field] = value
	}

	// Clears the value of the specified field, resetting it to default.
	func clear(field: ProtoFieldDescriptor) {
		fields.removeValue(forKey: field)
	}

	// Returns whether the message is valid and properly initialized.
	func isValid() -> Bool {
		return messageDescriptor.isValid()
	}
}
