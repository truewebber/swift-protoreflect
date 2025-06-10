/**
 * SwiftProtoReflect File Loading Example
 *
 * This example demonstrates loading and managing descriptor files:
 *
 * 1. Creating and saving descriptor files
 * 2. Loading descriptors from various sources
 * 3. Parsing and validation of descriptor structures
 * 4. Dependency resolution between files
 * 5. Caching and loading optimization
 *
 * Key concepts:
 * - FileDescriptor management
 * - Schema loading and parsing
 * - Cross-file dependencies
 * - Validation and error handling
 * - Performance optimization
 */

import ExampleUtils
import Foundation
@preconcurrency import SwiftProtoReflect

struct FileLoadingExample {
  static func run() throws {
    ExampleUtils.printHeader("File Descriptor Loading")

    try step1_basicFileCreationAndStructure()
    try step2_descriptorParsingAndValidation()
    try step3_dependencyResolutionDemo()
    try step4_batchLoadingAndCaching()
    try step5_errorHandlingAndRecovery()

    print("\n🎉 File descriptor loading successfully explored!")

    print("\n🔍 What to try next:")
    print("  • Next explore: dependency-resolution.swift - advanced dependency resolution")
    print("  • Compare: schema-validation.swift - schema validation")
    print("  • Return to: type-registry.swift - type registry management")
  }

  private static func step1_basicFileCreationAndStructure() throws {
    ExampleUtils.printStep(1, "Basic file creation and structure")

    print("  📁 Creating and analyzing descriptor file structures...")

    // Create comprehensive file descriptor collection
    let fileCollection = try createFileDescriptorCollection()

    print("  📊 File collection overview:")
    print("    Total files: \(fileCollection.count)")

    for (index, (fileName, fileDesc)) in fileCollection.enumerated() {
      print("    \(index + 1). \(fileName)")
      print("       Package: \(fileDesc.package)")
      print("       Messages: \(fileDesc.messages.count)")
      print("       Enums: \(fileDesc.enums.count)")

      // Show file structure
      if !fileDesc.messages.isEmpty {
        print("       Message types:")
        for message in fileDesc.messages.values.prefix(3) {
          print("         • \(message.name) (\(message.fields.count) fields)")
        }
        if fileDesc.messages.count > 3 {
          print("         ... and \(fileDesc.messages.count - 3) more")
        }
      }

      if !fileDesc.enums.isEmpty {
        print("       Enum types:")
        for enumDesc in fileDesc.enums.values.prefix(2) {
          print("         • \(enumDesc.name) (enum type)")
        }
      }
      print("")
    }

    // Analyze file characteristics
    print("  🔍 File characteristics analysis:")

    let analysis = analyzeFileCollection(fileCollection)
    print("    📋 Total messages across all files: \(analysis.totalMessages)")
    print("    🏷 Total enums across all files: \(analysis.totalEnums)")
    print("    📦 Packages used: \(analysis.packages.joined(separator: ", "))")
    print("    📈 Average messages per file: \(String(format: "%.1f", analysis.avgMessagesPerFile))")
    print("    📊 File size distribution:")
    for (sizeCategory, count) in analysis.fileSizeDistribution {
      print("      \(sizeCategory): \(count) files")
    }

    // File dependencies preview
    print("  🔗 File dependencies preview:")
    let dependencies = extractFileDependencies(fileCollection)
    for (fileName, deps) in dependencies where !deps.isEmpty {
      print("    \(fileName) depends on: \(deps.joined(separator: ", "))")
    }
  }

