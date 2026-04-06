//
// JSONNestedMessageDeserializationTests.swift
//
// Tests for JSON deserialization of nested Protocol Buffers messages.
// Covers: single nested, repeated nested, map<K, Message>, deep nesting,
// self-referencing messages, max depth guard, error paths, round-trip.
//

import XCTest

@testable import SwiftProtoReflect

final class JSONNestedMessageDeserializationTests: XCTestCase {

  // MARK: - Helpers

  private func makeRegistry(with fileDescriptor: FileDescriptor) async throws -> TypeRegistry {
    let registry = TypeRegistry()
    try await registry.registerFile(fileDescriptor)
    return registry
  }

  private func makeDeserializer(registry: TypeRegistry, maxNestingDepth: Int = 64) -> JSONDeserializer {
    let options = JSONDeserializationOptions(
      ignoreUnknownFields: true,
      typeRegistry: registry,
      maxNestingDepth: maxNestingDepth
    )
    return JSONDeserializer(options: options)
  }

  private func json(_ string: String) -> Data {
    string.data(using: .utf8)!
  }

  // MARK: - Single Nested Message

  func test_deserialize_singleNestedMessage_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var inner = MessageDescriptor(name: "Inner", parent: file)
    inner.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    file.addMessage(inner)

    var outer = MessageDescriptor(name: "Outer", parent: file)
    outer.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    outer.addField(FieldDescriptor(name: "inner", number: 2, type: .message, typeName: "test.Inner"))
    file.addMessage(outer)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"id": 42, "inner": {"value": "hello"}}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["Outer"]!)
    let accessor = FieldAccessor(message)

    XCTAssertEqual(accessor.getValue("id", as: Int32.self), 42)

    let innerMessage = try message.get(forField: "inner") as? DynamicMessage
    XCTAssertNotNil(innerMessage)
    XCTAssertEqual(innerMessage?.descriptor.fullName, "test.Inner")
    let innerAccessor = FieldAccessor(innerMessage!)
    XCTAssertEqual(innerAccessor.getValue("value", as: String.self), "hello")
  }

  // MARK: - Repeated Message Field

  func test_deserialize_repeatedMessageField_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var item = MessageDescriptor(name: "Item", parent: file)
    item.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    item.addField(FieldDescriptor(name: "quantity", number: 2, type: .int32))
    file.addMessage(item)

    var order = MessageDescriptor(name: "Order", parent: file)
    order.addField(
      FieldDescriptor(name: "items", number: 1, type: .message, typeName: "test.Item", isRepeated: true)
    )
    file.addMessage(order)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"items": [{"name": "Apple", "quantity": 3}, {"name": "Banana", "quantity": 5}]}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["Order"]!)
    let items = try message.get(forField: "items") as? [Any]
    XCTAssertNotNil(items)
    XCTAssertEqual(items?.count, 2)

    let firstItem = items?[0] as? DynamicMessage
    XCTAssertNotNil(firstItem)
    XCTAssertEqual(FieldAccessor(firstItem!).getValue("name", as: String.self), "Apple")
    XCTAssertEqual(FieldAccessor(firstItem!).getValue("quantity", as: Int32.self), 3)

    let secondItem = items?[1] as? DynamicMessage
    XCTAssertNotNil(secondItem)
    XCTAssertEqual(FieldAccessor(secondItem!).getValue("name", as: String.self), "Banana")
    XCTAssertEqual(FieldAccessor(secondItem!).getValue("quantity", as: Int32.self), 5)
  }

  // MARK: - Map with Message Values

  func test_deserialize_mapWithMessageValues_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var config = MessageDescriptor(name: "Config", parent: file)
    config.addField(FieldDescriptor(name: "enabled", number: 1, type: .bool))
    config.addField(FieldDescriptor(name: "timeout", number: 2, type: .int32))
    file.addMessage(config)

    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "test.Config")
    let mapEntry = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    var settings = MessageDescriptor(name: "Settings", parent: file)
    settings.addField(
      FieldDescriptor(
        name: "configs",
        number: 1,
        type: .message,
        typeName: "test.Settings.ConfigsEntry",
        isMap: true,
        mapEntryInfo: mapEntry
      )
    )
    file.addMessage(settings)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"configs": {"db": {"enabled": true, "timeout": 30}, "cache": {"enabled": false, "timeout": 10}}}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["Settings"]!)
    let configs = try message.get(forField: "configs") as? [AnyHashable: Any]
    XCTAssertNotNil(configs)
    XCTAssertEqual(configs?.count, 2)

    let dbConfig = configs?["db" as AnyHashable] as? DynamicMessage
    XCTAssertNotNil(dbConfig)
    XCTAssertEqual(FieldAccessor(dbConfig!).getValue("enabled", as: Bool.self), true)
    XCTAssertEqual(FieldAccessor(dbConfig!).getValue("timeout", as: Int32.self), 30)

    let cacheConfig = configs?["cache" as AnyHashable] as? DynamicMessage
    XCTAssertNotNil(cacheConfig)
    XCTAssertEqual(FieldAccessor(cacheConfig!).getValue("enabled", as: Bool.self), false)
    XCTAssertEqual(FieldAccessor(cacheConfig!).getValue("timeout", as: Int32.self), 10)
  }

  // MARK: - Deep Nesting (3 levels)

  func test_deserialize_threeLayerNesting_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var c = MessageDescriptor(name: "C", parent: file)
    c.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    file.addMessage(c)

    var b = MessageDescriptor(name: "B", parent: file)
    b.addField(FieldDescriptor(name: "c", number: 1, type: .message, typeName: "test.C"))
    file.addMessage(b)

    var a = MessageDescriptor(name: "A", parent: file)
    a.addField(FieldDescriptor(name: "b", number: 1, type: .message, typeName: "test.B"))
    file.addMessage(a)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"b": {"c": {"value": "deep"}}}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["A"]!)

    let bMsg = try message.get(forField: "b") as? DynamicMessage
    XCTAssertNotNil(bMsg)

    let cMsg = try bMsg?.get(forField: "c") as? DynamicMessage
    XCTAssertNotNil(cMsg)

    XCTAssertEqual(FieldAccessor(cMsg!).getValue("value", as: String.self), "deep")
  }

  // MARK: - Max Depth Guard

  func test_deserialize_nestingDepthExceeded_throwsError() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var node = MessageDescriptor(name: "Node", parent: file)
    node.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    node.addField(FieldDescriptor(name: "child", number: 2, type: .message, typeName: "test.Node"))
    file.addMessage(node)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry, maxNestingDepth: 2)

    let data = json(
      """
      {"name": "l0", "child": {"name": "l1", "child": {"name": "l2", "child": {"name": "l3"}}}}
      """
    )

    do {
      try await deserializer.deserialize(data, using: file.messages["Node"]!)
      XCTFail("Expected error to be thrown")
    }
    catch {
      if let jsonError = error as? JSONDeserializationError,
        case .nestingDepthExceeded(let maxDepth) = jsonError
      {
        XCTAssertEqual(maxDepth, 2)
      }
      else {
        XCTFail("Expected nestingDepthExceeded error, got: \(error)")
      }
    }
  }

  // MARK: - Self-Referencing Message (within depth)

  func test_deserialize_selfReferencingMessage_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var node = MessageDescriptor(name: "Node", parent: file)
    node.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    node.addField(FieldDescriptor(name: "child", number: 2, type: .message, typeName: "test.Node"))
    file.addMessage(node)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"name": "root", "child": {"name": "leaf"}}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["Node"]!)
    XCTAssertEqual(FieldAccessor(message).getValue("name", as: String.self), "root")

    let child = try message.get(forField: "child") as? DynamicMessage
    XCTAssertNotNil(child)
    XCTAssertEqual(FieldAccessor(child!).getValue("name", as: String.self), "leaf")
  }

  // MARK: - Empty Nested Message

  func test_deserialize_emptyNestedMessage_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    let inner = MessageDescriptor(name: "Empty", parent: file)
    file.addMessage(inner)

    var outer = MessageDescriptor(name: "Wrapper", parent: file)
    outer.addField(FieldDescriptor(name: "empty", number: 1, type: .message, typeName: "test.Empty"))
    file.addMessage(outer)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"empty": {}}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["Wrapper"]!)
    let emptyMsg = try message.get(forField: "empty") as? DynamicMessage
    XCTAssertNotNil(emptyMsg)
    XCTAssertEqual(emptyMsg?.descriptor.fullName, "test.Empty")
  }

  // MARK: - Nested Message with All Scalar Field Types

  func test_deserialize_nestedMessageWithScalarFields_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var payload = MessageDescriptor(name: "Payload", parent: file)
    payload.addField(FieldDescriptor(name: "d", number: 1, type: .double))
    payload.addField(FieldDescriptor(name: "f", number: 2, type: .float))
    payload.addField(FieldDescriptor(name: "i32", number: 3, type: .int32))
    payload.addField(FieldDescriptor(name: "i64", number: 4, type: .int64))
    payload.addField(FieldDescriptor(name: "u32", number: 5, type: .uint32))
    payload.addField(FieldDescriptor(name: "u64", number: 6, type: .uint64))
    payload.addField(FieldDescriptor(name: "b", number: 7, type: .bool))
    payload.addField(FieldDescriptor(name: "s", number: 8, type: .string))
    payload.addField(FieldDescriptor(name: "data", number: 9, type: .bytes))
    file.addMessage(payload)

    var envelope = MessageDescriptor(name: "Envelope", parent: file)
    envelope.addField(FieldDescriptor(name: "payload", number: 1, type: .message, typeName: "test.Payload"))
    file.addMessage(envelope)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"payload": {"d": 3.14, "f": 2.71, "i32": -42, "i64": "9223372036854775000", "u32": 100, "u64": "18446744073709551000", "b": true, "s": "hello", "data": "AQID"}}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["Envelope"]!)
    let payloadMsg = try message.get(forField: "payload") as? DynamicMessage
    XCTAssertNotNil(payloadMsg)
    let pa = FieldAccessor(payloadMsg!)

    XCTAssertEqual(pa.getValue("d", as: Double.self)!, 3.14, accuracy: 0.001)
    XCTAssertEqual(pa.getValue("f", as: Float.self)!, 2.71, accuracy: 0.01)
    XCTAssertEqual(pa.getValue("i32", as: Int32.self), -42)
    XCTAssertEqual(pa.getValue("i64", as: Int64.self), 9_223_372_036_854_775_000)
    XCTAssertEqual(pa.getValue("u32", as: UInt32.self), 100)
    XCTAssertEqual(pa.getValue("u64", as: UInt64.self), 18_446_744_073_709_551_000)
    XCTAssertEqual(pa.getValue("b", as: Bool.self), true)
    XCTAssertEqual(pa.getValue("s", as: String.self), "hello")
    XCTAssertEqual(pa.getValue("data", as: Data.self), Data([0x01, 0x02, 0x03]))
  }

  // MARK: - Multiple Nested Message Fields

  func test_deserialize_multipleNestedMessageFields_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var address = MessageDescriptor(name: "Address", parent: file)
    address.addField(FieldDescriptor(name: "city", number: 1, type: .string))
    file.addMessage(address)

    var company = MessageDescriptor(name: "Company", parent: file)
    company.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    file.addMessage(company)

    var person = MessageDescriptor(name: "Person", parent: file)
    person.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    person.addField(FieldDescriptor(name: "address", number: 2, type: .message, typeName: "test.Address"))
    person.addField(FieldDescriptor(name: "company", number: 3, type: .message, typeName: "test.Company"))
    file.addMessage(person)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"name": "Alice", "address": {"city": "Moscow"}, "company": {"name": "Acme"}}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["Person"]!)

    XCTAssertEqual(FieldAccessor(message).getValue("name", as: String.self), "Alice")

    let addr = try message.get(forField: "address") as? DynamicMessage
    XCTAssertEqual(FieldAccessor(addr!).getValue("city", as: String.self), "Moscow")

    let comp = try message.get(forField: "company") as? DynamicMessage
    XCTAssertEqual(FieldAccessor(comp!).getValue("name", as: String.self), "Acme")
  }

  // MARK: - CamelCase JSON Field Names in Nested Messages

  func test_deserialize_nestedMessageWithCamelCaseNames_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var detail = MessageDescriptor(name: "Detail", parent: file)
    detail.addField(
      FieldDescriptor(name: "first_name", number: 1, type: .string, jsonName: "firstName")
    )
    detail.addField(
      FieldDescriptor(name: "last_name", number: 2, type: .string, jsonName: "lastName")
    )
    file.addMessage(detail)

    var wrapper = MessageDescriptor(name: "Wrapper", parent: file)
    wrapper.addField(
      FieldDescriptor(
        name: "user_detail",
        number: 1,
        type: .message,
        typeName: "test.Detail",
        jsonName: "userDetail"
      )
    )
    file.addMessage(wrapper)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"userDetail": {"firstName": "John", "lastName": "Doe"}}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["Wrapper"]!)
    let detail2 = try message.get(forField: "user_detail") as? DynamicMessage
    XCTAssertNotNil(detail2)
    XCTAssertEqual(FieldAccessor(detail2!).getValue("first_name", as: String.self), "John")
    XCTAssertEqual(FieldAccessor(detail2!).getValue("last_name", as: String.self), "Doe")
  }

  // MARK: - Round-trip: Nested Message

  func test_deserialize_roundTripNestedMessage_matches() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var inner = MessageDescriptor(name: "Inner", parent: file)
    inner.addField(FieldDescriptor(name: "tag", number: 1, type: .string))
    inner.addField(FieldDescriptor(name: "score", number: 2, type: .int32))
    file.addMessage(inner)

    var outer = MessageDescriptor(name: "Outer", parent: file)
    outer.addField(FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "test.Inner"))
    file.addMessage(outer)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)
    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))

    let innerMsg = DynamicMessage(descriptor: file.messages["Inner"]!)
    var outerMsg = DynamicMessage(descriptor: file.messages["Outer"]!)
    var innerMut = innerMsg
    try innerMut.set("test-tag", forField: "tag")
    try innerMut.set(Int32(99), forField: "score")
    try outerMsg.set(innerMut, forField: "inner")

    let jsonData = try await serializer.serialize(outerMsg)
    let deserialized = try await deserializer.deserialize(jsonData, using: file.messages["Outer"]!)

    XCTAssertEqual(outerMsg, deserialized)
  }

  // MARK: - Round-trip: Repeated Nested Messages

  func test_deserialize_roundTripRepeatedNestedMessages_matches() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var entry = MessageDescriptor(name: "Entry", parent: file)
    entry.addField(FieldDescriptor(name: "key", number: 1, type: .string))
    file.addMessage(entry)

    var collection = MessageDescriptor(name: "Collection", parent: file)
    collection.addField(
      FieldDescriptor(name: "entries", number: 1, type: .message, typeName: "test.Entry", isRepeated: true)
    )
    file.addMessage(collection)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)
    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))

    var e1 = DynamicMessage(descriptor: file.messages["Entry"]!)
    try e1.set("alpha", forField: "key")
    var e2 = DynamicMessage(descriptor: file.messages["Entry"]!)
    try e2.set("beta", forField: "key")

    var col = DynamicMessage(descriptor: file.messages["Collection"]!)
    try col.set([e1, e2] as [Any], forField: "entries")

    let jsonData = try await serializer.serialize(col)
    let deserialized = try await deserializer.deserialize(jsonData, using: file.messages["Collection"]!)

    XCTAssertEqual(col, deserialized)
  }

  // MARK: - Error: No Registry (empty registry)

  func test_deserialize_noRegistryWithNestedMessage_throwsDescriptorNotFound() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var inner = MessageDescriptor(name: "Inner", parent: file)
    inner.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    file.addMessage(inner)

    var outer = MessageDescriptor(name: "Outer", parent: file)
    outer.addField(FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "test.Inner"))
    file.addMessage(outer)

    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))

    let data = json(
      """
      {"inner": {"value": "hello"}}
      """
    )

    do {
      try await deserializer.deserialize(data, using: file.messages["Outer"]!)
      XCTFail("Expected error to be thrown")
    }
    catch {
      if let jsonError = error as? JSONDeserializationError,
        case .nestedMessageDescriptorNotFound(let fieldName, let typeName) = jsonError
      {
        XCTAssertEqual(fieldName, "inner")
        XCTAssertEqual(typeName, "test.Inner")
      }
      else {
        XCTFail("Expected nestedMessageDescriptorNotFound error, got: \(error)")
      }
    }
  }

  // MARK: - Error: Type Not in Registry

  func test_deserialize_typeNotInRegistry_throwsDescriptorNotFound() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var outer = MessageDescriptor(name: "Outer", parent: file)
    outer.addField(FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "test.Missing"))
    file.addMessage(outer)

    let registry = TypeRegistry()
    try await registry.registerMessage(file.messages["Outer"]!)

    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"inner": {"value": "hello"}}
      """
    )

    do {
      try await deserializer.deserialize(data, using: file.messages["Outer"]!)
      XCTFail("Expected error to be thrown")
    }
    catch {
      if let jsonError = error as? JSONDeserializationError,
        case .nestedMessageDescriptorNotFound(let fieldName, let typeName) = jsonError
      {
        XCTAssertEqual(fieldName, "inner")
        XCTAssertEqual(typeName, "test.Missing")
      }
      else {
        XCTFail("Expected nestedMessageDescriptorNotFound error, got: \(error)")
      }
    }
  }

  // MARK: - Error: Wrong JSON Type for Nested Message

  func test_deserialize_nestedMessageWithNonObjectJSON_throwsTypeMismatch() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var inner = MessageDescriptor(name: "Inner", parent: file)
    inner.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    file.addMessage(inner)

    var outer = MessageDescriptor(name: "Outer", parent: file)
    outer.addField(FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "test.Inner"))
    file.addMessage(outer)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"inner": "not an object"}
      """
    )

    do {
      try await deserializer.deserialize(data, using: file.messages["Outer"]!)
      XCTFail("Expected error to be thrown")
    }
    catch {
      if let jsonError = error as? JSONDeserializationError,
        case .valueTypeMismatch(let fieldName, let expected, _) = jsonError
      {
        XCTAssertEqual(fieldName, "inner")
        XCTAssertEqual(expected, "Object")
      }
      else {
        XCTFail("Expected valueTypeMismatch error, got: \(error)")
      }
    }
  }

  // MARK: - Ticket Reproduction Case (OPE-240)

  func test_deserialize_ticketReproCase_succeeds() async throws {
    var file = FileDescriptor(name: "example.proto", package: "example")

    var name = MessageDescriptor(name: "Name", parent: file)
    name.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    name.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    name.addField(FieldDescriptor(name: "birthday", number: 3, type: .string))
    file.addMessage(name)

    var twoRequest = MessageDescriptor(name: "TwoRequest", parent: file)
    twoRequest.addField(
      FieldDescriptor(name: "names", number: 1, type: .message, typeName: "example.Name", isRepeated: true)
    )
    file.addMessage(twoRequest)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"names":[{"id":"test","name":"test","birthday":"2006-01-02T15:04:05Z"}]}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["TwoRequest"]!)

    let names = try message.get(forField: "names") as? [Any]
    XCTAssertNotNil(names)
    XCTAssertEqual(names?.count, 1)

    let firstName = names?[0] as? DynamicMessage
    XCTAssertNotNil(firstName)
    let fa = FieldAccessor(firstName!)
    XCTAssertEqual(fa.getValue("id", as: String.self), "test")
    XCTAssertEqual(fa.getValue("name", as: String.self), "test")
    XCTAssertEqual(fa.getValue("birthday", as: String.self), "2006-01-02T15:04:05Z")
  }

  // MARK: - Empty Repeated Messages

  func test_deserialize_emptyRepeatedMessages_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var item = MessageDescriptor(name: "Item", parent: file)
    item.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    file.addMessage(item)

    var container = MessageDescriptor(name: "Container", parent: file)
    container.addField(
      FieldDescriptor(name: "items", number: 1, type: .message, typeName: "test.Item", isRepeated: true)
    )
    file.addMessage(container)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"items": []}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["Container"]!)
    let items = try message.get(forField: "items") as? [Any]
    XCTAssertNotNil(items)
    XCTAssertEqual(items?.count, 0)
  }

  // MARK: - Nested Message Inside Repeated Inside Nested

  func test_deserialize_nestedInsideRepeatedInsideNested_succeeds() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")

    var tag = MessageDescriptor(name: "Tag", parent: file)
    tag.addField(FieldDescriptor(name: "label", number: 1, type: .string))
    file.addMessage(tag)

    var section = MessageDescriptor(name: "Section", parent: file)
    section.addField(FieldDescriptor(name: "title", number: 1, type: .string))
    section.addField(
      FieldDescriptor(name: "tags", number: 2, type: .message, typeName: "test.Tag", isRepeated: true)
    )
    file.addMessage(section)

    var document = MessageDescriptor(name: "Document", parent: file)
    document.addField(FieldDescriptor(name: "section", number: 1, type: .message, typeName: "test.Section"))
    file.addMessage(document)

    let registry = try await makeRegistry(with: file)
    let deserializer = makeDeserializer(registry: registry)

    let data = json(
      """
      {"section": {"title": "Intro", "tags": [{"label": "important"}, {"label": "draft"}]}}
      """
    )

    let message = try await deserializer.deserialize(data, using: file.messages["Document"]!)
    let section2 = try message.get(forField: "section") as? DynamicMessage
    XCTAssertNotNil(section2)
    XCTAssertEqual(FieldAccessor(section2!).getValue("title", as: String.self), "Intro")

    let tags = try section2?.get(forField: "tags") as? [Any]
    XCTAssertEqual(tags?.count, 2)
    let tag1 = tags?[0] as? DynamicMessage
    XCTAssertEqual(FieldAccessor(tag1!).getValue("label", as: String.self), "important")
    let tag2 = tags?[1] as? DynamicMessage
    XCTAssertEqual(FieldAccessor(tag2!).getValue("label", as: String.self), "draft")
  }

  // MARK: - New Error Description and Equality

  func test_errorDescription_nestedMessageDescriptorNotFound() async throws {
    let error = JSONDeserializationError.nestedMessageDescriptorNotFound(
      fieldName: "inner",
      typeName: "test.Inner"
    )
    XCTAssertEqual(
      error.description,
      "Nested message descriptor not found for field 'inner': test.Inner"
    )
  }

  func test_errorDescription_nestingDepthExceeded() async throws {
    let error = JSONDeserializationError.nestingDepthExceeded(maxDepth: 64)
    XCTAssertEqual(
      error.description,
      "Nesting depth exceeded maximum of 64"
    )
  }

  func test_errorEquality_nestedMessageDescriptorNotFound() async throws {
    let a = JSONDeserializationError.nestedMessageDescriptorNotFound(fieldName: "f1", typeName: "T1")
    let b = JSONDeserializationError.nestedMessageDescriptorNotFound(fieldName: "f1", typeName: "T1")
    let c = JSONDeserializationError.nestedMessageDescriptorNotFound(fieldName: "f2", typeName: "T1")
    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a, c)
  }

  func test_errorEquality_nestingDepthExceeded() async throws {
    let a = JSONDeserializationError.nestingDepthExceeded(maxDepth: 10)
    let b = JSONDeserializationError.nestingDepthExceeded(maxDepth: 10)
    let c = JSONDeserializationError.nestingDepthExceeded(maxDepth: 20)
    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a, c)
  }
}
