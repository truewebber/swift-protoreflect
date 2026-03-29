//
// FieldTypeGroupTests.swift
// SwiftProtoReflectTests
//

import XCTest

@testable import SwiftProtoReflect

final class FieldTypeGroupTests: XCTestCase {

  // MARK: - Binary Serialization

  func test_binarySerialize_groupField_succeeds() throws {
    var innerDesc = MessageDescriptor(name: "MyGroup", fullName: "test.MyGroup")
    innerDesc.addField(FieldDescriptor(name: "v", number: 1, type: .int32))

    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(
      FieldDescriptor(name: "my_group", number: 1, type: .group, typeName: "test.MyGroup")
    )
    desc.addNestedMessage(innerDesc)

    var msg = DynamicMessage(descriptor: desc)
    var group = DynamicMessage(descriptor: innerDesc)
    try group.set(Int32(99), forField: "v")
    try msg.set(group, forField: 1)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)
    XCTAssertFalse(data.isEmpty)

    let decoded = try BinaryDeserializer().deserialize(data, using: desc)
    let decodedGroup = try decoded.get(forField: 1) as? DynamicMessage
    XCTAssertNotNil(decodedGroup)
    let v = try decodedGroup?.get(forField: "v") as? Int32
    XCTAssertEqual(v, 99)
  }

  // MARK: - JSON Serialization

  func test_jsonSerialize_groupField_succeeds() throws {
    var innerDesc = MessageDescriptor(name: "MyGroup", fullName: "test.MyGroup")
    innerDesc.addField(FieldDescriptor(name: "v", number: 1, type: .int32))

    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(
      FieldDescriptor(name: "my_group", number: 1, type: .group, typeName: "test.MyGroup")
    )
    desc.addNestedMessage(innerDesc)

    var group = DynamicMessage(descriptor: innerDesc)
    try group.set(Int32(42), forField: "v")

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(group, forField: 1)

    let serializer = JSONSerializer(options: JSONSerializationOptions(useOriginalFieldNames: true))
    let data = try serializer.serialize(msg)
    XCTAssertFalse(data.isEmpty)

    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let groupJson = json?["my_group"] as? [String: Any]
    XCTAssertNotNil(groupJson)
    XCTAssertEqual(groupJson?["v"] as? Int, 42)
  }

  // MARK: - Binary Deserialization

  func test_binaryDeserialize_groupWireType_throwsUnsupported() {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(FieldDescriptor(name: "value", number: 1, type: .int32))
    // Wire type 3 = start group, field number 1 => tag = (1 << 3) | 3 = 11 = 0x0B
    let data = Data([0x0B])
    let deserializer = BinaryDeserializer()
    XCTAssertThrowsError(try deserializer.deserialize(data, using: desc))
  }
}
