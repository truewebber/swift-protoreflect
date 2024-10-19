// ProtoFieldType defines the various types of fields in protobuf messages.
enum ProtoFieldType {
	case int32
	case int64
	case uint32
	case uint64
	case string
	case bool
	case message
	case enumType

	// Returns a human-readable name for the field type.
	func name() -> String {
		switch self {
		case .int32: return "int32"
		case .int64: return "int64"
		case .uint32: return "uint32"
		case .uint64: return "uint64"
		case .string: return "string"
		case .bool: return "bool"
		case .message: return "message"
		case .enumType: return "enum"
		}
	}
}
