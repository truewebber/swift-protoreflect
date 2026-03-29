import Foundation
import XCTest

@testable import SwiftProtoReflect

final class WellKnownTypeCoverageTests: XCTestCase {

  // MARK: - WrapperHandler validate() methods

  func test_int32ValueHandler_validate_correctType_returnsTrue() {
    XCTAssertTrue(Int32ValueHandler.validate(Int32(42)))
  }

  func test_int32ValueHandler_validate_wrongType_returnsFalse() {
    XCTAssertFalse(Int32ValueHandler.validate("not_int"))
  }

  func test_int64ValueHandler_validate_correctType_returnsTrue() {
    XCTAssertTrue(Int64ValueHandler.validate(Int64(42)))
  }

  func test_int64ValueHandler_validate_wrongType_returnsFalse() {
    XCTAssertFalse(Int64ValueHandler.validate("not_int"))
  }

  func test_uint32ValueHandler_validate_correctType_returnsTrue() {
    XCTAssertTrue(UInt32ValueHandler.validate(UInt32(42)))
  }

  func test_uint32ValueHandler_validate_wrongType_returnsFalse() {
    XCTAssertFalse(UInt32ValueHandler.validate("not_uint"))
  }

  func test_uint64ValueHandler_validate_correctType_returnsTrue() {
    XCTAssertTrue(UInt64ValueHandler.validate(UInt64(42)))
  }

  func test_uint64ValueHandler_validate_wrongType_returnsFalse() {
    XCTAssertFalse(UInt64ValueHandler.validate("not_uint"))
  }

  func test_boolValueHandler_validate_correctType_returnsTrue() {
    XCTAssertTrue(BoolValueHandler.validate(true))
  }

  func test_boolValueHandler_validate_wrongType_returnsFalse() {
    XCTAssertFalse(BoolValueHandler.validate("not_bool"))
  }

  func test_floatValueHandler_validate_correctType_returnsTrue() {
    XCTAssertTrue(FloatValueHandler.validate(Float(1.5)))
  }

  func test_floatValueHandler_validate_wrongType_returnsFalse() {
    XCTAssertFalse(FloatValueHandler.validate("not_float"))
  }

  func test_doubleValueHandler_validate_correctType_returnsTrue() {
    XCTAssertTrue(DoubleValueHandler.validate(Double(3.14)))
  }

  func test_doubleValueHandler_validate_wrongType_returnsFalse() {
    XCTAssertFalse(DoubleValueHandler.validate("not_double"))
  }

  func test_bytesValueHandler_validate_correctType_returnsTrue() {
    XCTAssertTrue(BytesValueHandler.validate(Data([0x01])))
  }

  func test_bytesValueHandler_validate_wrongType_returnsFalse() {
    XCTAssertFalse(BytesValueHandler.validate("not_data"))
  }

  // MARK: - WrapperHandler error paths: missing value field

  func test_int32ValueHandler_createSpecialized_missingValue_throws() throws {
    var desc = MessageDescriptor(name: "Int32Value", fullName: "google.protobuf.Int32Value")
    desc.addField(FieldDescriptor(name: "value", number: 1, type: .int32))
    let msg = DynamicMessage(descriptor: desc)

    XCTAssertThrowsError(try Int32ValueHandler.createSpecialized(from: msg))
  }

  // MARK: - WrapperHandler error paths: wrong specialized type in createDynamic

  func test_int32ValueHandler_createDynamic_wrongType_throws() throws {
    XCTAssertThrowsError(try Int32ValueHandler.createDynamic(from: "not_int"))
  }

  func test_int64ValueHandler_createDynamic_wrongType_throws() throws {
    XCTAssertThrowsError(try Int64ValueHandler.createDynamic(from: "not_int"))
  }

  func test_uint32ValueHandler_createDynamic_wrongType_throws() throws {
    XCTAssertThrowsError(try UInt32ValueHandler.createDynamic(from: "not_uint"))
  }

