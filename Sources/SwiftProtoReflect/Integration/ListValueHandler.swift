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

    return try _dynamicMessageToListValue(message)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let values = specialized as? [StructHandler.ValueValue] else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected [ValueValue]"
      )
    }

    return try _listValueToDynamicMessage(values)
  }

  public static func validate(_ specialized: Any) -> Bool {
    return specialized is [StructHandler.ValueValue]
  }

  // MARK: - Descriptor

  /// Returns the canonical descriptor for `google.protobuf.ListValue`.
  public static func createListValueDescriptor() -> MessageDescriptor {
    return StructProtoDescriptors.listValueDescriptor
  }
}
