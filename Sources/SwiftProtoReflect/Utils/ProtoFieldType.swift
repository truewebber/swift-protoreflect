/// Defines the various types of fields in Protocol Buffer messages.
///
/// This enum represents the different data types that can be used in Protocol Buffer fields,
/// such as integers, strings, booleans, and nested messages.
public enum ProtoFieldType {
  /// 32-bit signed integer
  case int32
  /// 64-bit signed integer
  case int64
  /// 32-bit unsigned integer
  case uint32
  /// 64-bit unsigned integer
  case uint64
  /// UTF-8 encoded string
  case string
  /// Boolean value
  case bool
  /// Nested message
  case message
  /// Enumeration value
  case enumType

  /// Returns a human-readable name for the field type.
  ///
  /// - Returns: A string representation of the field type.
  public func name() -> String {
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
