//
// Descriptor.swift
// SwiftProtoReflect
//
// Public surface for all Protocol Buffers descriptor types.
// Internal implementations live in Descriptor/_Xxx.swift.
//

import Foundation

// MARK: - DescriptorOption

/// A single typed option value for any descriptor options dictionary.
///
/// Replaces `Any` in `[String: Any]` options, enabling `Sendable` conformance
/// across all descriptor types without unsafe workarounds.
public enum DescriptorOption: Equatable, Sendable {
  /// A boolean option value.
  case bool(Bool)
  /// An integer option value.
  case int(Int)
  /// A string option value.
  case string(String)
  /// A single-precision float option value.
  case float(Float)
  /// A double-precision float option value.
  case double(Double)
  /// A raw bytes option value.
  case bytes(Data)

  /// Returns the underlying value as `Any`, for interoperability with APIs that require `Any`.
  public var asAny: Any {
    switch self {
    case .bool(let v): return v
    case .int(let v): return v
    case .string(let v): return v
    case .float(let v): return v
    case .double(let v): return v
    case .bytes(let v): return v
    }
  }
}

// MARK: - DescriptorParent

/// A type that can serve as a parent context for a Protocol Buffers descriptor node.
///
/// Conforming types: `FileDescriptor`, `MessageDescriptor`.
/// Services always live at file level and therefore do not participate.
///
/// Implementing this protocol lets `MessageDescriptor` and `EnumDescriptor`
/// compute their `fullName`, `syntax`, and `fileDescriptorPath` from the parent
/// without relying on runtime `as?` casts against `Any`.
public protocol DescriptorParent: Sendable {

  /// Prefix used to build the child descriptor's `fullName`.
  ///
  /// - For `FileDescriptor`: equals `package` (may be empty).
  /// - For `MessageDescriptor`: equals `fullName`.
  var descriptorFullNamePrefix: String { get }

  /// Path of the file that owns this descriptor node.
  ///
  /// Propagated to child `fileDescriptorPath`.
  var descriptorFilePath: String? { get }

  /// Proto syntax version (`"proto3"` or `"proto2"`) of the owning file.
  ///
  /// Inherited by child descriptors.
  var descriptorSyntax: String { get }

  /// If this parent is a message descriptor, returns its `fullName`; otherwise `nil`.
  ///
  /// Used to populate `parentMessageFullName` on child `MessageDescriptor` and
  /// `EnumDescriptor` instances.
  var descriptorParentMessageFullName: String? { get }
}

// MARK: - FieldType

/// Protocol Buffers field type.
public enum FieldType: Equatable, Sendable {
  /// Double-precision floating-point (wire type: fixed64).
  case double
  /// Single-precision floating-point (wire type: fixed32).
  case float
  /// Signed 32-bit integer (wire type: varint).
  case int32
  /// Signed 64-bit integer (wire type: varint).
  case int64
  /// Unsigned 32-bit integer (wire type: varint).
  case uint32
  /// Unsigned 64-bit integer (wire type: varint).
  case uint64
  /// Signed 32-bit integer with ZigZag encoding (wire type: varint).
  case sint32
  /// Signed 64-bit integer with ZigZag encoding (wire type: varint).
  case sint64
  /// 32-bit integer stored as exactly 4 bytes (wire type: fixed32).
  case fixed32
  /// 64-bit integer stored as exactly 8 bytes (wire type: fixed64).
  case fixed64
  /// Signed 32-bit integer stored as exactly 4 bytes (wire type: fixed32).
  case sfixed32
  /// Signed 64-bit integer stored as exactly 8 bytes (wire type: fixed64).
  case sfixed64
  /// Boolean (wire type: varint).
  case bool
  /// UTF-8 string (wire type: length-delimited).
  case string
  /// Arbitrary raw bytes (wire type: length-delimited).
  case bytes
  /// Embedded message (wire type: length-delimited).
  case message
  /// Enumerated type (wire type: varint).
  case `enum`
  /// Group — deprecated proto2 wire format (wire type: start/end group).
  case group
}

// MARK: - MapEntryInfo

/// Class describing metadata for map<key, value> type fields.
///
/// Uses reference-type to avoid circular references.
public final class MapEntryInfo: Equatable, Sendable {
  /// Key field information.
  public let keyFieldInfo: KeyFieldInfo

  /// Value field information.
  public let valueFieldInfo: ValueFieldInfo

  /// Creates a new MapEntryInfo instance.
  ///
  /// - Parameters:
  ///   - keyFieldInfo: Key field information.
  ///   - valueFieldInfo: Value field information.
  public init(keyFieldInfo: KeyFieldInfo, valueFieldInfo: ValueFieldInfo) {
    let validKeyTypes: [FieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .string,
    ]

    guard validKeyTypes.contains(keyFieldInfo.type) else {
      fatalError("Invalid key type for map: \(keyFieldInfo.type)")
    }

    self.keyFieldInfo = keyFieldInfo
    self.valueFieldInfo = valueFieldInfo
  }

