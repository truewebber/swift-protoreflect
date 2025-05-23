// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "SwiftProtoReflect",
  platforms: [
    .macOS(.v12),
    .iOS(.v15),
  ],
  products: [
    .library(
      name: "SwiftProtoReflect",
      targets: ["SwiftProtoReflect"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.29.0")
  ],
  targets: [
    .target(
      name: "SwiftProtoReflect",
      dependencies: [
        .product(name: "SwiftProtobuf", package: "swift-protobuf")
      ],
      exclude: [
        "Service/_README.md",
        "Errors/_README.md",
        "Dynamic/_README.md",
        "Bridge/_README.md",
        "Descriptor/_README.md",
        "Serialization/_README.md",
        "Registry/_README.md"
      ]
    ),
    .testTarget(
      name: "SwiftProtoReflectTests",
      dependencies: [
        "SwiftProtoReflect",
        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
      ],
      exclude: [
        "PROTOCOL_CONFORMANCE_TEST_PLAN.md",
        "Fixtures/README.md",
        "Mocks/README.md",
        "TestUtils/README.md",
        "TestResources/README.md",
      ]
    )
  ]
)
