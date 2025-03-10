import Foundation

/// Utility functions for reflection on Protocol Buffer messages.
///
/// This class provides utility functions for inspecting and describing Protocol Buffer messages
/// and their descriptors.
public struct ProtoReflectionUtils {

  /// Validates a message descriptor to ensure it is properly initialized.
  ///
  /// - Parameter descriptor: The message descriptor to validate.
  /// - Returns: `true` if the descriptor is valid, `false` otherwise.
  public static func validateMessageDescriptor(_ descriptor: ProtoMessageDescriptor) -> Bool {
    return descriptor.isValid()
  }

  /// Describes a message, including its fields and their types.
  ///
  /// - Parameter message: The message to describe.
  /// - Returns: A string description of the message.
  public static func describeMessage(_ message: ProtoMessage) -> String {
    let descriptor = message.descriptor()
    var description = "Message: \(descriptor.fullName)\n"
    for field in descriptor.fields {
      description += "Field: \(field.name) (Type: \(field.type.description()))\n"
    }
    return description
  }

  /// Validates a field descriptor to ensure it is properly initialized.
  ///
  /// - Parameter descriptor: The field descriptor to validate.
  /// - Returns: `true` if the descriptor is valid, `false` otherwise.
  public static func validateFieldDescriptor(_ descriptor: ProtoFieldDescriptor) -> Bool {
    return descriptor.isValid()
  }
}