  /// Returns `true` if both instances have equal key and value field info.
  public static func == (lhs: MapEntryInfo, rhs: MapEntryInfo) -> Bool {
    return lhs.keyFieldInfo == rhs.keyFieldInfo && lhs.valueFieldInfo == rhs.valueFieldInfo
  }
}

// MARK: - KeyFieldInfo

/// Key field information in a map.
public struct KeyFieldInfo: Equatable, Sendable {
  /// Field name (e.g., "key").
  public let name: String
  /// Field number in the generated map-entry message.
  public let number: Int
  /// Key field type (must be a scalar integral or string type).
  public let type: FieldType

  /// Creates a new `KeyFieldInfo`.
  ///
  /// - Parameters:
  ///   - name: Field name.
  ///   - number: Field number.
  ///   - type: Key type; must be a valid map-key type.
  public init(name: String, number: Int, type: FieldType) {
    self.name = name
    self.number = number
    self.type = type
  }
}

// MARK: - ValueFieldInfo

/// Value field information in a map.
public struct ValueFieldInfo: Equatable, Sendable {
  /// Field name (e.g., "value").
  public let name: String
  /// Field number in the generated map-entry message.
  public let number: Int
  /// Value field type.
  public let type: FieldType
  /// Fully-qualified type name for `.message` and `.enum` value types; `nil` for scalars.
  public let typeName: String?

  /// Creates a new `ValueFieldInfo`.
  ///
  /// - Parameters:
  ///   - name: Field name.
  ///   - number: Field number.
  ///   - type: Value field type.
  ///   - typeName: Fully-qualified type name for message/enum types.
  public init(name: String, number: Int, type: FieldType, typeName: String? = nil) {
    self.name = name
    self.number = number
    self.type = type
    self.typeName = typeName

    if case .message = type, typeName == nil {
      fatalError("typeName must be specified for 'message' type fields")
    }
    if case .enum = type, typeName == nil {
      fatalError("typeName must be specified for 'enum' type fields")
    }
  }
}

// MARK: - FieldDescriptor

/// FieldDescriptor.
///
/// Protocol Buffers field descriptor describing properties of a message field,
/// including its type, name, number, options and other metadata.
public struct FieldDescriptor: Equatable, Sendable {
  // MARK: - Properties

  /// Field name (e.g., "first_name").
  public let name: String

  /// JSON field name (if different from name).
  public let jsonName: String

  /// Field number in the message.
  public let number: Int

  /// Field type (int32, string, message, etc.)
  public let type: FieldType

  /// Full name of message or enum type (for message and enum types).
  public let typeName: String?

  /// Indicates if the field is an array (repeated).
  public let isRepeated: Bool

  /// Indicates if the field is optional.
  public let isOptional: Bool

  /// Indicates if the field is required - deprecated for proto3.
  public let isRequired: Bool

  /// Indicates if the field is a map (map<key, value>).
  public let isMap: Bool

  /// Indicates if the field is part of a oneof group.
  public let oneofIndex: Int?

  /// Whether this is a proto3 `optional` field with explicit presence.
  public let proto3Optional: Bool

  /// Contains metadata for map type fields.
  public let mapEntryInfo: MapEntryInfo?

  /// Default value for the field (if defined).
  public let defaultValue: DescriptorOption?

  /// Whether this repeated field uses packed encoding.
  ///
  /// - `nil`: not explicitly set — use syntax default (proto3 → packed, proto2 → unpacked).
  /// - `true`: explicitly `[packed = true]`.
  /// - `false`: explicitly `[packed = false]`.
  public let isPacked: Bool?

  /// Field options.
  public let options: [String: DescriptorOption]

  // MARK: - Initialization

  /// Creates a new FieldDescriptor instance.
  ///
  /// - Parameters:
  ///   - name: Field name.
  ///   - number: Field number.
  ///   - type: Field type.
  ///   - typeName: Full type name (for message and enum).
  ///   - jsonName: JSON field name (defaults to name).
  ///   - isRepeated: Whether the field is an array.
  ///   - isOptional: Whether the field is optional.
  ///   - isRequired: Whether the field is required.
  ///   - isMap: Whether the field is a map.
  ///   - oneofIndex: Oneof group index if the field is part of a oneof.
  ///   - proto3Optional: Whether this field uses proto3 `optional` keyword.
  ///   - mapEntryInfo: Metadata for map fields.
  ///   - defaultValue: Default value expressed as a `DescriptorOption`.
  ///   - options: Field options.
  public init(
    name: String,
    number: Int,
    type: FieldType,
    typeName: String? = nil,
    jsonName: String? = nil,
    isRepeated: Bool = false,
    isOptional: Bool = false,
    isRequired: Bool = false,
    isMap: Bool = false,
    oneofIndex: Int? = nil,
    proto3Optional: Bool = false,
    mapEntryInfo: MapEntryInfo? = nil,
    defaultValue: DescriptorOption? = nil,
    isPacked: Bool? = nil,
    options: [String: DescriptorOption] = [:]
  ) {
    self.name = name
    self.number = number
    self.type = type
    self.typeName = typeName
    self.jsonName = jsonName ?? name
    self.isRepeated = isMap ? true : isRepeated
    self.isOptional = isOptional
    self.isRequired = isRequired
    self.isMap = isMap
    self.oneofIndex = oneofIndex
    self.proto3Optional = proto3Optional
    self.mapEntryInfo = mapEntryInfo
    self.defaultValue = defaultValue
    self.isPacked = isPacked
    self.options = options

    if case .message = type, typeName == nil {
      fatalError("typeName must be specified for 'message' type fields")
    }
    if case .enum = type, typeName == nil {
      fatalError("typeName must be specified for 'enum' type fields")
    }

    if isMap && mapEntryInfo == nil {
      fatalError("mapEntryInfo must be specified for 'map' type fields")
    }
  }

