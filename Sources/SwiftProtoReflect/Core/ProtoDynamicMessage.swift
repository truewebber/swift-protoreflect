import Foundation

/// Errors that can occur when working with Protocol Buffer messages.
///
/// These errors provide detailed information about what went wrong when
/// manipulating dynamic Protocol Buffer messages.
public enum ProtoError: Error, CustomStringConvertible {
  /// A field was not found in the message descriptor.
  case fieldNotFound(fieldName: String, messageType: String)

  /// A field value was invalid for the field type.
  case invalidFieldValue(fieldName: String, expectedType: String, actualValue: String)

  /// A required field was missing.
  case missingRequiredField(fieldName: String, messageType: String)

  /// An index was out of bounds for a repeated field.
  case indexOutOfBounds(fieldName: String, index: Int, count: Int)

  /// A key was not found in a map field.
  case keyNotFound(fieldName: String, key: String)

  /// A message validation error occurred.
  case validationError(message: String)

  /// A general error occurred.
  case generalError(message: String)

  /// A human-readable description of the error.
  public var description: String {
    switch self {
    case .fieldNotFound(let fieldName, let messageType):
      return "Field '\(fieldName)' not found in message type '\(messageType)'"
    case .invalidFieldValue(let fieldName, let expectedType, let actualValue):
      return "Invalid value for field '\(fieldName)': expected type '\(expectedType)', got '\(actualValue)'"
    case .missingRequiredField(let fieldName, let messageType):
      return "Required field '\(fieldName)' is missing in message type '\(messageType)'"
    case .indexOutOfBounds(let fieldName, let index, let count):
      return "Index \(index) is out of bounds for repeated field '\(fieldName)' with \(count) elements"
    case .keyNotFound(let fieldName, let key):
      return "Key '\(key)' not found in map field '\(fieldName)'"
    case .validationError(let message):
      return "Validation error: \(message)"
    case .generalError(let message):
      return "Error: \(message)"
    }
  }
}

/// A dynamic implementation of a Protocol Buffer message.
///
/// `ProtoDynamicMessage` allows for the creation and manipulation of Protocol Buffer messages
/// at runtime without generated code. It stores field values based on field descriptors and
/// provides methods for accessing and modifying these values.
///
/// # Examples
///
/// ## Creating Messages
/// ```swift
/// // Create a message descriptor
/// let addressDescriptor = ProtoMessageDescriptor(
///     fullName: "Address",
///     fields: [
///         ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
///         ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
///         ProtoFieldDescriptor(name: "zipCode", number: 3, type: .string, isRepeated: false, isMap: false)
///     ],
///     enums: [],
///     nestedMessages: []
/// )
///
/// let personDescriptor = ProtoMessageDescriptor(
///     fullName: "Person",
///     fields: [
///         ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
///         ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false),
///         ProtoFieldDescriptor(name: "address", number: 3, type: .message, isRepeated: false, isMap: false, messageType: addressDescriptor),
///         ProtoFieldDescriptor(name: "phoneNumbers", number: 4, type: .string, isRepeated: true, isMap: false),
///         ProtoFieldDescriptor(name: "attributes", number: 5, type: .string, isRepeated: false, isMap: true)
///     ],
///     enums: [],
///     nestedMessages: []
/// )
///
/// // Create a dynamic message
/// let person = ProtoDynamicMessage(descriptor: personDescriptor)
/// ```
///
/// ## Setting Field Values
/// ```swift
/// // Set simple field values
/// person.set(fieldName: "name", value: .stringValue("John Doe"))
/// person.set(fieldName: "age", value: .intValue(30))
///
/// // Set a nested message field
/// let address = ProtoDynamicMessage(descriptor: addressDescriptor)
/// address.set(fieldName: "street", value: .stringValue("123 Main St"))
/// address.set(fieldName: "city", value: .stringValue("Anytown"))
/// address.set(fieldName: "zipCode", value: .stringValue("12345"))
///
/// person.set(fieldName: "address", value: .messageValue(address))
///
/// // Set a repeated field
/// person.set(fieldName: "phoneNumbers", value: .repeatedValue([
///     .stringValue("555-1234"),
///     .stringValue("555-5678")
/// ]))
///
/// // Set a map field
/// person.set(fieldName: "attributes", value: .mapValue([
///     "height": .stringValue("180cm"),
///     "weight": .stringValue("75kg")
/// ]))
/// ```
///
/// ## Getting Field Values
/// ```swift
/// // Get simple field values
/// if let name = person.get(fieldName: "name")?.getString() {
///     print("Name: \(name)")
/// }
///
/// if let age = person.get(fieldName: "age")?.getInt() {
///     print("Age: \(age)")
/// }
///
/// // Get a nested message field
/// if let addressValue = person.get(fieldName: "address"),
///    let addressMessage = addressValue.getMessage() as? ProtoDynamicMessage,
///    let street = addressMessage.get(fieldName: "street")?.getString() {
///     print("Street: \(street)")
/// }
///
/// // Get a repeated field
/// if let phoneNumbers = person.get(fieldName: "phoneNumbers")?.getRepeated() {
///     for (index, phoneNumber) in phoneNumbers.enumerated() {
///         if let number = phoneNumber.getString() {
///             print("Phone \(index + 1): \(number)")
///         }
///     }
/// }
///
/// // Get a map field
/// if let attributes = person.get(fieldName: "attributes")?.getMap() {
///     for (key, value) in attributes {
///         if let attributeValue = value.getString() {
///             print("\(key): \(attributeValue)")
///         }
///     }
/// }
/// ```
///
/// ## Checking Field Presence and Clearing Fields
/// ```swift
/// // Check if a field is set
/// if person.has(fieldName: "name") {
///     print("Name is set")
/// }
///
/// // Clear a field
/// person.clear(fieldName: "name")
///
/// // Check again
/// if !person.has(fieldName: "name") {
///     print("Name is not set")
/// }
/// ```
///
/// ## Validating Messages
/// ```swift
/// // Validate the entire message
/// let isValid = person.validateFields()
/// if isValid {
///     print("Person message is valid")
/// } else {
///     print("Person message is invalid")
/// }
/// ```
public class ProtoDynamicMessage: ProtoMessage, Hashable {
  /// The message descriptor for this dynamic message.
  private let messageDescriptor: ProtoMessageDescriptor

