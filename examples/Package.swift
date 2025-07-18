// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "SwiftProtoReflectExamples",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17),
    .watchOS(.v10),
  ],
  dependencies: [
    .package(path: "../")
  ],
  targets: [
    // Shared utilities for examples
    .target(
      name: "ExampleUtils",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect")
      ],
      path: "shared"
    ),

    // Individual examples as executables
    .executableTarget(
      name: "HelloWorld",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "01-basic-usage",
      exclude: ["field-types.swift", "simple-message.swift", "basic-descriptors.swift"],
      sources: ["hello-world.swift"]
    ),

    .executableTarget(
      name: "FieldTypes",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "01-basic-usage",
      exclude: ["hello-world.swift", "simple-message.swift", "basic-descriptors.swift"],
      sources: ["field-types.swift"]
    ),

    .executableTarget(
      name: "SimpleMessage",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "01-basic-usage",
      exclude: ["hello-world.swift", "field-types.swift", "basic-descriptors.swift"],
      sources: ["simple-message.swift"]
    ),

    .executableTarget(
      name: "BasicDescriptors",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "01-basic-usage",
      exclude: ["hello-world.swift", "field-types.swift", "simple-message.swift"],
      sources: ["basic-descriptors.swift"]
    ),

    // 02-dynamic-messages examples
    .executableTarget(
      name: "ComplexMessages",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "02-dynamic-messages",
      exclude: [
        "nested-operations.swift", "field-manipulation.swift", "message-cloning.swift", "conditional-logic.swift",
        "performance-optimization.swift", "nested-types.swift",
      ],
      sources: ["complex-messages.swift"]
    ),

    .executableTarget(
      name: "NestedOperations",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "02-dynamic-messages",
      exclude: [
        "complex-messages.swift", "field-manipulation.swift", "message-cloning.swift", "conditional-logic.swift",
        "performance-optimization.swift", "nested-types.swift",
      ],
      sources: ["nested-operations.swift"]
    ),

    .executableTarget(
      name: "NestedTypes",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "02-dynamic-messages",
      exclude: [
        "complex-messages.swift", "nested-operations.swift", "field-manipulation.swift", "message-cloning.swift",
        "conditional-logic.swift", "performance-optimization.swift",
      ],
      sources: ["nested-types.swift"]
    ),

    .executableTarget(
      name: "FieldManipulation",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "02-dynamic-messages",
      exclude: [
        "complex-messages.swift", "nested-operations.swift", "message-cloning.swift", "conditional-logic.swift",
        "performance-optimization.swift", "nested-types.swift",
      ],
      sources: ["field-manipulation.swift"]
    ),

    .executableTarget(
      name: "MessageCloning",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "02-dynamic-messages",
      exclude: [
        "complex-messages.swift", "nested-operations.swift", "field-manipulation.swift", "conditional-logic.swift",
        "performance-optimization.swift", "nested-types.swift",
      ],
      sources: ["message-cloning.swift"]
    ),

    .executableTarget(
      name: "ConditionalLogic",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "02-dynamic-messages",
      exclude: [
        "complex-messages.swift", "nested-operations.swift", "field-manipulation.swift", "message-cloning.swift",
        "performance-optimization.swift", "nested-types.swift",
      ],
      sources: ["conditional-logic.swift"]
    ),

    .executableTarget(
      name: "PerformanceOptimization",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "02-dynamic-messages",
      exclude: [
        "complex-messages.swift", "nested-operations.swift", "field-manipulation.swift", "message-cloning.swift",
        "conditional-logic.swift", "nested-types.swift",
      ],
      sources: ["performance-optimization.swift"]
    ),

    // 03-serialization examples
    .executableTarget(
      name: "ProtobufSerialization",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "03-serialization",
      exclude: ["json-conversion.swift", "binary-data.swift", "streaming.swift", "compression.swift"],
      sources: ["protobuf-serialization.swift"]
    ),

    .executableTarget(
      name: "JsonConversion",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "03-serialization",
      exclude: ["protobuf-serialization.swift", "binary-data.swift", "streaming.swift", "compression.swift"],
      sources: ["json-conversion.swift"]
    ),

    .executableTarget(
      name: "BinaryData",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "03-serialization",
      exclude: ["protobuf-serialization.swift", "json-conversion.swift", "streaming.swift", "compression.swift"],
      sources: ["binary-data.swift"]
    ),

    .executableTarget(
      name: "Streaming",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "03-serialization",
      exclude: ["protobuf-serialization.swift", "json-conversion.swift", "binary-data.swift", "compression.swift"],
      sources: ["streaming.swift"]
    ),

    .executableTarget(
      name: "Compression",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "03-serialization",
      exclude: ["protobuf-serialization.swift", "json-conversion.swift", "binary-data.swift", "streaming.swift"],
      sources: ["compression.swift"]
    ),

    // 04-registry examples
    .executableTarget(
      name: "TypeRegistry",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "04-registry",
      exclude: ["file-loading.swift", "dependency-resolution.swift", "schema-validation.swift"],
      sources: ["type-registry.swift"]
    ),

    .executableTarget(
      name: "FileLoading",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "04-registry",
      exclude: ["type-registry.swift", "dependency-resolution.swift", "schema-validation.swift"],
      sources: ["file-loading.swift"]
    ),

    .executableTarget(
      name: "DependencyResolution",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "04-registry",
      exclude: ["type-registry.swift", "file-loading.swift", "schema-validation.swift"],
      sources: ["dependency-resolution.swift"]
    ),

    .executableTarget(
      name: "SchemaValidation",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "04-registry",
      exclude: ["type-registry.swift", "file-loading.swift", "dependency-resolution.swift"],
      sources: ["schema-validation.swift"]
    ),

    // 05-well-known-types examples
    .executableTarget(
      name: "TimestampDemo",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "05-well-known-types",
      exclude: [
        "well-known-registry.swift", "duration-demo.swift", "empty-demo.swift", "field-mask-demo.swift",
        "struct-demo.swift", "value-demo.swift", "any-demo.swift",
      ],
      sources: ["timestamp-demo.swift"]
    ),

    .executableTarget(
      name: "DurationDemo",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "05-well-known-types",
      exclude: [
        "well-known-registry.swift", "timestamp-demo.swift", "empty-demo.swift", "field-mask-demo.swift",
        "struct-demo.swift", "value-demo.swift", "any-demo.swift",
      ],
      sources: ["duration-demo.swift"]
    ),

    .executableTarget(
      name: "EmptyDemo",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "05-well-known-types",
      exclude: [
        "well-known-registry.swift", "timestamp-demo.swift", "duration-demo.swift", "field-mask-demo.swift",
        "struct-demo.swift", "value-demo.swift", "any-demo.swift",
      ],
      sources: ["empty-demo.swift"]
    ),

    .executableTarget(
      name: "FieldMaskDemo",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "05-well-known-types",
      exclude: [
        "well-known-registry.swift", "timestamp-demo.swift", "duration-demo.swift", "empty-demo.swift",
        "struct-demo.swift", "value-demo.swift", "any-demo.swift",
      ],
      sources: ["field-mask-demo.swift"]
    ),

    .executableTarget(
      name: "StructDemo",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "05-well-known-types",
      exclude: [
        "well-known-registry.swift", "timestamp-demo.swift", "duration-demo.swift", "empty-demo.swift",
        "field-mask-demo.swift", "value-demo.swift", "any-demo.swift",
      ],
      sources: ["struct-demo.swift"]
    ),

    .executableTarget(
      name: "ValueDemo",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "05-well-known-types",
      exclude: [
        "well-known-registry.swift", "timestamp-demo.swift", "duration-demo.swift", "empty-demo.swift",
        "field-mask-demo.swift", "struct-demo.swift", "any-demo.swift",
      ],
      sources: ["value-demo.swift"]
    ),

    .executableTarget(
      name: "AnyDemo",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "05-well-known-types",
      exclude: [
        "well-known-registry.swift", "timestamp-demo.swift", "duration-demo.swift", "empty-demo.swift",
        "field-mask-demo.swift", "struct-demo.swift", "value-demo.swift", "well-known-registry.swift",
      ],
      sources: ["any-demo.swift"]
    ),

    .executableTarget(
      name: "WellKnownRegistry",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "05-well-known-types",
      exclude: [
        "timestamp-demo.swift", "duration-demo.swift", "empty-demo.swift", "field-mask-demo.swift", "struct-demo.swift",
        "value-demo.swift", "any-demo.swift",
      ],
      sources: ["well-known-registry.swift"]
    ),

    // 06-grpc examples
    .executableTarget(
      name: "DynamicClient",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "06-grpc",
      exclude: ["service-discovery.swift", "unary-calls.swift", "error-handling.swift", "metadata-options.swift"],
      sources: ["dynamic-client.swift"]
    ),

    .executableTarget(
      name: "ServiceDiscovery",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "06-grpc",
      exclude: ["dynamic-client.swift", "unary-calls.swift", "error-handling.swift", "metadata-options.swift"],
      sources: ["service-discovery.swift"]
    ),

    .executableTarget(
      name: "UnaryCalls",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "06-grpc",
      exclude: ["dynamic-client.swift", "service-discovery.swift", "error-handling.swift", "metadata-options.swift"],
      sources: ["unary-calls.swift"]
    ),

    .executableTarget(
      name: "ErrorHandling",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "06-grpc",
      exclude: ["dynamic-client.swift", "service-discovery.swift", "unary-calls.swift", "metadata-options.swift"],
      sources: ["error-handling.swift"]
    ),

    .executableTarget(
      name: "MetadataOptions",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "06-grpc",
      exclude: ["dynamic-client.swift", "service-discovery.swift", "unary-calls.swift", "error-handling.swift"],
      sources: ["metadata-options.swift"]
    ),

    // 07-advanced examples
    .executableTarget(
      name: "DescriptorBridge",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "07-advanced",
      exclude: [
        "static-message-bridge.swift", "batch-operations.swift", "memory-optimization.swift", "thread-safety.swift",
        "custom-extensions.swift",
      ],
      sources: ["descriptor-bridge.swift"]
    ),

    .executableTarget(
      name: "StaticMessageBridge",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "07-advanced",
      exclude: [
        "descriptor-bridge.swift", "batch-operations.swift", "memory-optimization.swift", "thread-safety.swift",
        "custom-extensions.swift",
      ],
      sources: ["static-message-bridge.swift"]
    ),

    .executableTarget(
      name: "BatchOperations",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "07-advanced",
      exclude: [
        "descriptor-bridge.swift", "static-message-bridge.swift", "memory-optimization.swift", "thread-safety.swift",
        "custom-extensions.swift",
      ],
      sources: ["batch-operations.swift"]
    ),

    .executableTarget(
      name: "MemoryOptimization",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "07-advanced",
      exclude: [
        "descriptor-bridge.swift", "static-message-bridge.swift", "batch-operations.swift", "thread-safety.swift",
        "custom-extensions.swift",
      ],
      sources: ["memory-optimization.swift"]
    ),

    .executableTarget(
      name: "ThreadSafety",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "07-advanced",
      exclude: [
        "descriptor-bridge.swift", "static-message-bridge.swift", "batch-operations.swift", "memory-optimization.swift",
        "custom-extensions.swift",
      ],
      sources: ["thread-safety.swift"]
    ),

    .executableTarget(
      name: "CustomExtensions",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "07-advanced",
      exclude: [
        "descriptor-bridge.swift", "static-message-bridge.swift", "batch-operations.swift", "memory-optimization.swift",
        "thread-safety.swift",
      ],
      sources: ["custom-extensions.swift"]
    ),

    // 08-real-world examples
    .executableTarget(
      name: "ConfigurationSystem",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "08-real-world",
      exclude: ["api-gateway.swift", "message-transform.swift", "validation-framework.swift", "proto-repl.swift"],
      sources: ["configuration-system.swift"]
    ),

    .executableTarget(
      name: "ApiGateway",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "08-real-world",
      exclude: [
        "configuration-system.swift", "message-transform.swift", "validation-framework.swift", "proto-repl.swift",
      ],
      sources: ["api-gateway.swift"]
    ),

    .executableTarget(
      name: "MessageTransform",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "08-real-world",
      exclude: ["configuration-system.swift", "api-gateway.swift", "validation-framework.swift", "proto-repl.swift"],
      sources: ["message-transform.swift"]
    ),

    .executableTarget(
      name: "ValidationFramework",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "08-real-world",
      exclude: ["configuration-system.swift", "api-gateway.swift", "message-transform.swift", "proto-repl.swift"],
      sources: ["validation-framework.swift"]
    ),

    .executableTarget(
      name: "ProtoREPL",
      dependencies: [
        .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
        "ExampleUtils",
      ],
      path: "08-real-world",
      exclude: [
        "configuration-system.swift", "api-gateway.swift", "message-transform.swift", "validation-framework.swift",
      ],
      sources: ["proto-repl.swift"]
    ),
  ]
)
