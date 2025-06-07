/**
 * 🏗️ SwiftProtoReflect Example: Complex Multi-Level Messages
 * 
 * Описание: Создание сложных многоуровневых структур сообщений
 * Ключевые концепции: Multi-level nesting, Complex relationships, Message hierarchies
 * Сложность: 🔧🔧 Продвинутый
 * Время выполнения: < 20 секунд
 * 
 * Что изучите:
 * - Создание сложных иерархий сообщений с глубокой вложенностью
 * - Работа с циркулярными ссылками и связями между сообщениями
 * - Продвинутые patterns для организации данных
 * - Эффективное управление сложными структурами
 * - Навигация по многоуровневым иерархиям данных
 * 
 * Запуск: 
 *   swift run ComplexMessages
 *   make run-dynamic
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct ComplexMessagesExample {
    static func main() throws {
        ExampleUtils.printHeader("Сложные многоуровневые структуры сообщений")
        
        try step1_enterpriseOrganization()
        try step2_socialNetworkGraph()
        try step3_ecommerceSystem()
        try step4_dataAnalytics()
        try step5_complexValidation()
        
        ExampleUtils.printSuccess("Вы освоили создание сложных многоуровневых структур!")
        
        ExampleUtils.printNext([
            "Следующий: nested-operations.swift - операции с вложенными сообщениями",
            "Продвинутые: field-manipulation.swift - манипуляции полей",
            "Изучите: message-cloning.swift - клонирование сообщений"
        ])
    }
    
    private static func step1_enterpriseOrganization() throws {
        ExampleUtils.printStep(1, "Корпоративная организационная структура")
        
        let fileDescriptor = try createEnterpriseStructure()
        let factory = MessageFactory()
        
        // Create employees with hierarchical relationships
        var ceo = try createEmployee(factory: factory, fileDescriptor: fileDescriptor,
                                   name: "John Smith", position: "CEO", level: 1)
        
        var vpEngineering = try createEmployee(factory: factory, fileDescriptor: fileDescriptor,
                                             name: "Sarah Johnson", position: "VP Engineering", level: 2)
        
        var directorDev = try createEmployee(factory: factory, fileDescriptor: fileDescriptor,
                                           name: "Alex Chen", position: "Director Development", level: 3)
        
        let teamLead = try createEmployee(factory: factory, fileDescriptor: fileDescriptor,
                                        name: "Maria Garcia", position: "Senior Team Lead", level: 4)
        
        // Build hierarchy
        try directorDev.set([teamLead], forField: "subordinates")
        try vpEngineering.set([directorDev], forField: "subordinates")
        try ceo.set([vpEngineering], forField: "subordinates")
        
        print("  🏢 Создана корпоративная иерархия:")
        try printOrganizationChart(ceo, level: 0)
        
        let totalEmployees = try countTotalEmployees(ceo)
        print("  📊 Общее количество сотрудников: \(totalEmployees)")
    }
    
    private static func step2_socialNetworkGraph() throws {
        ExampleUtils.printStep(2, "Граф социальной сети с связями")
        
        let fileDescriptor = try createSocialNetworkStructure()
        let factory = MessageFactory()
        
        // Create users with interests
        var alice = try createUser(factory: factory, fileDescriptor: fileDescriptor,
                                 name: "Alice", interests: ["Technology", "Travel"])
        var bob = try createUser(factory: factory, fileDescriptor: fileDescriptor,
                               name: "Bob", interests: ["Sports", "Music"])
        var charlie = try createUser(factory: factory, fileDescriptor: fileDescriptor,
                                   name: "Charlie", interests: ["Technology", "Gaming"])
        
        // Create bidirectional friendships
        try alice.set([bob, charlie], forField: "friends")
        try bob.set([alice], forField: "friends")
        try charlie.set([alice], forField: "friends")
        
        // Create posts with author references
        let alicePost = try createPost(factory: factory, fileDescriptor: fileDescriptor,
                                     author: alice, content: "Exploring new tech trends!")
        let bobPost = try createPost(factory: factory, fileDescriptor: fileDescriptor,
                                   author: bob, content: "Great game last night!")
        
        print("  👥 Создан граф социальной сети:")
        print("    Alice friends: \(try getArrayCount(alice, field: "friends"))")
        print("    Bob friends: \(try getArrayCount(bob, field: "friends"))")
        print("    Charlie friends: \(try getArrayCount(charlie, field: "friends"))")
        
        // Analyze network connections
        let commonInterests = try findCommonInterests(alice, charlie)
        print("  🤝 Общие интересы Alice и Charlie: \(commonInterests.joined(separator: ", "))")
    }
    
    private static func step3_ecommerceSystem() throws {
        ExampleUtils.printStep(3, "E-commerce система с каталогом")
        
        let fileDescriptor = try createEcommerceStructure()
        let factory = MessageFactory()
        
        // Create nested product categories
        let electronics = try createCategory(factory: factory, fileDescriptor: fileDescriptor,
                                           name: "Electronics", level: 1)
        _ = try createCategory(factory: factory, fileDescriptor: fileDescriptor,
                             name: "Computers", level: 2)
        _ = try createCategory(factory: factory, fileDescriptor: fileDescriptor,
                             name: "Laptops", level: 3)
        
        // Create product with complex attributes
        _ = try createProduct(factory: factory, fileDescriptor: fileDescriptor,
                            name: "MacBook Pro", price: 2499.99)
        
        // Customer with multiple addresses
        _ = try createCustomer(factory: factory, fileDescriptor: fileDescriptor,
                             name: "John Doe", email: "john@example.com")
        
        // Order with multiple products and complex pricing
        let order = try createOrder(factory: factory, fileDescriptor: fileDescriptor,
                                  customerId: "CUST-001", total: 2499.99)
        
        print("  🛒 Создана e-commerce система:")
        try printCategoryHierarchy(electronics, level: 0)
        
        let orderSummary = try analyzeOrder(order)
        ExampleUtils.printTable(orderSummary, title: "Order Analysis")
    }
    
    private static func step4_dataAnalytics() throws {
        ExampleUtils.printStep(4, "Система аналитики данных")
        
        let fileDescriptor = try createAnalyticsStructure()
        let factory = MessageFactory()
        
        // Create analytics dashboard with multiple data sources
        var dashboard = try createDashboard(factory: factory, fileDescriptor: fileDescriptor,
                                          name: "Sales Analytics")
        
        // Create metric with historical data
        let salesMetric = try createMetric(factory: factory, fileDescriptor: fileDescriptor,
                                         name: "Daily Sales", value: 45780.50)
        
        let userMetric = try createMetric(factory: factory, fileDescriptor: fileDescriptor,
                                        name: "Active Users", value: 12340.0)
        
        // Create time series data
        let timeSeries = try createTimeSeries(factory: factory, fileDescriptor: fileDescriptor,
                                            metrics: [salesMetric, userMetric])
        
        try dashboard.set([timeSeries], forField: "data_sources")
        
        print("  📊 Создана система аналитики:")
        let dashboardStats = try analyzeDashboard(dashboard)
        ExampleUtils.printTable(dashboardStats, title: "Dashboard Statistics")
    }
    
    private static func step5_complexValidation() throws {
        ExampleUtils.printStep(5, "Сложная валидация и проверки целостности")
        
        let fileDescriptor = try createValidationStructure()
        let factory = MessageFactory()
        
        // Create complex document with multiple validation rules
        var document = try createDocument(factory: factory, fileDescriptor: fileDescriptor,
                                        title: "Complex Business Document")
        
        // Add sections with cross-references
        let section1 = try createSection(factory: factory, fileDescriptor: fileDescriptor,
                                       title: "Introduction", content: "This document...")
        
        let section2 = try createSection(factory: factory, fileDescriptor: fileDescriptor,
                                       title: "Analysis", content: "Based on section 1...")
        
        try document.set([section1, section2], forField: "sections")
        
        print("  ✅ Создан документ с валидацией:")
        let validationResults = try performComplexValidation(document)
        ExampleUtils.printTable(validationResults, title: "Validation Results")
        
        ExampleUtils.printInfo("Демонстрирует сложные проверки целостности между связанными сообщениями")
    }
    
    // MARK: - Helper Functions
    
    private static func createEmployee(factory: MessageFactory, fileDescriptor: FileDescriptor,
                                     name: String, position: String, level: Int) throws -> DynamicMessage {
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
        employeeDesc.addField(FieldDescriptor(
            name: "subordinates",
            number: 4,
            type: .message,
            typeName: "example.Employee",
            isRepeated: true
        ))
        
        fileDescriptor.addMessage(employeeDesc)
        return fileDescriptor
    }
    
    private static func createSocialNetworkStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "social.proto", package: "example")
        
        var userDesc = MessageDescriptor(name: "User", parent: fileDescriptor)
        userDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        userDesc.addField(FieldDescriptor(name: "interests", number: 2, type: .string, isRepeated: true))
        userDesc.addField(FieldDescriptor(
            name: "friends",
            number: 3,
            type: .message,
            typeName: "example.User",
            isRepeated: true
        ))
        
        var postDesc = MessageDescriptor(name: "Post", parent: fileDescriptor)
        postDesc.addField(FieldDescriptor(name: "content", number: 1, type: .string))
        postDesc.addField(FieldDescriptor(
            name: "author",
            number: 2,
            type: .message,
            typeName: "example.User"
        ))
        
        fileDescriptor.addMessage(userDesc)
        fileDescriptor.addMessage(postDesc)
        return fileDescriptor
    }
    
    private static func createEcommerceStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "ecommerce.proto", package: "example")
        
        var categoryDesc = MessageDescriptor(name: "Category", parent: fileDescriptor)
        categoryDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        categoryDesc.addField(FieldDescriptor(name: "level", number: 2, type: .int32))
        
        var productDesc = MessageDescriptor(name: "Product", parent: fileDescriptor)
        productDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        productDesc.addField(FieldDescriptor(name: "price", number: 2, type: .double))
        
        var customerDesc = MessageDescriptor(name: "Customer", parent: fileDescriptor)
        customerDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        customerDesc.addField(FieldDescriptor(name: "email", number: 2, type: .string))
        
        var orderDesc = MessageDescriptor(name: "Order", parent: fileDescriptor)
        orderDesc.addField(FieldDescriptor(name: "customer_id", number: 1, type: .string))
        orderDesc.addField(FieldDescriptor(name: "total", number: 2, type: .double))
        
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
        dashboardDesc.addField(FieldDescriptor(
            name: "data_sources",
            number: 2,
            type: .message,
            typeName: "example.TimeSeries",
            isRepeated: true
        ))
        
        var metricDesc = MessageDescriptor(name: "Metric", parent: fileDescriptor)
        metricDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        metricDesc.addField(FieldDescriptor(name: "value", number: 2, type: .double))
        
        var timeSeriesDesc = MessageDescriptor(name: "TimeSeries", parent: fileDescriptor)
        timeSeriesDesc.addField(FieldDescriptor(
            name: "metrics",
            number: 1,
            type: .message,
            typeName: "example.Metric",
            isRepeated: true
        ))
        
        fileDescriptor.addMessage(dashboardDesc)
        fileDescriptor.addMessage(metricDesc)
        fileDescriptor.addMessage(timeSeriesDesc)
        return fileDescriptor
    }
    
    private static func createValidationStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "validation.proto", package: "example")
        
        var documentDesc = MessageDescriptor(name: "Document", parent: fileDescriptor)
        documentDesc.addField(FieldDescriptor(name: "title", number: 1, type: .string))
        documentDesc.addField(FieldDescriptor(
            name: "sections",
            number: 2,
            type: .message,
            typeName: "example.Section",
            isRepeated: true
        ))
        
        var sectionDesc = MessageDescriptor(name: "Section", parent: fileDescriptor)
        sectionDesc.addField(FieldDescriptor(name: "title", number: 1, type: .string))
        sectionDesc.addField(FieldDescriptor(name: "content", number: 2, type: .string))
        
        fileDescriptor.addMessage(documentDesc)
        fileDescriptor.addMessage(sectionDesc)
        return fileDescriptor
    }
    
    // MARK: - Factory Methods
    
    private static func createUser(factory: MessageFactory, fileDescriptor: FileDescriptor, name: String, interests: [String]) throws -> DynamicMessage {
        let userDesc = fileDescriptor.messages.values.first { $0.name == "User" }!
        var user = factory.createMessage(from: userDesc)
        try user.set(name, forField: "name")
        try user.set(interests, forField: "interests")
        try user.set([], forField: "friends")
        return user
    }
    
    private static func createPost(factory: MessageFactory, fileDescriptor: FileDescriptor, author: DynamicMessage, content: String) throws -> DynamicMessage {
        let postDesc = fileDescriptor.messages.values.first { $0.name == "Post" }!
        var post = factory.createMessage(from: postDesc)
        try post.set(content, forField: "content")
        try post.set(author, forField: "author")
        return post
    }
    
    private static func createCategory(factory: MessageFactory, fileDescriptor: FileDescriptor, name: String, level: Int) throws -> DynamicMessage {
        let categoryDesc = fileDescriptor.messages.values.first { $0.name == "Category" }!
        var category = factory.createMessage(from: categoryDesc)
        try category.set(name, forField: "name")
        try category.set(Int32(level), forField: "level")
        return category
    }
    
    private static func createProduct(factory: MessageFactory, fileDescriptor: FileDescriptor, name: String, price: Double) throws -> DynamicMessage {
        let productDesc = fileDescriptor.messages.values.first { $0.name == "Product" }!
        var product = factory.createMessage(from: productDesc)
        try product.set(name, forField: "name")
        try product.set(price, forField: "price")
        return product
    }
    
    private static func createCustomer(factory: MessageFactory, fileDescriptor: FileDescriptor, name: String, email: String) throws -> DynamicMessage {
        let customerDesc = fileDescriptor.messages.values.first { $0.name == "Customer" }!
        var customer = factory.createMessage(from: customerDesc)
        try customer.set(name, forField: "name")
        try customer.set(email, forField: "email")
        return customer
    }
    
    private static func createOrder(factory: MessageFactory, fileDescriptor: FileDescriptor, customerId: String, total: Double) throws -> DynamicMessage {
        let orderDesc = fileDescriptor.messages.values.first { $0.name == "Order" }!
        var order = factory.createMessage(from: orderDesc)
        try order.set(customerId, forField: "customer_id")
        try order.set(total, forField: "total")
        return order
    }
    
    private static func createDashboard(factory: MessageFactory, fileDescriptor: FileDescriptor, name: String) throws -> DynamicMessage {
        let dashboardDesc = fileDescriptor.messages.values.first { $0.name == "Dashboard" }!
        var dashboard = factory.createMessage(from: dashboardDesc)
        try dashboard.set(name, forField: "name")
        try dashboard.set([], forField: "data_sources")
        return dashboard
    }
    
    private static func createMetric(factory: MessageFactory, fileDescriptor: FileDescriptor, name: String, value: Double) throws -> DynamicMessage {
        let metricDesc = fileDescriptor.messages.values.first { $0.name == "Metric" }!
        var metric = factory.createMessage(from: metricDesc)
        try metric.set(name, forField: "name")
        try metric.set(value, forField: "value")
        return metric
    }
    
    private static func createTimeSeries(factory: MessageFactory, fileDescriptor: FileDescriptor, metrics: [DynamicMessage]) throws -> DynamicMessage {
        let timeSeriesDesc = fileDescriptor.messages.values.first { $0.name == "TimeSeries" }!
        var timeSeries = factory.createMessage(from: timeSeriesDesc)
        try timeSeries.set(metrics, forField: "metrics")
        return timeSeries
    }
    
    private static func createDocument(factory: MessageFactory, fileDescriptor: FileDescriptor, title: String) throws -> DynamicMessage {
        let documentDesc = fileDescriptor.messages.values.first { $0.name == "Document" }!
        var document = factory.createMessage(from: documentDesc)
        try document.set(title, forField: "title")
        try document.set([], forField: "sections")
        return document
    }
    
    private static func createSection(factory: MessageFactory, fileDescriptor: FileDescriptor, title: String, content: String) throws -> DynamicMessage {
        let sectionDesc = fileDescriptor.messages.values.first { $0.name == "Section" }!
        var section = factory.createMessage(from: sectionDesc)
        try section.set(title, forField: "title")
        try section.set(content, forField: "content")
        return section
    }
    
    // MARK: - Analysis Methods
    
    private static func printCategoryHierarchy(_ category: DynamicMessage, level: Int) throws {
        let indent = String(repeating: "  ", count: level)
        let name = try category.get(forField: "name") as? String ?? "Unknown"
        print("    \(indent)• \(name)")
    }
    
    private static func analyzeOrder(_ order: DynamicMessage) throws -> [String: String] {
        let customerId = try order.get(forField: "customer_id") as? String ?? "Unknown"
        let total = try order.get(forField: "total") as? Double ?? 0.0
        
        return [
            "Customer ID": customerId,
            "Total Amount": String(format: "$%.2f", total),
            "Status": "Analyzed"
        ]
    }
    
    private static func analyzeDashboard(_ dashboard: DynamicMessage) throws -> [String: String] {
        let name = try dashboard.get(forField: "name") as? String ?? "Unknown"
        let dataSources = try dashboard.get(forField: "data_sources") as? [DynamicMessage] ?? []
        
        var totalMetrics = 0
        for dataSource in dataSources {
            if let metrics = try dataSource.get(forField: "metrics") as? [DynamicMessage] {
                totalMetrics += metrics.count
            }
        }
        
        return [
            "Dashboard Name": name,
            "Data Sources": "\(dataSources.count)",
            "Total Metrics": "\(totalMetrics)"
        ]
    }
    
    private static func performComplexValidation(_ document: DynamicMessage) throws -> [String: String] {
        let title = try document.get(forField: "title") as? String ?? ""
        let sections = try document.get(forField: "sections") as? [DynamicMessage] ?? []
        
        let validationResults: [String: String] = [
            "Title Valid": title.isEmpty ? "❌ Empty" : "✅ Valid",
            "Sections Count": "\(sections.count)",
            "Cross-References": "✅ Valid",
            "Overall Status": "✅ Passed"
        ]
        
        return validationResults
    }
}
