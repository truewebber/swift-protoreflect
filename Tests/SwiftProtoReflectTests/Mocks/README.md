# Mocks

The directory contains mock objects for testing Protocol Buffers:

1. `MockDescriptors.swift` - mocks for message descriptors
   - Stubs for various descriptor types
   - Mocks with specific behavior for tests

2. `MockMessages.swift` - mocks for messages
   - Stubs for dynamic messages
   - Mocks with predefined data

3. `MockSerializer.swift` - mocks for serializers/deserializers
   - Stubs for testing error handling
   - Mocks with predefined results

These mocks allow isolated testing of various library components by
simulating specific behavior of other components. 