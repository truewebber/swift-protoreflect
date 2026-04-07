//
// ResolutionPriorityTests.swift
// SwiftProtoReflectTests
//
// Tests that TypeRegistry is the primary lookup for type resolution across
// BinaryDeserializer, JSONSerializer, and JSONDeserializer.
//

import XCTest

@testable import SwiftProtoReflect

final class ResolutionPriorityTests: XCTestCase {

  private let factory = MessageFactory()
  private let binarySerializer = BinarySerializer()

  // MARK: - Helpers

  /// Builds an enum descriptor with UNKNOWN / ACTIVE / INACTIVE, registered in a fresh TypeRegistry.
  private func makeStatusEnum(fullName: String = "pkg.Status") -> EnumDescriptor {
    var enumDesc = EnumDescriptor(name: "Status", fullName: fullName)
    enumDesc.addValue(.init(name: "UNKNOWN", number: 0))
    enumDesc.addValue(.init(name: "ACTIVE", number: 1))
    enumDesc.addValue(.init(name: "INACTIVE", number: 2))
    return enumDesc
  }

  /// Builds a message descriptor with a single enum field whose typeName points to `enumFullName`.
  ///
  /// No nestedEnum is added so enum resolution MUST come from TypeRegistry.
  private func makeMsgDescWithEnumField(enumTypeName: String = "pkg.Status") -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    desc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: enumTypeName, jsonName: "status")
    )
    return desc
  }

  /// Returns JSON bytes for `{"status": "ACTIVE"}`.
  private func activeStatusJSON() -> Data {
    Data(#"{"status":"ACTIVE"}"#.utf8)
  }

  // MARK: - Binary: TypeRegistry primary for message resolution

  /// TypeRegistry WINS over a shadowing nestedMessage when both are present.
  ///
  /// The outer descriptor carries a nestedMessage "Inner" with field "bad_field" (wrong).
  /// TypeRegistry has "pkg.Outer.Inner" with field "good_field" (correct).
  /// After the priority flip, TypeRegistry is consulted first → "good_field" is accessible.
  func test_binaryDeserialize_nestedMessage_resolvedViaRegistry() async throws {
    // Build the "correct" inner descriptor (in TypeRegistry).
    var registryInner = MessageDescriptor(name: "Inner", fullName: "pkg.Outer.Inner")
    registryInner.addField(FieldDescriptor(name: "good_field", number: 1, type: .string))

    // Build a "shadow" inner descriptor that is added as a nestedMessage.
    var shadowInner = MessageDescriptor(name: "Inner", fullName: "pkg.Outer.Inner")
    shadowInner.addField(FieldDescriptor(name: "bad_field", number: 1, type: .string))

    // Outer descriptor: field typeName points to "pkg.Outer.Inner".
    var outerDesc = MessageDescriptor(name: "Outer", fullName: "pkg.Outer")
    outerDesc.addField(
      FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "pkg.Outer.Inner")
    )

    // Produce binary data using the "correct" inner.
    var innerMsg = factory.createMessage(from: registryInner)
    try innerMsg.set("hello", forField: "good_field")
    var outerMsg = factory.createMessage(from: outerDesc)
    try outerMsg.set(innerMsg, forField: "inner")
    let data = try binarySerializer.serialize(outerMsg)

    // Attach the SHADOW inner as nestedMessage — currently this would win.
    var deserDesc = outerDesc
    deserDesc.addNestedMessage(shadowInner)

    // Register the CORRECT inner in TypeRegistry — must win after priority flip.
    let registry = TypeRegistry()
    try await registry.registerMessage(registryInner)

    let decoded = try await BinaryDeserializer(options: .init(typeRegistry: registry))
      .deserialize(data, using: deserDesc)

    let decodedInner = try XCTUnwrap(decoded.get(forField: "inner") as? DynamicMessage)
    // Must use the TypeRegistry descriptor → "good_field" must be accessible.
    XCTAssertEqual(try decodedInner.get(forField: "good_field") as? String, "hello")
  }

  /// A sibling message (not structurally nested) is resolved via TypeRegistry as primary lookup.
  func test_binaryDeserialize_siblingMessage_resolvedViaRegistry() async throws {
    var innerDesc = MessageDescriptor(name: "Payload", fullName: "pkg.Payload")
    innerDesc.addField(FieldDescriptor(name: "data", number: 1, type: .string))

    var outerDesc = MessageDescriptor(name: "Container", fullName: "pkg.Container")
    outerDesc.addField(
      FieldDescriptor(name: "payload", number: 1, type: .message, typeName: "pkg.Payload")
    )

    var innerMsg = factory.createMessage(from: innerDesc)
    try innerMsg.set("content", forField: "data")
    var outerMsg = factory.createMessage(from: outerDesc)
    try outerMsg.set(innerMsg, forField: "payload")
    let data = try binarySerializer.serialize(outerMsg)

    let registry = TypeRegistry()
    try await registry.registerMessage(innerDesc)

    let decoded = try await BinaryDeserializer(options: .init(typeRegistry: registry))
      .deserialize(data, using: outerDesc)

    let decodedPayload = try XCTUnwrap(decoded.get(forField: "payload") as? DynamicMessage)
    XCTAssertEqual(try decodedPayload.get(forField: "data") as? String, "content")
  }

  /// When TypeRegistry has no entry, resolution falls back to structural nesting (deprecated path).
  func test_binaryDeserialize_withoutRegisteredType_fallsBackToNested() async throws {
    var innerDesc = MessageDescriptor(name: "Inner", fullName: "pkg.Outer.Inner")
    innerDesc.addField(FieldDescriptor(name: "val", number: 1, type: .int32))

    var outerDesc = MessageDescriptor(name: "Outer", fullName: "pkg.Outer")
    outerDesc.addField(
      FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "pkg.Outer.Inner")
    )
    outerDesc.addNestedMessage(innerDesc)

    var innerMsg = factory.createMessage(from: innerDesc)
    try innerMsg.set(Int32(42), forField: "val")
    var outerMsg = factory.createMessage(from: outerDesc)
    try outerMsg.set(innerMsg, forField: "inner")
    let data = try binarySerializer.serialize(outerMsg)

    // Empty TypeRegistry → must fall back to nestedMessage.
    let decoded = try await BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
      .deserialize(data, using: outerDesc)

    let decodedInner = try XCTUnwrap(decoded.get(forField: "inner") as? DynamicMessage)
    XCTAssertEqual(try decodedInner.get(forField: "val") as? Int32, 42)
  }

  // MARK: - JSON Serializer: TypeRegistry primary for enum resolution

  /// Enum resolved from TypeRegistry (no nestedEnum on the descriptor) →
  /// enum value is serialised as its string name, not as a raw integer.
  func test_jsonSerialize_enumField_resolvedViaRegistry() async throws {
    let enumDesc = makeStatusEnum()
    let msgDesc = makeMsgDescWithEnumField()

    let registry = TypeRegistry()
    try await registry.registerEnum(enumDesc)

    var msg = factory.createMessage(from: msgDesc)
    try msg.set(Int32(1), forField: "status")

    let serializer = JSONSerializer(options: .init(typeRegistry: registry))
    let data = try await serializer.serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    // TypeRegistry must supply the enum → value should be string "ACTIVE", not Int 1.
    XCTAssertEqual(json["status"] as? String, "ACTIVE")
  }

  /// Enum in a map field's value is resolved from TypeRegistry →
  /// values serialised as string names.
  func test_jsonSerialize_mapEnumValue_resolvedViaRegistry() async throws {
    let enumDesc = makeStatusEnum()

    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valInfo = ValueFieldInfo(name: "value", number: 2, type: .enum, typeName: "pkg.Status")
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valInfo)

    var msgDesc = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    msgDesc.addField(
      FieldDescriptor(
        name: "statuses",
        number: 1,
        type: .message,
        typeName: "pkg.statuses_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )

    let registry = TypeRegistry()
    try await registry.registerEnum(enumDesc)

    var msg = factory.createMessage(from: msgDesc)
    try msg.set(["alice": Int32(1)] as [AnyHashable: Any], forField: "statuses")

    let serializer = JSONSerializer(options: .init(typeRegistry: registry))
    let data = try await serializer.serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    let statuses = try XCTUnwrap(json["statuses"] as? [String: Any])

    // TypeRegistry must supply the enum → "alice" → "ACTIVE", not 1.
    XCTAssertEqual(statuses["alice"] as? String, "ACTIVE")
  }

  /// proto3 default for an enum field uses TypeRegistry to emit the string name of value 0.
  func test_jsonSerialize_proto3DefaultEnum_resolvedViaRegistry() async throws {
    let enumDesc = makeStatusEnum()
    let msgDesc = makeMsgDescWithEnumField()

    let registry = TypeRegistry()
    try await registry.registerEnum(enumDesc)

    // Create message without setting the enum field → proto3 default is value 0 ("UNKNOWN").
    let msg = factory.createMessage(from: msgDesc)

    let serializer = JSONSerializer(
      options: .init(includeDefaultValues: true, typeRegistry: registry)
    )
    let data = try await serializer.serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    // TypeRegistry must supply the enum → default value 0 → "UNKNOWN", not 0.
    XCTAssertEqual(json["status"] as? String, "UNKNOWN")
  }

  /// When TypeRegistry has no enum, resolution falls back to structural nesting (deprecated path).
  func test_jsonSerialize_enumField_fallsBackToNestedEnum() async throws {
    let enumDesc = makeStatusEnum()

    var msgDesc = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    msgDesc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "pkg.Status", jsonName: "status")
    )
    msgDesc.addNestedEnum(enumDesc)

    var msg = factory.createMessage(from: msgDesc)
    try msg.set(Int32(1), forField: "status")

    // Empty TypeRegistry → must fall back to nestedEnum.
    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let data = try await serializer.serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    // nestedEnum fallback must produce the string name.
    XCTAssertEqual(json["status"] as? String, "ACTIVE")
  }

  // MARK: - JSON Deserializer: TypeRegistry primary for enum resolution

  /// Enum resolved from TypeRegistry (no nestedEnum on the descriptor) →
  /// string name in JSON is mapped to the correct integer.
  func test_jsonDeserialize_enumField_resolvedViaRegistry() async throws {
    let enumDesc = makeStatusEnum()
    let msgDesc = makeMsgDescWithEnumField()

    let registry = TypeRegistry()
    try await registry.registerEnum(enumDesc)

    let deserializer = JSONDeserializer(options: .init(typeRegistry: registry))
    let msg = try await deserializer.deserialize(activeStatusJSON(), using: msgDesc)

    // TypeRegistry must supply the enum → "ACTIVE" → 1.
    XCTAssertEqual(try msg.get(forField: "status") as? Int32, 1)
  }

  /// Enum in a map field's value is resolved from TypeRegistry →
  /// string names in JSON are converted to integers.
  func test_jsonDeserialize_mapEnumValue_resolvedViaRegistry() async throws {
    let enumDesc = makeStatusEnum()

    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valInfo = ValueFieldInfo(name: "value", number: 2, type: .enum, typeName: "pkg.Status")
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valInfo)

    var msgDesc = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    msgDesc.addField(
      FieldDescriptor(
        name: "statuses",
        number: 1,
        type: .message,
        typeName: "pkg.statuses_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )

    let registry = TypeRegistry()
    try await registry.registerEnum(enumDesc)

    let jsonData = Data(#"{"statuses":{"alice":"ACTIVE"}}"#.utf8)
    let deserializer = JSONDeserializer(options: .init(typeRegistry: registry))
    let msg = try await deserializer.deserialize(jsonData, using: msgDesc)

    let statuses = try XCTUnwrap(msg.get(forField: "statuses") as? [AnyHashable: Any])
    // TypeRegistry must supply the enum → "ACTIVE" → 1.
    XCTAssertEqual(statuses["alice"] as? Int32, 1)
  }

  /// When TypeRegistry has no enum, resolution falls back to structural nesting (deprecated path).
  func test_jsonDeserialize_enumField_fallsBackToNestedEnum() async throws {
    let enumDesc = makeStatusEnum()

    var msgDesc = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    msgDesc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "pkg.Status", jsonName: "status")
    )
    msgDesc.addNestedEnum(enumDesc)

    // Empty TypeRegistry → must fall back to nestedEnum.
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let msg = try await deserializer.deserialize(activeStatusJSON(), using: msgDesc)

    // nestedEnum fallback must map "ACTIVE" → 1.
    XCTAssertEqual(try msg.get(forField: "status") as? Int32, 1)
  }
}
