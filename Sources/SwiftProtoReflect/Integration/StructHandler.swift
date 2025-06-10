/**
 * StructHandler.swift
 * SwiftProtoReflect
 *
 * Handler for google.protobuf.Struct - dynamic JSON-like structures
 */

import Foundation
import SwiftProtobuf

// MARK: - Struct Handler

/// Handler for google.protobuf.Struct.
public struct StructHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.structType
  public static let supportPhase: WellKnownSupportPhase = .important

  // MARK: - Struct Representation

  /// Specialized representation of Struct.
  public struct StructValue: Equatable, CustomStringConvertible {

    /// Structure fields.
    public let fields: [String: ValueValue]

    /// Initialization with structure fields.
    /// - Parameter fields: Dictionary of structure fields.
    public init(fields: [String: ValueValue] = [:]) {
      self.fields = fields
    }

    /// Initialization from Dictionary<String, Any>.
    /// - Parameter dictionary: Dictionary with arbitrary values.
    /// - Throws: WellKnownTypeError if conversion is impossible.
    public init(from dictionary: [String: Any]) throws {
      var convertedFields: [String: ValueValue] = [:]

      for (key, value) in dictionary {
        convertedFields[key] = try ValueValue(from: value)
      }

      self.fields = convertedFields
    }

    /// Creates empty structure.
    /// - Returns: StructValue without fields.
    public static func empty() -> StructValue {
      return StructValue()
    }

    /// Checks if structure contains specified key.
    /// - Parameter key: Key to check.
    /// - Returns: true if key is present in structure.
    public func contains(_ key: String) -> Bool {
      return fields[key] != nil
    }

    /// Gets value by key.
    /// - Parameter key: Field key.
    /// - Returns: ValueValue or nil if key not found.
    public func getValue(_ key: String) -> ValueValue? {
      return fields[key]
    }

    /// Creates new structure with added field.
    /// - Parameters:
    ///   - key: Field key.
    ///   - value: Field value.
    /// - Returns: New StructValue with added field.
    public func adding(_ key: String, value: ValueValue) -> StructValue {
      var newFields = fields
      newFields[key] = value
      return StructValue(fields: newFields)
    }

    /// Creates new structure without specified field.
    /// - Parameter key: Field key to remove.
    /// - Returns: New StructValue without specified field.
    public func removing(_ key: String) -> StructValue {
      var newFields = fields
      newFields.removeValue(forKey: key)
      return StructValue(fields: newFields)
    }

    /// Merges two structures.
    /// - Parameter other: Other structure to merge.
    /// - Returns: New StructValue with merged fields (values from other overwrite values from self).
    public func merging(_ other: StructValue) -> StructValue {
      var newFields = fields
      for (key, value) in other.fields {
        newFields[key] = value
      }
      return StructValue(fields: newFields)
    }

    /// Converts to Dictionary<String, Any>.
    /// - Returns: Dictionary with arbitrary values.
    public func toDictionary() -> [String: Any] {
      var result: [String: Any] = [:]
      for (key, value) in fields {
        result[key] = value.toAny()
      }
      return result
    }

    public var description: String {
      if fields.isEmpty {
        return "Struct(empty)"
      }

      let fieldStrings = fields.map { "\($0.key): \($0.value)" }.sorted()
      return "Struct({\(fieldStrings.joined(separator: ", "))})"
    }
  }

  // MARK: - Value Representation

  /// Specialized representation for google.protobuf.Value.
  public enum ValueValue: Equatable, CustomStringConvertible {
    case nullValue
    case numberValue(Double)
    case stringValue(String)
    case boolValue(Bool)
    case structValue(StructValue)
    case listValue([ValueValue])

    /// Initialization from arbitrary Swift value.
    /// - Parameter value: Arbitrary value for conversion.
    /// - Throws: WellKnownTypeError if type is not supported.
    public init(from value: Any) throws {
      switch value {
      case is NSNull:
        self = .nullValue
      case let number as NSNumber:
        // NSNumber can represent both Bool and Number
        #if canImport(CoreFoundation) && !os(Linux)
          if CFGetTypeID(number) == CFBooleanGetTypeID() {
            self = .boolValue(number.boolValue)
          }
          else {
            self = .numberValue(number.doubleValue)
          }
        #else
          // Cross-platform compatible way to detect boolean NSNumber on Linux
          let objCType = String(cString: number.objCType)
          if objCType == "c" || objCType == "B" {  // char or Bool
            self = .boolValue(number.boolValue)
          }
          else {
            self = .numberValue(number.doubleValue)
          }
        #endif
      case let bool as Bool:
        self = .boolValue(bool)
      case let int as Int:
        self = .numberValue(Double(int))
      case let int32 as Int32:
        self = .numberValue(Double(int32))
      case let int64 as Int64:
        self = .numberValue(Double(int64))
      case let uint as UInt:
        self = .numberValue(Double(uint))
      case let uint32 as UInt32:
        self = .numberValue(Double(uint32))
      case let uint64 as UInt64:
        self = .numberValue(Double(uint64))
      case let float as Float:
        self = .numberValue(Double(float))
      case let double as Double:
        self = .numberValue(double)
      case let string as String:
        self = .stringValue(string)
      case let dict as [String: Any]:
        let structValue = try StructValue(from: dict)
        self = .structValue(structValue)
      case let array as [Any]:
        let listValues = try array.map { try ValueValue(from: $0) }
        self = .listValue(listValues)
      default:
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.value,
          reason: "Unsupported value type: \(type(of: value))"
        )
      }
    }

    /// Converts to arbitrary Swift value.
    /// - Returns: Arbitrary value.
    public func toAny() -> Any {
      switch self {
      case .nullValue:
        return NSNull()
      case .numberValue(let number):
        return number
      case .stringValue(let string):
        return string
      case .boolValue(let bool):
        return bool
      case .structValue(let structValue):
        return structValue.toDictionary()
      case .listValue(let list):
        return list.map { $0.toAny() }
      }
    }

    public var description: String {
      switch self {
      case .nullValue:
        return "null"
      case .numberValue(let number):
        return String(number)
      case .stringValue(let string):
        return "\"\(string)\""
      case .boolValue(let bool):
        return String(bool)
      case .structValue(let structValue):
        return structValue.description
      case .listValue(let list):
        let elements = list.map { $0.description }
        return "[\(elements.joined(separator: ", "))]"
      }
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    // Check message type
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    // Extract fields field as Data and deserialize JSON
    let fieldsValue: [String: Any]

    do {
      if try message.hasValue(forField: "fields") {
        let value = try message.get(forField: "fields")

        if let data = value as? Data {
          // Deserialize JSON data
          let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
          if let dict = jsonObject as? [String: Any] {
            fieldsValue = dict
          }
          else {
            fieldsValue = [:]
          }
        }
        else {
          fieldsValue = [:]
        }
      }
      else {
        fieldsValue = [:]
      }
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "StructValue",
        reason: "Failed to extract fields: \(error.localizedDescription)"
      )
    }

    // Create StructValue
    return try StructValue(from: fieldsValue)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let structValue = specialized as? StructValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected StructValue"
      )
    }

    // Create descriptor for Struct
    let structDescriptor = createStructDescriptor()

    // Create message
    let factory = MessageFactory()
    var message = factory.createMessage(from: structDescriptor)

    // Serialize fields to JSON and save as Data
    let fieldsDict = structValue.toDictionary()

    do {
      let jsonData = try JSONSerialization.data(withJSONObject: fieldsDict, options: [])
      try message.set(jsonData, forField: "fields")
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "StructValue",
        to: "DynamicMessage",
        reason: "Failed to serialize fields: \(error.localizedDescription)"
      )
    }

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    return specialized is StructValue
  }

  // MARK: - Descriptor Creation

  /// Creates descriptor for google.protobuf.Struct.
  /// - Returns: MessageDescriptor for Struct.
  private static func createStructDescriptor() -> MessageDescriptor {
    // Create file descriptor
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/struct.proto",
      package: "google.protobuf"
    )

    // Create Struct message descriptor
    var messageDescriptor = MessageDescriptor(
      name: "Struct",
      parent: fileDescriptor
    )

    // Add fields field as bytes for storing JSON serialized data
    // This is simplified version for dynamic structure support
    let fieldsField = FieldDescriptor(
      name: "fields",
      number: 1,
      type: .bytes  // Store JSON as binary data
    )
    messageDescriptor.addField(fieldsField)

    // Register in file
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

extension Dictionary where Key == String, Value == Any {

  /// Creates StructValue from dictionary.
  /// - Returns: StructValue.
  /// - Throws: WellKnownTypeError if conversion is impossible.
  public func toStructValue() throws -> StructHandler.StructValue {
    return try StructHandler.StructValue(from: self)
  }
}

extension DynamicMessage {

  /// Creates DynamicMessage from dictionary for google.protobuf.Struct.
  /// - Parameter fields: Structure fields.
  /// - Returns: DynamicMessage representing Struct.
  /// - Throws: WellKnownTypeError.
  public static func structMessage(from fields: [String: Any]) throws -> DynamicMessage {
    let structValue = try StructHandler.StructValue(from: fields)
    return try StructHandler.createDynamic(from: structValue)
  }

  /// Converts DynamicMessage to dictionary (if it's Struct).
  /// - Returns: Dictionary of structure fields.
  /// - Throws: WellKnownTypeError if message is not Struct.
  public func toFieldsDictionary() throws -> [String: Any] {
    guard descriptor.fullName == WellKnownTypeNames.structType else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a Struct"
      )
    }

    let structValue = try StructHandler.createSpecialized(from: self) as! StructHandler.StructValue
    return structValue.toDictionary()
  }
}
