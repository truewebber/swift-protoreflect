# Migration Guide

## Part 1: SwiftProtobuf vs SwiftProtoReflect

SwiftProtobuf requires compile-time code generation (`protoc`). SwiftProtoReflect works entirely at runtime — no `.pb.swift` files needed.

### Message Creation

**SwiftProtobuf:**

```swift
import GeneratedProtos

var person = Person()
person.name = "Alice"
person.age = 30
person.email = "alice@example.com"
```

**SwiftProtoReflect:**

```swift
import SwiftProtoReflect

var desc = MessageDescriptor(name: "Person", fullName: "example.Person")
desc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
desc.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
desc.addField(FieldDescriptor(name: "email", number: 3, type: .string))

var person = DynamicMessage(descriptor: desc)
try person.set("Alice", forField: "name")
try person.set(Int32(30), forField: "age")
try person.set("alice@example.com", forField: "email")
```

### Serialization

**SwiftProtobuf:**

```swift
let data = try person.serializedData()
let json = try person.jsonUTF8Data()

let decoded = try Person(serializedBytes: data)
```

**SwiftProtoReflect:**

```swift
let registry = TypeRegistry()
try registry.registerMessage(desc)

let data = try BinarySerializer().serialize(person)
let json = try JSONSerializer(options: .init(typeRegistry: registry)).serialize(person)

let decoded = try BinaryDeserializer(options: .init(typeRegistry: registry))
    .deserialize(data, using: desc)
```

### Field Access

**SwiftProtobuf:**

```swift
let name = person.name          // String, compile-time safe
let age = person.age            // Int32
```

**SwiftProtoReflect:**

```swift
let name = try person.get(forField: "name") as? String
let age = try person.get(forField: "age") as? Int32

// Or via typed accessor:
let accessor = person.fieldAccessor
let name = accessor.getString("name")
let age = accessor.getInt32("age")
```

### Nested and Cross-File Types

**SwiftProtobuf:** Handled automatically by generated code.

**SwiftProtoReflect:** Register all types in `TypeRegistry`:

```swift
let registry = TypeRegistry()
try registry.registerFile(addressFile)
try registry.registerFile(personFile)

// Or use the convenience initializer:
let registry = try TypeRegistry(fileDescriptors: [addressFile, personFile])
```

### Static-Dynamic Interop

Convert between generated SwiftProtobuf messages and DynamicMessage:

```swift
let bridge = StaticMessageBridge()

// Static → Dynamic
let dynamic = try bridge.toDynamicMessage(from: staticPerson, using: personDesc)

// Dynamic → Static
let static: Person = try bridge.toStaticMessage(from: dynamic, as: Person.self)

// Shorthand extensions
let dynamic = try staticPerson.toDynamicMessage(using: personDesc)
let static: Person = try dynamic.toStaticMessage(as: Person.self)
```

### Well-Known Types

**SwiftProtobuf:**

```swift
let ts = Google_Protobuf_Timestamp(date: Date())
```

**SwiftProtoReflect:**

```swift
let ts = try DynamicMessage.timestampMessage(from: Date())
let date = try ts.toDate()

let dur = try DynamicMessage.durationMessage(from: TimeInterval(3.5))
let empty = try DynamicMessage.emptyMessage()
let mask = try DynamicMessage.fieldMaskMessage(from: ["name", "email"])
let structMsg = try DynamicMessage.structMessage(from: ["key": "value", "count": 42])
```

---

## Part 2: SwiftProtoReflect v5 → v6

### Removed: Deprecated Descriptor Initializers

The `parent: Any?` overloads are removed. Use typed `DescriptorParent` instead.

```swift
// v5 (removed)
let msg = MessageDescriptor(name: "Child", parent: fileDesc as Any?)
let enm = EnumDescriptor(name: "Status", parent: fileDesc as Any?)

// v6
let msg = MessageDescriptor(name: "Child", parent: fileDesc)
let enm = EnumDescriptor(name: "Status", parent: fileDesc)
```

Both `FileDescriptor` and `MessageDescriptor` conform to `DescriptorParent`.

### Removed: Deprecated Serializer Constructors

No-argument `init()` is removed from all serializers/deserializers. Pass `TypeRegistry` explicitly.

```swift
// v5 (removed)
let ser = JSONSerializer()
let deser = JSONDeserializer()
let binDeser = BinaryDeserializer()

// v6
let registry = TypeRegistry()
let ser = JSONSerializer(options: .init(typeRegistry: registry))
let deser = JSONDeserializer(options: .init(typeRegistry: registry))
let binDeser = BinaryDeserializer(options: .init(typeRegistry: registry))
```

### Removed: Deprecated Options Constructors

Options structs without `typeRegistry` parameter are removed.

