/**
 * FieldMaskHandler.swift
 * SwiftProtoReflect
 *
 * Handler for google.protobuf.FieldMask - field masks for partial updates
 */

import Foundation
import SwiftProtobuf

// MARK: - FieldMask Handler

/// Handler for google.protobuf.FieldMask.
public struct FieldMaskHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.fieldMask
  public static let supportPhase: WellKnownSupportPhase = .important

  // MARK: - FieldMask Representation

  /// Specialized representation of FieldMask.
  public struct FieldMaskValue: Equatable, CustomStringConvertible {

    /// Field paths.
    public let paths: [String]

    /// Initialization with field paths.
    /// - Parameter paths: List of field paths.
    /// - Throws: WellKnownTypeError if paths are invalid.
    public init(paths: [String]) throws {
      for path in paths {
        guard Self.isValidPath(path) else {
          throw WellKnownTypeError.invalidData(
            typeName: WellKnownTypeNames.fieldMask,
            reason:
              "Invalid field path: '\(path)'. Path must not be empty and can only contain alphanumeric characters, dots, and underscores."
          )
        }
      }

      self.paths = paths
    }

    /// Initialization with single path.
    /// - Parameter path: Field path.
    /// - Throws: WellKnownTypeError if path is invalid.
    public init(path: String) throws {
      try self.init(paths: [path])
    }

    /// Initialization of empty mask.
    public init() {
      self.paths = []
    }

    /// Checks if mask contains specified path.
    /// - Parameter path: Path to check.
    /// - Returns: true if path is contained in mask.
    public func contains(_ path: String) -> Bool {
      return paths.contains(path)
    }

    /// Checks if mask contains path or its parent path.
    /// - Parameter path: Path to check.
    /// - Returns: true if path or its parent is contained in mask.
    public func covers(_ path: String) -> Bool {
      // Check exact match
      if paths.contains(path) {
        return true
      }

      // Check if parent path is in mask
      let components = path.split(separator: ".").map(String.init)
      for i in 1..<components.count {
        let parentPath = components[0..<i].joined(separator: ".")
        if paths.contains(parentPath) {
          return true
        }
      }

      return false
    }

    /// Adds path to mask.
    /// - Parameter path: Path to add.
    /// - Returns: New FieldMaskValue with added path.
    /// - Throws: WellKnownTypeError if path is invalid.
    public func adding(_ path: String) throws -> FieldMaskValue {
      guard Self.isValidPath(path) else {
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.fieldMask,
          reason: "Invalid field path: '\(path)'"
        )
      }

      var newPaths = paths
      if !newPaths.contains(path) {
        newPaths.append(path)
      }
      return try FieldMaskValue(paths: newPaths)
    }

    /// Removes path from mask.
    /// - Parameter path: Path to remove.
    /// - Returns: New FieldMaskValue without specified path.
    public func removing(_ path: String) -> FieldMaskValue {
      let newPaths = paths.filter { $0 != path }
      return try! FieldMaskValue(paths: newPaths)  // Safe since removing valid paths
    }

    /// Merges two field masks.
    /// - Parameter other: Other mask to merge.
    /// - Returns: New FieldMaskValue with merged paths.
    public func union(_ other: FieldMaskValue) -> FieldMaskValue {
      let combinedPaths = Array(Set(paths + other.paths)).sorted()
      return try! FieldMaskValue(paths: combinedPaths)  // Safe since merging valid paths
    }

    /// Intersection of two field masks.
    /// - Parameter other: Other mask for intersection.
    /// - Returns: New FieldMaskValue with intersected paths.
    public func intersection(_ other: FieldMaskValue) -> FieldMaskValue {
      let intersectionPaths = paths.filter { other.paths.contains($0) }
      return try! FieldMaskValue(paths: intersectionPaths)  // Safe since filtering valid paths
    }

    /// Empty field mask.
    /// - Returns: FieldMaskValue without paths.
    public static func empty() -> FieldMaskValue {
      return FieldMaskValue()
    }

    /// Mask with all specified fields.
    /// - Parameter paths: Field paths.
    /// - Returns: FieldMaskValue with specified paths.
    /// - Throws: WellKnownTypeError if any path is invalid.
    public static func with(paths: [String]) throws -> FieldMaskValue {
      return try FieldMaskValue(paths: paths)
    }

    public var description: String {
      if paths.isEmpty {
        return "FieldMask(empty)"
      }
      return "FieldMask(\(paths.joined(separator: ", ")))"
    }

    // MARK: - Validation

    /// Validates field path.
    /// - Parameter path: Path to validate.
    /// - Returns: true if path is valid.
    internal static func isValidPath(_ path: String) -> Bool {
      // Path must not be empty
      guard !path.isEmpty else {
        return false
      }

      // Path can only contain letters, digits, dots and underscores
      let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "._"))
      return path.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    // Check message type
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    // Extract paths field
    let pathsValue: [String]

    do {
      if try message.hasValue(forField: "paths") {
        if let value = try message.get(forField: "paths") as? [String] {
          pathsValue = value
        }
        else {
          pathsValue = []
        }
      }
      else {
        pathsValue = []
      }
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "FieldMaskValue",
        reason: "Failed to extract paths field: \(error.localizedDescription)"
      )
    }

    // Create FieldMaskValue
    return try FieldMaskValue(paths: pathsValue)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let fieldMaskValue = specialized as? FieldMaskValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected FieldMaskValue"
      )
    }

    // Create descriptor for FieldMask
    let fieldMaskDescriptor = createFieldMaskDescriptor()

    // Create message
    let factory = MessageFactory()
    var message = factory.createMessage(from: fieldMaskDescriptor)

    // Set paths field
    try message.set(fieldMaskValue.paths, forField: "paths")

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    guard let fieldMaskValue = specialized as? FieldMaskValue else {
      return false
    }

    // Check all paths in mask
    return fieldMaskValue.paths.allSatisfy { FieldMaskValue.isValidPath($0) }
  }

  // MARK: - Descriptor Creation

  /// Creates descriptor for google.protobuf.FieldMask.
  /// - Returns: MessageDescriptor for FieldMask.
  private static func createFieldMaskDescriptor() -> MessageDescriptor {
    // Create file descriptor
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/field_mask.proto",
      package: "google.protobuf"
    )

    // Create message descriptor
    var messageDescriptor = MessageDescriptor(
      name: "FieldMask",
      parent: fileDescriptor
    )

    // Add paths field
    let pathsField = FieldDescriptor(
      name: "paths",
      number: 1,
      type: .string,
      isRepeated: true
    )
    messageDescriptor.addField(pathsField)

    // Register in file
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

