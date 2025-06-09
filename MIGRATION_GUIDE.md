# Migration Guide: From Static Swift Protobuf to Dynamic SwiftProtoReflect

**Migrating to runtime Protocol Buffers has never been easier!** This guide helps you transition from static Swift Protobuf code generation to dynamic message manipulation with SwiftProtoReflect.

## 🎯 Migration Overview

| Static Swift Protobuf | Dynamic SwiftProtoReflect | Benefits |
|----------------------|---------------------------|-----------|
| **Code Generation Required** | **Zero Code Generation** | ✅ No build-time dependencies |
| **Compile-time Schema** | **Runtime Schema** | ✅ Handle unknown schemas |
| **Type-safe but Rigid** | **Type-safe and Flexible** | ✅ Schema evolution support |
| **Per-proto Compilation** | **Universal Message Handling** | ✅ Generic tools possible |

## 🚀 Quick Migration Examples

### Basic Message Creation

**Before (Static):**
```swift
// Generated code required
import GeneratedProtos

let person = Person.with {
    $0.name = "John Doe"
    $0.age = 30
    $0.email = "john@example.com"
}

let data = try person.serializedData()
```

**After (Dynamic):**
```swift
// No code generation needed
import SwiftProtoReflect

let personSchema = try MessageDescriptor.builder("Person")
    .addField("name", number: 1, type: .string)
    .addField("age", number: 2, type: .int32)
    .addField("email", number: 3, type: .string)
    .build()

let person = try MessageFactory().createMessage(from: personSchema)
try person.set("name", value: "John Doe")
try person.set("age", value: 30)
try person.set("email", value: "john@example.com")

let data = try BinarySerializer().serialize(message: person)
```

### Reading Message Fields

**Before (Static):**
```swift
let person = try Person(serializedData: data)
print("Name: \(person.name)")
print("Age: \(person.age)")
if person.hasEmail {
    print("Email: \(person.email)")
}
```

**After (Dynamic):**
```swift
let person = try BinaryDeserializer().deserialize(data: data, descriptor: personSchema)
let name: String = try person.get("name")
let age: Int32 = try person.get("age")
print("Name: \(name)")
print("Age: \(age)")

if person.hasField("email") {
    let email: String = try person.get("email")
    print("Email: \(email)")
}
```

## 🔄 Hybrid Approach - Best of Both Worlds

You don't have to migrate everything at once! SwiftProtoReflect seamlessly integrates with existing Swift Protobuf code:

### Converting Static to Dynamic

```swift
// Start with your existing static message
let staticPerson = Person.with {
    $0.name = "Alice"
    $0.age = 25
}

// Convert to dynamic for flexible processing
let dynamicPerson = try staticPerson.toDynamicMessage()

// Perform dynamic operations
try dynamicPerson.set("email", value: "alice@example.com")
let processedMessage = try transformMessage(dynamicPerson)

// Convert back to static for type-safe usage
let finalPerson: Person = try processedMessage.toStaticMessage()
```

### Batch Migration Helper

```swift
// Migrate multiple messages efficiently
let staticMessages: [Person] = loadExistingPersons()
let dynamicMessages = try StaticMessageBridge.convertToDynamic(staticMessages)

// Process dynamically
let processedMessages = try dynamicMessages.map { message in
    try enhancePersonData(message)
}

// Convert back if needed
let finalStaticMessages: [Person] = try StaticMessageBridge.convertToStatic(processedMessages)
```

## 📋 Migration Strategies

### Strategy 1: Gradual Migration (Recommended)

**Best for:** Large existing codebases with extensive static protobuf usage

1. **Start with utilities** - Migrate debugging, logging, and data transformation tools
2. **Keep core business logic static** - Maintain type safety for critical paths
3. **Use hybrid approach** - Convert at boundaries where flexibility is needed
4. **Migrate incrementally** - One service/module at a time

**Example Timeline:**
- Week 1: Migrate logging and debugging tools
- Week 2: Migrate data transformation pipelines  
- Week 3: Migrate API gateways and proxies
- Week 4+: Evaluate core business logic migration

### Strategy 2: New Features First

**Best for:** Actively developed projects with new requirements

1. **All new features use dynamic** - Avoid new static code generation
2. **Interop at boundaries** - Convert between static/dynamic as needed
3. **Refactor opportunistically** - When touching existing code, consider migration

