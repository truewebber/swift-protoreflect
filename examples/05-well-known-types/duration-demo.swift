/**
 * ⏱ SwiftProtoReflect Example: Duration Demo
 *
 * Description: Working with google.protobuf.Duration and conversion with TimeInterval
 * Key concepts: DurationHandler, WellKnownTypes, TimeInterval conversion
 * Complexity: 🔧 Intermediate
 * Execution time: < 10 seconds
 *
 * What you'll learn:
 * - Creating and converting google.protobuf.Duration
 * - Integration with Foundation.TimeInterval
 * - Time intervals with nanosecond precision
 * - Negative time durations
 * - Utility operations (abs, negated, zero)
 * - Validation of seconds/nanos fields
 *
 * Run with:
 *   swift run DurationDemo
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct DurationDemo {
  static func main() throws {
    ExampleUtils.printHeader("Google Protobuf Duration Integration")

    try demonstrateBasicUsage()
    try demonstrateAdvancedOperations()
    try demonstrateUtilityMethods()
    try demonstrateSignValidation()
    try demonstratePerformanceAndEdgeCases()

    ExampleUtils.printSuccess("Duration demo completed! You've learned all aspects of working with google.protobuf.Duration.")

    ExampleUtils.printNext([
      "Next, explore: empty-demo.swift - empty messages",
      "Compare with: timestamp-demo.swift - timestamps",
      "Advanced: field-mask-demo.swift - field masks for updates",
    ])
  }

  // MARK: - Implementation Steps

  private static func demonstrateBasicUsage() throws {
    ExampleUtils.printStep(1, "Basic Duration Operations")

    // Create from TimeInterval
    let timeInterval: TimeInterval = 123.456789
    let durationValue = DurationHandler.DurationValue(from: timeInterval)
    let durationMessage = try DurationHandler.createDynamic(from: durationValue)

    print("  ⏱ Original TimeInterval: \(timeInterval) seconds")
    print("  📊 Duration seconds: \(durationValue.seconds)")
    print("  🔢 Duration nanos: \(durationValue.nanos)")

    // Convert back
    let extractedValue = try DurationHandler.createSpecialized(from: durationMessage) as! DurationHandler.DurationValue
    let reconstructedInterval = extractedValue.toTimeInterval()

    print("  🔄 Reconstructed TimeInterval: \(reconstructedInterval) seconds")

    let timeDifference = abs(timeInterval - reconstructedInterval)
    print("  ✅ Precision (difference): \(String(format: "%.9f", timeDifference)) seconds")
    print("  ✅ High precision match: \(timeDifference < 0.000001 ? "YES" : "NO")")

    // Check message structure
    print("  📋 Message structure:")
    print("    Message type: \(durationMessage.descriptor.name)")
    print("    Fields count: \(durationMessage.descriptor.fields.count)")
    for field in durationMessage.descriptor.fields.values {
      let value = try? durationMessage.get(forField: field.name)
      print("    \(field.name): \(value ?? "nil")")
    }

    // Check sign consistency
    let sameSign =
      (durationValue.seconds >= 0 && durationValue.nanos >= 0)
      || (durationValue.seconds <= 0 && durationValue.nanos <= 0)
      || (durationValue.seconds == 0 || durationValue.nanos == 0)
    print("  ✅ Sign consistency: \(sameSign ? "VALID" : "INVALID")")
  }

  private static func demonstrateAdvancedOperations() throws {
    ExampleUtils.printStep(2, "Advanced Duration Operations")

    // Various types of time intervals
    let testDurations = [
      ("Millisecond", 0.001),
      ("Second", 1.0),
      ("Minute", 60.0),
      ("Hour", 3600.0),
      ("Negative second", -1.0),
      ("Negative minute", -60.0),
      ("Mixed signs (positive)", 1.5),
      ("Mixed signs (negative)", -2.75),
      ("Very small", 0.000000123),
      ("Very large", 86400.0),  // 1 day
    ]

    ExampleUtils.printDataTable(
      testDurations.map { (label, interval) in
        let durationValue = DurationHandler.DurationValue(from: interval)
        let humanReadable = formatDurationHuman(interval)
        let signConsistent = isSignConsistent(durationValue)

        return [
          "Type": label,
          "TimeInterval": String(format: "%.6f", interval),
          "Seconds": "\(durationValue.seconds)",
          "Nanos": "\(durationValue.nanos)",
          "Human": humanReadable,
          "Sign OK": signConsistent ? "✅" : "❌",
        ]
      },
      title: "Duration Types Analysis"
    )

    // Precision demonstration with fractional seconds
    print("  🎯 Precision demonstration with fractional seconds:")
    let precisionTests = [0.1, 0.01, 0.001, 0.0001, 0.00001]

    for precision in precisionTests {
      let duration = DurationHandler.DurationValue(from: precision)
      let roundTrip = duration.toTimeInterval()
      let error = abs(precision - roundTrip)
      let errorPercent = (error / precision) * 100

      print(
        "    \(String(format: "%.5f", precision))s -> " + "\(String(format: "%.5f", roundTrip))s "
          + "(error: \(String(format: "%.3f%%", errorPercent)))"
      )
    }
  }

  private static func demonstrateUtilityMethods() throws {
    ExampleUtils.printStep(3, "Duration Utility Methods")

    // Create various duration values for demonstration
    let testCases = [
      ("Positive duration", try DurationHandler.DurationValue(seconds: 5, nanos: 500_000_000)),
      ("Negative duration", try DurationHandler.DurationValue(seconds: -3, nanos: -250_000_000)),
      ("Zero duration", DurationHandler.DurationValue.zero()),
      ("Only nanos", try DurationHandler.DurationValue(seconds: 0, nanos: 123_456_789)),
      ("Large duration", try DurationHandler.DurationValue(seconds: 3661, nanos: 0)),  // 1h 1m 1s
    ]

    var utilityResults: [[String: String]] = []

    for (label, duration) in testCases {
      let original = duration.toTimeInterval()
      let absolute = duration.abs()
      let negated = duration.negated()
      let isZero = duration == DurationHandler.DurationValue.zero()

      utilityResults.append([
        "Case": label,
        "Original": String(format: "%.3f", original),
        "Absolute": String(format: "%.3f", absolute.toTimeInterval()),
        "Negated": String(format: "%.3f", negated.toTimeInterval()),
        "Is Zero": isZero ? "✅" : "❌",
        "Sign": original >= 0 ? "+" : "-",
      ])
    }

    ExampleUtils.printDataTable(utilityResults, title: "Utility Methods Results")

    // Demonstration of special methods
    print("  🔧 Special operations:")
    let positiveDuration = try DurationHandler.DurationValue(seconds: 2, nanos: 500_000_000)
    let negativeDuration = try DurationHandler.DurationValue(seconds: -1, nanos: -750_000_000)

    print("    Original positive: \(positiveDuration.toTimeInterval())s")
    print("    Absolute of positive: \(positiveDuration.abs().toTimeInterval())s")
    print("    Negated positive: \(positiveDuration.negated().toTimeInterval())s")
    print()
    print("    Original negative: \(negativeDuration.toTimeInterval())s")
    print("    Absolute of negative: \(negativeDuration.abs().toTimeInterval())s")
    print("    Negated negative: \(negativeDuration.negated().toTimeInterval())s")

    // Zero duration properties
    let zero = DurationHandler.DurationValue.zero()
    print("    Zero duration: seconds=\(zero.seconds), nanos=\(zero.nanos)")
    print("    Zero is zero: \(zero == DurationHandler.DurationValue.zero())")
    print("    Zero absolute: \(zero.abs().toTimeInterval())s")
    print("    Zero negated: \(zero.negated().toTimeInterval())s")
  }

  private static func demonstrateSignValidation() throws {
    ExampleUtils.printStep(4, "Sign Validation and Edge Cases")

    // Testing sign rules for Duration
    let signTestCases = [
      // Valid cases
      ("Both positive", 1, 500_000_000, true),
      ("Both negative", -1, -500_000_000, true),
      ("Zero seconds, positive nanos", 0, 123_456_789, true),
      ("Zero seconds, negative nanos", 0, -123_456_789, true),
      ("Positive seconds, zero nanos", 5, 0, true),
      ("Negative seconds, zero nanos", -5, 0, true),
      ("Both zero", 0, 0, true),

      // Invalid cases (mixed signs)
      ("Positive seconds, negative nanos", 1, -500_000_000, false),
      ("Negative seconds, positive nanos", -1, 500_000_000, false),

      // Edge cases
      ("Max valid nanos", 0, 999_999_999, true),
      ("Min valid nanos", 0, -999_999_999, true),
      ("Invalid large nanos", 0, 1_000_000_000, false),
      ("Invalid small nanos", 0, -1_000_000_000, false),
    ]

    var validationResults: [[String: String]] = []

    for (label, seconds, nanos, shouldBeValid) in signTestCases {
      do {
        let duration = try DurationHandler.DurationValue(seconds: Int64(seconds), nanos: Int32(nanos))
        let timeInterval = duration.toTimeInterval()
        let signValid = isSignConsistent(duration)
        let status = shouldBeValid ? "✅ VALID" : "⚠️ UNEXPECTED SUCCESS"

        validationResults.append([
          "Case": label,
          "Seconds": "\(seconds)",
          "Nanos": "\(nanos)",
          "TimeInterval": String(format: "%.6f", timeInterval),
          "Sign Valid": signValid ? "✅" : "❌",
          "Status": status,
        ])
      }
      catch {
        let status = shouldBeValid ? "❌ UNEXPECTED ERROR" : "✅ CORRECTLY REJECTED"
        validationResults.append([
          "Case": label,
          "Seconds": "\(seconds)",
          "Nanos": "\(nanos)",
          "TimeInterval": "ERROR",
          "Sign Valid": "N/A",
          "Status": status,
        ])
      }
    }

    ExampleUtils.printDataTable(validationResults, title: "Sign Validation Results")

    print("  📝 Duration validation rules:")
    print("    • seconds and nanos must have the same sign")
    print("    • or one of them must be zero")
    print("    • nanos must be in range [-999,999,999, 999,999,999]")
    print("    • both fields can be negative for negative durations")
  }

  private static func demonstratePerformanceAndEdgeCases() throws {
    ExampleUtils.printStep(5, "Performance and Edge Cases")

    // Performance benchmarking
    let testCount = 1000

    let (_, conversionTime) = ExampleUtils.measureTime {
      for _ in 0..<testCount {
        let interval = Double.random(in: -1000...1000)
        let duration = DurationHandler.DurationValue(from: interval)
        let _ = duration.toTimeInterval()
      }
    }

    let (_, handlerTime) = ExampleUtils.measureTime {
      for _ in 0..<testCount {
        let interval = Double.random(in: -1000...1000)
        let duration = DurationHandler.DurationValue(from: interval)
        let _ = try! DurationHandler.createDynamic(from: duration)
      }
    }

    ExampleUtils.printTiming("Duration conversions (\(testCount) iterations)", time: conversionTime)
    ExampleUtils.printTiming("Handler operations (\(testCount) iterations)", time: handlerTime)

    let conversionsPerSecond = Double(testCount) / conversionTime
    let handlerOpsPerSecond = Double(testCount) / handlerTime

    print("  🚀 Performance:")
    print("    Conversions: \(String(format: "%.0f", conversionsPerSecond)) ops/second")
    print("    Handler operations: \(String(format: "%.0f", handlerOpsPerSecond)) ops/second")

    // Edge cases testing
    print("  🔍 Edge cases analysis:")
    let edgeCases = [
      ("Smallest positive", 0.000000001),  // 1 nanosecond
      ("Largest practical", 86400.0 * 365),  // 1 year
      ("Negative smallest", -0.000000001),
      ("Negative largest", -86400.0 * 365),
      ("Near zero positive", 0.0000000001),
      ("Near zero negative", -0.0000000001),
    ]

    var edgeResults: [[String: String]] = []

    for (label, interval) in edgeCases {
      let duration = DurationHandler.DurationValue(from: interval)
      let roundTrip = duration.toTimeInterval()
      let error = abs(interval - roundTrip)
      let errorPercent = interval != 0 ? (error / abs(interval)) * 100 : 0

      edgeResults.append([
        "Case": label,
        "Input": String(format: "%.9f", interval),
        "Seconds": "\(duration.seconds)",
        "Nanos": "\(duration.nanos)",
        "Output": String(format: "%.9f", roundTrip),
        "Error %": String(format: "%.3f%%", errorPercent),
      ])
    }

    ExampleUtils.printDataTable(edgeResults, title: "Edge Cases Analysis")

    print("  💡 Key insights:")
    print("    • Duration supports both positive and negative intervals")
    print("    • Nanosecond precision is preserved in most cases")
    print("    • Utility methods (abs, negated, zero) work correctly")
    print("    • Sign validation ensures canonical representation")
    print("    • Performance meets production usage requirements")
  }
}

// MARK: - Helper Functions

private func formatDurationHuman(_ interval: TimeInterval) -> String {
  let absInterval = abs(interval)
  let sign = interval < 0 ? "-" : ""

  if absInterval >= 3600 {
    let hours = Int(absInterval / 3600)
    let remainder = absInterval.truncatingRemainder(dividingBy: 3600)
    let minutes = Int(remainder / 60)
    return "\(sign)\(hours)h \(minutes)m"
  }
  else if absInterval >= 60 {
    let minutes = Int(absInterval / 60)
    let seconds = absInterval.truncatingRemainder(dividingBy: 60)
    return "\(sign)\(minutes)m \(String(format: "%.1f", seconds))s"
  }
  else if absInterval >= 1 {
    return "\(sign)\(String(format: "%.3f", absInterval))s"
  }
  else if absInterval >= 0.001 {
    return "\(sign)\(String(format: "%.1f", absInterval * 1000))ms"
  }
  else {
    return "\(sign)\(String(format: "%.1f", absInterval * 1_000_000))μs"
  }
}

private func isSignConsistent(_ duration: DurationHandler.DurationValue) -> Bool {
  return (duration.seconds >= 0 && duration.nanos >= 0) || (duration.seconds <= 0 && duration.nanos <= 0)
    || (duration.seconds == 0 || duration.nanos == 0)
}
