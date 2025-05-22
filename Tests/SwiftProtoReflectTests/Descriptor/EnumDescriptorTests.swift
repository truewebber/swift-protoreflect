//
// EnumDescriptorTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-22
//

import XCTest
@testable import SwiftProtoReflect

final class EnumDescriptorTests: XCTestCase {
  // MARK: - Properties
  var fileDescriptor: FileDescriptor!
  var messageDescriptor: MessageDescriptor!
  
  // MARK: - Setup
  
  override func setUp() {
    super.setUp()
    fileDescriptor = FileDescriptor(
      name: "test.proto",
      package: "test",
      dependencies: []
    )
    
    messageDescriptor = MessageDescriptor(
      name: "TestMessage",
      parent: fileDescriptor
    )
  }
  
  override func tearDown() {
    fileDescriptor = nil
    messageDescriptor = nil
    super.tearDown()
  }
  
  // MARK: - Tests
  
  func testInitWithNameAndFullName() {
    // Arrange
    let name = "Status"
    let fullName = "test.Status"
    let options: [String: Any] = ["deprecated": true]
    
    // Act
    let enumDescriptor = EnumDescriptor(
      name: name,
      fullName: fullName,
      options: options
    )
    
    // Assert
    XCTAssertEqual(enumDescriptor.name, name)
    XCTAssertEqual(enumDescriptor.fullName, fullName)
    XCTAssertEqual(enumDescriptor.options as? [String: Bool], ["deprecated": true])
  }
  
  func testInitWithParentFileDescriptor() {
    // Arrange
    let name = "Status"
    
    // Act
    let enumDescriptor = EnumDescriptor(
      name: name,
      parent: fileDescriptor
    )
    
    // Assert
    XCTAssertEqual(enumDescriptor.name, name)
    XCTAssertEqual(enumDescriptor.fullName, "test.Status")
    XCTAssertEqual(enumDescriptor.fileDescriptorPath, fileDescriptor.name)
    XCTAssertNil(enumDescriptor.parentMessageFullName)
  }
  
  func testInitWithParentMessageDescriptor() {
    // Arrange
    let name = "Status"
    
    // Act
    let enumDescriptor = EnumDescriptor(
      name: name,
      parent: messageDescriptor
    )
    
    // Assert
    XCTAssertEqual(enumDescriptor.name, name)
    XCTAssertEqual(enumDescriptor.fullName, "test.TestMessage.Status")
    XCTAssertEqual(enumDescriptor.fileDescriptorPath, fileDescriptor.name)
    XCTAssertEqual(enumDescriptor.parentMessageFullName, messageDescriptor.fullName)
  }
  
  func testInitWithNoParent() {
    // Arrange
    let name = "Status"
    
    // Act
    let enumDescriptor = EnumDescriptor(
      name: name
    )
    
    // Assert
    XCTAssertEqual(enumDescriptor.name, name)
    XCTAssertEqual(enumDescriptor.fullName, name)
    XCTAssertNil(enumDescriptor.fileDescriptorPath)
    XCTAssertNil(enumDescriptor.parentMessageFullName)
  }
  
  func testAddAndRetrieveEnumValue() {
    // Arrange
    var enumDescriptor = EnumDescriptor(
      name: "Status",
      parent: fileDescriptor
    )
    let value1 = EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0)
    let value2 = EnumDescriptor.EnumValue(name: "STARTED", number: 1)
    let value3 = EnumDescriptor.EnumValue(name: "RUNNING", number: 2)
    
    // Act
    enumDescriptor.addValue(value1)
    enumDescriptor.addValue(value2)
    enumDescriptor.addValue(value3)
    
