//
// _DescriptorBridge.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation
import SwiftProtobuf

internal struct _DescriptorBridge {

  // MARK: - Message Descriptor Conversion

  func toSwiftProtobuf(
    from messageDescriptor: _MessageDescriptor
  ) throws -> Google_Protobuf_DescriptorProto {
    var proto = Google_Protobuf_DescriptorProto()

    proto.name = messageDescriptor.name

    proto.field = try messageDescriptor.allFields().map { field in
      try toProtobufFieldDescriptor(from: field)
    }

    proto.nestedType = try Array(messageDescriptor.nestedMessages.values).map { nestedMessage in
      try toSwiftProtobuf(from: nestedMessage)
    }

    proto.enumType = try Array(messageDescriptor.nestedEnums.values).map { nestedEnum in
      try toProtobufEnumDescriptor(from: nestedEnum)
    }

    proto.oneofDecl = messageDescriptor.oneofDecls.sorted { $0.index < $1.index }.map { oneof in
      var oneofProto = Google_Protobuf_OneofDescriptorProto()
      oneofProto.name = oneof.name
      return oneofProto
    }

    proto.extensionRange = messageDescriptor.extensionRanges.map { range in
      var rangeProto = Google_Protobuf_DescriptorProto.ExtensionRange()
      rangeProto.start = Int32(range.start)
      rangeProto.end = Int32(range.end)
      return rangeProto
    }

    if !messageDescriptor.options.isEmpty {
      proto.options = try toProtobufMessageOptions(from: messageDescriptor.options)
    }

    return proto
  }

  func fromProtobufDescriptor(
    _ protobufDescriptor: Google_Protobuf_DescriptorProto,
    parent: (any _DescriptorParent)? = nil
  ) throws -> _MessageDescriptor {
    var messageDescriptor = _MessageDescriptor(
      name: protobufDescriptor.name,
      parent: parent
    )

    for nestedProto in protobufDescriptor.nestedType {
      let nestedMessage = try fromProtobufDescriptor(nestedProto, parent: messageDescriptor)
      messageDescriptor.addNestedMessage(nestedMessage)
    }

    for enumProto in protobufDescriptor.enumType {
      let nestedEnum = try fromProtobufEnumDescriptor(enumProto, parent: messageDescriptor)
      messageDescriptor.addNestedEnum(nestedEnum)
    }

    let syntax = messageDescriptor.syntax
    for fieldProto in protobufDescriptor.field {
      let field = try fromProtobufFieldDescriptor(
        fieldProto,
        messageDescriptor: protobufDescriptor,
        nestedMessages: messageDescriptor.nestedMessages,
        syntax: syntax
      )
      messageDescriptor.addField(field)
    }

    for (index, oneofProto) in protobufDescriptor.oneofDecl.enumerated() {
      messageDescriptor.addOneofDecl(_OneofDescriptor(name: oneofProto.name, index: index))
    }

    for rangeProto in protobufDescriptor.extensionRange {
      messageDescriptor.addExtensionRange(
        _ExtensionRange(start: Int(rangeProto.start), end: Int(rangeProto.end))
      )
    }

    if protobufDescriptor.hasOptions {
      _ = try fromProtobufMessageOptions(protobufDescriptor.options)
    }

    return messageDescriptor
  }

  // MARK: - Field Descriptor Conversion

  func toProtobufFieldDescriptor(
    from fieldDescriptor: _FieldDescriptor
  ) throws -> Google_Protobuf_FieldDescriptorProto {
    var proto = Google_Protobuf_FieldDescriptorProto()

    proto.name = fieldDescriptor.name
    proto.number = Int32(fieldDescriptor.number)
    proto.type = try toProtobufFieldType(from: fieldDescriptor.type)

    if fieldDescriptor.isRepeated {
      proto.label = .repeated
    }
    else if fieldDescriptor.isRequired {
      proto.label = .required
    }
    else {
      proto.label = .optional
    }

    if let typeName = fieldDescriptor.typeName {
      proto.typeName = typeName
    }

    if fieldDescriptor.jsonName != fieldDescriptor.name {
      proto.jsonName = fieldDescriptor.jsonName
    }

    if let idx = fieldDescriptor.oneofIndex {
      proto.oneofIndex = Int32(idx)
    }

    if !fieldDescriptor.options.isEmpty {
      proto.options = try toProtobufFieldOptions(from: fieldDescriptor.options)
    }

    return proto
  }