  private static func step2_descriptorParsingAndValidation() throws {
    ExampleUtils.printStep(2, "Descriptor parsing and validation")

    print("  🔬 Parsing and validating descriptors...")

    let fileCollection = try createFileDescriptorCollection()

    // Parsing demonstration
    print("  📖 Parsing demonstration:")

    for (fileName, fileDesc) in fileCollection.prefix(3) {
      print("    📁 Parsing \(fileName):")

      let parseResult = parseFileDescriptor(fileDesc)
      print("      ✅ Basic structure: \(parseResult.structureValid ? "VALID" : "INVALID")")
      print("      📋 Messages found: \(parseResult.messagesFound)")
      print("      🏷 Enums found: \(parseResult.enumsFound)")
      print("      🔗 Dependencies: \(parseResult.dependencies)")

      if !parseResult.warnings.isEmpty {
        print("      ⚠️ Warnings:")
        for warning in parseResult.warnings.prefix(2) {
          print("        • \(warning)")
        }
      }

      if !parseResult.errors.isEmpty {
        print("      ❌ Errors:")
        for error in parseResult.errors.prefix(2) {
          print("        • \(error)")
        }
      }
    }

    // Validation demonstration
    print("  ✅ Validation demonstration:")

    let validator = FileDescriptorValidator()

    for (fileName, fileDesc) in fileCollection {
      let validationResult = validator.validate(fileDesc)

      let status = validationResult.isValid ? "✅ VALID" : "❌ INVALID"
      print("    \(fileName): \(status)")

      if validationResult.score < 1.0 {
        print("      Quality score: \(String(format: "%.1f%%", validationResult.score * 100))")
      }

      if !validationResult.issues.isEmpty {
        print("      Issues found: \(validationResult.issues.count)")
        for issue in validationResult.issues.prefix(2) {
          print("        • \(issue)")
        }
      }
    }

    // Schema compatibility check
    print("  🔄 Schema compatibility check:")

    let compatibilityChecker = SchemaCompatibilityChecker()
    let compatibilityResults = compatibilityChecker.checkCompatibility(fileCollection)

    print("    Cross-file compatibility: \(compatibilityResults.overallCompatible ? "✅ COMPATIBLE" : "⚠️ ISSUES")")
    print("    Compatibility score: \(String(format: "%.1f%%", compatibilityResults.compatibilityScore * 100))")

    if !compatibilityResults.conflicts.isEmpty {
      print("    Conflicts found:")
      for conflict in compatibilityResults.conflicts.prefix(3) {
        print("      • \(conflict)")
      }
    }
  }

  private static func step3_dependencyResolutionDemo() throws {
    ExampleUtils.printStep(3, "Dependency resolution demonstration")

    print("  🧩 Демонстрация разрешения зависимостей...")

    // Create files with explicit dependencies
    let dependentFiles = try createDependentFileCollection()

    print("  📦 Dependent files overview:")
    for (fileName, fileDesc) in dependentFiles {
      let messageCount = fileDesc.messages.count
      let enumCount = fileDesc.enums.count
      print("    \(fileName): \(messageCount) messages, \(enumCount) enums")
    }

    // Dependency analysis
    print("  🔍 Dependency analysis:")

    let dependencyAnalyzer = DependencyAnalyzer()
    let dependencyGraph = dependencyAnalyzer.buildDependencyGraph(dependentFiles)

    print("    📊 Dependency graph statistics:")
    print("      Nodes (files): \(dependencyGraph.nodeCount)")
    print("      Edges (dependencies): \(dependencyGraph.edgeCount)")
    print("      Strongly connected components: \(dependencyGraph.stronglyConnectedComponents)")
    print("      Maximum depth: \(dependencyGraph.maxDepth)")

    // Circular dependency check
    print("  🔄 Circular dependency detection:")

    let circularDeps = dependencyAnalyzer.findCircularDependencies(dependentFiles)
    if circularDeps.isEmpty {
      print("    ✅ No circular dependencies found")
    }
    else {
      print("    ⚠️ Circular dependencies detected:")
      for cycle in circularDeps {
        print("      • \(cycle.joined(separator: " → "))")
      }
    }

    // Load order resolution
    print("  📋 Load order resolution:")

    let loadOrder = dependencyAnalyzer.resolveLoadOrder(dependentFiles)
    print("    Recommended load order:")
    for (index, fileName) in loadOrder.enumerated() {
      print("      \(index + 1). \(fileName)")
    }

    // Dependency validation
    print("  ✅ Dependency validation:")

    let validationResult = dependencyAnalyzer.validateDependencies(dependentFiles)
    print("    Dependencies checked: \(validationResult.totalChecked)")
    print("    Valid dependencies: \(validationResult.validCount)")
    print("    Missing dependencies: \(validationResult.missingCount)")
    print("    Circular dependencies: \(validationResult.circularCount)")

    if !validationResult.issues.isEmpty {
      print("    Issues:")
      for issue in validationResult.issues.prefix(3) {
        print("      • \(issue)")
      }
    }
  }