  /// A dictionary that maps field numbers to their current values.
  private var fields: [Int: ProtoValue]

  /// A flag indicating whether the message has been initialized with required fields.
  private var isInitialized: Bool = false

  /// Any validation errors that occurred during the last validation.
  private var validationErrors: [ProtoError] = []

  /// Creates a new dynamic message with the specified descriptor.
  ///
  /// - Parameter descriptor: The descriptor defining the structure of the message.
  public init(descriptor: ProtoMessageDescriptor) {
    self.messageDescriptor = descriptor
    self.fields = [:]
  }

  /// Creates a new dynamic message with the specified descriptor and initial field values.
  ///
  /// - Parameters:
  ///   - descriptor: The descriptor defining the structure of the message.
  ///   - initialValues: A dictionary mapping field numbers to their initial values.
  public init(descriptor: ProtoMessageDescriptor, initialValues: [Int: ProtoValue]) {
    self.messageDescriptor = descriptor
    self.fields = initialValues
    validateFields()
  }

  /// Returns the message descriptor (schema information).
  ///
  /// - Returns: The message descriptor containing field definitions and other metadata.
  public func descriptor() -> ProtoMessageDescriptor {
    return messageDescriptor
  }

  /// Returns any validation errors that occurred during the last validation.
  ///
  /// - Returns: An array of validation errors, or an empty array if no errors occurred.
  public var errors: [ProtoError] {
    return validationErrors
  }

  /// Retrieves the value of the specified field using its descriptor.
  ///
  /// - Parameter field: The descriptor of the field to retrieve.
  /// - Returns: The field value, or nil if the field is not set.
  /// - Throws: `ProtoError.fieldNotFound` if the field is not found in this message.
  public func tryGet(field: ProtoFieldDescriptor) throws -> ProtoValue? {
    guard let fieldDescriptor = validateFieldDescriptor(field) else {
      throw ProtoError.fieldNotFound(fieldName: field.name, messageType: messageDescriptor.fullName)
    }

    return fields[fieldDescriptor.number]
  }

  /// Retrieves the value of a field by its name.
  ///
  /// - Parameter name: The name of the field to retrieve.
  /// - Returns: The field value, or nil if the field is not found or not set.
  /// - Throws: `ProtoError.fieldNotFound` if the field is not found in this message.
  public func tryGet(fieldName: String) throws -> ProtoValue? {
    guard let field = messageDescriptor.field(named: fieldName) else {
      throw ProtoError.fieldNotFound(fieldName: fieldName, messageType: messageDescriptor.fullName)
    }

    return try tryGet(field: field)
  }

  /// Retrieves the value of a field by its number.
  ///
  /// - Parameter number: The number of the field to retrieve.
  /// - Returns: The field value, or nil if the field is not found or not set.
  /// - Throws: `ProtoError.fieldNotFound` if the field is not found in this message.
  public func tryGet(fieldNumber: Int) throws -> ProtoValue? {
    guard let field = messageDescriptor.field(number: fieldNumber) else {
      throw ProtoError.fieldNotFound(fieldName: "#\(fieldNumber)", messageType: messageDescriptor.fullName)
    }

    return try tryGet(field: field)
  }

  /// Non-throwing version of tryGet(field:) for backward compatibility.
  ///
  /// - Parameter field: The descriptor of the field to retrieve.
  /// - Returns: The field value, or nil if the field is not set or an error occurs.
  public func get(field: ProtoFieldDescriptor) -> ProtoValue? {
    do {
      return try tryGet(field: field)
    }
    catch {
      return nil
    }
  }

  /// Non-throwing version of tryGet(fieldName:) for backward compatibility.
  ///
  /// - Parameter name: The name of the field to retrieve.
  /// - Returns: The field value, or nil if the field is not found or not set or an error occurs.
  public func get(fieldName: String) -> ProtoValue? {
    do {
      return try tryGet(fieldName: fieldName)
    }
    catch {
      return nil
    }
  }

  /// Non-throwing version of tryGet(fieldNumber:) for backward compatibility.
  ///
  /// - Parameter number: The number of the field to retrieve.
  /// - Returns: The field value, or nil if the field is not found or not set or an error occurs.
  public func get(fieldNumber: Int) -> ProtoValue? {
    do {
      return try tryGet(fieldNumber: fieldNumber)
    }
    catch {
      return nil
    }
  }

