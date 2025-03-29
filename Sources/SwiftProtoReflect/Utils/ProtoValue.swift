import Foundation

/// Represents a value in a Protocol Buffer message.
///
/// `ProtoValue` is an enum that can represent any valid Protocol Buffer field value,
/// including primitive types, strings, bytes, nested messages, enums, repeated fields, and maps.
///
/// # Examples
///
/// ## Creating Values
/// ```swift
/// // Creating primitive values
/// let intValue = ProtoValue.intValue(42)
/// let uintValue = ProtoValue.uintValue(100)
/// let floatValue = ProtoValue.floatValue(3.14)
/// let doubleValue = ProtoValue.doubleValue(2.71828)
/// let boolValue = ProtoValue.boolValue(true)
/// let stringValue = ProtoValue.stringValue("Hello, world!")
/// let bytesValue = ProtoValue.bytesValue(Data([0x01, 0x02, 0x03]))
///
/// // Creating a message value
/// let personDescriptor = ProtoMessageDescriptor(fullName: "Person", fields: [...], enums: [], nestedMessages: [])
/// let personMessage = ProtoDynamicMessage(descriptor: personDescriptor)
/// let messageValue = ProtoValue.messageValue(personMessage)
///
/// // Creating an enum value
/// let enumDescriptor = ProtoEnumDescriptor(name: "Color", values: [
///     ProtoEnumValueDescriptor(name: "RED", number: 0),
///     ProtoEnumValueDescriptor(name: "GREEN", number: 1),
///     ProtoEnumValueDescriptor(name: "BLUE", number: 2)
/// ])
/// let enumValue = ProtoValue.enumValue(name: "GREEN", number: 1, enumDescriptor: enumDescriptor)
///
/// // Creating a repeated value
/// let repeatedValue = ProtoValue.repeatedValue([
///     ProtoValue.intValue(1),
///     ProtoValue.intValue(2),
///     ProtoValue.intValue(3)
/// ])
///
/// // Creating a map value
/// let mapValue = ProtoValue.mapValue([
///     "key1": ProtoValue.stringValue("value1"),
///     "key2": ProtoValue.stringValue("value2")
/// ])
/// ```
///
/// ## Extracting Values
/// ```swift
/// // Type-safe extraction
/// if let value = intValue.getInt() {
///     print("Int value: \(value)")
/// }
///
/// if let value = stringValue.getString() {
///     print("String value: \(value)")
/// }
///
/// // Working with repeated values
/// if let values = repeatedValue.getRepeated() {
///     for value in values {
///         if let intValue = value.getInt() {
///             print("Repeated int: \(intValue)")
///         }
///     }
/// }
///
/// // Working with map values
/// if let map = mapValue.getMap() {
///     for (key, value) in map {
///         if let stringValue = value.getString() {
///             print("Map entry: \(key) -> \(stringValue)")
///         }
///     }
/// }
/// ```
///
/// ## Type Conversion
/// ```swift
/// // Converting between types
/// let intAsString = intValue.asString() // "42"
/// let stringAsInt = stringValue.asInt32() // nil if not a valid integer
///
/// // Converting to target type
/// if let doubleFromInt = intValue.convertTo(targetType: .double) {
///     print("Converted to double: \(doubleFromInt.getDouble()!)")
/// }
/// ```
///
/// ## Validation
/// ```swift
/// // Validating against field descriptors
/// let fieldDescriptor = ProtoFieldDescriptor(name: "age", number: 1, type: .int32, isRepeated: false, isMap: false)
/// let isValid = intValue.isValid(for: fieldDescriptor) // true
///
/// // Validating complex types
/// let repeatedFieldDescriptor = ProtoFieldDescriptor(name: "scores", number: 2, type: .int32, isRepeated: true, isMap: false)
/// let isValidRepeated = repeatedValue.isValid(for: repeatedFieldDescriptor) // true if all elements are valid integers
/// ```
public enum ProtoValue: Hashable {
  /// Represents an integer value (int32, int64, sint32, sint64, sfixed32, sfixed64).
  case intValue(Int)

