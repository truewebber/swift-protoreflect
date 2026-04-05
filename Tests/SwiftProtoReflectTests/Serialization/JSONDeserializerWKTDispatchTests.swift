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

  func test_deserialize_nonWKTMessage_usesStandardDecoding() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string, jsonName: "name"))

    let json = #"{"name":"hello"}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let msg = try deserializer.deserialize(json, using: desc)
    XCTAssertEqual(try msg.get(forField: 1) as? String, "hello")
  }

  // MARK: - WKT messages route to WKT decoder (throws unsupported for unimplemented WKTs)

  func test_deserialize_wktMessage_routesToWKTDecoder() throws {
    let tsFile = makeTimestampFileDescriptor()
    let tsDesc = tsFile.messages["Timestamp"]!

    // Canonical JSON form for Timestamp is a string, not an object
    let json = #""2024-01-01T00:00:00Z""#.data(using: .utf8)!
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    XCTAssertThrowsError(try deserializer.deserialize(json, using: tsDesc)) { error in
      guard case JSONDeserializationError.unsupportedWellKnownTypeDecoding(let typeName) = error else {
        XCTFail("Expected unsupportedWellKnownTypeDecoding, got \(error)")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Timestamp")
    }
  }

  // MARK: - Nested WKT fields within regular messages route to WKT decoder

  func test_deserialize_nestedWKTField_routesToWKTDecoder() throws {
    let tsFile = makeTimestampFileDescriptor()
    let registry = try TypeRegistry(fileDescriptors: [tsFile])

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

    // Canonical Timestamp in a nested field: value is a string, not a dict
    let json = #"{"ts":"2024-01-01T00:00:00Z"}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: registry)
    )
    XCTAssertThrowsError(try deserializer.deserialize(json, using: outerDesc)) { error in
      guard case JSONDeserializationError.unsupportedWellKnownTypeDecoding(let typeName) = error else {
        XCTFail("Expected unsupportedWellKnownTypeDecoding, got \(error)")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Timestamp")
    }
  }
}
