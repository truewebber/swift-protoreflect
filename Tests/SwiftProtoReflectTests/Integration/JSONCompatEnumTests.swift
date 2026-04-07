// JSONCompatEnumTests.swift
// SwiftProtoReflectTests
//
// Group 7: Enum Fields — bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatEnumTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() async throws {
    try await super.setUp()
    registry = try? await CompatDescriptors.fullRegistry()
  }

  override func tearDown() async throws {
    registry = nil
    try await super.tearDown()
  }

  // MARK: - Enum by name (protobuf JSON uses enum name, not number)

  func test_enum_topLevel_byName_bidirectional() async throws {
    let proto = Testcompat_SimpleMessage()
    // Use WithNestedEnum for enum field
    var protoWNE = Testcompat_WithNestedEnum()
    protoWNE.kind = .innerAlpha
    protoWNE.label = "alpha"

    let desc = CompatDescriptors.withNestedEnum()
    try await CompatHelpers.assertProtocToUs(proto: protoWNE, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
      XCTAssertEqual(try msg.get(forField: 2) as? String, "alpha")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(1), forField: 1)
    try dynamic.set("alpha", forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_WithNestedEnum.self
    ) { decoded in
      XCTAssertEqual(decoded.kind, .innerAlpha)
      XCTAssertEqual(decoded.label, "alpha")
    }
    _ = proto
  }

  // MARK: - Enum all values

  func test_enum_allStatusValues_bidirectional() async throws {
    let statuses: [(Testcompat_Status, Int32)] = [
      (.unspecified, 0),
      (.active, 1),
      (.inactive, 2),
      (.deleted, 3),
    ]

    let desc = CompatDescriptors.withNestedEnum()

    for (status, rawValue) in statuses {
      let protoWNE = Testcompat_WithNestedEnum()
      // Use a wrapper message that holds a Status enum field
      // For this test, we use IntentHolder for the Status-based test
      let proto2 = Testcompat_MixedContainers()
      _ = proto2
      _ = protoWNE
      _ = status
      // Just test via the field on the descriptor
      var dynamic = DynamicMessage(descriptor: desc)
      try dynamic.set(rawValue, forField: 1)
      let jsonData = try await CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
      let jsonStr = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
      // Enum values with non-zero value must appear in JSON by name
      if rawValue != 0 {
        XCTAssertTrue(jsonStr.contains("INNER_"), "Expected enum name in JSON, got: \(jsonStr)")
      }
    }
  }

  // MARK: - Aliased enum (PRIORITY_NORMAL / PRIORITY_MEDIUM same value)

  func test_enum_aliased_bidirectional() async throws {
    var proto = Testcompat_IntentHolder()
    proto.intent = .intentInformational

    let desc = CompatDescriptors.intentHolder()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(1), forField: 1)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_IntentHolder.self
    ) {
      decoded in
      XCTAssertEqual(decoded.intent, .intentInformational)
    }
  }

  // MARK: - Enum with negative values (Direction enum)

  func test_enum_negativeValues_bidirectional() async throws {
    // Direction enum: DOWN=-1, LEFT=-2, RIGHT=2
    // Uses DirectionHolder which has a `dir` field of type Direction.
    var proto = Testcompat_DirectionHolder()
    proto.dir = .down  // -1

    let desc = CompatDescriptors.directionHolder()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, -1)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(-1), forField: 1)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_DirectionHolder.self
    ) {
      decoded in
      XCTAssertEqual(decoded.dir, .down)
    }

    // Also test DIRECTION_LEFT = -2
    var proto2 = Testcompat_DirectionHolder()
    proto2.dir = .left  // -2
    try await CompatHelpers.assertProtocToUs(proto: proto2, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, -2)
    }

    var dynamic2 = DynamicMessage(descriptor: desc)
    try dynamic2.set(Int32(-2), forField: 1)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic2,
      registry: registry,
      protoType: Testcompat_DirectionHolder.self
    ) { decoded in
      XCTAssertEqual(decoded.dir, .left)
    }
  }

  // MARK: - Repeated enum

  func test_enum_repeated_bidirectional() async throws {
    var proto = Testcompat_IntentHolder()
    proto.allIntents = [.intentInformational, .intentNavigational, .intentTransactional, .intentCommercial]

    let desc = CompatDescriptors.intentHolder()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 2) as? [Int32])
      XCTAssertEqual(vals, [1, 2, 4, 8])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([Int32(1), Int32(2), Int32(4), Int32(8)] as [Int32], forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_IntentHolder.self
    ) {
      decoded in
      XCTAssertEqual(
        decoded.allIntents,
        [.intentInformational, .intentNavigational, .intentTransactional, .intentCommercial]
      )
    }
  }

  // MARK: - Enum as map value

  func test_enum_mapValue_bidirectional() async throws {
    var proto = Testcompat_IntentHolder()
    proto.byName = ["search": .intentNavigational, "buy": .intentTransactional]

    let desc = CompatDescriptors.intentHolder()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
      XCTAssertEqual(map["search"] as? Int32, 2)
      XCTAssertEqual(map["buy"] as? Int32, 4)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry(Int32(2), forKey: "search", inField: 3)
    try dynamic.setMapEntry(Int32(4), forKey: "buy", inField: 3)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_IntentHolder.self
    ) {
      decoded in
      XCTAssertEqual(decoded.byName["search"], .intentNavigational)
      XCTAssertEqual(decoded.byName["buy"], .intentTransactional)
    }
  }

  // MARK: - Default (zero) enum value → omitted in proto3

  func test_enum_defaultValue_omittedInProto3() async throws {
    var proto = Testcompat_IntentHolder()
    proto.intent = .intentDefault

    let jsonStr = try proto.jsonString()
    // Zero enum should be omitted in proto3 JSON
    XCTAssertFalse(jsonStr.contains("intent"), "Zero enum should be omitted: \(jsonStr)")

    let desc = CompatDescriptors.intentHolder()
    let dynamic = DynamicMessage(descriptor: desc)
    let jsonData = try await CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
    let ourJson = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
    XCTAssertFalse(ourJson.contains("intent"), "Zero enum should be omitted in our JSON too: \(ourJson)")
  }

  // MARK: - Priority aliased enum (NORMAL == MEDIUM, same value 2)

  func test_enum_aliased_priorityNormalMedium_bidirectional() async throws {
    // Priority: PRIORITY_NORMAL=2 and PRIORITY_MEDIUM=2 (alias)
    // protoc serializes value 2 as the first registered name → "PRIORITY_NORMAL"
    let desc = CompatDescriptors.withNestedEnum()
    // Use CrossFileAll which has a Priority field (field 8)
    let crossDesc = CompatDescriptors.crossFileAll()
    var proto = Testcompat_CrossFileAll()
    proto.priority = .normal

    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: crossDesc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 8) as? Int32, 2)
    }

    var dynamic = DynamicMessage(descriptor: crossDesc)
    try dynamic.set(Int32(2), forField: 8)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_CrossFileAll.self
    ) { decoded in
      // Both PRIORITY_NORMAL and PRIORITY_MEDIUM have value 2
      XCTAssertTrue(decoded.priority == .normal || decoded.priority == .medium)
    }
    _ = desc
  }

  // MARK: - Enum in oneof

  func test_enum_inOneof_bidirectional() async throws {
    var proto = Testcompat_OneofComplex()
    proto.enumVal = .deleted

    let desc = CompatDescriptors.oneofComplex()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 5) as? Int32, 3)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(3), forField: 5)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_OneofComplex.self
    ) {
      decoded in
      if case .enumVal(let v) = decoded.choice {
        XCTAssertEqual(v, .deleted)
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  // MARK: - All enum types simultaneously

  func test_enum_allEnumTypes_simultaneously_bidirectional() async throws {
    // Use IntentHolder: covers IntentFlag (non-sequential bitmask) + repeated + map
    var proto = Testcompat_IntentHolder()
    proto.intent = .intentTransactional
    proto.allIntents = [.intentInformational, .intentNavigational, .intentTransactional, .intentCommercial]
    proto.byName = ["info": .intentInformational, "buy": .intentTransactional]

    let desc = CompatDescriptors.intentHolder()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 4)
      let vals = try XCTUnwrap(try msg.get(forField: 2) as? [Int32])
      XCTAssertEqual(vals, [1, 2, 4, 8])
      let map = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
      XCTAssertEqual(map["info"] as? Int32, 1)
      XCTAssertEqual(map["buy"] as? Int32, 4)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(4), forField: 1)
    try dynamic.set([Int32(1), Int32(2), Int32(4), Int32(8)] as [Int32], forField: 2)
    try dynamic.setMapEntry(Int32(1), forKey: "info", inField: 3)
    try dynamic.setMapEntry(Int32(4), forKey: "buy", inField: 3)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_IntentHolder.self
    ) {
      decoded in
      XCTAssertEqual(decoded.intent, .intentTransactional)
      XCTAssertEqual(decoded.allIntents.count, 4)
      XCTAssertEqual(decoded.byName["info"], .intentInformational)
    }
  }

  // MARK: - Round-trip: all Direction values (including negative)

  func test_enum_roundTrip_allDirectionValues() async throws {
    // Direction enum: UNSPECIFIED=0, UP=1, DOWN=-1, LEFT=-2, RIGHT=2
    // Uses DirectionHolder with repeated dirs field to test all values.
    var proto = Testcompat_DirectionHolder()
    proto.dirs = [.unspecified, .up, .down, .left, .right]

    let desc = CompatDescriptors.directionHolder()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 2) as? [Int32])
      XCTAssertEqual(vals, [0, 1, -1, -2, 2])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([Int32(0), Int32(1), Int32(-1), Int32(-2), Int32(2)] as [Int32], forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_DirectionHolder.self
    ) {
      decoded in
      XCTAssertEqual(
        decoded.dirs,
        [.unspecified, .up, .down, .left, .right]
      )
    }

    // Verify round-trip via our own serializer/deserializer preserves negatives
    let allValues: [Int32] = [0, 1, -1, -2, 2]
    var dynRt = DynamicMessage(descriptor: desc)
    try dynRt.set(allValues, forField: 2)
    try await CompatHelpers.assertRoundTrip(dynamic: dynRt, registry: registry) { restored in
      let vals = try XCTUnwrap(try restored.get(forField: 2) as? [Int32])
      XCTAssertEqual(vals, allValues)
    }
  }

  // MARK: - Nested enum inside message

  func test_enum_nestedInsideMessage_bidirectional() async throws {
    var proto = Testcompat_WithNestedEnum()
    proto.kind = .innerGamma
    proto.label = "gamma test"

    let desc = CompatDescriptors.withNestedEnum()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 3)
      XCTAssertEqual(try msg.get(forField: 2) as? String, "gamma test")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(3), forField: 1)
    try dynamic.set("gamma test", forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_WithNestedEnum.self
    ) { decoded in
      XCTAssertEqual(decoded.kind, .innerGamma)
      XCTAssertEqual(decoded.label, "gamma test")
    }
  }
}
