//
// DynamicMessageBenchmarks.swift
//
// Performance benchmarks для DynamicMessage операций
//
// Тестовые случаи:
// - Field access performance (get/set operations)
// - Message creation and cloning performance
// - Well-Known Types conversion performance
// - Large message manipulation performance

import XCTest
@testable import SwiftProtoReflect

/// Performance benchmarks для DynamicMessage операций
final class DynamicMessageBenchmarks: XCTestCase {
    
    // MARK: - Test Setup
    
    private var simpleMessage: DynamicMessage!
    private var complexMessage: DynamicMessage!
    private var largeMessage: DynamicMessage!
    private var messageFactory: MessageFactory!
    private var registry: TypeRegistry!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        messageFactory = MessageFactory()
        registry = TypeRegistry()
        
        try setupTestMessages()
    }
    
    private func setupTestMessages() throws {
        // Simple message для базовых операций
        let simpleDescriptor = try createSimpleMessageDescriptor()
        try registry.registerMessage(simpleDescriptor)
        simpleMessage = messageFactory.createMessage(from: simpleDescriptor)
        
        // Nested message descriptor (нужно создать до complex message)
        let nestedDescriptor = try createNestedMessageDescriptor()
        try registry.registerMessage(nestedDescriptor)
        
        // Complex message с вложенными структурами
        let complexDescriptor = try createComplexMessageDescriptor()
        try registry.registerMessage(complexDescriptor)
        complexMessage = messageFactory.createMessage(from: complexDescriptor)
        
        // Large message с множеством полей
        let largeDescriptor = try createLargeMessageDescriptor()
        try registry.registerMessage(largeDescriptor)
        largeMessage = messageFactory.createMessage(from: largeDescriptor)
        
        // Заполняем сообщения данными
        try populateMessages()
    }
    
    private func populateMessages() throws {
        // Заполняем simple message
        try simpleMessage.set("Test String", forField: "text_field")
        try simpleMessage.set(Int32(42), forField: "int_field")
        try simpleMessage.set(true, forField: "bool_field")
        
        // Заполняем complex message
        try complexMessage.set("Complex Message", forField: "name")
        try complexMessage.set(["item1", "item2", "item3"], forField: "repeated_strings")
        
        // Создаем nested message
        let nestedDescriptor = try createNestedMessageDescriptor()
        var nestedMessage = messageFactory.createMessage(from: nestedDescriptor)
        try nestedMessage.set("Nested Value", forField: "nested_text")
        try nestedMessage.set(Int32(100), forField: "nested_number")
        try complexMessage.set(nestedMessage, forField: "nested_message")
        
        // Заполняем large message множеством полей
        for i in 0..<100 {
            try largeMessage.set("String \(i)", forField: "string_field_\(i)")
            try largeMessage.set(Int32(i), forField: "int_field_\(i)")
        }
    }
    
    // MARK: - Field Access Performance Tests
    
    /// Performance test для get операций
    func testFieldGetPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = try? simpleMessage.get(forField: "text_field")
                let _ = try? simpleMessage.get(forField: "int_field")
                let _ = try? simpleMessage.get(forField: "bool_field")
            }
        }
    }
    
    /// Performance test для set операций
    func testFieldSetPerformance() {
        measure {
            do {
                for i in 0..<1000 {
                    try simpleMessage.set("Updated String \(i)", forField: "text_field")
                    try simpleMessage.set(Int32(i), forField: "int_field")
                    try simpleMessage.set(i % 2 == 0, forField: "bool_field")
                }
            } catch {
                XCTFail("Set operations failed: \(error)")
            }
        }
    }
    
    /// Performance test для repeated field операций
    func testRepeatedFieldPerformance() {
        measure {
            do {
                for i in 0..<100 {
                    let items = (0..<10).map { "Item \(i)_\($0)" }
                    try complexMessage.set(items, forField: "repeated_strings")
                }
            } catch {
                XCTFail("Repeated field operations failed: \(error)")
            }
        }
    }
    
    /// Performance test для nested message access
    func testNestedMessageAccessPerformance() {
        measure {
            for _ in 0..<1000 {
                if let nested = try? complexMessage.get(forField: "nested_message") as? DynamicMessage {
                    let _ = try? nested.get(forField: "nested_text")
                    let _ = try? nested.get(forField: "nested_number")
                }
            }
        }
    }
    
    // MARK: - Message Creation Performance Tests
    
    /// Performance test для создания сообщений
    func testMessageCreationPerformance() {
        measure {
            do {
                for _ in 0..<1000 {
                    var message = messageFactory.createMessage(from: simpleMessage.descriptor)
                    try message.set("Test", forField: "text_field")
                    try message.set(Int32(42), forField: "int_field")
                    try message.set(true, forField: "bool_field")
                }
            } catch {
                XCTFail("Message creation failed: \(error)")
            }
        }
    }
    
    /// Performance test для клонирования сообщений
    func testMessageCloningPerformance() {
        measure {
            do {
                for _ in 0..<1000 {
                    let _ = try messageFactory.clone(complexMessage)
                }
            } catch {
                XCTFail("Message cloning failed: \(error)")
            }
        }
    }
    
    /// Performance test для создания больших сообщений
    func testLargeMessageCreationPerformance() {
        measure {
            do {
                for _ in 0..<100 {
                    var message = messageFactory.createMessage(from: largeMessage.descriptor)
                    
                    // Заполняем множество полей
                    for i in 0..<50 {
                        try message.set("String \(i)", forField: "string_field_\(i)")
                        try message.set(Int32(i), forField: "int_field_\(i)")
                    }
                }
            } catch {
                XCTFail("Large message creation failed: \(error)")
            }
        }
    }
    
    // MARK: - Well-Known Types Performance Tests
    
    /// Performance test для Timestamp conversions
    func testTimestampConversionPerformance() throws {
        let timestampDescriptor = try createTimestampDescriptor()
        try registry.registerMessage(timestampDescriptor)
        
        measure {
            do {
                for _ in 0..<1000 {
                    var timestampMessage = messageFactory.createMessage(from: timestampDescriptor)
                    let now = Date()
                    
                    // Convert Date to Timestamp
                    let seconds = Int64(now.timeIntervalSince1970)
                    let nanos = Int32((now.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)) * 1_000_000_000)
                    
                    try timestampMessage.set(seconds, forField: "seconds")
                    try timestampMessage.set(nanos, forField: "nanos")
                    
                    // Convert back to Date
                    if let timestampSeconds = try timestampMessage.get(forField: "seconds") as? Int64,
                       let timestampNanos = try timestampMessage.get(forField: "nanos") as? Int32 {
                        let _ = Date(timeIntervalSince1970: Double(timestampSeconds) + Double(timestampNanos) / 1_000_000_000)
                    }
                }
            } catch {
                XCTFail("Timestamp conversion failed: \(error)")
            }
        }
    }
    
    /// Performance test для Struct conversions
    func testStructConversionPerformance() throws {
        let structDescriptor = try createStructDescriptor()
        try registry.registerMessage(structDescriptor)
        
        measure {
            do {
                for _ in 0..<1000 {
                    var structMessage = messageFactory.createMessage(from: structDescriptor)
                    
                    // Create complex struct data
                    let structData: [String: String] = [
                        "string_value": "test string",
                        "number_value": "42.5",
                        "bool_value": "true",
                        "null_value": "",
                        "list_value": "item1,item2,123",
                        "struct_value": "nested_string:nested value,nested_number:100"
                    ]
                    
                    // Convert to Struct message (simplified)
                    try structMessage.set(structData, forField: "fields")
                    
                    // Read back
                    let _ = try structMessage.get(forField: "fields")
                }
            } catch {
                XCTFail("Struct conversion failed: \(error)")
            }
        }
    }
    
    // MARK: - Memory Usage Tests
    
    /// Memory usage test для больших сообщений
    func testLargeMessageMemoryUsage() {
        measure {
            do {
                var messages: [DynamicMessage] = []
                
                // Создаем множество больших сообщений
                for i in 0..<100 {
                    var message = messageFactory.createMessage(from: largeMessage.descriptor)
                    
                    // Заполняем большим количеством данных
                    for j in 0..<100 {
                        try message.set("Large String Data \(i)_\(j) with additional content to increase memory usage", forField: "string_field_\(j)")
                        try message.set(Int32(i * 1000 + j), forField: "int_field_\(j)")
                    }
                    
                    messages.append(message)
                }
                
                // Выполняем операции с сообщениями
                for message in messages {
                    let _ = try? message.get(forField: "string_field_0")
                    let _ = try? message.get(forField: "int_field_0")
                }
            } catch {
                XCTFail("Large message memory test failed: \(error)")
            }
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    /// Performance test для concurrent field access
    func testConcurrentFieldAccessPerformance() {
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        measure {
            let expectation = self.expectation(description: "Concurrent field access")
            expectation.expectedFulfillmentCount = 100
            
            // Concurrent read operations
            for _ in 0..<100 {
                queue.async {
                    // Concurrent read operations
                    for _ in 0..<10 {
                        let _ = try? self.complexMessage.get(forField: "name")
                        let _ = try? self.complexMessage.get(forField: "repeated_strings")
                        let _ = try? self.complexMessage.get(forField: "nested_message")
                    }
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    /// Performance test для concurrent message creation
    func testConcurrentMessageCreationPerformance() {
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        measure {
            let expectation = self.expectation(description: "Concurrent message creation")
            expectation.expectedFulfillmentCount = 100
            
            for i in 0..<100 {
                queue.async {
                    do {
                        var message = self.messageFactory.createMessage(from: self.simpleMessage.descriptor)
                        try message.set("Concurrent Test \(i)", forField: "text_field")
                        try message.set(Int32(i), forField: "int_field")
                        try message.set(i % 2 == 0, forField: "bool_field")
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Validation Performance Tests
    
    /// Performance test для валидации сообщений
    func testMessageValidationPerformance() {
        measure {
            for _ in 0..<1000 {
                let result = messageFactory.validate(complexMessage)
                XCTAssertTrue(result.isValid)
            }
        }
    }
    
    // MARK: - Helper Methods for Descriptor Creation
    
    private func createSimpleMessageDescriptor() throws -> MessageDescriptor {
        let fileDescriptor = FileDescriptor(name: "simple.proto", package: "performance.test")
        var messageDescriptor = MessageDescriptor(name: "SimpleMessage", parent: fileDescriptor)
        
        messageDescriptor.addField(FieldDescriptor(name: "text_field", number: 1, type: .string))
        messageDescriptor.addField(FieldDescriptor(name: "int_field", number: 2, type: .int32))
        messageDescriptor.addField(FieldDescriptor(name: "bool_field", number: 3, type: .bool))
        
        var fileDescriptorMutable = fileDescriptor
        fileDescriptorMutable.addMessage(messageDescriptor)
        return messageDescriptor
    }
    
    private func createComplexMessageDescriptor() throws -> MessageDescriptor {
        let fileDescriptor = FileDescriptor(name: "complex.proto", package: "performance.test")
        var messageDescriptor = MessageDescriptor(name: "ComplexMessage", parent: fileDescriptor)
        
        messageDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        messageDescriptor.addField(FieldDescriptor(name: "repeated_strings", number: 2, type: .string, isRepeated: true))
        messageDescriptor.addField(FieldDescriptor(name: "nested_message", number: 3, type: .message, typeName: "performance.test.NestedMessage"))
        
        var fileDescriptorMutable = fileDescriptor
        fileDescriptorMutable.addMessage(messageDescriptor)
        return messageDescriptor
    }
    
    private func createNestedMessageDescriptor() throws -> MessageDescriptor {
        let fileDescriptor = FileDescriptor(name: "nested.proto", package: "performance.test")
        var messageDescriptor = MessageDescriptor(name: "NestedMessage", parent: fileDescriptor)
        
        messageDescriptor.addField(FieldDescriptor(name: "nested_text", number: 1, type: .string))
        messageDescriptor.addField(FieldDescriptor(name: "nested_number", number: 2, type: .int32))
        
        var fileDescriptorMutable = fileDescriptor
        fileDescriptorMutable.addMessage(messageDescriptor)
        return messageDescriptor
    }
    
    private func createLargeMessageDescriptor() throws -> MessageDescriptor {
        let fileDescriptor = FileDescriptor(name: "large.proto", package: "performance.test")
        var messageDescriptor = MessageDescriptor(name: "LargeMessage", parent: fileDescriptor)
        
        // Добавляем множество полей
        for i in 0..<100 {
            messageDescriptor.addField(FieldDescriptor(name: "string_field_\(i)", number: i * 2 + 1, type: .string))
            messageDescriptor.addField(FieldDescriptor(name: "int_field_\(i)", number: i * 2 + 2, type: .int32))
        }
        
        var fileDescriptorMutable = fileDescriptor
        fileDescriptorMutable.addMessage(messageDescriptor)
        return messageDescriptor
    }
    
    private func createTimestampDescriptor() throws -> MessageDescriptor {
        let fileDescriptor = FileDescriptor(name: "timestamp.proto", package: "google.protobuf")
        var messageDescriptor = MessageDescriptor(name: "Timestamp", parent: fileDescriptor)
        
        messageDescriptor.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
        messageDescriptor.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
        
        var fileDescriptorMutable = fileDescriptor
        fileDescriptorMutable.addMessage(messageDescriptor)
        return messageDescriptor
    }
    
    private func createStructDescriptor() throws -> MessageDescriptor {
        let fileDescriptor = FileDescriptor(name: "struct.proto", package: "google.protobuf")
        var messageDescriptor = MessageDescriptor(name: "Struct", parent: fileDescriptor)
        
        messageDescriptor.addField(FieldDescriptor(
            name: "fields",
            number: 1,
            type: .string,
            isMap: true,
            mapEntryInfo: MapEntryInfo(
                keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
                valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
            )
        ))
        
        var fileDescriptorMutable = fileDescriptor
        fileDescriptorMutable.addMessage(messageDescriptor)
        return messageDescriptor
    }
}