  /// Represents an unsigned integer value (uint32, uint64, fixed32, fixed64).
  case uintValue(UInt)

  /// Represents a floating-point value (float).
  case floatValue(Float)

  /// Represents a double-precision floating-point value (double).
  case doubleValue(Double)

  /// Represents a boolean value (bool).
  case boolValue(Bool)

  /// Represents a string value (string).
  case stringValue(String)

  /// Represents a bytes value (bytes).
  case bytesValue(Data)

  /// Represents a nested message value (message).
  case messageValue(ProtoMessage)

  /// Represents a repeated value (repeated).
  case repeatedValue([ProtoValue])

  /// Represents a map value (map).
  case mapValue([String: ProtoValue])

  /// Represents an enum value (enum).
  case enumValue(name: String, number: Int, enumDescriptor: ProtoEnumDescriptor)

  /// Returns the value as an Int, or nil if the value is not an Int.
  public func getInt() -> Int? {
    if case .intValue(let value) = self {
      return value
    }
    return nil
  }

  /// Returns the value as a UInt, or nil if the value is not a UInt.
  public func getUInt() -> UInt? {
    if case .uintValue(let value) = self {
      return value
    }
    return nil
  }

  /// Returns the value as a Float, or nil if the value is not a Float.
  public func getFloat() -> Float? {
    if case .floatValue(let value) = self {
      return value
    }
    return nil
  }

  /// Returns the value as a Double, or nil if the value is not a Double.
  public func getDouble() -> Double? {
    if case .doubleValue(let value) = self {
      return value
    }
    return nil
  }

  /// Returns the value as a Bool, or nil if the value is not a Bool.
  public func getBool() -> Bool? {
    if case .boolValue(let value) = self {
      return value
    }
    return nil
  }

  /// Returns the value as a String, or nil if the value is not a String.
  public func getString() -> String? {
    if case .stringValue(let value) = self {
      return value
    }
    return nil
  }

  /// Returns the value as Data, or nil if the value is not Data.
  public func getBytes() -> Data? {
    if case .bytesValue(let value) = self {
      return value
    }
    return nil
  }

  /// Returns the value as a ProtoMessage, or nil if the value is not a ProtoMessage.
  public func getMessage() -> ProtoMessage? {
    if case .messageValue(let value) = self {
      return value
    }
    return nil
  }

  /// Returns the value as an array of ProtoValues, or nil if the value is not a repeated value.
  public func getRepeated() -> [ProtoValue]? {
    if case .repeatedValue(let value) = self {
      return value
    }
    return nil
  }

  /// Returns the value as a dictionary of ProtoValues, or nil if the value is not a map value.
  public func getMap() -> [String: ProtoValue]? {
    if case .mapValue(let value) = self {
      return value
    }
    return nil
  }

  /// Returns the value as an enum, or nil if the value is not an enum.
  public func getEnum() -> (name: String, number: Int, enumDescriptor: ProtoEnumDescriptor)? {
    if case .enumValue(let name, let number, let enumDescriptor) = self {
      return (name, number, enumDescriptor)
    }
    return nil
  }

  /// Attempts to convert the value to an Int32, regardless of its original type.
  ///
  /// - Returns: The value as an Int32, or nil if conversion is not possible.
  public func asInt32() -> Int? {
    switch self {
    case .intValue(let value):
      return value
    case .uintValue(let value):
      return Int(value)
    case .floatValue(let value):
      return Int(value)
    case .doubleValue(let value):
      return Int(value)
    case .boolValue(let value):
      return value ? 1 : 0
    case .stringValue(let value):
      return Int(value)
    case .enumValue(_, let number, _):
      return number
    default:
      return nil
    }
  }

  /// Attempts to convert the value to an Int64, regardless of its original type.
  ///
  /// - Returns: The value as an Int64, or nil if conversion is not possible.
  public func asInt64() -> Int64? {
    switch self {
    case .intValue(let value):
      return Int64(exactly: value)
    case .uintValue(let value):
      return Int64(exactly: value)
    case .floatValue(let value):
      return Int64(exactly: value)
    case .doubleValue(let value):
      return Int64(exactly: value)
    case .boolValue(let value):
      return value ? 1 : 0
    case .stringValue(let value):
      return Int64(value)
    case .enumValue(_, let number, _):
      return Int64(exactly: number)
    default:
      return nil
    }
  }

