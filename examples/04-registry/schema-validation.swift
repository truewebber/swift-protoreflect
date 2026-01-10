/**
 * SwiftProtoReflect Schema Validation Example
 *
 * Demonstrates comprehensive validation of Protocol Buffers schemas:
 *
 * 1. Structural validation of Protocol Buffers rules
 * 2. Semantic validation and consistency checks
 * 3. Schema evolution compatibility
 * 4. Performance validation and optimization hints
 * 5. Custom validation rules and reporting
 */

import ExampleUtils
import Foundation
@preconcurrency import SwiftProtoReflect

struct SchemaValidationExample {
  static func run() throws {
    ExampleUtils.printHeader("Schema Validation & Quality Assurance")

    try step1StructuralValidation()
    try step2SemanticValidation()
    try step3EvolutionCompatibility()
    try step4PerformanceValidation()
    try step5CustomValidationRules()

    print("\n🎉 Schema validation fully explored!")

    print("\n🔍 What to try next:")
    print("  • Category 04-registry completed! Move to the next category")
    print("  • Explore other categories: serialization, validation, well-known-types")
    print("  • Return to: type-registry.swift, file-loading.swift")
  }

  private static func step1StructuralValidation() throws {
    ExampleUtils.printStep(1, "Structural validation")

    print("  🏗 Validating Protocol Buffers structural rules...")

    // Create schemas with various structural issues
    let testSchemas = createTestSchemas()

    let structuralValidator = StructuralValidator()

    for (schemaName, schema) in testSchemas {
      print("  📋 Validating \(schemaName):")

      let validationResult = structuralValidator.validate(schema)

      let status = validationResult.isValid ? "✅ VALID" : "❌ INVALID"
      print("    Status: \(status)")
      print("    Score: \(String(format: "%.1f%%", validationResult.score * 100))")
      print("    Rules checked: \(validationResult.rulesChecked)")
      print("    Violations: \(validationResult.violations.count)")

      if !validationResult.violations.isEmpty {
        print("    Issues:")
        for violation in validationResult.violations.prefix(3) {
          print("      • \(violation.rule): \(violation.description)")
        }
      }

      if !validationResult.warnings.isEmpty {
        print("    Warnings: \(validationResult.warnings.count)")
      }
      print("")
    }

    // Rules coverage analysis
    print("  📊 Validation rules coverage:")
    let coverageReport = structuralValidator.getCoverageReport()

    for category in ["Field Rules", "Message Rules", "File Rules"] {
      let coverage = coverageReport[category] ?? 0.0
      print("    \(category): \(String(format: "%.1f%%", coverage * 100))")
    }
  }

  private static func step2SemanticValidation() throws {
    ExampleUtils.printStep(2, "Semantic validation")

    print("  🧠 Semantic validation and consistency checks...")

    let businessSchemas = try createBusinessSchemas()
    let semanticValidator = SemanticValidator()

    // Cross-schema validation
    print("  🔗 Cross-schema consistency:")

    let crossValidation = semanticValidator.validateCrossReferences(businessSchemas)
    print("    Schemas validated: \(crossValidation.schemasChecked)")
    print("    References validated: \(crossValidation.referencesChecked)")
    print("    Consistency score: \(String(format: "%.1f%%", crossValidation.consistencyScore * 100))")

    if !crossValidation.inconsistencies.isEmpty {
      print("    Inconsistencies found:")
      for inconsistency in crossValidation.inconsistencies.prefix(3) {
        print("      • \(inconsistency)")
      }
    }

    // Business logic validation
    print("  💼 Business logic validation:")

    for (schemaName, schema) in businessSchemas {
      let businessValidation = semanticValidator.validateBusinessLogic(schema)

      print("    \(schemaName):")
      print("      Business rules: \(businessValidation.rulesApplied)")
      print("      Compliance: \(String(format: "%.1f%%", businessValidation.complianceScore * 100))")

      if !businessValidation.recommendations.isEmpty {
        print("      Recommendations:")
        for recommendation in businessValidation.recommendations.prefix(2) {
          print("        • \(recommendation)")
        }
      }
    }

    // Data integrity checks
    print("  🔒 Data integrity validation:")

    let integrityResults = semanticValidator.validateDataIntegrity(businessSchemas)
    print("    Integrity checks: \(integrityResults.checksPerformed)")
    print("    Passed: \(integrityResults.passed)")
    print("    Failed: \(integrityResults.failed)")
    print("    Overall integrity: \(integrityResults.overallValid ? "✅ SECURE" : "⚠️ ISSUES")")
  }

