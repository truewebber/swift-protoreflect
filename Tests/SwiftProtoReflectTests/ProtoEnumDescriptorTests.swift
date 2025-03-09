import XCTest
@testable import SwiftProtoReflect

class ProtoEnumDescriptorTests: XCTestCase {

    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given
        let name = "TestEnum"
        let values = [
            ProtoEnumValueDescriptor(name: "VALUE_1", number: 1),
            ProtoEnumValueDescriptor(name: "VALUE_2", number: 2)
        ]
        
        // When
        let descriptor = ProtoEnumDescriptor(name: name, values: values)
        
        // Then
        XCTAssertEqual(descriptor.name, name)
        XCTAssertEqual(descriptor.values.count, 2)
        XCTAssertEqual(descriptor.values[0].name, "VALUE_1")
        XCTAssertEqual(descriptor.values[1].number, 2)
    }
    
    // MARK: - Value Access Tests

    func testGetEnumValueByName() {
        // Given
        let value = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [value])
        
        // When
        let retrievedValue = descriptor.value(named: "VALUE_1")
        
        // Then
        XCTAssertNotNil(retrievedValue)
        XCTAssertEqual(retrievedValue?.number, 1)
    }
    
    func testGetEnumValueByNumber() {
        // Given
        let value = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [value])
        
        // When
        let retrievedValue = descriptor.value(by: 1)
        
        // Then
        XCTAssertNotNil(retrievedValue)
        XCTAssertEqual(retrievedValue?.name, "VALUE_1")
    }

    func testGetNonExistentEnumValueByName() {
        // Given
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [
            ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
        ])
        
        // When
        let value = descriptor.value(named: "NON_EXISTENT")
        
        // Then
        XCTAssertNil(value)
    }
    
    func testGetNonExistentEnumValueByNumber() {
        // Given
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [
            ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
        ])
        
        // When
        let value = descriptor.value(by: 999)
        
        // Then
        XCTAssertNil(value)
    }
    
    // MARK: - Validation Tests

    func testValidEnumDescriptor() {
        // Given
        let value = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [value])
        
        // Then
        XCTAssertTrue(descriptor.isValid())
        XCTAssertNil(descriptor.validationError())
    }

    func testInvalidEnumDescriptorEmptyName() {
        // Given
        let descriptor = ProtoEnumDescriptor(name: "", values: [
            ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
        ])
        
        // Then
        XCTAssertFalse(descriptor.isValid())
        XCTAssertEqual(descriptor.validationError(), "Enum name cannot be empty")
    }
    
    func testInvalidEnumDescriptorNoValues() {
        // Given
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [])
        
        // Then
        XCTAssertFalse(descriptor.isValid())
        XCTAssertEqual(descriptor.validationError(), "Enum TestEnum must have at least one value")
    }
    
    func testInvalidEnumDescriptorDuplicateValueNumbers() {
        // Given
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [
            ProtoEnumValueDescriptor(name: "VALUE_1", number: 1),
            ProtoEnumValueDescriptor(name: "VALUE_2", number: 1) // Same number
        ])
        
        // Then
        XCTAssertNotNil(descriptor.validationError())
        XCTAssertTrue(descriptor.validationError()?.contains("Duplicate value number") ?? false)
    }
    
    func testInvalidEnumDescriptorDuplicateValueNames() {
        // Given
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [
            ProtoEnumValueDescriptor(name: "SAME_NAME", number: 1),
            ProtoEnumValueDescriptor(name: "SAME_NAME", number: 2) // Same name
        ])
        
        // Then
        XCTAssertNotNil(descriptor.validationError())
        XCTAssertTrue(descriptor.validationError()?.contains("Duplicate value name") ?? false)
    }
    
    func testInvalidEnumDescriptorInvalidValue() {
        // Given
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [
            ProtoEnumValueDescriptor(name: "", number: 1) // Empty name
        ])
        
        // Then
        XCTAssertNotNil(descriptor.validationError())
        XCTAssertTrue(descriptor.validationError()?.contains("Invalid value") ?? false)
    }
    
    // MARK: - Edge Case Tests
    
    func testEnumDescriptorWithManyValues() {
        // Given
        var values: [ProtoEnumValueDescriptor] = []
        for i in 0..<50 {
            values.append(ProtoEnumValueDescriptor(name: "VALUE_\(i)", number: i))
        }
        
        // When
        let descriptor = ProtoEnumDescriptor(name: "LargeEnum", values: values)
        
        // Then
        XCTAssertTrue(descriptor.isValid())
        XCTAssertEqual(descriptor.values.count, 50)
        XCTAssertNotNil(descriptor.value(named: "VALUE_25"))
        XCTAssertEqual(descriptor.value(by: 25)?.name, "VALUE_25")
    }
    
    func testEnumDescriptorWithNegativeValues() {
        // Given
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [
            ProtoEnumValueDescriptor(name: "NEGATIVE", number: -1),
            ProtoEnumValueDescriptor(name: "ZERO", number: 0),
            ProtoEnumValueDescriptor(name: "POSITIVE", number: 1)
        ])
        
        // Then
        XCTAssertTrue(descriptor.isValid())
        XCTAssertEqual(descriptor.value(by: -1)?.name, "NEGATIVE")
        XCTAssertEqual(descriptor.value(by: 0)?.name, "ZERO")
        XCTAssertEqual(descriptor.value(by: 1)?.name, "POSITIVE")
    }
}
