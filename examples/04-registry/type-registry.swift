/**
 * SwiftProtoReflect Type Registry Example
 *
 * This example demonstrates working with Protocol Buffers type registry:
 *
 * 1. Creating types and working with TypeRegistry
 * 2. Looking up types by name
 * 3. Dynamic message creation
 * 4. Type analysis and structure exploration
 * 5. Working with type metadata
 *
 * Key concepts:
 * - TypeRegistry as type catalog
 * - Dynamic type resolution
 * - Type introspection and analysis
 * - Message factory pattern
 * - Type metadata exploration
 */

import ExampleUtils
import Foundation
@preconcurrency import SwiftProtoReflect

struct TypeRegistryExample {
  static func run() throws {
    ExampleUtils.printHeader("Type Registry Management")

    try step1_basicTypeCreationAndLookup()
    try step2_dynamicMessageCreation()
    try step3_typeIntrospectionAnalysis()
    try step4_registryOperationsDemo()
    try step5_messageFactoryPatterns()

    print("\n🎉 Type Registry management successfully explored!")

    print("\n🔍 What to try next:")
    print("  • Next explore: file-loading.swift - loading descriptor files")
    print("  • Compare: dependency-resolution.swift - dependency resolution")
    print("  • Advanced: schema-validation.swift - schema validation")
  }

  private static func step1_basicTypeCreationAndLookup() throws {
    ExampleUtils.printStep(1, "Basic type creation and lookup")

    print("  🏗 Creating types and basic Registry operations...")

    let _ = TypeRegistry()  // Registry示例

    // Create business domain types
    let businessTypes = try createBusinessTypes()

    print("  📝 Created types:")
    for (fileName, messages) in businessTypes {
      print("    📁 \(fileName):")
      for message in messages {
        print("      📋 \(message.fullName) (\(message.fields.count) fields)")

        // Show field details
        for field in message.fields.values.prefix(3) {
          let repeated = field.isRepeated ? " (repeated)" : ""
          print("        • \(field.name): \(field.type)\(repeated)")
        }
        if message.fields.count > 3 {
          print("        ... and \(message.fields.count - 3) more fields")
        }
      }
    }

    // Registry lookup simulation
    print("  🔍 Type lookup simulation:")

    // Simulate what registry.findMessage would do
    let allMessages = businessTypes.flatMap { $0.messages }
    let searchTargets = ["business.Person", "business.Company", "business.Product", "unknown.Type"]

    for target in searchTargets {
      if let found = allMessages.first(where: { $0.fullName == target }) {
        print("    ✅ Found \(target): \(found.fields.count) fields")
      }
      else {
        print("    ❌ Not found: \(target)")
      }
    }

    // Type statistics
    let stats = calculateTypeStatistics(allMessages)
    print("  📊 Type statistics:")
    print("    Total messages: \(stats.totalMessages)")
    print("    Total fields: \(stats.totalFields)")
    print("    Average fields per message: \(String(format: "%.1f", stats.averageFields))")
    print("    Field type distribution:")
    for (fieldType, count) in stats.fieldTypeDistribution.sorted(by: { $0.value > $1.value }) {
      print("      \(fieldType): \(count)")
    }
  }

  private static func step2_dynamicMessageCreation() throws {
    ExampleUtils.printStep(2, "Dynamic message creation")

    print("  🎯 Динамическое создание сообщений по типам...")

    let _ = TypeRegistry()  // Registry для демонстрации
    let factory = MessageFactory()

    // Create types for demonstration
    let businessTypes = try createBusinessTypes()
    let allMessages = businessTypes.flatMap { $0.messages }

    print("  🏭 Message Factory demonstration:")

    for messageDesc in allMessages {
      print("    📋 Creating \(messageDesc.name):")

      // Create message from descriptor
      var message = factory.createMessage(from: messageDesc)

      // Populate with sample data
      try populateMessageWithSampleData(&message, descriptor: messageDesc)

      // Show created message info
      print("      Fields populated: \(messageDesc.fields.count)")
      for field in messageDesc.fields.values.prefix(3) {
        do {
          let hasValue = try message.hasValue(forField: field.name)
          if hasValue {
            let value = try message.get(forField: field.name)
            print("        \(field.name): \(String(describing: value))")
          }
          else {
            print("        \(field.name): <not set>")
          }
        }
        catch {
          print("        \(field.name): <error: \(error)>")
        }
      }

      // Validate message structure
      let isValid = try validateMessage(message, descriptor: messageDesc)
      print("      Validation: \(isValid ? "✅ PASSED" : "❌ FAILED")")
    }

    // Performance test
    print("  ⚡ Performance test:")

    let testDescriptor = allMessages.first!
    let (_, creationTime) = ExampleUtils.measureTime {
      for _ in 0..<1000 {
        let _ = factory.createMessage(from: testDescriptor)
      }
    }

    ExampleUtils.printTiming("1000 message creations", time: creationTime)
    let creationRate = 1000.0 / creationTime
    print("    Creation rate: \(String(format: "%.1f", creationRate)) messages/sec")
  }

