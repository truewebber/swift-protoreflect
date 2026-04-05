// CompatTestHelpers.swift
// SwiftProtoReflectTests
//
// Shared helpers for bidirectional JSON compatibility tests.
// Direction A: SwiftProtobuf.jsonString() → our JSONDeserializer → assert field values
// Direction B: our JSONSerializer → SwiftProtobuf.init(jsonString:) → assert values
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

// MARK: - CompatHelpers

enum CompatHelpers {

  // MARK: - Serializer/Deserializer factories

  static func makeSerializer(registry: TypeRegistry) -> JSONSerializer {
    JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: registry
      )
    )
  }

  static func makeDeserializer(registry: TypeRegistry) -> JSONDeserializer {
    JSONDeserializer(options: JSONDeserializationOptions(typeRegistry: registry))
  }

  // MARK: - Direction A: SwiftProtobuf → our deserializer

  /// Serializes a SwiftProtobuf message to JSON, then deserializes with our deserializer.
  ///
  /// Calls `validate` with the resulting `DynamicMessage` for assertions.
  @discardableResult
  static func assertProtocToUs<P: SwiftProtobuf.Message>(
    proto: P,
    descriptor: MessageDescriptor,
    registry: TypeRegistry,
    file: StaticString = #file,
    line: UInt = #line,
    validate: (DynamicMessage) throws -> Void
  ) throws -> DynamicMessage {
    let jsonStr = try proto.jsonString()
    guard let jsonData = jsonStr.data(using: .utf8) else {
      XCTFail("Failed to encode JSON string to Data", file: file, line: line)
      throw CompatError.jsonEncodingFailed
    }
    let msg = try makeDeserializer(registry: registry).deserialize(jsonData, using: descriptor)
    try validate(msg)
    return msg
  }

  // MARK: - Direction B: our serializer → SwiftProtobuf

  /// Serializes a `DynamicMessage` to JSON, then parses with SwiftProtobuf.
  ///
  /// Calls `validate` with the decoded SwiftProtobuf message for assertions.
  @discardableResult
  static func assertUsToProtoc<P: SwiftProtobuf.Message>(
    dynamic: DynamicMessage,
    registry: TypeRegistry,
    protoType: P.Type,
    file: StaticString = #file,
    line: UInt = #line,
    validate: (P) throws -> Void
  ) throws -> P {
    let jsonData = try makeSerializer(registry: registry).serialize(dynamic)
    guard let jsonStr = String(data: jsonData, encoding: .utf8) else {
      XCTFail("Failed to decode JSON Data to String", file: file, line: line)
      throw CompatError.jsonDecodingFailed
    }
    let decoded = try P(jsonString: jsonStr)
    try validate(decoded)
    return decoded
  }

  // MARK: - Bidirectional (both directions in one call)

  /// Runs both directions and asserts in each direction.
  /// Direction A: SwiftProtobuf → JSON → DynamicMessage (validateDynamic)
  /// Direction B: build DynamicMessage via `buildDynamic` → JSON → SwiftProtobuf (validateProto)
  static func assertBidirectional<P: SwiftProtobuf.Message>(
    proto: P,
    descriptor: MessageDescriptor,
    registry: TypeRegistry,
    file: StaticString = #file,
    line: UInt = #line,
    validateDynamic: (DynamicMessage) throws -> Void,
    buildDynamic: () throws -> DynamicMessage,
    validateProto: (P) throws -> Void
  ) throws {
    try assertProtocToUs(
      proto: proto,
      descriptor: descriptor,
      registry: registry,
      file: file,
      line: line,
      validate: validateDynamic
    )
    let dynamic = try buildDynamic()
    try assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: P.self,
      file: file,
      line: line,
      validate: validateProto
    )
  }

  // MARK: - DynamicMessage helper

  static func message(descriptor: MessageDescriptor) -> DynamicMessage {
    DynamicMessage(descriptor: descriptor)
  }

  // MARK: - JSON round-trip (us → us)

  static func assertRoundTrip(
    dynamic: DynamicMessage,
    registry: TypeRegistry,
    file: StaticString = #file,
    line: UInt = #line,
    validate: (DynamicMessage) throws -> Void
  ) throws {
    let serializer = makeSerializer(registry: registry)
    let deserializer = makeDeserializer(registry: registry)
    let jsonData = try serializer.serialize(dynamic)
    let restored = try deserializer.deserialize(jsonData, using: dynamic.descriptor)
    try validate(restored)
  }
}

// MARK: - CompatError

enum CompatError: Error {
  case jsonEncodingFailed
  case jsonDecodingFailed
}
