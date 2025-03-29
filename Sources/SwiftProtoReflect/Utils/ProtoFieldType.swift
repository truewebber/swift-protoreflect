import Foundation

/// Represents the data type of a Protocol Buffer field.
///
/// This enum defines all the possible field types in Protocol Buffers, including
/// primitive types, strings, bytes, messages, and enums.
///
/// Example:
/// ```swift
/// let fieldType = ProtoFieldType.int32
/// let isNumeric = fieldType.isNumericType()
/// ```
public enum ProtoFieldType {
  /// A 32-bit signed integer.
  case int32

  /// A 64-bit signed integer.
  case int64

  /// A 32-bit unsigned integer.
  case uint32

  /// A 64-bit unsigned integer.
  case uint64

  /// A 32-bit signed integer using zigzag encoding for efficient negative number representation.
  case sint32

  /// A 64-bit signed integer using zigzag encoding for efficient negative number representation.
  case sint64

  /// A 32-bit fixed-size signed integer.
  case sfixed32

  /// A 64-bit fixed-size signed integer.
  case sfixed64

  /// A 32-bit fixed-size unsigned integer.
  case fixed32

  /// A 64-bit fixed-size unsigned integer.
  case fixed64

  /// A boolean value.
  case bool

  /// A UTF-8 encoded string.
  case string

  /// A sequence of bytes.
  case bytes

  /// A single-precision floating-point number.
  case float

  /// A double-precision floating-point number.
  case double

  /// A nested message.
  case message(ProtoMessageDescriptor? = nil)

  /// An enumeration.
  case `enum`(ProtoEnumDescriptor? = nil)

  /// A group (deprecated in Protocol Buffers v3, included for backward compatibility).
  case group

  /// An unknown or unsupported type.
  case unknown

  /// Determines if the field type is a numeric type.
  ///
  /// Numeric types include integers, floating-point numbers, and booleans.
  ///
  /// - Returns: `true` if the field type is numeric, `false` otherwise.
  public func isNumericType() -> Bool {
    switch self {
    case .int32, .int64, .uint32, .uint64, .sint32, .sint64, .sfixed32, .sfixed64, .fixed32, .fixed64, .float, .double:
      return true
    default:
      return false
    }
  }

  /// Determines if the field type is an integer type.
  ///
  /// Integer types include signed and unsigned integers, but not floating-point numbers.
  ///
  /// - Returns: `true` if the field type is an integer, `false` otherwise.
  public func isIntegerType() -> Bool {
    switch self {
    case .int32, .int64, .uint32, .uint64, .sint32, .sint64, .sfixed32, .sfixed64, .fixed32, .fixed64:
      return true
    default:
      return false
    }
  }

  /// Determines if the field type is a floating-point type.
  ///
  /// Floating-point types include float and double.
  ///
  /// - Returns: `true` if the field type is a floating-point number, `false` otherwise.
  public func isFloatingPointType() -> Bool {
    switch self {
    case .float, .double:
      return true
    default:
      return false
    }
  }

  /// Determines if the field type is a string or bytes type.
  ///
  /// - Returns: `true` if the field type is a string or bytes, `false` otherwise.
  public func isStringOrBytesType() -> Bool {
    switch self {
    case .string, .bytes:
      return true
    default:
      return false
    }
  }

  /// Returns a string representation of the field type.
  ///
  /// - Returns: A string describing the field type.
  public func description() -> String {
    switch self {
    case .int32:
      return "int32"
    case .int64:
      return "int64"
    case .uint32:
      return "uint32"
    case .uint64:
      return "uint64"
    case .sint32:
      return "sint32"
    case .sint64:
      return "sint64"
    case .sfixed32:
      return "sfixed32"
    case .sfixed64:
      return "sfixed64"
    case .fixed32:
      return "fixed32"
    case .fixed64:
      return "fixed64"
    case .bool:
      return "bool"
    case .string:
      return "string"
    case .bytes:
      return "bytes"
    case .float:
      return "float"
    case .double:
      return "double"
    case .message:
      return "message"
    case .enum:
      return "enum"
    case .group:
      return "group"
    case .unknown:
      return "unknown"
    }
  }

  /// Validates a field number according to Protocol Buffer specifications.
  ///
  /// Field numbers must be:
  /// - Greater than 0
  /// - Less than or equal to 536870911 (2^29 - 1)
  /// - Not in the reserved range (19000-19999)
  ///
  /// - Parameter fieldNumber: The field number to validate
  /// - Returns: `true` if the field number is valid, `false` otherwise
  public static func validateFieldNumber(_ fieldNumber: Int) -> Bool {
    // Check basic range
    guard fieldNumber > 0 && fieldNumber <= 536870911 else {
      return false
    }
    
    // Check reserved range
    guard fieldNumber < 19000 || fieldNumber > 19999 else {
      return false
    }
    
    return true
  }
  