  // MARK: - Methods

  /// Returns the full type name for messages and enums.
  ///
  /// - Returns: Full type name or nil for scalar types.
  public func getFullTypeName() -> String? {
    return typeName
  }

  /// Checks if the field is a scalar type.
  ///
  /// - Returns: true if the field has a scalar type.
  public func isScalarType() -> Bool {
    switch type {
    case .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes:
      return true
    case .message, .enum, .group:
      return false
    }
  }

  /// Checks if the field is a numeric type.
  ///
  /// - Returns: true if the field has a numeric type.
  public func isNumericType() -> Bool {
    switch type {
    case .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64:
      return true
    case .bool, .string, .bytes, .message, .enum, .group:
      return false
    }
  }

  /// Gets key and value information for map fields.
  ///
  /// - Returns: Map field information or nil if the field is not a map.
  public func getMapKeyValueInfo() -> MapEntryInfo? {
    guard isMap else {
      return nil
    }

    return mapEntryInfo
  }

  /// Returns the effective packed encoding setting, resolving `nil` via syntax default.
  ///
  /// In proto3, repeated numeric fields are packed by default.
  /// In proto2, they are unpacked unless explicitly marked `[packed = true]`.
  ///
  /// - Parameter syntax: The proto syntax version (`"proto2"` or `"proto3"`).
  /// - Returns: `true` if packed encoding should be used.
  public func effectiveIsPacked(syntax: String) -> Bool {
    isPacked ?? (syntax == "proto3")
  }

  // MARK: - Equatable

  /// Returns `true` if all properties of both descriptors are equal.
  public static func == (lhs: FieldDescriptor, rhs: FieldDescriptor) -> Bool {
    return lhs.name == rhs.name && lhs.jsonName == rhs.jsonName && lhs.number == rhs.number && lhs.type == rhs.type
      && lhs.typeName == rhs.typeName && lhs.isRepeated == rhs.isRepeated && lhs.isOptional == rhs.isOptional
      && lhs.isRequired == rhs.isRequired && lhs.isMap == rhs.isMap && lhs.oneofIndex == rhs.oneofIndex
      && lhs.proto3Optional == rhs.proto3Optional && lhs.mapEntryInfo == rhs.mapEntryInfo
      && lhs.defaultValue == rhs.defaultValue && lhs.isPacked == rhs.isPacked && lhs.options == rhs.options
  }
}

// MARK: - OneofDescriptor

/// Descriptor for a oneof group in a Protocol Buffers message.
///
/// A oneof group means that at most one field within the group can be set at a time.
/// `OneofDescriptor` gives consumers the name and position of the group
/// within the parent message, matching `FieldDescriptor.oneofIndex`.
public struct OneofDescriptor: Equatable, Sendable {

  /// Group name as defined in the .proto file (e.g. "contact").
  public let name: String

  /// Zero-based index within the parent message.
  ///
  /// Matches `FieldDescriptor.oneofIndex` for all fields that belong to this group.
  public let index: Int

  /// Oneof options (mirrors `Google_Protobuf_OneofOptions`).
  public let options: [String: DescriptorOption]

  /// Creates a new `OneofDescriptor`.
  ///
  /// - Parameters:
  ///   - name: Group name as defined in the .proto file.
  ///   - index: Zero-based index within the parent message.
  ///   - options: Oneof options; defaults to empty.
  public init(name: String, index: Int, options: [String: DescriptorOption] = [:]) {
    self.name = name
    self.index = index
    self.options = options
  }

  /// Two descriptors are equal when they share the same `name` and `index`.
  ///
  /// `options` is excluded from equality, consistent with `FieldDescriptor`.
  public static func == (lhs: OneofDescriptor, rhs: OneofDescriptor) -> Bool {
    lhs.name == rhs.name && lhs.index == rhs.index
  }
}

// MARK: - ExtensionRange

/// Declared extension range for a proto2 message.
///
/// Represents a half-open range `[start, end)` of field numbers
/// reserved for extensions.
public struct ExtensionRange: Equatable, Hashable, Sendable {
  /// Start of the range (inclusive).
  public let start: Int

  /// End of the range (exclusive).
  public let end: Int

