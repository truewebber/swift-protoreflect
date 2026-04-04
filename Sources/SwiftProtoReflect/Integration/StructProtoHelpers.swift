//
// StructProtoHelpers.swift
// SwiftProtoReflect
//
// Internal helpers for bi-directional conversion between StructHandler.ValueValue
// and DynamicMessage using the canonical struct.proto field schema.
//
// These functions are intentionally internal so they can be shared by
// StructHandler, ValueHandler, and ListValueHandler without leaking
// implementation details into the public API.
//

// MARK: - Value ↔ DynamicMessage

/// Converts a `ValueValue` to a `DynamicMessage` with descriptor `google.protobuf.Value`.
///
/// Encodes the active oneof field using the real struct.proto field numbers:
/// null_value=1, number_value=2, string_value=3, bool_value=4, struct_value=5, list_value=6.
func valueValueToDynamicMessage(_ value: StructHandler.ValueValue) throws -> DynamicMessage {
  var message = DynamicMessage(descriptor: StructProtoDescriptors.valueDescriptor)

  switch value {
  case .nullValue:
    try message.set(Int32(0), forField: 1)
  case .numberValue(let d):
    try message.set(d, forField: 2)
  case .stringValue(let s):
    try message.set(s, forField: 3)
  case .boolValue(let b):
    try message.set(b, forField: 4)
  case .structValue(let s):
    try message.set(try _structValueToDynamicMessage(s), forField: 5)
  case .listValue(let l):
    try message.set(try _listValueToDynamicMessage(l), forField: 6)
  }

  return message
}

/// Converts a `DynamicMessage` with descriptor `google.protobuf.Value` back to a `ValueValue`.
///
/// Inspects fields 1–6 in order and returns the first set field.
/// Returns `.nullValue` when no field is set (proto3 zero-value default).
func dynamicMessageToValueValue(_ message: DynamicMessage) throws -> StructHandler.ValueValue {
  if (try? message.hasValue(forField: 1)) == true {
    return .nullValue
  }
  if (try? message.hasValue(forField: 2)) == true {
    guard let d = try message.get(forField: 2) as? Double else {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage(Value)",
        to: "ValueValue",
        reason: "field 2 (number_value) is not a Double"
      )
    }
    return .numberValue(d)
  }
  if (try? message.hasValue(forField: 3)) == true {
    guard let s = try message.get(forField: 3) as? String else {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage(Value)",
        to: "ValueValue",
        reason: "field 3 (string_value) is not a String"
      )
    }
    return .stringValue(s)
  }
  if (try? message.hasValue(forField: 4)) == true {
    guard let b = try message.get(forField: 4) as? Bool else {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage(Value)",
        to: "ValueValue",
        reason: "field 4 (bool_value) is not a Bool"
      )
    }
    return .boolValue(b)
  }
  if (try? message.hasValue(forField: 5)) == true {
    guard let nested = try message.get(forField: 5) as? DynamicMessage else {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage(Value)",
        to: "ValueValue",
        reason: "field 5 (struct_value) is not a DynamicMessage"
      )
    }
    return .structValue(try _dynamicMessageToStructValue(nested))
  }
  if (try? message.hasValue(forField: 6)) == true {
    guard let nested = try message.get(forField: 6) as? DynamicMessage else {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage(Value)",
        to: "ValueValue",
        reason: "field 6 (list_value) is not a DynamicMessage"
      )
    }
    return .listValue(try _dynamicMessageToListValue(nested))
  }
  return .nullValue
}

// MARK: - Struct helpers

/// Encodes a `StructValue` into a `DynamicMessage` with descriptor `google.protobuf.Struct`.
///
/// Each field entry becomes a map entry in field 1 (`map<string, google.protobuf.Value>`).
func _structValueToDynamicMessage(_ structValue: StructHandler.StructValue) throws -> DynamicMessage {
  var message = DynamicMessage(descriptor: StructProtoDescriptors.structDescriptor)

  for (key, value) in structValue.fields {
    let valueMsg = try valueValueToDynamicMessage(value)
    try message.setMapEntry(valueMsg, forKey: key, inField: 1)
  }

  return message
}

/// Decodes a `DynamicMessage` with descriptor `google.protobuf.Struct` into a
/// `StructValue` by reading the `map<string, Value>` at field 1.
func _dynamicMessageToStructValue(_ message: DynamicMessage) throws -> StructHandler.StructValue {
  let rawMap = try message.get(forField: 1) as? [AnyHashable: Any] ?? [:]
  var fields: [String: StructHandler.ValueValue] = [:]

  for (key, value) in rawMap {
    guard let stringKey = key as? String else {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage(Struct)",
        to: "StructValue",
        reason: "map key is not a String"
      )
    }
    guard let valueMsg = value as? DynamicMessage else {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage(Struct)",
        to: "StructValue",
        reason: "map value for key '\(stringKey)' is not a DynamicMessage"
      )
    }
    fields[stringKey] = try dynamicMessageToValueValue(valueMsg)
  }

  return StructHandler.StructValue(fields: fields)
}

// MARK: - ListValue helpers

/// Encodes a list of `ValueValue` elements into a `DynamicMessage` with descriptor `google.protobuf.ListValue`.
///
/// Each element becomes a repeated entry in field 1 (`repeated google.protobuf.Value`).
func _listValueToDynamicMessage(_ list: [StructHandler.ValueValue]) throws -> DynamicMessage {
  var message = DynamicMessage(descriptor: StructProtoDescriptors.listValueDescriptor)

  for item in list {
    let valueMsg = try valueValueToDynamicMessage(item)
    try message.addRepeatedValue(valueMsg, forField: 1)
  }

  return message
}

/// Decodes a `DynamicMessage` with descriptor `google.protobuf.ListValue` into a
/// `[ValueValue]` by reading the repeated `google.protobuf.Value` field at field 1.
func _dynamicMessageToListValue(_ message: DynamicMessage) throws -> [StructHandler.ValueValue] {
  let rawList = try message.get(forField: 1) as? [Any] ?? []

  return try rawList.map { item in
    guard let valueMsg = item as? DynamicMessage else {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage(ListValue)",
        to: "[ValueValue]",
        reason: "repeated element is not a DynamicMessage"
      )
    }
    return try dynamicMessageToValueValue(valueMsg)
  }
}
