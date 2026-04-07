//
// UnknownFieldsTests.swift
// SwiftProtoReflectTests
//

import XCTest

@testable import SwiftProtoReflect

final class UnknownFieldsTests: XCTestCase {

  // MARK: - Helpers

  private func makeDescriptor(fields: [FieldDescriptor] = []) -> MessageDescriptor {
    var desc = MessageDescriptor(name: "TestMessage", fullName: "test.TestMessage")
    for f in fields { desc.addField(f) }
    return desc
  }

  private let int32Field = FieldDescriptor(name: "value", number: 1, type: .int32)

  /// Builds raw binary: tag (varint) + value for a given field number and wire type.
  private func buildVarintField(fieldNumber: Int, value: UInt64) -> Data {
    var data = Data()
    let tag = UInt64((fieldNumber << 3) | 0)
    appendVarint(&data, tag)
    appendVarint(&data, value)
    return data
  }

  private func buildFixed32Field(fieldNumber: Int, value: UInt32) -> Data {
    var data = Data()
    let tag = UInt64((fieldNumber << 3) | 5)
    appendVarint(&data, tag)
    withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    return data
  }

  private func buildFixed64Field(fieldNumber: Int, value: UInt64) -> Data {
    var data = Data()
    let tag = UInt64((fieldNumber << 3) | 1)
    appendVarint(&data, tag)
    withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    return data
  }

  private func buildLengthDelimitedField(fieldNumber: Int, payload: Data) -> Data {
    var data = Data()
    let tag = UInt64((fieldNumber << 3) | 2)
    appendVarint(&data, tag)
    appendVarint(&data, UInt64(payload.count))
    data.append(payload)
    return data
  }

  private func appendVarint(_ data: inout Data, _ value: UInt64) {
    var val = value
    while val >= 0x80 {
      data.append(UInt8(val & 0x7F | 0x80))
      val >>= 7
    }
    data.append(UInt8(val & 0x7F))
  }

  // MARK: - Storage Tests

  func test_newMessage_unknownFieldsEmpty() async throws {
    let desc = makeDescriptor()
    let msg = DynamicMessage(descriptor: desc)
    XCTAssertTrue(msg.unknownFields.isEmpty)
  }

  func test_setUnknownFields_storedCorrectly() async throws {
    let desc = makeDescriptor()
    var msg = DynamicMessage(descriptor: desc)
    let payload = Data([0x08, 0x96, 0x01])
    msg.setUnknownFields(payload)
    XCTAssertEqual(msg.unknownFields, payload)
  }

  func test_clearUnknownFields_becomesEmpty() async throws {
    let desc = makeDescriptor()
    var msg = DynamicMessage(descriptor: desc)
    msg.setUnknownFields(Data([0x01, 0x02]))
    msg.setUnknownFields(Data())
    XCTAssertTrue(msg.unknownFields.isEmpty)
  }

  // MARK: - Binary Deserialization

