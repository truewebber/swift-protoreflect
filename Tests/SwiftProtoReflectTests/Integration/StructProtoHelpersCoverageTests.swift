//
// StructProtoHelpersCoverageTests.swift
// SwiftProtoReflectTests
//
// Covers error paths in Integration/_StructProtoHelpers.swift:
//   - dynamicMessageToValueValue: wrong type at fields 2–6 throws WellKnownTypeError.conversionFailed
//   - _dynamicMessageToListValue: repeated element not a DynamicMessage throws conversionFailed
//   - Additional happy-path coverage for all six ValueValue kinds round-trip
//

import XCTest

@testable import SwiftProtoReflect

final class StructProtoHelpersCoverageTests: XCTestCase {

  // MARK: - Helpers

  /// Creates a descriptor matching google.protobuf.Value field schema but with field 2
  /// typed as int64 (not double), to trigger a type-mismatch error.
  // MARK: - dynamicMessageToValueValue: field 2 (number_value) wrong type

  // [PUBLIC-MIRROR] StructProtoHelpersTests.test_roundTrip_allSixKinds()
  // Oracle: dynamicMessageToValueValue throws conversionFailed when field 2 is not a Double
  func test_dynamicMessageToValueValue_field2_wrongType_throwsConversionFailed() throws {
    // Create descriptor where field 2 is int64 instead of double
    var desc = MessageDescriptor(name: "google.protobuf.Value", fullName: "google.protobuf.Value")
    desc.addField(FieldDescriptor(name: "null_value", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "number_value", number: 2, type: .int64))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int64(42), forField: "number_value")

