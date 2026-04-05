//
// Proto2JSONSerializationTests.swift
// SwiftProtoReflect
//
// Tests for proto2-specific JSON serialization features:
// group as JSON object, extension field serialization.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class Proto2JSONSerializationTests: XCTestCase {

  // MARK: - Group as JSON object

  func test_jsonSerialize_groupField_asNestedObject() throws {
    var groupDesc = MessageDescriptor(name: "G", fullName: "test.G", syntax: "proto2")
    groupDesc.addField(FieldDescriptor(name: "val", number: 1, type: .int32))

    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "my_group", number: 2, type: .group, typeName: "test.G"))
    desc.addNestedMessage(groupDesc)

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(1), forField: "id")
    var group = DynamicMessage(descriptor: groupDesc)
    try group.set(Int32(42), forField: "val")
    try msg.set(group, forField: "my_group")

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(useOriginalFieldNames: true, typeRegistry: TypeRegistry())
    )
    let json = try serializer.serializeToJSONObject(msg)

    XCTAssertNotNil(json["my_group"])
    let groupJson = json["my_group"] as? [String: Any]
    XCTAssertNotNil(groupJson)
    XCTAssertEqual(groupJson?["val"] as? Int, 42)
  }

  // MARK: - Extension fields in JSON

  func test_jsonSerialize_extensionField_included() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtension(FieldDescriptor(name: "ext_name", number: 100, type: .string))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(1), forField: 1)
    try msg.set("extended", forField: 100)

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(useOriginalFieldNames: true, typeRegistry: TypeRegistry())
    )
    let json = try serializer.serializeToJSONObject(msg)

    XCTAssertEqual(json["id"] as? Int, 1)
    XCTAssertEqual(json["ext_name"] as? String, "extended")
  }

  // MARK: - JSON round-trip for group

  func test_jsonRoundTrip_groupField() throws {
    let registry = TypeRegistry()

    var groupDesc = MessageDescriptor(name: "G", fullName: "test.G", syntax: "proto2")
    groupDesc.addField(FieldDescriptor(name: "val", number: 1, type: .int32))

    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "my_group", number: 2, type: .group, typeName: "test.G"))
    desc.addNestedMessage(groupDesc)
    try registry.registerMessage(desc)

    var group = DynamicMessage(descriptor: groupDesc)
    try group.set(Int32(42), forField: 1)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(7), forField: 1)
    try msg.set(group, forField: 2)

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(useOriginalFieldNames: true, typeRegistry: TypeRegistry())
    )
    let data = try serializer.serialize(msg)

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: registry)
    )
    let decoded = try deserializer.deserialize(data, using: desc)
    let decodedGroup = try decoded.get(forField: 2) as? DynamicMessage
    XCTAssertNotNil(decodedGroup)
    XCTAssertEqual(try decodedGroup?.get(forField: 1) as? Int32, 42)
    XCTAssertEqual(try decoded.get(forField: 1) as? Int32, 7)
  }

  // MARK: - JSON round-trip for extension

  func test_jsonRoundTrip_extensionField() throws {
    let registry = TypeRegistry()

    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtension(FieldDescriptor(name: "ext_value", number: 100, type: .string))
    try registry.registerMessage(desc)

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(5), forField: 1)
    try msg.set("hello", forField: 100)

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(useOriginalFieldNames: true, typeRegistry: TypeRegistry())
    )
    let data = try serializer.serialize(msg)

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: registry)
    )
    let decoded = try deserializer.deserialize(data, using: desc)

    XCTAssertEqual(try decoded.get(forField: 1) as? Int32, 5)
    XCTAssertEqual(try decoded.get(forField: 100) as? String, "hello")
  }
}
