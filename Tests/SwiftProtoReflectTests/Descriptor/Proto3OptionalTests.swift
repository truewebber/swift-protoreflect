//
// Proto3OptionalTests.swift
// SwiftProtoReflectTests
//

import XCTest

@testable import SwiftProtoReflect

final class Proto3OptionalTests: XCTestCase {

  // MARK: - FieldDescriptor

  func test_fieldDescriptor_defaultProto3OptionalFalse() async throws {
    let field = FieldDescriptor(name: "value", number: 1, type: .int32)
    XCTAssertFalse(field.proto3Optional)
  }

  func test_fieldDescriptor_proto3OptionalTrue_stored() async throws {
    let field = FieldDescriptor(name: "value", number: 1, type: .int32, proto3Optional: true)
    XCTAssertTrue(field.proto3Optional)
  }

  func test_fieldDescriptor_equality_differentProto3Optional_notEqual() async throws {
    let f1 = FieldDescriptor(name: "v", number: 1, type: .int32, proto3Optional: false)
    let f2 = FieldDescriptor(name: "v", number: 1, type: .int32, proto3Optional: true)
    XCTAssertNotEqual(f1, f2)
  }

  // MARK: - DynamicMessage Presence: Regular Scalar

  func test_regularScalar_notSet_getReturnsDefault() async throws {
    let desc = makeDescriptor(proto3Optional: false, defaultValue: .int(0))
    let msg = DynamicMessage(descriptor: desc)
    let value = try msg.get(forField: 1) as? Int
    XCTAssertEqual(value, 0)
  }

  func test_regularScalar_setToZero_getReturnsZero() async throws {
    let desc = makeDescriptor(proto3Optional: false)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(0), forField: 1)
    let value = try msg.get(forField: 1) as? Int32
    XCTAssertEqual(value, 0)
  }

  func test_regularScalar_notSet_hasValueFalse() async throws {
    let desc = makeDescriptor(proto3Optional: false)
    let msg = DynamicMessage(descriptor: desc)
    XCTAssertFalse(try msg.hasValue(forField: 1))
  }

  func test_regularScalar_setToZero_hasValueTrue() async throws {
    let desc = makeDescriptor(proto3Optional: false)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(0), forField: 1)
    XCTAssertTrue(try msg.hasValue(forField: 1))
  }

  // MARK: - DynamicMessage Presence: Proto3 Optional Scalar

  func test_optionalScalar_notSet_getReturnsNil() async throws {
    let desc = makeDescriptor(proto3Optional: true)
    let msg = DynamicMessage(descriptor: desc)
    let value = try msg.get(forField: 1)
    XCTAssertNil(value, "Proto3 optional field should return nil when not set")
  }

  func test_optionalScalar_setToZero_getReturnsZero() async throws {
    let desc = makeDescriptor(proto3Optional: true)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(0), forField: 1)
    let value = try msg.get(forField: 1) as? Int32
    XCTAssertEqual(value, 0)
  }

  func test_optionalScalar_notSet_hasValueFalse() async throws {
    let desc = makeDescriptor(proto3Optional: true)
    let msg = DynamicMessage(descriptor: desc)
    XCTAssertFalse(try msg.hasValue(forField: 1))
  }

  func test_optionalScalar_setToZero_hasValueTrue() async throws {
    let desc = makeDescriptor(proto3Optional: true)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(0), forField: 1)
    XCTAssertTrue(try msg.hasValue(forField: 1))
  }

  func test_optionalScalar_setThenClear_getReturnsNil() async throws {
    let desc = makeDescriptor(proto3Optional: true)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(42), forField: 1)
    try msg.clearField(1)
    let value = try msg.get(forField: 1)
    XCTAssertNil(value)
  }

  func test_optionalString_notSet_getReturnsNil() async throws {
    let desc = makeStringDescriptor(proto3Optional: true)
    let msg = DynamicMessage(descriptor: desc)
    let value = try msg.get(forField: 1)
    XCTAssertNil(value)
  }

  func test_optionalString_setToEmpty_getReturnsEmpty() async throws {
    let desc = makeStringDescriptor(proto3Optional: true)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set("", forField: 1)
    let value = try msg.get(forField: 1) as? String
    XCTAssertEqual(value, "")
  }

  func test_optionalBool_notSet_getReturnsNil() async throws {
    let desc = makeBoolDescriptor(proto3Optional: true)
    let msg = DynamicMessage(descriptor: desc)
    let value = try msg.get(forField: 1)
    XCTAssertNil(value)
  }

  func test_optionalBool_setToFalse_getReturnsFalse() async throws {
    let desc = makeBoolDescriptor(proto3Optional: true)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(false, forField: 1)
    let value = try msg.get(forField: 1) as? Bool
    XCTAssertEqual(value, false)
  }

  // MARK: - Helpers

  private func makeDescriptor(
    proto3Optional: Bool,
    defaultValue: DescriptorOption? = nil
  ) -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(
      FieldDescriptor(
        name: "value",
        number: 1,
        type: .int32,
        proto3Optional: proto3Optional,
        defaultValue: defaultValue
      )
    )
    return desc
  }

  private func makeStringDescriptor(proto3Optional: Bool) -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(
      FieldDescriptor(name: "value", number: 1, type: .string, proto3Optional: proto3Optional)
    )
    return desc
  }

  private func makeBoolDescriptor(proto3Optional: Bool) -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(
      FieldDescriptor(name: "value", number: 1, type: .bool, proto3Optional: proto3Optional)
    )
    return desc
  }
}
