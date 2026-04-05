// CompatDescriptors.swift
// SwiftProtoReflectTests
//
// Programmatic message/enum descriptors mirroring all 9 .proto fixture files.
// Used in JSON compatibility tests as the SwiftProtoReflect side of bidirectional testing.
//

import Foundation

@testable import SwiftProtoReflect

// swiftlint:disable file_length type_body_length function_body_length

// MARK: - Helpers

/// Converts snake_case field name to lowerCamelCase json_name per protobuf spec.
///
/// E.g. "double_field" → "doubleField", "http_request" → "httpRequest".
private func camelCaseJsonName(_ snake: String) -> String {
  let parts = snake.split(separator: "_", omittingEmptySubsequences: false)
  guard parts.count > 1 else { return snake }
  let first = String(parts[0])
  let rest = parts.dropFirst().map { word -> String in
    guard !word.isEmpty else { return "" }
    return word.prefix(1).uppercased() + word.dropFirst()
  }
  return ([first] + rest).joined()
}

/// Creates a FieldDescriptor with automatically computed camelCase jsonName (protobuf spec default).
private func fd(
  _ name: String,
  _ number: Int,
  _ type: SwiftProtoReflect.FieldType,
  typeName: String? = nil,
  jsonNameOverride: String? = nil,
  isRepeated: Bool = false,
  isOptional: Bool = false,
  isRequired: Bool = false,
  isMap: Bool = false,
  oneofIndex: Int? = nil,
  proto3Optional: Bool = false,
  mapEntryInfo: MapEntryInfo? = nil,
  defaultValue: DescriptorOption? = nil
) -> FieldDescriptor {
  FieldDescriptor(
    name: name,
    number: number,
    type: type,
    typeName: typeName,
    jsonName: jsonNameOverride ?? camelCaseJsonName(name),
    isRepeated: isRepeated,
    isOptional: isOptional,
    isRequired: isRequired,
    isMap: isMap,
    oneofIndex: oneofIndex,
    proto3Optional: proto3Optional,
    mapEntryInfo: mapEntryInfo,
    defaultValue: defaultValue
  )
}

private func mapFd(
  _ name: String,
  _ number: Int,
  keyType: SwiftProtoReflect.FieldType,
  valueType: SwiftProtoReflect.FieldType,
  valueTypeName: String? = nil
) -> FieldDescriptor {
  FieldDescriptor(
    name: name,
    number: number,
    type: .message,
    typeName: "\(name)Entry",
    jsonName: camelCaseJsonName(name),
    isMap: true,
    mapEntryInfo: MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: keyType),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: valueType, typeName: valueTypeName)
    )
  )
}

// MARK: - CompatDescriptors

/// Programmatic descriptors mirroring all 9 .proto fixture files.
enum CompatDescriptors {

  // MARK: - WKT Descriptors (reusable)

