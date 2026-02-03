//
// DescriptorBridge.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation
import SwiftProtobuf

/// DescriptorBridge provides conversion between SwiftProtoReflect descriptors
/// and Swift Protobuf descriptors.
///
/// This component allows:
/// - Converting SwiftProtoReflect descriptors to Swift Protobuf format.
/// - Creating SwiftProtoReflect descriptors from Swift Protobuf descriptors.
/// - Ensuring compatibility between different metadata representations.
public struct DescriptorBridge {

  // MARK: - Initialization

  /// Creates new DescriptorBridge instance.
  public init() {}

  // MARK: - Message Descriptor Conversion

  /// Converts MessageDescriptor to Google_Protobuf_DescriptorProto.
  ///
  /// - Parameter messageDescriptor: SwiftProtoReflect message descriptor.
  /// - Returns: Message descriptor in Swift Protobuf format.
  /// - Throws: Error if conversion is impossible.
  public func toProtobufDescriptor(
    from messageDescriptor: MessageDescriptor
  ) throws -> Google_Protobuf_DescriptorProto {
    var proto = Google_Protobuf_DescriptorProto()

    // Set message name
    proto.name = messageDescriptor.name

    // Convert fields
    proto.field = try messageDescriptor.allFields().map { field in
      try toProtobufFieldDescriptor(from: field)
    }

    // Convert nested messages
    proto.nestedType = try Array(messageDescriptor.nestedMessages.values).map { nestedMessage in
      try toProtobufDescriptor(from: nestedMessage)
    }

    // Convert nested enums
    proto.enumType = try Array(messageDescriptor.nestedEnums.values).map { nestedEnum in
      try toProtobufEnumDescriptor(from: nestedEnum)
    }

    // Set options if present
    if !messageDescriptor.options.isEmpty {
      proto.options = try toProtobufMessageOptions(from: messageDescriptor.options)
    }

    return proto
  }

  /// Creates MessageDescriptor from Google_Protobuf_DescriptorProto.
  ///
  /// - Parameters:
  ///   - protobufDescriptor: Message descriptor in Swift Protobuf format.
  ///   - parent: Parent file descriptor (optional).
  /// - Returns: SwiftProtoReflect message descriptor.
  /// - Throws: Error if conversion is impossible.
  public func fromProtobufDescriptor(
    _ protobufDescriptor: Google_Protobuf_DescriptorProto,
    parent: FileDescriptor? = nil
  ) throws -> MessageDescriptor {
    var messageDescriptor = MessageDescriptor(
      name: protobufDescriptor.name,
      parent: parent
    )

    // First, convert nested messages (needed for map entry detection)
    for nestedProto in protobufDescriptor.nestedType {
      let nestedMessage = try fromProtobufDescriptor(nestedProto, parent: nil)
      messageDescriptor.addNestedMessage(nestedMessage)
    }

    // Convert nested enums
    for enumProto in protobufDescriptor.enumType {
      let nestedEnum = try fromProtobufEnumDescriptor(enumProto)
      messageDescriptor.addNestedEnum(nestedEnum)
    }

    // Convert fields (now with nested messages available for map detection)
    for fieldProto in protobufDescriptor.field {
      let field = try fromProtobufFieldDescriptor(
        fieldProto,
        messageDescriptor: protobufDescriptor,
        nestedMessages: messageDescriptor.nestedMessages
      )
      messageDescriptor.addField(field)
    }

    // Convert options
    if protobufDescriptor.hasOptions {
      _ = try fromProtobufMessageOptions(protobufDescriptor.options)
      // TODO: Add options support to MessageDescriptor
      // for (key, value) in options {
      //   messageDescriptor.setOption(key: key, value: value)
      // }
    }

    return messageDescriptor
  }

  // MARK: - Field Descriptor Conversion