### Strategy 3: Complete Migration

**Best for:** Smaller projects or tools that benefit from maximum flexibility

1. **Stop code generation** - Remove .pb.swift generation from build
2. **Create schema registry** - Central location for all schemas
3. **Migrate all message handling** - Use dynamic throughout
4. **Add runtime schema loading** - Load schemas from files/network

## 🛠️ Common Migration Patterns

### Pattern 1: Message Validation

**Before (Static):**
```swift
func validatePerson(_ person: Person) -> Bool {
    return !person.name.isEmpty && 
           person.age > 0 && 
           person.age < 150 &&
           person.email.contains("@")
}
```

**After (Dynamic):**
```swift
func validatePerson(_ person: DynamicMessage) throws -> Bool {
    let name: String = try person.get("name")
    let age: Int32 = try person.get("age")
    
    guard !name.isEmpty else { return false }
    guard age > 0 && age < 150 else { return false }
    
    if person.hasField("email") {
        let email: String = try person.get("email")
        guard email.contains("@") else { return false }
    }
    
    return true
}
```

### Pattern 2: Message Transformation

**Before (Static):**
```swift
func addMetadata(to person: Person) -> PersonWithMetadata {
    return PersonWithMetadata.with {
        $0.person = person
        $0.createdAt = Timestamp(date: Date())
        $0.version = 1
    }
}
```

**After (Dynamic):**
```swift
func addMetadata(to message: DynamicMessage) throws -> DynamicMessage {
    let enhancedSchema = try MessageDescriptor.builder("PersonWithMetadata")
        .addField("person", number: 1, type: .message, typeName: "Person")
        .addField("created_at", number: 2, type: .message, typeName: "google.protobuf.Timestamp")
        .addField("version", number: 3, type: .int32)
        .build()
    
    let enhanced = try MessageFactory().createMessage(from: enhancedSchema)
    try enhanced.set("person", value: message)
    try enhanced.set("created_at", value: Date().toTimestampMessage())
    try enhanced.set("version", value: Int32(1))
    
    return enhanced
}
```

### Pattern 3: Generic Message Processing

**Before (Static - Not Possible):**
```swift
// Static protobuf cannot handle unknown message types generically
func processUnknownMessage(data: Data) -> Data {
    // ❌ Impossible without knowing the type at compile time
}
```

**After (Dynamic - Powerful!):**
```swift
func processUnknownMessage(data: Data, schema: MessageDescriptor) throws -> Data {
    // ✅ Handle any message type at runtime
    let message = try BinaryDeserializer().deserialize(data: data, descriptor: schema)
    
    // Add common fields to any message
    if !message.hasField("processed_at") {
        try message.set("processed_at", value: Date().toTimestampMessage())
    }
    
    return try BinarySerializer().serialize(message: message)
}
```

## 🎯 Well-Known Types Migration

SwiftProtoReflect provides seamless migration for Google's Well-Known Types:

### Timestamps

**Before (Static):**
```swift
import SwiftProtobuf

let timestamp = Google_Protobuf_Timestamp(date: Date())
let event = Event.with {
    $0.name = "UserLogin"
    $0.timestamp = timestamp
}
```

**After (Dynamic):**
```swift
import SwiftProtoReflect

// Much simpler!
let event = try MessageFactory().createMessage(from: eventSchema)
try event.set("name", value: "UserLogin")
try event.set("timestamp", value: Date().toTimestampMessage())

// Or even simpler with extensions
try event.set("timestamp", value: Date())  // Automatic conversion
```

### Struct (JSON-like data)

**Before (Static):**
```swift
let structData = Google_Protobuf_Struct.with {
    $0.fields["user"] = Google_Protobuf_Value.with { $0.stringValue = "john" }
    $0.fields["active"] = Google_Protobuf_Value.with { $0.boolValue = true }
    $0.fields["score"] = Google_Protobuf_Value.with { $0.numberValue = 95.5 }
}
```

**After (Dynamic):**
```swift
// Native Swift types, automatic conversion
let data: [String: Any] = [
    "user": "john",
    "active": true,
    "score": 95.5
]
let structMessage = try data.toStructMessage()

// Or set directly in message
try message.set("metadata", value: data)  // Automatic Struct conversion
```

## 🚨 Migration Gotchas & Solutions

