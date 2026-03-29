//
// ListValueHandler.swift
// SwiftProtoReflect
//
// Handler for google.protobuf.ListValue — a repeated list of Value objects.
//

import Foundation

/// Handler for google.protobuf.ListValue.
public struct ListValueHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.listValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    do {
      if try message.hasValue(forField: "values_data") {
        let data = try message.get(forField: "values_data") as? Data ?? Data()
        if !data.isEmpty {
          let jsonArray = try JSONSerialization.jsonObject(with: data, options: [])
          guard let array = jsonArray as? [[String: Any]] else {
            return [StructHandler.ValueValue]()
          }
          return try array.map { wrappedElement -> StructHandler.ValueValue in
            if let actualValue = wrappedElement["value"] {
              return try StructHandler.ValueValue(from: actualValue)
            }
            return StructHandler.ValueValue.nullValue
          }
        }
      }
    }
    catch let error as WellKnownTypeError {
      throw error
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "[ValueValue]",
        reason: "Failed to extract values_data: \(error.localizedDescription)"
      )
    }

    return [StructHandler.ValueValue]()
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let values = specialized as? [StructHandler.ValueValue] else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected [ValueValue]"
      )
    }

    let descriptor = createListValueDescriptor()
    let factory = MessageFactory()
    var message = factory.createMessage(from: descriptor)

    let jsonArray: [[String: Any]] = values.map { value in
      ["value": value.toAny()]
    }

    do {
      let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
      try message.set(jsonData, forField: "values_data")
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "[ValueValue]",
        to: "DynamicMessage",
        reason: "Failed to serialize values: \(error.localizedDescription)"
      )
    }

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    return specialized is [StructHandler.ValueValue]
  }

  // MARK: - Descriptor Creation

  /// Creates descriptor for google.protobuf.ListValue.
  ///
  /// Uses a simplified representation with a single bytes field to store
  /// the serialized JSON array of values.
  public static func createListValueDescriptor() -> MessageDescriptor {
    let fileDescriptor = FileDescriptor(
      name: "google/protobuf/struct.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "ListValue",
      parent: fileDescriptor
    )

    let valuesField = FieldDescriptor(
      name: "values_data",
      number: 1,
      type: .bytes
    )
    messageDescriptor.addField(valuesField)

    return messageDescriptor
  }
}
