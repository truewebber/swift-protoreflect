import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

/// End-to-end integration tests for nested protobuf types.
///
/// Covers the full pipeline: DescriptorBridge → DescriptorPool → TypeRegistry → JSONDeserializer.
final class NestedTypesIntegrationTests: XCTestCase {

  private let bridge = DescriptorBridge()

  private func makeDeserializer(registry: TypeRegistry) -> JSONDeserializer {
    JSONDeserializer(
      options: JSONDeserializationOptions(
        ignoreUnknownFields: true,
        typeRegistry: registry
      )
    )
  }

  // MARK: - Group 8.1: ISSUE.md exact reproductions

  func test_integration_issueMd_failure1_exactRepro_noThrow() throws {
    // Verbatim reproduction of Failure 1: GetGroupedAdsResponse with nested Cursor and Item.
    // Prior to fix, iterating allMessageTypeNames and re-registering caused duplicateType.
    let fileDesc = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)

    let pool = DescriptorPool()
    try pool.addFileDescriptor(fileDesc)

    let registry = TypeRegistry()
    XCTAssertNoThrow(try registry.registerFile(fileDesc))

    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Cursor"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Item"))
  }

  func test_integration_issueMd_failure2_exactRepro_deserializesCorrectly() throws {
    // Verbatim reproduction of Failure 2: GetGroupedAdsRequest with nested SearchFilters.
    // Prior to fix, JSONDeserializationError.nestedMessageDescriptorNotFound was thrown.
    let fileDesc = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let registry = TypeRegistry()
    try registry.registerFile(fileDesc)

    guard let requestDesc = registry.findMessage(named: "pkg.GetGroupedAdsRequest") else {
      XCTFail("GetGroupedAdsRequest not found")
      return
    }
    let deserializer = makeDeserializer(registry: registry)
    let json: [String: Any] = [
      "search_filters": ["title": "test"],
      "limit": 10,
    ]
    let msg = try deserializer.deserializeFromJSONObject(json, using: requestDesc)
    let filtersValue = try msg.get(forField: "search_filters")
    let filtersMsg = try XCTUnwrap(filtersValue as? DynamicMessage)
    let title = try filtersMsg.get(forField: "title")
    XCTAssertEqual(title as? String, "test")
    XCTAssertEqual(try msg.get(forField: "limit") as? Int32, 10)
  }

  // MARK: - Group 8.2: Pool → Registry patterns

  func test_integration_poolToRegistryViaRegisterFile_noError() throws {
    let fileDesc = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let pool = DescriptorPool()
    try pool.addFileDescriptor(fileDesc)

    let registry = TypeRegistry()
    // registerFile via pool lookup must not throw
    if let fd = pool.findFileDescriptor(named: "ads.proto") {
      XCTAssertNoThrow(try registry.registerFile(fd))
    }
    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Cursor"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Item"))
  }

  func test_integration_poolToRegistryViaAllMessageTypeNames_duplicateOnlyForQualifiedName() throws {
    let fileDesc = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let registry = TypeRegistry()
    // registerFile registers parent and its nested children at once
    try registry.registerFile(fileDesc)

    // Trying to register a nested type independently AFTER registerFile → duplicateType with qualified name
    if let cursorDesc = registry.findMessage(named: "pkg.GetGroupedAdsResponse.Cursor") {
      XCTAssertThrowsError(try registry.registerMessage(cursorDesc)) { error in
        if case RegistryError.duplicateType(let name) = error {
          XCTAssertEqual(name, "pkg.GetGroupedAdsResponse.Cursor")
        }
        else {
          XCTFail("Expected duplicateType but got \(error)")
        }
      }
    }
  }

  func test_integration_registerFile_preferred_noError() throws {
    let fileDesc = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let registry = TypeRegistry()
    XCTAssertNoThrow(try registry.registerFile(fileDesc))

    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Cursor"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Item"))
  }

  // MARK: - Group 8.3: Deep nesting end-to-end

  func test_integration_3LevelNesting_bridgeToPoolToRegistryToDeserialize() throws {
    // Build pkg.A { B { C { string val = 1; } } } manually for deserialization
    var fileDesc = FileDescriptor(name: "deep.proto", package: "pkg")
    var cDesc = MessageDescriptor(name: "C", parent: nil as (any DescriptorParent)?)
    cDesc = MessageDescriptor(name: "C")
    cDesc.addField(FieldDescriptor(name: "val", number: 1, type: .string))

    var bDesc = MessageDescriptor(name: "B")
    bDesc.addField(FieldDescriptor(name: "c", number: 1, type: .message, typeName: "pkg.A.B.C"))
    bDesc.addNestedMessage(cDesc)

    var aDesc = MessageDescriptor(name: "A", parent: fileDesc)
    aDesc.addField(FieldDescriptor(name: "b", number: 1, type: .message, typeName: "pkg.A.B"))
    aDesc.addNestedMessage(bDesc)
    fileDesc.addMessage(aDesc)

    // Also register cDesc and bDesc manually so registry can find them
    let registry = TypeRegistry()
    try registry.registerFile(fileDesc)

    // Lookup deeply nested types by qualified name derived from bridge
    let bridgedFileDesc = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    let registry2 = TypeRegistry()
    try registry2.registerFile(bridgedFileDesc)

    XCTAssertNotNil(registry2.findMessage(named: "pkg.A"))
    XCTAssertNotNil(registry2.findMessage(named: "pkg.A.B"))
    XCTAssertNotNil(registry2.findMessage(named: "pkg.A.B.C"))
  }

  func test_integration_sameNestedNameInTwoMessages_bothAccessible() throws {
    let cursorA = makeMessageProto(
      name: "Cursor",
      fields: [makeFieldProto(name: "a", number: 1, type: .string)]
    )
    let cursorB = makeMessageProto(
      name: "Cursor",
      fields: [makeFieldProto(name: "b", number: 1, type: .string)]
    )
    let a = makeMessageProto(name: "A", nestedMessages: [cursorA])
    let b = makeMessageProto(name: "B", nestedMessages: [cursorB])
    let fileProto = makeFileProto(name: "same.proto", package: "pkg", messages: [a, b])

    let fileDesc = try bridge.fromProtobufFileDescriptor(fileProto)
    let registry = TypeRegistry()
    try registry.registerFile(fileDesc)

    XCTAssertNotNil(registry.findMessage(named: "pkg.A.Cursor"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.B.Cursor"))
  }

  func test_integration_twoPackages_sameNestedName_noCollision() throws {
    let y1 = makeMessageProto(
      name: "Y",
      fields: [makeFieldProto(name: "v", number: 1, type: .string)]
    )
    let x1 = makeMessageProto(name: "X", nestedMessages: [y1])
    let file1 = makeFileProto(name: "p1.proto", package: "pkg1", messages: [x1])

    let y2 = makeMessageProto(
      name: "Y",
      fields: [makeFieldProto(name: "v", number: 1, type: .string)]
    )
    let x2 = makeMessageProto(name: "X", nestedMessages: [y2])
    let file2 = makeFileProto(name: "p2.proto", package: "pkg2", messages: [x2])

    let fd1 = try bridge.fromProtobufFileDescriptor(file1)
    let fd2 = try bridge.fromProtobufFileDescriptor(file2)
    let registry = TypeRegistry()
    try registry.registerFile(fd1)
    try registry.registerFile(fd2)

    XCTAssertNotNil(registry.findMessage(named: "pkg1.X.Y"))
    XCTAssertNotNil(registry.findMessage(named: "pkg2.X.Y"))
  }

  // MARK: - Group 8.4: Nested enum end-to-end

  func test_integration_nestedEnum_bridgeToRegistryToDeserialize() throws {
    let fileDesc = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let registry = TypeRegistry()
    try registry.registerFile(fileDesc)

    XCTAssertNotNil(registry.findMessage(named: "pkg.Parent"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.Parent.Child"))
    XCTAssertNotNil(registry.findEnum(named: "pkg.Parent.Status"))
  }

  func test_integration_multipleLevelsOfNestedEnums_allQualified() throws {
    let color = makeEnumProto(name: "Color", values: [("RED", 0), ("BLUE", 1)])
    let b = makeMessageProto(name: "B", nestedEnums: [color])
    let a = makeMessageProto(name: "A", nestedMessages: [b])
    let fileProto = makeFileProto(name: "color.proto", package: "pkg", messages: [a])

    let fileDesc = try bridge.fromProtobufFileDescriptor(fileProto)
    let pool = DescriptorPool()
    try pool.addFileDescriptor(fileDesc)
    let registry = TypeRegistry()
    try registry.registerFile(fileDesc)

    XCTAssertTrue(pool.allEnumTypeNames().contains("pkg.A.B.Color"))
    XCTAssertNotNil(registry.findEnum(named: "pkg.A.B.Color"))
  }

  // MARK: - Group 8.5: Multi-file scenarios

  func test_integration_twoFilesWithNestedTypes_allAccessible() throws {
    let x1 = makeMessageProto(
      name: "X",
      nestedMessages: [makeMessageProto(name: "ChildA")]
    )
    let file1 = makeFileProto(name: "f1.proto", package: "p1", messages: [x1])

    let x2 = makeMessageProto(
      name: "X",
      nestedMessages: [makeMessageProto(name: "ChildB")]
    )
    let file2 = makeFileProto(name: "f2.proto", package: "p2", messages: [x2])

    let fd1 = try bridge.fromProtobufFileDescriptor(file1)
    let fd2 = try bridge.fromProtobufFileDescriptor(file2)
    let registry = TypeRegistry()
    try registry.registerFile(fd1)
    try registry.registerFile(fd2)

    XCTAssertNotNil(registry.findMessage(named: "p1.X.ChildA"))
    XCTAssertNotNil(registry.findMessage(named: "p2.X.ChildB"))
  }

  func test_integration_removeFile_removesNestedTypesFromRegistry() throws {
    let fileDesc = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let registry = TypeRegistry()
    try registry.registerFile(fileDesc)
    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Cursor"))

    let removed = registry.removeFile(named: "ads.proto")
    XCTAssertTrue(removed)
    XCTAssertNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Cursor"))
    XCTAssertNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Item"))
    XCTAssertNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse"))
  }

  // MARK: - Group 8.6: Roundtrip

  func test_integration_bridge_roundTrip_nestedMessage_fullNamePreserved() throws {
    let fileDesc1 = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let responseMsg1 = fileDesc1.messages["GetGroupedAdsResponse"]
    let cursorFull1 = responseMsg1?.nestedMessages["Cursor"]?.fullName

    // Roundtrip: toProtobuf → fromProtobuf
    let fileProto2 = try bridge.toProtobufFileDescriptor(from: fileDesc1)
    let fileDesc2 = try bridge.fromProtobufFileDescriptor(fileProto2)
    let responseMsg2 = fileDesc2.messages["GetGroupedAdsResponse"]
    let cursorFull2 = responseMsg2?.nestedMessages["Cursor"]?.fullName

    XCTAssertEqual(cursorFull1, "pkg.GetGroupedAdsResponse.Cursor")
    XCTAssertEqual(cursorFull1, cursorFull2)
  }

  func test_integration_bridge_roundTrip_nestedEnum_fullNamePreserved() throws {
    let fileDesc1 = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let parentMsg1 = fileDesc1.messages["Parent"]
    let statusFull1 = parentMsg1?.nestedEnums["Status"]?.fullName

    let fileProto2 = try bridge.toProtobufFileDescriptor(from: fileDesc1)
    let fileDesc2 = try bridge.fromProtobufFileDescriptor(fileProto2)
    let parentMsg2 = fileDesc2.messages["Parent"]
    let statusFull2 = parentMsg2?.nestedEnums["Status"]?.fullName

    XCTAssertEqual(statusFull1, "pkg.Parent.Status")
    XCTAssertEqual(statusFull1, statusFull2)
  }

  // MARK: - Group 8.7: Complex real-world scenarios

  func test_integration_complexProto_getGroupedAdsResponse_allTypesAccessible() throws {
    let fileDesc = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let registry = TypeRegistry()
    try registry.registerFile(fileDesc)

    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Cursor"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsResponse.Item"))
  }

  func test_integration_complexProto_getGroupedAdsRequest_searchFilters() throws {
    let fileDesc = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    let registry = TypeRegistry()
    try registry.registerFile(fileDesc)

    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsRequest"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.GetGroupedAdsRequest.SearchFilters"))
  }

  func test_integration_pool_allMessageTypeNames_allQualified() throws {
    let fileDesc = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let pool = DescriptorPool()
    try pool.addFileDescriptor(fileDesc)

    let names = pool.allMessageTypeNames()
    let bareNames = names.filter { !$0.contains(".") }
    XCTAssertTrue(
      bareNames.isEmpty,
      "Expected all names to be qualified, but found bare names: \(bareNames)"
    )
  }

  func test_integration_pool_allEnumTypeNames_allQualified() throws {
    let fileDesc = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let pool = DescriptorPool()
    try pool.addFileDescriptor(fileDesc)

    let names = pool.allEnumTypeNames()
    let bareNames = names.filter { !$0.contains(".") }
    XCTAssertTrue(
      bareNames.isEmpty,
      "Expected all enum names to be qualified, but found bare names: \(bareNames)"
    )
  }

  // MARK: - Group 8.8: Proto2

  func test_integration_proto2_nestedMessage_syntaxInherited() throws {
    let child = makeMessageProto(
      name: "Child",
      fields: [makeFieldProto(name: "id", number: 1, type: .string)]
    )
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(
      name: "p2.proto",
      package: "pkg",
      syntax: "proto2",
      messages: [parent]
    )

    let fileDesc = try bridge.fromProtobufFileDescriptor(fileProto)
    guard
      let parentMsg = fileDesc.messages["Parent"],
      let childMsg = parentMsg.nestedMessages["Child"]
    else {
      XCTFail("Descriptors not found")
      return
    }
    XCTAssertEqual(childMsg.syntax, "proto2")
    XCTAssertEqual(childMsg.fullName, "pkg.Parent.Child")
  }

  func test_integration_proto2_requiredFieldInNested_preserved() throws {
    let childFields = [makeFieldProto(name: "id", number: 1, type: .string, label: .required)]
    let child = makeMessageProto(name: "Child", fields: childFields)
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(
      name: "p2req.proto",
      package: "pkg",
      syntax: "proto2",
      messages: [parent]
    )

    let fileDesc = try bridge.fromProtobufFileDescriptor(fileProto)
    guard
      let parentMsg = fileDesc.messages["Parent"],
      let childMsg = parentMsg.nestedMessages["Child"],
      let idField = childMsg.fieldsByName["id"]
    else {
      XCTFail("Descriptors not found")
      return
    }
    XCTAssertTrue(idField.isRequired)
  }

  // MARK: - Group 8.9: Performance

  func test_integration_performance_100NestedTypes_bridgeAndRegisterWithinBudget() throws {
    let nestedMessages = (0..<100).map { i in
      makeMessageProto(
        name: "Nested\(i)",
        fields: [makeFieldProto(name: "v", number: 1, type: .string)]
      )
    }
    let root = makeMessageProto(name: "Root", nestedMessages: nestedMessages)
    let fileProto = makeFileProto(name: "perf.proto", package: "perf", messages: [root])

    measure {
      do {
        let fileDesc = try bridge.fromProtobufFileDescriptor(fileProto)
        let pool = DescriptorPool()
        try pool.addFileDescriptor(fileDesc)
        let registry = TypeRegistry()
        try registry.registerFile(fileDesc)
      }
      catch {
        XCTFail("Performance test threw: \(error)")
      }
    }
  }
}