  func fromProtobufFieldDescriptor(
    _ protobufDescriptor: Google_Protobuf_FieldDescriptorProto,
    syntax: String = "proto3"
  ) throws -> _FieldDescriptor {
    return try fromProtobufFieldDescriptor(
      protobufDescriptor,
      messageDescriptor: nil,
      nestedMessages: [:],
      syntax: syntax
    )
  }

  private func fromProtobufFieldDescriptor(
    _ protobufDescriptor: Google_Protobuf_FieldDescriptorProto,
    messageDescriptor: Google_Protobuf_DescriptorProto?,
    nestedMessages: [String: _MessageDescriptor],
    syntax: String = "proto3"
  ) throws -> _FieldDescriptor {
    let fieldType = try fromProtobufFieldType(protobufDescriptor.type)

    let isRepeated = protobufDescriptor.label == .repeated
    let isRequired = syntax != "proto3" && protobufDescriptor.label == .required
    let isOptional = protobufDescriptor.label == .optional

    var isMap = false
    var mapEntryInfo: _MapEntryInfo? = nil

    if isRepeated && fieldType == .message && protobufDescriptor.hasTypeName {
      if let mapInfo = try detectMapField(
        fieldDescriptor: protobufDescriptor,
        messageDescriptor: messageDescriptor,
        nestedMessages: nestedMessages
      ) {
        isMap = true
        mapEntryInfo = mapInfo
      }
    }

    let oneofIndex: Int? = protobufDescriptor.hasOneofIndex ? Int(protobufDescriptor.oneofIndex) : nil

    let defaultValue = parseDefaultValue(protobufDescriptor, fieldType: fieldType)
    let isPacked = parseIsPacked(protobufDescriptor)

    let fieldDescriptor = _FieldDescriptor(
      name: protobufDescriptor.name,
      number: Int(protobufDescriptor.number),
      type: fieldType,
      typeName: protobufDescriptor.hasTypeName ? protobufDescriptor.typeName : nil,
      jsonName: protobufDescriptor.hasJsonName ? protobufDescriptor.jsonName : protobufDescriptor.name,
      isRepeated: isRepeated,
      isOptional: isOptional,
      isRequired: isRequired,
      isMap: isMap,
      oneofIndex: oneofIndex,
      mapEntryInfo: mapEntryInfo,
      defaultValue: defaultValue,
      isPacked: isPacked
    )

    if protobufDescriptor.hasOptions {
      _ = try fromProtobufFieldOptions(protobufDescriptor.options)
    }

    return fieldDescriptor
  }

  // MARK: - Enum Descriptor Conversion

  func toProtobufEnumDescriptor(
    from enumDescriptor: _EnumDescriptor
  ) throws -> Google_Protobuf_EnumDescriptorProto {
    var proto = Google_Protobuf_EnumDescriptorProto()

    proto.name = enumDescriptor.name

    proto.value = enumDescriptor.valuesByName.values.sorted { $0.number < $1.number }.map { enumValue in
      var valueProto = Google_Protobuf_EnumValueDescriptorProto()
      valueProto.name = enumValue.name
      valueProto.number = Int32(enumValue.number)
      return valueProto
    }

    return proto
  }

