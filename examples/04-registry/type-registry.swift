/**
 * 🗂 SwiftProtoReflect Example: TypeRegistry — Complete Guide
 *
 * Description: Everything you need to know about TypeRegistry in one file
 * Key concepts: registration, lookup, nested type resolution, binary + JSON
 * Complexity: 🔧🔧 Advanced
 * Execution time: < 5 seconds
 *
 * What you'll learn:
 * - Building a TypeRegistry from FileDescriptors (recommended pattern)
 * - Registering messages, enums, and services individually
 * - Lookup: findMessage, findEnum, findFile, allMessages, allFiles, hasMessage
 * - Why registry matters: cross-file nested type resolution
 * - BinaryDeserializer: registry resolves types not nested in the message descriptor
 * - JSONDeserializer: registry is REQUIRED for all nested message fields
 * - JSONSerializer: structural enum lookup works without registry
 * - Registry lifecycle: removeFile, clear, re-register
 *
 * Run with:
 *   swift run TypeRegistry
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

struct TypeRegistryGuide {
  static func run() async throws {
    ExampleUtils.printHeader("TypeRegistry — Complete Guide")

    try await step1BuildRegistryPatterns()
    try await step2LookupOperations()
    try await step3BinaryDeserializationWithRegistry()
    try await step4JSONSerializationWithRegistry()
    try await step5RegistryLifecycle()

    ExampleUtils.printSuccess("TypeRegistry complete guide finished!")

    ExampleUtils.printNext([
      "Next: file-loading.swift — runtime descriptor loading",
      "Also: dependency-resolution.swift — multi-file dependency graphs",
      "Compare: schema-validation.swift — schema validation patterns",
    ])
  }

  // MARK: - Domain Schema

  /// address.proto — package com.shop
  /// Defines a reusable Address type referenced by other files.
  private static func makeAddressFile() -> FileDescriptor {
    var file = FileDescriptor(name: "address.proto", package: "com.shop")
    var addr = MessageDescriptor(name: "Address", parent: file)
    addr.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addr.addField(FieldDescriptor(name: "city", number: 2, type: .string))
    addr.addField(FieldDescriptor(name: "zip", number: 3, type: .string))
    file.addMessage(addr)
    return file
  }

  /// Builds the product.proto FileDescriptor (package com.shop).
  ///
  /// Defines Product with a structurally nested Status enum and
  /// a cross-file reference to com.shop.Address (requires registry for deserialization).
  private static func makeProductFile() -> FileDescriptor {
    var file = FileDescriptor(name: "product.proto", package: "com.shop")
    var product = MessageDescriptor(name: "Product", parent: file)

    var status = EnumDescriptor(name: "Status", parent: product)
    status.addValue(.init(name: "UNKNOWN", number: 0))
    status.addValue(.init(name: "ACTIVE", number: 1))
    status.addValue(.init(name: "INACTIVE", number: 2))
    product.addNestedEnum(status)

    product.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    product.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    product.addField(FieldDescriptor(name: "price_cents", number: 3, type: .int64))
    product.addField(
      FieldDescriptor(
        name: "status",
        number: 4,
        type: .enum,
        typeName: "com.shop.Product.Status"
      )
    )
    product.addField(FieldDescriptor(name: "tags", number: 5, type: .string, isRepeated: true))
    // Cross-file reference — NOT a nested message of Product, lives in address.proto
    product.addField(
      FieldDescriptor(
        name: "warehouse_address",
        number: 6,
        type: .message,
        typeName: "com.shop.Address"
      )
    )

    file.addMessage(product)
    return file
  }

  // MARK: - Step 1: Building a Registry

  private static func step1BuildRegistryPatterns() async throws {
    ExampleUtils.printStep(1, "Building a TypeRegistry — all patterns")

    let addrFile = makeAddressFile()
    let productFile = makeProductFile()

    // Pattern A: recommended — one call, all files registered atomically
    let registryA = try await TypeRegistry(fileDescriptors: [addrFile, productFile])
    print("  Pattern A — TypeRegistry(fileDescriptors:)")
    print("    messages: \(await registryA.allMessages().count), files: \(await registryA.allFiles().count)")

    // Pattern B: start empty, add files one by one
    let registryB = TypeRegistry()
    try await registryB.registerFile(addrFile)
    try await registryB.registerFile(productFile)
    print("  Pattern B — TypeRegistry() + registerFile(_:)")
    print("    messages: \(await registryB.allMessages().count), files: \(await registryB.allFiles().count)")

    // Pattern C: register individual descriptors (no FileDescriptor needed).
    // registerMessage automatically registers nested enums — no separate registerEnum needed.
    let addrDesc = makeAddressFile().messages.values.first!
    let productDesc = makeProductFile().messages.values.first!

    let registryC = TypeRegistry()
    try await registryC.registerMessage(addrDesc)
    try await registryC.registerMessage(productDesc)
    print("  Pattern C — registerMessage(_:)")
    print("    messages: \(await registryC.allMessages().count), enums: \(await registryC.allEnums().count)")

    // Duplicate registration is rejected
    print("  Duplicate file registration:")
    do {
      try await registryA.registerFile(addrFile)
      print("    ❌ Should have thrown duplicateFile")
    }
    catch {
      print("    ✅ Correctly rejected: \(error)")
    }
  }

  // MARK: - Step 2: Lookup Operations

  private static func step2LookupOperations() async throws {
    ExampleUtils.printStep(2, "Lookup operations")

    let registry = try await TypeRegistry(fileDescriptors: [makeAddressFile(), makeProductFile()])

    // findMessage — full qualified name
    print("  findMessage(named:)")
    let addrDesc = await registry.findMessage(named: "com.shop.Address")
    print("    com.shop.Address  → \(addrDesc.map { "\($0.fields.count) fields" } ?? "nil")")
    let productDesc = await registry.findMessage(named: "com.shop.Product")
    print("    com.shop.Product  → \(productDesc.map { "\($0.fields.count) fields" } ?? "nil")")
    print("    com.shop.Unknown  → \(await registry.findMessage(named: "com.shop.Unknown") == nil ? "nil" : "found")")

    // findEnum — nested enum full name
    print("  findEnum(named:)")
    let status = await registry.findEnum(named: "com.shop.Product.Status")
    print(
      "    com.shop.Product.Status → \(status.map { "\($0.valuesByName.count) values: \($0.valuesByName.keys.sorted().joined(separator: ", "))" } ?? "nil")"
    )

    // hasMessage / hasEnum / hasFile
    print("  Boolean checks")
    print("    hasMessage(com.shop.Address):        \(await registry.hasMessage(named: "com.shop.Address"))")
    print("    hasMessage(com.shop.Gone):           \(await registry.hasMessage(named: "com.shop.Gone"))")
    print("    hasEnum(com.shop.Product.Status):    \(await registry.hasEnum(named: "com.shop.Product.Status"))")
    print("    hasFile(address.proto):              \(await registry.hasFile(named: "address.proto"))")

    // Enumerate all
    print("  allMessages(): \(await registry.allMessages().map { $0.fullName }.sorted().joined(separator: ", "))")
    print("  allFiles():    \(await registry.allFiles().map { $0.name }.sorted().joined(separator: ", "))")
    print("  allEnums():    \(await registry.allEnums().map { $0.fullName }.sorted().joined(separator: ", "))")

    // findFile
    if let f = await registry.findFile(named: "product.proto") {
      print("  findFile(\"product.proto\"): \(f.messages.count) message(s)")
    }
  }

  // MARK: - Step 3: Binary Deserialization with Registry

  private static func step3BinaryDeserializationWithRegistry() async throws {
    ExampleUtils.printStep(3, "Binary deserialization — cross-file nested type")

    let registry = try await TypeRegistry(fileDescriptors: [makeAddressFile(), makeProductFile()])
    let addrDesc = await registry.findMessage(named: "com.shop.Address")!
    let productDesc = await registry.findMessage(named: "com.shop.Product")!

    // Build a Product with a nested Address (cross-file reference)
    var address = DynamicMessage(descriptor: addrDesc)
    try address.set("123 Main St", forField: "street")
    try address.set("Springfield", forField: "city")
    try address.set("12345", forField: "zip")

    var product = MessageFactory().createMessage(from: productDesc)
    try product.set(Int64(42), forField: "id")
    try product.set("Widget Pro", forField: "name")
    try product.set(Int64(999), forField: "price_cents")  // $9.99
    try product.set(Int32(1), forField: "status")  // ACTIVE
    try product.set(["electronics", "sale"], forField: "tags")
    try product.set(address, forField: "warehouse_address")

    // BinarySerializer never needs a registry — it encodes whatever it has
    let binaryData = try BinarySerializer().serialize(product)
    print("  Serialized: \(binaryData.count) bytes")

    // WITHOUT registry: resolver fails on the cross-file warehouse_address field
    print("  Deserialization WITHOUT registry:")
    do {
      _ = try await BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
        .deserialize(binaryData, using: productDesc)
      print("    ❌ Should have thrown — Address type unknown")
    }
    catch {
      print("    ✅ Expected error: \(error)")
    }

    // WITH registry: cross-file type resolved from the registry
    print("  Deserialization WITH registry:")
    let decoded = try await BinaryDeserializer(options: .init(typeRegistry: registry))
      .deserialize(binaryData, using: productDesc)

    let name = try decoded.get(forField: "name") as? String ?? ""
    let status = try decoded.get(forField: "status") as? Int32 ?? 0
    let tags = try decoded.get(forField: "tags") as? [String] ?? []
    print("    ✅ name:    \(name)")
    print("       status: \(status) (ACTIVE)")
    print("       tags:   \(tags)")

    if let addr = try decoded.get(forField: "warehouse_address") as? DynamicMessage {
      let street = try addr.get(forField: "street") as? String ?? ""
      let city = try addr.get(forField: "city") as? String ?? ""
      print("       address: \(street), \(city)")
    }
  }

  // MARK: - Step 4: JSON Serialization with Registry

  private static func step4JSONSerializationWithRegistry() async throws {
    ExampleUtils.printStep(4, "JSON serialization — enums and nested messages")

    let registry = try await TypeRegistry(fileDescriptors: [makeAddressFile(), makeProductFile()])
    let addrDesc = await registry.findMessage(named: "com.shop.Address")!
    let productDesc = await registry.findMessage(named: "com.shop.Product")!

    var address = DynamicMessage(descriptor: addrDesc)
    try address.set("456 Oak Ave", forField: "street")
    try address.set("Shelbyville", forField: "city")
    try address.set("67890", forField: "zip")

    var product = MessageFactory().createMessage(from: productDesc)
    try product.set(Int64(7), forField: "id")
    try product.set("Gizmo", forField: "name")
    try product.set(Int64(499), forField: "price_cents")  // $4.99
    try product.set(Int32(1), forField: "status")  // ACTIVE → "ACTIVE" in JSON
    try product.set(["gadgets"], forField: "tags")
    try product.set(address, forField: "warehouse_address")

    // JSONSerializer:
    //   - Enum field: structural lookup in productDesc.nestedEnums → "ACTIVE" (no registry needed)
    //   - Nested message field: encodes from the DynamicMessage value (no registry needed)
    let jsonData = try await JSONSerializer(options: .init(typeRegistry: registry)).serialize(product)
    let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
    print("  JSON output:")
    if let obj = try? JSONSerialization.jsonObject(with: jsonData, options: []),
      let pretty = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted),
      let prettyStr = String(data: pretty, encoding: .utf8)
    {
      for line in prettyStr.components(separatedBy: .newlines) {
        print("    \(line)")
      }
    }
    else {
      print("    \(jsonString)")
    }

    // JSONDeserializer WITHOUT registry:
    //   - Fails immediately on warehouseAddress — no registry to resolve com.shop.Address
    print("  Deserialization WITHOUT registry:")
    do {
      _ = try await JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))
        .deserialize(jsonData, using: productDesc)
      print("    ❌ Should have thrown — Address not in registry")
    }
    catch {
      print("    ✅ Expected error: \(error)")
    }

    // JSONDeserializer WITH registry:
    //   - com.shop.Address resolved from registry
    //   - "ACTIVE" parsed back to Int32(1) via structural enum lookup
    print("  Deserialization WITH registry:")
    let decoded = try await JSONDeserializer(options: .init(typeRegistry: registry))
      .deserialize(jsonData, using: productDesc)

    let name = try decoded.get(forField: "name") as? String ?? ""
    let status = try decoded.get(forField: "status") as? Int32 ?? -1
    let tags = try decoded.get(forField: "tags") as? [String] ?? []
    print("    ✅ name:   \(name)")
    print("       status: \(status) (ACTIVE — round-tripped from \"ACTIVE\")")
    print("       tags:  \(tags)")

    if let addr = try decoded.get(forField: "warehouse_address") as? DynamicMessage {
      let city = try addr.get(forField: "city") as? String ?? ""
      let zip = try addr.get(forField: "zip") as? String ?? ""
      print("       city: \(city), zip: \(zip)")
    }
  }

  // MARK: - Step 5: Registry Lifecycle

  private static func step5RegistryLifecycle() async throws {
    ExampleUtils.printStep(5, "Registry lifecycle — inspect, remove, clear")

    let registry = try await TypeRegistry(fileDescriptors: [makeAddressFile(), makeProductFile()])

    print("  Initial state:")
    print("    files:    \(await registry.allFiles().count)")
    print("    messages: \(await registry.allMessages().count)")
    print("    enums:    \(await registry.allEnums().count)")

    // Remove a single file — unregisters Address
    let removed = await registry.removeFile(named: "address.proto")
    print("  After removeFile(\"address.proto\") → \(removed):")
    print("    hasFile(\"address.proto\"):         \(await registry.hasFile(named: "address.proto"))")
    print("    hasMessage(\"com.shop.Address\"):   \(await registry.hasMessage(named: "com.shop.Address"))")
    print("    hasMessage(\"com.shop.Product\"):  \(await registry.hasMessage(named: "com.shop.Product"))")
    print("    messages: \(await registry.allMessages().count)")

    // Clear everything
    await registry.clear()
    print("  After clear():")
    print("    files: \(await registry.allFiles().count), messages: \(await registry.allMessages().count)")

    // Registry is reusable after clear
    try await registry.registerFile(makeAddressFile())
    try await registry.registerFile(makeProductFile())
    print("  After re-registration:")
    print("    files: \(await registry.allFiles().count), messages: \(await registry.allMessages().count)")
    print("    com.shop.Address found: \(await registry.hasMessage(named: "com.shop.Address"))")
  }
}

@main
struct TypeRegistryEntry {
  static func main() async throws {
    try await TypeRegistryGuide.run()
  }
}
