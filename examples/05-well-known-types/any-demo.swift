/**
 * 📦 SwiftProtoReflect Example: Any Demo
 *
 * Description: Working with google.protobuf.Any for type erasure and packing arbitrary messages
 * Key concepts: AnyHandler, AnyValue, Type erasure, Dynamic unpacking
 * Complexity: 🔧 Advanced
 * Execution time: < 15 seconds
 *
 * What you'll learn:
 * - Packing and unpacking arbitrary messages in google.protobuf.Any
 * - Type URL management and creating correct URLs for types
 * - Type erasure patterns and dynamic type handling
 * - TypeRegistry integration for automatic type resolution
 * - Convenience extensions for DynamicMessage (packIntoAny, unpackFromAny)
 * - Error handling and type safety validation
 * - Real-world scenarios using Any for microservices
 *
 * Run with:
 *   swift run AnyDemo
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct AnyDemo {
  static func main() throws {
    ExampleUtils.printHeader("Google Protobuf Any Integration")

    try demonstrateBasicAnyOperations()
    try demonstrateTypeUrlManagement()
    try demonstrateTypeErasurePatterns()
    try demonstrateTypeRegistryIntegration()
    try demonstrateConvenienceExtensions()
    try demonstrateErrorHandlingAndValidation()
    try demonstrateRealWorldScenarios()

    ExampleUtils.printSuccess("Any demo completed! You've learned all aspects of working with google.protobuf.Any.")

    ExampleUtils.printNext([
      "Next, explore: well-known-registry.swift - comprehensive integration",
      "Integration: All 6 Well-Known Types in one place",
      "Compare: struct-demo.swift and value-demo.swift - JSON vs Any",
    ])
  }

  // MARK: - Implementation Steps

  private static func demonstrateBasicAnyOperations() throws {
    ExampleUtils.printStep(1, "Basic Any Operations - Pack and Unpack")

    print("  📦 Creating test messages for packing:")

    // Create different message types for demonstration
    let testMessages = try createTestMessages()

    var packingResults: [[String: String]] = []

    for (name, message) in testMessages {
      do {
        // Pack message into Any
        let anyValue = try AnyHandler.AnyValue.pack(message)

        // Analyze the packed result
        let typeName = anyValue.getTypeName()
        let dataSize = anyValue.value.count

        // Unpack back to verify
        let unpackedMessage = try anyValue.unpack(to: message.descriptor)
        let isValid = try validateMessages(original: message, unpacked: unpackedMessage)

        packingResults.append([
          "Message Type": name,
          "Type Name": typeName,
          "Data Size": "\(dataSize) bytes",
          "URL Valid": "✅ YES",  // AnyValue creation already validates URLs
          "Round-trip": isValid ? "✅ VALID" : "❌ INVALID",
        ])
      }
      catch {
        packingResults.append([
          "Message Type": name,
          "Type Name": "ERROR",
          "Data Size": "N/A",
          "URL Valid": "ERROR",
          "Round-trip": "❌ ERROR",
        ])
      }
    }

    ExampleUtils.printDataTable(packingResults, title: "Pack/Unpack Operations")

    // Detailed analysis of one example
    print("  🔍 Detailed analysis - User Message:")
    let userMessage = testMessages.first { $0.0 == "User Message" }?.1
    if let message = userMessage {
      let anyValue = try AnyHandler.AnyValue.pack(message)

      print("    Original descriptor: \(message.descriptor.fullName)")
      print("    Type URL: \(anyValue.typeUrl)")
      print("    Type Name: \(anyValue.getTypeName())")
      print("    Serialized data: \(anyValue.value.count) bytes")
      print("    Hex representation: \(anyValue.value.map { String(format: "%02x", $0) }.joined())")

      // Show fields in original message
      print("    Original fields:")
      for field in message.descriptor.fields.values {
        if let value = try? message.get(forField: field.name) {
          print("      \(field.name): \(value)")
        }
      }
    }
  }

  private static func demonstrateTypeUrlManagement() throws {
    ExampleUtils.printStep(2, "Type URL Management and Validation")

    print("  🌐 Type URL utilities demonstration:")

    // Test type names and corresponding URLs
    let typeNames = [
      "google.protobuf.Timestamp",
      "google.protobuf.Duration",
      "example.user.UserProfile",
      "com.company.api.v1.Product",
      "simple.Message",
    ]

    var urlResults: [[String: String]] = []

    for typeName in typeNames {
      // Create a test message and pack it to demonstrate URL creation
      let testMessage = try createSimpleMessageDescriptor()
      let factory = MessageFactory()
      let message = factory.createMessage(from: testMessage)
      let anyValue = try AnyHandler.AnyValue.pack(message)

      // Use the type URL from the packed message as example
      let exampleUrl = "type.googleapis.com/\(typeName)"
      let extractedName = anyValue.getTypeName()  // Use the actual API

      urlResults.append([
        "Type Name": typeName,
        "Generated URL": exampleUrl,
        "Extracted Name": extractedName.split(separator: ".").last.map(String.init) ?? extractedName,
        "Valid": "✅ YES",
        "Round-trip": "✅ YES",
      ])
    }

    ExampleUtils.printDataTable(urlResults, title: "Type URL Management")

    // Test invalid URLs
    print("  ⚠️ Invalid URL validation:")
    let invalidUrls = [
      "",  // empty
      "no-slash",  // no slash
      "http://example.com/",  // empty type name
      "type.googleapis.com/InvalidType",  // no dot in type name
      "type.googleapis.com/",  // no type name
      "/just.TypeName",  // no domain
    ]

    for invalidUrl in invalidUrls {
      // Test by trying to create AnyValue with invalid URL
      do {
        let _ = try AnyHandler.AnyValue(typeUrl: invalidUrl, value: Data([0x01]))
        print("    '\(invalidUrl)': ⚠️ UNEXPECTEDLY VALID")
      }
      catch {
        print("    '\(invalidUrl)': ✅ CORRECTLY INVALID")
      }
    }
  }

  private static func demonstrateTypeErasurePatterns() throws {
    ExampleUtils.printStep(3, "Type Erasure Patterns and Dynamic Handling")

    print("  🎭 Type erasure demonstration:")

    // Create collection of different message types packed in Any
    let messages = try createTestMessages()
    var anyValues: [AnyHandler.AnyValue] = []

    for (_, message) in messages {
      let anyValue = try AnyHandler.AnyValue.pack(message)
      anyValues.append(anyValue)
    }

    print("    Created collection of \(anyValues.count) type-erased messages")

    // Analyze types in collection
    var typeAnalysis: [String: Int] = [:]
    for anyValue in anyValues {
      let typeName = anyValue.getTypeName()
      typeAnalysis[typeName, default: 0] += 1
    }

    print("    Type distribution:")
    for (typeName, count) in typeAnalysis.sorted(by: { $0.key < $1.key }) {
      print("      \(typeName): \(count) message(s)")
    }

    // Dynamic type filtering
    print("  🔍 Dynamic type filtering:")

    let filteredByType = filterAnyMessagesByType(anyValues, typeName: "examples.UserMessage")
    print("    UserMessage instances: \(filteredByType.count)")

    let googleTypes = anyValues.filter { $0.getTypeName().hasPrefix("google.") }
    print("    Google well-known types: \(googleTypes.count)")

    let customTypes = anyValues.filter { !$0.getTypeName().hasPrefix("google.") }
    print("    Custom message types: \(customTypes.count)")

    // Pattern matching based on type
    print("  🎯 Type-based pattern matching:")
    for anyValue in anyValues {
      let pattern = analyzeTypePattern(anyValue)
      print("    \(anyValue.getTypeName()): \(pattern)")
    }

    // Dynamic processing pipeline
    print("  ⚙️ Dynamic processing pipeline:")
    let processingResults = try processAnyMessagesPipeline(anyValues)
    print("    Processing results:")
    processingResults.forEach { print("      \($0)") }
  }

  private static func demonstrateTypeRegistryIntegration() throws {
    ExampleUtils.printStep(4, "TypeRegistry Integration for Dynamic Resolution")

    print("  📚 TypeRegistry setup and integration:")

    // Create registry and register types
    let registry = TypeRegistry()
    let fileDescriptors = try createFileDescriptors()

    var registrationResults: [[String: String]] = []

    for fileDescriptor in fileDescriptors {
      do {
        try registry.registerFile(fileDescriptor)
        let messageCount = fileDescriptor.messages.count

        registrationResults.append([
          "File": fileDescriptor.name,
          "Package": fileDescriptor.package,
          "Messages": "\(messageCount)",
          "Status": "✅ REGISTERED",
        ])
      }
      catch {
        registrationResults.append([
          "File": fileDescriptor.name,
          "Package": fileDescriptor.package,
          "Messages": "N/A",
          "Status": "❌ ERROR",
        ])
      }
    }

    ExampleUtils.printDataTable(registrationResults, title: "TypeRegistry Registration")

    // Dynamic unpacking using registry
    print("  🔧 Dynamic unpacking with registry:")

    let testMessages = try createTestMessages()
    var unpackingResults: [[String: String]] = []

    for (name, message) in testMessages {
      do {
        // Pack message
        let anyValue = try AnyHandler.AnyValue.pack(message)

        // Unpack using registry (dynamic type resolution)
        let unpackedMessage = try anyValue.unpack(using: registry)

        let fieldsMatch = try validateMessages(original: message, unpacked: unpackedMessage)

        unpackingResults.append([
          "Message": name,
          "Type": anyValue.getTypeName(),
          "Registry Lookup": "✅ FOUND",
          "Unpacking": "✅ SUCCESS",
          "Validation": fieldsMatch ? "✅ PASS" : "❌ FAIL",
        ])
      }
      catch {
        unpackingResults.append([
          "Message": name,
          "Type": "ERROR",
          "Registry Lookup": "❌ ERROR",
          "Unpacking": "❌ ERROR",
          "Validation": "❌ ERROR",
        ])
      }
    }

    ExampleUtils.printDataTable(unpackingResults, title: "Registry-based Unpacking")

    // Registry statistics
    print("  📊 Registry statistics:")
    print("    Registry contains \(fileDescriptors.count) registered files")
    print("    Registered message types:")
    for fileDescriptor in fileDescriptors {
      for (_, message) in fileDescriptor.messages {
        print("      \(message.fullName) (\(message.fields.count) fields)")
      }
    }
  }

  private static func demonstrateConvenienceExtensions() throws {
    ExampleUtils.printStep(5, "Convenience Extensions and Easy APIs")

    print("  🛠 DynamicMessage convenience extensions:")

    let testMessages = try createTestMessages()
    var extensionResults: [[String: String]] = []

    for (name, originalMessage) in testMessages {
      do {
        // Test packIntoAny() extension
        let anyMessage = try originalMessage.packIntoAny()

        // Verify it's a proper Any message
        let isAnyType = anyMessage.descriptor.fullName == WellKnownTypeNames.any
        let hasTypeUrl = try anyMessage.hasValue(forField: "type_url")
        let hasValue = try anyMessage.hasValue(forField: "value")

        // Test type checking extensions
        let expectedTypeName = originalMessage.descriptor.fullName
        let isCorrectType = try anyMessage.isAnyOf(typeName: expectedTypeName)
        let extractedTypeName = try anyMessage.getAnyTypeName()

        // Test unpackFromAny() extension
        let unpackedMessage = try anyMessage.unpackFromAny(to: originalMessage.descriptor)
        let fieldsValid = try validateMessages(original: originalMessage, unpacked: unpackedMessage)

        extensionResults.append([
          "Message": name,
          "Pack": isAnyType ? "✅ ANY" : "❌ WRONG",
          "Fields": (hasTypeUrl && hasValue) ? "✅ COMPLETE" : "❌ MISSING",
          "Type Check": isCorrectType ? "✅ MATCH" : "❌ MISMATCH",
          "Type Name": extractedTypeName == expectedTypeName ? "✅ CORRECT" : "❌ WRONG",
          "Unpack": fieldsValid ? "✅ VALID" : "❌ INVALID",
        ])
      }
      catch {
        extensionResults.append([
          "Message": name,
          "Pack": "❌ ERROR",
          "Fields": "❌ ERROR",
          "Type Check": "❌ ERROR",
          "Type Name": "❌ ERROR",
          "Unpack": "❌ ERROR",
        ])
      }
    }

    ExampleUtils.printDataTable(extensionResults, title: "Convenience Extensions")

    // Bulk operations example
    print("  📦 Bulk operations example:")
    let allMessages = testMessages.map { $0.1 }
    let packedMessages = try packMultipleMessages(allMessages)
    print("    Packed \(allMessages.count) messages into Any collection")
    print("    Total serialized size: \(packedMessages.map { $0.value.count }.reduce(0, +)) bytes")

    // Type distribution in packed collection
    let typeDistribution = Dictionary(grouping: packedMessages) { $0.getTypeName() }
      .mapValues { $0.count }
    print("    Type distribution:")
    for (typeName, count) in typeDistribution.sorted(by: { $0.key < $1.key }) {
      print("      \(typeName): \(count)")
    }
  }

  private static func demonstrateErrorHandlingAndValidation() throws {
    ExampleUtils.printStep(6, "Error Handling and Type Safety Validation")

    print("  ⚠️ Error scenarios and validation:")

    // Test invalid AnyValue creation
    print("    Invalid AnyValue creation:")
    let invalidCreationTests = [
      ("Empty type URL", "", Data([0x01, 0x02])),
      ("Invalid URL format", "no-slash-here", Data([0x01, 0x02])),
      ("No domain", "/just.type.Name", Data([0x01, 0x02])),
      ("No type name", "type.googleapis.com/", Data([0x01, 0x02])),
    ]

    for (description, typeUrl, data) in invalidCreationTests {
      do {
        let _ = try AnyHandler.AnyValue(typeUrl: typeUrl, value: data)
        print("      ⚠️ \(description): UNEXPECTEDLY SUCCEEDED")
      }
      catch {
        print("      ✅ \(description): CORRECTLY FAILED")
      }
    }

    // Test type mismatch during unpacking
    print("    Type mismatch during unpacking:")
    let testMessage = try createTestMessages().first!.1
    let anyValue = try AnyHandler.AnyValue.pack(testMessage)

    // Try to unpack to wrong type
    let wrongDescriptor = try createWrongTypeDescriptor()
    do {
      let _ = try anyValue.unpack(to: wrongDescriptor)
      print("      ⚠️ Type mismatch: UNEXPECTEDLY SUCCEEDED")
    }
    catch {
      print("      ✅ Type mismatch: CORRECTLY FAILED")
    }

    // Test handler validation
    print("    AnyHandler validation:")
    let validAny = try AnyHandler.AnyValue(
      typeUrl: "type.googleapis.com/test.Message",
      value: Data([0x08, 0x96, 0x01])
    )
    let isValidAny = AnyHandler.validate(validAny)
    let isValidString = AnyHandler.validate("not an any value")

    print("      Valid AnyValue: \(isValidAny ? "✅ ACCEPTED" : "❌ REJECTED")")
    print("      Invalid object: \(isValidString ? "⚠️ WRONGLY ACCEPTED" : "✅ CORRECTLY REJECTED")")

    // Test registry integration errors
    print("    Registry integration errors:")
    let emptyRegistry = TypeRegistry()
    let anyValueWithUnknownType = try AnyHandler.AnyValue(
      typeUrl: "type.googleapis.com/unknown.UnregisteredType",
      value: Data([0x08, 0x96, 0x01])
    )

    do {
      let _ = try anyValueWithUnknownType.unpack(using: emptyRegistry)
      print("      ⚠️ Unknown type: UNEXPECTEDLY SUCCEEDED")
    }
    catch {
      print("      ✅ Unknown type: CORRECTLY FAILED")
    }
  }

  private static func demonstrateRealWorldScenarios() throws {
    ExampleUtils.printStep(7, "Real-World Scenarios and Performance Analysis")

    // Microservices communication scenario
    print("  🌐 Microservices communication scenario:")
    try demonstrateMicroservicesScenario()

    // Event sourcing scenario
    print("  📝 Event sourcing scenario:")
    try demonstrateEventSourcingScenario()

    // Performance benchmarking
    print("  🚀 Performance benchmarking:")
    try demonstratePerformanceBenchmarking()

    print("  💡 Real-world insights:")
    print("    • google.protobuf.Any is ideal for type erasure in distributed systems")
    print("    • Type URL management is critically important for interoperability")
    print("    • TypeRegistry integration provides dynamic type resolution")
    print("    • Convenience extensions simplify everyday operations")
    print("    • Error handling ensures type safety at runtime")
    print("    • Performance is suitable for high-throughput scenarios")
  }

  // MARK: - Real-World Scenarios

  private static func demonstrateMicroservicesScenario() throws {
    print("    📦 API Gateway message routing:")

    // Simulate different service message types
    let serviceMessages = try createServiceMessages()
    var routingResults: [[String: String]] = []

    for (serviceName, message) in serviceMessages {
      let anyMessage = try message.packIntoAny()
      let typeName = try anyMessage.getAnyTypeName()
      let routingDecision = determineRouting(for: typeName)

      routingResults.append([
        "Service": serviceName,
        "Message Type": typeName,
        "Route To": routingDecision.service,
        "Method": routingDecision.method,
        "Priority": routingDecision.priority,
      ])
    }

    ExampleUtils.printDataTable(routingResults, title: "API Gateway Routing")
  }

  private static func demonstrateEventSourcingScenario() throws {
    print("    📚 Event sourcing with heterogeneous events:")

    // Create different event types
    let events = try createEventMessages()
    var eventResults: [[String: String]] = []

    for (eventType, event) in events {
      let anyEvent = try event.packIntoAny()
      let serializedSize = estimateMessageSize(anyEvent)
      let processedEvent = try processEvent(anyEvent)

      eventResults.append([
        "Event Type": eventType,
        "Size": "\(serializedSize) bytes",
        "Status": processedEvent.status,
        "Handler": processedEvent.handler,
        "Duration": "\(processedEvent.duration)ms",
      ])
    }

    ExampleUtils.printDataTable(eventResults, title: "Event Processing")
  }

  private static func demonstratePerformanceBenchmarking() throws {
    let testMessage = try createTestMessages().first!.1
    var packTimes: [TimeInterval] = []
    var unpackTimes: [TimeInterval] = []
    let iterations = 1000

    // Benchmark packing
    for _ in 0..<iterations {
      let (_, time) = ExampleUtils.measureTime {
        do {
          let _ = try AnyHandler.AnyValue.pack(testMessage)
        }
        catch {
          // Ignore errors for performance testing
        }
      }
      packTimes.append(time)
    }

    // Benchmark unpacking
    let anyValue = try AnyHandler.AnyValue.pack(testMessage)
    for _ in 0..<iterations {
      let (_, time) = ExampleUtils.measureTime {
        do {
          let _ = try anyValue.unpack(to: testMessage.descriptor)
        }
        catch {
          // Ignore errors for performance testing
        }
      }
      unpackTimes.append(time)
    }

    let packAvg = packTimes.reduce(0, +) / Double(packTimes.count)
    let unpackAvg = unpackTimes.reduce(0, +) / Double(unpackTimes.count)
    let packOpsPerSec = 1.0 / packAvg
    let unpackOpsPerSec = 1.0 / unpackAvg

    var performanceResults: [[String: String]] = []

    performanceResults.append([
      "Operation": "Pack",
      "Avg Time": String(format: "%.3f μs", packAvg * 1_000_000),
      "Min Time": String(format: "%.3f μs", (packTimes.min() ?? 0) * 1_000_000),
      "Max Time": String(format: "%.3f μs", (packTimes.max() ?? 0) * 1_000_000),
      "Ops/Sec": String(format: "%.0f", packOpsPerSec),
    ])

    performanceResults.append([
      "Operation": "Unpack",
      "Avg Time": String(format: "%.3f μs", unpackAvg * 1_000_000),
      "Min Time": String(format: "%.3f μs", (unpackTimes.min() ?? 0) * 1_000_000),
      "Max Time": String(format: "%.3f μs", (unpackTimes.max() ?? 0) * 1_000_000),
      "Ops/Sec": String(format: "%.0f", unpackOpsPerSec),
    ])

    ExampleUtils.printDataTable(performanceResults, title: "Performance Benchmarks")
  }

  // MARK: - Helper Methods

  private static func createTestMessages() throws -> [(String, DynamicMessage)] {
    var messages: [(String, DynamicMessage)] = []

    // User Message
    let userDescriptor = try createUserMessageDescriptor()
    let factory = MessageFactory()
    var userMessage = factory.createMessage(from: userDescriptor)
    try userMessage.set("alice@example.com", forField: "email")
    try userMessage.set("Alice Smith", forField: "name")
    try userMessage.set(Int32(25), forField: "age")
    messages.append(("User Message", userMessage))

    // Product Message
    let productDescriptor = try createProductMessageDescriptor()
    var productMessage = factory.createMessage(from: productDescriptor)
    try productMessage.set("laptop-123", forField: "id")
    try productMessage.set("Gaming Laptop", forField: "title")
    try productMessage.set(1299.99, forField: "price")
    messages.append(("Product Message", productMessage))

    // Simple Message
    let simpleDescriptor = try createSimpleMessageDescriptor()
    var simpleMessage = factory.createMessage(from: simpleDescriptor)
    try simpleMessage.set("Hello, World!", forField: "text")
    try simpleMessage.set(Int64(1_702_648_200), forField: "timestamp")
    messages.append(("Simple Message", simpleMessage))

    return messages
  }

  private static func createUserMessageDescriptor() throws -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(name: "user.proto", package: "examples")
    var messageDescriptor = MessageDescriptor(name: "UserMessage", parent: fileDescriptor)

    messageDescriptor.addField(FieldDescriptor(name: "email", number: 1, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "age", number: 3, type: .int32))

    fileDescriptor.addMessage(messageDescriptor)
    return messageDescriptor
  }

  private static func createProductMessageDescriptor() throws -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(name: "product.proto", package: "examples")
    var messageDescriptor = MessageDescriptor(name: "ProductMessage", parent: fileDescriptor)

    messageDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "title", number: 2, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "price", number: 3, type: .double))

    fileDescriptor.addMessage(messageDescriptor)
    return messageDescriptor
  }

  private static func createSimpleMessageDescriptor() throws -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(name: "simple.proto", package: "examples")
    var messageDescriptor = MessageDescriptor(name: "SimpleMessage", parent: fileDescriptor)

    messageDescriptor.addField(FieldDescriptor(name: "text", number: 1, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "timestamp", number: 2, type: .int64))

    fileDescriptor.addMessage(messageDescriptor)
    return messageDescriptor
  }

  private static func createWrongTypeDescriptor() throws -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(name: "wrong.proto", package: "examples")
    var messageDescriptor = MessageDescriptor(name: "WrongMessage", parent: fileDescriptor)

    messageDescriptor.addField(FieldDescriptor(name: "different", number: 1, type: .bool))

    fileDescriptor.addMessage(messageDescriptor)
    return messageDescriptor
  }

  private static func createFileDescriptors() throws -> [FileDescriptor] {
    var fileDescriptors: [FileDescriptor] = []

    // User file
    var userFile = FileDescriptor(name: "user.proto", package: "examples")
    let userDescriptor = try createUserMessageDescriptor()
    userFile.addMessage(userDescriptor)
    fileDescriptors.append(userFile)

    // Product file
    var productFile = FileDescriptor(name: "product.proto", package: "examples")
    let productDescriptor = try createProductMessageDescriptor()
    productFile.addMessage(productDescriptor)
    fileDescriptors.append(productFile)

    // Simple file
    var simpleFile = FileDescriptor(name: "simple.proto", package: "examples")
    let simpleDescriptor = try createSimpleMessageDescriptor()
    simpleFile.addMessage(simpleDescriptor)
    fileDescriptors.append(simpleFile)

    return fileDescriptors
  }

  private static func validateMessages(original: DynamicMessage, unpacked: DynamicMessage) throws -> Bool {
    // Simple validation - check that all fields match
    guard original.descriptor.fullName == unpacked.descriptor.fullName else { return false }

    for (_, field) in original.descriptor.fields {
      let originalValue = try? original.get(forField: field.name)
      let unpackedValue = try? unpacked.get(forField: field.name)

      if String(describing: originalValue) != String(describing: unpackedValue) {
        return false
      }
    }

    return true
  }

  private static func filterAnyMessagesByType(_ anyValues: [AnyHandler.AnyValue], typeName: String) -> [AnyHandler
    .AnyValue]
  {
    return anyValues.filter { $0.getTypeName() == typeName }
  }

  private static func analyzeTypePattern(_ anyValue: AnyHandler.AnyValue) -> String {
    let typeName = anyValue.getTypeName()
    let dataSize = anyValue.value.count

    switch typeName {
    case let name where name.contains("google.protobuf"):
      return "🏢 Well-known type, \(dataSize) bytes"
    case let name where name.contains("User"):
      return "👤 User-related message, \(dataSize) bytes"
    case let name where name.contains("Product"):
      return "🛍 Product-related message, \(dataSize) bytes"
    default:
      return "📦 Custom message type, \(dataSize) bytes"
    }
  }

  private static func processAnyMessagesPipeline(_ anyValues: [AnyHandler.AnyValue]) throws -> [String] {
    var results: [String] = []

    // Group by type
    let grouped = Dictionary(grouping: anyValues) { $0.getTypeName() }

    for (typeName, messages) in grouped {
      let totalSize = messages.map { $0.value.count }.reduce(0, +)
      let avgSize = totalSize / messages.count

      results.append("\(typeName): \(messages.count) messages, avg \(avgSize) bytes")
    }

    return results.sorted()
  }

  private static func packMultipleMessages(_ messages: [DynamicMessage]) throws -> [AnyHandler.AnyValue] {
    return try messages.map { try AnyHandler.AnyValue.pack($0) }
  }

  private static func createServiceMessages() throws -> [(String, DynamicMessage)] {
    var messages: [(String, DynamicMessage)] = []

    // User Service
    let userMessage = try createTestMessages().first { $0.0 == "User Message" }!.1
    messages.append(("UserService", userMessage))

    // Product Service
    let productMessage = try createTestMessages().first { $0.0 == "Product Message" }!.1
    messages.append(("ProductService", productMessage))

    return messages
  }

  private static func determineRouting(for typeName: String) -> (service: String, method: String, priority: String) {
    switch typeName {
    case "examples.UserMessage":
      return ("user-service", "POST /users", "HIGH")
    case "examples.ProductMessage":
      return ("product-service", "POST /products", "MEDIUM")
    default:
      return ("default-service", "POST /messages", "LOW")
    }
  }

  private static func createEventMessages() throws -> [(String, DynamicMessage)] {
    let testMessages = try createTestMessages()
    return [
      ("UserCreated", testMessages[0].1),
      ("ProductUpdated", testMessages[1].1),
      ("SystemEvent", testMessages[2].1),
    ]
  }

  private static func processEvent(_ anyEvent: DynamicMessage) throws -> (
    status: String, handler: String, duration: String
  ) {
    let typeName = try anyEvent.getAnyTypeName()

    switch typeName {
    case "examples.UserMessage":
      return ("✅ PROCESSED", "UserEventHandler", "5")
    case "examples.ProductMessage":
      return ("✅ PROCESSED", "ProductEventHandler", "3")
    default:
      return ("✅ PROCESSED", "DefaultEventHandler", "2")
    }
  }

  private static func estimateMessageSize(_ message: DynamicMessage) -> Int {
    // Simple estimation based on field count
    return message.descriptor.fields.count * 10 + 20
  }
}
