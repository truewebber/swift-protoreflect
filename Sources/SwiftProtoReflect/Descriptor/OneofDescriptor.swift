//
// OneofDescriptor.swift
// SwiftProtoReflect
//
// Created: 2026-03-20
//

/// Descriptor for a oneof group in a Protocol Buffers message.
///
/// A oneof group means that at most one field within the group can be set at a time.
/// `OneofDescriptor` gives consumers the name and position of the group
/// within the parent message, matching `FieldDescriptor.oneofIndex`.
public struct OneofDescriptor: Equatable {

  /// Group name as defined in the .proto file (e.g. "contact").
  public let name: String

  /// Zero-based index within the parent message.
  ///
  /// Matches `FieldDescriptor.oneofIndex` for all fields that belong to this group.
  public let index: Int

  /// Oneof options (mirrors `Google_Protobuf_OneofOptions`).
  public let options: [String: Any]

  /// Creates a new `OneofDescriptor`.
  ///
  /// - Parameters:
  ///   - name: Group name as defined in the .proto file.
  ///   - index: Zero-based index within the parent message.
  ///   - options: Oneof options; defaults to empty.
  public init(name: String, index: Int, options: [String: Any] = [:]) {
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
