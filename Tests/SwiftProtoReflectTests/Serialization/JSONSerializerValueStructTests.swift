//
// JSONSerializerValueStructTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class JSONSerializerValueStructTests: XCTestCase {

  private var serializer: JSONSerializer {
    JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: TypeRegistry()
      )
    )
  }

  private func decode(_ data: Data) throws -> Any {
    return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
  }

  // MARK: - google.protobuf.Value

  func test_serialize_valueNull_producesJSONNull() async throws {
    let msg = try DynamicMessage.valueMessage(from: NSNull())
    let data = try await serializer.serialize(msg)
    let result = try decode(data)
    XCTAssertTrue(result is NSNull, "Expected NSNull, got \(type(of: result))")
  }

  func test_serialize_valueNumber_producesJSONNumber() async throws {
    let msg = try DynamicMessage.valueMessage(from: 3.14)
    let data = try await serializer.serialize(msg)
    let result = try decode(data)
    let number = try XCTUnwrap(result as? Double)
    XCTAssertEqual(number, 3.14, accuracy: 1e-10)
  }

  func test_serialize_valueString_producesJSONString() async throws {
    let msg = try DynamicMessage.valueMessage(from: "hello")
    let data = try await serializer.serialize(msg)
    let result = try decode(data)
    XCTAssertEqual(result as? String, "hello")
  }

  func test_serialize_valueBool_producesJSONBool() async throws {
    let msg = try DynamicMessage.valueMessage(from: true)
    let data = try await serializer.serialize(msg)
    let result = try decode(data)
    let number = try XCTUnwrap(result as? NSNumber)
    XCTAssertEqual(number.boolValue, true)
  }

  func test_serialize_valueStruct_producesJSONObject() async throws {
    let msg = try DynamicMessage.valueMessage(from: ["key": "value"])
    let data = try await serializer.serialize(msg)
    let result = try decode(data) as? [String: Any]
    XCTAssertNotNil(result)
    XCTAssertEqual(result?["key"] as? String, "value")
  }

  func test_serialize_valueList_producesJSONArray() async throws {
    let msg = try DynamicMessage.valueMessage(from: [1.0, 2.0, 3.0] as [Any])
    let data = try await serializer.serialize(msg)
    let result = try decode(data) as? [Any]
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.count, 3)
  }

  // MARK: - google.protobuf.Struct

  func test_serialize_struct_producesPlainObject() async throws {
    let msg = try DynamicMessage.structMessage(from: ["name": "Alice", "age": 30.0])
    let data = try await serializer.serialize(msg)
    let result = try decode(data) as? [String: Any]
    XCTAssertNotNil(result)
    XCTAssertEqual(result?["name"] as? String, "Alice")
    XCTAssertEqual((result?["age"] as? NSNumber)?.doubleValue ?? 0.0, 30.0, accuracy: 1e-10)
  }

  func test_serialize_emptyStruct_producesEmptyObject() async throws {
    let msg = try DynamicMessage.structMessage(from: [:])
    let data = try await serializer.serialize(msg)
    let result = try decode(data) as? [String: Any]
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.count, 0)
  }

  // MARK: - google.protobuf.ListValue

  func test_serialize_listValue_producesPlainArray() async throws {
    let values: [StructHandler.ValueValue] = [
      .stringValue("a"),
      .stringValue("b"),
      .stringValue("c"),
    ]
    let msg = try ListValueHandler.createDynamic(from: values)
    let data = try await serializer.serialize(msg)
    let result = try decode(data) as? [Any]
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.count, 3)
    XCTAssertEqual(result?[0] as? String, "a")
  }

  func test_serialize_emptyListValue_producesEmptyArray() async throws {
    let values: [StructHandler.ValueValue] = []
    let msg = try ListValueHandler.createDynamic(from: values)
    let data = try await serializer.serialize(msg)
    let result = try decode(data) as? [Any]
    XCTAssertNotNil(result)
    XCTAssertEqual(result?.count, 0)
  }

  // MARK: - Deep nesting

  func test_serialize_structDeepNesting_works() async throws {
    // Struct { "inner": [ Struct { "x": 1.0 } ] }
    let innerStruct = StructHandler.StructValue(fields: ["x": .numberValue(1.0)])
    let listValues: [StructHandler.ValueValue] = [.structValue(innerStruct)]
    let outerStruct = StructHandler.StructValue(fields: [
      "inner": .listValue(listValues)
    ])
    let msg = try StructHandler.createDynamic(from: outerStruct)

    let data = try await serializer.serialize(msg)
    let result = try decode(data) as? [String: Any]
    XCTAssertNotNil(result)
    let innerArr = result?["inner"] as? [Any]
    XCTAssertNotNil(innerArr)
    XCTAssertEqual(innerArr?.count, 1)
    let firstObj = innerArr?[0] as? [String: Any]
    XCTAssertNotNil(firstObj)
    XCTAssertEqual((firstObj?["x"] as? NSNumber)?.doubleValue ?? 0.0, 1.0, accuracy: 1e-10)
  }
}
