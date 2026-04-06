import Foundation
import XCTest

@testable import SwiftProtoReflect

final class DynamicMessageEdgeCaseTests: XCTestCase {

  // MARK: - Set Message/Group field with wrong type

  func test_set_messageFieldWithString_throwsTypeMismatch() async throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "nested",
        number: 1,
        type: .message,
        typeName: "Inner"
      )
    )
    var msg = DynamicMessage(descriptor: desc)

    XCTAssertThrowsError(try msg.set("not_a_message", forField: "nested")) { error in
      guard case DynamicMessageError.typeMismatch(let fieldName, let expected, _) = error else {
        return XCTFail("Expected typeMismatch error")
      }
      XCTAssertEqual(fieldName, "nested")
      XCTAssertEqual(expected, "DynamicMessage")
    }
  }

  func test_set_groupFieldWithString_throwsTypeMismatch() async throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "grp",
        number: 1,
        type: .group,
        typeName: "MyGroup"
      )
    )
    var msg = DynamicMessage(descriptor: desc)

    XCTAssertThrowsError(try msg.set("not_a_group", forField: "grp")) { error in
      guard case DynamicMessageError.typeMismatch(let fieldName, let expected, _) = error else {
        return XCTFail("Expected typeMismatch error")
      }
      XCTAssertEqual(fieldName, "grp")
      XCTAssertEqual(expected, "DynamicMessage (group)")
    }
  }

  // MARK: - clearOneofField for map/repeated

  func test_clearOneof_repeatedField_clearsRepeated() async throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "names",
        number: 1,
        type: .string,
        isRepeated: true,
        oneofIndex: 0
      )
    )
    desc.addField(FieldDescriptor(name: "value", number: 2, type: .int32, oneofIndex: 0))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(["Alice", "Bob"] as [Any], forField: "names")
    let before = try msg.get(forField: "names") as? [Any]
    XCTAssertNotNil(before)

    try msg.set(Int32(42), forField: "value")
    let after = try msg.get(forField: "names") as? [Any]
    XCTAssertNil(after)
  }

  func test_clearOneof_mapField_clearsMap() async throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "labels",
        number: 1,
        type: .message,
        typeName: "Entry",
        isMap: true,
        oneofIndex: 0,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )
    desc.addField(FieldDescriptor(name: "count", number: 2, type: .int32, oneofIndex: 0))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(["k": "v"] as [AnyHashable: Any], forField: "labels")
    let before = try msg.get(forField: "labels") as? [AnyHashable: Any]
    XCTAssertNotNil(before)

    try msg.set(Int32(1), forField: "count")
    let after = try msg.get(forField: "labels") as? [AnyHashable: Any]
    XCTAssertNil(after)
  }

  // MARK: - NSNumber conversion for double field

  func test_set_doubleFieldWithNSNumber_convertsToDouble() async throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(FieldDescriptor(name: "val", number: 1, type: .double))
    var msg = DynamicMessage(descriptor: desc)

    let nsNum = NSNumber(value: Int32(42))
    try msg.set(nsNum, forField: "val")
    let result = try msg.get(forField: "val") as? Double
    XCTAssertEqual(result, 42.0)
  }

  // MARK: - invalidMapKeyType error

  func test_set_mapWithInvalidKeyType_throwsError() async throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "data",
        number: 1,
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

    XCTAssertThrowsError(try msg.set([Int32(1): "v"] as [AnyHashable: Any], forField: "data"))
  }
}
