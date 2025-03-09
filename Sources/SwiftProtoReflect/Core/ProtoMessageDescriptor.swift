/// Describes the structure of a Protocol Buffer message, including its fields, enums, and nested messages.
///
/// This class provides metadata about a Protocol Buffer message type, including its fields,
/// enums, and nested messages. It is used for dynamic message creation and validation.
///
/// Example:
/// ```swift
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

  /// Creates a new message descriptor with the specified properties.
  ///
  /// - Parameters:
  ///   - fullName: The full name of the message, including package and parent message names.
  ///   - fields: The field descriptors for the message's fields.
  ///   - enums: The enum descriptors for any enum types defined in the message.
  ///   - nestedMessages: The message descriptors for any message types defined in the message.
  public init(
    fullName: String,
    fields: [ProtoFieldDescriptor],
    enums: [ProtoEnumDescriptor],
    nestedMessages: [ProtoMessageDescriptor]
  ) {
    self.fullName = fullName
    self.fields = fields
    self.enums = enums
    self.nestedMessages = nestedMessages
  }

  /// Retrieves a field descriptor by name.
  ///
  /// - Parameter name: The name of the field to retrieve.
  /// - Returns: The field descriptor, or nil if no field with the given name exists.
  public func field(named name: String) -> ProtoFieldDescriptor? {
    return fields.first { $0.name == name }
  }

  /// Retrieves a field descriptor by index.
  ///
  /// - Parameter index: The index of the field to retrieve.
  /// - Returns: The field descriptor, or nil if the index is out of bounds.
  public func field(at index: Int) -> ProtoFieldDescriptor? {
    guard index < fields.count else { return nil }
    return fields[index]
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
}
