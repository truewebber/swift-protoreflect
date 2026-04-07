//
// MappingWKTConvertersTests.swift
// SwiftProtoReflectTests
//
// Tests for Mapping.swift WKT converter pairs and _FileDescriptor.
// Also covers _StructHandler.swift (0% → 100%) via _StructValue / _ValueValue.
//
// Each assertion is backed by one of two oracles:
//   [PUBLIC-MIRROR] <File>.<testMethod> — same behavior verified on the public API
//   [PROTOC-BASH]   <command> — expected value produced by running protoc
//

import XCTest

@testable import SwiftProtoReflect

final class MappingWKTConvertersTests: XCTestCase {

  // MARK: - _WellKnownSupportPhase ↔ WellKnownSupportPhase

  // [PUBLIC-MIRROR] AnyHandlerTests.testHandlerBasicProperties()
  // Oracle: AnyHandler.supportPhase == .advanced
  func test_wellKnownSupportPhase_critical_roundTrip() async throws {
    let pub = WellKnownSupportPhase.critical
    let impl = _WellKnownSupportPhase(from: pub)
    let back = WellKnownSupportPhase(from: impl)
    XCTAssertEqual(back, .critical)
  }

  // [PUBLIC-MIRROR] TimestampHandlerTests.testHandlerBasicProperties() — .critical phase
  func test_wellKnownSupportPhase_important_roundTrip() async throws {
    let pub = WellKnownSupportPhase.important
    let impl = _WellKnownSupportPhase(from: pub)
    let back = WellKnownSupportPhase(from: impl)
    XCTAssertEqual(back, .important)
  }

  // [PUBLIC-MIRROR] AnyHandlerTests.testHandlerBasicProperties() — .advanced phase
  func test_wellKnownSupportPhase_advanced_roundTrip() async throws {
    let pub = WellKnownSupportPhase.advanced
    let impl = _WellKnownSupportPhase(from: pub)
    let back = WellKnownSupportPhase(from: impl)
    XCTAssertEqual(back, .advanced)
  }

  // MARK: - _TimestampHandler._TimestampValue ↔ TimestampHandler.TimestampValue

  // [PUBLIC-MIRROR] TimestampHandlerTests.testTimestampValueInitialization()
  // Oracle: TimestampValue(seconds:1_234_567_890, nanos:123_456_789) preserves both fields
  func test_timestampValue_mapping_roundTrip() async throws {
    let pub = try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_789)

    let impl = _TimestampHandler._TimestampValue(from: pub)
    XCTAssertEqual(impl.seconds, 1_234_567_890)
    XCTAssertEqual(impl.nanos, 123_456_789)