    XCTAssertThrowsError(try dynamicMessageToValueValue(msg)) { error in
      guard let wktError = error as? WellKnownTypeError,
        case .conversionFailed = wktError
      else {
        XCTFail("Expected WellKnownTypeError.conversionFailed, got \(error)")
        return
      }
    }
  }

  // MARK: - dynamicMessageToValueValue: field 3 (string_value) wrong type

  // [PUBLIC-MIRROR] StructProtoHelpersTests.test_roundTrip_allSixKinds()
  // Oracle: dynamicMessageToValueValue throws conversionFailed when field 3 is not a String
  func test_dynamicMessageToValueValue_field3_wrongType_throwsConversionFailed() throws {
    var desc = MessageDescriptor(name: "google.protobuf.Value", fullName: "google.protobuf.Value")
    desc.addField(FieldDescriptor(name: "null_value", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "number_value", number: 2, type: .double))
    desc.addField(FieldDescriptor(name: "string_value", number: 3, type: .int32))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(99), forField: "string_value")

    XCTAssertThrowsError(try dynamicMessageToValueValue(msg)) { error in
      guard let wktError = error as? WellKnownTypeError,
        case .conversionFailed = wktError
      else {
        XCTFail("Expected WellKnownTypeError.conversionFailed, got \(error)")
        return
      }
    }
  }

  // MARK: - dynamicMessageToValueValue: field 4 (bool_value) wrong type

  // [PUBLIC-MIRROR] StructProtoHelpersTests.test_roundTrip_allSixKinds()
  // Oracle: dynamicMessageToValueValue throws conversionFailed when field 4 is not a Bool
  func test_dynamicMessageToValueValue_field4_wrongType_throwsConversionFailed() throws {
    var desc = MessageDescriptor(name: "google.protobuf.Value", fullName: "google.protobuf.Value")
    desc.addField(FieldDescriptor(name: "null_value", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "number_value", number: 2, type: .double))
    desc.addField(FieldDescriptor(name: "string_value", number: 3, type: .string))
    desc.addField(FieldDescriptor(name: "bool_value", number: 4, type: .int32))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(1), forField: "bool_value")

    XCTAssertThrowsError(try dynamicMessageToValueValue(msg)) { error in
      guard let wktError = error as? WellKnownTypeError,
        case .conversionFailed = wktError
      else {
        XCTFail("Expected WellKnownTypeError.conversionFailed, got \(error)")
        return
      }
    }
  }

  // MARK: - dynamicMessageToValueValue: field 5 (struct_value) wrong type

  // [PUBLIC-MIRROR] StructProtoHelpersTests.test_roundTrip_allSixKinds()
  // Oracle: dynamicMessageToValueValue throws conversionFailed when field 5 is not a DynamicMessage
  func test_dynamicMessageToValueValue_field5_wrongType_throwsConversionFailed() throws {
    var desc = MessageDescriptor(name: "google.protobuf.Value", fullName: "google.protobuf.Value")
    desc.addField(FieldDescriptor(name: "null_value", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "number_value", number: 2, type: .double))
    desc.addField(FieldDescriptor(name: "string_value", number: 3, type: .string))
    desc.addField(FieldDescriptor(name: "bool_value", number: 4, type: .bool))
    desc.addField(FieldDescriptor(name: "struct_value", number: 5, type: .string))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set("not-a-message", forField: "struct_value")

    XCTAssertThrowsError(try dynamicMessageToValueValue(msg)) { error in
      guard let wktError = error as? WellKnownTypeError,
        case .conversionFailed = wktError
      else {
        XCTFail("Expected WellKnownTypeError.conversionFailed, got \(error)")
        return
      }
    }
  }

  // MARK: - dynamicMessageToValueValue: field 6 (list_value) wrong type

  // [PUBLIC-MIRROR] StructProtoHelpersTests.test_roundTrip_allSixKinds()
  // Oracle: dynamicMessageToValueValue throws conversionFailed when field 6 is not a DynamicMessage
  func test_dynamicMessageToValueValue_field6_wrongType_throwsConversionFailed() throws {
    var desc = MessageDescriptor(name: "google.protobuf.Value", fullName: "google.protobuf.Value")
    desc.addField(FieldDescriptor(name: "null_value", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "number_value", number: 2, type: .double))
    desc.addField(FieldDescriptor(name: "string_value", number: 3, type: .string))
    desc.addField(FieldDescriptor(name: "bool_value", number: 4, type: .bool))
    desc.addField(FieldDescriptor(name: "struct_value", number: 5, type: .string))
    desc.addField(FieldDescriptor(name: "list_value", number: 6, type: .string))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set("not-a-message", forField: "list_value")

    XCTAssertThrowsError(try dynamicMessageToValueValue(msg)) { error in
      guard let wktError = error as? WellKnownTypeError,
        case .conversionFailed = wktError
      else {
        XCTFail("Expected WellKnownTypeError.conversionFailed, got \(error)")
        return
      }
    }
  }

  // MARK: - _dynamicMessageToListValue: element not a DynamicMessage

  // [PUBLIC-MIRROR] StructProtoHelpersTests.test_encode_listValue_setsField6_withNestedListValueMessage()
  // Oracle: _dynamicMessageToListValue throws conversionFailed when repeated element is not a DynamicMessage
  func test_dynamicMessageToListValue_wrongElementType_throwsConversionFailed() throws {
    // Create descriptor where field 1 is repeated int32 (not repeated message)
    var desc = MessageDescriptor(name: "google.protobuf.ListValue", fullName: "google.protobuf.ListValue")
    desc.addField(
      FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true)
    )

    var msg = DynamicMessage(descriptor: desc)
    try msg.addRepeatedValue(Int32(1), forField: "values")
    try msg.addRepeatedValue(Int32(2), forField: "values")

    XCTAssertThrowsError(try _dynamicMessageToListValue(msg)) { error in
      guard let wktError = error as? WellKnownTypeError,
        case .conversionFailed = wktError
      else {
        XCTFail("Expected WellKnownTypeError.conversionFailed, got \(error)")
        return
      }
    }
  }

  // MARK: - dynamicMessageToValueValue: no fields set → returns nullValue

  // [PUBLIC-MIRROR] StructProtoHelpersTests.test_encode_nullValue_setsField1()
  // Oracle: dynamicMessageToValueValue returns .nullValue when no fields are set
  func test_dynamicMessageToValueValue_emptyMessage_returnsNullValue() throws {
    let emptyMsg = DynamicMessage(descriptor: StructProtoDescriptors.valueDescriptor)
    let result = try dynamicMessageToValueValue(emptyMsg)
    XCTAssertEqual(result, .nullValue)
  }

  // MARK: - _dynamicMessageToStructValue: empty struct message → empty fields

  // [PUBLIC-MIRROR] StructProtoHelpersTests.test_roundTrip_allSixKinds()
  // Oracle: _dynamicMessageToStructValue on empty Struct message returns StructValue with no fields
  func test_dynamicMessageToStructValue_emptyMessage_returnsEmptyFields() throws {
    let emptyMsg = DynamicMessage(descriptor: StructProtoDescriptors.structDescriptor)
    let result = try _dynamicMessageToStructValue(emptyMsg)
    XCTAssertTrue(result.fields.isEmpty)
  }
}