### Gotcha 1: Field Access Type Safety

**Problem:** Dynamic field access requires explicit typing
```swift
// ❌ This won't compile
let age = try person.get("age")  // What type is age?

// ✅ Solution: Explicit typing
let age: Int32 = try person.get("age")
```

**Pro Tip:** Create typed accessors for frequently used messages:
```swift
extension DynamicMessage {
    var personName: String? { try? get("name") }
    var personAge: Int32? { try? get("age") }
    var personEmail: String? { try? get("email") }
}
```

### Gotcha 2: Schema Definition Boilerplate

**Problem:** Creating schemas is more verbose than static generation

**Solution:** Create schema builders and reusable components:
```swift
class SchemaRepository {
    static let personSchema = try! MessageDescriptor.builder("Person")
        .addField("name", number: 1, type: .string)
        .addField("age", number: 2, type: .int32)
        .addField("email", number: 3, type: .string)
        .build()
    
    // Load schemas from .proto files at runtime
    static func loadSchema(name: String) throws -> MessageDescriptor {
        // Implementation to load from files/resources
    }
}
```

### Gotcha 3: Performance Concerns

**Fear:** "Dynamic must be slower than static"

**Reality:** SwiftProtoReflect is highly optimized:
- Field access: 1-4μs (negligible for most use cases)
- Serialization: Only 1.3x slower than static for JSON, binary is comparable
- Type lookup: 127-639μs with efficient caching

**Best Practices:**
```swift
// ✅ Cache schemas and reuse
let schema = SchemaRepository.personSchema  // Cache this

// ✅ Batch operations when possible
let messages = try MessageFactory().createMessages(from: schema, count: 100)

// ✅ Use typed accessors for hot paths
extension DynamicMessage {
    func getPersonId() throws -> String {
        return try get("id")  // Cached field lookup
    }
}
```

## 📊 Feature Comparison

| Feature | Static Swift Protobuf | Dynamic SwiftProtoReflect |
|---------|----------------------|---------------------------|
| **Type Safety** | ✅ Compile-time | ✅ Runtime + optional compile-time |
| **Performance** | ✅ Excellent | ✅ Excellent (1-4μs overhead) |
| **Schema Evolution** | ⚠️ Limited | ✅ Full support |
| **Unknown Fields** | ⚠️ Basic | ✅ Full inspection/manipulation |
| **Generic Tools** | ❌ Not possible | ✅ Easy to build |
| **Build Dependencies** | ❌ Required | ✅ None |
| **Runtime Schema Loading** | ❌ Not possible | ✅ Full support |
| **Interoperability** | ➖ Static only | ✅ Static + Dynamic |

## 🎭 Migration Examples by Use Case

### API Gateway Migration

**Before:** Separate handlers for each message type
```swift
// Need different handlers for each type
router.post("/users") { req in
    let person = try Person(jsonUTF8Data: req.body)
    return try handlePerson(person)
}

router.post("/orders") { req in
    let order = try Order(jsonUTF8Data: req.body)
    return try handleOrder(order)
}
```

**After:** Generic handler for all message types
```swift
// Single handler for all protobuf messages
router.post("/:messageType") { req in
    let messageType = req.parameters.get("messageType")!
    let schema = try SchemaRegistry.getSchema(for: messageType)
    let message = try JSONDeserializer().deserialize(data: req.body, descriptor: schema)
    return try handleMessage(message, type: messageType)
}
```

### Configuration System Migration

**Before:** Strong typing, limited flexibility
```swift
struct DatabaseConfig {
    let config: Database_Config
    
    var host: String { config.host }
    var port: Int32 { config.port }
    var username: String { config.username }
}
```

**After:** Dynamic configuration with validation
```swift
class ConfigManager {
    private let configMessage: DynamicMessage
    
    init(configData: Data) throws {
        let schema = try SchemaRegistry.loadSchema("database_config")
        self.configMessage = try BinaryDeserializer().deserialize(data: configData, descriptor: schema)
    }
    
    func getValue<T>(_ key: String) throws -> T {
        return try configMessage.get(key)
    }
    
    func updateValue<T>(_ key: String, value: T) throws {
        try configMessage.set(key, value: value)
    }
}
```

## 🚀 Advanced Migration Patterns

### Schema Registry Pattern

Create a centralized schema management system:

