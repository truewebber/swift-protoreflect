/// Defines the core protocol for all Protocol Buffer messages in the reflection system.
///
/// Messages conforming to ProtoMessage can be manipulated dynamically without knowing their structure at compile time.
/// This protocol provides methods for accessing and modifying field values, as well as retrieving schema information.
///
/// Example usage:
/// ```swift
/// // Assuming we have a message and its descriptor
/// let value = message.get(field: descriptor.field(named: "user_id"))
/// if let userId = value?.getInt() {
///     print("User ID: \(userId)")
/// }
///
/// // Setting a field value
/// message.set(field: descriptor.field(named: "user_id"), value: .intValue(42))
/// ```
public protocol ProtoMessage {
  /// Returns the descriptor of the message, which holds schema information.
  ///
  /// - Returns: The message descriptor containing field definitions and other metadata.
  func descriptor() -> ProtoMessageDescriptor

  /// Retrieves the value of the specified field using its field descriptor.
  ///
  /// - Parameter field: The descriptor of the field to retrieve.
  /// - Returns: The field value, or nil if the field is not set.
  func get(field: ProtoFieldDescriptor) -> ProtoValue?

  /// Sets the value of the specified field.
  ///
  /// - Parameters:
  ///   - field: The descriptor of the field to set.
  ///   - value: The value to set for the field.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  @discardableResult
  func set(field: ProtoFieldDescriptor, value: ProtoValue) -> Bool

  /// Clears the value of the specified field, resetting it to its default.
  ///
  /// - Parameter field: The descriptor of the field to clear.
  /// - Returns: `true` if the field was cleared successfully, `false` otherwise.
  @discardableResult
  func clear(field: ProtoFieldDescriptor) -> Bool

  /// Returns whether the message is valid and properly initialized.
  ///
  /// - Returns: `true` if the message is valid, `false` otherwise.
  func isValid() -> Bool
}
