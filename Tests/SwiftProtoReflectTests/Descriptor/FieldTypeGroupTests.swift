//
// FieldTypeGroupTests.swift
// SwiftProtoReflectTests
//

import XCTest

@testable import SwiftProtoReflect

final class FieldTypeGroupTests: XCTestCase {

  // MARK: - Binary Serialization

  func test_binarySerialize_groupField_throwsUnsupported() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(
      FieldDescriptor(name: "my_group", number: 1, type: .group, typeName: "test.MyGroup")
    )

    let innerDesc = MessageDescriptor(name: "MyGroup", fullName: "test.MyGroup")
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(DynamicMessage(descriptor: innerDesc), forField: 1)

    let serializer = BinarySerializer()
    XCTAssertThrowsError(try serializer.serialize(msg)) { error in
      guard let serError = error as? SerializationError,
        case .unsupportedFieldType(let typeName) = serError
      else {
        XCTFail("Expected unsupportedFieldType error, got \(error)")
        return
      }
      XCTAssertEqual(typeName, "group")
    }
  }

  // MARK: - JSON Serialization

  func test_jsonSerialize_groupField_throwsUnsupported() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(
      FieldDescriptor(name: "my_group", number: 1, type: .group, typeName: "test.MyGroup")
    )

    let innerDesc = MessageDescriptor(name: "MyGroup", fullName: "test.MyGroup")
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(DynamicMessage(descriptor: innerDesc), forField: 1)

    let serializer = JSONSerializer()
    XCTAssertThrowsError(try serializer.serialize(msg))
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