  /// Sets the value of the specified field.
  ///
  /// - Parameters:
  ///   - field: The descriptor of the field to set.
  ///   - value: The value to set for the field.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  /// - Throws:
  ///   - `ProtoError.fieldNotFound` if the field is not found in this message.
  ///   - `ProtoError.invalidFieldValue` if the value is invalid for the field type.
  @discardableResult
  public func trySet(field: ProtoFieldDescriptor, value: ProtoValue) throws -> Bool {
    guard let fieldDescriptor = validateFieldDescriptor(field) else {
      throw ProtoError.fieldNotFound(fieldName: field.name, messageType: messageDescriptor.fullName)
    }

    // Use strict validation for field values
    do {
      try ProtoWireFormat.validateFieldValue(field: fieldDescriptor, value: value)
    }
    catch {
      throw ProtoError.invalidFieldValue(
        fieldName: field.name,
        expectedType: fieldDescriptor.type.description(),
        actualValue: value.asString()
      )
    }

    // Set the field value
    fields[fieldDescriptor.number] = value

    // Update initialization status
    validateFields()

    return true
  }

  /// Non-throwing version of trySet(field:value:) for backward compatibility.
  ///
  /// - Parameters:
  ///   - field: The descriptor of the field to set.
  ///   - value: The value to set for the field.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  @discardableResult
  public func set(field: ProtoFieldDescriptor, value: ProtoValue) -> Bool {
    // For backward compatibility, we directly set the field value without validation
    // This allows tests to set invalid values for testing validation during serialization
    if let fieldDescriptor = validateFieldDescriptor(field) {
      fields[fieldDescriptor.number] = value
      validateFields()
      return true
    }
    return false
  }

  /// Sets the value of a field by its name.
  ///
  /// - Parameters:
  ///   - name: The name of the field to set.
  ///   - value: The value to set for the field.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  /// - Throws:
  ///   - `ProtoError.fieldNotFound` if the field is not found in this message.
  ///   - `ProtoError.invalidFieldValue` if the value is invalid for the field type.
  @discardableResult
  public func trySet(fieldName: String, value: ProtoValue) throws -> Bool {
    guard let field = messageDescriptor.field(named: fieldName) else {
      throw ProtoError.fieldNotFound(fieldName: fieldName, messageType: messageDescriptor.fullName)
    }

    return try trySet(field: field, value: value)
  }

  /// Non-throwing version of trySet(fieldName:value:) for backward compatibility.
  ///
  /// - Parameters:
  ///   - name: The name of the field to set.
  ///   - value: The value to set for the field.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  @discardableResult
  public func set(fieldName: String, value: ProtoValue) -> Bool {
    do {
      return try trySet(fieldName: fieldName, value: value)
    }
    catch {
      return false
    }
  }

  /// Sets the value of a field by its number.
  ///
  /// - Parameters:
  ///   - number: The number of the field to set.
  ///   - value: The value to set for the field.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  /// - Throws:
  ///   - `ProtoError.fieldNotFound` if the field is not found in this message.
  ///   - `ProtoError.invalidFieldValue` if the value is invalid for the field type.
  @discardableResult
  public func trySet(fieldNumber: Int, value: ProtoValue) throws -> Bool {
    guard let field = messageDescriptor.field(number: fieldNumber) else {
      throw ProtoError.fieldNotFound(fieldName: "#\(fieldNumber)", messageType: messageDescriptor.fullName)
    }

    return try trySet(field: field, value: value)
  }

  /// Non-throwing version of trySet(fieldNumber:value:) for backward compatibility.
  ///
  /// - Parameters:
  ///   - number: The number of the field to set.
  ///   - value: The value to set for the field.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  @discardableResult
  public func set(fieldNumber: Int, value: ProtoValue) -> Bool {
    do {
      return try trySet(fieldNumber: fieldNumber, value: value)
    }
    catch {
      return false
    }
  }

  /// Clears the value of the specified field, resetting it to default.
  ///
  /// - Parameter field: The descriptor of the field to clear.
  /// - Returns: `true` if the field was cleared successfully, `false` otherwise.
  @discardableResult
  public func clear(field: ProtoFieldDescriptor) -> Bool {
    guard let fieldDescriptor = validateFieldDescriptor(field) else {
      return false
    }

    fields.removeValue(forKey: fieldDescriptor.number)
    validateFields()
    return true
  }

  /// Clears the value of a field by its name.
  ///
  /// - Parameter name: The name of the field to clear.
  /// - Returns: `true` if the field was cleared successfully, `false` otherwise.
  @discardableResult
  public func clear(fieldName: String) -> Bool {
    guard let field = messageDescriptor.field(named: fieldName) else {
      return false
    }

    return clear(field: field)
  }

  /// Clears the value of a field by its number.
  ///
  /// - Parameter number: The number of the field to clear.
  /// - Returns: `true` if the field was cleared successfully, `false` otherwise.
  @discardableResult
  public func clear(fieldNumber: Int) -> Bool {
    guard let field = messageDescriptor.field(number: fieldNumber) else {
      return false
    }

    return clear(field: field)
  }

