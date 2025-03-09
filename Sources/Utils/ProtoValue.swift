/// Represents the value of a Protocol Buffer field.
///
/// This enum encapsulates different Swift types such as Int, String, Bool, and nested messages,
/// providing a type-safe way to work with Protocol Buffer field values.
public enum ProtoValue {
	/// An integer value
	case intValue(Int)
	/// A string value
	case stringValue(String)
	/// A boolean value
	case boolValue(Bool)
	/// A nested message value
	case messageValue(ProtoMessage)
	/// An enum value
	case enumValue(ProtoEnumValueDescriptor)
	/// An array of values (for repeated fields)
	case arrayValue([ProtoValue])
	/// A dictionary of values (for map fields)
	case mapValue([String: ProtoValue])

	/// Returns the value as an integer if it is an intValue.
	///
	/// - Returns: The integer value, or nil if this is not an intValue.
	public func getInt() -> Int? {
		if case let .intValue(value) = self {
			return value
		}
		return nil
	}

	/// Returns the value as a string if it is a stringValue.
	///
	/// - Returns: The string value, or nil if this is not a stringValue.
	public func getString() -> String? {
		if case let .stringValue(value) = self {
			return value
		}
		return nil
	}

	/// Returns the value as a boolean if it is a boolValue.
	///
	/// - Returns: The boolean value, or nil if this is not a boolValue.
	public func getBool() -> Bool? {
		if case let .boolValue(value) = self {
			return value
		}
		return nil
	}

	/// Returns the value as a nested message if it is a messageValue.
	///
	/// - Returns: The message value, or nil if this is not a messageValue.
	public func getMessage() -> ProtoMessage? {
		if case let .messageValue(value) = self {
			return value
		}
		return nil
	}

	/// Returns the value as an enum if it is an enumValue.
	///
	/// - Returns: The enum value descriptor, or nil if this is not an enumValue.
	public func getEnum() -> ProtoEnumValueDescriptor? {
		if case let .enumValue(value) = self {
			return value
		}
		return nil
	}
	
	/// Returns the value as an array if it is an arrayValue.
	///
	/// - Returns: The array of values, or nil if this is not an arrayValue.
	public func getArray() -> [ProtoValue]? {
		if case let .arrayValue(value) = self {
			return value
		}
		return nil
	}
	
	/// Returns the value as a map if it is a mapValue.
	///
	/// - Returns: The dictionary of values, or nil if this is not a mapValue.
	public func getMap() -> [String: ProtoValue]? {
		if case let .mapValue(value) = self {
			return value
		}
		return nil
	}
}
