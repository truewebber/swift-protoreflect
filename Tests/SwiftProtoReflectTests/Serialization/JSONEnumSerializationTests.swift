//
// JSONEnumSerializationTests.swift
// SwiftProtoReflectTests
//

import XCTest

@testable import SwiftProtoReflect

final class JSONEnumSerializationTests: XCTestCase {

  // MARK: - Helpers

  private func makeDescriptorWithEnum() -> (MessageDescriptor, EnumDescriptor) {
    var enumDesc = EnumDescriptor(name: "Status", fullName: "test.Status")
    enumDesc.addValue(.init(name: "UNKNOWN", number: 0))
    enumDesc.addValue(.init(name: "ACTIVE", number: 1))
    enumDesc.addValue(.init(name: "INACTIVE", number: 2))

    var msgDesc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    msgDesc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "test.Status", jsonName: "status")
    )
    msgDesc.addNestedEnum(enumDesc)
    return (msgDesc, enumDesc)
  }

  private func jsonDict(_ data: Data) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: data) as! [String: Any]
  }

  // MARK: - Serialization

  func test_serialize_knownEnumValue_emitsName() async throws {
    let (desc, _) = makeDescriptorWithEnum()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(1), forField: 1)

    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let json = try await jsonDict(serializer.serialize(msg))
    XCTAssertEqual(json["status"] as? String, "ACTIVE")
  }

  func test_serialize_zeroEnumValue_emitsZeroName() async throws {
    let (desc, _) = makeDescriptorWithEnum()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(0), forField: 1)

    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let json = try await jsonDict(serializer.serialize(msg))
    XCTAssertEqual(json["status"] as? String, "UNKNOWN")
  }

  func test_serialize_unknownEnumValue_emitsNumber() async throws {
    let (desc, _) = makeDescriptorWithEnum()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(999), forField: 1)

    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let json = try await jsonDict(serializer.serialize(msg))
    XCTAssertEqual(json["status"] as? Int, 999)
  }

  func test_serialize_repeatedEnum_emitsNameArray() async throws {
    let (_, enumDesc) = makeDescriptorWithEnum()
    var msgDesc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    msgDesc.addField(
      FieldDescriptor(
        name: "statuses",
        number: 1,
        type: .enum,
        typeName: "test.Status",
        jsonName: "statuses",
        isRepeated: true
      )
    )
    msgDesc.addNestedEnum(enumDesc)

    var msg = DynamicMessage(descriptor: msgDesc)
    try msg.set([Int32(0), Int32(1), Int32(2)], forField: 1)

    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let json = try await jsonDict(serializer.serialize(msg))
    let arr = json["statuses"] as? [Any]
    XCTAssertEqual(arr?[0] as? String, "UNKNOWN")
    XCTAssertEqual(arr?[1] as? String, "ACTIVE")
    XCTAssertEqual(arr?[2] as? String, "INACTIVE")
  }

  func test_serialize_enumWithoutDescriptor_fallbackToNumber() async throws {
    var msgDesc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    msgDesc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "test.UnknownEnum", jsonName: "status")
    )

    var msg = DynamicMessage(descriptor: msgDesc)
    try msg.set(Int32(42), forField: 1)

    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let json = try await jsonDict(serializer.serialize(msg))
    XCTAssertEqual(json["status"] as? Int, 42)
  }

  // MARK: - Deserialization

  func test_deserialize_enumByName_returnsNumber() async throws {
    let (desc, _) = makeDescriptorWithEnum()
    let jsonData = try JSONSerialization.data(withJSONObject: ["status": "ACTIVE"])
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(jsonData, using: desc)
    let value = try msg.get(forField: 1) as? Int32
    XCTAssertEqual(value, 1)
  }

  func test_deserialize_enumByNumber_returnsNumber() async throws {
    let (desc, _) = makeDescriptorWithEnum()
    let jsonData = try JSONSerialization.data(withJSONObject: ["status": 1])
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(jsonData, using: desc)
    let value = try msg.get(forField: 1) as? Int32
    XCTAssertEqual(value, 1)
  }

  func test_deserialize_enumByStringNumber_returnsNumber() async throws {
    let (desc, _) = makeDescriptorWithEnum()
    let jsonData = try JSONSerialization.data(withJSONObject: ["status": "1"])
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(jsonData, using: desc)
    let value = try msg.get(forField: 1) as? Int32
    XCTAssertEqual(value, 1)
  }

  func test_deserialize_unknownEnumName_throwsError() async throws {
    let (desc, _) = makeDescriptorWithEnum()
    let jsonData = try JSONSerialization.data(withJSONObject: ["status": "NONEXISTENT"])
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    do {
      try await deserializer.deserialize(jsonData, using: desc)
      XCTFail("Expected error to be thrown")
    }
    catch {
      // expected error
    }
  }

  // MARK: - Round-trip

  func test_roundTrip_knownEnumValue_preserved() async throws {
    let (desc, _) = makeDescriptorWithEnum()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(1), forField: 1)

    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let json = try await serializer.serialize(msg)

    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let restored = try await deserializer.deserialize(json, using: desc)
    let value = try restored.get(forField: 1) as? Int32
    XCTAssertEqual(value, 1)
  }

  func test_roundTrip_zeroEnumValue_preserved() async throws {
    let (desc, _) = makeDescriptorWithEnum()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(0), forField: 1)

    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let json = try await serializer.serialize(msg)

    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let restored = try await deserializer.deserialize(json, using: desc)
    let value = try restored.get(forField: 1) as? Int32
    XCTAssertEqual(value, 0)
  }
}