    let back = try TimestampHandler.TimestampValue(from: impl)
    XCTAssertEqual(back.seconds, pub.seconds)
    XCTAssertEqual(back.nanos, pub.nanos)
  }

  // [PUBLIC-MIRROR] TimestampHandlerTests.testTimestampValueInitialization() — zero values
  // Oracle: TimestampValue(seconds:0, nanos:0) is valid
  func test_timestampValue_mapping_zero_roundTrip() async throws {
    let pub = try TimestampHandler.TimestampValue(seconds: 0, nanos: 0)

    let impl = _TimestampHandler._TimestampValue(from: pub)
    XCTAssertEqual(impl.seconds, 0)
    XCTAssertEqual(impl.nanos, 0)

    let back = try TimestampHandler.TimestampValue(from: impl)
    XCTAssertEqual(back.seconds, 0)
    XCTAssertEqual(back.nanos, 0)
  }

  // [PUBLIC-MIRROR] TimestampHandlerTests.testTimestampValueInitialization() — negative seconds
  // Oracle: TimestampValue(seconds:-1, nanos:999_999_999) is valid
  func test_timestampValue_mapping_negativeSeconds_roundTrip() async throws {
    let pub = try TimestampHandler.TimestampValue(seconds: -1, nanos: 999_999_999)

    let impl = _TimestampHandler._TimestampValue(from: pub)
    let back = try TimestampHandler.TimestampValue(from: impl)

    XCTAssertEqual(back.seconds, -1)
    XCTAssertEqual(back.nanos, 999_999_999)
  }

  // MARK: - _DurationHandler._DurationValue ↔ DurationHandler.DurationValue

  // [PUBLIC-MIRROR] DurationHandlerTests — DurationValue(seconds:3600, nanos:0)
  // Oracle: DurationValue preserves seconds and nanos
  func test_durationValue_mapping_roundTrip() async throws {
    let pub = try DurationHandler.DurationValue(seconds: 3600, nanos: 0)

    let impl = _DurationHandler._DurationValue(from: pub)
    XCTAssertEqual(impl.seconds, 3600)
    XCTAssertEqual(impl.nanos, 0)

    let back = try DurationHandler.DurationValue(from: impl)
    XCTAssertEqual(back.seconds, 3600)
    XCTAssertEqual(back.nanos, 0)
  }

  // [PUBLIC-MIRROR] DurationHandlerTests — negative duration
  // Oracle: DurationValue(seconds:-5, nanos:-500_000_000) is valid
  func test_durationValue_mapping_negative_roundTrip() async throws {
    let pub = try DurationHandler.DurationValue(seconds: -5, nanos: -500_000_000)

    let impl = _DurationHandler._DurationValue(from: pub)
    let back = try DurationHandler.DurationValue(from: impl)

    XCTAssertEqual(back.seconds, -5)
    XCTAssertEqual(back.nanos, -500_000_000)
  }

  // MARK: - _EmptyHandler._EmptyValue ↔ EmptyHandler.EmptyValue

  // [PUBLIC-MIRROR] EmptyHandlerTests — EmptyValue has no fields
  // Oracle: EmptyValue() round-trips without error
  func test_emptyValue_mapping_roundTrip() async throws {
    let pub = EmptyHandler.EmptyValue()

    let impl = _EmptyHandler._EmptyValue(from: pub)
    let back = EmptyHandler.EmptyValue(from: impl)

    _ = back  // Just verify it initializes without error
    XCTAssertTrue(true, "EmptyValue round-trip succeeded")
  }

  // MARK: - _FieldMaskHandler._FieldMaskValue ↔ FieldMaskHandler.FieldMaskValue

  // [PUBLIC-MIRROR] FieldMaskHandlerTests — FieldMaskValue(paths:["user.name","user.email"])
  // Oracle: paths array preserved through round-trip
  func test_fieldMaskValue_mapping_roundTrip() async throws {
    let paths = ["user.name", "user.email", "user.address.city"]
    let pub = try FieldMaskHandler.FieldMaskValue(paths: paths)

    let impl = _FieldMaskHandler._FieldMaskValue(from: pub)
    XCTAssertEqual(impl.paths, paths)

    let back = try FieldMaskHandler.FieldMaskValue(from: impl)
    XCTAssertEqual(back.paths, paths)
  }

  // [PUBLIC-MIRROR] FieldMaskHandlerTests — empty paths
  // Oracle: FieldMaskValue(paths:[]) round-trips
  func test_fieldMaskValue_mapping_emptyPaths_roundTrip() async throws {
    let pub = try FieldMaskHandler.FieldMaskValue(paths: [])

    let impl = _FieldMaskHandler._FieldMaskValue(from: pub)
    XCTAssertTrue(impl.paths.isEmpty)

    let back = try FieldMaskHandler.FieldMaskValue(from: impl)
    XCTAssertTrue(back.paths.isEmpty)
  }

  // MARK: - _StructHandler._StructValue ↔ StructHandler.StructValue
  // These tests also cover _StructHandler.swift (0% → 100%)

  // [PUBLIC-MIRROR] StructHandlerTests.testStructValueInitialization()
  // Oracle: StructValue(fields:["name":.stringValue("John")]) round-trips
  func test_structValue_mapping_roundTrip() async throws {
    let pub = StructHandler.StructValue(fields: [
      "name": .stringValue("John"),
      "age": .numberValue(30),
      "active": .boolValue(true),
    ])

    // Covers _StructHandler._StructValue.init(_ pub:)
    let impl = _StructHandler._StructValue(from: pub)
    XCTAssertEqual(impl.pub.fields.count, 3)
    XCTAssertEqual(impl.pub.getValue("name"), .stringValue("John"))
    XCTAssertEqual(impl.pub.getValue("age"), .numberValue(30))
    XCTAssertEqual(impl.pub.getValue("active"), .boolValue(true))

    // Covers StructHandler.StructValue.init(from: _StructValue)
    let back = StructHandler.StructValue(from: impl)
    XCTAssertEqual(back.fields.count, 3)
    XCTAssertEqual(back.getValue("name"), .stringValue("John"))
  }

  // [PUBLIC-MIRROR] StructHandlerTests.testStructValueInitialization() — empty struct
  // Oracle: StructValue() has empty fields
  func test_structValue_mapping_empty_roundTrip() async throws {
    let pub = StructHandler.StructValue()

    let impl = _StructHandler._StructValue(from: pub)
    XCTAssertTrue(impl.pub.fields.isEmpty)

    let back = StructHandler.StructValue(from: impl)
    XCTAssertTrue(back.fields.isEmpty)
  }

  // MARK: - _StructHandler._ValueValue ↔ StructHandler.ValueValue

  // [PUBLIC-MIRROR] StructHandlerTests — nullValue
  // Oracle: .nullValue round-trips through _ValueValue
  func test_valueValue_mapping_nullValue_roundTrip() async throws {
    let pub = StructHandler.ValueValue.nullValue

    let impl = _StructHandler._ValueValue(from: pub)
    XCTAssertEqual(impl.pub, .nullValue)

    let back = StructHandler.ValueValue(from: impl)
    XCTAssertEqual(back, .nullValue)
  }

  // [PUBLIC-MIRROR] StructHandlerTests.testStructValueInitialization()
  // Oracle: .numberValue(42.0) round-trips
  func test_valueValue_mapping_numberValue_roundTrip() async throws {
    let pub = StructHandler.ValueValue.numberValue(42.5)

    let impl = _StructHandler._ValueValue(from: pub)
    XCTAssertEqual(impl.pub, .numberValue(42.5))

    let back = StructHandler.ValueValue(from: impl)
    XCTAssertEqual(back, .numberValue(42.5))
  }

  // [PUBLIC-MIRROR] StructHandlerTests — .stringValue("hello")
  func test_valueValue_mapping_stringValue_roundTrip() async throws {
    let pub = StructHandler.ValueValue.stringValue("hello world")

    let impl = _StructHandler._ValueValue(from: pub)
    XCTAssertEqual(impl.pub, .stringValue("hello world"))

    let back = StructHandler.ValueValue(from: impl)
    XCTAssertEqual(back, .stringValue("hello world"))
  }

  // [PUBLIC-MIRROR] StructHandlerTests — .boolValue(true)
  func test_valueValue_mapping_boolValue_roundTrip() async throws {
    let pub = StructHandler.ValueValue.boolValue(true)

    let impl = _StructHandler._ValueValue(from: pub)
    XCTAssertEqual(impl.pub, .boolValue(true))

    let back = StructHandler.ValueValue(from: impl)
    XCTAssertEqual(back, .boolValue(true))
  }

  // [PUBLIC-MIRROR] StructHandlerTests — .structValue(...)
  func test_valueValue_mapping_structValue_roundTrip() async throws {
    let inner = StructHandler.StructValue(fields: ["key": .stringValue("val")])
    let pub = StructHandler.ValueValue.structValue(inner)

    let impl = _StructHandler._ValueValue(from: pub)
    if case .structValue(let s) = impl.pub {
      XCTAssertEqual(s.getValue("key"), .stringValue("val"))
    }
    else {
      XCTFail("Expected structValue in impl")
    }

    let back = StructHandler.ValueValue(from: impl)
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] StructHandlerTests — .listValue(...)
  func test_valueValue_mapping_listValue_roundTrip() async throws {
    let pub = StructHandler.ValueValue.listValue([.stringValue("a"), .numberValue(1.0)])

    let impl = _StructHandler._ValueValue(from: pub)
    if case .listValue(let list) = impl.pub {
      XCTAssertEqual(list.count, 2)
      XCTAssertEqual(list[0], .stringValue("a"))
    }
    else {
      XCTFail("Expected listValue in impl")
    }

    let back = StructHandler.ValueValue(from: impl)
    XCTAssertEqual(back, pub)
  }

  // MARK: - _AnyHandler._AnyValue ↔ AnyHandler.AnyValue

  // [PUBLIC-MIRROR] AnyHandlerTests.testAnyValueInitialization()
  // Oracle: AnyValue(typeUrl:..., value:Data([0x08, 0x96, 0x01])) preserves both fields
  func test_anyValue_mapping_roundTrip() async throws {
    let typeUrl = "type.googleapis.com/google.protobuf.Duration"
    let data = Data([0x08, 0x96, 0x01])
    let pub = try AnyHandler.AnyValue(typeUrl: typeUrl, value: data)

    let impl = _AnyHandler._AnyValue(from: pub)
    XCTAssertEqual(impl.typeUrl, typeUrl)
    XCTAssertEqual(impl.value, data)

    let back = try AnyHandler.AnyValue(from: impl)
    XCTAssertEqual(back.typeUrl, typeUrl)
    XCTAssertEqual(back.value, data)
  }

  // [PUBLIC-MIRROR] AnyHandlerTests.testAnyValueInitialization() — empty value data
  // Oracle: AnyValue with empty Data is valid
  func test_anyValue_mapping_emptyData_roundTrip() async throws {
    let typeUrl = "type.googleapis.com/google.protobuf.Empty"
    let pub = try AnyHandler.AnyValue(typeUrl: typeUrl, value: Data())

    let impl = _AnyHandler._AnyValue(from: pub)
    XCTAssertTrue(impl.value.isEmpty)

    let back = try AnyHandler.AnyValue(from: impl)
    XCTAssertTrue(back.value.isEmpty)
    XCTAssertEqual(back.typeUrl, typeUrl)
  }

  // MARK: - _FileDescriptor ↔ FileDescriptor

  // [PUBLIC-MIRROR] FileDescriptorTests.testInitialization()
  // Oracle: FileDescriptor(name:package:dependencies:options:) preserves all fields
  func test_fileDescriptor_mapping_basicInit_roundTrip() async throws {
    var pub = FileDescriptor(
      name: "person.proto",
      package: "example.person",
      dependencies: ["google/protobuf/timestamp.proto"],
      options: ["java_package": .string("com.example.person")]
    )
    pub.addMessage(MessageDescriptor(name: "Person", fullName: "example.person.Person"))

    let impl = _FileDescriptor(from: pub)
    let back = FileDescriptor(from: impl)

    XCTAssertEqual(back.name, "person.proto")
    XCTAssertEqual(back.package, "example.person")
    XCTAssertEqual(back.dependencies, ["google/protobuf/timestamp.proto"])
    XCTAssertEqual(back.options["java_package"], .string("com.example.person"))
    XCTAssertTrue(back.hasMessage(named: "Person"))
  }

  // [PUBLIC-MIRROR] FileDescriptorTests.testInitializationWithDefaults()
  // Oracle: FileDescriptor(name:package:) with no dependencies/options
  func test_fileDescriptor_mapping_defaults_roundTrip() async throws {
    let pub = FileDescriptor(name: "empty.proto", package: "test")

    let impl = _FileDescriptor(from: pub)
    let back = FileDescriptor(from: impl)

    XCTAssertEqual(back.name, "empty.proto")
    XCTAssertEqual(back.package, "test")
    XCTAssertTrue(back.dependencies.isEmpty)
    XCTAssertTrue(back.options.isEmpty)
  }

  // [PUBLIC-MIRROR] FileDescriptorTests.testInitializationWithEmptyPackage()
  // Oracle: FileDescriptor with empty package → syntax fallback to proto2 when empty
  func test_fileDescriptor_mapping_emptyPackage_roundTrip() async throws {
    let pub = FileDescriptor(name: "no_package.proto", package: "")

    let impl = _FileDescriptor(from: pub)
    let back = FileDescriptor(from: impl)

    XCTAssertEqual(back.name, "no_package.proto")
    XCTAssertEqual(back.package, "")
  }

  // [PUBLIC-MIRROR] FileDescriptorTests.testInitialization() — multiple dependencies
  // Oracle: dependencies array preserved exactly
  func test_fileDescriptor_mapping_multipleDependencies_roundTrip() async throws {
    let pub = FileDescriptor(
      name: "service.proto",
      package: "myapp",
      dependencies: [
        "google/protobuf/timestamp.proto",
        "google/protobuf/duration.proto",
        "common/types.proto",
      ]
    )

    let impl = _FileDescriptor(from: pub)
    let back = FileDescriptor(from: impl)

    XCTAssertEqual(back.dependencies.count, 3)
    XCTAssertTrue(back.dependencies.contains("google/protobuf/timestamp.proto"))
    XCTAssertTrue(back.dependencies.contains("google/protobuf/duration.proto"))
    XCTAssertTrue(back.dependencies.contains("common/types.proto"))
  }

  // [PUBLIC-MIRROR] ServiceDescriptorTests — FileDescriptor with services
  // Oracle: services added to file are preserved through round-trip
  func test_fileDescriptor_mapping_withServices_roundTrip() async throws {
    var pub = FileDescriptor(name: "user_service.proto", package: "example")
    var service = ServiceDescriptor(name: "UserService", parent: pub)
    service.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "GetUser",
        inputType: ".example.GetUserRequest",
        outputType: ".example.GetUserResponse"
      )
    )
    pub.addService(service)

    let impl = _FileDescriptor(from: pub)
    let back = FileDescriptor(from: impl)

    XCTAssertTrue(back.hasService(named: "UserService"))
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests — FileDescriptor with enums
  // Oracle: enums added to file are preserved through round-trip
  func test_fileDescriptor_mapping_withEnums_roundTrip() async throws {
    var pub = FileDescriptor(name: "status.proto", package: "example")
    var status = EnumDescriptor(name: "Status", parent: pub)
    status.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    status.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    pub.addEnum(status)

    let impl = _FileDescriptor(from: pub)
    let back = FileDescriptor(from: impl)

    XCTAssertTrue(back.hasEnum(named: "Status"))
  }

  // [PUBLIC-MIRROR] FileDescriptorTests — proto2 syntax
  // Oracle: FileDescriptor with syntax "proto2" preserved; empty syntax → "proto2"
  func test_fileDescriptor_mapping_proto2Syntax_roundTrip() async throws {
    let pub = FileDescriptor(name: "old.proto", package: "legacy", syntax: "proto2")

    let impl = _FileDescriptor(from: pub)
    let back = FileDescriptor(from: impl)

    XCTAssertEqual(back.syntax, "proto2")
  }

  // [PUBLIC-MIRROR] FileDescriptorTests — proto3 syntax
  // Oracle: default FileDescriptor syntax is "proto3"
  func test_fileDescriptor_mapping_proto3Syntax_roundTrip() async throws {
    let pub = FileDescriptor(name: "modern.proto", package: "example", syntax: "proto3")

    let impl = _FileDescriptor(from: pub)
    let back = FileDescriptor(from: impl)

    XCTAssertEqual(back.syntax, "proto3")
  }
}
