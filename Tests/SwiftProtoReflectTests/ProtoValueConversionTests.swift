import XCTest

@testable import SwiftProtoReflect

class ProtoValueConversionTests: XCTestCase {

  // MARK: - ConvertTo Tests

  func testConvertToInt() {
    let int32Descriptor = ProtoFieldDescriptor(
      name: "int32_field",
      number: 1,
      type: .int32,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.intValue(42).convertTo(fieldDescriptor: int32Descriptor)?.getInt(), 42)
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.uintValue(42).convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.stringValue("42").convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.floatValue(42.5).convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.doubleValue(42.5).convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01])).convertTo(fieldDescriptor: int32Descriptor))
  }

  func testConvertToUInt() {
    let uint32Descriptor = ProtoFieldDescriptor(
      name: "uint32_field",
      number: 1,
      type: .uint32,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.uintValue(42).convertTo(fieldDescriptor: uint32Descriptor)?.getUInt(), 42)
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.stringValue("42").convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.floatValue(42.5).convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.doubleValue(42.5).convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01])).convertTo(fieldDescriptor: uint32Descriptor))
  }

  func testConvertToFloat() {
    let floatDescriptor = ProtoFieldDescriptor(
      name: "float_field",
      number: 1,
      type: .float,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.floatValue(42.5).convertTo(fieldDescriptor: floatDescriptor)?.getFloat(), 42.5)
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.doubleValue(42.5).convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.uintValue(42).convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.stringValue("42.5").convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01])).convertTo(fieldDescriptor: floatDescriptor))
  }

  func testConvertToDouble() {
    let doubleDescriptor = ProtoFieldDescriptor(
      name: "double_field",
      number: 1,
      type: .double,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.doubleValue(42.5).convertTo(fieldDescriptor: doubleDescriptor)?.getDouble(), 42.5)
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.floatValue(42.5).convertTo(fieldDescriptor: doubleDescriptor))
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: doubleDescriptor))
    XCTAssertNil(ProtoValue.uintValue(42).convertTo(fieldDescriptor: doubleDescriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: doubleDescriptor))
    XCTAssertNil(ProtoValue.stringValue("42.5").convertTo(fieldDescriptor: doubleDescriptor))
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01])).convertTo(fieldDescriptor: doubleDescriptor))
  }

  func testConvertToBool() {
    let boolDescriptor = ProtoFieldDescriptor(
      name: "bool_field",
      number: 1,
      type: .bool,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.boolValue(true).convertTo(fieldDescriptor: boolDescriptor)?.getBool(), true)
    XCTAssertEqual(ProtoValue.boolValue(false).convertTo(fieldDescriptor: boolDescriptor)?.getBool(), false)
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(1).convertTo(fieldDescriptor: boolDescriptor))
    XCTAssertNil(ProtoValue.uintValue(1).convertTo(fieldDescriptor: boolDescriptor))
    XCTAssertNil(ProtoValue.floatValue(1.0).convertTo(fieldDescriptor: boolDescriptor))
    XCTAssertNil(ProtoValue.doubleValue(1.0).convertTo(fieldDescriptor: boolDescriptor))
    XCTAssertNil(ProtoValue.stringValue("true").convertTo(fieldDescriptor: boolDescriptor))
  }

  func testConvertToString() {
    let stringDescriptor = ProtoFieldDescriptor(
      name: "string_field",
      number: 1,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.stringValue("Hello").convertTo(fieldDescriptor: stringDescriptor)?.getString(), "Hello")
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.uintValue(100).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.floatValue(3.14).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.doubleValue(2.71828).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01, 0x02, 0x03])).convertTo(fieldDescriptor: stringDescriptor))
  }

  func testConvertToBytes() {
    let bytesDescriptor = ProtoFieldDescriptor(
      name: "bytes_field",
      number: 1,
      type: .bytes,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.bytesValue(Data([0x01, 0x02, 0x03])).convertTo(fieldDescriptor: bytesDescriptor)?.getBytes(), Data([0x01, 0x02, 0x03]))
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.stringValue("Hello").convertTo(fieldDescriptor: bytesDescriptor))
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: bytesDescriptor))
    XCTAssertNil(ProtoValue.uintValue(42).convertTo(fieldDescriptor: bytesDescriptor))
    XCTAssertNil(ProtoValue.floatValue(42.5).convertTo(fieldDescriptor: bytesDescriptor))
    XCTAssertNil(ProtoValue.doubleValue(42.5).convertTo(fieldDescriptor: bytesDescriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: bytesDescriptor))
  }

  func testConvertToEnum() {
    let enumDescriptor = ProtoEnumDescriptor(
      name: "TestEnum",
      values: [
        ProtoEnumValueDescriptor(name: "TEST_VALUE", number: 1)
      ]
    )
    let enumFieldDescriptor = ProtoFieldDescriptor(
      name: "enum_field",
      number: 1,
      type: .enum(enumDescriptor),
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertNotNil(ProtoValue.enumValue(name: "TEST_VALUE", number: 1, enumDescriptor: enumDescriptor)
      .convertTo(fieldDescriptor: enumFieldDescriptor))
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(1).convertTo(fieldDescriptor: enumFieldDescriptor))
    XCTAssertNil(ProtoValue.stringValue("TEST_VALUE").convertTo(fieldDescriptor: enumFieldDescriptor))
  }

  func testConvertToMap() {
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "map_field",
      number: 1,
      type: .message(nil),
      isRepeated: false,
      isMap: true
    )
    
    // Valid conversions - protoc allows same type
    let mapValue = ProtoValue.mapValue(["key1": .intValue(1), "key2": .intValue(2)])
    XCTAssertNotNil(mapValue.convertTo(fieldDescriptor: mapFieldDescriptor))
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: mapFieldDescriptor))
    XCTAssertNil(ProtoValue.stringValue("{}").convertTo(fieldDescriptor: mapFieldDescriptor))
  }

  func testConvertToMessage() {
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [],
      enums: [],
      nestedMessages: []
    )
    let messageFieldDescriptor = ProtoFieldDescriptor(
      name: "message_field",
      number: 1,
      type: .message(messageDescriptor),
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    XCTAssertNotNil(ProtoValue.messageValue(message).convertTo(fieldDescriptor: messageFieldDescriptor))
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.stringValue("{}").convertTo(fieldDescriptor: messageFieldDescriptor))
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: messageFieldDescriptor))
  }

  func testConvertToRepeated() {
    // Only same type conversion is allowed
    let values = [ProtoValue.intValue(1), ProtoValue.intValue(2), ProtoValue.intValue(3)]
    let repeatedFieldDescriptor = ProtoFieldDescriptor(
      name: "repeated_int32",
      number: 1,
      type: .int32,
      isRepeated: true,
      isMap: false
    )
    XCTAssertNotNil(ProtoValue.repeatedValue(values).convertTo(fieldDescriptor: repeatedFieldDescriptor))
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: repeatedFieldDescriptor))
    XCTAssertNil(ProtoValue.stringValue("[1, 2, 3]").convertTo(fieldDescriptor: repeatedFieldDescriptor))
  }

  // MARK: - ToSwiftValue Tests

  func testToSwiftValue() {
    // Test primitive types
    XCTAssertEqual(ProtoValue.intValue(42).toSwiftValue() as? Int, 42)
    XCTAssertEqual(ProtoValue.uintValue(42).toSwiftValue() as? UInt, 42)
    XCTAssertEqual(ProtoValue.floatValue(42.5).toSwiftValue() as? Float, 42.5)
    XCTAssertEqual(ProtoValue.doubleValue(42.5).toSwiftValue() as? Double, 42.5)
    XCTAssertEqual(ProtoValue.boolValue(true).toSwiftValue() as? Bool, true)
    XCTAssertEqual(ProtoValue.stringValue("hello").toSwiftValue() as? String, "hello")

    // Test bytes
    let data = Data([0x01, 0x02, 0x03])
    XCTAssertEqual(ProtoValue.bytesValue(data).toSwiftValue() as? Data, data)

    // Test repeated values
    let repeatedValue = ProtoValue.repeatedValue([.intValue(1), .intValue(2), .intValue(3)])
    let swiftArray = repeatedValue.toSwiftValue() as? [Any]
    XCTAssertNotNil(swiftArray)
    XCTAssertEqual(swiftArray?.count, 3)
    XCTAssertEqual(swiftArray?[0] as? Int, 1)
    XCTAssertEqual(swiftArray?[1] as? Int, 2)
    XCTAssertEqual(swiftArray?[2] as? Int, 3)

    // Test map values
    let mapValue = ProtoValue.mapValue(["key1": .intValue(1), "key2": .stringValue("value2")])
    let swiftMap = mapValue.toSwiftValue() as? [String: Any]
    XCTAssertNotNil(swiftMap)
    XCTAssertEqual(swiftMap?.count, 2)
    XCTAssertEqual(swiftMap?["key1"] as? Int, 1)
    XCTAssertEqual(swiftMap?["key2"] as? String, "value2")
  }

  // MARK: - From SwiftValue Tests

  func testFromSwiftValueInt() {
    // Valid conversions - protoc allows Int, Int32, Int64
    XCTAssertEqual(ProtoValue.from(swiftValue: Int(42), targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: Int32(42), targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: Int64(42), targetType: .int32)?.getInt(), 42)
    
    // Invalid conversions - protoc doesn't allow other types
    XCTAssertNil(ProtoValue.from(swiftValue: Float(42.0), targetType: .int32))
    XCTAssertNil(ProtoValue.from(swiftValue: Double(42.0), targetType: .int32))
    XCTAssertNil(ProtoValue.from(swiftValue: Bool(true), targetType: .int32))
    XCTAssertNil(ProtoValue.from(swiftValue: String("42"), targetType: .int32))
    XCTAssertNil(ProtoValue.from(swiftValue: Data([0x01]), targetType: .int32))
  }

  func testFromSwiftValueUInt() {
    // Valid conversions - protoc allows UInt, UInt32, UInt64
    XCTAssertEqual(ProtoValue.from(swiftValue: UInt(42), targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: UInt32(42), targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: UInt64(42), targetType: .uint32)?.getUInt(), 42)
    
    // Invalid conversions - protoc doesn't allow other types
    XCTAssertNil(ProtoValue.from(swiftValue: Int(-42), targetType: .uint32))
    XCTAssertNil(ProtoValue.from(swiftValue: Float(42.0), targetType: .uint32))
    XCTAssertNil(ProtoValue.from(swiftValue: Double(42.0), targetType: .uint32))
    XCTAssertNil(ProtoValue.from(swiftValue: Bool(true), targetType: .uint32))
    XCTAssertNil(ProtoValue.from(swiftValue: String("42"), targetType: .uint32))
    XCTAssertNil(ProtoValue.from(swiftValue: Data([0x01]), targetType: .uint32))
  }

  func testFromSwiftValueFloat() {
    // Valid conversions - protoc allows Float, Double
    XCTAssertEqual(ProtoValue.from(swiftValue: Float(3.14), targetType: .float)?.getFloat(), 3.14)
    XCTAssertEqual(ProtoValue.from(swiftValue: Double(3.14), targetType: .float)?.getFloat(), 3.14)
    
    // Invalid conversions - protoc doesn't allow other types
    XCTAssertNil(ProtoValue.from(swiftValue: Int(42), targetType: .float))
    XCTAssertNil(ProtoValue.from(swiftValue: UInt(42), targetType: .float))
    XCTAssertNil(ProtoValue.from(swiftValue: Bool(true), targetType: .float))
    XCTAssertNil(ProtoValue.from(swiftValue: String("3.14"), targetType: .float))
    XCTAssertNil(ProtoValue.from(swiftValue: Data([0x01]), targetType: .float))
  }

  func testFromSwiftValueBool() {
    // Valid conversions - protoc only allows Bool
    XCTAssertEqual(ProtoValue.from(swiftValue: Bool(true), targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.from(swiftValue: Bool(false), targetType: .bool)?.getBool(), false)
    
    // Invalid conversions - protoc doesn't allow other types
    XCTAssertNil(ProtoValue.from(swiftValue: Int(1), targetType: .bool))
    XCTAssertNil(ProtoValue.from(swiftValue: UInt(1), targetType: .bool))
    XCTAssertNil(ProtoValue.from(swiftValue: Float(1.0), targetType: .bool))
    XCTAssertNil(ProtoValue.from(swiftValue: Double(1.0), targetType: .bool))
    XCTAssertNil(ProtoValue.from(swiftValue: String("true"), targetType: .bool))
    XCTAssertNil(ProtoValue.from(swiftValue: Data([0x01]), targetType: .bool))
  }

  // MARK: - Mixed Type Conversion Tests

  func testMixedTypeConversion() {
    let values: [Any] = [
      Int(42),
      UInt(100),
      Float(3.14),
      Double(2.71828),
      Bool(true),
      String("Hello"),
      Data([0x01, 0x02, 0x03])
    ]
    
    // Convert to int32 - protoc only allows Int, Int32, Int64
    let int32Values = values.compactMap { ProtoValue.from(swiftValue: $0, targetType: .int32) }
    XCTAssertEqual(int32Values.count, 1) // Only Int(42) should convert
    
    // Convert to string - protoc allows any type to string
    let stringValues = values.compactMap { ProtoValue.from(swiftValue: $0, targetType: .string) }
    XCTAssertEqual(stringValues.count, 7) // All values should convert to string
  }

  // MARK: - Helper Classes

  class CustomStringObject: CustomStringConvertible {
    var description: String {
      return "CustomStringObject"
    }
  }

  func testEdgeCases() {
    let maxInt = Int.max
    let minInt = Int.min
    let maxUInt = UInt.max
    let minUInt = UInt.min
    
    let int32Descriptor = ProtoFieldDescriptor(
      name: "int32_field",
      number: 1,
      type: .int32,
      isRepeated: false,
      isMap: false
    )
    let uint32Descriptor = ProtoFieldDescriptor(
      name: "uint32_field",
      number: 2,
      type: .uint32,
      isRepeated: false,
      isMap: false
    )
    let floatDescriptor = ProtoFieldDescriptor(
      name: "float_field",
      number: 3,
      type: .float,
      isRepeated: false,
      isMap: false
    )
    let stringDescriptor = ProtoFieldDescriptor(
      name: "string_field",
      number: 4,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    let bytesDescriptor = ProtoFieldDescriptor(
      name: "bytes_field",
      number: 5,
      type: .bytes,
      isRepeated: false,
      isMap: false
    )
    
    // Test numeric overflow/underflow
    XCTAssertEqual(ProtoValue.intValue(maxInt).convertTo(fieldDescriptor: int32Descriptor)?.getInt(), maxInt)
    XCTAssertEqual(ProtoValue.intValue(minInt).convertTo(fieldDescriptor: int32Descriptor)?.getInt(), minInt)
    XCTAssertEqual(ProtoValue.uintValue(maxUInt).convertTo(fieldDescriptor: uint32Descriptor)?.getUInt(), maxUInt)
    XCTAssertEqual(ProtoValue.uintValue(minUInt).convertTo(fieldDescriptor: uint32Descriptor)?.getUInt(), minUInt)
    
    // Test string number formats - no implicit conversions allowed
    XCTAssertNil(ProtoValue.stringValue("42").convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.stringValue("invalid").convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.stringValue("42.5").convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.stringValue("4.25e1").convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.stringValue("0x2A").convertTo(fieldDescriptor: int32Descriptor))
    
    // Test base64 encoding/decoding - no implicit conversions allowed
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01, 0x02, 0x03])).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.stringValue("not base64").convertTo(fieldDescriptor: bytesDescriptor))
  }
}
