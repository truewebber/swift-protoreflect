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
  
  // MARK: - Дополнительные тесты для повышения покрытия
  
  func testEnumValueEqualityWithDifferentOptionTypes() {
    // Тестирование равенства значений перечисления с разными типами опций
    
    // Int опции
    let value1 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["intOption": 10])
    let value2 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["intOption": 10])
    let value3 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["intOption": 20])
    
    XCTAssertEqual(value1, value2)
    XCTAssertNotEqual(value1, value3)
    
    // String опции
    let value4 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["stringOption": "value"])
    let value5 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["stringOption": "value"])
    let value6 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["stringOption": "other"])
    
    XCTAssertEqual(value4, value5)
    XCTAssertNotEqual(value4, value6)
    
    // Custom опции
    class CustomValue: CustomStringConvertible {
      let value: String
      
      init(value: String) {
        self.value = value
      }
      
      var description: String {
        return "CustomValue(\(value))"
      }
    }
    
    let custom1 = CustomValue(value: "test1")
    let custom2 = CustomValue(value: "test1")
    let custom3 = CustomValue(value: "test2")
    
    let value7 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["customOption": custom1])
    let value8 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["customOption": custom2])
    let value9 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["customOption": custom3])
    
    XCTAssertEqual(value7, value8)
    XCTAssertNotEqual(value7, value9)
  }
  
  func testEnumValueWithDifferentOptionKeys() {
    // Проверяем сравнение значений с разными наборами ключей в опциях
    let value1 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["option1": true, "option2": 42])
    let value2 = EnumDescriptor.EnumValue(name: "OPTION1", number: 1, options: ["option1": true, "option3": "value"])
    
    XCTAssertNotEqual(value1, value2)
  }
  
  func testEnumDescriptorWithDifferentFileDescriptorPath() {
    // Проверяем, что дескрипторы с разными путями к файлу не равны
    let enum1 = EnumDescriptor(name: "Status", fullName: "test.Status")
    var enum2 = EnumDescriptor(name: "Status", fullName: "test.Status")
    enum2.fileDescriptorPath = "different_path.proto"
    
    XCTAssertNotEqual(enum1, enum2)
  }
  
  func testEnumDescriptorWithDifferentParentMessageFullName() {
    // Проверяем, что дескрипторы с разными родительскими сообщениями не равны
    let enum1 = EnumDescriptor(name: "Status", fullName: "test.Status")
    var enum2 = EnumDescriptor(name: "Status", fullName: "test.Status")
    enum2.parentMessageFullName = "test.ParentMessage"
    
    XCTAssertNotEqual(enum1, enum2)
  }
  
  func testEnumDescriptorWithDifferentOptionTypes() {
    // Тестирование дескрипторов с разными типами опций
    
    // Int опции
    let enum1 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["intOption": 10])
    let enum2 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["intOption": 10])
    let enum3 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["intOption": 20])
    
    XCTAssertEqual(enum1, enum2)
    XCTAssertNotEqual(enum1, enum3)
    
    // String опции
    let enum4 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["stringOption": "value"])
    let enum5 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["stringOption": "value"])
    let enum6 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["stringOption": "other"])
    
    XCTAssertEqual(enum4, enum5)
    XCTAssertNotEqual(enum4, enum6)
    
    // Custom опции
    class CustomValue: CustomStringConvertible {
      let value: String
      
      init(value: String) {
        self.value = value
      }
      
      var description: String {
        return "CustomValue(\(value))"
      }
    }
    
    let custom1 = CustomValue(value: "test1")
    let custom2 = CustomValue(value: "test1")
    let custom3 = CustomValue(value: "test2")
    
    let enum7 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["customOption": custom1])
    let enum8 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["customOption": custom2])
    let enum9 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["customOption": custom3])
    
    XCTAssertEqual(enum7, enum8)
    XCTAssertNotEqual(enum7, enum9)
  }
  
  func testEnumDescriptorWithDifferentOptionKeys() {
    // Проверяем сравнение дескрипторов с разными наборами ключей в опциях
    let enum1 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["option1": true, "option2": 42])
    let enum2 = EnumDescriptor(name: "Status", fullName: "test.Status", options: ["option1": true, "option3": "value"])
    
    XCTAssertNotEqual(enum1, enum2)
  }
  
  func testEnumDescriptorWithDifferentEnumValues() {
    // Проверка сравнения дескрипторов с разными наборами значений
    var enum1 = EnumDescriptor(name: "Status", parent: fileDescriptor)
    var enum2 = EnumDescriptor(name: "Status", parent: fileDescriptor)
    
    // Добавляем одинаковые значения, но с разными именами
    enum1.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 1))
    enum1.addValue(EnumDescriptor.EnumValue(name: "VALUE2", number: 2))
    
    enum2.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 1))
    enum2.addValue(EnumDescriptor.EnumValue(name: "DIFFERENT", number: 2))
    
    XCTAssertNotEqual(enum1, enum2)
  }
}
