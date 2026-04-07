//
// InternalDescriptorsMappingTests.swift
// SwiftProtoReflectTests
//
// Tests for internal descriptor types (_ServiceDescriptor, _EnumDescriptor,
// _FieldDescriptor, _OneofDescriptor) exercised through Mapping.swift round-trips.
//
// Each assertion is backed by one of two oracles:
//   [PUBLIC-MIRROR] <File>.<testMethod> — same behavior verified on the public API
//   [PROTOC-BASH]   <command> — expected value produced by running protoc
//

import XCTest

@testable import SwiftProtoReflect

final class InternalDescriptorsMappingTests: XCTestCase {

  // MARK: - _ServiceDescriptor via Mapping round-trip

  // [PUBLIC-MIRROR] ServiceDescriptorTests.testInitWithNameAndFullName()
  // Oracle: ServiceDescriptor(name:fullName:).name == "UserService", .fullName == "example.UserService"
  func test_serviceDescriptor_mapping_basicInit_roundTrip() async throws {
    let pub = ServiceDescriptor(name: "UserService", fullName: "example.UserService")
    let impl = _ServiceDescriptor(from: pub)
    let back = ServiceDescriptor(from: impl)

    XCTAssertEqual(back.name, "UserService")
    XCTAssertEqual(back.fullName, "example.UserService")
    XCTAssertNil(back.fileDescriptorPath)
    XCTAssertTrue(back.methodsByName.isEmpty)
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] ServiceDescriptorTests.testInitWithParent()
  // Oracle: ServiceDescriptor(name:parent:).fullName == "example.UserService",
  //         .fileDescriptorPath == "user.proto"
  func test_serviceDescriptor_mapping_preservesFullNameAndFilePath() async throws {
    let fileDesc = FileDescriptor(name: "user.proto", package: "example")
    var pub = ServiceDescriptor(name: "UserService", parent: fileDesc)
    pub.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "GetUser",
        inputType: "example.GetUserRequest",
        outputType: "example.GetUserResponse"
      )
    )

    let impl = _ServiceDescriptor(from: pub)
    let back = ServiceDescriptor(from: impl)

    XCTAssertEqual(back.fullName, "example.UserService")
    XCTAssertEqual(back.fileDescriptorPath, "user.proto")
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] ServiceDescriptorTests.testAddMultipleMethods()
  // Oracle: service with 3 methods → methodsByName.count == 3
  func test_serviceDescriptor_mapping_preservesAllMethods() async throws {
    var pub = ServiceDescriptor(name: "UserService", fullName: "example.UserService")
    pub.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "GetUser",
        inputType: "example.GetUserRequest",
        outputType: "example.GetUserResponse"
      )
    )
    pub.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "CreateUser",
        inputType: "example.CreateUserRequest",
        outputType: "example.CreateUserResponse",
        clientStreaming: true
      )
    )
    pub.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "ListUsers",
        inputType: "example.ListUsersRequest",
        outputType: "example.ListUsersResponse",
        serverStreaming: true
      )
    )

    let impl = _ServiceDescriptor(from: pub)
    let back = ServiceDescriptor(from: impl)

    XCTAssertEqual(back.methodsByName.count, 3)
    XCTAssertTrue(back.hasMethod(named: "GetUser"))
    XCTAssertTrue(back.hasMethod(named: "CreateUser"))
    XCTAssertTrue(back.hasMethod(named: "ListUsers"))
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] ServiceDescriptorTests.testMethodDescriptorInitialization()
  // Oracle: MethodDescriptor(clientStreaming:true, serverStreaming:true) preserves both flags
  func test_serviceDescriptor_mapping_preservesStreamingFlags() async throws {
    var pub = ServiceDescriptor(name: "RouteGuide", fullName: "routeguide.RouteGuide")
    pub.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "RouteChat",
        inputType: ".routeguide.RouteNote",
        outputType: ".routeguide.RouteNote",
        clientStreaming: true,
        serverStreaming: true
      )
    )
    pub.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "ListFeatures",
        inputType: ".routeguide.Rectangle",
        outputType: ".routeguide.Feature",
        clientStreaming: false,
        serverStreaming: true
      )
    )
    pub.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "RecordRoute",
        inputType: ".routeguide.Point",
        outputType: ".routeguide.RouteSummary",
        clientStreaming: true,
        serverStreaming: false
      )
    )

    let impl = _ServiceDescriptor(from: pub)
    let back = ServiceDescriptor(from: impl)

    let routeChat = try XCTUnwrap(back.method(named: "RouteChat"))
    XCTAssertTrue(routeChat.clientStreaming)
    XCTAssertTrue(routeChat.serverStreaming)

    let listFeatures = try XCTUnwrap(back.method(named: "ListFeatures"))
    XCTAssertFalse(listFeatures.clientStreaming)
    XCTAssertTrue(listFeatures.serverStreaming)

    let recordRoute = try XCTUnwrap(back.method(named: "RecordRoute"))
    XCTAssertTrue(recordRoute.clientStreaming)
    XCTAssertFalse(recordRoute.serverStreaming)
  }

  // [PUBLIC-MIRROR] ServiceDescriptorTests.testInitWithOptions()
  // Oracle: ServiceDescriptor(options:["deprecated":.bool(true)]).options["deprecated"] == .bool(true)
  func test_serviceDescriptor_mapping_preservesOptions() async throws {
    let pub = ServiceDescriptor(
      name: "UserService",
      fullName: "example.UserService",
      options: ["deprecated": .bool(true), "customOption": .string("value")]
    )

    let impl = _ServiceDescriptor(from: pub)
    let back = ServiceDescriptor(from: impl)

    XCTAssertEqual(back.options.count, 2)
    XCTAssertEqual(back.options["deprecated"], .bool(true))
    XCTAssertEqual(back.options["customOption"], .string("value"))
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] ServiceDescriptorTests.testServiceDescriptorDifferentMethodCount()
  // Oracle: services with different method counts are not equal
  func test_serviceDescriptor_impl_equality_differentMethodCount() async throws {
    var pub1 = ServiceDescriptor(name: "S", fullName: "S")
    pub1.addMethod(
      ServiceDescriptor.MethodDescriptor(name: "M1", inputType: "I", outputType: "O")
    )
    pub1.addMethod(
      ServiceDescriptor.MethodDescriptor(name: "M2", inputType: "I", outputType: "O")
    )
    var pub2 = ServiceDescriptor(name: "S", fullName: "S")
    pub2.addMethod(
      ServiceDescriptor.MethodDescriptor(name: "M1", inputType: "I", outputType: "O")
    )

    let impl1 = _ServiceDescriptor(from: pub1)
    let impl2 = _ServiceDescriptor(from: pub2)

    XCTAssertNotEqual(impl1, impl2)
  }

  // [PUBLIC-MIRROR] ServiceDescriptorTests.testServiceDescriptorInequalityDifferentMethods()
  // Oracle: services with same count but different method names are not equal
  func test_serviceDescriptor_impl_equality_differentMethodName() async throws {
    var pub1 = ServiceDescriptor(name: "S", fullName: "S")
    pub1.addMethod(
      ServiceDescriptor.MethodDescriptor(name: "Method1", inputType: "I", outputType: "O")
    )
    var pub2 = ServiceDescriptor(name: "S", fullName: "S")
    pub2.addMethod(
      ServiceDescriptor.MethodDescriptor(name: "Method2", inputType: "I", outputType: "O")
    )

    let impl1 = _ServiceDescriptor(from: pub1)
    let impl2 = _ServiceDescriptor(from: pub2)

    XCTAssertNotEqual(impl1, impl2)
  }

  // [PUBLIC-MIRROR] ServiceDescriptorTests.testMethodDescriptorInequality()
  // Oracle: methods with different clientStreaming values are not equal
  func test_serviceDescriptor_impl_methodEquality_differentStreaming() async throws {
    var pub1 = ServiceDescriptor(name: "S", fullName: "S")
    pub1.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "M",
        inputType: "I",
        outputType: "O",
        clientStreaming: true
      )
    )
    var pub2 = ServiceDescriptor(name: "S", fullName: "S")
    pub2.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "M",
        inputType: "I",
        outputType: "O",
        clientStreaming: false
      )
    )

    let impl1 = _ServiceDescriptor(from: pub1)
    let impl2 = _ServiceDescriptor(from: pub2)

    XCTAssertNotEqual(impl1, impl2)
  }

  // [PUBLIC-MIRROR] ServiceDescriptorTests.testServiceDescriptorInequality()
  // Oracle: services with different names are not equal (different fullName → different ==)
  func test_serviceDescriptor_impl_equality_differentFullName() async throws {
    let pub1 = ServiceDescriptor(name: "S", fullName: "pkg.S")
    let pub2 = ServiceDescriptor(name: "S", fullName: "other.S")

    let impl1 = _ServiceDescriptor(from: pub1)
    let impl2 = _ServiceDescriptor(from: pub2)

    XCTAssertNotEqual(impl1, impl2)
  }

  // MARK: - _EnumDescriptor via Mapping round-trip

  // [PUBLIC-MIRROR] EnumDescriptorTests.testInitWithNameAndFullName()
  // Oracle: EnumDescriptor(name:"Status", fullName:"test.Status").name == "Status"
  func test_enumDescriptor_mapping_basicInit_roundTrip() async throws {
    let pub = EnumDescriptor(
      name: "Status",
      fullName: "test.Status",
      options: ["deprecated": .bool(true)]
    )

    let impl = _EnumDescriptor(from: pub)
    let back = EnumDescriptor(from: impl)

    XCTAssertEqual(back.name, "Status")
    XCTAssertEqual(back.fullName, "test.Status")
    XCTAssertEqual(back.options["deprecated"], .bool(true))
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests.testInitWithParentFileDescriptor()
  // Oracle: EnumDescriptor(name:parent:FileDescriptor).fullName == "test.Status",
  //         .fileDescriptorPath == "test.proto"
  func test_enumDescriptor_mapping_withFileParent_preservesFilePath() async throws {
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let pub = EnumDescriptor(name: "Status", parent: fileDescriptor)

    let impl = _EnumDescriptor(from: pub)
    let back = EnumDescriptor(from: impl)

    XCTAssertEqual(back.name, "Status")
    XCTAssertEqual(back.fullName, "test.Status")
    XCTAssertEqual(back.fileDescriptorPath, "test.proto")
    XCTAssertNil(back.parentMessageFullName)
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests.testInitWithParentMessageDescriptor()
  // Oracle: EnumDescriptor(name:parent:MessageDescriptor).fullName == "test.TestMessage.Status",
  //         .parentMessageFullName == "test.TestMessage"
  func test_enumDescriptor_mapping_withMessageParent_preservesParentFullName() async throws {
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    let pub = EnumDescriptor(name: "Status", parent: messageDescriptor)

    let impl = _EnumDescriptor(from: pub)
    let back = EnumDescriptor(from: impl)

    XCTAssertEqual(back.fullName, "test.TestMessage.Status")
    XCTAssertEqual(back.fileDescriptorPath, "test.proto")
    XCTAssertEqual(back.parentMessageFullName, "test.TestMessage")
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests.testInitWithNoParent()
  // Oracle: EnumDescriptor(name:) without parent → fullName == name, fileDescriptorPath == nil
  func test_enumDescriptor_mapping_noParent_preservesNameAsFullName() async throws {
    let pub = EnumDescriptor(name: "Status")

    let impl = _EnumDescriptor(from: pub)
    let back = EnumDescriptor(from: impl)

    XCTAssertEqual(back.name, "Status")
    XCTAssertEqual(back.fullName, "Status")
    XCTAssertNil(back.fileDescriptorPath)
    XCTAssertNil(back.parentMessageFullName)
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests.testAddAndRetrieveEnumValue()
  // Oracle: addValue(UNKNOWN/0), addValue(STARTED/1), addValue(RUNNING/2) → valuesByName/valuesByNumber
  func test_enumDescriptor_mapping_preservesValues() async throws {
    var pub = EnumDescriptor(name: "Status", fullName: "test.Status")
    pub.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    pub.addValue(EnumDescriptor.EnumValue(name: "STARTED", number: 1))
    pub.addValue(EnumDescriptor.EnumValue(name: "RUNNING", number: 2))

    let impl = _EnumDescriptor(from: pub)
    let back = EnumDescriptor(from: impl)

    XCTAssertTrue(back.hasValue(named: "UNKNOWN"))
    XCTAssertTrue(back.hasValue(number: 0))
    XCTAssertTrue(back.hasValue(named: "STARTED"))
    XCTAssertTrue(back.hasValue(number: 1))
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests.testEnumDescriptorEquality() — different value sets
  // Oracle: enums with different valuesByName elements are not equal
  func test_enumDescriptor_impl_equality_differentValues() async throws {
    var pub1 = EnumDescriptor(name: "Status", fullName: "test.Status")
    pub1.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 1))

    var pub2 = EnumDescriptor(name: "Status", fullName: "test.Status")
    pub2.addValue(EnumDescriptor.EnumValue(name: "DIFFERENT", number: 1))

    let impl1 = _EnumDescriptor(from: pub1)
    let impl2 = _EnumDescriptor(from: pub2)

    XCTAssertNotEqual(impl1, impl2)
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests.testEnumDescriptorWithDifferentFileDescriptorPath()
  // Oracle: same name/fullName but different fileDescriptorPath → not equal
  func test_enumDescriptor_impl_equality_differentFilePath() async throws {
    var pub1 = EnumDescriptor(name: "Status", fullName: "test.Status")
    pub1.fileDescriptorPath = "a.proto"

    var pub2 = EnumDescriptor(name: "Status", fullName: "test.Status")
    pub2.fileDescriptorPath = "b.proto"

    let impl1 = _EnumDescriptor(from: pub1)
    let impl2 = _EnumDescriptor(from: pub2)

    XCTAssertNotEqual(impl1, impl2)
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests.testEnumDescriptorWithDifferentParentMessageFullName()
  // Oracle: same name but different parentMessageFullName → not equal
  func test_enumDescriptor_impl_equality_differentParentMessage() async throws {
    var pub1 = EnumDescriptor(name: "Status", fullName: "test.Status")
    pub1.parentMessageFullName = "test.MessageA"

    var pub2 = EnumDescriptor(name: "Status", fullName: "test.Status")
    pub2.parentMessageFullName = "test.MessageB"

    let impl1 = _EnumDescriptor(from: pub1)
    let impl2 = _EnumDescriptor(from: pub2)

    XCTAssertNotEqual(impl1, impl2)
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests.testEnumDescriptorEqualityWithDifferentOptions()
  // Oracle: same name but different options value → not equal
  func test_enumDescriptor_impl_equality_differentOptions() async throws {
    let pub1 = EnumDescriptor(
      name: "Status",
      fullName: "test.Status",
      options: ["allow_alias": .bool(true)]
    )
    let pub2 = EnumDescriptor(
      name: "Status",
      fullName: "test.Status",
      options: ["allow_alias": .bool(false)]
    )

    let impl1 = _EnumDescriptor(from: pub1)
    let impl2 = _EnumDescriptor(from: pub2)

    XCTAssertNotEqual(impl1, impl2)
  }

  // Also exercise _EnumDescriptor init(name:parent:options:) with a _DescriptorParent
  // [PUBLIC-MIRROR] EnumDescriptorTests.testInitWithParentFileDescriptor()
  // Oracle: _EnumDescriptor with parent sets fullName as "package.Name"
  func test_enumDescriptor_internalInit_withParent() async throws {
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var pubVar = EnumDescriptor(name: "Color", parent: fileDescriptor)
    pubVar.addValue(EnumDescriptor.EnumValue(name: "RED", number: 0))
    pubVar.addValue(EnumDescriptor.EnumValue(name: "GREEN", number: 1))

    let impl = _EnumDescriptor(from: pubVar)
    XCTAssertEqual(impl.fullName, "test.Color")
    XCTAssertEqual(impl.fileDescriptorPath, "test.proto")
    XCTAssertEqual(impl.valuesByName.count, 2)
    XCTAssertNotNil(impl.valuesByName["RED"])
    XCTAssertEqual(impl.valuesByNumber[0]?.name, "RED")
    XCTAssertEqual(impl.valuesByNumber[1]?.name, "GREEN")
  }

  // MARK: - _FieldDescriptor via Mapping round-trip

  // [PUBLIC-MIRROR] FieldDescriptorTests.testBasicFieldDescriptor()
  // Oracle: FieldDescriptor(name:"age", number:1, type:.int32) preserves all default fields
  func test_fieldDescriptor_mapping_basicField_roundTrip() async throws {
    let pub = FieldDescriptor(name: "age", number: 1, type: .int32)

    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)

    XCTAssertEqual(back.name, "age")
    XCTAssertEqual(back.jsonName, "age")
    XCTAssertEqual(back.number, 1)
    XCTAssertEqual(back.type, .int32)
    XCTAssertNil(back.typeName)
    XCTAssertFalse(back.isRepeated)
    XCTAssertFalse(back.isOptional)
    XCTAssertFalse(back.isRequired)
    XCTAssertFalse(back.isMap)
    XCTAssertNil(back.oneofIndex)
    XCTAssertNil(back.mapEntryInfo)
    XCTAssertNil(back.defaultValue)
    XCTAssertTrue(back.options.isEmpty)
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests.test_fieldDescriptor_mapField_autoSetsIsRepeated() line 1189
  // Oracle: FieldDescriptor(isMap:true, isRepeated:false) → .isRepeated == true (auto-set)
  func test_fieldDescriptor_mapping_isMap_forcesIsRepeated() async throws {
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    let pub = FieldDescriptor(
      name: "my_map",
      number: 1,
      type: .message,
      typeName: "example.MapEntry",
      isRepeated: false,
      isMap: true,
      mapEntryInfo: mapInfo
    )

    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)

    XCTAssertTrue(back.isMap)
    XCTAssertTrue(back.isRepeated, "Map fields must be automatically marked as repeated")
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests.testFieldDescriptorWithAllProperties()
  // Oracle: FieldDescriptor with jsonName, isRepeated, defaultValue, options preserved
  func test_fieldDescriptor_mapping_allProperties_preserved() async throws {
    let pub = FieldDescriptor(
      name: "emails",
      number: 2,
      type: .string,
      jsonName: "email_addresses",
      isRepeated: true,
      isOptional: false,
      defaultValue: .string(""),
      options: ["packed": .bool(true)]
    )

    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)

    XCTAssertEqual(back.name, "emails")
    XCTAssertEqual(back.jsonName, "email_addresses")
    XCTAssertEqual(back.number, 2)
    XCTAssertEqual(back.type, .string)
    XCTAssertTrue(back.isRepeated)
    XCTAssertEqual(back.defaultValue, .string(""))
    XCTAssertEqual(back.options["packed"], .bool(true))
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests.test_fieldDescriptor_whenCreatedWithOneofIndex_preservesIndex_TFD01()
  // Oracle: FieldDescriptor(oneofIndex:0).oneofIndex == 0
  func test_fieldDescriptor_mapping_oneofIndex_preserved() async throws {
    let pub = FieldDescriptor(
      name: "email",
      number: 1,
      type: .string,
      oneofIndex: 0
    )

    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)

    XCTAssertEqual(back.oneofIndex, 0)
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests.testMapEntryComplexValue()
  // Oracle: MapEntryInfo with message value type and typeName preserved through round-trip
  func test_fieldDescriptor_mapping_mapEntryInfo_messageValue_preserved() async throws {
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "example.User")
    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    let pub = FieldDescriptor(
      name: "users",
      number: 5,
      type: .message,
      typeName: "example.UserMapEntry",
      isMap: true,
      mapEntryInfo: mapInfo
    )

    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)

    XCTAssertTrue(back.isMap)
    XCTAssertEqual(back.mapEntryInfo?.valueFieldInfo.type, .message)
    XCTAssertEqual(back.mapEntryInfo?.valueFieldInfo.typeName, "example.User")
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests — isPacked preserved
  // Oracle: FieldDescriptor with isPacked:true → impl.isPacked == true
  func test_fieldDescriptor_mapping_isPacked_preserved() async throws {
    let pub = FieldDescriptor(
      name: "values",
      number: 1,
      type: .int32,
      isRepeated: true,
      isPacked: true
    )

    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)

    XCTAssertEqual(back.isPacked, true)
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests — proto2 required field
  // Oracle: FieldDescriptor(isRequired:true).isRequired == true
  func test_fieldDescriptor_mapping_proto2_requiredField_preserved() async throws {
    let pub = FieldDescriptor(
      name: "id",
      number: 1,
      type: .int32,
      isRequired: true
    )

    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)

    XCTAssertTrue(back.isRequired)
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests — proto3 optional
  // Oracle: FieldDescriptor(proto3Optional:true).proto3Optional == true
  func test_fieldDescriptor_mapping_proto3Optional_preserved() async throws {
    let pub = FieldDescriptor(
      name: "nickname",
      number: 3,
      type: .string,
      isOptional: true,
      proto3Optional: true
    )

    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)

    XCTAssertTrue(back.proto3Optional)
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests — inequality by number
  // Oracle: two fields with different numbers are not equal
  func test_fieldDescriptor_impl_equality_differentNumber() async throws {
    let pub1 = FieldDescriptor(name: "id", number: 1, type: .int32)
    let pub2 = FieldDescriptor(name: "id", number: 2, type: .int32)

    let impl1 = _FieldDescriptor(from: pub1)
    let impl2 = _FieldDescriptor(from: pub2)

    XCTAssertNotEqual(impl1, impl2)
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests — inequality by type
  // Oracle: same name/number but different type → not equal
  func test_fieldDescriptor_impl_equality_differentType() async throws {
    let pub1 = FieldDescriptor(name: "val", number: 1, type: .int32)
    let pub2 = FieldDescriptor(name: "val", number: 1, type: .int64)

    let impl1 = _FieldDescriptor(from: pub1)
    let impl2 = _FieldDescriptor(from: pub2)

    XCTAssertNotEqual(impl1, impl2)
  }

  // MARK: - _OneofDescriptor via Mapping round-trip

  // [PUBLIC-MIRROR] OneofDescriptorTests.testInitialization()
  // Oracle: OneofDescriptor(name:"contact", index:0, options:["deprecated":.bool(true)])
  //         preserves all fields
  func test_oneofDescriptor_mapping_basicInit_roundTrip() async throws {
    let pub = OneofDescriptor(
      name: "contact",
      index: 0,
      options: ["deprecated": .bool(true)]
    )

    let impl = _OneofDescriptor(from: pub)
    let back = OneofDescriptor(from: impl)

    XCTAssertEqual(back.name, "contact")
    XCTAssertEqual(back.index, 0)
    XCTAssertEqual(back.options["deprecated"], .bool(true))
    XCTAssertEqual(back, pub)
  }

  // [PUBLIC-MIRROR] OneofDescriptorTests.testEquality() line 93
  // Oracle: OneofDescriptor with same name/index equal even with different options
  func test_oneofDescriptor_mapping_equalityIgnoresOptions() async throws {
    let pubWithOptions = OneofDescriptor(
      name: "contact",
      index: 0,
      options: ["deprecated": .bool(true)]
    )
    let pubEmpty = OneofDescriptor(name: "contact", index: 0)

    let implWithOptions = _OneofDescriptor(from: pubWithOptions)
    let implEmpty = _OneofDescriptor(from: pubEmpty)

    XCTAssertEqual(implWithOptions, implEmpty)
  }

  // [PUBLIC-MIRROR] OneofDescriptorTests.testInequalityDifferentName()
  // Oracle: different name → not equal
  func test_oneofDescriptor_impl_equality_differentName() async throws {
    let impl1 = _OneofDescriptor(from: OneofDescriptor(name: "contact", index: 0))
    let impl2 = _OneofDescriptor(from: OneofDescriptor(name: "payment", index: 0))

    XCTAssertNotEqual(impl1, impl2)
  }

  // [PUBLIC-MIRROR] OneofDescriptorTests.testInequalityDifferentIndex()
  // Oracle: different index → not equal
  func test_oneofDescriptor_impl_equality_differentIndex() async throws {
    let impl1 = _OneofDescriptor(from: OneofDescriptor(name: "contact", index: 0))
    let impl2 = _OneofDescriptor(from: OneofDescriptor(name: "contact", index: 1))

    XCTAssertNotEqual(impl1, impl2)
  }

  // [PUBLIC-MIRROR] OneofDescriptorTests.test_oneofDescriptor_whenCreatedWithOptionsDictionary_storesOptions_TOD02()
  // Oracle: options are stored and accessible
  func test_oneofDescriptor_mapping_options_preserved() async throws {
    let pub = OneofDescriptor(name: "x", index: 0, options: ["key": .bool(true)])
    let impl = _OneofDescriptor(from: pub)
    let back = OneofDescriptor(from: impl)

    XCTAssertEqual(back.options["key"], .bool(true))
  }

  // MARK: - Mapping.swift _FieldType all cases

  // [PUBLIC-MIRROR] FieldDescriptorTests — all FieldType scalar cases map correctly
  // Oracle: each pub FieldType survives the pub→impl→pub round-trip unchanged
  func test_fieldType_scalarCases_mapping_roundTrip() async throws {
    let scalarTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes,
    ]

    for fieldType in scalarTypes {
      let pub = FieldDescriptor(name: "f", number: 1, type: fieldType)
      let impl = _FieldDescriptor(from: pub)
      let back = FieldDescriptor(from: impl)
      XCTAssertEqual(back.type, fieldType, "FieldType.\(fieldType) did not survive Mapping round-trip")
    }
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests.testMapEntryComplexValue() — .message type with typeName
  // Oracle: FieldType.message with typeName survives round-trip
  func test_fieldType_message_mapping_roundTrip() async throws {
    let pub = FieldDescriptor(name: "user", number: 1, type: .message, typeName: "example.User")
    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)
    XCTAssertEqual(back.type, .message)
    XCTAssertEqual(back.typeName, "example.User")
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests — enum type field
  // Oracle: FieldType.enum with typeName survives round-trip
  func test_fieldType_enum_mapping_roundTrip() async throws {
    let pub = FieldDescriptor(name: "status", number: 2, type: .enum, typeName: "example.Status")
    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)
    XCTAssertEqual(back.type, .enum)
    XCTAssertEqual(back.typeName, "example.Status")
  }

  // [PUBLIC-MIRROR] Proto2DescriptorTests — group type (proto2 only)
  // Oracle: FieldType.group with typeName survives round-trip
  func test_fieldType_group_mapping_roundTrip() async throws {
    let pub = FieldDescriptor(name: "mygroup", number: 3, type: .group, typeName: "example.MyGroup")
    let impl = _FieldDescriptor(from: pub)
    let back = FieldDescriptor(from: impl)
    XCTAssertEqual(back.type, .group)
  }

  // MARK: - Mapping.swift ExtensionRange

  // [PUBLIC-MIRROR] FileDescriptorTests — extension ranges preserved
  // Oracle: ExtensionRange(start:100, end:200) survives round-trip
  func test_extensionRange_mapping_roundTrip() async throws {
    let pub = ExtensionRange(start: 100, end: 200)
    let impl = _ExtensionRange(from: pub)
    let back = ExtensionRange(from: impl)

    XCTAssertEqual(back.start, 100)
    XCTAssertEqual(back.end, 200)
  }

  // MARK: - Mapping.swift KeyFieldInfo / ValueFieldInfo

  // [PUBLIC-MIRROR] FieldDescriptorTests.testMapEntryValidKeyTypes()
  // Oracle: KeyFieldInfo(name:number:type:) preserves all fields
  func test_keyFieldInfo_mapping_roundTrip() async throws {
    let pub = KeyFieldInfo(name: "key", number: 1, type: .string)
    let impl = _KeyFieldInfo(from: pub)
    let back = KeyFieldInfo(from: impl)

    XCTAssertEqual(back.name, "key")
    XCTAssertEqual(back.number, 1)
    XCTAssertEqual(back.type, .string)
  }

  // [PUBLIC-MIRROR] FieldDescriptorTests.testMapEntryComplexValue()
  // Oracle: ValueFieldInfo with typeName preserved through round-trip
  func test_valueFieldInfo_mapping_withTypeName_roundTrip() async throws {
    let pub = ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "example.User")
    let impl = _ValueFieldInfo(from: pub)
    let back = ValueFieldInfo(from: impl)

    XCTAssertEqual(back.name, "value")
    XCTAssertEqual(back.number, 2)
    XCTAssertEqual(back.type, .message)
    XCTAssertEqual(back.typeName, "example.User")
  }

  // MARK: - Mapping.swift DescriptorOption all cases

  // [PUBLIC-MIRROR] ServiceDescriptorTests.testInitWithOptions() — all option types
  // Oracle: each DescriptorOption type survives pub→impl→pub round-trip
  func test_descriptorOption_allCases_mapping_roundTrip() async throws {
    let cases: [DescriptorOption] = [
      .bool(true), .bool(false),
      .int(42), .int(-1),
      .string("hello"), .string(""),
      .float(3.14), .float(-1.5),
      .double(1.23456789), .double(0.0),
      .bytes(Data([0x01, 0x02, 0xFF])),
    ]

    for option in cases {
      let impl = _DescriptorOption(from: option)
      let back = DescriptorOption(from: impl)
      XCTAssertEqual(back, option, "DescriptorOption \(option) did not survive Mapping round-trip")
    }
  }

  // MARK: - _FileDescriptor coverage

  // [PUBLIC-MIRROR] FileDescriptorTests.testAddMessage
  // Oracle: _FileDescriptor.addMessage sets fileDescriptorPath on message when it has none
  func test_fileDescriptor_addMessage_setsFileDescriptorPath_whenMessageHasNone() {
    var fileDesc = _FileDescriptor(name: "my.proto", package: "example")
    let msgDesc = _MessageDescriptor(name: "MyMessage", fullName: "example.MyMessage")

    XCTAssertNil(msgDesc.fileDescriptorPath)
    XCTAssertNil(msgDesc.parentMessageFullName)

    fileDesc.addMessage(msgDesc)

    XCTAssertEqual(fileDesc.messages["MyMessage"]?.fileDescriptorPath, "my.proto")
  }

  // [PUBLIC-MIRROR] FileDescriptorTests.testGetFullName
  // Oracle: _FileDescriptor.getFullName with non-empty package returns "package.TypeName"
  func test_fileDescriptor_getFullName_withNonEmptyPackage_returnsPrefixed() {
    let fileDesc = _FileDescriptor(name: "my.proto", package: "example")

    XCTAssertEqual(fileDesc.getFullName(for: "MyMessage"), "example.MyMessage")
    XCTAssertEqual(fileDesc.getFullName(for: "OtherType"), "example.OtherType")
  }

  // [PUBLIC-MIRROR] FileDescriptorTests.testGetFullName
  // Oracle: _FileDescriptor.getFullName with empty package returns just the type name
  func test_fileDescriptor_getFullName_withEmptyPackage_returnsTypeName() {
    let fileDesc = _FileDescriptor(name: "my.proto", package: "")

    XCTAssertEqual(fileDesc.getFullName(for: "MyMessage"), "MyMessage")
  }

  // MARK: - _EnumDescriptor._EnumValue equality

  // [PUBLIC-MIRROR] EnumDescriptorTests.testEnumDescriptorEquality
  // Oracle: two _EnumValue instances with same name/number/options are equal
  func test_enumValue_impl_equality_identical_returnsTrue() {
    let v1 = _EnumDescriptor._EnumValue(name: "ACTIVE", number: 1, options: ["deprecated": .bool(false)])
    let v2 = _EnumDescriptor._EnumValue(name: "ACTIVE", number: 1, options: ["deprecated": .bool(false)])

    XCTAssertEqual(v1, v2)
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests.testEnumValueWithOptions
  // Oracle: two _EnumValue instances with different options are not equal
  func test_enumValue_impl_equality_differentOptions_returnsFalse() {
    let v1 = _EnumDescriptor._EnumValue(name: "ACTIVE", number: 1, options: ["deprecated": .bool(true)])
    let v2 = _EnumDescriptor._EnumValue(name: "ACTIVE", number: 1, options: ["deprecated": .bool(false)])

    XCTAssertNotEqual(v1, v2)
  }

  // MARK: - _EnumDescriptor equality complete paths

  // [PUBLIC-MIRROR] EnumDescriptorTests.testEnumDescriptorEquality
  // Oracle: two identical _EnumDescriptor instances (same values) are equal
  func test_enumDescriptor_impl_equality_identical_returnsTrue() {
    var impl1 = _EnumDescriptor(name: "Status", fullName: "test.Status")
    impl1.addValue(_EnumDescriptor._EnumValue(name: "UNKNOWN", number: 0))
    impl1.addValue(_EnumDescriptor._EnumValue(name: "ACTIVE", number: 1))

    var impl2 = _EnumDescriptor(name: "Status", fullName: "test.Status")
    impl2.addValue(_EnumDescriptor._EnumValue(name: "UNKNOWN", number: 0))
    impl2.addValue(_EnumDescriptor._EnumValue(name: "ACTIVE", number: 1))

    XCTAssertEqual(impl1, impl2)
  }

  // [PUBLIC-MIRROR] EnumDescriptorTests.testEnumDescriptorEquality
  // Oracle: _EnumDescriptor with same metadata but different value count → not equal
  func test_enumDescriptor_impl_equality_differentValueCount_returnsFalse() {
    var impl1 = _EnumDescriptor(name: "Status", fullName: "test.Status")
    impl1.addValue(_EnumDescriptor._EnumValue(name: "A", number: 0))
    impl1.addValue(_EnumDescriptor._EnumValue(name: "B", number: 1))

    var impl2 = _EnumDescriptor(name: "Status", fullName: "test.Status")
    impl2.addValue(_EnumDescriptor._EnumValue(name: "A", number: 0))

    XCTAssertNotEqual(impl1, impl2)
  }
}