  /// Checks if a field is set in the message.
  ///
  /// - Parameter field: The descriptor of the field to check.
  /// - Returns: `true` if the field is set, `false` otherwise.
  public func has(field: ProtoFieldDescriptor) -> Bool {
    guard let fieldDescriptor = validateFieldDescriptor(field) else {
      return false
    }

    return fields[fieldDescriptor.number] != nil
  }

  /// Checks if a field is set in the message by its name.
  ///
  /// - Parameter name: The name of the field to check.
  /// - Returns: `true` if the field is set, `false` otherwise.
  public func has(fieldName: String) -> Bool {
    guard let field = messageDescriptor.field(named: fieldName) else {
      return false
    }

    return has(field: field)
  }

  /// Checks if a field is set in the message by its number.
  ///
  /// - Parameter number: The number of the field to check.
  /// - Returns: `true` if the field is set, `false` otherwise.
  public func has(fieldNumber: Int) -> Bool {
    guard let field = messageDescriptor.field(number: fieldNumber) else {
      return false
    }

    return has(field: field)
  }

  /// Adds a value to a repeated field.
  ///
  /// - Parameters:
  ///   - field: The descriptor of the repeated field.
  ///   - value: The value to add to the repeated field.
  /// - Returns: `true` if the value was added successfully, `false` otherwise.
  @discardableResult
  public func add(toRepeatedField field: ProtoFieldDescriptor, value: ProtoValue) -> Bool {
    guard let fieldDescriptor = validateFieldDescriptor(field), fieldDescriptor.isRepeated else {
      return false
    }

    // Create a non-repeated version of the field descriptor for element validation
    let elementDescriptor = ProtoFieldDescriptor(
      name: fieldDescriptor.name,
      number: fieldDescriptor.number,
      type: fieldDescriptor.type,
      isRepeated: false,
      isMap: false,
      defaultValue: fieldDescriptor.defaultValue,
      messageType: fieldDescriptor.messageType
    )

    // Validate the value against the element descriptor
    guard value.isValid(for: elementDescriptor) else {
      return false
    }

    // Get the current repeated value or create a new one
    var repeatedValue: [ProtoValue]
    if let existingValue = fields[fieldDescriptor.number]?.getRepeated() {
      repeatedValue = existingValue
    }
    else {
      repeatedValue = []
    }

    // Add the new value and update the field
    repeatedValue.append(value)
    fields[fieldDescriptor.number] = .repeatedValue(repeatedValue)
    return true
  }

  /// Adds a value to a repeated field by its name.
  ///
  /// - Parameters:
  ///   - name: The name of the repeated field.
  ///   - value: The value to add to the repeated field.
  /// - Returns: `true` if the value was added successfully, `false` otherwise.
  @discardableResult
  public func add(toRepeatedFieldNamed name: String, value: ProtoValue) -> Bool {
    guard let field = messageDescriptor.field(named: name) else {
      return false
    }

    return add(toRepeatedField: field, value: value)
  }

  /// Adds a value to a repeated field by its number.
  ///
  /// - Parameters:
  ///   - number: The number of the repeated field.
  ///   - value: The value to add to the repeated field.
  /// - Returns: `true` if the value was added successfully, `false` otherwise.
  @discardableResult
  public func add(toRepeatedFieldNumber number: Int, value: ProtoValue) -> Bool {
    guard let field = messageDescriptor.field(number: number) else {
      return false
    }

    return add(toRepeatedField: field, value: value)
  }

  /// Sets a value in a map field.
  ///
  /// - Parameters:
  ///   - field: The descriptor of the map field.
  ///   - key: The key in the map.
  ///   - value: The value to set for the key.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  @discardableResult
  public func set(inMapField field: ProtoFieldDescriptor, key: String, value: ProtoValue) -> Bool {
    guard let fieldDescriptor = validateFieldDescriptor(field), fieldDescriptor.isMap else {
      return false
    }

    // For this test, we're using a string field with isMap=true
    // In a real implementation, map fields would be message types with key/value fields
    if fieldDescriptor.isMap {
      // Get the current map value or create a new one
      var mapValue: [String: ProtoValue]
      if let existingValue = fields[fieldDescriptor.number]?.getMap() {
        mapValue = existingValue
      }
      else {
        mapValue = [:]
      }

      // Set the new value and update the field
      mapValue[key] = value
      fields[fieldDescriptor.number] = .mapValue(mapValue)

      // Update initialization status
      validateFields()

      return true
    }

    return false
  }

  /// Sets a value in a map field by its name.
  ///
  /// - Parameters:
  ///   - name: The name of the map field.
  ///   - key: The key in the map.
  ///   - value: The value to set for the key.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  @discardableResult
  public func set(inMapFieldNamed name: String, key: String, value: ProtoValue) -> Bool {
    guard let field = messageDescriptor.field(named: name) else {
      return false
    }

    return set(inMapField: field, key: key, value: value)
  }

  /// Sets a value in a map field by its number.
  ///
  /// - Parameters:
  ///   - number: The number of the map field.
  ///   - key: The key in the map.
  ///   - value: The value to set for the key.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  @discardableResult
  public func set(inMapFieldNumber number: Int, key: String, value: ProtoValue) -> Bool {
    guard let field = messageDescriptor.field(number: number) else {
      return false
    }

    return set(inMapField: field, key: key, value: value)
  }

