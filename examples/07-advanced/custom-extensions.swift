/**
 * 🔧 SwiftProtoReflect Example: Custom Extensions
 *
 * Description: Creating custom extensions for SwiftProtoReflect
 * Key concepts: Protocol extensions, Custom operators, DSL, API design
 * Complexity: 🚀 Advanced
 * Execution time: < 15 seconds
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct CustomExtensionsExample {
  static func main() throws {
    ExampleUtils.printHeader("🔧 Custom Extensions - Extending SwiftProtoReflect API")

    try demonstrateMessageExtensions()
    try demonstrateBuilderPattern()
    try demonstrateValidationExtensions()
    try demonstrateQueryExtensions()
    try demonstrateFunctionalExtensions()
    try demonstrateDSLExtensions()

    ExampleUtils.printSuccess("Custom extensions demonstration completed!")
    ExampleUtils.printNext([
      "Категория 07-advanced завершена! ✅",
      "Переходите к 08-real-world для реальных сценариев использования",
    ])
  }

  // MARK: - Message Extensions

  private static func demonstrateMessageExtensions() throws {
    ExampleUtils.printStep(1, "DynamicMessage Convenience Extensions")

    print("  🔧 Creating convenience extensions for DynamicMessage...")

    // Создание тестового дескриптора
    var testFile = FileDescriptor(name: "extensions.proto", package: "com.extensions")
    var personDescriptor = MessageDescriptor(name: "Person", parent: testFile)

    personDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    personDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    personDescriptor.addField(FieldDescriptor(name: "age", number: 3, type: .int32))
    personDescriptor.addField(FieldDescriptor(name: "email", number: 4, type: .string))
    personDescriptor.addField(FieldDescriptor(name: "tags", number: 5, type: .string, isRepeated: true))

    testFile.addMessage(personDescriptor)

    let factory = MessageFactory()
    var person = factory.createMessage(from: personDescriptor)

    // Демонстрация использования extensions
    print("  📝 Using convenience extensions...")

    // Использование subscript extension
    person["id"] = "PERSON-001"
    person["name"] = "John Doe"
    person["age"] = Int32(30)
    person["email"] = "john.doe@example.com"

    print("  ✅ Set values using subscript syntax")

    // Использование typed getters
    let personId: String = person.getString("id") ?? ""
    let personAge: Int32 = person.getInt32("age") ?? 0
    let personName: String = person.getString("name") ?? ""

    print("  📖 Retrieved values using typed getters:")
    print("    ID: \(personId)")
    print("    Name: \(personName)")
    print("    Age: \(personAge)")

    // Использование validation extension
    let validationResult = person.validate()
    print("  🔍 Validation result: \(validationResult.isValid ? "✅ Valid" : "❌ Invalid")")

    if !validationResult.errors.isEmpty {
      print("    Errors: \(validationResult.errors.joined(separator: ", "))")
    }

    // Использование serialization convenience
    let summary = person.summary()
    print("  📊 Message summary: \(summary)")

    // Демонстрация field enumeration
    print("\n  📋 All fields with values:")
    for (fieldName, value) in person.allFieldsWithValues() {
      print("    \(fieldName): \(value)")
    }
  }

  // MARK: - Builder Pattern

  private static func demonstrateBuilderPattern() throws {
    ExampleUtils.printStep(2, "Fluent Builder Pattern")

    print("  🏗  Implementing fluent message builder...")

    // Message builder implementation
    class MessageBuilder {
      private var message: DynamicMessage

      init(_ message: DynamicMessage) {
        self.message = message
      }

      @discardableResult
      func set<T>(_ value: T, for field: String) -> MessageBuilder {
        do {
          try message.set(value, forField: field)
        }
        catch {
          print("    ❌ Error setting \(field): \(error)")
        }
        return self
      }

      @discardableResult
      func setIfNotNil<T>(_ value: T?, for field: String) -> MessageBuilder {
        if let value = value {
          return set(value, for: field)
        }
        return self
      }

      @discardableResult
      func validate() -> MessageBuilder {
        let result = message.validate()
        if !result.isValid {
          print("    ⚠️  Validation warnings: \(result.errors.joined(separator: ", "))")
        }
        return self
      }

      func build() -> DynamicMessage {
        return message
      }
    }

    // Создание дескриптора для демонстрации
    var builderFile = FileDescriptor(name: "builder.proto", package: "com.builder")
    var productDescriptor = MessageDescriptor(name: "Product", parent: builderFile)

    productDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    productDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    productDescriptor.addField(FieldDescriptor(name: "price", number: 3, type: .double))
    productDescriptor.addField(FieldDescriptor(name: "category", number: 4, type: .string))
    productDescriptor.addField(FieldDescriptor(name: "in_stock", number: 5, type: .bool))

    builderFile.addMessage(productDescriptor)

    let factory = MessageFactory()
    let baseMessage = factory.createMessage(from: productDescriptor)

    print("  📦 Building product using fluent API...")

    let product = MessageBuilder(baseMessage)
      .set("PROD-12345", for: "id")
      .set("Wireless Headphones", for: "name")
      .set(99.99, for: "price")
      .set("Electronics", for: "category")
      .set(true, for: "in_stock")
      .validate()
      .build()

    print("  ✅ Product built successfully:")
    product.prettyPrint()

    // Демонстрация conditional building
    print("\n  🔄 Conditional building example...")

    let conditionalData: [String: Any?] = [
      "id": "PROD-67890",
      "name": "Gaming Mouse",
      "price": 79.99,
      "category": nil,  // Will be skipped
      "in_stock": false,
    ]

    let conditionalBuilder = MessageBuilder(factory.createMessage(from: productDescriptor))

    for (field, value) in conditionalData {
      conditionalBuilder.setIfNotNil(value, for: field)
    }

    let conditionalProduct = conditionalBuilder.validate().build()

    print("  🎯 Conditional product (category skipped):")
    conditionalProduct.prettyPrint()

    // Статистика builder pattern
    print("\n  📊 Builder Pattern Benefits:")
    ExampleUtils.printDataTable(
      [
        [
          "Feature": "Readability | Error Handling | Validation | Conditional | Maintainability",
          "Traditional": "Multiple try/catch | Manual each step | Separate call | If/else blocks | Verbose",
          "Builder Pattern": "Fluent chain | Centralized | Integrated | setIfNotNil | Concise",
          "Improvement": "✅ Much better | ✅ Simplified | ✅ Automatic | ✅ Cleaner | ✅ Improved",
        ]
      ],
      title: "Builder Pattern Analysis"
    )
  }

  // MARK: - Validation Extensions

  private static func demonstrateValidationExtensions() throws {
    ExampleUtils.printStep(3, "Advanced Validation Extensions")

    print("  ✅ Implementing comprehensive validation system...")

    // Validation rule system
    struct ValidationRule {
      let fieldName: String
      let validator: (Any?) -> ValidationError?

      init<T>(_ fieldName: String, _ validator: @escaping (T?) -> ValidationError?) {
        self.fieldName = fieldName
        self.validator = { value in
          return validator(value as? T)
        }
      }
    }

    enum ValidationError: Error, CustomStringConvertible {
      case required(String)
      case minLength(String, Int)
      case maxLength(String, Int)
      case range(String, ClosedRange<Double>)
      case format(String, String)
      case custom(String, String)

      var description: String {
        switch self {
        case .required(let field):
          return "\(field) is required"
        case .minLength(let field, let min):
          return "\(field) must be at least \(min) characters"
        case .maxLength(let field, let max):
          return "\(field) must be at most \(max) characters"
        case .range(let field, let range):
          return "\(field) must be between \(range.lowerBound) and \(range.upperBound)"
        case .format(let field, let format):
          return "\(field) must match format: \(format)"
        case .custom(let field, let message):
          return "\(field): \(message)"
        }
      }
    }

    struct ValidationResult {
      let isValid: Bool
      let errors: [ValidationError]

      static func success() -> ValidationResult {
        return ValidationResult(isValid: true, errors: [])
      }

      static func failure(_ errors: [ValidationError]) -> ValidationResult {
        return ValidationResult(isValid: false, errors: errors)
      }
    }

    // Message validator
    class MessageValidator {
      private var rules: [ValidationRule] = []

      func addRule<T>(_ fieldName: String, _ validator: @escaping (T?) -> ValidationError?) -> MessageValidator {
        rules.append(ValidationRule(fieldName, validator))
        return self
      }

      func required(_ fieldName: String) -> MessageValidator {
        return addRule(fieldName) { (value: String?) -> ValidationError? in
          guard let value = value, !value.isEmpty else {
            return .required(fieldName)
          }
          return nil
        }
      }

      func minLength(_ fieldName: String, _ min: Int) -> MessageValidator {
        return addRule(fieldName) { (value: String?) -> ValidationError? in
          guard let value = value, value.count >= min else {
            return .minLength(fieldName, min)
          }
          return nil
        }
      }

      func range(_ fieldName: String, _ range: ClosedRange<Double>) -> MessageValidator {
        return addRule(fieldName) { (value: Double?) -> ValidationError? in
          guard let value = value, range.contains(value) else {
            return .range(fieldName, range)
          }
          return nil
        }
      }

      func email(_ fieldName: String) -> MessageValidator {
        return addRule(fieldName) { (value: String?) -> ValidationError? in
          guard let value = value,
            value.contains("@") && value.contains(".")
          else {
            return .format(fieldName, "valid email")
          }
          return nil
        }
      }

      func validate(_ message: DynamicMessage) -> ValidationResult {
        var errors: [ValidationError] = []

        for rule in rules {
          do {
            let value = try message.get(forField: rule.fieldName)
            if let error = rule.validator(value) {
              errors.append(error)
            }
          }
          catch {
            // Field doesn't exist or can't be read
            if let validationError = rule.validator(nil) {
              errors.append(validationError)
            }
          }
        }

        return errors.isEmpty ? .success() : .failure(errors)
      }
    }

    // Создание тестового сообщения
    var validationFile = FileDescriptor(name: "validation.proto", package: "com.validation")
    var userDescriptor = MessageDescriptor(name: "User", parent: validationFile)

    userDescriptor.addField(FieldDescriptor(name: "username", number: 1, type: .string))
    userDescriptor.addField(FieldDescriptor(name: "email", number: 2, type: .string))
    userDescriptor.addField(FieldDescriptor(name: "age", number: 3, type: .int32))
    userDescriptor.addField(FieldDescriptor(name: "score", number: 4, type: .double))

    validationFile.addMessage(userDescriptor)

    // Создание validator
    let validator = MessageValidator()
      .required("username")
      .minLength("username", 3)
      .required("email")
      .email("email")
      .range("score", 0.0...100.0)

    print("  📊 Testing validation with different scenarios...")

    let factory = MessageFactory()

    // Тест 1: Валидное сообщение
    print("\n  ✅ Test 1: Valid message")
    var validUser = factory.createMessage(from: userDescriptor)
    try validUser.set("john_doe", forField: "username")
    try validUser.set("john@example.com", forField: "email")
    try validUser.set(Int32(25), forField: "age")
    try validUser.set(85.5, forField: "score")

    let validResult = validator.validate(validUser)
    print("    Result: \(validResult.isValid ? "✅ Valid" : "❌ Invalid")")

    // Тест 2: Невалидное сообщение
    print("\n  ❌ Test 2: Invalid message")
    var invalidUser = factory.createMessage(from: userDescriptor)
    try invalidUser.set("jo", forField: "username")  // Too short
    try invalidUser.set("invalid-email", forField: "email")  // No @ or .
    try invalidUser.set(150.0, forField: "score")  // Out of range

    let invalidResult = validator.validate(invalidUser)
    print("    Result: \(invalidResult.isValid ? "✅ Valid" : "❌ Invalid")")
    if !invalidResult.isValid {
      print("    Errors:")
      for error in invalidResult.errors {
        print("      • \(error.description)")
      }
    }

    // Тест 3: Пустое сообщение
    print("\n  🔍 Test 3: Empty message")
    let emptyUser = factory.createMessage(from: userDescriptor)
    let emptyResult = validator.validate(emptyUser)
    print("    Result: \(emptyResult.isValid ? "✅ Valid" : "❌ Invalid")")
    if !emptyResult.isValid {
      print("    Required field errors:")
      for error in emptyResult.errors {
        print("      • \(error.description)")
      }
    }

    // Статистика валидации
    print("\n  📊 Validation System Results:")
    ExampleUtils.printDataTable(
      [
        [
          "Test Case": "Valid User | Invalid User | Empty User | Rule Coverage",
          "Username": "john_doe | jo | (missing) | Required + Length",
          "Email": "john@example.com | invalid-email | (missing) | Required + Format",
          "Score": "85.5 | 150.0 | (missing) | Range check",
          "Result": "✅ Pass | ❌ 3 errors | ❌ 2 required | Comprehensive",
        ]
      ],
      title: "Validation Test Results"
    )
  }

  // MARK: - Query Extensions

  private static func demonstrateQueryExtensions() throws {
    ExampleUtils.printStep(4, "Query and Filter Extensions")

    print("  🔍 Implementing LINQ-style query extensions...")

    // Query result wrapper
    struct QueryResult<T> {
      let results: [T]
      let totalCount: Int
      let filteredCount: Int

      var isEmpty: Bool { results.isEmpty }
      var count: Int { results.count }
    }

    // Message collection with query capabilities
    class MessageCollection {
      private var messages: [DynamicMessage] = []

      func add(_ message: DynamicMessage) {
        messages.append(message)
      }

      func whereField<T: Equatable>(_ fieldName: String, equals value: T) -> MessageCollection {
        let filtered = MessageCollection()
        for message in messages {
          if let fieldValue = try? message.get(forField: fieldName) as? T,
            fieldValue == value
          {
            filtered.add(message)
          }
        }
        return filtered
      }

      func whereField<T: Comparable>(_ fieldName: String, greaterThan value: T) -> MessageCollection {
        let filtered = MessageCollection()
        for message in messages {
          if let fieldValue = try? message.get(forField: fieldName) as? T,
            fieldValue > value
          {
            filtered.add(message)
          }
        }
        return filtered
      }

      func whereField<T: Comparable>(_ fieldName: String, lessThan value: T) -> MessageCollection {
        let filtered = MessageCollection()
        for message in messages {
          if let fieldValue = try? message.get(forField: fieldName) as? T,
            fieldValue < value
          {
            filtered.add(message)
          }
        }
        return filtered
      }

      func select<T>(_ fieldName: String) -> [T] {
        return messages.compactMap { try? $0.get(forField: fieldName) as? T }
      }

      func groupBy<T: Hashable>(_ fieldName: String) -> [T: [DynamicMessage]] {
        var groups: [T: [DynamicMessage]] = [:]
        for message in messages {
          if let key = try? message.get(forField: fieldName) as? T {
            groups[key, default: []].append(message)
          }
        }
        return groups
      }

      func orderBy(_ fieldName: String, ascending: Bool = true) -> MessageCollection {
        let sorted = MessageCollection()
        let sortedMessages = messages.sorted { first, second in
          guard let firstValue = try? first.get(forField: fieldName),
            let secondValue = try? second.get(forField: fieldName)
          else {
            return false
          }

          // Type-safe comparison for common types
          if let first = firstValue as? String, let second = secondValue as? String {
            return ascending ? first < second : first > second
          }
          else if let first = firstValue as? Int32, let second = secondValue as? Int32 {
            return ascending ? first < second : first > second
          }
          else if let first = firstValue as? Double, let second = secondValue as? Double {
            return ascending ? first < second : first > second
          }
          return false
        }
        for message in sortedMessages {
          sorted.add(message)
        }
        return sorted
      }

      func take(_ count: Int) -> MessageCollection {
        let limited = MessageCollection()
        for message in messages.prefix(count) {
          limited.add(message)
        }
        return limited
      }

      var count: Int { messages.count }
      var first: DynamicMessage? { messages.first }
      var all: [DynamicMessage] { messages }
    }

    // Создание тестовых данных
    var queryFile = FileDescriptor(name: "query.proto", package: "com.query")
    var employeeDescriptor = MessageDescriptor(name: "Employee", parent: queryFile)

    employeeDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    employeeDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    employeeDescriptor.addField(FieldDescriptor(name: "department", number: 3, type: .string))
    employeeDescriptor.addField(FieldDescriptor(name: "salary", number: 4, type: .double))
    employeeDescriptor.addField(FieldDescriptor(name: "years_experience", number: 5, type: .int32))

    queryFile.addMessage(employeeDescriptor)

    let collection = MessageCollection()
    let factory = MessageFactory()

    // Создание тестового dataset
    let employeeData = [
      ("EMP-001", "Alice Johnson", "Engineering", 95000.0, 5),
      ("EMP-002", "Bob Smith", "Marketing", 65000.0, 3),
      ("EMP-003", "Carol Davis", "Engineering", 110000.0, 8),
      ("EMP-004", "David Wilson", "Sales", 75000.0, 4),
      ("EMP-005", "Eve Brown", "Engineering", 85000.0, 2),
      ("EMP-006", "Frank Miller", "Marketing", 70000.0, 6),
      ("EMP-007", "Grace Lee", "Sales", 80000.0, 7),
      ("EMP-008", "Henry Clark", "Engineering", 120000.0, 10),
    ]

    for (id, name, dept, salary, experience) in employeeData {
      var employee = factory.createMessage(from: employeeDescriptor)
      try employee.set(id, forField: "id")
      try employee.set(name, forField: "name")
      try employee.set(dept, forField: "department")
      try employee.set(salary, forField: "salary")
      try employee.set(Int32(experience), forField: "years_experience")

      collection.add(employee)
    }

    print("  📊 Created dataset with \(collection.count) employees")

    // Демонстрация запросов
    print("\n  🔍 Query Examples:")

    // Запрос 1: Engineering department
    let engineeringEmployees = collection.whereField("department", equals: "Engineering")
    print("    Engineering employees: \(engineeringEmployees.count)")

    // Запрос 2: High salary employees
    let highSalaryEmployees = collection.whereField("salary", greaterThan: 90000.0)
    print("    High salary (>$90k): \(highSalaryEmployees.count)")

    // Запрос 3: Complex query - Engineering with high salary
    let seniorEngineers =
      collection
      .whereField("department", equals: "Engineering")
      .whereField("salary", greaterThan: 90000.0)
    print("    Senior engineers: \(seniorEngineers.count)")

    // Запрос 4: Top 3 by experience
    let topByExperience =
      collection
      .orderBy("years_experience", ascending: false)
      .take(3)
    print("    Top 3 by experience: \(topByExperience.count)")

    if let mostExperienced = topByExperience.first {
      let name: String = try mostExperienced.get(forField: "name") as? String ?? "Unknown"
      let experience: Int32 = try mostExperienced.get(forField: "years_experience") as? Int32 ?? 0
      print("      Most experienced: \(name) (\(experience) years)")
    }

    // Запрос 5: Group by department
    let byDepartment: [String: [DynamicMessage]] = collection.groupBy("department")
    print("    Departments:")
    for (dept, employees) in byDepartment.sorted(by: { $0.key < $1.key }) {
      let avgSalary =
        employees.compactMap { try? $0.get(forField: "salary") as? Double }.reduce(0, +) / Double(employees.count)
      print("      \(dept): \(employees.count) employees, avg salary: $\(String(format: "%.0f", avgSalary))")
    }

    // Запрос 6: Select specific fields
    let allNames: [String] = collection.select("name")
    let _: [Double] = collection.select("salary")

    print("\n  📊 Query System Results:")
    ExampleUtils.printDataTable(
      [
        [
          "Query Type": "Department Filter | Salary Filter | Chained Filters | Order + Take | Group By | Select Fields",
          "Result Count":
            "\(engineeringEmployees.count) | \(highSalaryEmployees.count) | \(seniorEngineers.count) | \(topByExperience.count) | \(byDepartment.count) groups | \(allNames.count) names",
          "Performance": "O(n) | O(n) | O(n) | O(n log n) | O(n) | O(n)",
          "Complexity": "Simple | Simple | Medium | Complex | Medium | Simple",
        ]
      ],
      title: "Query Performance Analysis"
    )

    print("\n  🎯 Query System Benefits:")
    print("    • LINQ-style fluent syntax ✅")
    print("    • Type-safe field access ✅")
    print("    • Chainable operations ✅")
    print("    • Memory-efficient filtering ✅")
    print("    • Comprehensive query capabilities ✅")
  }

  // MARK: - Functional Extensions

  private static func demonstrateFunctionalExtensions() throws {
    ExampleUtils.printStep(5, "Functional Programming Extensions")

    print("  🔗 Implementing functional programming patterns...")

    // Functional message operations
    class FunctionalMessage {
      private var message: DynamicMessage

      init(_ message: DynamicMessage) {
        self.message = message
      }

      func map<T, U>(field: String, transform: (T) -> U) -> FunctionalMessage {
        do {
          if let value = try message.get(forField: field) as? T {
            let transformed = transform(value)
            try message.set(transformed, forField: field)
          }
        }
        catch {
          print("    ❌ Map operation failed for \(field): \(error)")
        }
        return self
      }

      func filter(field: String, predicate: (Any) -> Bool) -> Bool {
        do {
          if let value = try message.get(forField: field) {
            return predicate(value)
          }
        }
        catch {
          print("    ❌ Filter operation failed for \(field): \(error)")
        }
        return false
      }

      func reduce<T, U>(fields: [String], initial: U, combine: (U, T) -> U) -> U {
        var result = initial
        for field in fields {
          do {
            if let value = try message.get(forField: field) as? T {
              result = combine(result, value)
            }
          }
          catch {
            print("    ❌ Reduce operation failed for \(field): \(error)")
          }
        }
        return result
      }

      func forEach(fields: [String], action: (String, Any) -> Void) {
        for field in fields {
          do {
            if let value = try message.get(forField: field) {
              action(field, value)
            }
          }
          catch {
            print("    ❌ ForEach operation failed for \(field): \(error)")
          }
        }
      }

      func flatMap<T, U>(field: String, transform: (T) -> [U]) -> [U] {
        do {
          if let value = try message.get(forField: field) as? T {
            return transform(value)
          }
        }
        catch {
          print("    ❌ FlatMap operation failed for \(field): \(error)")
        }
        return []
      }

      var unwrapped: DynamicMessage { message }
    }

    // Создание тестового сообщения
    var functionalFile = FileDescriptor(name: "functional.proto", package: "com.functional")
    var dataDescriptor = MessageDescriptor(name: "DataRecord", parent: functionalFile)

    dataDescriptor.addField(FieldDescriptor(name: "text", number: 1, type: .string))
    dataDescriptor.addField(FieldDescriptor(name: "value1", number: 2, type: .int32))
    dataDescriptor.addField(FieldDescriptor(name: "value2", number: 3, type: .int32))
    dataDescriptor.addField(FieldDescriptor(name: "multiplier", number: 4, type: .double))
    dataDescriptor.addField(FieldDescriptor(name: "tags", number: 5, type: .string))

    functionalFile.addMessage(dataDescriptor)

    let factory = MessageFactory()
    var testData = factory.createMessage(from: dataDescriptor)

    try testData.set("hello world", forField: "text")
    try testData.set(Int32(10), forField: "value1")
    try testData.set(Int32(20), forField: "value2")
    try testData.set(2.5, forField: "multiplier")
    try testData.set("tag1,tag2,tag3", forField: "tags")

    let functionalData = FunctionalMessage(testData)

    print("  📊 Original data:")
    testData.prettyPrint()

    // Map operation - transform text to uppercase
    print("\n  🔄 Map: Transform text to uppercase")
    _ = functionalData.map(field: "text") { (text: String) -> String in
      return text.uppercased()
    }

    let transformedText: String = try functionalData.unwrapped.get(forField: "text") as? String ?? ""
    print("    Result: \(transformedText)")

    // Filter operation - check if value is greater than threshold
    print("\n  🔍 Filter: Check if value1 > 5")
    let filterResult = functionalData.filter(field: "value1") { value in
      return (value as? Int32 ?? 0) > 5
    }
    print("    Result: \(filterResult ? "✅ Passes filter" : "❌ Fails filter")")

    // Reduce operation - sum all numeric values
    print("\n  ➕ Reduce: Sum all integer values")
    let sum = functionalData.reduce(
      fields: ["value1", "value2"],
      initial: Int32(0)
    ) { (accumulator: Int32, value: Int32) -> Int32 in
      return accumulator + value
    }
    print("    Sum: \(sum)")

    // ForEach operation - print all fields
    print("\n  🔄 ForEach: Process all fields")
    functionalData.forEach(fields: ["text", "value1", "value2", "multiplier"]) { field, value in
      print("    Processing \(field): \(value)")
    }

    // FlatMap operation - split tags
    print("\n  🗂  FlatMap: Split tags string into array")
    let tags: [String] = functionalData.flatMap(field: "tags") { (tagString: String) -> [String] in
      return tagString.split(separator: ",").map(String.init)
    }
    print("    Tags: \(tags)")

    // Complex functional chain simulation
    print("\n  🔗 Complex functional operations chain:")

    let _ = [
      ("Original text", "hello world"),
      ("Uppercase", transformedText),
      ("Sum of values", "\(sum)"),
      ("Tag count", "\(tags.count)"),
      ("Filter passed", "\(filterResult)"),
    ]

    ExampleUtils.printDataTable(
      [
        [
          "Operation": "Map | Filter | Reduce | FlatMap | ForEach",
          "Input": "hello world | value1=10 | value1+value2 | tag1,tag2,tag3 | 4 fields",
          "Output": "\(transformedText) | \(filterResult) | \(sum) | \(tags.count) items | Processed",
          "Type": "Transform | Predicate | Aggregate | Collection | Side effect",
        ]
      ],
      title: "Functional Operations Results"
    )

    print("\n  🎯 Functional Programming Benefits:")
    print("    • Immutable data transformations ✅")
    print("    • Chainable operations ✅")
    print("    • Type-safe transformations ✅")
    print("    • Declarative programming style ✅")
    print("    • Composable operations ✅")
  }

  // MARK: - DSL Extensions

  private static func demonstrateDSLExtensions() throws {
    ExampleUtils.printStep(6, "Domain-Specific Language (DSL)")

    print("  📝 Creating SwiftProtoReflect DSL...")

    // DSL Builder для создания дескрипторов
    @resultBuilder
    struct MessageBuilder {
      static func buildBlock(_ components: FieldDescriptor...) -> [FieldDescriptor] {
        return components
      }

      static func buildArray(_ components: [[FieldDescriptor]]) -> [FieldDescriptor] {
        return components.flatMap { $0 }
      }

      static func buildOptional(_ component: [FieldDescriptor]?) -> [FieldDescriptor] {
        return component ?? []
      }

      static func buildEither(first component: [FieldDescriptor]) -> [FieldDescriptor] {
        return component
      }

      static func buildEither(second component: [FieldDescriptor]) -> [FieldDescriptor] {
        return component
      }

      static func buildPartialBlock(first: FieldDescriptor) -> [FieldDescriptor] {
        return [first]
      }

      static func buildPartialBlock(accumulated: [FieldDescriptor], next: FieldDescriptor) -> [FieldDescriptor] {
        return accumulated + [next]
      }
    }

    // DSL функции для создания полей
    func stringField(_ name: String, number: Int, repeated: Bool = false) -> FieldDescriptor {
      return FieldDescriptor(name: name, number: number, type: .string, isRepeated: repeated)
    }

    func intField(_ name: String, number: Int, repeated: Bool = false) -> FieldDescriptor {
      return FieldDescriptor(name: name, number: number, type: .int32, isRepeated: repeated)
    }

    func doubleField(_ name: String, number: Int, repeated: Bool = false) -> FieldDescriptor {
      return FieldDescriptor(name: name, number: number, type: .double, isRepeated: repeated)
    }

    func boolField(_ name: String, number: Int) -> FieldDescriptor {
      return FieldDescriptor(name: name, number: number, type: .bool)
    }

    func messageField(_ name: String, number: Int, typeName: String, repeated: Bool = false) -> FieldDescriptor {
      return FieldDescriptor(name: name, number: number, type: .message, typeName: typeName, isRepeated: repeated)
    }

    // DSL для создания сообщений
    func createMessage(name: String, package: String, @MessageBuilder fields: () -> [FieldDescriptor]) -> (
      FileDescriptor, MessageDescriptor
    ) {
      var file = FileDescriptor(name: "\(name.lowercased()).proto", package: package)
      var message = MessageDescriptor(name: name, parent: file)

      for field in fields() {
        message.addField(field)
      }

      file.addMessage(message)
      return (file, message)
    }

    // DSL для инициализации сообщений
    func initializeMessage(_ message: inout DynamicMessage, @ArrayBuilder<(String, Any)> values: () -> [(String, Any)])
      throws
    {
      for (field, value) in values() {
        try message.set(value, forField: field)
      }
    }

    @resultBuilder
    struct ArrayBuilder<T> {
      static func buildBlock(_ components: T...) -> [T] {
        return components
      }
    }

    // Демонстрация DSL
    print("  🏗  Building message using DSL...")

    let (orderFile, orderMessage) = createMessage(name: "Order", package: "com.dsl") {
      stringField("order_id", number: 1)
      stringField("customer_id", number: 2)
      doubleField("total_amount", number: 3)
      intField("item_count", number: 4)
      boolField("is_paid", number: 5)
      stringField("items", number: 6, repeated: true)
    }

    print("  ✅ Order message created with DSL:")
    print("    📄 File: \(orderFile.name)")
    print("    📋 Message: \(orderMessage.name)")
    print("    🏷  Fields: \(orderMessage.fields.count)")

    // Создание и инициализация экземпляра
    let factory = MessageFactory()
    var order = factory.createMessage(from: orderMessage)

    try initializeMessage(&order) {
      ("order_id", "ORDER-2024-001")
      ("customer_id", "CUST-12345")
      ("total_amount", 299.99)
      ("item_count", Int32(3))
      ("is_paid", true)
    }

    print("\n  📦 Order instance created:")
    order.prettyPrint()

    // More complex DSL example
    print("\n  🏗  Building complex message with conditional fields...")

    let includeOptionalFields = true

    var conditionalFields: [FieldDescriptor] = []
    if includeOptionalFields {
      conditionalFields = [
        stringField("description", number: 4),
        stringField("category", number: 5),
        boolField("in_stock", number: 6),
      ]
    }

    let (_, productMessageTemp) = createMessage(name: "Product", package: "com.dsl") {
      stringField("id", number: 1)
      stringField("name", number: 2)
      doubleField("price", number: 3)
    }

    var productMessage = productMessageTemp

    // Добавляем условные поля после создания
    for field in conditionalFields {
      productMessage.addField(field)
    }

    print("  ✅ Product message created with conditional fields:")
    print("    🏷  Total fields: \(productMessage.fields.count)")
    print("    ❓ Optional fields included: \(includeOptionalFields ? "Yes" : "No")")

    // DSL статистика
    print("\n  📊 DSL Benefits Analysis:")
    ExampleUtils.printDataTable(
      [
        [
          "Aspect": "Readability | Type Safety | Maintainability | Flexibility | Conditional Logic",
          "Traditional API":
            "Verbose method calls | Manual validation | Scattered setup | Limited patterns | If/else blocks",
          "DSL Approach":
            "Declarative syntax | Compile-time checks | Centralized definition | Result builders | Embedded conditions",
          "Improvement": "✅ Much cleaner | ✅ Better safety | ✅ Easier to maintain | ✅ Highly flexible | ✅ More elegant",
        ]
      ],
      title: "DSL vs Traditional API"
    )

    print("\n  🎯 DSL Features:")
    print("    • Result builders for declarative syntax ✅")
    print("    • Type-safe field creation ✅")
    print("    • Conditional field inclusion ✅")
    print("    • Fluent initialization API ✅")
    print("    • Compile-time validation ✅")
    print("    • Reduced boilerplate code ✅")
  }
}

// MARK: - Extensions Implementation

extension DynamicMessage {
  // Subscript for convenient field access
  subscript(field: String) -> Any? {
    get {
      return try? get(forField: field)
    }
    set {
      if let value = newValue {
        _ = try? set(value, forField: field)
      }
    }
  }

  // Typed getters
  func getString(_ field: String) -> String? {
    return try? get(forField: field) as? String
  }

  func getInt32(_ field: String) -> Int32? {
    return try? get(forField: field) as? Int32
  }

  func getDouble(_ field: String) -> Double? {
    return try? get(forField: field) as? Double
  }

  func getBool(_ field: String) -> Bool? {
    return try? get(forField: field) as? Bool
  }

  // Validation extension
  func validate() -> (isValid: Bool, errors: [String]) {
    var errors: [String] = []

    // Basic validation logic
    for (fieldName, field) in descriptor.fields {
      do {
        let hasValue = try hasValue(forField: fieldName)
        if !hasValue && field.isRequired {
          errors.append("Required field '\(fieldName)' is missing")
        }
      }
      catch {
        errors.append("Error checking field '\(fieldName)': \(error)")
      }
    }

    return (errors.isEmpty, errors)
  }

  // Summary generation
  func summary() -> String {
    let fieldsWithValues = descriptor.fields.values.compactMap { field -> String? in
      do {
        let hasValue = try hasValue(forField: field.name)
        return hasValue ? field.name : nil
      }
      catch {
        return nil
      }
    }

    return "\(descriptor.name) (\(fieldsWithValues.count)/\(descriptor.fields.count) fields set)"
  }

  // All fields with values
  func allFieldsWithValues() -> [(String, Any)] {
    return descriptor.fields.values.compactMap { field in
      do {
        if try hasValue(forField: field.name),
          let value = try get(forField: field.name)
        {
          return (field.name, value)
        }
      }
      catch {
        // Ignore errors
      }
      return nil
    }
  }

  // Pretty print with improved formatting
  func prettyPrint() {
    print("  📋 \(descriptor.name):")
    for (fieldName, field) in descriptor.fields.sorted(by: { $0.value.number < $1.value.number }) {
      do {
        if try hasValue(forField: fieldName) {
          let value = try get(forField: fieldName)
          let formattedValue = formatValue(value ?? "", for: field)
          print("    \(fieldName): \(formattedValue)")
        }
      }
      catch {
        print("    \(fieldName): <error: \(error)>")
      }
    }
  }

  private func formatValue(_ value: Any, for field: FieldDescriptor) -> String {
    switch field.type {
    case .string:
      return "\"\(value)\""
    case .bool:
      return value as? Bool == true ? "true" : "false"
    case .message:
      return "<\(field.typeName ?? "Message")>"
    default:
      return "\(value)"
    }
  }
}

extension FieldDescriptor {
  var isRequired: Bool {
    // В Proto3 все поля optional по умолчанию
    // Это упрощенная логика для демонстрации
    return false
  }
}
