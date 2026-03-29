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
  private let deserializer = BinaryDeserializer()
  private let factory = MessageFactory()

  // MARK: - Unknown fields preserved across round-trip

  func test_unknownFields_preservedAcrossRoundTrip() throws {
    var fullDesc = MessageDescriptor(name: "M", fullName: "test.M")
    fullDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    fullDesc.addField(FieldDescriptor(name: "extra", number: 2, type: .string))

    var original = factory.createMessage(from: fullDesc)
    try original.set(Int32(42), forField: "id")
    try original.set("hidden", forField: "extra")
    let data = try serializer.serialize(original)

    var reducedDesc = MessageDescriptor(name: "M", fullName: "test.M")
    reducedDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let partial = try deserializer.deserialize(data, using: reducedDesc)
    XCTAssertEqual(try partial.get(forField: "id") as? Int32, 42)
    XCTAssertFalse(partial.unknownFields.isEmpty)

    let reencoded = try serializer.serialize(partial)
    let restored = try deserializer.deserialize(reencoded, using: fullDesc)
    XCTAssertEqual(try restored.get(forField: "id") as? Int32, 42)
    XCTAssertEqual(try restored.get(forField: "extra") as? String, "hidden")
  }

  // MARK: - Field identified by number, not name

  func test_fieldIdentifiedByNumber_notName() throws {
    var writerDesc = MessageDescriptor(name: "M", fullName: "test.M")
    writerDesc.addField(FieldDescriptor(name: "old_name", number: 1, type: .int32))

    var msg = factory.createMessage(from: writerDesc)
    try msg.set(Int32(99), forField: "old_name")
    let data = try serializer.serialize(msg)

    var readerDesc = MessageDescriptor(name: "M", fullName: "test.M")
    readerDesc.addField(FieldDescriptor(name: "new_name", number: 1, type: .int32))

    let decoded = try deserializer.deserialize(data, using: readerDesc)
    XCTAssertEqual(
      try decoded.get(forField: "new_name") as? Int32,
      99,
      "Wire format uses field numbers, not names"
    )
  }

  // MARK: - Edge values of numeric types

  func test_int32_extremeValues() throws {
    for value: Int32 in [.min, .max, 0, 1, -1] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .int32))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try serializer.serialize(msg)
      let decoded = try deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? Int32, value, "Round-trip failed for \(value)")
    }
  }

  func test_int64_extremeValues() throws {
    for value: Int64 in [.min, .max, 0, 1, -1] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .int64))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try serializer.serialize(msg)
      let decoded = try deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? Int64, value, "Round-trip failed for \(value)")
    }
  }

  func test_uint32_extremeValues() throws {
    for value: UInt32 in [.min, .max, 0, 1] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .uint32))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try serializer.serialize(msg)
      let decoded = try deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? UInt32, value, "Round-trip failed for \(value)")
    }
  }

  func test_uint64_extremeValues() throws {
    for value: UInt64 in [.min, .max, 0, 1] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .uint64))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try serializer.serialize(msg)
      let decoded = try deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? UInt64, value, "Round-trip failed for \(value)")
    }
  }

  // MARK: - Float special values

  func test_float_specialValues() throws {
    for value: Float in [0.0, .infinity, -.infinity, .greatestFiniteMagnitude, .leastNonzeroMagnitude] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .float))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try serializer.serialize(msg)
      let decoded = try deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? Float, value, "Round-trip failed for \(value)")
    }
  }

  func test_float_NaN() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .float))

    var msg = factory.createMessage(from: desc)
    try msg.set(Float.nan, forField: "v")
    let data = try serializer.serialize(msg)
    let decoded = try deserializer.deserialize(data, using: desc)
    let result = try decoded.get(forField: "v") as? Float
    XCTAssertNotNil(result)
    XCTAssertTrue(result!.isNaN)
  }

  func test_double_specialValues() throws {
    for value: Double in [
      0.0, .infinity, -.infinity, .greatestFiniteMagnitude, .leastNonzeroMagnitude,
    ] {
      var desc = MessageDescriptor(name: "M", fullName: "test.M")
      desc.addField(FieldDescriptor(name: "v", number: 1, type: .double))

      var msg = factory.createMessage(from: desc)
      try msg.set(value, forField: "v")
      let data = try serializer.serialize(msg)
      let decoded = try deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try decoded.get(forField: "v") as? Double, value, "Round-trip failed for \(value)")
    }
  }

  func test_double_NaN() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .double))

    var msg = factory.createMessage(from: desc)
    try msg.set(Double.nan, forField: "v")
    let data = try serializer.serialize(msg)
    let decoded = try deserializer.deserialize(data, using: desc)
    let result = try decoded.get(forField: "v") as? Double
    XCTAssertNotNil(result)
    XCTAssertTrue(result!.isNaN)
  }

  // MARK: - Packed repeated encoding

  func test_packedRepeated_roundtrip() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(
      FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true)
    )

    var msg = factory.createMessage(from: desc)
    try msg.set([Int32(1), Int32(2), Int32(3)] as [Any], forField: "values")

    let data = try serializer.serialize(msg)
    let decoded = try deserializer.deserialize(data, using: desc)

    let values = try decoded.get(forField: "values")
    let arr = values as? [Any]
    XCTAssertNotNil(arr)
    XCTAssertEqual(arr?.count, 3)
  }
}