  /// Attempts to convert the value to a UInt32, regardless of its original type.
  ///
  /// - Returns: The value as a UInt32, or nil if conversion is not possible.
  public func asUInt32() -> UInt32? {
    switch self {
    case .intValue(let value):
      if value < 0 { return nil }
      return UInt32(exactly: value)
    case .uintValue(let value):
      return UInt32(exactly: value)
    case .floatValue(let value):
      if value < 0 { return nil }
      return UInt32(exactly: value)
    case .doubleValue(let value):
      if value < 0 { return nil }
      return UInt32(exactly: value)
    case .boolValue(let value):
      return value ? 1 : 0
    case .stringValue(let value):
      return UInt32(value)
    case .enumValue(_, let number, _):
      if number < 0 { return nil }
      return UInt32(exactly: number)
    default:
      return nil
    }
  }

  /// Attempts to convert the value to a UInt64, regardless of its original type.
  ///
  /// - Returns: The value as a UInt64, or nil if conversion is not possible.
  public func asUInt64() -> UInt64? {
    switch self {
    case .intValue(let value):
      if value < 0 { return nil }
      return UInt64(exactly: value)
    case .uintValue(let value):
      return UInt64(exactly: value)
    case .floatValue(let value):
      if value < 0 { return nil }
      return UInt64(exactly: value)
    case .doubleValue(let value):
      if value < 0 { return nil }
      return UInt64(exactly: value)
    case .boolValue(let value):
      return value ? 1 : 0
    case .stringValue(let value):
      return UInt64(value)
    case .enumValue(_, let number, _):
      if number < 0 { return nil }
      return UInt64(exactly: number)
    default:
      return nil
    }
  }

  /// Attempts to convert the value to a Float, regardless of its original type.
  ///
  /// - Returns: The value as a Float, or nil if conversion is not possible.
  public func asFloat() -> Float? {
    switch self {
    case .intValue(let value):
      return Float(value)
    case .uintValue(let value):
      return Float(value)
    case .floatValue(let value):
      return value
    case .doubleValue(let value):
      return Float(value)
    case .boolValue(let value):
      return value ? 1.0 : 0.0
    case .stringValue(let value):
      return Float(value)
    case .enumValue(_, let number, _):
      return Float(number)
    default:
      return nil
    }
  }

  /// Attempts to convert the value to a Double, regardless of its original type.
  ///
  /// - Returns: The value as a Double, or nil if conversion is not possible.
  public func asDouble() -> Double? {
    switch self {
    case .intValue(let value):
      return Double(value)
    case .uintValue(let value):
      return Double(value)
    case .floatValue(let value):
      return Double(value)
    case .doubleValue(let value):
      return value
    case .boolValue(let value):
      return value ? 1.0 : 0.0
    case .stringValue(let value):
      return Double(value)
    case .enumValue(_, let number, _):
      return Double(number)
    default:
      return nil
    }
  }

  /// Attempts to convert the value to a Bool, regardless of its original type.
  ///
  /// - Returns: The value as a Bool, or nil if conversion is not possible.
  public func asBool() -> Bool? {
    switch self {
    case .intValue(let value):
      return value != 0
    case .uintValue(let value):
      return value != 0
    case .floatValue(let value):
      return value != 0
    case .doubleValue(let value):
      return value != 0
    case .boolValue(let value):
      return value
    case .stringValue(let value):
      if value.lowercased() == "true" { return true }
      if value.lowercased() == "false" { return false }
      if let intValue = Int(value) { return intValue != 0 }
      return nil
    case .enumValue(_, let number, _):
      return number != 0
    default:
      return nil
    }
  }

