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
        "Dynamic/_README.md",
        "Bridge/_README.md",
        "Descriptor/_README.md",
        "Serialization/_README.md",
        "Registry/_README.md",
        "Integration/_README.md",
      ]
    ),
    .testTarget(
      name: "SwiftProtoReflectTests",
      dependencies: [
        "SwiftProtoReflect",
        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
      ],
      exclude: [
        "Fixtures/README.md",
        "Mocks/README.md",
        "TestUtils/README.md",
        "TestResources/README.md",
      ],
      resources: [
        .copy("Fixtures/StructProto"),
        .copy("Fixtures/Proto/common_types.proto"),
        .copy("Fixtures/Proto/scalar_types.proto"),
        .copy("Fixtures/Proto/container_types.proto"),
        .copy("Fixtures/Proto/oneof_types.proto"),
        .copy("Fixtures/Proto/nesting_types.proto"),
        .copy("Fixtures/Proto/wkt_types.proto"),
        .copy("Fixtures/Proto/proto2_types.proto"),
        .copy("Fixtures/Proto/realworld_types.proto"),
        .copy("Fixtures/Proto/cross_file_types.proto"),
      ]
    ),
  ]
)
