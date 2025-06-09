/**
 * ValueHandlerTests.swift
 * SwiftProtoReflectTests
 *
 * Comprehensive тесты для ValueHandler - google.protobuf.Value поддержка
 */

import XCTest

@testable import SwiftProtoReflect

final class ValueHandlerTests: XCTestCase {

  // MARK: - Basic Handler Properties Tests

  func testHandlerBasicProperties() {
    XCTAssertEqual(ValueHandler.handledTypeName, WellKnownTypeNames.value)
    XCTAssertEqual(ValueHandler.supportPhase, .important)
  }

  // MARK: - ValueValue Initialization Tests

  func testValueValueFromBasicTypes() {
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

  func testValueValueFromAnyTypes() throws {
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

  func testValueValueUnsupportedType() {
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

  func testValueValueToAny() {
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

  func testCreateDynamicFromSpecialized() throws {
    // Test number value
    let numberValue = ValueHandler.ValueValue.numberValue(42.5)
    let numberMessage = try ValueHandler.createDynamic(from: numberValue)
    XCTAssertEqual(numberMessage.descriptor.fullName, WellKnownTypeNames.value)

    // Check that value_data field exists and contains data
    XCTAssertTrue(try numberMessage.hasValue(forField: "value_data"))
    let valueData = try numberMessage.get(forField: "value_data") as? Data
    XCTAssertNotNil(valueData)
    XCTAssertFalse(valueData!.isEmpty)

    // Test string value
    let stringValue = ValueHandler.ValueValue.stringValue("hello")
    let stringMessage = try ValueHandler.createDynamic(from: stringValue)

    XCTAssertTrue(try stringMessage.hasValue(forField: "value_data"))
    let stringData = try stringMessage.get(forField: "value_data") as? Data
    XCTAssertNotNil(stringData)
    XCTAssertFalse(stringData!.isEmpty)

    // Test bool value
    let boolValue = ValueHandler.ValueValue.boolValue(true)
    let boolMessage = try ValueHandler.createDynamic(from: boolValue)

    XCTAssertTrue(try boolMessage.hasValue(forField: "value_data"))
    let boolData = try boolMessage.get(forField: "value_data") as? Data
    XCTAssertNotNil(boolData)
    XCTAssertFalse(boolData!.isEmpty)

    // Test null value
    let nullValue = ValueHandler.ValueValue.nullValue
    let nullMessage = try ValueHandler.createDynamic(from: nullValue)

    XCTAssertTrue(try nullMessage.hasValue(forField: "value_data"))
    let nullData = try nullMessage.get(forField: "value_data") as? Data
    XCTAssertNotNil(nullData)
    XCTAssertFalse(nullData!.isEmpty)
  }

  func testCreateDynamicFromInvalidSpecialized() {
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

  func testValidate() {
    XCTAssertTrue(ValueHandler.validate(ValueHandler.ValueValue.nullValue))
    XCTAssertTrue(ValueHandler.validate(ValueHandler.ValueValue.numberValue(42)))
    XCTAssertTrue(ValueHandler.validate(ValueHandler.ValueValue.stringValue("test")))
    XCTAssertTrue(ValueHandler.validate(ValueHandler.ValueValue.boolValue(true)))

    XCTAssertFalse(ValueHandler.validate("not a ValueValue"))
    XCTAssertFalse(ValueHandler.validate(42))
    XCTAssertFalse(ValueHandler.validate([]))
  }

  // MARK: - Registry Integration Tests

  func testRegistryIntegration() throws {
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

  func testAnyExtensions() throws {
    let value: Any = 42.5
    let valueValue = try ValueHandler.ValueValue(from: value)
    XCTAssertEqual(valueValue, .numberValue(42.5))

    let stringValue: Any = "test"
    let stringValueValue = try ValueHandler.ValueValue(from: stringValue)
    XCTAssertEqual(stringValueValue, .stringValue("test"))
  }

  func testDynamicMessageExtensions() throws {
    // Test valueMessage creation
    let message = try DynamicMessage.valueMessage(from: 42.5)
    XCTAssertEqual(message.descriptor.fullName, WellKnownTypeNames.value)

    // Check that value_data field exists and contains data
    XCTAssertTrue(try message.hasValue(forField: "value_data"))
    let valueData = try message.get(forField: "value_data") as? Data
    XCTAssertNotNil(valueData)
    XCTAssertFalse(valueData!.isEmpty)

    // Test toAnyValue conversion
    let anyValue = try message.toAnyValue()
    XCTAssertEqual(anyValue as? Double, 42.5)
  }

  // MARK: - Round-Trip Tests

  func testRoundTripConversion() throws {
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

  func testValueConversionPerformance() {
    measure {
      for i in 0..<1000 {
        let value = ValueHandler.ValueValue.numberValue(Double(i))
        let _ = value.toAny()
      }
    }
  }

  func testHandlerPerformance() {
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

  func testCreateSpecializedWithWrongMessageType() throws {
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

  func testCreateSpecializedWithEmptyValueData() throws {
    // Create a Value message with empty value_data
    let valueDescriptor = try createTestValueDescriptor()
    let factory = MessageFactory()
    var message = factory.createMessage(from: valueDescriptor)

    // Set empty data
    try message.set(Data(), forField: "value_data")

    // This should return nullValue
    let result = try ValueHandler.createSpecialized(from: message)
    let valueValue = result as! ValueHandler.ValueValue
    XCTAssertEqual(valueValue, .nullValue)
  }

  func testCreateSpecializedWithMissingValueData() throws {
    // Create a Value message without setting value_data
    let valueDescriptor = try createTestValueDescriptor()
    let factory = MessageFactory()
    let message = factory.createMessage(from: valueDescriptor)

    // Don't set value_data field - it should return nullValue
    let result = try ValueHandler.createSpecialized(from: message)
    let valueValue = result as! ValueHandler.ValueValue
    XCTAssertEqual(valueValue, .nullValue)
  }

  func testCreateSpecializedWithInvalidJSON() throws {
    // Create a Value message with invalid JSON data
    let valueDescriptor = try createTestValueDescriptor()
    let factory = MessageFactory()
    var message = factory.createMessage(from: valueDescriptor)

    // Set invalid JSON data
    let invalidJSONData = "invalid json".data(using: .utf8)!
    try message.set(invalidJSONData, forField: "value_data")

    // This should throw conversionFailed error
    XCTAssertThrowsError(try ValueHandler.createSpecialized(from: message)) { error in
      guard let wellKnownError = error as? WellKnownTypeError,
        case .conversionFailed(let from, let to, let reason) = wellKnownError
      else {
        XCTFail("Expected WellKnownTypeError.conversionFailed")
        return
      }
      XCTAssertEqual(from, "DynamicMessage")
      XCTAssertEqual(to, "ValueValue")
      XCTAssertTrue(reason.contains("Failed to extract value_data"))
    }
  }

  func testCreateSpecializedWithMalformedJSONStructure() throws {
    // Create a Value message with valid JSON but wrong structure
    let valueDescriptor = try createTestValueDescriptor()
    let factory = MessageFactory()
    var message = factory.createMessage(from: valueDescriptor)

    // Set JSON data without the expected "value" wrapper
    let malformedJSON = ["not_value": "test"]
    let jsonData = try JSONSerialization.data(withJSONObject: malformedJSON, options: [])
    try message.set(jsonData, forField: "value_data")

    // This should return nullValue since the wrapper structure is not found
    let result = try ValueHandler.createSpecialized(from: message)
    let valueValue = result as! ValueHandler.ValueValue
    XCTAssertEqual(valueValue, .nullValue)
  }

  func testToAnyValueWithWrongMessageType() throws {
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
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/struct.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "Value",
      parent: fileDescriptor
    )

    let valueDataField = FieldDescriptor(
      name: "value_data",
      number: 1,
      type: .bytes
    )
    messageDescriptor.addField(valueDataField)
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}