  func fromProtobufEnumDescriptor(
    _ protobufDescriptor: Google_Protobuf_EnumDescriptorProto,
    parent: (any _DescriptorParent)? = nil
  ) throws -> _EnumDescriptor {
    var enumDescriptor = _EnumDescriptor(
      name: protobufDescriptor.name,
      parent: parent
    )
    for valueProto in protobufDescriptor.value {
      enumDescriptor.addValue(
        _EnumDescriptor._EnumValue(name: valueProto.name, number: Int(valueProto.number))
      )
    }
    return enumDescriptor
  }

  // MARK: - File Descriptor Conversion

  func toProtobufFileDescriptor(
    from fileDescriptor: _FileDescriptor
  ) throws -> Google_Protobuf_FileDescriptorProto {
    var proto = Google_Protobuf_FileDescriptorProto()

    proto.name = fileDescriptor.name
    if !fileDescriptor.package.isEmpty {
      proto.package = fileDescriptor.package
    }
    proto.syntax = fileDescriptor.syntax

    proto.messageType = try Array(fileDescriptor.messages.values).map { message in
      try toSwiftProtobuf(from: message)
    }

    proto.enumType = try Array(fileDescriptor.enums.values).map { enumDesc in
      try toProtobufEnumDescriptor(from: enumDesc)
    }

    proto.service = try Array(fileDescriptor.services.values).map { service in
      try toProtobufServiceDescriptor(from: service)
    }

    proto.dependency = fileDescriptor.dependencies

    return proto
  }

  func fromProtobufFileDescriptor(
    _ protobufDescriptor: Google_Protobuf_FileDescriptorProto
  ) throws -> _FileDescriptor {
    let syntax = protobufDescriptor.hasSyntax ? protobufDescriptor.syntax : ""
    var fileDescriptor = _FileDescriptor(
      name: protobufDescriptor.name,
      package: protobufDescriptor.hasPackage ? protobufDescriptor.package : "",
      dependencies: protobufDescriptor.dependency,
      syntax: syntax
    )

    for messageProto in protobufDescriptor.messageType {
      let message = try fromProtobufDescriptor(
        messageProto,
        parent: fileDescriptor as (any _DescriptorParent)?
      )
      fileDescriptor.addMessage(message)
    }

    for enumProto in protobufDescriptor.enumType {
      let enumDesc = try fromProtobufEnumDescriptor(
        enumProto,
        parent: fileDescriptor as (any _DescriptorParent)?
      )
      fileDescriptor.addEnum(enumDesc)
    }

    for serviceProto in protobufDescriptor.service {
      let service = try fromProtobufServiceDescriptor(serviceProto, parent: fileDescriptor)
      fileDescriptor.addService(service)
    }

    return fileDescriptor
  }

  // MARK: - Service Descriptor Conversion

  func toProtobufServiceDescriptor(
    from serviceDescriptor: _ServiceDescriptor
  ) throws -> Google_Protobuf_ServiceDescriptorProto {
    var proto = Google_Protobuf_ServiceDescriptorProto()

    proto.name = serviceDescriptor.name

    proto.method = serviceDescriptor.methodsByName.values.map { method in
      var methodProto = Google_Protobuf_MethodDescriptorProto()
      methodProto.name = method.name
      methodProto.inputType = method.inputType
      methodProto.outputType = method.outputType
      methodProto.clientStreaming = method.clientStreaming
      methodProto.serverStreaming = method.serverStreaming
      return methodProto
    }

    return proto
  }

  func fromProtobufServiceDescriptor(
    _ protobufDescriptor: Google_Protobuf_ServiceDescriptorProto,
    parent: _FileDescriptor? = nil
  ) throws -> _ServiceDescriptor {
    var serviceDescriptor = _ServiceDescriptor(
      name: protobufDescriptor.name,
      fullName: parent.map { p in
        p.package.isEmpty ? protobufDescriptor.name : "\(p.package).\(protobufDescriptor.name)"
      } ?? protobufDescriptor.name
    )

    for methodProto in protobufDescriptor.method {
      serviceDescriptor.addMethod(
        _ServiceDescriptor._MethodDescriptor(
          name: methodProto.name,
          inputType: methodProto.inputType,
          outputType: methodProto.outputType,
          clientStreaming: methodProto.clientStreaming,
          serverStreaming: methodProto.serverStreaming
        )
      )
    }

    return serviceDescriptor
  }

