import Foundation
import SwiftProtobuf

/// Describes the structure of a Protocol Buffer message, including its fields, enums, and nested messages.
///
/// This class provides metadata about a Protocol Buffer message type, including its fields,
/// enums, and nested messages. It is used for dynamic message creation and validation.
///
/// Example:
/// ```swift
/// // Creating from a SwiftProtobuf descriptor
/// let messageDescriptor = ProtoMessageDescriptor(descriptorProto: descriptorProto, packageName: "example")
///
/// // Or creating manually
/// let personDescriptor = ProtoMessageDescriptor(
///     fullName: "Person",
///     fields: [
///         ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
///         ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false)
///     ],
///     enums: [],
///     nestedMessages: []
/// )
/// ```
public class ProtoMessageDescriptor {
  /// Full name of the Protocol Buffer message.
  ///
  /// This typically includes the package name and any parent message names, separated by dots.
  /// For example: "example.Person" or "example.OuterMessage.InnerMessage".
  public let fullName: String

  /// List of field descriptors in the message.
  ///
  /// These describe the fields that make up the message, including their names, types, and numbers.
  public let fields: [ProtoFieldDescriptor]

  /// Enum descriptors used in the message.
  ///
  /// These describe any enum types defined within this message.
  public let enums: [ProtoEnumDescriptor]

  /// Nested message descriptors.
  ///
  /// These describe any message types defined within this message.
  public let nestedMessages: [ProtoMessageDescriptor]

  /// Oneof descriptors for oneofs defined in this message.
  ///
  /// These describe any oneof fields defined within this message.
  public let oneofs: [ProtoOneofDescriptor]

  /// The original SwiftProtobuf descriptor proto, if this descriptor was created from one.
  private let descriptorProto: Google_Protobuf_DescriptorProto?

  /// Creates a new message descriptor with the specified properties.
  ///
  /// - Parameters:
  ///   - fullName: The full name of the message, including package and parent message names.
  ///   - fields: The field descriptors for the message's fields.
  ///   - enums: The enum descriptors for any enum types defined in the message.
  ///   - nestedMessages: The message descriptors for any message types defined in the message.
  ///   - oneofs: The oneof descriptors for any oneof fields defined in the message.
  public init(
    fullName: String,
    fields: [ProtoFieldDescriptor],
    enums: [ProtoEnumDescriptor],
    nestedMessages: [ProtoMessageDescriptor],
    oneofs: [ProtoOneofDescriptor] = []
  ) {
    self.fullName = fullName
    self.fields = fields
    self.enums = enums
    self.nestedMessages = nestedMessages
    self.oneofs = oneofs
    self.descriptorProto = nil
  }