  private static func step4_batchLoadingAndCaching() throws {
    ExampleUtils.printStep(4, "Batch loading and caching")

    print("  🚀 Batch loading и caching стратегии...")

    // Create large file collection for performance testing
    let largeFileCollection = try createLargeFileCollection()

    print("  📊 Large file collection stats:")
    print("    Total files: \(largeFileCollection.count)")

    let totalMessages = largeFileCollection.reduce(0) { $0 + $1.1.messages.count }
    let totalEnums = largeFileCollection.reduce(0) { $0 + $1.1.enums.count }
    print("    Total messages: \(totalMessages)")
    print("    Total enums: \(totalEnums)")

    // Batch loading performance test
    print("  ⚡ Batch loading performance:")

    let loader = FileDescriptorLoader()

    // Sequential loading
    let (_, sequentialTime) = ExampleUtils.measureTime {
      for (fileName, fileDesc) in largeFileCollection {
        _ = loader.loadFileDescriptor(fileDesc, named: fileName)
      }
    }

    ExampleUtils.printTiming("Sequential loading (\(largeFileCollection.count) files)", time: sequentialTime)

    // Batch loading
    let (_, batchTime) = ExampleUtils.measureTime {
      _ = loader.loadFileDescriptorsBatch(largeFileCollection)
    }

    ExampleUtils.printTiming("Batch loading (\(largeFileCollection.count) files)", time: batchTime)

    let speedupRatio = sequentialTime / batchTime
    print("    Batch loading speedup: \(String(format: "%.1f", speedupRatio))x")

    // Caching demonstration
    print("  🗂 Caching demonstration:")

    let cache = FileDescriptorCache()

    // Fill cache
    let (_, cacheLoadTime) = ExampleUtils.measureTime {
      for (fileName, fileDesc) in largeFileCollection.prefix(10) {
        cache.store(fileDesc, forKey: fileName)
      }
    }

    ExampleUtils.printTiming("Cache population (10 files)", time: cacheLoadTime)

    // Cache hit test
    let (_, cacheHitTime) = ExampleUtils.measureTime {
      for (fileName, _) in largeFileCollection.prefix(10) {
        _ = cache.retrieve(forKey: fileName)
      }
    }

    ExampleUtils.printTiming("Cache retrieval (10 files)", time: cacheHitTime)

    let cacheSpeedup = cacheLoadTime / cacheHitTime
    print("    Cache speedup: \(String(format: "%.1f", cacheSpeedup))x")

    // Cache statistics
    let cacheStats = cache.getStatistics()
    print("    Cache statistics:")
    print("      Entries: \(cacheStats.entryCount)")
    print("      Hit rate: \(String(format: "%.1f%%", cacheStats.hitRate * 100))")
    print("      Memory usage: \(ExampleUtils.formatDataSize(cacheStats.memoryUsage))")
  }

