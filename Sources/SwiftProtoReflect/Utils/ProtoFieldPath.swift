import Foundation

/// A utility for accessing fields in dynamic messages using path notation.
///
/// `ProtoFieldPath` allows for accessing nested fields in Protocol Buffer messages
/// using a path notation, such as "person.address.street". It also supports accessing
/// elements in repeated fields using index notation (e.g., "people[0].name") and
/// elements in map fields using key notation (e.g., "attributes['key']").
///
/// # Examples
///
/// ## Basic Field Access
/// ```swift
/// // Create a field path for a simple field
/// let namePath = ProtoFieldPath(path: "name")
///
/// // Get the value
/// let nameValue = namePath.getValue(from: personMessage)
///
/// // Set a value
/// namePath.setValue(.stringValue("Jane Doe"), in: personMessage)
///
/// // Clear a value
/// namePath.clearValue(in: personMessage)
///
/// // Check if a field is set
/// let hasName = namePath.hasValue(in: personMessage)
/// ```
///
/// ## Nested Field Access
/// ```swift
/// // Create a field path for a nested field
/// let streetPath = ProtoFieldPath(path: "address.street")
///
/// // Get the nested value
/// let streetValue = streetPath.getValue(from: personMessage)
///
/// // Set a nested value
/// streetPath.setValue(.stringValue("456 Oak Ave"), in: personMessage)
///
/// // Clear a nested value
/// streetPath.clearValue(in: personMessage)
///
/// // Check if a nested field is set
/// let hasStreet = streetPath.hasValue(in: personMessage)
///
/// // Multiple levels of nesting
/// let deepPath = ProtoFieldPath(path: "company.address.zipCode")
/// let zipValue = deepPath.getValue(from: personMessage)
/// ```
///
/// ## Repeated Field Access
/// ```swift
/// // Access an element in a repeated field by index
/// let firstPhonePath = ProtoFieldPath(path: "phoneNumbers[0]")
/// let firstPhone = firstPhonePath.getValue(from: personMessage)
///
/// // Set a value in a repeated field
/// firstPhonePath.setValue(.stringValue("555-9876"), in: personMessage)
///
/// // Access a nested field within a repeated element
/// let contactNamePath = ProtoFieldPath(path: "contacts[2].name")
/// let contactName = contactNamePath.getValue(from: personMessage)
///
/// // Clear a value in a repeated field
/// firstPhonePath.clearValue(in: personMessage)
/// ```
///
/// ## Map Field Access
/// ```swift
/// // Access an element in a map field by key
/// let heightPath = ProtoFieldPath(path: "attributes['height']")
/// let height = heightPath.getValue(from: personMessage)
///
/// // Alternative syntax with double quotes
/// let weightPath = ProtoFieldPath(path: "attributes[\"weight\"]")
/// let weight = weightPath.getValue(from: personMessage)
///
/// // Set a value in a map field
/// heightPath.setValue(.stringValue("185cm"), in: personMessage)
///
/// // Access a nested field within a map value (if the map value is a message)
/// let settingValuePath = ProtoFieldPath(path: "settings['display'].value")
/// let settingValue = settingValuePath.getValue(from: personMessage)
///
/// // Clear a value in a map field
/// heightPath.clearValue(in: personMessage)
/// ```
///
/// ## Complex Path Examples
/// ```swift
/// // Combining repeated and nested access
/// let friendCityPath = ProtoFieldPath(path: "friends[0].address.city")
/// let friendCity = friendCityPath.getValue(from: personMessage)
///
/// // Combining map and nested access
/// let configValuePath = ProtoFieldPath(path: "configs['network'].settings.timeout")
/// let configValue = configValuePath.getValue(from: personMessage)
///
/// // Combining map and repeated access
/// let tagPath = ProtoFieldPath(path: "categories['work'].tags[0]")
/// let tag = tagPath.getValue(from: personMessage)
/// ```
public class ProtoFieldPath {
  /// Represents a component in a field path.
  private enum PathComponent {
    /// A simple field name.
    case field(String)

    /// A repeated field access with an index.
    case repeatedField(name: String, index: Int)

    /// A map field access with a key.
    case mapField(name: String, key: String)

