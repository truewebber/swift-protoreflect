//
// BinaryNestedMessageTests.swift
// SwiftProtoReflect
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class BinaryNestedMessageTests: XCTestCase {

  // MARK: - Helpers

  private func makeInnerDescriptor() -> MessageDescriptor {
    var inner = MessageDescriptor(name: "Inner", fullName: "test.Inner")
    inner.addField(
      FieldDescriptor(name: "value", number: 1, type: .int32, isRepeated: false)
    )
    inner.addField(
      FieldDescriptor(name: "label", number: 2, type: .string, isRepeated: false)
    )
    return inner
  }

  private func makeOuterDescriptor(inner: MessageDescriptor) -> MessageDescriptor {
    var outer = MessageDescriptor(name: "Outer", fullName: "test.Outer")
    outer.addField(
      FieldDescriptor(name: "id", number: 1, type: .int32, isRepeated: false)
    )
    outer.addField(
      FieldDescriptor(
        name: "inner",
        number: 2,
        type: .message,
        typeName: "test.Inner"
      )
    )
    outer.addNestedMessage(inner)
    return outer
  }

  private func makeDeepInnerDescriptor() -> MessageDescriptor {
    var deep = MessageDescriptor(name: "DeepInner", fullName: "test.DeepInner")
    deep.addField(
      FieldDescriptor(name: "deep_value", number: 1, type: .string)
    )
    return deep
  }

  private func makeMidDescriptor(deepInner: MessageDescriptor) -> MessageDescriptor {
    var mid = MessageDescriptor(name: "Mid", fullName: "test.Mid")
    mid.addField(
      FieldDescriptor(name: "name", number: 1, type: .string)
    )
    mid.addField(
      FieldDescriptor(
        name: "deep",
        number: 2,
        type: .message,
        typeName: "test.DeepInner"
      )
    )
    mid.addNestedMessage(deepInner)
    return mid
  }

  private func makeTopDescriptor(mid: MessageDescriptor) -> MessageDescriptor {
    var top = MessageDescriptor(name: "Top", fullName: "test.Top")
    top.addField(
      FieldDescriptor(name: "id", number: 1, type: .int32)
    )
    top.addField(
      FieldDescriptor(
        name: "mid",
        number: 2,
        type: .message,
        typeName: "test.Mid"
      )
    )
    top.addNestedMessage(mid)
    return top
  }

  // MARK: - Test: nested message round-trip via serializer+deserializer

  func test_deserialize_nestedMessage_decoded() throws {
    let inner = makeInnerDescriptor()
    let outer = makeOuterDescriptor(inner: inner)

    let factory = MessageFactory()
    var innerMsg = factory.createMessage(from: inner)
    try innerMsg.set(Int32(42), forField: "value")
    try innerMsg.set("hello", forField: "label")

    var outerMsg = factory.createMessage(from: outer)
    try outerMsg.set(Int32(1), forField: "id")
    try outerMsg.set(innerMsg, forField: "inner")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(outerMsg)

    let deserializer = BinaryDeserializer()
    let decoded = try deserializer.deserialize(data, using: outer)

    XCTAssertEqual(try decoded.get(forField: "id") as? Int32, 1)

    let decodedInner = try XCTUnwrap(try decoded.get(forField: "inner") as? DynamicMessage)
    XCTAssertEqual(try decodedInner.get(forField: "value") as? Int32, 42)
    XCTAssertEqual(try decodedInner.get(forField: "label") as? String, "hello")
  }

  func test_deserialize_nestedMessage_emptyInner_decoded() throws {
    let inner = makeInnerDescriptor()
    let outer = makeOuterDescriptor(inner: inner)

    let factory = MessageFactory()
    let innerMsg = factory.createMessage(from: inner)

    var outerMsg = factory.createMessage(from: outer)
    try outerMsg.set(Int32(5), forField: "id")
    try outerMsg.set(innerMsg, forField: "inner")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(outerMsg)

    let deserializer = BinaryDeserializer()
    let decoded = try deserializer.deserialize(data, using: outer)

    XCTAssertEqual(try decoded.get(forField: "id") as? Int32, 5)
    let decodedInner = try XCTUnwrap(try decoded.get(forField: "inner") as? DynamicMessage)
    XCTAssertNil(try decodedInner.get(forField: "value"))
    XCTAssertNil(try decodedInner.get(forField: "label"))
  }

  func test_deserialize_deeplyNestedMessage_decoded() throws {
    let deepInner = makeDeepInnerDescriptor()
    let mid = makeMidDescriptor(deepInner: deepInner)
    let top = makeTopDescriptor(mid: mid)

    let factory = MessageFactory()
    var deepMsg = factory.createMessage(from: deepInner)
    try deepMsg.set("deep_hello", forField: "deep_value")

    var midMsg = factory.createMessage(from: mid)
    try midMsg.set("mid_name", forField: "name")
    try midMsg.set(deepMsg, forField: "deep")

    var topMsg = factory.createMessage(from: top)
    try topMsg.set(Int32(99), forField: "id")
    try topMsg.set(midMsg, forField: "mid")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(topMsg)

    let deserializer = BinaryDeserializer()
    let decoded = try deserializer.deserialize(data, using: top)

    XCTAssertEqual(try decoded.get(forField: "id") as? Int32, 99)

    let decodedMid = try XCTUnwrap(try decoded.get(forField: "mid") as? DynamicMessage)
    XCTAssertEqual(try decodedMid.get(forField: "name") as? String, "mid_name")

    let decodedDeep = try XCTUnwrap(try decodedMid.get(forField: "deep") as? DynamicMessage)
    XCTAssertEqual(try decodedDeep.get(forField: "deep_value") as? String, "deep_hello")
  }

  func test_deserialize_nestedMessage_descriptorNotFound_throws() throws {
    var outer = MessageDescriptor(name: "Outer", fullName: "test.Outer")
    outer.addField(
      FieldDescriptor(name: "id", number: 1, type: .int32, isRepeated: false)
    )
    outer.addField(
      FieldDescriptor(
        name: "inner",
        number: 2,
        type: .message,
        typeName: "test.Unknown"
      )
    )

    let inner = makeInnerDescriptor()
    let fullOuter = makeOuterDescriptor(inner: inner)

    let factory = MessageFactory()
    var innerMsg = factory.createMessage(from: inner)
    try innerMsg.set(Int32(1), forField: "value")

    var outerMsg = factory.createMessage(from: fullOuter)
    try outerMsg.set(Int32(1), forField: "id")
    try outerMsg.set(innerMsg, forField: "inner")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(outerMsg)

    let deserializer = BinaryDeserializer()
    XCTAssertThrowsError(try deserializer.deserialize(data, using: outer)) { error in
      guard let deserError = error as? DeserializationError else {
        XCTFail("Expected DeserializationError, got \(error)")
        return
      }
      switch deserError {
      case .unsupportedNestedMessage:
        break
      default:
        XCTFail("Expected unsupportedNestedMessage, got \(deserError)")
      }
    }
  }

  func test_deserialize_repeatedNestedMessage_decoded() throws {
    let inner = makeInnerDescriptor()

    var outer = MessageDescriptor(name: "Outer", fullName: "test.Outer")
    outer.addField(
      FieldDescriptor(name: "id", number: 1, type: .int32, isRepeated: false)
    )
    outer.addField(
      FieldDescriptor(
        name: "items",
        number: 2,
        type: .message,
        typeName: "test.Inner",
        isRepeated: true
      )
    )
    outer.addNestedMessage(inner)

    let factory = MessageFactory()
    var item1 = factory.createMessage(from: inner)
    try item1.set(Int32(10), forField: "value")
    try item1.set("first", forField: "label")

    var item2 = factory.createMessage(from: inner)
    try item2.set(Int32(20), forField: "value")
    try item2.set("second", forField: "label")

    var outerMsg = factory.createMessage(from: outer)
    try outerMsg.set(Int32(1), forField: "id")
    try outerMsg.set([item1, item2] as [Any], forField: "items")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(outerMsg)

    let deserializer = BinaryDeserializer()
    let decoded = try deserializer.deserialize(data, using: outer)

    XCTAssertEqual(try decoded.get(forField: "id") as? Int32, 1)

    let items = try XCTUnwrap(try decoded.get(forField: "items") as? [Any])
    XCTAssertEqual(items.count, 2)

    let decodedItem1 = try XCTUnwrap(items[0] as? DynamicMessage)
    XCTAssertEqual(try decodedItem1.get(forField: "value") as? Int32, 10)
    XCTAssertEqual(try decodedItem1.get(forField: "label") as? String, "first")

    let decodedItem2 = try XCTUnwrap(items[1] as? DynamicMessage)
    XCTAssertEqual(try decodedItem2.get(forField: "value") as? Int32, 20)
    XCTAssertEqual(try decodedItem2.get(forField: "label") as? String, "second")
  }

  func test_deserialize_nestedMessage_onlyId_innerNotSet() throws {
    let inner = makeInnerDescriptor()
    let outer = makeOuterDescriptor(inner: inner)

    let factory = MessageFactory()
    var outerMsg = factory.createMessage(from: outer)
    try outerMsg.set(Int32(7), forField: "id")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(outerMsg)

    let deserializer = BinaryDeserializer()
    let decoded = try deserializer.deserialize(data, using: outer)

    XCTAssertEqual(try decoded.get(forField: "id") as? Int32, 7)
    XCTAssertNil(try decoded.get(forField: "inner"))
  }
}
