// swift-tools-version: 6.0

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
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.29.0"),
    .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
    .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.0.0"),
    .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.86.0"),
    .package(url: "https://github.com/apple/swift-nio-http2.git", from: "1.38.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.6.4"),
  ],
  targets: [
    .target(
      name: "SwiftProtoReflect",
      dependencies: [
        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
        .product(name: "GRPCCore", package: "grpc-swift-2"),
        .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
        .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf"),
        // NIO
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOFoundationCompat", package: "swift-nio"),
        // HPACK from nio-http2
        .product(name: "NIOHTTP2", package: "swift-nio-http2"),
        // swift-log
        .product(name: "Logging", package: "swift-log"),
      ],
      exclude: [
        "Service/_README.md",
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
        .product(name: "GRPCCore", package: "grpc-swift-2"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
      ],
      exclude: [
        "Fixtures/README.md",
        "Mocks/README.md",
        "TestUtils/README.md",
        "TestResources/README.md",
      ]
    ),
  ]
)
