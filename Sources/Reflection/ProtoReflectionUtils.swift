// ProtoReflectionUtils provides common utility methods for reflection tasks and error handling.
struct ProtoReflectionUtils {
	
	// Validates that a ProtoFieldDescriptor is properly initialized.
	static func validateFieldDescriptor(_ descriptor: ProtoFieldDescriptor) -> Bool {
		return descriptor.isValid()
	}

	// Validates that a ProtoMessageDescriptor is properly initialized.
	static func validateMessageDescriptor(_ descriptor: ProtoMessageDescriptor) -> Bool {
		return descriptor.isValid()
	}

	// Provides detailed reflection information for a ProtoMessage.
	static func describeMessage(_ message: ProtoMessage) -> String {
		let descriptor = message.descriptor()
		var description = "Message: \(descriptor.fullName)\n"
		for field in descriptor.fields {
			description += "Field: \(field.name) (Type: \(field.type.name()))\n"
		}
		return description
	}
}
