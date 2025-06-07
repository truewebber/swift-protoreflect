/**
 * 🌊 SwiftProtoReflect Example: Streaming Data Processing
 * 
 * Описание: Потоковая обработка больших datasets с Protocol Buffers для memory-efficient операций
 * Ключевые концепции: Streaming serialization, Memory management, Large datasets, Batch processing
 * Сложность: 🚀 Продвинутый
 * Время выполнения: < 20 секунд
 * 
 * Что изучите:
 * - Потоковая сериализация больших datasets без загрузки всего в память
 * - Memory-efficient batch processing с Protocol Buffers
 * - Streaming deserialization для обработки данных по частям
 * - Large file handling и progressive loading
 * - Memory footprint optimization для больших объемов данных
 * - Producer-Consumer patterns для streaming обработки
 * 
 * Запуск: 
 *   swift run Streaming
 *   make run-serialization
 */

import Foundation
import OSLog
@preconcurrency import SwiftProtoReflect
import ExampleUtils

@main
struct StreamingExample {
    static func main() throws {
        ExampleUtils.printHeader("Streaming Protocol Buffers Processing")
        
        try step1_memoryEfficientSerialization()
        try step2_batchProcessing()
        try step3_largeDatasetStreaming()
        try step4_producerConsumerPattern()
        try step5_memoryOptimizationTechniques()
        
        ExampleUtils.printSuccess("Streaming обработка данных успешно изучена!")
        
        ExampleUtils.printNext([
            "Далее попробуйте: swift run Compression - продвинутые техники сжатия",
            "Сравните: binary-data.swift - binary операции",
            "Изучите: protobuf-serialization.swift - основы сериализации"
        ])
    }
    
    // MARK: - Implementation Steps
    