  /// Attempts to convert the value to a String, regardless of its original type.
  ///
  /// - Returns: The value as a String.
  public func asString() -> String {
    switch self {
    case .intValue(let value):
      return String(value)
    case .uintValue(let value):
      return String(value)
    case .floatValue(let value):
      return String(value)
    case .doubleValue(let value):
      return String(value)
    case .boolValue(let value):
      return value ? "true" : "false"
    case .stringValue(let value):
      return value
    case .bytesValue(let value):
      return value.base64EncodedString()
    case .messageValue(let value):
      return "Message(\(value.descriptor().fullName))"
    case .repeatedValue(let values):
      return "[\(values.map { $0.asString() }.joined(separator: ", "))]"
    case .mapValue(let entries):
      let entriesString = entries.map { "\"\($0.key)\": \($0.value.asString())" }.joined(separator: ", ")
      return "{\(entriesString)}"
    case .enumValue(let name, _, _):
      return name
    }
  }

  /// Validates if the value is valid for the given field descriptor.
  ///
  /// This method checks if the current `ProtoValue` is valid for the specified field descriptor,
  /// taking into account the field type, whether it's repeated or a map, and any constraints
  /// on the field values.
  ///
  /// - Parameter fieldDescriptor: The field descriptor to validate against.
  /// - Returns: `true` if the value is valid for the field, `false` otherwise.
  public func isValid(for fieldDescriptor: ProtoFieldDescriptor) -> Bool {
    // Check if the field is a map (do this check first)
    if fieldDescriptor.isMap {
      // For map fields, we need a mapValue
      guard case .mapValue(_) = self else {
        return false
      }

      return true
    }

    // Check if the field is repeated
    if fieldDescriptor.isRepeated {
      // For repeated fields, we need a repeatedValue
      guard case .repeatedValue(let values) = self else {
        return false
      }

      // Check that all values in the repeated field are valid for the element type
      for value in values {
        // Create a non-repeated version of the field descriptor for element validation
        let elementDescriptor = ProtoFieldDescriptor(
          name: fieldDescriptor.name,
          number: fieldDescriptor.number,
          type: fieldDescriptor.type,
          isRepeated: false,
          isMap: false,
          defaultValue: fieldDescriptor.defaultValue,
          messageType: fieldDescriptor.messageType,
          enumType: fieldDescriptor.enumType
        )

        if !value.isValid(for: elementDescriptor) {
          return false
        }
      }

      return true
    }

    // For non-repeated, non-map fields, check the type
    switch fieldDescriptor.type {
    case .group:
      // Groups are not directly supported for validation
      return false
    case .int32, .sint32, .sfixed32:
      // For 32-bit integer types, ensure the value can be represented as an Int32
      if case .intValue(_) = self {
        return true
      }
      if case .uintValue(let value) = self {
        return value <= UInt(Int32.max)
      }
      if case .stringValue(let strValue) = self {
        return Int32(strValue) != nil
      }
      if case .floatValue(_) = self {
        return true
      }
      if case .doubleValue(_) = self {
        return true
      }
      return false

    case .int64, .sint64, .sfixed64:
      // For 64-bit integer types, ensure the value can be represented as an Int64
      if case .intValue(_) = self {
        return true
      }
      if case .uintValue(let value) = self {
        return value <= UInt(Int64.max)
      }
      if case .stringValue(let strValue) = self {
        return Int64(strValue) != nil
      }
      if case .floatValue(_) = self {
        return true
      }
      if case .doubleValue(_) = self {
        return true
      }
      return false

    case .uint32, .fixed32:
      // For 32-bit unsigned integer types, ensure the value can be represented as a UInt32
      if case .uintValue(_) = self {
        return true
      }
      if case .intValue(let value) = self {
        return value >= 0 && value <= Int(UInt32.max)
      }
      if case .stringValue(let strValue) = self {
        return UInt32(strValue) != nil
      }
      if case .floatValue(let value) = self {
        return value >= 0 && value <= Float(UInt32.max)
      }
      if case .doubleValue(let value) = self {
        return value >= 0 && value <= Double(UInt32.max)
      }
      return false

    case .uint64, .fixed64:
      // For 64-bit unsigned integer types, ensure the value can be represented as a UInt64
      if case .uintValue(_) = self {
        return true
      }
      if case .intValue(let value) = self {
        return value >= 0
      }
      if case .stringValue(let strValue) = self {
        return UInt64(strValue) != nil
      }
      if case .floatValue(let value) = self {
        return value >= 0
      }
      if case .doubleValue(let value) = self {
        return value >= 0
      }
      return false

    case .float:
      // For float fields, ensure the value can be represented as a Float
      if case .floatValue(_) = self {
        return true
      }
      if case .intValue(_) = self {
        return true
      }
      if case .uintValue(_) = self {
        return true
      }
      if case .doubleValue(_) = self {
        return true
      }
      if case .stringValue(let strValue) = self {
        return Float(strValue) != nil
      }
      return false

    case .double:
      // For double fields, most numeric values can be converted to Double
      if case .doubleValue(_) = self {
        return true
      }
      if case .floatValue(_) = self {
        return true
      }
      if case .intValue(_) = self {
        return true
      }
      if case .uintValue(_) = self {
        return true
      }
      if case .stringValue(let strValue) = self {
        return Double(strValue) != nil
      }
      return false

    case .bool:
      // For boolean fields, ensure the value can be represented as a Bool
      if case .boolValue(_) = self {
        return true
      }
      if case .intValue(let intValue) = self {
        return intValue == 0 || intValue == 1
      }
      if case .stringValue(let strValue) = self {
        let lowercased = strValue.lowercased()
        return lowercased == "true" || lowercased == "false" || lowercased == "1" || lowercased == "0"
      }
      return false

    case .string:
      // For string fields, we should be more strict
      // Only allow actual string values or values that can be meaningfully converted to strings
      switch self {
      case .stringValue:
        return true
      case .intValue, .uintValue, .floatValue, .doubleValue, .boolValue:
        return true  // These can be meaningfully converted to strings
      default:
        return false
      }

    case .bytes:
      // For bytes fields, ensure the value is Data or can be converted to Data
      if self.getBytes() != nil {
        return true
      }
      else if self.getString() != nil {
        // Allow any string to be converted to bytes
        return true
      }
      return false

    case .message:
      // For message fields, ensure the value is a message of the expected type
      if let message = self.getMessage() {
        // If we have a message type, check that it matches the expected type
        if let expectedType = fieldDescriptor.messageType {
          return message.descriptor().fullName == expectedType.fullName
        }
        // If no expected type is specified, any message is valid
        return true
      }
      return false

    case .enum:
      // For enum fields, ensure the value is a valid enum value for the enum type
      if let enumValue = self.getEnum() {
        // For enum values, check that the enum descriptor matches and the value is valid
        if let enumDescriptor = fieldDescriptor.enumType {
          // Check that the enum descriptors match
          if enumValue.enumDescriptor.name != enumDescriptor.name {
            return false
          }

          // Check that the enum value is valid for this enum descriptor
          return enumDescriptor.value(withNumber: enumValue.number) != nil
            || enumDescriptor.value(named: enumValue.name) != nil
        }
      }
      else if let intValue = self.getInt() {
        // Allow integer values for enums if they correspond to a valid enum number
        if let enumDescriptor = fieldDescriptor.enumType {
          return enumDescriptor.value(withNumber: intValue) != nil
        }
      }
      else if let stringValue = self.getString() {
        // Allow string values for enums if they correspond to a valid enum name
        if let enumDescriptor = fieldDescriptor.enumType {
          return enumDescriptor.value(named: stringValue) != nil
        }
      }
      return false

    case .unknown:
      return false
    }
  }

