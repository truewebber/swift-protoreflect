/**
 * 🎁 SwiftProtoReflect Example: Wrapper Types Demo
 *
 * Description: Working with all 9 protobuf wrapper types (StringValue, Int32Value, etc.)
 * Key concepts: WrapperHandlers, nullable primitives, createSpecialized/createDynamic
 * Complexity: 🔧 Intermediate
 * Execution time: < 5 seconds
 *
 * What you'll learn:
 * - All 9 wrapper types: DoubleValue, FloatValue, Int64Value, UInt64Value,
 *   Int32Value, UInt32Value, BoolValue, StringValue, BytesValue
 * - Converting between DynamicMessage and native Swift values
 * - Use cases: nullable primitives in proto3
 * - Validation of wrapper type values
 *
 * Run with:
 *   swift run WrapperTypesDemo
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct WrapperTypesDemo {
  static func main() async throws {
    ExampleUtils.printHeader("Protobuf Wrapper Types")

    try await demonstrateStringValue()
    try await demonstrateNumericWrappers()
    try await demonstrateBoolAndBytesWrappers()
    try await demonstrateNullablePattern()

    ExampleUtils.printSuccess(
      "Wrapper types demo completed! All 9 types demonstrated."
    )

    ExampleUtils.printNext([
      "Next: list-value-demo.swift - working with ListValue",
      "Also: value-demo.swift - dynamic Value type",
      "See: struct-demo.swift - structured data",
    ])
  }

  // MARK: - StringValue

  private static func demonstrateStringValue() async throws {
    ExampleUtils.printStep(1, "google.protobuf.StringValue")

    let dynamic = try StringValueHandler.createDynamic(from: "Hello, Wrappers!")
    let specialized = try StringValueHandler.createSpecialized(from: dynamic)
    let value = specialized as? String ?? ""

    print("  Original:    \"Hello, Wrappers!\"")
    print("  Round-trip:  \"\(value)\"")
    print("  Valid:       \(StringValueHandler.validate("test"))")
    print("  Invalid:     \(StringValueHandler.validate(42))")

    ExampleUtils.printInfo(
      "StringValue wraps a string — useful for nullable string fields in proto3"
    )
  }

  // MARK: - Numeric Wrappers

  private static func demonstrateNumericWrappers() async throws {
    ExampleUtils.printStep(2, "Numeric Wrapper Types")

    let types: [(String, Any, any WellKnownTypeHandler.Type)] = [
      ("Int32Value", Int32(42), Int32ValueHandler.self),
      ("Int64Value", Int64(9_000_000_000), Int64ValueHandler.self),
      ("UInt32Value", UInt32(100), UInt32ValueHandler.self),
      ("UInt64Value", UInt64(18_000_000_000), UInt64ValueHandler.self),
      ("FloatValue", Float(3.14), FloatValueHandler.self),
      ("DoubleValue", Double(2.718281828), DoubleValueHandler.self),
    ]

    for (name, value, handler) in types {
      let dynamic = try handler.createDynamic(from: value)
      let restored = try handler.createSpecialized(from: dynamic)
      let valid = handler.validate(value)
      print("  \(name): \(value) → round-trip: \(restored), valid: \(valid)")
    }

    ExampleUtils.printInfo(
      "Each numeric wrapper wraps a single primitive — all support round-trip conversion"
    )
  }

  // MARK: - Bool and Bytes

  private static func demonstrateBoolAndBytesWrappers() async throws {
    ExampleUtils.printStep(3, "BoolValue & BytesValue")

    let boolDynamic = try BoolValueHandler.createDynamic(from: true)
    let boolBack = try BoolValueHandler.createSpecialized(from: boolDynamic) as? Bool ?? false
    print("  BoolValue:  true → \(boolBack)")

    let boolFalseDynamic = try BoolValueHandler.createDynamic(from: false)
    let boolFalseBack =
      try BoolValueHandler.createSpecialized(from: boolFalseDynamic) as? Bool ?? true
    print("  BoolValue:  false → \(boolFalseBack)")

    let testData = Data([0xCA, 0xFE, 0xBA, 0xBE])
    let bytesDynamic = try BytesValueHandler.createDynamic(from: testData)
    let bytesBack = try BytesValueHandler.createSpecialized(from: bytesDynamic) as? Data ?? Data()
    print(
      "  BytesValue: 0xCAFEBABE → 0x\(bytesBack.map { String(format: "%02X", $0) }.joined())"
    )

    ExampleUtils.printInfo(
      "BoolValue distinguishes unset from false; BytesValue wraps arbitrary binary data"
    )
  }

  // MARK: - Nullable Pattern

  private static func demonstrateNullablePattern() async throws {
    ExampleUtils.printStep(4, "Nullable Primitives Pattern")

    print("  Proto3 problem: all scalars have implicit defaults (0, \"\", false)")
    print("  Solution: Wrapper types let you distinguish \"not set\" from \"set to zero\"")
    print("")
    print("  Example: optional score field")
    print("    Without wrapper: score=0 could mean \"zero points\" or \"not scored\"")
    print("    With Int32Value: absent means \"not scored\", present(0) means \"zero points\"")
    print("")

    let registry = WellKnownTypesRegistry.shared
    let wrapperNames = [
      WellKnownTypeNames.stringValue,
      WellKnownTypeNames.int32Value,
      WellKnownTypeNames.int64Value,
      WellKnownTypeNames.uint32Value,
      WellKnownTypeNames.uint64Value,
      WellKnownTypeNames.floatValue,
      WellKnownTypeNames.doubleValue,
      WellKnownTypeNames.boolValue,
      WellKnownTypeNames.bytesValue,
    ]

    print("  Registered wrapper types:")
    for name in wrapperNames {
      let registered = await registry.getHandler(for: name) != nil
      print("    \(name): \(registered ? "registered" : "NOT registered")")
    }

    ExampleUtils.printInfo(
      "All 9 wrapper types are automatically registered in WellKnownTypesRegistry"
    )
  }
}
