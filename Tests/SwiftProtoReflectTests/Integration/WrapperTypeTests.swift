//
// WrapperTypeTests.swift
// SwiftProtoReflect
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class WrapperTypeTests: XCTestCase {

  // MARK: - Helpers

  private func makeWrapperDescriptor(name: String, fieldType: FieldType) -> MessageDescriptor {
    var desc = MessageDescriptor(name: name, fullName: "google.protobuf.\(name)")
    desc.addField(FieldDescriptor(name: "value", number: 1, type: fieldType))
    return desc
  }

  private func makeDynamic(descriptor: MessageDescriptor, value: Any) throws -> DynamicMessage {
    let factory = MessageFactory()
    var msg = factory.createMessage(from: descriptor)
    try msg.set(value, forField: "value")
    return msg
  }

  // MARK: - StringValue

  func test_stringValue_createSpecialized_returnsString() throws {
    let desc = makeWrapperDescriptor(name: "StringValue", fieldType: .string)
    let msg = try makeDynamic(descriptor: desc, value: "hello")
    let result = try StringValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? String, "hello")
  }

  func test_stringValue_createDynamic_wrapsString() throws {
    let msg = try StringValueHandler.createDynamic(from: "hello")
    let value = try msg.get(forField: "value")
    XCTAssertEqual(value as? String, "hello")
  }

  func test_stringValue_validate_validString_returnsTrue() {
    XCTAssertTrue(StringValueHandler.validate("hello"))
  }

  func test_stringValue_validate_nonString_returnsFalse() {
    XCTAssertFalse(StringValueHandler.validate(42))
  }

  func test_stringValue_empty_createSpecialized() throws {
    let desc = makeWrapperDescriptor(name: "StringValue", fieldType: .string)
    let msg = try makeDynamic(descriptor: desc, value: "")
    let result = try StringValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? String, "")
  }

  // MARK: - Int32Value

  func test_int32Value_createSpecialized_returnsInt32() throws {
    let desc = makeWrapperDescriptor(name: "Int32Value", fieldType: .int32)
    let msg = try makeDynamic(descriptor: desc, value: Int32(42))
    let result = try Int32ValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? Int32, 42)
  }

  func test_int32Value_createDynamic_wrapsInt32() throws {
    let msg = try Int32ValueHandler.createDynamic(from: Int32(42))
    let value = try msg.get(forField: "value")
    XCTAssertEqual(value as? Int32, 42)
  }

  func test_int32Value_zero_createSpecialized() throws {
    let desc = makeWrapperDescriptor(name: "Int32Value", fieldType: .int32)
    let msg = try makeDynamic(descriptor: desc, value: Int32(0))
    let result = try Int32ValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? Int32, 0)
  }

  // MARK: - Int64Value

  func test_int64Value_createSpecialized_returnsInt64() throws {
    let desc = makeWrapperDescriptor(name: "Int64Value", fieldType: .int64)
    let msg = try makeDynamic(descriptor: desc, value: Int64(123_456_789))
    let result = try Int64ValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? Int64, 123_456_789)
  }

  func test_int64Value_createDynamic_wrapsInt64() throws {
    let msg = try Int64ValueHandler.createDynamic(from: Int64(123_456_789))
    let value = try msg.get(forField: "value")
    XCTAssertEqual(value as? Int64, 123_456_789)
  }

  // MARK: - UInt32Value

  func test_uint32Value_createSpecialized_returnsUInt32() throws {
    let desc = makeWrapperDescriptor(name: "UInt32Value", fieldType: .uint32)
    let msg = try makeDynamic(descriptor: desc, value: UInt32(42))
    let result = try UInt32ValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? UInt32, 42)
  }

  func test_uint32Value_createDynamic_wrapsUInt32() throws {
    let msg = try UInt32ValueHandler.createDynamic(from: UInt32(42))
    let value = try msg.get(forField: "value")
    XCTAssertEqual(value as? UInt32, 42)
  }

  // MARK: - UInt64Value

  func test_uint64Value_createSpecialized_returnsUInt64() throws {
    let desc = makeWrapperDescriptor(name: "UInt64Value", fieldType: .uint64)
    let msg = try makeDynamic(descriptor: desc, value: UInt64(123_456_789))
    let result = try UInt64ValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? UInt64, 123_456_789)
  }

  func test_uint64Value_createDynamic_wrapsUInt64() throws {
    let msg = try UInt64ValueHandler.createDynamic(from: UInt64(123_456_789))
    let value = try msg.get(forField: "value")
    XCTAssertEqual(value as? UInt64, 123_456_789)
  }

  // MARK: - BoolValue

  func test_boolValue_createSpecialized_returnsBool() throws {
    let desc = makeWrapperDescriptor(name: "BoolValue", fieldType: .bool)
    let msg = try makeDynamic(descriptor: desc, value: true)
    let result = try BoolValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? Bool, true)
  }

  func test_boolValue_createDynamic_wrapsBool() throws {
    let msg = try BoolValueHandler.createDynamic(from: false)
    let value = try msg.get(forField: "value")
    XCTAssertEqual(value as? Bool, false)
  }

  func test_boolValue_false_createSpecialized() throws {
    let desc = makeWrapperDescriptor(name: "BoolValue", fieldType: .bool)
    let msg = try makeDynamic(descriptor: desc, value: false)
    let result = try BoolValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? Bool, false)
  }

  // MARK: - FloatValue

  func test_floatValue_createSpecialized_returnsFloat() throws {
    let desc = makeWrapperDescriptor(name: "FloatValue", fieldType: .float)
    let msg = try makeDynamic(descriptor: desc, value: Float(3.14))
    let result = try FloatValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? Float, Float(3.14))
  }

  func test_floatValue_createDynamic_wrapsFloat() throws {
    let msg = try FloatValueHandler.createDynamic(from: Float(3.14))
    let value = try msg.get(forField: "value")
    XCTAssertEqual(value as? Float, Float(3.14))
  }

  // MARK: - DoubleValue

  func test_doubleValue_createSpecialized_returnsDouble() throws {
    let desc = makeWrapperDescriptor(name: "DoubleValue", fieldType: .double)
    let msg = try makeDynamic(descriptor: desc, value: 3.14159)
    let result = try DoubleValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? Double, 3.14159)
  }

  func test_doubleValue_createDynamic_wrapsDouble() throws {
    let msg = try DoubleValueHandler.createDynamic(from: 3.14159)
    let value = try msg.get(forField: "value")
    XCTAssertEqual(value as? Double, 3.14159)
  }

  // MARK: - BytesValue

  func test_bytesValue_createSpecialized_returnsData() throws {
    let desc = makeWrapperDescriptor(name: "BytesValue", fieldType: .bytes)
    let data = "Hello".data(using: .utf8)!
    let msg = try makeDynamic(descriptor: desc, value: data)
    let result = try BytesValueHandler.createSpecialized(from: msg)
    XCTAssertEqual(result as? Data, data)
  }

  func test_bytesValue_createDynamic_wrapsData() throws {
    let data = "Hello".data(using: .utf8)!
    let msg = try BytesValueHandler.createDynamic(from: data)
    let value = try msg.get(forField: "value")
    XCTAssertEqual(value as? Data, data)
  }

  // MARK: - Registry Integration

  func test_registry_hasAllWrapperHandlers() {
    let registry = WellKnownTypesRegistry.shared
    let wrapperTypes = [
      WellKnownTypeNames.doubleValue,
      WellKnownTypeNames.floatValue,
      WellKnownTypeNames.int64Value,
      WellKnownTypeNames.uint64Value,
      WellKnownTypeNames.int32Value,
      WellKnownTypeNames.uint32Value,
      WellKnownTypeNames.boolValue,
      WellKnownTypeNames.stringValue,
      WellKnownTypeNames.bytesValue,
    ]
    for typeName in wrapperTypes {
      XCTAssertNotNil(registry.getHandler(for: typeName), "Missing handler for \(typeName)")
    }
  }
}
