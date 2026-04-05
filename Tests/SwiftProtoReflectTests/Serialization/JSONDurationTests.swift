//
// JSONDurationTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import XCTest

@testable import SwiftProtoReflect

final class JSONDurationTests: XCTestCase {

  // MARK: - Helpers

  private func makeDurationDescriptor() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/duration.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "Duration", parent: file)
    desc.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    desc.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
    file.addMessage(desc)
    return file.messages["Duration"]!
  }

  private func makeDurationMessage(seconds: Int64, nanos: Int32 = 0) throws -> DynamicMessage {
    let desc = makeDurationDescriptor()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(seconds, forField: 1)
    if nanos != 0 {
      try msg.set(nanos, forField: 2)
    }
    return msg
  }

  private func canonicalSerializer() -> JSONSerializer {
    JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: TypeRegistry()
      )
    )
  }

  private func deserializer() -> JSONDeserializer {
    JSONDeserializer(options: JSONDeserializationOptions(typeRegistry: TypeRegistry()))
  }

  // MARK: - Encoder tests

  func test_serialize_duration_integerSeconds_producesString() throws {
    let msg = try makeDurationMessage(seconds: 300)
    let data = try canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""300s""#)
  }

  func test_serialize_duration_zero_producesZeroS() throws {
    let msg = try makeDurationMessage(seconds: 0)
    let data = try canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""0s""#)
  }

  func test_serialize_duration_negative_producesNegativeString() throws {
    let msg = try makeDurationMessage(seconds: -300)
    let data = try canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""-300s""#)
  }

  func test_serialize_duration_withNanos_includesFraction() throws {
    // 1 second + 500_000_000 ns = 1.5s (trailing zeros trimmed: "5" not "500000000")
    let msg = try makeDurationMessage(seconds: 1, nanos: 500_000_000)
    let data = try canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""1.5s""#)
  }

  func test_serialize_duration_negativeWithNanos_trailingZerosTrimmed() throws {
    // -1.5s: seconds=-1, nanos=-500_000_000
    let msg = try makeDurationMessage(seconds: -1, nanos: -500_000_000)
    let data = try canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""-1.5s""#)
  }

  func test_serialize_duration_subSecondNegative_producesNegativeZeroPrefixed() throws {
    // -0.5s: seconds=0, nanos=-500_000_000
    let msg = try makeDurationMessage(seconds: 0, nanos: -500_000_000)
    let data = try canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""-0.5s""#)
  }

  func test_serialize_duration_fullNanos_noTrailingZeros() throws {
    // 123_456_789 ns — no trailing zeros in "123456789"
    let msg = try makeDurationMessage(seconds: 0, nanos: 123_456_789)
    let data = try canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""0.123456789s""#)
  }

  // MARK: - Decoder tests

  func test_deserialize_duration_integerSeconds() throws {
    let json = #""300s""#.data(using: .utf8)!
    let desc = makeDurationDescriptor()
    let msg = try deserializer().deserialize(json, using: desc)
    let seconds = try XCTUnwrap(try msg.get(forField: 1) as? Int64)
    let nanos = try msg.get(forField: 2) as? Int32 ?? 0
    XCTAssertEqual(seconds, 300)
    XCTAssertEqual(nanos, 0)
  }

  func test_deserialize_duration_fractionalSeconds() throws {
    let json = #""1.5s""#.data(using: .utf8)!
    let desc = makeDurationDescriptor()
    let msg = try deserializer().deserialize(json, using: desc)
    let seconds = try XCTUnwrap(try msg.get(forField: 1) as? Int64)
    let nanos = try XCTUnwrap(try msg.get(forField: 2) as? Int32)
    XCTAssertEqual(seconds, 1)
    XCTAssertEqual(nanos, 500_000_000)
  }

  func test_deserialize_duration_negative() throws {
    let json = #""-1.5s""#.data(using: .utf8)!
    let desc = makeDurationDescriptor()
    let msg = try deserializer().deserialize(json, using: desc)
    let seconds = try XCTUnwrap(try msg.get(forField: 1) as? Int64)
    let nanos = try XCTUnwrap(try msg.get(forField: 2) as? Int32)
    XCTAssertEqual(seconds, -1)
    XCTAssertEqual(nanos, -500_000_000)
  }

  func test_deserialize_duration_invalidFormat_throwsError() throws {
    let desc = makeDurationDescriptor()

    // Non-string JSON value
    let json1 = #"300"#.data(using: .utf8)!
    XCTAssertThrowsError(try deserializer().deserialize(json1, using: desc)) { error in
      guard case JSONDeserializationError.invalidJSONStructure = error else {
        XCTFail("Expected invalidJSONStructure, got \(error)")
        return
      }
    }

    // String without 's' suffix
    let json2 = #""300""#.data(using: .utf8)!
    XCTAssertThrowsError(try deserializer().deserialize(json2, using: desc)) { error in
      guard case JSONDeserializationError.invalidJSONStructure = error else {
        XCTFail("Expected invalidJSONStructure, got \(error)")
        return
      }
    }

    // Non-numeric content
    let json3 = #""abcs""#.data(using: .utf8)!
    XCTAssertThrowsError(try deserializer().deserialize(json3, using: desc)) { error in
      guard case JSONDeserializationError.invalidJSONStructure = error else {
        XCTFail("Expected invalidJSONStructure, got \(error)")
        return
      }
    }
  }

  // MARK: - Round-trip tests

  func test_roundTrip_duration_preservesData() throws {
    let seconds: Int64 = 123
    let nanos: Int32 = 456_789_000
    let msg = try makeDurationMessage(seconds: seconds, nanos: nanos)

    let data = try canonicalSerializer().serialize(msg)
    let roundTripped = try deserializer().deserialize(data, using: makeDurationDescriptor())

    let rtSeconds = try XCTUnwrap(try roundTripped.get(forField: 1) as? Int64)
    let rtNanos = try XCTUnwrap(try roundTripped.get(forField: 2) as? Int32)
    XCTAssertEqual(rtSeconds, seconds)
    XCTAssertEqual(rtNanos, nanos)
  }
}
