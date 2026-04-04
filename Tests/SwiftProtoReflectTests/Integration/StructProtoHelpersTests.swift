//
// StructProtoHelpersTests.swift
// SwiftProtoReflectTests
//
// Tests for internal StructProtoHelpers — Value↔DynamicMessage conversion.
//

import XCTest

@testable import SwiftProtoReflect

final class StructProtoHelpersTests: XCTestCase {

  // MARK: - Encode: nullValue

  func test_encode_nullValue_setsField1() throws {
    let message = try valueValueToDynamicMessage(.nullValue)

    XCTAssertEqual(message.descriptor.fullName, "google.protobuf.Value")
    XCTAssertTrue(try message.hasValue(forField: 1))
    let raw = try message.get(forField: 1)
    XCTAssertEqual(raw as? Int32, Int32(0))

    XCTAssertFalse(try message.hasValue(forField: 2))
    XCTAssertFalse(try message.hasValue(forField: 3))
    XCTAssertFalse(try message.hasValue(forField: 4))
    XCTAssertFalse(try message.hasValue(forField: 5))
    XCTAssertFalse(try message.hasValue(forField: 6))
  }

  // MARK: - Encode: numberValue

  func test_encode_numberValue_setsField2() throws {
    let message = try valueValueToDynamicMessage(.numberValue(3.14))

    XCTAssertTrue(try message.hasValue(forField: 2))
    let raw = try XCTUnwrap(try message.get(forField: 2) as? Double)
    XCTAssertEqual(raw, 3.14, accuracy: 1e-10)

    XCTAssertFalse(try message.hasValue(forField: 1))
  }

  // MARK: - Encode: stringValue

  func test_encode_stringValue_setsField3() throws {
    let message = try valueValueToDynamicMessage(.stringValue("hello"))

    XCTAssertTrue(try message.hasValue(forField: 3))
    let raw = try message.get(forField: 3)
    XCTAssertEqual(raw as? String, "hello")

    XCTAssertFalse(try message.hasValue(forField: 1))
  }

  // MARK: - Encode: boolValue

  func test_encode_boolValue_setsField4() throws {
    let message = try valueValueToDynamicMessage(.boolValue(true))

    XCTAssertTrue(try message.hasValue(forField: 4))
    let raw = try message.get(forField: 4)
    XCTAssertEqual(raw as? Bool, true)

    XCTAssertFalse(try message.hasValue(forField: 1))
  }

  // MARK: - Encode: structValue

  func test_encode_structValue_setsField5_withNestedStructMessage() throws {
    let structVal = StructHandler.StructValue(fields: [
      "key1": .stringValue("val1"),
      "key2": .numberValue(42),
    ])
    let message = try valueValueToDynamicMessage(.structValue(structVal))

    XCTAssertTrue(try message.hasValue(forField: 5))
    let nested = try message.get(forField: 5)
    let structMsg = try XCTUnwrap(nested as? DynamicMessage)
    XCTAssertEqual(structMsg.descriptor.fullName, "google.protobuf.Struct")

    XCTAssertFalse(try message.hasValue(forField: 1))
    XCTAssertFalse(try message.hasValue(forField: 6))
  }

  // MARK: - Encode: listValue

  func test_encode_listValue_setsField6_withNestedListValueMessage() throws {
    let items: [StructHandler.ValueValue] = [.numberValue(1), .stringValue("two")]
    let message = try valueValueToDynamicMessage(.listValue(items))

    XCTAssertTrue(try message.hasValue(forField: 6))
    let nested = try message.get(forField: 6)
    let listMsg = try XCTUnwrap(nested as? DynamicMessage)
    XCTAssertEqual(listMsg.descriptor.fullName, "google.protobuf.ListValue")

    XCTAssertFalse(try message.hasValue(forField: 1))
    XCTAssertFalse(try message.hasValue(forField: 5))
  }

  // MARK: - Round-trip all six kinds

  func test_roundTrip_allSixKinds() throws {
    let cases: [StructHandler.ValueValue] = [
      .nullValue,
      .numberValue(2.718),
      .stringValue("proto"),
      .boolValue(false),
      .structValue(StructHandler.StructValue(fields: ["x": .numberValue(1)])),
      .listValue([.boolValue(true), .stringValue("y")]),
    ]

    for original in cases {
      let encoded = try valueValueToDynamicMessage(original)
      let decoded = try dynamicMessageToValueValue(encoded)
      XCTAssertEqual(decoded, original, "Round-trip failed for \(original)")
    }
  }

  // MARK: - Round-trip: deeply nested struct in list

  func test_roundTrip_deeplyNestedStructInList() throws {
    let inner = StructHandler.StructValue(fields: [
      "deep": .numberValue(99)
    ])
    let outer = StructHandler.StructValue(fields: [
      "list": .listValue([.structValue(inner), .nullValue]),
      "flag": .boolValue(true),
    ])
    let original = StructHandler.ValueValue.structValue(outer)

    let encoded = try valueValueToDynamicMessage(original)
    let decoded = try dynamicMessageToValueValue(encoded)

    XCTAssertEqual(decoded, original)
  }
}
