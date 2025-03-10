import Foundation

/// A builder for creating and manipulating dynamic messages.
///
/// `MessageBuilder` provides a fluent interface for setting and getting field values
/// in Protocol Buffer messages using path notation.
///
/// # Examples
///
/// ## Basic Usage
/// ```swift
/// // Create a new message builder
/// let person = ProtoReflect.createMessage(from: personDescriptor)
///
/// // Set field values using the builder pattern
/// person.set("name", to: "John Doe")
///     .set("age", to: 30)
///
/// // Get field values
/// let name = person.get("name")?.getString()
/// print("Name: \(name ?? "unknown")")
///
/// // Check if a field is set
/// if person.has("email") {
///     print("Email is set")
/// } else {
///     print("Email is not set")
/// }
///
/// // Clear a field
/// person.clear("name")
///
/// // Build the final message
/// let message = person.build()
/// ```
///
/// ## Working with Different Field Types
/// ```swift
/// // Setting primitive types
/// person.set("name", to: "John Doe")       // string
///     .set("age", to: 30)                  // int32
///     .set("height", to: 1.85)             // float
///     .set("isEmployed", to: true)         // bool
///     .set("id", to: 12345678901)          // int64
///
/// // Setting bytes
/// let imageData = Data([0x01, 0x02, 0x03])
/// person.set("profileImage", to: imageData)
///
/// // Setting enums (by name or number)
/// person.set("status", to: "ACTIVE")       // enum by name
/// person.set("role", to: 2)                // enum by number
/// ```
///
/// ## Working with Nested Messages
/// ```swift
/// // Setting nested fields using path notation
/// person.set("address.street", to: "123 Main St")
///     .set("address.city", to: "Anytown")
///     .set("address.zipCode", to: "12345")
///
/// // Getting nested fields
/// let city = person.get("address.city")?.getString()
///
/// // Setting a nested message as a whole
/// let addressDict: [String: Any] = [
///     "street": "456 Oak Ave",
///     "city": "Othertown",
///     "zipCode": "67890"
/// ]
/// person.set("address", to: addressDict)
///
/// // Clearing a nested field
/// person.clear("address.street")
///
/// // Clearing an entire nested message
/// person.clear("address")
/// ```
///
/// ## Working with Repeated Fields
/// ```swift
/// // Setting a repeated field
/// person.set("phoneNumbers", to: ["555-1234", "555-5678"])
///
/// // Adding to a repeated field (requires getting and modifying)
/// if var phones = person.get("phoneNumbers")?.getRepeated() {
///     phones.append(.stringValue("555-9012"))
///     person.set("phoneNumbers", to: .repeatedValue(phones))
/// }
///
/// // Getting values from a repeated field
/// if let phones = person.get("phoneNumbers")?.getRepeated() {
///     for (index, phone) in phones.enumerated() {
///         if let number = phone.getString() {
///             print("Phone \(index + 1): \(number)")
///         }
///     }
/// }
///
/// // Clearing a repeated field
/// person.clear("phoneNumbers")
/// ```
///
/// ## Working with Map Fields
/// ```swift
/// // Setting a map field
/// person.set("attributes", to: [
///     "height": "185cm",
///     "weight": "75kg",
///     "eyeColor": "blue"
/// ])
///
/// // Getting values from a map field
/// if let attributes = person.get("attributes")?.getMap() {
///     for (key, value) in attributes {
///         if let attributeValue = value.getString() {
///             print("\(key): \(attributeValue)")
///         }
///     }
/// }
///
/// // Getting a specific map entry
/// let heightPath = ProtoFieldPath(path: "attributes['height']")
/// if let height = heightPath.getValue(from: person.build())?.getString() {
///     print("Height: \(height)")
/// }
///
/// // Clearing a map field
/// person.clear("attributes")
/// ```
///
/// ## Complex Example
/// ```swift
/// // Create a complex person record
/// let person = ProtoReflect.createMessage(from: personDescriptor)
///
/// // Set basic info
/// person.set("name", to: "John Doe")
///     .set("age", to: 30)
///     .set("email", to: "john.doe@example.com")
///
/// // Set address
/// person.set("address.street", to: "123 Main St")
///     .set("address.city", to: "Anytown")
///     .set("address.state", to: "CA")
///     .set("address.zipCode", to: "12345")
///
/// // Set phone numbers
/// person.set("phoneNumbers", to: ["555-1234", "555-5678"])
///
/// // Set attributes
/// person.set("attributes", to: [
///     "height": "185cm",
///     "weight": "75kg",
///     "eyeColor": "blue"
/// ])
///
/// // Set work history (repeated messages)
/// person.set("workHistory[0].company", to: "Acme Corp")
///     .set("workHistory[0].position", to: "Developer")
///     .set("workHistory[0].startYear", to: 2015)
///     .set("workHistory[0].endYear", to: 2018)
///
/// person.set("workHistory[1].company", to: "Beta Inc")
///     .set("workHistory[1].position", to: "Senior Developer")
///     .set("workHistory[1].startYear", to: 2018)
///
/// // Build the final message
/// let message = person.build()
/// ```
public class MessageBuilder {
  /// The underlying dynamic message.
  private let message: ProtoDynamicMessage

