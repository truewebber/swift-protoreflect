# Service Module

This module handles dynamic interaction with gRPC services. It provides:

- Dynamic gRPC method calls without pre-compiling .proto files
- Processing server responses with compile-time unknown types
- Working with gRPC services through dynamic descriptors

## Module Status

- [x] **ServiceClient** - Dynamic client for calling gRPC methods ✅ COMPLETED
  - [x] Unary calls (85.93% test coverage)
  - [x] Request/response type validation
  - [x] Error handling (full coverage of all error types)
  - [x] Configurable call options (timeouts, metadata)
  - [x] GRPCPayloadWrapper (full serialization/deserialization coverage)
  - [x] Helper methods (serialization, deserialization, validation)
  - [ ] Client streaming calls (future versions)
  - [ ] Server streaming calls (future versions)
  - [ ] Bidirectional streaming calls (future versions)

## Components

### ServiceClient

Main class for performing dynamic gRPC calls.

**Capabilities:**
- Dynamic unary calls based on ServiceDescriptor
- Automatic DynamicMessage serialization/deserialization
- Type compatibility validation
- Configurable options (timeouts, metadata)
- Detailed error handling

**Usage example:**
```swift
let client = ServiceClient(channel: channel, typeRegistry: registry)

let result = try await client.unaryCall(
  service: serviceDescriptor,
  method: "GetUser",
  request: requestMessage,
  options: ServiceClient.CallOptions(
    timeout: .seconds(30),
    metadata: ["authorization": "Bearer token"]
  )
)

print("Response: \(result.response)")
```

### ServiceClientError

Error enumeration for ServiceClient with detailed descriptions:
- `methodNotFound` - method not found in service
- `invalidMethodType` - invalid method type (e.g., streaming instead of unary)
- `typeMismatch` - message type mismatch
- `typeNotFound` - type not found in registry
- `serializationError` - serialization error
- `deserializationError` - deserialization error
- `grpcError` - gRPC error

## Interactions with Other Modules

- **Descriptor**: for getting service and method metadata
- **Dynamic**: for working with dynamic messages during calls
- **Registry**: for type resolution during RPC calls
- **Serialization**: for message serialization/deserialization

## Architectural Decisions

1. **gRPC Swift Integration**: Uses low-level gRPC Swift API for maximum flexibility
2. **Type Safety**: Strict runtime type checking
3. **Error Handling**: Detailed error handling with clear messages
4. **Extensibility**: Architecture allows easy addition of streaming method support
