/**
 * 🏗 SwiftProtoReflect Example: Simple Complex Messages
 *
 * Description: Creating more complex messages with nesting, oneof fields and message types
 * Key concepts: Nested Messages, OneOf Fields, Message Types, Default Values
 * Complexity: 🔧 Intermediate
 * Execution time: < 10 seconds
 *
 * What you'll learn:
 * - Creating nested messages
 * - Using oneof fields for mutually exclusive values
 * - Working with message types and typeName
 * - Default values for fields
 * - Complex data hierarchies
 *
 * Run:
 *   swift run SimpleMessage
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct SimpleMessageExample {
  static func main() throws {
    ExampleUtils.printHeader("Complex Messages - Nesting and OneOf Fields")

    try step1UcreateNestedMessages()
    try step2UuseOneOfFields()
    try step3UworkWithMessageTypes()
    try step4UdefaultValues()
    try step5UcomplexHierarchy()

    ExampleUtils.printSuccess("You mastered creating complex Protocol Buffers messages!")

    ExampleUtils.printNext([
      "Next: basic-descriptors.swift - metadata and descriptor navigation",
      "Advanced: complex-messages.swift - even more complex structures",
      "Explore: nested-messages.swift - specialization in nested messages",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1UcreateNestedMessages() throws {
    ExampleUtils.printStep(1, "Creating nested messages")

    let (userDescriptor, addressDescriptor, _) = try createNestedMessageStructure()
    let factory = MessageFactory()

    // Create messages
    var user = factory.createMessage(from: userDescriptor)
    var address = factory.createMessage(from: addressDescriptor)

    // Fill nested Address message
    try address.set("123 Main Street", forField: "street")
    try address.set("Springfield", forField: "city")
    try address.set("12345", forField: "postal_code")

    print("  📍 Address created:")
    address.prettyPrint()

    // Fill main User message
    try user.set("John Doe", forField: "name")
    try user.set("john.doe@example.com", forField: "email")
    try user.set(Int32(30), forField: "age")
    try user.set(address, forField: "address")

    print("\n  👤 User created with nested Address:")
    user.prettyPrint()

    // Check access to nested data
    if let userAddress = try user.get(forField: "address") as? DynamicMessage {
      let street = try userAddress.get(forField: "street") as? String
      print("  🏠 User's street: \(street ?? "not specified")")
    }
  }

  private static func step2UuseOneOfFields() throws {
    ExampleUtils.printStep(2, "Using OneOf fields")

    let (messageDescriptor, _) = try createOneOfMessage()
    let factory = MessageFactory()

    // Demonstrate different oneof variants
    print("  🔀 Testing OneOf fields:")

    // Variant 1: contact_method = email
    var message1 = factory.createMessage(from: messageDescriptor)
    try message1.set("user@example.com", forField: "email")

    let hasEmail = try message1.hasValue(forField: "email")
    let hasPhone = try message1.hasValue(forField: "phone")

    print("    📧 Email set:")
    print("      - hasEmail: \(hasEmail)")
    print("      - hasPhone: \(hasPhone)")
    print("      - email: \(try message1.get(forField: "email") as? String ?? "nil")")

    // Variant 2: contact_method = phone (overwrites email)
    try message1.set("+1-555-123-4567", forField: "phone")

    let hasEmailAfter = try message1.hasValue(forField: "email")
    let hasPhoneAfter = try message1.hasValue(forField: "phone")

    print("    📞 Phone set (should clear email):")
    print("      - hasEmail: \(hasEmailAfter)")
    print("      - hasPhone: \(hasPhoneAfter)")
    print("      - phone: \(try message1.get(forField: "phone") as? String ?? "nil")")

    // Variant 3: another oneof - notification_method
    try message1.set(true, forField: "push_enabled")
    let hasPush = try message1.hasValue(forField: "push_enabled")
    print("    🔔 Notification method - push_enabled: \(hasPush)")
  }

  private static func step3UworkWithMessageTypes() throws {
    ExampleUtils.printStep(3, "Working with message types")

    let (companyDescriptor, departmentDescriptor, _) = try createCompanyStructure()
    let factory = MessageFactory()

    // Create department
    var department = factory.createMessage(from: departmentDescriptor)
    try department.set("Engineering", forField: "name")
    try department.set(Int32(25), forField: "employee_count")

    print("  🏢 Department created:")
    department.prettyPrint()

    // Create company with nested department
    var company = factory.createMessage(from: companyDescriptor)
    try company.set("TechCorp", forField: "name")
    try company.set("A leading technology company", forField: "description")

    // Set department as message field
    try company.set(department, forField: "main_department")

    print("\n  🏭 Company created with nested Department:")
    company.prettyPrint()

    // Check access to message field
    if let mainDept = try company.get(forField: "main_department") as? DynamicMessage {
      let deptName = try mainDept.get(forField: "name") as? String
      let employeeCount = try mainDept.get(forField: "employee_count") as? Int32

      ExampleUtils.printTable(
        [
          "Department Name": deptName ?? "Unknown",
          "Employee Count": employeeCount?.description ?? "0",
        ],
        title: "Main Department Info"
      )
    }
  }

  private static func step4UdefaultValues() throws {
    ExampleUtils.printStep(4, "Default field values")

    let (messageDescriptor, _) = try createMessageWithDefaults()
    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    print("  🎯 Testing default values:")

    // Check values before setting (should be defaults or nil)
    let statusBefore = try message.get(forField: "status") as? String
    let priorityBefore = try message.get(forField: "priority") as? Int32
    let activeBefore = try message.get(forField: "is_active") as? Bool

    print("    Before setting values:")
    print("      - status: \(statusBefore ?? "nil")")
    print("      - priority: \(priorityBefore?.description ?? "nil")")
    print("      - is_active: \(activeBefore?.description ?? "nil")")

    // Set values
    try message.set("pending", forField: "status")
    try message.set(Int32(5), forField: "priority")
    // Leave is_active unset

    let statusAfter = try message.get(forField: "status") as? String
    let priorityAfter = try message.get(forField: "priority") as? Int32
    let activeAfter = try message.get(forField: "is_active") as? Bool

    print("    After setting:")
    print("      - status: \(statusAfter ?? "nil")")
    print("      - priority: \(priorityAfter?.description ?? "nil")")
    print("      - is_active: \(activeAfter?.description ?? "nil") (default)")
  }

  private static func step5UcomplexHierarchy() throws {
    ExampleUtils.printStep(5, "Complex message hierarchy")

    let (blogDescriptor, postDescriptor, authorDescriptor, _) = try createBlogStructure()
    let factory = MessageFactory()

    // Create author
    var author = factory.createMessage(from: authorDescriptor)
    try author.set("Jane Smith", forField: "name")
    try author.set("jane@example.com", forField: "email")
    try author.set("Senior Developer", forField: "bio")

    // Create post
    var post = factory.createMessage(from: postDescriptor)
    try post.set("Introduction to SwiftProtoReflect", forField: "title")
    try post.set("This is a comprehensive guide...", forField: "content")
    try post.set(["swift", "protobuf", "ios"], forField: "tags")
    try post.set(author, forField: "author")

    // Create blog with post
    var blog = factory.createMessage(from: blogDescriptor)
    try blog.set("Tech Blog", forField: "name")
    try blog.set("A blog about technology", forField: "description")
    try blog.set([post], forField: "posts")

    print("  📝 Complex hierarchy created: Blog -> Post -> Author")

    // Demonstrate hierarchy navigation
    if let posts = try blog.get(forField: "posts") as? [DynamicMessage],
      let firstPost = posts.first
    {

      let postTitle = try firstPost.get(forField: "title") as? String
      print("  📰 First post: \(postTitle ?? "Untitled")")

      if let postAuthor = try firstPost.get(forField: "author") as? DynamicMessage {
        let authorName = try postAuthor.get(forField: "name") as? String
        let authorEmail = try postAuthor.get(forField: "email") as? String

        ExampleUtils.printTable(
          [
            "Post Title": postTitle ?? "Unknown",
            "Author Name": authorName ?? "Unknown",
            "Author Email": authorEmail ?? "Unknown",
          ],
          title: "Blog Post Details"
        )
      }

      if let tags = try firstPost.get(forField: "tags") as? [String] {
        print("  🏷  Tags: \(tags.joined(separator: ", "))")
      }
    }

    ExampleUtils.printInfo(
      "This demonstration shows ability to create complex multi-level data structures using SwiftProtoReflect"
    )
  }

  // MARK: - Helper Methods

  private static func createNestedMessageStructure() throws -> (MessageDescriptor, MessageDescriptor, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "user.proto", package: "example")

    // Create nested Address message
    var addressDescriptor = MessageDescriptor(name: "Address", parent: fileDescriptor)
    addressDescriptor.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "city", number: 2, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "postal_code", number: 3, type: .string))

    // Create main User message
    var userDescriptor = MessageDescriptor(name: "User", parent: fileDescriptor)
    userDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    userDescriptor.addField(FieldDescriptor(name: "email", number: 2, type: .string))
    userDescriptor.addField(FieldDescriptor(name: "age", number: 3, type: .int32))
    userDescriptor.addField(
      FieldDescriptor(
        name: "address",
        number: 4,
        type: .message,
        typeName: "example.Address"
      )
    )

    fileDescriptor.addMessage(addressDescriptor)
    fileDescriptor.addMessage(userDescriptor)

    return (userDescriptor, addressDescriptor, fileDescriptor)
  }

  private static func createOneOfMessage() throws -> (MessageDescriptor, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "contact.proto", package: "example")
    var messageDescriptor = MessageDescriptor(name: "Contact", parent: fileDescriptor)

    // Regular fields
    messageDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))

    // OneOf group 1: contact_method (email OR phone)
    messageDescriptor.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    messageDescriptor.addField(FieldDescriptor(name: "phone", number: 3, type: .string, oneofIndex: 0))

    // OneOf group 2: notification_method (push_enabled OR sms_enabled)
    messageDescriptor.addField(FieldDescriptor(name: "push_enabled", number: 4, type: .bool, oneofIndex: 1))
    messageDescriptor.addField(FieldDescriptor(name: "sms_enabled", number: 5, type: .bool, oneofIndex: 1))

    fileDescriptor.addMessage(messageDescriptor)

    return (messageDescriptor, fileDescriptor)
  }

  private static func createCompanyStructure() throws -> (MessageDescriptor, MessageDescriptor, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "company.proto", package: "example")

    // Create Department message
    var departmentDescriptor = MessageDescriptor(name: "Department", parent: fileDescriptor)
    departmentDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    departmentDescriptor.addField(FieldDescriptor(name: "employee_count", number: 2, type: .int32))

    // Create Company message with message field
    var companyDescriptor = MessageDescriptor(name: "Company", parent: fileDescriptor)
    companyDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    companyDescriptor.addField(FieldDescriptor(name: "description", number: 2, type: .string))
    companyDescriptor.addField(
      FieldDescriptor(
        name: "main_department",
        number: 3,
        type: .message,
        typeName: "example.Department"
      )
    )

    fileDescriptor.addMessage(departmentDescriptor)
    fileDescriptor.addMessage(companyDescriptor)

    return (companyDescriptor, departmentDescriptor, fileDescriptor)
  }

  private static func createMessageWithDefaults() throws -> (MessageDescriptor, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "defaults.proto", package: "example")
    var messageDescriptor = MessageDescriptor(name: "TaskInfo", parent: fileDescriptor)

    // Fields with potential default values
    messageDescriptor.addField(
      FieldDescriptor(
        name: "status",
        number: 1,
        type: .string,
        defaultValue: "new"
      )
    )
    messageDescriptor.addField(
      FieldDescriptor(
        name: "priority",
        number: 2,
        type: .int32,
        defaultValue: Int32(1)
      )
    )
    messageDescriptor.addField(
      FieldDescriptor(
        name: "is_active",
        number: 3,
        type: .bool,
        defaultValue: true
      )
    )

    fileDescriptor.addMessage(messageDescriptor)

    return (messageDescriptor, fileDescriptor)
  }

  private static func createBlogStructure() throws -> (
    MessageDescriptor, MessageDescriptor, MessageDescriptor, FileDescriptor
  ) {
    var fileDescriptor = FileDescriptor(name: "blog.proto", package: "example")

    // Author message
    var authorDescriptor = MessageDescriptor(name: "Author", parent: fileDescriptor)
    authorDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    authorDescriptor.addField(FieldDescriptor(name: "email", number: 2, type: .string))
    authorDescriptor.addField(FieldDescriptor(name: "bio", number: 3, type: .string))

    // Post message
    var postDescriptor = MessageDescriptor(name: "Post", parent: fileDescriptor)
    postDescriptor.addField(FieldDescriptor(name: "title", number: 1, type: .string))
    postDescriptor.addField(FieldDescriptor(name: "content", number: 2, type: .string))
    postDescriptor.addField(FieldDescriptor(name: "tags", number: 3, type: .string, isRepeated: true))
    postDescriptor.addField(
      FieldDescriptor(
        name: "author",
        number: 4,
        type: .message,
        typeName: "example.Author"
      )
    )

    // Blog message
    var blogDescriptor = MessageDescriptor(name: "Blog", parent: fileDescriptor)
    blogDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    blogDescriptor.addField(FieldDescriptor(name: "description", number: 2, type: .string))
    blogDescriptor.addField(
      FieldDescriptor(
        name: "posts",
        number: 3,
        type: .message,
        typeName: "example.Post",
        isRepeated: true
      )
    )

    fileDescriptor.addMessage(authorDescriptor)
    fileDescriptor.addMessage(postDescriptor)
    fileDescriptor.addMessage(blogDescriptor)

    return (blogDescriptor, postDescriptor, authorDescriptor, fileDescriptor)
  }
}
