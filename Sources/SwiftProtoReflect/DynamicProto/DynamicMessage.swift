import Foundation
import SwiftProtobuf

/// A dynamic message that can be modified at runtime using field descriptors
public class DynamicMessage: ProtoMessage {
  /// The descriptor defining the message structure
  private let messageDescriptor: ProtoMessageDescriptor

  /// Storage for field values
  private var fields: [Int: ProtoValue] = [:]

  /// Creates a new dynamic message with the given descriptor
  /// - Parameter descriptor: The descriptor defining the message structure
  public init(descriptor: ProtoMessageDescriptor) {
    self.messageDescriptor = descriptor
  }

  /// Returns the descriptor of the message
  public func descriptor() -> ProtoMessageDescriptor {
    return messageDescriptor
  }

  /// Gets a field value
  public func get(field: ProtoFieldDescriptor) -> ProtoValue? {
    return fields[field.number]
  }

  /// Sets a field value
  @discardableResult
  public func set(field: ProtoFieldDescriptor, value: ProtoValue) -> Bool {
    fields[field.number] = value
    return true
  }

  /// Clears a field value
  @discardableResult
  public func clear(field: ProtoFieldDescriptor) -> Bool {
    fields.removeValue(forKey: field.number)
    return true
  }

  /// Checks if message is valid
  public func isValid() -> Bool {
    return true  // TODO: Implement validation
  }

  /// Sets a value for a field by number
  public func setValue(_ value: Any, forField fieldNumber: Int) {
    guard let field = messageDescriptor.field(number: fieldNumber) else { return }

    // Convert value to ProtoValue
    let protoValue: ProtoValue
    switch value {
    case let intValue as Int:
      protoValue = .intValue(intValue)
    case let uintValue as UInt:
      protoValue = .uintValue(uintValue)
    case let floatValue as Float:
      protoValue = .floatValue(floatValue)
    case let doubleValue as Double:
      protoValue = .doubleValue(doubleValue)
    case let boolValue as Bool:
      protoValue = .boolValue(boolValue)
    case let stringValue as String:
      protoValue = .stringValue(stringValue)
    case let dataValue as Data:
      protoValue = .bytesValue(dataValue)
    case let messageValue as ProtoMessage:
      protoValue = .messageValue(messageValue)
    case let arrayValue as [Any]:
      let values = arrayValue.compactMap { self.convertToProtoValue($0) }
      protoValue = .repeatedValue(values)
    case let dictValue as [String: Any]:
      let values = dictValue.mapValues { self.convertToProtoValue($0) ?? .stringValue("") }
      protoValue = .mapValue(values)
    default:
      return
    }

    _ = set(field: field, value: protoValue)
  }

  /// Gets a value for a field by number
  public func getValue(forField fieldNumber: Int) -> Any? {
    guard let field = messageDescriptor.field(number: fieldNumber),
      let value = get(field: field)
    else { return nil }
    return value.toSwiftValue()
  }

  /// Adds a value to a repeated field
  public func addRepeatedValue(_ value: Any, forField fieldNumber: Int) {
    guard let field = messageDescriptor.field(number: fieldNumber),
      field.isRepeated
    else { return }

    let protoValue = convertToProtoValue(value) ?? .stringValue("")

    if case .repeatedValue(var values) = fields[field.number] ?? .repeatedValue([]) {
      values.append(protoValue)
      fields[field.number] = .repeatedValue(values)
    }
  }

  /// Gets all values from a repeated field
  public func getRepeatedValues(forField fieldNumber: Int) -> [Any]? {
    guard let field = messageDescriptor.field(number: fieldNumber),
      field.isRepeated,
      case .repeatedValue(let values) = fields[field.number] ?? .repeatedValue([])
    else {
      return nil
    }
    return values.map { $0.toSwiftValue() }
  }

  /// Sets a key-value pair in a map field
  public func setMapEntry(_ key: Any, value: Any, forField fieldNumber: Int) {
    guard let field = messageDescriptor.field(number: fieldNumber),
      field.isMap,
      let stringKey = key as? String
    else { return }

    let protoValue = convertToProtoValue(value) ?? .stringValue("")

    if case .mapValue(var entries) = fields[field.number] ?? .mapValue([:]) {
      entries[stringKey] = protoValue
      fields[field.number] = .mapValue(entries)
    }
  }

  /// Gets all entries from a map field
  public func getMapEntries(forField fieldNumber: Int) -> [AnyHashable: Any]? {
    guard let field = messageDescriptor.field(number: fieldNumber),
      field.isMap,
      case .mapValue(let entries) = fields[field.number] ?? .mapValue([:])
    else {
      return nil
    }
    return entries.mapValues { $0.toSwiftValue() }
  }

  /// Sets multiple values for a repeated field
  public func setRepeatedValues(_ values: [Any], forField fieldNumber: Int) {
    guard let field = messageDescriptor.field(number: fieldNumber),
      field.isRepeated
    else { return }

    let protoValues = values.compactMap { convertToProtoValue($0) }
    fields[field.number] = .repeatedValue(protoValues)
  }

  /// Helper to convert Any to ProtoValue
  private func convertToProtoValue(_ value: Any) -> ProtoValue? {
    switch value {
    case let intValue as Int:
      return .intValue(intValue)
    case let uintValue as UInt:
      return .uintValue(uintValue)
    case let floatValue as Float:
      return .floatValue(floatValue)
    case let doubleValue as Double:
      return .doubleValue(doubleValue)
    case let boolValue as Bool:
      return .boolValue(boolValue)
    case let stringValue as String:
      return .stringValue(stringValue)
    case let dataValue as Data:
      return .bytesValue(dataValue)
    case let messageValue as ProtoMessage:
      return .messageValue(messageValue)
    default:
      return nil
    }
  }
}