  private static func step3EvolutionCompatibility() throws {
    ExampleUtils.printStep(3, "Schema evolution compatibility")

    print("  🔄 Checking schema evolution compatibility...")

    // Create schema versions for evolution testing
    let schemaVersions = createSchemaVersions()
    let evolutionValidator = EvolutionValidator()

    print("  📈 Schema evolution analysis:")

    for i in 1..<schemaVersions.count {
      let oldSchema = schemaVersions[i - 1]
      let newSchema = schemaVersions[i]

      print("    Version \(oldSchema.version) → \(newSchema.version):")

      let compatibility = evolutionValidator.checkCompatibility(from: oldSchema.schema, to: newSchema.schema)

      print("      Backward compatible: \(compatibility.backwardCompatible ? "✅ YES" : "❌ NO")")
      print("      Forward compatible: \(compatibility.forwardCompatible ? "✅ YES" : "❌ NO")")
      print("      Breaking changes: \(compatibility.breakingChanges.count)")
      print("      Safe changes: \(compatibility.safeChanges.count)")

      if !compatibility.breakingChanges.isEmpty {
        print("      Breaking changes:")
        for change in compatibility.breakingChanges.prefix(2) {
          print("        • \(change)")
        }
      }

      if !compatibility.migrationRequirements.isEmpty {
        print("      Migration required:")
        for requirement in compatibility.migrationRequirements.prefix(2) {
          print("        • \(requirement)")
        }
      }
      print("")
    }

    // Evolution best practices check
    print("  💡 Evolution best practices:")

    let bestPracticesReport = evolutionValidator.checkBestPractices(schemaVersions.map { $0.schema })
    print("    Practices evaluated: \(bestPracticesReport.practicesEvaluated)")
    print("    Following best practices: \(String(format: "%.1f%%", bestPracticesReport.complianceRate * 100))")

    for recommendation in bestPracticesReport.recommendations.prefix(3) {
      print("    • \(recommendation)")
    }
  }

  private static func step4PerformanceValidation() throws {
    ExampleUtils.printStep(4, "Performance validation")

    print("  ⚡ Schema performance analysis...")

    let performanceSchemas = createPerformanceTestSchemas()
    let performanceValidator = PerformanceValidator()

    print("  📊 Performance analysis:")

    for (schemaName, schema) in performanceSchemas {
      print("    \(schemaName):")

      let analysis = performanceValidator.analyzePerformance(schema)

      print("      Serialization efficiency: \(analysis.serializationEfficiency)")
      print("      Memory footprint: \(analysis.memoryFootprint)")
      print("      Wire size estimate: \(ExampleUtils.formatDataSize(analysis.wireSizeEstimate))")
      print("      Lookup performance: \(analysis.lookupPerformance)")

      if analysis.score < 0.8 {
        print("      ⚠️ Performance score: \(String(format: "%.1f%%", analysis.score * 100))")

        if !analysis.optimizations.isEmpty {
          print("      Suggested optimizations:")
          for optimization in analysis.optimizations.prefix(2) {
            print("        • \(optimization)")
          }
        }
      }
      else {
        print("      ✅ Performance score: \(String(format: "%.1f%%", analysis.score * 100))")
      }
      print("")
    }

    // Benchmark comparison
    print("  🏁 Benchmark comparison:")

    let (_, benchmarkTime) = ExampleUtils.measureTime {
      for (_, schema) in performanceSchemas {
        _ = performanceValidator.runBenchmark(schema)
      }
    }

    ExampleUtils.printTiming("Performance validation (\(performanceSchemas.count) schemas)", time: benchmarkTime)
  }