  /// Creates a new extension range.
  ///
  /// - Parameters:
  ///   - start: Start of range (inclusive).
  ///   - end: End of range (exclusive).
  public init(start: Int, end: Int) {
    self.start = start
    self.end = end
  }
}

// MARK: - MessageDescriptor

/// MessageDescriptor.
///
/// Protocol Buffers message descriptor that describes
/// the structure of a message, its fields, nested types and options.
public struct MessageDescriptor: Sendable {
  // MARK: - Properties

  /// Message name (e.g., "Person").
  public let name: String

  /// Full message name including package (e.g., "example.person.Person").
  public let fullName: String

  /// Proto syntax version inherited from the parent `FileDescriptor`.
  ///
  /// Defaults to `"proto3"` for backward compatibility.
  /// Empty string is normalised to `"proto2"` per protobuf spec.
  /// When the descriptor is added to a `FileDescriptor` or a parent
  /// `MessageDescriptor`, the syntax is overwritten with the parent's value.
  public var syntax: String

  /// Path to parent file (for reference resolution).
  public var fileDescriptorPath: String?

  /// Full name of parent message (if this is a nested message).
  public var parentMessageFullName: String?

  /// List of message fields.
  public private(set) var fields: [Int: FieldDescriptor] = [:]

  /// List of message fields by name.
  public private(set) var fieldsByName: [String: FieldDescriptor] = [:]

  /// List of nested messages.
  public private(set) var nestedMessages: [String: MessageDescriptor] = [:]

  /// List of nested enums.
  public private(set) var nestedEnums: [String: EnumDescriptor] = [:]

  /// Oneof group declarations for this message, ordered by insertion.
  public private(set) var oneofDecls: [OneofDescriptor] = []

  /// Extension ranges declared by this message (proto2 feature).
  public private(set) var extensionRanges: [ExtensionRange] = []

  /// Extension field descriptors registered for this message, keyed by field number.
  public private(set) var extensions: [Int: FieldDescriptor] = [:]

  /// Message options.
  public let options: [String: DescriptorOption]

  // MARK: - Initialization

  /// Creates a new MessageDescriptor instance.
  ///
  /// - Parameters:
  ///   - name: Message name.
  ///   - fullName: Full message name.
  ///   - syntax: Proto syntax version. Defaults to `"proto3"`.
  ///             Empty string is normalised to `"proto2"` per protobuf spec.
  ///   - options: Message options.
  public init(
    name: String,
    fullName: String,
    syntax: String = "proto3",
    options: [String: DescriptorOption] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.syntax = syntax.isEmpty ? "proto2" : syntax
    self.options = options
  }

  /// Creates a new `MessageDescriptor` with its `fullName` derived from the parent.
  ///
  /// - Parameters:
  ///   - name: Simple message name (e.g., `"Person"`).
  ///   - parent: Parent descriptor context. Pass a `FileDescriptor` for top-level
  ///     messages or a `MessageDescriptor` for nested messages. Pass `nil` to use
  ///     `name` as both the simple name and `fullName`.
  ///   - options: Message options.
  public init(
    name: String,
    parent: (any DescriptorParent)? = nil,
    options: [String: DescriptorOption] = [:]
  ) {
    self.name = name
    self.options = options

    if let parent {
      let prefix = parent.descriptorFullNamePrefix
      self.fullName = prefix.isEmpty ? name : "\(prefix).\(name)"
      self.parentMessageFullName = parent.descriptorParentMessageFullName
      self.fileDescriptorPath = parent.descriptorFilePath
      self.syntax = parent.descriptorSyntax
    }
    else {
      self.fullName = name
      self.syntax = "proto3"
    }
  }

  // MARK: - Field Methods

  /// Adds a field to the message.
  ///
  /// - Parameter field: Field descriptor to add.
  /// - Returns: Updated MessageDescriptor.
  @discardableResult
  public mutating func addField(_ field: FieldDescriptor) -> Self {
    fields[field.number] = field
    fieldsByName[field.name] = field
    return self
  }

  /// Checks if the message contains the specified field.
  ///
  /// - Parameter number: Field number.
  /// - Returns: true if the field exists.
  public func hasField(number: Int) -> Bool {
    return fields[number] != nil
  }

  /// Checks if the message contains the specified field.
  ///
  /// - Parameter name: Field name.
  /// - Returns: true if the field exists.
  public func hasField(named name: String) -> Bool {
    return fieldsByName[name] != nil
  }

  /// Gets a field by number.
  ///
  /// - Parameter number: Field number.
  /// - Returns: Field descriptor if it exists.
  public func field(number: Int) -> FieldDescriptor? {
    return fields[number]
  }

  /// Gets a field by name.
  ///
  /// - Parameter name: Field name.
  /// - Returns: Field descriptor if it exists.
  public func field(named name: String) -> FieldDescriptor? {
    return fieldsByName[name]
  }

  /// Gets a list of all fields ordered by number.
  ///
  /// - Returns: Ordered list of fields.
  public func allFields() -> [FieldDescriptor] {
    return fields.sorted { $0.key < $1.key }.map { $0.value }
  }