  /// Converts FieldDescriptor to Google_Protobuf_FieldDescriptorProto.
  ///
  /// - Parameter fieldDescriptor: SwiftProtoReflect field descriptor.
  /// - Returns: Field descriptor in Swift Protobuf format.
  /// - Throws: Error if conversion is impossible.
  public func toProtobufFieldDescriptor(
    from fieldDescriptor: FieldDescriptor
  ) throws -> Google_Protobuf_FieldDescriptorProto {
    var proto = Google_Protobuf_FieldDescriptorProto()

    // Set basic properties
    proto.name = fieldDescriptor.name
    proto.number = Int32(fieldDescriptor.number)

    // Convert field type
    proto.type = try toProtobufFieldType(from: fieldDescriptor.type)

    // Set label (repeated, optional, required)
    if fieldDescriptor.isRepeated {
      proto.label = .repeated
    }
    else if fieldDescriptor.isRequired {
      proto.label = .required
    }
    else {
      proto.label = .optional
    }

    // Set type name for complex types
    if let typeName = fieldDescriptor.typeName {
      proto.typeName = typeName
    }

    // Set JSON name if different
    if fieldDescriptor.jsonName != fieldDescriptor.name {
      proto.jsonName = fieldDescriptor.jsonName
    }

    // Set options if present
    if !fieldDescriptor.options.isEmpty {
      proto.options = try toProtobufFieldOptions(from: fieldDescriptor.options)
    }

    return proto
  }

  /// Creates FieldDescriptor from Google_Protobuf_FieldDescriptorProto.
  ///
  /// - Parameter protobufDescriptor: Field descriptor in Swift Protobuf format.
  /// - Returns: SwiftProtoReflect field descriptor.
  /// - Throws: Error if conversion is impossible.
  public func fromProtobufFieldDescriptor(
    _ protobufDescriptor: Google_Protobuf_FieldDescriptorProto
  ) throws -> FieldDescriptor {
    return try fromProtobufFieldDescriptor(
      protobufDescriptor,
      messageDescriptor: nil,
      nestedMessages: [:]
    )
  }

  /// Creates FieldDescriptor from Google_Protobuf_FieldDescriptorProto with map detection.
  ///
  /// - Parameters:
  ///   - protobufDescriptor: Field descriptor in Swift Protobuf format.
  ///   - messageDescriptor: Parent message descriptor for nested type resolution.
  ///   - nestedMessages: Dictionary of nested messages for map entry detection.
  /// - Returns: SwiftProtoReflect field descriptor.
  /// - Throws: Error if conversion is impossible.
  private func fromProtobufFieldDescriptor(
    _ protobufDescriptor: Google_Protobuf_FieldDescriptorProto,
    messageDescriptor: Google_Protobuf_DescriptorProto?,
    nestedMessages: [String: MessageDescriptor]
  ) throws -> FieldDescriptor {
    // Convert field type
    let fieldType = try fromProtobufFieldType(protobufDescriptor.type)

    // Determine flags
    let isRepeated = protobufDescriptor.label == .repeated
    let isRequired = protobufDescriptor.label == .required
    let isOptional = protobufDescriptor.label == .optional

    // Check if this is a map field
    var isMap = false
    var mapEntryInfo: MapEntryInfo? = nil

    if isRepeated && fieldType == .message && protobufDescriptor.hasTypeName {
      // Try to detect map field
      if let mapInfo = try detectMapField(
        fieldDescriptor: protobufDescriptor,
        messageDescriptor: messageDescriptor,
        nestedMessages: nestedMessages
      ) {
        isMap = true
        mapEntryInfo = mapInfo
      }
    }

    // Create field descriptor
    let fieldDescriptor = FieldDescriptor(
      name: protobufDescriptor.name,
      number: Int(protobufDescriptor.number),
      type: fieldType,
      typeName: protobufDescriptor.hasTypeName ? protobufDescriptor.typeName : nil,
      jsonName: protobufDescriptor.hasJsonName ? protobufDescriptor.jsonName : protobufDescriptor.name,
      isRepeated: isRepeated,
      isOptional: isOptional,
      isRequired: isRequired,
      isMap: isMap,
      mapEntryInfo: mapEntryInfo
    )

    // Convert options
    if protobufDescriptor.hasOptions {
      _ = try fromProtobufFieldOptions(protobufDescriptor.options)
      // TODO: Add options support to FieldDescriptor
      // for (key, value) in options {
      //   fieldDescriptor.setOption(key: key, value: value)
      // }
    }

    return fieldDescriptor
  }

  // MARK: - Enum Descriptor Conversion

