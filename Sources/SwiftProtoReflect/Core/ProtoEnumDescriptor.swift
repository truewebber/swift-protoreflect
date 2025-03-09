/// Describes an enum type within a Protocol Buffer message, including its values and names.
///
/// This class provides metadata about a Protocol Buffer enum type, including its name and values.
/// It is used for dynamic enum handling and validation.
///
/// Example:
/// ```swift
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
  /// Name of the enum type.
  ///
  /// This is the name of the enum as defined in the Protocol Buffer schema.
  public let name: String

  /// List of enum value descriptors in the enum.
  ///
  /// These describe the values that make up the enum, including their names and numbers.
  public let values: [ProtoEnumValueDescriptor]

  /// Creates a new enum descriptor with the specified properties.
  ///
  /// - Parameters:
  ///   - name: The name of the enum type.
  ///   - values: The value descriptors for the enum's values.
  public init(name: String, values: [ProtoEnumValueDescriptor]) {
    self.name = name
    self.values = values
  }

  /// Retrieves an enum value by name.
  ///
  /// - Parameter name: The name of the enum value to retrieve.
  /// - Returns: The enum value descriptor, or nil if no value with the given name exists.
  public func value(named name: String) -> ProtoEnumValueDescriptor? {
    return values.first { $0.name == name }
  }

  /// Retrieves an enum value by number.
  ///
  /// - Parameter number: The number of the enum value to retrieve.
  /// - Returns: The enum value descriptor, or nil if no value with the given number exists.
  public func value(by number: Int) -> ProtoEnumValueDescriptor? {
    return values.first { $0.number == number }
  }

  /// Verifies if the enum descriptor is valid according to Protocol Buffer rules.
  ///
  /// A valid enum descriptor must have a non-empty name and at least one value.
  ///
  /// - Returns: `true` if the descriptor is valid, `false` otherwise.
  public func isValid() -> Bool {
    return !name.isEmpty && !values.isEmpty
  }

  /// Returns a validation error message if the descriptor is invalid, or nil if it's valid.
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

    // Check value validity
    for value in values where !value.isValid() {
      return "Invalid value in enum \(name): \(value.name)"
    }

    return nil
  }
}
