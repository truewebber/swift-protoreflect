import Foundation

// ProtoReflect serves as the main entry point for the protoreflect library.
// It provides utility functions to work with protobuf messages, descriptors, and dynamic message creation.

struct ProtoReflect {

	// Creates a new dynamic message for the provided message descriptor.
	static func createMessage(from descriptor: ProtoMessageDescriptor) -> ProtoMessage {
		return ProtoDynamicMessage(descriptor: descriptor)
	}

	// Serializes a ProtoMessage into protobuf wire format.
	static func marshal(message: ProtoMessage) -> Data? {
		return ProtoWireFormat.marshal(message: message)
	}

	// Deserializes protobuf wire format data into a dynamic ProtoMessage based on the descriptor.
	static func unmarshal(data: Data, descriptor: ProtoMessageDescriptor) -> ProtoMessage? {
		return ProtoWireFormat.unmarshal(data: data, messageDescriptor: descriptor)
	}

	// Prints a description of the ProtoMessage, including its fields and types.
	static func describe(message: ProtoMessage) -> String {
		return ProtoReflectionUtils.describeMessage(message)
	}

	// Validates a ProtoMessage to ensure it is properly initialized.
	static func validateMessage(_ message: ProtoMessage) -> Bool {
		return ProtoReflectionUtils.validateMessageDescriptor(message.descriptor())
	}

	// Validates a ProtoFieldDescriptor to ensure it is properly initialized.
	static func validateField(_ field: ProtoFieldDescriptor) -> Bool {
		return ProtoReflectionUtils.validateFieldDescriptor(field)
	}
}
