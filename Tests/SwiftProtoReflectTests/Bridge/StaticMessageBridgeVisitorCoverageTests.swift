import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class StaticMessageBridgeVisitorCoverageTests: XCTestCase {

  private let bridge = StaticMessageBridge()

  // MARK: - Singular Scalar Types via Google Wrapper Types

  func test_toDynamic_doubleValue_fieldExtractedAsDouble() throws {
    var msg = Google_Protobuf_DoubleValue()
    msg.value = 3.14
    let dynamic = try bridge.toDynamicMessage(from: msg)
    let field = dynamic.descriptor.field(number: 1)
    XCTAssertNotNil(field)
    XCTAssertEqual(field?.type, .double)
  }

  func test_toDynamic_floatValue_fieldExtractedAsFloat() throws {
    var msg = Google_Protobuf_FloatValue()
    msg.value = 2.5
    let dynamic = try bridge.toDynamicMessage(from: msg)
    let field = dynamic.descriptor.field(number: 1)
    XCTAssertNotNil(field)
    XCTAssertEqual(field?.type, .float)
  }

  func test_toDynamic_int64Value_fieldExtractedAsInt64() throws {
    var msg = Google_Protobuf_Int64Value()
    msg.value = 123_456_789
    let dynamic = try bridge.toDynamicMessage(from: msg)
    let field = dynamic.descriptor.field(number: 1)
    XCTAssertNotNil(field)
    XCTAssertEqual(field?.type, .int64)
  }

  func test_toDynamic_uint64Value_fieldExtractedAsUInt64() throws {
    var msg = Google_Protobuf_UInt64Value()
    msg.value = 999_999_999
    let dynamic = try bridge.toDynamicMessage(from: msg)
    let field = dynamic.descriptor.field(number: 1)
    XCTAssertNotNil(field)
    XCTAssertEqual(field?.type, .uint64)
  }

  func test_toDynamic_uint32Value_fieldExtractedAsUInt32() throws {
    var msg = Google_Protobuf_UInt32Value()
    msg.value = 42
    let dynamic = try bridge.toDynamicMessage(from: msg)
    let field = dynamic.descriptor.field(number: 1)
    XCTAssertNotNil(field)
    XCTAssertEqual(field?.type, .uint32)
  }

  func test_toDynamic_boolValue_fieldExtractedAsBool() throws {
    var msg = Google_Protobuf_BoolValue()
    msg.value = true
    let dynamic = try bridge.toDynamicMessage(from: msg)
    let field = dynamic.descriptor.field(number: 1)
    XCTAssertNotNil(field)
    XCTAssertEqual(field?.type, .bool)
  }

  func test_toDynamic_bytesValue_fieldExtractedAsBytes() throws {
    var msg = Google_Protobuf_BytesValue()
    msg.value = Data([0x01, 0x02, 0x03])
    let dynamic = try bridge.toDynamicMessage(from: msg)
    let field = dynamic.descriptor.field(number: 1)
    XCTAssertNotNil(field)
    XCTAssertEqual(field?.type, .bytes)
  }

  func test_visitor_singularMessageField_viaTraverse_recorded() throws {
    var msg = Google_Protobuf_FieldDescriptorProto()
    msg.name = "test"
    msg.options = Google_Protobuf_FieldOptions()
    var visitor = FieldExtractorVisitor()
    try msg.traverse(visitor: &visitor)
    let messageFields = visitor.extractedFields.filter { $0.type == .message }
    XCTAssertFalse(messageFields.isEmpty)
  }

  // MARK: - Repeated Fields via Google Types

  func test_toDynamic_repeatedStringField_extractedAsRepeated() throws {
    var msg = Google_Protobuf_FileDescriptorProto()
    msg.name = "test.proto"
    msg.dependency = ["dep1.proto", "dep2.proto"]
    let dynamic = try bridge.toDynamicMessage(from: msg)
    let depField = dynamic.descriptor.field(named: "dependency")
    XCTAssertNotNil(depField)
    XCTAssertEqual(depField?.type, .string)
    XCTAssertEqual(depField?.isRepeated, true)
  }

  func test_toDynamic_repeatedInt32Field_extractedAsRepeated() throws {
    var msg = Google_Protobuf_FileDescriptorProto()
    msg.name = "test.proto"
    msg.publicDependency = [0, 1]
    let dynamic = try bridge.toDynamicMessage(from: msg)
    let field = dynamic.descriptor.field(named: "publicDependency")
    XCTAssertNotNil(field)
    XCTAssertEqual(field?.type, .int32)
    XCTAssertEqual(field?.isRepeated, true)
  }

  func test_visitor_repeatedMessageField_viaTraverse_recorded() throws {
    var msg = Google_Protobuf_FileDescriptorProto()
    msg.name = "test.proto"
    var nested = Google_Protobuf_DescriptorProto()
    nested.name = "Nested"
    msg.messageType = [nested]
    var visitor = FieldExtractorVisitor()
    try msg.traverse(visitor: &visitor)
    let repeatedMsgFields = visitor.extractedFields.filter { $0.type == .message && $0.isRepeated }
    XCTAssertFalse(repeatedMsgFields.isEmpty)
  }

  // MARK: - Map Field via Google_Protobuf_Struct (traverse only)

  func test_visitor_mapField_viaStructTraverse_recorded() throws {
    var msg = Google_Protobuf_Struct()
    msg.fields["key1"] = Google_Protobuf_Value(stringValue: "hello")
    var visitor = FieldExtractorVisitor()
    try msg.traverse(visitor: &visitor)
    XCTAssertFalse(visitor.extractedFields.isEmpty)
  }

  // MARK: - Direct FieldExtractorVisitor Tests (Singular)

  func test_visitor_singularSInt32_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularSInt32Field(value: -10, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields.count, 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .sint32)
    XCTAssertFalse(visitor.extractedFields[0].isRepeated)
  }

  func test_visitor_singularSInt64_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularSInt64Field(value: -100, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .sint64)
  }

  func test_visitor_singularFixed32_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularFixed32Field(value: 42, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .fixed32)
  }

  func test_visitor_singularFixed64_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularFixed64Field(value: 42, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .fixed64)
  }

  func test_visitor_singularSFixed32_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularSFixed32Field(value: -42, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .sfixed32)
  }

  func test_visitor_singularSFixed64_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularSFixed64Field(value: -42, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .sfixed64)
  }

  func test_visitor_singularDouble_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularDoubleField(value: 3.14, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .double)
  }

  func test_visitor_singularInt64_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularInt64Field(value: 42, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .int64)
  }

  func test_visitor_singularUInt64_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularUInt64Field(value: 42, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .uint64)
  }

  func test_visitor_singularBool_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularBoolField(value: true, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .bool)
  }

  func test_visitor_singularBytes_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularBytesField(value: Data([0x01]), fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .bytes)
  }

  func test_visitor_singularFloat_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularFloatField(value: 1.5, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .float)
  }

  func test_visitor_singularUInt32_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularUInt32Field(value: 42, fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .uint32)
  }

  func test_visitor_singularMessage_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularMessageField(value: Google_Protobuf_Empty(), fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .message)
    XCTAssertEqual(visitor.extractedFields[0].typeName, "google.protobuf.Empty")
  }

  func test_visitor_singularGroup_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularGroupField(value: Google_Protobuf_Empty(), fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .group)
    XCTAssertEqual(visitor.extractedFields[0].typeName, "google.protobuf.Empty")
  }

  // MARK: - Direct FieldExtractorVisitor Tests (Repeated)

  func test_visitor_repeatedScalarFields_allTypesRecorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitRepeatedDoubleField(value: [1.0], fieldNumber: 1)
    try visitor.visitRepeatedInt64Field(value: [1], fieldNumber: 2)
    try visitor.visitRepeatedUInt64Field(value: [1], fieldNumber: 3)
    try visitor.visitRepeatedBoolField(value: [true], fieldNumber: 4)
    try visitor.visitRepeatedStringField(value: ["a"], fieldNumber: 5)
    try visitor.visitRepeatedBytesField(value: [Data([0x01])], fieldNumber: 6)
    try visitor.visitRepeatedFloatField(value: [1.0], fieldNumber: 7)
    try visitor.visitRepeatedInt32Field(value: [1], fieldNumber: 8)
    try visitor.visitRepeatedUInt32Field(value: [1], fieldNumber: 9)
    try visitor.visitRepeatedSInt32Field(value: [-1], fieldNumber: 10)
    try visitor.visitRepeatedSInt64Field(value: [-1], fieldNumber: 11)
    try visitor.visitRepeatedFixed32Field(value: [1], fieldNumber: 12)
    try visitor.visitRepeatedFixed64Field(value: [1], fieldNumber: 13)
    try visitor.visitRepeatedSFixed32Field(value: [-1], fieldNumber: 14)
    try visitor.visitRepeatedSFixed64Field(value: [-1], fieldNumber: 15)

    XCTAssertEqual(visitor.extractedFields.count, 15)
    let expectedTypes: [SwiftProtoReflect.FieldType] = [
      .double, .int64, .uint64, .bool, .string, .bytes, .float,
      .int32, .uint32, .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
    ]
    for (index, expectedType) in expectedTypes.enumerated() {
      XCTAssertEqual(visitor.extractedFields[index].type, expectedType)
      XCTAssertTrue(visitor.extractedFields[index].isRepeated)
    }
  }

  func test_visitor_repeatedEnum_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitRepeatedEnumField(
      value: [Google_Protobuf_NullValue.nullValue],
      fieldNumber: 1
    )
    XCTAssertEqual(visitor.extractedFields[0].type, .enum)
    XCTAssertTrue(visitor.extractedFields[0].isRepeated)
  }

  func test_visitor_repeatedMessage_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitRepeatedMessageField(
      value: [Google_Protobuf_Empty()],
      fieldNumber: 1
    )
    XCTAssertEqual(visitor.extractedFields[0].type, .message)
    XCTAssertTrue(visitor.extractedFields[0].isRepeated)
    XCTAssertEqual(visitor.extractedFields[0].typeName, "google.protobuf.Empty")
  }

  func test_visitor_repeatedGroup_recorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitRepeatedGroupField(
      value: [Google_Protobuf_Empty()],
      fieldNumber: 1
    )
    XCTAssertEqual(visitor.extractedFields[0].type, .group)
    XCTAssertTrue(visitor.extractedFields[0].isRepeated)
  }

  // MARK: - visitUnknown and Deduplication

  func test_visitor_visitUnknown_doesNotRecordFields() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitUnknown(bytes: Data([0x01, 0x02]))
    XCTAssertEqual(visitor.extractedFields.count, 0)
  }

  func test_visitor_duplicateFieldNumber_onlyFirstRecorded() throws {
    var visitor = FieldExtractorVisitor()
    try visitor.visitSingularInt32Field(value: 1, fieldNumber: 1)
    try visitor.visitSingularStringField(value: "x", fieldNumber: 1)
    XCTAssertEqual(visitor.extractedFields.count, 1)
    XCTAssertEqual(visitor.extractedFields[0].type, .int32)
  }

  // MARK: - isCompatible False Paths

  func test_isCompatible_staticWithIncompatibleDescriptor_returnsFalse() {
    var descriptor = MessageDescriptor(name: "Test", fullName: "Test")
    descriptor.addField(
      FieldDescriptor(
        name: "nested",
        number: 1,
        type: .message,
        typeName: "Nonexistent"
      )
    )

    var msg = Google_Protobuf_DescriptorProto()
    msg.name = "Hello"

    XCTAssertFalse(bridge.isCompatible(staticMessage: msg, with: descriptor))
  }

}
