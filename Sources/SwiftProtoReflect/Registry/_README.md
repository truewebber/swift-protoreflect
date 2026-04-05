# Registry Module

This module handles centralized type and descriptor management. It provides:

- Registration and resolution of dependencies between types
- Efficient descriptor lookup by name
- Centralized storage for all known types

> **Required for serialization:** `TypeRegistry` is a required dependency for all
> `BinaryDeserializer`, `JSONDeserializer`, and `JSONSerializer` instances.
> Always populate a registry with the types your messages reference before
> serializing or deserializing.

## Module Status

- [x] TypeRegistry ✅
- [x] DescriptorPool ✅

## TypeRegistry

`TypeRegistry` provides thread-safe storage and lookup of `MessageDescriptor`,
`EnumDescriptor`, `ServiceDescriptor`, and `FileDescriptor` by their fully-qualified names.

### When to use `TypeRegistry(fileDescriptors:)`

Use the convenience initializer in production when you have `FileDescriptor`s that describe
all your proto files. All messages, enums, and services from every file are registered
automatically:

```swift
// Build FileDescriptors for all proto files your application uses.
var userFile = FileDescriptor(name: "user.proto", package: "myapp")
userFile.addMessage(userDescriptor)
userFile.addEnum(statusEnum)

var orderFile = FileDescriptor(name: "order.proto", package: "myapp")
orderFile.addMessage(orderDescriptor)

// Convenience init — registers everything in one call.
let registry = TypeRegistry(fileDescriptors: [userFile, orderFile])

// Pass to serializers/deserializers.
let serializer = JSONSerializer(options: .init(typeRegistry: registry))
```

### When to use explicit `registerMessage` / `registerEnum`

Use explicit registration for hand-built descriptors in tests and tools, or when you only
want to register a specific subset of types:

```swift
let registry = TypeRegistry()
try registry.registerMessage(addressDescriptor)
try registry.registerEnum(statusEnum)

let deserializer = BinaryDeserializer(options: .init(typeRegistry: registry))
```

### Key methods

| Method | Description |
|--------|-------------|
| `TypeRegistry(fileDescriptors:)` | Convenience init — registers all types from file descriptors |
| `registerFile(_:)` | Register all types from a `FileDescriptor` |
| `registerMessage(_:)` | Register a single `MessageDescriptor` (recursively registers nested types) |
| `registerEnum(_:)` | Register a single `EnumDescriptor` |
| `findMessage(named:)` | Look up a `MessageDescriptor` by fully-qualified name |
| `findEnum(named:)` | Look up an `EnumDescriptor` by fully-qualified name |
| `allFiles()` | Return all registered `FileDescriptor`s |

## Interactions with Other Modules

- **Descriptor**: manages `FileDescriptor`, `MessageDescriptor`, `EnumDescriptor`
- **Serialization**: TypeRegistry is a **required** input for `BinaryDeserializer`,
  `JSONDeserializer`, and `JSONSerializer` via their options structs
- **Dynamic**: used for creating messages by type name at runtime