  // MARK: - Oneof Decl Methods

  /// Adds a oneof group declaration to the message.
  ///
  /// - Parameter oneof: Oneof descriptor to add.
  /// - Returns: Updated MessageDescriptor.
  @discardableResult
  public mutating func addOneofDecl(_ oneof: OneofDescriptor) -> Self {
    oneofDecls.append(oneof)
    return self
  }

  /// Returns the oneof group descriptor at the given index.
  ///
  /// - Parameter index: Zero-based oneof index (matches `FieldDescriptor.oneofIndex`).
  /// - Returns: `OneofDescriptor` if a group with this index exists, otherwise `nil`.
  public func oneof(at index: Int) -> OneofDescriptor? {
    oneofDecls.first { $0.index == index }
  }

  // MARK: - Nested Type Methods

  /// Adds a nested message.
  ///
  /// The nested message inherits this message's `syntax` and `fileDescriptorPath`.
  ///
  /// - Parameter message: Nested message descriptor.
  /// - Returns: Updated MessageDescriptor.
  @discardableResult
  public mutating func addNestedMessage(_ message: MessageDescriptor) -> Self {
    var messageCopy = message
    messageCopy.parentMessageFullName = self.fullName
    messageCopy.fileDescriptorPath = self.fileDescriptorPath
    messageCopy.syntax = self.syntax
    nestedMessages[message.name] = messageCopy
    return self
  }

  /// Adds a nested enum.
  ///
  /// - Parameter enumDescriptor: Nested enum descriptor.
  /// - Returns: Updated MessageDescriptor.
  @discardableResult
  public mutating func addNestedEnum(_ enumDescriptor: EnumDescriptor) -> Self {
    nestedEnums[enumDescriptor.name] = enumDescriptor
    return self
  }

  /// Checks if the message contains the specified nested message.
  ///
  /// - Parameter name: Nested message name.
  /// - Returns: true if the nested message exists.
  public func hasNestedMessage(named name: String) -> Bool {
    return nestedMessages[name] != nil
  }

  /// Checks if the message contains the specified nested enum.
  ///
  /// - Parameter name: Nested enum name.
  /// - Returns: true if the nested enum exists.
  public func hasNestedEnum(named name: String) -> Bool {
    return nestedEnums[name] != nil
  }

  /// Gets a nested message by name.
  ///
  /// - Parameter name: Nested message name.
  /// - Returns: Nested message descriptor if it exists.
  public func nestedMessage(named name: String) -> MessageDescriptor? {
    return nestedMessages[name]
  }

  /// Gets a nested enum by name.
  ///
  /// - Parameter name: Nested enum name.
  /// - Returns: Nested enum descriptor if it exists.
  public func nestedEnum(named name: String) -> EnumDescriptor? {
    return nestedEnums[name]
  }

  // MARK: - Extension Range Methods

  /// Adds an extension range to the message (proto2 feature).
  ///
  /// - Parameter range: Extension range to add.
  /// - Returns: Updated MessageDescriptor.
  @discardableResult
  public mutating func addExtensionRange(_ range: ExtensionRange) -> Self {
    extensionRanges.append(range)
    return self
  }

  /// Registers an extension field descriptor for this message.
  ///
  /// - Parameter field: Extension field descriptor to register.
  /// - Returns: Updated MessageDescriptor.
  @discardableResult
  public mutating func addExtension(_ field: FieldDescriptor) -> Self {
    extensions[field.number] = field
    return self
  }

  /// Checks whether the given field number falls within any declared extension range.
  ///
  /// - Parameter number: Field number to check.
  /// - Returns: `true` if the number is inside an extension range.
  public func isExtensionNumber(_ number: Int) -> Bool {
    extensionRanges.contains { number >= $0.start && number < $0.end }
  }
}

// MARK: - MessageDescriptor: DescriptorParent

extension MessageDescriptor: DescriptorParent {

  /// The message's fully-qualified name — used as prefix for nested child names.
  public var descriptorFullNamePrefix: String { fullName }

  /// File path this message belongs to.
  public var descriptorFilePath: String? { fileDescriptorPath }

  /// Syntax version inherited from the owning file.
  public var descriptorSyntax: String { syntax }

  /// This is a message; returns its own `fullName` so children can populate
  /// their `parentMessageFullName`.
  public var descriptorParentMessageFullName: String? { fullName }
}

// MARK: - EnumDescriptor

/// EnumDescriptor.
///
/// Protocol Buffers enum descriptor that describes
/// enum values, their names, numeric values and options.
public struct EnumDescriptor: Equatable, Sendable {
  // MARK: - Types

  /// Enum value with its name and options.
  public struct EnumValue: Equatable, Sendable {
    /// Enum value name (e.g., "UNKNOWN").
    public let name: String

    /// Numeric value of the enum element.
    public let number: Int

    /// Enum value options.
    public let options: [String: DescriptorOption]

