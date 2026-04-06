//
// CPPCompatibilityTests.swift
// SwiftProtoReflect
//
// Tests verifying C++ Protocol Buffers implementation compatibility.
// These tests check that our library produces and consumes the same wire
// format as the C++ reference implementation (protoc).
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class CPPCompatibilityTests: XCTestCase {

  // MARK: - Helpers

  private let serializer = BinarySerializer()
  private let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
  private let factory = MessageFactory()

  // MARK: - Unknown fields preserved across round-trip

  func test_unknownFields_preservedAcrossRoundTrip() async throws {
    var fullDesc = MessageDescriptor(name: "M", fullName: "test.M")
    fullDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    fullDesc.addField(FieldDescriptor(name: "extra", number: 2, type: .string))

    var original = factory.createMessage(from: fullDesc)
    try original.set(Int32(42), forField: "id")
    try original.set("hidden", forField: "extra")
    let data = try await serializer.serialize(original)

    var reducedDesc = MessageDescriptor(name: "M", fullName: "test.M")
    reducedDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let partial = try await deserializer.deserialize(data, using: reducedDesc)
    XCTAssertEqual(try partial.get(forField: "id") as? Int32, 42)
    XCTAssertFalse(partial.unknownFields.isEmpty)

    let reencoded = try await serializer.serialize(partial)
    let restored = try await deserializer.deserialize(reencoded, using: fullDesc)
    XCTAssertEqual(try restored.get(forField: "id") as? Int32, 42)
    XCTAssertEqual(try restored.get(forField: "extra") as? String, "hidden")
  }

  // MARK: - Field identified by number, not name

  func test_fieldIdentifiedByNumber_notName() async throws {
    var writerDesc = MessageDescriptor(name: "M", fullName: "test.M")
    writerDesc.addField(FieldDescriptor(name: "old_name", number: 1, type: .int32))

    var msg = factory.createMessage(from: writerDesc)
    try msg.set(Int32(99), forField: "old_name")
    let data = try await serializer.serialize(msg)

    var readerDesc = MessageDescriptor(name: "M", fullName: "test.M")
    readerDesc.addField(FieldDescriptor(name: "new_name", number: 1, type: .int32))

    let decoded = try await deserializer.deserialize(data, using: readerDesc)
    XCTAssertEqual(
      try decoded.get(forField: "new_name") as? Int32,
      99,
      "Wire format uses field numbers, not names"
    )
  }

  // MARK: - Edge values of numeric types

  func test_int32_extremeValues() async throws {
    // 0 is the proto3 default and is omitted from wire; excluded from round-trip.
    for value: Int32 in [.min, .max, 1, -1] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .int32))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try await serializer.serialize(msg)
      let decoded = try await deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? Int32, value, "Round-trip failed for \(value)")
    }
  }

  func test_int64_extremeValues() async throws {
    // 0 is the proto3 default and is omitted from wire; excluded from round-trip.
    for value: Int64 in [.min, .max, 1, -1] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .int64))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try await serializer.serialize(msg)
      let decoded = try await deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? Int64, value, "Round-trip failed for \(value)")
    }
  }

  func test_uint32_extremeValues() async throws {
    // 0 (.min) is the proto3 default and is omitted from wire; excluded from round-trip.
    for value: UInt32 in [.max, 1] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .uint32))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try await serializer.serialize(msg)
      let decoded = try await deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? UInt32, value, "Round-trip failed for \(value)")
    }
  }

  func test_uint64_extremeValues() async throws {
    // 0 (.min) is the proto3 default and is omitted from wire; excluded from round-trip.
    for value: UInt64 in [.max, 1] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .uint64))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try await serializer.serialize(msg)
      let decoded = try await deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? UInt64, value, "Round-trip failed for \(value)")
    }
  }

  // MARK: - Float special values

  func test_float_specialValues() async throws {
    // 0.0 is the proto3 default and is omitted from wire; excluded from round-trip.
    for value: Float in [.infinity, -.infinity, .greatestFiniteMagnitude, .leastNonzeroMagnitude] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .float))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try await serializer.serialize(msg)
      let decoded = try await deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? Float, value, "Round-trip failed for \(value)")
    }
  }

  func test_float_NaN() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .float))

    var msg = factory.createMessage(from: desc)
    try msg.set(Float.nan, forField: "v")
    let data = try await serializer.serialize(msg)
    let decoded = try await deserializer.deserialize(data, using: desc)
    let result = try decoded.get(forField: "v") as? Float
    XCTAssertNotNil(result)
    XCTAssertTrue(result!.isNaN)
  }

  func test_double_specialValues() async throws {
    // 0.0 is the proto3 default and is omitted from wire; excluded from round-trip.
    for value: Double in [.infinity, -.infinity, .greatestFiniteMagnitude, .leastNonzeroMagnitude] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .double))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try await serializer.serialize(msg)
      let decoded = try await deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? Double, value, "Round-trip failed for \(value)")
    }
  }

  func test_double_NaN() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .double))

    var msg = factory.createMessage(from: desc)
    try msg.set(Double.nan, forField: "v")
    let data = try await serializer.serialize(msg)
    let decoded = try await deserializer.deserialize(data, using: desc)
    let result = try decoded.get(forField: "v") as? Double
    XCTAssertNotNil(result)
    XCTAssertTrue(result!.isNaN)
  }

  // MARK: - Packed repeated encoding

  func test_packedRepeated_roundtrip() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(
      FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true)
    )

    var msg = factory.createMessage(from: desc)
    try msg.set([Int32(1), Int32(2), Int32(3)] as [Any], forField: "values")

    let data = try await serializer.serialize(msg)
    let decoded = try await deserializer.deserialize(data, using: desc)

    let values = try decoded.get(forField: "values")
    let arr = values as? [Any]
    XCTAssertNotNil(arr)
    XCTAssertEqual(arr?.count, 3)
  }

  // MARK: - F. C++ Compatibility: sibling message wire format

  func test_cppCompat_binaryFormat_siblingMessageReference_matchesExpected() async throws {
    // Verifies that our serialiser produces the canonical protobuf wire format for a
    // message field referencing a sibling type, and that our deserialiser (with registry)
    // can parse the same bytes a C++ implementation would produce.
    //
    // Schema:
    //   message A { string value = 1; }
    //   message B { A a = 1; }
    //
    // Wire bytes for B { a: A { value: "hi" } }:
    //   Field 1 (LV): tag=0x0A, len=4, inner=[tag=0x0A, len=2, 0x68, 0x69]
    var descA = MessageDescriptor(name: "A", fullName: "cpp.A")
    descA.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    var descB = MessageDescriptor(name: "B", fullName: "cpp.B")
    descB.addField(FieldDescriptor(name: "a", number: 1, type: .message, typeName: "cpp.A"))

    // Expected bytes: "hi" = 0x68 0x69
    // A bytes: [0x0A, 0x02, 0x68, 0x69] (field 1 string, len 2, "hi")
    // B bytes: [0x0A, 0x04, 0x0A, 0x02, 0x68, 0x69] (field 1 LV, len 4, A bytes)
    let expectedBytes: [UInt8] = [0x0A, 0x04, 0x0A, 0x02, 0x68, 0x69]

    var msgA = factory.createMessage(from: descA)
    try msgA.set("hi", forField: "value")
    var msgB = factory.createMessage(from: descB)
    try msgB.set(msgA, forField: "a")
    let producedData = try await serializer.serialize(msgB)

    XCTAssertEqual([UInt8](producedData), expectedBytes, "Wire format must match C++ output")

    // Deserialise the canonical bytes using registry.
    let registry = TypeRegistry()
    try await registry.registerMessage(descA)
    let opts = DeserializationOptions(typeRegistry: registry)
    let cppBytes = Data(expectedBytes)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(cppBytes, using: descB)

    let decodedA = try XCTUnwrap(decoded.get(forField: "a") as? DynamicMessage)
    XCTAssertEqual(try decodedA.get(forField: "value") as? String, "hi")
  }

  func test_cppCompat_binaryFormat_nestedSiblingChain_matchesExpected() async throws {
    // Verifies the canonical wire format for a two-level sibling chain:
    //   message Inner { int32 n = 1; }
    //   message Middle { Inner inner = 1; }
    //   message Outer  { Middle middle = 1; }
    //
    // n=7: varint 0x07
    // Inner:  [0x08, 0x07]              (field 1 varint, 7)
    // Middle: [0x0A, 0x02, 0x08, 0x07]  (field 1 LV, len 2, Inner bytes)
    // Outer:  [0x0A, 0x04, 0x0A, 0x02, 0x08, 0x07]  (field 1 LV, len 4, Middle bytes)
    var innerDesc = MessageDescriptor(name: "Inner", fullName: "chain.Inner")
    innerDesc.addField(FieldDescriptor(name: "n", number: 1, type: .int32))

    var middleDesc = MessageDescriptor(name: "Middle", fullName: "chain.Middle")
    middleDesc.addField(
      FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "chain.Inner")
    )

    var outerDesc = MessageDescriptor(name: "Outer", fullName: "chain.Outer")
    outerDesc.addField(
      FieldDescriptor(name: "middle", number: 1, type: .message, typeName: "chain.Middle")
    )

    let expectedBytes: [UInt8] = [0x0A, 0x04, 0x0A, 0x02, 0x08, 0x07]

    var innerMsg = factory.createMessage(from: innerDesc)
    try innerMsg.set(Int32(7), forField: "n")
    var middleMsg = factory.createMessage(from: middleDesc)
    try middleMsg.set(innerMsg, forField: "inner")
    var outerMsg = factory.createMessage(from: outerDesc)
    try outerMsg.set(middleMsg, forField: "middle")
    let producedData = try await serializer.serialize(outerMsg)

    XCTAssertEqual([UInt8](producedData), expectedBytes, "Wire format must match C++ output")

    // Deserialise canonical bytes with registry.
    let registry = TypeRegistry()
    try await registry.registerMessage(innerDesc)
    try await registry.registerMessage(middleDesc)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(
      Data(expectedBytes),
      using: outerDesc
    )

    let decodedMiddle = try XCTUnwrap(decoded.get(forField: "middle") as? DynamicMessage)
    let decodedInner = try XCTUnwrap(decodedMiddle.get(forField: "inner") as? DynamicMessage)
    XCTAssertEqual(try decodedInner.get(forField: "n") as? Int32, 7)
  }
}
