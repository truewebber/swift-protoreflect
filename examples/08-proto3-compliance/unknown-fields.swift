/**
 * 🔮 SwiftProtoReflect Example: Unknown Fields Preservation
 *
 * Description: How proto3 preserves unknown fields for forward/backward compatibility
 * Key concepts: unknownFields, schema evolution, binary round-trip
 * Complexity: 🔧 Intermediate
 * Execution time: < 5 seconds
 *
 * What you'll learn:
 * - How unknown fields are preserved during deserialization
 * - Round-trip preservation through serialize → deserialize cycles
 * - Schema evolution: adding/removing fields safely
 * - How unknownFields works with DynamicMessage
 *
 * Run with:
 *   swift run UnknownFields
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct UnknownFieldsExample {
  static func main() throws {
    ExampleUtils.printHeader("Unknown Fields Preservation")

    try demonstrateBasicPreservation()
    try demonstrateSchemaEvolution()
    try demonstrateRoundTrip()

    ExampleUtils.printSuccess(
      "Unknown fields demo completed!"
    )

    ExampleUtils.printNext([
      "Next: schema-evolution.swift - full schema evolution patterns",
      "Also: json-canonical.swift - canonical JSON encoding",
      "See: syntax-and-defaults.swift - proto3 defaults",
    ])
  }

  // MARK: - Basic Preservation

  private static func demonstrateBasicPreservation() throws {
    ExampleUtils.printStep(1, "Basic Unknown Field Preservation")

    var fullDesc = MessageDescriptor(name: "User", fullName: "example.User")
    fullDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    fullDesc.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    fullDesc.addField(FieldDescriptor(name: "email", number: 3, type: .string))

    var user = MessageFactory().createMessage(from: fullDesc)
    try user.set(Int32(1), forField: "id")
    try user.set("Alice", forField: "name")
    try user.set("alice@example.com", forField: "email")

    let data = try BinarySerializer().serialize(user)
    print("  Full message size: \(data.count) bytes")

    var reducedDesc = MessageDescriptor(name: "User", fullName: "example.User")
    reducedDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let partial = try BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(
      data,
      using: reducedDesc
    )
    print("  Known field 'id': \(try partial.get(forField: "id") as? Int32 ?? 0)")
    print("  Unknown fields preserved: \(partial.unknownFields.count) bytes")
    print("  Unknown fields hex: \(partial.unknownFields.map { String(format: "%02x", $0) }.joined(separator: " "))")

    ExampleUtils.printInfo(
      "Fields 2 (name) and 3 (email) are preserved as unknown fields when not in the descriptor"
    )
  }

  // MARK: - Schema Evolution

  private static func demonstrateSchemaEvolution() throws {
    ExampleUtils.printStep(2, "Schema Evolution Safety")

    var v1Desc = MessageDescriptor(name: "Config", fullName: "example.Config")
    v1Desc.addField(FieldDescriptor(name: "timeout", number: 1, type: .int32))
    v1Desc.addField(FieldDescriptor(name: "retries", number: 2, type: .int32))

    var v1Msg = MessageFactory().createMessage(from: v1Desc)
    try v1Msg.set(Int32(30), forField: "timeout")
    try v1Msg.set(Int32(3), forField: "retries")
    let v1Data = try BinarySerializer().serialize(v1Msg)
    print("  v1 message: timeout=30, retries=3 (\(v1Data.count) bytes)")

    var v2Desc = MessageDescriptor(name: "Config", fullName: "example.Config")
    v2Desc.addField(FieldDescriptor(name: "timeout", number: 1, type: .int32))
    v2Desc.addField(FieldDescriptor(name: "retries", number: 2, type: .int32))
    v2Desc.addField(FieldDescriptor(name: "max_connections", number: 3, type: .int32))

    let v2Read = try BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(
      v1Data,
      using: v2Desc
    )
    let timeout = try v2Read.get(forField: "timeout") as? Int32 ?? 0
    let retries = try v2Read.get(forField: "retries") as? Int32 ?? 0
    let maxConn = try v2Read.get(forField: "max_connections")
    print(
      "  v2 reads v1: timeout=\(timeout), retries=\(retries), max_connections=\(maxConn.map { "\($0)" } ?? "nil (not in v1)")"
    )

    ExampleUtils.printInfo(
      "New fields are simply absent when reading old data — no errors, safe evolution"
    )
  }

  // MARK: - Round Trip

  private static func demonstrateRoundTrip() throws {
    ExampleUtils.printStep(3, "Full Round-Trip Through Reduced Schema")

    var fullDesc = MessageDescriptor(name: "Event", fullName: "example.Event")
    fullDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    fullDesc.addField(FieldDescriptor(name: "type", number: 2, type: .string))
    fullDesc.addField(FieldDescriptor(name: "payload", number: 3, type: .bytes))

    var original = MessageFactory().createMessage(from: fullDesc)
    try original.set(Int32(42), forField: "id")
    try original.set("click", forField: "type")
    try original.set(Data([0xCA, 0xFE]), forField: "payload")
    let originalData = try BinarySerializer().serialize(original)

    var proxyDesc = MessageDescriptor(name: "Event", fullName: "example.Event")
    proxyDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let roundTripRegistry = TypeRegistry()
    let proxy = try BinaryDeserializer(options: .init(typeRegistry: roundTripRegistry)).deserialize(
      originalData,
      using: proxyDesc
    )
    let proxyData = try BinarySerializer().serialize(proxy)

    let restored = try BinaryDeserializer(options: .init(typeRegistry: roundTripRegistry)).deserialize(
      proxyData,
      using: fullDesc
    )
    let restoredId = try restored.get(forField: "id") as? Int32 ?? 0
    let restoredType = try restored.get(forField: "type") as? String ?? ""
    let restoredPayload = try restored.get(forField: "payload") as? Data ?? Data()

    print("  Original: id=42, type=\"click\", payload=0xCAFE")
    print(
      "  After proxy round-trip: id=\(restoredId), type=\"\(restoredType)\", payload=0x\(restoredPayload.map { String(format: "%02X", $0) }.joined())"
    )
    print(
      "  Data preserved: \(restoredId == 42 && restoredType == "click" && restoredPayload == Data([0xCA, 0xFE]) ? "YES" : "NO")"
    )

    ExampleUtils.printInfo(
      "Unknown fields survive a full round-trip through a proxy that only knows about field 1"
    )
  }
}