    private static func step1_memoryEfficientSerialization() throws {
        ExampleUtils.printStep(1, "Memory-efficient сериализация")
        
        print("  💾 Создание large dataset симуляции...")
        
        let datasetSize = 10_000 // 10K records
        let batchSize = 100
        
        let (recordDescriptor, _) = try createStreamingRecordMessage()
        let factory = MessageFactory()
        let serializer = BinarySerializer()
        
        // Streaming file for output
        let tempDir = NSTemporaryDirectory()
        let streamingFile = "\(tempDir)streaming_records.bin"
        let outputStream = OutputStream(toFileAtPath: streamingFile, append: false)!
        outputStream.open()
        defer { outputStream.close() }
        
        var totalSerialized = 0
        var totalMemoryUsed = 0
        
        let (_, streamingTime) = try ExampleUtils.measureTime {
            for batchIndex in 0..<(datasetSize / batchSize) {
                // Create batch in memory
                var batchRecords: [DynamicMessage] = []
                
                for i in 0..<batchSize {
                    let recordIndex = batchIndex * batchSize + i
                    var record = factory.createMessage(from: recordDescriptor)
                    
                    try record.set("Record_\(recordIndex)", forField: "id")
                    try record.set("User \(recordIndex)", forField: "name")
                    try record.set(Double.random(in: 0...100), forField: "score")
                    try record.set(Int64(Date().timeIntervalSince1970 + Double(i)), forField: "timestamp")
                    try record.set(generateRandomTags(), forField: "tags")
                    
                    batchRecords.append(record)
                }
                
                // Serialize batch and write to stream
                for record in batchRecords {
                    let recordData = try serializer.serialize(record)
                    let lengthPrefix = withUnsafeBytes(of: UInt32(recordData.count).bigEndian) { Data($0) }
                    
                    // Write length prefix + record data
                    _ = lengthPrefix.withUnsafeBytes { outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: lengthPrefix.count) }
                    _ = recordData.withUnsafeBytes { outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: recordData.count) }
                    
                    totalSerialized += recordData.count + 4 // +4 for length prefix
                }
                
                // Clear batch from memory
                batchRecords.removeAll()
                
                // Estimate memory usage
                totalMemoryUsed = batchSize * 256 // Rough estimate per record
                
                if batchIndex % 10 == 0 {
                    print("    Batch \(batchIndex + 1)/\(datasetSize / batchSize): \(ExampleUtils.formatDataSize(totalSerialized)) written")
                }
            }
        }
        
        ExampleUtils.printTiming("Streaming serialization (\(datasetSize) records)", time: streamingTime)
        
        print("  📊 Streaming результаты:")
        print("    Total records: \(datasetSize)")
        print("    Batch size: \(batchSize)")
        print("    Total size: \(ExampleUtils.formatDataSize(totalSerialized))")
        print("    Peak memory: ~\(ExampleUtils.formatDataSize(totalMemoryUsed))")
        print("    Throughput: \(String(format: "%.1f", Double(datasetSize) / streamingTime)) records/sec")
        
        // Verify file was created
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: streamingFile)
        let fileSize = fileAttributes[.size] as! Int
        print("    File size: \(ExampleUtils.formatDataSize(fileSize))")
        
        _ = ExampleUtils.writeToTempFile("Streaming file path: \(streamingFile)", filename: "streaming_output_info.txt")
    }
    
    private static func step2_batchProcessing() throws {
        ExampleUtils.printStep(2, "Batch processing и deserialization")
        
        // Read back the streaming file we created
        let tempDir = NSTemporaryDirectory()
        let streamingFile = "\(tempDir)streaming_records.bin"
        
        guard FileManager.default.fileExists(atPath: streamingFile) else {
            print("  ❌ Streaming file not found, skipping batch processing")
            return
        }
        
        let inputStream = InputStream(fileAtPath: streamingFile)!
        inputStream.open()
        defer { inputStream.close() }
        
        let deserializer = BinaryDeserializer()
        let (recordDescriptor, _) = try createStreamingRecordMessage()
        
        var recordsProcessed = 0
        var totalScoreSum = 0.0
        var batchCount = 0
        let processingBatchSize = 250 // Different from serialization batch size
        
        print("  📖 Reading и processing streaming data...")
        
        let (_, processingTime) = try ExampleUtils.measureTime {
            var currentBatch: [DynamicMessage] = []
            
            while inputStream.hasBytesAvailable {
                // Read length prefix
                var lengthBytes = [UInt8](repeating: 0, count: 4)
                let lengthBytesRead = inputStream.read(&lengthBytes, maxLength: 4)
                
                if lengthBytesRead < 4 { break }
                
                let recordLength = lengthBytes.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
                
                // Read record data
                var recordBytes = [UInt8](repeating: 0, count: Int(recordLength))
                let recordBytesRead = inputStream.read(&recordBytes, maxLength: Int(recordLength))
                
                if recordBytesRead < recordLength { break }
                
                // Deserialize record
                let recordData = Data(recordBytes)
                let record = try deserializer.deserialize(recordData, using: recordDescriptor)
                
                currentBatch.append(record)
                recordsProcessed += 1
                
                // Process batch when full
                if currentBatch.count >= processingBatchSize {
                    totalScoreSum += try processBatch(currentBatch, batchNumber: batchCount + 1)
                    currentBatch.removeAll()
                    batchCount += 1
                }
            }
            
            // Process remaining records
            if !currentBatch.isEmpty {
                totalScoreSum += try processBatch(currentBatch, batchNumber: batchCount + 1)
                batchCount += 1
            }
        }
        
        ExampleUtils.printTiming("Batch processing (\(recordsProcessed) records)", time: processingTime)
        
        print("  📊 Processing результаты:")
        print("    Records processed: \(recordsProcessed)")
        print("    Batches processed: \(batchCount)")
        print("    Average score: \(String(format: "%.2f", totalScoreSum / Double(recordsProcessed)))")
        print("    Processing rate: \(String(format: "%.1f", Double(recordsProcessed) / processingTime)) records/sec")
    }
    
    private static func step3_largeDatasetStreaming() throws {
        ExampleUtils.printStep(3, "Large dataset streaming simulation")
        
        print("  🏔 Симуляция обработки очень большого dataset...")
        
        // Simulate a very large dataset (1M records) without actually creating it
        let virtualDatasetSize = 1_000_000
        let streamingBatchSize = 1000
        let _ = 500  // processingBatchSize - not used in simulation
        
        // Simulate memory usage and timing
        let recordSize = 256 // Average record size in bytes
        let totalDataSize = virtualDatasetSize * recordSize
        let batchMemoryUsage = streamingBatchSize * recordSize
        
        print("  📊 Large dataset параметры:")
        print("    Virtual dataset size: \(virtualDatasetSize) records")
        print("    Estimated total size: \(ExampleUtils.formatDataSize(totalDataSize))")
        print("    Streaming batch size: \(streamingBatchSize)")
        print("    Memory per batch: \(ExampleUtils.formatDataSize(batchMemoryUsage))")
        
        // Simulate streaming processing with statistics
        let statisticsCollector = StreamingStatistics()
        
        let (_, simulationTime) = ExampleUtils.measureTime {
            for batchIndex in 0..<(virtualDatasetSize / streamingBatchSize) {
                // Simulate batch processing time
                let batchProcessingTime = Double.random(in: 0.001...0.01)
                Thread.sleep(forTimeInterval: batchProcessingTime)
                
                // Collect statistics
                statisticsCollector.addBatch(
                    recordCount: streamingBatchSize,
                    processingTime: batchProcessingTime,
                    memoryUsed: batchMemoryUsage
                )
                
                if batchIndex % 100 == 0 {
                    let progress = Double(batchIndex) / Double(virtualDatasetSize / streamingBatchSize) * 100
                    print("    Progress: \(String(format: "%.1f%%", progress)) - Batch \(batchIndex)")
                }
            }
        }
        
        print("  📈 Streaming simulation результаты:")
        statisticsCollector.printReport()
        ExampleUtils.printTiming("Total simulation time", time: simulationTime)
        
        let projectedRealTime = statisticsCollector.averageProcessingTime * Double(virtualDatasetSize / streamingBatchSize)
        print("    Projected real processing time: \(String(format: "%.1f", projectedRealTime))s")
    }
    
    private static func step4_producerConsumerPattern() throws {
        ExampleUtils.printStep(4, "Producer-Consumer streaming pattern")
        
        print("  🔄 Демонстрация Producer-Consumer pattern для streaming...")
        
        let queue = StreamingQueue<ProcessedRecord>(maxSize: 50)
        let (recordDescriptor, _) = try createStreamingRecordMessage()
        let factory = MessageFactory()
        
        let producerCount = 2
        let consumerCount = 3
        let recordsPerProducer = 100
        
        // Statistics - using thread-safe counters
        let producedCounter = ThreadSafeCounter()
        let consumedCounter = ThreadSafeCounter()
        
        print("  🏭 Starting producers (\(producerCount)) и consumers (\(consumerCount))...")
        
        let (_, patternTime) = ExampleUtils.measureTime {
            // Create producer tasks
            let producerGroup = DispatchGroup()
            
            for producerId in 0..<producerCount {
                producerGroup.enter()
                DispatchQueue.global(qos: .userInitiated).async { [queue, factory, recordDescriptor, producedCounter] in
                    defer { producerGroup.leave() }
                    
                    for i in 0..<recordsPerProducer {
                        do {
                            var record = factory.createMessage(from: recordDescriptor)
                            try record.set("Producer\(producerId)_Record\(i)", forField: "id")
                            try record.set("Producer \(producerId) User \(i)", forField: "name")
                            try record.set(Double.random(in: 0...100), forField: "score")
                            try record.set(Int64(Date().timeIntervalSince1970), forField: "timestamp")
                            try record.set(["tag_\(i)"], forField: "tags")
                            
                            let processedRecord = ProcessedRecord(
                                id: "Producer\(producerId)_Record\(i)",
                                data: record,
                                processingMetadata: ["producer_id": "\(producerId)", "sequence": "\(i)"]
                            )
                            
                            queue.enqueue(processedRecord)
                            producedCounter.increment()
                            
                            // Simulate production time
                            Thread.sleep(forTimeInterval: 0.001)
                        } catch {
                            print("    Producer \(producerId) error: \(error)")
                        }
                    }
                    
                    print("    🏭 Producer \(producerId) finished")
                }
            }
            
            // Create consumer tasks
            let consumerGroup = DispatchGroup()
            
            for consumerId in 0..<consumerCount {
                consumerGroup.enter()
                DispatchQueue.global(qos: .userInitiated).async { [queue, consumedCounter, producedCounter] in
                    defer { consumerGroup.leave() }
                    
                    var localConsumedCount = 0
                    
                    while true {
                        if let record = queue.dequeue(timeout: 1.0) {
                            // Process the record
                            do {
                                _ = try processStreamingRecord(record.data)
                                localConsumedCount += 1
                                consumedCounter.increment()
                                
                                // Simulate processing time
                                Thread.sleep(forTimeInterval: 0.002)
                            } catch {
                                print("    Consumer \(consumerId) processing error: \(error)")
                            }
                        } else {
                            // Check if all producers are done and queue is empty
                            let currentProducedCount = producedCounter.value
                            
                            if queue.isEmpty && currentProducedCount >= producerCount * recordsPerProducer {
                                break
                            }
                        }
                    }
                    
                    print("    🔍 Consumer \(consumerId) finished (\(localConsumedCount) records)")
                }
            }
            
            // Wait for all producers to finish
            producerGroup.wait()
            
            // Signal no more data
            queue.signalCompletion()
            
            // Wait for all consumers to finish
            consumerGroup.wait()
        }
        
        ExampleUtils.printTiming("Producer-Consumer pattern", time: patternTime)
        
        print("  📊 Producer-Consumer результаты:")
        print("    Produced records: \(producedCounter.value)")
        print("    Consumed records: \(consumedCounter.value)")
        print("    Queue efficiency: \(consumedCounter.value == producedCounter.value ? "✅ Perfect" : "❌ Loss detected")")
        print("    Processing rate: \(String(format: "%.1f", Double(consumedCounter.value) / patternTime)) records/sec")
    }
    
    private static func step5_memoryOptimizationTechniques() throws {
        ExampleUtils.printStep(5, "Memory optimization techniques")
        
        print("  🧠 Memory optimization strategies демонстрация...")
        
        // Technique 1: Object Pooling
        print("  🏊 Object Pooling pattern:")
        let messagePool = MessagePool(descriptor: try createStreamingRecordMessage().0, poolSize: 10)
        
        let (_, poolingTime) = ExampleUtils.measureTime {
            for i in 0..<100 {
                var message = messagePool.borrowMessage()
                
                // Use the message
                do {
                    try message.set("Pooled_\(i)", forField: "id")
                    try message.set("Pooled User \(i)", forField: "name")
                    try message.set(Double(i), forField: "score")
                    // Simulate processing
                    Thread.sleep(forTimeInterval: 0.0001)
                } catch {
                    print("    Pool processing error: \(error)")
                }
                
                messagePool.returnMessage(message)
            }
        }
        
        ExampleUtils.printTiming("Object pooling (100 operations)", time: poolingTime)
        print("    Pool hits: \(messagePool.poolHits)")
        print("    Pool misses: \(messagePool.poolMisses)")
        print("    Pool efficiency: \(String(format: "%.1f%%", Double(messagePool.poolHits) / Double(messagePool.poolHits + messagePool.poolMisses) * 100))")
        
        // Technique 2: Lazy Loading
        print("  🐌 Lazy Loading simulation:")
        let lazyDataset = LazyDataset(size: 1000)
        
        let (_, lazyTime) = ExampleUtils.measureTime {
            // Access random elements (should trigger lazy loading)
            for _ in 0..<50 {
                let randomIndex = Int.random(in: 0..<1000)
                _ = lazyDataset.getRecord(at: randomIndex)
            }
        }
        
        ExampleUtils.printTiming("Lazy loading (50 random accesses)", time: lazyTime)
        print("    Records loaded: \(lazyDataset.loadedCount)/\(lazyDataset.totalSize)")
        print("    Memory efficiency: \(String(format: "%.1f%%", Double(lazyDataset.loadedCount) / Double(lazyDataset.totalSize) * 100))")
        
        // Technique 3: Memory Pressure Monitoring
        print("  📊 Memory pressure simulation:")
        let memoryMonitor = MemoryMonitor()
        
        // Simulate memory pressure
        var bigArrays: [[UInt8]] = []
        
        for i in 0..<10 {
            let arraySize = 1024 * 1024 // 1MB each
            bigArrays.append([UInt8](repeating: UInt8(i), count: arraySize))
            
            let currentMemory = memoryMonitor.getCurrentMemoryUsage()
            print("    Allocation \(i + 1): \(ExampleUtils.formatDataSize(currentMemory)) used")
            
            if memoryMonitor.isMemoryPressureHigh() {
                print("    ⚠️ High memory pressure detected, triggering cleanup...")
                bigArrays.removeFirst()
            }
        }
        
        // Cleanup
        bigArrays.removeAll()
        
        let finalMemory = memoryMonitor.getCurrentMemoryUsage()
        print("    Final memory: \(ExampleUtils.formatDataSize(finalMemory))")
    }
    
    // MARK: - Helper Methods
    
    static func createStreamingRecordMessage() throws -> (MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "streaming.proto", package: "streaming.test")
        var recordMessage = MessageDescriptor(name: "StreamingRecord", parent: fileDescriptor)
        
        recordMessage.addField(FieldDescriptor(name: "id", number: 1, type: .string))
        recordMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
        recordMessage.addField(FieldDescriptor(name: "score", number: 3, type: .double))
        recordMessage.addField(FieldDescriptor(name: "timestamp", number: 4, type: .int64))
        recordMessage.addField(FieldDescriptor(name: "tags", number: 5, type: .string, isRepeated: true))
        
        fileDescriptor.addMessage(recordMessage)
        
        return (recordMessage, fileDescriptor)
    }
    
    private static func generateRandomTags() -> [String] {
        let allTags = ["performance", "optimization", "streaming", "data", "processing", "batch", "memory", "efficient"]
        let tagCount = Int.random(in: 1...3)
        return Array(allTags.shuffled().prefix(tagCount))
    }
    
    private static func processBatch(_ batch: [DynamicMessage], batchNumber: Int) throws -> Double {
        var batchScoreSum = 0.0
        
        for record in batch {
            if let score = try record.get(forField: "score") as? Double {
                batchScoreSum += score
            }
        }
        
        if batchNumber % 10 == 0 {
            print("    Processed batch \(batchNumber): \(batch.count) records, avg score: \(String(format: "%.2f", batchScoreSum / Double(batch.count)))")
        }
        
        return batchScoreSum
    }
    
    private static func processStreamingRecord(_ record: DynamicMessage) throws -> ProcessingResult {
        // Simulate some processing logic
        let id = try record.get(forField: "id") as? String ?? "unknown"
        let score = try record.get(forField: "score") as? Double ?? 0.0
        
        return ProcessingResult(
            recordId: id,
            processedScore: score * 1.1, // Apply some transformation
            processingTime: Date()
        )
    }
}