  /// Creates a new message descriptor from a SwiftProtobuf descriptor proto.
  ///
  /// - Parameters:
  ///   - descriptorProto: The SwiftProtobuf descriptor proto.
  ///   - packageName: The package name for the message.
  ///   - parentFullName: The full name of the parent message, if this is a nested message.
  public init(descriptorProto: Google_Protobuf_DescriptorProto, packageName: String, parentFullName: String? = nil) {
    let messageName = descriptorProto.name

    // Determine the full name of the message
    if let parentFullName = parentFullName {
      self.fullName = "\(parentFullName).\(messageName)"
    }
    else if packageName.isEmpty {
      self.fullName = messageName
    }
    else {
      self.fullName = "\(packageName).\(messageName)"
    }

    // Create oneof descriptors first (without fields)
    var oneofDescriptors: [ProtoOneofDescriptor] = []
    var oneofMap: [Int: ProtoOneofDescriptor] = [:]
    for (index, oneofProto) in descriptorProto.oneofDecl.enumerated() {
      let oneofDescriptor = ProtoOneofDescriptor(oneofProto: oneofProto, fields: [])
      oneofDescriptors.append(oneofDescriptor)
      oneofMap[index] = oneofDescriptor
    }

    // Create field descriptors
    var fieldDescriptors: [ProtoFieldDescriptor] = []
    var oneofFields: [Int: [ProtoFieldDescriptor]] = [:]

    for fieldProto in descriptorProto.field {
      // Determine if this field is part of a oneof
      var oneofDescriptor: ProtoOneofDescriptor? = nil
      if fieldProto.hasOneofIndex {
        let oneofIndex = Int(fieldProto.oneofIndex)
        oneofDescriptor = oneofMap[oneofIndex]
      }

      if let fieldDescriptor = ProtoFieldDescriptor(
        fieldProto: fieldProto,
        messageProto: descriptorProto,
        oneofDescriptor: oneofDescriptor
      ) {
        fieldDescriptors.append(fieldDescriptor)

        // If this is a oneof field, add it to the appropriate collection
        if let _ = oneofDescriptor, fieldProto.hasOneofIndex {
          let oneofIndex = Int(fieldProto.oneofIndex)
          if oneofFields[oneofIndex] == nil {
            oneofFields[oneofIndex] = []
          }
          oneofFields[oneofIndex]?.append(fieldDescriptor)
        }
      }
    }

    // Update oneof descriptors with their fields
    for (index, fields) in oneofFields {
      if let oneofDescriptor = oneofMap[index] {
        // Create a new descriptor with the same name but with fields
        let updatedDescriptor = ProtoOneofDescriptor(
          oneofProto: oneofDescriptor.originalOneofProto()!,
          fields: fields
        )

        // Replace the old descriptor with the updated one
        if let descriptorIndex = oneofDescriptors.firstIndex(where: { $0.name == updatedDescriptor.name }) {
          oneofDescriptors[descriptorIndex] = updatedDescriptor

          // Update the reference in the map
          oneofMap[index] = updatedDescriptor
        }
      }
    }

    self.fields = fieldDescriptors
    self.oneofs = oneofDescriptors

    // Create enum descriptors
    var enumDescriptors: [ProtoEnumDescriptor] = []
    for enumProto in descriptorProto.enumType {
      let enumDescriptor = ProtoEnumDescriptor(enumProto: enumProto)
      enumDescriptors.append(enumDescriptor)
    }
    self.enums = enumDescriptors

    // Create nested message descriptors
    var nestedMessageDescriptors: [ProtoMessageDescriptor] = []
    for nestedMessageProto in descriptorProto.nestedType {
      let nestedMessageDescriptor = ProtoMessageDescriptor(
        descriptorProto: nestedMessageProto,
        packageName: packageName,
        parentFullName: self.fullName
      )
      nestedMessageDescriptors.append(nestedMessageDescriptor)
    }
    self.nestedMessages = nestedMessageDescriptors

    self.descriptorProto = descriptorProto
  }

  /// Retrieves a field descriptor by name.
  ///
  /// - Parameter name: The name of the field to retrieve.
  /// - Returns: The field descriptor, or nil if no field with the given name exists.
  public func field(named name: String) -> ProtoFieldDescriptor? {
    return fields.first { $0.name == name }
  }

  /// Retrieves a field descriptor by number.
  ///
  /// - Parameter number: The number of the field to retrieve.
  /// - Returns: The field descriptor, or nil if no field with the given number exists.
  public func field(number: Int) -> ProtoFieldDescriptor? {
    return fields.first { $0.number == number }
  }

  /// Retrieves a field descriptor by index.
  ///
  /// - Parameter index: The index of the field to retrieve.
  /// - Returns: The field descriptor, or nil if the index is out of bounds.
  public func field(at index: Int) -> ProtoFieldDescriptor? {
    guard index < fields.count else { return nil }
    return fields[index]
  }

  /// Retrieves a nested message descriptor by name.
  ///
  /// - Parameter name: The name of the nested message to retrieve.
  /// - Returns: The nested message descriptor, or nil if no nested message with the given name exists.
  public func nestedMessage(named name: String) -> ProtoMessageDescriptor? {
    return nestedMessages.first { $0.fullName.hasSuffix(".\(name)") || $0.fullName == name }
  }

