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
  case message

  /// An enumeration.
  case `enum`

  /// An unknown or unsupported type.
  case unknown

  /// Determines if the field type is a numeric type.
  ///
  /// Numeric types include integers, floating-point numbers, and booleans.
  ///
  /// - Returns: `true` if the field type is numeric, `false` otherwise.
  public func isNumericType() -> Bool {
    switch self {
    case .int32, .int64, .uint32, .uint64, .sint32, .sint64, .sfixed32, .sfixed64, .fixed32, .fixed64, .float, .double,
      .bool:
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
    case .unknown:
      return "unknown"
    }
  }
}
