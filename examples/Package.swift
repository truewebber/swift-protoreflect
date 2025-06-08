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
        .package(path: "../"),
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
                "ExampleUtils"
            ],
            path: "01-basic-usage",
            exclude: ["field-types.swift", "simple-message.swift", "basic-descriptors.swift", "README.md"],
            sources: ["hello-world.swift"]
        ),
        
        .executableTarget(
            name: "FieldTypes", 
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "01-basic-usage",
            exclude: ["hello-world.swift", "simple-message.swift", "basic-descriptors.swift", "README.md"],
            sources: ["field-types.swift"]
        ),
        
        .executableTarget(
            name: "SimpleMessage", 
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "01-basic-usage",
            exclude: ["hello-world.swift", "field-types.swift", "basic-descriptors.swift", "README.md"],
            sources: ["simple-message.swift"]
        ),
        
        .executableTarget(
            name: "BasicDescriptors", 
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "01-basic-usage",
            exclude: ["hello-world.swift", "field-types.swift", "simple-message.swift", "README.md"],
            sources: ["basic-descriptors.swift"]
        ),
        
        // 02-dynamic-messages examples
        .executableTarget(
            name: "ComplexMessages", 
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "02-dynamic-messages",
            exclude: ["nested-operations.swift", "field-manipulation.swift", "message-cloning.swift", "conditional-logic.swift", "performance-optimization.swift", "nested-types.swift"],
            sources: ["complex-messages.swift"]
        ),
        
        .executableTarget(
            name: "NestedOperations", 
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "02-dynamic-messages",
            exclude: ["complex-messages.swift", "field-manipulation.swift", "message-cloning.swift", "conditional-logic.swift", "performance-optimization.swift", "nested-types.swift"],
            sources: ["nested-operations.swift"]
        ),
        
        .executableTarget(
            name: "NestedTypes", 
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "02-dynamic-messages",
            exclude: ["complex-messages.swift", "nested-operations.swift", "field-manipulation.swift", "message-cloning.swift", "conditional-logic.swift", "performance-optimization.swift"],
            sources: ["nested-types.swift"]
        ),
        
        .executableTarget(
            name: "FieldManipulation", 
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "02-dynamic-messages",
            exclude: ["complex-messages.swift", "nested-operations.swift", "message-cloning.swift", "conditional-logic.swift", "performance-optimization.swift", "nested-types.swift"],
            sources: ["field-manipulation.swift"]
        ),
        
        .executableTarget(
            name: "MessageCloning", 
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "02-dynamic-messages",
            exclude: ["complex-messages.swift", "nested-operations.swift", "field-manipulation.swift", "conditional-logic.swift", "performance-optimization.swift", "nested-types.swift"],
            sources: ["message-cloning.swift"]
        ),
        
        .executableTarget(
            name: "ConditionalLogic",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "02-dynamic-messages",
            exclude: ["complex-messages.swift", "nested-operations.swift", "field-manipulation.swift", "message-cloning.swift", "performance-optimization.swift", "nested-types.swift"],
            sources: ["conditional-logic.swift"]
        ),
        
        .executableTarget(
            name: "PerformanceOptimization",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "02-dynamic-messages",
            exclude: ["complex-messages.swift", "nested-operations.swift", "field-manipulation.swift", "message-cloning.swift", "conditional-logic.swift", "nested-types.swift"],
            sources: ["performance-optimization.swift"]
        ),
        
        // 03-serialization examples
        .executableTarget(
            name: "ProtobufSerialization",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "03-serialization",
            exclude: ["json-conversion.swift", "binary-data.swift", "streaming.swift", "compression.swift"],
            sources: ["protobuf-serialization.swift"]
        ),
        
        .executableTarget(
            name: "JsonConversion",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "03-serialization",
            exclude: ["protobuf-serialization.swift", "binary-data.swift", "streaming.swift", "compression.swift"],
            sources: ["json-conversion.swift"]
        ),
        
        .executableTarget(
            name: "BinaryData",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "03-serialization",
            exclude: ["protobuf-serialization.swift", "json-conversion.swift", "streaming.swift", "compression.swift"],
            sources: ["binary-data.swift"]
        ),
        
        .executableTarget(
            name: "Streaming",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "03-serialization",
            exclude: ["protobuf-serialization.swift", "json-conversion.swift", "binary-data.swift", "compression.swift"],
            sources: ["streaming.swift"]
        ),
        
        .executableTarget(
            name: "Compression",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
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
                "ExampleUtils"
            ],
            path: "04-registry",
            exclude: ["file-loading.swift", "dependency-resolution.swift", "schema-validation.swift"],
            sources: ["type-registry.swift"]
        ),
        
        .executableTarget(
            name: "FileLoading",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "04-registry",
            exclude: ["type-registry.swift", "dependency-resolution.swift", "schema-validation.swift"],
            sources: ["file-loading.swift"]
        ),
        
        .executableTarget(
            name: "DependencyResolution",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "04-registry",
            exclude: ["type-registry.swift", "file-loading.swift", "schema-validation.swift"],
            sources: ["dependency-resolution.swift"]
        ),
        
        .executableTarget(
            name: "SchemaValidation",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
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
                "ExampleUtils"
            ],
            path: "05-well-known-types",
            exclude: ["well-known-registry.swift", "duration-demo.swift", "empty-demo.swift", "field-mask-demo.swift", "struct-demo.swift", "value-demo.swift", "any-demo.swift"],
            sources: ["timestamp-demo.swift"]
        ),
        
        .executableTarget(
            name: "DurationDemo",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "05-well-known-types",
            exclude: ["well-known-registry.swift", "timestamp-demo.swift", "empty-demo.swift", "field-mask-demo.swift", "struct-demo.swift", "value-demo.swift", "any-demo.swift"],
            sources: ["duration-demo.swift"]
        ),
        
        .executableTarget(
            name: "EmptyDemo",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "05-well-known-types",
            exclude: ["well-known-registry.swift", "timestamp-demo.swift", "duration-demo.swift", "field-mask-demo.swift", "struct-demo.swift", "value-demo.swift", "any-demo.swift"],
            sources: ["empty-demo.swift"]
        ),
        
        .executableTarget(
            name: "FieldMaskDemo",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "05-well-known-types",
            exclude: ["well-known-registry.swift", "timestamp-demo.swift", "duration-demo.swift", "empty-demo.swift", "struct-demo.swift", "value-demo.swift", "any-demo.swift"],
            sources: ["field-mask-demo.swift"]
        ),
        
        .executableTarget(
            name: "StructDemo",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "05-well-known-types",
            exclude: ["well-known-registry.swift", "timestamp-demo.swift", "duration-demo.swift", "empty-demo.swift", "field-mask-demo.swift", "value-demo.swift", "any-demo.swift"],
            sources: ["struct-demo.swift"]
        ),
        
        .executableTarget(
            name: "ValueDemo",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "05-well-known-types",
            exclude: ["well-known-registry.swift", "timestamp-demo.swift", "duration-demo.swift", "empty-demo.swift", "field-mask-demo.swift", "struct-demo.swift", "any-demo.swift"],
            sources: ["value-demo.swift"]
        ),
        
        .executableTarget(
            name: "AnyDemo",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "05-well-known-types",
            exclude: ["well-known-registry.swift", "timestamp-demo.swift", "duration-demo.swift", "empty-demo.swift", "field-mask-demo.swift", "struct-demo.swift", "value-demo.swift", "well-known-registry.swift"],
            sources: ["any-demo.swift"]
        ),
        
        .executableTarget(
            name: "WellKnownRegistry",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "05-well-known-types",
            exclude: ["timestamp-demo.swift", "duration-demo.swift", "empty-demo.swift", "field-mask-demo.swift", "struct-demo.swift", "value-demo.swift", "any-demo.swift"],
            sources: ["well-known-registry.swift"]
        ),
        
        // 06-grpc examples
        .executableTarget(
            name: "DynamicClient",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "06-grpc",
            exclude: ["service-discovery.swift", "unary-calls.swift", "error-handling.swift", "metadata-options.swift"],
            sources: ["dynamic-client.swift"]
        ),
        
        .executableTarget(
            name: "ServiceDiscovery",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "06-grpc",
            exclude: ["dynamic-client.swift", "unary-calls.swift", "error-handling.swift", "metadata-options.swift"],
            sources: ["service-discovery.swift"]
        ),
        
        .executableTarget(
            name: "UnaryCalls",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "06-grpc",
            exclude: ["dynamic-client.swift", "service-discovery.swift", "error-handling.swift", "metadata-options.swift"],
            sources: ["unary-calls.swift"]
        ),
        
        .executableTarget(
            name: "ErrorHandling",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "06-grpc",
            exclude: ["dynamic-client.swift", "service-discovery.swift", "unary-calls.swift", "metadata-options.swift"],
            sources: ["error-handling.swift"]
        ),
        
        .executableTarget(
            name: "MetadataOptions",
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "06-grpc",
            exclude: ["dynamic-client.swift", "service-discovery.swift", "unary-calls.swift", "error-handling.swift"],
            sources: ["metadata-options.swift"]
        ),
    ]
)
