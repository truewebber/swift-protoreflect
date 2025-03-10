import Foundation
import SwiftProtobuf

/// Describes a Protocol Buffer enum type, including its name and values.
///
/// This class provides metadata about a Protocol Buffer enum type, including its name and values.
/// It is used for dynamic enum handling and validation.
///
/// Example:
/// ```swift
/// // Creating from a SwiftProtobuf enum descriptor
/// let enumDescriptor = ProtoEnumDescriptor(enumProto: enumProto)
///
/// // Or creating manually
/// let statusEnum = ProtoEnumDescriptor(
///     name: "Status",
///     values: [
///         ProtoEnumValueDescriptor(name: "UNKNOWN", number: 0),
///         ProtoEnumValueDescriptor(name: "ACTIVE", number: 1),
///         ProtoEnumValueDescriptor(name: "INACTIVE", number: 2)
///     ]
/// )
/// ```
public class ProtoEnumDescriptor {
  /// The name of the enum type.
  ///
  /// This is the simple name of the enum, without any package or parent message names.
  /// For example, an enum defined as `enum Status { ... }` would have the name "Status".
  public let name: String

  /// The values defined in the enum.
  ///
  /// These are the individual enum values, each with a name and number.
  public let values: [ProtoEnumValueDescriptor]

  /// The original SwiftProtobuf enum descriptor proto, if this descriptor was created from one.
  private let enumProto: Google_Protobuf_EnumDescriptorProto?

  /// Creates a new enum descriptor with the specified name and values.
  ///
  /// - Parameters:
  ///   - name: The name of the enum type.
  ///   - values: The values defined in the enum.
  public init(name: String, values: [ProtoEnumValueDescriptor]) {
    self.name = name
    self.values = values
    self.enumProto = nil
  }

  /// Creates a new enum descriptor from a SwiftProtobuf enum descriptor proto.
  ///
  /// - Parameter enumProto: The SwiftProtobuf enum descriptor proto.
  public init(enumProto: Google_Protobuf_EnumDescriptorProto) {
    self.name = enumProto.name

    // Create enum value descriptors
    var valueDescriptors: [ProtoEnumValueDescriptor] = []
    for valueProto in enumProto.value {
      let valueDescriptor = ProtoEnumValueDescriptor(
        name: valueProto.name,
        number: Int(valueProto.number)
      )
      valueDescriptors.append(valueDescriptor)
    }

    self.values = valueDescriptors
    self.enumProto = enumProto
  }

  /// Retrieves an enum value descriptor by name.
  ///
  /// - Parameter name: The name of the enum value to retrieve.
  /// - Returns: The enum value descriptor, or nil if no value with the given name exists.
  public func value(named name: String) -> ProtoEnumValueDescriptor? {
    return values.first { $0.name == name }
  }

  /// Retrieves an enum value descriptor by number.
  ///
  /// - Parameter number: The number of the enum value to retrieve.
  /// - Returns: The enum value descriptor, or nil if no value with the given number exists.
  public func value(withNumber number: Int) -> ProtoEnumValueDescriptor? {
    return values.first { $0.number == number }
  }

  /// Verifies if the enum descriptor is valid according to Protocol Buffer rules.
  ///
  /// A valid enum descriptor must have a non-empty name and at least one value.
  ///
  /// - Returns: `true` if the enum descriptor is valid, `false` otherwise.
  public func isValid() -> Bool {
    return !name.isEmpty && !values.isEmpty
  }

  /// Returns a validation error message if the enum descriptor is invalid, or nil if it's valid.
  ///
  /// This method provides detailed information about why an enum descriptor is invalid.
  ///
  /// - Returns: An error message describing the validation failure, or nil if the descriptor is valid.
  public func validationError() -> String? {
    if name.isEmpty {
      return "Enum name cannot be empty"
    }

    if values.isEmpty {
      return "Enum \(name) must have at least one value"
    }

    // Check for duplicate value numbers
    var valueNumbers = Set<Int>()
    for value in values {
      if valueNumbers.contains(value.number) {
        return "Duplicate value number \(value.number) in enum \(name)"
      }
      valueNumbers.insert(value.number)
    }

    // Check for duplicate value names
    var valueNames = Set<String>()
    for value in values {
      if valueNames.contains(value.name) {
        return "Duplicate value name '\(value.name)' in enum \(name)"
      }
      valueNames.insert(value.name)
    }

    return nil
  }

  /// Returns the original SwiftProtobuf enum descriptor proto if available.
  ///
  /// - Returns: The original enum descriptor proto, or nil if this descriptor was not created from one.
  public func originalEnumProto() -> Google_Protobuf_EnumDescriptorProto? {
    return enumProto
  }
}
