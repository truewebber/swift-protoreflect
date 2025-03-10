import XCTest

@testable import SwiftProtoReflect

class ProtoValueConversionTests: XCTestCase {

  // MARK: - ConvertTo Tests

  func testConvertToInt() {
    // Test converting various types to int
    XCTAssertEqual(ProtoValue.intValue(42).convertTo(targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.uintValue(42).convertTo(targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.floatValue(42.0).convertTo(targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.doubleValue(42.0).convertTo(targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.boolValue(true).convertTo(targetType: .int32)?.getInt(), 1)
    XCTAssertEqual(ProtoValue.stringValue("42").convertTo(targetType: .int32)?.getInt(), 42)

    // Test invalid conversions
    XCTAssertNil(ProtoValue.stringValue("not a number").convertTo(targetType: .int32))
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01])).convertTo(targetType: .int32))
  }

  func testConvertToUInt() {
    // Test converting various types to uint
    XCTAssertEqual(ProtoValue.intValue(42).convertTo(targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.uintValue(42).convertTo(targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.floatValue(42.0).convertTo(targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.doubleValue(42.0).convertTo(targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.boolValue(true).convertTo(targetType: .uint32)?.getUInt(), 1)
    XCTAssertEqual(ProtoValue.stringValue("42").convertTo(targetType: .uint32)?.getUInt(), 42)

    // Test invalid conversions
    // Negative numbers can't be converted to unsigned
    XCTAssertNil(ProtoValue.intValue(-1).convertTo(targetType: .uint32))
    XCTAssertNil(ProtoValue.stringValue("not a number").convertTo(targetType: .uint32))
  }

  func testConvertToFloat() {
    // Test converting various types to float
    XCTAssertEqual(ProtoValue.intValue(42).convertTo(targetType: .float)?.getFloat(), 42.0)
    XCTAssertEqual(ProtoValue.uintValue(42).convertTo(targetType: .float)?.getFloat(), 42.0)
    XCTAssertEqual(ProtoValue.floatValue(42.5).convertTo(targetType: .float)?.getFloat(), 42.5)
    XCTAssertEqual(ProtoValue.doubleValue(42.5).convertTo(targetType: .float)?.getFloat(), 42.5)
    XCTAssertEqual(ProtoValue.boolValue(true).convertTo(targetType: .float)?.getFloat(), 1.0)
    XCTAssertEqual(ProtoValue.stringValue("42.5").convertTo(targetType: .float)?.getFloat(), 42.5)

    // Test invalid conversions
    XCTAssertNil(ProtoValue.stringValue("not a number").convertTo(targetType: .float))
  }

  func testConvertToDouble() {
    // Test converting various types to double
    XCTAssertEqual(ProtoValue.intValue(42).convertTo(targetType: .double)?.getDouble(), 42.0)
    XCTAssertEqual(ProtoValue.uintValue(42).convertTo(targetType: .double)?.getDouble(), 42.0)
    XCTAssertEqual(ProtoValue.floatValue(42.5).convertTo(targetType: .double)?.getDouble(), 42.5)
    XCTAssertEqual(ProtoValue.doubleValue(42.5).convertTo(targetType: .double)?.getDouble(), 42.5)
    XCTAssertEqual(ProtoValue.boolValue(true).convertTo(targetType: .double)?.getDouble(), 1.0)
    XCTAssertEqual(ProtoValue.stringValue("42.5").convertTo(targetType: .double)?.getDouble(), 42.5)

    // Test invalid conversions
    XCTAssertNil(ProtoValue.stringValue("not a number").convertTo(targetType: .double))
  }

  func testConvertToBool() {
    // Test converting various types to bool
    XCTAssertEqual(ProtoValue.intValue(1).convertTo(targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.intValue(0).convertTo(targetType: .bool)?.getBool(), false)
    XCTAssertEqual(ProtoValue.uintValue(1).convertTo(targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.uintValue(0).convertTo(targetType: .bool)?.getBool(), false)
    XCTAssertEqual(ProtoValue.floatValue(1.0).convertTo(targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.floatValue(0.0).convertTo(targetType: .bool)?.getBool(), false)
    XCTAssertEqual(ProtoValue.doubleValue(1.0).convertTo(targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.doubleValue(0.0).convertTo(targetType: .bool)?.getBool(), false)
    XCTAssertEqual(ProtoValue.boolValue(true).convertTo(targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.stringValue("true").convertTo(targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.stringValue("false").convertTo(targetType: .bool)?.getBool(), false)
    XCTAssertEqual(ProtoValue.stringValue("1").convertTo(targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.stringValue("0").convertTo(targetType: .bool)?.getBool(), false)

    // Test invalid conversions
    XCTAssertNil(ProtoValue.stringValue("not a boolean").convertTo(targetType: .bool))
  }

  func testConvertToString() {
    // Test converting various types to string
    XCTAssertEqual(ProtoValue.intValue(42).convertTo(targetType: .string)?.getString(), "42")
    XCTAssertEqual(ProtoValue.uintValue(42).convertTo(targetType: .string)?.getString(), "42")
    XCTAssertEqual(ProtoValue.floatValue(42.5).convertTo(targetType: .string)?.getString(), "42.5")
    XCTAssertEqual(ProtoValue.doubleValue(42.5).convertTo(targetType: .string)?.getString(), "42.5")
    XCTAssertEqual(ProtoValue.boolValue(true).convertTo(targetType: .string)?.getString(), "true")
    XCTAssertEqual(ProtoValue.stringValue("hello").convertTo(targetType: .string)?.getString(), "hello")

    // Test bytes to string conversion (should work if valid UTF-8)
    let helloData = "hello".data(using: .utf8)!
    XCTAssertEqual(ProtoValue.bytesValue(helloData).convertTo(targetType: .string)?.getString(), "aGVsbG8=")
  }

  func testConvertToBytes() {
    // Test string to bytes conversion
    let helloString = "hello"
    let helloData = helloString.data(using: .utf8)!
    XCTAssertEqual(ProtoValue.stringValue(helloString).convertTo(targetType: .bytes)?.getBytes(), helloData)

    // Test bytes to bytes conversion
    XCTAssertEqual(ProtoValue.bytesValue(helloData).convertTo(targetType: .bytes)?.getBytes(), helloData)

    // Test invalid conversions
    XCTAssertNil(ProtoValue.intValue(42).convertTo(targetType: .bytes))
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
    // Test converting various Swift types to int ProtoValue
    XCTAssertEqual(ProtoValue.from(swiftValue: 42, targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: Int32(42), targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: Int64(42), targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: 42.0, targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: Float(42.0), targetType: .int32)?.getInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: true, targetType: .int32)?.getInt(), 1)
    XCTAssertEqual(ProtoValue.from(swiftValue: "42", targetType: .int32)?.getInt(), 42)

    // Test invalid conversions
    XCTAssertNil(ProtoValue.from(swiftValue: "not a number", targetType: .int32))
    XCTAssertNil(ProtoValue.from(swiftValue: Data([0x01]), targetType: .int32))
  }

  func testFromSwiftValueUInt() {
    // Test converting various Swift types to uint ProtoValue
    XCTAssertEqual(ProtoValue.from(swiftValue: UInt(42), targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: UInt32(42), targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: UInt64(42), targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: 42, targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: 42.0, targetType: .uint32)?.getUInt(), 42)
    XCTAssertEqual(ProtoValue.from(swiftValue: Float(42.0), targetType: .uint32)?.getUInt(), 42)
    XCTAssertNil(ProtoValue.from(swiftValue: true, targetType: .uint32))
    XCTAssertEqual(ProtoValue.from(swiftValue: "42", targetType: .uint32)?.getUInt(), 42)

    // Test invalid conversions
    // Negative numbers can't be converted to unsigned
    XCTAssertNil(ProtoValue.from(swiftValue: -1, targetType: .uint32))
    XCTAssertNil(ProtoValue.from(swiftValue: "not a number", targetType: .uint32))
  }

  func testFromSwiftValueFloat() {
    // Test converting various Swift types to float ProtoValue
    XCTAssertEqual(ProtoValue.from(swiftValue: Float(42.5), targetType: .float)?.getFloat(), 42.5)
    XCTAssertEqual(ProtoValue.from(swiftValue: 42.5, targetType: .float)?.getFloat(), 42.5)
    XCTAssertEqual(ProtoValue.from(swiftValue: 42, targetType: .float)?.getFloat(), 42.0)
    XCTAssertEqual(ProtoValue.from(swiftValue: UInt(42), targetType: .float)?.getFloat(), 42.0)
    XCTAssertEqual(ProtoValue.from(swiftValue: true, targetType: .float)?.getFloat(), 1.0)
    XCTAssertEqual(ProtoValue.from(swiftValue: "42.5", targetType: .float)?.getFloat(), 42.5)

    // Test invalid conversions
    XCTAssertNil(ProtoValue.from(swiftValue: "not a number", targetType: .float))
  }

  func testFromSwiftValueBool() {
    // Test converting various Swift types to bool ProtoValue
    XCTAssertEqual(ProtoValue.from(swiftValue: true, targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.from(swiftValue: false, targetType: .bool)?.getBool(), false)
    XCTAssertEqual(ProtoValue.from(swiftValue: 1, targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.from(swiftValue: 0, targetType: .bool)?.getBool(), false)
    XCTAssertEqual(ProtoValue.from(swiftValue: 1.0, targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.from(swiftValue: 0.0, targetType: .bool)?.getBool(), false)
    XCTAssertEqual(ProtoValue.from(swiftValue: "true", targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.from(swiftValue: "false", targetType: .bool)?.getBool(), false)
    XCTAssertEqual(ProtoValue.from(swiftValue: "1", targetType: .bool)?.getBool(), true)
    XCTAssertEqual(ProtoValue.from(swiftValue: "0", targetType: .bool)?.getBool(), false)

    // Test invalid conversions
    XCTAssertNil(ProtoValue.from(swiftValue: "not a boolean", targetType: .bool))
  }

  func testFromSwiftValueString() {
    // Test converting various Swift types to string ProtoValue
    XCTAssertEqual(ProtoValue.from(swiftValue: "hello", targetType: .string)?.getString(), "hello")
    XCTAssertEqual(ProtoValue.from(swiftValue: 42, targetType: .string)?.getString(), "42")
    XCTAssertEqual(ProtoValue.from(swiftValue: 42.5, targetType: .string)?.getString(), "42.5")
    XCTAssertEqual(ProtoValue.from(swiftValue: true, targetType: .string)?.getString(), "true")

    // Test custom object conversion (should use description)
    let customObject = CustomStringObject()
    XCTAssertEqual(ProtoValue.from(swiftValue: customObject, targetType: .string)?.getString(), "CustomStringObject")
  }

  func testFromSwiftValueBytes() {
    // Test converting Data to bytes ProtoValue
    let data = Data([0x01, 0x02, 0x03])
    XCTAssertEqual(ProtoValue.from(swiftValue: data, targetType: .bytes)?.getBytes(), data)

    // Test string to bytes conversion
    let helloString = "hello"
    let helloData = helloString.data(using: .utf8)!
    XCTAssertEqual(ProtoValue.from(swiftValue: helloString, targetType: .bytes)?.getBytes(), helloData)

    // Test invalid conversions
    XCTAssertNil(ProtoValue.from(swiftValue: 42, targetType: .bytes))
  }

  // MARK: - Mixed Type Conversion Tests

  func testMixedTypeConversion() {
    // Test converting mixed types in an array
    let mixedArray: [Any] = [1, "two", 3.0, true, 5]

    // Convert to int
    let intValues = mixedArray.compactMap { ProtoValue.from(swiftValue: $0, targetType: .int32) }
    XCTAssertEqual(intValues.count, 4)  // "two" can't be converted to int
    XCTAssertEqual(intValues[0].getInt(), 1)
    XCTAssertEqual(intValues[1].getInt(), 3)
    XCTAssertEqual(intValues[2].getInt(), 1)  // true -> 1
    XCTAssertEqual(intValues[3].getInt(), 5)

    // Convert to string
    let stringValues = mixedArray.compactMap { ProtoValue.from(swiftValue: $0, targetType: .string) }
    XCTAssertEqual(stringValues.count, 5)  // All can be converted to string
    XCTAssertEqual(stringValues[0].getString(), "1")
    XCTAssertEqual(stringValues[1].getString(), "two")
    XCTAssertEqual(stringValues[2].getString(), "3.0")
    XCTAssertEqual(stringValues[3].getString(), "true")
    XCTAssertEqual(stringValues[4].getString(), "5")
  }

  // MARK: - Helper Classes

  class CustomStringObject: CustomStringConvertible {
    var description: String {
      return "CustomStringObject"
    }
  }
}
