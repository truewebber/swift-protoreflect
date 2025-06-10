/**
 * 🔍 SwiftProtoReflect Example: Basic Descriptors and Metadata
 *
 * Description: Detailed work with descriptors for metadata extraction and navigation
 * Key concepts: Descriptors, Metadata, Field Navigation, Type Introspection
 * Complexity: 🔧 Intermediate
 * Execution time: < 15 seconds
 *
 * What you'll learn:
 * - Navigation through FileDescriptor -> MessageDescriptor -> FieldDescriptor hierarchy
 * - Extracting detailed information about fields and their types
 * - Working with EnumDescriptor and its values
 * - Message structure introspection
 * - Analysis of dependencies and relationships between types
 *
 * Run:
 *   swift run BasicDescriptors
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct BasicDescriptorsExample {
  static func main() throws {
    ExampleUtils.printHeader("Descriptors and metadata - detailed introspection")

    try step1UfileDescriptorNavigation()
    try step2UmessageDescriptorDetails()
    try step3UfieldDescriptorAnalysis()
    try step4UenumDescriptorExploration()
    try step5UtypeRelationships()

    ExampleUtils.printSuccess("You mastered working with Protocol Buffers descriptors and metadata!")

    ExampleUtils.printNext([
      "Next: complex-messages.swift - advanced dynamic messages",
      "Category 02: dynamic-messages.swift - complex message operations",
      "Explore: serialization-basics.swift - serialization and deserialization",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1UfileDescriptorNavigation() throws {
    ExampleUtils.printStep(1, "FileDescriptor navigation")

    let fileDescriptor = try createComprehensiveFileStructure()

    // Analyze basic file information
    ExampleUtils.printTable(
      [
        "File Name": fileDescriptor.name,
        "Package": fileDescriptor.package,
        "Full Package Name": "\(fileDescriptor.package).\(fileDescriptor.name)",
        "Messages Count": "\(fileDescriptor.messages.count)",
        "Enums Count": "\(fileDescriptor.enums.count)",
      ],
      title: "File Descriptor Info"
    )

    print("\n  🏗  File structure:")

    // Navigate through messages
    print("    📋 Messages:")
    for message in fileDescriptor.messages.values {
      print("      • \(message.name) (\(message.fields.count) fields)")
    }

    // Navigate through enums
    print("    🏷  Enums:")
    for enumDesc in fileDescriptor.enums.values {
      print("      • \(enumDesc.name) (\(enumDesc.allValues().count) values)")
    }

    // Demonstrate search by name
    if let userMessage = fileDescriptor.messages.values.first(where: { $0.name == "User" }) {
      print("\n  🔍 Found User message:")
      print("      Full name: \(userMessage.fullName)")
      print("      Parent file: \(fileDescriptor.name)")
    }
  }

  private static func step2UmessageDescriptorDetails() throws {
    ExampleUtils.printStep(2, "Detailed MessageDescriptor analysis")

    let fileDescriptor = try createComprehensiveFileStructure()

    guard let userMessage = fileDescriptor.messages.values.first(where: { $0.name == "User" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "User message not found"])
    }

    print("  📋 User message analysis:")

    // Basic information
    ExampleUtils.printTable(
      [
        "Name": userMessage.name,
        "Full Name": userMessage.fullName,
        "Fields Count": "\(userMessage.fields.count)",
        "Parent Type": "FileDescriptor",
      ],
      title: "Message Details"
    )

    // Analyze fields by types
    var fieldsByType: [String: [FieldDescriptor]] = [:]
    for field in userMessage.fields.values {
      let typeName = "\(field.type)"
      if fieldsByType[typeName] == nil {
        fieldsByType[typeName] = []
      }
      fieldsByType[typeName]?.append(field)
    }

    print("\n    📊 Fields by type:")
    for (type, fields) in fieldsByType.sorted(by: { $0.key < $1.key }) {
      print("      \(type): \(fields.map { $0.name }.joined(separator: ", "))")
    }

    // Find special fields
    let repeatedFields = userMessage.fields.values.filter { $0.isRepeated }
    let oneofFields = userMessage.fields.values.filter { $0.oneofIndex != nil }

    if !repeatedFields.isEmpty {
      print("    🔄 Repeated fields: \(repeatedFields.map { $0.name }.joined(separator: ", "))")
    }

    if !oneofFields.isEmpty {
      print("    🔀 OneOf fields: \(oneofFields.map { $0.name }.joined(separator: ", "))")
    }
  }

  private static func step3UfieldDescriptorAnalysis() throws {
    ExampleUtils.printStep(3, "FieldDescriptor analysis")

    let fileDescriptor = try createComprehensiveFileStructure()

    guard let userMessage = fileDescriptor.messages.values.first(where: { $0.name == "User" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "User message not found"])
    }

    print("  🔍 Detailed User fields analysis:")

    // Create table with information about each field
    var fieldData: [String: String] = [:]

    for field in userMessage.fields.values.sorted(by: { $0.number < $1.number }) {
      var details: [String] = []

      details.append("Type: \(field.type)")
      details.append("Number: \(field.number)")

      if field.isRepeated {
        details.append("Repeated: ✅")
      }

      if let oneofIndex = field.oneofIndex {
        details.append("OneOf: group \(oneofIndex)")
      }

      if let typeName = field.typeName, !typeName.isEmpty {
        details.append("TypeName: \(typeName)")
      }

      if let defaultValue = field.defaultValue {
        details.append("Default: \(defaultValue)")
      }

      fieldData[field.name] = details.joined(separator: ", ")
    }

    ExampleUtils.printTable(fieldData, title: "Field Details")

    // Demonstrate field search by number
    if let fieldByNumber = userMessage.fields.values.first(where: { $0.number == 1 }) {
      print("\n  🎯 Field with number 1: \(fieldByNumber.name) (\(fieldByNumber.type))")
    }

    // Analyze message fields
    let messageFields = userMessage.fields.values.filter { $0.type == .message }
    if !messageFields.isEmpty {
      print("\n  🏗  Message fields:")
      for field in messageFields {
        print("      • \(field.name) -> \(field.typeName ?? "unknown")")
      }
    }
  }

  private static func step4UenumDescriptorExploration() throws {
    ExampleUtils.printStep(4, "EnumDescriptor exploration")

    let fileDescriptor = try createComprehensiveFileStructure()

    guard let statusEnum = fileDescriptor.enums.values.first(where: { $0.name == "UserStatus" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "UserStatus enum not found"])
    }

    print("  🏷  UserStatus enum analysis:")

    // Basic enum information
    ExampleUtils.printTable(
      [
        "Name": statusEnum.name,
        "Full Name": statusEnum.fullName,
        "Values Count": "\(statusEnum.allValues().count)",
        "Parent": fileDescriptor.name,
      ],
      title: "Enum Details"
    )

    // Analyze enum values
    print("\n    📊 Enum Values:")
    for enumValue in statusEnum.allValues().sorted(by: { $0.number < $1.number }) {
      print("      \(enumValue.name) = \(enumValue.number)")
    }

    // Find value by number
    if let valueByNumber = statusEnum.allValues().first(where: { $0.number == 1 }) {
      print("\n  🎯 Value with number 1: \(valueByNumber.name)")
    }

    // Find value by name
    if let valueByName = statusEnum.allValues().first(where: { $0.name == "ACTIVE" }) {
      print("  🎯 Value 'ACTIVE': number \(valueByName.number)")
    }

    // Demonstrate enum usage in field
    guard let userMessage = fileDescriptor.messages.values.first(where: { $0.name == "User" }) else {
      return
    }

    let enumFields = userMessage.fields.values.filter { $0.type == .enum }
    if let statusField = enumFields.first(where: { $0.name == "status" }) {
      print("\n  🔗 Status field linked to enum: \(statusField.typeName ?? "unknown")")
    }
  }

  private static func step5UtypeRelationships() throws {
    ExampleUtils.printStep(5, "Type relationship analysis")

    let fileDescriptor = try createComprehensiveFileStructure()

    print("  🕸  Type dependency graph:")

    // Analyze relationships between messages
    for message in fileDescriptor.messages.values {
      let messageFields = message.fields.values.filter { $0.type == .message }

      if !messageFields.isEmpty {
        print("\n    📋 \(message.name) references:")
        for field in messageFields {
          let referencedType = field.typeName?.components(separatedBy: ".").last ?? "unknown"
          print("      • \(field.name) -> \(referencedType)")
        }
      }
    }

    // Analyze enum usage
    print("\n  🏷  Enum Usage:")
    for message in fileDescriptor.messages.values {
      let enumFields = message.fields.values.filter { $0.type == .enum }

      if !enumFields.isEmpty {
        print("    📋 \(message.name) uses enums:")
        for field in enumFields {
          let enumType = field.typeName?.components(separatedBy: ".").last ?? "unknown"
          print("      • \(field.name) -> \(enumType)")
        }
      }
    }

    // Type usage statistics
    var typeUsage: [String: Int] = [:]
    for message in fileDescriptor.messages.values {
      for field in message.fields.values {
        let typeName = "\(field.type)"
        typeUsage[typeName, default: 0] += 1
      }
    }

    print("\n  📊 Type usage statistics:")
    for (type, count) in typeUsage.sorted(by: { $0.value > $1.value }) {
      print("      \(type): \(count) fields")
    }

    ExampleUtils.printInfo("Descriptor analysis allows understanding data structure without creating messages")
  }

  // MARK: - Helper Methods

  private static func createComprehensiveFileStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "comprehensive.proto", package: "example")

    // Create UserStatus enum
    var userStatusEnum = EnumDescriptor(name: "UserStatus", parent: fileDescriptor)
    userStatusEnum.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    userStatusEnum.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    userStatusEnum.addValue(EnumDescriptor.EnumValue(name: "INACTIVE", number: 2))
    userStatusEnum.addValue(EnumDescriptor.EnumValue(name: "SUSPENDED", number: 3))

    // Create Priority enum
    var priorityEnum = EnumDescriptor(name: "Priority", parent: fileDescriptor)
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "LOW", number: 0))
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "NORMAL", number: 1))
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "HIGH", number: 2))
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "URGENT", number: 3))

    // Create Address message
    var addressDescriptor = MessageDescriptor(name: "Address", parent: fileDescriptor)
    addressDescriptor.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "city", number: 2, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "postal_code", number: 3, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "country", number: 4, type: .string, defaultValue: "Unknown"))

    // Create Contact message with OneOf fields
    var contactDescriptor = MessageDescriptor(name: "Contact", parent: fileDescriptor)
    contactDescriptor.addField(FieldDescriptor(name: "email", number: 1, type: .string, oneofIndex: 0))
    contactDescriptor.addField(FieldDescriptor(name: "phone", number: 2, type: .string, oneofIndex: 0))
    contactDescriptor.addField(FieldDescriptor(name: "social_media", number: 3, type: .string, oneofIndex: 0))

    // Create main User message
    var userDescriptor = MessageDescriptor(name: "User", parent: fileDescriptor)
    userDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    userDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    userDescriptor.addField(FieldDescriptor(name: "email", number: 3, type: .string))
    userDescriptor.addField(FieldDescriptor(name: "age", number: 4, type: .int32, defaultValue: Int32(0)))
    userDescriptor.addField(
      FieldDescriptor(
        name: "status",
        number: 5,
        type: .enum,
        typeName: "example.UserStatus",
        defaultValue: Int32(0)
      )
    )
    userDescriptor.addField(
      FieldDescriptor(
        name: "address",
        number: 6,
        type: .message,
        typeName: "example.Address"
      )
    )
    userDescriptor.addField(
      FieldDescriptor(
        name: "contacts",
        number: 7,
        type: .message,
        typeName: "example.Contact",
        isRepeated: true
      )
    )
    userDescriptor.addField(FieldDescriptor(name: "tags", number: 8, type: .string, isRepeated: true))
    userDescriptor.addField(
      FieldDescriptor(
        name: "priority",
        number: 9,
        type: .enum,
        typeName: "example.Priority",
        defaultValue: Int32(1)
      )
    )
    userDescriptor.addField(FieldDescriptor(name: "is_verified", number: 10, type: .bool, defaultValue: false))

    // Add all types to file
    fileDescriptor.addEnum(userStatusEnum)
    fileDescriptor.addEnum(priorityEnum)
    fileDescriptor.addMessage(addressDescriptor)
    fileDescriptor.addMessage(contactDescriptor)
    fileDescriptor.addMessage(userDescriptor)

    return fileDescriptor
  }
}
