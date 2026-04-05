//
// JSONDeserializer.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation

/// JSONDeserializer.
///
/// Provides functionality for deserializing JSON data to dynamic Protocol Buffers messages
/// according to official Protocol Buffers JSON mapping specification.
/// Ensures full compatibility with JSONSerializer for round-trip operations.
public struct JSONDeserializer {

  // MARK: - Properties

  /// JSON deserialization options.
  public let options: JSONDeserializationOptions

  // MARK: - Initialization

  /// Creates new JSONDeserializer instance.
  ///
  /// - Parameter options: JSON deserialization options.
  public init(options: JSONDeserializationOptions) {
    self.options = options
  }

  /// Creates a JSONDeserializer with default options and an empty TypeRegistry.
  ///
  /// - Note: Deprecated. Use `init(options:)` with an explicit `TypeRegistry` so that
  ///   cross-file message types can be resolved correctly.
  @available(*, deprecated, message: "Use init(options:) with an explicit TypeRegistry")
  public init() {
    self.init(
      options: JSONDeserializationOptions(
        ignoreUnknownFields: true,
        strictTypeValidation: true,
        typeRegistry: TypeRegistry(),
        maxNestingDepth: 64
      )
    )
  }

  // MARK: - Deserialization Methods

  /// Deserializes JSON data to dynamic message.
  ///
  /// - Parameters:
  ///   - data: JSON data to deserialize.
  ///   - descriptor: Message descriptor to determine structure.
  /// - Returns: Deserialized dynamic message.
  /// - Throws: JSONDeserializationError if deserialization failed.
  public func deserialize(_ data: Data, using descriptor: MessageDescriptor) throws -> DynamicMessage {
    // Use .fragmentsAllowed so that WKTs with non-object canonical JSON (bare string,
    // number, boolean, or null) can be parsed at the top level.
    let jsonValue: Any
    do {
      jsonValue = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    }
    catch {
      throw JSONDeserializationError.invalidJSON(underlyingError: error)
    }

    // Route well-known types through the WKT dispatch layer.
    if WellKnownTypeDetector.isWellKnownType(descriptor.fullName) {
      return try deserializeWKTFromAny(jsonValue, using: descriptor, depth: 0)
    }

    guard let jsonDictionary = jsonValue as? [String: Any] else {
      throw JSONDeserializationError.invalidJSONStructure(
        expected: "Object",
        actual: String(describing: type(of: jsonValue))
      )
    }

    return try deserializeFromJSONObject(jsonDictionary, using: descriptor)
  }

