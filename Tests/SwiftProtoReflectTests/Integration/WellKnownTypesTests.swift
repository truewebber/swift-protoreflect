/**
 * WellKnownTypesTests.swift
 * SwiftProtoReflectTests
 *
 * Tests for WellKnownTypes module
 */

import XCTest

@testable import SwiftProtoReflect

final class WellKnownTypesTests: XCTestCase {

  // MARK: - WellKnownTypeNames Tests

  func testTypeNameConstants() async throws {
    XCTAssertEqual(WellKnownTypeNames.timestamp, "google.protobuf.Timestamp")
    XCTAssertEqual(WellKnownTypeNames.duration, "google.protobuf.Duration")
    XCTAssertEqual(WellKnownTypeNames.empty, "google.protobuf.Empty")
    XCTAssertEqual(WellKnownTypeNames.fieldMask, "google.protobuf.FieldMask")
    XCTAssertEqual(WellKnownTypeNames.structType, "google.protobuf.Struct")
    XCTAssertEqual(WellKnownTypeNames.value, "google.protobuf.Value")
    XCTAssertEqual(WellKnownTypeNames.any, "google.protobuf.Any")
    XCTAssertEqual(WellKnownTypeNames.listValue, "google.protobuf.ListValue")
    XCTAssertEqual(WellKnownTypeNames.nullValue, "google.protobuf.NullValue")
  }

  func testTypeCollections() async throws {
    // All types should contain all types
    XCTAssertEqual(WellKnownTypeNames.allTypes.count, 18)
    XCTAssertTrue(WellKnownTypeNames.allTypes.contains(WellKnownTypeNames.timestamp))
    XCTAssertTrue(WellKnownTypeNames.allTypes.contains(WellKnownTypeNames.duration))
    XCTAssertTrue(WellKnownTypeNames.allTypes.contains(WellKnownTypeNames.empty))

    // Critical types
    XCTAssertEqual(WellKnownTypeNames.criticalTypes.count, 3)
    XCTAssertTrue(WellKnownTypeNames.criticalTypes.contains(WellKnownTypeNames.timestamp))
    XCTAssertTrue(WellKnownTypeNames.criticalTypes.contains(WellKnownTypeNames.duration))
    XCTAssertTrue(WellKnownTypeNames.criticalTypes.contains(WellKnownTypeNames.empty))

    // Important types
    XCTAssertEqual(WellKnownTypeNames.importantTypes.count, 3)
    XCTAssertTrue(WellKnownTypeNames.importantTypes.contains(WellKnownTypeNames.fieldMask))
    XCTAssertTrue(WellKnownTypeNames.importantTypes.contains(WellKnownTypeNames.structType))
    XCTAssertTrue(WellKnownTypeNames.importantTypes.contains(WellKnownTypeNames.value))

    // Advanced types
    XCTAssertEqual(WellKnownTypeNames.advancedTypes.count, 3)
    XCTAssertTrue(WellKnownTypeNames.advancedTypes.contains(WellKnownTypeNames.any))
    XCTAssertTrue(WellKnownTypeNames.advancedTypes.contains(WellKnownTypeNames.listValue))
    XCTAssertTrue(WellKnownTypeNames.advancedTypes.contains(WellKnownTypeNames.nullValue))
  }

  func testCollectionsDoNotOverlap() async throws {
    // Check that collections do not overlap
    let criticalAndImportant = WellKnownTypeNames.criticalTypes.intersection(WellKnownTypeNames.importantTypes)
    XCTAssertTrue(criticalAndImportant.isEmpty)

    let criticalAndAdvanced = WellKnownTypeNames.criticalTypes.intersection(WellKnownTypeNames.advancedTypes)
    XCTAssertTrue(criticalAndAdvanced.isEmpty)

    let importantAndAdvanced = WellKnownTypeNames.importantTypes.intersection(WellKnownTypeNames.advancedTypes)
    XCTAssertTrue(importantAndAdvanced.isEmpty)
  }

  // MARK: - WellKnownTypeDetector Tests

