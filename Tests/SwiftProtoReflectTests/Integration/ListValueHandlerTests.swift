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
    let descriptor = ListValueHandler.createListValueDescriptor()
    let factory = MessageFactory()
    var msg = factory.createMessage(from: descriptor)

    let v1 = StructHandler.ValueValue.numberValue(1.0)
    let v2 = StructHandler.ValueValue.stringValue("hello")
    let v3 = StructHandler.ValueValue.boolValue(true)

    let jsonArray: [Any] = [
      ["value": 1.0],
      ["value": "hello"],
      ["value": true],
    ]
    let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
    try msg.set(data, forField: "values_data")

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
}
