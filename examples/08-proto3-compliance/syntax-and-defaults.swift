/**
 * 📋 SwiftProtoReflect Example: Proto3 Syntax & Default Values
 *
 * Description: FileDescriptor syntax tracking, proto3 default values, and enum validation
 * Key concepts: FileDescriptor.syntax, zero defaults, EnumDescriptor.validateProto3
 * Complexity: 🔧 Intermediate
 * Execution time: < 5 seconds
 *
 * What you'll learn:
 * - How FileDescriptor tracks proto2 vs proto3 syntax
 * - Proto3 zero-value defaults for all scalar types
 * - Enum validation requiring a zero-valued first entry
 * - How default values affect serialization (not on wire)
 *
 * Run with:
 *   swift run SyntaxAndDefaults
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct SyntaxAndDefaultsExample {
  static func main() throws {
    ExampleUtils.printHeader("Proto3 Syntax & Default Values")

    try demonstrateSyntaxTracking()
    try demonstrateZeroDefaults()
    try demonstrateEnumValidation()
    try demonstrateDefaultsNotOnWire()

    ExampleUtils.printSuccess(
      "Proto3 syntax and defaults demo completed!"
    )

    ExampleUtils.printNext([
      "Next: optional-presence.swift - proto3 optional keyword",
      "Also: unknown-fields.swift - unknown field preservation",
      "Advanced: json-canonical.swift - canonical JSON encoding",
    ])
  }

  // MARK: - Syntax Tracking

  private static func demonstrateSyntaxTracking() throws {
    ExampleUtils.printStep(1, "FileDescriptor Syntax Tracking")

    let proto3File = FileDescriptor(
      name: "user.proto", package: "example", syntax: "proto3")
    print("  Proto3 file syntax: \"\(proto3File.syntax)\"")

    let proto2File = FileDescriptor(
      name: "legacy.proto", package: "example", syntax: "proto2")
    print("  Proto2 file syntax: \"\(proto2File.syntax)\"")

    let defaultFile = FileDescriptor(name: "default.proto", package: "example")
    print("  Default syntax:     \"\(defaultFile.syntax)\"")

    let emptyFile = FileDescriptor(
      name: "empty.proto", package: "example", syntax: "")
    print("  Empty syntax:       \"\(emptyFile.syntax)\" (normalized to proto2)")

    ExampleUtils.printInfo(
      "FileDescriptor.syntax defaults to \"proto3\" and normalizes empty string to \"proto2\"")
  }

  // MARK: - Zero Defaults

  private static func demonstrateZeroDefaults() throws {
    ExampleUtils.printStep(2, "Proto3 Zero-Value Defaults")

    var desc = MessageDescriptor(name: "Scalars", fullName: "example.Scalars")
    desc.addField(FieldDescriptor(name: "int_val", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "long_val", number: 2, type: .int64))
    desc.addField(FieldDescriptor(name: "bool_val", number: 3, type: .bool))
    desc.addField(FieldDescriptor(name: "str_val", number: 4, type: .string))
    desc.addField(FieldDescriptor(name: "dbl_val", number: 5, type: .double))
    desc.addField(FieldDescriptor(name: "bytes_val", number: 6, type: .bytes))

    let msg = MessageFactory().createMessage(from: desc)

    print("  Unset field values in proto3:")
    for field in desc.allFields().sorted(by: { $0.number < $1.number }) {
      let val = try msg.get(forField: field.name)
      print("    \(field.name) (\(field.type)): \(val.map { "\($0)" } ?? "nil")")
    }

    ExampleUtils.printInfo(
      "In proto3, unset fields return nil (no explicit default) — they are treated as zero on the wire")
  }

  // MARK: - Enum Validation

  private static func demonstrateEnumValidation() throws {
    ExampleUtils.printStep(3, "Proto3 Enum Validation")

    var validEnum = EnumDescriptor(name: "Status", fullName: "example.Status")
    validEnum.addValue(.init(name: "UNKNOWN", number: 0))
    validEnum.addValue(.init(name: "ACTIVE", number: 1))
    validEnum.addValue(.init(name: "INACTIVE", number: 2))

    let validErrors = validEnum.validateProto3()
    print("  Valid enum (starts at 0): \(validErrors.isEmpty ? "PASS" : "FAIL")")

    var invalidEnum = EnumDescriptor(name: "Priority", fullName: "example.Priority")
    invalidEnum.addValue(.init(name: "LOW", number: 1))
    invalidEnum.addValue(.init(name: "HIGH", number: 2))

    let invalidErrors = invalidEnum.validateProto3()
    print("  Invalid enum (no zero value): \(invalidErrors.isEmpty ? "PASS" : "FAIL")")
    for err in invalidErrors {
      print("    Error: \(err)")
    }

    ExampleUtils.printInfo("Proto3 requires the first enum value to have number 0")
  }

  // MARK: - Defaults Not On Wire

  private static func demonstrateDefaultsNotOnWire() throws {
    ExampleUtils.printStep(4, "Default Values Not Serialized")

    var desc = MessageDescriptor(name: "M", fullName: "example.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "name", number: 2, type: .string))

    let emptyMsg = MessageFactory().createMessage(from: desc)
    let emptyData = try BinarySerializer().serialize(emptyMsg)
    print("  Empty message binary size: \(emptyData.count) bytes")

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int32(42), forField: "id")
    try msg.set("Alice", forField: "name")
    let fullData = try BinarySerializer().serialize(msg)
    print("  Populated message binary size: \(fullData.count) bytes")

    ExampleUtils.printInfo(
      "Proto3: unset/zero-valued fields produce 0 bytes on wire")
  }
}
