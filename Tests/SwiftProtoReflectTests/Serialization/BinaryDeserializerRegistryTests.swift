//
// BinaryDeserializerRegistryTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-04
//
// Full test suite for BinaryDeserializer registry-based type resolution.
// Groups B (positive), C (negative), D (corner cases) from OPE-250 test plan.
//

import XCTest

@testable import SwiftProtoReflect

final class BinaryDeserializerRegistryTests: XCTestCase {

  // MARK: - Shared Helpers

  private let factory = MessageFactory()
  private let serializer = BinarySerializer()

  private func makeRegistry(_ descriptors: MessageDescriptor...) async throws -> TypeRegistry {
    let registry = TypeRegistry()
    for descriptor in descriptors {
      try await registry.registerMessage(descriptor)
    }
    return registry
  }

  private func makeSiblingA() -> MessageDescriptor {
    var desc = MessageDescriptor(name: "A", fullName: "pkg.A")
    desc.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    return desc
  }

  private func makeSiblingB(typeName: String = "pkg.A") -> MessageDescriptor {
    var desc = MessageDescriptor(name: "B", fullName: "pkg.B")
    desc.addField(FieldDescriptor(name: "a", number: 1, type: .message, typeName: typeName))
    return desc
  }

  /// Serialises a B message containing A.value = `aValue`.
  ///
  /// Uses addNestedMessage only for the serialisation step so binary data is correctly formed.
  private func serialiseBContainingA(descA: MessageDescriptor, aValue: String) async throws -> Data {
    let innerDesc = descA
    var innerMsg = factory.createMessage(from: innerDesc)
    try innerMsg.set(aValue, forField: "value")

    var outerDesc = MessageDescriptor(name: "B", fullName: "pkg.B")
    outerDesc.addField(FieldDescriptor(name: "a", number: 1, type: .message, typeName: "pkg.A"))

    var outerMsg = factory.createMessage(from: outerDesc)
    try outerMsg.set(innerMsg, forField: "a")

    return try serializer.serialize(outerMsg)
  }

  // MARK: - B. Positive: sibling message resolution via registry

  func test_deserialize_siblingMessageField_withRegistry_succeeds() async throws {
    let descA = makeSiblingA()
    let descB = makeSiblingB()
    let data = try await serialiseBContainingA(descA: descA, aValue: "hello")

    let registry = try await makeRegistry(descA)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: descB)