  /// Checks if a value is valid as a map key for the given field type.
  ///
  /// In Protocol Buffers, map keys can only be integral types, string, or bool.
  ///
  /// - Parameters:
  ///   - keyType: The field type of the map key.
  /// - Returns: `true` if the value is valid as a map key, `false` otherwise.
  public func isValidMapKey(for keyType: ProtoFieldType) -> Bool {
    // In Protocol Buffers, map keys can only be:
    // - string
    // - integral types (int32, int64, uint32, uint64, sint32, sint64, fixed32, fixed64, sfixed32, sfixed64)
    // - bool

    switch keyType {
    case .string:
      return self.getString() != nil || (self.getString() == nil && self.asString().isEmpty == false)

    case .int32, .int64, .sint32, .sint64, .sfixed32, .sfixed64,
      .uint32, .uint64, .fixed32, .fixed64:
      return self.getInt() != nil || self.getUInt() != nil || self.asInt32() != nil || self.asUInt32() != nil

    case .bool:
      return self.getBool() != nil || self.asBool() != nil

    default:
      // Other types are not valid as map keys in Protocol Buffers
      return false
    }
  }

  /// Returns a string representation of the value.
  public func description() -> String {
    switch self {
    case .intValue(let value):
      return "Int(\(value))"
    case .uintValue(let value):
      return "UInt(\(value))"
    case .floatValue(let value):
      return "Float(\(value))"
    case .doubleValue(let value):
      return "Double(\(value))"
    case .boolValue(let value):
      return "Bool(\(value))"
    case .stringValue(let value):
      return "String(\"\(value)\")"
    case .bytesValue(let value):
      return "Bytes(\(value.count) bytes)"
    case .messageValue(let value):
      return "Message(\(value.descriptor().fullName))"
    case .repeatedValue(let value):
      return "Repeated[\(value.count) items]"
    case .mapValue(let value):
      return "Map[\(value.count) entries]"
    case .enumValue(let name, let number, let enumDescriptor):
      return "Enum(\(enumDescriptor.name).\(name): \(number))"
    }
  }