    /// Creates a path component from a string.
    ///
    /// - Parameter string: The string representation of the path component.
    /// - Returns: A path component, or nil if the string is invalid.
    static func from(string: String) -> PathComponent? {
      // Check for repeated field access: fieldName[index]
      if let repeatedMatch = string.range(of: #"^([^\[\]]+)\[(\d+)\]$"#, options: .regularExpression) {
        _ = string[repeatedMatch]
        let components = string.split(separator: "[")
        guard components.count == 2 else { return nil }

        let fieldName = String(components[0])
        let indexString = components[1].dropLast()

        guard let index = Int(indexString) else { return nil }
        return .repeatedField(name: fieldName, index: index)
      }

      // Check for map field access: fieldName['key'] or fieldName["key"]
      if let mapMatch = string.range(of: #"^([^\[\]]+)\[['"](.+)['"]\]$"#, options: .regularExpression) {
        _ = string[mapMatch]

        // Extract field name and key
        let startIndex = string.startIndex
        let openBracketIndex = string.firstIndex(of: "[")!
        let fieldName = String(string[startIndex..<openBracketIndex])

        // Extract the key (remove quotes)
        let keyStartIndex = string.index(after: string.firstIndex(of: "'") ?? string.firstIndex(of: "\"")!)
        let keyEndIndex = string.lastIndex(of: "'") ?? string.lastIndex(of: "\"")!
        let key = String(string[keyStartIndex..<keyEndIndex])

        return .mapField(name: fieldName, key: key)
      }

      // Simple field name
      return .field(string)
    }
  }

  /// The components of the field path.
  private let components: [PathComponent]

  /// Creates a new field path from a dot-separated path string.
  ///
  /// The path string can include:
  /// - Simple field names: "person.name"
  /// - Repeated field access: "people[0].name"
  /// - Map field access: "attributes['key']" or "attributes[\"key\"]"
  ///
  /// - Parameter path: A dot-separated path string.
  public init(path: String) {
    // Split the path by dots, but preserve dots inside quotes and brackets
    var components: [PathComponent] = []
    var currentComponent = ""
    var insideQuotes = false
    var insideBrackets = 0

    for char in path {
      if char == "." && !insideQuotes && insideBrackets == 0 {
        if !currentComponent.isEmpty {
          if let component = PathComponent.from(string: currentComponent) {
            components.append(component)
          }
          currentComponent = ""
        }
      }
      else {
        currentComponent.append(char)

        if char == "'" || char == "\"" {
          insideQuotes = !insideQuotes
        }
        else if char == "[" {
          insideBrackets += 1
        }
        else if char == "]" {
          insideBrackets -= 1
        }
      }
    }

    if !currentComponent.isEmpty {
      if let component = PathComponent.from(string: currentComponent) {
        components.append(component)
      }
    }

    self.components = components
  }

  /// Gets the value at the specified path in the message.
  ///
  /// - Parameter message: The message to get the value from.
  /// - Returns: The value at the path, or nil if the path is invalid.
  public func getValue(from message: ProtoMessage) -> ProtoValue? {
    return getValueRecursive(from: message, components: components, index: 0)
  }

  /// Sets a value at the specified path in a message.
  ///
  /// - Parameters:
  ///   - value: The value to set.
  ///   - message: The message to modify.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  @discardableResult
  public func setValue(_ value: ProtoValue, in message: ProtoMessage) -> Bool {
    return setValueRecursive(value, in: message, components: components, index: 0)
  }

  /// Clears a value at the specified path in a message.
  ///
  /// - Parameter message: The message to modify.
  /// - Returns: `true` if the value was cleared successfully, `false` otherwise.
  @discardableResult
  public func clearValue(in message: ProtoMessage) -> Bool {
    return clearValueRecursive(in: message, components: components, index: 0)
  }

  /// Checks if a value exists at the specified path in a message.
  ///
  /// - Parameter message: The message to check.
  /// - Returns: `true` if a value exists at the path, `false` otherwise.
  public func hasValue(in message: ProtoMessage) -> Bool {
    guard let dynamicMessage = message as? ProtoDynamicMessage else {
      return false
    }

    return hasValueRecursive(in: dynamicMessage, components: components, index: 0)
  }