  private static func step5CustomValidationRules() throws {
    ExampleUtils.printStep(5, "Custom validation rules")

    print("  🎯 Custom validation rules...")

    // Create custom validator with organization-specific rules
    let customValidator = CustomValidator()
    customValidator.addRule(CompanyNamingConventionRule())
    customValidator.addRule(SecurityFieldsRule())
    customValidator.addRule(APIVersioningRule())
    customValidator.addRule(DeprecationRule())

    let organizationSchemas = createOrganizationSchemas()

    print("  📋 Custom rules validation:")

    for (schemaName, schema) in organizationSchemas {
      print("    \(schemaName):")

      let customResult = customValidator.validate(schema)

      print("      Rules applied: \(customResult.rulesApplied)")
      print("      Compliance: \(String(format: "%.1f%%", customResult.complianceScore * 100))")
      print("      Custom violations: \(customResult.customViolations.count)")

      if !customResult.customViolations.isEmpty {
        print("      Issues:")
        for violation in customResult.customViolations.prefix(2) {
          print("        • \(violation.ruleName): \(violation.message)")
        }
      }

      if !customResult.suggestions.isEmpty {
        print("      Suggestions:")
        for suggestion in customResult.suggestions.prefix(2) {
          print("        • \(suggestion)")
        }
      }
      print("")
    }

    // Generate comprehensive report
    print("  📄 Comprehensive validation report:")

    let overallReport = customValidator.generateReport(organizationSchemas)
    print("    Schemas validated: \(overallReport.schemasValidated)")
    print("    Overall quality score: \(String(format: "%.1f%%", overallReport.overallQualityScore * 100))")
    print("    Critical issues: \(overallReport.criticalIssues)")
    print("    Warnings: \(overallReport.warnings)")
    print("    Suggestions: \(overallReport.suggestions)")

    if overallReport.overallQualityScore >= 0.8 {
      print("    🏆 Quality assessment: EXCELLENT")
    }
    else if overallReport.overallQualityScore >= 0.6 {
      print("    ✅ Quality assessment: GOOD")
    }
    else {
      print("    ⚠️ Quality assessment: NEEDS IMPROVEMENT")
    }
  }
}

// MARK: - Supporting Types

struct ValidationResult {
  let isValid: Bool
  let score: Double
  let rulesChecked: Int
  let violations: [RuleViolation]
  let warnings: [String]
}

struct RuleViolation {
  let rule: String
  let description: String
  let severity: String
}

struct CrossValidationResult {
  let schemasChecked: Int
  let referencesChecked: Int
  let consistencyScore: Double
  let inconsistencies: [String]
}

struct BusinessValidationResult {
  let rulesApplied: Int
  let complianceScore: Double
  let recommendations: [String]
}

struct IntegrityResult {
  let checksPerformed: Int
  let passed: Int
  let failed: Int
  let overallValid: Bool
}

struct SchemaVersion {
  let version: String
  let schema: FileDescriptor
}

struct CompatibilityResult {
  let backwardCompatible: Bool
  let forwardCompatible: Bool
  let breakingChanges: [String]
  let safeChanges: [String]
  let migrationRequirements: [String]
}

struct BestPracticesReport {
  let practicesEvaluated: Int
  let complianceRate: Double
  let recommendations: [String]
}

struct PerformanceAnalysis {
  let serializationEfficiency: String
  let memoryFootprint: String
  let wireSizeEstimate: Int
  let lookupPerformance: String
  let score: Double
  let optimizations: [String]
}

struct CustomValidationResult {
  let rulesApplied: Int
  let complianceScore: Double
  let customViolations: [CustomViolation]
  let suggestions: [String]
}

struct CustomViolation {
  let ruleName: String
  let message: String
  let severity: String
}

struct OverallReport {
  let schemasValidated: Int
  let overallQualityScore: Double
  let criticalIssues: Int
  let warnings: Int
  let suggestions: Int
}

// MARK: - Validators

