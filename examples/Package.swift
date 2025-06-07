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
            exclude: ["nested-operations.swift"],
            sources: ["complex-messages.swift"]
        ),
        
        .executableTarget(
            name: "NestedOperations", 
            dependencies: [
                .product(name: "SwiftProtoReflect", package: "swift-protoreflect"),
                "ExampleUtils"
            ],
            path: "02-dynamic-messages",
            exclude: ["complex-messages.swift"],
            sources: ["nested-operations.swift"]
        ),
    ]
)