  /// Recursively checks if a value exists in a message using path components.
  ///
  /// - Parameters:
  ///   - message: The message to check.
  ///   - components: The path components.
  ///   - index: The current component index.
  /// - Returns: `true` if a value exists at the path, `false` otherwise.
  private func hasValueRecursive(in message: ProtoDynamicMessage, components: [PathComponent], index: Int) -> Bool {
    guard index < components.count else {
      return false
    }

    let component = components[index]

    switch component {
    case .field(let fieldName):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return false
      }

      // If this is the last component, check if the field is set
      if index == components.count - 1 {
        return message.has(field: field)
      }

      // Otherwise, get the field value and continue recursively
      guard let fieldValue = message.get(field: field) else {
        return false
      }

      // If the field exists, it must be a message to continue
      if case .messageValue(let nestedMessage) = fieldValue,
        let dynamicMessage = nestedMessage as? ProtoDynamicMessage
      {
        return hasValueRecursive(in: dynamicMessage, components: components, index: index + 1)
      }

      return false

    case .repeatedField(let fieldName, let arrayIndex):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return false
      }

      // Get the repeated field value
      guard let fieldValue = message.get(field: field),
        case .repeatedValue(let array) = fieldValue
      else {
        return false
      }

      // Check if the index is valid
      guard arrayIndex >= 0 && arrayIndex < array.count else {
        return false
      }

      // If this is the last component, the value exists
      if index == components.count - 1 {
        return true
      }

      // Otherwise, get the element and continue recursively
      let element = array[arrayIndex]

      // The element must be a message to continue
      if case .messageValue(let nestedMessage) = element,
        let dynamicMessage = nestedMessage as? ProtoDynamicMessage
      {
        return hasValueRecursive(in: dynamicMessage, components: components, index: index + 1)
      }

      return false