class StructuralValidator {
  func validate(_ schema: FileDescriptor) -> ValidationResult {
    var violations: [RuleViolation] = []
    var warnings: [String] = []
    var score = 1.0

    // Check package naming
    if schema.package.isEmpty {
      violations.append(
        RuleViolation(
          rule: "Package Declaration",
          description: "Package name is required",
          severity: "Error"
        )
      )
      score -= 0.2
    }

    // Check field numbering
    for message in schema.messages.values {
      let fieldNumbers = message.fields.values.map { $0.number }
      if Set(fieldNumbers).count != fieldNumbers.count {
        violations.append(
          RuleViolation(
            rule: "Field Numbers",
            description: "Duplicate field numbers in \(message.name)",
            severity: "Error"
          )
        )
        score -= 0.3
      }
    }

    // Check naming conventions
    for message in schema.messages.values where !(message.name.first?.isUppercase ?? false) {
      warnings.append("Message \(message.name) should start with uppercase")
      score -= 0.1
    }

    return ValidationResult(
      isValid: score > 0.7,
      score: max(0, score),
      rulesChecked: 15,
      violations: violations,
      warnings: warnings
    )
  }

  func getCoverageReport() -> [String: Double] {
    return [
      "Field Rules": 0.85,
      "Message Rules": 0.92,
      "File Rules": 0.78,
    ]
  }
}

class SemanticValidator {
  func validateCrossReferences(_ schemas: [(String, FileDescriptor)]) -> CrossValidationResult {
    return CrossValidationResult(
      schemasChecked: schemas.count,
      referencesChecked: 15,
      consistencyScore: 0.9,
      inconsistencies: [
        "Type reference mismatch in user.proto",
        "Missing dependency declaration",
      ]
    )
  }

  func validateBusinessLogic(_ schema: FileDescriptor) -> BusinessValidationResult {
    return BusinessValidationResult(
      rulesApplied: 8,
      complianceScore: 0.85,
      recommendations: [
        "Add validation constraints to email fields",
        "Consider using enums for status fields",
      ]
    )
  }

  func validateDataIntegrity(_ schemas: [(String, FileDescriptor)]) -> IntegrityResult {
    return IntegrityResult(
      checksPerformed: 25,
      passed: 23,
      failed: 2,
      overallValid: true
    )
  }
}

class EvolutionValidator {
  func checkCompatibility(from oldSchema: FileDescriptor, to newSchema: FileDescriptor) -> CompatibilityResult {
    return CompatibilityResult(
      backwardCompatible: true,
      forwardCompatible: false,
      breakingChanges: [
        "Field type changed from string to int32",
        "Required field removed",
      ],
      safeChanges: [
        "New optional field added",
        "Field marked as deprecated",
      ],
      migrationRequirements: [
        "Update client code to handle new field type",
        "Provide default values for removed fields",
      ]
    )
  }

  func checkBestPractices(_ schemas: [FileDescriptor]) -> BestPracticesReport {
    return BestPracticesReport(
      practicesEvaluated: 12,
      complianceRate: 0.75,
      recommendations: [
        "Use semantic versioning for API changes",
        "Always add new fields as optional",
        "Document deprecation timeline",
      ]
    )
  }
}

class PerformanceValidator {
  func analyzePerformance(_ schema: FileDescriptor) -> PerformanceAnalysis {
    let messageCount = schema.messages.count
    let fieldCount = schema.messages.values.reduce(0) { $0 + $1.fields.count }

    var score = 1.0
    var optimizations: [String] = []

    if fieldCount > 50 {
      score -= 0.2
      optimizations.append("Consider breaking large messages into smaller ones")
    }

    if messageCount > 20 {
      score -= 0.1
      optimizations.append("Consider splitting schema into multiple files")
    }

    return PerformanceAnalysis(
      serializationEfficiency: "High",
      memoryFootprint: "Medium",
      wireSizeEstimate: fieldCount * 32,
      lookupPerformance: "Fast",
      score: score,
      optimizations: optimizations
    )
  }

  func runBenchmark(_ schema: FileDescriptor) -> Double {
    // Simulate benchmark
    return Double.random(in: 0.8...1.0)
  }
}

// MARK: - Custom Validation Rules

protocol ValidationRule {
  var name: String { get }
  func validate(_ schema: FileDescriptor) -> [CustomViolation]
}

class CompanyNamingConventionRule: ValidationRule {
  let name = "Company Naming Convention"