  func test_uint64ValueHandler_createDynamic_wrongType_throws() throws {
    XCTAssertThrowsError(try UInt64ValueHandler.createDynamic(from: "not_uint"))
  }

  func test_boolValueHandler_createDynamic_wrongType_throws() throws {
    XCTAssertThrowsError(try BoolValueHandler.createDynamic(from: "not_bool"))
  }

  func test_floatValueHandler_createDynamic_wrongType_throws() throws {
    XCTAssertThrowsError(try FloatValueHandler.createDynamic(from: "not_float"))
  }

  func test_doubleValueHandler_createDynamic_wrongType_throws() throws {
    XCTAssertThrowsError(try DoubleValueHandler.createDynamic(from: "not_double"))
  }

  func test_bytesValueHandler_createDynamic_wrongType_throws() throws {
    XCTAssertThrowsError(try BytesValueHandler.createDynamic(from: "not_data"))
  }

  // MARK: - ListValueHandler error paths

  func test_listValueHandler_createSpecialized_wrongDescriptor_throws() throws {
    var desc = MessageDescriptor(name: "Wrong", fullName: "wrong.Type")
    desc.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))
    let msg = DynamicMessage(descriptor: desc)

    XCTAssertThrowsError(try ListValueHandler.createSpecialized(from: msg))
  }

  func test_listValueHandler_createDynamic_wrongType_throws() throws {
    XCTAssertThrowsError(try ListValueHandler.createDynamic(from: "not_array"))
  }

  // MARK: - StructHandler: ValueValue from native Swift types

  func test_structValueValue_fromBool_createsCorrectly() throws {
    let val = try StructHandler.ValueValue(from: true as Any)
    if case .boolValue(let b) = val {
      XCTAssertTrue(b)
    }
    else {
      XCTFail("Expected boolValue")
    }
  }

  func test_structValueValue_fromString_createsCorrectly() throws {
    let val = try StructHandler.ValueValue(from: "hello" as Any)
    if case .stringValue(let s) = val {
      XCTAssertEqual(s, "hello")
    }
    else {
      XCTFail("Expected stringValue")
    }
  }

  func test_structValueValue_fromNSNull_createsNullValue() throws {
    let val = try StructHandler.ValueValue(from: NSNull())
    if case .nullValue = val {
    }
    else {
      XCTFail("Expected nullValue")
    }
  }

  func test_structValueValue_fromUnsupportedType_throws() {
    XCTAssertThrowsError(try StructHandler.ValueValue(from: Date()))
  }

  // MARK: - StructHandler: createSpecialized wrong descriptor

  func test_structHandler_createSpecialized_wrongDescriptor_throws() throws {
    var desc = MessageDescriptor(name: "Wrong", fullName: "wrong.Type")
    desc.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))
    let msg = DynamicMessage(descriptor: desc)

    XCTAssertThrowsError(try StructHandler.createSpecialized(from: msg))
  }

  // MARK: - TimestampHandler: seconds out of range

  func test_timestampHandler_init_secondsOutOfRange_throws() {
    XCTAssertThrowsError(try TimestampHandler.TimestampValue(seconds: 300_000_000_000, nanos: 0))
  }

  func test_timestampHandler_validate_validTimestamp_returnsTrue() throws {
    let valid = try TimestampHandler.TimestampValue(seconds: 1_000_000, nanos: 0)
    XCTAssertTrue(TimestampHandler.validate(valid))
  }

  func test_timestampHandler_validate_wrongType_returnsFalse() {
    XCTAssertFalse(TimestampHandler.validate("not a timestamp"))
  }

  // MARK: - AnyHandler: empty type_url

  func test_anyHandler_createSpecialized_wrongDescriptor_throws() throws {
    var desc = MessageDescriptor(name: "Wrong", fullName: "wrong.Type")
    desc.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))
    let msg = DynamicMessage(descriptor: desc)

    XCTAssertThrowsError(try AnyHandler.createSpecialized(from: msg))
  }
}
