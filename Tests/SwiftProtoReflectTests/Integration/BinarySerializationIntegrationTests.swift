//
// BinarySerializationIntegrationTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-04
//
// End-to-end integration tests for BinaryDeserializer with TypeRegistry.
// Covers the full pipeline: MessageDescriptor → TypeRegistry → BinaryDeserializer → DynamicMessage.
// Group E from OPE-250 test plan.
//

import XCTest

@testable import SwiftProtoReflect

final class BinarySerializationIntegrationTests: XCTestCase {

  private let factory = MessageFactory()
  private let binarySerializer = BinarySerializer()

  private func makeBinaryDeserializer(registry: TypeRegistry) -> BinaryDeserializer {
    BinaryDeserializer(options: DeserializationOptions(typeRegistry: registry))
  }

  private func makeJSONDeserializer(registry: TypeRegistry) -> JSONDeserializer {
    JSONDeserializer(options: JSONDeserializationOptions(typeRegistry: registry))
  }

  // MARK: - E. Integration: End-to-End Binary

  func test_e2e_fileDescriptorToRegistry_toBinaryDeserializer_succeedsRoundTrip() async throws {
    // Full pipeline: FileDescriptor → TypeRegistry → BinaryDeserializer.
    var descRequest = MessageDescriptor(name: "Request", fullName: "api.Request")
    descRequest.addField(FieldDescriptor(name: "query", number: 1, type: .string))

    var descResponse = MessageDescriptor(name: "Response", fullName: "api.Response")
    descResponse.addField(FieldDescriptor(name: "request", number: 1, type: .message, typeName: "api.Request"))
    descResponse.addField(FieldDescriptor(name: "status", number: 2, type: .int32))

    var file = FileDescriptor(name: "api.proto", package: "api")
    file.addMessage(descRequest)
    file.addMessage(descResponse)

    let registry = TypeRegistry()
    try await registry.registerFile(file)

    // Build and serialise a Response containing a Request.
    var reqMsg = factory.createMessage(from: descRequest)
    try reqMsg.set("search", forField: "query")
    var respMsg = factory.createMessage(from: descResponse)
    try respMsg.set(reqMsg, forField: "request")
    try respMsg.set(Int32(200), forField: "status")
    let data = try binarySerializer.serialize(respMsg)

    // Deserialise using the registry — must resolve api.Request.
    let deserializer = makeBinaryDeserializer(registry: registry)
    let decoded = try await deserializer.deserialize(data, using: descResponse)

    XCTAssertEqual(try decoded.get(forField: "status") as? Int32, 200)
    let decodedReq = try XCTUnwrap(decoded.get(forField: "request") as? DynamicMessage)
    XCTAssertEqual(try decodedReq.get(forField: "query") as? String, "search")
  }

  func test_e2e_binaryAndJsonDeserializersShareSameRegistry_produceIdenticalResult() async throws {
    var descA = MessageDescriptor(name: "A", fullName: "shared.A")
    descA.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    var descB = MessageDescriptor(name: "B", fullName: "shared.B")
    descB.addField(FieldDescriptor(name: "a", number: 1, type: .message, typeName: "shared.A"))

    let registry = TypeRegistry()
    try await registry.registerMessage(descA)
    try await registry.registerMessage(descB)

    // Build the message.
    var msgA = factory.createMessage(from: descA)
    try msgA.set("unified", forField: "value")
    var msgB = factory.createMessage(from: descB)
    try msgB.set(msgA, forField: "a")

    // Serialise to binary.
    let binaryData = try binarySerializer.serialize(msgB)

    // Serialise to JSON.
    let jsonData = try await JSONSerializer(options: .init(typeRegistry: TypeRegistry())).serialize(msgB)
    let jsonObject = try XCTUnwrap(
      try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    )

    // Deserialise binary.
    let binaryDecoded = try await makeBinaryDeserializer(registry: registry).deserialize(
      binaryData,
      using: descB
    )

    // Deserialise JSON.
    let jsonDecoded = try await makeJSONDeserializer(registry: registry).deserializeFromJSONObject(
      jsonObject,
      using: descB
    )

    // Both must contain the same field values.
    let binaryA = try XCTUnwrap(binaryDecoded.get(forField: "a") as? DynamicMessage)
    let jsonA = try XCTUnwrap(jsonDecoded.get(forField: "a") as? DynamicMessage)

    XCTAssertEqual(try binaryA.get(forField: "value") as? String, "unified")
    XCTAssertEqual(try jsonA.get(forField: "value") as? String, "unified")
  }