// MARK: - Supporting Classes

struct ProcessedRecord: Sendable {
    let id: String
    let data: DynamicMessage
    let processingMetadata: [String: String]
}

struct ProcessingResult: Sendable {
    let recordId: String
    let processedScore: Double
    let processingTime: Date
}

class StreamingStatistics {
    private var totalRecords = 0
    private var totalProcessingTime = 0.0
    private var totalMemoryUsed = 0
    private var batchCount = 0
    
    var averageProcessingTime: Double {
        return batchCount > 0 ? totalProcessingTime / Double(batchCount) : 0.0
    }
    
    func addBatch(recordCount: Int, processingTime: Double, memoryUsed: Int) {
        totalRecords += recordCount
        totalProcessingTime += processingTime
        totalMemoryUsed = max(totalMemoryUsed, memoryUsed) // Peak memory
        batchCount += 1
    }
    
    func printReport() {
        print("    Total records processed: \(totalRecords)")
        print("    Total batches: \(batchCount)")
        print("    Average batch processing time: \(String(format: "%.3f", averageProcessingTime * 1000))ms")
        print("    Peak memory usage: \(ExampleUtils.formatDataSize(totalMemoryUsed))")
        print("    Records per second: \(String(format: "%.1f", Double(totalRecords) / totalProcessingTime))")
    }
}

