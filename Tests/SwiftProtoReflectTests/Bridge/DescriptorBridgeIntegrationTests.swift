//
// DescriptorBridgeIntegrationTests.swift
// SwiftProtoReflectTests
//
// OPE-221 end-to-end scenarios (T-INT-01…05).

import XCTest

@testable import SwiftProtoReflect

final class DescriptorBridgeIntegrationTests: XCTestCase {

  private var bridge: DescriptorBridge!

  override func setUp() {
    super.setUp()
    bridge = DescriptorBridge()
  }

  override func tearDown() {
    bridge = nil
    super.tearDown()
  }

  // MARK: - T-INT-01: User oneof contact

  func test_INT01_userMessage_manualDescriptor_roundTrip_allFieldsResolveOneofName() throws {
    var msg = MessageDescriptor(name: "User", fullName: "example.User")
    msg.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addField(FieldDescriptor(name: "phone", number: 3, type: .string, oneofIndex: 0))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))

    let proto = try bridge.toProtobufDescriptor(from: msg)
    let round = try bridge.fromProtobufDescriptor(proto)

    for field in round.allFields() {
      if let idx = field.oneofIndex {
        XCTAssertEqual(round.oneof(at: idx)?.name, "contact", "field \(field.name)")
      }
    }
  }

  // MARK: - T-INT-02: Payment two oneofs

  func test_INT02_paymentMessage_twoOneofs_roundTrip_indicesAndNames() throws {
    var msg = MessageDescriptor(name: "Payment", fullName: "example.Payment")
    msg.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    msg.addField(FieldDescriptor(name: "card", number: 2, type: .string, oneofIndex: 0))
    msg.addField(FieldDescriptor(name: "bank", number: 3, type: .string, oneofIndex: 0))
    msg.addField(FieldDescriptor(name: "usd", number: 4, type: .string, oneofIndex: 1))
    msg.addField(FieldDescriptor(name: "eur", number: 5, type: .string, oneofIndex: 1))
    msg.addOneofDecl(OneofDescriptor(name: "source", index: 0))
    msg.addOneofDecl(OneofDescriptor(name: "currency", index: 1))

    let round = try bridge.fromProtobufDescriptor(try bridge.toProtobufDescriptor(from: msg))

    XCTAssertNil(round.field(named: "id")?.oneofIndex)
    XCTAssertEqual(round.field(named: "card")?.oneofIndex, 0)
    XCTAssertEqual(round.field(named: "bank")?.oneofIndex, 0)
    XCTAssertEqual(round.oneof(at: 0)?.name, "source")
    XCTAssertEqual(round.field(named: "usd")?.oneofIndex, 1)
    XCTAssertEqual(round.field(named: "eur")?.oneofIndex, 1)
    XCTAssertEqual(round.oneof(at: 1)?.name, "currency")
  }

  // MARK: - T-INT-03: Outer / Inner nested oneofs

  func test_INT03_outerInnerNestedOneofs_roundTrip_staySeparate() throws {
    var inner = MessageDescriptor(name: "Inner", fullName: "example.Outer.Inner")
    inner.addField(FieldDescriptor(name: "x", number: 1, type: .string, oneofIndex: 0))
    inner.addField(FieldDescriptor(name: "y", number: 2, type: .string, oneofIndex: 0))
    inner.addOneofDecl(OneofDescriptor(name: "format", index: 0))

    var outer = MessageDescriptor(name: "Outer", fullName: "example.Outer")
    outer.addField(FieldDescriptor(name: "a", number: 1, type: .string, oneofIndex: 0))
    outer.addField(FieldDescriptor(name: "b", number: 2, type: .string, oneofIndex: 0))
    outer.addOneofDecl(OneofDescriptor(name: "kind", index: 0))
    outer.addNestedMessage(inner)

    let round = try bridge.fromProtobufDescriptor(try bridge.toProtobufDescriptor(from: outer))

    XCTAssertEqual(round.oneofDecls.count, 1)
    XCTAssertEqual(round.oneof(at: 0)?.name, "kind")
    let innerRound = try XCTUnwrap(round.nestedMessage(named: "Inner"))
    XCTAssertEqual(innerRound.oneofDecls.count, 1)
    XCTAssertEqual(innerRound.oneof(at: 0)?.name, "format")
  }

  // MARK: - T-INT-04: Nested enum + nested message + oneof (regression)

  func test_INT04_nestedEnumNestedMessageAndOneof_composed_roundTrip() throws {
    var file = FileDescriptor(name: "mix.proto", package: "example")

    var nestedMsg = MessageDescriptor(name: "Payload", parent: file)
    nestedMsg.addField(FieldDescriptor(name: "data", number: 1, type: .string))

    var root = MessageDescriptor(name: "Root", parent: file)
    root.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    root.addField(FieldDescriptor(name: "token", number: 2, type: .string, oneofIndex: 0))
    root.addOneofDecl(OneofDescriptor(name: "auth", index: 0))
    root.addNestedMessage(nestedMsg)

    var statusEnum = EnumDescriptor(name: "Status", parent: file)
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    root.addNestedEnum(statusEnum)

    file.addMessage(root)

    let fileProto = try bridge.toProtobufFileDescriptor(from: file)
    let roundFile = try bridge.fromProtobufFileDescriptor(fileProto)
    let roundRoot = try XCTUnwrap(roundFile.messages["Root"])

    XCTAssertNotNil(roundRoot.nestedMessage(named: "Payload"))
    XCTAssertNotNil(roundRoot.nestedEnum(named: "Status"))
    XCTAssertEqual(roundRoot.oneof(at: 0)?.name, "auth")
    XCTAssertEqual(roundRoot.field(named: "token")?.oneofIndex, 0)
    XCTAssertNil(roundRoot.field(named: "id")?.oneofIndex)
  }

  // MARK: - T-INT-05: DynamicMessage binary + JSON with oneof metadata

  func test_INT05_dynamicMessage_withOneofDecls_binaryAndJsonRoundTrip() throws {
    var msg = MessageDescriptor(name: "User", fullName: "example.User")
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))

    var dynamic = DynamicMessage(descriptor: msg)
    try dynamic.set("a@b.c", forField: "email")

    let binarySerializer = BinarySerializer()
    let binaryDeserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let binData = try binarySerializer.serialize(dynamic)
    let fromBinary = try binaryDeserializer.deserialize(binData, using: msg)
    XCTAssertEqual(try fromBinary.get(forField: "email") as? String, "a@b.c")

    let jsonSerializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let jsonDeserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let jsonData = try jsonSerializer.serialize(dynamic)
    let fromJSON = try jsonDeserializer.deserialize(jsonData, using: msg)
    XCTAssertEqual(try fromJSON.get(forField: "email") as? String, "a@b.c")
  }
}