  // MARK: - Proto2 Parsing Helpers

  private func parseDefaultValue(
    _ proto: Google_Protobuf_FieldDescriptorProto,
    fieldType: _FieldType
  ) -> _DescriptorOption? {
    guard proto.hasDefaultValue, !proto.defaultValue.isEmpty else {
      return nil
    }

    let raw = proto.defaultValue
    switch fieldType {
    case .string:
      return .string(raw)
    case .bytes:
      return .bytes(Data(raw.utf8))
    case .bool:
      return .bool(raw == "true" || raw == "1")
    case .float:
      guard let val = Float(raw) else { return .string(raw) }
      return .float(val)
    case .double:
      guard let val = Double(raw) else { return .string(raw) }
      return .double(val)
    case .int32, .sint32, .sfixed32:
      guard let val = Int(raw) else { return .string(raw) }
      return .int(val)
    case .int64, .sint64, .sfixed64:
      guard let val = Int(raw) else { return .string(raw) }
      return .int(val)
    case .uint32, .fixed32:
      guard let val = Int(raw) else { return .string(raw) }
      return .int(val)
    case .uint64, .fixed64:
      guard let val = Int(raw) else { return .string(raw) }
      return .int(val)
    case .enum:
      return .string(raw)
    case .message, .group:
      return nil
    }
  }

  private func parseIsPacked(_ proto: Google_Protobuf_FieldDescriptorProto) -> Bool? {
    guard proto.hasOptions, proto.options.hasPacked else {
      return nil
    }
    return proto.options.packed
  }

  // MARK: - Helper Methods

  private func toProtobufFieldType(
    from fieldType: _FieldType
  ) throws -> Google_Protobuf_FieldDescriptorProto.TypeEnum {
    switch fieldType {
    case .double: return .double
    case .float: return .float
    case .int64: return .int64
    case .uint64: return .uint64
    case .int32: return .int32
    case .fixed64: return .fixed64
    case .fixed32: return .fixed32
    case .bool: return .bool
    case .string: return .string
    case .group: return .group
    case .message: return .message
    case .bytes: return .bytes
    case .uint32: return .uint32
    case .enum: return .enum
    case .sfixed32: return .sfixed32
    case .sfixed64: return .sfixed64
    case .sint32: return .sint32
    case .sint64: return .sint64
    }
  }

  private func fromProtobufFieldType(
    _ protobufType: Google_Protobuf_FieldDescriptorProto.TypeEnum
  ) throws -> _FieldType {
    switch protobufType {
    case .double: return .double
    case .float: return .float
    case .int64: return .int64
    case .uint64: return .uint64
    case .int32: return .int32
    case .fixed64: return .fixed64
    case .fixed32: return .fixed32
    case .bool: return .bool
    case .string: return .string
    case .group: return .group
    case .message: return .message
    case .bytes: return .bytes
    case .uint32: return .uint32
    case .enum: return .enum
    case .sfixed32: return .sfixed32
    case .sfixed64: return .sfixed64
    case .sint32: return .sint32
    case .sint64: return .sint64
    @unknown default:
      throw _DescriptorBridgeError.unsupportedFieldType(-1)
    }
  }

  private func toProtobufMessageOptions(
    from options: [String: _DescriptorOption]
  ) throws -> Google_Protobuf_MessageOptions {
    return Google_Protobuf_MessageOptions()
  }

  private func fromProtobufMessageOptions(
    _ options: Google_Protobuf_MessageOptions
  ) throws -> [String: _DescriptorOption] {
    return [:]
  }

