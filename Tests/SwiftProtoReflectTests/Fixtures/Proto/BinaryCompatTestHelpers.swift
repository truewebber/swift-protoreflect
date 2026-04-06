// BinaryCompatTestHelpers.swift
// SwiftProtoReflectTests
//
// Shared helpers for bidirectional binary compatibility tests.
// Direction A (oracle → us): SwiftProtobuf serializedData() → BinaryDeserializer → assert field values
// Direction B (us → oracle): BinarySerializer.serialize() → P(serializedBytes:) → assert values
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

// MARK: - BinaryCompatHelpers

enum BinaryCompatHelpers {

  // MARK: - Serializer/Deserializer factories

  static func makeSerializer() -> BinarySerializer {
    BinarySerializer()
  }

  static func makeDeserializer(registry: TypeRegistry) -> BinaryDeserializer {
    BinaryDeserializer(
      options: DeserializationOptions(
        preserveUnknownFields: true,
        strictUTF8Validation: true,
        typeRegistry: registry
      )
    )
  }

  // MARK: - Direction A: oracle (swift-protobuf) → our deserializer

  /// Serializes a swift-protobuf message to binary, deserializes via our BinaryDeserializer,
  /// and hands the DynamicMessage to `validate`.
  @discardableResult
  static func assertOracleToUs<P: SwiftProtobuf.Message>(
    proto: P,
    descriptor: MessageDescriptor,
    registry: TypeRegistry,
    file: StaticString = #file,
    line: UInt = #line,
    validate: (DynamicMessage) throws -> Void
  ) throws -> DynamicMessage {
    let referenceData = try proto.serializedData()
    let dynamic = try makeDeserializer(registry: registry).deserialize(referenceData, using: descriptor)
    try validate(dynamic)
    return dynamic
  }

  // MARK: - Direction B: our serializer → oracle (swift-protobuf)

  /// Serializes a DynamicMessage via our BinarySerializer, parses the bytes via the
  /// swift-protobuf generated type, and hands it to `validate`.
  @discardableResult
  static func assertUsToOracle<P: SwiftProtobuf.Message>(
    dynamic: DynamicMessage,
    protoType: P.Type,
    file: StaticString = #file,
    line: UInt = #line,
    validate: (P) throws -> Void
  ) throws -> P {
    let ourData = try makeSerializer().serialize(dynamic)
    let decoded = try P(serializedBytes: ourData)
    try validate(decoded)
    return decoded
  }

  // MARK: - Bidirectional (both directions in one call)

  /// Runs both directions and asserts in each direction.
  /// Direction A: swift-protobuf → binary → DynamicMessage (validateDynamic)
  /// Direction B: build DynamicMessage via `buildDynamic` → binary → swift-protobuf (validateProto)
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
    try assertOracleToUs(
      proto: proto,
      descriptor: descriptor,
      registry: registry,
      file: file,
      line: line,
      validate: validateDynamic
    )
    let dynamic = try buildDynamic()
    try assertUsToOracle(
      dynamic: dynamic,
      protoType: P.self,
      file: file,
      line: line,
      validate: validateProto
    )
  }
}