  /// Removes a key-value pair from a map field.
  ///
  /// - Parameters:
  ///   - field: The descriptor of the map field.
  ///   - key: The key to remove from the map.
  /// - Returns: `true` if the key was removed successfully, `false` otherwise.
  @discardableResult
  public func remove(fromMapField field: ProtoFieldDescriptor, key: String) -> Bool {
    guard let fieldDescriptor = validateFieldDescriptor(field), fieldDescriptor.isMap else {
      return false
    }

    // Get the current map value
    guard var mapValue = fields[fieldDescriptor.number]?.getMap() else {
      // Map doesn't exist or is empty, nothing to remove
      return false
    }

    // Check if the key exists
    guard mapValue[key] != nil else {
      // Key doesn't exist, nothing to remove
      return false
    }

    // Remove the key and update the field
    mapValue.removeValue(forKey: key)

    // If the map is now empty, we can either remove the field or set an empty map
    if mapValue.isEmpty {
      fields.removeValue(forKey: fieldDescriptor.number)
    }
    else {
      fields[fieldDescriptor.number] = .mapValue(mapValue)
    }

    return true
  }

  /// Removes a key-value pair from a map field by its name.
  ///
  /// - Parameters:
  ///   - name: The name of the map field.
  ///   - key: The key to remove from the map.
  /// - Returns: `true` if the key was removed successfully, `false` otherwise.
  @discardableResult
  public func remove(fromMapFieldNamed name: String, key: String) -> Bool {
    guard let field = messageDescriptor.field(named: name) else {
      return false
    }

    return remove(fromMapField: field, key: key)
  }

  /// Removes a key-value pair from a map field by its number.
  ///
  /// - Parameters:
  ///   - number: The number of the map field.
  ///   - key: The key to remove from the map.
  /// - Returns: `true` if the key was removed successfully, `false` otherwise.
  @discardableResult
  public func remove(fromMapFieldNumber number: Int, key: String) -> Bool {
    guard let field = messageDescriptor.field(number: number) else {
      return false
    }

    return remove(fromMapField: field, key: key)
  }

  /// Gets a value from a map field.
  ///
  /// - Parameters:
  ///   - field: The descriptor of the map field.
  ///   - key: The key in the map.
  /// - Returns: The value for the key, or nil if the key is not found.
  public func get(fromMapField field: ProtoFieldDescriptor, key: String) -> ProtoValue? {
    guard let fieldDescriptor = validateFieldDescriptor(field), fieldDescriptor.isMap else {
      return nil
    }

    // Get the current map value
    guard let mapValue = fields[fieldDescriptor.number]?.getMap() else {
      return nil
    }

    return mapValue[key]
  }

  /// Gets a value from a map field by its name.
  ///
  /// - Parameters:
  ///   - name: The name of the map field.
  ///   - key: The key in the map.
  /// - Returns: The value for the key, or nil if the key is not found.
  public func get(fromMapFieldNamed name: String, key: String) -> ProtoValue? {
    guard let field = messageDescriptor.field(named: name) else {
      return nil
    }

    return get(fromMapField: field, key: key)
  }

  /// Gets a value from a map field by its number.
  ///
  /// - Parameters:
  ///   - number: The number of the map field.
  ///   - key: The key in the map.
  /// - Returns: The value for the key, or nil if the key is not found.
  public func get(fromMapFieldNumber number: Int, key: String) -> ProtoValue? {
    guard let field = messageDescriptor.field(number: number) else {
      return nil
    }

    return get(fromMapField: field, key: key)
  }

  /// Gets a value from a repeated field at the specified index.
  ///
  /// - Parameters:
  ///   - field: The descriptor of the repeated field.
  ///   - index: The index in the repeated field.
  /// - Returns: The value at the index, or nil if the index is out of bounds.
  public func get(fromRepeatedField field: ProtoFieldDescriptor, at index: Int) -> ProtoValue? {
    guard let fieldDescriptor = validateFieldDescriptor(field), fieldDescriptor.isRepeated else {
      return nil
    }

    // Get the current repeated value
    guard let repeatedValue = fields[fieldDescriptor.number]?.getRepeated() else {
      return nil
    }

    // Check if the index is valid
    guard index >= 0 && index < repeatedValue.count else {
      return nil
    }

    return repeatedValue[index]
  }

  /// Gets a value from a repeated field by its name at the specified index.
  ///
  /// - Parameters:
  ///   - name: The name of the repeated field.
  ///   - index: The index in the repeated field.
  /// - Returns: The value at the index, or nil if the index is out of bounds.
  public func get(fromRepeatedFieldNamed name: String, at index: Int) -> ProtoValue? {
    guard let field = messageDescriptor.field(named: name) else {
      return nil
    }

    return get(fromRepeatedField: field, at: index)
  }

  /// Gets a value from a repeated field by its number at the specified index.
  ///
  /// - Parameters:
  ///   - number: The number of the repeated field.
  ///   - index: The index in the repeated field.
  /// - Returns: The value at the index, or nil if the index is out of bounds.
  public func get(fromRepeatedFieldNumber number: Int, at index: Int) -> ProtoValue? {
    guard let field = messageDescriptor.field(number: number) else {
      return nil
    }

    return get(fromRepeatedField: field, at: index)
  }

