import Foundation
import XCTest

@testable import SwiftProtoReflect

final class FieldAccessorEdgeCaseTests: XCTestCase {

  // MARK: - Helpers

  private func makeSimpleMessage() throws -> DynamicMessage {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    desc.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
    desc.addField(
      FieldDescriptor(
        name: "tags",
        number: 3,
        type: .string,
        isRepeated: true
      )
    )
    desc.addField(
      FieldDescriptor(
        name: "labels",
        number: 4,
        type: .message,
        typeName: "Entry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )
    var msg = DynamicMessage(descriptor: desc)
    try msg.set("Alice", forField: "name")
    try msg.set(Int32(30), forField: "age")
    try msg.set(["swift", "proto"] as [Any], forField: "tags")
    try msg.set(["env": "prod"] as [AnyHashable: Any], forField: "labels")
    return msg
  }

  // MARK: - getValue returns nil on nonexistent field (catch path)

  func test_getValue_byName_nonexistentField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getValue("nonexistent", as: String.self))
  }

  func test_getValue_byNumber_nonexistentField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getValue(999, as: String.self))
  }

  // MARK: - getValue returns nil on wrong type cast

  func test_getInt64_onStringField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getInt64("name"))
  }

  func test_getUInt32_onStringField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getUInt32("name"))
  }

  func test_getUInt64_onStringField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getUInt64("name"))
  }

  func test_getFloat_onStringField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getFloat("name"))
  }

  func test_getDouble_onStringField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getDouble("name"))
  }

  func test_getData_onStringField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getData("name"))
  }

  func test_getBool_onStringField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getBool("name"))
  }

  func test_getMessage_onStringField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getMessage("name"))
  }

  // MARK: - getRepeatedValue returns nil on nonexistent/wrong type

  func test_getStringArray_byName_nonexistentField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getStringArray("nonexistent"))
  }

  func test_getStringArray_byNumber_nonexistentField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getStringArray(999))
  }

  func test_getInt32Array_onStringArray_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getInt32Array("tags"))
  }

  func test_getInt64Array_onStringArray_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getInt64Array("tags"))
  }

  func test_getInt32Array_byNumber_onStringArray_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getInt32Array(3))
  }

  func test_getMessageArray_onStringArray_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getMessageArray("tags"))
  }

  // MARK: - getMapValue returns nil on nonexistent/wrong types

  func test_getStringMap_byName_nonexistentField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getStringMap("nonexistent"))
  }

  func test_getStringMap_byNumber_nonexistentField_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getStringMap(999))
  }

  func test_getStringToInt32Map_onStringToStringMap_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getStringToInt32Map("labels"))
  }

  func test_getStringToInt32Map_byNumber_onStringToStringMap_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getStringToInt32Map(4))
  }

  func test_getStringToMessageMap_onStringToStringMap_returnsNil() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertNil(accessor.getStringToMessageMap("labels"))
  }

  // MARK: - MutableFieldAccessor returning false

  func test_mutableSetString_nonexistentField_returnsFalse() async throws {
    var msg = try makeSimpleMessage()
    var accessor = MutableFieldAccessor(&msg)
    XCTAssertFalse(accessor.setString("x", forField: "nonexistent"))
    XCTAssertFalse(accessor.setString("x", forField: 999))
  }

  func test_mutableSetInt32_nonexistentField_returnsFalse() async throws {
    var msg = try makeSimpleMessage()
    var accessor = MutableFieldAccessor(&msg)
    XCTAssertFalse(accessor.setInt32(1, forField: "nonexistent"))
    XCTAssertFalse(accessor.setInt32(1, forField: 999))
  }

  func test_mutableSetBool_nonexistentField_returnsFalse() async throws {
    var msg = try makeSimpleMessage()
    var accessor = MutableFieldAccessor(&msg)
    XCTAssertFalse(accessor.setBool(true, forField: "nonexistent"))
    XCTAssertFalse(accessor.setBool(true, forField: 999))
  }

  func test_mutableSetMessage_nonexistentField_returnsFalse() async throws {
    var msg = try makeSimpleMessage()
    let nested = DynamicMessage(descriptor: MessageDescriptor(name: "N", fullName: "N"))
    var accessor = MutableFieldAccessor(&msg)
    XCTAssertFalse(accessor.setMessage(nested, forField: "nonexistent"))
    XCTAssertFalse(accessor.setMessage(nested, forField: 999))
  }

  // MARK: - hasValue returning false for nonexistent field

  func test_hasValue_byName_nonexistentField_returnsFalse() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertFalse(accessor.hasValue("nonexistent"))
  }

  func test_hasValue_byNumber_nonexistentField_returnsFalse() async throws {
    let msg = try makeSimpleMessage()
    let accessor = FieldAccessor(msg)
    XCTAssertFalse(accessor.hasValue(999))
  }
}
