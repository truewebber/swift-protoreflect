//
// WrapperHandlers.swift
// SwiftProtoReflect
//
// Handlers for google.protobuf wrapper well-known types:
// DoubleValue, FloatValue, Int64Value, UInt64Value,
// Int32Value, UInt32Value, BoolValue, StringValue, BytesValue.
//

import Foundation

// MARK: - Generic Wrapper Implementation

private func wrapperCreateSpecialized<T>(
  from message: DynamicMessage,
  typeName: String,
  as _: T.Type
) throws -> Any {
  guard let value = try message.get(forField: "value") else {
    throw WellKnownTypeError.invalidData(
      typeName: typeName,
      reason: "missing 'value' field"
    )
  }
  guard let typed = value as? T else {
    throw WellKnownTypeError.conversionFailed(
      from: String(describing: type(of: value)),
      to: String(describing: T.self),
      reason: "value is not \(T.self)"
    )
  }
  return typed
}

private func wrapperCreateDynamic<T>(
  from specialized: Any,
  typeName: String,
  descriptorName: String,
  fieldType: FieldType,
  as _: T.Type
) throws -> DynamicMessage {
  guard let typed = specialized as? T else {
    throw WellKnownTypeError.conversionFailed(
      from: String(describing: type(of: specialized)),
      to: typeName,
      reason: "expected \(T.self)"
    )
  }
  var desc = MessageDescriptor(name: descriptorName, fullName: typeName)
  desc.addField(FieldDescriptor(name: "value", number: 1, type: fieldType))
  let factory = MessageFactory()
  var msg = factory.createMessage(from: desc)
  try msg.set(typed, forField: "value")
  return msg
}

// MARK: - StringValueHandler

/// Handler for google.protobuf.StringValue.
public struct StringValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.stringValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: String.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "StringValue",
      fieldType: .string,
      as: String.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is String }
}

// MARK: - Int32ValueHandler

/// Handler for google.protobuf.Int32Value.
public struct Int32ValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.int32Value
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Int32.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "Int32Value",
      fieldType: .int32,
      as: Int32.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Int32 }
}

// MARK: - Int64ValueHandler

/// Handler for google.protobuf.Int64Value.
public struct Int64ValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.int64Value
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Int64.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "Int64Value",
      fieldType: .int64,
      as: Int64.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Int64 }
}

// MARK: - UInt32ValueHandler

/// Handler for google.protobuf.UInt32Value.
public struct UInt32ValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.uint32Value
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: UInt32.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "UInt32Value",
      fieldType: .uint32,
      as: UInt32.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is UInt32 }
}

// MARK: - UInt64ValueHandler

/// Handler for google.protobuf.UInt64Value.
public struct UInt64ValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.uint64Value
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: UInt64.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "UInt64Value",
      fieldType: .uint64,
      as: UInt64.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is UInt64 }
}

// MARK: - BoolValueHandler

/// Handler for google.protobuf.BoolValue.
public struct BoolValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.boolValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Bool.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "BoolValue",
      fieldType: .bool,
      as: Bool.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Bool }
}

// MARK: - FloatValueHandler

/// Handler for google.protobuf.FloatValue.
public struct FloatValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.floatValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Float.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "FloatValue",
      fieldType: .float,
      as: Float.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Float }
}

// MARK: - DoubleValueHandler

/// Handler for google.protobuf.DoubleValue.
public struct DoubleValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.doubleValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Double.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "DoubleValue",
      fieldType: .double,
      as: Double.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Double }
}

// MARK: - BytesValueHandler

/// Handler for google.protobuf.BytesValue.
public struct BytesValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.bytesValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Data.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "BytesValue",
      fieldType: .bytes,
      as: Data.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Data }
}
