import Foundation
import XCTest

@testable import SwiftProtoReflect

/// Utility class for benchmarking operations in SwiftProtoReflect.
///
/// This class provides methods for measuring the performance of various operations
/// and reporting the results.
public class BenchmarkUtils {

  /// Runs a benchmark with the given name and operation.
  ///
  /// - Parameters:
  ///   - name: The name of the benchmark.
  ///   - iterations: The number of iterations to run.
  ///   - operation: The operation to benchmark.
  /// - Returns: The benchmark result.
  public static func benchmark(name: String, iterations: Int = 1000, operation: () -> Void) -> BenchmarkResult {
    let start = Date()

    for _ in 0..<iterations {
      operation()
    }

    let end = Date()
    let duration = end.timeIntervalSince(start)
    let averageMs = (duration / Double(iterations)) * 1000

    let result = BenchmarkResult(
      name: name,
      iterations: iterations,
      totalDurationSeconds: duration,
      averageDurationMs: averageMs
    )

    print("Benchmark: \(name)")
    print("  Iterations: \(iterations)")
    print("  Total duration: \(String(format: "%.4f", duration)) seconds")
    print("  Average duration: \(String(format: "%.4f", averageMs)) ms")

    return result
  }

  /// Runs a benchmark with the given name and operation that returns a value.
  ///
  /// - Parameters:
  ///   - name: The name of the benchmark.
  ///   - iterations: The number of iterations to run.
  ///   - operation: The operation to benchmark.
  /// - Returns: The benchmark result.
  public static func benchmark<T>(name: String, iterations: Int = 1000, operation: () -> T) -> BenchmarkResult {
    let start = Date()

    var lastValue: T!
    for _ in 0..<iterations {
      lastValue = operation()
    }

    let end = Date()
    let duration = end.timeIntervalSince(start)
    let averageMs = (duration / Double(iterations)) * 1000

    let result = BenchmarkResult(
      name: name,
      iterations: iterations,
      totalDurationSeconds: duration,
      averageDurationMs: averageMs
    )

    print("Benchmark: \(name)")
    print("  Iterations: \(iterations)")
    print("  Total duration: \(String(format: "%.4f", duration)) seconds")
    print("  Average duration: \(String(format: "%.4f", averageMs)) ms")

    return result
  }

  /// Compares two benchmark results and prints the comparison.
  ///
  /// - Parameters:
  ///   - baseline: The baseline benchmark result.
  ///   - current: The current benchmark result.
  public static func compare(baseline: BenchmarkResult, current: BenchmarkResult) {
    let percentChange = ((current.averageDurationMs - baseline.averageDurationMs) / baseline.averageDurationMs) * 100

    print("Benchmark Comparison: \(current.name) vs \(baseline.name)")
    print("  Baseline average: \(String(format: "%.4f", baseline.averageDurationMs)) ms")
    print("  Current average: \(String(format: "%.4f", current.averageDurationMs)) ms")
    print("  Change: \(String(format: "%.2f", percentChange))%")

    if percentChange > 0 {
      print("  Performance regression detected!")
    }
    else if percentChange < 0 {
      print("  Performance improvement detected!")
    }
    else {
      print("  No significant change in performance.")
    }
  }
}

/// Represents the result of a benchmark.
public struct BenchmarkResult {
  /// The name of the benchmark.
  public let name: String

  /// The number of iterations run.
  public let iterations: Int

  /// The total duration of the benchmark in seconds.
  public let totalDurationSeconds: Double

  /// The average duration of a single iteration in milliseconds.
  public let averageDurationMs: Double
}
