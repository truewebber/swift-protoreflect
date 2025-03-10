import XCTest

@testable import SwiftProtoReflect

class ProtoValueTests: XCTestCase {

  // MARK: - Primitive Types Tests

  func testIntValue() {
    let value = ProtoValue.intValue(42)
    XCTAssertEqual(value.getInt(), 42)
    XCTAssertNil(value.getUInt())
    XCTAssertNil(value.getString())
    XCTAssertNil(value.getBool())
    XCTAssertNil(value.getFloat())
    XCTAssertNil(value.getDouble())
    XCTAssertNil(value.getBytes())
    XCTAssertNil(value.getMessage())
    XCTAssertNil(value.getRepeated())
    XCTAssertNil(value.getMap())
    XCTAssertNil(value.getEnum())
  }

  func testUIntValue() {
    let value = ProtoValue.uintValue(42)
    XCTAssertEqual(value.getUInt(), 42)
    XCTAssertNil(value.getInt())
  }

  func testFloatValue() {
    let value = ProtoValue.floatValue(3.14)
    XCTAssertEqual(value.getFloat(), 3.14)
    XCTAssertNil(value.getDouble())
    XCTAssertNil(value.getInt())
  }

  func testDoubleValue() {
    let value = ProtoValue.doubleValue(3.14159)
    XCTAssertEqual(value.getDouble(), 3.14159)
    XCTAssertNil(value.getFloat())
  }

  func testBoolValue() {
    let value = ProtoValue.boolValue(true)
    XCTAssertEqual(value.getBool(), true)
    XCTAssertNil(value.getInt())
  }

  // MARK: - String and Bytes Tests

  func testStringValue() {
    let value = ProtoValue.stringValue("hello")
    XCTAssertEqual(value.getString(), "hello")
    XCTAssertNil(value.getBytes())
  }

  func testBytesValue() {
    let data = Data([0x01, 0x02, 0x03])
    let value = ProtoValue.bytesValue(data)
    XCTAssertEqual(value.getBytes(), data)
    XCTAssertNil(value.getString())
  }

  // MARK: - Message Tests

  func testMessageValue() {
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [],
      enums: [],
      nestedMessages: []
    )
    let message = ProtoDynamicMessage(descriptor: descriptor)
    let value = ProtoValue.messageValue(message)

