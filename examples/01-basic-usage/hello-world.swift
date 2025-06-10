/**
 * 🚀 SwiftProtoReflect Example: Hello World
 *
 * Description: Simplest example of creating dynamic Protocol Buffers message
 * Key concepts: FileDescriptor, MessageDescriptor, DynamicMessage, FieldDescriptor
 * Complexity: 🔰 Beginner
 * Execution time: < 5 seconds
 *
 * What you'll learn:
 * - Creating file descriptor (FileDescriptor)
 * - Defining message with fields (MessageDescriptor)
 * - Creating dynamic message instance (DynamicMessage)
 * - Setting and reading field values
 * - Basics of working with TypeRegistry
 *
 * Run:
 *   swift run HelloWorld
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct HelloWorldExample {
  static func main() throws {
    ExampleUtils.printHeader("Hello World - First introduction to SwiftProtoReflect")

    try step1CreateFileDescriptor()
    try step2DefinePersonMessage()
    try step3CreateMessageInstance()
    try step4WorkWithData()
    try step5UseTypeRegistry()

    ExampleUtils.printSuccess("Congratulations! You created your first dynamic Protocol Buffers message.")

    ExampleUtils.printNext([
      "Next try: swift run FieldTypes - all Protocol Buffers field types",
      "Or explore: simple-message.swift - creating more complex message",
      "Advanced: basic-descriptors.swift - detailed work with descriptors",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1CreateFileDescriptor() throws {
    ExampleUtils.printStep(1, "Creating file descriptor")

    // Create file descriptor - foundation for all our types
    let fileDescriptor = FileDescriptor(name: "hello.proto", package: "example")
    print("  📄 File created: \(fileDescriptor.name)")
    print("  📦 Package: \(fileDescriptor.package)")
    print("  🔗 Full name: \(fileDescriptor.name)")
  }

  private static func step2DefinePersonMessage() throws {
    ExampleUtils.printStep(2, "Defining Person message")

    // Create file descriptor
    var fileDescriptor = FileDescriptor(name: "hello.proto", package: "example")

    // Create Person message descriptor
    var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)

    // Add fields to message
    personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    personMessage.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
    personMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))

    print("  👤 Message created: \(personMessage.name)")
    print("  🏷  Fields: \(personMessage.fields.values.map { "\($0.name):\($0.type)" }.joined(separator: ", "))")
    print("  📍 Full name: \(personMessage.fullName)")

    // Register message in file
    fileDescriptor.addMessage(personMessage)
    print("  ✅ Message registered in file \(fileDescriptor.name)")
  }

  private static func step3CreateMessageInstance() throws {
    ExampleUtils.printStep(3, "Creating dynamic message instance")

    // Recreate structure (in real code this would be extracted to separate method)
    let (messageDescriptor, _) = try createPersonMessageDescriptor()

    // Create message factory
    let factory = MessageFactory()
    let person = factory.createMessage(from: messageDescriptor)

    print("  🏗  Message instance created: \(person.descriptor.name)")
    print("  🔍 Number of fields: \(person.descriptor.fields.count)")
    print("  📋 Available fields: \(person.descriptor.fields.values.map { $0.name }.joined(separator: ", "))")
  }

  private static func step4WorkWithData() throws {
    ExampleUtils.printStep(4, "Working with message data")

    let (messageDescriptor, _) = try createPersonMessageDescriptor()
    let factory = MessageFactory()
    var person = factory.createMessage(from: messageDescriptor)

    // Fill with data
    try person.set("John Doe", forField: "name")
    try person.set(Int32(30), forField: "age")
    try person.set("john.doe@example.com", forField: "email")

    print("  ✏️  Data set")

    // Read data back
    let name: String? = try person.get(forField: "name") as? String
    let age: Int32? = try person.get(forField: "age") as? Int32
    let email: String? = try person.get(forField: "email") as? String

    ExampleUtils.printTable(
      [
        "Name": name ?? "not specified",
        "Age": age?.description ?? "not specified",
        "Email": email ?? "not specified",
      ],
      title: "Person Data"
    )

    // Check field presence
    for fieldName in ["name", "age", "email"] {
      let hasValue = try person.hasValue(forField: fieldName)
      print("  \(hasValue ? "✅" : "❌") Field '\(fieldName)': \(hasValue ? "set" : "not set")")
    }
  }

  private static func step5UseTypeRegistry() throws {
    ExampleUtils.printStep(5, "Using TypeRegistry for type management")

    let (_, fileDescriptor) = try createPersonMessageDescriptor()

    // Create type registry
    let typeRegistry = TypeRegistry()
    try typeRegistry.registerFile(fileDescriptor)

    print("  📂 File registered in TypeRegistry")

    // Search for registered type
    let foundMessage = typeRegistry.findMessage(named: "example.Person")

    if let found = foundMessage {
      print("  🔍 Type found: \(found.fullName)")
      print("  📊 Fields in found type: \(found.fields.count)")
    }
    else {
      print("  ❌ Type not found")
    }

    // Create message through registry
    let registryFactory = MessageFactory()
    if let foundDescriptor = foundMessage {
      var message = registryFactory.createMessage(from: foundDescriptor)
      try message.set("Registry User", forField: "name")

      let retrievedName: String? = try message.get(forField: "name") as? String
      print("  🎯 Message through registry: name = '\(retrievedName ?? "nil")'")
    }
  }

  // MARK: - Helper Methods

  private static func createPersonMessageDescriptor() throws -> (MessageDescriptor, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "hello.proto", package: "example")
    var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)

    personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    personMessage.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
    personMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))

    fileDescriptor.addMessage(personMessage)

    return (personMessage, fileDescriptor)
  }
}
