import Foundation

/// Enhanced errors that can occur during Protocol Buffer wire format operations.
///
/// This enum provides detailed error information for various failure scenarios
/// that may occur during serialization, deserialization, and validation of Protocol Buffer messages.
public enum ProtoWireFormatErrorEnhanced: Error, Equatable {
  // MARK: - Type Errors

  /// An error indicating a type mismatch between expected and actual types.
  case typeMismatch(expected: ProtoFieldType, got: ProtoFieldType)

  /// An error indicating an invalid field number.
  case invalidFieldNumber(number: Int)

  /// An error indicating a mismatch between expected and actual wire types.
  case wireTypeMismatch(expected: Int, got: Int)

  // MARK: - Validation Errors

  /// An error indicating a message exceeds the maximum allowed size.
  case messageTooLarge(size: Int, max: Int)

  /// An error indicating the nesting depth exceeds the maximum allowed depth.
  case nestingTooDeep(depth: Int, max: Int)

  /// An error indicating invalid UTF-8 string data.
  case invalidUtf8String

  /// An error indicating an invalid map key.
  case invalidMapKey(reason: String)

  // MARK: - Format Errors

  /// An error indicating a message is truncated or incomplete.
  case truncatedMessage

  /// An error indicating a malformed varint encoding.
  case malformedVarint

  /// An error indicating an invalid field tag.
  case invalidTag

  // MARK: - Resource Errors

  /// An error indicating out-of-memory condition.
  case outOfMemory

  /// An error indicating a buffer is too small for the required operation.
  case bufferTooSmall

  // MARK: - General Errors

  /// An error indicating a general validation error.
  case validationError(fieldName: String, reason: String)

  /// An error indicating an invalid or unsupported message type.
  case invalidMessageType

  /// An error indicating an unsupported field type.
  case unsupportedType

  /// An error indicating an unsupported wire type.
  case unsupportedWireType

  /// An error indicating an invalid field key.
  case invalidFieldKey

  // MARK: - Equatable Implementation

  /// Compares two error instances for equality.
  ///
  /// Two errors are considered equal if they are of the same case and their associated values match.
  public static func == (lhs: ProtoWireFormatErrorEnhanced, rhs: ProtoWireFormatErrorEnhanced) -> Bool {
    switch (lhs, rhs) {
    case (
      .typeMismatch(let lhsExpected, let lhsGot),
      .typeMismatch(let rhsExpected, let rhsGot)
    ):
      return lhsExpected == rhsExpected && lhsGot == rhsGot

    case (
      .invalidFieldNumber(let lhsNumber),
      .invalidFieldNumber(let rhsNumber)
    ):
      return lhsNumber == rhsNumber

    case (
      .wireTypeMismatch(let lhsExpected, let lhsGot),
      .wireTypeMismatch(let rhsExpected, let rhsGot)
    ):
      return lhsExpected == rhsExpected && lhsGot == rhsGot

    case (
      .messageTooLarge(let lhsSize, let lhsMax),
      .messageTooLarge(let rhsSize, let rhsMax)
    ):
      return lhsSize == rhsSize && lhsMax == rhsMax

    case (
      .nestingTooDeep(let lhsDepth, let lhsMax),
      .nestingTooDeep(let rhsDepth, let rhsMax)
    ):
      return lhsDepth == rhsDepth && lhsMax == rhsMax

    case (.invalidUtf8String, .invalidUtf8String):
      return true

    case (
      .invalidMapKey(let lhsReason),
      .invalidMapKey(let rhsReason)
    ):
      return lhsReason == rhsReason

    case (.truncatedMessage, .truncatedMessage),
      (.malformedVarint, .malformedVarint),
      (.invalidTag, .invalidTag),
      (.outOfMemory, .outOfMemory),
      (.bufferTooSmall, .bufferTooSmall),
      (.invalidMessageType, .invalidMessageType),
      (.unsupportedType, .unsupportedType),
      (.unsupportedWireType, .unsupportedWireType),
      (.invalidFieldKey, .invalidFieldKey):
      return true

    case (
      .validationError(let lhsFieldName, let lhsReason),
      .validationError(let rhsFieldName, let rhsReason)
    ):
      return lhsFieldName == rhsFieldName && lhsReason == rhsReason

    default:
      return false
    }
  }

  // MARK: - Localized Description

  /// Returns a human-readable description of the error.
  public var localizedDescription: String {
    switch self {
    case .typeMismatch(let expected, let got):
      return "Type mismatch: expected \(expected), got \(got)"

    case .invalidFieldNumber(let number):
      return "Invalid field number: \(number)"

    case .wireTypeMismatch(let expected, let got):
      return "Wire type mismatch: expected \(expected), got \(got)"

    case .messageTooLarge(let size, let max):
      return "Message too large: \(size) bytes, maximum allowed is \(max) bytes"

    case .nestingTooDeep(let depth, let max):
      return "Nesting too deep: \(depth) levels, maximum allowed is \(max) levels"

    case .invalidUtf8String:
      return "Invalid UTF-8 string"

    case .invalidMapKey(let reason):
      return "Invalid map key: \(reason)"

    case .truncatedMessage:
      return "Truncated message: unexpected end of data"

    case .malformedVarint:
      return "Malformed varint encoding"

    case .invalidTag:
      return "Invalid field tag"

    case .outOfMemory:
      return "Out of memory"

    case .bufferTooSmall:
      return "Buffer too small for operation"

    case .validationError(let fieldName, let reason):
      return "Validation error in field '\(fieldName)': \(reason)"

    case .invalidMessageType:
      return "Invalid or unsupported message type"

    case .unsupportedType:
      return "Unsupported field type"

    case .unsupportedWireType:
      return "Unsupported wire type"

    case .invalidFieldKey:
      return "Invalid field key"
    }
  }

  // MARK: - Conversion

  /// Convert from simple ProtoWireFormatError
  public static func from(_ error: SwiftProtoReflect.ProtoWireFormatError) -> ProtoWireFormatErrorEnhanced {
    switch error {
    case .typeMismatch:
      return .typeMismatch(expected: .unknown, got: .unknown)
    case .unsupportedType:
      return .unsupportedType
    case .malformedVarint:
      return .malformedVarint
    case .truncatedMessage:
      return .truncatedMessage
    case .invalidUtf8String:
      return .invalidUtf8String
    case .invalidMessageType:
      return .invalidMessageType
    case .wireTypeMismatch:
      return .wireTypeMismatch(expected: -1, got: -1)
    case .validationError(let fieldName, let reason):
      return .validationError(fieldName: fieldName, reason: reason)
    case .unsupportedWireType:
      return .unsupportedWireType
    case .invalidFieldKey:
      return .invalidFieldKey
    }
  }
}
