// ProtoMessage defines the core protocol for all protobuf messages in the reflection system.
// Messages conforming to ProtoMessage can be manipulated dynamically without knowing their structure at compile time.

protocol ProtoMessage {
	// Returns the descriptor of the message, which holds schema information.
	func descriptor() -> ProtoMessageDescriptor

	// Retrieves the value of the specified field using its field descriptor.
	func get(field: ProtoFieldDescriptor) -> ProtoValue?

	// Sets the value of the specified field.
	func set(field: ProtoFieldDescriptor, value: ProtoValue)

	// Clears the value of the specified field, resetting it to its default.
	func clear(field: ProtoFieldDescriptor)

	// Returns whether the message is valid and properly initialized.
	func isValid() -> Bool
}