  private static func step3_typeIntrospectionAnalysis() throws {
    ExampleUtils.printStep(3, "Type introspection and analysis")

    print("  🔬 Глубокий анализ структуры типов...")

    let businessTypes = try createBusinessTypes()
    let allMessages = businessTypes.flatMap { $0.messages }

    // Field analysis
    print("  📊 Field analysis:")

    var fieldTypeCount: [FieldType: Int] = [:]
    var repeatedFieldCount = 0
    var optionalFieldCount = 0

    for message in allMessages {
      for field in message.fields.values {
        fieldTypeCount[field.type, default: 0] += 1

        if field.isRepeated {
          repeatedFieldCount += 1
        }
        else {
          optionalFieldCount += 1
        }
      }
    }

    print("    Field type usage:")
    for (fieldType, count) in fieldTypeCount.sorted(by: { $0.value > $1.value }) {
      print("      \(fieldType): \(count) occurrences")
    }

    print("    Field characteristics:")
    print("      Repeated fields: \(repeatedFieldCount)")
    print("      Single fields: \(optionalFieldCount)")

    // Message complexity analysis
    print("  🧮 Message complexity analysis:")

    let complexityStats = analyzeMessageComplexity(allMessages)
    print("    Simple messages (1-3 fields): \(complexityStats.simple)")
    print("    Medium messages (4-8 fields): \(complexityStats.medium)")
    print("    Complex messages (9+ fields): \(complexityStats.complex)")

    // Namespace analysis
    print("  🏢 Namespace analysis:")

    let namespaces = extractNamespacesFromMessages(allMessages)
    for namespace in namespaces {
      let messageCount = allMessages.filter { $0.fullName.hasPrefix(namespace + ".") }.count
      print("    \(namespace): \(messageCount) messages")
    }

    // Detailed field inspection
    print("  🔍 Detailed field inspection:")

    for message in allMessages.prefix(2) {
      print("    📋 \(message.name) field details:")
      for field in message.fields.values {
        let characteristics = analyzeFieldCharacteristics(field)
        print("      \(field.name) (\(field.type)):")
        print("        Number: \(field.number)")
        print("        Repeated: \(field.isRepeated)")
        print("        Characteristics: \(characteristics.joined(separator: ", "))")
      }
    }
  }

  private static func step4_registryOperationsDemo() throws {
    ExampleUtils.printStep(4, "Registry operations demonstration")

    print("  🗂 Демонстрация операций с реестром типов...")

    // Create sample type collection
    let typeCollection = try createExtendedTypeCollection()

    print("  📚 Type collection overview:")
    print("    Categories: \(typeCollection.count)")

    for (category, types) in typeCollection {
      print("    \(category): \(types.count) types")
      for type in types.prefix(3) {
        print("      • \(type.name)")
      }
      if types.count > 3 {
        print("      ... и ещё \(types.count - 3)")
      }
    }

    // Search and filtering operations
    print("  🔎 Search and filtering operations:")

    let allTypes = typeCollection.values.flatMap { $0 }

    // Search by pattern
    let searchPatterns = ["User", "Order", "Product"]
    for pattern in searchPatterns {
      let matches = allTypes.filter { $0.name.contains(pattern) }
      print("    Pattern '\(pattern)': \(matches.count) matches")
    }

    // Filter by complexity
    let complexTypes = allTypes.filter { $0.fields.count >= 5 }
    print("    Complex types (5+ fields): \(complexTypes.count)")

    let simpleTypes = allTypes.filter { $0.fields.count <= 3 }
    print("    Simple types (≤3 fields): \(simpleTypes.count)")

    // Filter by field types
    let messagesWithStringFields = allTypes.filter { message in
      message.fields.values.contains { $0.type == .string }
    }
    print("    Messages with string fields: \(messagesWithStringFields.count)")

    // Bulk operations simulation
    print("  🚀 Bulk operations simulation:")

    let (_, bulkTime) = ExampleUtils.measureTime {
      // Simulate processing all types
      for type in allTypes {
        // Simulate some processing
        _ = type.fields.count
        _ = type.name.count
      }
    }

    ExampleUtils.printTiming("Process \(allTypes.count) types", time: bulkTime)
    let processingRate = Double(allTypes.count) / bulkTime
    print("    Processing rate: \(String(format: "%.1f", processingRate)) types/sec")
  }