final class StreamingQueue<T: Sendable>: @unchecked Sendable {
    private var queue: [T] = []
    private let lock = NSLock()
    private let condition = NSCondition()
    private let maxSize: Int
    private var isCompleted = false
    
    init(maxSize: Int) {
        self.maxSize = maxSize
    }
    
    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return queue.isEmpty
    }
    
    func enqueue(_ item: T) {
        condition.lock()
        defer { condition.unlock() }
        
        while queue.count >= maxSize {
            condition.wait()
        }
        
        queue.append(item)
        condition.broadcast()
    }
    
    func dequeue(timeout: TimeInterval) -> T? {
        condition.lock()
        defer { condition.unlock() }
        
        let deadline = Date().addingTimeInterval(timeout)
        
        while queue.isEmpty && !isCompleted {
            if !condition.wait(until: deadline) {
                return nil // Timeout
            }
        }
        
        if !queue.isEmpty {
            let item = queue.removeFirst()
            condition.broadcast()
            return item
        }
        
        return nil
    }
    
    func signalCompletion() {
        condition.lock()
        isCompleted = true
        condition.broadcast()
        condition.unlock()
    }
}

class MessagePool {
    private var pool: [DynamicMessage] = []
    private let lock = NSLock()
    private let descriptor: MessageDescriptor
    private let factory = MessageFactory()
    
