/**
 * ValueHandlerTests.swift
 * SwiftProtoReflectTests
 *
 * Comprehensive tests for ValueHandler - google.protobuf.Value support
 */

import XCTest

@testable import SwiftProtoReflect

final class ValueHandlerTests: XCTestCase {

  // MARK: - Basic Handler Properties Tests

  func testHandlerBasicProperties() async throws {
    XCTAssertEqual(ValueHandler.handledTypeName, WellKnownTypeNames.value)
    XCTAssertEqual(ValueHandler.supportPhase, .important)
  }

  // MARK: - ValueValue Initialization Tests

  func testValueValueFromBasicTypes() async throws {
    // Null value
    let nullValue = ValueHandler.ValueValue.nullValue
    XCTAssertEqual(nullValue, .nullValue)

    // Number values
    XCTAssertEqual(ValueHandler.ValueValue.numberValue(42.0), .numberValue(42.0))
    XCTAssertEqual(ValueHandler.ValueValue.numberValue(3.14), .numberValue(3.14))
    XCTAssertEqual(ValueHandler.ValueValue.numberValue(-123.45), .numberValue(-123.45))

    // String values
    XCTAssertEqual(ValueHandler.ValueValue.stringValue("hello"), .stringValue("hello"))
    XCTAssertEqual(ValueHandler.ValueValue.stringValue(""), .stringValue(""))

    // Bool values
    XCTAssertEqual(ValueHandler.ValueValue.boolValue(true), .boolValue(true))
    XCTAssertEqual(ValueHandler.ValueValue.boolValue(false), .boolValue(false))
  }

  func testValueValueFromAnyTypes() async throws {
    // NSNull
    let nullValue = try ValueHandler.ValueValue(from: NSNull())
    XCTAssertEqual(nullValue, .nullValue)

    // Numbers
    let intValue = try ValueHandler.ValueValue(from: 42)
    XCTAssertEqual(intValue, .numberValue(42.0))

    let doubleValue = try ValueHandler.ValueValue(from: 3.14)
    XCTAssertEqual(doubleValue, .numberValue(3.14))

    let floatValue = try ValueHandler.ValueValue(from: Float(2.5))
    XCTAssertEqual(floatValue, .numberValue(2.5))

    // String
    let stringValue = try ValueHandler.ValueValue(from: "test")
    XCTAssertEqual(stringValue, .stringValue("test"))

    // Bool
    let boolValue = try ValueHandler.ValueValue(from: true)
    XCTAssertEqual(boolValue, .boolValue(true))

    // Dictionary (struct)
    let dictValue = try ValueHandler.ValueValue(from: ["key": "value"])
    if case .structValue(let structValue) = dictValue {
      XCTAssertEqual(structValue.fields.count, 1)
      XCTAssertEqual(structValue.fields["key"], .stringValue("value"))
    }
    else {
      XCTFail("Expected structValue")
    }

    // Array (list)
    let arrayValue = try ValueHandler.ValueValue(from: [1, "two", true])
    if case .listValue(let listValues) = arrayValue {
      XCTAssertEqual(listValues.count, 3)
      XCTAssertEqual(listValues[0], .numberValue(1.0))
      XCTAssertEqual(listValues[1], .stringValue("two"))
      XCTAssertEqual(listValues[2], .boolValue(true))
    }
    else {
      XCTFail("Expected listValue")
    }
  }

  func testValueValueUnsupportedType() async throws {
    // Custom class should fail
    class CustomClass {}
    let customObject = CustomClass()

    XCTAssertThrowsError(try ValueHandler.ValueValue(from: customObject)) { error in
      guard let wellKnownError = error as? WellKnownTypeError,
        case .invalidData(let typeName, _) = wellKnownError
      else {
        XCTFail("Expected WellKnownTypeError.invalidData")
        return
      }
      XCTAssertEqual(typeName, WellKnownTypeNames.value)
    }
  }

  // MARK: - ValueValue to Any Conversion Tests

  func testValueValueToAny() async throws {
    // Null
    let nullValue = ValueHandler.ValueValue.nullValue
    let nullAny = nullValue.toAny()
    XCTAssertTrue(nullAny is NSNull)

    // Number
    let numberValue = ValueHandler.ValueValue.numberValue(42.5)
    let numberAny = numberValue.toAny()
    XCTAssertEqual(numberAny as? Double, 42.5)

    // String
    let stringValue = ValueHandler.ValueValue.stringValue("test")
    let stringAny = stringValue.toAny()
    XCTAssertEqual(stringAny as? String, "test")

    // Bool
    let boolValue = ValueHandler.ValueValue.boolValue(true)
    let boolAny = boolValue.toAny()
    XCTAssertEqual(boolAny as? Bool, true)
  }