  private static func step5_messageFactoryPatterns() throws {
    ExampleUtils.printStep(5, "Message factory patterns")

    print("  🏭 Продвинутые паттерны Message Factory...")

    let factory = MessageFactory()
    let businessTypes = try createBusinessTypes()
    let testMessage = businessTypes.flatMap { $0.messages }.first!

    // Pattern 1: Template-based creation
    print("  📋 Template-based creation:")

    let templates = createMessageTemplates()
    for (templateName, template) in templates {
      print("    Template '\(templateName)':")

      var message = factory.createMessage(from: testMessage)
      try applyTemplate(&message, template: template)

      print("      Applied \(template.values.count) field values")
      print("      Template type: \(template.templateType)")
    }

    // Pattern 2: Builder pattern simulation
    print("  🔧 Builder pattern simulation:")

    let builder = MessageBuilder(descriptor: testMessage, factory: factory)
    let builtMessage =
      try builder
      .setString("Builder User", forField: "name")
      .setInt64(12345, forField: "id")
      .setString("builder@example.com", forField: "email")
      .build()

    print("    ✅ Builder pattern message created")
    print("    Fields set: \(builder.getSetFieldsCount())")

    // Validate the built message was created successfully
    do {
      let hasName = try builtMessage.hasValue(forField: "name")
      print("    Message validation: \(hasName ? "✅ Valid" : "❌ Invalid")")
    }
    catch {
      print("    Message validation: ❌ Error - \(error)")
    }

    // Pattern 3: Cloning and modification
    print("  🔄 Cloning and modification:")

    var originalMessage = factory.createMessage(from: testMessage)
    try populateMessageWithSampleData(&originalMessage, descriptor: testMessage)

    // Manual cloning simulation
    var cloned = factory.createMessage(from: testMessage)
    for field in testMessage.fields.values {
      do {
        if try originalMessage.hasValue(forField: field.name) {
          if let value = try originalMessage.get(forField: field.name) {
            try cloned.set(value, forField: field.name)
          }
        }
      }
      catch {
        // Skip fields that can't be cloned
      }
    }
    print("    ✅ Message cloned manually")

    // Modify clone
    do {
      try cloned.set("Modified User", forField: "name")
      print("    ✅ Clone modified")
    }
    catch {
      print("    ❌ Clone modification failed: \(error)")
    }

    // Pattern 4: Batch creation
    print("  📦 Batch creation:")

    let (batchMessages, batchTime) = ExampleUtils.measureTime {
      var messages: [DynamicMessage] = []
      for i in 0..<100 {
        var message = factory.createMessage(from: testMessage)
        do {
          try message.set("Batch User \(i)", forField: "name")
          try message.set(Int64(i), forField: "id")
          messages.append(message)
        }
        catch {
          // Handle error
        }
      }
      return messages
    }

    ExampleUtils.printTiming("Batch creation (100 messages)", time: batchTime)
    print("    Created messages: \(batchMessages.count)")
    print("    Average time per message: \(String(format: "%.3f", batchTime * 1000 / 100))ms")
  }

  // MARK: - Helper Methods and Types

