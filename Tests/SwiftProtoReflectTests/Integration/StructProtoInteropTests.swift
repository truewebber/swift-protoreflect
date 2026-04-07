//
// StructProtoInteropTests.swift
// SwiftProtoReflect
//
// Binary interoperability tests between this library and SwiftProtobuf's generated types
// (Google_Protobuf_Struct, Google_Protobuf_Value, Google_Protobuf_ListValue).
//
// Each test verifies that binary data produced by SwiftProtobuf can be decoded by
// our library and vice-versa, proving wire-format correctness.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class StructProtoInteropTests: XCTestCase {

  // MARK: - Shared fixtures

  private let serializer = BinarySerializer()

  /// TypeRegistry populated with all struct.proto descriptors so the deserializer
  /// can resolve google.protobuf.Value, google.protobuf.Struct, and google.protobuf.ListValue
  /// when they appear as nested message fields.
  private func makeRegistry() async throws -> TypeRegistry {
    let registry = TypeRegistry()
    try await registry.registerFile(StructProtoDescriptors.fileDescriptor)
    return registry
  }

  private func makeDeserializer() async throws -> BinaryDeserializer {
    BinaryDeserializer(options: DeserializationOptions(typeRegistry: try await makeRegistry()))
  }

  // MARK: - Struct interop

  func test_interop_struct_swiftpbToLibrary_decodesCorrectly() async throws {
    var swiftpbStruct = Google_Protobuf_Struct()
    swiftpbStruct.fields["name"] = Google_Protobuf_Value(stringValue: "Alice")
    swiftpbStruct.fields["age"] = Google_Protobuf_Value(numberValue: 30)
    swiftpbStruct.fields["active"] = Google_Protobuf_Value(boolValue: true)

    let data = try swiftpbStruct.serializedData()

    let decoded = try await makeDeserializer().deserialize(data, using: StructProtoDescriptors.structDescriptor)
    let specialized = try XCTUnwrap(
      try StructHandler.createSpecialized(from: decoded) as? StructHandler.StructValue
    )

    XCTAssertEqual(specialized.fields["name"], .stringValue("Alice"))
    XCTAssertEqual(specialized.fields["age"], .numberValue(30))
    XCTAssertEqual(specialized.fields["active"], .boolValue(true))
    XCTAssertEqual(specialized.fields.count, 3)
  }

  func test_interop_struct_libraryToSwiftpb_encodesCorrectly() async throws {
    let sv = StructHandler.StructValue(fields: [
      "city": .stringValue("London"),
      "population": .numberValue(8_900_000),
    ])
    let dynamicMsg = try StructHandler.createDynamic(from: sv)
    let data = try serializer.serialize(dynamicMsg)

    let decoded = try Google_Protobuf_Struct(serializedBytes: data)

    XCTAssertEqual(decoded.fields["city"]?.stringValue, "London")
    XCTAssertEqual(decoded.fields["population"]?.numberValue, 8_900_000)
    XCTAssertEqual(decoded.fields.count, 2)
  }

  // MARK: - Value interop (null)

  func test_interop_value_nullValue_bothDirections() async throws {
    // SwiftProtobuf → Library
    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.nullValue = .nullValue
    let dataFwd = try swiftpbValue.serializedData()

    // Null value serialises to empty bytes in proto3 (default enum = 0 is not emitted).
    // Our library should return .nullValue for an empty (or zero-field) Value message.
    let decodedFwd = try await makeDeserializer().deserialize(dataFwd, using: StructProtoDescriptors.valueDescriptor)
    let valueFwd = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decodedFwd) as? ValueHandler.ValueValue
    )
    XCTAssertEqual(valueFwd, .nullValue)

    // Library → SwiftProtobuf
    // Our library explicitly sets field 1 = Int32(0), so BinarySerializer emits [0x08, 0x00].
    // SwiftProtobuf must decode this as kind == .nullValue(.nullValue), not nil.
    let dynamicMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.nullValue)
    let dataBwd = try serializer.serialize(dynamicMsg)
    XCTAssertFalse(dataBwd.isEmpty, "null_value must be emitted as [0x08, 0x00], not empty bytes")
    let decodedBwd = try Google_Protobuf_Value(serializedBytes: dataBwd)
    XCTAssertEqual(
      decodedBwd.kind,
      .nullValue(.nullValue),
      "SwiftProtobuf must decode our null_value bytes as kind == .nullValue(.nullValue)"
    )
  }

  func test_interop_value_numberValue_bothDirections() async throws {
    let number: Double = 3.14

    // SwiftProtobuf → Library
    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.numberValue = number
    let dataFwd = try swiftpbValue.serializedData()

    let decodedFwd = try await makeDeserializer().deserialize(dataFwd, using: StructProtoDescriptors.valueDescriptor)
    let valueFwd = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decodedFwd) as? ValueHandler.ValueValue
    )
    XCTAssertEqual(valueFwd, .numberValue(number))

    // Library → SwiftProtobuf
    let dynamicMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.numberValue(number))
    let dataBwd = try serializer.serialize(dynamicMsg)
    let decodedBwd = try Google_Protobuf_Value(serializedBytes: dataBwd)
    XCTAssertEqual(decodedBwd.numberValue, number, accuracy: 1e-10)
  }

  func test_interop_value_stringValue_bothDirections() async throws {
    let str = "hello, протобуф"

    // SwiftProtobuf → Library
    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.stringValue = str
    let dataFwd = try swiftpbValue.serializedData()

    let decodedFwd = try await makeDeserializer().deserialize(dataFwd, using: StructProtoDescriptors.valueDescriptor)
    let valueFwd = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decodedFwd) as? ValueHandler.ValueValue
    )
    XCTAssertEqual(valueFwd, .stringValue(str))

    // Library → SwiftProtobuf
    let dynamicMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.stringValue(str))
    let dataBwd = try serializer.serialize(dynamicMsg)
    let decodedBwd = try Google_Protobuf_Value(serializedBytes: dataBwd)
    XCTAssertEqual(decodedBwd.stringValue, str)
  }

  func test_interop_value_structValue_bothDirections() async throws {
    var inner = Google_Protobuf_Struct()
    inner.fields["x"] = Google_Protobuf_Value(numberValue: 1.0)
    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.structValue = inner
    let dataFwd = try swiftpbValue.serializedData()

    let decodedFwd = try await makeDeserializer().deserialize(dataFwd, using: StructProtoDescriptors.valueDescriptor)
    let valueFwd = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decodedFwd) as? ValueHandler.ValueValue
    )
    if case .structValue(let sv) = valueFwd {
      XCTAssertEqual(sv.fields["x"], .numberValue(1.0))
    }
    else {
      XCTFail("Expected structValue, got \(valueFwd)")
    }

    // Library → SwiftProtobuf
    let libSv = StructHandler.StructValue(fields: ["y": .stringValue("world")])
    let dynamicMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.structValue(libSv))
    let dataBwd = try serializer.serialize(dynamicMsg)
    let decodedBwd = try Google_Protobuf_Value(serializedBytes: dataBwd)
    XCTAssertEqual(decodedBwd.structValue.fields["y"]?.stringValue, "world")
  }

  func test_interop_value_boolValue_bothDirections() async throws {
    // SwiftProtobuf → Library (boolValue: false — field value equals proto default)
    var swiftpbFalse = Google_Protobuf_Value()
    swiftpbFalse.boolValue = false
    let dataFalse = try swiftpbFalse.serializedData()
    let decodedFalse = try await makeDeserializer().deserialize(
      dataFalse,
      using: StructProtoDescriptors.valueDescriptor
    )
    let valueFalse = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decodedFalse) as? ValueHandler.ValueValue
    )
    XCTAssertEqual(valueFalse, .boolValue(false))

    // SwiftProtobuf → Library (boolValue: true)
    var swiftpbTrue = Google_Protobuf_Value()
    swiftpbTrue.boolValue = true
    let dataTrue = try swiftpbTrue.serializedData()
    let decodedTrue = try await makeDeserializer().deserialize(
      dataTrue,
      using: StructProtoDescriptors.valueDescriptor
    )
    let valueTrue = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decodedTrue) as? ValueHandler.ValueValue
    )
    XCTAssertEqual(valueTrue, .boolValue(true))

    // Library → SwiftProtobuf (boolValue: false must be emitted as field 4 = 0, not omitted)
    let dynamicFalse = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.boolValue(false))
    let dataBwdFalse = try serializer.serialize(dynamicFalse)
    XCTAssertFalse(dataBwdFalse.isEmpty, "bool_value=false must be emitted (oneof field)")
    let decodedBwdFalse = try Google_Protobuf_Value(serializedBytes: dataBwdFalse)
    XCTAssertEqual(decodedBwdFalse.kind, .boolValue(false))

    // Library → SwiftProtobuf (boolValue: true)
    let dynamicTrue = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.boolValue(true))
    let dataBwdTrue = try serializer.serialize(dynamicTrue)
    let decodedBwdTrue = try Google_Protobuf_Value(serializedBytes: dataBwdTrue)
    XCTAssertEqual(decodedBwdTrue.kind, .boolValue(true))
  }

  func test_interop_value_listValue_bothDirections() async throws {
    // SwiftProtobuf → Library
    var swiftpbListInner = Google_Protobuf_ListValue()
    swiftpbListInner.values = [
      Google_Protobuf_Value(numberValue: 99),
      Google_Protobuf_Value(stringValue: "item"),
    ]
    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.listValue = swiftpbListInner
    let dataFwd = try swiftpbValue.serializedData()

    let decodedFwd = try await makeDeserializer().deserialize(dataFwd, using: StructProtoDescriptors.valueDescriptor)
    let valueFwd = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decodedFwd) as? ValueHandler.ValueValue
    )
    guard case .listValue(let items) = valueFwd else {
      XCTFail("Expected listValue, got \(valueFwd)")
      return
    }
    XCTAssertEqual(items.count, 2)
    XCTAssertEqual(items[0], .numberValue(99))
    XCTAssertEqual(items[1], .stringValue("item"))

    // Library → SwiftProtobuf
    let libValue = ValueHandler.ValueValue.listValue([.boolValue(true), .nullValue])
    let dynamicMsg = try ValueHandler.createDynamic(from: libValue)
    let dataBwd = try serializer.serialize(dynamicMsg)
    let decodedBwd = try Google_Protobuf_Value(serializedBytes: dataBwd)
    guard case .listValue(let rtList) = decodedBwd.kind else {
      XCTFail("Expected listValue kind, got \(String(describing: decodedBwd.kind))")
      return
    }
    XCTAssertEqual(rtList.values.count, 2)
    XCTAssertEqual(rtList.values[0].kind, .boolValue(true))
  }

  // MARK: - ListValue interop

  func test_interop_listValue_swiftpbToLibrary_decodesCorrectly() async throws {
    var swiftpbList = Google_Protobuf_ListValue()
    swiftpbList.values = [
      Google_Protobuf_Value(numberValue: 1),
      Google_Protobuf_Value(stringValue: "two"),
      Google_Protobuf_Value(boolValue: false),
    ]
    let data = try swiftpbList.serializedData()

    let decoded = try await makeDeserializer().deserialize(data, using: StructProtoDescriptors.listValueDescriptor)
    let specialized = try XCTUnwrap(
      try ListValueHandler.createSpecialized(from: decoded) as? [StructHandler.ValueValue]
    )

    XCTAssertEqual(specialized.count, 3)
    XCTAssertEqual(specialized[0], .numberValue(1))
    XCTAssertEqual(specialized[1], .stringValue("two"))
    XCTAssertEqual(specialized[2], .boolValue(false))
  }

  func test_interop_listValue_libraryToSwiftpb_encodesCorrectly() async throws {
    let values: [StructHandler.ValueValue] = [
      .nullValue,
      .numberValue(42),
      .stringValue("abc"),
    ]
    let dynamicMsg = try ListValueHandler.createDynamic(from: values)
    let data = try serializer.serialize(dynamicMsg)

    let decoded = try Google_Protobuf_ListValue(serializedBytes: data)

    XCTAssertEqual(decoded.values.count, 3)
    // null_value = 0 may decode as nil kind (proto3 default)
    let firstKind = decoded.values[0].kind
    XCTAssertTrue(
      firstKind == nil || firstKind == .nullValue(.nullValue),
      "Expected null, got \(String(describing: firstKind))"
    )
    XCTAssertEqual(decoded.values[1].numberValue, 42)
    XCTAssertEqual(decoded.values[2].stringValue, "abc")
  }

  // MARK: - Nesting interop

  func test_interop_nestedStructInList_roundTrip() async throws {
    // Build a deeply nested SwiftProtobuf structure:
    // { "items": [{ "id": 1, "name": "Alice" }, { "id": 2, "name": "Bob" }] }
    var alice = Google_Protobuf_Struct()
    alice.fields["id"] = Google_Protobuf_Value(numberValue: 1)
    alice.fields["name"] = Google_Protobuf_Value(stringValue: "Alice")

    var bob = Google_Protobuf_Struct()
    bob.fields["id"] = Google_Protobuf_Value(numberValue: 2)
    bob.fields["name"] = Google_Protobuf_Value(stringValue: "Bob")

    var list = Google_Protobuf_ListValue()
    var aliceValue = Google_Protobuf_Value()
    aliceValue.structValue = alice
    var bobValue = Google_Protobuf_Value()
    bobValue.structValue = bob
    list.values = [aliceValue, bobValue]

    var root = Google_Protobuf_Struct()
    var itemsValue = Google_Protobuf_Value()
    itemsValue.listValue = list
    root.fields["items"] = itemsValue

    // SwiftProtobuf → binary → Library
    let data = try root.serializedData()
    let decoded = try await makeDeserializer().deserialize(data, using: StructProtoDescriptors.structDescriptor)
    let sv = try XCTUnwrap(
      try StructHandler.createSpecialized(from: decoded) as? StructHandler.StructValue
    )

    guard case .listValue(let items) = sv.fields["items"] else {
      XCTFail("Expected listValue for 'items'")
      return
    }
    XCTAssertEqual(items.count, 2)

    guard case .structValue(let aliceSv) = items[0],
      case .structValue(let bobSv) = items[1]
    else {
      XCTFail("Expected structValue elements in list")
      return
    }
    XCTAssertEqual(aliceSv.fields["id"], .numberValue(1))
    XCTAssertEqual(aliceSv.fields["name"], .stringValue("Alice"))
    XCTAssertEqual(bobSv.fields["id"], .numberValue(2))
    XCTAssertEqual(bobSv.fields["name"], .stringValue("Bob"))

    // Library → binary → SwiftProtobuf (round-trip the other way)
    let libMsg = try StructHandler.createDynamic(from: sv)
    let rtData = try serializer.serialize(libMsg)
    let rtDecoded = try Google_Protobuf_Struct(serializedBytes: rtData)

    let rtItems = rtDecoded.fields["items"]?.listValue.values ?? []
    XCTAssertEqual(rtItems.count, 2)
    XCTAssertEqual(rtItems[0].structValue.fields["name"]?.stringValue, "Alice")
    XCTAssertEqual(rtItems[1].structValue.fields["name"]?.stringValue, "Bob")
  }
}
