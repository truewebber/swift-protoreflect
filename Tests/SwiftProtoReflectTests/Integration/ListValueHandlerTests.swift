//
// ListValueHandlerTests.swift
// SwiftProtoReflect
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class ListValueHandlerTests: XCTestCase {

  // MARK: - Registration

  func test_listValue_registered() {
    let registry = WellKnownTypesRegistry.shared
    XCTAssertNotNil(registry.getHandler(for: WellKnownTypeNames.listValue))
  }

  // MARK: - createSpecialized

  func test_listValue_createSpecialized_emptyList() throws {
    let descriptor = ListValueHandler.createListValueDescriptor()
    let factory = MessageFactory()
    let msg = factory.createMessage(from: descriptor)

    let result = try ListValueHandler.createSpecialized(from: msg)
    guard let values = result as? [StructHandler.ValueValue] else {
      XCTFail("Expected [ValueValue]")
      return
    }
    XCTAssertTrue(values.isEmpty)
  }

  func test_listValue_createSpecialized_withValues() throws {
    let v1 = StructHandler.ValueValue.numberValue(1.0)
    let v2 = StructHandler.ValueValue.stringValue("hello")
    let v3 = StructHandler.ValueValue.boolValue(true)

    let msg = try ListValueHandler.createDynamic(from: [v1, v2, v3])
    let result = try ListValueHandler.createSpecialized(from: msg)
    guard let values = result as? [StructHandler.ValueValue] else {
      XCTFail("Expected [ValueValue]")
      return
    }
    XCTAssertEqual(values.count, 3)
    XCTAssertEqual(values[0], v1)
    XCTAssertEqual(values[1], v2)
    XCTAssertEqual(values[2], v3)
  }

  // MARK: - createDynamic

  func test_listValue_createDynamic_emptyList() throws {
    let values: [StructHandler.ValueValue] = []
    let msg = try ListValueHandler.createDynamic(from: values)
    XCTAssertEqual(msg.descriptor.fullName, WellKnownTypeNames.listValue)
  }

  func test_listValue_createDynamic_withValues() throws {
    let values: [StructHandler.ValueValue] = [
      .numberValue(42.0),
      .stringValue("test"),
      .boolValue(false),
    ]
    let msg = try ListValueHandler.createDynamic(from: values)
    XCTAssertEqual(msg.descriptor.fullName, WellKnownTypeNames.listValue)
  }

  // MARK: - Round-trip

  func test_listValue_roundTrip_preservesValues() throws {
    let original: [StructHandler.ValueValue] = [
      .numberValue(1.0),
      .stringValue("hello"),
      .boolValue(true),
      .nullValue,
    ]
    let msg = try ListValueHandler.createDynamic(from: original)
    let restored = try ListValueHandler.createSpecialized(from: msg)
    guard let restoredValues = restored as? [StructHandler.ValueValue] else {
      XCTFail("Expected [ValueValue]")
      return
    }
    XCTAssertEqual(restoredValues, original)
  }

  // MARK: - Validation

  func test_listValue_validate_validArray() {
    let values: [StructHandler.ValueValue] = [.numberValue(1.0)]
    XCTAssertTrue(ListValueHandler.validate(values))
  }

  func test_listValue_validate_invalidType() {
    XCTAssertFalse(ListValueHandler.validate("not an array"))
  }

  func test_listValue_validate_emptyArray() {
    let values: [StructHandler.ValueValue] = []
    XCTAssertTrue(ListValueHandler.validate(values))
  }

  // MARK: - OPE-265 / OPE-266: New repeated-message wire-format tests

  func test_createDynamic_listValue_fieldIsRepeatedMessageNotBytes() throws {
    let values: [StructHandler.ValueValue] = [.boolValue(true), .nullValue, .numberValue(7)]
    let msg = try ListValueHandler.createDynamic(from: values)

    XCTAssertEqual(msg.descriptor.fullName, "google.protobuf.ListValue")
    XCTAssertNil(try? msg.get(forField: "values_data"), "values_data field must not exist")
    let rawList = try XCTUnwrap(try msg.get(forField: 1) as? [Any], "field 1 must be a list")
    XCTAssertEqual(rawList.count, 3)
    for element in rawList {
      XCTAssertNotNil(element as? DynamicMessage, "each element must be a DynamicMessage")
    }
  }

  func test_createDynamic_storesValuesAsRepeatedMessageNotBytes() throws {
    let values: [StructHandler.ValueValue] = [.numberValue(1.0), .stringValue("a")]
    let msg = try ListValueHandler.createDynamic(from: values)

    XCTAssertEqual(msg.descriptor.fullName, "google.protobuf.ListValue")
    let raw = try msg.get(forField: 1)
    let list = raw as? [Any]
    XCTAssertNotNil(list, "field 1 must be a repeated list, not bytes or nil")
    XCTAssertNil(raw as? Data, "field 1 must not be a bytes blob (old JSON approach)")
    XCTAssertEqual(list?.count, 2)
  }

  func test_createSpecialized_decodesRepeatedValueMessages() throws {
    let values: [StructHandler.ValueValue] = [.numberValue(1.0), .stringValue("a")]
    let msg = try ListValueHandler.createDynamic(from: values)

    let rawList = try XCTUnwrap(try msg.get(forField: 1) as? [Any])
    XCTAssertEqual(rawList.count, 2)

    let first = try XCTUnwrap(rawList[0] as? DynamicMessage)
    XCTAssertEqual(first.descriptor.fullName, "google.protobuf.Value")
    XCTAssertEqual(try first.get(forField: 2) as? Double, 1.0)

    let second = try XCTUnwrap(rawList[1] as? DynamicMessage)
    XCTAssertEqual(second.descriptor.fullName, "google.protobuf.Value")
    XCTAssertEqual(try second.get(forField: 3) as? String, "a")
  }

  func test_roundTrip_withMixedValueKinds_preservesOrderAndValues() throws {
    let original: [StructHandler.ValueValue] = [
      .nullValue,
      .numberValue(3.14),
      .stringValue("hello"),
      .boolValue(false),
      .structValue(StructHandler.StructValue(fields: ["x": .numberValue(1)])),
      .listValue([.stringValue("nested")]),
    ]
    let msg = try ListValueHandler.createDynamic(from: original)
    let result = try XCTUnwrap(
      try ListValueHandler.createSpecialized(from: msg) as? [StructHandler.ValueValue]
    )
    XCTAssertEqual(result, original)
  }

  func test_roundTrip_emptyList() throws {
    let original: [StructHandler.ValueValue] = []
    let msg = try ListValueHandler.createDynamic(from: original)
    let result = try XCTUnwrap(
      try ListValueHandler.createSpecialized(from: msg) as? [StructHandler.ValueValue]
    )
    XCTAssertEqual(result, original)
  }
}
