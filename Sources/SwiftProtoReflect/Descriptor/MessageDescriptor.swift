//
// MessageDescriptor.swift
// SwiftProtoReflect
//
// Created: 2025-05-18
//

import Foundation
import SwiftProtobuf

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

  /// Creates a new `MessageDescriptor` with its `fullName` derived from the parent.
  ///
  /// - Deprecated: Pass a `FileDescriptor` or `MessageDescriptor` directly.
  ///   Both types conform to `DescriptorParent`.
  @available(
    *,
    deprecated,
    message: "Pass a FileDescriptor or MessageDescriptor, both conform to DescriptorParent."
  )
  public init(
    name: String,
    parent: Any?,  // no default — avoids nil-ambiguity
    options: [String: DescriptorOption] = [:]
  ) {
    self.init(name: name, parent: parent as? (any DescriptorParent), options: options)
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
