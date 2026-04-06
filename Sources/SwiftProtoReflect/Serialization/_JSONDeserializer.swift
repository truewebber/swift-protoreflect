//
// _JSONDeserializer.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation

internal struct _JSONDeserializer {

  // MARK: - Properties

  let options: _JSONDeserializationOptions

  // MARK: - Deserialization Methods

  func deserialize(_ data: Data, using descriptor: _MessageDescriptor) throws -> _DynamicMessage {
    let jsonValue: Any
    do {
      jsonValue = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    }
    catch {
      throw _JSONDeserializationError.invalidJSON(underlyingError: error)
    }

    if WellKnownTypeDetector.isWellKnownType(descriptor.fullName) {
      return try deserializeWKTFromAny(jsonValue, using: descriptor, depth: 0)
    }

    guard let jsonDictionary = jsonValue as? [String: Any] else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "Object",
        actual: String(describing: type(of: jsonValue))
      )
    }

    return try deserializeFromJSONObject(jsonDictionary, using: descriptor)
  }

  internal func deserializeWKTFromAny(
    _ jsonValue: Any,
    using descriptor: _MessageDescriptor,
    depth: Int
  ) throws -> _DynamicMessage {
    switch descriptor.fullName {
    case WellKnownTypeNames.empty:
      guard let jsonObj = jsonValue as? [String: Any] else {
        throw _JSONDeserializationError.invalidJSONStructure(
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
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "Object",
          actual: String(describing: type(of: jsonValue))
        )
      }
      return try decodeStructFromObject(jsonObj, depth: depth)
    case WellKnownTypeNames.listValue:
      guard let jsonArr = jsonValue as? [Any] else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "Array",
          actual: String(describing: type(of: jsonValue))
        )
      }
      return try decodeListValueFromArray(jsonArr, depth: depth)
    case WellKnownTypeNames.any:
      return try decodeAnyFromAny(jsonValue, using: descriptor)
    case WellKnownTypeNames.doubleValue,
      WellKnownTypeNames.floatValue,
      WellKnownTypeNames.int32Value,
      WellKnownTypeNames.uint32Value,
      WellKnownTypeNames.int64Value,
      WellKnownTypeNames.uint64Value,
      WellKnownTypeNames.boolValue,
      WellKnownTypeNames.stringValue,
      WellKnownTypeNames.bytesValue:
      return try decodeWrapperFromAny(jsonValue, using: descriptor)
    default:
      throw _JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: descriptor.fullName)
    }
  }

  private func decodeAnyFromAny(_ jsonValue: Any, using descriptor: _MessageDescriptor) throws -> _DynamicMessage {
    guard let jsonObj = jsonValue as? [String: Any] else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "Object",
        actual: String(describing: type(of: jsonValue))
      )
    }
    guard let typeUrl = jsonObj["@type"] as? String else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "Object with @type key",
        actual: "Object without @type"
      )
    }

    guard let slashIdx = typeUrl.lastIndex(of: "/") else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "Valid type URL (e.g. type.googleapis.com/pkg.Msg)",
        actual: typeUrl
      )
    }
    let typeName = String(typeUrl[typeUrl.index(after: slashIdx)...])

    guard let packedDescriptor = options.typeRegistry.findMessage(named: typeName) else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "Registered message type",
        actual: typeName
      )
    }

    let packedMessage: _DynamicMessage
    if WellKnownTypeDetector.isWellKnownType(typeName) {
      let canonicalValue = jsonObj["value"] ?? NSNull()
      packedMessage = try deserializeWKTFromAny(canonicalValue, using: packedDescriptor, depth: 0)
    }
    else {
      var fieldsOnly = jsonObj
      fieldsOnly.removeValue(forKey: "@type")
      packedMessage = try deserializeFromJSONObject(fieldsOnly, using: packedDescriptor)
    }

    let binaryData = try _BinarySerializer().serialize(packedMessage)

    var anyMsg = _DynamicMessage(descriptor: descriptor)
    try anyMsg.set(typeUrl, forField: 1)
    try anyMsg.set(binaryData, forField: 2)
    return anyMsg
  }

  private func decodeWrapperFromAny(_ jsonValue: Any, using descriptor: _MessageDescriptor) throws -> _DynamicMessage {
    let fullName = descriptor.fullName
    var msg = _DynamicMessage(descriptor: descriptor)

    if jsonValue is NSNull {
      return msg
    }

    switch fullName {
    case WellKnownTypeNames.doubleValue:
      guard let number = jsonValue as? NSNumber, !isJSONBool(number) else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "Number",
          actual: String(describing: type(of: jsonValue))
        )
      }
      try msg.set(number.doubleValue, forField: 1)

    case WellKnownTypeNames.floatValue:
      guard let number = jsonValue as? NSNumber, !isJSONBool(number) else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "Number",
          actual: String(describing: type(of: jsonValue))
        )
      }
      try msg.set(Float(number.doubleValue), forField: 1)

    case WellKnownTypeNames.int32Value:
      guard let number = jsonValue as? NSNumber, !isJSONBool(number) else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "Number",
          actual: String(describing: type(of: jsonValue))
        )
      }
      try msg.set(Int32(truncatingIfNeeded: number.int64Value), forField: 1)

    case WellKnownTypeNames.uint32Value:
      guard let number = jsonValue as? NSNumber, !isJSONBool(number) else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "Number",
          actual: String(describing: type(of: jsonValue))
        )
      }
      try msg.set(UInt32(truncatingIfNeeded: number.uint64Value), forField: 1)

    case WellKnownTypeNames.int64Value:
      guard let str = jsonValue as? String, let value = Int64(str) else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "String (Int64)",
          actual: String(describing: type(of: jsonValue))
        )
      }
      try msg.set(value, forField: 1)

    case WellKnownTypeNames.uint64Value:
      guard let str = jsonValue as? String, let value = UInt64(str) else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "String (UInt64)",
          actual: String(describing: type(of: jsonValue))
        )
      }
      try msg.set(value, forField: 1)

    case WellKnownTypeNames.boolValue:
      guard let number = jsonValue as? NSNumber, isJSONBool(number) else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "Boolean",
          actual: String(describing: type(of: jsonValue))
        )
      }
      try msg.set(number.boolValue, forField: 1)

    case WellKnownTypeNames.stringValue:
      guard let str = jsonValue as? String else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "String",
          actual: String(describing: type(of: jsonValue))
        )
      }
      try msg.set(str, forField: 1)

    case WellKnownTypeNames.bytesValue:
      guard let str = jsonValue as? String, let data = Data(base64Encoded: str) else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "String (base64)",
          actual: String(describing: type(of: jsonValue))
        )
      }
      try msg.set(data, forField: 1)

    default:
      throw _JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: fullName)
    }

    return msg
  }

  private func decodeTimestampFromAny(
    _ jsonValue: Any,
    using descriptor: _MessageDescriptor
  ) throws -> _DynamicMessage {
    guard let str = jsonValue as? String else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "String",
        actual: String(describing: type(of: jsonValue))
      )
    }

    var datePart = str
    var nanosDigits: String? = nil

    if let dotIdx = str.firstIndex(of: ".") {
      let beforeDot = String(str[str.startIndex..<dotIdx])
      let afterDot = String(str[str.index(after: dotIdx)...])

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

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
    guard let date = formatter.date(from: datePart) else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "RFC 3339 timestamp string",
        actual: str
      )
    }

    let seconds = Int64(date.timeIntervalSince1970)

    let nanos: Int32
    if let digits = nanosDigits, !digits.isEmpty {
      var padded = digits
      while padded.count < 9 { padded += "0" }
      if padded.count > 9 { padded = String(padded.prefix(9)) }
      guard let value = Int32(padded) else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "Valid fractional seconds",
          actual: str
        )
      }
      nanos = value
    }
    else {
      nanos = 0
    }

    var msg = _DynamicMessage(descriptor: descriptor)
    try msg.set(seconds, forField: 1)
    if nanos != 0 {
      try msg.set(nanos, forField: 2)
    }
    return msg
  }

  private func decodeDurationFromAny(
    _ jsonValue: Any,
    using descriptor: _MessageDescriptor
  ) throws -> _DynamicMessage {
    guard let str = jsonValue as? String else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "String",
        actual: String(describing: type(of: jsonValue))
      )
    }

    guard str.hasSuffix("s") else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "Duration string ending in 's'",
        actual: str
      )
    }

    let withoutSuffix = String(str.dropLast())
    let isNegative = withoutSuffix.hasPrefix("-")
    let numericPart = isNegative ? String(withoutSuffix.dropFirst()) : withoutSuffix

    let dotComponents = numericPart.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
    guard let firstComponent = dotComponents.first, !firstComponent.isEmpty else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "Valid duration string",
        actual: str
      )
    }

    guard let absSeconds = Int64(firstComponent) else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "Valid duration string",
        actual: str
      )
    }

    let absNanos: Int32
    if dotComponents.count > 1 {
      let fracPart = String(dotComponents[1])
      guard !fracPart.isEmpty, fracPart.allSatisfy({ $0.isNumber }) else {
        throw _JSONDeserializationError.invalidJSONStructure(
          expected: "Valid duration string",
          actual: str
        )
      }
      var padded = fracPart
      while padded.count < 9 { padded += "0" }
      if padded.count > 9 { padded = String(padded.prefix(9)) }
      guard let value = Int32(padded) else {
        throw _JSONDeserializationError.invalidJSONStructure(
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

    var msg = _DynamicMessage(descriptor: descriptor)
    try msg.set(seconds, forField: 1)
    if nanos != 0 {
      try msg.set(nanos, forField: 2)
    }
    return msg
  }

  private func decodeFieldMaskFromAny(
    _ jsonValue: Any,
    using descriptor: _MessageDescriptor
  ) throws -> _DynamicMessage {
    guard let str = jsonValue as? String else {
      throw _JSONDeserializationError.invalidJSONStructure(
        expected: "String",
        actual: String(describing: type(of: jsonValue))
      )
    }

    var msg = _DynamicMessage(descriptor: descriptor)
    guard !str.isEmpty else {
      return msg
    }

    let paths = str.split(separator: ",", omittingEmptySubsequences: false).map { camelToSnakeCase(String($0)) }
    try msg.set(paths, forField: 1)
    return msg
  }

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

  private func decodeValueFromAny(_ jsonValue: Any, depth: Int) throws -> _DynamicMessage {
    guard depth <= options.maxNestingDepth else {
      throw _JSONDeserializationError.nestingDepthExceeded(maxDepth: options.maxNestingDepth)
    }
    var msg = _DynamicMessage(descriptor: _MessageDescriptor(from: StructProtoDescriptors.valueDescriptor))
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

  private func decodeStructFromObject(_ jsonObj: [String: Any], depth: Int) throws -> _DynamicMessage {
    guard depth <= options.maxNestingDepth else {
      throw _JSONDeserializationError.nestingDepthExceeded(maxDepth: options.maxNestingDepth)
    }
    var msg = _DynamicMessage(descriptor: _MessageDescriptor(from: StructProtoDescriptors.structDescriptor))
    for (key, value) in jsonObj {
      let valueMsg = try decodeValueFromAny(value, depth: depth + 1)
      try msg.setMapEntry(valueMsg, forKey: key, inField: 1)
    }
    return msg
  }

  private func decodeListValueFromArray(_ jsonArr: [Any], depth: Int) throws -> _DynamicMessage {
    guard depth <= options.maxNestingDepth else {
      throw _JSONDeserializationError.nestingDepthExceeded(maxDepth: options.maxNestingDepth)
    }
    var msg = _DynamicMessage(descriptor: _MessageDescriptor(from: StructProtoDescriptors.listValueDescriptor))
    for item in jsonArr {
      let valueMsg = try decodeValueFromAny(item, depth: depth + 1)
      try msg.addRepeatedValue(valueMsg, forField: 1)
    }
    return msg
  }

  private func isJSONBool(_ number: NSNumber) -> Bool {
    #if canImport(CoreFoundation) && !os(Linux)
      return CFGetTypeID(number) == CFBooleanGetTypeID()
    #else
      let objCType = String(cString: number.objCType)
      return objCType == "c" || objCType == "B"
    #endif
  }

  internal func deserializeFromJSONObject(_ jsonObject: [String: Any], using descriptor: _MessageDescriptor) throws
    -> _DynamicMessage
  {
    return try deserializeFromJSONObject(jsonObject, using: descriptor, depth: 0)
  }

  private func deserializeFromJSONObject(
    _ jsonObject: [String: Any],
    using descriptor: _MessageDescriptor,
    depth: Int
  ) throws -> _DynamicMessage {
    guard depth <= options.maxNestingDepth else {
      throw _JSONDeserializationError.nestingDepthExceeded(maxDepth: options.maxNestingDepth)
    }

    let factory = _MessageFactory()
    var message = factory.createMessage(from: descriptor)

    for (jsonFieldName, jsonValue) in jsonObject {
      guard let field = findField(byJSONName: jsonFieldName, in: descriptor) else {
        if options.ignoreUnknownFields {
          continue
        }
        else {
          throw _JSONDeserializationError.unknownField(fieldName: jsonFieldName, messageName: descriptor.name)
        }
      }

      let fieldValue = try deserializeFieldValue(jsonValue, for: field, descriptor: descriptor, depth: depth)
      try message.set(fieldValue, forField: field.number)
    }

    return message
  }

  // MARK: - Private Methods

  private func findField(byJSONName jsonName: String, in descriptor: _MessageDescriptor) -> _FieldDescriptor? {
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

  private func deserializeFieldValue(
    _ jsonValue: Any,
    for field: _FieldDescriptor,
    descriptor: _MessageDescriptor,
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

  private func deserializeSingleField(
    _ jsonValue: Any,
    for field: _FieldDescriptor,
    descriptor: _MessageDescriptor,
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

  private func deserializeRepeatedField(
    _ jsonValue: Any,
    for field: _FieldDescriptor,
    descriptor: _MessageDescriptor,
    depth: Int
  ) throws -> Any {
    guard let jsonArray = jsonValue as? [Any] else {
      throw _JSONDeserializationError.invalidFieldType(
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
        throw _JSONDeserializationError.invalidArrayElement(
          fieldName: field.name,
          index: index,
          underlyingError: error
        )
      }
    }

    return resultArray
  }

  private func deserializeMapField(
    _ jsonValue: Any,
    for field: _FieldDescriptor,
    descriptor: _MessageDescriptor,
    depth: Int
  ) throws -> Any {
    guard let jsonObject = jsonValue as? [String: Any] else {
      throw _JSONDeserializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Object",
        actualType: String(describing: type(of: jsonValue))
      )
    }

    guard let mapEntryInfo = field.mapEntryInfo else {
      throw _JSONDeserializationError.missingMapEntryInfo(fieldName: field.name)
    }

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
        throw _JSONDeserializationError.invalidMapKey(
          fieldName: field.name,
          key: String(describing: mapKey)
        )
      }

      resultMap[hashableKey] = mapValue
    }

    return resultMap
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

  private func convertJSONValueToFieldType(
    _ jsonValue: Any,
    type: _FieldType,
    typeName: String?,
    fieldName: String,
    depth: Int,
    enumDescriptor: _EnumDescriptor? = nil
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

  private func convertJSONToDouble(_ jsonValue: Any, fieldName: String) throws -> Double {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.doubleValue
    }
    else if let stringValue = jsonValue as? String {
      switch stringValue {
      case "Infinity":
        return Double.infinity
      case "-Infinity":
        return -Double.infinity
      case "NaN":
        return Double.nan
      default:
        guard let doubleValue = Double(stringValue) else {
          throw _JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
        }
        return doubleValue
      }
    }
    else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  private func convertJSONToFloat(_ jsonValue: Any, fieldName: String) throws -> Float {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.floatValue
    }
    else if let stringValue = jsonValue as? String {
      switch stringValue {
      case "Infinity":
        return Float.infinity
      case "-Infinity":
        return -Float.infinity
      case "NaN":
        return Float.nan
      default:
        guard let floatValue = Float(stringValue) else {
          throw _JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
        }
        return floatValue
      }
    }
    else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  private func convertJSONToInt32(_ jsonValue: Any, fieldName: String) throws -> Int32 {
    if let numberValue = jsonValue as? NSNumber {
      let int64Value = numberValue.int64Value
      guard int64Value >= Int64(Int32.min) && int64Value <= Int64(Int32.max) else {
        throw _JSONDeserializationError.numberOutOfRange(
          fieldName: fieldName,
          value: int64Value,
          expectedRange: "Int32"
        )
      }
      return Int32(int64Value)
    }
    else if let stringValue = jsonValue as? String {
      guard let int32Value = Int32(stringValue) else {
        throw _JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return int32Value
    }
    else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  private func convertJSONToInt64(_ jsonValue: Any, fieldName: String) throws -> Int64 {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.int64Value
    }
    else if let stringValue = jsonValue as? String {
      guard let int64Value = Int64(stringValue) else {
        throw _JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return int64Value
    }
    else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  private func convertJSONToUInt32(_ jsonValue: Any, fieldName: String) throws -> UInt32 {
    if let numberValue = jsonValue as? NSNumber {
      let uint64Value = numberValue.uint64Value
      guard uint64Value <= UInt64(UInt32.max) else {
        throw _JSONDeserializationError.numberOutOfRange(
          fieldName: fieldName,
          value: Int64(uint64Value),
          expectedRange: "UInt32"
        )
      }
      return UInt32(uint64Value)
    }
    else if let stringValue = jsonValue as? String {
      guard let uint32Value = UInt32(stringValue) else {
        throw _JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return uint32Value
    }
    else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  private func convertJSONToUInt64(_ jsonValue: Any, fieldName: String) throws -> UInt64 {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.uint64Value
    }
    else if let stringValue = jsonValue as? String {
      guard let uint64Value = UInt64(stringValue) else {
        throw _JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return uint64Value
    }
    else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  private func convertJSONToBool(_ jsonValue: Any, fieldName: String) throws -> Bool {
    if let boolValue = jsonValue as? Bool {
      return boolValue
    }
    else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Boolean",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  private func convertJSONToString(_ jsonValue: Any, fieldName: String) throws -> String {
    if let stringValue = jsonValue as? String {
      return stringValue
    }
    else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  private func convertJSONToBytes(_ jsonValue: Any, fieldName: String) throws -> Data {
    guard let base64String = jsonValue as? String else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "String (base64)",
        actual: String(describing: type(of: jsonValue))
      )
    }

    guard let data = Data(base64Encoded: base64String) else {
      throw _JSONDeserializationError.invalidBase64(fieldName: fieldName, value: base64String)
    }

    return data
  }

  private func normaliseTypeName(_ typeName: String) -> String {
    typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
  }

  private func convertJSONToMessage(
    _ jsonValue: Any,
    typeName: String?,
    fieldName: String,
    depth: Int
  ) throws -> _DynamicMessage {
    guard let rawTypeName = typeName else {
      throw _JSONDeserializationError.missingTypeName(fieldName: fieldName)
    }

    let lookupName = normaliseTypeName(rawTypeName)
    guard !lookupName.isEmpty else {
      throw _JSONDeserializationError.missingTypeName(fieldName: fieldName)
    }

    if WellKnownTypeDetector.isWellKnownType(lookupName) {
      if let nestedDescriptor = options.typeRegistry.findMessage(named: lookupName) {
        return try deserializeWKTFromAny(jsonValue, using: nestedDescriptor, depth: depth + 1)
      }
      throw _JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: lookupName)
    }

    guard let jsonObject = jsonValue as? [String: Any] else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Object",
        actual: String(describing: type(of: jsonValue))
      )
    }

    guard let nestedDescriptor = options.typeRegistry.findMessage(named: lookupName) else {
      throw _JSONDeserializationError.nestedMessageDescriptorNotFound(
        fieldName: fieldName,
        typeName: lookupName
      )
    }

    return try deserializeFromJSONObject(jsonObject, using: nestedDescriptor, depth: depth + 1)
  }

  private func convertJSONToEnum(
    _ jsonValue: Any,
    fieldName: String,
    enumDescriptor: _EnumDescriptor? = nil
  ) throws -> Int32 {
    if jsonValue is NSNull {
      if let enumDesc = enumDescriptor, enumDesc.fullName == WellKnownTypeNames.nullValue {
        return Int32(0)
      }
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: "NSNull"
      )
    }
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.int32Value
    }
    else if let stringValue = jsonValue as? String {
      if let enumDesc = enumDescriptor,
        let enumVal = enumDesc.valuesByName[stringValue]
      {
        return Int32(enumVal.number)
      }
      guard let enumValue = Int32(stringValue) else {
        throw _JSONDeserializationError.invalidEnumValue(fieldName: fieldName, value: stringValue)
      }
      return enumValue
    }
    else {
      throw _JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  private func convertJSONStringToMapKey(_ jsonKey: String, keyType: _FieldType, fieldName: String) throws -> Any {
    switch keyType {
    case .string:
      return jsonKey

    case .int32, .sint32, .sfixed32:
      guard let int32Value = Int32(jsonKey) else {
        throw _JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "Int32",
          value: jsonKey
        )
      }
      return int32Value

    case .int64, .sint64, .sfixed64:
      guard let int64Value = Int64(jsonKey) else {
        throw _JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "Int64",
          value: jsonKey
        )
      }
      return int64Value

    case .uint32, .fixed32:
      guard let uint32Value = UInt32(jsonKey) else {
        throw _JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "UInt32",
          value: jsonKey
        )
      }
      return uint32Value

    case .uint64, .fixed64:
      guard let uint64Value = UInt64(jsonKey) else {
        throw _JSONDeserializationError.invalidMapKeyFormat(
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
        throw _JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "Bool",
          value: jsonKey
        )
      }

    default:
      throw _JSONDeserializationError.invalidMapKeyType(
        fieldName: fieldName,
        keyType: String(describing: keyType)
      )
    }
  }
}

// MARK: - JSON Deserialization Options

internal struct _JSONDeserializationOptions {
  let ignoreUnknownFields: Bool
  let strictTypeValidation: Bool
  let typeRegistry: _TypeRegistry
  let maxNestingDepth: Int

  init(
    ignoreUnknownFields: Bool = true,
    strictTypeValidation: Bool = true,
    typeRegistry: _TypeRegistry,
    maxNestingDepth: Int = 64
  ) {
    self.ignoreUnknownFields = ignoreUnknownFields
    self.strictTypeValidation = strictTypeValidation
    self.typeRegistry = typeRegistry
    self.maxNestingDepth = maxNestingDepth
  }
}

// MARK: - JSON Deserialization Errors

internal enum _JSONDeserializationError: Error, Equatable {
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
  case unsupportedWellKnownTypeDecoding(typeName: String)

  var description: String {
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
      return
        "Invalid array element for field '\(fieldName)' at index \(index): \(underlyingError.localizedDescription)"
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

  static func == (lhs: _JSONDeserializationError, rhs: _JSONDeserializationError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidJSON(_), .invalidJSON(_)):
      return true
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
      return lField == rField && lIndex == rIndex
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
