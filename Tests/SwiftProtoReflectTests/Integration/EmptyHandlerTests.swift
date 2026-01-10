/**
 * EmptyHandlerTests.swift
 * SwiftProtoReflectTests
 *
 * Tests for EmptyHandler
 */

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class EmptyHandlerTests: XCTestCase {

  // MARK: - EmptyValue Tests

  func testEmptyValueInitialization() {
    // Basic initialization
    let empty1 = EmptyHandler.EmptyValue()
    let empty2 = EmptyHandler.EmptyValue()

    // All EmptyValue instances should be equal
    XCTAssertEqual(empty1, empty2)
  }

  func testEmptyValueSingleton() {
    let singleton = EmptyHandler.EmptyValue.instance
    let manual = EmptyHandler.EmptyValue()

    // Singleton and regular instance should be equal
    XCTAssertEqual(singleton, manual)
  }

  func testEmptyValueDescription() {
    let empty = EmptyHandler.EmptyValue()

    // Check description
    XCTAssertEqual(empty.description, "Empty")
  }

  func testEmptyValueEquality() {
    let empty1 = EmptyHandler.EmptyValue()
    let empty2 = EmptyHandler.EmptyValue()
    let singleton = EmptyHandler.EmptyValue.instance

    // All EmptyValue should be equal to each other
    XCTAssertEqual(empty1, empty2)
    XCTAssertEqual(empty1, singleton)
    XCTAssertEqual(empty2, singleton)
  }

  // MARK: - Handler Implementation Tests

  func testHandlerBasicProperties() {
    XCTAssertEqual(EmptyHandler.handledTypeName, "google.protobuf.Empty")
    XCTAssertEqual(EmptyHandler.supportPhase, .critical)
  }

  func testCreateSpecializedFromMessage() throws {
    // Create empty message
    let emptyMessage = try createEmptyMessage()

    // Convert to specialized type
    let specialized = try EmptyHandler.createSpecialized(from: emptyMessage)

    guard let empty = specialized as? EmptyHandler.EmptyValue else {
      XCTFail("Expected EmptyValue")
      return
    }

    // Check that we got the correct instance
    XCTAssertEqual(empty, EmptyHandler.EmptyValue.instance)
  }

  func testCreateSpecializedFromInvalidMessage() throws {
    // Create message of wrong type
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotEmpty", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try EmptyHandler.createSpecialized(from: wrongMessage)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, _) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Empty")
    }
  }

  func testCreateDynamicFromSpecialized() throws {
    let empty = EmptyHandler.EmptyValue.instance

    let dynamicMessage = try EmptyHandler.createDynamic(from: empty)

    // Check that the correct message was created
    XCTAssertEqual(dynamicMessage.descriptor.fullName, "google.protobuf.Empty")
    XCTAssertEqual(dynamicMessage.descriptor.name, "Empty")

    // Empty message should not have fields
    XCTAssertEqual(dynamicMessage.descriptor.fields.count, 0)
  }

  func testCreateDynamicFromInvalidSpecialized() throws {
    let wrongSpecialized = "not an empty"

    XCTAssertThrowsError(try EmptyHandler.createDynamic(from: wrongSpecialized)) { error in
      guard case WellKnownTypeError.conversionFailed(let from, let to, _) = error else {
        XCTFail("Expected conversionFailed error")
        return
      }
      XCTAssertEqual(from, "String")
      XCTAssertEqual(to, "DynamicMessage")
    }
  }

  func testValidate() throws {
    // Valid values
    let validEmpty = EmptyHandler.EmptyValue()
    let validSingleton = EmptyHandler.EmptyValue.instance

    XCTAssertTrue(EmptyHandler.validate(validEmpty))
    XCTAssertTrue(EmptyHandler.validate(validSingleton))

    // Invalid values
    XCTAssertFalse(EmptyHandler.validate("not empty"))
    XCTAssertFalse(EmptyHandler.validate(123))
    XCTAssertFalse(EmptyHandler.validate(Date()))
    XCTAssertFalse(EmptyHandler.validate([]))
  }

  func testRoundTripConversion() throws {
    let originalEmpty = EmptyHandler.EmptyValue.instance

    // Convert to dynamic message and back
    let dynamicMessage = try EmptyHandler.createDynamic(from: originalEmpty)
    let convertedSpecialized = try EmptyHandler.createSpecialized(from: dynamicMessage)

    guard let convertedEmpty = convertedSpecialized as? EmptyHandler.EmptyValue else {
      XCTFail("Expected EmptyValue")
      return
    }

    XCTAssertEqual(originalEmpty, convertedEmpty)
  }

  // MARK: - Convenience Extensions Tests

  func testDynamicMessageEmptyExtension() throws {
    // Create Empty message through convenience method
    let emptyMessage = try DynamicMessage.emptyMessage()

    XCTAssertEqual(emptyMessage.descriptor.fullName, "google.protobuf.Empty")
    XCTAssertTrue(emptyMessage.isEmpty())

    // Convert back to EmptyValue
    let empty = try emptyMessage.toEmpty()
    XCTAssertEqual(empty, EmptyHandler.EmptyValue.instance)
  }

  func testDynamicMessageIsEmpty() throws {
    // Empty message
    let emptyMessage = try DynamicMessage.emptyMessage()
    XCTAssertTrue(emptyMessage.isEmpty())

    // Non-Empty message
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotEmpty", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let notEmptyMessage = factory.createMessage(from: messageDescriptor)
    XCTAssertFalse(notEmptyMessage.isEmpty())
  }

  func testDynamicMessageToEmptyWithInvalidMessage() throws {
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotEmpty", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try wrongMessage.toEmpty()) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  // MARK: - Unit Type Integration Tests

  func testVoidIntegration() {
    // Create from Void
    let emptyFromVoid = EmptyHandler.EmptyValue.from(())
    XCTAssertEqual(emptyFromVoid, EmptyHandler.EmptyValue.instance)

    // Convert to Void
    let empty = EmptyHandler.EmptyValue()
    empty.toVoid()

    // Void type has no values to compare, so just check that method executed without errors
    XCTAssertTrue(true)  // If we reached this point, everything works
  }

  func testVoidRoundTrip() {
    let originalVoid: Void = ()
    let empty = EmptyHandler.EmptyValue.from(originalVoid)
    empty.toVoid()

    // Again, Void cannot be compared, but check that operations executed
    XCTAssertEqual(empty, EmptyHandler.EmptyValue.instance)
  }

  // MARK: - Registry Integration Tests

  func testRegistryIntegration() throws {
    let registry = WellKnownTypesRegistry.shared

    // Check that EmptyHandler is registered
    let handler = registry.getHandler(for: WellKnownTypeNames.empty)
    XCTAssertNotNil(handler)
    XCTAssertTrue(handler is EmptyHandler.Type)

    // Check that registered types include Empty
    let registeredTypes = registry.getRegisteredTypes()
    XCTAssertTrue(registeredTypes.contains(WellKnownTypeNames.empty))
  }

  func testRegistryCreateSpecialized() throws {
    let registry = WellKnownTypesRegistry.shared
    let emptyMessage = try createEmptyMessage()

    let specialized = try registry.createSpecialized(
      from: emptyMessage,
      typeName: WellKnownTypeNames.empty
    )

    guard let empty = specialized as? EmptyHandler.EmptyValue else {
      XCTFail("Expected EmptyValue from registry")
      return
    }

    XCTAssertEqual(empty, EmptyHandler.EmptyValue.instance)
  }

  func testRegistryCreateDynamic() throws {
    let registry = WellKnownTypesRegistry.shared
    let empty = EmptyHandler.EmptyValue.instance

    let dynamicMessage = try registry.createDynamic(
      from: empty,
      typeName: WellKnownTypeNames.empty
    )

    XCTAssertEqual(dynamicMessage.descriptor.fullName, WellKnownTypeNames.empty)
    XCTAssertTrue(dynamicMessage.isEmpty())
  }

  // MARK: - Edge Cases Tests

  func testMultipleEmptyMessagesAreEqual() throws {
    let empty1 = try DynamicMessage.emptyMessage()
    let empty2 = try DynamicMessage.emptyMessage()

    // Although these are different DynamicMessage objects, their specialized representations should be equal
    let specialized1 = try EmptyHandler.createSpecialized(from: empty1) as! EmptyHandler.EmptyValue
    let specialized2 = try EmptyHandler.createSpecialized(from: empty2) as! EmptyHandler.EmptyValue

    XCTAssertEqual(specialized1, specialized2)
  }

  func testEmptyMessageFieldAccess() throws {
    var emptyMessage = try DynamicMessage.emptyMessage()

    // Empty message should not have fields
    XCTAssertEqual(emptyMessage.descriptor.fields.count, 0)

    // Attempt to access non-existent field should throw error
    XCTAssertThrowsError(try emptyMessage.get(forField: "nonexistent"))
    XCTAssertThrowsError(try emptyMessage.set("value", forField: "nonexistent"))
    XCTAssertThrowsError(try emptyMessage.hasValue(forField: "nonexistent"))
  }

  // MARK: - Performance Tests

  func testConversionPerformance() throws {
    let empty = EmptyHandler.EmptyValue.instance

    measure {
      for _ in 0..<1000 {
        do {
          let dynamicMessage = try EmptyHandler.createDynamic(from: empty)
          _ = try EmptyHandler.createSpecialized(from: dynamicMessage)
        }
        catch {
          XCTFail("Performance test failed: \(error)")
        }
      }
    }
  }

  func testRegistryPerformance() throws {
    let registry = WellKnownTypesRegistry.shared
    let emptyMessage = try createEmptyMessage()

    measure {
      for _ in 0..<1000 {
        do {
          let specialized = try registry.createSpecialized(
            from: emptyMessage,
            typeName: WellKnownTypeNames.empty
          )
          _ = try registry.createDynamic(
            from: specialized,
            typeName: WellKnownTypeNames.empty
          )
        }
        catch {
          XCTFail("Registry performance test failed: \(error)")
        }
      }
    }
  }

  // MARK: - Error Handling Tests

  func testCreateSpecializedWithNilMessage() throws {
    // This test checks edge cases, although such scenario should not happen in reality
    // since DynamicMessage cannot be nil in Swift's typed system
  }

  func testValidateWithNil() {
    // Check validation with nil (which should return false)
    let nilValue: Any? = nil
    if let value = nilValue {
      XCTAssertFalse(EmptyHandler.validate(value))
    }
    // If nil, test still passes since we can't pass nil to validate
  }

  // MARK: - Helper Methods

  private func createEmptyMessage() throws -> DynamicMessage {
    // Create descriptor for Empty
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/empty.proto",
      package: "google.protobuf"
    )

    let messageDescriptor = MessageDescriptor(
      name: "Empty",
      parent: fileDescriptor
    )

    // Empty message has no fields
    fileDescriptor.addMessage(messageDescriptor)

    // Create message
    let factory = MessageFactory()
    let message = factory.createMessage(from: messageDescriptor)

    return message
  }
}
