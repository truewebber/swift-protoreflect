// ProtoValue represents the value of a protobuf field. It encapsulates different Swift types such as Int, String, Bool, and nested messages.
enum ProtoValue {
	case intValue(Int)
	case stringValue(String)
	case boolValue(Bool)
	case messageValue(ProtoMessage)
	case enumValue(ProtoEnumValueDescriptor)

	// Returns the value as an integer if it is an intValue.
	func getInt() -> Int? {
		if case let .intValue(value) = self {
			return value
		}
		return nil
	}

	// Returns the value as a string if it is a stringValue.
	func getString() -> String? {
		if case let .stringValue(value) = self {
			return value
		}
		return nil
	}

	// Returns the value as a boolean if it is a boolValue.
	func getBool() -> Bool? {
		if case let .boolValue(value) = self {
			return value
		}
		return nil
	}

	// Returns the value as a nested message if it is a messageValue.
	func getMessage() -> ProtoMessage? {
		if case let .messageValue(value) = self {
			return value
		}
		return nil
	}

	// Returns the value as an enum if it is an enumValue.
	func getEnum() -> ProtoEnumValueDescriptor? {
		if case let .enumValue(value) = self {
			return value
		}
		return nil
	}
}
