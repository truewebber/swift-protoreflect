import XCTest

@testable import SwiftProtoReflect

class ProtoFieldTypeTests: XCTestCase {

  var testEnumDescriptor: ProtoEnumDescriptor!
  var testMessage: ProtoMessage!

  override func setUp() {
    super.setUp()

    // Create test enum descriptor
    testEnumDescriptor = ProtoEnumDescriptor(
      name: "TestEnum",
      values: [
        ProtoEnumValueDescriptor(name: "RED", number: 0),
        ProtoEnumValueDescriptor(name: "GREEN", number: 1),
        ProtoEnumValueDescriptor(name: "BLUE", number: 2),
      ]
    )

    // Create test message
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [],
      enums: [],
      nestedMessages: []
    )
    testMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
  }

  // MARK: - Type Classification Tests

  func testNumericTypes() {
    // All integer types are numeric
    XCTAssertTrue(ProtoFieldType.int32.isNumericType())
    XCTAssertTrue(ProtoFieldType.int64.isNumericType())
    XCTAssertTrue(ProtoFieldType.uint32.isNumericType())
    XCTAssertTrue(ProtoFieldType.uint64.isNumericType())
    XCTAssertTrue(ProtoFieldType.sint32.isNumericType())
    XCTAssertTrue(ProtoFieldType.sint64.isNumericType())
    XCTAssertTrue(ProtoFieldType.fixed32.isNumericType())
    XCTAssertTrue(ProtoFieldType.fixed64.isNumericType())
    XCTAssertTrue(ProtoFieldType.sfixed32.isNumericType())
    XCTAssertTrue(ProtoFieldType.sfixed64.isNumericType())

    // All floating-point types are numeric
    XCTAssertTrue(ProtoFieldType.float.isNumericType())
    XCTAssertTrue(ProtoFieldType.double.isNumericType())

    // Non-numeric types
    XCTAssertFalse(ProtoFieldType.bool.isNumericType())
    XCTAssertFalse(ProtoFieldType.string.isNumericType())
    XCTAssertFalse(ProtoFieldType.bytes.isNumericType())
    XCTAssertFalse(ProtoFieldType.message(nil).isNumericType())
    XCTAssertFalse(ProtoFieldType.enum(nil).isNumericType())
  }

  func testIntegerTypes() {
    // Test integer types
    XCTAssertTrue(ProtoFieldType.int32.isIntegerType())
    XCTAssertTrue(ProtoFieldType.int64.isIntegerType())
    XCTAssertTrue(ProtoFieldType.uint32.isIntegerType())
    XCTAssertTrue(ProtoFieldType.uint64.isIntegerType())
    XCTAssertTrue(ProtoFieldType.sint32.isIntegerType())
    XCTAssertTrue(ProtoFieldType.sint64.isIntegerType())
    XCTAssertTrue(ProtoFieldType.fixed32.isIntegerType())
    XCTAssertTrue(ProtoFieldType.fixed64.isIntegerType())
    XCTAssertTrue(ProtoFieldType.sfixed32.isIntegerType())
    XCTAssertTrue(ProtoFieldType.sfixed64.isIntegerType())

    // Test non-integer types
    XCTAssertFalse(ProtoFieldType.float.isIntegerType())
    XCTAssertFalse(ProtoFieldType.double.isIntegerType())
    XCTAssertFalse(ProtoFieldType.bool.isIntegerType())
    XCTAssertFalse(ProtoFieldType.string.isIntegerType())
    XCTAssertFalse(ProtoFieldType.bytes.isIntegerType())
    XCTAssertFalse(ProtoFieldType.message(nil).isIntegerType())
    XCTAssertFalse(ProtoFieldType.enum(nil).isIntegerType())
  }

  func testFloatingPointTypes() {
    // Test floating point types
    XCTAssertTrue(ProtoFieldType.float.isFloatingPointType())
    XCTAssertTrue(ProtoFieldType.double.isFloatingPointType())

    // Test non-floating point types
    XCTAssertFalse(ProtoFieldType.int32.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.int64.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.uint32.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.uint64.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.sint32.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.sint64.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.fixed32.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.fixed64.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.sfixed32.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.sfixed64.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.bool.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.string.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.bytes.isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.message(nil).isFloatingPointType())
    XCTAssertFalse(ProtoFieldType.enum(nil).isFloatingPointType())
  }

  func testStringAndBytesTypes() {
    // Test string and bytes types
    XCTAssertTrue(ProtoFieldType.string.isStringOrBytesType())
    XCTAssertTrue(ProtoFieldType.bytes.isStringOrBytesType())

    // Test non-string and non-bytes types
    XCTAssertFalse(ProtoFieldType.int32.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.int64.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.uint32.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.uint64.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.sint32.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.sint64.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.fixed32.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.fixed64.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.sfixed32.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.sfixed64.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.float.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.double.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.bool.isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.message(nil).isStringOrBytesType())
    XCTAssertFalse(ProtoFieldType.enum(nil).isStringOrBytesType())
  }

  // MARK: - String Representation Tests

  func testStringRepresentation() {
    // Test string representation of each type
    XCTAssertEqual(ProtoFieldType.int32.description(), "int32")
    XCTAssertEqual(ProtoFieldType.int64.description(), "int64")
    XCTAssertEqual(ProtoFieldType.uint32.description(), "uint32")
    XCTAssertEqual(ProtoFieldType.uint64.description(), "uint64")
    XCTAssertEqual(ProtoFieldType.sint32.description(), "sint32")
    XCTAssertEqual(ProtoFieldType.sint64.description(), "sint64")
    XCTAssertEqual(ProtoFieldType.fixed32.description(), "fixed32")
    XCTAssertEqual(ProtoFieldType.fixed64.description(), "fixed64")
    XCTAssertEqual(ProtoFieldType.sfixed32.description(), "sfixed32")
    XCTAssertEqual(ProtoFieldType.sfixed64.description(), "sfixed64")
    XCTAssertEqual(ProtoFieldType.float.description(), "float")
    XCTAssertEqual(ProtoFieldType.double.description(), "double")
    XCTAssertEqual(ProtoFieldType.bool.description(), "bool")
    XCTAssertEqual(ProtoFieldType.string.description(), "string")
    XCTAssertEqual(ProtoFieldType.bytes.description(), "bytes")
    XCTAssertEqual(ProtoFieldType.message(nil).description(), "message")
    XCTAssertEqual(ProtoFieldType.enum(nil).description(), "enum")
  }

  // MARK: - Wire Type Mapping Tests

  func testWireTypeMapping() {
    // Test wire type mapping for each type
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .int32), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .int64), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .uint32), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .uint64), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .sint32), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .sint64), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .fixed32), ProtoWireFormat.wireTypeFixed32)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .fixed64), ProtoWireFormat.wireTypeFixed64)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .sfixed32), ProtoWireFormat.wireTypeFixed32)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .sfixed64), ProtoWireFormat.wireTypeFixed64)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .float), ProtoWireFormat.wireTypeFixed32)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .double), ProtoWireFormat.wireTypeFixed64)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .bool), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .string), ProtoWireFormat.wireTypeLengthDelimited)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .bytes), ProtoWireFormat.wireTypeLengthDelimited)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .message(nil)), ProtoWireFormat.wireTypeLengthDelimited)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .enum(nil)), ProtoWireFormat.wireTypeVarint)
  }

  // MARK: - Type Conversion Tests

  func testTypeConversion() {
    // Valid conversions according to protoc
    XCTAssertEqual(
      ProtoValue.enumValue(name: "RED", number: 0, enumDescriptor: testEnumDescriptor).convertTo(targetType: .int32)?
        .getInt(),
      0
    )
    XCTAssertEqual(
      ProtoValue.messageValue(testMessage).convertTo(targetType: .string)?.getString(),
      "Message(TestMessage)"
    )

    // Invalid conversions according to protoc
    XCTAssertNil(ProtoValue.stringValue("42").convertTo(targetType: .int32))
    XCTAssertNil(ProtoValue.messageValue(testMessage).convertTo(targetType: .int32))
  }

  // MARK: - Edge Cases Tests

  func testEdgeCasesInTypeConversion() {
    // Test numeric type conversions
    let numericTypes: [ProtoFieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .sfixed32, .fixed64, .sfixed64, .float, .double,
    ]

    for type in numericTypes {
      XCTAssertTrue(type.isNumericType(), "\(type) should be a numeric type")
    }

    // Test non-numeric types
    let nonNumericTypes: [ProtoFieldType] = [.string, .bytes, .message(nil), .enum(nil), .group, .unknown]
    for type in nonNumericTypes {
      XCTAssertFalse(type.isNumericType(), "\(type) should not be a numeric type")
    }

    // Test integer types
    let integerTypes: [ProtoFieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .sfixed32, .fixed64, .sfixed64,
    ]

    for type in integerTypes {
      XCTAssertTrue(type.isIntegerType(), "\(type) should be an integer type")
    }

    // Test non-integer types
    let nonIntegerTypes: [ProtoFieldType] = [
      .float, .double, .bool, .string, .bytes,
      .message(nil), .enum(nil), .group, .unknown,
    ]
    for type in nonIntegerTypes {
      XCTAssertFalse(type.isIntegerType(), "\(type) should not be an integer type")
    }

    // Test floating-point types
    let floatingPointTypes: [ProtoFieldType] = [.float, .double]
    for type in floatingPointTypes {
      XCTAssertTrue(type.isFloatingPointType(), "\(type) should be a floating-point type")
    }

    // Test non-floating-point types
    let nonFloatingPointTypes: [ProtoFieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .sfixed32, .fixed64, .sfixed64, .bool,
      .string, .bytes, .message(nil), .enum(nil), .group, .unknown,
    ]
    for type in nonFloatingPointTypes {
      XCTAssertFalse(type.isFloatingPointType(), "\(type) should not be a floating-point type")
    }

    // Test string/bytes types
    let stringBytesTypes: [ProtoFieldType] = [.string, .bytes]
    for type in stringBytesTypes {
      XCTAssertTrue(type.isStringOrBytesType(), "\(type) should be a string/bytes type")
    }

    // Test non-string/bytes types
    let nonStringBytesTypes: [ProtoFieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .sfixed32, .fixed64, .sfixed64, .float,
      .double, .bool, .message(nil), .enum(nil), .group, .unknown,
    ]
    for type in nonStringBytesTypes {
      XCTAssertFalse(type.isStringOrBytesType(), "\(type) should not be a string/bytes type")
    }
  }

  // MARK: - Invalid Type Combinations Tests

  func testInvalidTypeCombinations() {
    // Test invalid type combinations according to protoc
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(targetType: .int32))  // protoc doesn't allow bool to int
    XCTAssertNil(ProtoValue.intValue(42).convertTo(targetType: .bool))  // protoc doesn't allow int to bool
    XCTAssertNil(ProtoValue.stringValue("42").convertTo(targetType: .int32))  // protoc doesn't allow string to int
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01])).convertTo(targetType: .string))  // protoc doesn't allow bytes to string
  }

  // MARK: - Field Number Validation Tests

  func testTypeValidationWithFieldNumbers() {
    let testCases: [(ProtoFieldType, Int, Bool)] = [
      // Valid field numbers (1-536870911)
      (.int32, 1, true),
      (.int32, 536_870_911, true),
      (.int32, 2, true),
      (.int32, 536_870_910, true),

      // Invalid field numbers
      (.int32, 0, false),
      (.int32, 536_870_912, false),
      (.int32, -1, false),

      // Reserved field numbers (19000-19999)
      (.int32, 19000, false),
      (.int32, 19999, false),
      (.int32, 19500, false),
    ]

    for (type, fieldNumber, shouldSucceed) in testCases {
      let isValid = ProtoFieldType.validateFieldNumber(fieldNumber)
      if shouldSucceed {
        XCTAssertTrue(isValid, "Field number \(fieldNumber) should be valid for type \(type)")
      }
      else {
        XCTAssertFalse(isValid, "Field number \(fieldNumber) should be invalid for type \(type)")
      }
    }
  }

  // MARK: - Wire Format Compatibility Tests

  func testWireFormatCompatibility() {
    // Test Varint (0) compatibility
    let varintTypes: [ProtoFieldType] = [.int32, .int64, .uint32, .uint64, .sint32, .sint64, .bool, .enum(nil)]
    for type in varintTypes {
      XCTAssertTrue(ProtoFieldType.isWireTypeCompatible(type, 0), "\(type) should be compatible with Varint wire type")
    }

    // Test Fixed64 (1) compatibility
    let fixed64Types: [ProtoFieldType] = [.fixed64, .sfixed64, .double]
    for type in fixed64Types {
      XCTAssertTrue(ProtoFieldType.isWireTypeCompatible(type, 1), "\(type) should be compatible with Fixed64 wire type")
    }

    // Test Length-delimited (2) compatibility
    let lengthDelimitedTypes: [ProtoFieldType] = [.string, .bytes, .message(nil)]
    for type in lengthDelimitedTypes {
      XCTAssertTrue(
        ProtoFieldType.isWireTypeCompatible(type, 2),
        "\(type) should be compatible with Length-delimited wire type"
      )
    }

    // Test Fixed32 (5) compatibility
    let fixed32Types: [ProtoFieldType] = [.fixed32, .sfixed32, .float]
    for type in fixed32Types {
      XCTAssertTrue(ProtoFieldType.isWireTypeCompatible(type, 5), "\(type) should be compatible with Fixed32 wire type")
    }

    // Test incompatible combinations
    let allTypes: [ProtoFieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64, .bool, .enum(nil),
      .fixed64, .sfixed64, .double, .string, .bytes, .message(nil),
      .fixed32, .sfixed32, .float, .group, .unknown,
    ]

    for type in allTypes {
      // Test invalid wire type
      XCTAssertFalse(
        ProtoFieldType.isWireTypeCompatible(type, 3),
        "\(type) should not be compatible with invalid wire type 3"
      )
      XCTAssertFalse(
        ProtoFieldType.isWireTypeCompatible(type, 4),
        "\(type) should not be compatible with invalid wire type 4"
      )
      XCTAssertFalse(
        ProtoFieldType.isWireTypeCompatible(type, 6),
        "\(type) should not be compatible with invalid wire type 6"
      )
      XCTAssertFalse(
        ProtoFieldType.isWireTypeCompatible(type, -1),
        "\(type) should not be compatible with negative wire type"
      )
    }
  }

  // MARK: - Type Compatibility Tests

  func testTypeCompatibility() {
    // Test same type compatibility
    let allTypes: [ProtoFieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64, .bool, .enum(nil),
      .fixed64, .sfixed64, .double, .string, .bytes, .message(nil),
      .fixed32, .sfixed32, .float, .group, .unknown,
    ]

    for type in allTypes {
      XCTAssertTrue(ProtoFieldType.areTypesCompatible(type, type), "Type \(type) should be compatible with itself")
    }

    // Test numeric type compatibility
    let numericTypes: [ProtoFieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .sfixed32, .fixed64, .sfixed64, .float, .double,
    ]

    for type1 in numericTypes {
      for type2 in numericTypes {
        XCTAssertTrue(
          ProtoFieldType.areTypesCompatible(type1, type2),
          "Numeric types \(type1) and \(type2) should be compatible"
        )
      }
    }

    // Test string and bytes incompatibility
    XCTAssertFalse(ProtoFieldType.areTypesCompatible(.string, .bytes), "String and bytes should not be compatible")
    XCTAssertFalse(ProtoFieldType.areTypesCompatible(.bytes, .string), "Bytes and string should not be compatible")

    // Test message and enum incompatibility with primitive types
    let primitiveTypes: [ProtoFieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .sfixed32, .fixed64, .sfixed64, .float, .double,
      .bool, .string, .bytes,
    ]

    for primitiveType in primitiveTypes {
      XCTAssertFalse(
        ProtoFieldType.areTypesCompatible(.message(nil), primitiveType),
        "Message type should not be compatible with \(primitiveType)"
      )
      XCTAssertFalse(
        ProtoFieldType.areTypesCompatible(.enum(nil), primitiveType),
        "Enum type should not be compatible with \(primitiveType)"
      )
    }

    // Test unknown type compatibility
    for type in allTypes where type != .unknown {
      XCTAssertFalse(
        ProtoFieldType.areTypesCompatible(.unknown, type),
        "Unknown type should not be compatible with \(type)"
      )
      XCTAssertFalse(
        ProtoFieldType.areTypesCompatible(type, .unknown),
        "\(type) should not be compatible with unknown type"
      )
    }

    // Test group type compatibility
    for type in allTypes where type != .group {
      XCTAssertFalse(
        ProtoFieldType.areTypesCompatible(.group, type),
        "Group type should not be compatible with \(type)"
      )
      XCTAssertFalse(
        ProtoFieldType.areTypesCompatible(type, .group),
        "\(type) should not be compatible with group type"
      )
    }
  }
}