    XCTAssertNotNil(value.getMessage())
    XCTAssertEqual(value.getMessage()?.descriptor().fullName, "TestMessage")
  }

  // MARK: - Enum Tests

  func testEnumValue() {
    let enumDescriptor = ProtoEnumDescriptor(
      name: "TestEnum",
      values: [
        ProtoEnumValueDescriptor(name: "UNKNOWN", number: 0),
        ProtoEnumValueDescriptor(name: "VALUE1", number: 1),
      ]
    )

    let value = ProtoValue.enumValue(name: "VALUE1", number: 1, enumDescriptor: enumDescriptor)

    XCTAssertNotNil(value.getEnum())
    XCTAssertEqual(value.getEnum()?.name, "VALUE1")
    XCTAssertEqual(value.getEnum()?.number, 1)
    XCTAssertEqual(value.getEnum()?.enumDescriptor.name, "TestEnum")
  }

  // MARK: - Repeated Fields Tests

  func testRepeatedValue() {
    let values = [
      ProtoValue.intValue(1),
      ProtoValue.intValue(2),
      ProtoValue.intValue(3),
    ]

    let repeatedValue = ProtoValue.repeatedValue(values)

    XCTAssertNotNil(repeatedValue.getRepeated())
    XCTAssertEqual(repeatedValue.getRepeated()?.count, 3)
    XCTAssertEqual(repeatedValue.getRepeated()?[0].getInt(), 1)
    XCTAssertEqual(repeatedValue.getRepeated()?[1].getInt(), 2)
    XCTAssertEqual(repeatedValue.getRepeated()?[2].getInt(), 3)
  }

  // MARK: - Map Fields Tests

  func testMapValue() {
    let map: [String: ProtoValue] = [
      "key1": .intValue(1),
      "key2": .stringValue("value2"),
    ]

    let mapValue = ProtoValue.mapValue(map)

    XCTAssertNotNil(mapValue.getMap())
    XCTAssertEqual(mapValue.getMap()?.count, 2)
    XCTAssertEqual(mapValue.getMap()?["key1"]?.getInt(), 1)
    XCTAssertEqual(mapValue.getMap()?["key2"]?.getString(), "value2")
  }

  // MARK: - Equality and Hashing Tests

  func testEquality() {
    XCTAssertEqual(ProtoValue.intValue(42), ProtoValue.intValue(42))
    XCTAssertEqual(ProtoValue.stringValue("hello"), ProtoValue.stringValue("hello"))
    XCTAssertNotEqual(ProtoValue.intValue(42), ProtoValue.intValue(43))
    XCTAssertNotEqual(ProtoValue.intValue(42), ProtoValue.stringValue("42"))

    // Test repeated value equality
    let repeatedValue1 = ProtoValue.repeatedValue([.intValue(1), .intValue(2)])
    let repeatedValue2 = ProtoValue.repeatedValue([.intValue(1), .intValue(2)])
    let repeatedValue3 = ProtoValue.repeatedValue([.intValue(2), .intValue(1)])

    XCTAssertEqual(repeatedValue1, repeatedValue2)
    XCTAssertNotEqual(repeatedValue1, repeatedValue3)

    // Test map value equality
    let mapValue1 = ProtoValue.mapValue(["key1": .intValue(1), "key2": .intValue(2)])
    let mapValue2 = ProtoValue.mapValue(["key1": .intValue(1), "key2": .intValue(2)])
    let mapValue3 = ProtoValue.mapValue(["key1": .intValue(2), "key2": .intValue(1)])

    XCTAssertEqual(mapValue1, mapValue2)
    XCTAssertNotEqual(mapValue1, mapValue3)
  }

  func testHashing() {
    var set = Set<ProtoValue>()

    set.insert(.intValue(42))
    set.insert(.intValue(42))  // Duplicate
    set.insert(.stringValue("hello"))

    XCTAssertEqual(set.count, 2)
  }

  // MARK: - Type Conversion Tests

  func testAsInt32() {
    XCTAssertEqual(ProtoValue.intValue(42).asInt32(), 42)
    XCTAssertEqual(ProtoValue.uintValue(42).asInt32(), 42)
    XCTAssertEqual(ProtoValue.floatValue(42.0).asInt32(), 42)
    XCTAssertEqual(ProtoValue.doubleValue(42.0).asInt32(), 42)
    XCTAssertEqual(ProtoValue.boolValue(true).asInt32(), 1)
    XCTAssertEqual(ProtoValue.stringValue("42").asInt32(), 42)
    XCTAssertNil(ProtoValue.stringValue("not a number").asInt32())
  }

  func testAsUInt32() {
    XCTAssertEqual(ProtoValue.intValue(42).asUInt32(), 42)
    XCTAssertEqual(ProtoValue.uintValue(42).asUInt32(), 42)
    XCTAssertEqual(ProtoValue.floatValue(42.0).asUInt32(), 42)
    XCTAssertEqual(ProtoValue.doubleValue(42.0).asUInt32(), 42)
    XCTAssertEqual(ProtoValue.boolValue(true).asUInt32(), 1)
    XCTAssertEqual(ProtoValue.stringValue("42").asUInt32(), 42)
    XCTAssertNil(ProtoValue.stringValue("not a number").asUInt32())
    XCTAssertNil(ProtoValue.intValue(-1).asUInt32())  // Negative numbers can't be converted to unsigned
  }

  // MARK: - Validation Tests

  func testValidateAgainstFieldDescriptor() {
    let intField = ProtoFieldDescriptor(name: "intField", number: 1, type: .int32, isRepeated: false, isMap: false)
    let stringField = ProtoFieldDescriptor(
      name: "stringField",
      number: 2,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    let repeatedIntField = ProtoFieldDescriptor(
      name: "repeatedIntField",
      number: 3,
      type: .int32,
      isRepeated: true,
      isMap: false
    )

    // Valid cases
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: intField))
    XCTAssertTrue(ProtoValue.stringValue("hello").isValid(for: stringField))
    XCTAssertTrue(ProtoValue.repeatedValue([.intValue(1), .intValue(2)]).isValid(for: repeatedIntField))

    // Valid conversions
    // Int can be converted to String
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: stringField))

    // Invalid cases
    // String that can't be converted to Int
    XCTAssertFalse(ProtoValue.stringValue("not a number").isValid(for: intField))
    // Not a repeated value
    XCTAssertFalse(ProtoValue.intValue(42).isValid(for: repeatedIntField))
    // Wrong element type
    XCTAssertFalse(ProtoValue.repeatedValue([.stringValue("hello")]).isValid(for: repeatedIntField))
  }
}
