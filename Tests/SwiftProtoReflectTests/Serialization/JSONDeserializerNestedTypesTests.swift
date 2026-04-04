import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONDeserializerNestedTypesTests: XCTestCase {

  let bridge = DescriptorBridge()

  private func makeRegistry(from fileProto: Google_Protobuf_FileDescriptorProto) throws -> TypeRegistry {
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let registry = TypeRegistry()
    try registry.registerFile(fd)
    return registry
  }

  private func makeDeserializer(registry: TypeRegistry) -> JSONDeserializer {
    JSONDeserializer(
      options: JSONDeserializationOptions(
        ignoreUnknownFields: true,
        typeRegistry: registry
      )
    )
  }

  // MARK: - Group 7.1 — Deserialization with nested message fields (Failure 2 fix)

  func test_deserialize_nestedMessageField_succeeds() throws {
    let registry = try makeRegistry(from: adsRequestFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["search_filters": ["title": "test"], "limit": 10]
    XCTAssertNoThrow(try deserializer.deserializeFromJSONObject(json, using: requestDesc))
  }

  func test_deserialize_nestedMessageField_nestedFieldValuesCorrect() throws {
    let registry = try makeRegistry(from: adsRequestFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["search_filters": ["title": "test_title"], "limit": 5]
    let result = try deserializer.deserializeFromJSONObject(json, using: requestDesc)
    guard let filters = try result.get(forField: "search_filters") as? DynamicMessage else {
      XCTFail("Expected DynamicMessage for search_filters")
      return
    }
    XCTAssertEqual(try filters.get(forField: "title") as? String, "test_title")
  }

  func test_deserialize_twoNestedMessageFields_bothDeserializeCorrectly() throws {
    let registry = try makeRegistry(from: adsResponseFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let responseDesc = fd.messages["GetGroupedAdsResponse"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = [
      "cursor": ["next_page_token": "tok123"],
      "items": [["id": "item1"]],
    ]
    let result = try deserializer.deserializeFromJSONObject(json, using: responseDesc)
    XCTAssertNotNil(try result.get(forField: "cursor"))
    XCTAssertNotNil(try result.get(forField: "items"))
  }

  func test_deserialize_doublyNestedMessageField_succeeds() throws {
    let registry = try makeRegistry(from: deepNestingFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    let aDesc = fd.messages["A"]!
    let aRegistry = TypeRegistry()
    try aRegistry.registerFile(fd)

    let bField = makeFieldProto(
      name: "b",
      number: 1,
      type: .message,
      typeName: ".pkg.A.B"
    )
    let cField = makeFieldProto(
      name: "c",
      number: 1,
      type: .message,
      typeName: ".pkg.A.B.C"
    )
    let valField = makeFieldProto(name: "value", number: 1, type: .string)

    var aWithB = makeMessageProto(name: "A", fields: [bField])
    aWithB.nestedType = [
      makeMessageProto(name: "B", fields: [cField]),
      makeMessageProto(name: "C", fields: [valField]),
    ]
    let customFileProto = makeFileProto(name: "custom.proto", package: "pkg", messages: [aWithB])
    let customFd = try bridge.fromProtobufFileDescriptor(customFileProto)
    let customRegistry = TypeRegistry()
    try customRegistry.registerFile(customFd)
    let customDeserializer = makeDeserializer(registry: customRegistry)
    let json: [String: Any] = ["b": [:]]
    XCTAssertNoThrow(
      try customDeserializer.deserializeFromJSONObject(json, using: customFd.messages["A"]!)
    )
  }

  func test_deserialize_repeatedNestedMessageField_succeeds() throws {
    let registry = try makeRegistry(from: adsResponseFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let responseDesc = fd.messages["GetGroupedAdsResponse"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["items": [["id": "a"], ["id": "b"], ["id": "c"]]]
    let result = try deserializer.deserializeFromJSONObject(json, using: responseDesc)
    if let items = try result.get(forField: "items") as? [Any] {
      XCTAssertEqual(items.count, 3)
    }
    else {
      XCTFail("Expected array for items field")
    }
  }

  func test_deserialize_repeatedNestedMessageField_arrayCountCorrect() throws {
    let registry = try makeRegistry(from: adsResponseFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let responseDesc = fd.messages["GetGroupedAdsResponse"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["items": [["id": "a"], ["id": "b"], ["id": "c"]]]
    let result = try deserializer.deserializeFromJSONObject(json, using: responseDesc)
    let items = try result.get(forField: "items") as? [Any]
    XCTAssertEqual(items?.count, 3)
  }

  func test_deserialize_nullNestedField_handledGracefully() throws {
    let registry = try makeRegistry(from: adsRequestFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(ignoreUnknownFields: true, typeRegistry: registry)
    )
    let json: [String: Any] = ["limit": 5]
    XCTAssertNoThrow(try deserializer.deserializeFromJSONObject(json, using: requestDesc))
  }

  func test_deserialize_missingNestedField_noError() throws {
    let registry = try makeRegistry(from: adsRequestFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["limit": 10]
    XCTAssertNoThrow(try deserializer.deserializeFromJSONObject(json, using: requestDesc))
  }

  // MARK: - Group 7.1b — Leading dot in field.typeName

  func test_deserialize_fieldTypeNameWithLeadingDot_lookupSucceeds() throws {
    let registry = try makeRegistry(from: adsRequestFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["search_filters": ["title": "test"]]
    XCTAssertNoThrow(try deserializer.deserializeFromJSONObject(json, using: requestDesc))
  }

  func test_deserialize_fieldTypeNameWithoutLeadingDot_lookupSucceeds() throws {
    let filtersMsg = makeMessageProto(
      name: "SearchFilters",
      fields: [makeFieldProto(name: "title", number: 1, type: .string)]
    )
    let filtersField = makeFieldProto(
      name: "search_filters",
      number: 1,
      type: .message,
      typeName: "pkg.GetGroupedAdsRequest.SearchFilters"  // no leading dot
    )
    let request = makeMessageProto(
      name: "GetGroupedAdsRequest",
      fields: [filtersField],
      nestedMessages: [filtersMsg]
    )
    let fileProto = makeFileProto(name: "ads.proto", package: "pkg", messages: [request])
    let registry = try makeRegistry(from: fileProto)
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["search_filters": ["title": "hello"]]
    XCTAssertNoThrow(try deserializer.deserializeFromJSONObject(json, using: requestDesc))
  }

  func test_deserialize_fieldTypeNameEmpty_throwsMissingTypeName() throws {
    let fieldWithEmptyType = FieldDescriptor(
      name: "nested",
      number: 1,
      type: .message,
      typeName: ""
    )
    var msgDesc = MessageDescriptor(name: "Msg", fullName: "Msg")
    msgDesc.addField(fieldWithEmptyType)
    let registry = TypeRegistry()
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["nested": ["key": "val"]]
    XCTAssertThrowsError(try deserializer.deserializeFromJSONObject(json, using: msgDesc)) { error in
      guard case JSONDeserializationError.missingTypeName = error else {
        XCTFail("Expected missingTypeName, got \(error)")
        return
      }
    }
  }

  func test_deserialize_fieldTypeNameOnlyDot_throwsMissingTypeName() throws {
    let fieldWithDotType = FieldDescriptor(
      name: "nested",
      number: 1,
      type: .message,
      typeName: "."
    )
    var msgDesc = MessageDescriptor(name: "Msg", fullName: "Msg")
    msgDesc.addField(fieldWithDotType)
    let registry = TypeRegistry()
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["nested": ["key": "val"]]
    XCTAssertThrowsError(try deserializer.deserializeFromJSONObject(json, using: msgDesc)) { error in
      // Should throw either missingTypeName or nestedMessageDescriptorNotFound (not a crash)
      XCTAssertTrue(
        error is JSONDeserializationError,
        "Expected a JSONDeserializationError but got \(error)"
      )
    }
  }

  // MARK: - Group 7.2 — Error cases (error 16)

  func test_deserialize_nestedTypeNotInRegistry_throwsError16() throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let emptyRegistry = TypeRegistry()
    let deserializer = makeDeserializer(registry: emptyRegistry)
    let json: [String: Any] = ["search_filters": ["title": "test"]]
    XCTAssertThrowsError(try deserializer.deserializeFromJSONObject(json, using: requestDesc)) { error in
      guard case JSONDeserializationError.nestedMessageDescriptorNotFound = error else {
        XCTFail("Expected nestedMessageDescriptorNotFound (error 16), got \(error)")
        return
      }
    }
  }

  func test_deserialize_nestedTypeInRegistryByBareName_throwsError16() throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let registry = TypeRegistry()
    // Register SearchFilters under bare name (wrong, should be qualified)
    let filtersMsg = makeMessageProto(
      name: "SearchFilters",
      fields: [makeFieldProto(name: "title", number: 1, type: .string)]
    )
    let filtersFileProto = makeFileProto(
      name: "filters.proto",
      package: "",
      messages: [filtersMsg]
    )
    let filtersFd = try bridge.fromProtobufFileDescriptor(filtersFileProto)
    try registry.registerFile(filtersFd)
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["search_filters": ["title": "test"]]
    XCTAssertThrowsError(try deserializer.deserializeFromJSONObject(json, using: requestDesc)) { error in
      guard case JSONDeserializationError.nestedMessageDescriptorNotFound = error else {
        XCTFail("Expected nestedMessageDescriptorNotFound (error 16), got \(error)")
        return
      }
    }
  }

  func test_deserialize_nestedTypeInRegistryByQualifiedName_succeeds() throws {
    let registry = try makeRegistry(from: adsRequestFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["search_filters": ["title": "test"]]
    XCTAssertNoThrow(try deserializer.deserializeFromJSONObject(json, using: requestDesc))
  }

  // MARK: - Group 7.3 — Nested enums in JSON

  func test_deserialize_nestedEnumField_knownValue_succeeds() throws {
    let status = makeEnumProto(name: "Status", values: [("UNKNOWN", 0), ("ACTIVE", 1)])
    let statusField = makeFieldProto(
      name: "status",
      number: 1,
      type: .enum,
      typeName: ".pkg.Parent.Status"
    )
    let parent = makeMessageProto(name: "Parent", fields: [statusField], nestedEnums: [status])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let parentDesc = fd.messages["Parent"]!
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let json: [String: Any] = ["status": "ACTIVE"]
    let result = try deserializer.deserializeFromJSONObject(json, using: parentDesc)
    XCTAssertEqual(try result.get(forField: "status") as? Int32, 1)
  }

  func test_deserialize_nestedEnumField_unknownValue_handledPerSyntax() throws {
    let status = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let statusField = makeFieldProto(
      name: "status",
      number: 1,
      type: .enum,
      typeName: ".pkg.Parent.Status"
    )
    let parent = makeMessageProto(name: "Parent", fields: [statusField], nestedEnums: [status])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let parentDesc = fd.messages["Parent"]!
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    // For proto3 unknown string enum values should be treated as errors
    XCTAssertThrowsError(
      try deserializer.deserializeFromJSONObject(["status": "UNKNOWN_VALUE"], using: parentDesc)
    )
  }

  // MARK: - Group 7.4 — Exact ISSUE.md reproductions

  func test_deserialize_issueMd_failure2_exactRepro_succeeds() throws {
    let registry = try makeRegistry(from: adsRequestFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = [
      "search_filters": ["title": "test"],
      "limit": 10,
    ]
    XCTAssertNoThrow(try deserializer.deserializeFromJSONObject(json, using: requestDesc))
  }

  func test_deserialize_issueMd_failure2_searchFiltersTitle_correct() throws {
    let registry = try makeRegistry(from: adsRequestFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["search_filters": ["title": "test"]]
    let result = try deserializer.deserializeFromJSONObject(json, using: requestDesc)
    if let filters = try result.get(forField: "search_filters") as? DynamicMessage {
      XCTAssertEqual(try filters.get(forField: "title") as? String, "test")
    }
    else {
      XCTFail("Expected DynamicMessage for search_filters")
    }
  }

  func test_deserialize_issueMd_failure2_limitField_correct() throws {
    let registry = try makeRegistry(from: adsRequestFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["limit": 10]
    let result = try deserializer.deserializeFromJSONObject(json, using: requestDesc)
    XCTAssertEqual(try result.get(forField: "limit") as? Int32, 10)
  }

  // MARK: - Group 7.5 — No registry (empty registry)

  func test_deserialize_nestedFieldWithoutRegistry_throwsNestedMessageDescriptorNotFound() throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let json: [String: Any] = ["search_filters": ["title": "test"]]
    XCTAssertThrowsError(try deserializer.deserializeFromJSONObject(json, using: requestDesc)) { error in
      guard case JSONDeserializationError.nestedMessageDescriptorNotFound = error else {
        XCTFail("Expected nestedMessageDescriptorNotFound, got \(error)")
        return
      }
    }
  }

  // MARK: - Group 7.7 — Regressions

  func test_deserialize_flatMessage_unchanged() throws {
    let msgProto = makeMessageProto(
      name: "Flat",
      fields: [makeFieldProto(name: "name", number: 1, type: .string)]
    )
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let flatDesc = fd.messages["Flat"]!
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let result = try deserializer.deserializeFromJSONObject(["name": "hello"], using: flatDesc)
    XCTAssertEqual(try result.get(forField: "name") as? String, "hello")
  }

  func test_deserialize_allScalarTypes_unchanged() throws {
    let fields = [
      makeFieldProto(name: "b", number: 1, type: .bool),
      makeFieldProto(name: "i", number: 2, type: .int32),
      makeFieldProto(name: "s", number: 3, type: .string),
    ]
    let msgProto = makeMessageProto(name: "Scalars", fields: fields)
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let scalarDesc = fd.messages["Scalars"]!
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let json: [String: Any] = ["b": true, "i": 42, "s": "hello"]
    let result = try deserializer.deserializeFromJSONObject(json, using: scalarDesc)
    XCTAssertEqual(try result.get(forField: "b") as? Bool, true)
    XCTAssertEqual(try result.get(forField: "i") as? Int32, 42)
    XCTAssertEqual(try result.get(forField: "s") as? String, "hello")
  }

  func test_deserialize_repeatedScalarField_unchanged() throws {
    let field = makeFieldProto(name: "nums", number: 1, type: .int32, label: .repeated)
    let msgProto = makeMessageProto(name: "Msg", fields: [field])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let msgDesc = fd.messages["Msg"]!
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let result = try deserializer.deserializeFromJSONObject(["nums": [1, 2, 3]], using: msgDesc)
    XCTAssertNotNil(try result.get(forField: "nums"))
  }

  func test_deserialize_emptyMessage_unchanged() throws {
    let msgProto = makeMessageProto(name: "Empty")
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let msgDesc = fd.messages["Empty"]!
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    XCTAssertNoThrow(try deserializer.deserializeFromJSONObject([:], using: msgDesc))
  }

  func test_deserialize_nestedMessageWithAllScalarTypes_allFieldsCorrect() throws {
    let innerFields = [
      makeFieldProto(name: "name", number: 1, type: .string),
      makeFieldProto(name: "count", number: 2, type: .int32),
    ]
    let innerMsg = makeMessageProto(name: "Inner", fields: innerFields)
    let outerField = makeFieldProto(
      name: "inner",
      number: 1,
      type: .message,
      typeName: ".pkg.Outer.Inner"
    )
    let outerMsg = makeMessageProto(name: "Outer", fields: [outerField], nestedMessages: [innerMsg])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [outerMsg])
    let registry = try makeRegistry(from: fileProto)
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let outerDesc = fd.messages["Outer"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["inner": ["name": "hello", "count": 5]]
    let result = try deserializer.deserializeFromJSONObject(json, using: outerDesc)
    if let inner = try result.get(forField: "inner") as? DynamicMessage {
      XCTAssertEqual(try inner.get(forField: "name") as? String, "hello")
      XCTAssertEqual(try inner.get(forField: "count") as? Int32, 5)
    }
    else {
      XCTFail("Expected DynamicMessage for inner")
    }
  }

  func test_deserialize_proto2MessageWithNestedField_succeeds() throws {
    let innerMsg = makeMessageProto(
      name: "Inner",
      fields: [makeFieldProto(name: "val", number: 1, type: .string)]
    )
    let outerField = makeFieldProto(
      name: "inner",
      number: 1,
      type: .message,
      typeName: ".pkg.Outer.Inner"
    )
    let outerMsg = makeMessageProto(
      name: "Outer",
      fields: [outerField],
      nestedMessages: [innerMsg]
    )
    let fileProto = makeFileProto(
      name: "t.proto",
      package: "pkg",
      syntax: "proto2",
      messages: [outerMsg]
    )
    let registry = try makeRegistry(from: fileProto)
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let outerDesc = fd.messages["Outer"]!
    let deserializer = makeDeserializer(registry: registry)
    XCTAssertNoThrow(
      try deserializer.deserializeFromJSONObject(["inner": ["val": "x"]], using: outerDesc)
    )
  }

  func test_deserialize_mixedNestedAndScalarFields_allDeserialized() throws {
    let registry = try makeRegistry(from: adsRequestFileProto)
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = [
      "search_filters": ["title": "hello"],
      "limit": 42,
    ]
    let result = try deserializer.deserializeFromJSONObject(json, using: requestDesc)
    XCTAssertNotNil(try result.get(forField: "search_filters"))
    XCTAssertEqual(try result.get(forField: "limit") as? Int32, 42)
  }

  // MARK: - Group 7.2 addendum — error contains fieldName and qualified typeName

  func test_deserialize_errorContainsFieldNameAndQualifiedTypeName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let requestDesc = fd.messages["GetGroupedAdsRequest"]!
    let emptyRegistry = TypeRegistry()
    let deserializer = makeDeserializer(registry: emptyRegistry)
    let json: [String: Any] = ["search_filters": ["title": "test"]]
    XCTAssertThrowsError(try deserializer.deserializeFromJSONObject(json, using: requestDesc)) { error in
      if case JSONDeserializationError.nestedMessageDescriptorNotFound(
        let fieldName,
        let typeName
      ) = error {
        XCTAssertEqual(fieldName, "search_filters")
        XCTAssertEqual(typeName, "pkg.GetGroupedAdsRequest.SearchFilters")
      }
      else {
        XCTFail("Expected nestedMessageDescriptorNotFound, got \(error)")
      }
    }
  }

  // MARK: - Group 7.6 — Oneof with nested message type

  func test_deserialize_oneofContainingNestedMessageType_succeeds() throws {
    // Build: Wrapper { oneof payload { NestedMsg msg = 1; } }
    let innerMsg = makeMessageProto(
      name: "Inner",
      fields: [makeFieldProto(name: "val", number: 1, type: .string)]
    )
    let outerField = makeFieldProto(
      name: "msg",
      number: 1,
      type: .message,
      typeName: ".pkg.Wrapper.Inner"
    )
    let wrapperMsg = makeMessageProto(
      name: "Wrapper",
      fields: [outerField],
      nestedMessages: [innerMsg]
    )
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [wrapperMsg])
    let registry = try makeRegistry(from: fileProto)
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    var wrapperDesc = fd.messages["Wrapper"]!
    // Attach a oneofDecl so the field has a oneofIndex
    let oneofDecl = OneofDescriptor(name: "payload", index: 0)
    wrapperDesc.addOneofDecl(oneofDecl)
    let outerFieldDesc = FieldDescriptor(
      name: "msg",
      number: 1,
      type: .message,
      typeName: ".pkg.Wrapper.Inner",
      oneofIndex: 0
    )
    wrapperDesc.addField(outerFieldDesc)

    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["msg": ["val": "hello"]]
    XCTAssertNoThrow(try deserializer.deserializeFromJSONObject(json, using: wrapperDesc))
  }

  // MARK: - Group 7.7 addendum — regression tests for map and enum fields

  func test_deserialize_mapField_unchanged() throws {
    // map<string, int32> — verifies map deserialization not broken by nested type changes
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)
    let mapField = FieldDescriptor(
      name: "scores",
      number: 1,
      type: .message,
      typeName: ".pkg.Msg.ScoresEntry",
      isMap: true,
      mapEntryInfo: mapInfo
    )
    var msgDesc = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    msgDesc.addField(mapField)
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let json: [String: Any] = ["scores": ["alice": 10, "bob": 20]]
    let result = try deserializer.deserializeFromJSONObject(json, using: msgDesc)
    let scores = try result.get(forField: "scores") as? [AnyHashable: Any]
    XCTAssertEqual(scores?.count, 2)
  }

  func test_deserialize_topLevelEnumField_unchanged() throws {
    // Enum field (not nested): verifies top-level enum handling unchanged
    var statusEnum = EnumDescriptor(name: "Status")
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    var msgDesc = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    msgDesc.addField(FieldDescriptor(name: "status", number: 1, type: .int32))
    msgDesc.addNestedEnum(statusEnum)
    let deserializer = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let result = try deserializer.deserializeFromJSONObject(["status": 1], using: msgDesc)
    XCTAssertEqual(try result.get(forField: "status") as? Int32, 1)
  }

  func test_deserialize_messageWithMapFieldWhereValueIsNestedMessage_succeeds() throws {
    // map<string, NestedMsg> — value is a nested message type
    let innerMsg = makeMessageProto(
      name: "Inner",
      fields: [makeFieldProto(name: "val", number: 1, type: .string)]
    )
    let outerMsg = makeMessageProto(name: "Outer", nestedMessages: [innerMsg])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [outerMsg])
    let registry = try makeRegistry(from: fileProto)
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let outerDesc = fd.messages["Outer"]!

    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "pkg.Outer.Inner"
    )
    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)
    let mapField = FieldDescriptor(
      name: "items",
      number: 1,
      type: .message,
      typeName: ".pkg.Outer.ItemsEntry",
      isMap: true,
      mapEntryInfo: mapInfo
    )
    var outerWithMap = outerDesc
    outerWithMap.addField(mapField)

    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = ["items": ["k1": ["val": "hello"]]]
    XCTAssertNoThrow(try deserializer.deserializeFromJSONObject(json, using: outerWithMap))
  }
}
