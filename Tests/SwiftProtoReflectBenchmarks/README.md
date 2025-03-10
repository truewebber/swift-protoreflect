# SwiftProtoReflect Performance Benchmarks

This directory contains performance benchmarks for the SwiftProtoReflect library. These benchmarks measure the performance of various operations in the library, including:

- Core types (ProtoValue, ProtoFieldDescriptor, ProtoMessageDescriptor)
- DescriptorRegistry operations
- ProtoWireFormat serialization and deserialization

## Running Benchmarks

You can run all benchmarks using the following command:

```bash
swift test --filter BenchmarkRunner/testRunAllBenchmarks
```

Or run a specific benchmark by setting the `BENCHMARK_NAME` environment variable:

```bash
BENCHMARK_NAME="ProtoValue.creation" swift test --filter BenchmarkRunner/testRunBenchmark
```

## Available Benchmarks

### Core Types Benchmarks

- `ProtoValue.creation`: Measures the performance of creating ProtoValue instances
- `ProtoValue.access`: Measures the performance of accessing values from ProtoValue instances
- `ProtoValue.hashable`: Measures the performance of using ProtoValue in hashable collections
- `ProtoValue.equality`: Measures the performance of comparing ProtoValue instances
- `ProtoFieldDescriptor.creation`: Measures the performance of creating ProtoFieldDescriptor instances
- `ProtoFieldDescriptor.validation`: Measures the performance of validating ProtoFieldDescriptor instances
- `ProtoFieldDescriptor.hashable`: Measures the performance of using ProtoFieldDescriptor in hashable collections
- `ProtoMessageDescriptor.creation`: Measures the performance of creating ProtoMessageDescriptor instances
- `ProtoMessageDescriptor.fieldLookup`: Measures the performance of looking up fields in a ProtoMessageDescriptor

### DescriptorRegistry Benchmarks

- `DescriptorRegistry.registerFileDescriptor`: Measures the performance of registering a file descriptor
- `DescriptorRegistry.messageDescriptor`: Measures the performance of looking up a message descriptor
- `DescriptorRegistry.enumDescriptor`: Measures the performance of looking up an enum descriptor
- `DescriptorRegistry.nestedMessageDescriptor`: Measures the performance of looking up a nested message descriptor

### ProtoWireFormat Benchmarks

- `ProtoWireFormat.encodeVarint`: Measures the performance of encoding a varint
- `ProtoWireFormat.decodeVarint`: Measures the performance of decoding a varint
- `ProtoWireFormat.encodeField`: Measures the performance of encoding a field
- `ProtoWireFormat.determineWireType`: Measures the performance of determining the wire type for a field type

## Interpreting Results

The benchmark results include the following information:

- **Name**: The name of the benchmark
- **Iterations**: The number of iterations run
- **Total Duration**: The total time taken to run all iterations
- **Average Duration**: The average time taken per iteration

The benchmarks also include assertions to ensure that the performance meets certain thresholds. If a benchmark fails, it means that the performance is worse than expected.

## Adding New Benchmarks

To add a new benchmark:

1. Add a new test method to the appropriate benchmark class
2. Add the benchmark to the `testRunAllBenchmarks` method in `BenchmarkRunner.swift`
3. Add a case for the benchmark in the `testRunBenchmark` method in `BenchmarkRunner.swift`
4. Add the benchmark to the list of available benchmarks in this README 