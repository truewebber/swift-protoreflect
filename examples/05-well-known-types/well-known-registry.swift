/**
 * ⭐ SwiftProtoReflect Example: Well-Known Types Registry Integration
 *
 * Description: Comprehensive demonstration of integrating all Well-Known Types through WellKnownTypesRegistry
 * Key concepts: WellKnownTypesRegistry, Handler integration, Type conversion patterns
 * Complexity: 🚀 Advanced
 * Execution time: < 15 seconds
 *
 * What you'll learn:
 * - Centralized management of all Well-Known Types
 * - Registry-based creation of specialized values
 * - Cross-type operations and conversions
 * - Batch processing Well-Known Types
 * - Performance optimization for registry operations
 * - Error handling and type safety in registry
 *
 * Run with:
 *   swift run WellKnownRegistry
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct WellKnownRegistryExample {
  static func main() throws {
    ExampleUtils.printHeader("Well-Known Types Registry Integration")

    try demonstrateRegistryBasics()
    try demonstrateHandlerIntegration()
    try demonstrateCrossTypeOperations()
    try demonstrateBatchProcessing()
    try demonstrateAdvancedPatterns()
    try demonstratePerformanceOptimization()

    ExampleUtils.printSuccess("Well-Known Types Registry example completed!")
    ExampleUtils.printNext([
      "Explore: 06-grpc examples for gRPC integration",
      "Advanced: 07-advanced examples for complex scenarios",
    ])
  }

  // MARK: - Registry Basics

  private static func demonstrateRegistryBasics() throws {
    ExampleUtils.printStep(1, "Registry Basics - Central Management")

    let registry = WellKnownTypesRegistry.shared

    // Check available types
    let supportedTypes = [
      WellKnownTypeNames.timestamp,
      WellKnownTypeNames.duration,
      WellKnownTypeNames.empty,
      WellKnownTypeNames.fieldMask,
      WellKnownTypeNames.structType,
      WellKnownTypeNames.value,
      WellKnownTypeNames.any,
    ]

    print("  📋 Supported Well-Known Types:")
    let registeredTypes = registry.getRegisteredTypes()
    for typeName in supportedTypes {
      let isRegistered = registeredTypes.contains(typeName)
      let status = isRegistered ? "✅" : "❌"
      print("    \(status) \(typeName)")
    }

    print("\n  🎯 Registry Statistics:")
    print("    Total types: \(supportedTypes.count)")
    print("    Registered: \(supportedTypes.filter { registeredTypes.contains($0) }.count)")
  }

  // MARK: - Handler Integration

  private static func demonstrateHandlerIntegration() throws {
    ExampleUtils.printStep(2, "Handler Integration - Type-specific Operations")

    let registry = WellKnownTypesRegistry.shared

    // Timestamp integration
    let now = Date()
    let timestampValue = TimestampHandler.TimestampValue(from: now)
    let timestampMessage = try TimestampHandler.createDynamic(from: timestampValue)

    let specializedTimestamp = try registry.createSpecialized(
      from: timestampMessage,
      typeName: WellKnownTypeNames.timestamp
    )

    print("  ⏰ Timestamp Integration:")
    print("    Original Date: \(now)")
    print("    Specialized Type: \(type(of: specializedTimestamp))")
    print("    Round-trip: \((specializedTimestamp as! TimestampHandler.TimestampValue).toDate())")

    // Duration integration
    let timeInterval: TimeInterval = 3661.500  // 1 hour, 1 minute, 1.5 seconds
    let durationValue = DurationHandler.DurationValue(from: timeInterval)
    let durationMessage = try DurationHandler.createDynamic(from: durationValue)

    let specializedDuration = try registry.createSpecialized(
      from: durationMessage,
      typeName: WellKnownTypeNames.duration
    )

    print("\n  ⏱  Duration Integration:")
    print("    Original Interval: \(timeInterval)s")
    print("    Specialized Type: \(type(of: specializedDuration))")
    print("    Round-trip: \((specializedDuration as! DurationHandler.DurationValue).toTimeInterval())s")

    // FieldMask integration
    let paths = ["user.profile.name", "user.settings.theme", "metadata.version"]
    let fieldMaskValue = try FieldMaskHandler.FieldMaskValue(paths: paths)
    let fieldMaskMessage = try FieldMaskHandler.createDynamic(from: fieldMaskValue)

    let specializedFieldMask = try registry.createSpecialized(
      from: fieldMaskMessage,
      typeName: WellKnownTypeNames.fieldMask
    )

    print("\n  🎯 FieldMask Integration:")
    print("    Original Paths: \(paths)")
    print("    Specialized Type: \(type(of: specializedFieldMask))")
    print("    Round-trip Paths: \((specializedFieldMask as! FieldMaskHandler.FieldMaskValue).paths)")
  }

  // MARK: - Cross-Type Operations

  private static func demonstrateCrossTypeOperations() throws {
    ExampleUtils.printStep(3, "Cross-Type Operations - Type Interoperability")

    let registry = WellKnownTypesRegistry.shared

    // Create Struct with all Well-Known Types
    let complexData: [String: Any] = [
      "created_at": Date().timeIntervalSince1970,
      "duration_seconds": 3600.5,
      "is_active": true,
      "user_settings": [
        "theme": "dark",
        "notifications": true,
        "auto_save_interval": 300,
      ],
      "tags": ["important", "user-data", "v2.0"],
      "metadata": NSNull(),
    ]

    let structValue = try StructHandler.StructValue(from: complexData)
    let structMessage = try StructHandler.createDynamic(from: structValue)

    let specializedStruct =
      try registry.createSpecialized(
        from: structMessage,
        typeName: WellKnownTypeNames.structType
      ) as! StructHandler.StructValue

    print("  📊 Complex Struct with Mixed Types:")
    print("    Original keys: \(complexData.keys.sorted())")
    print("    Specialized keys: \(specializedStruct.fields.keys.sorted())")

    // Extract and convert individual fields
    if let userSettingsValue = specializedStruct.fields["user_settings"] {
      print("\n  🔧 Nested Struct Extraction:")
      print("    User Settings Type: \(type(of: userSettingsValue))")

      if case .structValue(let nestedStruct) = userSettingsValue {
        print("    Nested Keys: \(nestedStruct.fields.keys.sorted())")
      }
    }

    // Create FieldMask for partial updates
    let updatePaths = ["user_settings.theme", "is_active"]
    let updateMask = try FieldMaskHandler.FieldMaskValue(paths: updatePaths)

    print("\n  🎭 Cross-Type Integration:")
    print("    Update Mask Paths: \(updateMask.paths)")
    print("    Applicable to Struct: \(updateMask.covers("user_settings"))")
  }

  // MARK: - Batch Processing

  private static func demonstrateBatchProcessing() throws {
    ExampleUtils.printStep(4, "Batch Processing - Mass Operations")

    let registry = WellKnownTypesRegistry.shared

    // Create batch data of various types
    let batchData: [(String, Any)] = [
      (WellKnownTypeNames.timestamp, TimestampHandler.TimestampValue(from: Date())),
      (WellKnownTypeNames.duration, DurationHandler.DurationValue(from: 1234.567)),
      (WellKnownTypeNames.empty, EmptyHandler.EmptyValue()),
      (WellKnownTypeNames.fieldMask, try FieldMaskHandler.FieldMaskValue(paths: ["a.b", "c.d"])),
      (WellKnownTypeNames.structType, try StructHandler.StructValue(from: ["key": "value"])),
      (WellKnownTypeNames.value, try ValueHandler.ValueValue(from: "test string")),
    ]

    var processedItems: [(String, DynamicMessage)] = []

    let (_, processingTime) = ExampleUtils.measureTime {
      for (typeName, value) in batchData {
        do {
          let message: DynamicMessage

          switch typeName {
          case WellKnownTypeNames.timestamp:
            message = try TimestampHandler.createDynamic(from: value as! TimestampHandler.TimestampValue)
          case WellKnownTypeNames.duration:
            message = try DurationHandler.createDynamic(from: value as! DurationHandler.DurationValue)
          case WellKnownTypeNames.empty:
            message = try EmptyHandler.createDynamic(from: value as! EmptyHandler.EmptyValue)
          case WellKnownTypeNames.fieldMask:
            message = try FieldMaskHandler.createDynamic(from: value as! FieldMaskHandler.FieldMaskValue)
          case WellKnownTypeNames.structType:
            message = try StructHandler.createDynamic(from: value as! StructHandler.StructValue)
          case WellKnownTypeNames.value:
            message = try ValueHandler.createDynamic(from: value as! ValueHandler.ValueValue)
          default:
            continue
          }

          processedItems.append((typeName, message))
        }
        catch {
          print("    ❌ Failed to process \(typeName): \(error)")
        }
      }
    }

    ExampleUtils.printTiming("Batch processing", time: processingTime)

    print("\n  📊 Batch Results:")
    for (typeName, message) in processedItems {
      print("    ✅ \(typeName): \(message.descriptor.name)")
    }

    // Batch validation
    print("\n  🔍 Batch Validation:")
    let registeredTypes = registry.getRegisteredTypes()
    for (typeName, _) in processedItems {
      let isValid = registeredTypes.contains(typeName)
      let status = isValid ? "✅" : "❌"
      print("    \(status) \(typeName) - Registry compatible")
    }
  }

  // MARK: - Advanced Patterns

  private static func demonstrateAdvancedPatterns() throws {
    ExampleUtils.printStep(5, "Advanced Patterns - Complex Scenarios")

    let registry = WellKnownTypesRegistry.shared

    // Pattern 1: Dynamic type detection and processing
    let unknownMessages = try createMixedWellKnownMessages()

    print("  🕵️ Dynamic Type Detection:")
    for (index, message) in unknownMessages.enumerated() {
      let typeName = detectWellKnownType(message: message)

      if let detectedType = typeName {
        let specialized = try registry.createSpecialized(from: message, typeName: detectedType)
        print("    Message \(index + 1): \(detectedType) -> \(type(of: specialized))")
      }
      else {
        print("    Message \(index + 1): Unknown type ❓")
      }
    }

    // Pattern 2: Conditional processing based on type
    print("\n  🔀 Conditional Processing:")
    for (index, message) in unknownMessages.enumerated() {
      if let typeName = detectWellKnownType(message: message) {
        switch typeName {
        case WellKnownTypeNames.timestamp:
          let specialized =
            try registry.createSpecialized(from: message, typeName: typeName) as! TimestampHandler.TimestampValue
          print("    Timestamp \(index + 1): \(specialized.toDate().timeIntervalSince1970)")

        case WellKnownTypeNames.duration:
          let specialized =
            try registry.createSpecialized(from: message, typeName: typeName) as! DurationHandler.DurationValue
          print("    Duration \(index + 1): \(specialized.toTimeInterval())s")

        case WellKnownTypeNames.structType:
          let specialized =
            try registry.createSpecialized(from: message, typeName: typeName) as! StructHandler.StructValue
          print("    Struct \(index + 1): \(specialized.fields.count) fields")

        default:
          print("    Other type \(index + 1): \(typeName)")
        }
      }
    }

    // Pattern 3: Type transformation pipeline
    print("\n  🔄 Type Transformation Pipeline:")
    let originalDate = Date()

    // Date -> Timestamp -> Duration (difference from epoch) -> Struct (metadata)
    let timestampValue = TimestampHandler.TimestampValue(from: originalDate)
    _ = try TimestampHandler.createDynamic(from: timestampValue)

    let epochDiff = originalDate.timeIntervalSince1970
    let durationValue = DurationHandler.DurationValue(from: epochDiff)
    _ = try DurationHandler.createDynamic(from: durationValue)

    let metadataDict: [String: Any] = [
      "original_timestamp": originalDate.timeIntervalSince1970,
      "duration_seconds": epochDiff,
      "formatted_date": ISO8601DateFormatter().string(from: originalDate),
    ]
    let structValue = try StructHandler.StructValue(from: metadataDict)
    _ = try StructHandler.createDynamic(from: structValue)

    print("    Pipeline: Date -> Timestamp -> Duration -> Struct")
    print("    Final Struct fields: \(structValue.fields.count)")
  }

  // MARK: - Performance Optimization

  private static func demonstratePerformanceOptimization() throws {
    ExampleUtils.printStep(6, "Performance Optimization - Registry Efficiency")

    let registry = WellKnownTypesRegistry.shared

    // Benchmark 1: Registry lookup performance
    let lookupIterations = 10000
    let typesToLookup = [
      WellKnownTypeNames.timestamp,
      WellKnownTypeNames.duration,
      WellKnownTypeNames.structType,
      WellKnownTypeNames.value,
    ]

    let (_, lookupTime) = ExampleUtils.measureTime {
      for _ in 0..<lookupIterations {
        for typeName in typesToLookup {
          _ = registry.getHandler(for: typeName)
        }
      }
    }

    let lookupsPerSecond = Double(lookupIterations * typesToLookup.count) / lookupTime
    ExampleUtils.printTiming("Registry lookups", time: lookupTime)
    print("    Lookups/sec: \(String(format: "%.0f", lookupsPerSecond))")

    // Benchmark 2: Specialization performance
    let testMessage = try TimestampHandler.createDynamic(from: TimestampHandler.TimestampValue(from: Date()))
    let specializationIterations = 1000

    let (_, specializationTime) = ExampleUtils.measureTime {
      for _ in 0..<specializationIterations {
        _ = try? registry.createSpecialized(from: testMessage, typeName: WellKnownTypeNames.timestamp)
      }
    }

    let specializationsPerSecond = Double(specializationIterations) / specializationTime
    ExampleUtils.printTiming("Specialization operations", time: specializationTime)
    print("    Specializations/sec: \(String(format: "%.0f", specializationsPerSecond))")

    // Benchmark 3: Batch vs individual processing
    let batchSize = 100
    let testItems = (0..<batchSize).map { _ in
      try! TimestampHandler.createDynamic(from: TimestampHandler.TimestampValue(from: Date()))
    }

    // Individual processing
    let (_, individualTime) = ExampleUtils.measureTime {
      for message in testItems {
        _ = try? registry.createSpecialized(from: message, typeName: WellKnownTypeNames.timestamp)
      }
    }

    // Simulated batch processing (same operations but measured together)
    let (_, batchTime) = ExampleUtils.measureTime {
      let results = testItems.compactMap { message in
        try? registry.createSpecialized(from: message, typeName: WellKnownTypeNames.timestamp)
      }
      _ = results.count
    }

    print("\n  📊 Performance Comparison:")
    ExampleUtils.printTiming("Individual processing (\(batchSize) items)", time: individualTime)
    ExampleUtils.printTiming("Batch processing (\(batchSize) items)", time: batchTime)

    let speedupFactor = individualTime / batchTime
    print("    Batch speedup: \(String(format: "%.1f", speedupFactor))x")

    // Memory usage estimation
    print("\n  💾 Memory Efficiency:")
    print("    Registry singleton: Minimal overhead")
    print("    Specialized objects: Stack allocated when possible")
    print("    Message caching: Not implemented (opportunity for optimization)")
  }

  // MARK: - Helper Functions

  private static func createMixedWellKnownMessages() throws -> [DynamicMessage] {
    return [
      try TimestampHandler.createDynamic(from: TimestampHandler.TimestampValue(from: Date())),
      try DurationHandler.createDynamic(from: DurationHandler.DurationValue(from: 3600)),
      try EmptyHandler.createDynamic(from: EmptyHandler.EmptyValue()),
      try StructHandler.createDynamic(from: try StructHandler.StructValue(from: ["test": "value"])),
      try ValueHandler.createDynamic(from: try ValueHandler.ValueValue(from: 42)),
    ]
  }

  private static func detectWellKnownType(message: DynamicMessage) -> String? {
    let typeName = message.descriptor.fullName

    // Simple type name matching (in real implementation would be more sophisticated)
    if typeName.contains("Timestamp") {
      return WellKnownTypeNames.timestamp
    }
    else if typeName.contains("Duration") {
      return WellKnownTypeNames.duration
    }
    else if typeName.contains("Empty") {
      return WellKnownTypeNames.empty
    }
    else if typeName.contains("FieldMask") {
      return WellKnownTypeNames.fieldMask
    }
    else if typeName.contains("Struct") {
      return WellKnownTypeNames.structType
    }
    else if typeName.contains("Value") {
      return WellKnownTypeNames.value
    }
    else if typeName.contains("Any") {
      return WellKnownTypeNames.any
    }

    return nil
  }
}