```swift
// v5 (removed)
let opts = DeserializationOptions()
let jsonOpts = JSONSerializationOptions(useOriginalFieldNames: true)
let jsonDeserOpts = JSONDeserializationOptions(ignoreUnknownFields: false)

// v6
let opts = DeserializationOptions(typeRegistry: registry)
let jsonOpts = JSONSerializationOptions(useOriginalFieldNames: true, typeRegistry: registry)
let jsonDeserOpts = JSONDeserializationOptions(ignoreUnknownFields: false, typeRegistry: registry)
```

### Removed: Deprecated Bridge Methods

```swift
// v5 (removed)
let msg = try bridge.fromProtobufDescriptor(proto, parent: fileDesc as FileDescriptor?)
let enm = try bridge.fromProtobufEnumDescriptor(proto, parent: fileDesc as Any?)

// v6
let msg = try bridge.fromProtobufDescriptor(proto, parent: fileDesc)
let enm = try bridge.fromProtobufEnumDescriptor(proto, parent: fileDesc)
```

### Removed: MessageFactory.validate(\_:syntax:)

Syntax is now read from `descriptor.syntax`.

```swift
// v5 (removed)
let result = factory.validate(message, syntax: "proto2")

// v6
let result = factory.validate(message)
```

### Breaking: TypeRegistry, DescriptorPool, WellKnownTypesRegistry Are Now Actors

All three types changed from `class` to `actor`. Every method call requires `await`.

```swift
// v5
let registry = TypeRegistry()
try registry.registerMessage(desc)
let found = registry.findMessage(named: "pkg.Msg")

// v6
let registry = TypeRegistry()
try await registry.registerMessage(desc)
let found = await registry.findMessage(named: "pkg.Msg")
```

```swift
// v5
let pool = DescriptorPool()
try pool.addFileDescriptor(file)
let msg = pool.findMessageDescriptor(named: "pkg.Msg")

// v6
let pool = DescriptorPool()
try await pool.addFileDescriptor(file)
let msg = await pool.findMessageDescriptor(named: "pkg.Msg")
```

```swift
// v5
let handler = WellKnownTypesRegistry.shared.getHandler(for: "google.protobuf.Timestamp")

// v6
let handler = await WellKnownTypesRegistry.shared.getHandler(for: "google.protobuf.Timestamp")
```

`WellKnownTypesRegistry.init()` is now `public` — you can create isolated instances instead of using `shared`.

### Breaking: Serializer Methods Become Async

Because serializers call `TypeRegistry` (now an actor), three methods become `async throws`:

```swift
// v5
let data = try jsonSerializer.serialize(message)
let msg = try jsonDeserializer.deserialize(jsonData, using: desc)
let msg = try binaryDeserializer.deserialize(binData, using: desc)

// v6
let data = try await jsonSerializer.serialize(message)
let msg = try await jsonDeserializer.deserialize(jsonData, using: desc)
let msg = try await binaryDeserializer.deserialize(binData, using: desc)
```

`BinarySerializer.serialize()` stays synchronous — it does not call `TypeRegistry`.

### MessageFactory: Sendable Without @unchecked

`MessageFactory` has no stored state. In v6 it conforms to `Sendable` directly (without `@unchecked`). No call-site changes required.

### Removed: JSONSerializationOptions No-Argument Initializer

The `JSONSerializationOptions()` no-argument initializer (which defaulted to an empty `TypeRegistry`) is removed. Pass an explicit `TypeRegistry`.

```swift
// v5 (removed)
let opts = JSONSerializationOptions()

// v6
let opts = JSONSerializationOptions(typeRegistry: TypeRegistry())
```

### Summary of All Removed APIs

| Removed API | Replacement |
|---|---|
| `MessageDescriptor.init(name:parent: Any?)` | `init(name:parent: (any DescriptorParent)?)` |
| `EnumDescriptor.init(name:parent: Any?)` | `init(name:parent: (any DescriptorParent)?)` |
| `BinaryDeserializer.init()` | `init(options:)` |
| `JSONSerializer.init()` | `init(options:)` |
| `JSONDeserializer.init()` | `init(options:)` |
| `DeserializationOptions.init(preserveUnknownFields:strictUTF8Validation:)` | `init(preserveUnknownFields:strictUTF8Validation:typeRegistry:)` |
| `JSONSerializationOptions.init(useOriginalFieldNames:prettyPrinted:includeDefaultValues:)` | `init(useOriginalFieldNames:prettyPrinted:includeDefaultValues:useCanonicalWellKnownTypeEncoding:typeRegistry:)` |
| `JSONDeserializationOptions.init(ignoreUnknownFields:strictTypeValidation:maxNestingDepth:)` | `init(ignoreUnknownFields:strictTypeValidation:typeRegistry:maxNestingDepth:)` |
| `DescriptorBridge.fromProtobufDescriptor(_:parent: FileDescriptor?)` | `fromProtobufDescriptor(_:parent: (any DescriptorParent)?)` |
| `DescriptorBridge.fromProtobufEnumDescriptor(_:parent: Any?)` | `fromProtobufEnumDescriptor(_:parent: (any DescriptorParent)?)` |
| `MessageFactory.validate(_:syntax:)` | `validate(_:)` |