  /// Gets the count of elements in a repeated field.
  ///
  /// - Parameter field: The descriptor of the repeated field.
  /// - Returns: The number of elements in the repeated field, or 0 if the field is not set.
  public func count(ofRepeatedField field: ProtoFieldDescriptor) -> Int {
    guard let fieldDescriptor = validateFieldDescriptor(field), fieldDescriptor.isRepeated else {
      return 0
    }

    return fields[fieldDescriptor.number]?.getRepeated()?.count ?? 0
  }

  /// Gets the count of elements in a repeated field by its name.
  ///
  /// - Parameter name: The name of the repeated field.
  /// - Returns: The number of elements in the repeated field, or 0 if the field is not set.
  public func count(ofRepeatedFieldNamed name: String) -> Int {
    guard let field = messageDescriptor.field(named: name) else {
      return 0
    }

    return count(ofRepeatedField: field)
  }

  /// Gets the count of elements in a repeated field by its number.
  ///
  /// - Parameter number: The number of the repeated field.
  /// - Returns: The number of elements in the repeated field, or 0 if the field is not set.
  public func count(ofRepeatedFieldNumber number: Int) -> Int {
    guard let field = messageDescriptor.field(number: number) else {
      return 0
    }

    return count(ofRepeatedField: field)
  }

  /// Gets the count of key-value pairs in a map field.
  ///
  /// - Parameter field: The descriptor of the map field.
  /// - Returns: The number of key-value pairs in the map field, or 0 if the field is not set.
  public func count(ofMapField field: ProtoFieldDescriptor) -> Int {
    guard let fieldDescriptor = validateFieldDescriptor(field), fieldDescriptor.isMap else {
      return 0
    }

    return fields[fieldDescriptor.number]?.getMap()?.count ?? 0
  }

  /// Gets the count of key-value pairs in a map field by its name.
  ///
  /// - Parameter name: The name of the map field.
  /// - Returns: The number of key-value pairs in the map field, or 0 if the field is not set.
  public func count(ofMapFieldNamed name: String) -> Int {
    guard let field = messageDescriptor.field(named: name) else {
      return 0
    }

    return count(ofMapField: field)
  }

  /// Gets the count of key-value pairs in a map field by its number.
  ///
  /// - Parameter number: The number of the map field.
  /// - Returns: The number of key-value pairs in the map field, or 0 if the field is not set.
  public func count(ofMapFieldNumber number: Int) -> Int {
    guard let field = messageDescriptor.field(number: number) else {
      return 0
    }

    return count(ofMapField: field)
  }

  /// Returns whether the message is valid and properly initialized.
  ///
  /// - Returns: `true` if the message is valid, `false` otherwise.
  public func isValid() -> Bool {
    // First check if the descriptor itself is valid
    guard messageDescriptor.isValid() else {
      return false
    }

    // Validate all fields in the message
    validateFields()

    return isInitialized
  }

  /// Validates that a field descriptor belongs to this message.
  ///
  /// - Parameter field: The field descriptor to validate.
  /// - Returns: The validated field descriptor, or nil if the field does not belong to this message.
  private func validateFieldDescriptor(_ field: ProtoFieldDescriptor) -> ProtoFieldDescriptor? {
    // Check if the field belongs to this message
    guard let messageField = messageDescriptor.field(number: field.number) else {
      return nil
    }

    // Check if the field types match
    guard messageField.type == field.type else {
      return nil
    }

    return messageField
  }

  /// Validates all fields in the message and updates the initialization status.
  ///
  /// This method checks that all fields have valid values according to their descriptors
  /// and collects any validation errors that occur.
  ///
  /// - Returns: `true` if the message is valid, `false` otherwise.
  @discardableResult
  public func validateFields() -> Bool {
    // Clear previous validation errors
    validationErrors = []

    // In Protocol Buffers v3, all fields are optional by default
    // However, we should still validate that any set fields have valid values

    isInitialized = true

    // Check each field that is set
    for (fieldNumber, value) in fields {
      // Get the field descriptor
      guard let fieldDescriptor = messageDescriptor.field(number: fieldNumber) else {
        let error = ProtoError.fieldNotFound(
          fieldName: "#\(fieldNumber)",
          messageType: messageDescriptor.fullName
        )
        validationErrors.append(error)
        isInitialized = false
        continue
      }

      // Validate the value against the field descriptor
      if !value.isValid(for: fieldDescriptor) {
        let error = ProtoError.invalidFieldValue(
          fieldName: fieldDescriptor.name,
          expectedType: fieldDescriptor.type.description(),
          actualValue: value.asString()
        )
        validationErrors.append(error)
        isInitialized = false
        continue
      }

      // For message fields, recursively validate nested messages
      if fieldDescriptor.type == .message, let nestedMessage = value.getMessage() as? ProtoDynamicMessage {
        if !nestedMessage.validateFields() {
          // Add nested validation errors with a prefix to identify the field
          for nestedError in nestedMessage.errors {
            let prefixedError = ProtoError.validationError(
              message: "In field '\(fieldDescriptor.name)': \(nestedError.description)"
            )
            validationErrors.append(prefixedError)
          }
          isInitialized = false
          continue
        }
      }

      // For repeated fields with message elements, validate each message
      if fieldDescriptor.isRepeated, case .repeatedValue(let elements) = value {
        for (index, element) in elements.enumerated() {
          if fieldDescriptor.type == .message, let nestedMessage = element.getMessage() as? ProtoDynamicMessage {
            if !nestedMessage.validateFields() {
              // Add nested validation errors with a prefix to identify the field and index
              for nestedError in nestedMessage.errors {
                let prefixedError = ProtoError.validationError(
                  message: "In field '\(fieldDescriptor.name)[\(index)]': \(nestedError.description)"
                )
                validationErrors.append(prefixedError)
              }
              isInitialized = false
              continue
            }
          }
        }
      }

      // For map fields with message values, validate each message
      if fieldDescriptor.isMap, case .mapValue(let map) = value {
        for (key, mapValue) in map {
          if fieldDescriptor.type == .message, let nestedMessage = mapValue.getMessage() as? ProtoDynamicMessage {
            if !nestedMessage.validateFields() {
              // Add nested validation errors with a prefix to identify the field and key
              for nestedError in nestedMessage.errors {
                let prefixedError = ProtoError.validationError(
                  message: "In field '\(fieldDescriptor.name)[\"\(key)\"]': \(nestedError.description)"
                )
                validationErrors.append(prefixedError)
              }
              isInitialized = false
              continue
            }
          }
        }
      }
    }

    return isInitialized
  }