    /// Creates a new enum value.
    ///
    /// - Parameters:
    ///   - name: Enum value name.
    ///   - number: Numeric value.
    ///   - options: Enum value options.
    public init(name: String, number: Int, options: [String: DescriptorOption] = [:]) {
      self.name = name
      self.number = number
      self.options = options
    }

    // MARK: - Equatable

    /// Returns `true` if both enum values share the same name, number, and options.
    public static func == (lhs: EnumValue, rhs: EnumValue) -> Bool {
      return lhs.name == rhs.name && lhs.number == rhs.number && lhs.options == rhs.options
    }
  }

  // MARK: - Properties

  /// Enum name (e.g., "Status").
  public let name: String

  /// Full enum name including package (e.g., "example.Status").
  public let fullName: String

  /// Path to parent file (for reference resolution).
  public var fileDescriptorPath: String?

  /// Full name of parent message (if this is a nested enum).
  public var parentMessageFullName: String?

  /// List of enum values by name.
  public private(set) var valuesByName: [String: EnumValue] = [:]

  /// List of enum values by numeric value.
  public private(set) var valuesByNumber: [Int: EnumValue] = [:]

  /// Enum options.
  public let options: [String: DescriptorOption]

  // MARK: - Initialization

  /// Creates a new EnumDescriptor instance.
  ///
  /// - Parameters:
  ///   - name: Enum name.
  ///   - fullName: Full enum name.
  ///   - options: Enum options.
  public init(
    name: String,
    fullName: String,
    options: [String: DescriptorOption] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.options = options
  }

  /// Creates a new `EnumDescriptor` with its `fullName` derived from the parent.
  ///
  /// - Parameters:
  ///   - name: Simple enum name.
  ///   - parent: Parent context (`FileDescriptor` or `MessageDescriptor`).
  ///   - options: Enum options.
  public init(
    name: String,
    parent: (any DescriptorParent)? = nil,
    options: [String: DescriptorOption] = [:]
  ) {
    self.name = name
    self.options = options

    if let parent {
      let prefix = parent.descriptorFullNamePrefix
      self.fullName = prefix.isEmpty ? name : "\(prefix).\(name)"
      self.parentMessageFullName = parent.descriptorParentMessageFullName
      self.fileDescriptorPath = parent.descriptorFilePath
    }
    else {
      self.fullName = name
    }
  }

  // MARK: - Value Methods

  /// Adds an enum value.
  ///
  /// - Parameter value: Enum value to add.
  /// - Returns: Updated EnumDescriptor.
  @discardableResult
  public mutating func addValue(_ value: EnumValue) -> Self {
    valuesByName[value.name] = value
    valuesByNumber[value.number] = value
    return self
  }

  /// Checks if the enum contains the specified value by name.
  ///
  /// - Parameter name: Value name.
  /// - Returns: true if the value exists.
  public func hasValue(named name: String) -> Bool {
    return valuesByName[name] != nil
  }

  /// Checks if the enum contains the specified value by number.
  ///
  /// - Parameter number: Numeric value.
  /// - Returns: true if the value exists.
  public func hasValue(number: Int) -> Bool {
    return valuesByNumber[number] != nil
  }

  /// Gets an enum value by name.
  ///
  /// - Parameter name: Value name.
  /// - Returns: Enum value if it exists.
  public func value(named name: String) -> EnumValue? {
    return valuesByName[name]
  }

  /// Gets an enum value by numeric value.
  ///
  /// - Parameter number: Numeric value.
  /// - Returns: Enum value if it exists.
  public func value(number: Int) -> EnumValue? {
    return valuesByNumber[number]
  }

  /// Gets a list of all enum values ordered by numeric value.
  ///
  /// - Returns: Ordered list of enum values.
  public func allValues() -> [EnumValue] {
    return valuesByNumber.sorted { $0.key < $1.key }.map { $0.value }
  }

  // MARK: - Validation

  /// Validates the enum against proto3 rules.
  ///
  /// - Returns: Array of validation error strings. Empty if valid.
  public func validateProto3() -> [String] {
    var errors: [String] = []

    if valuesByName.isEmpty && valuesByNumber.isEmpty {
      errors.append("Enum '\(fullName)' must have at least one value")
      return errors
    }

    if !valuesByNumber.keys.contains(0) {
      errors.append("Proto3 enum '\(fullName)' must have a value with number 0")
    }

    return errors
  }

  /// Validates the enum against proto2 rules.
  ///
  /// Proto2 enums must have at least one value but do not require
  /// a value with number 0 (unlike proto3).
  ///
  /// - Returns: Array of validation error strings. Empty if valid.
  public func validateProto2() -> [String] {
    var errors: [String] = []

    if valuesByName.isEmpty && valuesByNumber.isEmpty {
      errors.append("Enum '\(fullName)' must have at least one value")
    }

    return errors
  }

  // MARK: - Equatable

