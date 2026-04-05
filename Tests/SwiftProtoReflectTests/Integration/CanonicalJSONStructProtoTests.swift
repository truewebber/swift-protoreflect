//
// CanonicalJSONStructProtoTests.swift
// SwiftProtoReflect
//
// Integration tests verifying canonical JSON for struct.proto types works end-to-end
// and is fully interoperable with SwiftProtobuf.
//
// Tests cover:
//   Round-trip: canonical JSON → DynamicMessage → canonical JSON preserves data.
//   Interop: JSON from SwiftProtobuf's jsonString() can be parsed by JSONDeserializer,
//            and vice versa.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class CanonicalJSONStructProtoTests: XCTestCase {

  // MARK: - Shared helpers

  private var valueDesc: MessageDescriptor { StructProtoDescriptors.valueDescriptor }
  private var structDesc: MessageDescriptor { StructProtoDescriptors.structDescriptor }
  private var listValueDesc: MessageDescriptor { StructProtoDescriptors.listValueDescriptor }

  private func makeSerializer() -> JSONSerializer {
    JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: TypeRegistry()
      )
    )
  }

  private func makeDeserializer() -> JSONDeserializer {
    JSONDeserializer(options: JSONDeserializationOptions(typeRegistry: TypeRegistry()))
  }

  // MARK: - Round-trip: Value variants

  func test_roundTrip_valueNull_preservesData() throws {
    let original = ValueHandler.ValueValue.nullValue
    let dynMsg = try ValueHandler.createDynamic(from: original)

    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: valueDesc)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: restored) as? ValueHandler.ValueValue)

    XCTAssertEqual(result, .nullValue)
  }

  func test_roundTrip_valueNumber_preservesData() throws {
    let number: Double = 42.5
    let original = ValueHandler.ValueValue.numberValue(number)
    let dynMsg = try ValueHandler.createDynamic(from: original)

    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: valueDesc)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: restored) as? ValueHandler.ValueValue)

    XCTAssertEqual(result, .numberValue(number))
  }

  func test_roundTrip_valueString_preservesData() throws {
    let str = "Hello, 世界 🌍"
    let original = ValueHandler.ValueValue.stringValue(str)
    let dynMsg = try ValueHandler.createDynamic(from: original)

    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: valueDesc)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: restored) as? ValueHandler.ValueValue)

    XCTAssertEqual(result, .stringValue(str))
  }

  func test_roundTrip_valueBool_preservesData() throws {
    for boolVal in [true, false] {
      let original = ValueHandler.ValueValue.boolValue(boolVal)
      let dynMsg = try ValueHandler.createDynamic(from: original)

      let jsonData = try makeSerializer().serialize(dynMsg)
      let restored = try makeDeserializer().deserialize(jsonData, using: valueDesc)
      let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: restored) as? ValueHandler.ValueValue)

      XCTAssertEqual(result, .boolValue(boolVal), "bool_value=\(boolVal) must survive round-trip")
    }
  }

  // MARK: - Round-trip: Struct

  func test_roundTrip_struct_preservesData() throws {
    let sv = StructHandler.StructValue(fields: [
      "name": .stringValue("Alice"),
      "score": .numberValue(99.5),
      "active": .boolValue(true),
      "nothing": .nullValue,
    ])
    let dynMsg = try StructHandler.createDynamic(from: sv)

    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: structDesc)
    let result = try XCTUnwrap(try StructHandler.createSpecialized(from: restored) as? StructHandler.StructValue)

    XCTAssertEqual(result.fields["name"], .stringValue("Alice"))
    XCTAssertEqual(result.fields["score"], .numberValue(99.5))
    XCTAssertEqual(result.fields["active"], .boolValue(true))
    XCTAssertEqual(result.fields["nothing"], .nullValue)
    XCTAssertEqual(result.fields.count, 4)
  }

  func test_roundTrip_emptyStruct_preservesData() throws {
    let sv = StructHandler.StructValue(fields: [:])
    let dynMsg = try StructHandler.createDynamic(from: sv)

    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: structDesc)
    let result = try XCTUnwrap(try StructHandler.createSpecialized(from: restored) as? StructHandler.StructValue)

    XCTAssertTrue(result.fields.isEmpty)
  }

  // MARK: - Round-trip: ListValue

  func test_roundTrip_listValue_preservesData() throws {
    let values: [StructHandler.ValueValue] = [
      .nullValue,
      .numberValue(1.0),
      .stringValue("two"),
      .boolValue(false),
    ]
    let dynMsg = try ListValueHandler.createDynamic(from: values)

    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: listValueDesc)
    let result = try XCTUnwrap(try ListValueHandler.createSpecialized(from: restored) as? [StructHandler.ValueValue])

    XCTAssertEqual(result.count, 4)
    XCTAssertEqual(result[0], .nullValue)
    XCTAssertEqual(result[1], .numberValue(1.0))
    XCTAssertEqual(result[2], .stringValue("two"))
    XCTAssertEqual(result[3], .boolValue(false))
  }

  func test_roundTrip_emptyListValue_preservesData() throws {
    let values: [StructHandler.ValueValue] = []
    let dynMsg = try ListValueHandler.createDynamic(from: values)

    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: listValueDesc)
    let result = try XCTUnwrap(try ListValueHandler.createSpecialized(from: restored) as? [StructHandler.ValueValue])

    XCTAssertTrue(result.isEmpty)
  }

  // MARK: - Round-trip: deep nesting

  func test_roundTrip_deepNesting_preservesData() throws {
    // Build 5-level nesting: Struct { "l1": Struct { "l2": Struct { "l3": Struct { "l4": Struct { "leaf": 42 } } } } }
    let l4 = StructHandler.StructValue(fields: ["leaf": .numberValue(42)])
    let l3 = StructHandler.StructValue(fields: ["l4": .structValue(l4)])
    let l2 = StructHandler.StructValue(fields: ["l3": .structValue(l3)])
    let l1 = StructHandler.StructValue(fields: ["l2": .structValue(l2)])
    let root = StructHandler.StructValue(fields: ["l1": .structValue(l1)])

    let dynMsg = try StructHandler.createDynamic(from: root)
    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: structDesc)
    let result = try XCTUnwrap(try StructHandler.createSpecialized(from: restored) as? StructHandler.StructValue)

    guard case .structValue(let r1) = result.fields["l1"],
      case .structValue(let r2) = r1.fields["l2"],
      case .structValue(let r3) = r2.fields["l3"],
      case .structValue(let r4) = r3.fields["l4"]
    else {
      XCTFail("Deep nesting not preserved after round-trip")
      return
    }
    XCTAssertEqual(r4.fields["leaf"], .numberValue(42))
  }

  // MARK: - Interop: SwiftProtobuf JSON → our deserializer

  func test_interop_swiftProtobufJSON_toOurDeserializer() throws {
    var swiftpbNull = Google_Protobuf_Value()
    swiftpbNull.nullValue = .nullValue

    let cases: [(Google_Protobuf_Value, ValueHandler.ValueValue)] = [
      (swiftpbNull, .nullValue),
      (Google_Protobuf_Value(numberValue: 3.14), .numberValue(3.14)),
      (Google_Protobuf_Value(stringValue: "протобуф"), .stringValue("протобуф")),
      (Google_Protobuf_Value(boolValue: true), .boolValue(true)),
      (Google_Protobuf_Value(boolValue: false), .boolValue(false)),
    ]

    for (swiftpbValue, expected) in cases {
      let jsonStr = try swiftpbValue.jsonString()
      let jsonData = try XCTUnwrap(jsonStr.data(using: .utf8))

      let restored = try makeDeserializer().deserialize(jsonData, using: valueDesc)
      let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: restored) as? ValueHandler.ValueValue)

      XCTAssertEqual(result, expected, "SwiftProtobuf JSON '\(jsonStr)' must parse to \(expected)")
    }
  }

  // MARK: - Interop: our serializer → SwiftProtobuf

  func test_interop_ourSerializer_toSwiftProtobufJSON() throws {
    let cases: [(ValueHandler.ValueValue, (Google_Protobuf_Value) -> Void)] = [
      (.nullValue, { XCTAssertEqual($0.kind, .nullValue(.nullValue)) }),
      (.numberValue(2.71), { XCTAssertEqual($0.numberValue, 2.71, accuracy: 1e-10) }),
      (.stringValue("swift"), { XCTAssertEqual($0.stringValue, "swift") }),
      (.boolValue(true), { XCTAssertEqual($0.kind, .boolValue(true)) }),
      (.boolValue(false), { XCTAssertEqual($0.kind, .boolValue(false)) }),
    ]

    for (valueValue, assert) in cases {
      let dynMsg = try ValueHandler.createDynamic(from: valueValue)
      let jsonData = try makeSerializer().serialize(dynMsg)
      let jsonStr = try XCTUnwrap(String(data: jsonData, encoding: .utf8))

      let swiftpbValue = try Google_Protobuf_Value(jsonString: jsonStr)
      assert(swiftpbValue)
    }
  }

  // MARK: - Interop: Struct bidirectional

  func test_interop_struct_bidirectional() throws {
    // SwiftProtobuf → JSON → our deserializer
    var swiftpbStruct = Google_Protobuf_Struct()
    swiftpbStruct.fields["city"] = Google_Protobuf_Value(stringValue: "Tokyo")
    swiftpbStruct.fields["pop"] = Google_Protobuf_Value(numberValue: 13_960_000)
    swiftpbStruct.fields["capital"] = Google_Protobuf_Value(boolValue: true)

    let jsonStr = try swiftpbStruct.jsonString()
    let jsonData = try XCTUnwrap(jsonStr.data(using: .utf8))

    let restored = try makeDeserializer().deserialize(jsonData, using: structDesc)
    let sv = try XCTUnwrap(try StructHandler.createSpecialized(from: restored) as? StructHandler.StructValue)

    XCTAssertEqual(sv.fields["city"], .stringValue("Tokyo"))
    XCTAssertEqual(sv.fields["pop"], .numberValue(13_960_000))
    XCTAssertEqual(sv.fields["capital"], .boolValue(true))
    XCTAssertEqual(sv.fields.count, 3)

    // Our serializer → JSON → SwiftProtobuf
    let libSv = StructHandler.StructValue(fields: [
      "lang": .stringValue("Swift"),
      "version": .numberValue(6.0),
    ])
    let dynMsg = try StructHandler.createDynamic(from: libSv)
    let libJsonData = try makeSerializer().serialize(dynMsg)
    let libJsonStr = try XCTUnwrap(String(data: libJsonData, encoding: .utf8))

    let decodedBySwiftpb = try Google_Protobuf_Struct(jsonString: libJsonStr)
    XCTAssertEqual(decodedBySwiftpb.fields["lang"]?.stringValue, "Swift")
    XCTAssertEqual(decodedBySwiftpb.fields["version"]?.numberValue ?? 0, 6.0, accuracy: 1e-10)
    XCTAssertEqual(decodedBySwiftpb.fields.count, 2)
  }

  // MARK: - Interop: ListValue bidirectional

  func test_interop_listValue_bidirectional() throws {
    // SwiftProtobuf → JSON → our deserializer
    var swiftpbNull = Google_Protobuf_Value()
    swiftpbNull.nullValue = .nullValue

    var swiftpbList = Google_Protobuf_ListValue()
    swiftpbList.values = [
      Google_Protobuf_Value(numberValue: 1),
      Google_Protobuf_Value(stringValue: "two"),
      Google_Protobuf_Value(boolValue: false),
      swiftpbNull,
    ]

    let jsonStr = try swiftpbList.jsonString()
    let jsonData = try XCTUnwrap(jsonStr.data(using: .utf8))

    let restored = try makeDeserializer().deserialize(jsonData, using: listValueDesc)
    let lv = try XCTUnwrap(try ListValueHandler.createSpecialized(from: restored) as? [StructHandler.ValueValue])

    XCTAssertEqual(lv.count, 4)
    XCTAssertEqual(lv[0], .numberValue(1))
    XCTAssertEqual(lv[1], .stringValue("two"))
    XCTAssertEqual(lv[2], .boolValue(false))
    XCTAssertEqual(lv[3], .nullValue)

    // Our serializer → JSON → SwiftProtobuf
    let libValues: [StructHandler.ValueValue] = [.stringValue("a"), .numberValue(2), .boolValue(true)]
    let dynMsg = try ListValueHandler.createDynamic(from: libValues)
    let libJsonData = try makeSerializer().serialize(dynMsg)
    let libJsonStr = try XCTUnwrap(String(data: libJsonData, encoding: .utf8))

    let decodedBySwiftpb = try Google_Protobuf_ListValue(jsonString: libJsonStr)
    XCTAssertEqual(decodedBySwiftpb.values.count, 3)
    XCTAssertEqual(decodedBySwiftpb.values[0].stringValue, "a")
    XCTAssertEqual(decodedBySwiftpb.values[1].numberValue, 2)
    XCTAssertEqual(decodedBySwiftpb.values[2].kind, .boolValue(true))
  }

  // MARK: - Interop: nested Struct bidirectional

  func test_interop_nestedStruct_bidirectional() throws {
    // Build: { "items": [{ "id": 1, "name": "Alice" }, { "id": 2, "name": "Bob" }] }
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

    // SwiftProtobuf JSON → our deserializer
    let jsonStr = try root.jsonString()
    let jsonData = try XCTUnwrap(jsonStr.data(using: .utf8))

    let restored = try makeDeserializer().deserialize(jsonData, using: structDesc)
    let sv = try XCTUnwrap(try StructHandler.createSpecialized(from: restored) as? StructHandler.StructValue)

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

    // Our serializer → JSON → SwiftProtobuf
    let libAlice = StructHandler.StructValue(fields: ["id": .numberValue(1), "name": .stringValue("Alice")])
    let libBob = StructHandler.StructValue(fields: ["id": .numberValue(2), "name": .stringValue("Bob")])
    let libItems: [StructHandler.ValueValue] = [.structValue(libAlice), .structValue(libBob)]
    let libRoot = StructHandler.StructValue(fields: ["items": .listValue(libItems)])

    let libDynMsg = try StructHandler.createDynamic(from: libRoot)
    let libJsonData = try makeSerializer().serialize(libDynMsg)
    let libJsonStr = try XCTUnwrap(String(data: libJsonData, encoding: .utf8))

    let decodedBySwiftpb = try Google_Protobuf_Struct(jsonString: libJsonStr)
    let rtItems = decodedBySwiftpb.fields["items"]?.listValue.values ?? []
    XCTAssertEqual(rtItems.count, 2)
    XCTAssertEqual(rtItems[0].structValue.fields["name"]?.stringValue, "Alice")
    XCTAssertEqual(rtItems[1].structValue.fields["name"]?.stringValue, "Bob")
    XCTAssertEqual(rtItems[0].structValue.fields["id"]?.numberValue ?? 0, 1.0, accuracy: 1e-10)
    XCTAssertEqual(rtItems[1].structValue.fields["id"]?.numberValue ?? 0, 2.0, accuracy: 1e-10)
  }

  // MARK: - Edge cases

  func test_roundTrip_unicodeString_preservesData() throws {
    let unicode = "日本語 한국어 العربية \u{1F600}\u{1F4AF}"
    let original = ValueHandler.ValueValue.stringValue(unicode)
    let dynMsg = try ValueHandler.createDynamic(from: original)

    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: valueDesc)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: restored) as? ValueHandler.ValueValue)

    XCTAssertEqual(result, .stringValue(unicode))
  }

  func test_roundTrip_allValueVariantsInListValue_preservesData() throws {
    let innerStruct = StructHandler.StructValue(fields: ["k": .numberValue(1)])
    let values: [StructHandler.ValueValue] = [
      .nullValue,
      .numberValue(3.14),
      .stringValue("text"),
      .boolValue(true),
      .boolValue(false),
      .structValue(innerStruct),
      .listValue([.stringValue("nested")]),
    ]
    let dynMsg = try ListValueHandler.createDynamic(from: values)

    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: listValueDesc)
    let result = try XCTUnwrap(try ListValueHandler.createSpecialized(from: restored) as? [StructHandler.ValueValue])

    XCTAssertEqual(result.count, 7)
    XCTAssertEqual(result[0], .nullValue)
    XCTAssertEqual(result[1], .numberValue(3.14))
    XCTAssertEqual(result[2], .stringValue("text"))
    XCTAssertEqual(result[3], .boolValue(true))
    XCTAssertEqual(result[4], .boolValue(false))
    guard case .structValue(let sv) = result[5] else {
      XCTFail("Expected structValue at index 5")
      return
    }
    XCTAssertEqual(sv.fields["k"], .numberValue(1))
    guard case .listValue(let nested) = result[6] else {
      XCTFail("Expected listValue at index 6")
      return
    }
    XCTAssertEqual(nested, [.stringValue("nested")])
  }

  func test_roundTrip_largeNumber_preservesData() throws {
    let large: Double = 1.7976931348623157e+308
    let original = ValueHandler.ValueValue.numberValue(large)
    let dynMsg = try ValueHandler.createDynamic(from: original)

    let jsonData = try makeSerializer().serialize(dynMsg)
    let restored = try makeDeserializer().deserialize(jsonData, using: valueDesc)
    let result = try XCTUnwrap(try ValueHandler.createSpecialized(from: restored) as? ValueHandler.ValueValue)

    guard case .numberValue(let val) = result else {
      XCTFail("Expected numberValue")
      return
    }
    XCTAssertEqual(val, large, accuracy: large * 1e-10)
  }
}
