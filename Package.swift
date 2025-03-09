// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "SwiftProtoReflect",
	platforms: [
		.macOS(.v12),
		.iOS(.v15)
	],
	products: [
		.library(
			name: "SwiftProtoReflect",
			targets: ["SwiftProtoReflect"]
		)
	],
	dependencies: [],
	targets: [
		.target(
			name: "SwiftProtoReflect",
			dependencies: []
		),
		.testTarget(
			name: "SwiftProtoReflectTests",
			dependencies: ["SwiftProtoReflect"]
		)
	]
)