    case .mapField(let fieldName, let mapKey):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return false
      }

      // Get the map field value
      guard let fieldValue = message.get(field: field),
        case .mapValue(let map) = fieldValue
      else {
        return false
      }

      // Check if the key exists
      guard let mapValue = map[mapKey] else {
        return false
      }

      // If this is the last component, the value exists
      if index == components.count - 1 {
        return true
      }

      // Otherwise, get the value and continue recursively
      // The value must be a message to continue
      if case .messageValue(let nestedMessage) = mapValue,
        let dynamicMessage = nestedMessage as? ProtoDynamicMessage
      {
        return hasValueRecursive(in: dynamicMessage, components: components, index: index + 1)
      }

      return false
    }
  }

  /// Recursively gets a value from a message using path components.
  ///
  /// - Parameters:
  ///   - message: The message to get the value from.
  ///   - components: The path components.
  ///   - index: The current component index.
  /// - Returns: The value at the path, or nil if the path is invalid.
  private func getValueRecursive(from message: ProtoMessage, components: [PathComponent], index: Int) -> ProtoValue? {
    guard index < components.count else {
      return nil
    }

    let component = components[index]

    switch component {
    case .field(let fieldName):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return nil
      }

      // Get the field value
      guard let fieldValue = message.get(field: field) else {
        return nil
      }

      // If this is the last component, return the value
      if index == components.count - 1 {
        return fieldValue
      }

      // Otherwise, continue recursively
      if case .messageValue(let nestedMessage) = fieldValue {
        return getValueRecursive(from: nestedMessage, components: components, index: index + 1)
      }

      return nil

    case .repeatedField(let fieldName, let arrayIndex):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return nil
      }

      // Get the repeated field value
      guard let fieldValue = message.get(field: field),
        case .repeatedValue(let array) = fieldValue
      else {
        return nil
      }

      // Check if the index is valid
      guard arrayIndex >= 0 && arrayIndex < array.count else {
        return nil
      }

      let element = array[arrayIndex]

      // If this is the last component, return the element
      if index == components.count - 1 {
        return element
      }

      // Otherwise, continue recursively if the element is a message
      if case .messageValue(let nestedMessage) = element {
        return getValueRecursive(from: nestedMessage, components: components, index: index + 1)
      }

      return nil

    case .mapField(let fieldName, let mapKey):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return nil
      }

      // Get the map field value
      guard let fieldValue = message.get(field: field),
        case .mapValue(let map) = fieldValue
      else {
        return nil
      }

      // Check if the key exists
      guard let mapValue = map[mapKey] else {
        return nil
      }

      // If this is the last component, return the map value
      if index == components.count - 1 {
        return mapValue
      }

      // Otherwise, continue recursively if the map value is a message
      if case .messageValue(let nestedMessage) = mapValue {
        return getValueRecursive(from: nestedMessage, components: components, index: index + 1)
      }

      return nil
    }
  }

  /// Recursively sets a value in a message using path components.
  ///
  /// - Parameters:
  ///   - value: The value to set.
  ///   - message: The message to modify.
  ///   - components: The path components.
  ///   - index: The current component index.
  /// - Returns: `true` if the value was set successfully, `false` otherwise.
  private func setValueRecursive(_ value: ProtoValue, in message: ProtoMessage, components: [PathComponent], index: Int)
    -> Bool
  {
    guard index < components.count else {
      return false
    }

    let component = components[index]

    // If this is the last component, set the value directly
    if index == components.count - 1 {
      switch component {
      case .field(let fieldName):
        guard let field = message.descriptor().field(named: fieldName) else {
          return false
        }
        return message.set(field: field, value: value)

      case .repeatedField(let fieldName, let arrayIndex):
        // Get the field descriptor
        guard let field = message.descriptor().field(named: fieldName) else {
          return false
        }

        // Get the repeated field value
        guard let fieldValue = message.get(field: field),
          case .repeatedValue(var array) = fieldValue
        else {
          return false
        }

        // Check if the index is valid
        guard arrayIndex >= 0 && arrayIndex < array.count else {
          return false
        }

        // Update the element
        array[arrayIndex] = value

        // Set the updated array back to the field
        return message.set(field: field, value: ProtoValue.repeatedValue(array))

      case .mapField(let fieldName, let mapKey):
        // Get the field descriptor
        guard let field = message.descriptor().field(named: fieldName) else {
          return false
        }

        // Get the map field value
        guard let fieldValue = message.get(field: field),
          case .mapValue(var map) = fieldValue
        else {
          return false
        }

        // Update the map
        map[mapKey] = value

        // Set the updated map back to the field
        return message.set(field: field, value: ProtoValue.mapValue(map))
      }
    }

    // Otherwise, we need to navigate to the next component
    switch component {
    case .field(let fieldName):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return false
      }

      // Get the field value
      guard let fieldValue = message.get(field: field) else {
        // If the field doesn't exist and it should be a message, create it
        if let dynamicMessage = message as? ProtoDynamicMessage,
          case .message = field.type,
          field.messageType != nil,
          let nestedMessage = dynamicMessage.createNestedMessage(for: field)
        {

          // Set the new message on the field
          dynamicMessage.setNestedMessage(field: field, message: nestedMessage)

          // Continue recursively with the new message
          return setValueRecursive(value, in: nestedMessage, components: components, index: index + 1)
        }

        return false
      }

      // If the field exists, it must be a message to continue
      if case .messageValue(let nestedMessage) = fieldValue {
        return setValueRecursive(value, in: nestedMessage, components: components, index: index + 1)
      }

      return false

    case .repeatedField(let fieldName, let arrayIndex):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return false
      }

      // Get the repeated field value
      guard let fieldValue = message.get(field: field),
        case .repeatedValue(let array) = fieldValue
      else {
        return false
      }

      // Check if the index is valid
      guard arrayIndex >= 0 && arrayIndex < array.count else {
        return false
      }

      let element = array[arrayIndex]

      // The element must be a message to continue
      if case .messageValue(let nestedMessage) = element {
        // Continue recursively with the nested message
        if setValueRecursive(value, in: nestedMessage, components: components, index: index + 1) {
          // The nested message was updated, but we need to update the array as well
          var updatedArray = array
          updatedArray[arrayIndex] = ProtoValue.messageValue(nestedMessage)

          // Set the updated array back to the field
          return message.set(field: field, value: ProtoValue.repeatedValue(updatedArray))
        }
      }

      return false

    case .mapField(let fieldName, let mapKey):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return false
      }

      // Get the map field value
      guard let fieldValue = message.get(field: field),
        case .mapValue(let map) = fieldValue
      else {
        return false
      }

      // Check if the key exists
      guard let mapValue = map[mapKey] else {
        return false
      }

      // The value must be a message to continue
      if case .messageValue(let nestedMessage) = mapValue {
        // Continue recursively with the nested message
        if setValueRecursive(value, in: nestedMessage, components: components, index: index + 1) {
          // The nested message was updated, but we need to update the map as well
          var updatedMap = map
          updatedMap[mapKey] = ProtoValue.messageValue(nestedMessage)

          // Set the updated map back to the field
          return message.set(field: field, value: ProtoValue.mapValue(updatedMap))
        }
      }

      return false
    }
  }

  /// Recursively clears a value in a message using path components.
  ///
  /// - Parameters:
  ///   - message: The message to modify.
  ///   - components: The path components.
  ///   - index: The current component index.
  /// - Returns: `true` if the value was cleared successfully, `false` otherwise.
  private func clearValueRecursive(in message: ProtoMessage, components: [PathComponent], index: Int) -> Bool {
    guard index < components.count else {
      return false
    }

    let component = components[index]

    // If this is the last component, clear the value directly
    if index == components.count - 1 {
      switch component {
      case .field(let fieldName):
        guard let field = message.descriptor().field(named: fieldName) else {
          return false
        }
        return message.clear(field: field)

      case .repeatedField(let fieldName, let arrayIndex):
        // Get the field descriptor
        guard let field = message.descriptor().field(named: fieldName) else {
          return false
        }

        // Get the repeated field value
        guard let fieldValue = message.get(field: field),
          case .repeatedValue(var array) = fieldValue
        else {
          return false
        }

        // Check if the index is valid
        guard arrayIndex >= 0 && arrayIndex < array.count else {
          return false
        }

        // Remove the element at the specified index
        array.remove(at: arrayIndex)

        // Set the updated array back to the field
        return message.set(field: field, value: ProtoValue.repeatedValue(array))

      case .mapField(let fieldName, let mapKey):
        // Get the field descriptor
        guard let field = message.descriptor().field(named: fieldName) else {
          return false
        }

        // Get the map field value
        guard let fieldValue = message.get(field: field),
          case .mapValue(var map) = fieldValue
        else {
          return false
        }

        // Remove the key from the map
        map.removeValue(forKey: mapKey)

        // Set the updated map back to the field
        return message.set(field: field, value: ProtoValue.mapValue(map))
      }
    }

    // Otherwise, we need to navigate to the next component
    switch component {
    case .field(let fieldName):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return false
      }

      // Get the field value
      guard let fieldValue = message.get(field: field) else {
        // If the field doesn't exist, we can't clear anything in it
        return false
      }

      // The field must be a message to continue
      if case .messageValue(let nestedMessage) = fieldValue {
        // Continue recursively with the nested message
        return clearValueRecursive(in: nestedMessage, components: components, index: index + 1)
      }

      return false

    case .repeatedField(let fieldName, let arrayIndex):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return false
      }

      // Get the repeated field value
      guard let fieldValue = message.get(field: field),
        case .repeatedValue(let array) = fieldValue
      else {
        return false
      }

      // Check if the index is valid
      guard arrayIndex >= 0 && arrayIndex < array.count else {
        return false
      }

      let element = array[arrayIndex]

      // The element must be a message to continue
      if case .messageValue(let nestedMessage) = element {
        // Continue recursively with the nested message
        if clearValueRecursive(in: nestedMessage, components: components, index: index + 1) {
          // The nested message was updated, but we need to update the array as well
          var updatedArray = array
          updatedArray[arrayIndex] = ProtoValue.messageValue(nestedMessage)

          // Set the updated array back to the field
          return message.set(field: field, value: ProtoValue.repeatedValue(updatedArray))
        }
      }

      return false

    case .mapField(let fieldName, let mapKey):
      // Get the field descriptor
      guard let field = message.descriptor().field(named: fieldName) else {
        return false
      }

      // Get the map field value
      guard let fieldValue = message.get(field: field),
        case .mapValue(let map) = fieldValue
      else {
        return false
      }

      // Check if the key exists
      guard let mapValue = map[mapKey] else {
        return false
      }

      // The value must be a message to continue
      if case .messageValue(let nestedMessage) = mapValue {
        // Continue recursively with the nested message
        if clearValueRecursive(in: nestedMessage, components: components, index: index + 1) {
          // The nested message was updated, but we need to update the map as well
          var updatedMap = map
          updatedMap[mapKey] = ProtoValue.messageValue(nestedMessage)

          // Set the updated map back to the field
          return message.set(field: field, value: ProtoValue.mapValue(updatedMap))
        }
      }

      return false
    }
  }

  /// Returns a string representation of the field path.
  ///
  /// - Returns: A dot-separated path string.
  public func description() -> String {
    return components.map { component in
      switch component {
      case .field(let fieldName):
        return fieldName
      case .repeatedField(let fieldName, let index):
        return "\(fieldName)[\(index)]"
      case .mapField(let fieldName, let key):
        return "\(fieldName)['\(key)']"
      }
    }.joined(separator: ".")
  }
}