    private(set) var poolHits = 0
    private(set) var poolMisses = 0
    
    init(descriptor: MessageDescriptor, poolSize: Int) {
        self.descriptor = descriptor
        
        // Pre-populate pool
        for _ in 0..<poolSize {
            pool.append(factory.createMessage(from: descriptor))
        }
    }
    
    func borrowMessage() -> DynamicMessage {
        lock.lock()
        defer { lock.unlock() }
        
        if !pool.isEmpty {
            poolHits += 1
            return pool.removeLast()
        } else {
            poolMisses += 1
            return factory.createMessage(from: descriptor)
        }
    }
    
    func returnMessage(_ message: DynamicMessage) {
        lock.lock()
        defer { lock.unlock() }
        
        // Clear the message before returning to pool
        // Note: In real implementation, we'd need a clearAll() method
        pool.append(message)
    }
}

class LazyDataset {
    private var loadedRecords: [Int: DynamicMessage] = [:]
    private let lock = NSLock()
    
    let totalSize: Int
    var loadedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return loadedRecords.count
    }
    
    init(size: Int) {
        self.totalSize = size
    }
    
    func getRecord(at index: Int) -> DynamicMessage? {
        guard index >= 0 && index < totalSize else { return nil }
        
        lock.lock()
        defer { lock.unlock() }
        
        if let existingRecord = loadedRecords[index] {
            return existingRecord
        }
        
        // Lazy load the record
        do {
            let (descriptor, _) = try StreamingExample.createStreamingRecordMessage()
            let factory = MessageFactory()
            var record = factory.createMessage(from: descriptor)
            
            try record.set("Lazy_\(index)", forField: "id")
            try record.set("Lazy User \(index)", forField: "name")
            try record.set(Double(index), forField: "score")
            try record.set(Int64(Date().timeIntervalSince1970), forField: "timestamp")
            try record.set(["lazy"], forField: "tags")
            
            loadedRecords[index] = record
            return record
        } catch {
            return nil
        }
    }
}

class MemoryMonitor {
    func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size)
        } else {
            return 0
        }
    }
    
    func isMemoryPressureHigh() -> Bool {
        let currentMemory = getCurrentMemoryUsage()
        let threshold = 100 * 1024 * 1024 // 100MB threshold for demo
        return currentMemory > threshold
    }
}

final class ThreadSafeCounter: Sendable {
    private let _value = OSAllocatedUnfairLock(initialState: 0)
    
    var value: Int {
        return _value.withLock { $0 }
    }
    
    func increment() {
        _value.withLock { $0 += 1 }
    }
    
    func decrement() {
        _value.withLock { $0 -= 1 }
    }
    
    func reset() {
        _value.withLock { $0 = 0 }
    }
}