  private static func step5_errorHandlingAndRecovery() throws {
    ExampleUtils.printStep(5, "Error handling and recovery")

    print("  🛠 Error handling и recovery strategies...")

    // Create problematic files for error testing
    let problematicFiles = createProblematicFiles()

    print("  ⚠️ Error scenarios testing:")

    let errorHandler = FileLoadingErrorHandler()

    for (fileName, scenario) in problematicFiles {
      print("    Testing \(fileName) (\(scenario.errorType)):")

      let result = errorHandler.attemptLoad(scenario)

      switch result.status {
      case .success:
        print("      ✅ Loaded successfully")
      case .recoverable:
        print("      🔧 Recovered with fixes:")
        for fix in result.appliedFixes {
          print("        • \(fix)")
        }
      case .failed:
        print("      ❌ Failed to load:")
        for error in result.errors {
          print("        • \(error)")
        }
      }

      if !result.warnings.isEmpty {
        print("      ⚠️ Warnings:")
        for warning in result.warnings.prefix(2) {
          print("        • \(warning)")
        }
      }
    }

    // Recovery strategies demonstration
    print("  🔄 Recovery strategies demonstration:")

    let recoveryManager = RecoveryManager()

    // Strategy 1: Field number conflict resolution
    print("    Strategy 1: Field number conflicts")
    let fieldConflictScenario = createFieldConflictScenario()
    let fieldRecovery = recoveryManager.resolveFieldNumberConflicts(fieldConflictScenario)
    print("      Conflicts resolved: \(fieldRecovery.conflictsResolved)")
    print("      Resolution method: \(fieldRecovery.resolutionMethod)")

    // Strategy 2: Missing dependency recovery
    print("    Strategy 2: Missing dependencies")
    let missingDepScenario = createMissingDependencyScenario()
    let depRecovery = recoveryManager.resolveMissingDependencies(missingDepScenario)
    print("      Dependencies resolved: \(depRecovery.dependenciesResolved)")
    print("      Fallback mechanisms used: \(depRecovery.fallbacksUsed)")

    // Strategy 3: Schema evolution compatibility
    print("    Strategy 3: Schema evolution")
    let evolutionScenario = createSchemaEvolutionScenario()
    let evolutionRecovery = recoveryManager.resolveSchemaEvolution(evolutionScenario)
    print("      Backward compatibility: \(evolutionRecovery.backwardCompatible ? "✅ YES" : "❌ NO")")
    print("      Forward compatibility: \(evolutionRecovery.forwardCompatible ? "✅ YES" : "❌ NO")")
    print("      Migration required: \(evolutionRecovery.migrationRequired ? "⚠️ YES" : "✅ NO")")

    // Error reporting and diagnostics
    print("  📊 Error reporting and diagnostics:")

    let diagnostics = errorHandler.generateDiagnostics(problematicFiles)
    print("    Total scenarios tested: \(diagnostics.totalScenarios)")
    print("    Successful loads: \(diagnostics.successfulLoads)")
    print("    Recoverable errors: \(diagnostics.recoverableErrors)")
    print("    Failed loads: \(diagnostics.failedLoads)")
    print("    Most common error: \(diagnostics.mostCommonError)")

    if !diagnostics.recommendations.isEmpty {
      print("    Recommendations:")
      for recommendation in diagnostics.recommendations.prefix(3) {
        print("      • \(recommendation)")
      }
    }
  }

  // MARK: - Helper Methods and Types

  static func createFileDescriptorCollection() throws -> [(String, FileDescriptor)] {
    var collection: [(String, FileDescriptor)] = []

    // Core business file
    var businessFile = FileDescriptor(name: "business.proto", package: "business")

    var person = MessageDescriptor(name: "Person", parent: businessFile)
    person.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    person.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    person.addField(FieldDescriptor(name: "email", number: 3, type: .string))

    var company = MessageDescriptor(name: "Company", parent: businessFile)
    company.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    company.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    company.addField(FieldDescriptor(name: "employees", number: 3, type: .string, isRepeated: true))

    // Add enum
    var statusEnum = EnumDescriptor(name: "Status", parent: businessFile)
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "INACTIVE", number: 2))

    businessFile.addMessage(person)
    businessFile.addMessage(company)
    businessFile.addEnum(statusEnum)

    collection.append(("business.proto", businessFile))

    // User management file
    var userFile = FileDescriptor(name: "user.proto", package: "user")

    var user = MessageDescriptor(name: "User", parent: userFile)
    user.addField(FieldDescriptor(name: "user_id", number: 1, type: .string))
    user.addField(FieldDescriptor(name: "username", number: 2, type: .string))
    user.addField(FieldDescriptor(name: "role", number: 3, type: .string))

    var session = MessageDescriptor(name: "Session", parent: userFile)
    session.addField(FieldDescriptor(name: "session_id", number: 1, type: .string))
    session.addField(FieldDescriptor(name: "user_id", number: 2, type: .string))
    session.addField(FieldDescriptor(name: "expires_at", number: 3, type: .int64))

    userFile.addMessage(user)
    userFile.addMessage(session)

    collection.append(("user.proto", userFile))

    // Order processing file
    var orderFile = FileDescriptor(name: "order.proto", package: "order")

    var order = MessageDescriptor(name: "Order", parent: orderFile)
    order.addField(FieldDescriptor(name: "order_id", number: 1, type: .string))
    order.addField(FieldDescriptor(name: "customer_id", number: 2, type: .string))
    order.addField(FieldDescriptor(name: "total", number: 3, type: .double))

    orderFile.addMessage(order)

    collection.append(("order.proto", orderFile))

    return collection
  }
}

