/**
 * 🏗️ SwiftProtoReflect Example: Complex Multi-Level Messages
 *
 * Description: Creating complex multi-level message structures
 * Key concepts: Multi-level nesting, Complex relationships, Message hierarchies
 * Complexity: 🔧🔧 Advanced
 * Execution time: < 20 seconds
 *
 * What you'll learn:
 * - Creating complex message hierarchies with deep nesting
 * - Working with circular references and relationships between messages
 * - Advanced patterns for data organization
 * - Efficient management of complex structures
 * - Navigation through multi-level data hierarchies
 *
 * Run:
 *   swift run ComplexMessages
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct ComplexMessagesExample {
  static func main() throws {
    ExampleUtils.printHeader("Complex multi-level message structures")

    try step1UenterpriseOrganization()
    try step2UsocialNetworkGraph()
    try step3UecommerceSystem()
    try step4UdataAnalytics()
    try step5UcomplexValidation()

    ExampleUtils.printSuccess("You mastered creating complex multi-level structures!")

    ExampleUtils.printNext([
      "Next: nested-operations.swift - operations with nested messages",
      "Advanced: field-manipulation.swift - field manipulations",
      "Explore: message-cloning.swift - message cloning",
    ])
  }

  private static func step1UenterpriseOrganization() throws {
    ExampleUtils.printStep(1, "Enterprise organizational structure")

    let fileDescriptor = try createEnterpriseStructure()
    let factory = MessageFactory()

    // Create employees with hierarchical relationships
    var ceo = try createEmployee(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "John Smith",
      position: "CEO",
      level: 1
    )

    var vpEngineering = try createEmployee(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Sarah Johnson",
      position: "VP Engineering",
      level: 2
    )

    var directorDev = try createEmployee(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Alex Chen",
      position: "Director Development",
      level: 3
    )

    let teamLead = try createEmployee(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Maria Garcia",
      position: "Senior Team Lead",
      level: 4
    )

    // Build hierarchy
    try directorDev.set([teamLead], forField: "subordinates")
    try vpEngineering.set([directorDev], forField: "subordinates")
    try ceo.set([vpEngineering], forField: "subordinates")

    print("  🏢 Created enterprise hierarchy:")
    try printOrganizationChart(ceo, level: 0)

    let totalEmployees = try countTotalEmployees(ceo)
    print("  📊 Total employees: \(totalEmployees)")
  }

  private static func step2UsocialNetworkGraph() throws {
    ExampleUtils.printStep(2, "Social network graph with connections")

    let fileDescriptor = try createSocialNetworkStructure()
    let factory = MessageFactory()

    // Create users with interests
    var alice = try createUser(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Alice",
      interests: ["Technology", "Travel"]
    )
    var bob = try createUser(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Bob",
      interests: ["Sports", "Music"]
    )
    var charlie = try createUser(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Charlie",
      interests: ["Technology", "Gaming"]
    )

    // Create bidirectional friendships
    try alice.set([bob, charlie], forField: "friends")
    try bob.set([alice], forField: "friends")
    try charlie.set([alice], forField: "friends")

    print("  👥 Created social network graph:")
    print("    Alice friends: \(try getArrayCount(alice, field: "friends"))")
    print("    Bob friends: \(try getArrayCount(bob, field: "friends"))")
    print("    Charlie friends: \(try getArrayCount(charlie, field: "friends"))")

    // Analyze network connections
    let commonInterests = try findCommonInterests(alice, charlie)
    print("  🤝 Common interests of Alice and Charlie: \(commonInterests.joined(separator: ", "))")
  }

  private static func step3UecommerceSystem() throws {
    ExampleUtils.printStep(3, "E-commerce system with catalog")

    let fileDescriptor = try createEcommerceStructure()
    let factory = MessageFactory()

    // Create nested product categories with proper hierarchy
    var electronics = try createCategory(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Electronics",
      level: 1
    )
    var computers = try createCategory(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Computers",
      level: 2
    )
    var laptops = try createCategory(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Laptops",
      level: 3
    )

    // Build category hierarchy (parent-child relationships)
    try computers.set(electronics, forField: "parent_category")
    try laptops.set(computers, forField: "parent_category")

    // Set subcategories (children)
    try electronics.set([computers], forField: "subcategories")
    try computers.set([laptops], forField: "subcategories")
    try laptops.set([], forField: "subcategories")  // No subcategories for laptops

    // Create product linked to category
    var macbook = try createProduct(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "MacBook Pro",
      price: 2499.99
    )
    try macbook.set(laptops, forField: "category")

    // Create customer with proper data
    let customer = try createCustomer(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "John Doe",
      email: "john@example.com"
    )

    // Create order with real relationships
    var order = try createOrder(
      factory: factory,
      fileDescriptor: fileDescriptor,
      customerId: "CUST-001",
      total: 2499.99
    )
    try order.set(customer, forField: "customer")
    try order.set([macbook], forField: "products")

    print("  🛒 Created e-commerce system with real relationships:")
    try printCategoryHierarchy(electronics, level: 0)

    // Demonstrate relationships
    print("  📱 MacBook Pro category: \(try getCategoryName(macbook))")
    print("  👤 Customer: \(try getCustomerName(order))")
    print("  📦 Products in order: \(try getOrderProductCount(order))")

    let orderSummary = try analyzeOrder(order)
    ExampleUtils.printTable(orderSummary, title: "Order Analysis")
  }

  private static func step4UdataAnalytics() throws {
    ExampleUtils.printStep(4, "Data analytics system")

    let fileDescriptor = try createAnalyticsStructure()
    let factory = MessageFactory()

    // Create analytics dashboard with multiple data sources
    var dashboard = try createDashboard(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Sales Analytics"
    )

    // Create metric with historical data
    let salesMetric = try createMetric(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Daily Sales",
      value: 45780.50
    )

    let userMetric = try createMetric(
      factory: factory,
      fileDescriptor: fileDescriptor,
      name: "Active Users",
      value: 12340.0
    )

    // Create time series data
    let timeSeries = try createTimeSeries(
      factory: factory,
      fileDescriptor: fileDescriptor,
      metrics: [salesMetric, userMetric]
    )

    try dashboard.set([timeSeries], forField: "data_sources")

    print("  📊 Created analytics system:")
    let dashboardStats = try analyzeDashboard(dashboard)
    ExampleUtils.printTable(dashboardStats, title: "Dashboard Statistics")
  }

  private static func step5UcomplexValidation() throws {
    ExampleUtils.printStep(5, "Complex validation and integrity checks")

    let fileDescriptor = try createValidationStructure()
    let factory = MessageFactory()

    // Create complex document with multiple validation rules
    var document = try createDocument(
      factory: factory,
      fileDescriptor: fileDescriptor,
      title: "Complex Business Document"
    )

    // Add sections with cross-references
    let section1 = try createSection(
      factory: factory,
      fileDescriptor: fileDescriptor,
      title: "Introduction",
      content: "This document..."
    )

    let section2 = try createSection(
      factory: factory,
      fileDescriptor: fileDescriptor,
      title: "Analysis",
      content: "Based on section 1..."
    )

    try document.set([section1, section2], forField: "sections")

    print("  ✅ Created document with validation:")
    let validationResults = try performComplexValidation(document)
    ExampleUtils.printTable(validationResults, title: "Validation Results")

    ExampleUtils.printInfo("Demonstrates complex integrity checks between linked messages")
  }

  // MARK: - Helper Functions

  private static func createEmployee(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    name: String,
    position: String,
    level: Int
  ) throws -> DynamicMessage {
    guard let employeeDesc = fileDescriptor.messages.values.first(where: { $0.name == "Employee" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Employee descriptor not found"])
    }

    var employee = factory.createMessage(from: employeeDesc)
    try employee.set(name, forField: "name")
    try employee.set(position, forField: "position")
    try employee.set(Int32(level), forField: "level")
    try employee.set([], forField: "subordinates")

    return employee
  }

  private static func printOrganizationChart(_ employee: DynamicMessage, level: Int) throws {
    let indent = String(repeating: "  ", count: level)
    let name = try employee.get(forField: "name") as? String ?? "Unknown"
    let position = try employee.get(forField: "position") as? String ?? "Unknown"

    print("    \(indent)• \(name) (\(position))")

    if let subordinates = try employee.get(forField: "subordinates") as? [DynamicMessage] {
      for subordinate in subordinates {
        try printOrganizationChart(subordinate, level: level + 1)
      }
    }
  }

  private static func countTotalEmployees(_ employee: DynamicMessage) throws -> Int {
    var count = 1
    if let subordinates = try employee.get(forField: "subordinates") as? [DynamicMessage] {
      for subordinate in subordinates {
        count += try countTotalEmployees(subordinate)
      }
    }
    return count
  }

  private static func getArrayCount(_ message: DynamicMessage, field: String) throws -> Int {
    if let array = try message.get(forField: field) as? [Any] {
      return array.count
    }
    return 0
  }

  private static func findCommonInterests(_ user1: DynamicMessage, _ user2: DynamicMessage) throws -> [String] {
    let user1Interests = try user1.get(forField: "interests") as? [String] ?? []
    let user2Interests = try user2.get(forField: "interests") as? [String] ?? []

    return Array(Set(user1Interests).intersection(Set(user2Interests)))
  }

  // MARK: - Structure Creation Methods

  private static func createEnterpriseStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "enterprise.proto", package: "example")

    var employeeDesc = MessageDescriptor(name: "Employee", parent: fileDescriptor)
    employeeDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    employeeDesc.addField(FieldDescriptor(name: "position", number: 2, type: .string))
    employeeDesc.addField(FieldDescriptor(name: "level", number: 3, type: .int32))
    employeeDesc.addField(
      FieldDescriptor(
        name: "subordinates",
        number: 4,
        type: .message,
        typeName: "example.Employee",
        isRepeated: true
      )
    )

    fileDescriptor.addMessage(employeeDesc)
    return fileDescriptor
  }

  private static func createSocialNetworkStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "social.proto", package: "example")

    var userDesc = MessageDescriptor(name: "User", parent: fileDescriptor)
    userDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    userDesc.addField(FieldDescriptor(name: "interests", number: 2, type: .string, isRepeated: true))
    userDesc.addField(
      FieldDescriptor(
        name: "friends",
        number: 3,
        type: .message,
        typeName: "example.User",
        isRepeated: true
      )
    )

    var postDesc = MessageDescriptor(name: "Post", parent: fileDescriptor)
    postDesc.addField(FieldDescriptor(name: "content", number: 1, type: .string))
    postDesc.addField(
      FieldDescriptor(
        name: "author",
        number: 2,
        type: .message,
        typeName: "example.User"
      )
    )

    fileDescriptor.addMessage(userDesc)
    fileDescriptor.addMessage(postDesc)
    return fileDescriptor
  }

  private static func createEcommerceStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "ecommerce.proto", package: "example")

    var categoryDesc = MessageDescriptor(name: "Category", parent: fileDescriptor)
    categoryDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    categoryDesc.addField(FieldDescriptor(name: "level", number: 2, type: .int32))
    categoryDesc.addField(
      FieldDescriptor(
        name: "parent_category",
        number: 3,
        type: .message,
        typeName: "example.Category"
      )
    )
    categoryDesc.addField(
      FieldDescriptor(
        name: "subcategories",
        number: 4,
        type: .message,
        typeName: "example.Category",
        isRepeated: true
      )
    )

    var productDesc = MessageDescriptor(name: "Product", parent: fileDescriptor)
    productDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    productDesc.addField(FieldDescriptor(name: "price", number: 2, type: .double))
    productDesc.addField(
      FieldDescriptor(
        name: "category",
        number: 3,
        type: .message,
        typeName: "example.Category"
      )
    )

    var customerDesc = MessageDescriptor(name: "Customer", parent: fileDescriptor)
    customerDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    customerDesc.addField(FieldDescriptor(name: "email", number: 2, type: .string))

    var orderDesc = MessageDescriptor(name: "Order", parent: fileDescriptor)
    orderDesc.addField(FieldDescriptor(name: "customer_id", number: 1, type: .string))
    orderDesc.addField(FieldDescriptor(name: "total", number: 2, type: .double))
    orderDesc.addField(
      FieldDescriptor(
        name: "customer",
        number: 3,
        type: .message,
        typeName: "example.Customer"
      )
    )
    orderDesc.addField(
      FieldDescriptor(
        name: "products",
        number: 4,
        type: .message,
        typeName: "example.Product",
        isRepeated: true
      )
    )

    fileDescriptor.addMessage(categoryDesc)
    fileDescriptor.addMessage(productDesc)
    fileDescriptor.addMessage(customerDesc)
    fileDescriptor.addMessage(orderDesc)
    return fileDescriptor
  }

  private static func createAnalyticsStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "analytics.proto", package: "example")

    var dashboardDesc = MessageDescriptor(name: "Dashboard", parent: fileDescriptor)
    dashboardDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    dashboardDesc.addField(
      FieldDescriptor(
        name: "data_sources",
        number: 2,
        type: .message,
        typeName: "example.TimeSeries",
        isRepeated: true
      )
    )

    var metricDesc = MessageDescriptor(name: "Metric", parent: fileDescriptor)
    metricDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    metricDesc.addField(FieldDescriptor(name: "value", number: 2, type: .double))

    var timeSeriesDesc = MessageDescriptor(name: "TimeSeries", parent: fileDescriptor)
    timeSeriesDesc.addField(
      FieldDescriptor(
        name: "metrics",
        number: 1,
        type: .message,
        typeName: "example.Metric",
        isRepeated: true
      )
    )

    fileDescriptor.addMessage(dashboardDesc)
    fileDescriptor.addMessage(metricDesc)
    fileDescriptor.addMessage(timeSeriesDesc)
    return fileDescriptor
  }

  private static func createValidationStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "validation.proto", package: "example")

    var documentDesc = MessageDescriptor(name: "Document", parent: fileDescriptor)
    documentDesc.addField(FieldDescriptor(name: "title", number: 1, type: .string))
    documentDesc.addField(
      FieldDescriptor(
        name: "sections",
        number: 2,
        type: .message,
        typeName: "example.Section",
        isRepeated: true
      )
    )

    var sectionDesc = MessageDescriptor(name: "Section", parent: fileDescriptor)
    sectionDesc.addField(FieldDescriptor(name: "title", number: 1, type: .string))
    sectionDesc.addField(FieldDescriptor(name: "content", number: 2, type: .string))

    fileDescriptor.addMessage(documentDesc)
    fileDescriptor.addMessage(sectionDesc)
    return fileDescriptor
  }

  // MARK: - Factory Methods

  private static func createUser(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    name: String,
    interests: [String]
  ) throws -> DynamicMessage {
    guard let userDesc = fileDescriptor.messages.values.first(where: { $0.name == "User" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "User descriptor not found"])
    }

    var user = factory.createMessage(from: userDesc)
    try user.set(name, forField: "name")
    try user.set(interests, forField: "interests")
    try user.set([], forField: "friends")

    return user
  }

  private static func createCategory(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    name: String,
    level: Int
  ) throws -> DynamicMessage {
    guard let categoryDesc = fileDescriptor.messages.values.first(where: { $0.name == "Category" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Category descriptor not found"])
    }

    var category = factory.createMessage(from: categoryDesc)
    try category.set(name, forField: "name")
    try category.set(Int32(level), forField: "level")

    return category
  }

  private static func createProduct(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    name: String,
    price: Double
  ) throws -> DynamicMessage {
    guard let productDesc = fileDescriptor.messages.values.first(where: { $0.name == "Product" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Product descriptor not found"])
    }

    var product = factory.createMessage(from: productDesc)
    try product.set(name, forField: "name")
    try product.set(price, forField: "price")

    return product
  }

  private static func createCustomer(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    name: String,
    email: String
  ) throws -> DynamicMessage {
    guard let customerDesc = fileDescriptor.messages.values.first(where: { $0.name == "Customer" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Customer descriptor not found"])
    }

    var customer = factory.createMessage(from: customerDesc)
    try customer.set(name, forField: "name")
    try customer.set(email, forField: "email")

    return customer
  }

  private static func createOrder(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    customerId: String,
    total: Double
  ) throws -> DynamicMessage {
    guard let orderDesc = fileDescriptor.messages.values.first(where: { $0.name == "Order" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Order descriptor not found"])
    }

    var order = factory.createMessage(from: orderDesc)
    try order.set(customerId, forField: "customer_id")
    try order.set(total, forField: "total")

    return order
  }

  private static func createDashboard(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    name: String
  ) throws -> DynamicMessage {
    guard let dashboardDesc = fileDescriptor.messages.values.first(where: { $0.name == "Dashboard" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Dashboard descriptor not found"])
    }

    var dashboard = factory.createMessage(from: dashboardDesc)
    try dashboard.set(name, forField: "name")

    return dashboard
  }

  private static func createMetric(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    name: String,
    value: Double
  ) throws -> DynamicMessage {
    guard let metricDesc = fileDescriptor.messages.values.first(where: { $0.name == "Metric" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Metric descriptor not found"])
    }

    var metric = factory.createMessage(from: metricDesc)
    try metric.set(name, forField: "name")
    try metric.set(value, forField: "value")

    return metric
  }

  private static func createTimeSeries(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    metrics: [DynamicMessage]
  ) throws -> DynamicMessage {
    guard let timeSeriesDesc = fileDescriptor.messages.values.first(where: { $0.name == "TimeSeries" }) else {
      throw NSError(
        domain: "Example",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "TimeSeries descriptor not found"]
      )
    }

    var timeSeries = factory.createMessage(from: timeSeriesDesc)
    try timeSeries.set(metrics, forField: "metrics")

    return timeSeries
  }

  private static func createDocument(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    title: String
  ) throws -> DynamicMessage {
    guard let documentDesc = fileDescriptor.messages.values.first(where: { $0.name == "Document" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Document descriptor not found"])
    }

    var document = factory.createMessage(from: documentDesc)
    try document.set(title, forField: "title")

    return document
  }

  private static func createSection(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    title: String,
    content: String
  ) throws -> DynamicMessage {
    guard let sectionDesc = fileDescriptor.messages.values.first(where: { $0.name == "Section" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "Section descriptor not found"])
    }

    var section = factory.createMessage(from: sectionDesc)
    try section.set(title, forField: "title")
    try section.set(content, forField: "content")

    return section
  }

  // MARK: - Analysis Methods

  private static func printCategoryHierarchy(_ category: DynamicMessage, level: Int) throws {
    let indent = String(repeating: "  ", count: level)
    let name = try category.get(forField: "name") as? String ?? "Unknown"
    let categoryLevel = try category.get(forField: "level") as? Int32 ?? 0

    print("    \(indent)• \(name) (Level \(categoryLevel))")

    if let subcategories = try category.get(forField: "subcategories") as? [DynamicMessage] {
      for subcategory in subcategories {
        try printCategoryHierarchy(subcategory, level: level + 1)
      }
    }
  }

  private static func getCategoryName(_ product: DynamicMessage) throws -> String {
    if let category = try product.get(forField: "category") as? DynamicMessage {
      return try category.get(forField: "name") as? String ?? "Unknown"
    }
    return "No category"
  }

  private static func getCustomerName(_ order: DynamicMessage) throws -> String {
    if let customer = try order.get(forField: "customer") as? DynamicMessage {
      return try customer.get(forField: "name") as? String ?? "Unknown"
    }
    return "No customer"
  }

  private static func getOrderProductCount(_ order: DynamicMessage) throws -> Int {
    if let products = try order.get(forField: "products") as? [Any] {
      return products.count
    }
    return 0
  }

  private static func analyzeOrder(_ order: DynamicMessage) throws -> [String: String] {
    let customerId = try order.get(forField: "customer_id") as? String ?? "Unknown"
    let total = try order.get(forField: "total") as? Double ?? 0.0
    let productCount = try getOrderProductCount(order)

    return [
      "Customer ID": customerId,
      "Total Amount": String(format: "%.2f", total),
      "Product Count": "\(productCount)",
      "Customer Name": try getCustomerName(order),
    ]
  }

  private static func analyzeDashboard(_ dashboard: DynamicMessage) throws -> [String: String] {
    let name = try dashboard.get(forField: "name") as? String ?? "Unknown"
    var metricCount = 0

    if let dataSources = try dashboard.get(forField: "data_sources") as? [DynamicMessage] {
      for dataSource in dataSources {
        if let metrics = try dataSource.get(forField: "metrics") as? [Any] {
          metricCount += metrics.count
        }
      }
    }

    return [
      "Dashboard Name": name,
      "Total Metrics": "\(metricCount)",
      "Data Sources": "\(try getArrayCount(dashboard, field: "data_sources"))",
    ]
  }

  private static func performComplexValidation(_ document: DynamicMessage) throws -> [String: String] {
    let title = try document.get(forField: "title") as? String ?? ""
    let sectionCount = try getArrayCount(document, field: "sections")

    var validationResults: [String: String] = [:]

    // Check title length
    if title.count < 5 {
      validationResults["Title Length"] = "❌ Too short"
    } else {
      validationResults["Title Length"] = "✅ Valid"
    }

    // Check section count
    if sectionCount == 0 {
      validationResults["Section Count"] = "❌ No sections"
    } else {
      validationResults["Section Count"] = "✅ \(sectionCount) sections"
    }

    // Check section content
    var hasContent = false
    if let sections = try document.get(forField: "sections") as? [DynamicMessage] {
      for section in sections {
        if let content = try section.get(forField: "content") as? String, !content.isEmpty {
          hasContent = true
          break
        }
      }
    }

    validationResults["Content Check"] = hasContent ? "✅ Has content" : "❌ No content"

    return validationResults
  }
}
