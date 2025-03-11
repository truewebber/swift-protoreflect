import XCTest

@testable import SwiftProtoReflect

/// A test case that runs all benchmarks.
///
/// This class serves as an entry point for running all benchmarks in the project.
/// It can be run from the command line using `swift test --filter BenchmarkRunner`.
class BenchmarkRunner: XCTestCase {

  /// Runs all benchmarks in the project.
  func testRunAllBenchmarks() {
    print("\n=== SwiftProtoReflect Performance Benchmarks ===\n")

    // Run core types benchmarks
    print("\n--- Core Types Benchmarks ---\n")
    let coreTypesBenchmarks = CoreTypesBenchmarks()
    coreTypesBenchmarks.setUp()
    coreTypesBenchmarks.testProtoValueCreationPerformance()
    coreTypesBenchmarks.testProtoValueAccessPerformance()
    coreTypesBenchmarks.testProtoValueHashablePerformance()
    coreTypesBenchmarks.testProtoValueEqualityPerformance()
    coreTypesBenchmarks.testProtoFieldDescriptorCreationPerformance()
    coreTypesBenchmarks.testProtoFieldDescriptorValidationPerformance()
    coreTypesBenchmarks.testProtoFieldDescriptorHashablePerformance()
    coreTypesBenchmarks.testProtoMessageDescriptorCreationPerformance()
    coreTypesBenchmarks.testProtoMessageDescriptorFieldLookupPerformance()

    // Run descriptor registry benchmarks
    print("\n--- Descriptor Registry Benchmarks ---\n")
    let registryBenchmarks = DescriptorRegistryBenchmarks()
    registryBenchmarks.setUp()
    registryBenchmarks.testRegistrationPerformance()
    registryBenchmarks.testMessageLookupPerformance()
    registryBenchmarks.testEnumLookupPerformance()
    registryBenchmarks.testNestedMessageLookupPerformance()

    // Run wire format benchmarks
    print("\n--- Wire Format Benchmarks ---\n")
    let wireFormatBenchmarks = ProtoWireFormatBenchmarks()
    wireFormatBenchmarks.setUp()
    wireFormatBenchmarks.testVarintEncodingPerformance()
    wireFormatBenchmarks.testVarintDecodingPerformance()
    wireFormatBenchmarks.testSint32FieldEncodingPerformance()
    wireFormatBenchmarks.testSint64FieldEncodingPerformance()
    wireFormatBenchmarks.testWireTypePerformance()

    print("\n=== Benchmark Run Complete ===\n")
  }

  /// Runs a specific benchmark by name.
  ///
  /// This method can be used to run a specific benchmark from the command line.
  /// For example: `swift test --filter BenchmarkRunner/testRunBenchmark`
  func testRunBenchmark() {
    // Get the benchmark name from the environment
    guard let benchmarkName = ProcessInfo.processInfo.environment["BENCHMARK_NAME"] else {
      print("No benchmark name specified. Set the BENCHMARK_NAME environment variable.")
      return
    }

    print("\n=== Running Benchmark: \(benchmarkName) ===\n")

    // Run the specified benchmark
    switch benchmarkName {
    case "ProtoValue.creation":
      let benchmark = CoreTypesBenchmarks()
      benchmark.setUp()
      benchmark.testProtoValueCreationPerformance()

    case "ProtoValue.access":
      let benchmark = CoreTypesBenchmarks()
      benchmark.setUp()
      benchmark.testProtoValueAccessPerformance()

    case "ProtoValue.hashable":
      let benchmark = CoreTypesBenchmarks()
      benchmark.setUp()
      benchmark.testProtoValueHashablePerformance()

    case "ProtoValue.equality":
      let benchmark = CoreTypesBenchmarks()
      benchmark.setUp()
      benchmark.testProtoValueEqualityPerformance()

    case "ProtoFieldDescriptor.creation":
      let benchmark = CoreTypesBenchmarks()
      benchmark.setUp()
      benchmark.testProtoFieldDescriptorCreationPerformance()

    case "ProtoFieldDescriptor.validation":
      let benchmark = CoreTypesBenchmarks()
      benchmark.setUp()
      benchmark.testProtoFieldDescriptorValidationPerformance()

    case "ProtoFieldDescriptor.hashable":
      let benchmark = CoreTypesBenchmarks()
      benchmark.setUp()
      benchmark.testProtoFieldDescriptorHashablePerformance()

    case "ProtoMessageDescriptor.creation":
      let benchmark = CoreTypesBenchmarks()
      benchmark.setUp()
      benchmark.testProtoMessageDescriptorCreationPerformance()

    case "ProtoMessageDescriptor.fieldLookup":
      let benchmark = CoreTypesBenchmarks()
      benchmark.setUp()
      benchmark.testProtoMessageDescriptorFieldLookupPerformance()

    case "DescriptorRegistry.registerFileDescriptor":
      let benchmark = DescriptorRegistryBenchmarks()
      benchmark.setUp()
      benchmark.testRegistrationPerformance()

    case "DescriptorRegistry.messageDescriptor":
      let benchmark = DescriptorRegistryBenchmarks()
      benchmark.setUp()
      benchmark.testMessageLookupPerformance()

    case "DescriptorRegistry.enumDescriptor":
      let benchmark = DescriptorRegistryBenchmarks()
      benchmark.setUp()
      benchmark.testEnumLookupPerformance()

    case "DescriptorRegistry.nestedMessageDescriptor":
      let benchmark = DescriptorRegistryBenchmarks()
      benchmark.setUp()
      benchmark.testNestedMessageLookupPerformance()

    case "ProtoWireFormat.encodeVarint":
      let benchmark = ProtoWireFormatBenchmarks()
      benchmark.setUp()
      benchmark.testVarintEncodingPerformance()

    case "ProtoWireFormat.decodeVarint":
      let benchmark = ProtoWireFormatBenchmarks()
      benchmark.setUp()
      benchmark.testVarintDecodingPerformance()

    case "ProtoWireFormat.encodeField.sint32":
      let benchmark = ProtoWireFormatBenchmarks()
      benchmark.setUp()
      benchmark.testSint32FieldEncodingPerformance()

    case "ProtoWireFormat.encodeField.sint64":
      let benchmark = ProtoWireFormatBenchmarks()
      benchmark.setUp()
      benchmark.testSint64FieldEncodingPerformance()

    case "ProtoWireFormat.determineWireType":
      let benchmark = ProtoWireFormatBenchmarks()
      benchmark.setUp()
      benchmark.testWireTypePerformance()

    default:
      print("Unknown benchmark: \(benchmarkName)")
    }

    print("\n=== Benchmark Run Complete ===\n")
  }
}