  // MARK: - Hashable Implementation

  public func hash(into hasher: inout Hasher) {
    switch self {
    case .intValue(let value):
      hasher.combine(0)  // Tag for intValue
      hasher.combine(value)
    case .uintValue(let value):
      hasher.combine(1)  // Tag for uintValue
      hasher.combine(value)
    case .floatValue(let value):
      hasher.combine(2)  // Tag for floatValue
      hasher.combine(value)
    case .doubleValue(let value):
      hasher.combine(3)  // Tag for doubleValue
      hasher.combine(value)
    case .boolValue(let value):
      hasher.combine(4)  // Tag for boolValue
      hasher.combine(value)
    case .stringValue(let value):
      hasher.combine(5)  // Tag for stringValue
      hasher.combine(value)
    case .bytesValue(let value):
      hasher.combine(6)  // Tag for bytesValue
      hasher.combine(value)
    case .messageValue(let value):
      hasher.combine(7)  // Tag for messageValue
      // Use the descriptor's fullName as a proxy for identity
      hasher.combine(value.descriptor().fullName)
    case .repeatedValue(let value):
      hasher.combine(8)  // Tag for repeatedValue
      hasher.combine(value)
    case .mapValue(let value):
      hasher.combine(9)  // Tag for mapValue
      // Hash the keys and values separately
      var keyHash = 0
      var valueHash = 0
      for (key, val) in value {
        keyHash = keyHash ^ key.hashValue
        valueHash = valueHash ^ val.hashValue
      }
      hasher.combine(keyHash)
      hasher.combine(valueHash)
    case .enumValue(let name, let number, let enumDescriptor):
      hasher.combine(10)  // Tag for enumValue
      hasher.combine(name)
      hasher.combine(number)
      hasher.combine(enumDescriptor.name)
    }
  }

