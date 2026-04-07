//
// StructProtoProtocFixtureTests.swift
// SwiftProtoReflect
//
// Binary fixture tests for google.protobuf.Value, Struct, and ListValue.
//
// Every `.binpb` file in Tests/Fixtures/StructProto/ was produced by:
//
//   echo '<text proto>' | protoc --encode=google.protobuf.<Type> \
//     -I /usr/local/include google/protobuf/struct.proto > <name>.binpb
//
// These files are the canonical ground truth — the actual bytes emitted by
// the reference protoc implementation (libprotoc 33.5).
//
// Each test asserts THREE things:
//   1. SwiftProtobuf's serializedData() matches the fixture byte-for-byte.
//   2. Our BinarySerializer output matches the fixture byte-for-byte.
//   3. Our BinaryDeserializer correctly decodes the fixture into the expected value.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class StructProtoProtocFixtureTests: XCTestCase {

  private let serializer = BinarySerializer()
  private var deserializer: BinaryDeserializer!
  private var registry: TypeRegistry!

  override func setUp() async throws {
    registry = TypeRegistry()
    try await registry.registerFile(StructProtoDescriptors.fileDescriptor)
    deserializer = BinaryDeserializer(options: DeserializationOptions(typeRegistry: registry))
  }

  // MARK: - Helpers

  private func fixture(named name: String) throws -> Data {
    guard
      let url = Bundle.module.url(
        forResource: name,
        withExtension: "binpb",
        subdirectory: "StructProto"
      )
    else {
      throw XCTSkip("Fixture \(name).binpb not found in bundle")
    }
    return try Data(contentsOf: url)
  }

  // MARK: - Value: null_value = NULL_VALUE(0)

  func test_fixture_value_null() async throws {
    // protoc source: null_value: NULL_VALUE
    let protoc = try fixture(named: "value_null")

    var swiftpb = Google_Protobuf_Value()
    swiftpb.nullValue = .nullValue
    XCTAssertEqual(try swiftpb.serializedData(), protoc, "SwiftProtobuf mismatch vs protoc fixture")

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.nullValue)
    let _asyncResult10 = try serializer.serialize(dynMsg)
    XCTAssertEqual(_asyncResult10, protoc, "Our serializer mismatch vs protoc fixture")

    let decoded = try await deserializer.deserialize(protoc, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue)
    XCTAssertEqual(result, .nullValue)
  }

  // MARK: - Value: number_value = 1.0

  func test_fixture_value_number_1() async throws {
    // protoc source: number_value: 1.0
    let protoc = try fixture(named: "value_number_1")

    var swiftpb = Google_Protobuf_Value()
    swiftpb.numberValue = 1.0
    XCTAssertEqual(try swiftpb.serializedData(), protoc, "SwiftProtobuf mismatch vs protoc fixture")

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.numberValue(1.0))
    let _asyncResult11 = try serializer.serialize(dynMsg)
    XCTAssertEqual(_asyncResult11, protoc, "Our serializer mismatch vs protoc fixture")

    let decoded = try await deserializer.deserialize(protoc, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue)
    XCTAssertEqual(result, .numberValue(1.0))
  }

  // MARK: - Value: string_value = "hi"

  func test_fixture_value_string_hi() async throws {
    // protoc source: string_value: "hi"
    let protoc = try fixture(named: "value_string_hi")

    var swiftpb = Google_Protobuf_Value()
    swiftpb.stringValue = "hi"
    XCTAssertEqual(try swiftpb.serializedData(), protoc, "SwiftProtobuf mismatch vs protoc fixture")

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.stringValue("hi"))
    let _asyncResult12 = try serializer.serialize(dynMsg)
    XCTAssertEqual(_asyncResult12, protoc, "Our serializer mismatch vs protoc fixture")

    let decoded = try await deserializer.deserialize(protoc, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue)
    XCTAssertEqual(result, .stringValue("hi"))
  }

  // MARK: - Value: bool_value = true

  func test_fixture_value_bool_true() async throws {
    // protoc source: bool_value: true
    let protoc = try fixture(named: "value_bool_true")

    var swiftpb = Google_Protobuf_Value()
    swiftpb.boolValue = true
    XCTAssertEqual(try swiftpb.serializedData(), protoc, "SwiftProtobuf mismatch vs protoc fixture")

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.boolValue(true))
    let _asyncResult13 = try serializer.serialize(dynMsg)
    XCTAssertEqual(_asyncResult13, protoc, "Our serializer mismatch vs protoc fixture")

    let decoded = try await deserializer.deserialize(protoc, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue)
    XCTAssertEqual(result, .boolValue(true))
  }

  // MARK: - Value: bool_value = false (critical oneof edge case)

  func test_fixture_value_bool_false() async throws {
    // protoc source: bool_value: false
    // KEY: bool=false inside a oneof MUST be emitted (field tag + 0x00), not omitted.
    let protoc = try fixture(named: "value_bool_false")

    var swiftpb = Google_Protobuf_Value()
    swiftpb.boolValue = false
    XCTAssertEqual(try swiftpb.serializedData(), protoc, "SwiftProtobuf mismatch vs protoc fixture")

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.boolValue(false))
    let _asyncResult14 = try serializer.serialize(dynMsg)
    XCTAssertEqual(_asyncResult14, protoc, "Our serializer mismatch vs protoc fixture")

    let decoded = try await deserializer.deserialize(protoc, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue)
    XCTAssertEqual(result, .boolValue(false))
  }

  // MARK: - ListValue: [string_value="hi"]

  func test_fixture_listvalue_string_hi() async throws {
    // protoc source: values { string_value: "hi" }
    let protoc = try fixture(named: "listvalue_string_hi")

    var swiftpb = Google_Protobuf_ListValue()
    swiftpb.values = [Google_Protobuf_Value(stringValue: "hi")]
    XCTAssertEqual(try swiftpb.serializedData(), protoc, "SwiftProtobuf mismatch vs protoc fixture")

    let dynMsg = try ListValueHandler.createDynamic(from: [StructHandler.ValueValue.stringValue("hi")])
    let _asyncResult15 = try serializer.serialize(dynMsg)
    XCTAssertEqual(_asyncResult15, protoc, "Our serializer mismatch vs protoc fixture")

    let decoded = try await deserializer.deserialize(protoc, using: StructProtoDescriptors.listValueDescriptor)
    let result = try XCTUnwrap(
      try ListValueHandler.createSpecialized(from: decoded) as? [StructHandler.ValueValue]
    )
    XCTAssertEqual(result, [.stringValue("hi")])
  }

  // MARK: - Struct: {k: string_value="v"}

  func test_fixture_struct_k_stringv() async throws {
    // protoc source: fields { key: "k" value { string_value: "v" } }
    let protoc = try fixture(named: "struct_k_stringv")

    var swiftpb = Google_Protobuf_Struct()
    swiftpb.fields["k"] = Google_Protobuf_Value(stringValue: "v")
    XCTAssertEqual(try swiftpb.serializedData(), protoc, "SwiftProtobuf mismatch vs protoc fixture")

    let sv = StructHandler.StructValue(fields: ["k": .stringValue("v")])
    let dynMsg = try StructHandler.createDynamic(from: sv)
    let _asyncResult16 = try serializer.serialize(dynMsg)
    XCTAssertEqual(_asyncResult16, protoc, "Our serializer mismatch vs protoc fixture")

    let decoded = try await deserializer.deserialize(protoc, using: StructProtoDescriptors.structDescriptor)
    let result = try XCTUnwrap(try StructHandler.createSpecialized(from: decoded) as? StructHandler.StructValue)
    XCTAssertEqual(result.fields["k"], .stringValue("v"))
    XCTAssertEqual(result.fields.count, 1)
  }

  // MARK: - Value: struct_value = {k: string_value="v"}

  func test_fixture_value_struct() async throws {
    // protoc source: struct_value { fields { key: "k" value { string_value: "v" } } }
    let protoc = try fixture(named: "value_struct")

    var inner = Google_Protobuf_Struct()
    inner.fields["k"] = Google_Protobuf_Value(stringValue: "v")
    var swiftpb = Google_Protobuf_Value()
    swiftpb.structValue = inner
    XCTAssertEqual(try swiftpb.serializedData(), protoc, "SwiftProtobuf mismatch vs protoc fixture")

    let libSv = StructHandler.StructValue(fields: ["k": .stringValue("v")])
    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.structValue(libSv))
    let _asyncResult17 = try serializer.serialize(dynMsg)
    XCTAssertEqual(_asyncResult17, protoc, "Our serializer mismatch vs protoc fixture")

    let decoded = try await deserializer.deserialize(protoc, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue)
    guard case .structValue(let sv) = result else {
      XCTFail("Expected structValue, got \(result)")
      return
    }
    XCTAssertEqual(sv.fields["k"], .stringValue("v"))
    XCTAssertEqual(sv.fields.count, 1)
  }

  // MARK: - Value: list_value = [string_value="hi"]

  func test_fixture_value_list() async throws {
    // protoc source: list_value { values { string_value: "hi" } }
    let protoc = try fixture(named: "value_list")

    var innerList = Google_Protobuf_ListValue()
    innerList.values = [Google_Protobuf_Value(stringValue: "hi")]
    var swiftpb = Google_Protobuf_Value()
    swiftpb.listValue = innerList
    XCTAssertEqual(try swiftpb.serializedData(), protoc, "SwiftProtobuf mismatch vs protoc fixture")

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.listValue([.stringValue("hi")]))
    let _asyncResult18 = try serializer.serialize(dynMsg)
    XCTAssertEqual(_asyncResult18, protoc, "Our serializer mismatch vs protoc fixture")

    let decoded = try await deserializer.deserialize(protoc, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue)
    guard case .listValue(let items) = result else {
      XCTFail("Expected listValue, got \(result)")
      return
    }
    XCTAssertEqual(items, [.stringValue("hi")])
  }

  // MARK: - Struct: deep nesting  {items: [{id:1,name:"Alice"},{id:2,name:"Bob"}]}

  func test_fixture_struct_nested_deep() async throws {
    // protoc source:
    //   fields { key: "items" value { list_value {
    //     values { struct_value { fields { key: "id" value { number_value: 1 } }
    //                            fields { key: "name" value { string_value: "Alice" } } } }
    //     values { struct_value { fields { key: "id" value { number_value: 2 } }
    //                            fields { key: "name" value { string_value: "Bob" } } } }
    //   } } }
    //
    // NOTE: Map entries have no guaranteed ordering in the protobuf spec.
    // protoc writes them in text-proto order (id→name), while Swift Dictionary
    // iteration is hash-order. Therefore this test verifies:
    //   (a) Our BinaryDeserializer correctly decodes the protoc-generated fixture.
    //   (b) Our BinarySerializer produces valid bytes that round-trip semantically
    //       via SwiftProtobuf (not byte-for-byte equal to the protoc fixture).
    let protoc = try fixture(named: "struct_nested_deep")

    // (a) Our deserializer must decode the protoc fixture correctly.
    let decoded = try await deserializer.deserialize(protoc, using: StructProtoDescriptors.structDescriptor)
    let result = try XCTUnwrap(try StructHandler.createSpecialized(from: decoded) as? StructHandler.StructValue)
    guard case .listValue(let items) = result.fields["items"] else {
      XCTFail("Expected items to be a listValue")
      return
    }
    XCTAssertEqual(items.count, 2)
    guard case .structValue(let decodedAlice) = items[0] else {
      XCTFail("Expected first item to be a structValue")
      return
    }
    XCTAssertEqual(decodedAlice.fields["id"], .numberValue(1))
    XCTAssertEqual(decodedAlice.fields["name"], .stringValue("Alice"))
    guard case .structValue(let decodedBob) = items[1] else {
      XCTFail("Expected second item to be a structValue")
      return
    }
    XCTAssertEqual(decodedBob.fields["id"], .numberValue(2))
    XCTAssertEqual(decodedBob.fields["name"], .stringValue("Bob"))

    // (b) Our serializer output round-trips correctly through SwiftProtobuf.
    let alice = StructHandler.StructValue(fields: ["id": .numberValue(1), "name": .stringValue("Alice")])
    let bob = StructHandler.StructValue(fields: ["id": .numberValue(2), "name": .stringValue("Bob")])
    let libSv = StructHandler.StructValue(fields: [
      "items": .listValue([.structValue(alice), .structValue(bob)])
    ])
    let dynMsg = try StructHandler.createDynamic(from: libSv)
    let ourBytes = try serializer.serialize(dynMsg)
    let roundTripped = try Google_Protobuf_Struct(serializedBytes: ourBytes)
    guard case .listValue(let spbList) = roundTripped.fields["items"]?.kind else {
      XCTFail("SwiftProtobuf round-trip: expected items to be a listValue")
      return
    }
    XCTAssertEqual(spbList.values.count, 2)
    let names = spbList.values.compactMap { v -> String? in
      guard case .structValue(let s) = v.kind,
        case .stringValue(let n) = s.fields["name"]?.kind
      else { return nil }
      return n
    }
    XCTAssertEqual(Set(names), ["Alice", "Bob"])
  }
}
