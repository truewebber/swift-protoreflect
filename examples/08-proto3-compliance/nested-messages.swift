/**
 * 🪆 SwiftProtoReflect Example: Nested Message Handling
 *
 * Description: Binary serialization and deserialization of nested and deeply nested messages
 * Key concepts: nested MessageDescriptor, recursive deserialization, type resolution
 * Complexity: 🔧🔧 Advanced
 * Execution time: < 5 seconds
 *
 * What you'll learn:
 * - Defining nested message descriptors
 * - Binary serialization of messages containing other messages
 * - Recursive deserialization with type resolution
 * - Multi-level nesting patterns
 *
 * Run with:
 *   swift run NestedMessages
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct NestedMessagesExample {
  static func main() async throws {
    ExampleUtils.printHeader("Nested Message Handling")

    try await demonstrateSimpleNesting()
    try await demonstrateDeepNesting()
    try await demonstrateJsonNesting()

    ExampleUtils.printSuccess(
      "Nested messages demo completed!"
    )

    ExampleUtils.printNext([
      "Next: schema-evolution.swift - schema evolution patterns",
      "Also: unknown-fields.swift - unknown field preservation",
      "See: json-canonical.swift - JSON encoding rules",
    ])
  }

  // MARK: - Simple Nesting

  private static func demonstrateSimpleNesting() async throws {
    ExampleUtils.printStep(1, "Simple Nested Message")

    var outerDesc = MessageDescriptor(name: "Person", fullName: "example.Person")
    outerDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))

    var addressDesc = MessageDescriptor(name: "Address", parent: outerDesc)
    addressDesc.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addressDesc.addField(FieldDescriptor(name: "city", number: 2, type: .string))

    outerDesc.addField(
      FieldDescriptor(
        name: "address",
        number: 2,
        type: .message,
        typeName: "example.Person.Address"
      )
    )
    outerDesc.addNestedMessage(addressDesc)

    var address = DynamicMessage(descriptor: addressDesc)
    try address.set("123 Main St", forField: 1)
    try address.set("Springfield", forField: 2)

    var person = MessageFactory().createMessage(from: outerDesc)
    try person.set("Alice", forField: "name")
    try person.set(address, forField: 2)

    let data = try BinarySerializer().serialize(person)
    print("  Serialized size: \(data.count) bytes")

    let decoded = try await BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(
      data,
      using: outerDesc
    )
    let decodedName = try decoded.get(forField: "name") as? String ?? ""
    print("  Name: \(decodedName)")

    if let decodedAddr = try decoded.get(forField: "address") as? DynamicMessage {
      let street = try decodedAddr.get(forField: "street") as? String ?? ""
      let city = try decodedAddr.get(forField: "city") as? String ?? ""
      print("  Address: \(street), \(city)")
    }

    ExampleUtils.printInfo(
      "Nested messages are recursively serialized and deserialized using descriptor lookups"
    )
  }

  // MARK: - Deep Nesting

  private static func demonstrateDeepNesting() async throws {
    ExampleUtils.printStep(2, "Multi-Level Nesting")

    var rootDesc = MessageDescriptor(name: "Root", fullName: "example.Root")
    rootDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    var midDesc = MessageDescriptor(name: "Mid", parent: rootDesc)
    midDesc.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    var leafDesc = MessageDescriptor(name: "Leaf", parent: midDesc)
    leafDesc.addField(FieldDescriptor(name: "data", number: 1, type: .int32))

    midDesc.addField(
      FieldDescriptor(name: "leaf", number: 2, type: .message, typeName: "example.Root.Mid.Leaf")
    )
    midDesc.addNestedMessage(leafDesc)

    rootDesc.addField(
      FieldDescriptor(name: "mid", number: 2, type: .message, typeName: "example.Root.Mid")
    )
    rootDesc.addNestedMessage(midDesc)

    var leaf = DynamicMessage(descriptor: leafDesc)
    try leaf.set(Int32(99), forField: 1)

    var mid = DynamicMessage(descriptor: midDesc)
    try mid.set("middle", forField: 1)
    try mid.set(leaf, forField: 2)

    var root = DynamicMessage(descriptor: rootDesc)
    try root.set(Int32(1), forField: 1)
    try root.set(mid, forField: 2)

    let data = try BinarySerializer().serialize(root)
    print("  3-level message size: \(data.count) bytes")

    let decoded = try await BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(
      data,
      using: rootDesc
    )
    let decodedId = try decoded.get(forField: "id") as? Int32 ?? 0
    print("  Root.id: \(decodedId)")

    if let decodedMid = try decoded.get(forField: "mid") as? DynamicMessage {
      let midVal = try decodedMid.get(forField: "value") as? String ?? ""
      print("  Root.mid.value: \"\(midVal)\"")

      if let decodedLeaf = try decodedMid.get(forField: "leaf") as? DynamicMessage {
        let leafData = try decodedLeaf.get(forField: "data") as? Int32 ?? 0
        print("  Root.mid.leaf.data: \(leafData)")
      }
    }

    ExampleUtils.printInfo("Deeply nested messages are fully supported with recursive deserialization")
  }

  // MARK: - JSON Nesting

  private static func demonstrateJsonNesting() async throws {
    ExampleUtils.printStep(3, "Nested Messages in JSON")

    var outerDesc = MessageDescriptor(name: "Place", fullName: "example.Place")
    outerDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))

    var innerDesc = MessageDescriptor(name: "Coord", parent: outerDesc)
    innerDesc.addField(FieldDescriptor(name: "lat", number: 1, type: .double))
    innerDesc.addField(FieldDescriptor(name: "lng", number: 2, type: .double))

    outerDesc.addField(
      FieldDescriptor(
        name: "location",
        number: 2,
        type: .message,
        typeName: "example.Place.Coord"
      )
    )
    outerDesc.addNestedMessage(innerDesc)

    var coord = DynamicMessage(descriptor: innerDesc)
    try coord.set(Double(37.7749), forField: 1)
    try coord.set(Double(-122.4194), forField: 2)

    var place = MessageFactory().createMessage(from: outerDesc)
    try place.set("San Francisco", forField: "name")
    try place.set(coord, forField: 2)

    let jsonData = try await JSONSerializer(options: .init(typeRegistry: TypeRegistry())).serialize(place)
    let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
    print("  JSON: \(jsonString)")

    ExampleUtils.printInfo("Nested messages serialize as nested JSON objects")
  }
}