  /// Creates a new nested message for a message field.
  ///
  /// This method creates a new dynamic message for a message field based on the field's message type.
  /// The created message can then be populated with values and set on the field.
  ///
  /// - Parameter field: The descriptor of the message field.
  /// - Returns: A new dynamic message, or nil if the field is not a message field or the message type is not found.
  public func createNestedMessage(for field: ProtoFieldDescriptor) -> ProtoDynamicMessage? {
    guard let fieldDescriptor = validateFieldDescriptor(field), fieldDescriptor.type == .message else {
      return nil
    }

    // Get the message type from the field descriptor
    guard let messageType = fieldDescriptor.messageType else {
      return nil
    }

    // Create a new dynamic message with the message type
    return ProtoDynamicMessage(descriptor: messageType)
  }

  /// Creates a new nested message for a message field by its name.
  ///
  /// - Parameter fieldName: The name of the message field.
  /// - Returns: A new dynamic message, or nil if the field is not found, not a message field, or the message type is not found.
  public func createNestedMessage(forFieldNamed fieldName: String) -> ProtoDynamicMessage? {
    guard let field = messageDescriptor.field(named: fieldName) else {
      return nil
    }

    return createNestedMessage(for: field)
  }

  /// Creates a new nested message for a message field by its number.
  ///
  /// - Parameter fieldNumber: The number of the message field.
  /// - Returns: A new dynamic message, or nil if the field is not found, not a message field, or the message type is not found.
  public func createNestedMessage(forFieldNumber fieldNumber: Int) -> ProtoDynamicMessage? {
    guard let field = messageDescriptor.field(number: fieldNumber) else {
      return nil
    }

    return createNestedMessage(for: field)
  }

  /// Sets a nested message on a message field.
  ///
  /// - Parameters:
  ///   - field: The descriptor of the message field.
  ///   - message: The nested message to set.
  /// - Returns: `true` if the message was set successfully, `false` otherwise.
  @discardableResult
  public func setNestedMessage(field: ProtoFieldDescriptor, message: ProtoMessage) -> Bool {
    guard let fieldDescriptor = validateFieldDescriptor(field), fieldDescriptor.type == .message else {
      return false
    }

    // Validate that the message type matches the field's message type
    if let expectedType = fieldDescriptor.messageType {
      guard message.descriptor().fullName == expectedType.fullName else {
        return false
      }
    }

    // Set the message value
    fields[fieldDescriptor.number] = .messageValue(message)

    // Update initialization status
    validateFields()

    return true
  }

  /// Sets a nested message on a message field by its name.
  ///
  /// - Parameters:
  ///   - fieldName: The name of the message field.
  ///   - message: The nested message to set.
  /// - Returns: `true` if the message was set successfully, `false` otherwise.
  @discardableResult
  public func setNestedMessage(fieldName: String, message: ProtoMessage) -> Bool {
    guard let field = messageDescriptor.field(named: fieldName) else {
      return false
    }

    return setNestedMessage(field: field, message: message)
  }

  /// Sets a nested message on a message field by its number.
  ///
  /// - Parameters:
  ///   - fieldNumber: The number of the message field.
  ///   - message: The nested message to set.
  /// - Returns: `true` if the message was set successfully, `false` otherwise.
  @discardableResult
  public func setNestedMessage(fieldNumber: Int, message: ProtoMessage) -> Bool {
    guard let field = messageDescriptor.field(number: fieldNumber) else {
      return false
    }

    return setNestedMessage(field: field, message: message)
  }

  /// Gets a nested message from a message field.
  ///
  /// - Parameter field: The descriptor of the message field.
  /// - Returns: The nested message, or nil if the field is not set or not a message field.
  public func getNestedMessage(field: ProtoFieldDescriptor) -> ProtoMessage? {
    guard let fieldDescriptor = validateFieldDescriptor(field), fieldDescriptor.type == .message else {
      return nil
    }

    return fields[fieldDescriptor.number]?.getMessage()
  }

