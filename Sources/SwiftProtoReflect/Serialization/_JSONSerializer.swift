//
// _JSONSerializer.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation

internal struct _JSONSerializer {

  // MARK: - Properties

  let options: _JSONSerializationOptions

  // MARK: - Serialization Methods

  func serialize(_ message: _DynamicMessage) throws -> Data {
    let jsonValue = try serializeMessageToAny(message)

    var writingOptions: JSONSerialization.WritingOptions = .fragmentsAllowed
    if self.options.prettyPrinted {
      writingOptions.insert(.prettyPrinted)
    }
    if !self.options.escapeSlashesInStrings {
      writingOptions.insert(.withoutEscapingSlashes)
    }
    if self.options.sortJSONObjectKeys {
      writingOptions.insert(.sortedKeys)
    }

    do {
      return try JSONSerialization.data(withJSONObject: jsonValue, options: writingOptions)
    }
    catch {
      throw _JSONSerializationError.jsonWriteError(underlyingError: error)
    }
  }

  internal func serializeMessageToAny(_ message: _DynamicMessage) throws -> Any {
    let fullName = message.descriptor.fullName
    guard options.useCanonicalWellKnownTypeEncoding,
      WellKnownTypeDetector.isWellKnownType(fullName)
    else {
      return try serializeToJSONObject(message)
    }
    return try encodeWellKnownType(message, fullName: fullName)
  }

