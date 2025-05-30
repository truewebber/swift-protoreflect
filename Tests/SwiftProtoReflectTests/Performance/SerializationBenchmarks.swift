//
// SerializationBenchmarks.swift
//
// Тесты для измерения производительности сериализации/десериализации Protocol Buffers
//
// Тестовые случаи из плана:
// - Test-PERF-001: Сравнение времени сериализации с protoc-генерируемым кодом
// - Test-PERF-002: Сравнение времени десериализации с protoc-генерируемым кодом
// - Test-PERF-003: Производительность при работе с большими наборами данных
// - Test-PERF-004: Анализ накладных расходов на рефлексию по сравнению с компилируемым кодом

import XCTest
import SwiftProtobuf
@testable import SwiftProtoReflect

/// Комплексные performance benchmarks для сериализации и десериализации
final class SerializationBenchmarks: XCTestCase {
    
    // MARK: - Test Setup
    
    private var smallMessage: DynamicMessage!
    private var mediumMessage: DynamicMessage!
    private var largeMessage: DynamicMessage!
    private var registry: TypeRegistry!
    private var binarySerializer: BinarySerializer!
    private var binaryDeserializer: BinaryDeserializer!
    private var jsonSerializer: JSONSerializer!
    private var jsonDeserializer: JSONDeserializer!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        registry = TypeRegistry()
        binarySerializer = BinarySerializer()
        binaryDeserializer = BinaryDeserializer()
        jsonSerializer = JSONSerializer()
        jsonDeserializer = JSONDeserializer()
        
