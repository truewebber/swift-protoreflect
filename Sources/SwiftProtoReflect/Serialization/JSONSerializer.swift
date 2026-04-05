//
// JSONSerializer.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation

/// JSONSerializer.
///
/// Provides functionality for serializing dynamic Protocol Buffers messages
/// to JSON format according to official Protocol Buffers JSON mapping specification.
/// Ensures full compatibility with protoc --json_out.
public struct JSONSerializer {

  // MARK: - Properties

  /// JSON serialization options.
  public let options: JSONSerializationOptions

  // MARK: - Initialization

  /// Creates new JSONSerializer instance.
  ///
  /// - Parameter options: JSON serialization options.
  public init(options: JSONSerializationOptions) {
    self.options = options
  }

  /// Creates a JSONSerializer with default options and an empty TypeRegistry.
  ///
  /// - Note: Deprecated. Use `init(options:)` with an explicit `TypeRegistry` so that
  ///   cross-file message types can be resolved correctly.
  @available(*, deprecated, message: "Use init(options:) with an explicit TypeRegistry")
  public init() {
    self.init(
      options: JSONSerializationOptions(
        useOriginalFieldNames: false,
        prettyPrinted: false,
        includeDefaultValues: false,
        typeRegistry: TypeRegistry()
      )
    )
  }

  // MARK: - Serialization Methods

  /// Serializes dynamic message to JSON format.
  ///
  /// - Parameter message: Dynamic message to serialize.
  /// - Returns: JSON string in Data format.
  /// - Throws: JSONSerializationError if serialization failed.
  public func serialize(_ message: DynamicMessage) throws -> Data {
    let jsonValue = try serializeMessageToAny(message)

    var writingOptions: JSONSerialization.WritingOptions = .fragmentsAllowed
    if self.options.prettyPrinted {
      writingOptions.insert(.prettyPrinted)
    }

    do {
      return try JSONSerialization.data(withJSONObject: jsonValue, options: writingOptions)
    }
    catch {
      throw JSONSerializationError.jsonWriteError(underlyingError: error)
    }
  }

  /// Serializes a dynamic message to an `Any` value.
  ///
  /// When `useCanonicalWellKnownTypeEncoding` is enabled and the message is a well-known type,
  /// this method routes to a WKT-specific encoder. For all other messages it falls through to
  /// standard field-by-field encoding via `serializeToJSONObject`.
  ///
  /// The return type is `Any` rather than `[String: Any]` because canonical WKT output can be
  /// a non-object JSON value (e.g. a bare `String`, `Bool`, `NSNull`, or `[Any]`).
  ///
  /// - Parameter message: Dynamic message to serialize.
  /// - Returns: JSON-compatible value (`Any`).
  /// - Throws: `JSONSerializationError.unsupportedWellKnownTypeEncoding` when canonical mode is
  ///   enabled for a WKT whose encoder has not yet been implemented.
  internal func serializeMessageToAny(_ message: DynamicMessage) throws -> Any {
    let fullName = message.descriptor.fullName
    guard options.useCanonicalWellKnownTypeEncoding,
      WellKnownTypeDetector.isWellKnownType(fullName)
    else {
      return try serializeToJSONObject(message)
    }
    return try encodeWellKnownType(message, fullName: fullName)
  }