  /// Creates a new message builder with the specified message.
  ///
  /// - Parameter message: The dynamic message to build.
  internal init(message: ProtoDynamicMessage) {
    self.message = message
  }

  /// Sets a field value using a path notation.
  ///
  /// - Parameters:
  ///   - path: The path to the field, such as "person.address.street".
  ///   - value: The value to set.
  /// - Returns: The builder for method chaining.
  @discardableResult
  public func set(_ path: String, to value: Any) -> MessageBuilder {
    let fieldPath = ProtoFieldPath(path: path)

    // Get the field descriptor to check the field type
    let components = path.split(separator: ".").map { String($0) }
    guard let fieldName = components.last,
      let field = message.descriptor().field(named: fieldName)
    else {
      // If we can't find the field, just try to set the value as is
      if let protoValue = ProtoValue.from(swiftValue: value, targetType: .string) {
        fieldPath.setValue(protoValue, in: message)
      }
      return self
    }

    // For repeated fields, handle special conversion
    if field.isRepeated {
      if let arrayValue = value as? [Any] {
        // Convert each element based on the field type
        var convertedArray: [ProtoValue] = []
        for element in arrayValue {
          // Use the new ProtoValue.from method for better type conversion
          if let convertedValue = ProtoValue.from(swiftValue: element, targetType: field.type) {
            convertedArray.append(convertedValue)
          }
          else {
            // If conversion fails, try a generic conversion
            if let genericValue = ProtoValue.from(swiftValue: element, targetType: .string) {
              convertedArray.append(genericValue)
            }
          }
        }

        let protoValue = ProtoValue.repeatedValue(convertedArray)
        fieldPath.setValue(protoValue, in: message)
        return self
      }
    }

    // For map fields, handle special conversion
    if field.isMap {
      if let mapValue = value as? [String: Any] {
        // Get the value field descriptor from the map entry message
        var valueFieldType: ProtoFieldType = .string  // Default to string if we can't determine
        if let messageType = field.messageType,
          let valueField = messageType.field(named: "value")
        {
          valueFieldType = valueField.type
        }

        // Convert each value based on the value field type
        var convertedMap: [String: ProtoValue] = [:]
        for (key, element) in mapValue {
          // Use the new ProtoValue.from method for better type conversion
          if let convertedValue = ProtoValue.from(swiftValue: element, targetType: valueFieldType) {
            convertedMap[key] = convertedValue
          }
          else {
            // If conversion fails, try a generic conversion
            if let genericValue = ProtoValue.from(swiftValue: element, targetType: .string) {
              convertedMap[key] = genericValue
            }
          }
        }

        let protoValue = ProtoValue.mapValue(convertedMap)
        fieldPath.setValue(protoValue, in: message)
        return self
      }
    }

    // For non-repeated, non-map fields, use the specific type conversion
    if let convertedValue = ProtoValue.from(swiftValue: value, targetType: field.type) {
      fieldPath.setValue(convertedValue, in: message)
    }
    else {
      // If conversion fails, try a generic conversion
      if let genericValue = ProtoValue.from(swiftValue: value, targetType: .string) {
        fieldPath.setValue(genericValue, in: message)
      }
    }

    return self
  }

  /// Gets a field value using a path notation.
  ///
  /// - Parameter path: The path to the field, such as "person.address.street".
  /// - Returns: The field value, or nil if the path is invalid.
  public func get(_ path: String) -> ProtoValue? {
    let fieldPath = ProtoFieldPath(path: path)
    return fieldPath.getValue(from: message)
  }

  /// Clears a field value using a path notation.
  ///
  /// - Parameter path: The path to the field, such as "person.address.street".
  /// - Returns: The builder for method chaining.
  @discardableResult
  public func clear(_ path: String) -> MessageBuilder {
    let fieldPath = ProtoFieldPath(path: path)
    fieldPath.clearValue(in: message)
    return self
  }

  /// Checks if a field is set using a path notation.
  ///
  /// - Parameter path: The path to the field, such as "person.address.street".
  /// - Returns: `true` if the field is set, `false` otherwise.
  public func has(_ path: String) -> Bool {
    let fieldPath = ProtoFieldPath(path: path)
    return fieldPath.hasValue(in: message)
  }

  /// Returns the underlying dynamic message.
  ///
  /// - Returns: The dynamic message.
  public func build() -> ProtoMessage {
    return message
  }
}