  public static func == (lhs: ProtoValue, rhs: ProtoValue) -> Bool {
    switch (lhs, rhs) {
    case (.intValue(let lhsValue), .intValue(let rhsValue)):
      return lhsValue == rhsValue
    case (.uintValue(let lhsValue), .uintValue(let rhsValue)):
      return lhsValue == rhsValue
    case (.floatValue(let lhsValue), .floatValue(let rhsValue)):
      return lhsValue == rhsValue
    case (.doubleValue(let lhsValue), .doubleValue(let rhsValue)):
      return lhsValue == rhsValue
    case (.boolValue(let lhsValue), .boolValue(let rhsValue)):
      return lhsValue == rhsValue
    case (.stringValue(let lhsValue), .stringValue(let rhsValue)):
      return lhsValue == rhsValue
    case (.bytesValue(let lhsValue), .bytesValue(let rhsValue)):
      return lhsValue == rhsValue
    case (.messageValue(let lhsValue), .messageValue(let rhsValue)):
      // Compare by descriptor fullName and identity
      return lhsValue.descriptor().fullName == rhsValue.descriptor().fullName
    case (.repeatedValue(let lhsValue), .repeatedValue(let rhsValue)):
      return lhsValue == rhsValue
    case (.mapValue(let lhsValue), .mapValue(let rhsValue)):
      return lhsValue == rhsValue
    case (
      .enumValue(let lhsName, let lhsNumber, let lhsDescriptor),
      .enumValue(let rhsName, let rhsNumber, let rhsDescriptor)
    ):
      return lhsName == rhsName && lhsNumber == rhsNumber && lhsDescriptor.name == rhsDescriptor.name
    default:
      return false
    }
  }

  /// Attempts to convert this value to a target field type.
  ///
  /// - Parameter targetType: The target type to convert to.
  /// - Returns: A new ProtoValue of the target type, or nil if conversion is not possible.
  public func convertTo(targetType: ProtoFieldType) -> ProtoValue? {
    // Create a non-repeated field descriptor for the target type
    let fieldDescriptor = ProtoFieldDescriptor(
      name: "temp",
      number: 1,
      type: targetType,
      isRepeated: false,
      isMap: false
    )
    return convertTo(fieldDescriptor: fieldDescriptor)
  }

  /// Attempts to convert this value to a target field type.
  ///
  /// - Parameter fieldDescriptor: The target field descriptor to convert to.
  /// - Returns: A new ProtoValue of the target type, or nil if conversion is not possible.
  public func convertTo(fieldDescriptor: ProtoFieldDescriptor) -> ProtoValue? {
    // For repeated fields, only allow repeated values
    if fieldDescriptor.isRepeated {
      if case .repeatedValue(let values) = self {
        // Check if all elements can be converted to the target type
        for value in values {
          if value.convertTo(targetType: fieldDescriptor.type) == nil {
            return nil
          }
        }
        return self
      }
      return nil
    }

    // For non-repeated values, only allow conversion to non-repeated field types
    if case .repeatedValue = self {
      return nil
    }

    // For map fields, only allow map values
    if fieldDescriptor.isMap {
      if case .mapValue = self {
        return self
      }
      return nil
    }

    // Handle non-repeated, non-map field types
    switch self {
    case .intValue(_):
      switch fieldDescriptor.type {
      case .int32, .int64, .sint32, .sint64, .sfixed32, .sfixed64:
        return self
      default:
        return nil
      }
      
    case .uintValue(_):
      switch fieldDescriptor.type {
      case .uint32, .uint64, .fixed32, .fixed64:
        return self
      default:
        return nil
      }
      
    case .floatValue(_):
      switch fieldDescriptor.type {
      case .float:
        return self
      default:
        return nil
      }
      
    case .doubleValue(_):
      switch fieldDescriptor.type {
      case .double:
        return self
      default:
        return nil
      }
      
    case .boolValue(_):
      switch fieldDescriptor.type {
      case .bool:
        return self
      default:
        return nil
      }
      
    case .stringValue(_):
      switch fieldDescriptor.type {
      case .string:
        return self
      default:
        return nil
      }
      
    case .bytesValue(_):
      switch fieldDescriptor.type {
      case .bytes:
        return self
      default:
        return nil
      }
      
    case .enumValue(_, let number, let enumDescriptor):
      switch fieldDescriptor.type {
      case .enum(let targetDescriptor):
        if let targetDescriptor = targetDescriptor, targetDescriptor.name == enumDescriptor.name {
          return self
        }
        return nil
      case .int32, .int64, .sint32, .sint64, .sfixed32, .sfixed64:
        // Enums can be converted to integers since they are stored as integers internally
        return .intValue(number)
      default:
        return nil
      }
      
    case .messageValue(let message):
      switch fieldDescriptor.type {
      case .message(let targetDescriptor):
        if let targetDescriptor = targetDescriptor,
           message.descriptor().fullName == targetDescriptor.fullName {
          return self
        }
        return nil
      case .string:
        // Messages can be converted to strings for display purposes
        return .stringValue("Message(\(message.descriptor().fullName))")
      default:
        return nil
      }
      
    case .mapValue:
      // Map values are handled above
      return nil
      
    case .repeatedValue:
      // Repeated values are handled above
      return nil
    }
  }