  /// Converts EnumDescriptor to Google_Protobuf_EnumDescriptorProto.
  ///
  /// - Parameter enumDescriptor: SwiftProtoReflect enum descriptor.
  /// - Returns: Enum descriptor in Swift Protobuf format.
  /// - Throws: Error if conversion is impossible.
  public func toProtobufEnumDescriptor(
    from enumDescriptor: EnumDescriptor
  ) throws -> Google_Protobuf_EnumDescriptorProto {
    var proto = Google_Protobuf_EnumDescriptorProto()

    // Set enum name
    proto.name = enumDescriptor.name

    // Convert enum values
    proto.value = enumDescriptor.allValues().map { enumValue in
      var valueProto = Google_Protobuf_EnumValueDescriptorProto()
      valueProto.name = enumValue.name
      valueProto.number = Int32(enumValue.number)

      // Set value options if present
      if !enumValue.options.isEmpty {
        // In real implementation there should be options conversion
        // valueProto.options = ...
      }

      return valueProto
    }

    // Set enum options if present
    if !enumDescriptor.options.isEmpty {
      // In real implementation there should be options conversion
      // proto.options = ...
    }

    return proto
  }

  /// Creates EnumDescriptor from Google_Protobuf_EnumDescriptorProto.
  ///
  /// - Parameters:
  ///   - protobufDescriptor: Enum descriptor in Swift Protobuf format.
  ///   - parent: Parent descriptor (optional).
  /// - Returns: SwiftProtoReflect enum descriptor.
  /// - Throws: Error if conversion is impossible.
  public func fromProtobufEnumDescriptor(
    _ protobufDescriptor: Google_Protobuf_EnumDescriptorProto,
    parent: Any? = nil
  ) throws -> EnumDescriptor {
    var enumDescriptor = EnumDescriptor(
      name: protobufDescriptor.name,
      parent: parent
    )

    // Convert enum values
    for valueProto in protobufDescriptor.value {
      enumDescriptor.addValue(
        EnumDescriptor.EnumValue(
          name: valueProto.name,
          number: Int(valueProto.number)
        )
      )
    }

    return enumDescriptor
  }

  // MARK: - File Descriptor Conversion

  /// Converts FileDescriptor to Google_Protobuf_FileDescriptorProto.
  ///
  /// - Parameter fileDescriptor: SwiftProtoReflect file descriptor.
  /// - Returns: File descriptor in Swift Protobuf format.
  /// - Throws: Error if conversion is impossible.
  public func toProtobufFileDescriptor(
    from fileDescriptor: FileDescriptor
  ) throws -> Google_Protobuf_FileDescriptorProto {
    var proto = Google_Protobuf_FileDescriptorProto()

    // Set basic properties
    proto.name = fileDescriptor.name
    if !fileDescriptor.package.isEmpty {
      proto.package = fileDescriptor.package
    }

    // Convert messages
    proto.messageType = try Array(fileDescriptor.messages.values).map { message in
      try toProtobufDescriptor(from: message)
    }

    // Convert enums
    proto.enumType = try Array(fileDescriptor.enums.values).map { enumDesc in
      try toProtobufEnumDescriptor(from: enumDesc)
    }

    // Convert services
    proto.service = try Array(fileDescriptor.services.values).map { service in
      try toProtobufServiceDescriptor(from: service)
    }

    // Set dependencies
    proto.dependency = fileDescriptor.dependencies

    return proto
  }

  /// Creates FileDescriptor from Google_Protobuf_FileDescriptorProto.
  ///
  /// - Parameter protobufDescriptor: File descriptor in Swift Protobuf format.
  /// - Returns: SwiftProtoReflect file descriptor.
  /// - Throws: Error if conversion is impossible.
  public func fromProtobufFileDescriptor(
    _ protobufDescriptor: Google_Protobuf_FileDescriptorProto
  ) throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(
      name: protobufDescriptor.name,
      package: protobufDescriptor.hasPackage ? protobufDescriptor.package : "",
      dependencies: protobufDescriptor.dependency
    )

    // Convert messages
    for messageProto in protobufDescriptor.messageType {
      let message = try fromProtobufDescriptor(messageProto, parent: fileDescriptor)
      fileDescriptor.addMessage(message)
    }

    // Convert enums
    for enumProto in protobufDescriptor.enumType {
      let enumDesc = try fromProtobufEnumDescriptor(enumProto, parent: fileDescriptor)
      fileDescriptor.addEnum(enumDesc)
    }

    // Convert services
    for serviceProto in protobufDescriptor.service {
      let service = try fromProtobufServiceDescriptor(serviceProto, parent: fileDescriptor)
      fileDescriptor.addService(service)
    }