  func testIsWellKnownType() async throws {
    // Positive cases
    XCTAssertTrue(WellKnownTypeDetector.isWellKnownType("google.protobuf.Timestamp"))
    XCTAssertTrue(WellKnownTypeDetector.isWellKnownType("google.protobuf.Duration"))
    XCTAssertTrue(WellKnownTypeDetector.isWellKnownType("google.protobuf.Empty"))
    XCTAssertTrue(WellKnownTypeDetector.isWellKnownType("google.protobuf.Any"))

    // Negative cases
    XCTAssertFalse(WellKnownTypeDetector.isWellKnownType("com.example.MyMessage"))
    XCTAssertFalse(WellKnownTypeDetector.isWellKnownType("google.protobuf.Unknown"))
    XCTAssertFalse(WellKnownTypeDetector.isWellKnownType(""))
    XCTAssertFalse(WellKnownTypeDetector.isWellKnownType("timestamp"))
  }

  func testGetSupportPhase() async throws {
    // Critical types
    XCTAssertEqual(WellKnownTypeDetector.getSupportPhase(for: "google.protobuf.Timestamp"), .critical)
    XCTAssertEqual(WellKnownTypeDetector.getSupportPhase(for: "google.protobuf.Duration"), .critical)
    XCTAssertEqual(WellKnownTypeDetector.getSupportPhase(for: "google.protobuf.Empty"), .critical)

    // Important types
    XCTAssertEqual(WellKnownTypeDetector.getSupportPhase(for: "google.protobuf.FieldMask"), .important)
    XCTAssertEqual(WellKnownTypeDetector.getSupportPhase(for: "google.protobuf.Struct"), .important)
    XCTAssertEqual(WellKnownTypeDetector.getSupportPhase(for: "google.protobuf.Value"), .important)

    // Advanced types
    XCTAssertEqual(WellKnownTypeDetector.getSupportPhase(for: "google.protobuf.Any"), .advanced)
    XCTAssertEqual(WellKnownTypeDetector.getSupportPhase(for: "google.protobuf.ListValue"), .advanced)
    XCTAssertEqual(WellKnownTypeDetector.getSupportPhase(for: "google.protobuf.NullValue"), .advanced)

    // Unknown types
    XCTAssertNil(WellKnownTypeDetector.getSupportPhase(for: "com.example.MyMessage"))
    XCTAssertNil(WellKnownTypeDetector.getSupportPhase(for: ""))
  }

  func testGetSimpleName() async throws {
    XCTAssertEqual(WellKnownTypeDetector.getSimpleName(for: "google.protobuf.Timestamp"), "Timestamp")
    XCTAssertEqual(WellKnownTypeDetector.getSimpleName(for: "google.protobuf.Duration"), "Duration")
    XCTAssertEqual(WellKnownTypeDetector.getSimpleName(for: "google.protobuf.Empty"), "Empty")
    XCTAssertEqual(WellKnownTypeDetector.getSimpleName(for: "google.protobuf.FieldMask"), "FieldMask")

    // Unknown types
    XCTAssertNil(WellKnownTypeDetector.getSimpleName(for: "com.example.MyMessage"))
    XCTAssertNil(WellKnownTypeDetector.getSimpleName(for: ""))
  }

  // MARK: - WellKnownSupportPhase Tests

  func testSupportPhaseProperties() async throws {
    XCTAssertEqual(WellKnownSupportPhase.critical.rawValue, 1)
    XCTAssertEqual(WellKnownSupportPhase.important.rawValue, 2)
    XCTAssertEqual(WellKnownSupportPhase.advanced.rawValue, 3)

    XCTAssertEqual(WellKnownSupportPhase.critical.description, "Critical Types (Phase 1)")
    XCTAssertEqual(WellKnownSupportPhase.important.description, "Important Types (Phase 2)")
    XCTAssertEqual(WellKnownSupportPhase.advanced.description, "Advanced Types (Phase 3)")
  }

  func testSupportPhaseIncludedTypes() async throws {
    XCTAssertEqual(WellKnownSupportPhase.critical.includedTypes, WellKnownTypeNames.criticalTypes)
    XCTAssertEqual(WellKnownSupportPhase.important.includedTypes, WellKnownTypeNames.importantTypes)
    XCTAssertEqual(WellKnownSupportPhase.advanced.includedTypes, WellKnownTypeNames.advancedTypes)
  }

  func testAllCases() async throws {
    let allCases = WellKnownSupportPhase.allCases
    XCTAssertEqual(allCases.count, 3)
    XCTAssertTrue(allCases.contains(.critical))
    XCTAssertTrue(allCases.contains(.important))
    XCTAssertTrue(allCases.contains(.advanced))
  }