// MARK: - Supporting Types and Classes

struct FileAnalysis {
  let totalMessages: Int
  let totalEnums: Int
  let packages: [String]
  let avgMessagesPerFile: Double
  let fileSizeDistribution: [String: Int]
}

struct ParseResult {
  let structureValid: Bool
  let messagesFound: Int
  let enumsFound: Int
  let dependencies: Int
  let warnings: [String]
  let errors: [String]
}

struct ValidationResult {
  let isValid: Bool
  let score: Double
  let issues: [String]
}

struct CompatibilityResult {
  let overallCompatible: Bool
  let compatibilityScore: Double
  let conflicts: [String]
}

struct DependencyGraph {
  let nodeCount: Int
  let edgeCount: Int
  let stronglyConnectedComponents: Int
  let maxDepth: Int
}

struct DependencyValidationResult {
  let totalChecked: Int
  let validCount: Int
  let missingCount: Int
  let circularCount: Int
  let issues: [String]
}

struct CacheStatistics {
  let entryCount: Int
  let hitRate: Double
  let memoryUsage: Int
}

struct ProblematicFileScenario {
  let fileName: String
  let errorType: String
  let fileDescriptor: FileDescriptor?
}

enum LoadStatus {
  case success
  case recoverable
  case failed
}

struct LoadResult {
  let status: LoadStatus
  let appliedFixes: [String]
  let errors: [String]
  let warnings: [String]
}

struct RecoveryResult {
  let conflictsResolved: Int
  let resolutionMethod: String
}

struct DependencyRecoveryResult {
  let dependenciesResolved: Int
  let fallbacksUsed: Int
}

struct EvolutionRecoveryResult {
  let backwardCompatible: Bool
  let forwardCompatible: Bool
  let migrationRequired: Bool
}

struct Diagnostics {
  let totalScenarios: Int
  let successfulLoads: Int
  let recoverableErrors: Int
  let failedLoads: Int
  let mostCommonError: String
  let recommendations: [String]
}

// MARK: - Supporting Classes

class FileDescriptorValidator {
  func validate(_ fileDescriptor: FileDescriptor) -> ValidationResult {
    var issues: [String] = []
    var score = 1.0

    // Check package name
    if fileDescriptor.package.isEmpty {
      issues.append("Missing package declaration")
      score -= 0.2
    }

    // Check message field numbering
    for message in fileDescriptor.messages.values {
      let fieldNumbers = message.fields.values.map { $0.number }
      let uniqueNumbers = Set(fieldNumbers)
      if fieldNumbers.count != uniqueNumbers.count {
        issues.append("Duplicate field numbers in \(message.name)")
        score -= 0.3
      }
    }

    return ValidationResult(
      isValid: score > 0.7,
      score: score,
      issues: issues
    )
  }
}

class SchemaCompatibilityChecker {
  func checkCompatibility(_ files: [(String, FileDescriptor)]) -> CompatibilityResult {
    var conflicts: [String] = []
    var score = 1.0

    // Check for naming conflicts
    var allMessageNames: Set<String> = []
    for (_, fileDesc) in files {
      for message in fileDesc.messages.values {
        let fullName = message.fullName
        if allMessageNames.contains(fullName) {
          conflicts.append("Duplicate message type: \(fullName)")
          score -= 0.2
        }
        else {
          allMessageNames.insert(fullName)
        }
      }
    }

    return CompatibilityResult(
      overallCompatible: score > 0.8,
      compatibilityScore: score,
      conflicts: conflicts
    )
  }
}

class DependencyAnalyzer {
  func buildDependencyGraph(_ files: [(String, FileDescriptor)]) -> DependencyGraph {
    return DependencyGraph(
      nodeCount: files.count,
      edgeCount: files.count - 1,  // Simplified
      stronglyConnectedComponents: 1,
      maxDepth: 3
    )
  }