  func test_e2e_siblingMessagesWithEnum_fullRoundTrip() async throws {
    var statusEnum = EnumDescriptor(name: "Status", fullName: "biz.Status")
    statusEnum.addValue(.init(name: "PENDING", number: 0))
    statusEnum.addValue(.init(name: "DONE", number: 1))

    var orderDesc = MessageDescriptor(name: "Order", fullName: "biz.Order")
    orderDesc.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    orderDesc.addField(FieldDescriptor(name: "status", number: 2, type: .enum, typeName: "biz.Status"))

    var invoiceDesc = MessageDescriptor(name: "Invoice", fullName: "biz.Invoice")
    invoiceDesc.addField(FieldDescriptor(name: "order", number: 1, type: .message, typeName: "biz.Order"))
    invoiceDesc.addField(FieldDescriptor(name: "total", number: 2, type: .double))

    let registry = TypeRegistry()
    try await registry.registerMessage(orderDesc)
    try await registry.registerMessage(invoiceDesc)

    var orderMsg = factory.createMessage(from: orderDesc)
    try orderMsg.set("order-123", forField: "id")
    try orderMsg.set(Int32(1), forField: "status")
    var invoiceMsg = factory.createMessage(from: invoiceDesc)
    try invoiceMsg.set(orderMsg, forField: "order")
    try invoiceMsg.set(Double(99.99), forField: "total")
    let data = try binarySerializer.serialize(invoiceMsg)

    let deserializer = makeBinaryDeserializer(registry: registry)
    let decoded = try await deserializer.deserialize(data, using: invoiceDesc)

    XCTAssertEqual(try decoded.get(forField: "total") as? Double, 99.99)
    let decodedOrder = try XCTUnwrap(decoded.get(forField: "order") as? DynamicMessage)
    XCTAssertEqual(try decodedOrder.get(forField: "id") as? String, "order-123")
    XCTAssertEqual(try decodedOrder.get(forField: "status") as? Int32, 1)
  }

  func test_e2e_wellKnownTypes_valueListValue_binaryRoundTrip() async throws {
    // Simulates google.protobuf.Value / ListValue sibling relationship.
    var valueDesc = MessageDescriptor(name: "Value", fullName: "google.protobuf.Value")
    valueDesc.addField(FieldDescriptor(name: "string_value", number: 3, type: .string))

    var listValueDesc = MessageDescriptor(name: "ListValue", fullName: "google.protobuf.ListValue")
    listValueDesc.addField(
      FieldDescriptor(
        name: "values",
        number: 1,
        type: .message,
        typeName: "google.protobuf.Value",
        isRepeated: true
      )
    )

    let registry = TypeRegistry()
    try await registry.registerMessage(valueDesc)
    try await registry.registerMessage(listValueDesc)

    // Serialise ListValue with two Value items (using lie for serialisation).
    var serListValueDesc = listValueDesc
    serListValueDesc.addNestedMessage(valueDesc)

    var v1 = factory.createMessage(from: valueDesc)
    try v1.set("alpha", forField: "string_value")
    var v2 = factory.createMessage(from: valueDesc)
    try v2.set("beta", forField: "string_value")

    var listMsg = factory.createMessage(from: serListValueDesc)
    try listMsg.set([v1, v2] as [Any], forField: "values")
    let data = try binarySerializer.serialize(listMsg)

    let deserializer = makeBinaryDeserializer(registry: registry)
    let decoded = try await deserializer.deserialize(data, using: listValueDesc)

    let items = try XCTUnwrap(decoded.get(forField: "values") as? [Any])
    XCTAssertEqual(items.count, 2)
    let first = try XCTUnwrap(items[0] as? DynamicMessage)
    XCTAssertEqual(try first.get(forField: "string_value") as? String, "alpha")
    let second = try XCTUnwrap(items[1] as? DynamicMessage)
    XCTAssertEqual(try second.get(forField: "string_value") as? String, "beta")
  }

  func test_e2e_concurrentDeserialization_sharedRegistry_isThreadSafe() async throws {
    var descA = MessageDescriptor(name: "A", fullName: "concurrent.A")
    descA.addField(FieldDescriptor(name: "v", number: 1, type: .string))

    var descB = MessageDescriptor(name: "B", fullName: "concurrent.B")
    descB.addField(FieldDescriptor(name: "a", number: 1, type: .message, typeName: "concurrent.A"))

    let registry = TypeRegistry()
    try await registry.registerMessage(descA)
    try await registry.registerMessage(descB)

    var msgA = factory.createMessage(from: descA)
    try msgA.set("thread-safe", forField: "v")
    var msgB = factory.createMessage(from: descB)
    try msgB.set(msgA, forField: "a")
    let data = try binarySerializer.serialize(msgB)

    try await withThrowingTaskGroup(of: Void.self) { group in
      for _ in 0..<20 {
        group.addTask {
          let opts = DeserializationOptions(typeRegistry: registry)
          let decoded = try await BinaryDeserializer(options: opts).deserialize(data, using: descB)
          let decodedA = try decoded.get(forField: "a") as? DynamicMessage
          _ = try decodedA?.get(forField: "v")
        }
      }
      try await group.waitForAll()
    }
  }
}