  /// Returns `true` if both descriptors have the same identity and values.
  public static func == (lhs: EnumDescriptor, rhs: EnumDescriptor) -> Bool {
    guard
      lhs.name == rhs.name && lhs.fullName == rhs.fullName && lhs.fileDescriptorPath == rhs.fileDescriptorPath
        && lhs.parentMessageFullName == rhs.parentMessageFullName && lhs.options == rhs.options
    else {
      return false
    }

    let lhsValuesByName = lhs.valuesByName
    let rhsValuesByName = rhs.valuesByName

    guard lhsValuesByName.count == rhsValuesByName.count else {
      return false
    }

    for (name, lhsValue) in lhsValuesByName {
      guard let rhsValue = rhsValuesByName[name], lhsValue == rhsValue else {
        return false
      }
    }

    return true
  }
}

// MARK: - ServiceDescriptor

/// ServiceDescriptor.
///
/// Protocol Buffers service descriptor that describes a gRPC service,
/// its methods, input and output message types, and options.
public struct ServiceDescriptor: Equatable, Sendable {
  // MARK: - Types

  /// Service method descriptor with name, input and output types.
  public struct MethodDescriptor: Equatable, Sendable {
    /// Method name (e.g., "GetUser").
    public let name: String

    /// Full name of input message type (e.g., "example.GetUserRequest").
    public let inputType: String

    /// Full name of output message type (e.g., "example.GetUserResponse").
    public let outputType: String

    /// Indicates if the method is client streaming.
    public let clientStreaming: Bool

    /// Indicates if the method is server streaming.
    public let serverStreaming: Bool

    /// Method options.
    public let options: [String: DescriptorOption]

    /// Creates a new method descriptor.
    ///
    /// - Parameters:
    ///   - name: Method name.
    ///   - inputType: Full name of input message type.
    ///   - outputType: Full name of output message type.
    ///   - clientStreaming: Client streaming flag.
    ///   - serverStreaming: Server streaming flag.
    ///   - options: Method options.
    public init(
      name: String,
      inputType: String,
      outputType: String,
      clientStreaming: Bool = false,
      serverStreaming: Bool = false,
      options: [String: DescriptorOption] = [:]
    ) {
      self.name = name
      self.inputType = inputType
      self.outputType = outputType
      self.clientStreaming = clientStreaming
      self.serverStreaming = serverStreaming
      self.options = options
    }

    // MARK: - Equatable

    /// Returns `true` if both method descriptors have the same properties.
    public static func == (lhs: MethodDescriptor, rhs: MethodDescriptor) -> Bool {
      return lhs.name == rhs.name && lhs.inputType == rhs.inputType && lhs.outputType == rhs.outputType
        && lhs.clientStreaming == rhs.clientStreaming && lhs.serverStreaming == rhs.serverStreaming
        && lhs.options == rhs.options
    }
  }

  // MARK: - Properties

  /// Service name (e.g., "UserService").
  public let name: String

  /// Full service name including package (e.g., "example.UserService").
  public let fullName: String

  /// Path to parent file (for reference resolution).
  public var fileDescriptorPath: String?

  /// List of service methods by name.
  public private(set) var methodsByName: [String: MethodDescriptor] = [:]

  /// Service options.
  public let options: [String: DescriptorOption]

  // MARK: - Initialization

  /// Creates a new ServiceDescriptor instance.
  ///
  /// - Parameters:
  ///   - name: Service name.
  ///   - fullName: Full service name.
  ///   - options: Service options.
  public init(
    name: String,
    fullName: String,
    options: [String: DescriptorOption] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.options = options
  }

  /// Creates a new ServiceDescriptor instance with a base name.
  ///
  /// Full name will be generated automatically based on parent file.
  ///
  /// - Parameters:
  ///   - name: Service name.
  ///   - parent: Parent file.
  ///   - options: Service options.
  public init(
    name: String,
    parent: FileDescriptor,
    options: [String: DescriptorOption] = [:]
  ) {
    self.name = name
    self.options = options
    self.fullName = parent.getFullName(for: name)
    self.fileDescriptorPath = parent.name
  }

  // MARK: - Method Methods

  /// Adds a method to the service.
  ///
  /// - Parameter method: Method descriptor to add.
  /// - Returns: Updated ServiceDescriptor.
  @discardableResult
  public mutating func addMethod(_ method: MethodDescriptor) -> Self {
    methodsByName[method.name] = method
    return self
  }

  /// Checks if the service contains the specified method.
  ///
  /// - Parameter name: Method name.
  /// - Returns: true if the method exists.
  public func hasMethod(named name: String) -> Bool {
    return methodsByName[name] != nil
  }

  /// Gets a method by name.
  ///
  /// - Parameter name: Method name.
  /// - Returns: Method descriptor if it exists.
  public func method(named name: String) -> MethodDescriptor? {
    return methodsByName[name]
  }

  /// Gets a list of all service methods.
  ///
  /// - Returns: List of methods.
  public func allMethods() -> [MethodDescriptor] {
    return Array(methodsByName.values)
  }

  // MARK: - Equatable