  private func encodeWellKnownType(_ message: _DynamicMessage, fullName: String) throws -> Any {
    switch fullName {
    case WellKnownTypeNames.empty:
      return [String: Any]()
    case WellKnownTypeNames.timestamp:
      return try encodeTimestampMessage(message)
    case WellKnownTypeNames.duration:
      return try encodeDurationMessage(message)
    case WellKnownTypeNames.fieldMask:
      return try encodeFieldMaskMessage(message)
    case WellKnownTypeNames.value:
      return try encodeValueMessage(message)
    case WellKnownTypeNames.structType:
      return try encodeStructMessage(message)
    case WellKnownTypeNames.listValue:
      return try encodeListValueMessage(message)
    case WellKnownTypeNames.any:
      return try encodeAnyMessage(message)
    case WellKnownTypeNames.doubleValue,
      WellKnownTypeNames.floatValue,
      WellKnownTypeNames.int32Value,
      WellKnownTypeNames.uint32Value,
      WellKnownTypeNames.int64Value,
      WellKnownTypeNames.uint64Value,
      WellKnownTypeNames.boolValue,
      WellKnownTypeNames.stringValue,
      WellKnownTypeNames.bytesValue:
      return try encodeWrapperMessage(message, fullName: fullName)
    default:
      throw _JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: fullName)
    }
  }

  private func encodeWrapperMessage(_ message: _DynamicMessage, fullName: String) throws -> Any {
    let rawValue = try? message.get(forField: 1)

    switch fullName {
    case WellKnownTypeNames.int64Value:
      let v = rawValue as? Int64 ?? 0
      return String(v)
    case WellKnownTypeNames.uint64Value:
      let v = rawValue as? UInt64 ?? 0
      return String(v)
    case WellKnownTypeNames.bytesValue:
      let v = rawValue as? Data ?? Data()
      return v.base64EncodedString()
    case WellKnownTypeNames.doubleValue:
      let v = rawValue as? Double ?? 0.0
      return convertDoubleToJSON(v)
    case WellKnownTypeNames.floatValue:
      let v = rawValue as? Float ?? 0.0
      return convertDoubleToJSON(Double(v))
    case WellKnownTypeNames.int32Value:
      return rawValue as? Int32 ?? Int32(0)
    case WellKnownTypeNames.uint32Value:
      return rawValue as? UInt32 ?? UInt32(0)
    case WellKnownTypeNames.boolValue:
      return rawValue as? Bool ?? false
    default:
      return rawValue as? String ?? ""
    }
  }

  private func encodeTimestampMessage(_ message: _DynamicMessage) throws -> Any {
    let seconds = (try? message.get(forField: 1) as? Int64) ?? 0
    let nanos = (try? message.get(forField: 2) as? Int32) ?? 0

    let date = Date(timeIntervalSince1970: Double(seconds))
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")!
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    let base = formatter.string(from: date)

    if nanos == 0 {
      return "\(base)Z"
    }
    else if nanos % 1_000_000 == 0 {
      return String(format: "\(base).%03dZ", nanos / 1_000_000)
    }
    else if nanos % 1_000 == 0 {
      return String(format: "\(base).%06dZ", nanos / 1_000)
    }
    else {
      return String(format: "\(base).%09dZ", nanos)
    }
  }

  private func encodeDurationMessage(_ message: _DynamicMessage) throws -> Any {
    let seconds = (try? message.get(forField: 1) as? Int64) ?? 0
    let nanos = (try? message.get(forField: 2) as? Int32) ?? 0

    let isNegative = seconds < 0 || (seconds == 0 && nanos < 0)
    let absSeconds: Int64 = seconds < 0 ? -seconds : seconds
    let absNanos: Int32 = nanos < 0 ? -nanos : nanos
    let sign = isNegative ? "-" : ""

    if absNanos == 0 {
      return "\(sign)\(absSeconds)s"
    }
    var fracStr = String(format: "%09d", absNanos)
    while fracStr.last == "0" { fracStr.removeLast() }
    return "\(sign)\(absSeconds).\(fracStr)s"
  }

  private func encodeFieldMaskMessage(_ message: _DynamicMessage) throws -> Any {
    let paths = (try? message.get(forField: 1) as? [String]) ?? []
    let camelPaths = paths.map { snakeToCamelCase($0) }
    return camelPaths.joined(separator: ",")
  }

  private func snakeToCamelCase(_ snake: String) -> String {
    let parts = snake.split(separator: "_", omittingEmptySubsequences: false)
    guard !parts.isEmpty else { return snake }
    var result = parts[0].lowercased()
    for part in parts.dropFirst() {
      if let first = part.first {
        result += String(first).uppercased() + String(part.dropFirst()).lowercased()
      }
    }
    return result
  }

  private func encodeAnyMessage(_ message: _DynamicMessage) throws -> Any {
    let typeUrl = (try? message.get(forField: 1) as? String) ?? ""
    let valueBytes = (try? message.get(forField: 2) as? Data) ?? Data()

    guard !typeUrl.isEmpty, let slashIdx = typeUrl.lastIndex(of: "/") else {
      return try serializeToJSONObject(message)
    }
    let typeName = String(typeUrl[typeUrl.index(after: slashIdx)...])

    guard let packedDescriptor = options.typeRegistry.findMessage(named: typeName) else {
      return try serializeToJSONObject(message)
    }

    let packedMessage = try _BinaryDeserializer(
      options: _DeserializationOptions(typeRegistry: options.typeRegistry)
    ).deserialize(valueBytes, using: packedDescriptor)

    if WellKnownTypeDetector.isWellKnownType(typeName) {
      let canonicalValue = try encodeWellKnownType(packedMessage, fullName: typeName)
      return ["@type": typeUrl, "value": canonicalValue]
    }

    var jsonObject = try serializeToJSONObject(packedMessage)
    jsonObject["@type"] = typeUrl
    return jsonObject
  }

  private func encodeValueMessage(_ message: _DynamicMessage) throws -> Any {
    if (try? message.hasValue(forField: 1)) == true {
      return NSNull()
    }
    if (try? message.hasValue(forField: 2)) == true {
      guard let d = try message.get(forField: 2) as? Double else {
        throw _JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.value)
      }
      return convertDoubleToJSON(d)
    }
    if (try? message.hasValue(forField: 3)) == true {
      guard let s = try message.get(forField: 3) as? String else {
        throw _JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.value)
      }
      return s
    }
    if (try? message.hasValue(forField: 4)) == true {
      guard let b = try message.get(forField: 4) as? Bool else {
        throw _JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.value)
      }
      return b
    }
    if (try? message.hasValue(forField: 5)) == true {
      let raw = try message.get(forField: 5)
      let nested: _DynamicMessage
      if let m = raw as? _DynamicMessage {
        nested = m
        // TODO(Strangler migration / OPE-302): Remove once internal storage never holds public DynamicMessage.
      }
      else if let pub = raw as? DynamicMessage {
        nested = _DynamicMessage(from: pub)
      }
      else {
        throw _JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.value)
      }
      return try encodeStructMessage(nested)
    }
    if (try? message.hasValue(forField: 6)) == true {
      let raw = try message.get(forField: 6)
      let nested: _DynamicMessage
      if let m = raw as? _DynamicMessage {
        nested = m
        // TODO(Strangler migration / OPE-302): Remove once internal storage never holds public DynamicMessage.
      }
      else if let pub = raw as? DynamicMessage {
        nested = _DynamicMessage(from: pub)
      }
      else {
        throw _JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.value)
      }
      return try encodeListValueMessage(nested)
    }
    return NSNull()
  }

  private func encodeStructMessage(_ message: _DynamicMessage) throws -> [String: Any] {
    let rawMap = (try? message.get(forField: 1) as? [AnyHashable: Any]) ?? [:]
    var result: [String: Any] = [:]
    for (key, value) in rawMap {
      guard let stringKey = key as? String else { continue }
      let valueMsg: _DynamicMessage
      if let m = value as? _DynamicMessage {
        valueMsg = m
        // TODO(Strangler migration / OPE-302): Remove once internal storage never holds public DynamicMessage.
      }
      else if let pub = value as? DynamicMessage {
        valueMsg = _DynamicMessage(from: pub)
      }
      else {
        continue
      }
      result[stringKey] = try encodeValueMessage(valueMsg)
    }
    return result
  }

  private func encodeListValueMessage(_ message: _DynamicMessage) throws -> [Any] {
    let rawList = (try? message.get(forField: 1) as? [Any]) ?? []
    return try rawList.map { item -> Any in
      let valueMsg: _DynamicMessage
      if let m = item as? _DynamicMessage {
        valueMsg = m
        // TODO(Strangler migration / OPE-302): Remove once internal storage never holds public DynamicMessage.
      }
      else if let pub = item as? DynamicMessage {
        valueMsg = _DynamicMessage(from: pub)
      }
      else {
        throw _JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.listValue)
      }
      return try encodeValueMessage(valueMsg)
    }
  }

  internal func serializeToJSONObject(_ message: _DynamicMessage) throws -> [String: Any] {
    var result: [String: Any] = [:]

    let descriptor = message.descriptor
    let fieldAccess = _FieldAccessor(message)

    var allFields = descriptor.allFields()
    allFields.append(contentsOf: descriptor.extensions.values)

    for field in allFields {
      let hasValue = fieldAccess.hasValue(field.number)
      let fieldName = options.useOriginalFieldNames ? field.name : field.jsonName

      if hasValue {
        if !options.includeDefaultValues
          && isProto3ImplicitPresenceScalar(field)
          && isProto3ScalarDefault(fieldAccess.getValue(field.number, as: Any.self), type: field.type)
        {
          continue
        }
        result[fieldName] = try serializeFieldValue(field, from: fieldAccess, descriptor: descriptor)
      }
      else if options.includeDefaultValues {
        if field.proto3Optional { continue }
        if case .message = field.type, !field.isMap { continue }

        result[fieldName] = proto3DefaultJSON(for: field, in: descriptor)
      }
    }

    return result
  }

  private func isProto3ImplicitPresenceScalar(_ field: _FieldDescriptor) -> Bool {
    guard !field.proto3Optional, !field.isRequired, !field.isOptional,
      !field.isRepeated, !field.isMap,
      field.oneofIndex == nil
    else { return false }
    switch field.type {
    case .message, .group, .enum: return false
    default: return true
    }
  }

  private func isProto3ScalarDefault(_ value: Any?, type: _FieldType) -> Bool {
    guard let value else { return true }
    switch type {
    case .double: return (value as? Double) == 0.0
    case .float: return (value as? Float) == 0.0
    case .int32, .sint32, .sfixed32: return (value as? Int32) == 0
    case .int64, .sint64, .sfixed64: return (value as? Int64) == 0
    case .uint32, .fixed32: return (value as? UInt32) == 0
    case .uint64, .fixed64: return (value as? UInt64) == 0
    case .bool: return (value as? Bool) == false
    case .string: return (value as? String) == ""
    case .bytes: return (value as? Data)?.isEmpty == true
    case .enum: return (value as? Int32) == 0
    case .message, .group: return false
    }
  }

  private func resolveEnumDescriptor(
    for field: _FieldDescriptor,
    in descriptor: _MessageDescriptor
  ) -> _EnumDescriptor? {
    guard case .enum = field.type, let typeName = field.typeName else { return nil }
    let normalized = typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
    if let desc = options.typeRegistry.findEnum(named: normalized) {
      return desc
    }
    // DEPRECATED: Legacy structural nesting fallback. Will be removed in a future major version.
    let simpleName = typeName.split(separator: ".").last.map(String.init) ?? typeName
    return descriptor.nestedEnums[simpleName]
  }

  private func proto3DefaultJSON(for field: _FieldDescriptor, in descriptor: _MessageDescriptor) -> Any {
    if field.isMap {
      return [String: Any]()
    }
    if field.isRepeated {
      return [Any]()
    }
    switch field.type {
    case .double, .float: return 0
    case .int32, .sint32, .sfixed32, .uint32, .fixed32: return 0
    case .int64, .sint64, .sfixed64, .uint64, .fixed64: return "0"
    case .bool: return false
    case .string: return ""
    case .bytes: return ""
    case .enum:
      if let enumDesc = resolveEnumDescriptor(for: field, in: descriptor),
        let zeroVal = enumDesc.valuesByNumber[0]
      {
        return zeroVal.name
      }
      return 0
    case .message, .group: return NSNull()
    }
  }

  // MARK: - Private Methods

  private func serializeFieldValue(
    _ field: _FieldDescriptor,
    from fieldAccess: _FieldAccessor,
    descriptor: _MessageDescriptor
  ) throws -> Any {
    if field.isMap {
      return try serializeMapField(field, from: fieldAccess, descriptor: descriptor)
    }
    else if field.isRepeated {
      return try serializeRepeatedField(field, from: fieldAccess, descriptor: descriptor)
    }
    else {
      return try serializeSingleField(field, from: fieldAccess, descriptor: descriptor)
    }
  }

  private func serializeSingleField(
    _ field: _FieldDescriptor,
    from fieldAccess: _FieldAccessor,
    descriptor: _MessageDescriptor
  ) throws -> Any {
    guard let value = fieldAccess.getValue(field.number, as: Any.self) else {
      throw _JSONSerializationError.missingFieldValue(fieldName: field.name)
    }

    let enumDesc = resolveEnumDescriptor(for: field, in: descriptor)
    return try convertValueToJSON(value, type: field.type, typeName: field.typeName, enumDescriptor: enumDesc)
  }

  private func serializeRepeatedField(
    _ field: _FieldDescriptor,
    from fieldAccess: _FieldAccessor,
    descriptor: _MessageDescriptor
  ) throws -> Any {
    guard let values = fieldAccess.getValue(field.number, as: [Any].self) else {
      throw _JSONSerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Array",
        actualType: String(describing: type(of: fieldAccess.getValue(field.number, as: Any.self)))
      )
    }

    let enumDesc = resolveEnumDescriptor(for: field, in: descriptor)
    var jsonArray: [Any] = []
    for value in values {
      let jsonValue = try convertValueToJSON(
        value,
        type: field.type,
        typeName: field.typeName,
        enumDescriptor: enumDesc
      )
      jsonArray.append(jsonValue)
    }

    return jsonArray
  }

  private func serializeMapField(
    _ field: _FieldDescriptor,
    from fieldAccess: _FieldAccessor,
    descriptor: _MessageDescriptor
  ) throws -> Any {
    guard let mapEntryInfo = field.mapEntryInfo else {
      throw _JSONSerializationError.missingMapEntryInfo(fieldName: field.name)
    }

    guard let mapValues = fieldAccess.getValue(field.number, as: [AnyHashable: Any].self) else {
      throw _JSONSerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Dictionary",
        actualType: String(describing: type(of: fieldAccess.getValue(field.number, as: Any.self)))
      )
    }

    var jsonObject: [String: Any] = [:]

    let enumDesc: _EnumDescriptor? = {
      guard case .enum = mapEntryInfo.valueFieldInfo.type,
        let typeName = mapEntryInfo.valueFieldInfo.typeName
      else { return nil }
      let normalized = typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
      if let desc = options.typeRegistry.findEnum(named: normalized) {
        return desc
      }
      // DEPRECATED: Legacy structural nesting fallback. Will be removed in a future major version.
      let simpleName = typeName.split(separator: ".").last.map(String.init) ?? typeName
      return descriptor.nestedEnums[simpleName]
    }()

    for (key, value) in mapValues {
      let jsonKey = try convertMapKeyToJSONString(key, keyType: mapEntryInfo.keyFieldInfo.type)
      let jsonValue = try convertValueToJSON(
        value,
        type: mapEntryInfo.valueFieldInfo.type,
        typeName: mapEntryInfo.valueFieldInfo.typeName,
        enumDescriptor: enumDesc
      )
      jsonObject[jsonKey] = jsonValue
    }

    return jsonObject
  }

  internal func convertValueToJSON(
    _ value: Any,
    type: _FieldType,
    typeName: String?,
    enumDescriptor: _EnumDescriptor? = nil
  ) throws -> Any {
    switch type {
    case .double:
      guard let doubleValue = value as? Double else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "Double",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return convertDoubleToJSON(doubleValue)

    case .float:
      guard let floatValue = value as? Float else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "Float",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return convertFloatToJSON(floatValue)

    case .int32, .sint32, .sfixed32:
      guard let int32Value = value as? Int32 else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return Int(int32Value)

    case .int64, .sint64, .sfixed64:
      guard let int64Value = value as? Int64 else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "Int64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return String(int64Value)

    case .uint32, .fixed32:
      guard let uint32Value = value as? UInt32 else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "UInt32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return UInt(uint32Value)

    case .uint64, .fixed64:
      guard let uint64Value = value as? UInt64 else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "UInt64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return String(uint64Value)

    case .bool:
      guard let boolValue = value as? Bool else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "Bool",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return boolValue

    case .string:
      guard let stringValue = value as? String else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "String",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return stringValue

    case .bytes:
      guard let bytesValue = value as? Data else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "Data",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return bytesValue.base64EncodedString()

    case .message:
      let messageValue: _DynamicMessage
      if let m = value as? _DynamicMessage {
        messageValue = m
        // TODO(Strangler migration / OPE-302): Remove once internal storage never holds public DynamicMessage.
      }
      else if let pub = value as? DynamicMessage {
        messageValue = _DynamicMessage(from: pub)
      }
      else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "DynamicMessage",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return try serializeMessageToAny(messageValue)

    case .enum:
      guard let enumValue = value as? Int32 else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      if let enumDesc = enumDescriptor,
        let enumVal = enumDesc.valuesByNumber[Int(enumValue)]
      {
        return enumVal.name
      }
      return Int(enumValue)

    case .group:
      let groupMessage: _DynamicMessage
      if let m = value as? _DynamicMessage {
        groupMessage = m
        // TODO(Strangler migration / OPE-302): Remove once internal storage never holds public DynamicMessage.
      }
      else if let pub = value as? DynamicMessage {
        groupMessage = _DynamicMessage(from: pub)
      }
      else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "DynamicMessage (group)",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return try serializeMessageToAny(groupMessage)
    }
  }

  internal func convertMapKeyToJSONString(_ key: Any, keyType: _FieldType) throws -> String {
    switch keyType {
    case .string:
      guard let stringKey = key as? String else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "String",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return stringKey

    case .int32, .sint32, .sfixed32:
      guard let int32Key = key as? Int32 else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(int32Key)

    case .int64, .sint64, .sfixed64:
      guard let int64Key = key as? Int64 else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "Int64",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(int64Key)

    case .uint32, .fixed32:
      guard let uint32Key = key as? UInt32 else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "UInt32",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(uint32Key)

    case .uint64, .fixed64:
      guard let uint64Key = key as? UInt64 else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "UInt64",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(uint64Key)

    case .bool:
      guard let boolKey = key as? Bool else {
        throw _JSONSerializationError.valueTypeMismatch(
          expected: "Bool",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return boolKey ? "true" : "false"

    default:
      throw _JSONSerializationError.invalidMapKeyType(keyType: String(describing: keyType))
    }
  }

  private func convertDoubleToJSON(_ value: Double) -> Any {
    if value.isInfinite {
      return value > 0 ? "Infinity" : "-Infinity"
    }
    else if value.isNaN {
      return "NaN"
    }
    else {
      return value
    }
  }

  private func convertFloatToJSON(_ value: Float) -> Any {
    if value.isInfinite {
      return value > 0 ? "Infinity" : "-Infinity"
    }
    else if value.isNaN {
      return "NaN"
    }
    else {
      return value
    }
  }
}

// MARK: - JSON Serialization Options

internal struct _JSONSerializationOptions {
  let useOriginalFieldNames: Bool
  let prettyPrinted: Bool
  let includeDefaultValues: Bool
  let useCanonicalWellKnownTypeEncoding: Bool
  let escapeSlashesInStrings: Bool
  let sortJSONObjectKeys: Bool
  let typeRegistry: _TypeRegistry

  init(
    useOriginalFieldNames: Bool = false,
    prettyPrinted: Bool = false,
    includeDefaultValues: Bool = false,
    useCanonicalWellKnownTypeEncoding: Bool = true,
    escapeSlashesInStrings: Bool = true,
    sortJSONObjectKeys: Bool = false,
    typeRegistry: _TypeRegistry
  ) {
    self.useOriginalFieldNames = useOriginalFieldNames
    self.prettyPrinted = prettyPrinted
    self.includeDefaultValues = includeDefaultValues
    self.useCanonicalWellKnownTypeEncoding = useCanonicalWellKnownTypeEncoding
    self.escapeSlashesInStrings = escapeSlashesInStrings
    self.sortJSONObjectKeys = sortJSONObjectKeys
    self.typeRegistry = typeRegistry
  }
}

// MARK: - JSON Serialization Errors

internal enum _JSONSerializationError: Error, Equatable {
  case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
  case valueTypeMismatch(expected: String, actual: String)
  case missingMapEntryInfo(fieldName: String)
  case missingFieldValue(fieldName: String)
  case unsupportedFieldType(type: String)
  case invalidMapKeyType(keyType: String)
  case jsonWriteError(underlyingError: Error)
  case unsupportedWellKnownTypeEncoding(typeName: String)

  var description: String {
    switch self {
    case .invalidFieldType(let fieldName, let expectedType, let actualType):
      return "Invalid field type for field '\(fieldName)': expected \(expectedType), got \(actualType)"
    case .valueTypeMismatch(let expected, let actual):
      return "Value type mismatch: expected \(expected), got \(actual)"
    case .missingMapEntryInfo(let fieldName):
      return "Missing map entry info for field '\(fieldName)'"
    case .missingFieldValue(let fieldName):
      return "Missing value for field '\(fieldName)'"
    case .unsupportedFieldType(let type):
      return "Unsupported field type: \(type)"
    case .invalidMapKeyType(let keyType):
      return "Invalid map key type: \(keyType)"
    case .jsonWriteError(let underlyingError):
      return "JSON write error: \(underlyingError.localizedDescription)"
    case .unsupportedWellKnownTypeEncoding(let typeName):
      return "Canonical JSON encoding for well-known type '\(typeName)' is not yet implemented"
    }
  }

  static func == (lhs: _JSONSerializationError, rhs: _JSONSerializationError) -> Bool {
    switch (lhs, rhs) {
    case (
      .invalidFieldType(let lField, let lExpected, let lActual),
      .invalidFieldType(let rField, let rExpected, let rActual)
    ):
      return lField == rField && lExpected == rExpected && lActual == rActual
    case (
      .valueTypeMismatch(let lExpected, let lActual),
      .valueTypeMismatch(let rExpected, let rActual)
    ):
      return lExpected == rExpected && lActual == rActual
    case (.missingMapEntryInfo(let lField), .missingMapEntryInfo(let rField)):
      return lField == rField
    case (.missingFieldValue(let lField), .missingFieldValue(let rField)):
      return lField == rField
    case (.unsupportedFieldType(let lType), .unsupportedFieldType(let rType)):
      return lType == rType
    case (.invalidMapKeyType(let lType), .invalidMapKeyType(let rType)):
      return lType == rType
    case (.jsonWriteError(_), .jsonWriteError(_)):
      return true
    case (
      .unsupportedWellKnownTypeEncoding(let lType),
      .unsupportedWellKnownTypeEncoding(let rType)
    ):
      return lType == rType
    default:
      return false
    }
  }
}