  // MARK: - WellKnownTypeError Tests

  func testErrorEquality() async throws {
    let error1 = WellKnownTypeError.unsupportedType("TestType")
    let error2 = WellKnownTypeError.unsupportedType("TestType")
    let error3 = WellKnownTypeError.unsupportedType("OtherType")

    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)

    let conversionError1 = WellKnownTypeError.conversionFailed(from: "A", to: "B", reason: "test")
    let conversionError2 = WellKnownTypeError.conversionFailed(from: "A", to: "B", reason: "test")
    let conversionError3 = WellKnownTypeError.conversionFailed(from: "A", to: "B", reason: "other")

    XCTAssertEqual(conversionError1, conversionError2)
    XCTAssertNotEqual(conversionError1, conversionError3)
  }

  func testErrorDescriptions() async throws {
    let unsupportedError = WellKnownTypeError.unsupportedType("TestType")
    XCTAssertEqual(unsupportedError.description, "Unsupported well-known type: TestType")

    let conversionError = WellKnownTypeError.conversionFailed(from: "A", to: "B", reason: "test reason")
    XCTAssertEqual(conversionError.description, "Failed to convert from A to B: test reason")

    let invalidDataError = WellKnownTypeError.invalidData(typeName: "TestType", reason: "invalid")
    XCTAssertEqual(invalidDataError.description, "Invalid data for TestType: invalid")

    let handlerNotFoundError = WellKnownTypeError.handlerNotFound("TestType")
    XCTAssertEqual(handlerNotFoundError.description, "Handler not found for well-known type: TestType")

    let validationError = WellKnownTypeError.validationFailed(typeName: "TestType", reason: "failed")
    XCTAssertEqual(validationError.description, "Validation failed for TestType: failed")
  }

  // MARK: - WellKnownTypesRegistry Tests

  func testRegistryInitialization() async throws {
    let registry = WellKnownTypesRegistry.shared

    XCTAssertNotNil(registry)

    let registeredTypes = await registry.getRegisteredTypes()
    XCTAssertTrue(registeredTypes.contains("google.protobuf.Timestamp"))
  }

  func testRegistryThreadSafety() async throws {
    let registry = WellKnownTypesRegistry.shared

    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<10 {
        group.addTask {
          let types = await registry.getRegisteredTypes()
          XCTAssertFalse(types.isEmpty)

          let handler = await registry.getHandler(for: "google.protobuf.Timestamp")
          XCTAssertNotNil(handler)
        }
      }
    }
  }

  func testGetHandler() async throws {
    let registry = WellKnownTypesRegistry.shared

    let timestampHandler = await registry.getHandler(for: "google.protobuf.Timestamp")
    XCTAssertNotNil(timestampHandler)
    XCTAssertTrue(timestampHandler is TimestampHandler.Type)

    let unknownHandler = await registry.getHandler(for: "unknown.type")
    XCTAssertNil(unknownHandler)
  }

  func testRegistryCreateSpecializedSuccess() async throws {
    let registry = WellKnownTypesRegistry.shared

    let timestampMessage = try createTestTimestampMessage(seconds: 1_234_567_890, nanos: 123_456_789)

    do {
      let specialized = try await registry.createSpecialized(
        from: timestampMessage,
        typeName: "google.protobuf.Timestamp"
      )
      XCTAssertTrue(specialized is TimestampHandler.TimestampValue)

      if let timestamp = specialized as? TimestampHandler.TimestampValue {
        XCTAssertEqual(timestamp.seconds, 1_234_567_890)
        XCTAssertEqual(timestamp.nanos, 123_456_789)
      }
    }
    catch {
      XCTFail("Failed to create specialized object: \(error)")
    }
  }

  func testRegistryCreateSpecializedHandlerNotFound() async throws {
    let registry = WellKnownTypesRegistry.shared

    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let testMessage = factory.createMessage(from: messageDescriptor)

    do {
      _ = try await registry.createSpecialized(from: testMessage, typeName: "unknown.Type")
      XCTFail("Expected handlerNotFound error")
    }
    catch let error as WellKnownTypeError {
      guard case .handlerNotFound(let typeName) = error else {
        XCTFail("Expected handlerNotFound error, got: \(error)")
        return
      }
      XCTAssertEqual(typeName, "unknown.Type")
    }
  }

  func testRegistryCreateDynamicSuccess() async throws {
    let registry = WellKnownTypesRegistry.shared

    let timestampValue = try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_789)

    do {
      let dynamicMessage = try await registry.createDynamic(
        from: timestampValue,
        typeName: "google.protobuf.Timestamp"
      )
      XCTAssertEqual(dynamicMessage.descriptor.fullName, "google.protobuf.Timestamp")

      let seconds = try dynamicMessage.get(forField: "seconds") as! Int64
      let nanos = try dynamicMessage.get(forField: "nanos") as! Int32

      XCTAssertEqual(seconds, 1_234_567_890)
      XCTAssertEqual(nanos, 123_456_789)
    }
    catch {
      XCTFail("Failed to create dynamic message: \(error)")
    }
  }

  func testRegistryCreateDynamicHandlerNotFound() async throws {
    let registry = WellKnownTypesRegistry.shared

    let testSpecialized = "not a well-known type"

    do {
      _ = try await registry.createDynamic(from: testSpecialized, typeName: "unknown.Type")
      XCTFail("Expected handlerNotFound error")
    }
    catch let error as WellKnownTypeError {
      guard case .handlerNotFound(let typeName) = error else {
        XCTFail("Expected handlerNotFound error, got: \(error)")
        return
      }
      XCTAssertEqual(typeName, "unknown.Type")
    }
  }

  func testRegistryClear() async throws {
    let registry = WellKnownTypesRegistry()

    let typesBeforeClear = await registry.getRegisteredTypes()
    XCTAssertFalse(typesBeforeClear.isEmpty)
    XCTAssertTrue(typesBeforeClear.contains("google.protobuf.Timestamp"))

    await registry.clear()

    let typesAfterClear = await registry.getRegisteredTypes()
    XCTAssertTrue(typesAfterClear.isEmpty)

    let handler = await registry.getHandler(for: "google.protobuf.Timestamp")
    XCTAssertNil(handler)

    await registry.resetToDefaults()

    let restoredTypes = await registry.getRegisteredTypes()
    XCTAssertFalse(restoredTypes.isEmpty)
    XCTAssertTrue(restoredTypes.contains("google.protobuf.Timestamp"))
  }

  func testRegistryConversionWithHandlerErrors() async throws {
    let registry = WellKnownTypesRegistry.shared

    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "WrongMessage", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    do {
      _ = try await registry.createSpecialized(from: wrongMessage, typeName: "google.protobuf.Timestamp")
      XCTFail("Expected invalidData error")
    }
    catch let error as WellKnownTypeError {
      guard case .invalidData = error else {
        XCTFail("Expected invalidData error from handler, got: \(error)")
        return
      }
    }

    let wrongSpecialized = "not a timestamp value"
    do {
      _ = try await registry.createDynamic(from: wrongSpecialized, typeName: "google.protobuf.Timestamp")
      XCTFail("Expected conversionFailed error")
    }
    catch let error as WellKnownTypeError {
      guard case .conversionFailed = error else {
        XCTFail("Expected conversionFailed error from handler, got: \(error)")
        return
      }
    }
  }

  // MARK: - Helper Methods

  private func createTestTimestampMessage(seconds: Int64, nanos: Int32) throws -> DynamicMessage {
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/timestamp.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "Timestamp",
      parent: fileDescriptor
    )

    let secondsField = FieldDescriptor(
      name: "seconds",
      number: 1,
      type: .int64
    )
    messageDescriptor.addField(secondsField)

    let nanosField = FieldDescriptor(
      name: "nanos",
      number: 2,
      type: .int32
    )
    messageDescriptor.addField(nanosField)

    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    try message.set(seconds, forField: "seconds")
    try message.set(nanos, forField: "nanos")

    return message
  }
}

// MARK: - Mock Handler for Testing

struct MockWellKnownTypeHandler: WellKnownTypeHandler {
  static let handledTypeName = "test.MockType"
  static let supportPhase: WellKnownSupportPhase = .critical

  static func createSpecialized(from message: DynamicMessage) throws -> Any {
    return "specialized"
  }

  static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    // Create simple mock descriptor for testing
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "MockType", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    return factory.createMessage(from: messageDescriptor)
  }

  static func validate(_ specialized: Any) -> Bool {
    return specialized is String
  }
}
