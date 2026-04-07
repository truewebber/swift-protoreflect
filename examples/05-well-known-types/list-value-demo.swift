/**
 * 📝 SwiftProtoReflect Example: ListValue Demo
 *
 * Description: Working with google.protobuf.ListValue for dynamic arrays
 * Key concepts: ListValueHandler, StructHandler.ValueValue, JSON arrays
 * Complexity: 🔧 Intermediate
 * Execution time: < 5 seconds
 *
 * What you'll learn:
 * - Creating ListValue from Swift arrays
 * - Converting between DynamicMessage and [ValueValue]
 * - Handling mixed-type arrays (strings, numbers, bools, nulls)
 * - Round-trip conversion and validation
 *
 * Run with:
 *   swift run ListValueDemo
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct ListValueDemo {
  static func main() async throws {
    ExampleUtils.printHeader("Google Protobuf ListValue")

    try await demonstrateBasicList()
    try await demonstrateMixedTypeList()
    try await demonstrateEmptyList()
    try await demonstrateRegistryIntegration()

    ExampleUtils.printSuccess(
      "ListValue demo completed!"
    )

    ExampleUtils.printNext([
      "Next: wrapper-types-demo.swift - nullable primitives",
      "Also: struct-demo.swift - structured data",
      "See: value-demo.swift - dynamic Value type",
    ])
  }

  // MARK: - Basic List

  private static func demonstrateBasicList() async throws {
    ExampleUtils.printStep(1, "Basic ListValue Operations")

    let values: [StructHandler.ValueValue] = [
      .stringValue("Alice"),
      .stringValue("Bob"),
      .stringValue("Charlie"),
    ]

    let dynamic = try ListValueHandler.createDynamic(from: values)
    print("  Created DynamicMessage from list of 3 strings")

    let restored = try ListValueHandler.createSpecialized(from: dynamic)
    guard let restoredList = restored as? [StructHandler.ValueValue] else {
      print("  ERROR: unexpected type")
      return
    }

    print("  Round-trip result:")
    for (i, val) in restoredList.enumerated() {
      print("    [\(i)] = \(val)")
    }

    ExampleUtils.printInfo(
      "ListValue stores an ordered array of Value elements"
    )
  }

  // MARK: - Mixed Type List

  private static func demonstrateMixedTypeList() async throws {
    ExampleUtils.printStep(2, "Mixed-Type List")

    let mixed: [StructHandler.ValueValue] = [
      .stringValue("hello"),
      .numberValue(42),
      .boolValue(true),
      .nullValue,
      .numberValue(3.14),
    ]

    let dynamic = try ListValueHandler.createDynamic(from: mixed)
    let restored = try ListValueHandler.createSpecialized(from: dynamic)
    guard let list = restored as? [StructHandler.ValueValue] else {
      print("  ERROR: unexpected type")
      return
    }

    print("  Mixed list (\(list.count) items):")
    for (i, val) in list.enumerated() {
      print("    [\(i)] = \(val)")
    }

    ExampleUtils.printInfo(
      "ListValue supports mixed types: strings, numbers, bools, and nulls in the same list"
    )
  }

  // MARK: - Empty List

  private static func demonstrateEmptyList() async throws {
    ExampleUtils.printStep(3, "Empty ListValue")

    let empty: [StructHandler.ValueValue] = []

    let dynamic = try ListValueHandler.createDynamic(from: empty)
    let restored = try ListValueHandler.createSpecialized(from: dynamic)
    guard let list = restored as? [StructHandler.ValueValue] else {
      print("  ERROR: unexpected type")
      return
    }

    print("  Empty list count: \(list.count)")
    print("  Validates empty: \(ListValueHandler.validate(empty))")
    print("  Validates non-array: \(ListValueHandler.validate("not an array"))")

    ExampleUtils.printInfo("Empty lists are valid ListValue instances")
  }

  // MARK: - Registry Integration

  private static func demonstrateRegistryIntegration() async throws {
    ExampleUtils.printStep(4, "Registry Integration")

    let registry = WellKnownTypesRegistry.shared
    let typeName = WellKnownTypeNames.listValue

    print("  Type name: \(typeName)")
    print("  Registered: \(await registry.getHandler(for: typeName) != nil)")

    let values: [StructHandler.ValueValue] = [.stringValue("test"), .numberValue(123)]
    let dynamic = try await registry.createDynamic(from: values, typeName: typeName)
    let restored = try await registry.createSpecialized(from: dynamic, typeName: typeName)

    print("  Registry round-trip: \(restored)")

    ExampleUtils.printInfo(
      "ListValue is auto-registered in WellKnownTypesRegistry alongside all other well-known types"
    )
  }
}
