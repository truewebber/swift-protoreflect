//
// JSONDeserializerWKTDispatchTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import XCTest

@testable import SwiftProtoReflect

final class JSONDeserializerWKTDispatchTests: XCTestCase {

  // MARK: - Helpers

  private func makeTimestampFileDescriptor() -> FileDescriptor {
    var file = FileDescriptor(name: "google/protobuf/timestamp.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "Timestamp", parent: file)
    desc.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    desc.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
    file.addMessage(desc)
    return file
  }

  // MARK: - Non-WKT messages use standard decoding

  func test_deserialize_nonWKTMessage_usesStandardDecoding() async throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string, jsonName: "name"))

    let json = #"{"name":"hello"}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let msg = try await deserializer.deserialize(json, using: desc)
    XCTAssertEqual(try msg.get(forField: 1) as? String, "hello")
  }

  // MARK: - WKT messages route to WKT decoder — Timestamp decodes RFC 3339 string

  func test_deserialize_wktMessage_routesToWKTDecoder() async throws {
    let tsFile = makeTimestampFileDescriptor()
    let tsDesc = tsFile.messages["Timestamp"]!

    // Canonical JSON form for Timestamp is an RFC 3339 string
    let json = #""2024-01-01T00:00:00Z""#.data(using: .utf8)!
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let msg = try await deserializer.deserialize(json, using: tsDesc)
    let seconds = try XCTUnwrap(try msg.get(forField: 1) as? Int64)
    // 2024-01-01T00:00:00Z = 1704067200
    XCTAssertEqual(seconds, 1_704_067_200)
  }

  // MARK: - Nested WKT fields within regular messages route to WKT decoder

  func test_deserialize_nestedWKTField_routesToWKTDecoder() async throws {
    let tsFile = makeTimestampFileDescriptor()
    let registry = try await TypeRegistry(fileDescriptors: [tsFile])

    var outerFile = FileDescriptor(name: "test.proto", package: "test")
    var eventDesc = MessageDescriptor(name: "Event", parent: outerFile)
    eventDesc.addField(
      FieldDescriptor(
        name: "ts",
        number: 1,
        type: .message,
        typeName: "google.protobuf.Timestamp",
        jsonName: "ts"
      )
    )
    outerFile.addMessage(eventDesc)
    let outerDesc = outerFile.messages["Event"]!

    // Canonical Timestamp in a nested field: value is an RFC 3339 string
    let json = #"{"ts":"2024-01-01T00:00:00Z"}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: registry)
    )
    let msg = try await deserializer.deserialize(json, using: outerDesc)
    let tsMsg = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
    let seconds = try XCTUnwrap(try tsMsg.get(forField: 1) as? Int64)
    XCTAssertEqual(seconds, 1_704_067_200)
  }
}
