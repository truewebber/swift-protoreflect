# Test Utilities

The directory contains utility helpers for testing Protocol Buffers:

1. `TestHelpers.swift` - common helper functions for tests
   - Binary data comparison functions
   - Message structure comparison functions
   - Utilities for creating typical test cases

2. `CPPBridge.swift` - bridge to C++ Protocol Buffers implementation for comparison
   - Functions to run C++ protoc for generating reference data
   - Functions to call C++ serializers/deserializers

3. `PerformanceMeasurement.swift` - performance measurement utilities

4. `TestDescriptors.swift` - ready-made descriptors for tests

These utilities are used in tests to simplify testing and ensure 
consistency of comparison with the reference C++ implementation.
