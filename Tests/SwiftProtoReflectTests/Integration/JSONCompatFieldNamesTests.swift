// JSONCompatFieldNamesTests.swift
// SwiftProtoReflectTests
//
// Group 9: Field Name Mapping — camelCase, custom json_name, acronyms.
// Bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatFieldNamesTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() {
    super.setUp()
    registry = try? CompatDescriptors.fullRegistry()
  }

  override func tearDown() {
    registry = nil
    super.tearDown()
  }

  // MARK: - snake_case → camelCase mapping

  func test_fieldNames_snakeToCamel_bidirectional() throws {
    // my_field_name → myFieldName
    // a_long_field_name_here → aLongFieldNameHere
    // http_request → httpRequest
    // my_rpc → myRpc
    var proto = Testcompat_FieldNameEdgeCases()
    proto.myFieldName = "test1"
    proto.aLongFieldNameHere = 42
    proto.httpRequest = true
    proto.myRpc = "service"

    let desc = CompatDescriptors.fieldNameEdgeCases()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "test1")
      XCTAssertEqual(try msg.get(forField: 2) as? Int32, 42)
      XCTAssertEqual(try msg.get(forField: 3) as? Bool, true)
      XCTAssertEqual(try msg.get(forField: 4) as? String, "service")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("test1", forField: 1)
    try dynamic.set(Int32(42), forField: 2)
    try dynamic.set(true, forField: 3)
    try dynamic.set("service", forField: 4)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_FieldNameEdgeCases.self
    ) { decoded in
      XCTAssertEqual(decoded.myFieldName, "test1")
      XCTAssertEqual(decoded.aLongFieldNameHere, 42)
      XCTAssertTrue(decoded.httpRequest)
      XCTAssertEqual(decoded.myRpc, "service")
    }
  }

  // MARK: - custom json_name option overrides camelCase

  func test_fieldNames_customJsonName_bidirectional() throws {
    // custom_json has json_name = "customOverride"
    var proto = Testcompat_FieldNameEdgeCases()
    proto.customJson = "override_value"

    let desc = CompatDescriptors.fieldNameEdgeCases()

    // The JSON should use "customOverride" as the key
    let jsonStr = try proto.jsonString()
    XCTAssertTrue(
      jsonStr.contains("customOverride"),
      "JSON must use custom json_name override 'customOverride', got: \(jsonStr)"
    )
    XCTAssertFalse(
      jsonStr.contains("customJson"),
      "JSON must NOT use camelCase name when json_name is set, got: \(jsonStr)"
    )

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 7) as? String, "override_value")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("override_value", forField: 7)
    let jsonData = try CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
    let ourJson = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
    XCTAssertTrue(
      ourJson.contains("customOverride"),
      "Our serializer must use json_name override, got: \(ourJson)"
    )

    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_FieldNameEdgeCases.self
    ) { decoded in
      XCTAssertEqual(decoded.customJson, "override_value")
    }
  }

  // MARK: - ALLCAPS field name (no camelCase transformation)

  func test_fieldNames_allCaps_noChange_bidirectional() throws {
    var proto = Testcompat_FieldNameEdgeCases()
    proto.allcaps = "caps_value"

    let desc = CompatDescriptors.fieldNameEdgeCases()
    let jsonStr = try proto.jsonString()
    // ALLCAPS → JSON key should be "ALLCAPS" (no transformation)
    XCTAssertTrue(jsonStr.contains("ALLCAPS"), "ALLCAPS field should remain unchanged in JSON: \(jsonStr)")

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 8) as? String, "caps_value")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("caps_value", forField: 8)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_FieldNameEdgeCases.self
    ) { decoded in
      XCTAssertEqual(decoded.allcaps, "caps_value")
    }
  }

  // MARK: - CamelCase field name (preserved as-is)

  func test_fieldNames_camelCase_preserved_bidirectional() throws {
    var proto = Testcompat_FieldNameEdgeCases()
    proto.camelCase = "camel_value"

    let desc = CompatDescriptors.fieldNameEdgeCases()
    let jsonStr = try proto.jsonString()
    // CamelCase → JSON key should be "CamelCase" (no transformation for already-camel)
    XCTAssertTrue(jsonStr.contains("CamelCase"), "CamelCase field should be 'CamelCase' in JSON: \(jsonStr)")

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 9) as? String, "camel_value")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("camel_value", forField: 9)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_FieldNameEdgeCases.self
    ) { decoded in
      XCTAssertEqual(decoded.camelCase, "camel_value")
    }
  }

  // MARK: - Numeric suffix in field name (field_10 → field10)

  func test_fieldNames_numericSuffix_bidirectional() throws {
    var proto = Testcompat_FieldNameEdgeCases()
    proto.field10 = 999

    let desc = CompatDescriptors.fieldNameEdgeCases()
    let jsonStr = try proto.jsonString()
    XCTAssertTrue(jsonStr.contains("field10"), "field_10 should map to 'field10' in JSON: \(jsonStr)")

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 10) as? Int32, 999)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(999), forField: 10)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_FieldNameEdgeCases.self
    ) { decoded in
      XCTAssertEqual(decoded.field10, 999)
    }
  }

  // MARK: - All edge cases together

  func test_fieldNames_allEdgeCases_bidirectional() throws {
    var proto = Testcompat_FieldNameEdgeCases()
    proto.myFieldName = "field"
    proto.aLongFieldNameHere = 7
    proto.httpRequest = true
    proto.myRpc = "rpc"
    proto._DoubleLeading = "dbl"
    proto.trailing_ = "trail"
    proto.customJson = "custom"
    proto.allcaps = "ALLCAPS"
    proto.camelCase = "Camel"
    proto.field10 = 10

    let desc = CompatDescriptors.fieldNameEdgeCases()
    let msg = try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "field")
      XCTAssertEqual(try msg.get(forField: 2) as? Int32, 7)
      XCTAssertEqual(try msg.get(forField: 3) as? Bool, true)
      XCTAssertEqual(try msg.get(forField: 4) as? String, "rpc")
      XCTAssertEqual(try msg.get(forField: 5) as? String, "dbl")
      XCTAssertEqual(try msg.get(forField: 6) as? String, "trail")
      XCTAssertEqual(try msg.get(forField: 7) as? String, "custom")
      XCTAssertEqual(try msg.get(forField: 8) as? String, "ALLCAPS")
      XCTAssertEqual(try msg.get(forField: 9) as? String, "Camel")
      XCTAssertEqual(try msg.get(forField: 10) as? Int32, 10)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("field", forField: 1)
    try dynamic.set(Int32(7), forField: 2)
    try dynamic.set(true, forField: 3)
    try dynamic.set("rpc", forField: 4)
    try dynamic.set("dbl", forField: 5)
    try dynamic.set("trail", forField: 6)
    try dynamic.set("custom", forField: 7)
    try dynamic.set("ALLCAPS", forField: 8)
    try dynamic.set("Camel", forField: 9)
    try dynamic.set(Int32(10), forField: 10)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_FieldNameEdgeCases.self
    ) { decoded in
      XCTAssertEqual(decoded.myFieldName, "field")
      XCTAssertEqual(decoded.aLongFieldNameHere, 7)
      XCTAssertTrue(decoded.httpRequest)
      XCTAssertEqual(decoded.myRpc, "rpc")
      XCTAssertEqual(decoded._DoubleLeading, "dbl")
      XCTAssertEqual(decoded.trailing_, "trail")
      XCTAssertEqual(decoded.customJson, "custom")
      XCTAssertEqual(decoded.allcaps, "ALLCAPS")
      XCTAssertEqual(decoded.camelCase, "Camel")
      XCTAssertEqual(decoded.field10, 10)
    }
    _ = msg
  }

  // MARK: - Double leading underscores: __double_leading → DoubleLeading

  func test_fieldNames_doubleLeadingUnderscore_bidirectional() throws {
    var proto = Testcompat_FieldNameEdgeCases()
    proto._DoubleLeading = "double_val"

    let desc = CompatDescriptors.fieldNameEdgeCases()
    let jsonStr = try proto.jsonString()
    // protobuf spec: leading underscores stripped, first real char uppercased
    XCTAssertTrue(jsonStr.contains("DoubleLeading"), "Expected 'DoubleLeading' in JSON: \(jsonStr)")

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 5) as? String, "double_val")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("double_val", forField: 5)
    let ourJson = try XCTUnwrap(
      String(
        data: try CompatHelpers.makeSerializer(registry: registry).serialize(dynamic),
        encoding: .utf8
      )
    )
    XCTAssertTrue(ourJson.contains("DoubleLeading"), "Our JSON must use DoubleLeading: \(ourJson)")

    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_FieldNameEdgeCases.self
    ) { decoded in
      XCTAssertEqual(decoded._DoubleLeading, "double_val")
    }
  }

  // MARK: - Trailing underscore: trailing_ → trailing

  func test_fieldNames_trailingUnderscore_bidirectional() throws {
    var proto = Testcompat_FieldNameEdgeCases()
    proto.trailing_ = "trail_val"

    let desc = CompatDescriptors.fieldNameEdgeCases()
    let jsonStr = try proto.jsonString()
    XCTAssertTrue(jsonStr.contains("\"trailing\""), "Expected 'trailing' key in JSON: \(jsonStr)")
    XCTAssertFalse(jsonStr.contains("trailing_"), "Should not contain trailing underscore in key: \(jsonStr)")

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 6) as? String, "trail_val")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("trail_val", forField: 6)
    let ourJson = try XCTUnwrap(
      String(
        data: try CompatHelpers.makeSerializer(registry: registry).serialize(dynamic),
        encoding: .utf8
      )
    )
    XCTAssertTrue(ourJson.contains("\"trailing\""), "Our JSON must use 'trailing': \(ourJson)")

    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_FieldNameEdgeCases.self
    ) { decoded in
      XCTAssertEqual(decoded.trailing_, "trail_val")
    }
  }

  // MARK: - Direction A: original snake_case name accepted on input

  func test_fieldNames_originalNameAccepted_directionA() throws {
    // JSON from protoc uses camelCase keys. But the deserializer should also accept
    // the original snake_case field name as an alternative input.
    let snakeCaseJson = """
      {"my_field_name":"snake","a_long_field_name_here":7,"http_request":true,"my_rpc":"rpc_v"}
      """
    guard let data = snakeCaseJson.data(using: .utf8) else { throw CompatError.jsonEncodingFailed }
    let desc = CompatDescriptors.fieldNameEdgeCases()
    let msg = try CompatHelpers.makeDeserializer(registry: registry).deserialize(data, using: desc)
    XCTAssertEqual(try msg.get(forField: 1) as? String, "snake")
    XCTAssertEqual(try msg.get(forField: 2) as? Int32, 7)
    XCTAssertEqual(try msg.get(forField: 3) as? Bool, true)
    XCTAssertEqual(try msg.get(forField: 4) as? String, "rpc_v")
  }

  // MARK: - Simple message: id and name camelCase is a no-op (already camel)

  func test_fieldNames_simpleMessage_idAndName_bidirectional() throws {
    var proto = Testcompat_SimpleMessage()
    proto.id = 123
    proto.name = "simple"

    let desc = CompatDescriptors.simpleMessage()
    let jsonStr = try proto.jsonString()
    XCTAssertTrue(jsonStr.contains("\"id\""), "id should appear as 'id' in JSON: \(jsonStr)")
    XCTAssertTrue(jsonStr.contains("\"name\""), "name should appear as 'name' in JSON: \(jsonStr)")

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 123)
      XCTAssertEqual(try msg.get(forField: 2) as? String, "simple")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(123), forField: 1)
    try dynamic.set("simple", forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_SimpleMessage.self) {
      decoded in
      XCTAssertEqual(decoded.id, 123)
      XCTAssertEqual(decoded.name, "simple")
    }
  }
}