    return fileDescriptor
  }

  // MARK: - Service Descriptor Conversion

  /// Converts ServiceDescriptor to Google_Protobuf_ServiceDescriptorProto.
  ///
  /// - Parameter serviceDescriptor: SwiftProtoReflect service descriptor.
  /// - Returns: Service descriptor in Swift Protobuf format.
  /// - Throws: Error if conversion is impossible.
  public func toProtobufServiceDescriptor(
    from serviceDescriptor: ServiceDescriptor
  ) throws -> Google_Protobuf_ServiceDescriptorProto {
    var proto = Google_Protobuf_ServiceDescriptorProto()

    // Set service name
    proto.name = serviceDescriptor.name

    // Convert methods
    proto.method = serviceDescriptor.allMethods().map { method in
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

  /// Creates ServiceDescriptor from Google_Protobuf_ServiceDescriptorProto.
  ///
  /// - Parameters:
  ///   - protobufDescriptor: Service descriptor in Swift Protobuf format.
  ///   - parent: Parent file descriptor (optional).
  /// - Returns: SwiftProtoReflect service descriptor.
  /// - Throws: Error if conversion is impossible.
  public func fromProtobufServiceDescriptor(
    _ protobufDescriptor: Google_Protobuf_ServiceDescriptorProto,
    parent: FileDescriptor? = nil
  ) throws -> ServiceDescriptor {
    var serviceDescriptor = ServiceDescriptor(
      name: protobufDescriptor.name,
      parent: parent ?? FileDescriptor(name: "", package: "")
    )

    // Convert methods
    for methodProto in protobufDescriptor.method {
      serviceDescriptor.addMethod(
        ServiceDescriptor.MethodDescriptor(
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

  // MARK: - Helper Methods

  /// Converts FieldType to Google_Protobuf_FieldDescriptorProto.TypeEnum.
  private func toProtobufFieldType(from fieldType: FieldType) throws -> Google_Protobuf_FieldDescriptorProto.TypeEnum {
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

  /// Converts Google_Protobuf_FieldDescriptorProto.TypeEnum to FieldType.
  private func fromProtobufFieldType(_ protobufType: Google_Protobuf_FieldDescriptorProto.TypeEnum) throws -> FieldType
  {
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
      throw DescriptorBridgeError.unsupportedFieldType(-1)
    }
  }

  /// Converts message options to Google_Protobuf_MessageOptions.
  private func toProtobufMessageOptions(from options: [String: Any]) throws -> Google_Protobuf_MessageOptions {
    // Stub for options conversion
    // In real implementation there should be full conversion logic
    return Google_Protobuf_MessageOptions()
  }

  /// Converts Google_Protobuf_MessageOptions to options dictionary.
  private func fromProtobufMessageOptions(_ options: Google_Protobuf_MessageOptions) throws -> [String: Any] {
    // Stub for options conversion
    // In real implementation there should be full conversion logic
    return [:]
  }

  /// Converts field options to Google_Protobuf_FieldOptions.
  private func toProtobufFieldOptions(from options: [String: Any]) throws -> Google_Protobuf_FieldOptions {
    // Stub for options conversion
    // In real implementation there should be full conversion logic
    return Google_Protobuf_FieldOptions()
  }

  /// Converts Google_Protobuf_FieldOptions to options dictionary.
  private func fromProtobufFieldOptions(_ options: Google_Protobuf_FieldOptions) throws -> [String: Any] {
    // Stub for options conversion
    // In real implementation there should be full conversion logic
    return [:]
  }

  // MARK: - Map Field Detection

  /// Detects if a field is a map and extracts map entry information.
  ///
  /// According to Protocol Buffers specification, map fields are represented as:
  /// - Repeated message field with a specific entry message
  /// - Entry message has `map_entry = true` option
  /// - Entry message has exactly 2 fields: "key" (tag 1) and "value" (tag 2)
  ///
  /// - Parameters:
  ///   - fieldDescriptor: Field descriptor to check.
  ///   - messageDescriptor: Parent message descriptor containing nested types.
  ///   - nestedMessages: Already converted nested messages.
  /// - Returns: MapEntryInfo if field is a map, nil otherwise.
  /// - Throws: Error if map entry structure is invalid.
  private func detectMapField(
    fieldDescriptor: Google_Protobuf_FieldDescriptorProto,
    messageDescriptor: Google_Protobuf_DescriptorProto?,
    nestedMessages: [String: MessageDescriptor]
  ) throws -> MapEntryInfo? {
    guard let typeName = fieldDescriptor.hasTypeName ? fieldDescriptor.typeName : nil else {
      return nil
    }

    // Extract the simple name from the type name (e.g., ".package.Message.EntryMessage" -> "EntryMessage")
    let entryMessageName = extractSimpleName(from: typeName)

    // Try to find the entry message in nested messages
    guard let entryMessage = findMapEntryMessage(
      named: entryMessageName,
      in: messageDescriptor,
      nestedMessages: nestedMessages
    ) else {
      return nil
    }

    // Check if this message has map_entry option
    guard isMapEntryMessage(entryMessage) else {
      return nil
    }

    // Extract key and value fields
    guard let keyField = entryMessage.field.first(where: { $0.number == 1 }),
      let valueField = entryMessage.field.first(where: { $0.number == 2 })
    else {
      throw DescriptorBridgeError.invalidDescriptorStructure(
        "Map entry message '\(entryMessageName)' must have exactly 2 fields with numbers 1 (key) and 2 (value)"
      )
    }

    // Validate key and value fields
    guard keyField.name == "key" && valueField.name == "value" else {
      throw DescriptorBridgeError.invalidDescriptorStructure(
        "Map entry message '\(entryMessageName)' fields must be named 'key' and 'value'"
      )
    }

    // Convert key field type
    let keyType = try fromProtobufFieldType(keyField.type)

    // Validate key type (only scalar types except float, double, bytes are allowed)
    let validKeyTypes: [FieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .string,
    ]

    guard validKeyTypes.contains(keyType) else {
      throw DescriptorBridgeError.invalidDescriptorStructure(
        "Invalid map key type '\(keyType)'. Only scalar types except float, double, and bytes are allowed"
      )
    }

    // Convert value field type
    let valueType = try fromProtobufFieldType(valueField.type)

    // Create key and value field info
    let keyFieldInfo = KeyFieldInfo(
      name: keyField.name,
      number: Int(keyField.number),
      type: keyType
    )

    let valueFieldInfo = ValueFieldInfo(
      name: valueField.name,
      number: Int(valueField.number),
      type: valueType,
      typeName: valueField.hasTypeName ? valueField.typeName : nil
    )

    return MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)
  }

  /// Extracts simple name from a fully qualified type name.
  ///
  /// Examples:
  /// - ".package.Message.EntryMessage" -> "EntryMessage"
  /// - "EntryMessage" -> "EntryMessage"
  /// - ".Message" -> "Message"
  ///
  /// - Parameter typeName: Fully qualified type name.
  /// - Returns: Simple name without package and parent message prefixes.
  private func extractSimpleName(from typeName: String) -> String {
    let components = typeName.split(separator: ".")
    return String(components.last ?? "")
  }

  /// Finds a map entry message by name in the parent message's nested types.
  ///
  /// - Parameters:
  ///   - name: Simple name of the entry message.
  ///   - messageDescriptor: Parent message descriptor.
  ///   - nestedMessages: Already converted nested messages.
  /// - Returns: Map entry message descriptor if found, nil otherwise.
  private func findMapEntryMessage(
    named name: String,
    in messageDescriptor: Google_Protobuf_DescriptorProto?,
    nestedMessages: [String: MessageDescriptor]
  ) -> Google_Protobuf_DescriptorProto? {
    guard let messageDescriptor = messageDescriptor else {
      return nil
    }

    // Search in nested types
    return messageDescriptor.nestedType.first { $0.name == name }
  }

  /// Checks if a message descriptor is a map entry message.
  ///
  /// A message is a map entry if it has the `map_entry = true` option set.
  ///
  /// - Parameter messageDescriptor: Message descriptor to check.
  /// - Returns: true if message is a map entry, false otherwise.
  private func isMapEntryMessage(_ messageDescriptor: Google_Protobuf_DescriptorProto) -> Bool {
    guard messageDescriptor.hasOptions else {
      return false
    }

    return messageDescriptor.options.mapEntry
  }
}

/// Errors that occur when working with DescriptorBridge.
public enum DescriptorBridgeError: Error, LocalizedError {
  case unsupportedFieldType(Int)
  case conversionFailed(String)
  case missingRequiredField(String)
  case invalidDescriptorStructure(String)

  public var errorDescription: String? {
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
