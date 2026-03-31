//
// DescriptorParent.swift
// SwiftProtoReflect
//
// Created: 2025-03-31
//

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

// MARK: - FileDescriptor conformance

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

// MARK: - MessageDescriptor conformance

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
