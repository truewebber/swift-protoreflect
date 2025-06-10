# Bridge Module

This module handles integration with the existing Swift Protobuf library. It provides:

- Conversion between static and dynamic messages
- Bridge between our descriptors and Swift Protobuf descriptors
- Integration with existing Swift Protobuf infrastructure

## Module Status

- [x] StaticMessageBridge - ✅ COMPLETED
- [x] DescriptorBridge - ✅ COMPLETED

## Components

### StaticMessageBridge
Provides conversion between static Swift Protobuf messages and dynamic DynamicMessage objects:
- Converting static messages to dynamic for reflection
- Creating static messages from dynamic for integration with existing code
- Batch conversion of message arrays
- Type compatibility verification
- Extensions for convenient usage

### DescriptorBridge
Provides conversion between SwiftProtoReflect and Swift Protobuf descriptors:
- MessageDescriptor ↔ Google_Protobuf_DescriptorProto conversion
- FieldDescriptor ↔ Google_Protobuf_FieldDescriptorProto conversion
- EnumDescriptor ↔ Google_Protobuf_EnumDescriptorProto conversion
- FileDescriptor ↔ Google_Protobuf_FileDescriptorProto conversion
- ServiceDescriptor ↔ Google_Protobuf_ServiceDescriptorProto conversion
- Round-trip compatibility

## Interactions with Other Modules

- **Dynamic**: for conversion between static and dynamic messages
- **Descriptor**: for conversion between different descriptor representations
- **Serialization**: for using Swift Protobuf serialization
