import Foundation
import SwiftProtobuf

/// A registry for managing and accessing Protocol Buffer descriptors.
///
/// The `DescriptorRegistry` provides a centralized repository for storing and retrieving
/// Protocol Buffer descriptors. It supports registration of file descriptors and lookup
/// of message and enum descriptors by their fully qualified names.
///
/// Example:
/// ```swift
/// let registry = DescriptorRegistry.shared
///
/// // Register a file descriptor
/// try registry.registerFileDescriptor(fileDescriptor)
///
/// // Look up a message descriptor
/// let messageDescriptor = try registry.messageDescriptor(forTypeName: "example.Person")
/// ```
public class DescriptorRegistry {
  /// The shared singleton instance of the descriptor registry.
  public static let shared = DescriptorRegistry()

  /// Thread-safe storage for file descriptors.
  private let queue = DispatchQueue(label: "com.swiftprotoreflect.descriptorregistry", attributes: .concurrent)

  /// Storage for file descriptors, keyed by their name.
  private var fileDescriptors: [String: Google_Protobuf_FileDescriptorProto] = [:]

  /// Storage for message descriptors, keyed by their fully qualified name.
  private var messageDescriptors: [String: ProtoMessageDescriptor] = [:]

  /// Storage for enum descriptors, keyed by their fully qualified name.
  private var enumDescriptors: [String: ProtoEnumDescriptor] = [:]

  /// Private initializer to enforce singleton pattern.
  private init() {}

  /// Registers a file descriptor with the registry.
  ///
  /// - Parameter fileDescriptor: The file descriptor to register.
  /// - Throws: An error if the file descriptor is invalid or if there was an error processing it.
  public func registerFileDescriptor(_ fileDescriptor: Google_Protobuf_FileDescriptorProto) throws {
    if fileDescriptor.name.isEmpty {
      throw DescriptorError.invalidFileDescriptor("File descriptor has no name")
    }

    queue.async(flags: .barrier) { [weak self] in
      guard let self = self else { return }
      self.fileDescriptors[fileDescriptor.name] = fileDescriptor
      self.processFileDescriptor(fileDescriptor)
    }
  }

  /// Retrieves a message descriptor by its fully qualified type name.
  ///
  /// - Parameter typeName: The fully qualified name of the message type.
  /// - Returns: The message descriptor for the specified type.
  /// - Throws: An error if the message descriptor is not found.
  public func messageDescriptor(forTypeName typeName: String) throws -> ProtoMessageDescriptor {
    var result: ProtoMessageDescriptor?

    queue.sync {
      result = messageDescriptors[typeName]
    }

    guard let descriptor = result else {
      throw DescriptorError.descriptorNotFound("Message descriptor not found for type: \(typeName)")
    }

    return descriptor
  }

  /// Retrieves an enum descriptor by its fully qualified type name.
  ///
  /// - Parameter typeName: The fully qualified name of the enum type.
  /// - Returns: The enum descriptor for the specified type.
  /// - Throws: An error if the enum descriptor is not found.
  public func enumDescriptor(forTypeName typeName: String) throws -> ProtoEnumDescriptor {
    var result: ProtoEnumDescriptor?

    queue.sync {
      result = enumDescriptors[typeName]
    }

    guard let descriptor = result else {
      throw DescriptorError.descriptorNotFound("Enum descriptor not found for type: \(typeName)")
    }

    return descriptor
  }

  /// Processes a file descriptor to extract and store message and enum descriptors.
  ///
  /// - Parameter fileDescriptor: The file descriptor to process.
  private func processFileDescriptor(_ fileDescriptor: Google_Protobuf_FileDescriptorProto) {
    let packageName = fileDescriptor.package

    // Process message types
    for messageType in fileDescriptor.messageType {
      let fullName = packageName.isEmpty ? messageType.name : "\(packageName).\(messageType.name)"
      let messageDescriptor = createMessageDescriptor(messageType, packageName: packageName)
      messageDescriptors[fullName] = messageDescriptor
    }

    // Process enum types
    for enumType in fileDescriptor.enumType {
      let fullName = packageName.isEmpty ? enumType.name : "\(packageName).\(enumType.name)"
      let enumDescriptor = createEnumDescriptor(enumType)
      enumDescriptors[fullName] = enumDescriptor
    }
  }

