/**
 * ValueHandler.swift
 * SwiftProtoReflect
 *
 * Handler for google.protobuf.Value - universal JSON-like values
 */

import Foundation

// MARK: - Value Handler

/// Handler for google.protobuf.Value.
public struct ValueHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.value
  public static let supportPhase: WellKnownSupportPhase = .important

  // MARK: - Type Aliases

  /// Reuse ValueValue from StructHandler for compatibility.
  public typealias ValueValue = StructHandler.ValueValue

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    // Check message type
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    // Simplified implementation: store Value as JSON in bytes field
    do {
      if try message.hasValue(forField: "value_data") {
        let data = try message.get(forField: "value_data") as? Data ?? Data()
        if !data.isEmpty {
          let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
          // Extract value from wrapper object
          if let wrappedValue = jsonObject as? [String: Any],
            let actualValue = wrappedValue["value"]
          {
            return try ValueValue(from: actualValue)
          }
        }
      }
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "ValueValue",
        reason: "Failed to extract value_data: \(error.localizedDescription)"
      )
    }

    // If field is empty or missing, return null
    return ValueValue.nullValue
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let valueValue = specialized as? ValueValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected ValueValue"
      )
    }

    // Create descriptor for Value
    let valueDescriptor = createValueDescriptor()

    // Create message
    let factory = MessageFactory()
    var message = factory.createMessage(from: valueDescriptor)

    // Serialize value to JSON and save as Data
    let anyValue = valueValue.toAny()

    do {
      // Wrap value in dictionary to avoid issues with top-level types
      let wrappedValue = ["value": anyValue]
      let jsonData = try JSONSerialization.data(withJSONObject: wrappedValue, options: [])
      try message.set(jsonData, forField: "value_data")
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "ValueValue",
        to: "DynamicMessage",
        reason: "Failed to serialize value: \(error.localizedDescription)"
      )
    }

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    return specialized is ValueValue
  }

  // MARK: - Descriptor Creation

  /// Creates descriptor for google.protobuf.Value.
  /// - Returns: MessageDescriptor for Value.
  private static func createValueDescriptor() -> MessageDescriptor {
    // Create file descriptor
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/struct.proto",
      package: "google.protobuf"
    )

    // Create Value message descriptor
    var messageDescriptor = MessageDescriptor(
      name: "Value",
      parent: fileDescriptor
    )

    // Simplified implementation: store JSON as bytes
    let valueDataField = FieldDescriptor(
      name: "value_data",
      number: 1,
      type: .bytes
    )
    messageDescriptor.addField(valueDataField)

    // Register in file
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

extension DynamicMessage {

  /// Creates DynamicMessage from arbitrary value for google.protobuf.Value.
  /// - Parameter value: Arbitrary value.
  /// - Returns: DynamicMessage representing Value.
  /// - Throws: WellKnownTypeError.
  public static func valueMessage(from value: Any) throws -> DynamicMessage {
    let valueValue = try ValueHandler.ValueValue(from: value)
    return try ValueHandler.createDynamic(from: valueValue)
  }

  /// Converts DynamicMessage to arbitrary value (if it's Value).
  /// - Returns: Arbitrary value.
  /// - Throws: WellKnownTypeError if message is not Value.
  public func toAnyValue() throws -> Any {
    guard descriptor.fullName == WellKnownTypeNames.value else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a Value"
      )
    }

    let valueValue = try ValueHandler.createSpecialized(from: self) as! ValueHandler.ValueValue
    return valueValue.toAny()
  }
}