  static func createBusinessTypes() throws -> [(fileName: String, messages: [MessageDescriptor])] {
    var results: [(String, [MessageDescriptor])] = []

    // Business types
    var businessFile = FileDescriptor(name: "business.proto", package: "business")

    // Person message
    var personMessage = MessageDescriptor(name: "Person", parent: businessFile)
    personMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    personMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    personMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))
    personMessage.addField(FieldDescriptor(name: "age", number: 4, type: .int32))

    // Company message
    var companyMessage = MessageDescriptor(name: "Company", parent: businessFile)
    companyMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    companyMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    companyMessage.addField(FieldDescriptor(name: "industry", number: 3, type: .string))
    companyMessage.addField(FieldDescriptor(name: "employee_count", number: 4, type: .int32))
    companyMessage.addField(FieldDescriptor(name: "public", number: 5, type: .bool))

    // Product message
    var productMessage = MessageDescriptor(name: "Product", parent: businessFile)
    productMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    productMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    productMessage.addField(FieldDescriptor(name: "price", number: 3, type: .double))
    productMessage.addField(FieldDescriptor(name: "category", number: 4, type: .string))
    productMessage.addField(FieldDescriptor(name: "tags", number: 5, type: .string, isRepeated: true))
    productMessage.addField(FieldDescriptor(name: "in_stock", number: 6, type: .bool))

    businessFile.addMessage(personMessage)
    businessFile.addMessage(companyMessage)
    businessFile.addMessage(productMessage)

    results.append(("business.proto", [personMessage, companyMessage, productMessage]))

    return results
  }

  private static func createExtendedTypeCollection() throws -> [String: [MessageDescriptor]] {
    var collection: [String: [MessageDescriptor]] = [:]

    // Business types
    let businessTypes = try createBusinessTypes()
    collection["Business"] = businessTypes.flatMap { $0.messages }

    // User management types
    var userFile = FileDescriptor(name: "user.proto", package: "user")

    var user = MessageDescriptor(name: "User", parent: userFile)
    user.addField(FieldDescriptor(name: "user_id", number: 1, type: .string))
    user.addField(FieldDescriptor(name: "username", number: 2, type: .string))
    user.addField(FieldDescriptor(name: "email", number: 3, type: .string))
    user.addField(FieldDescriptor(name: "active", number: 4, type: .bool))

    var userProfile = MessageDescriptor(name: "UserProfile", parent: userFile)
    userProfile.addField(FieldDescriptor(name: "display_name", number: 1, type: .string))
    userProfile.addField(FieldDescriptor(name: "bio", number: 2, type: .string))
    userProfile.addField(FieldDescriptor(name: "avatar_url", number: 3, type: .string))

    userFile.addMessage(user)
    userFile.addMessage(userProfile)

    collection["User Management"] = [user, userProfile]

    // Order processing types
    var orderFile = FileDescriptor(name: "order.proto", package: "order")

    var order = MessageDescriptor(name: "Order", parent: orderFile)
    order.addField(FieldDescriptor(name: "order_id", number: 1, type: .string))
    order.addField(FieldDescriptor(name: "customer_id", number: 2, type: .string))
    order.addField(FieldDescriptor(name: "total", number: 3, type: .double))
    order.addField(FieldDescriptor(name: "status", number: 4, type: .string))
    order.addField(FieldDescriptor(name: "items", number: 5, type: .string, isRepeated: true))

    var orderItem = MessageDescriptor(name: "OrderItem", parent: orderFile)
    orderItem.addField(FieldDescriptor(name: "product_id", number: 1, type: .string))
    orderItem.addField(FieldDescriptor(name: "quantity", number: 2, type: .int32))
    orderItem.addField(FieldDescriptor(name: "unit_price", number: 3, type: .double))

    orderFile.addMessage(order)
    orderFile.addMessage(orderItem)

    collection["Order Processing"] = [order, orderItem]

    return collection
  }
}

// MARK: - Supporting Types and Functions

struct TypeStatistics {
  let totalMessages: Int
  let totalFields: Int
  let averageFields: Double
  let fieldTypeDistribution: [String: Int]
}

struct ComplexityStats {
  let simple: Int
  let medium: Int
  let complex: Int
}

struct MessageTemplate {
  let templateType: String
  let values: [String: Any]
}

class MessageBuilder {
  private let descriptor: MessageDescriptor
  private let factory: MessageFactory
  private var message: DynamicMessage
  private var setFields: Set<String> = []

  init(descriptor: MessageDescriptor, factory: MessageFactory) {
    self.descriptor = descriptor
    self.factory = factory
    self.message = factory.createMessage(from: descriptor)
  }

  func setString(_ value: String, forField fieldName: String) throws -> MessageBuilder {
    try message.set(value, forField: fieldName)
    setFields.insert(fieldName)
    return self
  }

  func setInt64(_ value: Int64, forField fieldName: String) throws -> MessageBuilder {
    try message.set(value, forField: fieldName)
    setFields.insert(fieldName)
    return self
  }