  func test_deserialize_unknownVarintField_preserved() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    let unknownData = buildVarintField(fieldNumber: 99, value: 42)
    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(unknownData, using: desc)
    XCTAssertFalse(msg.unknownFields.isEmpty, "Unknown varint field should be preserved")
  }

  func test_deserialize_unknownFixed32Field_preserved() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    let unknownData = buildFixed32Field(fieldNumber: 99, value: 12345)
    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(unknownData, using: desc)
    XCTAssertFalse(msg.unknownFields.isEmpty)
  }

  func test_deserialize_unknownFixed64Field_preserved() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    let unknownData = buildFixed64Field(fieldNumber: 99, value: 123_456_789)
    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(unknownData, using: desc)
    XCTAssertFalse(msg.unknownFields.isEmpty)
  }

  func test_deserialize_unknownLengthDelimitedField_preserved() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    let unknownData = buildLengthDelimitedField(fieldNumber: 99, payload: Data([0xDE, 0xAD]))
    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(unknownData, using: desc)
    XCTAssertFalse(msg.unknownFields.isEmpty)
  }

  func test_deserialize_multipleUnknownFields_allPreserved() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    var binary = Data()
    binary.append(buildVarintField(fieldNumber: 90, value: 1))
    binary.append(buildFixed32Field(fieldNumber: 91, value: 2))
    binary.append(buildLengthDelimitedField(fieldNumber: 92, payload: Data([0xFF])))

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(binary, using: desc)
    XCTAssertFalse(msg.unknownFields.isEmpty)
    XCTAssertTrue(msg.unknownFields.count > 5, "Should contain data from all 3 unknown fields")
  }

  func test_deserialize_mixedKnownAndUnknown_bothHandled() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    var binary = Data()
    binary.append(buildVarintField(fieldNumber: 1, value: 42))
    binary.append(buildVarintField(fieldNumber: 99, value: 7))

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(binary, using: desc)

    let knownValue = try msg.get(forField: 1) as? Int32
    XCTAssertEqual(knownValue, 42)
    XCTAssertFalse(msg.unknownFields.isEmpty, "Unknown field 99 should be preserved")
  }

  func test_deserialize_preserveUnknownFieldsFalse_discarded() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    let unknownData = buildVarintField(fieldNumber: 99, value: 42)
    let opts = DeserializationOptions(preserveUnknownFields: false, typeRegistry: TypeRegistry())
    let deserializer = BinaryDeserializer(options: opts)
    let msg = try await deserializer.deserialize(unknownData, using: desc)
    XCTAssertTrue(msg.unknownFields.isEmpty)
  }

  func test_deserialize_onlyUnknownFields_messageEmptyButUnknownPresent() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    let unknownData = buildVarintField(fieldNumber: 50, value: 100)
    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(unknownData, using: desc)

    let hasKnown = try msg.hasValue(forField: 1)
    XCTAssertFalse(hasKnown)
    XCTAssertFalse(msg.unknownFields.isEmpty)
  }

  func test_deserialize_emptyData_noUnknownFields() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(Data(), using: desc)
    XCTAssertTrue(msg.unknownFields.isEmpty)
  }

  // MARK: - Serialization Round-trip

  func test_serialize_messageWithUnknownFields_appendedToOutput() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    var msg = DynamicMessage(descriptor: desc)
    let rawUnknown = buildVarintField(fieldNumber: 99, value: 77)
    msg.setUnknownFields(rawUnknown)

    let serializer = BinarySerializer()
    let output = try serializer.serialize(msg)
    XCTAssertTrue(output.count >= rawUnknown.count, "Output should contain the unknown field bytes")
    XCTAssertTrue(output.hasSuffix(rawUnknown), "Unknown fields should be appended at the end")
  }

  func test_roundTrip_unknownVarint_preserved() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    let unknownData = buildVarintField(fieldNumber: 99, value: 42)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(unknownData, using: desc)

    let serializer = BinarySerializer()
    let reencoded = try serializer.serialize(msg)

    let msg2 = try await deserializer.deserialize(reencoded, using: desc)
    XCTAssertEqual(msg.unknownFields, msg2.unknownFields)
  }

  func test_roundTrip_unknownFixed64_preserved() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    let unknownData = buildFixed64Field(fieldNumber: 99, value: 0xDEAD_BEEF_CAFE_BABE)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(unknownData, using: desc)

    let serializer = BinarySerializer()
    let reencoded = try serializer.serialize(msg)

    let msg2 = try await deserializer.deserialize(reencoded, using: desc)
    XCTAssertEqual(msg.unknownFields, msg2.unknownFields)
  }

  func test_roundTrip_unknownLengthDelimited_preserved() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    let unknownData = buildLengthDelimitedField(fieldNumber: 99, payload: Data("hello".utf8))

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(unknownData, using: desc)

    let serializer = BinarySerializer()
    let reencoded = try serializer.serialize(msg)

    let msg2 = try await deserializer.deserialize(reencoded, using: desc)
    XCTAssertEqual(msg.unknownFields, msg2.unknownFields)
  }

  func test_roundTrip_knownAndUnknown_bothPreserved() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    var binary = Data()
    binary.append(buildVarintField(fieldNumber: 1, value: 42))
    binary.append(buildVarintField(fieldNumber: 99, value: 7))

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(binary, using: desc)

    let serializer = BinarySerializer()
    let reencoded = try serializer.serialize(msg)

    let msg2 = try await deserializer.deserialize(reencoded, using: desc)
    let value = try msg2.get(forField: 1) as? Int32
    XCTAssertEqual(value, 42)
    XCTAssertEqual(msg.unknownFields, msg2.unknownFields)
  }

  // MARK: - Clone & Equality

  func test_clone_unknownFieldsCopied() async throws {
    let desc = makeDescriptor(fields: [int32Field])
    var msg = DynamicMessage(descriptor: desc)
    msg.setUnknownFields(Data([0xDE, 0xAD]))

    let factory = MessageFactory()
    let cloned = try factory.clone(msg)
    XCTAssertEqual(cloned.unknownFields, msg.unknownFields)
  }

  func test_equality_sameUnknownFields_equal() async throws {
    let desc = makeDescriptor()
    var msg1 = DynamicMessage(descriptor: desc)
    var msg2 = DynamicMessage(descriptor: desc)
    msg1.setUnknownFields(Data([0x01]))
    msg2.setUnknownFields(Data([0x01]))
    XCTAssertEqual(msg1, msg2)
  }

  func test_equality_differentUnknownFields_notEqual() async throws {
    let desc = makeDescriptor()
    var msg1 = DynamicMessage(descriptor: desc)
    var msg2 = DynamicMessage(descriptor: desc)
    msg1.setUnknownFields(Data([0x01]))
    msg2.setUnknownFields(Data([0x02]))
    XCTAssertNotEqual(msg1, msg2)
  }

  func test_equality_oneHasUnknownOtherNot_notEqual() async throws {
    let desc = makeDescriptor()
    var msg1 = DynamicMessage(descriptor: desc)
    let msg2 = DynamicMessage(descriptor: desc)
    msg1.setUnknownFields(Data([0x01]))
    XCTAssertNotEqual(msg1, msg2)
  }
}

extension Data {
  fileprivate func hasSuffix(_ other: Data) -> Bool {
    guard count >= other.count else { return false }
    return suffix(other.count) == other
  }
}
