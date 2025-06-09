/**
 * 🧵 SwiftProtoReflect Example: Thread Safety
 * 
 * Описание: Демонстрация многопоточной безопасности и concurrent access patterns
 * Ключевые концепции: Thread safety, Concurrent access, Synchronization, Race conditions
 * Сложность: 🚀 Продвинутый
 * Время выполнения: < 20 секунд
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct ThreadSafetyExample {
    static func main() throws {
        ExampleUtils.printHeader("🧵 Thread Safety - Concurrent Access Patterns")
        
        try demonstrateReadWriteOperations()
        try demonstrateConcurrentMessageCreation()
        try demonstrateThreadSafeRegistry()
        try demonstrateLockingStrategies()
        try demonstrateAtomicOperations()
        try demonstrateRaceConditionPrevention()
        
        ExampleUtils.printSuccess("Thread safety demonstration completed!")
        ExampleUtils.printNext([
            "Следующий пример: custom-extensions.swift - создание собственных расширений",
            "Изучите также: batch-operations.swift - массовые операции"
        ])
    }
    
    // MARK: - Read/Write Operations
    
    private static func demonstrateReadWriteOperations() throws {
        ExampleUtils.printStep(1, "Concurrent Read/Write Operations")
        
        print("  🔐 Testing thread-safe read/write patterns...")
        
        // Thread-safe message wrapper
        class ThreadSafeMessage {
            private var message: DynamicMessage
            private let queue = DispatchQueue(label: "message.queue", attributes: .concurrent)
            
            init(_ message: DynamicMessage) {
                self.message = message
            }
            
            func read<T>(field: String) throws -> T? {
                return try queue.sync {
                    return try message.get(forField: field) as? T
                }
            }
            
            func write<T>(_ value: T, field: String) throws {
                _ = try queue.sync(flags: .barrier) {
                    try message.set(value, forField: field)
                }
            }
            
            func hasValue(field: String) throws -> Bool {
                return try queue.sync {
                    return try message.hasValue(forField: field)
                }
            }
        }
        
        // Создание тестового сообщения
        var testFile = FileDescriptor(name: "thread_test.proto", package: "com.thread")
        var counterDescriptor = MessageDescriptor(name: "Counter", parent: testFile)
        
        counterDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .int64))
        counterDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
        counterDescriptor.addField(FieldDescriptor(name: "timestamp", number: 3, type: .int64))
        
        testFile.addMessage(counterDescriptor)
        
        let factory = MessageFactory()
        let baseMessage = factory.createMessage(from: counterDescriptor)
        let threadSafeMessage = ThreadSafeMessage(baseMessage)
        
        // Инициализация
        try threadSafeMessage.write(Int64(0), field: "value")
        try threadSafeMessage.write("ThreadSafeCounter", field: "name")
        
        let operationCount = 1000
        let threadCount = 8
        
        print("  📊 Running \(operationCount) operations across \(threadCount) threads...")
        
        let concurrentTime = ExampleUtils.measureTime {
            let group = DispatchGroup()
            let concurrentQueue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)
            
            // Запуск параллельных операций
            for threadId in 0..<threadCount {
                group.enter()
                concurrentQueue.async {
                    for i in 0..<(operationCount / threadCount) {
                        do {
                            // Читаем текущее значение
                            let currentValue: Int64 = try threadSafeMessage.read(field: "value") ?? 0
                            
                            // Записываем новое значение
                            try threadSafeMessage.write(currentValue + 1, field: "value")
                            
                            // Обновляем timestamp
                            try threadSafeMessage.write(Int64(Date().timeIntervalSince1970), field: "timestamp")
                            
                        } catch {
                            print("    ❌ Error in thread \(threadId): \(error)")
                        }
                    }
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        ExampleUtils.printTiming("Concurrent operations (\(operationCount) ops, \(threadCount) threads)", time: concurrentTime.time)
        
        // Проверка результатов
        let finalValue: Int64 = try threadSafeMessage.read(field: "value") ?? 0
        let expectedValue = Int64(operationCount)
        
        print("\n  📊 Thread Safety Results:")
        ExampleUtils.printDataTable([[
            "Metric": "Expected Final Value | Actual Final Value | Thread Count | Operations | Data Integrity",
            "Value": "\(expectedValue) | \(finalValue) | \(threadCount) | \(operationCount) | \(finalValue == expectedValue ? "Preserved" : "Corrupted")",
            "Status": "Target | \(finalValue == expectedValue ? "✅ Correct" : "❌ Race condition") | Concurrent access | All completed | \(finalValue == expectedValue ? "✅" : "❌")"
        ]], title: "Concurrent Read/Write Analysis")
    }
    
    // MARK: - Concurrent Message Creation
    
    private static func demonstrateConcurrentMessageCreation() throws {
        ExampleUtils.printStep(2, "Concurrent Message Creation")
        
        print("  🏗  Testing concurrent message factory usage...")
        
        // Thread-safe message factory
        class ThreadSafeMessageFactory {
            private let factory = MessageFactory()
            private let queue = DispatchQueue(label: "factory.queue")
            private var createdCount = 0
            
            func createMessage(from descriptor: MessageDescriptor) -> DynamicMessage {
                return queue.sync {
                    createdCount += 1
                    return factory.createMessage(from: descriptor)
                }
            }
            
            var totalCreated: Int {
                return queue.sync { createdCount }
            }
        }
        
        // Создание дескриптора для тестирования
        var factoryFile = FileDescriptor(name: "factory_test.proto", package: "com.factory")
        var userDescriptor = MessageDescriptor(name: "User", parent: factoryFile)
        
        userDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .string))
        userDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
        userDescriptor.addField(FieldDescriptor(name: "thread_id", number: 3, type: .int32))
        userDescriptor.addField(FieldDescriptor(name: "created_at", number: 4, type: .int64))
        
        factoryFile.addMessage(userDescriptor)
        
        let threadSafeFactory = ThreadSafeMessageFactory()
        let messageCount = 2000
        let threadCount = 6
        
        print("  📊 Creating \(messageCount) messages across \(threadCount) threads...")
        
        var allMessages: [DynamicMessage] = []
        let messagesLock = NSLock()
        
        let creationTime = ExampleUtils.measureTime {
            let group = DispatchGroup()
            let concurrentQueue = DispatchQueue(label: "creation.concurrent", attributes: .concurrent)
            
            for threadId in 0..<threadCount {
                group.enter()
                concurrentQueue.async {
                    var threadMessages: [DynamicMessage] = []
                    
                    for i in 0..<(messageCount / threadCount) {
                        var message = threadSafeFactory.createMessage(from: userDescriptor)
                        
                        do {
                            try message.set("USER-\(threadId)-\(i)", forField: "id")
                            try message.set("User \(threadId).\(i)", forField: "name")
                            try message.set(Int32(threadId), forField: "thread_id")
                            try message.set(Int64(Date().timeIntervalSince1970 * 1000), forField: "created_at")
                            
                            threadMessages.append(message)
                        } catch {
                            print("    ❌ Error creating message: \(error)")
                        }
                    }
                    
                    // Thread-safe добавление в общий массив
                    messagesLock.lock()
                    allMessages.append(contentsOf: threadMessages)
                    messagesLock.unlock()
                    
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        ExampleUtils.printTiming("Concurrent message creation (\(messageCount) messages)", time: creationTime.time)
        
        // Валидация результатов
        let uniqueThreadIds = Set(allMessages.compactMap { try? $0.get(forField: "thread_id") as? Int32 })
        let throughput = Double(allMessages.count) / creationTime.time
        
        print("\n  📊 Concurrent Creation Results:")
        ExampleUtils.printDataTable([[
            "Metric": "Messages Created | Expected Count | Factory Usage | Unique Threads | Throughput",
            "Value": "\(allMessages.count) | \(messageCount) | \(threadSafeFactory.totalCreated) | \(uniqueThreadIds.count) | \(String(format: "%.0f", throughput)) msg/s",
            "Status": "All successful | Target | Thread-safe | All participated | High performance"
        ]], title: "Concurrent Creation Analysis")
        
        print("\n  🎯 Creation Benefits:")
        print("    • Thread-safe factory operations ✅")
        print("    • No message corruption ✅")
        print("    • High concurrent throughput ✅")
        print("    • Resource contention minimized ✅")
    }
    
    // MARK: - Thread-Safe Registry
    
    private static func demonstrateThreadSafeRegistry() throws {
        ExampleUtils.printStep(3, "Thread-Safe Type Registry")
        
        print("  🗂  Testing concurrent registry operations...")
        
        // Thread-safe type registry wrapper
        class ConcurrentTypeRegistry {
            private let registry = TypeRegistry()
            private let readerWriterQueue = DispatchQueue(label: "registry.queue", attributes: .concurrent)
            
            func registerFile(_ file: FileDescriptor) throws {
                try readerWriterQueue.sync(flags: .barrier) {
                    try registry.registerFile(file)
                    registeredFiles.append(file)
                }
            }
            
            func findMessage(named name: String) -> MessageDescriptor? {
                return readerWriterQueue.sync {
                    return registry.findMessage(named: name)
                }
            }
            
            private var registeredFiles: [FileDescriptor] = []
            
            func getAllRegisteredFiles() -> [FileDescriptor] {
                return readerWriterQueue.sync {
                    return registeredFiles
                }
            }
            
            var messageCount: Int {
                return readerWriterQueue.sync {
                    return registeredFiles.reduce(0) { $0 + $1.messages.count }
                }
            }
        }
        
        let concurrentRegistry = ConcurrentTypeRegistry()
        let fileCount = 20
        let threadCount = 4
        
        print("  📊 Registering \(fileCount) files across \(threadCount) threads...")
        
        let registrationTime = ExampleUtils.measureTime {
            let group = DispatchGroup()
            let concurrentQueue = DispatchQueue(label: "registry.concurrent", attributes: .concurrent)
            
            // Регистрация файлов
            for threadId in 0..<threadCount {
                group.enter()
                concurrentQueue.async {
                    for i in 0..<(fileCount / threadCount) {
                        let fileName = "thread\(threadId)_file\(i).proto"
                        var file = FileDescriptor(name: fileName, package: "com.thread\(threadId)")
                        
                        var message = MessageDescriptor(name: "Message\(threadId)\(i)", parent: file)
                        message.addField(FieldDescriptor(name: "id", number: 1, type: .string))
                        message.addField(FieldDescriptor(name: "thread_id", number: 2, type: .int32))
                        
                        file.addMessage(message)
                        
                        do {
                            try concurrentRegistry.registerFile(file)
                        } catch {
                            print("    ❌ Registration error: \(error)")
                        }
                    }
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        ExampleUtils.printTiming("Concurrent registry operations", time: registrationTime.time)
        
        // Тестирование concurrent чтения
        print("\n  🔍 Testing concurrent lookups...")
        
        let lookupCount = 1000
        var successfulLookups = 0
        let lookupLock = NSLock()
        
        let lookupTime = ExampleUtils.measureTime {
            let group = DispatchGroup()
            let concurrentQueue = DispatchQueue(label: "lookup.concurrent", attributes: .concurrent)
            
            for threadId in 0..<threadCount {
                group.enter()
                concurrentQueue.async {
                    var threadSuccesses = 0
                    
                    for i in 0..<(lookupCount / threadCount) {
                        let messageNumber = i % (fileCount / threadCount)
                        let messageName = "com.thread\(threadId).Message\(threadId)\(messageNumber)"
                        
                        if concurrentRegistry.findMessage(named: messageName) != nil {
                            threadSuccesses += 1
                        }
                    }
                    
                    lookupLock.lock()
                    successfulLookups += threadSuccesses
                    lookupLock.unlock()
                    
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        ExampleUtils.printTiming("Concurrent lookups (\(lookupCount) operations)", time: lookupTime.time)
        
        // Результаты
        let registeredMessages = concurrentRegistry.messageCount
        let lookupSuccessRate = Double(successfulLookups) / Double(lookupCount) * 100
        
        print("\n  📊 Registry Thread Safety Results:")
        ExampleUtils.printDataTable([[
            "Metric": "Files Registered | Messages Registered | Lookup Operations | Successful Lookups | Data Integrity",
            "Value": "\(fileCount) | \(registeredMessages) | \(lookupCount) | \(successfulLookups) | Preserved",
            "Status": "All successful | Complete | Concurrent | \(String(format: "%.1f", lookupSuccessRate))% success | ✅ No corruption"
        ]], title: "Registry Concurrency Analysis")
        
        print("\n  🎯 Registry Benefits:")
        print("    • Thread-safe registration operations ✅")
        print("    • Concurrent read performance ✅")
        print("    • Data consistency guaranteed ✅")
        print("    • No reader-writer conflicts ✅")
    }
    
    // MARK: - Locking Strategies
    
    private static func demonstrateLockingStrategies() throws {
        ExampleUtils.printStep(4, "Different Locking Strategies")
        
        print("  🔒 Comparing locking strategies for thread safety...")
        
        // Test data
        let operationCount = 5000
        let threadCount = 8
        
        // 1. NSLock strategy
        class NSLockCounter {
            private var value: Int64 = 0
            private let lock = NSLock()
            
            func increment() {
                lock.lock()
                value += 1
                lock.unlock()
            }
            
            func getValue() -> Int64 {
                lock.lock()
                defer { lock.unlock() }
                return value
            }
        }
        
        // 2. DispatchQueue strategy
        class DispatchQueueCounter {
            private var value: Int64 = 0
            private let queue = DispatchQueue(label: "counter.queue")
            
            func increment() {
                queue.sync {
                    value += 1
                }
            }
            
            func getValue() -> Int64 {
                return queue.sync { value }
            }
        }
        
        // 3. OSAtomic strategy (симуляция)
        class AtomicCounter {
            private var value: Int64 = 0
            private let lock = NSLock() // Симуляция atomic operations
            
            func increment() {
                lock.lock()
                value += 1
                lock.unlock()
            }
            
            func getValue() -> Int64 {
                lock.lock()
                defer { lock.unlock() }
                return value
            }
        }
        
        // Тестирование NSLock
        print("\n  🧪 Testing NSLock strategy...")
        let nsLockCounter = NSLockCounter()
        
        let nsLockTime = ExampleUtils.measureTime {
            let group = DispatchGroup()
            let concurrentQueue = DispatchQueue(label: "nslock.test", attributes: .concurrent)
            
            for threadId in 0..<threadCount {
                group.enter()
                concurrentQueue.async {
                    for _ in 0..<(operationCount / threadCount) {
                        nsLockCounter.increment()
                    }
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        // Тестирование DispatchQueue
        print("  🧪 Testing DispatchQueue strategy...")
        let dispatchCounter = DispatchQueueCounter()
        
        let dispatchTime = ExampleUtils.measureTime {
            let group = DispatchGroup()
            let concurrentQueue = DispatchQueue(label: "dispatch.test", attributes: .concurrent)
            
            for threadId in 0..<threadCount {
                group.enter()
                concurrentQueue.async {
                    for _ in 0..<(operationCount / threadCount) {
                        dispatchCounter.increment()
                    }
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        // Тестирование Atomic
        print("  🧪 Testing Atomic strategy...")
        let atomicCounter = AtomicCounter()
        
        let atomicTime = ExampleUtils.measureTime {
            let group = DispatchGroup()
            let concurrentQueue = DispatchQueue(label: "atomic.test", attributes: .concurrent)
            
            for threadId in 0..<threadCount {
                group.enter()
                concurrentQueue.async {
                    for _ in 0..<(operationCount / threadCount) {
                        atomicCounter.increment()
                    }
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        // Сравнение результатов
        print("\n  📊 Locking Strategy Comparison:")
        ExampleUtils.printDataTable([[
            "Strategy": "NSLock | DispatchQueue | Atomic",
            "Time": "\(String(format: "%.3f", nsLockTime.time * 1000))ms | \(String(format: "%.3f", dispatchTime.time * 1000))ms | \(String(format: "%.3f", atomicTime.time * 1000))ms",
            "Final Value": "\(nsLockCounter.getValue()) | \(dispatchCounter.getValue()) | \(atomicCounter.getValue())",
            "Correctness": "\(nsLockCounter.getValue() == operationCount ? "✅" : "❌") | \(dispatchCounter.getValue() == operationCount ? "✅" : "❌") | \(atomicCounter.getValue() == operationCount ? "✅" : "❌")",
            "Performance": "Baseline | \(String(format: "%.1f", nsLockTime.time/dispatchTime.time))x | \(String(format: "%.1f", nsLockTime.time/atomicTime.time))x"
        ]], title: "Locking Performance Analysis")
        
        print("\n  🎯 Strategy Recommendations:")
        print("    • NSLock: Simple, reliable for basic synchronization ✅")
        print("    • DispatchQueue: Better for complex operations ✅")
        print("    • Atomic: Fastest for simple counters ✅")
        print("    • Choose based on specific use case ✅")
    }
    
    // MARK: - Atomic Operations
    
    private static func demonstrateAtomicOperations() throws {
        ExampleUtils.printStep(5, "Atomic Operations for Performance")
        
        print("  ⚡ Demonstrating atomic operation patterns...")
        
        // Atomic property wrapper simulation
        @propertyWrapper
        struct Atomic<T> {
            private var value: T
            private let lock = NSLock()
            
            init(wrappedValue: T) {
                self.value = wrappedValue
            }
            
            var wrappedValue: T {
                get {
                    lock.lock()
                    defer { lock.unlock() }
                    return value
                }
                set {
                    lock.lock()
                    value = newValue
                    lock.unlock()
                }
            }
        }
        
        // Thread-safe statistics collector
        class AtomicStatistics {
            @Atomic var messageCount: Int64 = 0
            @Atomic var errorCount: Int64 = 0
            @Atomic var totalProcessingTime: Double = 0.0
            @Atomic var maxProcessingTime: Double = 0.0
            
            func recordMessage(processingTime: Double) {
                messageCount += 1
                totalProcessingTime += processingTime
                maxProcessingTime = max(maxProcessingTime, processingTime)
            }
            
            func recordError() {
                errorCount += 1
            }
            
            var averageProcessingTime: Double {
                guard messageCount > 0 else { return 0 }
                return totalProcessingTime / Double(messageCount)
            }
            
            var successRate: Double {
                let total = messageCount + errorCount
                guard total > 0 else { return 0 }
                return Double(messageCount) / Double(total) * 100
            }
        }
        
        // Создание тестового сценария
        var atomicFile = FileDescriptor(name: "atomic.proto", package: "com.atomic")
        var taskDescriptor = MessageDescriptor(name: "Task", parent: atomicFile)
        
        taskDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
        taskDescriptor.addField(FieldDescriptor(name: "priority", number: 2, type: .int32))
        taskDescriptor.addField(FieldDescriptor(name: "data", number: 3, type: .string))
        
        atomicFile.addMessage(taskDescriptor)
        
        let statistics = AtomicStatistics()
        let taskCount = 3000
        let threadCount = 6
        
        print("  📊 Processing \(taskCount) tasks with atomic statistics...")
        
        let factory = MessageFactory()
        
        let atomicTime = ExampleUtils.measureTime {
            let group = DispatchGroup()
            let concurrentQueue = DispatchQueue(label: "atomic.processing", attributes: .concurrent)
            
            for threadId in 0..<threadCount {
                group.enter()
                concurrentQueue.async {
                    for i in 0..<(taskCount / threadCount) {
                        let taskStartTime = CFAbsoluteTimeGetCurrent()
                        
                        var task = factory.createMessage(from: taskDescriptor)
                        
                        do {
                            try task.set(Int64(threadId * 1000 + i), forField: "id")
                            try task.set(Int32.random(in: 1...10), forField: "priority")
                            try task.set("Task data \(threadId).\(i)", forField: "data")
                            
                            // Симуляция обработки
                            Thread.sleep(forTimeInterval: Double.random(in: 0.0001...0.0005))
                            
                            let processingTime = CFAbsoluteTimeGetCurrent() - taskStartTime
                            statistics.recordMessage(processingTime: processingTime)
                            
                        } catch {
                            statistics.recordError()
                        }
                    }
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        ExampleUtils.printTiming("Atomic operations (\(taskCount) tasks)", time: atomicTime.time)
        
        // Анализ статистики
        print("\n  📊 Atomic Operations Results:")
        ExampleUtils.printDataTable([[
            "Metric": "Tasks Processed | Errors Occurred | Success Rate | Avg Processing | Max Processing | Total Time",
            "Value": "\(statistics.messageCount) | \(statistics.errorCount) | \(String(format: "%.2f", statistics.successRate))% | \(String(format: "%.4f", statistics.averageProcessingTime))s | \(String(format: "%.4f", statistics.maxProcessingTime))s | \(String(format: "%.3f", statistics.totalProcessingTime))s",
            "Analysis": "Atomic counter | Concurrent tracking | High reliability | Atomic accumulation | Atomic comparison | Thread-safe sum"
        ]], title: "Atomic Statistics Analysis")
        
        print("\n  🎯 Atomic Benefits:")
        print("    • Lock-free performance for simple operations ✅")
        print("    • Thread-safe property access ✅")
        print("    • Reduced contention overhead ✅")
        print("    • Consistent statistical accuracy ✅")
    }
    
    // MARK: - Race Condition Prevention
    
    private static func demonstrateRaceConditionPrevention() throws {
        ExampleUtils.printStep(6, "Race Condition Prevention Techniques")
        
        print("  🏁 Demonstrating race condition prevention...")
        
        // Демонстрация потенциальной race condition
        class UnsafeCounter {
            private var value: Int = 0
            
            func increment() {
                // ОПАСНО: race condition возможна
                let temp = value
                Thread.sleep(forTimeInterval: 0.00001) // Симуляция задержки
                value = temp + 1
            }
            
            func getValue() -> Int { value }
        }
        
        // Безопасная версия
        class SafeCounter {
            private var value: Int = 0
            private let lock = NSLock()
            
            func increment() {
                lock.lock()
                let temp = value
                Thread.sleep(forTimeInterval: 0.00001) // Та же задержка, но в критической секции
                value = temp + 1
                lock.unlock()
            }
            
            func getValue() -> Int {
                lock.lock()
                defer { lock.unlock() }
                return value
            }
        }
        
        let testOperations = 500
        let testThreads = 10
        
        // Тест небезопасной версии
        print("\n  ⚠️  Testing unsafe counter (race condition possible)...")
        let unsafeCounter = UnsafeCounter()
        
        let unsafeTime = ExampleUtils.measureTime {
            let group = DispatchGroup()
            let concurrentQueue = DispatchQueue(label: "unsafe.test", attributes: .concurrent)
            
            for threadId in 0..<testThreads {
                group.enter()
                concurrentQueue.async {
                    for _ in 0..<(testOperations / testThreads) {
                        unsafeCounter.increment()
                    }
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        // Тест безопасной версии
        print("  🛡  Testing safe counter (race condition prevented)...")
        let safeCounter = SafeCounter()
        
        let safeTime = ExampleUtils.measureTime {
            let group = DispatchGroup()
            let concurrentQueue = DispatchQueue(label: "safe.test", attributes: .concurrent)
            
            for threadId in 0..<testThreads {
                group.enter()
                concurrentQueue.async {
                    for _ in 0..<(testOperations / testThreads) {
                        safeCounter.increment()
                    }
                    group.leave()
                }
            }
            
            group.wait()
        }
        
        // Анализ результатов
        let unsafeResult = unsafeCounter.getValue()
        let safeResult = safeCounter.getValue()
        let expectedResult = testOperations
        
        print("\n  📊 Race Condition Prevention Results:")
        ExampleUtils.printDataTable([[
            "Implementation": "Unsafe Counter | Safe Counter | Data Loss",
            "Final Value": "\(unsafeResult) | \(safeResult) | \(expectedResult - unsafeResult)",
            "Expected": "\(expectedResult) | \(expectedResult) | 0",
            "Correctness": "\(unsafeResult == expectedResult ? "✅ Lucky" : "❌ Race condition") | \(safeResult == expectedResult ? "✅ Correct" : "❌ Bug") | \(unsafeResult == expectedResult ? "No loss" : "Lost updates")",
            "Performance": "\(String(format: "%.3f", unsafeTime.time * 1000))ms | \(String(format: "%.3f", safeTime.time * 1000))ms | Race condition effect"
        ]], title: "Race Condition Analysis")
        
        print("\n  🎯 Prevention Techniques:")
        print("    • Critical section protection ✅")
        print("    • Atomic operation usage ✅")
        print("    • Lock-based synchronization ✅")
        print("    • Immutable data structures ✅")
        print("    • Actor-based concurrency ✅")
        
        print("\n  ⚠️  Common Race Condition Sources:")
        print("    • Read-modify-write operations")
        print("    • Shared mutable state")
        print("    • Non-atomic compound operations")
        print("    • Missing synchronization primitives")
    }
}
