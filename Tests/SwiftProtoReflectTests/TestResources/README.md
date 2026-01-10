# Test Resources

The directory contains resources for testing Protocol Buffers:

1. `proto/` - `.proto` files for tests
   - Basic types and structures
   - Complex structures with nested messages
   - Special cases (oneof, map, etc.)

2. `binary/` - Reference binary data for deserialization tests
   - C++ protoc serialized messages
   - Reference messages of different versions for compatibility tests

3. `json/` - Reference JSON representations for JSON format tests
   - Standard cases
   - Edge cases (NaN, Infinity, etc.)

4. `reference/` - Reference output data from C++ implementation
   - Test output data for comparison

These resources are used by various tests to verify that the behavior of
our library matches the official C++ protoc implementation and Protocol Buffers specification.
