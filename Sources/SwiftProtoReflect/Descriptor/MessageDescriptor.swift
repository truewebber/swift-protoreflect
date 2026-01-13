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
public struct MessageDescriptor: @unchecked Sendable {
  // MARK: - Properties

  /// Message name (e.g., "Person").
  public let name: String

  /// Full message name including package (e.g., "example.person.Person").
  public let fullName: String

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

  /// Message options.
  public let options: [String: Any]

  // MARK: - Initialization

  /// Creates a new MessageDescriptor instance.
  ///
  /// - Parameters:
  ///   - name: Message name.
  ///   - fullName: Full message name.
  ///   - options: Message options.
  public init(
    name: String,
    fullName: String,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.options = options
  }

  /// Creates a new MessageDescriptor instance with a base name.
  ///
  /// Full name will be generated automatically based on parent file or message.
  ///
  /// - Parameters:
  ///   - name: Message name.
  ///   - parent: Parent file or message.
  ///   - options: Message options.
  public init(
    name: String,
    parent: Any? = nil,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.options = options

    if let parentMessage = parent as? MessageDescriptor {
      self.fullName = "\(parentMessage.fullName).\(name)"
      self.parentMessageFullName = parentMessage.fullName
      self.fileDescriptorPath = parentMessage.fileDescriptorPath
    }
    else if let fileDescriptor = parent as? FileDescriptor {
      self.fullName = fileDescriptor.getFullName(for: name)
      self.fileDescriptorPath = fileDescriptor.name
    }
    else {
      self.fullName = name
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

  // MARK: - Nested Type Methods

  /// Adds a nested message.
  ///
  /// - Parameter message: Nested message descriptor.
  /// - Returns: Updated MessageDescriptor.
  @discardableResult
  public mutating func addNestedMessage(_ message: MessageDescriptor) -> Self {
    var messageCopy = message
    messageCopy.parentMessageFullName = self.fullName
    messageCopy.fileDescriptorPath = self.fileDescriptorPath
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
}

// FieldDescriptor is defined in FieldDescriptor.swift file
