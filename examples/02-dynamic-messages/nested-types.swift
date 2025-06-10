/**
 * 🏗️ SwiftProtoReflect Example: Nested Types (Enum inside Message)
 *
 * Description: Demonstration of nested enum and nested message inside Protocol Buffers messages
 * Key concepts: Nested Enum, Nested Message, Type hierarchies, Name resolution
 * Complexity: 🔧🔧 Advanced
 * Execution time: < 15 seconds
 *
 * What you'll learn:
 * - Creating enum inside message (nested enum)
 * - Creating message inside message (nested message)
 * - Proper naming and accessing nested types
 * - Using nested types in fields
 * - Nested type name resolution (ParentMessage.NestedType)
 *
 * Run:
 *   swift run NestedTypes
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct NestedTypesExample {
  static func main() throws {
    ExampleUtils.printHeader("Nested Types - Enum and Message inside Message")

    try step1UbasicNestedEnum()
    try step2UnestedMessage()
    try step3UcomplexHierarchy()
    try step4UnestedTypeAccess()
    try step5UrealWorldExample()

    ExampleUtils.printSuccess("You mastered working with nested types in Protocol Buffers!")

    ExampleUtils.printNext([
      "Next: message-cloning.swift - cloning complex structures",
      "Advanced: conditional-logic.swift - conditional logic based on types",
      "Explore: field-manipulation.swift - field manipulations",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1UbasicNestedEnum() throws {
    ExampleUtils.printStep(1, "Basic nested enum usage")

    let fileDescriptor = try createBasicNestedEnumStructure()
    let factory = MessageFactory()

    // Create message with nested enum
    guard let userDesc = fileDescriptor.messages.values.first(where: { $0.name == "User" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "User descriptor not found"])
    }

    var user = factory.createMessage(from: userDesc)
    try user.set("Alice Johnson", forField: "name")
    try user.set(Int32(1), forField: "status")  // ACTIVE = 1 (nested enum value)
    try user.set(Int32(2), forField: "role")  // ADMIN = 2 (nested enum value)

    print("  👤 Created User with nested enum fields:")
    print("    Name: \(try user.get(forField: "name") as? String ?? "Unknown")")

    let statusValue = try user.get(forField: "status") as? Int32 ?? 0
    let roleValue = try user.get(forField: "role") as? Int32 ?? 0

    print("    Status: \(statusValue) (\(getStatusName(statusValue)))")
    print("    Role: \(roleValue) (\(getRoleName(roleValue)))")

    // Demonstrate access to nested enum
    if let statusEnum = userDesc.nestedEnum(named: "Status") {
      print("  📋 Nested enum User.Status values:")
      for value in statusEnum.allValues() {
        print("    \(value.name) = \(value.number)")
      }
    }
  }

  private static func step2UnestedMessage() throws {
    ExampleUtils.printStep(2, "Nested message inside message")

    let fileDescriptor = try createNestedMessageStructure()
    let factory = MessageFactory()

    // Create parent message
    guard let companyDesc = fileDescriptor.messages.values.first(where: { $0.name == "Company" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Company descriptor not found"])
    }

    var company = factory.createMessage(from: companyDesc)
    try company.set("TechCorp Inc.", forField: "name")

    // Create nested message (Address)
    guard let addressDesc = companyDesc.nestedMessage(named: "Address") else {
      throw NSError(
        domain: "Example",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Address nested message not found"]
      )
    }

    var address = factory.createMessage(from: addressDesc)
    try address.set("123 Tech Street", forField: "street")
    try address.set("San Francisco", forField: "city")
    try address.set("CA", forField: "state")
    try address.set("94102", forField: "zip_code")

    // Set nested message in parent
    try company.set(address, forField: "headquarters")

    print("  🏢 Created Company with nested Address:")
    print("    Company: \(try company.get(forField: "name") as? String ?? "Unknown")")

    if let hq = try company.get(forField: "headquarters") as? DynamicMessage {
      print("    Address:")
      print("      Street: \(try hq.get(forField: "street") as? String ?? "Unknown")")
      print("      City: \(try hq.get(forField: "city") as? String ?? "Unknown")")
      print("      State: \(try hq.get(forField: "state") as? String ?? "Unknown")")
      print("      ZIP: \(try hq.get(forField: "zip_code") as? String ?? "Unknown")")
    }
  }

  private static func step3UcomplexHierarchy() throws {
    ExampleUtils.printStep(3, "Complex nested type hierarchy")

    let fileDescriptor = try createComplexHierarchyStructure()
    let factory = MessageFactory()

    // Create Document with nested Chapter and Section
    guard let documentDesc = fileDescriptor.messages.values.first(where: { $0.name == "Document" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document descriptor not found"])
    }

    var document = factory.createMessage(from: documentDesc)
    try document.set("Technical Manual", forField: "title")
    try document.set(Int32(1), forField: "type")  // MANUAL = 1 (nested enum)

    // Create Chapter (nested message)
    guard let chapterDesc = documentDesc.nestedMessage(named: "Chapter") else {
      throw NSError(
        domain: "Example",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Chapter nested message not found"]
      )
    }

    var chapter = factory.createMessage(from: chapterDesc)
    try chapter.set("Introduction", forField: "title")
    try chapter.set(Int32(1), forField: "number")

    // Create Section (nested in Chapter)
    guard let sectionDesc = chapterDesc.nestedMessage(named: "Section") else {
      throw NSError(
        domain: "Example",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Section nested message not found"]
      )
    }

    var section = factory.createMessage(from: sectionDesc)
    try section.set("Getting Started", forField: "title")
    try section.set("This section covers...", forField: "content")
    try section.set(Int32(2), forField: "importance")  // HIGH = 2 (nested enum in Section)

    // Assemble hierarchy
    try chapter.set([section], forField: "sections")
    try document.set([chapter], forField: "chapters")

    print("  📚 Created complex nested type hierarchy:")
    try printDocumentHierarchy(document)
  }

  private static func step4UnestedTypeAccess() throws {
    ExampleUtils.printStep(4, "Access to nested types and their metadata")

    let fileDescriptor = try createComplexHierarchyStructure()

    guard let documentDesc = fileDescriptor.messages.values.first(where: { $0.name == "Document" }) else {
      return
    }

    print("  🔍 Analysis of nested types in Document:")

    // Show nested enums
    print("    Nested Enums:")
    for (name, enumDesc) in documentDesc.nestedEnums {
      print("      Document.\(name):")
      for value in enumDesc.allValues() {
        print("        \(value.name) = \(value.number)")
      }
    }

    // Show nested messages
    print("    Nested Messages:")
    for (name, nestedDesc) in documentDesc.nestedMessages {
      print("      Document.\(name) (fields: \(nestedDesc.fields.count))")

      // Show nested types in nested message
      if !nestedDesc.nestedMessages.isEmpty {
        print("        Nested in \(name):")
        for (nestedName, _) in nestedDesc.nestedMessages {
          print("          Document.\(name).\(nestedName)")
        }
      }

      if !nestedDesc.nestedEnums.isEmpty {
        print("        Enums in \(name):")
        for (enumName, _) in nestedDesc.nestedEnums {
          print("          Document.\(name).\(enumName)")
        }
      }
    }
  }

  private static func step5UrealWorldExample() throws {
    ExampleUtils.printStep(5, "Real-world example: Order Management System")

    let fileDescriptor = try createOrderManagementStructure()
    let factory = MessageFactory()

    guard let orderDesc = fileDescriptor.messages.values.first(where: { $0.name == "Order" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Order descriptor not found"])
    }

    var order = factory.createMessage(from: orderDesc)
    try order.set("ORD-2024-001", forField: "order_id")
    try order.set(Int32(2), forField: "status")  // PROCESSING = 2
    try order.set(Int32(1), forField: "priority")  // HIGH = 1

    // Create Payment (nested message)
    guard let paymentDesc = orderDesc.nestedMessage(named: "Payment") else {
      throw NSError(
        domain: "Example",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Payment nested message not found"]
      )
    }

    var payment = factory.createMessage(from: paymentDesc)
    try payment.set(299.99, forField: "amount")
    try payment.set("USD", forField: "currency")
    try payment.set(Int32(1), forField: "method")  // CREDIT_CARD = 1 (nested enum in Payment)

    try order.set(payment, forField: "payment_info")

    let orderSummary = try analyzeOrder(order)
    ExampleUtils.printTable(orderSummary, title: "Order Management Analysis")

    print("  💡 Demonstrates real-world usage of nested types in business logic")
  }

  // MARK: - Structure Creation Methods

  private static func createBasicNestedEnumStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "nested_enum.proto", package: "example")

    var userDesc = MessageDescriptor(name: "User", parent: fileDescriptor)

    // Create nested enum Status inside User
    var statusEnum = EnumDescriptor(name: "Status", parent: userDesc)
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "INACTIVE", number: 2))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "SUSPENDED", number: 3))

    // Create nested enum Role inside User
    var roleEnum = EnumDescriptor(name: "Role", parent: userDesc)
    roleEnum.addValue(EnumDescriptor.EnumValue(name: "GUEST", number: 0))
    roleEnum.addValue(EnumDescriptor.EnumValue(name: "USER", number: 1))
    roleEnum.addValue(EnumDescriptor.EnumValue(name: "ADMIN", number: 2))

    // Add nested enums to message
    userDesc.addNestedEnum(statusEnum)
    userDesc.addNestedEnum(roleEnum)

    // Add fields that use nested enums
    userDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    userDesc.addField(FieldDescriptor(name: "status", number: 2, type: .int32))  // User.Status
    userDesc.addField(FieldDescriptor(name: "role", number: 3, type: .int32))  // User.Role

    fileDescriptor.addMessage(userDesc)
    return fileDescriptor
  }

  private static func createNestedMessageStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "nested_message.proto", package: "example")

    var companyDesc = MessageDescriptor(name: "Company", parent: fileDescriptor)

    // Create nested message Address inside Company
    var addressDesc = MessageDescriptor(name: "Address", parent: companyDesc)
    addressDesc.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addressDesc.addField(FieldDescriptor(name: "city", number: 2, type: .string))
    addressDesc.addField(FieldDescriptor(name: "state", number: 3, type: .string))
    addressDesc.addField(FieldDescriptor(name: "zip_code", number: 4, type: .string))

    // Add nested message to Company
    companyDesc.addNestedMessage(addressDesc)

    // Add fields to Company
    companyDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    companyDesc.addField(
      FieldDescriptor(
        name: "headquarters",
        number: 2,
        type: .message,
        typeName: "example.Company.Address"  // Full nested message name
      )
    )

    fileDescriptor.addMessage(companyDesc)
    return fileDescriptor
  }

  private static func createComplexHierarchyStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "complex_hierarchy.proto", package: "example")

    var documentDesc = MessageDescriptor(name: "Document", parent: fileDescriptor)

    // Nested enum DocumentType
    var docTypeEnum = EnumDescriptor(name: "DocumentType", parent: documentDesc)
    docTypeEnum.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    docTypeEnum.addValue(EnumDescriptor.EnumValue(name: "MANUAL", number: 1))
    docTypeEnum.addValue(EnumDescriptor.EnumValue(name: "TUTORIAL", number: 2))
    docTypeEnum.addValue(EnumDescriptor.EnumValue(name: "REFERENCE", number: 3))

    documentDesc.addNestedEnum(docTypeEnum)

    // Nested message Chapter
    var chapterDesc = MessageDescriptor(name: "Chapter", parent: documentDesc)
    chapterDesc.addField(FieldDescriptor(name: "title", number: 1, type: .string))
    chapterDesc.addField(FieldDescriptor(name: "number", number: 2, type: .int32))

    // Nested message Section inside Chapter (two-level nesting!)
    var sectionDesc = MessageDescriptor(name: "Section", parent: chapterDesc)

    // Nested enum Importance inside Section
    var importanceEnum = EnumDescriptor(name: "Importance", parent: sectionDesc)
    importanceEnum.addValue(EnumDescriptor.EnumValue(name: "LOW", number: 0))
    importanceEnum.addValue(EnumDescriptor.EnumValue(name: "MEDIUM", number: 1))
    importanceEnum.addValue(EnumDescriptor.EnumValue(name: "HIGH", number: 2))
    importanceEnum.addValue(EnumDescriptor.EnumValue(name: "CRITICAL", number: 3))

    sectionDesc.addNestedEnum(importanceEnum)
    sectionDesc.addField(FieldDescriptor(name: "title", number: 1, type: .string))
    sectionDesc.addField(FieldDescriptor(name: "content", number: 2, type: .string))
    sectionDesc.addField(FieldDescriptor(name: "importance", number: 3, type: .int32))  // Section.Importance

    chapterDesc.addNestedMessage(sectionDesc)
    chapterDesc.addField(
      FieldDescriptor(
        name: "sections",
        number: 3,
        type: .message,
        typeName: "example.Document.Chapter.Section",  // Three-level name!
        isRepeated: true
      )
    )

    documentDesc.addNestedMessage(chapterDesc)

    // Document fields
    documentDesc.addField(FieldDescriptor(name: "title", number: 1, type: .string))
    documentDesc.addField(FieldDescriptor(name: "type", number: 2, type: .int32))  // Document.DocumentType
    documentDesc.addField(
      FieldDescriptor(
        name: "chapters",
        number: 3,
        type: .message,
        typeName: "example.Document.Chapter",
        isRepeated: true
      )
    )

    fileDescriptor.addMessage(documentDesc)
    return fileDescriptor
  }

  private static func createOrderManagementStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "order_management.proto", package: "example")

    var orderDesc = MessageDescriptor(name: "Order", parent: fileDescriptor)

    // Nested enum OrderStatus
    var statusEnum = EnumDescriptor(name: "OrderStatus", parent: orderDesc)
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "PENDING", number: 0))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "CONFIRMED", number: 1))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "PROCESSING", number: 2))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "SHIPPED", number: 3))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "DELIVERED", number: 4))

    // Nested enum Priority
    var priorityEnum = EnumDescriptor(name: "Priority", parent: orderDesc)
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "STANDARD", number: 0))
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "HIGH", number: 1))
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "URGENT", number: 2))

    orderDesc.addNestedEnum(statusEnum)
    orderDesc.addNestedEnum(priorityEnum)

    // Nested message Payment
    var paymentDesc = MessageDescriptor(name: "Payment", parent: orderDesc)

    // Nested enum PaymentMethod inside Payment
    var paymentMethodEnum = EnumDescriptor(name: "PaymentMethod", parent: paymentDesc)
    paymentMethodEnum.addValue(EnumDescriptor.EnumValue(name: "CASH", number: 0))
    paymentMethodEnum.addValue(EnumDescriptor.EnumValue(name: "CREDIT_CARD", number: 1))
    paymentMethodEnum.addValue(EnumDescriptor.EnumValue(name: "DEBIT_CARD", number: 2))
    paymentMethodEnum.addValue(EnumDescriptor.EnumValue(name: "PAYPAL", number: 3))
    paymentMethodEnum.addValue(EnumDescriptor.EnumValue(name: "BANK_TRANSFER", number: 4))

    paymentDesc.addNestedEnum(paymentMethodEnum)
    paymentDesc.addField(FieldDescriptor(name: "amount", number: 1, type: .double))
    paymentDesc.addField(FieldDescriptor(name: "currency", number: 2, type: .string))
    paymentDesc.addField(FieldDescriptor(name: "method", number: 3, type: .int32))  // Payment.PaymentMethod

    orderDesc.addNestedMessage(paymentDesc)

    // Order fields
    orderDesc.addField(FieldDescriptor(name: "order_id", number: 1, type: .string))
    orderDesc.addField(FieldDescriptor(name: "status", number: 2, type: .int32))  // Order.OrderStatus
    orderDesc.addField(FieldDescriptor(name: "priority", number: 3, type: .int32))  // Order.Priority
    orderDesc.addField(
      FieldDescriptor(
        name: "payment_info",
        number: 4,
        type: .message,
        typeName: "example.Order.Payment"
      )
    )

    fileDescriptor.addMessage(orderDesc)
    return fileDescriptor
  }

  // MARK: - Helper Methods

  private static func getStatusName(_ value: Int32) -> String {
    switch value {
    case 0: return "UNKNOWN"
    case 1: return "ACTIVE"
    case 2: return "INACTIVE"
    case 3: return "SUSPENDED"
    default: return "INVALID"
    }
  }

  private static func getRoleName(_ value: Int32) -> String {
    switch value {
    case 0: return "GUEST"
    case 1: return "USER"
    case 2: return "ADMIN"
    default: return "INVALID"
    }
  }

  private static func printDocumentHierarchy(_ document: DynamicMessage) throws {
    let title = try document.get(forField: "title") as? String ?? "Untitled"
    let typeValue = try document.get(forField: "type") as? Int32 ?? 0
    let typeName = getDocumentTypeName(typeValue)

    print("    📄 Document: '\(title)' (Type: \(typeName))")

    if let chapters = try document.get(forField: "chapters") as? [DynamicMessage] {
      for chapter in chapters {
        let chapterTitle = try chapter.get(forField: "title") as? String ?? "Untitled"
        let chapterNumber = try chapter.get(forField: "number") as? Int32 ?? 0
        print("      📖 Chapter \(chapterNumber): '\(chapterTitle)'")

        if let sections = try chapter.get(forField: "sections") as? [DynamicMessage] {
          for section in sections {
            let sectionTitle = try section.get(forField: "title") as? String ?? "Untitled"
            let importance = try section.get(forField: "importance") as? Int32 ?? 0
            let importanceName = getImportanceName(importance)
            print("        📝 Section: '\(sectionTitle)' (Importance: \(importanceName))")
          }
        }
      }
    }
  }

  private static func getDocumentTypeName(_ value: Int32) -> String {
    switch value {
    case 0: return "UNKNOWN"
    case 1: return "MANUAL"
    case 2: return "TUTORIAL"
    case 3: return "REFERENCE"
    default: return "INVALID"
    }
  }

  private static func getImportanceName(_ value: Int32) -> String {
    switch value {
    case 0: return "LOW"
    case 1: return "MEDIUM"
    case 2: return "HIGH"
    case 3: return "CRITICAL"
    default: return "INVALID"
    }
  }

  private static func analyzeOrder(_ order: DynamicMessage) throws -> [String: String] {
    let orderId = try order.get(forField: "order_id") as? String ?? "Unknown"
    let statusValue = try order.get(forField: "status") as? Int32 ?? 0
    let priorityValue = try order.get(forField: "priority") as? Int32 ?? 0

    var result: [String: String] = [
      "Order ID": orderId,
      "Status": getOrderStatusName(statusValue),
      "Priority": getOrderPriorityName(priorityValue),
    ]

    if let payment = try order.get(forField: "payment_info") as? DynamicMessage {
      let amount = try payment.get(forField: "amount") as? Double ?? 0.0
      let currency = try payment.get(forField: "currency") as? String ?? "USD"
      let methodValue = try payment.get(forField: "method") as? Int32 ?? 0

      result["Payment Amount"] = "\(amount) \(currency)"
      result["Payment Method"] = getPaymentMethodName(methodValue)
    }

    return result
  }

  private static func getOrderStatusName(_ value: Int32) -> String {
    switch value {
    case 0: return "PENDING"
    case 1: return "CONFIRMED"
    case 2: return "PROCESSING"
    case 3: return "SHIPPED"
    case 4: return "DELIVERED"
    default: return "INVALID"
    }
  }

  private static func getOrderPriorityName(_ value: Int32) -> String {
    switch value {
    case 0: return "STANDARD"
    case 1: return "HIGH"
    case 2: return "URGENT"
    default: return "INVALID"
    }
  }

  private static func getPaymentMethodName(_ value: Int32) -> String {
    switch value {
    case 0: return "CASH"
    case 1: return "CREDIT_CARD"
    case 2: return "DEBIT_CARD"
    case 3: return "PAYPAL"
    case 4: return "BANK_TRANSFER"
    default: return "INVALID"
    }
  }
}
