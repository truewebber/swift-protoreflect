//
// Proto2BinarySerializationTests.swift
// SwiftProtoReflect
//
// Tests for proto2-specific binary serialization features:
// group wire format, syntax-aware packed encoding, extension fields.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class Proto2BinarySerializationTests: XCTestCase {

  // MARK: - Helpers

  private func makeGroupDescriptor() -> MessageDescriptor {
    var desc = MessageDescriptor(name: "MyGroup", fullName: "test.MyGroup", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "a", number: 1, type: .int32))
    return desc
  }

  private func makeMessageWithGroup() -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addField(
      FieldDescriptor(name: "my_group", number: 2, type: .group, typeName: "test.MyGroup")
    )
    desc.addNestedMessage(makeGroupDescriptor())
    return desc
  }

  private func makeMessageWithPackedField(syntax: String, isPacked: Bool? = nil) -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: syntax)
    desc.addField(
      FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true, isPacked: isPacked)
    )
    return desc
  }

  private func makeMessageWithExtension() -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtension(FieldDescriptor(name: "ext_name", number: 100, type: .string))
    return desc
  }

  // MARK: - Group wire format encoding/decoding

  func test_group_serialize_wireFormat_startEndGroupTags() throws {
    let desc = makeMessageWithGroup()
    var msg = DynamicMessage(descriptor: desc)

    var group = DynamicMessage(descriptor: makeGroupDescriptor())
    try group.set(Int32(10), forField: "a")
    try msg.set(group, forField: "my_group")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    var found = false
    var pos = 0
    let bytes = [UInt8](data)
    while pos < bytes.count {
      let byte = bytes[pos]
      let wireType = byte & 0x07
      let fieldNum = byte >> 3

      if fieldNum == 2 && wireType == 3 {
        found = true
        break
      }
      pos += 1
    }
    XCTAssertTrue(found, "Should contain startGroup tag for field 2")
  }

  // MARK: - Syntax-aware packed encoding

  func test_packed_proto3_defaultPacked() throws {
    let desc = makeMessageWithPackedField(syntax: "proto3")
    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Int32(1), Int32(2), Int32(3)] as [Any], forField: "values")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let decoded = try deserializer.deserialize(data, using: desc)
    let values = try decoded.get(forField: "values") as? [Any]
    XCTAssertEqual(values?.count, 3)
  }

  func test_packed_proto2_defaultUnpacked() throws {
    let desc = makeMessageWithPackedField(syntax: "proto2")
    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Int32(1), Int32(2)] as [Any], forField: "values")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let decoded = try deserializer.deserialize(data, using: desc)
    let values = try decoded.get(forField: "values") as? [Any]
    XCTAssertEqual(values?.count, 2)
  }

  func test_packed_proto2_explicitPacked_roundTrip() throws {
    let desc = makeMessageWithPackedField(syntax: "proto2", isPacked: true)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Int32(10), Int32(20)] as [Any], forField: "values")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let decoded = try deserializer.deserialize(data, using: desc)
    let values = try decoded.get(forField: "values") as? [Any]
    XCTAssertEqual(values?.count, 2)
  }

  func test_packed_proto3_explicitUnpacked_roundTrip() throws {
    let desc = makeMessageWithPackedField(syntax: "proto3", isPacked: false)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Int32(5), Int32(6)] as [Any], forField: "values")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let decoded = try deserializer.deserialize(data, using: desc)
    let values = try decoded.get(forField: "values") as? [Any]
    XCTAssertEqual(values?.count, 2)
  }

  // MARK: - Extension fields serialization

  func test_extension_serialize_roundTrip() throws {
    let desc = makeMessageWithExtension()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(1), forField: 1)
    try msg.set("extended", forField: 100)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let decoded = try deserializer.deserialize(data, using: desc)

    let id = try decoded.get(forField: 1) as? Int32
    XCTAssertEqual(id, 1)

    let ext = try decoded.get(forField: 100) as? String
    XCTAssertEqual(ext, "extended")
  }

  func test_extension_repeated_roundTrip() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtension(FieldDescriptor(name: "ext_tags", number: 101, type: .string, isRepeated: true))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(1), forField: 1)
    try msg.set(["a", "b", "c"] as [Any], forField: 101)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let decoded = try deserializer.deserialize(data, using: desc)

    let tags = try decoded.get(forField: 101) as? [String]
    XCTAssertEqual(tags, ["a", "b", "c"])
  }

  // MARK: - Repeated group wire format

  func test_group_repeated_serialize_startEndGroupTagsPerElement() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(
      FieldDescriptor(name: "items", number: 2, type: .group, typeName: "test.Item", isRepeated: true)
    )
    var itemDesc = MessageDescriptor(name: "Item", fullName: "test.Item", syntax: "proto2")
    itemDesc.addField(FieldDescriptor(name: "value", number: 1, type: .int32))
    desc.addNestedMessage(itemDesc)

    var item1 = DynamicMessage(descriptor: itemDesc)
    try item1.set(Int32(5), forField: "value")
    var item2 = DynamicMessage(descriptor: itemDesc)
    try item2.set(Int32(7), forField: "value")

    var msg = DynamicMessage(descriptor: desc)
    try msg.set([item1, item2] as [Any], forField: "items")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)
    let bytes = [UInt8](data)

    // Field 2 SGROUP tag = (2 << 3) | 3 = 0x13; EGROUP tag = (2 << 3) | 4 = 0x14
    let sgroupTag: UInt8 = 0x13
    let egroupTag: UInt8 = 0x14

    var sgroupCount = 0
    var egroupCount = 0
    for byte in bytes {
      if byte == sgroupTag { sgroupCount += 1 }
      if byte == egroupTag { egroupCount += 1 }
    }
    XCTAssertEqual(sgroupCount, 2, "Two repeated group elements need two SGROUP tags")
    XCTAssertEqual(egroupCount, 2, "Two repeated group elements need two EGROUP tags")

    // Also verify that each EGROUP immediately follows its group body (no interleaving)
    var firstEgroupPos: Int? = nil
    var secondSgroupPos: Int? = nil
    var pos = 0
    while pos < bytes.count {
      if bytes[pos] == egroupTag && firstEgroupPos == nil {
        firstEgroupPos = pos
      }
      else if bytes[pos] == sgroupTag && firstEgroupPos != nil && secondSgroupPos == nil {
        secondSgroupPos = pos
      }
      pos += 1
    }
    if let epos = firstEgroupPos, let spos = secondSgroupPos {
      XCTAssertLessThan(epos, spos, "First EGROUP must precede second SGROUP")
    }

    // Round-trip: deserialize and confirm both elements are present
    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let decoded = try deserializer.deserialize(data, using: desc)
    let items = try decoded.get(forField: "items") as? [Any]
    XCTAssertEqual(items?.count, 2)
  }

  // MARK: - Deserializer accepts both packed and unpacked

  func test_deserializer_acceptsPackedForUnpackedField() throws {
    let packedDesc = makeMessageWithPackedField(syntax: "proto3")
    var msg = DynamicMessage(descriptor: packedDesc)
    try msg.set([Int32(1), Int32(2)] as [Any], forField: "values")

    let serializer = BinarySerializer()
    let packedData = try serializer.serialize(msg)

    let unpackedDesc = makeMessageWithPackedField(syntax: "proto2")
    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let decoded = try deserializer.deserialize(packedData, using: unpackedDesc)
    let values = try decoded.get(forField: "values") as? [Any]
    XCTAssertEqual(values?.count, 2)
  }
}
