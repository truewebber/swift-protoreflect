//
// JSONTimestampTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import XCTest

@testable import SwiftProtoReflect

final class JSONTimestampTests: XCTestCase {

  // MARK: - Helpers

  private func makeTimestampDescriptor() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/timestamp.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "Timestamp", parent: file)
    desc.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    desc.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
    file.addMessage(desc)
    return file.messages["Timestamp"]!
  }

  private func makeTimestampMessage(seconds: Int64, nanos: Int32 = 0) throws -> DynamicMessage {
    let desc = makeTimestampDescriptor()
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

  func test_serialize_timestamp_zeroNanos_producesRFC3339WithoutFraction() async throws {
    // 2009-02-13T23:31:30Z
    let msg = try makeTimestampMessage(seconds: 1_234_567_890, nanos: 0)
    let data = try await canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""2009-02-13T23:31:30Z""#)
  }

  func test_serialize_timestamp_millisNanos_produces3Digits() async throws {
    // 500_000_000 ns = 500 ms
    let msg = try makeTimestampMessage(seconds: 0, nanos: 500_000_000)
    let data = try await canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""1970-01-01T00:00:00.500Z""#)
  }

  func test_serialize_timestamp_microsNanos_produces6Digits() async throws {
    // 123_456_000 ns = 123456 µs
    let msg = try makeTimestampMessage(seconds: 0, nanos: 123_456_000)
    let data = try await canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""1970-01-01T00:00:00.123456Z""#)
  }

  func test_serialize_timestamp_fullNanos_produces9Digits() async throws {
    // 123_456_789 ns
    let msg = try makeTimestampMessage(seconds: 0, nanos: 123_456_789)
    let data = try await canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""1970-01-01T00:00:00.123456789Z""#)
  }

  // MARK: - Decoder tests

  func test_deserialize_timestamp_fromRFC3339_basic() async throws {
    let json = #""2009-02-13T23:31:30Z""#.data(using: .utf8)!
    let desc = makeTimestampDescriptor()
    let msg = try await deserializer().deserialize(json, using: desc)
    let seconds = try XCTUnwrap(try msg.get(forField: 1) as? Int64)
    let nanos = try msg.get(forField: 2) as? Int32 ?? 0
    XCTAssertEqual(seconds, 1_234_567_890)
    XCTAssertEqual(nanos, 0)
  }

  func test_deserialize_timestamp_fromRFC3339_withFractionalSeconds() async throws {
    let json = #""1970-01-01T00:00:00.123456789Z""#.data(using: .utf8)!
    let desc = makeTimestampDescriptor()
    let msg = try await deserializer().deserialize(json, using: desc)
    let seconds = try XCTUnwrap(try msg.get(forField: 1) as? Int64)
    let nanos = try XCTUnwrap(try msg.get(forField: 2) as? Int32)
    XCTAssertEqual(seconds, 0)
    XCTAssertEqual(nanos, 123_456_789)
  }

  func test_deserialize_timestamp_fromRFC3339_withTimezoneOffset() async throws {
    // +00:00 is equivalent to Z
    let json = #""2009-02-13T23:31:30+00:00""#.data(using: .utf8)!
    let desc = makeTimestampDescriptor()
    let msg = try await deserializer().deserialize(json, using: desc)
    let seconds = try XCTUnwrap(try msg.get(forField: 1) as? Int64)
    XCTAssertEqual(seconds, 1_234_567_890)
  }

  func test_deserialize_timestamp_nonString_throwsError() async throws {
    let json = #"{"seconds":1234567890,"nanos":0}"#.data(using: .utf8)!
    let desc = makeTimestampDescriptor()
    do {
      _ = try await deserializer().deserialize(json, using: desc)
      XCTFail("Expected error to be thrown")
    }
    catch {
      guard case JSONDeserializationError.invalidJSONStructure = error else {
        XCTFail("Expected invalidJSONStructure, got \(error)")
        return
      }
    }
  }

  // MARK: - Round-trip tests

  func test_roundTrip_timestamp_preservesData() async throws {
    let seconds: Int64 = 1_234_567_890
    let nanos: Int32 = 123_456_789
    let msg = try makeTimestampMessage(seconds: seconds, nanos: nanos)

    let data = try await canonicalSerializer().serialize(msg)
    let roundTripped = try await deserializer().deserialize(data, using: makeTimestampDescriptor())

    let rtSeconds = try XCTUnwrap(try roundTripped.get(forField: 1) as? Int64)
    let rtNanos = try XCTUnwrap(try roundTripped.get(forField: 2) as? Int32)
    XCTAssertEqual(rtSeconds, seconds)
    XCTAssertEqual(rtNanos, nanos)
  }
}
