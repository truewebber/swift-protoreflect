//
// JSONDeserializerValueStructTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class JSONDeserializerValueStructTests: XCTestCase {

  private var deserializer: JSONDeserializer {
    JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
  }

  private var valueDesc: MessageDescriptor { StructProtoDescriptors.valueDescriptor }
  private var structDesc: MessageDescriptor { StructProtoDescriptors.structDescriptor }
  private var listValueDesc: MessageDescriptor { StructProtoDescriptors.listValueDescriptor }

  private func json(_ string: String) -> Data {
    string.data(using: .utf8)!
  }

  // MARK: - google.protobuf.Value

  func test_deserialize_valueNull_fromJSONNull() throws {
    let msg = try deserializer.deserialize(json("null"), using: valueDesc)
    XCTAssertTrue((try? msg.hasValue(forField: 1)) == true, "null_value (field 1) should be set")
    let other = [2, 3, 4, 5, 6].compactMap { try? msg.hasValue(forField: $0) }
    XCTAssertTrue(other.allSatisfy { !$0 }, "No other field should be set")
  }

  func test_deserialize_valueNumber_fromJSONNumber() throws {
    let msg = try deserializer.deserialize(json("3.14"), using: valueDesc)
    XCTAssertTrue((try? msg.hasValue(forField: 2)) == true, "number_value (field 2) should be set")
    let d = try msg.get(forField: 2) as? Double
    XCTAssertEqual(d ?? 0.0, 3.14, accuracy: 1e-10)
  }

  func test_deserialize_valueString_fromJSONString() throws {
    let msg = try deserializer.deserialize(json(#""hello""#), using: valueDesc)
    XCTAssertTrue((try? msg.hasValue(forField: 3)) == true, "string_value (field 3) should be set")
    XCTAssertEqual(try msg.get(forField: 3) as? String, "hello")
  }

  func test_deserialize_valueBoolTrue_fromJSONBool() throws {
    let msg = try deserializer.deserialize(json("true"), using: valueDesc)
    // Must be bool_value (field 4), NOT number_value (field 2)
    XCTAssertTrue((try? msg.hasValue(forField: 4)) == true, "bool_value (field 4) should be set")
    XCTAssertFalse((try? msg.hasValue(forField: 2)) == true, "number_value (field 2) must NOT be set")
    XCTAssertEqual(try msg.get(forField: 4) as? Bool, true)
  }

  func test_deserialize_valueBoolFalse_fromJSONBool() throws {
    let msg = try deserializer.deserialize(json("false"), using: valueDesc)
    XCTAssertTrue((try? msg.hasValue(forField: 4)) == true, "bool_value (field 4) should be set")
    XCTAssertFalse((try? msg.hasValue(forField: 2)) == true, "number_value (field 2) must NOT be set")
    XCTAssertEqual(try msg.get(forField: 4) as? Bool, false)
  }

  func test_deserialize_valueStruct_fromJSONObject() throws {
    let msg = try deserializer.deserialize(json(#"{"key":"val"}"#), using: valueDesc)
    XCTAssertTrue((try? msg.hasValue(forField: 5)) == true, "struct_value (field 5) should be set")
    let nested = try XCTUnwrap(try msg.get(forField: 5) as? DynamicMessage)
    XCTAssertEqual(nested.descriptor.fullName, "google.protobuf.Struct")
  }

  func test_deserialize_valueList_fromJSONArray() throws {
    let msg = try deserializer.deserialize(json("[1,2,3]"), using: valueDesc)
    XCTAssertTrue((try? msg.hasValue(forField: 6)) == true, "list_value (field 6) should be set")
    let nested = try XCTUnwrap(try msg.get(forField: 6) as? DynamicMessage)
    XCTAssertEqual(nested.descriptor.fullName, "google.protobuf.ListValue")
  }

  // MARK: - google.protobuf.Struct

  func test_deserialize_struct_fromPlainObject() throws {
    let msg = try deserializer.deserialize(json(#"{"name":"Alice","score":42}"#), using: structDesc)
    XCTAssertEqual(msg.descriptor.fullName, "google.protobuf.Struct")
    let structVal = try StructHandler.createSpecialized(from: msg) as! StructHandler.StructValue
    XCTAssertEqual(structVal.fields["name"], .stringValue("Alice"))
    XCTAssertEqual(structVal.fields["score"], .numberValue(42.0))
  }

  func test_deserialize_emptyStruct_fromEmptyObject() throws {
    let msg = try deserializer.deserialize(json("{}"), using: structDesc)
    let structVal = try StructHandler.createSpecialized(from: msg) as! StructHandler.StructValue
    XCTAssertTrue(structVal.fields.isEmpty)
  }

  // MARK: - google.protobuf.ListValue

  func test_deserialize_listValue_fromPlainArray() throws {
    let msg = try deserializer.deserialize(json(#"["a","b","c"]"#), using: listValueDesc)
    XCTAssertEqual(msg.descriptor.fullName, "google.protobuf.ListValue")
    let listVal = try ListValueHandler.createSpecialized(from: msg) as! [StructHandler.ValueValue]
    XCTAssertEqual(listVal.count, 3)
    XCTAssertEqual(listVal[0], .stringValue("a"))
  }

  func test_deserialize_emptyListValue_fromEmptyArray() throws {
    let msg = try deserializer.deserialize(json("[]"), using: listValueDesc)
    let listVal = try ListValueHandler.createSpecialized(from: msg) as! [StructHandler.ValueValue]
    XCTAssertTrue(listVal.isEmpty)
  }

  // MARK: - Deep nesting roundtrip

  func test_deserialize_deepNesting_roundtrips() throws {
    // Serialize: Struct { "inner": [ Struct { "x": 1.0 } ] }
    let innerStruct = StructHandler.StructValue(fields: ["x": .numberValue(1.0)])
    let listValues: [StructHandler.ValueValue] = [.structValue(innerStruct)]
    let outerStruct = StructHandler.StructValue(fields: ["inner": .listValue(listValues)])
    let original = try StructHandler.createDynamic(from: outerStruct)

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: TypeRegistry()
      )
    )
    let data = try serializer.serialize(original)

    // Deserialize back
    let restored = try deserializer.deserialize(data, using: structDesc)
    let restoredVal = try StructHandler.createSpecialized(from: restored) as! StructHandler.StructValue

    guard case .listValue(let innerList) = restoredVal.fields["inner"] else {
      XCTFail("Expected listValue for 'inner'")
      return
    }
    XCTAssertEqual(innerList.count, 1)
    guard case .structValue(let innerS) = innerList[0] else {
      XCTFail("Expected structValue as first list element")
      return
    }
    XCTAssertEqual(innerS.fields["x"], .numberValue(1.0))
  }
}
