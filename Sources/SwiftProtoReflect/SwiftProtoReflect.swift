import Foundation

/// ProtoReflect serves as the main entry point for the SwiftProtoReflect library.
///
/// It provides utility functions to work with Protocol Buffer messages, descriptors, and dynamic message creation.
///
/// # Examples
///
/// ## Registering and Retrieving Descriptors
/// ```swift
/// // Create a message descriptor
/// let addressDescriptor = ProtoMessageDescriptor(
///     fullName: "example.Address",
///     fields: [
///         ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
///         ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
///         ProtoFieldDescriptor(name: "zipCode", number: 3, type: .string, isRepeated: false, isMap: false)
///     ],
///     enums: [],
///     nestedMessages: []
/// )
///
/// // Register the descriptor
/// ProtoReflect.registerDescriptor(addressDescriptor)
///
/// // Retrieve the descriptor later
/// if let descriptor = ProtoReflect.getDescriptor(forTypeName: "example.Address") {
///     print("Found descriptor: \(descriptor.fullName)")
/// }
/// ```
///
/// ## Creating Dynamic Messages
/// ```swift
/// // Create a message using a descriptor
/// let personDescriptor = ProtoMessageDescriptor(
///     fullName: "example.Person",
///     fields: [
///         ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
///         ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false),
///         ProtoFieldDescriptor(name: "address", number: 3, type: .message, isRepeated: false, isMap: false, messageType: addressDescriptor)
///     ],
///     enums: [],
///     nestedMessages: []
/// )
///
/// // Create a message builder
/// let personBuilder = ProtoReflect.createMessage(from: personDescriptor)
///
/// // Set field values using the builder pattern
/// personBuilder.set("name", to: "John Doe")
///     .set("age", to: 30)
///     .set("address.street", to: "123 Main St")
///     .set("address.city", to: "Anytown")
///     .set("address.zipCode", to: "12345")
///
/// // Create a message by type name (if registered)
/// if let companyBuilder = ProtoReflect.createMessage(fromTypeName: "example.Company") {
///     companyBuilder.set("name", to: "Acme Corp")
///         .set("foundedYear", to: 1985)
/// }
/// ```
///
/// ## Serialization and Deserialization
/// ```swift
/// // Build the final message
/// let person = personBuilder.build()
///
/// // Serialize to wire format
/// if let data = ProtoReflect.marshal(message: person) {
///     print("Serialized message size: \(data.count) bytes")
///
///     // Deserialize from wire format
///     if let deserializedPerson = ProtoReflect.unmarshal(data: data, descriptor: personDescriptor) {
///         // Access fields from the deserialized message
///         if let name = (deserializedPerson as? ProtoDynamicMessage)?.get(fieldName: "name")?.getString() {
///             print("Deserialized name: \(name)")
///         }
///     }
/// }
/// ```
///
/// ## Message Inspection and Validation
/// ```swift
/// // Describe a message (useful for debugging)
/// let description = ProtoReflect.describe(message: person)
/// print(description)
///
/// // Validate a message
/// if ProtoReflect.validateMessage(person) {
///     print("Message is valid")
/// } else {
///     print("Message is invalid")
/// }
///
/// // Validate a field descriptor
/// let nameField = personDescriptor.field(named: "name")!
/// if ProtoReflect.validateField(nameField) {
///     print("Field descriptor is valid")
/// } else {
///     print("Field descriptor is invalid")
/// }
/// ```
public class ProtoReflect {
  /// A registry for storing and retrieving message descriptors.
  private static var descriptorRegistry = DescriptorRegistry.shared

  /// Private dictionary to store descriptors by their full names.
  private static var descriptorsByName: [String: ProtoMessageDescriptor] = [:]

  /// Registers a message descriptor with the library.
  ///
  /// - Parameter descriptor: The message descriptor to register.
  public static func registerDescriptor(_ descriptor: ProtoMessageDescriptor) {
    // Store the descriptor in our local dictionary
    descriptorsByName[descriptor.fullName] = descriptor

    // Register nested message descriptors
    for nestedDescriptor in descriptor.nestedMessages {
      registerDescriptor(nestedDescriptor)
    }
  }

  /// Retrieves a message descriptor by its full name.
  ///
  /// - Parameter typeName: The full name of the message type.
  /// - Returns: The message descriptor, or nil if not found.
  public static func getDescriptor(forTypeName typeName: String) -> ProtoMessageDescriptor? {
    // First try to get from our local dictionary
    if let descriptor = descriptorsByName[typeName] {
      return descriptor
    }

    // If not found, try the shared registry
    do {
      return try descriptorRegistry.messageDescriptor(forTypeName: typeName)
    }
    catch {
      return nil
    }
  }

  /// Creates a new dynamic message with the specified descriptor.
  ///
  /// - Parameter descriptor: The descriptor defining the structure of the message.
  /// - Returns: A new message builder for fluent configuration.
  public static func createMessage(from descriptor: ProtoMessageDescriptor) -> MessageBuilder {
    let message = ProtoDynamicMessage(descriptor: descriptor)
    return MessageBuilder(message: message)
  }

  /// Creates a new dynamic message with the specified descriptor full name.
  ///
  /// - Parameter typeName: The full name of the message type.
  /// - Returns: A new message builder, or nil if the descriptor is not found.
  public static func createMessage(fromTypeName typeName: String) -> MessageBuilder? {
    guard let descriptor = getDescriptor(forTypeName: typeName) else {
      return nil
    }

    return createMessage(from: descriptor)
  }

  /// Serializes a ProtoMessage into Protocol Buffer wire format.
  ///
  /// - Parameters:
  ///   - message: The message to serialize.
  ///   - options: Options for controlling the serialization process.
  /// - Returns: The serialized data.
  /// - Throws: Error if serialization fails.
  public static func marshal(message: ProtoMessage, options: SerializationOptions = SerializationOptions()) throws -> Data {
    return try ProtoWireFormat.marshal(message: message, options: options)
  }

  /// Deserializes Protocol Buffer wire format data into a dynamic ProtoMessage.
  ///
  /// - Parameters:
  ///   - data: The data to deserialize.
  ///   - descriptor: The descriptor defining the message structure.
  ///   - options: Options for controlling the deserialization process.
  /// - Returns: The deserialized message, or nil if deserialization fails.
  public static func unmarshal(data: Data, descriptor: ProtoMessageDescriptor, options: SerializationOptions = SerializationOptions()) -> ProtoMessage? {
    return ProtoWireFormat.unmarshal(data: data, messageDescriptor: descriptor, options: options)
  }

  /// Prints a description of the ProtoMessage, including its fields and types.
  ///
  /// - Parameter message: The message to describe.
  /// - Returns: A string description of the message.
  public static func describe(message: ProtoMessage) -> String {
    return ProtoReflectionUtils.describeMessage(message)
  }

  /// Validates a ProtoMessage to ensure it is properly initialized.
  ///
  /// - Parameter message: The message to validate.
  /// - Returns: `true` if the message is valid, `false` otherwise.
  public static func validateMessage(_ message: ProtoMessage) -> Bool {
    return ProtoReflectionUtils.validateMessageDescriptor(message.descriptor())
  }

  /// Validates a ProtoFieldDescriptor to ensure it is properly initialized.
  ///
  /// - Parameter field: The field descriptor to validate.
  /// - Returns: `true` if the field descriptor is valid, `false` otherwise.
  public static func validateField(_ field: ProtoFieldDescriptor) -> Bool {
    return ProtoReflectionUtils.validateFieldDescriptor(field)
  }
}
