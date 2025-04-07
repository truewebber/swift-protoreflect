import Foundation
import SwiftProtobuf

/// A descriptor for a Protocol Buffer field, containing metadata about the field's name, type, and other properties.
///
/// `ProtoFieldDescriptor` represents a single field within a Protocol Buffer message. It contains
/// all the metadata needed to correctly serialize, deserialize, and validate field values.
///
/// Example:
/// ```swift
/// // Creating from a SwiftProtobuf field descriptor
/// let fieldDescriptor = ProtoFieldDescriptor(fieldProto: fieldProto, messageProto: messageProto)
///
/// // Or creating manually
/// let fieldDescriptor = ProtoFieldDescriptor(
///     name: "user_id",
///     number: 1,
///     type: .int64,
///     isRepeated: false,
///     isMap: false
/// )
/// ```
///
/// - Note: Field numbers must be positive and unique within a message.
/// - Important: For message-type fields, you must provide a `messageType` descriptor.
public class ProtoFieldDescriptor: Hashable {
  /// The name of the field as defined in the Protocol Buffer schema.
  ///
  /// This name corresponds to the field name in the `.proto` file. For example, a field defined as
  /// `string user_name = 1;` in a `.proto` file would have the name "user_name".
  ///
  /// - Note: Field names must be non-empty and should follow Protocol Buffer naming conventions.
  public let name: String

  /// The field number as defined in the Protocol Buffer schema.
  ///
  /// Field numbers uniquely identify fields within a message when serialized to the binary wire format.
  /// Valid field numbers are positive integers.
  ///
  /// - Note: Field numbers 1-15 use one byte in the wire format, while numbers 16-2047 use two bytes.
  ///   For frequently used fields, prefer numbers 1-15 for efficiency.
  public let number: Int

  /// Field type, represented as ProtoFieldType.
  ///
  /// Defines the data type of the field, such as int32, string, bool, etc.
  /// This determines how the field is serialized and deserialized.
  public let type: ProtoFieldType

  /// Indicates whether the field is repeated (can contain multiple values).
  ///
  /// Repeated fields are equivalent to arrays in Swift and can contain zero or more values.
  /// In Protocol Buffers, repeated fields are defined with the `repeated` keyword.
  public let isRepeated: Bool

  /// Indicates whether the field is a map type.
  ///
  /// Map fields represent key-value pairs and are serialized as a special repeated message.
  /// In Protocol Buffers, map fields are defined with the `map<key_type, value_type>` syntax.
  public let isMap: Bool

  /// Indicates whether the field has explicit presence semantics.
  ///
  /// In proto3, fields normally don't track presence, but fields marked as `optional`
  /// do have explicit presence tracking. This allows distinguishing between an unset field
  /// and a field set to its default value.
  ///
  /// Example in proto3:
  /// ```
  /// optional int32 foo = 1;  // has explicit presence
  /// int32 bar = 2;           // no explicit presence
  /// ```
  public let hasExplicitPresence: Bool

  /// Default value of the field, if any.
  ///
  /// This value is used when the field is not present in the serialized data.
  /// If nil, the default value for the field type is used (0 for numbers, empty string for strings, etc.).
  public let defaultValue: ProtoValue?

  /// Descriptor for message fields (for nested message types).
  ///
  /// For fields of type `.message`, this property must contain the descriptor for the nested message type.
  /// This is required for proper serialization and deserialization of nested messages.
  public let messageType: ProtoMessageDescriptor?

  /// Descriptor for enum fields (for enum types).
  ///
  /// For fields of type `.enum`, this property should contain the descriptor for the enum type.
  /// This is used for proper validation and conversion of enum values.
  public let enumType: ProtoEnumDescriptor?

  /// If this field is part of a oneof, the descriptor for the oneof.
  ///
  /// For regular fields, this property is nil.
  public private(set) var oneofDescriptor: ProtoOneofDescriptor?

  /// Indicates whether this field is part of a oneof declaration.
  public var isOneofField: Bool {
    return oneofDescriptor != nil
  }

  /// The original SwiftProtobuf field descriptor proto, if this descriptor was created from one.
  private let fieldProto: Google_Protobuf_FieldDescriptorProto?