  func build() throws -> DynamicMessage {
    return message
  }

  func getSetFieldsCount() -> Int {
    return setFields.count
  }
}

func calculateTypeStatistics(_ messages: [MessageDescriptor]) -> TypeStatistics {
  let totalMessages = messages.count
  let totalFields = messages.reduce(0) { $0 + $1.fields.count }
  let averageFields = totalFields > 0 ? Double(totalFields) / Double(totalMessages) : 0.0

  var fieldTypeDistribution: [String: Int] = [:]

  for message in messages {
    for field in message.fields.values {
      let typeName = "\(field.type)"
      fieldTypeDistribution[typeName, default: 0] += 1
    }
  }

  return TypeStatistics(
    totalMessages: totalMessages,
    totalFields: totalFields,
    averageFields: averageFields,
    fieldTypeDistribution: fieldTypeDistribution
  )
}

func populateMessageWithSampleData(_ message: inout DynamicMessage, descriptor: MessageDescriptor) throws {
  for field in descriptor.fields.values {
    switch field.type {
    case .string:
      if field.isRepeated {
        try message.set(["Sample1", "Sample2"], forField: field.name)
      }
      else {
        try message.set("Sample \(field.name)", forField: field.name)
      }
    case .int32:
      try message.set(Int32.random(in: 1...1000), forField: field.name)
    case .int64:
      try message.set(Int64.random(in: 1...10000), forField: field.name)
    case .double:
      try message.set(Double.random(in: 1.0...100.0), forField: field.name)
    case .bool:
      try message.set(Bool.random(), forField: field.name)
    default:
      // Skip unsupported types for this example
      break
    }
  }
}

func validateMessage(_ message: DynamicMessage, descriptor: MessageDescriptor) throws -> Bool {
  // Simplified validation
  for field in descriptor.fields.values where !field.isRepeated {
    let hasValue = try message.hasValue(forField: field.name)
    if !hasValue {
      return false
    }
  }
  return true
}

func analyzeMessageComplexity(_ messages: [MessageDescriptor]) -> ComplexityStats {
  var simple = 0
  var medium = 0
  var complex = 0

  for message in messages {
    let fieldCount = message.fields.count
    if fieldCount <= 3 {
      simple += 1
    }
    else if fieldCount <= 8 {
      medium += 1
    }
    else {
      complex += 1
    }
  }

  return ComplexityStats(simple: simple, medium: medium, complex: complex)
}

func extractNamespacesFromMessages(_ messages: [MessageDescriptor]) -> [String] {
  var namespaces: Set<String> = []

  for message in messages {
    let fullName = message.fullName
    if let lastDotIndex = fullName.lastIndex(of: ".") {
      let namespace = String(fullName[..<lastDotIndex])
      namespaces.insert(namespace)
    }
  }

  return Array(namespaces).sorted()
}

func analyzeFieldCharacteristics(_ field: FieldDescriptor) -> [String] {
  var characteristics: [String] = []

  if field.isRepeated {
    characteristics.append("repeated")
  }

  if field.number <= 15 {
    characteristics.append("efficient encoding")
  }

  switch field.type {
  case .string:
    characteristics.append("variable length")
  case .int32, .int64:
    characteristics.append("varint encoded")
  case .double:
    characteristics.append("fixed 8 bytes")
  case .bool:
    characteristics.append("single bit")
  default:
    characteristics.append("complex type")
  }

  return characteristics
}

func createMessageTemplates() -> [String: MessageTemplate] {
  return [
    "Person": MessageTemplate(
      templateType: "Business Entity",
      values: [
        "id": Int64(1),
        "name": "Template Person",
        "email": "template@example.com",
        "age": Int32(25),
      ]
    ),
    "Company": MessageTemplate(
      templateType: "Organization",
      values: [
        "id": Int64(100),
        "name": "Template Corp",
        "industry": "Technology",
        "employee_count": Int32(50),
        "public": true,
      ]
    ),
  ]
}

func applyTemplate(_ message: inout DynamicMessage, template: MessageTemplate) throws {
  for (fieldName, value) in template.values {
    do {
      try message.set(value, forField: fieldName)
    }
    catch {
      // Ignore field errors for this demo
    }
  }
}

// MARK: - Main Execution

do {
  try TypeRegistryExample.run()
}
catch {
  print("❌ Error: \(error)")
  exit(1)
}