  /// Determines if two field types are compatible for conversion.
  ///
  /// Type compatibility rules:
  /// - Same types are always compatible
  /// - Numeric types can be converted between each other (with potential data loss)
  /// - String and bytes are not compatible with each other
  /// - Message and enum types are not compatible with primitive types
  /// - Unknown type is only compatible with itself
  /// - Group type is only compatible with itself
  ///
  /// - Parameters:
  ///   - type1: The first field type
  ///   - type2: The second field type
  /// - Returns: `true` if the types are compatible, `false` otherwise
  public static func areTypesCompatible(_ type1: ProtoFieldType, _ type2: ProtoFieldType) -> Bool {
    // Same types are always compatible
    if type1 == type2 {
      return true
    }
    
    // Unknown type is only compatible with itself
    switch (type1, type2) {
    case (.unknown, _), (_, .unknown):
      return false
    case (.group, _), (_, .group):
      return false
    case (.message, _), (_, .message):
      return false
    case (.enum, _), (_, .enum):
      return false
    case (.bool, _), (_, .bool):
      return false
    case (.string, _), (_, .string):
      return false
    case (.bytes, _), (_, .bytes):
      return false
    default:
      break
    }
    
    // Check numeric type compatibility
    if type1.isNumericType() && type2.isNumericType() {
      // Only allow conversions between compatible numeric types
      if type1.isIntegerType() && type2.isIntegerType() {
        return true
      }
      if type1.isFloatingPointType() && type2.isFloatingPointType() {
        return true
      }
      // Allow integer to float/double conversion
      if type1.isIntegerType() && type2.isFloatingPointType() {
        return true
      }
      if type2.isIntegerType() && type1.isFloatingPointType() {
        return true
      }
      return false
    }
    
    return false
  }
  
  /// Determines if a field type is compatible with a wire type.
  ///
  /// Wire type compatibility rules:
  /// - Varint (0): int32, int64, uint32, uint64, sint32, sint64, bool, enum
  /// - Fixed64 (1): fixed64, sfixed64, double
  /// - Length-delimited (2): string, bytes, message, repeated fields
  /// - Fixed32 (5): fixed32, sfixed32, float
  ///
  /// - Parameters:
  ///   - type: The field type to check
  ///   - wireType: The wire type to check compatibility with
  /// - Returns: `true` if the field type is compatible with the wire type, `false` otherwise
  public static func isWireTypeCompatible(_ type: ProtoFieldType, _ wireType: Int) -> Bool {
    switch wireType {
    case 0: // Varint
      switch type {
      case .int32, .int64, .uint32, .uint64, .sint32, .sint64, .bool, .enum:
        return true
      default:
        return false
      }
      
    case 1: // Fixed64
      switch type {
      case .fixed64, .sfixed64, .double:
        return true
      default:
        return false
      }
      
    case 2: // Length-delimited
      switch type {
      case .string, .bytes, .message:
        return true
      default:
        return false
      }
      
    case 5: // Fixed32
      switch type {
      case .fixed32, .sfixed32, .float:
        return true
      default:
        return false
      }
      
    default:
      return false
    }
  }
}

extension ProtoFieldType: Equatable {
  public static func == (lhs: ProtoFieldType, rhs: ProtoFieldType) -> Bool {
    switch (lhs, rhs) {
    case (.int32, .int32),
         (.int64, .int64),
         (.uint32, .uint32),
         (.uint64, .uint64),
         (.sint32, .sint32),
         (.sint64, .sint64),
         (.sfixed32, .sfixed32),
         (.sfixed64, .sfixed64),
         (.fixed32, .fixed32),
         (.fixed64, .fixed64),
         (.bool, .bool),
         (.string, .string),
         (.bytes, .bytes),
         (.float, .float),
         (.double, .double),
         (.group, .group),
         (.unknown, .unknown):
      return true
    case (.message(let lhsDescriptor), .message(let rhsDescriptor)):
      return lhsDescriptor?.fullName == rhsDescriptor?.fullName
    case (.enum(let lhsDescriptor), .enum(let rhsDescriptor)):
      return lhsDescriptor?.name == rhsDescriptor?.name
    default:
      return false
    }
  }
}

extension ProtoFieldType: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .int32:
      hasher.combine(0)
    case .int64:
      hasher.combine(1)
    case .uint32:
      hasher.combine(2)
    case .uint64:
      hasher.combine(3)
    case .sint32:
      hasher.combine(4)
    case .sint64:
      hasher.combine(5)
    case .sfixed32:
      hasher.combine(6)
    case .sfixed64:
      hasher.combine(7)
    case .fixed32:
      hasher.combine(8)
    case .fixed64:
      hasher.combine(9)
    case .bool:
      hasher.combine(10)
    case .string:
      hasher.combine(11)
    case .bytes:
      hasher.combine(12)
    case .float:
      hasher.combine(13)
    case .double:
      hasher.combine(14)
    case .message(let descriptor):
      hasher.combine(15)
      hasher.combine(descriptor?.fullName)
    case .enum(let descriptor):
      hasher.combine(16)
      hasher.combine(descriptor?.name)
    case .group:
      hasher.combine(17)
    case .unknown:
      hasher.combine(18)
    }
  }
}