  private func toProtobufFieldOptions(
    from options: [String: _DescriptorOption]
  ) throws -> Google_Protobuf_FieldOptions {
    return Google_Protobuf_FieldOptions()
  }

  private func fromProtobufFieldOptions(
    _ options: Google_Protobuf_FieldOptions
  ) throws -> [String: _DescriptorOption] {
    return [:]
  }

  // MARK: - Map Field Detection

  private func detectMapField(
    fieldDescriptor: Google_Protobuf_FieldDescriptorProto,
    messageDescriptor: Google_Protobuf_DescriptorProto?,
    nestedMessages: [String: _MessageDescriptor]
  ) throws -> _MapEntryInfo? {
    guard let typeName = fieldDescriptor.hasTypeName ? fieldDescriptor.typeName : nil else {
      return nil
    }

    let entryMessageName = extractSimpleName(from: typeName)

    guard
      let entryMessage = findMapEntryMessage(
        named: entryMessageName,
        in: messageDescriptor,
        nestedMessages: nestedMessages
      )
    else {
      return nil
    }

    guard isMapEntryMessage(entryMessage) else {
      return nil
    }

    guard let keyField = entryMessage.field.first(where: { $0.number == 1 }),
      let valueField = entryMessage.field.first(where: { $0.number == 2 })
    else {
      throw _DescriptorBridgeError.invalidDescriptorStructure(
        "Map entry message '\(entryMessageName)' must have exactly 2 fields with numbers 1 (key) and 2 (value)"
      )
    }

    guard keyField.name == "key" && valueField.name == "value" else {
      throw _DescriptorBridgeError.invalidDescriptorStructure(
        "Map entry message '\(entryMessageName)' fields must be named 'key' and 'value'"
      )
    }

    let keyType = try fromProtobufFieldType(keyField.type)

    let validKeyTypes: [_FieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .string,
    ]

    guard validKeyTypes.contains(keyType) else {
      throw _DescriptorBridgeError.invalidDescriptorStructure(
        "Invalid map key type '\(keyType)'. Only scalar types except float, double, and bytes are allowed"
      )
    }

    let valueType = try fromProtobufFieldType(valueField.type)

    let keyFieldInfo = _KeyFieldInfo(
      name: keyField.name,
      number: Int(keyField.number),
      type: keyType
    )

    let valueFieldInfo = _ValueFieldInfo(
      name: valueField.name,
      number: Int(valueField.number),
      type: valueType,
      typeName: valueField.hasTypeName ? valueField.typeName : nil
    )

    return _MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)
  }

  private func extractSimpleName(from typeName: String) -> String {
    let components = typeName.split(separator: ".")
    return String(components.last ?? "")
  }

  private func findMapEntryMessage(
    named name: String,
    in messageDescriptor: Google_Protobuf_DescriptorProto?,
    nestedMessages: [String: _MessageDescriptor]
  ) -> Google_Protobuf_DescriptorProto? {
    guard let messageDescriptor = messageDescriptor else {
      return nil
    }
    return messageDescriptor.nestedType.first { $0.name == name }
  }

  private func isMapEntryMessage(_ messageDescriptor: Google_Protobuf_DescriptorProto) -> Bool {
    guard messageDescriptor.hasOptions else {
      return false
    }
    return messageDescriptor.options.mapEntry
  }
}

internal enum _DescriptorBridgeError: Error, LocalizedError {
  case unsupportedFieldType(Int)
  case conversionFailed(String)
  case missingRequiredField(String)
  case invalidDescriptorStructure(String)

  var errorDescription: String? {
    switch self {
    case .unsupportedFieldType(let value):
      return "Unsupported field type: \(value)"
    case .conversionFailed(let details):
      return "Conversion error: \(details)"
    case .missingRequiredField(let fieldName):
      return "Missing required field: \(fieldName)"
    case .invalidDescriptorStructure(let details):
      return "Invalid descriptor structure: \(details)"
    }
  }
}
