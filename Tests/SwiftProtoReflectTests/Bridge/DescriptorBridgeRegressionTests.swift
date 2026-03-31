import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class DescriptorBridgeRegressionTests: XCTestCase {

  let bridge = DescriptorBridge()

  func test_fromProtobufDescriptor_allScalarFieldTypes_preservedCorrectly() throws {
    let fields = [
      makeFieldProto(name: "f_bool", number: 1, type: .bool),
      makeFieldProto(name: "f_int32", number: 2, type: .int32),
      makeFieldProto(name: "f_int64", number: 3, type: .int64),
      makeFieldProto(name: "f_uint32", number: 4, type: .uint32),
      makeFieldProto(name: "f_uint64", number: 5, type: .uint64),
      makeFieldProto(name: "f_float", number: 6, type: .float),
      makeFieldProto(name: "f_double", number: 7, type: .double),
      makeFieldProto(name: "f_string", number: 8, type: .string),
      makeFieldProto(name: "f_bytes", number: 9, type: .bytes),
    ]
    let msgProto = makeMessageProto(name: "Scalars", fields: fields)
    let fd = FileDescriptor(name: "t.proto", package: "pkg")
    let result = try bridge.fromProtobufDescriptor(msgProto, parent: fd)
    XCTAssertNotNil(result.field(named: "f_bool"))
    XCTAssertNotNil(result.field(named: "f_int32"))
    XCTAssertNotNil(result.field(named: "f_int64"))
    XCTAssertNotNil(result.field(named: "f_uint32"))
    XCTAssertNotNil(result.field(named: "f_uint64"))
    XCTAssertNotNil(result.field(named: "f_float"))
    XCTAssertNotNil(result.field(named: "f_double"))
    XCTAssertNotNil(result.field(named: "f_string"))
    XCTAssertNotNil(result.field(named: "f_bytes"))
  }

  func test_fromProtobufDescriptor_repeatedField_isRepeatedTrue() throws {
    let field = makeFieldProto(name: "items", number: 1, type: .string, label: .repeated)
    let msgProto = makeMessageProto(name: "Msg", fields: [field])
    let result = try bridge.fromProtobufDescriptor(msgProto)
    XCTAssertTrue(result.field(named: "items")!.isRepeated)
  }

  func test_fromProtobufDescriptor_requiredField_proto2_isRequiredTrue() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "name"
    fieldProto.number = 1
    fieldProto.type = .string
    fieldProto.label = .required
    let msgProto = makeMessageProto(name: "Msg", fields: [fieldProto])
    let fd = FileDescriptor(name: "t.proto", package: "pkg", syntax: "proto2")
    let result = try bridge.fromProtobufDescriptor(msgProto, parent: fd)
    XCTAssertTrue(result.field(named: "name")!.isRequired)
  }

  func test_fromProtobufDescriptor_mapField_isMapTrue_mapEntryInfoSet() throws {
    var mapValue = Google_Protobuf_FieldDescriptorProto()
    mapValue.name = "value"
    mapValue.number = 2
    mapValue.type = .string
    mapValue.label = .optional

    var mapKey = Google_Protobuf_FieldDescriptorProto()
    mapKey.name = "key"
    mapKey.number = 1
    mapKey.type = .string
    mapKey.label = .optional

    var mapEntryOptions = Google_Protobuf_MessageOptions()
    mapEntryOptions.mapEntry = true
    var mapEntryProto = Google_Protobuf_DescriptorProto()
    mapEntryProto.name = "DataEntry"
    mapEntryProto.field = [mapKey, mapValue]
    mapEntryProto.options = mapEntryOptions

    let mapField = makeFieldProto(
      name: "data",
      number: 1,
      type: .message,
      label: .repeated,
      typeName: ".Msg.DataEntry"
    )
    let msgProto = makeMessageProto(name: "Msg", fields: [mapField], nestedMessages: [mapEntryProto])
    let result = try bridge.fromProtobufDescriptor(msgProto)
    XCTAssertTrue(result.field(named: "data")!.isMap)
    XCTAssertNotNil(result.field(named: "data")!.mapEntryInfo)
  }

  func test_fromProtobufDescriptor_packedField_isPackedTrue() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "nums"
    fieldProto.number = 1
    fieldProto.type = .int32
    fieldProto.label = .repeated
    var opts = Google_Protobuf_FieldOptions()
    opts.packed = true
    fieldProto.options = opts
    let msgProto = makeMessageProto(name: "Msg", fields: [fieldProto])
    let result = try bridge.fromProtobufDescriptor(msgProto)
    XCTAssertEqual(result.field(named: "nums")?.isPacked, true)
  }

  func test_fromProtobufDescriptor_oneofDecl_countAndNamesPreserved() throws {
    var oneof = Google_Protobuf_OneofDescriptorProto()
    oneof.name = "payload"
    var oneofField = Google_Protobuf_FieldDescriptorProto()
    oneofField.name = "text"
    oneofField.number = 1
    oneofField.type = .string
    oneofField.label = .optional
    oneofField.oneofIndex = 0
    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Msg"
    msgProto.field = [oneofField]
    msgProto.oneofDecl = [oneof]
    let result = try bridge.fromProtobufDescriptor(msgProto)
    XCTAssertEqual(result.oneofDecls.count, 1)
    XCTAssertEqual(result.oneofDecls[0].name, "payload")
  }

  func test_fromProtobufDescriptor_extensionRange_preservedCorrectly() throws {
    var rangeProto = Google_Protobuf_DescriptorProto.ExtensionRange()
    rangeProto.start = 100
    rangeProto.end = 200
    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Msg"
    msgProto.extensionRange = [rangeProto]
    let result = try bridge.fromProtobufDescriptor(msgProto)
    XCTAssertEqual(result.extensionRanges.count, 1)
    XCTAssertEqual(result.extensionRanges[0].start, 100)
    XCTAssertEqual(result.extensionRanges[0].end, 200)
  }

  func test_fromProtobufDescriptor_proto2DefaultValues_preservedCorrectly() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "name"
    fieldProto.number = 1
    fieldProto.type = .string
    fieldProto.label = .optional
    fieldProto.defaultValue = "hello"
    let msgProto = makeMessageProto(name: "Msg", fields: [fieldProto])
    let fd = FileDescriptor(name: "t.proto", package: "pkg", syntax: "proto2")
    let result = try bridge.fromProtobufDescriptor(msgProto, parent: fd)
    XCTAssertNotNil(result.field(named: "name")?.defaultValue)
  }

  func test_fromProtobufFileDescriptor_fileEnumsAtTopLevel_qualifiedByPackage() throws {
    let topEnum = makeEnumProto(name: "TopLevel", values: [("NONE", 0)])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", enums: [topEnum])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.enums["TopLevel"]?.fullName, "pkg.TopLevel")
  }

  func test_fromProtobufFileDescriptor_services_convertedCorrectly() throws {
    var methodProto = Google_Protobuf_MethodDescriptorProto()
    methodProto.name = "GetFoo"
    methodProto.inputType = ".pkg.FooRequest"
    methodProto.outputType = ".pkg.FooResponse"
    var serviceProto = Google_Protobuf_ServiceDescriptorProto()
    serviceProto.name = "FooService"
    serviceProto.method = [methodProto]
    var fileProto = Google_Protobuf_FileDescriptorProto()
    fileProto.name = "t.proto"
    fileProto.package = "pkg"
    fileProto.syntax = "proto3"
    fileProto.service = [serviceProto]
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertNotNil(fd.services["FooService"])
    XCTAssertEqual(fd.services["FooService"]?.allMethods().first?.name, "GetFoo")
  }

  func test_fromProtobufFileDescriptor_dependencies_preservedCorrectly() throws {
    var fileProto = Google_Protobuf_FileDescriptorProto()
    fileProto.name = "t.proto"
    fileProto.package = "pkg"
    fileProto.syntax = "proto3"
    fileProto.dependency = ["google/protobuf/timestamp.proto", "other.proto"]
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.dependencies, ["google/protobuf/timestamp.proto", "other.proto"])
  }

  func test_toProtobufDescriptor_roundTrip_flatMessage_identicalFields() throws {
    let field = makeFieldProto(name: "name", number: 1, type: .string)
    let msgProto = makeMessageProto(name: "Person", fields: [field])
    let fd = FileDescriptor(name: "t.proto", package: "pkg")
    let descriptor = try bridge.fromProtobufDescriptor(msgProto, parent: fd)
    let backToProto = try bridge.toProtobufDescriptor(from: descriptor)
    XCTAssertEqual(backToProto.name, "Person")
    XCTAssertEqual(backToProto.field.count, 1)
    XCTAssertEqual(backToProto.field[0].name, "name")
  }

  func test_toProtobufDescriptor_roundTrip_messageWithNestedMessage_identicalStructure() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let parent = fd.messages["Parent"]!
    let backToProto = try bridge.toProtobufDescriptor(from: parent)
    XCTAssertEqual(backToProto.name, "Parent")
    XCTAssertEqual(backToProto.nestedType.count, 1)
    XCTAssertEqual(backToProto.nestedType[0].name, "Child")
  }

  func test_toProtobufDescriptor_roundTrip_messageWithNestedEnum_identicalValues() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let parent = fd.messages["Parent"]!
    let backToProto = try bridge.toProtobufDescriptor(from: parent)
    XCTAssertEqual(backToProto.enumType.count, 1)
    XCTAssertEqual(backToProto.enumType[0].name, "Status")
    XCTAssertEqual(backToProto.enumType[0].value.count, 2)
  }

  func test_fromProtobufDescriptor_jsonName_preservedFromProto() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "first_name"
    fieldProto.number = 1
    fieldProto.type = .string
    fieldProto.label = .optional
    fieldProto.jsonName = "firstName"
    let msgProto = makeMessageProto(name: "Msg", fields: [fieldProto])
    let result = try bridge.fromProtobufDescriptor(msgProto)
    XCTAssertEqual(result.field(named: "first_name")?.jsonName, "firstName")
  }
}
