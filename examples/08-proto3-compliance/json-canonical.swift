/**
 * 📄 SwiftProtoReflect Example: Proto3 Canonical JSON Encoding
 *
 * Description: Proto3 JSON mapping rules — int64 as string, bytes as base64, enums as names
 * Key concepts: JSONSerializer, includeDefaultValues, enum name serialization
 * Complexity: 🔧 Intermediate
 * Execution time: < 5 seconds
 *
 * What you'll learn:
 * - int64/uint64 serialized as JSON strings (precision preservation)
 * - bytes fields serialized as base64 strings
 * - enum fields serialized as string names instead of numbers
 * - includeDefaultValues option for explicit zero-value emission
 *
 * Run with:
 *   swift run JsonCanonical
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct JsonCanonicalExample {
  static func main() throws {
    ExampleUtils.printHeader("Proto3 Canonical JSON Encoding")

    try demonstrateInt64AsString()
    try demonstrateBytesAsBase64()
    try demonstrateEnumAsName()
    try demonstrateIncludeDefaultValues()

    ExampleUtils.printSuccess(
      "Proto3 canonical JSON encoding demo completed!"
    )

    ExampleUtils.printNext([
      "Next: optional-presence.swift - optional field presence",
      "Also: unknown-fields.swift - unknown field preservation",
      "See: schema-evolution.swift - schema evolution patterns",
    ])
  }

  // MARK: - Int64 as String

  private static func demonstrateInt64AsString() throws {
    ExampleUtils.printStep(1, "Int64/UInt64 as JSON Strings")

    var desc = MessageDescriptor(name: "BigNumbers", fullName: "example.BigNumbers")
    desc.addField(FieldDescriptor(name: "signed_big", number: 1, type: .int64))
    desc.addField(FieldDescriptor(name: "unsigned_big", number: 2, type: .uint64))
    desc.addField(FieldDescriptor(name: "regular_int", number: 3, type: .int32))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int64(9_007_199_254_740_993), forField: "signed_big")
    try msg.set(UInt64(18_446_744_073_709_551_615), forField: "unsigned_big")
    try msg.set(Int32(42), forField: "regular_int")

    let json = try JSONSerializer().serializeToJSONObject(msg)
    print("  signed_big type:   \(type(of: json["signed_big"]!)) = \(json["signed_big"]!)")
    print("  unsigned_big type: \(type(of: json["unsigned_big"]!)) = \(json["unsigned_big"]!)")
    print("  regular_int type:  \(type(of: json["regular_int"]!)) = \(json["regular_int"]!)")

    ExampleUtils.printInfo(
      "int64/uint64 are JSON strings to avoid JavaScript precision loss; int32 stays a number")
  }

  // MARK: - Bytes as Base64

  private static func demonstrateBytesAsBase64() throws {
    ExampleUtils.printStep(2, "Bytes as Base64 Strings")

    var desc = MessageDescriptor(name: "BinaryPayload", fullName: "example.BinaryPayload")
    desc.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))
    desc.addField(FieldDescriptor(name: "checksum", number: 2, type: .bytes))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set("Hello, Proto3!".data(using: .utf8)!, forField: "data")
    try msg.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forField: "checksum")

    let json = try JSONSerializer().serializeToJSONObject(msg)
    let dataB64 = json["data"] as? String ?? ""
    let checksumB64 = json["checksum"] as? String ?? ""
    print("  data (base64):     \"\(dataB64)\"")
    print("  checksum (base64): \"\(checksumB64)\"")

    let decoded = Data(base64Encoded: dataB64)!
    print("  Decoded data:      \"\(String(data: decoded, encoding: .utf8)!)\"")

    ExampleUtils.printInfo(
      "bytes fields use standard base64 encoding in JSON per proto3 spec")
  }

  // MARK: - Enum as Name

  private static func demonstrateEnumAsName() throws {
    ExampleUtils.printStep(3, "Enum Values as String Names")

    var statusEnum = EnumDescriptor(name: "Status", fullName: "example.Status")
    statusEnum.addValue(.init(name: "UNKNOWN", number: 0))
    statusEnum.addValue(.init(name: "ACTIVE", number: 1))
    statusEnum.addValue(.init(name: "SUSPENDED", number: 2))
    statusEnum.addValue(.init(name: "DELETED", number: 3))

    var desc = MessageDescriptor(name: "Account", fullName: "example.Account")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    desc.addField(
      FieldDescriptor(name: "status", number: 2, type: .enum, typeName: "example.Status"))
    desc.addNestedEnum(statusEnum)

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set("Alice", forField: "name")
    try msg.set(Int32(1), forField: "status")

    let json = try JSONSerializer().serializeToJSONObject(msg)
    print("  status value: \(json["status"]!)")
    print("  status type:  \(type(of: json["status"]!))")

    let jsonData = try JSONSerializer().serialize(msg)
    let deserialized = try JSONDeserializer().deserialize(jsonData, using: desc)
    let roundTripped = try deserialized.get(forField: "status") as? Int32 ?? -1
    print("  Round-trip:   enum name → Int32(\(roundTripped))")

    ExampleUtils.printInfo(
      "Enum fields serialize as string names in JSON and deserialize back to numbers")
  }

  // MARK: - Include Default Values

  private static func demonstrateIncludeDefaultValues() throws {
    ExampleUtils.printStep(4, "includeDefaultValues Option")

    var statusEnum = EnumDescriptor(name: "Role", fullName: "example.Role")
    statusEnum.addValue(.init(name: "GUEST", number: 0))
    statusEnum.addValue(.init(name: "ADMIN", number: 1))

    var desc = MessageDescriptor(name: "Profile", fullName: "example.Profile")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    desc.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
    desc.addField(FieldDescriptor(name: "active", number: 3, type: .bool))
    desc.addField(
      FieldDescriptor(name: "role", number: 4, type: .enum, typeName: "example.Role"))
    desc.addNestedEnum(statusEnum)

    let msg = MessageFactory().createMessage(from: desc)

    let defaultSerializer = JSONSerializer()
    let jsonDefault = try defaultSerializer.serializeToJSONObject(msg)
    print("  Default mode (empty message):  \(jsonDefault)")

    let fullSerializer = JSONSerializer(
      options: JSONSerializationOptions(includeDefaultValues: true))
    let jsonFull = try fullSerializer.serializeToJSONObject(msg)
    print("  includeDefaultValues=true:     \(jsonFull)")

    ExampleUtils.printInfo(
      "includeDefaultValues emits zero/empty/false for all unset scalar fields")
  }
}
