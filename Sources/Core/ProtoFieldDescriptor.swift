/// A descriptor for a Protocol Buffer field, containing metadata about the field's name, type, and other properties.
///
/// `ProtoFieldDescriptor` represents a single field within a Protocol Buffer message. It contains
/// all the metadata needed to correctly serialize, deserialize, and validate field values.
///
/// Example:
/// ```swift
/// let fieldDescriptor = ProtoFieldDescriptor(
///     name: "user_id",
///     number: 1,
///     type: .int64,
///     isRepeated: false,
///     isMap: false
/// )
/// ```
///
/// - Note: Field numbers must be positive and unique within a message.
/// - Important: For message-type fields, you must provide a `messageType` descriptor.
public class ProtoFieldDescriptor: Hashable {
	/// The name of the field as defined in the Protocol Buffer schema.
	///
	/// This name corresponds to the field name in the `.proto` file. For example, a field defined as
	/// `string user_name = 1;` in a `.proto` file would have the name "user_name".
	///
	/// - Note: Field names must be non-empty and should follow Protocol Buffer naming conventions.
	public let name: String

	/// The field number as defined in the Protocol Buffer schema.
	///
	/// Field numbers uniquely identify fields within a message when serialized to the binary wire format.
	/// Valid field numbers are positive integers.
	///
	/// - Note: Field numbers 1-15 use one byte in the wire format, while numbers 16-2047 use two bytes.
	///   For frequently used fields, prefer numbers 1-15 for efficiency.
	public let number: Int

	/// Field type, represented as ProtoFieldType.
	///
	/// Defines the data type of the field, such as int32, string, bool, etc.
	/// This determines how the field is serialized and deserialized.
	public let type: ProtoFieldType

	/// Indicates whether the field is repeated (can contain multiple values).
	///
	/// Repeated fields are equivalent to arrays in Swift and can contain zero or more values.
	/// In Protocol Buffers, repeated fields are defined with the `repeated` keyword.
	public let isRepeated: Bool

	/// Indicates whether the field is a map type.
	///
	/// Map fields represent key-value pairs and are serialized as a special repeated message.
	/// In Protocol Buffers, map fields are defined with the `map<key_type, value_type>` syntax.
	public let isMap: Bool

	/// Default value of the field, if any.
	///
	/// This value is used when the field is not present in the serialized data.
	/// If nil, the default value for the field type is used (0 for numbers, empty string for strings, etc.).
	public let defaultValue: ProtoValue?

	/// Descriptor for message fields (for nested message types).
	///
	/// For fields of type `.message`, this property must contain the descriptor for the nested message type.
	/// This is required for proper serialization and deserialization of nested messages.
	public let messageType: ProtoMessageDescriptor?

	/// Creates a new field descriptor with the specified properties.
	///
	/// - Parameters:
	///   - name: The name of the field as defined in the Protocol Buffer schema.
	///   - number: The field number as defined in the Protocol Buffer schema.
	///   - type: The data type of the field.
	///   - isRepeated: Whether the field can contain multiple values.
	///   - isMap: Whether the field is a map type.
	///   - defaultValue: The default value for the field, if any.
	///   - messageType: For message fields, the descriptor of the nested message type.
	///
	/// - Note: For fields of type `.message`, the `messageType` parameter is required.
	public init(name: String, number: Int, type: ProtoFieldType, isRepeated: Bool, isMap: Bool, defaultValue: ProtoValue? = nil, messageType: ProtoMessageDescriptor? = nil) {
		self.name = name
		self.number = number
		self.type = type
		self.isRepeated = isRepeated
		self.isMap = isMap
		self.defaultValue = defaultValue
		self.messageType = messageType
	}

	/// Compares two field descriptors for equality.
	///
	/// Two field descriptors are considered equal if they have the same name, number, and type.
	///
	/// - Parameters:
	///   - lhs: The left-hand side field descriptor.
	///   - rhs: The right-hand side field descriptor.
	/// - Returns: `true` if the field descriptors are equal, `false` otherwise.
	public static func == (lhs: ProtoFieldDescriptor, rhs: ProtoFieldDescriptor) -> Bool {
		return lhs.name == rhs.name && lhs.number == rhs.number && lhs.type == rhs.type
	}

	/// Hashes the essential components of the field descriptor.
	///
	/// - Parameter hasher: The hasher to use for combining the field's components.
	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(number)
		hasher.combine(type)
	}

	/// Verifies if the field descriptor is valid according to Protocol Buffer rules.
	///
	/// A valid field descriptor must have:
	/// - A non-empty name
	/// - A positive field number
	/// - For message fields, a non-nil messageType
	///
	/// - Returns: `true` if the field descriptor is valid, `false` otherwise.
	public func isValid() -> Bool {
		if name.isEmpty || number <= 0 {
			return false
		}
		
		// For message fields, messageType must be provided
		if type == .message && messageType == nil {
			return false
		}
		
		return true
	}
	
	/// Returns a validation error message if the field descriptor is invalid, or nil if it's valid.
	///
	/// This method provides detailed information about why a field descriptor is invalid.
	///
	/// - Returns: An error message describing the validation failure, or nil if the descriptor is valid.
	public func validationError() -> String? {
		if name.isEmpty {
			return "Field name cannot be empty"
		}
		
		if number <= 0 {
			return "Field number must be positive (got \(number))"
		}
		
		if type == .message && messageType == nil {
			return "Message type field '\(name)' requires a messageType descriptor"
		}
		
		return nil
	}
}