  /// Returns `true` if both descriptors have the same identity and methods.
  public static func == (lhs: ServiceDescriptor, rhs: ServiceDescriptor) -> Bool {
    guard
      lhs.name == rhs.name && lhs.fullName == rhs.fullName && lhs.fileDescriptorPath == rhs.fileDescriptorPath
        && lhs.options == rhs.options
    else {
      return false
    }

    let lhsMethodsByName = lhs.methodsByName
    let rhsMethodsByName = rhs.methodsByName

    guard lhsMethodsByName.count == rhsMethodsByName.count else {
      return false
    }

    for (name, lhsMethod) in lhsMethodsByName {
      guard let rhsMethod = rhsMethodsByName[name], lhsMethod == rhsMethod else {
        return false
      }
    }

    return true
  }
}

// MARK: - FileDescriptor

/// FileDescriptor.
///
/// Representation of a .proto file containing metadata about messages, enums,
/// services and other elements defined in the Protocol Buffers file.
public struct FileDescriptor: Sendable {
  // MARK: - Properties

  /// File name (e.g., "person.proto").
  public let name: String

  /// Package the file belongs to (e.g., "example.person").
  public let package: String

  /// File dependencies (imported .proto files).
  public let dependencies: [String]

  /// Proto syntax version (e.g. "proto2", "proto3").
  public let syntax: String

  /// File options.
  public let options: [String: DescriptorOption]

  /// List of messages defined in the file.
  public private(set) var messages: [String: MessageDescriptor] = [:]

  /// List of enums defined in the file.
  public private(set) var enums: [String: EnumDescriptor] = [:]

  /// List of services defined in the file.
  public private(set) var services: [String: ServiceDescriptor] = [:]

  // MARK: - Initialization

  /// Creates a new FileDescriptor instance.
  ///
  /// - Parameters:
  ///   - name: File name (e.g. "person.proto").
  ///   - package: Package name (e.g. "example.person").
  ///   - dependencies: Imported .proto file names.
  ///   - syntax: Proto syntax version. Defaults to `"proto3"`.
  ///             Empty string is normalised to `"proto2"` per protobuf spec.
  ///   - options: File-level options.
  public init(
    name: String,
    package: String,
    dependencies: [String] = [],
    syntax: String = "proto3",
    options: [String: DescriptorOption] = [:]
  ) {
    self.name = name
    self.package = package
    self.dependencies = dependencies
    self.syntax = syntax.isEmpty ? "proto2" : syntax
    self.options = options
  }

  // MARK: - Methods

  /// Adds a message descriptor to the file.
  ///
  /// - Parameter messageDescriptor: Message descriptor to add.
  /// - Returns: Updated FileDescriptor.
  @discardableResult
  public mutating func addMessage(_ messageDescriptor: MessageDescriptor) -> Self {
    var newMessage = messageDescriptor

    if newMessage.fileDescriptorPath == nil && newMessage.parentMessageFullName == nil {
      newMessage.fileDescriptorPath = self.name
    }

    newMessage.syntax = self.syntax

    messages[messageDescriptor.name] = newMessage
    return self
  }

  /// Adds an enum descriptor to the file.
  ///
  /// - Parameter enumDescriptor: Enum descriptor to add.
  /// - Returns: Updated FileDescriptor.
  @discardableResult
  public mutating func addEnum(_ enumDescriptor: EnumDescriptor) -> Self {
    enums[enumDescriptor.name] = enumDescriptor
    return self
  }

  /// Adds a service descriptor to the file.
  ///
  /// - Parameter serviceDescriptor: Service descriptor to add.
  /// - Returns: Updated FileDescriptor.
  @discardableResult
  public mutating func addService(_ serviceDescriptor: ServiceDescriptor) -> Self {
    services[serviceDescriptor.name] = serviceDescriptor
    return self
  }

  /// Gets the full path for a type in this file.
  ///
  /// - Parameter typeName: Type name.
  /// - Returns: Full name with package.
  public func getFullName(for typeName: String) -> String {
    return package.isEmpty ? typeName : "\(package).\(typeName)"
  }

  /// Checks if the file contains the specified message.
  ///
  /// - Parameter name: Message name.
  /// - Returns: true if the message exists.
  public func hasMessage(named name: String) -> Bool {
    return messages[name] != nil
  }

  /// Checks if the file contains the specified enum.
  ///
  /// - Parameter name: Enum name.
  /// - Returns: true if the enum exists.
  public func hasEnum(named name: String) -> Bool {
    return enums[name] != nil
  }

  /// Checks if the file contains the specified service.
  ///
  /// - Parameter name: Service name.
  /// - Returns: true if the service exists.
  public func hasService(named name: String) -> Bool {
    return services[name] != nil
  }
}

// MARK: - FileDescriptor: DescriptorParent

extension FileDescriptor: DescriptorParent {

  /// Package string used as the fully-qualified name prefix for child types.
  public var descriptorFullNamePrefix: String { package }

  /// The file's own path — propagated to child descriptors.
  public var descriptorFilePath: String? { name }

  /// Syntax version of this file.
  public var descriptorSyntax: String { syntax }

  /// Files are not messages; always `nil`.
  public var descriptorParentMessageFullName: String? { nil }
}