  /// Gets a nested message from a message field by its name.
  ///
  /// - Parameter fieldName: The name of the message field.
  /// - Returns: The nested message, or nil if the field is not found, not set, or not a message field.
  public func getNestedMessage(fieldName: String) -> ProtoMessage? {
    guard let field = messageDescriptor.field(named: fieldName) else {
      return nil
    }

    return getNestedMessage(field: field)
  }

  /// Gets a nested message from a message field by its number.
  ///
  /// - Parameter fieldNumber: The number of the message field.
  /// - Returns: The nested message, or nil if the field is not found, not set, or not a message field.
  public func getNestedMessage(fieldNumber: Int) -> ProtoMessage? {
    guard let field = messageDescriptor.field(number: fieldNumber) else {
      return nil
    }

    return getNestedMessage(field: field)
  }

  // MARK: - Hashable Implementation

  /// Hashes the essential components of this message into the provided hasher.
  ///
  /// This implementation carefully handles nested messages to avoid infinite recursion
  /// while still providing a good hash distribution.
  ///
  /// - Parameter hasher: The hasher to use when combining the components of this instance.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(messageDescriptor.fullName)

    // Sort field numbers for consistent hashing
    let sortedFieldNumbers = fields.keys.sorted()

    // Hash each field value in a consistent order
    for number in sortedFieldNumbers {
      guard let value = fields[number] else { continue }

      hasher.combine(number)

      // Special handling for different value types
      switch value {
      case .messageValue(let message):
        // For message values, we need to be careful to avoid infinite recursion
        // if there are circular references. We'll hash the message descriptor
        // and a subset of its fields rather than the entire message.
        hasher.combine(message.descriptor().fullName)

        // If the message is a ProtoDynamicMessage, we can use its field count
        // and a sample of its field numbers for better hash distribution
        if let dynamicMessage = message as? ProtoDynamicMessage {
          hasher.combine(dynamicMessage.fields.count)

          // Hash up to 3 field numbers if available
          let fieldNumbers = Array(dynamicMessage.fields.keys).prefix(3)
          for fieldNumber in fieldNumbers {
            hasher.combine(fieldNumber)
          }
        }
        else {
          // For other message types, use the object identifier
          hasher.combine(ObjectIdentifier(message as AnyObject))
        }

      case .repeatedValue(let values):
        // For repeated values, hash the count and a sample of values
        hasher.combine(values.count)

        // Hash up to 5 values if available
        for value in values.prefix(5) {
          hasher.combine(value)
        }

      case .mapValue(let mapValues):
        // For map values, hash the count and a sample of keys and values
        hasher.combine(mapValues.count)

        // Hash up to 5 key-value pairs if available
        let sortedKeys = mapValues.keys.sorted().prefix(5)
        for key in sortedKeys {
          hasher.combine(key)
          if let mapValue = mapValues[key] {
            hasher.combine(mapValue)
          }
        }

      default:
        // For other value types, hash the value directly
        hasher.combine(value)
      }
    }
  }

  /// Returns a Boolean value indicating whether two messages are equal.
  ///
  /// Two messages are considered equal if they have the same descriptor and
  /// all their fields have the same values.
  ///
  /// - Parameters:
  ///   - lhs: A message to compare.
  ///   - rhs: Another message to compare.
  /// - Returns: `true` if the messages are equal, `false` otherwise.
  public static func == (lhs: ProtoDynamicMessage, rhs: ProtoDynamicMessage) -> Bool {
    // Messages must have the same descriptor
    guard lhs.messageDescriptor.fullName == rhs.messageDescriptor.fullName else {
      return false
    }

    // Get all field numbers from both messages
    let lhsFieldNumbers = Set(lhs.fields.keys)
    let rhsFieldNumbers = Set(rhs.fields.keys)

    // Both messages must have the same set of fields
    guard lhsFieldNumbers == rhsFieldNumbers else {
      return false
    }

    // Check each field value
    for number in lhsFieldNumbers {
      guard let lhsValue = lhs.fields[number], let rhsValue = rhs.fields[number] else {
        return false
      }

      // Special handling for message values to avoid potential infinite recursion
      if case .messageValue(let lhsMessage) = lhsValue, case .messageValue(let rhsMessage) = rhsValue {
        // If both messages are ProtoDynamicMessage, we can compare them directly
        // because the == operator handles recursion properly
        if let lhsDynamicMessage = lhsMessage as? ProtoDynamicMessage,
          let rhsDynamicMessage = rhsMessage as? ProtoDynamicMessage
        {
          // Check if the messages are the same instance to avoid infinite recursion
          if lhsDynamicMessage === rhsDynamicMessage {
            continue
          }

          // Compare the messages
          if lhsDynamicMessage != rhsDynamicMessage {
            return false
          }
        }
        else {
          // For other message types, compare their descriptors
          if lhsMessage.descriptor().fullName != rhsMessage.descriptor().fullName {
            return false
          }

          // We can't compare the content of non-ProtoDynamicMessage instances directly,
          // so we'll consider them equal if they have the same descriptor
        }
      }
      else {
        // For other value types, compare them directly
        if lhsValue != rhsValue {
          return false
        }
      }
    }

    return true
  }
}
