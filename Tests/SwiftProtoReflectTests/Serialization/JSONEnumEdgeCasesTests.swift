//
// JSONEnumEdgeCasesTests.swift
// SwiftProtoReflectTests
//

import XCTest

@testable import SwiftProtoReflect

/// Tests enum JSON deserialization against protoc-equivalent behaviour.
///
/// protoc rules (verified with python-protobuf 5.x):
///   - known name string → accepted, returns number
///   - unknown name string → rejected (error)
///   - empty string → rejected (error)
///   - integer number → accepted (including unknown values and negatives)
///   - integer as string → accepted
///   - unknown integer as string → accepted
///   - negative integer as string → accepted
final class JSONEnumEdgeCasesTests: XCTestCase {

  // MARK: - Helpers

  private func makeEnum() -> EnumDescriptor {
    var e = EnumDescriptor(name: "Status", fullName: "test.Status")
    e.addValue(.init(name: "UNKNOWN", number: 0))
    e.addValue(.init(name: "ACTIVE", number: 1))
    e.addValue(.init(name: "INACTIVE", number: 2))
    return e
  }

  /// Message with enum field resolved via TypeRegistry only (no addNestedEnum).
  private func makeMsgAndRegistry() async throws -> (MessageDescriptor, TypeRegistry) {
    var d = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    d.addField(FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "test.Status", jsonName: "status"))
    let registry = TypeRegistry()
    try await registry.registerEnum(makeEnum())
    return (d, registry)
  }

  /// Message with enum field resolved via addNestedEnum (legacy path, no TypeRegistry).
  private func makeMsgNested() -> MessageDescriptor {
    var d = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    d.addField(FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "test.Status", jsonName: "status"))
    d.addNestedEnum(makeEnum())
    return d
  }

  private func parse(_ json: String, using desc: MessageDescriptor, registry: TypeRegistry) async throws -> Int32? {
    let data = json.data(using: .utf8)!
    let deser = JSONDeserializer(options: .init(typeRegistry: registry))
    let msg = try await deser.deserialize(data, using: desc)
    return try msg.get(forField: 1) as? Int32
  }

  // MARK: - TypeRegistry-based enum resolution

  func test_deserialize_enumByName_viaTypeRegistry() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    let value = try await parse(#"{"status":"ACTIVE"}"#, using: desc, registry: registry)
    XCTAssertEqual(value, 1)
  }

  func test_deserialize_enumZeroName_viaTypeRegistry() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    let value = try await parse(#"{"status":"UNKNOWN"}"#, using: desc, registry: registry)
    XCTAssertEqual(value, 0)
  }

  func test_deserialize_enumByNumber_viaTypeRegistry() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    let value = try await parse(#"{"status":1}"#, using: desc, registry: registry)
    XCTAssertEqual(value, 1)
  }

  func test_deserialize_enumByStringNumber_viaTypeRegistry() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    let value = try await parse(#"{"status":"1"}"#, using: desc, registry: registry)
    XCTAssertEqual(value, 1)
  }

  func test_deserialize_enumUnknownNumber_viaTypeRegistry() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    let value = try await parse(#"{"status":999}"#, using: desc, registry: registry)
    XCTAssertEqual(value, 999)
  }

  func test_deserialize_enumUnknownNumberAsString_viaTypeRegistry() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    let value = try await parse(#"{"status":"999"}"#, using: desc, registry: registry)
    XCTAssertEqual(value, 999)
  }

  func test_deserialize_enumNegativeNumber_viaTypeRegistry() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    let value = try await parse(#"{"status":-1}"#, using: desc, registry: registry)
    XCTAssertEqual(value, -1)
  }

  func test_deserialize_enumNegativeAsString_viaTypeRegistry() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    let value = try await parse(#"{"status":"-1"}"#, using: desc, registry: registry)
    XCTAssertEqual(value, -1)
  }

  func test_deserialize_unknownEnumName_viaTypeRegistry_throwsError() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    await assertThrowsAsync(
      try await parse(#"{"status":"NONEXISTENT"}"#, using: desc, registry: registry)
    )
  }

  func test_deserialize_emptyEnumString_viaTypeRegistry_throwsError() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    await assertThrowsAsync(
      try await parse(#"{"status":""}"#, using: desc, registry: registry)
    )
  }

  // MARK: - Negative / edge cases via nested enum (existing path)

  func test_deserialize_enumNegativeNumber_viaNestedEnum() async throws {
    let desc = makeMsgNested()
    let value = try await parse(#"{"status":-1}"#, using: desc, registry: TypeRegistry())
    XCTAssertEqual(value, -1)
  }

  func test_deserialize_enumNegativeAsString_viaNestedEnum() async throws {
    let desc = makeMsgNested()
    let value = try await parse(#"{"status":"-1"}"#, using: desc, registry: TypeRegistry())
    XCTAssertEqual(value, -1)
  }

  func test_deserialize_emptyEnumString_viaNestedEnum_throwsError() async throws {
    let desc = makeMsgNested()
    await assertThrowsAsync(
      try await parse(#"{"status":""}"#, using: desc, registry: TypeRegistry())
    )
  }

  // MARK: - Repeated enum via TypeRegistry

  func test_deserialize_repeatedEnum_mixedFormats_viaTypeRegistry() async throws {
    var d = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    d.addField(
      FieldDescriptor(
        name: "statuses",
        number: 1,
        type: .enum,
        typeName: "test.Status",
        jsonName: "statuses",
        isRepeated: true
      )
    )
    let registry = TypeRegistry()
    try await registry.registerEnum(makeEnum())

    let data = #"{"statuses":["ACTIVE","INACTIVE",0,999]}"#.data(using: .utf8)!
    let deser = JSONDeserializer(options: .init(typeRegistry: registry))
    let msg = try await deser.deserialize(data, using: d)
    let arr = try msg.get(forField: 1) as? [Int32]
    XCTAssertEqual(arr, [1, 2, 0, 999])
  }

  // MARK: - Real-world: message with int64 + single enum + repeated enum

  func test_deserialize_realWorldRequest_enumsAsStrings() async throws {
    // Mimics:
    // message Request {
    //   int64 competitor_id = 1;
    //   IntervalGroupType group_by_interval = 2;
    //   repeated Country countries = 3;
    // }
    var intervalEnum = EnumDescriptor(name: "IntervalGroupType", fullName: "app.IntervalGroupType")
    intervalEnum.addValue(.init(name: "INTERVAL_GROUP_TYPE_UNKNOWN", number: 0))
    intervalEnum.addValue(.init(name: "INTERVAL_GROUP_TYPE_WEEKS", number: 1))
    intervalEnum.addValue(.init(name: "INTERVAL_GROUP_TYPE_MONTHS", number: 2))

    var countryEnum = EnumDescriptor(name: "Country", fullName: "app.Country")
    countryEnum.addValue(.init(name: "COUNTRY_UNKNOWN", number: 0))
    countryEnum.addValue(.init(name: "COUNTRY_UNITED_STATES", number: 1))
    countryEnum.addValue(.init(name: "COUNTRY_UNITED_KINGDOM", number: 2))

    var msgDesc = MessageDescriptor(name: "Request", fullName: "app.Request")
    msgDesc.addField(FieldDescriptor(name: "competitor_id", number: 1, type: .int64, jsonName: "competitorId"))
    msgDesc.addField(
      FieldDescriptor(
        name: "group_by_interval",
        number: 2,
        type: .enum,
        typeName: "app.IntervalGroupType",
        jsonName: "groupByInterval"
      )
    )
    msgDesc.addField(
      FieldDescriptor(
        name: "countries",
        number: 3,
        type: .enum,
        typeName: "app.Country",
        jsonName: "countries",
        isRepeated: true
      )
    )

    let registry = TypeRegistry()
    try await registry.registerEnum(intervalEnum)
    try await registry.registerEnum(countryEnum)

    let json = """
      {
        "competitorId": 1,
        "groupByInterval": "INTERVAL_GROUP_TYPE_WEEKS",
        "countries": [
          "COUNTRY_UNITED_STATES",
          "COUNTRY_UNITED_KINGDOM"
        ]
      }
      """

    let data = json.data(using: .utf8)!
    let deser = JSONDeserializer(options: .init(typeRegistry: registry))
    let msg = try await deser.deserialize(data, using: msgDesc)

    let competitorId = try msg.get(forField: 1) as? Int64
    let interval = try msg.get(forField: 2) as? Int32
    let countries = try msg.get(forField: 3) as? [Int32]

    XCTAssertEqual(competitorId, 1)
    XCTAssertEqual(interval, 1)  // INTERVAL_GROUP_TYPE_WEEKS
    XCTAssertEqual(countries, [1, 2])  // COUNTRY_UNITED_STATES, COUNTRY_UNITED_KINGDOM
  }

  func test_deserialize_realWorldRequest_enumsAsStrings_originalFieldNames() async throws {
    // Same but with snake_case JSON field names (proto field names, not camelCase)
    var intervalEnum = EnumDescriptor(name: "IntervalGroupType", fullName: "app.IntervalGroupType")
    intervalEnum.addValue(.init(name: "INTERVAL_GROUP_TYPE_UNKNOWN", number: 0))
    intervalEnum.addValue(.init(name: "INTERVAL_GROUP_TYPE_WEEKS", number: 1))

    var countryEnum = EnumDescriptor(name: "Country", fullName: "app.Country")
    countryEnum.addValue(.init(name: "COUNTRY_UNKNOWN", number: 0))
    countryEnum.addValue(.init(name: "COUNTRY_UNITED_STATES", number: 1))
    countryEnum.addValue(.init(name: "COUNTRY_UNITED_KINGDOM", number: 2))

    var msgDesc = MessageDescriptor(name: "Request", fullName: "app.Request")
    msgDesc.addField(FieldDescriptor(name: "competitor_id", number: 1, type: .int64, jsonName: "competitorId"))
    msgDesc.addField(
      FieldDescriptor(
        name: "group_by_interval",
        number: 2,
        type: .enum,
        typeName: "app.IntervalGroupType",
        jsonName: "groupByInterval"
      )
    )
    msgDesc.addField(
      FieldDescriptor(
        name: "countries",
        number: 3,
        type: .enum,
        typeName: "app.Country",
        jsonName: "countries",
        isRepeated: true
      )
    )

    let registry = TypeRegistry()
    try await registry.registerEnum(intervalEnum)
    try await registry.registerEnum(countryEnum)

    // Using snake_case field names (proto field name, not jsonName)
    let json = """
      {
        "competitor_id": 1,
        "group_by_interval": "INTERVAL_GROUP_TYPE_WEEKS",
        "countries": [
          "COUNTRY_UNITED_STATES",
          "COUNTRY_UNITED_KINGDOM"
        ]
      }
      """

    let data = json.data(using: .utf8)!
    let deser = JSONDeserializer(options: .init(typeRegistry: registry))
    let msg = try await deser.deserialize(data, using: msgDesc)

    let competitorId = try msg.get(forField: 1) as? Int64
    let interval = try msg.get(forField: 2) as? Int32
    let countries = try msg.get(forField: 3) as? [Int32]

    XCTAssertEqual(competitorId, 1)
    XCTAssertEqual(interval, 1)
    XCTAssertEqual(countries, [1, 2])
  }

  // MARK: - Round-trip via TypeRegistry

  func test_roundTrip_knownEnum_viaTypeRegistry() async throws {
    let (desc, registry) = try await makeMsgAndRegistry()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(1), forField: 1)

    let serializer = JSONSerializer(options: .init(typeRegistry: registry))
    let json = try await serializer.serialize(msg)

    let deser = JSONDeserializer(options: .init(typeRegistry: registry))
    let restored = try await deser.deserialize(json, using: desc)
    XCTAssertEqual(try restored.get(forField: 1) as? Int32, 1)
  }
}

// MARK: - Helper

private func assertThrowsAsync<T>(
  _ expression: @autoclosure () async throws -> T,
  file: StaticString = #file,
  line: UInt = #line
) async {
  do {
    _ = try await expression()
    XCTFail("Expected error to be thrown", file: file, line: line)
  }
  catch {
    // expected
  }
}
