//
// Proto2DynamicMessageTests.swift
// SwiftProtoReflect
//
// Tests for proto2-specific dynamic message features:
// group storage, extension unified storage, syntax-aware validation.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class Proto2DynamicMessageTests: XCTestCase {

  // MARK: - Helpers

  private func makeGroupDescriptor() -> MessageDescriptor {
    var groupDesc = MessageDescriptor(name: "MyGroup", fullName: "test.MyGroup", syntax: "proto2")
    groupDesc.addField(FieldDescriptor(name: "group_value", number: 1, type: .string))
    return groupDesc
  }

  private func makeMessageWithGroup() -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addField(
      FieldDescriptor(name: "my_group", number: 2, type: .group, typeName: "test.MyGroup")
    )
    return desc
  }

  private func makeMessageWithExtensions() -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtension(FieldDescriptor(name: "ext_name", number: 100, type: .string))
    desc.addExtension(
      FieldDescriptor(
        name: "ext_msg",
        number: 101,
        type: .message,
        typeName: "test.Inner"
      )
    )
    return desc
  }

  private func makeInnerDescriptor() -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Inner", fullName: "test.Inner", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "value", number: 1, type: .int32))
    return desc
  }

  // MARK: - Group field storage

  func test_set_groupField_storedInNestedMessages() async throws {
    let desc = makeMessageWithGroup()
    var msg = DynamicMessage(descriptor: desc)
    let group = DynamicMessage(descriptor: makeGroupDescriptor())

    try msg.set(group, forField: "my_group")

    let result = try msg.get(forField: "my_group")
    XCTAssertNotNil(result)
    XCTAssertTrue(result is DynamicMessage)
  }

  func test_get_groupField_returnsFromNestedMessages() async throws {
    let desc = makeMessageWithGroup()
    var msg = DynamicMessage(descriptor: desc)

    var group = DynamicMessage(descriptor: makeGroupDescriptor())
    try group.set("hello", forField: "group_value")
    try msg.set(group, forField: "my_group")

    let result = try msg.get(forField: "my_group") as? DynamicMessage
    XCTAssertNotNil(result)
    let innerVal = try result?.get(forField: "group_value") as? String
    XCTAssertEqual(innerVal, "hello")
  }

  func test_hasValue_groupField_true_whenSet() async throws {
    let desc = makeMessageWithGroup()
    var msg = DynamicMessage(descriptor: desc)
    let group = DynamicMessage(descriptor: makeGroupDescriptor())

    try msg.set(group, forField: "my_group")
    XCTAssertTrue(try msg.hasValue(forField: "my_group"))
  }

  func test_hasValue_groupField_false_whenNotSet() async throws {
    let desc = makeMessageWithGroup()
    let msg = DynamicMessage(descriptor: desc)

    XCTAssertFalse(try msg.hasValue(forField: "my_group"))
  }

  func test_clearField_groupField_removesFromNestedMessages() async throws {
    let desc = makeMessageWithGroup()
    var msg = DynamicMessage(descriptor: desc)
    let group = DynamicMessage(descriptor: makeGroupDescriptor())

    try msg.set(group, forField: "my_group")
    XCTAssertTrue(try msg.hasValue(forField: "my_group"))

    try msg.clearField("my_group")
    XCTAssertFalse(try msg.hasValue(forField: "my_group"))
  }

  func test_set_groupField_nonDynamicMessage_throws() async throws {
    let desc = makeMessageWithGroup()
    var msg = DynamicMessage(descriptor: desc)

    XCTAssertThrowsError(try msg.set("not a message", forField: "my_group"))
  }

  func test_equality_withGroupFields_equal() async throws {
    let desc = makeMessageWithGroup()
    var msg1 = DynamicMessage(descriptor: desc)
    var msg2 = DynamicMessage(descriptor: desc)

    var group1 = DynamicMessage(descriptor: makeGroupDescriptor())
    try group1.set("hello", forField: "group_value")
    var group2 = DynamicMessage(descriptor: makeGroupDescriptor())
    try group2.set("hello", forField: "group_value")

    try msg1.set(group1, forField: "my_group")
    try msg2.set(group2, forField: "my_group")

    XCTAssertEqual(msg1, msg2)
  }

  func test_equality_withGroupFields_notEqual() async throws {
    let desc = makeMessageWithGroup()
    var msg1 = DynamicMessage(descriptor: desc)
    var msg2 = DynamicMessage(descriptor: desc)

    var group1 = DynamicMessage(descriptor: makeGroupDescriptor())
    try group1.set("hello", forField: "group_value")
    var group2 = DynamicMessage(descriptor: makeGroupDescriptor())
    try group2.set("world", forField: "group_value")

    try msg1.set(group1, forField: "my_group")
    try msg2.set(group2, forField: "my_group")

    XCTAssertNotEqual(msg1, msg2)
  }

  // MARK: - Extension fields (unified storage)

  func test_setExtension_validNumber_stored() async throws {
    let desc = makeMessageWithExtensions()
    var msg = DynamicMessage(descriptor: desc)

    try msg.set("extended", forField: 100)
    let result = try msg.get(forField: 100)
    XCTAssertEqual(result as? String, "extended")
  }

  func test_getExtension_notSet_returnsNil() async throws {
    let desc = makeMessageWithExtensions()
    let msg = DynamicMessage(descriptor: desc)

    let result = try msg.get(forField: 100)
    XCTAssertNil(result)
  }

  func test_hasExtension_true_whenSet() async throws {
    let desc = makeMessageWithExtensions()
    var msg = DynamicMessage(descriptor: desc)

    try msg.set("val", forField: 100)
    XCTAssertTrue(try msg.hasValue(forField: 100))
  }

  func test_hasExtension_false_whenNotSet() async throws {
    let desc = makeMessageWithExtensions()
    let msg = DynamicMessage(descriptor: desc)

    XCTAssertFalse(try msg.hasValue(forField: 100))
  }

  func test_clearExtension_removes() async throws {
    let desc = makeMessageWithExtensions()
    var msg = DynamicMessage(descriptor: desc)

    try msg.set("val", forField: 100)
    XCTAssertTrue(try msg.hasValue(forField: 100))

    try msg.clearField(100)
    XCTAssertFalse(try msg.hasValue(forField: 100))
  }

  func test_setExtension_messageType_stored() async throws {
    let desc = makeMessageWithExtensions()
    var msg = DynamicMessage(descriptor: desc)

    var inner = DynamicMessage(descriptor: makeInnerDescriptor())
    try inner.set(Int32(42), forField: "value")
    try msg.set(inner, forField: 101)

    let result = try msg.get(forField: 101) as? DynamicMessage
    XCTAssertNotNil(result)
    let val = try result?.get(forField: "value") as? Int32
    XCTAssertEqual(val, 42)
  }

  func test_extensionAndRegularFields_coexist() async throws {
    let desc = makeMessageWithExtensions()
    var msg = DynamicMessage(descriptor: desc)

    try msg.set(Int32(1), forField: "id")
    try msg.set("ext_value", forField: 100)

    XCTAssertEqual(try msg.get(forField: "id") as? Int32, 1)
    XCTAssertEqual(try msg.get(forField: 100) as? String, "ext_value")
  }

  func test_unknownFieldNumber_throws() async throws {
    let desc = makeMessageWithExtensions()
    var msg = DynamicMessage(descriptor: desc)

    XCTAssertThrowsError(try msg.set("val", forField: 50))
  }

  // MARK: - MessageFactory syntax from descriptor

  func test_validate_readsSyntaxFromDescriptor_proto2() async throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "req", number: 1, type: .string, isRequired: true))

    let msg = DynamicMessage(descriptor: desc)
    let factory = MessageFactory()

    let result = factory.validate(msg)
    XCTAssertFalse(result.isValid, "Proto2 message missing required field should be invalid")
  }

  func test_validate_readsSyntaxFromDescriptor_proto3() async throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto3")
    desc.addField(FieldDescriptor(name: "req", number: 1, type: .string, isRequired: true))

    let msg = DynamicMessage(descriptor: desc)
    let factory = MessageFactory()

    let result = factory.validate(msg)
    XCTAssertTrue(result.isValid, "Proto3 should ignore required fields")
  }

  func test_validate_proto2_allRequiredSet_valid() async throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "req", number: 1, type: .string, isRequired: true))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set("value", forField: "req")
    let factory = MessageFactory()

    let result = factory.validate(msg)
    XCTAssertTrue(result.isValid)
  }

  // swiftlint:disable:next deprecated_usage
  @available(*, deprecated)
  func test_validate_deprecatedSyntaxParam_stillWorks() async throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto3")
    desc.addField(FieldDescriptor(name: "req", number: 1, type: .string, isRequired: true))

    let msg = DynamicMessage(descriptor: desc)
    let factory = MessageFactory()

    // swiftlint:disable:next deprecated_usage
    let result = factory.validate(msg, syntax: "proto2")
    XCTAssertFalse(result.isValid, "Explicit syntax parameter should override descriptor.syntax")
  }
}