    let decodedA = try XCTUnwrap(decoded.get(forField: "a") as? DynamicMessage)
    XCTAssertEqual(try decodedA.get(forField: "value") as? String, "hello")
  }

  func test_deserialize_chainOfSiblingMessages_withRegistry_succeeds() async throws {
    var descC = MessageDescriptor(name: "C", fullName: "pkg.C")
    descC.addField(FieldDescriptor(name: "n", number: 1, type: .int32))

    var descB = MessageDescriptor(name: "B", fullName: "pkg.B")
    descB.addField(FieldDescriptor(name: "c", number: 1, type: .message, typeName: "pkg.C"))

    var descA = MessageDescriptor(name: "A", fullName: "pkg.A")
    descA.addField(FieldDescriptor(name: "b", number: 1, type: .message, typeName: "pkg.B"))

    // Serialise with nesting so binary data is correct.
    var serDescB = descB
    serDescB.addNestedMessage(descC)
    var serDescA = descA
    serDescA.addNestedMessage(serDescB)

    var msgC = factory.createMessage(from: descC)
    try msgC.set(Int32(42), forField: "n")
    var msgB = factory.createMessage(from: serDescB)
    try msgB.set(msgC, forField: "c")
    var msgA = factory.createMessage(from: serDescA)
    try msgA.set(msgB, forField: "b")
    let data = try serializer.serialize(msgA)

    // Deserialise with registry (no nesting lies).
    let registry = try await makeRegistry(descA, descB, descC)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: descA)

    let decodedB = try XCTUnwrap(decoded.get(forField: "b") as? DynamicMessage)
    let decodedC = try XCTUnwrap(decodedB.get(forField: "c") as? DynamicMessage)
    XCTAssertEqual(try decodedC.get(forField: "n") as? Int32, 42)
  }

  func test_deserialize_selfReferentialMessage_withRegistry_succeeds() async throws {
    // Node { string label = 1; Node child = 2; }  — 3 levels deep.
    var nodeDesc = MessageDescriptor(name: "Node", fullName: "pkg.Node")
    nodeDesc.addField(FieldDescriptor(name: "label", number: 1, type: .string))
    nodeDesc.addField(FieldDescriptor(name: "child", number: 2, type: .message, typeName: "pkg.Node"))

    // Serialise using the structural nesting lie (needed for serialisation only).
    var serNodeDesc = nodeDesc
    serNodeDesc.addNestedMessage(nodeDesc)

    var level3 = factory.createMessage(from: nodeDesc)
    try level3.set("leaf", forField: "label")

    var level2 = factory.createMessage(from: serNodeDesc)
    try level2.set("mid", forField: "label")
    try level2.set(level3, forField: "child")

    var level1 = factory.createMessage(from: serNodeDesc)
    try level1.set("root", forField: "label")
    try level1.set(level2, forField: "child")

    let data = try serializer.serialize(level1)

    // Deserialise with registry.
    let registry = try await makeRegistry(nodeDesc)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: nodeDesc)

    XCTAssertEqual(try decoded.get(forField: "label") as? String, "root")
    let child1 = try XCTUnwrap(decoded.get(forField: "child") as? DynamicMessage)
    XCTAssertEqual(try child1.get(forField: "label") as? String, "mid")
    let child2 = try XCTUnwrap(child1.get(forField: "child") as? DynamicMessage)
    XCTAssertEqual(try child2.get(forField: "label") as? String, "leaf")
  }

  func test_deserialize_mutuallyRecursiveMessages_withRegistry_succeeds() async throws {
    // Mirrors google.protobuf.Value / ListValue sibling pattern.
    var valueDesc = MessageDescriptor(name: "Value", fullName: "pkg.Value")
    valueDesc.addField(FieldDescriptor(name: "string_value", number: 3, type: .string))

    var listValueDesc = MessageDescriptor(name: "ListValue", fullName: "pkg.ListValue")
    listValueDesc.addField(
      FieldDescriptor(
        name: "values",
        number: 1,
        type: .message,
        typeName: "pkg.Value",
        isRepeated: true
      )
    )

    // Serialise using lie.
    var serListValueDesc = listValueDesc
    serListValueDesc.addNestedMessage(valueDesc)

    var v1 = factory.createMessage(from: valueDesc)
    try v1.set("item1", forField: "string_value")
    var v2 = factory.createMessage(from: valueDesc)
    try v2.set("item2", forField: "string_value")

    var listMsg = factory.createMessage(from: serListValueDesc)
    try listMsg.set([v1, v2] as [Any], forField: "values")
    let data = try serializer.serialize(listMsg)

    // Deserialise with registry (no lie).
    let registry = try await makeRegistry(valueDesc, listValueDesc)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: listValueDesc)

    let items = try XCTUnwrap(decoded.get(forField: "values") as? [Any])
    XCTAssertEqual(items.count, 2)
    let first = try XCTUnwrap(items[0] as? DynamicMessage)
    XCTAssertEqual(try first.get(forField: "string_value") as? String, "item1")
  }

  func test_deserialize_mapValueSiblingMessage_withRegistry_succeeds() async throws {
    var itemDesc = MessageDescriptor(name: "Item", fullName: "pkg.Item")
    itemDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))

    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valInfo = ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "pkg.Item")
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valInfo)

    var containerDesc = MessageDescriptor(name: "Container", fullName: "pkg.Container")
    containerDesc.addField(
      FieldDescriptor(
        name: "items",
        number: 1,
        type: .message,
        typeName: "pkg.items_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )

    // Serialise using lie for the map value type.
    let serItemDesc = itemDesc
    var serContainerDesc = containerDesc
    serContainerDesc.addNestedMessage(serItemDesc)

    var itemMsg = factory.createMessage(from: itemDesc)
    try itemMsg.set("widget", forField: "name")

    var containerMsg = factory.createMessage(from: serContainerDesc)
    try containerMsg.set(["key1": itemMsg] as [AnyHashable: Any], forField: "items")
    let data = try serializer.serialize(containerMsg)

    // Deserialise with registry.
    let registry = try await makeRegistry(itemDesc, containerDesc)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: containerDesc)

    let map = try XCTUnwrap(decoded.get(forField: "items") as? [AnyHashable: Any])
    let decodedItem = try XCTUnwrap(map["key1"] as? DynamicMessage)
    XCTAssertEqual(try decodedItem.get(forField: "name") as? String, "widget")
  }

  func test_deserialize_oneofSiblingMessageField_withRegistry_succeeds() async throws {
    var payloadDesc = MessageDescriptor(name: "Payload", fullName: "pkg.Payload")
    payloadDesc.addField(FieldDescriptor(name: "data", number: 1, type: .string))

    var wrapperDesc = MessageDescriptor(name: "Wrapper", fullName: "pkg.Wrapper")
    wrapperDesc.addOneofDecl(OneofDescriptor(name: "kind", index: 0))
    wrapperDesc.addField(
      FieldDescriptor(
        name: "payload",
        number: 1,
        type: .message,
        typeName: "pkg.Payload",
        oneofIndex: 0
      )
    )

    // Serialise using lie.
    var serWrapperDesc = wrapperDesc
    serWrapperDesc.addNestedMessage(payloadDesc)

    var payloadMsg = factory.createMessage(from: payloadDesc)
    try payloadMsg.set("secret", forField: "data")
    var wrapperMsg = factory.createMessage(from: serWrapperDesc)
    try wrapperMsg.set(payloadMsg, forField: "payload")
    let data = try serializer.serialize(wrapperMsg)

    // Deserialise with registry.
    let registry = try await makeRegistry(payloadDesc, wrapperDesc)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: wrapperDesc)

    let decodedPayload = try XCTUnwrap(decoded.get(forField: "payload") as? DynamicMessage)
    XCTAssertEqual(try decodedPayload.get(forField: "data") as? String, "secret")
  }

  func test_deserialize_siblingEnum_withRegistry_succeeds() async throws {
    // Note: enum fields are decoded as varints — no name resolution needed.
    // This test verifies that enum fields work correctly when a registry is present.
    var statusEnum = EnumDescriptor(name: "Status", fullName: "pkg.Status")
    statusEnum.addValue(.init(name: "UNKNOWN", number: 0))
    statusEnum.addValue(.init(name: "ACTIVE", number: 1))

    var docDesc = MessageDescriptor(name: "Doc", fullName: "pkg.Doc")
    docDesc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "pkg.Status")
    )

    let registry = TypeRegistry()

    var docMsg = factory.createMessage(from: docDesc)
    try docMsg.set(Int32(1), forField: "status")
    let data = try serializer.serialize(docMsg)

    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: docDesc)

    XCTAssertEqual(try decoded.get(forField: "status") as? Int32, 1)
  }

  func test_deserialize_typeNameWithLeadingDot_withRegistry_succeeds() async throws {
    // Some protoc outputs use ".pkg.A" (leading dot) instead of "pkg.A".
    let descA = makeSiblingA()

    var descB = MessageDescriptor(name: "B", fullName: "pkg.B")
    descB.addField(
      FieldDescriptor(name: "a", number: 1, type: .message, typeName: ".pkg.A")
    )

    let data = try await serialiseBContainingA(descA: descA, aValue: "dotted")

    let registry = try await makeRegistry(descA)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: descB)

    let decodedA = try XCTUnwrap(decoded.get(forField: "a") as? DynamicMessage)
    XCTAssertEqual(try decodedA.get(forField: "value") as? String, "dotted")
  }

  func test_deserialize_multiFileRegistry_withRegistry_succeeds() async throws {
    // Types from two separate FileDescriptors registered in the same registry.
    var descA = MessageDescriptor(name: "A", fullName: "svc.A")
    descA.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    var fileA = FileDescriptor(name: "a.proto", package: "svc")
    fileA.addMessage(descA)

    var descB = MessageDescriptor(name: "B", fullName: "svc.B")
    descB.addField(FieldDescriptor(name: "a", number: 1, type: .message, typeName: "svc.A"))

    var fileB = FileDescriptor(name: "b.proto", package: "svc")
    fileB.addMessage(descB)

    let registry = TypeRegistry()
    try await registry.registerFile(fileA)
    try await registry.registerFile(fileB)

    // Serialise B containing A.
    var innerMsg = factory.createMessage(from: descA)
    try innerMsg.set(Int32(99), forField: "id")
    var outerMsg = factory.createMessage(from: descB)
    try outerMsg.set(innerMsg, forField: "a")
    let data = try serializer.serialize(outerMsg)

    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: descB)

    let decodedA = try XCTUnwrap(decoded.get(forField: "a") as? DynamicMessage)
    XCTAssertEqual(try decodedA.get(forField: "id") as? Int32, 99)
  }

  func test_deserialize_structurallyNestedType_withRegistry_preferNested() async throws {
    // Truly nested Inner: fullName = "pkg.Outer.Inner".
    // Registry also has a sibling "pkg.Sibling" — must not be chosen.
    var innerDesc = MessageDescriptor(name: "Inner", fullName: "pkg.Outer.Inner")
    innerDesc.addField(FieldDescriptor(name: "x", number: 1, type: .int32))

    var outerDesc = MessageDescriptor(name: "Outer", fullName: "pkg.Outer")
    outerDesc.addField(
      FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "pkg.Outer.Inner")
    )
    outerDesc.addNestedMessage(innerDesc)

    var siblingDesc = MessageDescriptor(name: "Sibling", fullName: "pkg.Sibling")
    siblingDesc.addField(FieldDescriptor(name: "y", number: 1, type: .int32))

    let registry = try await makeRegistry(siblingDesc)

    var innerMsg = factory.createMessage(from: innerDesc)
    try innerMsg.set(Int32(7), forField: "x")
    var outerMsg = factory.createMessage(from: outerDesc)
    try outerMsg.set(innerMsg, forField: "inner")
    let data = try serializer.serialize(outerMsg)

    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: outerDesc)

    let decodedInner = try XCTUnwrap(decoded.get(forField: "inner") as? DynamicMessage)
    XCTAssertEqual(try decodedInner.get(forField: "x") as? Int32, 7)
  }

  func test_deserialize_proto2GroupFieldSibling_withRegistry_succeeds() async throws {
    var groupDesc = MessageDescriptor(name: "MyGroup", fullName: "test.MyGroup", syntax: "proto2")
    groupDesc.addField(FieldDescriptor(name: "a", number: 1, type: .int32))

    var msgDesc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    msgDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    msgDesc.addField(
      FieldDescriptor(name: "my_group", number: 2, type: .group, typeName: "test.MyGroup")
    )
    // No addNestedMessage — group is a sibling.

    var groupMsg = factory.createMessage(from: groupDesc)
    try groupMsg.set(Int32(42), forField: "a")
    var msg = factory.createMessage(from: msgDesc)
    try msg.set(Int32(1), forField: "id")
    try msg.set(groupMsg, forField: "my_group")
    let data = try serializer.serialize(msg)

    let registry = try await makeRegistry(groupDesc)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: msgDesc)

    XCTAssertEqual(try decoded.get(forField: "id") as? Int32, 1)
    let decodedGroup = try XCTUnwrap(decoded.get(forField: "my_group") as? DynamicMessage)
    XCTAssertEqual(try decodedGroup.get(forField: "a") as? Int32, 42)
  }

  // MARK: - C. Negative: error paths

  func test_deserialize_siblingMessage_withoutRegistry_throwsError() async throws {
    let descA = makeSiblingA()
    let descB = makeSiblingB()
    let data = try await serialiseBContainingA(descA: descA, aValue: "test")

    do {
      _ = try await BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(data, using: descB)
      XCTFail("Expected error to be thrown")
    }
    catch {
      guard case .unsupportedNestedMessage(let typeName) = error as? DeserializationError else {
        XCTFail("Expected unsupportedNestedMessage, got \(error)")
        return
      }
      XCTAssertEqual(typeName, "pkg.A")
    }
  }

  func test_deserialize_unknownTypeInRegistry_throwsError() async throws {
    let descA = makeSiblingA()
    let descB = makeSiblingB()
    let data = try await serialiseBContainingA(descA: descA, aValue: "test")

    // Registry has a different type — pkg.A is NOT registered.
    var otherDesc = MessageDescriptor(name: "Other", fullName: "pkg.Other")
    otherDesc.addField(FieldDescriptor(name: "v", number: 1, type: .string))
    let registry = try await makeRegistry(otherDesc)

    let opts = DeserializationOptions(typeRegistry: registry)
    do {
      _ = try await BinaryDeserializer(options: opts).deserialize(data, using: descB)
      XCTFail("Expected error to be thrown")
    }
    catch {
      XCTAssertTrue(error is DeserializationError)
    }
  }

  func test_deserialize_emptyRegistry_throwsError() async throws {
    let descA = makeSiblingA()
    let descB = makeSiblingB()
    let data = try await serialiseBContainingA(descA: descA, aValue: "test")

    let registry = TypeRegistry()  // empty
    let opts = DeserializationOptions(typeRegistry: registry)
    do {
      _ = try await BinaryDeserializer(options: opts).deserialize(data, using: descB)
      XCTFail("Expected error to be thrown")
    }
    catch {
      XCTAssertTrue(error is DeserializationError)
    }
  }

  func test_deserialize_nilRegistry_siblingMessage_throwsError() async throws {
    let descA = makeSiblingA()
    let descB = makeSiblingB()
    let data = try await serialiseBContainingA(descA: descA, aValue: "test")

    let opts = DeserializationOptions(typeRegistry: TypeRegistry())
    do {
      _ = try await BinaryDeserializer(options: opts).deserialize(data, using: descB)
      XCTFail("Expected error to be thrown")
    }
    catch {
      XCTAssertTrue(error is DeserializationError)
    }
  }

  // MARK: - D. Corner cases

  func test_deserialize_deeplyNestedChain_5levels_withRegistry_succeeds() async throws {
    // E → D → C → B → A → (leaf int32)
    var descA = MessageDescriptor(name: "A", fullName: "chain.A")
    descA.addField(FieldDescriptor(name: "val", number: 1, type: .int32))

    var descB = MessageDescriptor(name: "B", fullName: "chain.B")
    descB.addField(FieldDescriptor(name: "a", number: 1, type: .message, typeName: "chain.A"))

    var descC = MessageDescriptor(name: "C", fullName: "chain.C")
    descC.addField(FieldDescriptor(name: "b", number: 1, type: .message, typeName: "chain.B"))

    var descD = MessageDescriptor(name: "D", fullName: "chain.D")
    descD.addField(FieldDescriptor(name: "c", number: 1, type: .message, typeName: "chain.C"))

    var descE = MessageDescriptor(name: "E", fullName: "chain.E")
    descE.addField(FieldDescriptor(name: "d", number: 1, type: .message, typeName: "chain.D"))

    // Serialise with lies to produce valid binary data.
    var sB = descB
    sB.addNestedMessage(descA)
    var sC = descC
    sC.addNestedMessage(sB)
    var sD = descD
    sD.addNestedMessage(sC)
    var sE = descE
    sE.addNestedMessage(sD)

    var msgA = factory.createMessage(from: descA)
    try msgA.set(Int32(5), forField: "val")
    var msgB = factory.createMessage(from: sB)
    try msgB.set(msgA, forField: "a")
    var msgC = factory.createMessage(from: sC)
    try msgC.set(msgB, forField: "b")
    var msgD = factory.createMessage(from: sD)
    try msgD.set(msgC, forField: "c")
    var msgE = factory.createMessage(from: sE)
    try msgE.set(msgD, forField: "d")
    let data = try serializer.serialize(msgE)

    // Deserialise with clean registry.
    let registry = try await makeRegistry(descA, descB, descC, descD, descE)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: descE)

    let dD = try XCTUnwrap(decoded.get(forField: "d") as? DynamicMessage)
    let dC = try XCTUnwrap(dD.get(forField: "c") as? DynamicMessage)
    let dB = try XCTUnwrap(dC.get(forField: "b") as? DynamicMessage)
    let dA = try XCTUnwrap(dB.get(forField: "a") as? DynamicMessage)
    XCTAssertEqual(try dA.get(forField: "val") as? Int32, 5)
  }

  func test_deserialize_typeNameWithLeadingDotStripped_withRegistry_succeeds() async throws {
    // Multi-component leading-dot type name: ".com.example.Widget".
    var widgetDesc = MessageDescriptor(name: "Widget", fullName: "com.example.Widget")
    widgetDesc.addField(FieldDescriptor(name: "label", number: 1, type: .string))

    var boxDesc = MessageDescriptor(name: "Box", fullName: "com.example.Box")
    boxDesc.addField(
      FieldDescriptor(name: "widget", number: 1, type: .message, typeName: ".com.example.Widget")
    )

    // Serialise (binary format is the same regardless of leading dot in schema).
    var widgetMsg = factory.createMessage(from: widgetDesc)
    try widgetMsg.set("blue", forField: "label")
    var boxMsg = factory.createMessage(from: boxDesc)
    try boxMsg.set(widgetMsg, forField: "widget")
    let data = try serializer.serialize(boxMsg)

    let registry = try await makeRegistry(widgetDesc)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: boxDesc)

    let decodedWidget = try XCTUnwrap(decoded.get(forField: "widget") as? DynamicMessage)
    XCTAssertEqual(try decodedWidget.get(forField: "label") as? String, "blue")
  }

  func test_deserialize_registryWithMultipleSiblingTypes_allResolved() async throws {
    // Container has two fields, each pointing to a different sibling.
    var typeX = MessageDescriptor(name: "X", fullName: "multi.X")
    typeX.addField(FieldDescriptor(name: "x_val", number: 1, type: .int32))

    var typeY = MessageDescriptor(name: "Y", fullName: "multi.Y")
    typeY.addField(FieldDescriptor(name: "y_val", number: 1, type: .string))

    var containerDesc = MessageDescriptor(name: "Container", fullName: "multi.Container")
    containerDesc.addField(
      FieldDescriptor(name: "x", number: 1, type: .message, typeName: "multi.X")
    )
    containerDesc.addField(
      FieldDescriptor(name: "y", number: 2, type: .message, typeName: "multi.Y")
    )

    // Serialise.
    var serDesc = containerDesc
    serDesc.addNestedMessage(typeX)
    serDesc.addNestedMessage(typeY)

    var msgX = factory.createMessage(from: typeX)
    try msgX.set(Int32(11), forField: "x_val")
    var msgY = factory.createMessage(from: typeY)
    try msgY.set("hello", forField: "y_val")
    var containerMsg = factory.createMessage(from: serDesc)
    try containerMsg.set(msgX, forField: "x")
    try containerMsg.set(msgY, forField: "y")
    let data = try serializer.serialize(containerMsg)

    // Deserialise with clean registry.
    let registry = try await makeRegistry(typeX, typeY, containerDesc)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: containerDesc)

    let dX = try XCTUnwrap(decoded.get(forField: "x") as? DynamicMessage)
    XCTAssertEqual(try dX.get(forField: "x_val") as? Int32, 11)
    let dY = try XCTUnwrap(decoded.get(forField: "y") as? DynamicMessage)
    XCTAssertEqual(try dY.get(forField: "y_val") as? String, "hello")
  }

  func test_deserialize_emptyMessageBody_withRegistry_succeeds() async throws {
    // Inner message is set but has no fields — serialised as a 0-length LV.
    let descA = makeSiblingA()
    let descB = makeSiblingB()

    let emptyInner = factory.createMessage(from: descA)  // all fields default/nil
    var outerMsg = factory.createMessage(from: descB)
    try outerMsg.set(emptyInner, forField: "a")
    let data = try serializer.serialize(outerMsg)

    let registry = try await makeRegistry(descA)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: descB)

    let decodedA = try XCTUnwrap(decoded.get(forField: "a") as? DynamicMessage)
    XCTAssertNil(try decodedA.get(forField: "value"))
  }

  func test_deserialize_largeMessage_withRegistry_succeeds() async throws {
    // Inner message with a large string value to stress-test registry lookup.
    let descA = makeSiblingA()
    let descB = makeSiblingB()

    let largeString = String(repeating: "X", count: 10_000)
    let data = try await serialiseBContainingA(descA: descA, aValue: largeString)

    let registry = try await makeRegistry(descA)
    let opts = DeserializationOptions(typeRegistry: registry)
    let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: descB)

    let decodedA = try XCTUnwrap(decoded.get(forField: "a") as? DynamicMessage)
    XCTAssertEqual(try decodedA.get(forField: "value") as? String, largeString)
  }

  func test_deserialize_partialDataForMessageField_throwsTruncated() async throws {
    // Truncated binary data for a message field — must throw a binary error
    // regardless of registry presence (data is read before type resolution).
    let descA = makeSiblingA()
    let descB = makeSiblingB()
    let fullData = try await serialiseBContainingA(descA: descA, aValue: "complete")

    // Keep only the first 3 bytes: enough for the outer tag/length varint but
    // not the full inner message bytes.
    let truncated = fullData.prefix(3)

    let registry = try await makeRegistry(descA)
    let opts = DeserializationOptions(typeRegistry: registry)
    do {
      _ = try await BinaryDeserializer(options: opts).deserialize(Data(truncated), using: descB)
      XCTFail("Expected error to be thrown")
    }
    catch {
      XCTAssertTrue(error is DeserializationError)
    }
  }
}