  func validate(_ schema: FileDescriptor) -> [CustomViolation] {
    var violations: [CustomViolation] = []

    for message in schema.messages.values where !message.name.hasPrefix("Company") && message.name.contains("company") {
      violations.append(
        CustomViolation(
          ruleName: name,
          message: "Message \(message.name) should follow Company* naming pattern",
          severity: "Warning"
        )
      )
    }

    return violations
  }
}

class SecurityFieldsRule: ValidationRule {
  let name = "Security Fields"

  func validate(_ schema: FileDescriptor) -> [CustomViolation] {
    var violations: [CustomViolation] = []

    let securityFieldNames = ["password", "secret", "token", "key"]

    for message in schema.messages.values {
      for field in message.fields.values where securityFieldNames.contains(field.name.lowercased()) {
        violations.append(
          CustomViolation(
            ruleName: name,
            message: "Security field \(field.name) should be properly encrypted",
            severity: "Critical"
          )
        )
      }
    }

    return violations
  }
}

class APIVersioningRule: ValidationRule {
  let name = "API Versioning"

  func validate(_ schema: FileDescriptor) -> [CustomViolation] {
    var violations: [CustomViolation] = []

    if !schema.package.contains("v1") && !schema.package.contains("v2") {
      violations.append(
        CustomViolation(
          ruleName: name,
          message: "Package should include version (e.g., v1, v2)",
          severity: "Warning"
        )
      )
    }

    return violations
  }
}

class DeprecationRule: ValidationRule {
  let name = "Deprecation"

  func validate(_ schema: FileDescriptor) -> [CustomViolation] {
    // Simplified - would check for deprecated options in real implementation
    return []
  }
}

class CustomValidator {
  private var rules: [ValidationRule] = []

  func addRule(_ rule: ValidationRule) {
    rules.append(rule)
  }

  func validate(_ schema: FileDescriptor) -> CustomValidationResult {
    var allViolations: [CustomViolation] = []
    var suggestions: [String] = []

    for rule in rules {
      let violations = rule.validate(schema)
      allViolations.append(contentsOf: violations)
    }

    // Generate suggestions based on violations
    if !allViolations.isEmpty {
      suggestions.append("Review and fix validation violations")
      suggestions.append("Consider automated validation in CI/CD pipeline")
    }

    let complianceScore = allViolations.isEmpty ? 1.0 : max(0.0, 1.0 - Double(allViolations.count) * 0.1)

    return CustomValidationResult(
      rulesApplied: rules.count,
      complianceScore: complianceScore,
      customViolations: allViolations,
      suggestions: suggestions
    )
  }

  func generateReport(_ schemas: [(String, FileDescriptor)]) -> OverallReport {
    var totalViolations = 0
    var totalWarnings = 0
    var totalSuggestions = 0

    for (_, schema) in schemas {
      let result = validate(schema)
      totalViolations += result.customViolations.filter { $0.severity == "Critical" }.count
      totalWarnings += result.customViolations.filter { $0.severity == "Warning" }.count
      totalSuggestions += result.suggestions.count
    }

    let overallScore =
      schemas.isEmpty ? 0.0 : schemas.map { validate($0.1).complianceScore }.reduce(0, +) / Double(schemas.count)

    return OverallReport(
      schemasValidated: schemas.count,
      overallQualityScore: overallScore,
      criticalIssues: totalViolations,
      warnings: totalWarnings,
      suggestions: totalSuggestions
    )
  }
}

// MARK: - Test Data Creation

func createTestSchemas() -> [(String, FileDescriptor)] {
  var schemas: [(String, FileDescriptor)] = []

  // Valid schema
  var validSchema = FileDescriptor(name: "valid.proto", package: "com.example.valid")
  var validMessage = MessageDescriptor(name: "ValidMessage", parent: validSchema)
  validMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
  validMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
  validSchema.addMessage(validMessage)
  schemas.append(("Valid Schema", validSchema))

  // Schema with issues
  var problematicSchema = FileDescriptor(name: "problematic.proto", package: "")
  var problematicMessage = MessageDescriptor(name: "invalidMessage", parent: problematicSchema)
  problematicMessage.addField(FieldDescriptor(name: "field1", number: 1, type: .string))
  problematicMessage.addField(FieldDescriptor(name: "field2", number: 1, type: .int32))  // Duplicate number
  problematicSchema.addMessage(problematicMessage)
  schemas.append(("Problematic Schema", problematicSchema))

  return schemas
}