  static func wktTimestamp() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/timestamp.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "Timestamp", parent: file)
    desc.addField(fd("seconds", 1, .int64))
    desc.addField(fd("nanos", 2, .int32))
    file.addMessage(desc)
    return file.messages["Timestamp"]!
  }

  static func wktDuration() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/duration.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "Duration", parent: file)
    desc.addField(fd("seconds", 1, .int64))
    desc.addField(fd("nanos", 2, .int32))
    file.addMessage(desc)
    return file.messages["Duration"]!
  }

  static func wktFieldMask() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/field_mask.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "FieldMask", parent: file)
    desc.addField(fd("paths", 1, .string, isRepeated: true))
    file.addMessage(desc)
    return file.messages["FieldMask"]!
  }

  static func wktAny() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/any.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "Any", parent: file)
    desc.addField(fd("type_url", 1, .string))
    desc.addField(fd("value", 2, .bytes))
    file.addMessage(desc)
    return file.messages["Any"]!
  }

  static func wktStruct() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/struct.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "Struct", parent: file)
    desc.addField(mapFd("fields", 1, keyType: .string, valueType: .message, valueTypeName: "google.protobuf.Value"))
    file.addMessage(desc)
    return file.messages["Struct"]!
  }

  static func wktValue() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/struct.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "Value", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "kind", index: 0))
    desc.addField(fd("null_value", 1, .enum, typeName: "google.protobuf.NullValue", oneofIndex: 0))
    desc.addField(fd("number_value", 2, .double, oneofIndex: 0))
    desc.addField(fd("string_value", 3, .string, oneofIndex: 0))
    desc.addField(fd("bool_value", 4, .bool, oneofIndex: 0))
    desc.addField(fd("struct_value", 5, .message, typeName: "google.protobuf.Struct", oneofIndex: 0))
    desc.addField(fd("list_value", 6, .message, typeName: "google.protobuf.ListValue", oneofIndex: 0))
    file.addMessage(desc)
    return file.messages["Value"]!
  }

  static func wktListValue() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/struct.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "ListValue", parent: file)
    desc.addField(fd("values", 1, .message, typeName: "google.protobuf.Value", isRepeated: true))
    file.addMessage(desc)
    return file.messages["ListValue"]!
  }

  static func wktEmpty() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/empty.proto", package: "google.protobuf")
    let desc = MessageDescriptor(name: "Empty", parent: file)
    file.addMessage(desc)
    return file.messages["Empty"]!
  }

  static func wktWrapper(name: String, fieldType: SwiftProtoReflect.FieldType) -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/wrappers.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: name, parent: file)
    desc.addField(fd("value", 1, fieldType))
    file.addMessage(desc)
    return file.messages[name]!
  }

  static func wktNullValue() -> EnumDescriptor {
    var desc = EnumDescriptor(name: "NullValue", fullName: "google.protobuf.NullValue")
    desc.addValue(EnumDescriptor.EnumValue(name: "NULL_VALUE", number: 0))
    return desc
  }

  // MARK: - common_types.proto

  static func statusEnum() -> EnumDescriptor {
    var desc = EnumDescriptor(name: "Status", fullName: "testcompat.Status")
    desc.addValue(EnumDescriptor.EnumValue(name: "STATUS_UNSPECIFIED", number: 0))
    desc.addValue(EnumDescriptor.EnumValue(name: "STATUS_ACTIVE", number: 1))
    desc.addValue(EnumDescriptor.EnumValue(name: "STATUS_INACTIVE", number: 2))
    desc.addValue(EnumDescriptor.EnumValue(name: "STATUS_DELETED", number: 3))
    return desc
  }

  static func priorityEnum() -> EnumDescriptor {
    var desc = EnumDescriptor(
      name: "Priority",
      fullName: "testcompat.Priority",
      options: ["allow_alias": .bool(true)]
    )
    desc.addValue(EnumDescriptor.EnumValue(name: "PRIORITY_UNSPECIFIED", number: 0))
    desc.addValue(EnumDescriptor.EnumValue(name: "PRIORITY_LOW", number: 1))
    desc.addValue(EnumDescriptor.EnumValue(name: "PRIORITY_NORMAL", number: 2))
    desc.addValue(EnumDescriptor.EnumValue(name: "PRIORITY_MEDIUM", number: 2))
    desc.addValue(EnumDescriptor.EnumValue(name: "PRIORITY_HIGH", number: 3))
    desc.addValue(EnumDescriptor.EnumValue(name: "PRIORITY_CRITICAL", number: 4))
    return desc
  }

  static func directionEnum() -> EnumDescriptor {
    var desc = EnumDescriptor(name: "Direction", fullName: "testcompat.Direction")
    desc.addValue(EnumDescriptor.EnumValue(name: "DIRECTION_UNSPECIFIED", number: 0))
    desc.addValue(EnumDescriptor.EnumValue(name: "DIRECTION_UP", number: 1))
    desc.addValue(EnumDescriptor.EnumValue(name: "DIRECTION_DOWN", number: -1))
    desc.addValue(EnumDescriptor.EnumValue(name: "DIRECTION_LEFT", number: -2))
    desc.addValue(EnumDescriptor.EnumValue(name: "DIRECTION_RIGHT", number: 2))
    return desc
  }

  static func directionHolder() -> MessageDescriptor {
    var file = FileDescriptor(name: "common_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "DirectionHolder", parent: file)
    desc.addField(fd("dir", 1, .enum, typeName: "testcompat.Direction"))
    desc.addField(fd("dirs", 2, .enum, typeName: "testcompat.Direction", isRepeated: true))
    file.addMessage(desc)
    return file.messages["DirectionHolder"]!
  }

  static func simpleMessage() -> MessageDescriptor {
    var file = FileDescriptor(name: "common_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "SimpleMessage", parent: file)
    desc.addField(fd("id", 1, .int32))
    desc.addField(fd("name", 2, .string))
    file.addMessage(desc)
    return file.messages["SimpleMessage"]!
  }

  static func emptyCustom() -> MessageDescriptor {
    var file = FileDescriptor(name: "common_types.proto", package: "testcompat")
    let desc = MessageDescriptor(name: "EmptyCustom", parent: file)
    file.addMessage(desc)
    return file.messages["EmptyCustom"]!
  }

  static func withNestedEnum() -> MessageDescriptor {
    var file = FileDescriptor(name: "common_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "WithNestedEnum", parent: file)
    var innerEnum = EnumDescriptor(name: "InnerEnum", fullName: "testcompat.WithNestedEnum.InnerEnum")
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "INNER_UNSPECIFIED", number: 0))
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "INNER_ALPHA", number: 1))
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "INNER_BETA", number: 2))
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "INNER_GAMMA", number: 3))
    desc.addNestedEnum(innerEnum)
    desc.addField(fd("kind", 1, .enum, typeName: "testcompat.WithNestedEnum.InnerEnum"))
    desc.addField(fd("label", 2, .string))
    file.addMessage(desc)
    return file.messages["WithNestedEnum"]!
  }

  static func withNestedMessage() -> MessageDescriptor {
    var file = FileDescriptor(name: "common_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "WithNestedMessage", parent: file)
    var inner = MessageDescriptor(name: "Inner", parent: desc)
    inner.addField(fd("code", 1, .int32))
    inner.addField(fd("detail", 2, .string))
    desc.addNestedMessage(inner)
    desc.addField(fd("error", 1, .message, typeName: "testcompat.WithNestedMessage.Inner"))
    desc.addField(fd("status", 2, .int32))
    file.addMessage(desc)
    return file.messages["WithNestedMessage"]!
  }

  // MARK: - scalar_types.proto

  static func scalarMessage() -> MessageDescriptor {
    var file = FileDescriptor(name: "scalar_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "ScalarMessage", parent: file)
    desc.addField(fd("double_field", 1, .double))
    desc.addField(fd("float_field", 2, .float))
    desc.addField(fd("int32_field", 3, .int32))
    desc.addField(fd("int64_field", 4, .int64))
    desc.addField(fd("uint32_field", 5, .uint32))
    desc.addField(fd("uint64_field", 6, .uint64))
    desc.addField(fd("sint32_field", 7, .sint32))
    desc.addField(fd("sint64_field", 8, .sint64))
    desc.addField(fd("fixed32_field", 9, .fixed32))
    desc.addField(fd("fixed64_field", 10, .fixed64))
    desc.addField(fd("sfixed32_field", 11, .sfixed32))
    desc.addField(fd("sfixed64_field", 12, .sfixed64))
    desc.addField(fd("bool_field", 13, .bool))
    desc.addField(fd("string_field", 14, .string))
    desc.addField(fd("bytes_field", 15, .bytes))
    file.addMessage(desc)
    return file.messages["ScalarMessage"]!
  }

  static func optionalScalarMessage() -> MessageDescriptor {
    var file = FileDescriptor(name: "scalar_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "OptionalScalarMessage", parent: file)
    desc.addField(fd("opt_double", 1, .double, proto3Optional: true))
    desc.addField(fd("opt_float", 2, .float, proto3Optional: true))
    desc.addField(fd("opt_int32", 3, .int32, proto3Optional: true))
    desc.addField(fd("opt_int64", 4, .int64, proto3Optional: true))
    desc.addField(fd("opt_uint32", 5, .uint32, proto3Optional: true))
    desc.addField(fd("opt_uint64", 6, .uint64, proto3Optional: true))
    desc.addField(fd("opt_sint32", 7, .sint32, proto3Optional: true))
    desc.addField(fd("opt_sint64", 8, .sint64, proto3Optional: true))
    desc.addField(fd("opt_fixed32", 9, .fixed32, proto3Optional: true))
    desc.addField(fd("opt_fixed64", 10, .fixed64, proto3Optional: true))
    desc.addField(fd("opt_sfixed32", 11, .sfixed32, proto3Optional: true))
    desc.addField(fd("opt_sfixed64", 12, .sfixed64, proto3Optional: true))
    desc.addField(fd("opt_bool", 13, .bool, proto3Optional: true))
    desc.addField(fd("opt_string", 14, .string, proto3Optional: true))
    desc.addField(fd("opt_bytes", 15, .bytes, proto3Optional: true))
    desc.addField(fd("plain_int32", 16, .int32))
    file.addMessage(desc)
    return file.messages["OptionalScalarMessage"]!
  }

  static func fieldNameEdgeCases() -> MessageDescriptor {
    var file = FileDescriptor(name: "scalar_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "FieldNameEdgeCases", parent: file)
    desc.addField(fd("my_field_name", 1, .string))
    desc.addField(fd("a_long_field_name_here", 2, .int32))
    desc.addField(fd("http_request", 3, .bool))
    desc.addField(fd("my_rpc", 4, .string))
    desc.addField(fd("__double_leading", 5, .string, jsonNameOverride: "DoubleLeading"))
    desc.addField(fd("trailing_", 6, .string, jsonNameOverride: "trailing"))
    desc.addField(fd("custom_json", 7, .string, jsonNameOverride: "customOverride"))
    desc.addField(fd("ALLCAPS", 8, .string))
    desc.addField(fd("CamelCase", 9, .string))
    desc.addField(fd("field_10", 10, .int32))
    file.addMessage(desc)
    return file.messages["FieldNameEdgeCases"]!
  }

  static func wideMessage() -> MessageDescriptor {
    var file = FileDescriptor(name: "scalar_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "WideMessage", parent: file)
    for i in 1...20 { desc.addField(fd("f\(i)", i, .string)) }
    for i in 1...10 { desc.addField(fd("i\(i)", 20 + i, .int32)) }
    for i in 1...5 { desc.addField(fd("d\(i)", 30 + i, .double)) }
    for i in 1...5 { desc.addField(fd("b\(i)", 35 + i, .bool)) }
    for i in 1...3 { desc.addField(fd("by\(i)", 40 + i, .bytes)) }
    for i in 1...3 { desc.addField(fd("l\(i)", 43 + i, .int64)) }
    for i in 1...2 { desc.addField(fd("u\(i)", 46 + i, .uint64)) }
    for i in 1...2 { desc.addField(fd("fl\(i)", 48 + i, .float)) }
    file.addMessage(desc)
    return file.messages["WideMessage"]!
  }

  // MARK: - container_types.proto

  static func repeatedAllTypes() -> MessageDescriptor {
    var file = FileDescriptor(name: "container_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "RepeatedAllTypes", parent: file)
    desc.addField(fd("rep_double", 1, .double, isRepeated: true))
    desc.addField(fd("rep_float", 2, .float, isRepeated: true))
    desc.addField(fd("rep_int32", 3, .int32, isRepeated: true))
    desc.addField(fd("rep_int64", 4, .int64, isRepeated: true))
    desc.addField(fd("rep_uint32", 5, .uint32, isRepeated: true))
    desc.addField(fd("rep_uint64", 6, .uint64, isRepeated: true))
    desc.addField(fd("rep_sint32", 7, .sint32, isRepeated: true))
    desc.addField(fd("rep_sint64", 8, .sint64, isRepeated: true))
    desc.addField(fd("rep_fixed32", 9, .fixed32, isRepeated: true))
    desc.addField(fd("rep_fixed64", 10, .fixed64, isRepeated: true))
    desc.addField(fd("rep_sfixed32", 11, .sfixed32, isRepeated: true))
    desc.addField(fd("rep_sfixed64", 12, .sfixed64, isRepeated: true))
    desc.addField(fd("rep_bool", 13, .bool, isRepeated: true))
    desc.addField(fd("rep_string", 14, .string, isRepeated: true))
    desc.addField(fd("rep_bytes", 15, .bytes, isRepeated: true))
    desc.addField(fd("rep_msg", 16, .message, typeName: "testcompat.ScalarMessage", isRepeated: true))
    desc.addField(fd("rep_enum", 17, .enum, typeName: "testcompat.Status", isRepeated: true))
    desc.addField(fd("rep_simple", 18, .message, typeName: "testcompat.SimpleMessage", isRepeated: true))
    file.addMessage(desc)
    return file.messages["RepeatedAllTypes"]!
  }

  static func mapAllKeyTypes() -> MessageDescriptor {
    var file = FileDescriptor(name: "container_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "MapAllKeyTypes", parent: file)
    desc.addField(mapFd("map_string_string", 1, keyType: .string, valueType: .string))
    desc.addField(mapFd("map_int32_string", 2, keyType: .int32, valueType: .string))
    desc.addField(mapFd("map_int64_string", 3, keyType: .int64, valueType: .string))
    desc.addField(mapFd("map_uint32_string", 4, keyType: .uint32, valueType: .string))
    desc.addField(mapFd("map_uint64_string", 5, keyType: .uint64, valueType: .string))
    desc.addField(mapFd("map_sint32_string", 6, keyType: .sint32, valueType: .string))
    desc.addField(mapFd("map_sint64_string", 7, keyType: .sint64, valueType: .string))
    desc.addField(mapFd("map_fixed32_string", 8, keyType: .fixed32, valueType: .string))
    desc.addField(mapFd("map_fixed64_string", 9, keyType: .fixed64, valueType: .string))
    desc.addField(mapFd("map_sfixed32_string", 10, keyType: .sfixed32, valueType: .string))
    desc.addField(mapFd("map_sfixed64_string", 11, keyType: .sfixed64, valueType: .string))
    desc.addField(mapFd("map_bool_string", 12, keyType: .bool, valueType: .string))
    file.addMessage(desc)
    return file.messages["MapAllKeyTypes"]!
  }

  static func mapAllValueTypes() -> MessageDescriptor {
    var file = FileDescriptor(name: "container_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "MapAllValueTypes", parent: file)
    desc.addField(mapFd("map_s_int32", 1, keyType: .string, valueType: .int32))
    desc.addField(mapFd("map_s_int64", 2, keyType: .string, valueType: .int64))
    desc.addField(mapFd("map_s_double", 3, keyType: .string, valueType: .double))
    desc.addField(mapFd("map_s_float", 4, keyType: .string, valueType: .float))
    desc.addField(mapFd("map_s_bool", 5, keyType: .string, valueType: .bool))
    desc.addField(mapFd("map_s_bytes", 6, keyType: .string, valueType: .bytes))
    desc.addField(mapFd("map_s_string", 7, keyType: .string, valueType: .string))
    desc.addField(
      mapFd("map_s_msg", 8, keyType: .string, valueType: .message, valueTypeName: "testcompat.ScalarMessage")
    )
    desc.addField(mapFd("map_s_enum", 9, keyType: .string, valueType: .enum, valueTypeName: "testcompat.Status"))
    desc.addField(
      mapFd("map_s_simple", 10, keyType: .string, valueType: .message, valueTypeName: "testcompat.SimpleMessage")
    )
    file.addMessage(desc)
    return file.messages["MapAllValueTypes"]!
  }

  static func mixedContainers() -> MessageDescriptor {
    var file = FileDescriptor(name: "container_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "MixedContainers", parent: file)
    desc.addField(fd("ids", 1, .int32, isRepeated: true))
    desc.addField(fd("names", 2, .string, isRepeated: true))
    desc.addField(mapFd("scores", 3, keyType: .string, valueType: .int32))
    desc.addField(mapFd("entries", 4, keyType: .int64, valueType: .message, valueTypeName: "testcompat.SimpleMessage"))
    desc.addField(fd("items", 5, .message, typeName: "testcompat.SimpleMessage", isRepeated: true))
    desc.addField(mapFd("statuses", 6, keyType: .string, valueType: .enum, valueTypeName: "testcompat.Status"))
    file.addMessage(desc)
    return file.messages["MixedContainers"]!
  }

  // MARK: - oneof_types.proto

  static func oneofScalars() -> MessageDescriptor {
    var file = FileDescriptor(name: "oneof_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "OneofScalars", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "value", index: 0))
    desc.addField(fd("double_val", 1, .double, oneofIndex: 0))
    desc.addField(fd("float_val", 2, .float, oneofIndex: 0))
    desc.addField(fd("int32_val", 3, .int32, oneofIndex: 0))
    desc.addField(fd("int64_val", 4, .int64, oneofIndex: 0))
    desc.addField(fd("uint32_val", 5, .uint32, oneofIndex: 0))
    desc.addField(fd("uint64_val", 6, .uint64, oneofIndex: 0))
    desc.addField(fd("bool_val", 7, .bool, oneofIndex: 0))
    desc.addField(fd("string_val", 8, .string, oneofIndex: 0))
    desc.addField(fd("bytes_val", 9, .bytes, oneofIndex: 0))
    file.addMessage(desc)
    return file.messages["OneofScalars"]!
  }

  static func oneofComplex() -> MessageDescriptor {
    var file = FileDescriptor(name: "oneof_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "OneofComplex", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "choice", index: 0))
    desc.addField(fd("int_val", 1, .int32, oneofIndex: 0))
    desc.addField(fd("string_val", 2, .string, oneofIndex: 0))
    desc.addField(fd("msg_val", 3, .message, typeName: "testcompat.ScalarMessage", oneofIndex: 0))
    desc.addField(fd("bytes_val", 4, .bytes, oneofIndex: 0))
    desc.addField(fd("enum_val", 5, .enum, typeName: "testcompat.Status", oneofIndex: 0))
    desc.addField(fd("simple_val", 6, .message, typeName: "testcompat.SimpleMessage", oneofIndex: 0))
    desc.addField(fd("name", 10, .string))
    file.addMessage(desc)
    return file.messages["OneofComplex"]!
  }

  static func multiOneof() -> MessageDescriptor {
    var file = FileDescriptor(name: "oneof_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "MultiOneof", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "first_choice", index: 0))
    desc.addOneofDecl(OneofDescriptor(name: "second_choice", index: 1))
    desc.addOneofDecl(OneofDescriptor(name: "third_choice", index: 2))
    desc.addField(fd("first_int", 1, .int32, oneofIndex: 0))
    desc.addField(fd("first_str", 2, .string, oneofIndex: 0))
    desc.addField(fd("first_bool", 3, .bool, oneofIndex: 0))
    desc.addField(fd("second_dbl", 4, .double, oneofIndex: 1))
    desc.addField(fd("second_bytes", 5, .bytes, oneofIndex: 1))
    desc.addField(fd("second_enum", 6, .enum, typeName: "testcompat.Status", oneofIndex: 1))
    desc.addField(fd("third_msg", 7, .message, typeName: "testcompat.SimpleMessage", oneofIndex: 2))
    desc.addField(fd("third_scalar", 8, .message, typeName: "testcompat.ScalarMessage", oneofIndex: 2))
    desc.addField(fd("label", 20, .string))
    file.addMessage(desc)
    return file.messages["MultiOneof"]!
  }

  static func oneofWKT() -> MessageDescriptor {
    var file = FileDescriptor(name: "oneof_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "OneofWKT", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "wkt_choice", index: 0))
    desc.addField(fd("ts_val", 1, .message, typeName: "google.protobuf.Timestamp", oneofIndex: 0))
    desc.addField(fd("i64w_val", 2, .message, typeName: "google.protobuf.Int64Value", oneofIndex: 0))
    desc.addField(fd("strw_val", 3, .message, typeName: "google.protobuf.StringValue", oneofIndex: 0))
    desc.addField(fd("struct_val", 4, .message, typeName: "google.protobuf.Struct", oneofIndex: 0))
    desc.addField(fd("boolw_val", 5, .message, typeName: "google.protobuf.BoolValue", oneofIndex: 0))
    desc.addField(fd("tag", 10, .int32))
    file.addMessage(desc)
    return file.messages["OneofWKT"]!
  }

  // MARK: - nesting_types.proto

  static func nested4() -> MessageDescriptor {
    var file = FileDescriptor(name: "nesting_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "Nested4", parent: file)
    desc.addField(fd("value", 1, .int32))
    desc.addField(fd("tags", 2, .string, isRepeated: true))
    desc.addField(fd("status", 3, .enum, typeName: "testcompat.Status"))
    file.addMessage(desc)
    return file.messages["Nested4"]!
  }

  static func nested3() -> MessageDescriptor {
    var file = FileDescriptor(name: "nesting_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "Nested3", parent: file)
    desc.addField(fd("child", 1, .message, typeName: "testcompat.Nested4"))
    desc.addField(mapFd("props", 2, keyType: .string, valueType: .int32))
    desc.addField(fd("flag", 3, .bool))
    file.addMessage(desc)
    return file.messages["Nested3"]!
  }

  static func nested2() -> MessageDescriptor {
    var file = FileDescriptor(name: "nesting_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "Nested2", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "variant", index: 0))
    desc.addField(fd("child", 1, .message, typeName: "testcompat.Nested3"))
    desc.addField(fd("count", 2, .int32))
    desc.addField(fd("text", 3, .string, oneofIndex: 0))
    desc.addField(fd("number", 4, .int32, oneofIndex: 0))
    file.addMessage(desc)
    return file.messages["Nested2"]!
  }

  static func nested1() -> MessageDescriptor {
    var file = FileDescriptor(name: "nesting_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "Nested1", parent: file)
    desc.addField(fd("child", 1, .message, typeName: "testcompat.Nested2"))
    desc.addField(fd("name", 2, .string))
    desc.addField(fd("siblings", 3, .message, typeName: "testcompat.Nested2", isRepeated: true))
    file.addMessage(desc)
    return file.messages["Nested1"]!
  }

  static func outerWithNestedDefs() -> MessageDescriptor {
    var file = FileDescriptor(name: "nesting_types.proto", package: "testcompat")
    var outer = MessageDescriptor(name: "OuterWithNestedDefs", parent: file)

    // Use middleDefBase as a placeholder parent for innerDef so that innerDef's
    // fullName becomes "testcompat.OuterWithNestedDefs.MiddleDef.InnerDef" (same pattern
    // as mixedNest1).
    let middleDefBase = MessageDescriptor(name: "MiddleDef", parent: outer)
    var innerDef = MessageDescriptor(name: "InnerDef", parent: middleDefBase)
    innerDef.addField(fd("code", 1, .int32))
    innerDef.addField(fd("reason", 2, .string))

    var middleDef = MessageDescriptor(name: "MiddleDef", parent: outer)
    middleDef.addNestedMessage(innerDef)
    middleDef.addField(fd("detail", 1, .message, typeName: "testcompat.OuterWithNestedDefs.MiddleDef.InnerDef"))
    middleDef.addField(fd("label", 2, .string))

    var outerEnum = EnumDescriptor(name: "OuterEnum", fullName: "testcompat.OuterWithNestedDefs.OuterEnum")
    outerEnum.addValue(EnumDescriptor.EnumValue(name: "OUTER_UNSPECIFIED", number: 0))
    outerEnum.addValue(EnumDescriptor.EnumValue(name: "OUTER_A", number: 1))
    outerEnum.addValue(EnumDescriptor.EnumValue(name: "OUTER_B", number: 2))

    outer.addNestedMessage(middleDef)
    outer.addNestedEnum(outerEnum)
    outer.addField(fd("primary", 1, .message, typeName: "testcompat.OuterWithNestedDefs.MiddleDef"))
    outer.addField(fd("secondary", 2, .message, typeName: "testcompat.OuterWithNestedDefs.MiddleDef", isRepeated: true))
    outer.addField(fd("kind", 3, .enum, typeName: "testcompat.OuterWithNestedDefs.OuterEnum"))
    outer.addField(
      mapFd(
        "errors",
        4,
        keyType: .string,
        valueType: .message,
        valueTypeName: "testcompat.OuterWithNestedDefs.MiddleDef.InnerDef"
      )
    )
    file.addMessage(outer)
    return file.messages["OuterWithNestedDefs"]!
  }

  static func recursive() -> MessageDescriptor {
    var file = FileDescriptor(name: "nesting_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "Recursive", parent: file)
    desc.addField(fd("value", 1, .int32))
    desc.addField(fd("label", 2, .string))
    desc.addField(fd("child", 3, .message, typeName: "testcompat.Recursive"))
    desc.addField(fd("children", 4, .message, typeName: "testcompat.Recursive", isRepeated: true))
    file.addMessage(desc)
    return file.messages["Recursive"]!
  }

  static func mixedNest1() -> MessageDescriptor {
    var file = FileDescriptor(name: "nesting_types.proto", package: "testcompat")
    var outer = MessageDescriptor(name: "MixedNest1", parent: file)

    // Correct parent chain: MixedNest2 first, then MixedNest3 with parent=nest2
    let nest2Base = MessageDescriptor(name: "MixedNest2", parent: outer)
    var nest3 = MessageDescriptor(name: "MixedNest3", parent: nest2Base)
    nest3.addField(fd("val", 1, .int32))
    nest3.addField(fd("items", 2, .string, isRepeated: true))
    nest3.addField(mapFd("kv", 3, keyType: .string, valueType: .int32))

    var nest2 = MessageDescriptor(name: "MixedNest2", parent: outer)
    nest2.addNestedMessage(nest3)
    nest2.addOneofDecl(OneofDescriptor(name: "pick", index: 0))
    nest2.addField(fd("inner", 1, .message, typeName: "testcompat.MixedNest1.MixedNest2.MixedNest3"))
    nest2.addField(fd("s", 2, .string, oneofIndex: 0))
    nest2.addField(fd("n", 3, .int32, oneofIndex: 0))
    nest2.addField(fd("list", 4, .message, typeName: "testcompat.MixedNest1.MixedNest2.MixedNest3", isRepeated: true))

    outer.addNestedMessage(nest2)
    outer.addField(fd("child", 1, .message, typeName: "testcompat.MixedNest1.MixedNest2"))
    outer.addField(fd("name", 2, .string))
    outer.addField(
      mapFd("branches", 3, keyType: .string, valueType: .message, valueTypeName: "testcompat.MixedNest1.MixedNest2")
    )
    outer.addField(fd("flags", 4, .enum, typeName: "testcompat.Status", isRepeated: true))
    file.addMessage(outer)
    return file.messages["MixedNest1"]!
  }

  // MARK: - wkt_types.proto

  static func wktHolder() -> MessageDescriptor {
    var file = FileDescriptor(name: "wkt_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "WKTHolder", parent: file)
    desc.addField(fd("ts", 1, .message, typeName: "google.protobuf.Timestamp"))
    desc.addField(fd("dur", 2, .message, typeName: "google.protobuf.Duration"))
    desc.addField(fd("mask", 3, .message, typeName: "google.protobuf.FieldMask"))
    desc.addField(fd("any_val", 4, .message, typeName: "google.protobuf.Any"))
    desc.addField(fd("struct_val", 5, .message, typeName: "google.protobuf.Struct"))
    desc.addField(fd("value_val", 6, .message, typeName: "google.protobuf.Value"))
    desc.addField(fd("list_val", 7, .message, typeName: "google.protobuf.ListValue"))
    desc.addField(fd("dbl_w", 8, .message, typeName: "google.protobuf.DoubleValue"))
    desc.addField(fd("flt_w", 9, .message, typeName: "google.protobuf.FloatValue"))
    desc.addField(fd("i64_w", 10, .message, typeName: "google.protobuf.Int64Value"))
    desc.addField(fd("u64_w", 11, .message, typeName: "google.protobuf.UInt64Value"))
    desc.addField(fd("i32_w", 12, .message, typeName: "google.protobuf.Int32Value"))
    desc.addField(fd("u32_w", 13, .message, typeName: "google.protobuf.UInt32Value"))
    desc.addField(fd("bool_w", 14, .message, typeName: "google.protobuf.BoolValue"))
    desc.addField(fd("str_w", 15, .message, typeName: "google.protobuf.StringValue"))
    desc.addField(fd("bytes_w", 16, .message, typeName: "google.protobuf.BytesValue"))
    desc.addField(fd("empty_val", 17, .message, typeName: "google.protobuf.Empty"))
    file.addMessage(desc)
    return file.messages["WKTHolder"]!
  }

  static func repeatedWKTs() -> MessageDescriptor {
    var file = FileDescriptor(name: "wkt_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "RepeatedWKTs", parent: file)
    desc.addField(fd("timestamps", 1, .message, typeName: "google.protobuf.Timestamp", isRepeated: true))
    desc.addField(fd("durations", 2, .message, typeName: "google.protobuf.Duration", isRepeated: true))
    desc.addField(fd("int64_vals", 3, .message, typeName: "google.protobuf.Int64Value", isRepeated: true))
    desc.addField(fd("string_vals", 4, .message, typeName: "google.protobuf.StringValue", isRepeated: true))
    desc.addField(fd("bool_vals", 5, .message, typeName: "google.protobuf.BoolValue", isRepeated: true))
    desc.addField(fd("structs", 6, .message, typeName: "google.protobuf.Struct", isRepeated: true))
    desc.addField(fd("values", 7, .message, typeName: "google.protobuf.Value", isRepeated: true))
    desc.addField(fd("anys", 8, .message, typeName: "google.protobuf.Any", isRepeated: true))
    file.addMessage(desc)
    return file.messages["RepeatedWKTs"]!
  }

  static func mapWKTValues() -> MessageDescriptor {
    var file = FileDescriptor(name: "wkt_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "MapWKTValues", parent: file)
    desc.addField(mapFd("ts_map", 1, keyType: .string, valueType: .message, valueTypeName: "google.protobuf.Timestamp"))
    desc.addField(
      mapFd("i64w_map", 2, keyType: .string, valueType: .message, valueTypeName: "google.protobuf.Int64Value")
    )
    desc.addField(
      mapFd("strw_map", 3, keyType: .string, valueType: .message, valueTypeName: "google.protobuf.StringValue")
    )
    desc.addField(
      mapFd("struct_map", 4, keyType: .string, valueType: .message, valueTypeName: "google.protobuf.Struct")
    )
    desc.addField(mapFd("any_map", 5, keyType: .string, valueType: .message, valueTypeName: "google.protobuf.Any"))
    file.addMessage(desc)
    return file.messages["MapWKTValues"]!
  }

  static func wktNested() -> MessageDescriptor {
    var file = FileDescriptor(name: "wkt_types.proto", package: "testcompat")
    var outer = MessageDescriptor(name: "WKTNested", parent: file)
    var inner = MessageDescriptor(name: "Inner", parent: outer)
    inner.addField(fd("created", 1, .message, typeName: "google.protobuf.Timestamp"))
    inner.addField(fd("ttl", 2, .message, typeName: "google.protobuf.Duration"))
    inner.addField(fd("count", 3, .message, typeName: "google.protobuf.Int32Value"))
    outer.addNestedMessage(inner)
    outer.addField(fd("primary", 1, .message, typeName: "testcompat.WKTNested.Inner"))
    outer.addField(fd("history", 2, .message, typeName: "testcompat.WKTNested.Inner", isRepeated: true))
    outer.addField(
      mapFd("named", 3, keyType: .string, valueType: .message, valueTypeName: "testcompat.WKTNested.Inner")
    )
    file.addMessage(outer)
    return file.messages["WKTNested"]!
  }

  static func wktMixed() -> MessageDescriptor {
    var file = FileDescriptor(name: "wkt_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "WKTMixed", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "wkt_or_scalar", index: 0))
    desc.addField(fd("ts", 1, .message, typeName: "google.protobuf.Timestamp"))
    desc.addField(fd("labels", 2, .message, typeName: "google.protobuf.StringValue", isRepeated: true))
    desc.addField(
      mapFd("counters", 3, keyType: .string, valueType: .message, valueTypeName: "google.protobuf.Int64Value")
    )
    desc.addField(fd("dur_val", 4, .message, typeName: "google.protobuf.Duration", oneofIndex: 0))
    desc.addField(fd("int_val", 5, .int32, oneofIndex: 0))
    desc.addField(fd("struct_val", 6, .message, typeName: "google.protobuf.Struct", oneofIndex: 0))
    desc.addField(fd("simple", 10, .message, typeName: "testcompat.SimpleMessage"))
    desc.addField(fd("detail", 11, .message, typeName: "testcompat.ScalarMessage"))
    desc.addField(fd("status", 12, .enum, typeName: "testcompat.Status"))
    file.addMessage(desc)
    return file.messages["WKTMixed"]!
  }

  // MARK: - proto2_types.proto

  static func proto2Basic() -> MessageDescriptor {
    var file = FileDescriptor(name: "proto2_types.proto", package: "testcompat2", syntax: "proto2")
    var desc = MessageDescriptor(name: "Proto2Basic", parent: file)
    desc.addField(fd("required_string", 1, .string, isRequired: true))
    desc.addField(fd("required_int32", 2, .int32, isRequired: true))
    desc.addField(fd("opt_string", 3, .string, isOptional: true))
    desc.addField(fd("opt_int32", 4, .int32, isOptional: true))
    desc.addField(fd("opt_bool", 5, .bool, isOptional: true))
    desc.addField(fd("opt_bytes", 6, .bytes, isOptional: true))
    desc.addField(fd("opt_double", 7, .double, isOptional: true))
    file.addMessage(desc)
    return file.messages["Proto2Basic"]!
  }

  static func proto2Defaults() -> MessageDescriptor {
    var file = FileDescriptor(name: "proto2_types.proto", package: "testcompat2", syntax: "proto2")
    var desc = MessageDescriptor(name: "Proto2Defaults", parent: file)
    desc.addField(fd("count", 1, .int32, isOptional: true, defaultValue: .int(42)))
    desc.addField(fd("label", 2, .string, isOptional: true, defaultValue: .string("hello")))
    desc.addField(fd("active", 3, .bool, isOptional: true, defaultValue: .bool(true)))
    desc.addField(fd("rate", 4, .double, isOptional: true, defaultValue: .double(3.14)))
    desc.addField(fd("ratio", 5, .float, isOptional: true, defaultValue: .double(0.5)))
    desc.addField(fd("magic", 6, .bytes, isOptional: true))
    desc.addField(
      fd("kind", 7, .enum, typeName: "testcompat2.Proto2Enum", isOptional: true, defaultValue: .string("P2_BETA"))
    )
    file.addMessage(desc)
    return file.messages["Proto2Defaults"]!
  }

  static func proto2Enum() -> EnumDescriptor {
    var desc = EnumDescriptor(name: "Proto2Enum", fullName: "testcompat2.Proto2Enum")
    desc.addValue(EnumDescriptor.EnumValue(name: "P2_UNSPECIFIED", number: 0))
    desc.addValue(EnumDescriptor.EnumValue(name: "P2_ALPHA", number: 1))
    desc.addValue(EnumDescriptor.EnumValue(name: "P2_BETA", number: 2))
    desc.addValue(EnumDescriptor.EnumValue(name: "P2_GAMMA", number: 3))
    return desc
  }

  static func proto2NoZero() -> EnumDescriptor {
    var desc = EnumDescriptor(name: "Proto2NoZero", fullName: "testcompat2.Proto2NoZero")
    desc.addValue(EnumDescriptor.EnumValue(name: "P2NZ_ONE", number: 1))
    desc.addValue(EnumDescriptor.EnumValue(name: "P2NZ_TWO", number: 2))
    desc.addValue(EnumDescriptor.EnumValue(name: "P2NZ_THREE", number: 3))
    return desc
  }

  static func proto2WithGroup() -> MessageDescriptor {
    var file = FileDescriptor(name: "proto2_types.proto", package: "testcompat2", syntax: "proto2")
    var desc = MessageDescriptor(name: "Proto2WithGroup", parent: file)
    desc.addField(fd("id", 1, .int32, isRequired: true))
    var myGroupDesc = MessageDescriptor(name: "MyGroup", parent: desc)
    myGroupDesc.addField(fd("name", 1, .string, isOptional: true))
    myGroupDesc.addField(fd("value", 2, .int32, isOptional: true))
    desc.addNestedMessage(myGroupDesc)
    desc.addField(fd("mygroup", 2, .group, typeName: "testcompat2.Proto2WithGroup.MyGroup", isOptional: true))
    var anotherGroupDesc = MessageDescriptor(name: "AnotherGroup", parent: desc)
    anotherGroupDesc.addField(fd("flag", 1, .bool, isOptional: true))
    anotherGroupDesc.addField(fd("detail", 2, .string, isOptional: true))
    desc.addNestedMessage(anotherGroupDesc)
    desc.addField(fd("anothergroup", 3, .group, typeName: "testcompat2.Proto2WithGroup.AnotherGroup", isOptional: true))
    file.addMessage(desc)
    return file.messages["Proto2WithGroup"]!
  }

  static func proto2Extendable() -> MessageDescriptor {
    var file = FileDescriptor(name: "proto2_types.proto", package: "testcompat2", syntax: "proto2")
    var desc = MessageDescriptor(name: "Proto2Extendable", parent: file)
    desc.addField(fd("base_field", 1, .string, isRequired: true))
    desc.addField(fd("code", 2, .int32, isOptional: true))
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtensionRange(ExtensionRange(start: 200, end: 300))
    desc.addExtension(fd("ext_name", 100, .string, isOptional: true))
    desc.addExtension(fd("ext_count", 101, .int32, isOptional: true))
    desc.addExtension(fd("ext_flag", 102, .bool, isOptional: true))
    desc.addExtension(fd("ext_data", 103, .bytes, isOptional: true))
    desc.addExtension(fd("ext_msg", 104, .message, typeName: "testcompat2.Proto2Basic", isOptional: true))
    desc.addExtension(fd("ext_tags", 105, .string, isRepeated: true, isOptional: true))
    desc.addExtension(fd("ext_ids", 106, .int32, isRepeated: true, isOptional: true))
    file.addMessage(desc)
    return file.messages["Proto2Extendable"]!
  }

  static func proto2Complex() -> MessageDescriptor {
    var file = FileDescriptor(name: "proto2_types.proto", package: "testcompat2", syntax: "proto2")
    var desc = MessageDescriptor(name: "Proto2Complex", parent: file)
    desc.addField(fd("title", 1, .string, isRequired: true))
    desc.addField(fd("version", 2, .int32, isOptional: true))
    var headerGroup = MessageDescriptor(name: "Header", parent: desc)
    headerGroup.addField(fd("key", 1, .string, isOptional: true))
    headerGroup.addField(fd("value", 2, .string, isOptional: true))
    desc.addNestedMessage(headerGroup)
    desc.addField(fd("header", 3, .group, typeName: "testcompat2.Proto2Complex.Header", isOptional: true))
    var itemGroup = MessageDescriptor(name: "Item", parent: desc)
    itemGroup.addField(fd("id", 1, .int32, isOptional: true))
    itemGroup.addField(fd("label", 2, .string, isOptional: true))
    itemGroup.addField(fd("kind", 3, .enum, typeName: "testcompat2.Proto2Enum", isOptional: true))
    desc.addNestedMessage(itemGroup)
    desc.addField(fd("item", 4, .group, typeName: "testcompat2.Proto2Complex.Item", isRepeated: true))
    desc.addField(fd("basic", 5, .message, typeName: "testcompat2.Proto2Basic", isOptional: true))
    desc.addField(fd("items", 6, .message, typeName: "testcompat2.Proto2Basic", isRepeated: true))
    desc.addField(mapFd("meta", 7, keyType: .string, valueType: .string))
    file.addMessage(desc)
    return file.messages["Proto2Complex"]!
  }

  static func proto2Oneof() -> MessageDescriptor {
    var file = FileDescriptor(name: "proto2_types.proto", package: "testcompat2", syntax: "proto2")
    var desc = MessageDescriptor(name: "Proto2Oneof", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "choice", index: 0))
    desc.addField(fd("str_val", 1, .string, oneofIndex: 0))
    desc.addField(fd("int_val", 2, .int32, oneofIndex: 0))
    desc.addField(fd("bool_val", 3, .bool, oneofIndex: 0))
    desc.addField(fd("msg_val", 4, .message, typeName: "testcompat2.Proto2Basic", oneofIndex: 0))
    desc.addField(fd("label", 10, .string, isOptional: true))
    file.addMessage(desc)
    return file.messages["Proto2Oneof"]!
  }

  static func proto2KitchenSink() -> MessageDescriptor {
    var file = FileDescriptor(name: "proto2_types.proto", package: "testcompat2", syntax: "proto2")
    var desc = MessageDescriptor(name: "Proto2KitchenSink", parent: file)
    desc.addField(fd("name", 1, .string, isRequired: true))
    desc.addField(fd("id", 2, .int32, isOptional: true))
    desc.addField(fd("status", 3, .enum, typeName: "testcompat2.Proto2Enum", isOptional: true))
    desc.addField(fd("tags", 4, .string, isRepeated: true))
    desc.addField(mapFd("scores", 5, keyType: .string, valueType: .int32))
    var detailGroup = MessageDescriptor(name: "Detail", parent: desc)
    detailGroup.addField(fd("info", 1, .string, isOptional: true))
    detailGroup.addField(fd("code", 2, .int32, isOptional: true))
    desc.addNestedMessage(detailGroup)
    desc.addField(fd("detail", 6, .group, typeName: "testcompat2.Proto2KitchenSink.Detail", isOptional: true))
    desc.addOneofDecl(OneofDescriptor(name: "variant", index: 0))
    desc.addField(fd("str_variant", 7, .string, oneofIndex: 0))
    desc.addField(fd("int_variant", 8, .int32, oneofIndex: 0))
    desc.addField(fd("nested", 9, .message, typeName: "testcompat2.Proto2Basic", isOptional: true))
    desc.addField(fd("items", 10, .message, typeName: "testcompat2.Proto2Basic", isRepeated: true))
    desc.addField(fd("with_defaults", 11, .message, typeName: "testcompat2.Proto2Defaults", isOptional: true))
    file.addMessage(desc)
    return file.messages["Proto2KitchenSink"]!
  }

  // MARK: - realworld_types.proto

  static func nullableUint32() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "NullableUint32", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "kind", index: 0))
    desc.addField(fd("null_val", 1, .enum, typeName: "google.protobuf.NullValue", oneofIndex: 0))
    desc.addField(fd("value", 2, .uint32, oneofIndex: 0))
    file.addMessage(desc)
    return file.messages["NullableUint32"]!
  }

  static func nullableDouble() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "NullableDouble", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "kind", index: 0))
    desc.addField(fd("null_val", 1, .enum, typeName: "google.protobuf.NullValue", oneofIndex: 0))
    desc.addField(fd("value", 2, .double, oneofIndex: 0))
    file.addMessage(desc)
    return file.messages["NullableDouble"]!
  }

  static func nullableBool() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "NullableBool", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "kind", index: 0))
    desc.addField(fd("null_val", 1, .enum, typeName: "google.protobuf.NullValue", oneofIndex: 0))
    desc.addField(fd("value", 2, .bool, oneofIndex: 0))
    file.addMessage(desc)
    return file.messages["NullableBool"]!
  }

  static func nullableString() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "NullableString", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "kind", index: 0))
    desc.addField(fd("null_val", 1, .enum, typeName: "google.protobuf.NullValue", oneofIndex: 0))
    desc.addField(fd("value", 2, .string, oneofIndex: 0))
    file.addMessage(desc)
    return file.messages["NullableString"]!
  }

  static func nullableMessage() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "NullableMessage", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "kind", index: 0))
    desc.addField(fd("null_val", 1, .enum, typeName: "google.protobuf.NullValue", oneofIndex: 0))
    desc.addField(fd("value", 2, .message, typeName: "testcompat.SimpleMessage", oneofIndex: 0))
    file.addMessage(desc)
    return file.messages["NullableMessage"]!
  }

  static func withNullables() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "WithNullables", parent: file)
    desc.addField(fd("count", 1, .message, typeName: "testcompat.NullableUint32"))
    desc.addField(fd("rate", 2, .message, typeName: "testcompat.NullableDouble"))
    desc.addField(fd("active", 3, .message, typeName: "testcompat.NullableBool"))
    desc.addField(fd("label", 4, .message, typeName: "testcompat.NullableString"))
    desc.addField(fd("detail", 5, .message, typeName: "testcompat.NullableMessage"))
    desc.addField(fd("name", 10, .string))
    file.addMessage(desc)
    return file.messages["WithNullables"]!
  }

  static func nonSequentialFields() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "NonSequentialFields", parent: file)
    desc.addField(fd("name", 1, .string))
    desc.addField(fd("code", 2, .int32))
    desc.addField(fd("description", 10, .string))
    desc.addField(fd("big_number", 50, .int64))
    desc.addField(fd("flag", 100, .bool))
    desc.addField(fd("created_at", 71, .message, typeName: "google.protobuf.Timestamp"))
    desc.addField(fd("updated_at", 72, .message, typeName: "google.protobuf.Timestamp"))
    file.addMessage(desc)
    return file.messages["NonSequentialFields"]!
  }

  static func withReserved() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "WithReserved", parent: file)
    desc.addField(fd("name", 1, .string))
    desc.addField(fd("version", 5, .int32))
    desc.addField(fd("status", 9, .string))
    desc.addField(fd("priority", 10, .int32))
    file.addMessage(desc)
    return file.messages["WithReserved"]!
  }

  static func intentFlagEnum() -> EnumDescriptor {
    var desc = EnumDescriptor(name: "IntentFlag", fullName: "testcompat.IntentFlag")
    desc.addValue(EnumDescriptor.EnumValue(name: "INTENT_DEFAULT", number: 0))
    desc.addValue(EnumDescriptor.EnumValue(name: "INTENT_INFORMATIONAL", number: 1))
    desc.addValue(EnumDescriptor.EnumValue(name: "INTENT_NAVIGATIONAL", number: 2))
    desc.addValue(EnumDescriptor.EnumValue(name: "INTENT_TRANSACTIONAL", number: 4))
    desc.addValue(EnumDescriptor.EnumValue(name: "INTENT_COMMERCIAL", number: 8))
    return desc
  }

  static func reportResponse() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var outer = MessageDescriptor(name: "ReportResponse", parent: file)

    var metrics = MessageDescriptor(name: "Metrics", parent: outer)
    metrics.addField(fd("position", 1, .int32))
    metrics.addField(fd("visibility", 2, .float))
    metrics.addField(fd("traffic", 3, .float))

    var position = MessageDescriptor(name: "Position", parent: outer)
    position.addField(fd("metrics", 1, .message, typeName: "testcompat.ReportResponse.Metrics"))
    position.addField(fd("serp_features", 2, .enum, typeName: "testcompat.Status", isRepeated: true))
    position.addField(fd("url", 3, .string))

    var competitorData = MessageDescriptor(name: "CompetitorData", parent: outer)
    competitorData.addField(fd("competitor", 1, .message, typeName: "testcompat.SimpleMessage"))
    competitorData.addField(fd("position", 2, .message, typeName: "testcompat.ReportResponse.Position"))

    var dateEntry = MessageDescriptor(name: "DateEntry", parent: outer)
    dateEntry.addField(fd("date", 1, .string))
    dateEntry.addField(fd("is_crawled", 2, .bool))
    dateEntry.addField(
      fd("competitors", 3, .message, typeName: "testcompat.ReportResponse.CompetitorData", isRepeated: true)
    )

    var interval = MessageDescriptor(name: "Interval", parent: outer)
    interval.addField(fd("begin", 1, .message, typeName: "testcompat.ReportResponse.DateEntry"))
    interval.addField(fd("end", 2, .message, typeName: "testcompat.ReportResponse.DateEntry"))
    interval.addField(fd("diff", 3, .message, typeName: "testcompat.ReportResponse.CompetitorData", isRepeated: true))

    var keyword = MessageDescriptor(name: "Keyword", parent: outer)
    keyword.addField(fd("keyword", 1, .string))
    keyword.addField(fd("tags", 2, .string, isRepeated: true))
    keyword.addField(fd("cpc", 3, .message, typeName: "testcompat.NullableDouble"))
    keyword.addField(fd("volume", 4, .message, typeName: "testcompat.NullableUint32"))
    keyword.addField(fd("serps", 5, .message, typeName: "testcompat.ReportResponse.Interval"))

    outer.addNestedMessage(metrics)
    outer.addNestedMessage(position)
    outer.addNestedMessage(competitorData)
    outer.addNestedMessage(dateEntry)
    outer.addNestedMessage(interval)
    outer.addNestedMessage(keyword)
    outer.addField(fd("total", 1, .uint32))
    outer.addField(fd("limit", 2, .uint32))
    outer.addField(fd("offset", 3, .uint32))
    outer.addField(fd("keywords", 4, .message, typeName: "testcompat.ReportResponse.Keyword", isRepeated: true))
    file.addMessage(outer)
    return file.messages["ReportResponse"]!
  }

  static func dateValue() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "DateValue", parent: file)
    desc.addField(fd("year", 1, .int32))
    desc.addField(fd("month", 2, .int32))
    desc.addField(fd("day", 3, .int32))
    file.addMessage(desc)
    return file.messages["DateValue"]!
  }

  static func proto3OptionalMessages() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "Proto3OptionalMessages", parent: file)
    desc.addField(fd("opt_simple", 1, .message, typeName: "testcompat.SimpleMessage", proto3Optional: true))
    desc.addField(fd("opt_scalar", 2, .message, typeName: "testcompat.ScalarMessage", proto3Optional: true))
    desc.addField(fd("opt_ts", 3, .message, typeName: "google.protobuf.Timestamp", proto3Optional: true))
    desc.addField(fd("opt_wrapper", 4, .message, typeName: "google.protobuf.Int64Value", proto3Optional: true))
    desc.addField(fd("plain_simple", 5, .message, typeName: "testcompat.SimpleMessage"))
    desc.addField(fd("label", 10, .string))
    file.addMessage(desc)
    return file.messages["Proto3OptionalMessages"]!
  }

  static func intentHolder() -> MessageDescriptor {
    var file = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "IntentHolder", parent: file)
    desc.addField(fd("intent", 1, .enum, typeName: "testcompat.IntentFlag"))
    desc.addField(fd("all_intents", 2, .enum, typeName: "testcompat.IntentFlag", isRepeated: true))
    desc.addField(mapFd("by_name", 3, keyType: .string, valueType: .enum, valueTypeName: "testcompat.IntentFlag"))
    file.addMessage(desc)
    return file.messages["IntentHolder"]!
  }

  // MARK: - cross_file_types.proto

  static func crossFileAll() -> MessageDescriptor {
    var file = FileDescriptor(name: "cross_file_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "CrossFileAll", parent: file)
    desc.addField(fd("simple", 1, .message, typeName: "testcompat.SimpleMessage"))
    desc.addField(fd("scalar", 2, .message, typeName: "testcompat.ScalarMessage"))
    desc.addField(fd("repeated_all", 3, .message, typeName: "testcompat.RepeatedAllTypes"))
    desc.addField(fd("oneof_msg", 4, .message, typeName: "testcompat.OneofComplex"))
    desc.addField(fd("nested", 5, .message, typeName: "testcompat.Nested1"))
    desc.addField(fd("wkt", 6, .message, typeName: "testcompat.WKTHolder"))
    desc.addField(fd("status", 7, .enum, typeName: "testcompat.Status"))
    desc.addField(fd("priority", 8, .enum, typeName: "testcompat.Priority"))
    file.addMessage(desc)
    return file.messages["CrossFileAll"]!
  }

  static func crossFileMixed() -> MessageDescriptor {
    var file = FileDescriptor(name: "cross_file_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "CrossFileMixed", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "pick", index: 0))
    desc.addField(fd("items", 1, .message, typeName: "testcompat.SimpleMessage", isRepeated: true))
    desc.addField(mapFd("details", 2, keyType: .string, valueType: .message, valueTypeName: "testcompat.ScalarMessage"))
    desc.addField(fd("simple_pick", 3, .message, typeName: "testcompat.SimpleMessage", oneofIndex: 0))
    desc.addField(fd("wkt_pick", 4, .message, typeName: "testcompat.WKTHolder", oneofIndex: 0))
    desc.addField(fd("nested_pick", 5, .message, typeName: "testcompat.Nested1", oneofIndex: 0))
    desc.addField(fd("statuses", 6, .enum, typeName: "testcompat.Status", isRepeated: true))
    desc.addField(mapFd("status_map", 7, keyType: .string, valueType: .enum, valueTypeName: "testcompat.Status"))
    file.addMessage(desc)
    return file.messages["CrossFileMixed"]!
  }

  static func crossPackageRef() -> MessageDescriptor {
    var file = FileDescriptor(name: "cross_file_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "CrossPackageRef", parent: file)
    desc.addField(fd("p2_basic", 1, .message, typeName: "testcompat2.Proto2Basic"))
    desc.addField(fd("p2_defaults", 2, .message, typeName: "testcompat2.Proto2Defaults"))
    desc.addField(fd("p2_list", 4, .message, typeName: "testcompat2.Proto2Basic", isRepeated: true))
    desc.addField(fd("label", 10, .string))
    desc.addField(fd("created", 11, .message, typeName: "google.protobuf.Timestamp"))
    desc.addField(fd("count", 12, .message, typeName: "google.protobuf.Int64Value"))
    file.addMessage(desc)
    return file.messages["CrossPackageRef"]!
  }

  static func megaMixed() -> MessageDescriptor {
    var file = FileDescriptor(name: "cross_file_types.proto", package: "testcompat")
    var outer = MessageDescriptor(name: "MegaMixed", parent: file)

    // Correct parent chain: Layer2 first, then Layer3 with parent=layer2Base
    let layer2Base = MessageDescriptor(name: "Layer2", parent: outer)
    var layer3 = MessageDescriptor(name: "Layer3", parent: layer2Base)
    layer3.addField(fd("simple", 1, .message, typeName: "testcompat.SimpleMessage"))
    layer3.addField(fd("scalar", 2, .message, typeName: "testcompat.ScalarMessage"))
    layer3.addField(fd("wkt", 3, .message, typeName: "testcompat.WKTHolder"))
    layer3.addField(mapFd("flags", 4, keyType: .string, valueType: .enum, valueTypeName: "testcompat.Status"))

    var layer2 = MessageDescriptor(name: "Layer2", parent: outer)
    layer2.addOneofDecl(OneofDescriptor(name: "choice", index: 0))
    layer2.addNestedMessage(layer3)
    layer2.addField(fd("inner", 1, .message, typeName: "testcompat.MegaMixed.Layer2.Layer3"))
    layer2.addField(fd("list", 2, .message, typeName: "testcompat.MegaMixed.Layer2.Layer3", isRepeated: true))
    layer2.addField(fd("text", 3, .string, oneofIndex: 0))
    layer2.addField(fd("msg", 4, .message, typeName: "testcompat.SimpleMessage", oneofIndex: 0))

    outer.addNestedMessage(layer2)
    outer.addField(fd("child", 1, .message, typeName: "testcompat.MegaMixed.Layer2"))
    outer.addField(fd("name", 2, .string))
    outer.addField(
      mapFd("branches", 3, keyType: .string, valueType: .message, valueTypeName: "testcompat.MegaMixed.Layer2")
    )
    outer.addField(fd("oneofs", 4, .message, typeName: "testcompat.OneofComplex", isRepeated: true))
    outer.addField(fd("ts", 5, .message, typeName: "google.protobuf.Timestamp"))
    outer.addField(fd("nested", 6, .message, typeName: "testcompat.Nested1"))
    file.addMessage(outer)
    return file.messages["MegaMixed"]!
  }

  static func kitchenSinkFlat() -> MessageDescriptor {
    var file = FileDescriptor(name: "cross_file_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "KitchenSinkFlat", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "choice", index: 0))
    desc.addField(fd("int32_val", 1, .int32))
    desc.addField(fd("int64_val", 2, .int64))
    desc.addField(fd("uint32_val", 3, .uint32))
    desc.addField(fd("uint64_val", 4, .uint64))
    desc.addField(fd("sint32_val", 5, .sint32))
    desc.addField(fd("sint64_val", 6, .sint64))
    desc.addField(fd("fixed32_val", 7, .fixed32))
    desc.addField(fd("fixed64_val", 8, .fixed64))
    desc.addField(fd("sfixed32_val", 9, .sfixed32))
    desc.addField(fd("sfixed64_val", 10, .sfixed64))
    desc.addField(fd("double_val", 11, .double))
    desc.addField(fd("float_val", 12, .float))
    desc.addField(fd("bool_val", 13, .bool))
    desc.addField(fd("string_val", 14, .string))
    desc.addField(fd("bytes_val", 15, .bytes))
    desc.addField(fd("status", 16, .enum, typeName: "testcompat.Status"))
    desc.addField(fd("priority", 17, .enum, typeName: "testcompat.Priority"))
    desc.addField(fd("rep_int32", 18, .int32, isRepeated: true))
    desc.addField(fd("rep_string", 19, .string, isRepeated: true))
    desc.addField(fd("rep_status", 20, .enum, typeName: "testcompat.Status", isRepeated: true))
    desc.addField(fd("rep_msg", 21, .message, typeName: "testcompat.SimpleMessage", isRepeated: true))
    desc.addField(mapFd("map_ss", 22, keyType: .string, valueType: .string))
    desc.addField(mapFd("map_is", 23, keyType: .int32, valueType: .string))
    desc.addField(mapFd("map_sm", 24, keyType: .string, valueType: .message, valueTypeName: "testcompat.SimpleMessage"))
    desc.addField(mapFd("map_se", 25, keyType: .string, valueType: .enum, valueTypeName: "testcompat.Status"))
    desc.addField(fd("oneof_str", 26, .string, oneofIndex: 0))
    desc.addField(fd("oneof_int", 27, .int32, oneofIndex: 0))
    desc.addField(fd("oneof_msg", 28, .message, typeName: "testcompat.SimpleMessage", oneofIndex: 0))
    desc.addField(fd("ts", 29, .message, typeName: "google.protobuf.Timestamp"))
    desc.addField(fd("dur", 30, .message, typeName: "google.protobuf.Duration"))
    desc.addField(fd("i64_w", 31, .message, typeName: "google.protobuf.Int64Value"))
    desc.addField(fd("str_w", 32, .message, typeName: "google.protobuf.StringValue"))
    desc.addField(fd("struct_v", 33, .message, typeName: "google.protobuf.Struct"))
    desc.addField(fd("scalar_detail", 34, .message, typeName: "testcompat.ScalarMessage"))
    desc.addField(fd("deep_nested", 35, .message, typeName: "testcompat.Nested1"))
    desc.addField(fd("wkt_all", 36, .message, typeName: "testcompat.WKTHolder"))
    file.addMessage(desc)
    return file.messages["KitchenSinkFlat"]!
  }

  static func deepLevel4() -> MessageDescriptor {
    var file = FileDescriptor(name: "cross_file_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "DeepLevel4", parent: file)
    desc.addField(fd("value", 1, .int32))
    desc.addField(fd("items", 2, .string, isRepeated: true))
    desc.addField(fd("status", 3, .enum, typeName: "testcompat.Status"))
    file.addMessage(desc)
    return file.messages["DeepLevel4"]!
  }

  static func deepLevel3() -> MessageDescriptor {
    var file = FileDescriptor(name: "cross_file_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "DeepLevel3", parent: file)
    desc.addField(fd("child", 1, .message, typeName: "testcompat.DeepLevel4"))
    desc.addField(mapFd("props", 2, keyType: .string, valueType: .string))
    desc.addField(fd("flag", 3, .bool))
    desc.addField(fd("aux", 4, .message, typeName: "testcompat.SimpleMessage"))
    file.addMessage(desc)
    return file.messages["DeepLevel3"]!
  }

  static func deepLevel2() -> MessageDescriptor {
    var file = FileDescriptor(name: "cross_file_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "DeepLevel2", parent: file)
    desc.addOneofDecl(OneofDescriptor(name: "pick", index: 0))
    desc.addField(fd("child", 1, .message, typeName: "testcompat.DeepLevel3"))
    desc.addField(fd("count", 2, .int32))
    desc.addField(fd("numbers", 3, .int32, isRepeated: true))
    desc.addField(fd("text", 4, .string, oneofIndex: 0))
    desc.addField(fd("active", 5, .bool, oneofIndex: 0))
    desc.addField(fd("ts", 6, .message, typeName: "google.protobuf.Timestamp"))
    file.addMessage(desc)
    return file.messages["DeepLevel2"]!
  }

  static func deepLevel1() -> MessageDescriptor {
    var file = FileDescriptor(name: "cross_file_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "DeepLevel1", parent: file)
    desc.addField(fd("child", 1, .message, typeName: "testcompat.DeepLevel2"))
    desc.addField(fd("name", 2, .string))
    desc.addField(fd("tags", 3, .string, isRepeated: true))
    desc.addField(mapFd("scores", 4, keyType: .string, valueType: .int32))
    desc.addField(fd("extras", 5, .message, typeName: "testcompat.DeepLevel2", isRepeated: true))
    desc.addField(fd("count_w", 6, .message, typeName: "google.protobuf.Int64Value"))
    file.addMessage(desc)
    return file.messages["DeepLevel1"]!
  }

  // MARK: - Full Registry

  /// Creates a TypeRegistry with all descriptors from all fixture .proto files registered.
  static func fullRegistry() throws -> TypeRegistry {
    let registry = TypeRegistry()

    // WKTs
    var wktFile = FileDescriptor(name: "google/protobuf/timestamp.proto", package: "google.protobuf")
    wktFile.addMessage(wktTimestamp())
    try registry.registerFile(wktFile)

    var durFile = FileDescriptor(name: "google/protobuf/duration.proto", package: "google.protobuf")
    durFile.addMessage(wktDuration())
    try registry.registerFile(durFile)

    var fmFile = FileDescriptor(name: "google/protobuf/field_mask.proto", package: "google.protobuf")
    fmFile.addMessage(wktFieldMask())
    try registry.registerFile(fmFile)

    var anyFile = FileDescriptor(name: "google/protobuf/any.proto", package: "google.protobuf")
    anyFile.addMessage(wktAny())
    try registry.registerFile(anyFile)

    var structFile = FileDescriptor(name: "google/protobuf/struct.proto", package: "google.protobuf")
    structFile.addMessage(wktStruct())
    structFile.addMessage(wktValue())
    structFile.addMessage(wktListValue())
    structFile.addEnum(wktNullValue())
    try registry.registerFile(structFile)

    var wrappersFile = FileDescriptor(name: "google/protobuf/wrappers.proto", package: "google.protobuf")
    wrappersFile.addMessage(wktWrapper(name: "DoubleValue", fieldType: SwiftProtoReflect.FieldType.double))
    wrappersFile.addMessage(wktWrapper(name: "FloatValue", fieldType: SwiftProtoReflect.FieldType.float))
    wrappersFile.addMessage(wktWrapper(name: "Int64Value", fieldType: SwiftProtoReflect.FieldType.int64))
    wrappersFile.addMessage(wktWrapper(name: "UInt64Value", fieldType: SwiftProtoReflect.FieldType.uint64))
    wrappersFile.addMessage(wktWrapper(name: "Int32Value", fieldType: SwiftProtoReflect.FieldType.int32))
    wrappersFile.addMessage(wktWrapper(name: "UInt32Value", fieldType: SwiftProtoReflect.FieldType.uint32))
    wrappersFile.addMessage(wktWrapper(name: "BoolValue", fieldType: SwiftProtoReflect.FieldType.bool))
    wrappersFile.addMessage(wktWrapper(name: "StringValue", fieldType: SwiftProtoReflect.FieldType.string))
    wrappersFile.addMessage(wktWrapper(name: "BytesValue", fieldType: SwiftProtoReflect.FieldType.bytes))
    try registry.registerFile(wrappersFile)

    var emptyFile = FileDescriptor(name: "google/protobuf/empty.proto", package: "google.protobuf")
    emptyFile.addMessage(wktEmpty())
    try registry.registerFile(emptyFile)

    // common_types.proto
    var commonFile = FileDescriptor(name: "common_types.proto", package: "testcompat")
    commonFile.addEnum(statusEnum())
    commonFile.addEnum(priorityEnum())
    commonFile.addEnum(directionEnum())
    commonFile.addMessage(simpleMessage())
    commonFile.addMessage(emptyCustom())
    commonFile.addMessage(withNestedEnum())
    commonFile.addMessage(withNestedMessage())
    commonFile.addMessage(directionHolder())
    try registry.registerFile(commonFile)

    // scalar_types.proto
    var scalarFile = FileDescriptor(name: "scalar_types.proto", package: "testcompat")
    scalarFile.addMessage(scalarMessage())
    scalarFile.addMessage(optionalScalarMessage())
    scalarFile.addMessage(fieldNameEdgeCases())
    scalarFile.addMessage(wideMessage())
    try registry.registerFile(scalarFile)

    // container_types.proto
    var containerFile = FileDescriptor(name: "container_types.proto", package: "testcompat")
    containerFile.addMessage(repeatedAllTypes())
    containerFile.addMessage(mapAllKeyTypes())
    containerFile.addMessage(mapAllValueTypes())
    containerFile.addMessage(mixedContainers())
    try registry.registerFile(containerFile)

    // oneof_types.proto
    var oneofFile = FileDescriptor(name: "oneof_types.proto", package: "testcompat")
    oneofFile.addMessage(oneofScalars())
    oneofFile.addMessage(oneofComplex())
    oneofFile.addMessage(multiOneof())
    oneofFile.addMessage(oneofWKT())
    try registry.registerFile(oneofFile)

    // nesting_types.proto
    var nestingFile = FileDescriptor(name: "nesting_types.proto", package: "testcompat")
    nestingFile.addMessage(nested4())
    nestingFile.addMessage(nested3())
    nestingFile.addMessage(nested2())
    nestingFile.addMessage(nested1())
    nestingFile.addMessage(outerWithNestedDefs())
    nestingFile.addMessage(recursive())
    nestingFile.addMessage(mixedNest1())
    try registry.registerFile(nestingFile)

    // wkt_types.proto
    var wktTypesFile = FileDescriptor(name: "wkt_types.proto", package: "testcompat")
    wktTypesFile.addMessage(wktHolder())
    wktTypesFile.addMessage(repeatedWKTs())
    wktTypesFile.addMessage(mapWKTValues())
    wktTypesFile.addMessage(wktNested())
    wktTypesFile.addMessage(wktMixed())
    try registry.registerFile(wktTypesFile)

    // proto2_types.proto
    var proto2File = FileDescriptor(name: "proto2_types.proto", package: "testcompat2", syntax: "proto2")
    proto2File.addEnum(proto2Enum())
    proto2File.addEnum(proto2NoZero())
    proto2File.addMessage(proto2Basic())
    proto2File.addMessage(proto2Defaults())
    proto2File.addMessage(proto2WithGroup())
    proto2File.addMessage(proto2Extendable())
    proto2File.addMessage(proto2Complex())
    proto2File.addMessage(proto2Oneof())
    proto2File.addMessage(proto2KitchenSink())
    try registry.registerFile(proto2File)

    // realworld_types.proto
    var realworldFile = FileDescriptor(name: "realworld_types.proto", package: "testcompat")
    realworldFile.addEnum(intentFlagEnum())
    realworldFile.addMessage(nullableUint32())
    realworldFile.addMessage(nullableDouble())
    realworldFile.addMessage(nullableBool())
    realworldFile.addMessage(nullableString())
    realworldFile.addMessage(nullableMessage())
    realworldFile.addMessage(withNullables())
    realworldFile.addMessage(nonSequentialFields())
    realworldFile.addMessage(withReserved())
    realworldFile.addMessage(reportResponse())
    realworldFile.addMessage(dateValue())
    realworldFile.addMessage(proto3OptionalMessages())
    realworldFile.addMessage(intentHolder())
    try registry.registerFile(realworldFile)

    // cross_file_types.proto
    var crossFile = FileDescriptor(name: "cross_file_types.proto", package: "testcompat")
    crossFile.addMessage(crossFileAll())
    crossFile.addMessage(crossFileMixed())
    crossFile.addMessage(crossPackageRef())
    crossFile.addMessage(megaMixed())
    crossFile.addMessage(kitchenSinkFlat())
    crossFile.addMessage(deepLevel4())
    crossFile.addMessage(deepLevel3())
    crossFile.addMessage(deepLevel2())
    crossFile.addMessage(deepLevel1())
    try registry.registerFile(crossFile)

    return registry
  }
}