  /// Creates a new field descriptor with the specified properties.
  ///
  /// - Parameters:
  ///   - name: The name of the field as defined in the Protocol Buffer schema.
  ///   - number: The field number as defined in the Protocol Buffer schema.
  ///   - type: The data type of the field.
  ///   - isRepeated: Whether the field can contain multiple values.
  ///   - isMap: Whether the field is a map type.
  ///   - hasExplicitPresence: Whether the field has explicit presence semantics (proto3 optional).
  ///   - defaultValue: The default value for the field, if any.
  ///   - messageType: For message fields, the descriptor of the nested message type.
  ///   - enumType: For enum fields, the descriptor of the enum type.
  ///   - oneofDescriptor: If this field is part of a oneof, the descriptor for the oneof.
  ///
  /// - Note: For fields of type `.message`, the `messageType` parameter is required.
  /// - Note: For fields of type `.enum`, the `enumType` parameter is recommended.
  public init(
    name: String,
    number: Int,
    type: ProtoFieldType,
    isRepeated: Bool,
    isMap: Bool,
    hasExplicitPresence: Bool = false,
    defaultValue: ProtoValue? = nil,
    messageType: ProtoMessageDescriptor? = nil,
    enumType: ProtoEnumDescriptor? = nil,
    oneofDescriptor: ProtoOneofDescriptor? = nil
  ) {
    self.name = name
    self.number = number
    self.type = type
    self.isRepeated = isRepeated
    self.isMap = isMap
    self.hasExplicitPresence = hasExplicitPresence
    self.defaultValue = defaultValue
    self.messageType = messageType
    self.enumType = enumType
    self.oneofDescriptor = oneofDescriptor
    self.fieldProto = nil
  }

  /// Creates a new field descriptor from a SwiftProtobuf field descriptor proto.
  ///
  /// - Parameters:
  ///   - fieldProto: The SwiftProtobuf field descriptor proto.
  ///   - messageProto: The message descriptor proto containing the field, used for map field detection.
  ///   - messageType: For message fields, the descriptor of the nested message type.
  ///   - enumType: For enum fields, the descriptor of the enum type.
  ///   - oneofDescriptor: If this field is part of a oneof, the descriptor for the oneof.
  ///
  /// - Returns: A new field descriptor, or nil if the field proto is invalid.
  public init?(
    fieldProto: Google_Protobuf_FieldDescriptorProto,
    messageProto: Google_Protobuf_DescriptorProto,
    messageType: ProtoMessageDescriptor? = nil,
    enumType: ProtoEnumDescriptor? = nil,
    oneofDescriptor: ProtoOneofDescriptor? = nil
  ) {
    guard !fieldProto.name.isEmpty, fieldProto.number > 0 else {
      return nil
    }

    self.name = fieldProto.name
    self.number = Int(fieldProto.number)

    // Determine if field has explicit presence (proto3 optional)
    // Для proto3 поле считается имеющим explicit presence если:
    // 1. Оно явно помечено как optional (label == .optional)
    // 2. Оно находится в oneof (oneofIndex задан)
    // 3. Это поле сообщения (message)
    self.hasExplicitPresence =
      (fieldProto.label == .optional) || fieldProto.hasOneofIndex || fieldProto.type == .message

    // Map the field type
    switch fieldProto.type {
    case .double:
      self.type = .double
    case .float:
      self.type = .float
    case .int64:
      self.type = .int64
    case .uint64:
      self.type = .uint64
    case .int32:
      self.type = .int32
    case .fixed64:
      self.type = .fixed64
    case .fixed32:
      self.type = .fixed32
    case .bool:
      self.type = .bool
    case .string:
      self.type = .string
    case .message:
      self.type = .message(messageType)
    case .bytes:
      self.type = .bytes
    case .uint32:
      self.type = .uint32
    case .enum:
      self.type = .enum(enumType)
    case .sfixed32:
      self.type = .sfixed32
    case .sfixed64:
      self.type = .sfixed64
    case .sint32:
      self.type = .sint32
    case .sint64:
      self.type = .sint64
    default:
      self.type = .unknown
    }

    self.isRepeated = fieldProto.label == .repeated

    // Determine if this is a map field
    self.isMap = Self.isMapField(fieldProto, messageProto)

    // Extract default value if present
    if fieldProto.hasDefaultValue, !fieldProto.defaultValue.isEmpty {
      self.defaultValue = Self.parseDefaultValue(fieldProto.defaultValue, type: self.type)
    }
    else {
      self.defaultValue = nil
    }

    self.messageType = messageType
    self.enumType = enumType
    self.oneofDescriptor = oneofDescriptor
    self.fieldProto = fieldProto
  }