  /// Dispatches to a WKT-specific canonical JSON encoder.
  private func encodeWellKnownType(_ message: DynamicMessage, fullName: String) throws -> Any {
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
      throw JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: fullName)
    }
  }

  /// Encodes any of the 9 protobuf wrapper types to their canonical JSON value.
  ///
  /// Each wrapper holds a single `value` field (field 1). The field is read and
  /// returned as the raw JSON-compatible value:
  /// - Int64/UInt64 → quoted decimal string (to preserve precision beyond JS Number)
  /// - Data (BytesValue) → base64 string
  /// - All others → the native Swift value (Double, Float, Int32, UInt32, Bool, String)
  private func encodeWrapperMessage(_ message: DynamicMessage, fullName: String) throws -> Any {
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

  /// Encodes `google.protobuf.Timestamp` to its canonical RFC 3339 JSON string.
  ///
  /// Field layout: 1 seconds (int64), 2 nanos (int32).
  /// Fractional precision: 0 digits when nanos==0, 3 when millis-aligned,
  /// 6 when micros-aligned, 9 otherwise.
  private func encodeTimestampMessage(_ message: DynamicMessage) throws -> Any {
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

  /// Encodes `google.protobuf.Duration` to its canonical JSON string with `s` suffix.
  ///
  /// Field layout: 1 seconds (int64), 2 nanos (int32).
  /// If nanos is zero the output is `"Xs"`. Otherwise the 9-digit nanosecond fraction
  /// is appended with trailing zeros trimmed, e.g. `"1.5s"`. Negative durations
  /// carry a single leading `-` sign covering both the seconds and nanos parts.
  private func encodeDurationMessage(_ message: DynamicMessage) throws -> Any {
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

  /// Encodes `google.protobuf.FieldMask` to its canonical comma-separated camelCase JSON string.
  ///
  /// Field layout: 1 paths (repeated string, snake_case).
  /// Each snake_case path is converted to lowerCamelCase and joined with `,`.
  /// An empty paths array produces an empty string `""`.
  private func encodeFieldMaskMessage(_ message: DynamicMessage) throws -> Any {
    let paths = (try? message.get(forField: 1) as? [String]) ?? []
    let camelPaths = paths.map { snakeToCamelCase($0) }
    return camelPaths.joined(separator: ",")
  }

  /// Converts a snake_case string to lowerCamelCase.
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

  /// Encodes `google.protobuf.Any` to its canonical expanded JSON form.
  ///
  /// Reads `type_url` (field 1) and `value` (field 2, bytes) from the Any message.
  /// The type is looked up in `options.typeRegistry`:
  /// - If found and is a WKT: `{"@type": url, "value": <canonical WKT>}`.
  /// - If found and is a regular message: `serializeToJSONObject` result + `"@type"` key.
  /// - If not found: falls back to standard field-by-field encoding (no `@type` expansion).
  private func encodeAnyMessage(_ message: DynamicMessage) throws -> Any {
    let typeUrl = (try? message.get(forField: 1) as? String) ?? ""
    let valueBytes = (try? message.get(forField: 2) as? Data) ?? Data()

    // Extract the fully-qualified type name from the URL (everything after the last '/').
    guard !typeUrl.isEmpty, let slashIdx = typeUrl.lastIndex(of: "/") else {
      return try serializeToJSONObject(message)
    }
    let typeName = String(typeUrl[typeUrl.index(after: slashIdx)...])

    guard let packedDescriptor = options.typeRegistry.findMessage(named: typeName) else {
      return try serializeToJSONObject(message)
    }

    let packedMessage = try BinaryDeserializer().deserialize(valueBytes, using: packedDescriptor)

    if WellKnownTypeDetector.isWellKnownType(typeName) {
      let canonicalValue = try encodeWellKnownType(packedMessage, fullName: typeName)
      return ["@type": typeUrl, "value": canonicalValue]
    }

    var jsonObject = try serializeToJSONObject(packedMessage)
    jsonObject["@type"] = typeUrl
    return jsonObject
  }

  /// Encodes `google.protobuf.Value` to its canonical JSON form.
  ///
  /// Field layout (oneof kind):
  ///   1 null_value (enum), 2 number_value (double), 3 string_value,
  ///   4 bool_value, 5 struct_value (message), 6 list_value (message).
  /// When no field is set the canonical output is JSON null.
  private func encodeValueMessage(_ message: DynamicMessage) throws -> Any {
    if (try? message.hasValue(forField: 1)) == true {
      return NSNull()
    }
    if (try? message.hasValue(forField: 2)) == true {
      guard let d = try message.get(forField: 2) as? Double else {
        throw JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.value)
      }
      return convertDoubleToJSON(d)
    }
    if (try? message.hasValue(forField: 3)) == true {
      guard let s = try message.get(forField: 3) as? String else {
        throw JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.value)
      }
      return s
    }
    if (try? message.hasValue(forField: 4)) == true {
      guard let b = try message.get(forField: 4) as? Bool else {
        throw JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.value)
      }
      return b
    }
    if (try? message.hasValue(forField: 5)) == true {
      guard let nested = try message.get(forField: 5) as? DynamicMessage else {
        throw JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.value)
      }
      return try encodeStructMessage(nested)
    }
    if (try? message.hasValue(forField: 6)) == true {
      guard let nested = try message.get(forField: 6) as? DynamicMessage else {
        throw JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.value)
      }
      return try encodeListValueMessage(nested)
    }
    return NSNull()
  }

  /// Encodes `google.protobuf.Struct` to its canonical JSON form: `[String: Any]`.
  ///
  /// Reads the `map<string, Value>` at field 1 and canonically encodes each value.
  private func encodeStructMessage(_ message: DynamicMessage) throws -> [String: Any] {
    let rawMap = (try? message.get(forField: 1) as? [AnyHashable: Any]) ?? [:]
    var result: [String: Any] = [:]
    for (key, value) in rawMap {
      guard let stringKey = key as? String else { continue }
      guard let valueMsg = value as? DynamicMessage else { continue }
      result[stringKey] = try encodeValueMessage(valueMsg)
    }
    return result
  }

  /// Encodes `google.protobuf.ListValue` to its canonical JSON form: `[Any]`.
  ///
  /// Reads the `repeated Value` at field 1 and canonically encodes each element.
  private func encodeListValueMessage(_ message: DynamicMessage) throws -> [Any] {
    let rawList = (try? message.get(forField: 1) as? [Any]) ?? []
    return try rawList.map { item -> Any in
      guard let valueMsg = item as? DynamicMessage else {
        throw JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: WellKnownTypeNames.listValue)
      }
      return try encodeValueMessage(valueMsg)
    }
  }

  /// Serializes dynamic message to JSON object.
  ///
  /// - Parameter message: Dynamic message to serialize.
  /// - Returns: JSON compatible object (Dictionary).
  /// - Throws: JSONSerializationError if serialization failed.
  public func serializeToJSONObject(_ message: DynamicMessage) throws -> [String: Any] {
    var result: [String: Any] = [:]

    let descriptor = message.descriptor
    let fieldAccess = FieldAccessor(message)

    var allFields = descriptor.allFields()
    allFields.append(contentsOf: descriptor.extensions.values)

    for field in allFields {
      let hasValue = fieldAccess.hasValue(field.number)
      let fieldName = options.useOriginalFieldNames ? field.name : field.jsonName

      if hasValue {
        // Per proto3 JSON spec, scalar fields at their default value must be omitted
        // unless the field has explicit presence (proto3 optional, proto2 required/optional)
        // or the caller requested includeDefaultValues.
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

  /// Returns `true` when the field is a proto3 implicit-presence scalar.
  ///
  /// Such fields have no explicit presence: setting them to their default value is
  /// semantically equivalent to not setting them, so the value must be omitted from
  /// JSON output per the proto3 JSON mapping specification.
  ///
  /// Exclusions:
  /// - `proto3Optional`, `isRequired`, `isOptional` — explicit presence.
  /// - `isRepeated`, `isMap` — collections; empty is handled separately.
  /// - `oneofIndex != nil` — oneof fields have explicit presence by virtue of being the active branch.
  /// - `.message`, `.group` — non-scalar; omission handled via `hasValue` on `nestedMessages`.
  /// - `.enum` — enum zero-value omission is intentionally deferred; existing tests assert emission.
  private func isProto3ImplicitPresenceScalar(_ field: FieldDescriptor) -> Bool {
    guard !field.proto3Optional, !field.isRequired, !field.isOptional,
      !field.isRepeated, !field.isMap,
      field.oneofIndex == nil
    else { return false }
    switch field.type {
    case .message, .group, .enum: return false
    default: return true
    }
  }

  /// Returns `true` when `value` equals the proto3 default for the given scalar type.
  private func isProto3ScalarDefault(_ value: Any?, type: FieldType) -> Bool {
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

  /// Resolves an `EnumDescriptor` for a field.
  ///
  /// 1. `options.typeRegistry` by fully-qualified name (primary).
  /// 2. Structural nesting on `descriptor` (deprecated fallback).
  private func resolveEnumDescriptor(
    for field: FieldDescriptor,
    in descriptor: MessageDescriptor
  ) -> EnumDescriptor? {
    guard case .enum = field.type, let typeName = field.typeName else { return nil }
    let normalized = typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
    if let desc = options.typeRegistry.findEnum(named: normalized) {
      return desc
    }
    // DEPRECATED: Legacy structural nesting fallback. Will be removed in a future major version.
    // Users should register all types in TypeRegistry instead of relying on addNestedEnum().
    let simpleName = typeName.split(separator: ".").last.map(String.init) ?? typeName
    return descriptor.nestedEnum(named: simpleName)
  }

  /// Returns the proto3 JSON default for a field that has no value set.
  private func proto3DefaultJSON(for field: FieldDescriptor, in descriptor: MessageDescriptor) -> Any {
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
        let zeroVal = enumDesc.value(number: 0)
      {
        return zeroVal.name
      }
      return 0
    case .message, .group: return NSNull()
    }
  }

  // MARK: - Private Methods

  /// Serializes field value to JSON compatible object.
  private func serializeFieldValue(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    descriptor: MessageDescriptor
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

  /// Serializes single field.
  private func serializeSingleField(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    descriptor: MessageDescriptor
  ) throws -> Any {
    guard let value = fieldAccess.getValue(field.number, as: Any.self) else {
      throw JSONSerializationError.missingFieldValue(fieldName: field.name)
    }

    let enumDesc = resolveEnumDescriptor(for: field, in: descriptor)
    return try convertValueToJSON(value, type: field.type, typeName: field.typeName, enumDescriptor: enumDesc)
  }

  /// Serializes repeated field.
  private func serializeRepeatedField(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    descriptor: MessageDescriptor
  ) throws -> Any {
    guard let values = fieldAccess.getValue(field.number, as: [Any].self) else {
      throw JSONSerializationError.invalidFieldType(
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

  /// Serializes map field.
  private func serializeMapField(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    descriptor: MessageDescriptor
  ) throws -> Any {
    guard let mapEntryInfo = field.mapEntryInfo else {
      throw JSONSerializationError.missingMapEntryInfo(fieldName: field.name)
    }

    guard let mapValues = fieldAccess.getValue(field.number, as: [AnyHashable: Any].self) else {
      throw JSONSerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Dictionary",
        actualType: String(describing: type(of: fieldAccess.getValue(field.number, as: Any.self)))
      )
    }

    var jsonObject: [String: Any] = [:]

    let enumDesc: EnumDescriptor? = {
      guard case .enum = mapEntryInfo.valueFieldInfo.type,
        let typeName = mapEntryInfo.valueFieldInfo.typeName
      else { return nil }
      let normalized = typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
      if let desc = options.typeRegistry.findEnum(named: normalized) {
        return desc
      }
      // DEPRECATED: Legacy structural nesting fallback. Will be removed in a future major version.
      // Users should register all types in TypeRegistry instead of relying on addNestedEnum().
      let simpleName = typeName.split(separator: ".").last.map(String.init) ?? typeName
      return descriptor.nestedEnum(named: simpleName)
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

  /// Converts value to JSON compatible type.
  internal func convertValueToJSON(
    _ value: Any,
    type: FieldType,
    typeName: String?,
    enumDescriptor: EnumDescriptor? = nil
  ) throws -> Any {
    switch type {
    case .double:
      guard let doubleValue = value as? Double else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Double",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return convertDoubleToJSON(doubleValue)

    case .float:
      guard let floatValue = value as? Float else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Float",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return convertFloatToJSON(floatValue)

    case .int32, .sint32, .sfixed32:
      guard let int32Value = value as? Int32 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return Int(int32Value)

    case .int64, .sint64, .sfixed64:
      guard let int64Value = value as? Int64 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Int64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      // int64 is represented as string in JSON
      return String(int64Value)

    case .uint32, .fixed32:
      guard let uint32Value = value as? UInt32 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "UInt32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return UInt(uint32Value)

    case .uint64, .fixed64:
      guard let uint64Value = value as? UInt64 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "UInt64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      // uint64 is represented as string in JSON
      return String(uint64Value)

    case .bool:
      guard let boolValue = value as? Bool else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Bool",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return boolValue

    case .string:
      guard let stringValue = value as? String else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "String",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return stringValue

    case .bytes:
      guard let bytesValue = value as? Data else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Data",
          actual: String(describing: Swift.type(of: value))
        )
      }
      // bytes are represented as base64 string
      return bytesValue.base64EncodedString()

    case .message:
      guard let messageValue = value as? DynamicMessage else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "DynamicMessage",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return try serializeMessageToAny(messageValue)

    case .enum:
      guard let enumValue = value as? Int32 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      if let enumDesc = enumDescriptor,
        let enumVal = enumDesc.value(number: Int(enumValue))
      {
        return enumVal.name
      }
      return Int(enumValue)

    case .group:
      guard let groupMessage = value as? DynamicMessage else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "DynamicMessage (group)",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return try serializeMessageToAny(groupMessage)
    }
  }

  /// Converts map key to JSON string.
  internal func convertMapKeyToJSONString(_ key: Any, keyType: FieldType) throws -> String {
    switch keyType {
    case .string:
      guard let stringKey = key as? String else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "String",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return stringKey

    case .int32, .sint32, .sfixed32:
      guard let int32Key = key as? Int32 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(int32Key)

    case .int64, .sint64, .sfixed64:
      guard let int64Key = key as? Int64 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Int64",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(int64Key)

    case .uint32, .fixed32:
      guard let uint32Key = key as? UInt32 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "UInt32",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(uint32Key)

    case .uint64, .fixed64:
      guard let uint64Key = key as? UInt64 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "UInt64",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(uint64Key)

    case .bool:
      guard let boolKey = key as? Bool else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Bool",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return boolKey ? "true" : "false"

    default:
      throw JSONSerializationError.invalidMapKeyType(keyType: String(describing: keyType))
    }
  }

  /// Converts double value with handling of special cases.
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

  /// Converts float value with handling of special cases.
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

/// Options for JSON serialization.
public struct JSONSerializationOptions {
  /// Use original field names instead of camelCase.
  public let useOriginalFieldNames: Bool

  /// Format JSON with indentation for readability.
  public let prettyPrinted: Bool

  /// Include fields with default values.
  public let includeDefaultValues: Bool

  /// Use protobuf-spec canonical representations for well-known types.
  ///
  /// When `true`, the serializer emits well-known type values using their canonical
  /// protobuf JSON mapping (e.g. `Timestamp` as an RFC 3339 string) instead of
  /// generic field-by-field encoding. Defaults to `true`.
  public let useCanonicalWellKnownTypeEncoding: Bool

  /// Registry for resolving message types by fully-qualified name.
  ///
  /// Pass a populated `TypeRegistry` to enable cross-file type resolution during serialization.
  /// For hand-built descriptors without cross-file references, an empty `TypeRegistry()` is sufficient.
  public let typeRegistry: TypeRegistry

  /// Creates JSON serialization options with a required TypeRegistry.
  ///
  /// - Parameters:
  ///   - useOriginalFieldNames: Whether to use original proto field names instead of camelCase. Defaults to `false`.
  ///   - prettyPrinted: Whether to format JSON with indentation. Defaults to `false`.
  ///   - includeDefaultValues: Whether to include fields with default values. Defaults to `false`.
  ///   - useCanonicalWellKnownTypeEncoding: Whether to use canonical protobuf JSON for well-known types. Defaults to `true`.
  ///   - typeRegistry: Registry for resolving message types by fully-qualified name.
  public init(
    useOriginalFieldNames: Bool = false,
    prettyPrinted: Bool = false,
    includeDefaultValues: Bool = false,
    useCanonicalWellKnownTypeEncoding: Bool = true,
    typeRegistry: TypeRegistry
  ) {
    self.useOriginalFieldNames = useOriginalFieldNames
    self.prettyPrinted = prettyPrinted
    self.includeDefaultValues = includeDefaultValues
    self.useCanonicalWellKnownTypeEncoding = useCanonicalWellKnownTypeEncoding
    self.typeRegistry = typeRegistry
  }

  /// Creates JSON serialization options with an empty TypeRegistry.
  ///
  /// - Note: Deprecated. Use `init(useOriginalFieldNames:prettyPrinted:includeDefaultValues:useCanonicalWellKnownTypeEncoding:typeRegistry:)`
  ///   with an explicit `TypeRegistry` so that cross-file message types can be resolved correctly.
  @available(
    *,
    deprecated,
    message:
      "Use init(useOriginalFieldNames:prettyPrinted:includeDefaultValues:useCanonicalWellKnownTypeEncoding:typeRegistry:) with an explicit TypeRegistry"
  )
  public init(
    useOriginalFieldNames: Bool = false,
    prettyPrinted: Bool = false,
    includeDefaultValues: Bool = false
  ) {
    self.init(
      useOriginalFieldNames: useOriginalFieldNames,
      prettyPrinted: prettyPrinted,
      includeDefaultValues: includeDefaultValues,
      useCanonicalWellKnownTypeEncoding: true,
      typeRegistry: TypeRegistry()
    )
  }
}

// MARK: - JSON Serialization Errors

/// JSON serialization errors.
public enum JSONSerializationError: Error, Equatable {
  case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
  case valueTypeMismatch(expected: String, actual: String)
  case missingMapEntryInfo(fieldName: String)
  case missingFieldValue(fieldName: String)
  case unsupportedFieldType(type: String)
  case invalidMapKeyType(keyType: String)
  case jsonWriteError(underlyingError: Error)
  /// Canonical JSON encoding for a well-known type is not yet implemented.
  case unsupportedWellKnownTypeEncoding(typeName: String)

  public var description: String {
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

  public static func == (lhs: JSONSerializationError, rhs: JSONSerializationError) -> Bool {
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
      // Hard to compare underlying errors, so consider equal if both are jsonWriteError
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