  // MARK: - Handler Implementation Tests

  func testCreateDynamicFromSpecialized() async throws {
    // number_value → field 2 (double)
    let numberMessage = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.numberValue(42.5))
    XCTAssertEqual(numberMessage.descriptor.fullName, WellKnownTypeNames.value)
    XCTAssertTrue(try numberMessage.hasValue(forField: 2))
    XCTAssertEqual(try numberMessage.get(forField: 2) as? Double, 42.5)

    // string_value → field 3
    let stringMessage = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.stringValue("hello"))
    XCTAssertTrue(try stringMessage.hasValue(forField: 3))
    XCTAssertEqual(try stringMessage.get(forField: 3) as? String, "hello")

    // bool_value → field 4
    let boolMessage = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.boolValue(true))
    XCTAssertTrue(try boolMessage.hasValue(forField: 4))
    XCTAssertEqual(try boolMessage.get(forField: 4) as? Bool, true)

    // null_value → field 1 (enum = 0)
    let nullMessage = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.nullValue)
    XCTAssertTrue(try nullMessage.hasValue(forField: 1))
    XCTAssertEqual(try nullMessage.get(forField: 1) as? Int32, Int32(0))
  }

  func testCreateDynamicFromInvalidSpecialized() async throws {
    XCTAssertThrowsError(try ValueHandler.createDynamic(from: "invalid")) { error in
      guard let wellKnownError = error as? WellKnownTypeError,
        case .conversionFailed(_, _, _) = wellKnownError
      else {
        XCTFail("Expected WellKnownTypeError.conversionFailed")
        return
      }
    }
  }

  // MARK: - Validation Tests

  func testValidate() async throws {
    XCTAssertTrue(ValueHandler.validate(ValueHandler.ValueValue.nullValue))
    XCTAssertTrue(ValueHandler.validate(ValueHandler.ValueValue.numberValue(42)))
    XCTAssertTrue(ValueHandler.validate(ValueHandler.ValueValue.stringValue("test")))
    XCTAssertTrue(ValueHandler.validate(ValueHandler.ValueValue.boolValue(true)))

    XCTAssertFalse(ValueHandler.validate("not a ValueValue"))
    XCTAssertFalse(ValueHandler.validate(42))
    XCTAssertFalse(ValueHandler.validate([]))
  }

  // MARK: - Registry Integration Tests

  func testRegistryIntegration() async throws {
    let registry = WellKnownTypesRegistry.shared
    let handler = registry.getHandler(for: WellKnownTypeNames.value)
    XCTAssertNotNil(handler)
    XCTAssertTrue(handler is ValueHandler.Type)

    // Test through registry
    let valueValue = ValueHandler.ValueValue.numberValue(42.5)
    let message = try registry.createDynamic(from: valueValue, typeName: WellKnownTypeNames.value)
    let roundTripValue = try registry.createSpecialized(from: message, typeName: WellKnownTypeNames.value)

    guard let roundTripValueValue = roundTripValue as? ValueHandler.ValueValue else {
      XCTFail("Expected ValueValue")
      return
    }
    XCTAssertEqual(roundTripValueValue, valueValue)
  }

  // MARK: - Convenience Extensions Tests

  func testAnyExtensions() async throws {
    let value: Any = 42.5
    let valueValue = try ValueHandler.ValueValue(from: value)
    XCTAssertEqual(valueValue, .numberValue(42.5))

    let stringValue: Any = "test"
    let stringValueValue = try ValueHandler.ValueValue(from: stringValue)
    XCTAssertEqual(stringValueValue, .stringValue("test"))
  }

  func testDynamicMessageExtensions() async throws {
    let message = try DynamicMessage.valueMessage(from: 42.5)
    XCTAssertEqual(message.descriptor.fullName, WellKnownTypeNames.value)

    // number_value stored at field 2 in the new wire format
    XCTAssertTrue(try message.hasValue(forField: 2))
    XCTAssertEqual(try message.get(forField: 2) as? Double, 42.5)

    let anyValue = try message.toAnyValue()
    XCTAssertEqual(anyValue as? Double, 42.5)
  }

  // MARK: - Round-Trip Tests

  func testRoundTripConversion() async throws {
    let testValues: [ValueHandler.ValueValue] = [
      .nullValue,
      .numberValue(42.5),
      .numberValue(-123.0),
      .numberValue(0.0),
      .stringValue("hello"),
      .stringValue(""),
      .stringValue("unicode: 🚀"),
      .boolValue(true),
      .boolValue(false),
    ]

    for originalValue in testValues {
      let message = try ValueHandler.createDynamic(from: originalValue)
      let roundTripValue = try ValueHandler.createSpecialized(from: message) as! ValueHandler.ValueValue
      XCTAssertEqual(roundTripValue, originalValue, "Round-trip failed for \(originalValue)")
    }
  }

  // MARK: - Performance Tests

  func testValueConversionPerformance() async throws {
    measure {
      for i in 0..<1000 {
        let value = ValueHandler.ValueValue.numberValue(Double(i))
        let _ = value.toAny()
      }
    }
  }

  func testHandlerPerformance() async throws {
    let values = (0..<100).map { ValueHandler.ValueValue.numberValue(Double($0)) }

    measure {
      for value in values {
        do {
          let message = try ValueHandler.createDynamic(from: value)
          let _ = try ValueHandler.createSpecialized(from: message)
        }
        catch {
          XCTFail("Unexpected error: \(error)")
        }
      }
    }
  }

  // MARK: - Error Handling Tests

  func testCreateSpecializedWithWrongMessageType() async throws {
    // Create a message with different type name
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var messageDescriptor = MessageDescriptor(name: "WrongType", parent: fileDescriptor)

    let valueDataField = FieldDescriptor(
      name: "value_data",
      number: 1,
      type: .bytes
    )
    messageDescriptor.addField(valueDataField)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let message = factory.createMessage(from: messageDescriptor)

    // This should throw invalidData error
    XCTAssertThrowsError(try ValueHandler.createSpecialized(from: message)) { error in
      guard let wellKnownError = error as? WellKnownTypeError,
        case .invalidData(let typeName, let reason) = wellKnownError
      else {
        XCTFail("Expected WellKnownTypeError.invalidData")
        return
      }
      XCTAssertEqual(typeName, WellKnownTypeNames.value)
      XCTAssertTrue(reason.contains("Expected"))
      XCTAssertTrue(reason.contains("got"))
    }
  }

  func testCreateSpecializedWithEmptyValueData() async throws {
    // A Value message with no oneof field set should return .nullValue.
    let message = DynamicMessage(descriptor: StructProtoDescriptors.valueDescriptor)
    let result = try ValueHandler.createSpecialized(from: message)
    XCTAssertEqual(result as? ValueHandler.ValueValue, .nullValue)
  }

  func testCreateSpecializedWithMissingValueData() async throws {
    // Create a Value message without setting value_data
    let valueDescriptor = try createTestValueDescriptor()
    let factory = MessageFactory()
    let message = factory.createMessage(from: valueDescriptor)

    // Don't set value_data field - it should return nullValue
    let result = try ValueHandler.createSpecialized(from: message)
    let valueValue = result as! ValueHandler.ValueValue
    XCTAssertEqual(valueValue, .nullValue)
  }

  func testCreateSpecializedWithInvalidJSON() async throws {
    // In the new wire format there is no JSON — invalid descriptor is rejected by fullName check.
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let wrongDescriptor = MessageDescriptor(name: "Value", parent: fileDescriptor)
    fileDescriptor.addMessage(wrongDescriptor)

    let factory = MessageFactory()
    let message = factory.createMessage(from: wrongDescriptor)

    XCTAssertThrowsError(try ValueHandler.createSpecialized(from: message)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, _) = error else {
        XCTFail("Expected invalidData, got \(error)")
        return
      }
      XCTAssertEqual(typeName, WellKnownTypeNames.value)
    }
  }

  func testCreateSpecializedWithMalformedJSONStructure() async throws {
    // In the new wire format a Value message with string_value set (field 3)
    // always decodes correctly — there is no JSON wrapping.
    var message = DynamicMessage(descriptor: StructProtoDescriptors.valueDescriptor)
    try message.set("hello", forField: 3)

    let result = try ValueHandler.createSpecialized(from: message)
    XCTAssertEqual(result as? ValueHandler.ValueValue, .stringValue("hello"))
  }

  func testToAnyValueWithWrongMessageType() async throws {
    // Create a message with different type name
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "WrongType", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let message = factory.createMessage(from: messageDescriptor)

    // This should throw invalidData error
    XCTAssertThrowsError(try message.toAnyValue()) { error in
      guard let wellKnownError = error as? WellKnownTypeError,
        case .invalidData(let typeName, let reason) = wellKnownError
      else {
        XCTFail("Expected WellKnownTypeError.invalidData")
        return
      }
      XCTAssertEqual(typeName, "test.WrongType")
      XCTAssertEqual(reason, "Message is not a Value")
    }
  }

  // MARK: - Helper Methods

  private func createTestValueDescriptor() throws -> MessageDescriptor {
    return StructProtoDescriptors.valueDescriptor
  }

  // MARK: - OPE-264 / OPE-266: New oneof wire-format tests

  func test_createDynamic_value_activeOneofFieldIsCorrect() async throws {
    let stringMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.stringValue("hi"))
    XCTAssertEqual(stringMsg.descriptor.fullName, "google.protobuf.Value")
    XCTAssertNil(try? stringMsg.get(forField: "value_data"), "value_data field must not exist")
    XCTAssertTrue(try stringMsg.hasValue(forField: 3), "string_value must be at field 3")
    XCTAssertEqual(try stringMsg.get(forField: 3) as? String, "hi")

    let boolMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.boolValue(false))
    XCTAssertTrue(try boolMsg.hasValue(forField: 4), "bool_value must be at field 4")
    XCTAssertEqual(try boolMsg.get(forField: 4) as? Bool, false)

    let numMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.numberValue(0.5))
    XCTAssertTrue(try numMsg.hasValue(forField: 2), "number_value must be at field 2")
  }

  func test_createDynamic_nullValue_setsEnumField1() async throws {
    let message = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.nullValue)

    XCTAssertEqual(message.descriptor.fullName, "google.protobuf.Value")
    XCTAssertTrue(try message.hasValue(forField: 1))
    XCTAssertEqual(try message.get(forField: 1) as? Int32, Int32(0))
    XCTAssertFalse(try message.hasValue(forField: 2))
    XCTAssertFalse(try message.hasValue(forField: 3))
    XCTAssertFalse(try message.hasValue(forField: 4))
    XCTAssertFalse(try message.hasValue(forField: 5))
    XCTAssertFalse(try message.hasValue(forField: 6))
  }

  func test_createDynamic_numberValue_setsDoubleField2() async throws {
    let message = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.numberValue(3.14))

    XCTAssertTrue(try message.hasValue(forField: 2))
    let d = try XCTUnwrap(try message.get(forField: 2) as? Double)
    XCTAssertEqual(d, 3.14, accuracy: 1e-10)
    XCTAssertFalse(try message.hasValue(forField: 1))
  }

  func test_createDynamic_structValue_setsMessageField5() async throws {
    let sv = StructHandler.StructValue(fields: ["k": .numberValue(1)])
    let message = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.structValue(sv))

    XCTAssertTrue(try message.hasValue(forField: 5))
    let nested = try XCTUnwrap(try message.get(forField: 5) as? DynamicMessage)
    XCTAssertEqual(nested.descriptor.fullName, "google.protobuf.Struct")
    XCTAssertFalse(try message.hasValue(forField: 1))
    XCTAssertFalse(try message.hasValue(forField: 6))
  }

  func test_createDynamic_listValue_setsMessageField6() async throws {
    let message = try ValueHandler.createDynamic(
      from: ValueHandler.ValueValue.listValue([.numberValue(1), .stringValue("x")])
    )

    XCTAssertTrue(try message.hasValue(forField: 6))
    let nested = try XCTUnwrap(try message.get(forField: 6) as? DynamicMessage)
    XCTAssertEqual(nested.descriptor.fullName, "google.protobuf.ListValue")
    XCTAssertFalse(try message.hasValue(forField: 1))
    XCTAssertFalse(try message.hasValue(forField: 5))
  }

  func test_createSpecialized_roundTrip_allSixKinds() async throws {
    let cases: [ValueHandler.ValueValue] = [
      .nullValue,
      .numberValue(42.5),
      .stringValue("hello"),
      .boolValue(true),
      .structValue(StructHandler.StructValue(fields: ["x": .boolValue(false)])),
      .listValue([.stringValue("a"), .nullValue]),
    ]
    for original in cases {
      let msg = try ValueHandler.createDynamic(from: original)
      let decoded = try XCTUnwrap(
        try ValueHandler.createSpecialized(from: msg) as? ValueHandler.ValueValue
      )
      XCTAssertEqual(decoded, original, "Round-trip failed for \(original)")
    }
  }
}