  /// Retrieves an enum descriptor by name.
  ///
  /// - Parameter name: The name of the enum to retrieve.
  /// - Returns: The enum descriptor, or nil if no enum with the given name exists.
  public func enumType(named name: String) -> ProtoEnumDescriptor? {
    return enums.first { $0.name == name }
  }

  /// Retrieves a oneof descriptor by name.
  ///
  /// - Parameter name: The name of the oneof to retrieve.
  /// - Returns: The oneof descriptor, or nil if no oneof with the given name exists.
  public func oneof(named name: String) -> ProtoOneofDescriptor? {
    return oneofs.first { $0.name == name }
  }

  /// Retrieves all oneof fields for easier processing.
  ///
  /// - Returns: A dictionary mapping oneof names to arrays of their field descriptors.
  public func oneofFields() -> [String: [ProtoFieldDescriptor]] {
    var result: [String: [ProtoFieldDescriptor]] = [:]

    for oneof in oneofs {
      result[oneof.name] = oneof.fields
    }

    return result
  }

  /// Verifies if the descriptor is valid according to Protocol Buffer rules.
  ///
  /// A valid message descriptor must have a non-empty full name.
  ///
  /// - Returns: `true` if the descriptor is valid, `false` otherwise.
  public func isValid() -> Bool {
    return !fullName.isEmpty
  }

  /// Returns a validation error message if the descriptor is invalid, or nil if it's valid.
  ///
  /// This method provides detailed information about why a message descriptor is invalid.
  ///
  /// - Returns: An error message describing the validation failure, or nil if the descriptor is valid.
  public func validationError() -> String? {
    if fullName.isEmpty {
      return "Message full name cannot be empty"
    }

    // Check for duplicate field numbers
    var fieldNumbers = Set<Int>()
    for field in fields {
      if fieldNumbers.contains(field.number) {
        return "Duplicate field number \(field.number) in message \(fullName)"
      }
      fieldNumbers.insert(field.number)
    }

    // Check field validity
    for field in fields {
      if let error = field.validationError() {
        return "Invalid field in message \(fullName): \(error)"
      }
    }

    // Check nested message validity
    for nestedMessage in nestedMessages {
      if let error = nestedMessage.validationError() {
        return "Invalid nested message in \(fullName): \(error)"
      }
    }

    return nil
  }

  /// Returns the original SwiftProtobuf descriptor proto if available.
  ///
  /// - Returns: The original descriptor proto, or nil if this descriptor was not created from one.
  public func originalDescriptorProto() -> Google_Protobuf_DescriptorProto? {
    return descriptorProto
  }
}

/// Extension with factory methods for creating message descriptors
extension ProtoMessageDescriptor {
  /// Creates a new message descriptor with oneof fields
  /// - Parameters:
  ///   - fullName: The full name of the message including package and parent message names
  ///   - regularFields: Regular fields not part of any oneof
  ///   - oneofs: Array of tuples with oneof name and its fields
  ///   - enums: Enum descriptors for any enum types defined in the message
  ///   - nestedMessages: Message descriptors for any message types defined in the message
  /// - Returns: A new message descriptor with properly configured oneofs
  public static func createWithOneofs(
    fullName: String,
    regularFields: [ProtoFieldDescriptor],
    oneofs: [(name: String, fields: [ProtoFieldDescriptor])],
    enums: [ProtoEnumDescriptor] = [],
    nestedMessages: [ProtoMessageDescriptor] = []
  ) -> ProtoMessageDescriptor {
    // Create oneof descriptors and establish relationships
    var oneofDescriptors: [ProtoOneofDescriptor] = []
    var allFields = regularFields

    for (name, fields) in oneofs {
      let oneof = ProtoOneofDescriptor.create(name: name, fields: fields)
      oneofDescriptors.append(oneof)
      allFields.append(contentsOf: fields)
    }

    return ProtoMessageDescriptor(
      fullName: fullName,
      fields: allFields,
      enums: enums,
      nestedMessages: nestedMessages,
      oneofs: oneofDescriptors
    )
  }
}