        // Создаем тестовые сообщения разного размера
        try setupTestMessages()
    }
    
    private func setupTestMessages() throws {
        // Small message: простое сообщение с несколькими полями
        let smallDescriptor = try createPersonDescriptor()
        try registry.registerMessage(smallDescriptor)
        
        smallMessage = MessageFactory().createMessage(from: smallDescriptor)
        try smallMessage.set("John Doe", forField: "name")
        try smallMessage.set(Int32(30), forField: "age")
        try smallMessage.set("john@example.com", forField: "email")
        
        // Medium message: сообщение с вложенными структурами и repeated полями
        let mediumDescriptor = try createCompanyDescriptor()
        try registry.registerMessage(mediumDescriptor)
        
        mediumMessage = MessageFactory().createMessage(from: mediumDescriptor)
        try mediumMessage.set("TechCorp Inc", forField: "name")
        try mediumMessage.set(Int32(1000), forField: "employee_count")
        
        // Добавляем repeated поля
        let departments = ["Engineering", "Marketing", "Sales", "HR", "Finance"]
        try mediumMessage.set(departments, forField: "departments")
        
        // Large message: большое сообщение с множеством полей и данных
        let largeDescriptor = try createDatabaseDescriptor()
        try registry.registerMessage(largeDescriptor)
        
        largeMessage = MessageFactory().createMessage(from: largeDescriptor)
        try largeMessage.set("ProductDB", forField: "name")
        try largeMessage.set(Int32(50000), forField: "record_count")
        
        // Создаем большой массив данных
        let records = (0..<1000).map { "Record_\($0)" }
        try largeMessage.set(records, forField: "records")
        
        // Добавляем map поле
        let metadata: [String: String] = [
            "version": "2.1.0",
            "environment": "production",
            "region": "us-west-2",
            "backup_schedule": "daily"
        ]
        try largeMessage.set(metadata, forField: "metadata")
    }
    
    // MARK: - Binary Serialization Performance Tests
    
    /// Test-PERF-001: Binary serialization performance - small messages
    func testBinarySerializationPerformanceSmall() {
        measure {
            do {
                let _ = try binarySerializer.serialize(smallMessage)
            } catch {
                XCTFail("Serialization failed: \(error)")
            }
        }
    }
    
    /// Test-PERF-001: Binary serialization performance - medium messages
    func testBinarySerializationPerformanceMedium() {
        measure {
            do {
                let _ = try binarySerializer.serialize(mediumMessage)
            } catch {
                XCTFail("Serialization failed: \(error)")
            }
        }
    }
    
    /// Test-PERF-001: Binary serialization performance - large messages
    func testBinarySerializationPerformanceLarge() {
        measure {
            do {
                let _ = try binarySerializer.serialize(largeMessage)
            } catch {
                XCTFail("Serialization failed: \(error)")
            }
        }
    }
    
    // MARK: - Binary Deserialization Performance Tests
    
    /// Test-PERF-002: Binary deserialization performance - small messages
    func testBinaryDeserializationPerformanceSmall() throws {
        let serializedData = try binarySerializer.serialize(smallMessage)
        
        measure {
            do {
                let _ = try binaryDeserializer.deserialize(
                    serializedData,
                    using: smallMessage.descriptor
                )
            } catch {
                XCTFail("Deserialization failed: \(error)")
            }
        }
    }
    
    /// Test-PERF-002: Binary deserialization performance - medium messages
    func testBinaryDeserializationPerformanceMedium() throws {
        let serializedData = try binarySerializer.serialize(mediumMessage)
        
        measure {
            do {
                let _ = try binaryDeserializer.deserialize(
                    serializedData,
                    using: mediumMessage.descriptor
                )
            } catch {
                XCTFail("Deserialization failed: \(error)")
            }
        }
    }
    
    /// Test-PERF-002: Binary deserialization performance - large messages
    func testBinaryDeserializationPerformanceLarge() throws {
        let serializedData = try binarySerializer.serialize(largeMessage)
        
        measure {
            do {
                let _ = try binaryDeserializer.deserialize(
                    serializedData,
                    using: largeMessage.descriptor
                )
            } catch {
                XCTFail("Deserialization failed: \(error)")
            }
        }
    }
    
    // MARK: - JSON Serialization Performance Tests
    
    /// Test-PERF-001: JSON serialization performance - small messages
    func testJSONSerializationPerformanceSmall() {
        measure {
            do {
                let _ = try jsonSerializer.serialize(smallMessage)
            } catch {
                XCTFail("JSON serialization failed: \(error)")
            }
        }
    }
    
    /// Test-PERF-001: JSON serialization performance - medium messages
    func testJSONSerializationPerformanceMedium() {
        measure {
            do {
                let _ = try jsonSerializer.serialize(mediumMessage)
            } catch {
                XCTFail("JSON serialization failed: \(error)")
            }
        }
    }
    
    /// Test-PERF-001: JSON serialization performance - large messages
    func testJSONSerializationPerformanceLarge() {
        measure {
            do {
                let _ = try jsonSerializer.serialize(largeMessage)
            } catch {
                XCTFail("JSON serialization failed: \(error)")
            }
        }
    }
    
    // MARK: - JSON Deserialization Performance Tests
    
    /// Test-PERF-002: JSON deserialization performance - small messages
    func testJSONDeserializationPerformanceSmall() throws {
        let jsonData = try jsonSerializer.serialize(smallMessage)
        
        measure {
            do {
                let _ = try jsonDeserializer.deserialize(
                    jsonData,
                    using: smallMessage.descriptor
                )
            } catch {
                XCTFail("JSON deserialization failed: \(error)")
            }
        }
    }
    
    /// Test-PERF-002: JSON deserialization performance - medium messages
    func testJSONDeserializationPerformanceMedium() throws {
        let jsonData = try jsonSerializer.serialize(mediumMessage)
        
        measure {
            do {
                let _ = try jsonDeserializer.deserialize(
                    jsonData,
                    using: mediumMessage.descriptor
                )
            } catch {
                XCTFail("JSON deserialization failed: \(error)")
            }
        }
    }
    
    /// Test-PERF-002: JSON deserialization performance - large messages
    func testJSONDeserializationPerformanceLarge() throws {
        let jsonData = try jsonSerializer.serialize(largeMessage)
        
        measure {
            do {
                let _ = try jsonDeserializer.deserialize(
                    jsonData,
                    using: largeMessage.descriptor
                )
            } catch {
                XCTFail("JSON deserialization failed: \(error)")
            }
        }
    }
    
    // MARK: - Round Trip Performance Tests
    
    /// Test-PERF-003: Binary round-trip performance with large datasets
    func testBinaryRoundTripPerformanceLarge() throws {
        measure {
            do {
                let serializedData = try binarySerializer.serialize(largeMessage)
                let _ = try binaryDeserializer.deserialize(
                    serializedData,
                    using: largeMessage.descriptor
                )
            } catch {
                XCTFail("Round-trip failed: \(error)")
            }
        }
    }
    
    /// Test-PERF-003: JSON round-trip performance with large datasets
    func testJSONRoundTripPerformanceLarge() throws {
        measure {
            do {
                let jsonData = try jsonSerializer.serialize(largeMessage)
                let _ = try jsonDeserializer.deserialize(
                    jsonData,
                    using: largeMessage.descriptor
                )
            } catch {
                XCTFail("JSON round-trip failed: \(error)")
            }
        }
    }
    
    // MARK: - Comparative Performance Tests
    
    /// Test-PERF-004: Comparison of binary vs JSON serialization
    func testBinaryVsJSONSerializationComparison() throws {
        var binaryTimes: [TimeInterval] = []
        var jsonTimes: [TimeInterval] = []
        
        // Measure binary serialization
        for _ in 0..<10 {
            let startTime = Date()
            let _ = try binarySerializer.serialize(mediumMessage)
            binaryTimes.append(Date().timeIntervalSince(startTime))
        }
        
        // Measure JSON serialization
        for _ in 0..<10 {
            let startTime = Date()
            let _ = try jsonSerializer.serialize(mediumMessage)
            jsonTimes.append(Date().timeIntervalSince(startTime))
        }
        
        let avgBinaryTime = binaryTimes.reduce(0, +) / Double(binaryTimes.count)
        let avgJSONTime = jsonTimes.reduce(0, +) / Double(jsonTimes.count)
        
        print("Binary serialization average time: \(avgBinaryTime * 1000) ms")
        print("JSON serialization average time: \(avgJSONTime * 1000) ms")
        print("Performance ratio (JSON/Binary): \(avgJSONTime / avgBinaryTime)")
        
        // JSON обычно медленнее binary, но проверяем, что разница разумная
        XCTAssertLessThan(avgJSONTime / avgBinaryTime, 20.0, "JSON should not be more than 20x slower than binary")
    }
    
    // MARK: - Memory Usage Tests
    
    /// Test-PERF-003: Memory usage during large message processing
    func testMemoryUsageLargeMessage() throws {
        // Создаем очень большое сообщение для проверки memory usage
        let veryLargeDescriptor = try createVeryLargeDataDescriptor()
        try registry.registerMessage(veryLargeDescriptor)
        
        var veryLargeMessage = MessageFactory().createMessage(from: veryLargeDescriptor)
        
        // Заполняем большим количеством данных
        let largeData = (0..<10000).map { "LargeDataEntry_\($0)_With_Long_Content_To_Test_Memory_Usage" }
        try veryLargeMessage.set(largeData, forField: "data_entries")
        
        measure {
            do {
                let serializedData = try binarySerializer.serialize(veryLargeMessage)
                let _ = try binaryDeserializer.deserialize(
                    serializedData,
                    using: veryLargeMessage.descriptor
                )
            } catch {
                XCTFail("Large message processing failed: \(error)")
            }
        }
    }
    
    // MARK: - Stress Testing
    
    /// Test-PERF-003: Concurrent serialization stress test
    func testConcurrentSerializationStress() throws {
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        measure {
            let expectation = self.expectation(description: "Concurrent serialization")
            expectation.expectedFulfillmentCount = 100
            
            for _ in 0..<100 {
                queue.async {
                    do {
                        let _ = try self.binarySerializer.serialize(self.mediumMessage)
                        expectation.fulfill()
                    } catch {
                        XCTFail("Concurrent serialization failed: \(error)")
                    }
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Helper Methods for Test Message Creation
    
    private func createPersonDescriptor() throws -> MessageDescriptor {
        let fileDescriptor = FileDescriptor(name: "person.proto", package: "performance.test")
        var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)
        
        personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        personMessage.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
        personMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))
        
        var fileDescriptorMutable = fileDescriptor
        fileDescriptorMutable.addMessage(personMessage)
        return personMessage
    }
    
    private func createCompanyDescriptor() throws -> MessageDescriptor {
        let fileDescriptor = FileDescriptor(name: "company.proto", package: "performance.test")
        var companyMessage = MessageDescriptor(name: "Company", parent: fileDescriptor)
        
        companyMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        companyMessage.addField(FieldDescriptor(name: "employee_count", number: 2, type: .int32))
        companyMessage.addField(FieldDescriptor(name: "departments", number: 3, type: .string, isRepeated: true))
        
        var fileDescriptorMutable = fileDescriptor
        fileDescriptorMutable.addMessage(companyMessage)
        return companyMessage
    }
    
    private func createDatabaseDescriptor() throws -> MessageDescriptor {
        let fileDescriptor = FileDescriptor(name: "database.proto", package: "performance.test")
        var databaseMessage = MessageDescriptor(name: "Database", parent: fileDescriptor)
        
        databaseMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        databaseMessage.addField(FieldDescriptor(name: "record_count", number: 2, type: .int32))
        databaseMessage.addField(FieldDescriptor(name: "records", number: 3, type: .string, isRepeated: true))
        databaseMessage.addField(FieldDescriptor(
            name: "metadata", 
            number: 4, 
            type: .string,
            isMap: true,
            mapEntryInfo: MapEntryInfo(
                keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
                valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
            )
        ))
        
        var fileDescriptorMutable = fileDescriptor
        fileDescriptorMutable.addMessage(databaseMessage)
        return databaseMessage
    }
    
    private func createVeryLargeDataDescriptor() throws -> MessageDescriptor {
        let fileDescriptor = FileDescriptor(name: "large_data.proto", package: "performance.test")
        var largeDataMessage = MessageDescriptor(name: "VeryLargeData", parent: fileDescriptor)
        
        largeDataMessage.addField(FieldDescriptor(name: "data_entries", number: 1, type: .string, isRepeated: true))
        
        var fileDescriptorMutable = fileDescriptor
        fileDescriptorMutable.addMessage(largeDataMessage)
        return largeDataMessage
    }
}
