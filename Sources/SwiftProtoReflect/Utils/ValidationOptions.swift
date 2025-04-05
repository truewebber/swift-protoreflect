import Foundation

/// Options for customizing Protocol Buffer message validation.
///
/// The `ValidationOptions` struct allows you to configure various aspects of Protocol Buffer
/// message validation, such as enum value validation, UTF-8 string validation, and recursion depth.
///
/// Example:
/// ```swift
/// var options = ValidationOptions()
/// options.validateEnumValues = true
/// options.validateUTF8 = true
/// options.maxRecursionDepth = 50
///
/// try message.validate(options: options)
/// ```
public struct ValidationOptions {
  /// Whether to validate enum values against descriptor.
  ///
  /// If `true` (default), enum values will be validated against their enum descriptors.
  /// If `false`, invalid enum values will be allowed, but may cause issues when interacting
  /// with other Protocol Buffer implementations.
  public var validateEnumValues: Bool = true

  /// Whether to validate string fields are valid UTF-8.
  ///
  /// If `true` (default), string fields will be validated as proper UTF-8.
  /// If `false`, validation will be skipped, which may lead to invalid Protocol Buffer messages.
  public var validateUTF8: Bool = true

  /// Maximum recursion depth for validation.
  ///
  /// This helps prevent stack overflow errors when dealing with deeply nested messages.
  /// The default value is 100, as specified in the Protocol Buffer wire format PRD.
  public var maxRecursionDepth: Int = 100

  /// Whether to validate repeated field elements.
  ///
  /// If `true` (default), each element in a repeated field will be validated.
  /// If `false`, only the field itself will be validated, not individual elements.
  public var validateRepeatedElements: Bool = true

  /// Whether to validate map field keys and values.
  ///
  /// If `true` (default), each key and value in a map field will be validated.
  /// If `false`, only the field itself will be validated, not individual entries.
  public var validateMapEntries: Bool = true

  /// Whether to check for circular references during validation.
  ///
  /// If `true` (default), validation will check for circular references between messages.
  /// If `false`, circular references will not be detected, which may cause infinite recursion.
  public var detectCircularReferences: Bool = true

  /// Creates a new `ValidationOptions` instance with default values.
  public init() {}

  /// Creates a new `ValidationOptions` instance with specified values.
  ///
  /// - Parameters:
  ///   - validateEnumValues: Whether to validate enum values against descriptor.
  ///   - validateUTF8: Whether to validate string fields are valid UTF-8.
  ///   - maxRecursionDepth: Maximum recursion depth for validation.
  ///   - validateRepeatedElements: Whether to validate repeated field elements.
  ///   - validateMapEntries: Whether to validate map field keys and values.
  ///   - detectCircularReferences: Whether to check for circular references during validation.
  public init(
    validateEnumValues: Bool = true,
    validateUTF8: Bool = true,
    maxRecursionDepth: Int = 100,
    validateRepeatedElements: Bool = true,
    validateMapEntries: Bool = true,
    detectCircularReferences: Bool = true
  ) {
    self.validateEnumValues = validateEnumValues
    self.validateUTF8 = validateUTF8
    self.maxRecursionDepth = maxRecursionDepth
    self.validateRepeatedElements = validateRepeatedElements
    self.validateMapEntries = validateMapEntries
    self.detectCircularReferences = detectCircularReferences
  }
}
