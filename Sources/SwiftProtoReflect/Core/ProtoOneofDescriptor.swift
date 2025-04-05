import Foundation
import SwiftProtobuf

/// A descriptor for a Protocol Buffer oneof field, containing metadata about the oneof and its fields.
///
/// `ProtoOneofDescriptor` represents a oneof field declaration within a Protocol Buffer message.
/// It provides access to the oneof name and the fields that are part of the oneof.
///
/// Example:
/// ```swift
/// // Creating from a SwiftProtobuf oneof descriptor
/// let oneofDescriptor = ProtoOneofDescriptor(oneofProto: oneofProto, fields: oneofFields)
///
/// // Or creating manually
/// let oneofDescriptor = ProtoOneofDescriptor(
///     name: "contact_info",
///     fields: [emailField, phoneField]
/// )
///
/// // Accessing fields in the oneof
/// let fields = oneofDescriptor.fields
/// let field = oneofDescriptor.field(named: "email")
/// ```
///
/// - Note: When one field in a oneof is set, all other fields in the oneof are automatically cleared.
public class ProtoOneofDescriptor: Hashable {
  /// The name of the oneof field as defined in the Protocol Buffer schema.
  ///
  /// This name corresponds to the oneof name in the `.proto` file. For example, a oneof defined as
  /// `oneof contact_info { ... }` in a `.proto` file would have the name "contact_info".
  public let name: String

  /// The fields that are part of this oneof declaration.
  ///
  /// These are the fields that were declared within the oneof block in the Protocol Buffer schema.
  public private(set) var fields: [ProtoFieldDescriptor]

  /// The original SwiftProtobuf oneof descriptor proto, if this descriptor was created from one.
  private let oneofProto: Google_Protobuf_OneofDescriptorProto?

  /// Creates a new oneof descriptor with the specified properties.
  ///
  /// - Parameters:
  ///   - name: The name of the oneof as defined in the Protocol Buffer schema.
  ///   - fields: The fields that are part of this oneof declaration.
  public init(name: String, fields: [ProtoFieldDescriptor]) {
    self.name = name
    self.fields = fields
    self.oneofProto = nil
  }

  /// Creates a new oneof descriptor from a SwiftProtobuf oneof descriptor proto.
  ///
  /// - Parameters:
  ///   - oneofProto: The SwiftProtobuf oneof descriptor proto.
  ///   - fields: The field descriptors that are part of this oneof.
  public init(oneofProto: Google_Protobuf_OneofDescriptorProto, fields: [ProtoFieldDescriptor]) {
    self.name = oneofProto.name
    self.fields = fields
    self.oneofProto = oneofProto
  }

  /// Retrieves a field descriptor by name.
  ///
  /// - Parameter name: The name of the field to retrieve.
  /// - Returns: The field descriptor, or nil if no field with the given name exists in this oneof.
  public func field(named name: String) -> ProtoFieldDescriptor? {
    return fields.first { $0.name == name }
  }

  /// Retrieves a field descriptor by number.
  ///
  /// - Parameter number: The number of the field to retrieve.
  /// - Returns: The field descriptor, or nil if no field with the given number exists in this oneof.
  public func field(number: Int) -> ProtoFieldDescriptor? {
    return fields.first { $0.number == number }
  }

  /// Returns the original SwiftProtobuf oneof descriptor proto if available.
  ///
  /// - Returns: The original oneof descriptor proto, or nil if this descriptor was not created from one.
  public func originalOneofProto() -> Google_Protobuf_OneofDescriptorProto? {
    return oneofProto
  }

  /// Adds a field to this oneof and sets the field's oneof reference
  /// - Parameter field: The field to add to this oneof
  /// - Returns: This oneof descriptor for method chaining
  @discardableResult
  public func addField(_ field: ProtoFieldDescriptor) -> ProtoOneofDescriptor {
    fields.append(field)
    field.setOneof(self)
    return self
  }

  /// Adds multiple fields to this oneof and sets each field's oneof reference
  /// - Parameter fields: The fields to add to this oneof
  /// - Returns: This oneof descriptor for method chaining
  @discardableResult
  public func addFields(_ fields: [ProtoFieldDescriptor]) -> ProtoOneofDescriptor {
    for field in fields {
      addField(field)
    }
    return self
  }

  /// Creates a new oneof descriptor with fields and automatically sets up the bidirectional relationships
  /// - Parameters:
  ///   - name: The name of the oneof
  ///   - fields: The fields to include in the oneof
  /// - Returns: A new oneof descriptor with proper field relationships
  public static func create(name: String, fields: [ProtoFieldDescriptor]) -> ProtoOneofDescriptor {
    let oneof = ProtoOneofDescriptor(name: name, fields: [])
    oneof.addFields(fields)
    return oneof
  }

  // MARK: - Hashable Conformance

  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(fields.count)
  }

  public static func == (lhs: ProtoOneofDescriptor, rhs: ProtoOneofDescriptor) -> Bool {
    return lhs.name == rhs.name && lhs.fields.count == rhs.fields.count
  }
}
