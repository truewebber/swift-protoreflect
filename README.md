# SwiftProtoReflect

**Dynamic Protocol Buffers for Swift** - Production-ready library for runtime Protocol Buffers message manipulation without pre-compiled .pb files.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg?style=flat)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2012.0%2B%20|%20iOS%2015.0%2B-lightgrey.svg?style=flat)](https://developer.apple.com)
[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftruewebber%2Fswift-protoreflect%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/truewebber/swift-protoreflect)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](LICENSE)
[![Coverage](https://img.shields.io/badge/Test%20Coverage-94%25-green.svg?style=flat)](#quality-metrics)

## 🚀 Quick Start

**Ready to run in 30 seconds:**

```bash
# Clone and explore 43 working examples
git clone https://github.com/truewebber/swift-protoreflect.git
cd swift-protoreflect/examples

# Your first dynamic Protocol Buffers message
swift run HelloWorld
swift run FieldTypes
swift run TimestampDemo
```

**Add to your project:**

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/truewebber/swift-protoreflect.git", from: "2.0.0")
]
```

## 🎯 Why SwiftProtoReflect?

Traditional Protocol Buffers require code generation. **SwiftProtoReflect** lets you work with protobuf messages dynamically at runtime:

```swift
// ❌ Traditional approach - requires .pb.swift generation
let person = Person()
person.name = "John Doe"
person.age = 30

// ✅ SwiftProtoReflect - pure runtime magic
let message = try MessageFactory().createMessage(from: personDescriptor)
try message.set("name", value: "John Doe")
try message.set("age", value: 30)

// Same binary output, zero code generation needed! 🎉
```

## 🌟 Key Features

- 🔥 **Zero Code Generation** - Work with any .proto schema at runtime
- ⚡ **High Performance** - Microsecond-level operations (faster than many static solutions)
- 🛡️ **Type Safe** - Complete compile-time and runtime type safety
- 🔄 **Full Compatibility** - 100% Protocol Buffers specification compliance
- 🌐 **All Field Types** - Scalars, messages, enums, maps, repeated fields, oneofs
- 📊 **Serialization** - Binary + JSON with round-trip fidelity
- 🤝 **Swift Protobuf Integration** - Seamless interoperability with existing code
- 🎯 **Well-Known Types** - Full support for Google's standard types
- 📡 **Dynamic gRPC** - Call any gRPC service without stub generation

## 📚 Learn by Example - 43 Ready-to-Run Examples

### 🎓 **Beginner - Start Here** (4 examples)
```bash
cd examples
swift run HelloWorld        # Your first dynamic message
swift run FieldTypes        # All Protocol Buffers field types
swift run SimpleMessage     # Basic message creation patterns  
swift run BasicDescriptors  # Understanding descriptors
```

### 🔧 **Dynamic Messages** (6 examples)
```bash
swift run NestedMessages    # Complex nested structures
swift run RepeatedFields    # Arrays and collections
swift run MapFields          # Key-value mappings
swift run MessageCreation   # Factory patterns
swift run FieldValidation   # Type safety and validation
swift run MessageCloning    # Deep copying strategies
```

### 💾 **Serialization** (5 examples)
```bash
swift run BinaryFormat      # High-performance binary encoding
swift run JSONFormat        # Human-readable JSON conversion
swift run RoundTrip         # Data integrity verification
swift run SerializationDemo # Complete serialization workflows
swift run FormatComparison  # Binary vs JSON performance
```

### 🗂️ **Type Management** (4 examples)
```bash
swift run TypeRegistration  # Central type management
swift run TypeLookup        # Efficient type discovery
swift run DependencyResolv  # Complex type relationships
swift run RegistryOps       # Advanced registry operations
```

### 🎨 **Well-Known Types** (8 examples)
```bash
swift run TimestampDemo     # google.protobuf.Timestamp
swift run DurationDemo      # google.protobuf.Duration  
swift run StructDemo        # google.protobuf.Struct (JSON-like)
swift run ValueDemo         # google.protobuf.Value
swift run AnyDemo           # google.protobuf.Any (type erasure)
swift run FieldMaskDemo     # google.protobuf.FieldMask
swift run EmptyDemo         # google.protobuf.Empty
swift run WellKnownOps      # Advanced operations
```

### 📡 **gRPC Integration** (5 examples)
```bash
swift run DynamicGRPC       # Call any gRPC service dynamically
swift run ServiceDiscovery  # Runtime service introspection
swift run MethodInvocation  # Dynamic method calls
swift run GRPCMetadata      # Headers and call options
swift run ServiceClient     # Production gRPC patterns
```

### 🚀 **Advanced Patterns** (6 examples)
```bash
swift run SchemaEvolution   # Handling schema changes
swift run MessageTransform  # Message conversion patterns
swift run ValidationFramework # Custom validation rules
swift run PerformanceOpts   # Optimization techniques
swift run MemoryManagement  # Efficient memory usage
swift run ConcurrentAccess  # Thread-safe operations
```

### 🏭 **Real-World Scenarios** (5 examples)
```bash
swift run ApiGateway        # API Gateway with dynamic routing
swift run ConfigManager     # Dynamic configuration system
swift run DataPipeline      # ETL processing pipeline
swift run LoggingFramework  # Structured logging system
swift run MessageQueue      # Event-driven architecture
```

## 🚀 Quick Examples

### Creating Dynamic Messages

```swift
import SwiftProtoReflect

// Create a schema at runtime
let personSchema = try MessageDescriptor.builder("Person")
    .addField("name", number: 1, type: .string)
    .addField("age", number: 2, type: .int32)
    .addField("emails", number: 3, type: .string, label: .repeated)
    .build()

// Create and populate a message
let message = try MessageFactory().createMessage(from: personSchema)
try message.set("name", value: "Alice")
try message.set("age", value: 25)
try message.set("emails", value: ["alice@example.com", "alice.dev@example.com"])

// Serialize to binary or JSON
let binaryData = try BinarySerializer().serialize(message: message)
let jsonString = try JSONSerializer().serialize(message: message)

print(jsonString)
// Output: {"name":"Alice","age":25,"emails":["alice@example.com","alice.dev@example.com"]}
```

### Working with Well-Known Types

```swift
// Easy timestamps
let now = Date()
let timestampMessage = try now.toTimestampMessage()
let backToDate = try timestampMessage.toDate()

// JSON-like structures with google.protobuf.Struct
let data: [String: Any] = [
    "user": "john",
    "settings": ["theme": "dark", "notifications": true],
    "scores": [95, 87, 92]
]
let structMessage = try data.toStructMessage()
let backToDict = try structMessage.toDictionary()

// Type erasure with google.protobuf.Any
let anyMessage = try message.packIntoAny()
let unpackedMessage = try anyMessage.unpackFromAny(to: personSchema)
```

### Dynamic gRPC Calls

```swift
// Call any gRPC service without code generation
let client = ServiceClient(channel: grpcChannel)

let request = try MessageFactory().createMessage(from: requestSchema)
try request.set("query", value: "SwiftProtoReflect")

let response = try await client.unaryCall(
    service: "search.SearchService",
    method: "Search", 
    request: request
)

let results: [String] = try response.get("results")
print("Found \(results.count) results")
```

## 🏗️ Architecture

SwiftProtoReflect is built on a robust, layered architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    📱 User-Friendly API                     │
│              (43 examples + comprehensive docs)             │
├─────────────────────────────────────────────────────────────┤
│  🏗️ Dynamic Messages  │  📊 Serialization  │ 🌐 Well-Known │
│      & Validation      │   Binary + JSON   │     Types     │
├─────────────────────────────────────────────────────────────┤
│   📝 Descriptor System  │  🗂️ Type Registry  │  📡 gRPC     │
│    Schema Management   │   & Lookup        │  Integration  │
├─────────────────────────────────────────────────────────────┤
│                 🔗 Swift Protobuf Integration               │
│                   (Wire format compatibility)              │
└─────────────────────────────────────────────────────────────┘
```

**All components are production-ready** with 94%+ test coverage and comprehensive benchmarking.

## 📊 Performance Metrics

SwiftProtoReflect delivers excellent performance across all operations:

| Operation | Small Messages | Medium Messages | Large Messages |
|-----------|---------------|-----------------|----------------|
| **Binary Serialization** | 9-118μs | 16-271μs | 697-1302μs |
| **JSON Serialization** | 15-329μs | 17-248μs | 357-673μs |
| **Type Lookup** | 127-639μs | - | - |
| **Static↔Dynamic Conversion** | 79-352μs | - | - |

**Key Achievements:**
- JSON is only 1.3x slower than binary (excellent efficiency)
- Direct lookup is 10.6x faster than iterative (optimized caching)
- Microsecond-level operations for most use cases

## 🛡️ Quality Metrics

**Production-ready reliability:**

- ✅ **866 tests** with 100% success rate
- ✅ **94.17% code coverage** across all modules  
- ✅ **43 performance benchmarks** preventing regressions
- ✅ **Thread-safe** concurrent operations
- ✅ **Memory efficient** with intelligent caching
- ✅ **100% Protocol Buffers compatibility**

## 🔧 Requirements

- **Swift**: 5.9+
- **Platforms**: macOS 12.0+, iOS 15.0+
- **Dependencies**: SwiftProtobuf 1.29.0+, GRPC-Swift 1.23.0+

## 📖 Documentation

### 📚 **Learning Resources**
- **[Architecture Guide](ARCHITECTURE.md)** - Complete technical overview
- **[Developer Guide](DEVELOPER_GUIDE.md)** - Contributing and development
- **[API Reference](Sources/)** - Comprehensive API documentation
- **[Performance Guide](test_coverage_analysis_report.md)** - Optimization tips

### 🎯 **Quick Navigation**
- **Beginners**: Start with `examples/01-basic-usage/`
- **Migration**: Coming from static protobuf? See migration examples
- **Advanced**: Explore `examples/07-advanced/` and `examples/08-real-world/`
- **gRPC**: Dynamic service calls in `examples/06-grpc/`

## 🤝 Integration with Existing Code

SwiftProtoReflect seamlessly integrates with existing Swift Protobuf code:

```swift
// Convert static messages to dynamic
let staticPerson = Person.with {
    $0.name = "John"
    $0.age = 30
}
let dynamicPerson = try staticPerson.toDynamicMessage()

// Convert dynamic messages to static  
let backToStatic: Person = try dynamicPerson.toStaticMessage()

// Mixed workflows
let processedMessage = try processMessage(dynamicPerson)
let finalStatic: Person = try processedMessage.toStaticMessage()
```

## 🎯 Use Cases

**Perfect for:**

- 🔧 **Generic Tools** - Protocol buffer viewers, debuggers, transformers
- 🌐 **API Gateways** - Route messages without knowing schemas in advance
- 📊 **Data Processing** - ETL pipelines with dynamic schema handling
- 🔍 **Testing Tools** - Generate test data for any protobuf schema
- 🚀 **Rapid Prototyping** - Work with protobuf schemas without code generation
- 📱 **Configuration Systems** - Dynamic configuration with protobuf schemas
- 🔌 **Plugin Systems** - Load and process protobuf data at runtime

## 🚀 Getting Started

1. **Try the examples**:
   ```bash
   git clone https://github.com/truewebber/swift-protoreflect.git
   cd swift-protoreflect/examples
   swift run HelloWorld
   ```

2. **Add to your project**:
   ```swift
   dependencies: [
       .package(url: "https://github.com/truewebber/swift-protoreflect.git", from: "2.0.0")
   ]
   ```

3. **Start coding**:
   ```swift
   import SwiftProtoReflect
   
   // Your first dynamic message
   let message = try MessageFactory().createMessage(from: schema)
   try message.set("field", value: "Hello, SwiftProtoReflect!")
   ```

## 🤝 Contributing

We welcome contributions! To contribute to SwiftProtoReflect:

- **Open Issues**: Report bugs or suggest features via GitHub Issues
- **Submit Pull Requests**: Follow Swift coding conventions and include tests
- **Add Examples**: Help expand our example collection with real-world use cases
- **Documentation**: Improve API documentation and usage guides

**Requirements for contributions:**
- Maintain or improve test coverage (target: 94%+)
- Follow existing code style and architecture patterns
- Include performance considerations for new features
- Provide clear documentation for new APIs

## 📄 License

SwiftProtoReflect is released under the MIT License. See [LICENSE](LICENSE) for details.

---

**Ready to get started?** 🚀 

```bash
cd examples && swift run HelloWorld
```

**Questions?** Check out our [43 comprehensive examples](examples/) or [detailed documentation](Sources/).

**Found this useful?** ⭐ Star the repo and share with your team!