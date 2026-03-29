import Foundation
import XCTest

@testable import SwiftProtoReflect

final class SerializationErrorPathTests: XCTestCase {

  // MARK: - JSONDeserializer: type mismatches and invalid data

  func test_jsonDeserialize_repeatedFieldNotArray_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "items",
        number: 1,
        type: .string,
        isRepeated: true
      )
    )
    let json = #"{"items": "not_an_array"}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(json, using: desc))
  }

  func test_jsonDeserialize_mapFieldNotObject_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "labels",
        number: 1,
        type: .message,
        typeName: "Entry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )
    let json = #"{"labels": [1,2,3]}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(json, using: desc))
  }

  func test_jsonDeserialize_int32OutOfRange_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(FieldDescriptor(name: "val", number: 1, type: .int32))
    let json = #"{"val": 9999999999999}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(json, using: desc))
  }

  func test_jsonDeserialize_invalidBase64ForBytes_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))
    let json = #"{"data": "!!!not-base64!!!"}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(json, using: desc))
  }

  func test_jsonDeserialize_wrongTypeForBoolField_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(FieldDescriptor(name: "flag", number: 1, type: .bool))
    let json = #"{"flag": "yes"}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(json, using: desc))
  }

  func test_jsonDeserialize_wrongTypeForDoubleField_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(FieldDescriptor(name: "val", number: 1, type: .double))
    let json = #"{"val": [1,2,3]}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(json, using: desc))
  }

  func test_jsonDeserialize_wrongTypeForStringField_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    let json = #"{"name": 42}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(json, using: desc))
  }

  func test_jsonDeserialize_invalidMapKeyForUInt64_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "counts",
        number: 1,
        type: .message,
        typeName: "Entry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .uint64),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )
    let json = #"{"counts": {"not_a_number": "v"}}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(json, using: desc))
  }

  func test_jsonDeserialize_unsupportedMapKeyType_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "data",
        number: 1,
        type: .message,
        typeName: "Entry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .int32),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )
    let json = #"{"data": {"not_int": "v"}}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(json, using: desc))
  }

  // MARK: - BinaryDeserializer: truncated/malformed data

  func test_binaryDeserialize_truncatedData_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    let truncatedData = Data([0x0A, 0x10])
    let deserializer = BinaryDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(truncatedData, using: desc))
  }

  func test_binaryDeserialize_messageFieldWithUnknownType_throws() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "nested",
        number: 1,
        type: .message,
        typeName: "UnknownType"
      )
    )
    let data = Data([0x0A, 0x02, 0x08, 0x01])
    let deserializer = BinaryDeserializer()

    XCTAssertThrowsError(try deserializer.deserialize(data, using: desc))
  }
}