  /// Deserializes a `Any` JSON value to a well-known type message.
  ///
  /// Dispatches to a WKT-specific canonical JSON decoder. Unimplemented WKT decoders
  /// throw `JSONDeserializationError.unsupportedWellKnownTypeDecoding` rather than
  /// silently falling through to field-by-field decoding (which would produce incorrect output).
  ///
  /// - Parameters:
  ///   - jsonValue: JSON value parsed from the wire (can be any JSON type).
  ///   - descriptor: Message descriptor whose `fullName` identifies the WKT.
  ///   - depth: Current nesting depth for cycle/depth checks.
  /// - Returns: Deserialized dynamic message.
  /// - Throws: `JSONDeserializationError.unsupportedWellKnownTypeDecoding` for unimplemented WKTs.
  internal func deserializeWKTFromAny(
    _ jsonValue: Any,
    using descriptor: MessageDescriptor,
    depth: Int
  ) throws -> DynamicMessage {
    switch descriptor.fullName {
    case WellKnownTypeNames.empty:
      guard let jsonObj = jsonValue as? [String: Any] else {
        throw JSONDeserializationError.invalidJSONStructure(
          expected: "Object",
          actual: String(describing: type(of: jsonValue))
        )
      }
      return try deserializeFromJSONObject(jsonObj, using: descriptor, depth: depth)
    case WellKnownTypeNames.timestamp:
      return try decodeTimestampFromAny(jsonValue, using: descriptor)
    case WellKnownTypeNames.duration:
      return try decodeDurationFromAny(jsonValue, using: descriptor)
    case WellKnownTypeNames.fieldMask:
      return try decodeFieldMaskFromAny(jsonValue, using: descriptor)
    case WellKnownTypeNames.value:
      return try decodeValueFromAny(jsonValue, depth: depth)
    case WellKnownTypeNames.structType:
      guard let jsonObj = jsonValue as? [String: Any] else {
        throw JSONDeserializationError.invalidJSONStructure(
          expected: "Object",
          actual: String(describing: type(of: jsonValue))
        )
      }
      return try decodeStructFromObject(jsonObj, depth: depth)
    case WellKnownTypeNames.listValue:
      guard let jsonArr = jsonValue as? [Any] else {
        throw JSONDeserializationError.invalidJSONStructure(
          expected: "Array",
          actual: String(describing: type(of: jsonValue))
        )
      }
      return try decodeListValueFromArray(jsonArr, depth: depth)
    default:
      throw JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: descriptor.fullName)
    }
  }

  /// Decodes a canonical RFC 3339 JSON string to `google.protobuf.Timestamp`.
  ///
  /// Accepts strings with Z or ±HH:MM timezone offsets and optional fractional seconds
  /// with up to 9 digits of precision.  Non-string JSON input throws
  /// `invalidJSONStructure`.
  private func decodeTimestampFromAny(_ jsonValue: Any, using descriptor: MessageDescriptor) throws -> DynamicMessage {
    guard let str = jsonValue as? String else {
      throw JSONDeserializationError.invalidJSONStructure(
        expected: "String",
        actual: String(describing: type(of: jsonValue))
      )
    }

    // Separate optional fractional-seconds digits from the rest of the timestamp.
    var datePart = str
    var nanosDigits: String? = nil

    if let dotIdx = str.firstIndex(of: ".") {
      let beforeDot = String(str[str.startIndex..<dotIdx])
      let afterDot = String(str[str.index(after: dotIdx)...])

      // The timezone indicator follows the fractional digits: Z, +, or -
      let tzChars: Set<Character> = ["Z", "+", "-"]
      if let tzIdx = afterDot.firstIndex(where: { tzChars.contains($0) }) {
        nanosDigits = String(afterDot[afterDot.startIndex..<tzIdx])
        let tz = String(afterDot[tzIdx...])
        datePart = beforeDot + tz
      }
      else {
        nanosDigits = afterDot
        datePart = beforeDot + "Z"
      }
    }

    // Parse the whole-second timestamp using DateFormatter.
    // Format XXX handles both Z and ±HH:MM offsets (RFC 3339 / ISO 8601 extended).
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
    guard let date = formatter.date(from: datePart) else {
      throw JSONDeserializationError.invalidJSONStructure(
        expected: "RFC 3339 timestamp string",
        actual: str
      )
    }

    let seconds = Int64(date.timeIntervalSince1970)

    // Parse fractional digits, padding/truncating to exactly 9 nanosecond digits.
    let nanos: Int32
    if let digits = nanosDigits, !digits.isEmpty {
      var padded = digits
      while padded.count < 9 { padded += "0" }
      if padded.count > 9 { padded = String(padded.prefix(9)) }
      guard let value = Int32(padded) else {
        throw JSONDeserializationError.invalidJSONStructure(
          expected: "Valid fractional seconds",
          actual: str
        )
      }
      nanos = value
    }
    else {
      nanos = 0
    }

    var msg = DynamicMessage(descriptor: descriptor)
    try msg.set(seconds, forField: 1)
    if nanos != 0 {
      try msg.set(nanos, forField: 2)
    }
    return msg
  }

  /// Decodes a canonical duration JSON string (e.g. `"1.5s"`, `"-300s"`) to
  /// `google.protobuf.Duration`.
  ///
  /// Accepts strings matching `^-?\d+(\.\d+)?s$` with up to 9 fractional digits.
  /// Non-string input or malformed strings throw `invalidJSONStructure`.
  private func decodeDurationFromAny(_ jsonValue: Any, using descriptor: MessageDescriptor) throws -> DynamicMessage {
    guard let str = jsonValue as? String else {
      throw JSONDeserializationError.invalidJSONStructure(
        expected: "String",
        actual: String(describing: type(of: jsonValue))
      )
    }

    guard str.hasSuffix("s") else {
      throw JSONDeserializationError.invalidJSONStructure(
        expected: "Duration string ending in 's'",
        actual: str
      )
    }

    let withoutSuffix = String(str.dropLast())
    let isNegative = withoutSuffix.hasPrefix("-")
    let numericPart = isNegative ? String(withoutSuffix.dropFirst()) : withoutSuffix

    // Split on the optional decimal point
    let dotComponents = numericPart.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
    guard let firstComponent = dotComponents.first, !firstComponent.isEmpty else {
      throw JSONDeserializationError.invalidJSONStructure(
        expected: "Valid duration string",
        actual: str
      )
    }

    guard let absSeconds = Int64(firstComponent) else {
      throw JSONDeserializationError.invalidJSONStructure(
        expected: "Valid duration string",
        actual: str
      )
    }

    let absNanos: Int32
    if dotComponents.count > 1 {
      let fracPart = String(dotComponents[1])
      guard !fracPart.isEmpty, fracPart.allSatisfy({ $0.isNumber }) else {
        throw JSONDeserializationError.invalidJSONStructure(
          expected: "Valid duration string",
          actual: str
        )
      }
      var padded = fracPart
      while padded.count < 9 { padded += "0" }
      if padded.count > 9 { padded = String(padded.prefix(9)) }
      guard let value = Int32(padded) else {
        throw JSONDeserializationError.invalidJSONStructure(
          expected: "Valid duration string",
          actual: str
        )
      }
      absNanos = value
    }
    else {
      absNanos = 0
    }

    let seconds: Int64 = isNegative ? -absSeconds : absSeconds
    let nanos: Int32 = isNegative ? -absNanos : absNanos

    var msg = DynamicMessage(descriptor: descriptor)
    try msg.set(seconds, forField: 1)
    if nanos != 0 {
      try msg.set(nanos, forField: 2)
    }
    return msg
  }

  /// Decodes a canonical comma-separated camelCase JSON string to `google.protobuf.FieldMask`.
  ///
  /// Each camelCase segment is converted to snake_case and stored in the repeated `paths` field.
  /// An empty string produces an empty paths array. Non-string input throws `invalidJSONStructure`.
  private func decodeFieldMaskFromAny(_ jsonValue: Any, using descriptor: MessageDescriptor) throws -> DynamicMessage {
    guard let str = jsonValue as? String else {
      throw JSONDeserializationError.invalidJSONStructure(
        expected: "String",
        actual: String(describing: type(of: jsonValue))
      )
    }

    var msg = DynamicMessage(descriptor: descriptor)
    guard !str.isEmpty else {
      return msg
    }

    let paths = str.split(separator: ",", omittingEmptySubsequences: false).map { camelToSnakeCase(String($0)) }
    try msg.set(paths, forField: 1)
    return msg
  }

  /// Converts a lowerCamelCase string to snake_case.
  private func camelToSnakeCase(_ camel: String) -> String {
    var result = ""
    for char in camel {
      if char.isUppercase {
        result += "_" + char.lowercased()
      }
      else {
        result.append(char)
      }
    }
    return result
  }

  /// Decodes any JSON value to `google.protobuf.Value`.
  ///
  /// Field layout: 1 null_value, 2 number_value, 3 string_value, 4 bool_value,
  /// 5 struct_value, 6 list_value. JSON booleans are distinguished from numbers
  /// via `CFBooleanGetTypeID()` on Darwin; objcType "c"/"B" on Linux.
  private func decodeValueFromAny(_ jsonValue: Any, depth: Int) throws -> DynamicMessage {
    guard depth <= options.maxNestingDepth else {
      throw JSONDeserializationError.nestingDepthExceeded(maxDepth: options.maxNestingDepth)
    }
    var msg = DynamicMessage(descriptor: StructProtoDescriptors.valueDescriptor)
    if jsonValue is NSNull {
      try msg.set(Int32(0), forField: 1)
    }
    else if let number = jsonValue as? NSNumber {
      if isJSONBool(number) {
        try msg.set(number.boolValue, forField: 4)
      }
      else {
        try msg.set(number.doubleValue, forField: 2)
      }
    }
    else if let string = jsonValue as? String {
      try msg.set(string, forField: 3)
    }
    else if let dict = jsonValue as? [String: Any] {
      let nested = try decodeStructFromObject(dict, depth: depth + 1)
      try msg.set(nested, forField: 5)
    }
    else if let arr = jsonValue as? [Any] {
      let nested = try decodeListValueFromArray(arr, depth: depth + 1)
      try msg.set(nested, forField: 6)
    }
    else {
      try msg.set(Int32(0), forField: 1)
    }
    return msg
  }

  /// Decodes a `[String: Any]` JSON object to `google.protobuf.Struct`.
  private func decodeStructFromObject(_ jsonObj: [String: Any], depth: Int) throws -> DynamicMessage {
    guard depth <= options.maxNestingDepth else {
      throw JSONDeserializationError.nestingDepthExceeded(maxDepth: options.maxNestingDepth)
    }
    var msg = DynamicMessage(descriptor: StructProtoDescriptors.structDescriptor)
    for (key, value) in jsonObj {
      let valueMsg = try decodeValueFromAny(value, depth: depth + 1)
      try msg.setMapEntry(valueMsg, forKey: key, inField: 1)
    }
    return msg
  }

  /// Decodes a `[Any]` JSON array to `google.protobuf.ListValue`.
  private func decodeListValueFromArray(_ jsonArr: [Any], depth: Int) throws -> DynamicMessage {
    guard depth <= options.maxNestingDepth else {
      throw JSONDeserializationError.nestingDepthExceeded(maxDepth: options.maxNestingDepth)
    }
    var msg = DynamicMessage(descriptor: StructProtoDescriptors.listValueDescriptor)
    for item in jsonArr {
      let valueMsg = try decodeValueFromAny(item, depth: depth + 1)
      try msg.addRepeatedValue(valueMsg, forField: 1)
    }
    return msg
  }

  /// Returns `true` when `number` was produced from a JSON boolean literal.
  private func isJSONBool(_ number: NSNumber) -> Bool {
    #if canImport(CoreFoundation) && !os(Linux)
      return CFGetTypeID(number) == CFBooleanGetTypeID()
    #else
      let objCType = String(cString: number.objCType)
      return objCType == "c" || objCType == "B"
    #endif
  }

  /// Deserializes JSON object to dynamic message.
  ///
  /// - Parameters:
  ///   - jsonObject: JSON object (Dictionary) to deserialize.
  ///   - descriptor: Message descriptor to determine structure.
  /// - Returns: Deserialized dynamic message.
  /// - Throws: JSONDeserializationError if deserialization failed.
  public func deserializeFromJSONObject(_ jsonObject: [String: Any], using descriptor: MessageDescriptor) throws
    -> DynamicMessage
  {
    return try deserializeFromJSONObject(jsonObject, using: descriptor, depth: 0)
  }

  private func deserializeFromJSONObject(
    _ jsonObject: [String: Any],
    using descriptor: MessageDescriptor,
    depth: Int
  ) throws -> DynamicMessage {
    guard depth <= options.maxNestingDepth else {
      throw JSONDeserializationError.nestingDepthExceeded(maxDepth: options.maxNestingDepth)
    }

    let factory = MessageFactory()
    var message = factory.createMessage(from: descriptor)

    for (jsonFieldName, jsonValue) in jsonObject {
      guard let field = findField(byJSONName: jsonFieldName, in: descriptor) else {
        if options.ignoreUnknownFields {
          continue
        }
        else {
          throw JSONDeserializationError.unknownField(fieldName: jsonFieldName, messageName: descriptor.name)
        }
      }

      let fieldValue = try deserializeFieldValue(jsonValue, for: field, descriptor: descriptor, depth: depth)
      try message.set(fieldValue, forField: field.number)
    }

    return message
  }

  // MARK: - Private Methods

  /// Finds field by JSON name (supports original names, camelCase, and extension fields).
  private func findField(byJSONName jsonName: String, in descriptor: MessageDescriptor) -> FieldDescriptor? {
    for field in descriptor.allFields() {
      if field.name == jsonName {
        return field
      }
      if field.jsonName == jsonName {
        return field
      }
    }
    for (_, extField) in descriptor.extensions {
      if extField.name == jsonName {
        return extField
      }
      if extField.jsonName == jsonName {
        return extField
      }
    }
    return nil
  }

  /// Deserializes field value from JSON.
  private func deserializeFieldValue(
    _ jsonValue: Any,
    for field: FieldDescriptor,
    descriptor: MessageDescriptor,
    depth: Int
  ) throws -> Any {
    if field.isMap {
      return try deserializeMapField(jsonValue, for: field, descriptor: descriptor, depth: depth)
    }
    else if field.isRepeated {
      return try deserializeRepeatedField(jsonValue, for: field, descriptor: descriptor, depth: depth)
    }
    else {
      return try deserializeSingleField(jsonValue, for: field, descriptor: descriptor, depth: depth)
    }
  }

  /// Deserializes single field.
  private func deserializeSingleField(
    _ jsonValue: Any,
    for field: FieldDescriptor,
    descriptor: MessageDescriptor,
    depth: Int
  ) throws -> Any {
    let enumDesc = resolveEnumDescriptor(for: field, in: descriptor)
    return try convertJSONValueToFieldType(
      jsonValue,
      type: field.type,
      typeName: field.typeName,
      fieldName: field.name,
      depth: depth,
      enumDescriptor: enumDesc
    )
  }

  /// Deserializes repeated field.
  private func deserializeRepeatedField(
    _ jsonValue: Any,
    for field: FieldDescriptor,
    descriptor: MessageDescriptor,
    depth: Int
  ) throws -> Any {
    guard let jsonArray = jsonValue as? [Any] else {
      throw JSONDeserializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Array",
        actualType: String(describing: type(of: jsonValue))
      )
    }

    let enumDesc = resolveEnumDescriptor(for: field, in: descriptor)
    var resultArray: [Any] = []

    for (index, arrayElement) in jsonArray.enumerated() {
      do {
        let convertedValue = try convertJSONValueToFieldType(
          arrayElement,
          type: field.type,
          typeName: field.typeName,
          fieldName: "\(field.name)[\(index)]",
          depth: depth,
          enumDescriptor: enumDesc
        )
        resultArray.append(convertedValue)
      }
      catch {
        throw JSONDeserializationError.invalidArrayElement(
          fieldName: field.name,
          index: index,
          underlyingError: error
        )
      }
    }

    return resultArray
  }

  /// Deserializes map field.
  private func deserializeMapField(
    _ jsonValue: Any,
    for field: FieldDescriptor,
    descriptor: MessageDescriptor,
    depth: Int
  ) throws -> Any {
    guard let jsonObject = jsonValue as? [String: Any] else {
      throw JSONDeserializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Object",
        actualType: String(describing: type(of: jsonValue))
      )
    }

    guard let mapEntryInfo = field.mapEntryInfo else {
      throw JSONDeserializationError.missingMapEntryInfo(fieldName: field.name)
    }

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

    var resultMap: [AnyHashable: Any] = [:]

    for (jsonKey, jsonMapValue) in jsonObject {
      let mapKey = try convertJSONStringToMapKey(
        jsonKey,
        keyType: mapEntryInfo.keyFieldInfo.type,
        fieldName: field.name
      )

      let mapValue = try convertJSONValueToFieldType(
        jsonMapValue,
        type: mapEntryInfo.valueFieldInfo.type,
        typeName: mapEntryInfo.valueFieldInfo.typeName,
        fieldName: "\(field.name)[\(jsonKey)]",
        depth: depth,
        enumDescriptor: enumDesc
      )

      guard let hashableKey = mapKey as? AnyHashable else {
        throw JSONDeserializationError.invalidMapKey(
          fieldName: field.name,
          key: String(describing: mapKey)
        )
      }

      resultMap[hashableKey] = mapValue
    }

    return resultMap
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

  /// Converts JSON value to corresponding field type.
  private func convertJSONValueToFieldType(
    _ jsonValue: Any,
    type: FieldType,
    typeName: String?,
    fieldName: String,
    depth: Int,
    enumDescriptor: EnumDescriptor? = nil
  ) throws -> Any {

    switch type {
    case .double:
      return try convertJSONToDouble(jsonValue, fieldName: fieldName)

    case .float:
      return try convertJSONToFloat(jsonValue, fieldName: fieldName)

    case .int32, .sint32, .sfixed32:
      return try convertJSONToInt32(jsonValue, fieldName: fieldName)

    case .int64, .sint64, .sfixed64:
      return try convertJSONToInt64(jsonValue, fieldName: fieldName)

    case .uint32, .fixed32:
      return try convertJSONToUInt32(jsonValue, fieldName: fieldName)

    case .uint64, .fixed64:
      return try convertJSONToUInt64(jsonValue, fieldName: fieldName)

    case .bool:
      return try convertJSONToBool(jsonValue, fieldName: fieldName)

    case .string:
      return try convertJSONToString(jsonValue, fieldName: fieldName)

    case .bytes:
      return try convertJSONToBytes(jsonValue, fieldName: fieldName)

    case .message:
      return try convertJSONToMessage(jsonValue, typeName: typeName, fieldName: fieldName, depth: depth)

    case .enum:
      return try convertJSONToEnum(jsonValue, fieldName: fieldName, enumDescriptor: enumDescriptor)

    case .group:
      return try convertJSONToMessage(jsonValue, typeName: typeName, fieldName: fieldName, depth: depth)
    }
  }

  // MARK: - JSON Value Conversion Methods

  /// Converts JSON value to Double.
  private func convertJSONToDouble(_ jsonValue: Any, fieldName: String) throws -> Double {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.doubleValue
    }
    else if let stringValue = jsonValue as? String {
      // Handle special values
      switch stringValue {
      case "Infinity":
        return Double.infinity
      case "-Infinity":
        return -Double.infinity
      case "NaN":
        return Double.nan
      default:
        guard let doubleValue = Double(stringValue) else {
          throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
        }
        return doubleValue
      }
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to Float.
  private func convertJSONToFloat(_ jsonValue: Any, fieldName: String) throws -> Float {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.floatValue
    }
    else if let stringValue = jsonValue as? String {
      // Handle special values
      switch stringValue {
      case "Infinity":
        return Float.infinity
      case "-Infinity":
        return -Float.infinity
      case "NaN":
        return Float.nan
      default:
        guard let floatValue = Float(stringValue) else {
          throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
        }
        return floatValue
      }
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to Int32.
  private func convertJSONToInt32(_ jsonValue: Any, fieldName: String) throws -> Int32 {
    if let numberValue = jsonValue as? NSNumber {
      let int64Value = numberValue.int64Value
      guard int64Value >= Int64(Int32.min) && int64Value <= Int64(Int32.max) else {
        throw JSONDeserializationError.numberOutOfRange(
          fieldName: fieldName,
          value: int64Value,
          expectedRange: "Int32"
        )
      }
      return Int32(int64Value)
    }
    else if let stringValue = jsonValue as? String {
      guard let int32Value = Int32(stringValue) else {
        throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return int32Value
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to Int64.
  private func convertJSONToInt64(_ jsonValue: Any, fieldName: String) throws -> Int64 {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.int64Value
    }
    else if let stringValue = jsonValue as? String {
      guard let int64Value = Int64(stringValue) else {
        throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return int64Value
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to UInt32.
  private func convertJSONToUInt32(_ jsonValue: Any, fieldName: String) throws -> UInt32 {
    if let numberValue = jsonValue as? NSNumber {
      let uint64Value = numberValue.uint64Value
      guard uint64Value <= UInt64(UInt32.max) else {
        throw JSONDeserializationError.numberOutOfRange(
          fieldName: fieldName,
          value: Int64(uint64Value),
          expectedRange: "UInt32"
        )
      }
      return UInt32(uint64Value)
    }
    else if let stringValue = jsonValue as? String {
      guard let uint32Value = UInt32(stringValue) else {
        throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return uint32Value
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to UInt64.
  private func convertJSONToUInt64(_ jsonValue: Any, fieldName: String) throws -> UInt64 {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.uint64Value
    }
    else if let stringValue = jsonValue as? String {
      guard let uint64Value = UInt64(stringValue) else {
        throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return uint64Value
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to Bool.
  private func convertJSONToBool(_ jsonValue: Any, fieldName: String) throws -> Bool {
    if let boolValue = jsonValue as? Bool {
      return boolValue
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Boolean",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to String.
  private func convertJSONToString(_ jsonValue: Any, fieldName: String) throws -> String {
    if let stringValue = jsonValue as? String {
      return stringValue
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to Data (from base64).
  private func convertJSONToBytes(_ jsonValue: Any, fieldName: String) throws -> Data {
    guard let base64String = jsonValue as? String else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "String (base64)",
        actual: String(describing: type(of: jsonValue))
      )
    }

    guard let data = Data(base64Encoded: base64String) else {
      throw JSONDeserializationError.invalidBase64(fieldName: fieldName, value: base64String)
    }

    return data
  }

  /// Normalises a proto type name for registry lookup.
  ///
  /// Proto descriptors store type names with a leading dot (e.g. `.pkg.Msg`).
  /// `TypeRegistry` stores them without the dot. This function removes the leading
  /// dot so lookups succeed regardless of which format the caller uses.
  private func normaliseTypeName(_ typeName: String) -> String {
    typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
  }

  /// Converts JSON value to DynamicMessage by resolving the descriptor from the type registry.
  private func convertJSONToMessage(
    _ jsonValue: Any,
    typeName: String?,
    fieldName: String,
    depth: Int
  ) throws -> DynamicMessage {
    guard let rawTypeName = typeName else {
      throw JSONDeserializationError.missingTypeName(fieldName: fieldName)
    }

    let lookupName = normaliseTypeName(rawTypeName)
    guard !lookupName.isEmpty else {
      throw JSONDeserializationError.missingTypeName(fieldName: fieldName)
    }

    // Route well-known type nested fields through the WKT dispatch layer.
    if WellKnownTypeDetector.isWellKnownType(lookupName) {
      if let nestedDescriptor = options.typeRegistry.findMessage(named: lookupName) {
        return try deserializeWKTFromAny(jsonValue, using: nestedDescriptor, depth: depth + 1)
      }
      throw JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: lookupName)
    }

    guard let jsonObject = jsonValue as? [String: Any] else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Object",
        actual: String(describing: type(of: jsonValue))
      )
    }

    guard let nestedDescriptor = options.typeRegistry.findMessage(named: lookupName) else {
      throw JSONDeserializationError.nestedMessageDescriptorNotFound(
        fieldName: fieldName,
        typeName: lookupName
      )
    }

    return try deserializeFromJSONObject(jsonObject, using: nestedDescriptor, depth: depth + 1)
  }

  /// Converts JSON value to enum.
  private func convertJSONToEnum(
    _ jsonValue: Any,
    fieldName: String,
    enumDescriptor: EnumDescriptor? = nil
  ) throws -> Int32 {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.int32Value
    }
    else if let stringValue = jsonValue as? String {
      if let enumDesc = enumDescriptor,
        let enumVal = enumDesc.value(named: stringValue)
      {
        return Int32(enumVal.number)
      }
      guard let enumValue = Int32(stringValue) else {
        throw JSONDeserializationError.invalidEnumValue(fieldName: fieldName, value: stringValue)
      }
      return enumValue
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON string to map key.
  private func convertJSONStringToMapKey(_ jsonKey: String, keyType: FieldType, fieldName: String) throws -> Any {
    switch keyType {
    case .string:
      return jsonKey

    case .int32, .sint32, .sfixed32:
      guard let int32Value = Int32(jsonKey) else {
        throw JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "Int32",
          value: jsonKey
        )
      }
      return int32Value

    case .int64, .sint64, .sfixed64:
      guard let int64Value = Int64(jsonKey) else {
        throw JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "Int64",
          value: jsonKey
        )
      }
      return int64Value

    case .uint32, .fixed32:
      guard let uint32Value = UInt32(jsonKey) else {
        throw JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "UInt32",
          value: jsonKey
        )
      }
      return uint32Value

    case .uint64, .fixed64:
      guard let uint64Value = UInt64(jsonKey) else {
        throw JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "UInt64",
          value: jsonKey
        )
      }
      return uint64Value

    case .bool:
      switch jsonKey {
      case "true":
        return true
      case "false":
        return false
      default:
        throw JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "Bool",
          value: jsonKey
        )
      }

    default:
      throw JSONDeserializationError.invalidMapKeyType(
        fieldName: fieldName,
        keyType: String(describing: keyType)
      )
    }
  }
}

// MARK: - JSON Deserialization Options

/// Options for JSON deserialization.
public struct JSONDeserializationOptions {
  /// Ignore unknown fields in JSON.
  public let ignoreUnknownFields: Bool

  /// Strict type validation.
  public let strictTypeValidation: Bool

  /// Registry for resolving nested message descriptors by fully-qualified name.
  ///
  /// Pass a populated `TypeRegistry` to enable cross-file and sibling-message resolution.
  /// For hand-built descriptors without cross-file references, an empty `TypeRegistry()` is sufficient.
  public let typeRegistry: TypeRegistry

  /// Maximum allowed nesting depth for recursive message deserialization.
  public let maxNestingDepth: Int

  /// Creates JSON deserialization options with a required TypeRegistry.
  ///
  /// - Parameters:
  ///   - ignoreUnknownFields: Whether to ignore unknown JSON fields. Defaults to `true`.
  ///   - strictTypeValidation: Whether to enforce strict type validation. Defaults to `true`.
  ///   - typeRegistry: Registry for resolving nested message types by fully-qualified name.
  ///   - maxNestingDepth: Maximum allowed nesting depth. Defaults to `64`.
  public init(
    ignoreUnknownFields: Bool = true,
    strictTypeValidation: Bool = true,
    typeRegistry: TypeRegistry,
    maxNestingDepth: Int = 64
  ) {
    self.ignoreUnknownFields = ignoreUnknownFields
    self.strictTypeValidation = strictTypeValidation
    self.typeRegistry = typeRegistry
    self.maxNestingDepth = maxNestingDepth
  }

  /// Creates JSON deserialization options with an empty TypeRegistry.
  ///
  /// - Note: Deprecated. Use `init(ignoreUnknownFields:strictTypeValidation:typeRegistry:maxNestingDepth:)`
  ///   with an explicit `TypeRegistry` so that cross-file message types can be resolved correctly.
  @available(
    *,
    deprecated,
    message:
      "Use init(ignoreUnknownFields:strictTypeValidation:typeRegistry:maxNestingDepth:) with an explicit TypeRegistry"
  )
  public init(
    ignoreUnknownFields: Bool = true,
    strictTypeValidation: Bool = true,
    maxNestingDepth: Int = 64
  ) {
    self.init(
      ignoreUnknownFields: ignoreUnknownFields,
      strictTypeValidation: strictTypeValidation,
      typeRegistry: TypeRegistry(),
      maxNestingDepth: maxNestingDepth
    )
  }
}

// MARK: - JSON Deserialization Errors

/// JSON deserialization errors.
public enum JSONDeserializationError: Error, Equatable {
  case invalidJSON(underlyingError: Error)
  case invalidJSONStructure(expected: String, actual: String)
  case unknownField(fieldName: String, messageName: String)
  case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
  case valueTypeMismatch(fieldName: String, expected: String, actual: String)
  case invalidNumberFormat(fieldName: String, value: String)
  case numberOutOfRange(fieldName: String, value: Int64, expectedRange: String)
  case invalidBase64(fieldName: String, value: String)
  case invalidEnumValue(fieldName: String, value: String)
  case invalidMapKeyFormat(fieldName: String, keyType: String, value: String)
  case invalidMapKeyType(fieldName: String, keyType: String)
  case invalidMapKey(fieldName: String, key: String)
  case invalidArrayElement(fieldName: String, index: Int, underlyingError: Error)
  case missingMapEntryInfo(fieldName: String)
  case missingTypeName(fieldName: String)
  case unsupportedNestedMessage(fieldName: String, typeName: String)
  case nestedMessageDescriptorNotFound(fieldName: String, typeName: String)
  case nestingDepthExceeded(maxDepth: Int)
  case unsupportedFieldType(type: String)
  /// Canonical JSON decoding for a well-known type is not yet implemented.
  case unsupportedWellKnownTypeDecoding(typeName: String)

  public var description: String {
    switch self {
    case .invalidJSON(let underlyingError):
      return "Invalid JSON: \(underlyingError.localizedDescription)"
    case .invalidJSONStructure(let expected, let actual):
      return "Invalid JSON structure: expected \(expected), got \(actual)"
    case .unknownField(let fieldName, let messageName):
      return "Unknown field '\(fieldName)' in message '\(messageName)'"
    case .invalidFieldType(let fieldName, let expectedType, let actualType):
      return "Invalid field type for '\(fieldName)': expected \(expectedType), got \(actualType)"
    case .valueTypeMismatch(let fieldName, let expected, let actual):
      return "Value type mismatch for field '\(fieldName)': expected \(expected), got \(actual)"
    case .invalidNumberFormat(let fieldName, let value):
      return "Invalid number format for field '\(fieldName)': \(value)"
    case .numberOutOfRange(let fieldName, let value, let expectedRange):
      return "Number out of range for field '\(fieldName)': \(value) (expected \(expectedRange))"
    case .invalidBase64(let fieldName, let value):
      return "Invalid base64 string for field '\(fieldName)': \(value)"
    case .invalidEnumValue(let fieldName, let value):
      return "Invalid enum value for field '\(fieldName)': \(value)"
    case .invalidMapKeyFormat(let fieldName, let keyType, let value):
      return "Invalid map key format for field '\(fieldName)': expected \(keyType), got '\(value)'"
    case .invalidMapKeyType(let fieldName, let keyType):
      return "Invalid map key type for field '\(fieldName)': \(keyType)"
    case .invalidMapKey(let fieldName, let key):
      return "Invalid map key for field '\(fieldName)': \(key)"
    case .invalidArrayElement(let fieldName, let index, let underlyingError):
      return "Invalid array element for field '\(fieldName)' at index \(index): \(underlyingError.localizedDescription)"
    case .missingMapEntryInfo(let fieldName):
      return "Missing map entry info for field '\(fieldName)'"
    case .missingTypeName(let fieldName):
      return "Missing type name for field '\(fieldName)'"
    case .unsupportedNestedMessage(let fieldName, let typeName):
      return "Unsupported nested message for field '\(fieldName)': \(typeName)"
    case .nestedMessageDescriptorNotFound(let fieldName, let typeName):
      return "Nested message descriptor not found for field '\(fieldName)': \(typeName)"
    case .nestingDepthExceeded(let maxDepth):
      return "Nesting depth exceeded maximum of \(maxDepth)"
    case .unsupportedFieldType(let type):
      return "Unsupported field type: \(type)"
    case .unsupportedWellKnownTypeDecoding(let typeName):
      return "Canonical JSON decoding for well-known type '\(typeName)' is not yet implemented"
    }
  }

  public static func == (lhs: JSONDeserializationError, rhs: JSONDeserializationError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidJSON(_), .invalidJSON(_)):
      return true  // Hard to compare underlying errors
    case (
      .invalidJSONStructure(let lExpected, let lActual),
      .invalidJSONStructure(let rExpected, let rActual)
    ):
      return lExpected == rExpected && lActual == rActual
    case (
      .unknownField(let lField, let lMessage),
      .unknownField(let rField, let rMessage)
    ):
      return lField == rField && lMessage == rMessage
    case (
      .invalidFieldType(let lField, let lExpected, let lActual),
      .invalidFieldType(let rField, let rExpected, let rActual)
    ):
      return lField == rField && lExpected == rExpected && lActual == rActual
    case (
      .valueTypeMismatch(let lField, let lExpected, let lActual),
      .valueTypeMismatch(let rField, let rExpected, let rActual)
    ):
      return lField == rField && lExpected == rExpected && lActual == rActual
    case (
      .invalidNumberFormat(let lField, let lValue),
      .invalidNumberFormat(let rField, let rValue)
    ):
      return lField == rField && lValue == rValue
    case (
      .numberOutOfRange(let lField, let lValue, let lRange),
      .numberOutOfRange(let rField, let rValue, let rRange)
    ):
      return lField == rField && lValue == rValue && lRange == rRange
    case (
      .invalidBase64(let lField, let lValue),
      .invalidBase64(let rField, let rValue)
    ):
      return lField == rField && lValue == rValue
    case (
      .invalidEnumValue(let lField, let lValue),
      .invalidEnumValue(let rField, let rValue)
    ):
      return lField == rField && lValue == rValue
    case (
      .invalidMapKeyFormat(let lField, let lType, let lValue),
      .invalidMapKeyFormat(let rField, let rType, let rValue)
    ):
      return lField == rField && lType == rType && lValue == rValue
    case (
      .invalidMapKeyType(let lField, let lType),
      .invalidMapKeyType(let rField, let rType)
    ):
      return lField == rField && lType == rType
    case (
      .invalidMapKey(let lField, let lKey),
      .invalidMapKey(let rField, let rKey)
    ):
      return lField == rField && lKey == rKey
    case (
      .invalidArrayElement(let lField, let lIndex, _),
      .invalidArrayElement(let rField, let rIndex, _)
    ):
      return lField == rField && lIndex == rIndex  // Don't compare underlying errors
    case (.missingMapEntryInfo(let lField), .missingMapEntryInfo(let rField)):
      return lField == rField
    case (.missingTypeName(let lField), .missingTypeName(let rField)):
      return lField == rField
    case (
      .unsupportedNestedMessage(let lField, let lType),
      .unsupportedNestedMessage(let rField, let rType)
    ):
      return lField == rField && lType == rType
    case (
      .nestedMessageDescriptorNotFound(let lField, let lType),
      .nestedMessageDescriptorNotFound(let rField, let rType)
    ):
      return lField == rField && lType == rType
    case (.nestingDepthExceeded(let lMax), .nestingDepthExceeded(let rMax)):
      return lMax == rMax
    case (.unsupportedFieldType(let lType), .unsupportedFieldType(let rType)):
      return lType == rType
    case (
      .unsupportedWellKnownTypeDecoding(let lType),
      .unsupportedWellKnownTypeDecoding(let rType)
    ):
      return lType == rType
    default:
      return false
    }
  }
}