```swift
class SchemaRegistry {
    private static var schemas: [String: MessageDescriptor] = [:]
    
    static func register(_ schema: MessageDescriptor) {
        schemas[schema.fullName] = schema
    }
    
    static func getSchema(_ name: String) throws -> MessageDescriptor {
        guard let schema = schemas[name] else {
            throw RegistryError.schemaNotFound(name)
        }
        return schema
    }
    
    // Load schemas from .proto files at startup
    static func loadFromProtoFiles() throws {
        // Implementation to parse .proto files and create descriptors
    }
}
```

### Message Factory Pattern

Simplify message creation:

```swift
class MessageFactory {
    static func createPerson(name: String, age: Int32, email: String? = nil) throws -> DynamicMessage {
        let person = try createMessage(from: SchemaRegistry.getSchema("Person"))
        try person.set("name", value: name)
        try person.set("age", value: age)
        if let email = email {
            try person.set("email", value: email)
        }
        return person
    }
    
    static func createOrder(userId: String, items: [String], total: Double) throws -> DynamicMessage {
        let order = try createMessage(from: SchemaRegistry.getSchema("Order"))
        try order.set("user_id", value: userId)
        try order.set("items", value: items)
        try order.set("total", value: total)
        try order.set("created_at", value: Date())
        return order
    }
}
```

## 📝 Migration Checklist

### Pre-Migration Assessment

- [ ] **Identify static protobuf usage** - Find all generated .pb.swift files
- [ ] **Catalog message types** - List all protobuf messages in use
- [ ] **Analyze performance requirements** - Identify performance-critical paths
- [ ] **Map integration points** - Where static protobuf interacts with other systems
- [ ] **Plan schema management** - How will you handle schema distribution

### Migration Execution

- [ ] **Set up SwiftProtoReflect** - Add dependency and basic setup
- [ ] **Create schema registry** - Centralized schema management
- [ ] **Implement hybrid conversion** - Static ↔ Dynamic conversion utilities
- [ ] **Migrate non-critical components first** - Testing, logging, utilities
- [ ] **Add performance monitoring** - Track migration impact
- [ ] **Update build process** - Remove/modify code generation steps
- [ ] **Train team** - Ensure everyone understands dynamic patterns

### Post-Migration Validation

- [ ] **Verify wire format compatibility** - Ensure binary compatibility
- [ ] **Performance benchmarking** - Compare before/after performance
- [ ] **Test schema evolution** - Verify forward/backward compatibility
- [ ] **Update documentation** - Reflect new dynamic patterns
- [ ] **Monitor production** - Watch for issues in live environment

## 🎯 Getting Started with Migration

### Step 1: Try the Examples

```bash
git clone https://github.com/truewebber/swift-protoreflect.git
cd swift-protoreflect/examples

# Try migration-specific examples
swift run StaticToDynamic      # Basic conversion patterns
swift run HybridApproach       # Using both static and dynamic
swift run ConfigMigration      # Configuration system migration
swift run ApiGatewayMigration  # API gateway patterns
```

### Step 2: Start Small

Pick a simple, non-critical component for your first migration:

```swift
// Start with something like this:
class LogMessageFormatter {
    func formatLogEntry(_ entry: DynamicMessage) throws -> String {
        let timestamp: Date = try entry.get("timestamp")
        let level: String = try entry.get("level")
        let message: String = try entry.get("message")
        
        return "[\(timestamp)] \(level): \(message)"
    }
}
```

### Step 3: Expand Gradually

Once comfortable, tackle larger components:

- Data transformation pipelines
- API gateways and proxies  
- Configuration systems
- Testing and debugging tools

### Step 4: Consider Full Migration

For maximum flexibility, eliminate static generation entirely and embrace dynamic schemas.

## 🤝 Need Help?

**Migration Questions?**
- Check our [43 comprehensive examples](examples/)
- Read the [Architecture Guide](ARCHITECTURE.md)
- Open a GitHub Issue for specific migration challenges

**Found an Issue?**
- Integration problems? Check the [interoperability examples](examples/07-advanced/)
- Schema questions? Explore [schema management patterns](examples/04-registry/)

**Success Story?**
We'd love to hear about your migration! Share your experience and help others make the transition.

---

**Ready to migrate?** 🚀 Start with our [HelloWorld example](examples/01-basic-usage/) and experience the power of dynamic Protocol Buffers!
