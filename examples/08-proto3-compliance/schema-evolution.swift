/**
 * 🔄 SwiftProtoReflect Example: Schema Evolution
 *
 * Description: Safely evolving proto schemas — adding, removing, and renaming fields
 * Key concepts: backward compatibility, unknown fields, field numbers
 * Complexity: 🔧🔧 Advanced
 * Execution time: < 5 seconds
 *
 * What you'll learn:
 * - Adding new fields without breaking old readers
 * - Removing fields — old data preserved as unknown fields
 * - Renaming fields — binary format uses numbers, not names
 * - Adding new enum values — unknown values preserved
 *
 * Run with:
 *   swift run SchemaEvolution
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct SchemaEvolutionExample {
  static func main() throws {
    ExampleUtils.printHeader("Proto3 Schema Evolution")

    try demonstrateAddField()
    try demonstrateRemoveField()
    try demonstrateRenameField()
    try demonstrateNewEnumValue()

    ExampleUtils.printSuccess(
      "Schema evolution demo completed!"
    )

    ExampleUtils.printNext([
      "Next: unknown-fields.swift - deep dive into unknown fields",
      "Also: nested-messages.swift - nested message handling",
      "See: syntax-and-defaults.swift - proto3 basics",
    ])
  }

  // MARK: - Add Field

  private static func demonstrateAddField() throws {
    ExampleUtils.printStep(1, "Adding a New Field (Backward Compatible)")

    var v1 = MessageDescriptor(name: "User", fullName: "example.User")
    v1.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    v1.addField(FieldDescriptor(name: "name", number: 2, type: .string))

    var msg = MessageFactory().createMessage(from: v1)
    try msg.set(Int32(1), forField: "id")
    try msg.set("Alice", forField: "name")
    let data = try BinarySerializer().serialize(msg)
    print("  v1 writes: id=1, name=\"Alice\" (\(data.count) bytes)")

    var v2 = MessageDescriptor(name: "User", fullName: "example.User")
    v2.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    v2.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    v2.addField(FieldDescriptor(name: "email", number: 3, type: .string))

    let decoded = try BinaryDeserializer().deserialize(data, using: v2)
    print("  v2 reads:  id=\(try decoded.get(forField: "id") as? Int32 ?? 0)")
    print("             name=\"\(try decoded.get(forField: "name") as? String ?? "")\"")
    print("             email=\(try decoded.get(forField: "email").map { "\"\($0)\"" } ?? "nil (absent)")")

    ExampleUtils.printInfo("New fields are simply absent when reading old data")
  }

  // MARK: - Remove Field

  private static func demonstrateRemoveField() throws {
    ExampleUtils.printStep(2, "Removing a Field (Unknown Field Preservation)")

    var old = MessageDescriptor(name: "Config", fullName: "example.Config")
    old.addField(FieldDescriptor(name: "timeout", number: 1, type: .int32))
    old.addField(FieldDescriptor(name: "debug_mode", number: 2, type: .bool))
    old.addField(FieldDescriptor(name: "retries", number: 3, type: .int32))

    var msg = MessageFactory().createMessage(from: old)
    try msg.set(Int32(30), forField: "timeout")
    try msg.set(true, forField: "debug_mode")
    try msg.set(Int32(5), forField: "retries")
    let data = try BinarySerializer().serialize(msg)

    var newer = MessageDescriptor(name: "Config", fullName: "example.Config")
    newer.addField(FieldDescriptor(name: "timeout", number: 1, type: .int32))
    newer.addField(FieldDescriptor(name: "retries", number: 3, type: .int32))

    let decoded = try BinaryDeserializer().deserialize(data, using: newer)
    print(
      "  Known:   timeout=\(try decoded.get(forField: "timeout") as? Int32 ?? 0), retries=\(try decoded.get(forField: "retries") as? Int32 ?? 0)"
    )
    print("  Unknown: \(decoded.unknownFields.count) bytes preserved (was debug_mode)")

    let reencoded = try BinarySerializer().serialize(decoded)
    let restored = try BinaryDeserializer().deserialize(reencoded, using: old)
    print("  Restored debug_mode: \(try restored.get(forField: "debug_mode") as? Bool ?? false)")

    ExampleUtils.printInfo("Removed fields survive as unknown fields through intermediaries")
  }

  // MARK: - Rename Field

  private static func demonstrateRenameField() throws {
    ExampleUtils.printStep(3, "Renaming a Field (Binary Unaffected)")

    var writer = MessageDescriptor(name: "Item", fullName: "example.Item")
    writer.addField(FieldDescriptor(name: "user_name", number: 1, type: .string))

    var msg = MessageFactory().createMessage(from: writer)
    try msg.set("Alice", forField: "user_name")
    let data = try BinarySerializer().serialize(msg)

    var reader = MessageDescriptor(name: "Item", fullName: "example.Item")
    reader.addField(FieldDescriptor(name: "display_name", number: 1, type: .string))

    let decoded = try BinaryDeserializer().deserialize(data, using: reader)
    let value = try decoded.get(forField: "display_name") as? String ?? ""
    print("  Writer field: \"user_name\" = \"Alice\"")
    print("  Reader field: \"display_name\" = \"\(value)\"")
    print("  Same data: \(value == "Alice" ? "YES" : "NO")")

    ExampleUtils.printInfo(
      "Binary format uses field numbers, not names — renaming is always safe"
    )
  }

  // MARK: - New Enum Value

  private static func demonstrateNewEnumValue() throws {
    ExampleUtils.printStep(4, "Adding New Enum Values")

    var newEnum = EnumDescriptor(name: "Status", fullName: "example.Status")
    newEnum.addValue(.init(name: "UNKNOWN", number: 0))
    newEnum.addValue(.init(name: "ACTIVE", number: 1))
    newEnum.addValue(.init(name: "ARCHIVED", number: 2))

    var writerDesc = MessageDescriptor(name: "Doc", fullName: "example.Doc")
    writerDesc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "example.Status")
    )

    var msg = MessageFactory().createMessage(from: writerDesc)
    try msg.set(Int32(2), forField: "status")
    let data = try BinarySerializer().serialize(msg)

    var oldEnum = EnumDescriptor(name: "Status", fullName: "example.Status")
    oldEnum.addValue(.init(name: "UNKNOWN", number: 0))
    oldEnum.addValue(.init(name: "ACTIVE", number: 1))

    var readerDesc = MessageDescriptor(name: "Doc", fullName: "example.Doc")
    readerDesc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "example.Status")
    )

    let decoded = try BinaryDeserializer().deserialize(data, using: readerDesc)
    let status = try decoded.get(forField: "status") as? Int32 ?? -1
    print("  Writer sends:    ARCHIVED (2)")
    print("  Old reader gets: raw value \(status) (name unknown to old schema)")

    ExampleUtils.printInfo(
      "Unknown enum values are preserved as raw numbers — no data loss"
    )
  }
}