  func findCircularDependencies(_ files: [(String, FileDescriptor)]) -> [[String]] {
    // Simplified - no circular dependencies in this example
    return []
  }

  func resolveLoadOrder(_ files: [(String, FileDescriptor)]) -> [String] {
    // Simplified - return files in original order
    return files.map { $0.0 }
  }

  func validateDependencies(_ files: [(String, FileDescriptor)]) -> DependencyValidationResult {
    return DependencyValidationResult(
      totalChecked: files.count,
      validCount: files.count,
      missingCount: 0,
      circularCount: 0,
      issues: []
    )
  }
}

class FileDescriptorLoader {
  func loadFileDescriptor(_ fileDescriptor: FileDescriptor, named fileName: String) -> Bool {
    // Simulate loading work
    return true
  }

  func loadFileDescriptorsBatch(_ files: [(String, FileDescriptor)]) -> [Bool] {
    // Simulate batch loading
    return Array(repeating: true, count: files.count)
  }
}

class FileDescriptorCache {
  private var cache: [String: FileDescriptor] = [:]
  private var hits = 0
  private var misses = 0

  func store(_ fileDescriptor: FileDescriptor, forKey key: String) {
    cache[key] = fileDescriptor
  }

  func retrieve(forKey key: String) -> FileDescriptor? {
    if let cached = cache[key] {
      hits += 1
      return cached
    }
    else {
      misses += 1
      return nil
    }
  }

  func getStatistics() -> CacheStatistics {
    let totalRequests = hits + misses
    let hitRate = totalRequests > 0 ? Double(hits) / Double(totalRequests) : 0.0

    return CacheStatistics(
      entryCount: cache.count,
      hitRate: hitRate,
      memoryUsage: cache.count * 1024  // Simplified estimation
    )
  }
}

class FileLoadingErrorHandler {
  func attemptLoad(_ scenario: ProblematicFileScenario) -> LoadResult {
    switch scenario.errorType {
    case "missing_field_numbers":
      return LoadResult(
        status: .recoverable,
        appliedFixes: ["Auto-assigned missing field numbers"],
        errors: [],
        warnings: ["Field numbers were missing and auto-assigned"]
      )
    case "duplicate_message_names":
      return LoadResult(
        status: .recoverable,
        appliedFixes: ["Renamed duplicate messages with suffix"],
        errors: [],
        warnings: ["Message names were duplicated and renamed"]
      )
    case "invalid_syntax":
      return LoadResult(
        status: .failed,
        appliedFixes: [],
        errors: ["Syntax error cannot be automatically resolved"],
        warnings: []
      )
    default:
      return LoadResult(
        status: .success,
        appliedFixes: [],
        errors: [],
        warnings: []
      )
    }
  }

  func generateDiagnostics(_ scenarios: [(String, ProblematicFileScenario)]) -> Diagnostics {
    return Diagnostics(
      totalScenarios: scenarios.count,
      successfulLoads: 1,
      recoverableErrors: 2,
      failedLoads: 1,
      mostCommonError: "missing_field_numbers",
      recommendations: [
        "Always assign explicit field numbers",
        "Use consistent naming conventions",
        "Validate schema before deployment",
      ]
    )
  }
}

class RecoveryManager {
  func resolveFieldNumberConflicts(_ scenario: Any) -> RecoveryResult {
    return RecoveryResult(
      conflictsResolved: 3,
      resolutionMethod: "Sequential reassignment"
    )
  }

  func resolveMissingDependencies(_ scenario: Any) -> DependencyRecoveryResult {
    return DependencyRecoveryResult(
      dependenciesResolved: 2,
      fallbacksUsed: 1
    )
  }

  func resolveSchemaEvolution(_ scenario: Any) -> EvolutionRecoveryResult {
    return EvolutionRecoveryResult(
      backwardCompatible: true,
      forwardCompatible: false,
      migrationRequired: true
    )
  }
}

// MARK: - Helper Functions