    // Assert
    XCTAssertTrue(enumDescriptor.hasValue(named: "UNKNOWN"))
    XCTAssertTrue(enumDescriptor.hasValue(number: 0))
    XCTAssertEqual(enumDescriptor.value(named: "RUNNING"), value3)
    XCTAssertEqual(enumDescriptor.value(number: 1), value2)
    XCTAssertNil(enumDescriptor.value(named: "NONEXISTENT"))
    XCTAssertNil(enumDescriptor.value(number: 99))
  }
  
  func testAllValues() {
    // Arrange
    var enumDescriptor = EnumDescriptor(
      name: "Status",
      parent: fileDescriptor
    )
    let value1 = EnumDescriptor.EnumValue(name: "FINISHED", number: 4)
    let value2 = EnumDescriptor.EnumValue(name: "STARTED", number: 1)
    let value3 = EnumDescriptor.EnumValue(name: "RUNNING", number: 2)
    
    // Act
    enumDescriptor.addValue(value1)
    enumDescriptor.addValue(value2)
    enumDescriptor.addValue(value3)
    let allValues = enumDescriptor.allValues()
    
    // Assert
    XCTAssertEqual(allValues.count, 3)
    XCTAssertEqual(allValues[0], value2)  // number = 1
    XCTAssertEqual(allValues[1], value3)  // number = 2
    XCTAssertEqual(allValues[2], value1)  // number = 4
  }
  
  func testEnumValueEquality() {
    // Arrange
    let options1: [String: Any] = ["deprecated": true]
    let options2: [String: Any] = ["deprecated": true]
    let options3: [String: Any] = ["deprecated": false]
    
    let value1 = EnumDescriptor.EnumValue(name: "ACTIVE", number: 1, options: options1)
    let value2 = EnumDescriptor.EnumValue(name: "ACTIVE", number: 1, options: options2)
    let value3 = EnumDescriptor.EnumValue(name: "ACTIVE", number: 2, options: options1)
    let value4 = EnumDescriptor.EnumValue(name: "INACTIVE", number: 1, options: options1)
    let value5 = EnumDescriptor.EnumValue(name: "ACTIVE", number: 1, options: options3)
    let value6 = EnumDescriptor.EnumValue(name: "ACTIVE", number: 1)
    
    // Assert
    XCTAssertEqual(value1, value2)
    XCTAssertNotEqual(value1, value3)
    XCTAssertNotEqual(value1, value4)
    XCTAssertNotEqual(value1, value5)
    XCTAssertNotEqual(value1, value6)
  }
  
  func testEnumDescriptorEquality() {
    // Arrange
    var enum1 = EnumDescriptor(name: "Status", parent: fileDescriptor)
    var enum2 = EnumDescriptor(name: "Status", parent: fileDescriptor)
    var enum3 = EnumDescriptor(name: "OtherStatus", parent: fileDescriptor)
    
    let value1 = EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0)
    let value2 = EnumDescriptor.EnumValue(name: "STARTED", number: 1)
    
    enum1.addValue(value1)
    enum1.addValue(value2)
    
    enum2.addValue(value1)
    enum2.addValue(value2)
    
    enum3.addValue(value1)
    enum3.addValue(value2)
    
    // Assert
    XCTAssertEqual(enum1, enum2)
    XCTAssertNotEqual(enum1, enum3)
    
    // Change enum2 by adding a different value
    enum2.addValue(EnumDescriptor.EnumValue(name: "FINISHED", number: 2))
    XCTAssertNotEqual(enum1, enum2)
  }
  
  func testEnumDescriptorEqualityWithDifferentOptions() {
    // Arrange
    var enum1 = EnumDescriptor(
      name: "Status",
      parent: fileDescriptor,
      options: ["allow_alias": true]
    )
    var enum2 = EnumDescriptor(
      name: "Status",
      parent: fileDescriptor,
      options: ["allow_alias": true]
    )
    var enum3 = EnumDescriptor(
      name: "Status",
      parent: fileDescriptor,
      options: ["allow_alias": false]
    )
    
    let value1 = EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0)
    
    enum1.addValue(value1)
    enum2.addValue(value1)
    enum3.addValue(value1)
    
    // Assert
    XCTAssertEqual(enum1, enum2)
    XCTAssertNotEqual(enum1, enum3)
  }
  
  func testChainedAddValue() {
    // Arrange
    var enumDescriptor = EnumDescriptor(name: "Status", parent: fileDescriptor)
    let value1 = EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0)
    let value2 = EnumDescriptor.EnumValue(name: "STARTED", number: 1)
    
    // Act - properly handling mutations
    enumDescriptor = enumDescriptor.addValue(value1)
    enumDescriptor = enumDescriptor.addValue(value2)
    
    // Assert
    XCTAssertEqual(enumDescriptor.allValues().count, 2)
    XCTAssertEqual(enumDescriptor.value(named: "UNKNOWN"), value1)
    XCTAssertEqual(enumDescriptor.value(named: "STARTED"), value2)
  }
}