  /// Attempts to convert the value to a Swift Any type that best represents it.
  ///
  /// This method converts the ProtoValue to a native Swift type like Int, String, Bool, etc.
  ///
  /// - Returns: A Swift Any value representing this ProtoValue.
  public func toSwiftValue() -> Any {
    switch self {
    case .intValue(let value):
      return value
    case .uintValue(let value):
      return value
    case .floatValue(let value):
      return value
    case .doubleValue(let value):
      return value
    case .boolValue(let value):
      return value
    case .stringValue(let value):
      return value
    case .bytesValue(let value):
      return value
    case .messageValue(let value):
      // For messages, we can't easily convert to a Swift type
      // Return a description instead
      return "Message(\(value.descriptor().fullName))"
    case .repeatedValue(let values):
      // Convert each element to a Swift value
      return values.map { $0.toSwiftValue() }
    case .mapValue(let entries):
      // Convert each value to a Swift value
      var result: [String: Any] = [:]
      for (key, value) in entries {
        result[key] = value.toSwiftValue()
      }
      return result
    case .enumValue(let name, let number, _):
      // For enums, return a tuple with the name and number
      return (name: name, number: number)
    }
  }

  /// Creates a ProtoValue from a Swift value and target field type.
  ///
  /// This method attempts to convert a Swift value to a ProtoValue of the specified type.
  ///
  /// - Parameters:
  ///   - value: The Swift value to convert.
  ///   - targetType: The target Protocol Buffer field type.
  /// - Returns: A ProtoValue of the target type, or nil if conversion is not possible.
  public static func from(swiftValue: Any, targetType: ProtoFieldType) -> ProtoValue? {
    switch targetType {
    case .int32, .int64, .sint32, .sint64, .sfixed32, .sfixed64:
        if let intValue = swiftValue as? Int {
            return .intValue(intValue)
        }
        if let int32Value = swiftValue as? Int32 {
            return .intValue(Int(int32Value))
        }
        if let int64Value = swiftValue as? Int64 {
            return .intValue(Int(int64Value))
        }
        return nil

    case .uint32, .uint64, .fixed32, .fixed64:
        if let uintValue = swiftValue as? UInt {
            return .uintValue(uintValue)
        }
        if let uint32Value = swiftValue as? UInt32 {
            return .uintValue(UInt(uint32Value))
        }
        if let uint64Value = swiftValue as? UInt64 {
            return .uintValue(UInt(uint64Value))
        }
        return nil

    case .float:
        if let floatValue = swiftValue as? Float {
            return .floatValue(floatValue)
        }
        if let doubleValue = swiftValue as? Double {
            return .floatValue(Float(doubleValue))
        }
        return nil

    case .double:
        if let doubleValue = swiftValue as? Double {
            return .doubleValue(doubleValue)
        }
        if let floatValue = swiftValue as? Float {
            return .doubleValue(Double(floatValue))
        }
        return nil

    case .bool:
        if let boolValue = swiftValue as? Bool {
            return .boolValue(boolValue)
        }
        return nil

    case .string:
        return .stringValue(String(describing: swiftValue))

    case .bytes:
        if let dataValue = swiftValue as? Data {
            return .bytesValue(dataValue)
        }
        return nil

    case .enum:
        // Handle enum values
        return nil

    case .message:
        // Handle message values
        return nil

    case .group:
        // Handle group values
        return nil

    case .unknown:
        return nil
    }
  }
}