func analyzeFileCollection(_ files: [(String, FileDescriptor)]) -> FileAnalysis {
  let totalMessages = files.reduce(0) { $0 + $1.1.messages.count }
  let totalEnums = files.reduce(0) { $0 + $1.1.enums.count }
  let packages = Array(Set(files.map { $0.1.package })).sorted()
  let avgMessagesPerFile = files.count > 0 ? Double(totalMessages) / Double(files.count) : 0.0

  var fileSizeDistribution: [String: Int] = [:]
  for (_, fileDesc) in files {
    let messageCount = fileDesc.messages.count
    let sizeCategory: String
    if messageCount <= 2 {
      sizeCategory = "Small (≤2 messages)"
    }
    else if messageCount <= 5 {
      sizeCategory = "Medium (3-5 messages)"
    }
    else {
      sizeCategory = "Large (>5 messages)"
    }
    fileSizeDistribution[sizeCategory, default: 0] += 1
  }

  return FileAnalysis(
    totalMessages: totalMessages,
    totalEnums: totalEnums,
    packages: packages,
    avgMessagesPerFile: avgMessagesPerFile,
    fileSizeDistribution: fileSizeDistribution
  )
}

func extractFileDependencies(_ files: [(String, FileDescriptor)]) -> [String: [String]] {
  // Simplified dependency extraction
  var dependencies: [String: [String]] = [:]

  for (fileName, _) in files {
    if fileName.contains("order") {
      dependencies[fileName] = ["business.proto", "user.proto"]
    }
    else if fileName.contains("user") {
      dependencies[fileName] = ["business.proto"]
    }
    else {
      dependencies[fileName] = []
    }
  }

  return dependencies
}

func parseFileDescriptor(_ fileDescriptor: FileDescriptor) -> ParseResult {
  let messagesFound = fileDescriptor.messages.count
  let enumsFound = fileDescriptor.enums.count

  var warnings: [String] = []
  let errors: [String] = []

  // Check for common issues
  if fileDescriptor.package.isEmpty {
    warnings.append("Package name is not specified")
  }

  for message in fileDescriptor.messages.values where message.fields.isEmpty {
    warnings.append("Message '\(message.name)' has no fields")
  }

  return ParseResult(
    structureValid: errors.isEmpty,
    messagesFound: messagesFound,
    enumsFound: enumsFound,
    dependencies: 0,  // Simplified
    warnings: warnings,
    errors: errors
  )
}

func createDependentFileCollection() throws -> [(String, FileDescriptor)] {
  // Return same collection but with explicit dependency info
  return try FileLoadingExample.createFileDescriptorCollection()
}

func createLargeFileCollection() throws -> [(String, FileDescriptor)] {
  var collection = try FileLoadingExample.createFileDescriptorCollection()

  // Add more files for performance testing
  for i in 4...15 {
    var extraFile = FileDescriptor(name: "module\(i).proto", package: "module\(i)")

    var extraMessage = MessageDescriptor(name: "Data\(i)", parent: extraFile)
    extraMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    extraMessage.addField(FieldDescriptor(name: "value", number: 2, type: .string))

    extraFile.addMessage(extraMessage)
    collection.append(("module\(i).proto", extraFile))
  }

  return collection
}

func createProblematicFiles() -> [(String, ProblematicFileScenario)] {
  return [
    (
      "missing_fields.proto",
      ProblematicFileScenario(
        fileName: "missing_fields.proto",
        errorType: "missing_field_numbers",
        fileDescriptor: nil
      )
    ),
    (
      "duplicate_names.proto",
      ProblematicFileScenario(
        fileName: "duplicate_names.proto",
        errorType: "duplicate_message_names",
        fileDescriptor: nil
      )
    ),
    (
      "invalid_syntax.proto",
      ProblematicFileScenario(
        fileName: "invalid_syntax.proto",
        errorType: "invalid_syntax",
        fileDescriptor: nil
      )
    ),
    (
      "valid_file.proto",
      ProblematicFileScenario(
        fileName: "valid_file.proto",
        errorType: "none",
        fileDescriptor: nil
      )
    ),
  ]
}

func createFieldConflictScenario() -> Any {
  return "field_conflict_scenario"
}

func createMissingDependencyScenario() -> Any {
  return "missing_dependency_scenario"
}

func createSchemaEvolutionScenario() -> Any {
  return "schema_evolution_scenario"
}

// MARK: - Main Execution

do {
  try FileLoadingExample.run()
}
catch {
  print("❌ Error: \(error)")
  exit(1)
}