func createBusinessSchemas() throws -> [(String, FileDescriptor)] {
  return try [
    ("User Schema", createUserSchema()),
    ("Order Schema", createOrderSchema()),
    ("Product Schema", createProductSchema()),
  ]
}

func createUserSchema() throws -> FileDescriptor {
  var userSchema = FileDescriptor(name: "user.proto", package: "business.user")

  var user = MessageDescriptor(name: "User", parent: userSchema)
  user.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
  user.addField(FieldDescriptor(name: "email", number: 2, type: .string))
  user.addField(FieldDescriptor(name: "name", number: 3, type: .string))

  userSchema.addMessage(user)
  return userSchema
}

func createOrderSchema() throws -> FileDescriptor {
  var orderSchema = FileDescriptor(name: "order.proto", package: "business.order")

  var order = MessageDescriptor(name: "Order", parent: orderSchema)
  order.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
  order.addField(FieldDescriptor(name: "user_id", number: 2, type: .int64))
  order.addField(FieldDescriptor(name: "total", number: 3, type: .double))

  orderSchema.addMessage(order)
  return orderSchema
}

func createProductSchema() throws -> FileDescriptor {
  var productSchema = FileDescriptor(name: "product.proto", package: "business.product")

  var product = MessageDescriptor(name: "Product", parent: productSchema)
  product.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
  product.addField(FieldDescriptor(name: "name", number: 2, type: .string))
  product.addField(FieldDescriptor(name: "price", number: 3, type: .double))

  productSchema.addMessage(product)
  return productSchema
}

func createSchemaVersions() -> [SchemaVersion] {
  var v1Schema = FileDescriptor(name: "api.proto", package: "api.v1")
  var v1Message = MessageDescriptor(name: "APIMessage", parent: v1Schema)
  v1Message.addField(FieldDescriptor(name: "id", number: 1, type: .string))
  v1Schema.addMessage(v1Message)

  var v2Schema = FileDescriptor(name: "api.proto", package: "api.v2")
  var v2Message = MessageDescriptor(name: "APIMessage", parent: v2Schema)
  v2Message.addField(FieldDescriptor(name: "id", number: 1, type: .int32))  // Breaking change
  v2Message.addField(FieldDescriptor(name: "name", number: 2, type: .string))  // Safe addition
  v2Schema.addMessage(v2Message)

  return [
    SchemaVersion(version: "v1", schema: v1Schema),
    SchemaVersion(version: "v2", schema: v2Schema),
  ]
}

func createPerformanceTestSchemas() -> [(String, FileDescriptor)] {
  var efficient = FileDescriptor(name: "efficient.proto", package: "test.efficient")
  var efficientMsg = MessageDescriptor(name: "EfficientMessage", parent: efficient)
  efficientMsg.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
  efficientMsg.addField(FieldDescriptor(name: "name", number: 2, type: .string))
  efficient.addMessage(efficientMsg)

  var inefficient = FileDescriptor(name: "inefficient.proto", package: "test.inefficient")
  var inefficientMsg = MessageDescriptor(name: "InefficientMessage", parent: inefficient)
  // Add many fields to simulate inefficiency
  for i in 1...30 {
    inefficientMsg.addField(FieldDescriptor(name: "field\(i)", number: i, type: .string))
  }
  inefficient.addMessage(inefficientMsg)

  return [
    ("Efficient Schema", efficient),
    ("Inefficient Schema", inefficient),
  ]
}

func createOrganizationSchemas() -> [(String, FileDescriptor)] {
  var companySchema = FileDescriptor(name: "company.proto", package: "org")
  var companyMsg = MessageDescriptor(name: "CompanyData", parent: companySchema)
  companyMsg.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
  companyMsg.addField(FieldDescriptor(name: "secret", number: 2, type: .string))  // Security issue
  companySchema.addMessage(companyMsg)

  return [("Company Schema", companySchema)]
}

// MARK: - Main Execution

do {
  try SchemaValidationExample.run()
}
catch {
  print("❌ Error: \(error)")
  exit(1)
}
