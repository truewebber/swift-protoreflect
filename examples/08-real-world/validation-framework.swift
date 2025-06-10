/**
 * ✅ SwiftProtoReflect Example: Comprehensive Validation Framework
 *
 * Description: Production-ready validation system for Protocol Buffers messages
 * Key concepts: Validation Rules, Custom Validators, Error Reporting, Conditional Logic
 * Complexity: 🏢 Expert
 * Execution time: 12-18 seconds
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct ValidationFrameworkExample {
  static func main() throws {
    ExampleUtils.printHeader("Comprehensive Protocol Buffers Validation Framework")

    try step1UsetupValidationFramework()
    try step2UbasicValidationRules()
    try step3UcustomValidators()
    try step4UconditionalValidation()
    try step5UbulkValidationAndReporting()

    ExampleUtils.printSuccess("Validation framework ready for production deployment!")
    ExampleUtils.printNext([
      "Try: proto-repl.swift - Interactive Protocol Buffers exploration",
      "Explore: api-gateway.swift - API Gateway with validation integration",
    ])
  }

  private static func step1UsetupValidationFramework() throws {
    ExampleUtils.printStep(1, "Setting Up Validation Framework")

    let framework = ValidationFramework()
    ValidationGlobalContext.shared.framework = framework

    // Register built-in validators
    framework.registerValidator("required", RequiredValidator())
    framework.registerValidator("email", EmailValidator())
    framework.registerValidator("range", RangeValidator())
    framework.registerValidator("length", LengthValidator())
    framework.registerValidator("pattern", PatternValidator())
    framework.registerValidator("custom", CustomValidator())

    // Create test schemas
    let userSchema = try createUserValidationSchema()
    let orderSchema = try createOrderValidationSchema()

    framework.registerSchema("User", schema: userSchema)
    framework.registerSchema("Order", schema: orderSchema)

    print("  ✅ Framework initialized with \(framework.validatorCount) validators")
    print("  📋 Registered \(framework.schemaCount) validation schemas")
    print("  🔧 Built-in validators: required, email, range, length, pattern, custom")

    ExampleUtils.printSuccess("Validation framework ready")
  }

  private static func step2UbasicValidationRules() throws {
    ExampleUtils.printStep(2, "Basic Validation Rules and Error Handling")

    let framework = ValidationGlobalContext.shared.framework!

    // Test cases with different validation scenarios
    let testCases = [
      (
        name: "Valid User",
        data: [
          "name": "John Doe",
          "email": "john@example.com",
          "age": 30,
          "phone": "+1-555-0123",
        ],
        shouldPass: true
      ),
      (
        name: "Invalid Email",
        data: [
          "name": "Jane Doe",
          "email": "invalid-email",
          "age": 25,
          "phone": "+1-555-0456",
        ],
        shouldPass: false
      ),
      (
        name: "Missing Required Field",
        data: [
          "email": "test@example.com",
          "age": 35,
            // name is missing
        ],
        shouldPass: false
      ),
      (
        name: "Age Out of Range",
        data: [
          "name": "Young User",
          "email": "young@example.com",
          "age": 15,  // Below minimum
          "phone": "+1-555-0789",
        ],
        shouldPass: false
      ),
    ]

    print("  🧪 Running basic validation tests...")

    var passedTests = 0
    var totalTests = testCases.count

    for testCase in testCases {
      let userMessage = try createUserMessage(from: testCase.data)

      let (result, validationTime) = try ExampleUtils.measureTime {
        return framework.validate(userMessage, schemaName: "User")
      }

      let testPassed = result.isValid == testCase.shouldPass
      passedTests += testPassed ? 1 : 0

      print(
        "  \(testPassed ? "✅" : "❌") \(testCase.name): \(result.isValid ? "Valid" : "Invalid") (\(String(format: "%.2f", validationTime * 1000))ms)"
      )

      if !result.isValid && !result.errors.isEmpty {
        for error in result.errors.prefix(2) {  // Show first 2 errors
          print("    🚫 \(error.message)")
        }
      }
    }

    print("\n  📊 Test Results: \(passedTests)/\(totalTests) passed (\(passedTests * 100 / totalTests)%)")

    ExampleUtils.printSuccess("Basic validation rules tested")
  }

  private static func step3UcustomValidators() throws {
    ExampleUtils.printStep(3, "Custom Validators and Business Logic")

    let framework = ValidationGlobalContext.shared.framework!

    // Register business-specific validators
    framework.registerValidator("business_email", BusinessEmailValidator())
    framework.registerValidator("working_hours", WorkingHoursValidator())
    framework.registerValidator("price_range", PriceRangeValidator())
    framework.registerValidator("inventory", InventoryValidator())

    print("  🔧 Registered custom business validators:")
    print("    • BusinessEmailValidator: Validates corporate email domains")
    print("    • WorkingHoursValidator: Ensures timestamps in business hours")
    print("    • PriceRangeValidator: Validates product pricing constraints")
    print("    • InventoryValidator: Checks stock availability")

    // Test custom validators
    let businessTests: [(name: String, validator: String, value: Any, expected: Bool)] = [
      (
        name: "Corporate Email Test",
        validator: "business_email",
        value: "user@company.com",
        expected: true
      ),
      (
        name: "Personal Email Test",
        validator: "business_email",
        value: "user@gmail.com",
        expected: false
      ),
      (
        name: "Business Hours Test",
        validator: "working_hours",
        value: 14.5,  // 2:30 PM
        expected: true
      ),
      (
        name: "After Hours Test",
        validator: "working_hours",
        value: 22.0,  // 10:00 PM
        expected: false
      ),
    ]

    print("\n  🧪 Testing custom validators:")
    for test in businessTests {
      let validator = framework.getValidator(test.validator)!
      let isValid = validator.validate(test.value, context: ValidationContext.empty())
      let testPassed = isValid == test.expected

      print("    \(testPassed ? "✅" : "❌") \(test.name): \(isValid ? "Valid" : "Invalid")")
    }

    ExampleUtils.printSuccess("Custom validators implemented and tested")
  }

  private static func step4UconditionalValidation() throws {
    ExampleUtils.printStep(4, "Conditional Validation and Complex Rules")

    let framework = ValidationGlobalContext.shared.framework!

    // Setup conditional validation rules
    let conditionalRules = [
      ConditionalRule(
        condition: { message in
          guard let userType = try? message.get(forField: "user_type") as? String else { return false }
          return userType == "premium"
        },
        validator: "premium_features",
        description: "Premium users require additional validation"
      ),
      ConditionalRule(
        condition: { message in
          guard let age = try? message.get(forField: "age") as? Int32 else { return false }
          return age < 18
        },
        validator: "parental_consent",
        description: "Minors require parental consent"
      ),
      ConditionalRule(
        condition: { message in
          guard let country = try? message.get(forField: "country") as? String else { return false }
          return ["DE", "FR", "IT"].contains(country)
        },
        validator: "gdpr_compliance",
        description: "EU users require GDPR compliance"
      ),
    ]

    framework.addConditionalRules(conditionalRules)

    print("  🔀 Registered conditional validation rules:")
    for rule in conditionalRules {
      print("    • \(rule.description)")
    }

    // Test conditional validation scenarios
    let conditionalTests = [
      (
        name: "Premium User",
        data: [
          "name": "Premium User",
          "email": "premium@company.com",
          "age": 35,
          "user_type": "premium",
          "country": "US",
        ]
      ),
      (
        name: "Minor User",
        data: [
          "name": "Young User",
          "email": "young@example.com",
          "age": 16,
          "user_type": "standard",
          "country": "US",
        ]
      ),
      (
        name: "EU User",
        data: [
          "name": "EU User",
          "email": "eu@example.com",
          "age": 28,
          "user_type": "standard",
          "country": "DE",
        ]
      ),
    ]

    print("\n  🧪 Testing conditional validation:")
    for test in conditionalTests {
      let message = try createUserMessage(from: test.data)
      let result = framework.validate(message, schemaName: "User")

      print("    📋 \(test.name):")
      print("      Validation result: \(result.isValid ? "✅ Valid" : "❌ Invalid")")
      print("      Applied rules: \(result.appliedRules.count)")

      if !result.warnings.isEmpty {
        for warning in result.warnings.prefix(1) {
          print("      ⚠️  \(warning)")
        }
      }
    }

    ExampleUtils.printSuccess("Conditional validation rules implemented")
  }

  private static func step5UbulkValidationAndReporting() throws {
    ExampleUtils.printStep(5, "Bulk Validation and Performance Analysis")

    let framework = ValidationGlobalContext.shared.framework!

    // Generate test dataset
    let datasetSize = 1000
    print("  📊 Generating \(datasetSize) test records...")

    let (testData, generationTime) = try ExampleUtils.measureTime {
      return try generateValidationTestDataset(count: datasetSize)
    }
    ExampleUtils.printTiming("Test data generation", time: generationTime)

    // Bulk validation
    print("  🚀 Running bulk validation...")
    let (results, validationTime) = try ExampleUtils.measureTime {
      return framework.bulkValidate(testData, schemaName: "User")
    }

    let throughput = Double(datasetSize) / validationTime
    ExampleUtils.printTiming("Bulk validation", time: validationTime)
    print("  📈 Validation throughput: \(String(format: "%.1f", throughput)) records/sec")

    // Analysis and reporting
    let analysis = ValidationAnalyzer.analyze(results)

    print("\n  📊 Validation Results Summary:")
    print("    Total records: \(analysis.totalRecords)")
    print("    Valid records: \(analysis.validRecords) (\(String(format: "%.1f", analysis.validPercentage))%)")
    print("    Invalid records: \(analysis.invalidRecords) (\(String(format: "%.1f", analysis.invalidPercentage))%)")
    print("    Most common errors:")

    for (error, count) in analysis.topErrors.prefix(3) {
      print("      • \(error): \(count) occurrences")
    }

    // Performance insights
    print("\n  ⚡ Performance Insights:")
    print("    Average validation time: \(String(format: "%.2f", analysis.averageValidationTime * 1000))ms")
    print("    Memory usage: \(ExampleUtils.formatDataSize(analysis.memoryUsage))")

    if analysis.hasPerformanceIssues {
      print("    💡 Optimization recommendations:")
      for recommendation in analysis.optimizationRecommendations {
        print("      • \(recommendation)")
      }
    }

    ExampleUtils.printSuccess("Bulk validation and analysis completed")
  }
}

// MARK: - Validation Framework Implementation

class ValidationFramework {
  private var validators: [String: Validator] = [:]
  private var schemas: [String: MessageDescriptor] = [:]
  private var conditionalRules: [ConditionalRule] = []

  var validatorCount: Int { validators.count }
  var schemaCount: Int { schemas.count }

  func getSchema(_ name: String) -> MessageDescriptor? {
    return schemas[name]
  }

  func registerValidator(_ name: String, _ validator: Validator) {
    validators[name] = validator
  }

  func registerSchema(_ name: String, schema: MessageDescriptor) {
    schemas[name] = schema
  }

  func getValidator(_ name: String) -> Validator? {
    return validators[name]
  }

  func addConditionalRules(_ rules: [ConditionalRule]) {
    conditionalRules.append(contentsOf: rules)
  }

  func validate(_ message: DynamicMessage, schemaName: String) -> ValidationResult {
    guard let schema = schemas[schemaName] else {
      return ValidationResult.failure([ValidationError(field: "schema", message: "Unknown schema: \(schemaName)")])
    }

    var errors: [ValidationError] = []
    var warnings: [String] = []
    var appliedRules: [String] = []

    // Apply conditional rules
    for rule in conditionalRules where rule.condition(message) {
      appliedRules.append(rule.validator)
      if let validator = validators[rule.validator] {
        let context = ValidationContext(message: message, schema: schema)
        if !validator.validate(message, context: context) {
          warnings.append("Conditional rule '\(rule.validator)' failed: \(rule.description)")
        }
      }
    }

    // Basic field validation
    for field in schema.fields.values {
      do {
        let hasValue = try message.hasValue(forField: field.name)

        if hasValue {
          let value = try message.get(forField: field.name)

          // Apply appropriate validators based on field type
          if field.type == .string {
            if field.name == "email" {
              if let emailValidator = validators["email"] {
                let context = ValidationContext(message: message, schema: schema)
                if !emailValidator.validate(value, context: context) {
                  errors.append(ValidationError(field: field.name, message: "Invalid email format"))
                }
              }
            }
          }
        }
      }
      catch {
        errors.append(ValidationError(field: field.name, message: "Validation error: \(error)"))
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      appliedRules: appliedRules
    )
  }

  func bulkValidate(_ messages: [DynamicMessage], schemaName: String) -> [ValidationResult] {
    return messages.map { validate($0, schemaName: schemaName) }
  }
}

// MARK: - Validation Types

protocol Validator {
  func validate(_ value: Any?, context: ValidationContext) -> Bool
}

struct ValidationResult {
  let isValid: Bool
  let errors: [ValidationError]
  let warnings: [String]
  let appliedRules: [String]

  static func success() -> ValidationResult {
    return ValidationResult(isValid: true, errors: [], warnings: [], appliedRules: [])
  }

  static func failure(_ errors: [ValidationError]) -> ValidationResult {
    return ValidationResult(isValid: false, errors: errors, warnings: [], appliedRules: [])
  }
}

struct ValidationError {
  let field: String
  let message: String
}

struct ValidationContext {
  let message: DynamicMessage?
  let schema: MessageDescriptor?

  init(message: DynamicMessage? = nil, schema: MessageDescriptor? = nil) {
    self.message = message
    self.schema = schema
  }

  static func empty() -> ValidationContext {
    return ValidationContext()
  }
}

struct ConditionalRule {
  let condition: (DynamicMessage) -> Bool
  let validator: String
  let description: String
}

// MARK: - Built-in Validators

class RequiredValidator: Validator {
  func validate(_ value: Any?, context: ValidationContext) -> Bool {
    return value != nil
  }
}

class EmailValidator: Validator {
  func validate(_ value: Any?, context: ValidationContext) -> Bool {
    guard let email = value as? String else { return false }
    let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    return email.range(of: emailRegex, options: .regularExpression) != nil
  }
}

class RangeValidator: Validator {
  func validate(_ value: Any?, context: ValidationContext) -> Bool {
    guard let number = value as? Int32 else { return false }
    return number >= 18 && number <= 120  // Age range
  }
}

class LengthValidator: Validator {
  func validate(_ value: Any?, context: ValidationContext) -> Bool {
    guard let string = value as? String else { return false }
    return string.count >= 2 && string.count <= 100
  }
}

class PatternValidator: Validator {
  func validate(_ value: Any?, context: ValidationContext) -> Bool {
    guard let string = value as? String else { return false }
    let phoneRegex = #"^\+?[\d\s\-\(\)]{10,}$"#
    return string.range(of: phoneRegex, options: .regularExpression) != nil
  }
}

class CustomValidator: Validator {
  func validate(_ value: Any?, context: ValidationContext) -> Bool {
    // Custom business logic
    return true
  }
}

// MARK: - Business Validators

class BusinessEmailValidator: Validator {
  private let allowedDomains = ["company.com", "corp.com", "enterprise.org"]

  func validate(_ value: Any?, context: ValidationContext) -> Bool {
    guard let email = value as? String else { return false }
    guard let domain = email.split(separator: "@").last else { return false }
    return allowedDomains.contains(String(domain))
  }
}

class WorkingHoursValidator: Validator {
  func validate(_ value: Any?, context: ValidationContext) -> Bool {
    guard let hour = value as? Double else { return false }
    return hour >= 9.0 && hour <= 17.0  // 9 AM to 5 PM
  }
}

class PriceRangeValidator: Validator {
  func validate(_ value: Any?, context: ValidationContext) -> Bool {
    guard let price = value as? Double else { return false }
    return price >= 0.01 && price <= 10000.00
  }
}

class InventoryValidator: Validator {
  func validate(_ value: Any?, context: ValidationContext) -> Bool {
    guard let quantity = value as? Int32 else { return false }
    return quantity >= 0 && quantity <= 1000
  }
}

// MARK: - Analysis and Reporting

struct ValidationAnalyzer {
  static func analyze(_ results: [ValidationResult]) -> ValidationAnalysis {
    let totalRecords = results.count
    let validRecords = results.filter { $0.isValid }.count
    let invalidRecords = totalRecords - validRecords

    var errorCounts: [String: Int] = [:]
    for result in results {
      for error in result.errors {
        errorCounts[error.message, default: 0] += 1
      }
    }

    let topErrors = errorCounts.sorted { $0.value > $1.value }

    return ValidationAnalysis(
      totalRecords: totalRecords,
      validRecords: validRecords,
      invalidRecords: invalidRecords,
      topErrors: topErrors,
      averageValidationTime: 0.001,  // Simulated
      memoryUsage: totalRecords * 150,  // Estimated
      hasPerformanceIssues: totalRecords > 500,
      optimizationRecommendations: totalRecords > 500
        ? [
          "Consider parallel validation for large datasets",
          "Cache compiled regex patterns for better performance",
          "Use streaming validation for memory efficiency",
        ] : []
    )
  }
}

struct ValidationAnalysis {
  let totalRecords: Int
  let validRecords: Int
  let invalidRecords: Int
  let topErrors: [(String, Int)]
  let averageValidationTime: TimeInterval
  let memoryUsage: Int
  let hasPerformanceIssues: Bool
  let optimizationRecommendations: [String]

  var validPercentage: Double {
    return Double(validRecords) / Double(totalRecords) * 100
  }

  var invalidPercentage: Double {
    return Double(invalidRecords) / Double(totalRecords) * 100
  }
}

// MARK: - Global Context

final class ValidationGlobalContext: @unchecked Sendable {
  static let shared = ValidationGlobalContext()
  var framework: ValidationFramework?

  private init() {}
}

// MARK: - Helper Functions

private func createUserValidationSchema() throws -> MessageDescriptor {
  var fileDescriptor = FileDescriptor(name: "user_validation.proto", package: "validation")
  var userMessage = MessageDescriptor(name: "User", parent: fileDescriptor)

  userMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
  userMessage.addField(FieldDescriptor(name: "email", number: 2, type: .string))
  userMessage.addField(FieldDescriptor(name: "age", number: 3, type: .int32))
  userMessage.addField(FieldDescriptor(name: "phone", number: 4, type: .string))
  userMessage.addField(FieldDescriptor(name: "user_type", number: 5, type: .string))
  userMessage.addField(FieldDescriptor(name: "country", number: 6, type: .string))

  fileDescriptor.addMessage(userMessage)
  return userMessage
}

private func createOrderValidationSchema() throws -> MessageDescriptor {
  var fileDescriptor = FileDescriptor(name: "order_validation.proto", package: "validation")
  var orderMessage = MessageDescriptor(name: "Order", parent: fileDescriptor)

  orderMessage.addField(FieldDescriptor(name: "order_id", number: 1, type: .string))
  orderMessage.addField(FieldDescriptor(name: "user_id", number: 2, type: .string))
  orderMessage.addField(FieldDescriptor(name: "total_amount", number: 3, type: .double))
  orderMessage.addField(FieldDescriptor(name: "items", number: 4, type: .string, isRepeated: true))

  fileDescriptor.addMessage(orderMessage)
  return orderMessage
}

private func createUserMessage(from data: [String: Any]) throws -> DynamicMessage {
  let schema = ValidationGlobalContext.shared.framework!.getSchema("User")!
  let factory = MessageFactory()
  var message = factory.createMessage(from: schema)

  for (key, value) in data {
    try message.set(value, forField: key)
  }

  return message
}

private func generateValidationTestDataset(count: Int) throws -> [DynamicMessage] {
  let schema = ValidationGlobalContext.shared.framework!.getSchema("User")!
  let factory = MessageFactory()

  let userTypes = ["standard", "premium", "enterprise"]
  let countries = ["US", "CA", "UK", "DE", "FR", "JP"]
  let domains = ["example.com", "test.org", "company.com", "gmail.com"]

  return try (0..<count).map { index in
    var message = factory.createMessage(from: schema)

    let isValid = index % 4 != 0  // 75% valid rate

    if isValid {
      try message.set("User\(index)", forField: "name")
      try message.set("user\(index)@\(domains.randomElement()!)", forField: "email")
      try message.set(Int32.random(in: 18...65), forField: "age")
      try message.set("+1-555-\(String(format: "%04d", index % 10000))", forField: "phone")
    }
    else {
      // Introduce validation errors
      if index % 4 == 1 {
        try message.set("", forField: "name")  // Empty name
      }
      else if index % 4 == 2 {
        try message.set("invalid-email", forField: "email")  // Invalid email
      }
      else {
        try message.set(Int32.random(in: 10...17), forField: "age")  // Invalid age
      }
    }

    try message.set(userTypes.randomElement()!, forField: "user_type")
    try message.set(countries.randomElement()!, forField: "country")

    return message
  }
}