  /// Creates a message descriptor from a Protocol Buffer message descriptor proto.
  ///
  /// - Parameters:
  ///   - descriptorProto: The Protocol Buffer message descriptor proto.
  ///   - packageName: The package name for the message.
  /// - Returns: A message descriptor.
  private func createMessageDescriptor(_ descriptorProto: Google_Protobuf_DescriptorProto, packageName: String)
    -> ProtoMessageDescriptor
  {
    let fullName = packageName.isEmpty ? descriptorProto.name : "\(packageName).\(descriptorProto.name)"

    // Create nested enum descriptors first so we can reference them when creating fields
    var enums: [ProtoEnumDescriptor] = []
    for enumProto in descriptorProto.enumType {
      let enumDescriptor = createEnumDescriptor(enumProto)
      enums.append(enumDescriptor)
    }

    // Create nested message descriptors
    var nestedMessages: [ProtoMessageDescriptor] = []
    for nestedMessageProto in descriptorProto.nestedType {
      let nestedMessageDescriptor = createMessageDescriptor(nestedMessageProto, packageName: fullName)
      nestedMessages.append(nestedMessageDescriptor)
    }

    // Create field descriptors
    var fields: [ProtoFieldDescriptor] = []
    for fieldProto in descriptorProto.field {
      let fieldType = mapFieldType(fieldProto.type)
      let isRepeated = fieldProto.label == .repeated
      let isMap = isMapField(fieldProto, descriptorProto)

      // Find the message type for message fields
      var messageType: ProtoMessageDescriptor? = nil
      if fieldType == .message && !fieldProto.typeName.isEmpty {
        let typeName =
          fieldProto.typeName.hasPrefix(".") ? String(fieldProto.typeName.dropFirst()) : fieldProto.typeName
        messageType =
          messageDescriptors[typeName]
          ?? nestedMessages.first { $0.fullName == typeName || typeName.hasSuffix(".\($0.fullName)") }
      }

      // Find the enum type for enum fields
      var enumType: ProtoEnumDescriptor? = nil
      if fieldType == .enum && !fieldProto.typeName.isEmpty {
        let typeName =
          fieldProto.typeName.hasPrefix(".") ? String(fieldProto.typeName.dropFirst()) : fieldProto.typeName
        enumType = enumDescriptors[typeName] ?? enums.first { $0.name == typeName.components(separatedBy: ".").last }
      }

      let field = ProtoFieldDescriptor(
        name: fieldProto.name,
        number: Int(fieldProto.number),
        type: fieldType,
        isRepeated: isRepeated,
        isMap: isMap,
        messageType: messageType,
        enumType: enumType
      )

      fields.append(field)
    }

    return ProtoMessageDescriptor(
      fullName: fullName,
      fields: fields,
      enums: enums,
      nestedMessages: nestedMessages
    )
  }

  /// Creates an enum descriptor from a Protocol Buffer enum descriptor proto.
  ///
  /// - Parameter enumProto: The Protocol Buffer enum descriptor proto.
  /// - Returns: An enum descriptor.
  private func createEnumDescriptor(_ enumProto: Google_Protobuf_EnumDescriptorProto) -> ProtoEnumDescriptor {
    var values: [ProtoEnumValueDescriptor] = []

    for valueProto in enumProto.value {
      let value = ProtoEnumValueDescriptor(
        name: valueProto.name,
        number: Int(valueProto.number)
      )
      values.append(value)
    }

    return ProtoEnumDescriptor(
      name: enumProto.name,
      values: values
    )
  }

  /// Maps a Protocol Buffer field type to a ProtoFieldType.
  ///
  /// - Parameter fieldType: The Protocol Buffer field type.
  /// - Returns: The corresponding ProtoFieldType.
  private func mapFieldType(_ fieldType: Google_Protobuf_FieldDescriptorProto.TypeEnum) -> ProtoFieldType {
    switch fieldType {
    case .double:
      return .double
    case .float:
      return .float
    case .int64:
      return .int64
    case .uint64:
      return .uint64
    case .int32:
      return .int32
    case .fixed64:
      return .fixed64
    case .fixed32:
      return .fixed32
    case .bool:
      return .bool
    case .string:
      return .string
    case .message:
      return .message
    case .bytes:
      return .bytes
    case .uint32:
      return .uint32
    case .enum:
      return .enum
    case .sfixed32:
      return .sfixed32
    case .sfixed64:
      return .sfixed64
    case .sint32:
      return .sint32
    case .sint64:
      return .sint64
    default:
      return .unknown
    }
  }

  /// Determines if a field is a map field.
  ///
  /// - Parameters:
  ///   - fieldProto: The field descriptor proto.
  ///   - messageProto: The message descriptor proto containing the field.
  /// - Returns: `true` if the field is a map field, `false` otherwise.
  private func isMapField(
    _ fieldProto: Google_Protobuf_FieldDescriptorProto,
    _ messageProto: Google_Protobuf_DescriptorProto
  ) -> Bool {
    // Map fields are represented as repeated message fields with a special message type
    guard fieldProto.label == .repeated, fieldProto.type == .message else {
      return false
    }

    // The field type name should reference a nested message
    if fieldProto.typeName.isEmpty {
      return false
    }

    // Extract the message name from the type name
    let components = fieldProto.typeName.split(separator: ".")
    guard let messageName = components.last else {
      return false
    }

    // Find the nested message type
    guard let nestedType = messageProto.nestedType.first(where: { $0.name == String(messageName) }) else {
      return false
    }

    // Check if the nested message has the map_entry option set to true
    return nestedType.options.mapEntry
  }
}

/// Errors that can occur when working with descriptors.
public enum DescriptorError: Error {
  /// Indicates that a descriptor was not found.
  case descriptorNotFound(String)

  /// Indicates that a file descriptor is invalid.
  case invalidFileDescriptor(String)
}
