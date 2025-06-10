# Swift Protocol Buffers Reflection Library - Business Requirements

## Product Overview
Swift Protocol Buffers Reflection Library is a library that provides the ability to work dynamically with Protocol Buffers messages in Swift 6. The library allows interaction with protobuf messages without pre-compiled .pb files, giving developers flexibility when working with dynamically obtained protodescriptors.

## Key Features

### Dynamic Message Manipulation
- Ability to dynamically create proto objects based on protodescriptors obtained at runtime
- Support for getting protodescriptors from gRPC server or from manually assembled descriptor objects
- Ability to perform proto marshal and unmarshal operations with dynamically created objects

### Usage Without Pre-compilation
- Working with proto messages without the need for pre-compilation of .proto files
- Performing gRPC calls without pre-compiled protobuf files

## Requirements and Limitations

### Technical Limitations
- Support only for proto3 protocol, without proto2 support
- Strict compliance with the behavior of the official C++ protoc implementation (https://github.com/protocolbuffers/protobuf)
- Adherence to Protocol Buffers specification with strict enforcement of official documentation requirements

### Performance
- Target performance should be at the level of protoc-generated code
- Optimization of serialization/deserialization operations to minimize reflection overhead

## Integrations and Dependencies
- The library will serve as the foundation for a future gRPC/gRPC-web client for Swift developers
- Ensuring compatibility with existing Swift Protocol Buffers implementations

## Usage Scenarios

### Dynamic Message Processing
- Processing unknown message types received at runtime
- Dynamic creation and manipulation of Protocol Buffers messages

### gRPC Interaction
- Performing gRPC calls to services with API unknown at compile time
- Implementation of dynamic gRPC clients

## Examples of Analogs
- Google Protocol Buffers reflection for Go: google.golang.org/protobuf/reflect/protoreflect