  /// Parses a default value string from a field descriptor proto.
  ///
  /// - Parameters:
  ///   - defaultValueString: The default value string from the field descriptor proto.
  ///   - type: The field type.
  ///
  /// - Returns: A ProtoValue representing the default value, or nil if parsing fails.
  private static func parseDefaultValue(_ defaultValueString: String, type: ProtoFieldType) -> ProtoValue? {
    switch type {
    case .int32, .sint32, .sfixed32:
      if let value = Int32(defaultValueString) {
        return .intValue(Int(value))
      }
    case .int64, .sint64, .sfixed64:
      if let value = Int64(defaultValueString) {
        return .intValue(Int(value))
      }
    case .uint32, .fixed32:
      if let value = UInt32(defaultValueString) {
        return .uintValue(UInt(value))
      }
    case .uint64, .fixed64:
      if let value = UInt64(defaultValueString) {
        return .uintValue(UInt(value))
      }
    case .float:
      if let value = Float(defaultValueString) {
        return .floatValue(value)
      }
    case .double:
      if let value = Double(defaultValueString) {
        return .doubleValue(value)
      }
    case .bool:
      if defaultValueString == "true" {
        return .boolValue(true)
      }
      else if defaultValueString == "false" {
        return .boolValue(false)
      }
    case .string:
      return .stringValue(defaultValueString)
    case .bytes:
      // Bytes are typically base64 encoded in default values
      if let data = Data(base64Encoded: defaultValueString) {
        return .bytesValue(data)
      }
    case .enum:
      // For enums, we just store the string value
      return .stringValue(defaultValueString)
    default:
      break
    }

    return nil
  }

  /// Determines if a field is a map field.
  ///
  /// - Parameters:
  ///   - fieldProto: The field descriptor proto.
  ///   - messageProto: The message descriptor proto containing the field.
  ///
  /// - Returns: `true` if the field is a map field, `false` otherwise.
  private static func isMapField(
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

  /// Compares two field descriptors for equality.
  ///
  /// Two field descriptors are considered equal if they have the same name, number, and type.
  ///
  /// - Parameters:
  ///   - lhs: The left-hand side field descriptor.
  ///   - rhs: The right-hand side field descriptor.
  /// - Returns: `true` if the field descriptors are equal, `false` otherwise.
  public static func == (lhs: ProtoFieldDescriptor, rhs: ProtoFieldDescriptor) -> Bool {
    return lhs.name == rhs.name && lhs.number == rhs.number && lhs.type == rhs.type
  }

  /// Hashes the essential components of the field descriptor.
  ///
  /// - Parameter hasher: The hasher to use for combining the field's components.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(number)
    hasher.combine(type)
  }

  /// Verifies if the field descriptor is valid according to Protocol Buffer rules.
  ///
  /// A valid field descriptor must have:
  /// - A non-empty name
  /// - A positive field number
  /// - For message fields, a non-nil messageType
  /// - For enum fields, a non-nil enumType
  /// - For map fields, type must be message
  /// - For repeated fields, type cannot be map
  /// - Unknown types are not valid
  /// - Group types are deprecated but still valid
  ///
  /// - Returns: `true` if the field descriptor is valid, `false` otherwise.
  public func isValid() -> Bool {
    if name.isEmpty || number <= 0 {
      return false
    }

    // Unknown types are not valid
    if case .unknown = type {
      return false
    }

    // For message fields, messageType must be provided
    if case .message = type, messageType == nil {
      return false
    }

    // For enum fields, enumType must be provided
    if case .enum = type, enumType == nil {
      return false
    }

    // For map fields, type must be message
    if isMap {
      if case .message = type {
        return true
      }
      return false
    }

    // For repeated fields, type cannot be map
    if isRepeated && isMap {
      return false
    }

    // Group types are deprecated but still valid
    if case .group = type {
      return true
    }

    return true
  }

  /// Returns a validation error message if the field descriptor is invalid, or nil if it's valid.
  ///
  /// This method provides detailed information about why a field descriptor is invalid.
  ///
  /// - Returns: An error message describing the validation failure, or nil if the descriptor is valid.
  public func validationError() -> String? {
    if name.isEmpty {
      return "Field name cannot be empty"
    }

    if number <= 0 {
      return "Field number must be positive (got \(number))"
    }

    if case .message = type, messageType == nil {
      return "Message type field '\(name)' requires a messageType descriptor"
    }

    if case .enum = type, enumType == nil {
      return "Enum type field '\(name)' requires an enumType descriptor"
    }

    return nil
  }

  /// Returns the original SwiftProtobuf field descriptor proto if available.
  ///
  /// - Returns: The original field descriptor proto, or nil if this descriptor was not created from one.
  public func originalFieldProto() -> Google_Protobuf_FieldDescriptorProto? {
    return fieldProto
  }

  /// Links this field with a oneof descriptor.
  ///
  /// This method establishes a bidirectional relationship between the field and the oneof.
  /// - Parameter oneof: The oneof descriptor to link with this field
  /// - Returns: This field descriptor (for method chaining)
  @discardableResult
  public func setOneof(_ oneof: ProtoOneofDescriptor) -> ProtoFieldDescriptor {
    self.oneofDescriptor = oneof
    return self
  }
}
