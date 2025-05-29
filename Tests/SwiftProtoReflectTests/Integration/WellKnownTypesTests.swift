/**
 * WellKnownTypesTests.swift
 * SwiftProtoReflectTests
 *
 * Тесты для модуля WellKnownTypes
 */

import XCTest
@testable import SwiftProtoReflect

final class WellKnownTypesTests: XCTestCase {
    
    // MARK: - WellKnownTypeNames Tests
    
    func testTypeNameConstants() {
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
    
    func testTypeCollections() {
        // All types должен содержать все типы
        XCTAssertEqual(WellKnownTypeNames.allTypes.count, 9)
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
    
    func testCollectionsDoNotOverlap() {
        // Проверяем, что коллекции не пересекаются
        let criticalAndImportant = WellKnownTypeNames.criticalTypes.intersection(WellKnownTypeNames.importantTypes)
        XCTAssertTrue(criticalAndImportant.isEmpty)
        
        let criticalAndAdvanced = WellKnownTypeNames.criticalTypes.intersection(WellKnownTypeNames.advancedTypes)
        XCTAssertTrue(criticalAndAdvanced.isEmpty)
        
        let importantAndAdvanced = WellKnownTypeNames.importantTypes.intersection(WellKnownTypeNames.advancedTypes)
        XCTAssertTrue(importantAndAdvanced.isEmpty)
    }
    
    // MARK: - WellKnownTypeDetector Tests
    
    func testIsWellKnownType() {
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
    
    func testGetSupportPhase() {
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
    
    func testGetSimpleName() {
        XCTAssertEqual(WellKnownTypeDetector.getSimpleName(for: "google.protobuf.Timestamp"), "Timestamp")
        XCTAssertEqual(WellKnownTypeDetector.getSimpleName(for: "google.protobuf.Duration"), "Duration")
        XCTAssertEqual(WellKnownTypeDetector.getSimpleName(for: "google.protobuf.Empty"), "Empty")
        XCTAssertEqual(WellKnownTypeDetector.getSimpleName(for: "google.protobuf.FieldMask"), "FieldMask")
        
        // Unknown types
        XCTAssertNil(WellKnownTypeDetector.getSimpleName(for: "com.example.MyMessage"))
        XCTAssertNil(WellKnownTypeDetector.getSimpleName(for: ""))
    }
    
    // MARK: - WellKnownSupportPhase Tests
    
    func testSupportPhaseProperties() {
        XCTAssertEqual(WellKnownSupportPhase.critical.rawValue, 1)
        XCTAssertEqual(WellKnownSupportPhase.important.rawValue, 2)
        XCTAssertEqual(WellKnownSupportPhase.advanced.rawValue, 3)
        
        XCTAssertEqual(WellKnownSupportPhase.critical.description, "Critical Types (Phase 1)")
        XCTAssertEqual(WellKnownSupportPhase.important.description, "Important Types (Phase 2)")
        XCTAssertEqual(WellKnownSupportPhase.advanced.description, "Advanced Types (Phase 3)")
    }
    
    func testSupportPhaseIncludedTypes() {
        XCTAssertEqual(WellKnownSupportPhase.critical.includedTypes, WellKnownTypeNames.criticalTypes)
        XCTAssertEqual(WellKnownSupportPhase.important.includedTypes, WellKnownTypeNames.importantTypes)
        XCTAssertEqual(WellKnownSupportPhase.advanced.includedTypes, WellKnownTypeNames.advancedTypes)
    }
    
    func testAllCases() {
        let allCases = WellKnownSupportPhase.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.critical))
        XCTAssertTrue(allCases.contains(.important))
        XCTAssertTrue(allCases.contains(.advanced))
    }
    
    // MARK: - WellKnownTypeError Tests
    
    func testErrorEquality() {
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
    
    func testErrorDescriptions() {
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
    
    func testRegistryInitialization() {
        let registry = WellKnownTypesRegistry.shared
        
        // Проверяем, что registry инициализирован
        XCTAssertNotNil(registry)
        
        // Проверяем, что TimestampHandler зарегистрирован по умолчанию
        let registeredTypes = registry.getRegisteredTypes()
        XCTAssertTrue(registeredTypes.contains("google.protobuf.Timestamp"))
    }
    
    func testRegistryThreadSafety() {
        let registry = WellKnownTypesRegistry.shared
        let expectation = self.expectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        // Запускаем несколько потоков
        for i in 0..<10 {
            DispatchQueue.global().async {
                // Выполняем операции с registry
                let types = registry.getRegisteredTypes()
                XCTAssertFalse(types.isEmpty)
                
                // Попытка получить обработчик
                let handler = registry.getHandler(for: "google.protobuf.Timestamp")
                XCTAssertNotNil(handler)
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testGetHandler() {
        let registry = WellKnownTypesRegistry.shared
        
        // Получаем зарегистрированный обработчик
        let timestampHandler = registry.getHandler(for: "google.protobuf.Timestamp")
        XCTAssertNotNil(timestampHandler)
        XCTAssertTrue(timestampHandler is TimestampHandler.Type)
        
        // Несуществующий обработчик
        let unknownHandler = registry.getHandler(for: "unknown.type")
        XCTAssertNil(unknownHandler)
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
        // Создаем простой mock дескриптор для тестирования
        var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
        var messageDescriptor = MessageDescriptor(name: "MockType", parent: fileDescriptor)
        fileDescriptor.addMessage(messageDescriptor)
        
        let factory = MessageFactory()
        return factory.createMessage(from: messageDescriptor)
    }
    
    static func validate(_ specialized: Any) -> Bool {
        return specialized is String
    }
} 