extension Array where Element == String {

  /// Creates FieldMaskValue from string array.
  /// - Returns: FieldMaskValue.
  /// - Throws: WellKnownTypeError if any path is invalid.
  public func toFieldMaskValue() throws -> FieldMaskHandler.FieldMaskValue {
    return try FieldMaskHandler.FieldMaskValue(paths: self)
  }
}

extension DynamicMessage {

  /// Creates DynamicMessage from path array for google.protobuf.FieldMask.
  /// - Parameter paths: Field paths.
  /// - Returns: DynamicMessage representing FieldMask.
  /// - Throws: WellKnownTypeError.
  public static func fieldMaskMessage(from paths: [String]) throws -> DynamicMessage {
    let fieldMask = try FieldMaskHandler.FieldMaskValue(paths: paths)
    return try FieldMaskHandler.createDynamic(from: fieldMask)
  }

  /// Converts DynamicMessage to path array (if it's FieldMask).
  /// - Returns: Array of field paths.
  /// - Throws: WellKnownTypeError if message is not FieldMask.
  public func toFieldPaths() throws -> [String] {
    guard descriptor.fullName == WellKnownTypeNames.fieldMask else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a FieldMask"
      )
    }

    let fieldMask = try FieldMaskHandler.createSpecialized(from: self) as! FieldMaskHandler.FieldMaskValue
    return fieldMask.paths
  }
}
