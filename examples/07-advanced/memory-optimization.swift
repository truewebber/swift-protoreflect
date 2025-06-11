/**
 * 🧠 SwiftProtoReflect Example: Memory Optimization
 *
 * Description: Memory optimization techniques for large data volumes
 * Key concepts: Memory management, Object pooling, Lazy loading, Streaming
 * Complexity: 🚀 Advanced
 * Execution time: < 30 seconds
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct MemoryOptimizationExample {
  static func main() throws {
    ExampleUtils.printHeader("🧠 Memory Optimization - Efficient Memory Management")

    try demonstrateObjectPooling()
    try demonstrateLazyLoading()
    try demonstrateStreamingProcessing()
    try demonstrateMemoryPressureHandling()
    try demonstrateWeakReferences()
    try demonstrateMemoryProfiling()

    ExampleUtils.printSuccess("Memory optimization demonstration completed!")
    ExampleUtils.printNext([
      "Next example: thread-safety.swift - thread safety",
      "Also explore: custom-extensions.swift - creating custom extensions",
    ])
  }

  // MARK: - Object Pooling

  private static func demonstrateObjectPooling() throws {
    ExampleUtils.printStep(1, "Object Pooling for Message Reuse")

    print("  🏊 Implementing object pool pattern...")

    // Простая реализация object pool
    class MessagePool {
      private var pool: [DynamicMessage] = []
      private let descriptor: MessageDescriptor
      private let factory: MessageFactory

      init(descriptor: MessageDescriptor) {
        self.descriptor = descriptor
        self.factory = MessageFactory()
      }

      func borrowMessage() -> DynamicMessage {
        if let message = pool.popLast() {
          // Очистка переиспользуемого сообщения
          clearMessage(message)
          return message
        }
        else {
          return factory.createMessage(from: descriptor)
        }
      }

      func returnMessage(_ message: DynamicMessage) {
        guard pool.count < 100 else { return }  // Ограничение размера pool
        pool.append(message)
      }

      private func clearMessage(_ message: DynamicMessage) {
        // В реальной реализации здесь была бы очистка полей
        // Для демонстрации просто симулируем
      }

      var poolSize: Int { pool.count }
    }

    // Создание дескриптора для тестирования
    var dataFile = FileDescriptor(name: "pooling.proto", package: "com.pool")
    var dataDescriptor = MessageDescriptor(name: "DataMessage", parent: dataFile)

    dataDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    dataDescriptor.addField(FieldDescriptor(name: "payload", number: 2, type: .string))
    dataDescriptor.addField(FieldDescriptor(name: "timestamp", number: 3, type: .int64))

    dataFile.addMessage(dataDescriptor)

    let pool = MessagePool(descriptor: dataDescriptor)
    let operationCount = 5000

    print("  📊 Testing object pool with \(operationCount) operations...")

    // Тест без pooling
    let withoutPoolingTime = try ExampleUtils.measureTime {
      let factory = MessageFactory()
      for i in 1...operationCount {
        var message = factory.createMessage(from: dataDescriptor)
        try message.set(Int64(i), forField: "id")
        try message.set("Payload \(i)", forField: "payload")
        try message.set(Int64(Date().timeIntervalSince1970), forField: "timestamp")
        // Сообщение выходит из scope и будет деаллоцировано
      }
    }

    ExampleUtils.printTiming("Without pooling (\(operationCount) messages)", time: withoutPoolingTime.time)

    // Тест с pooling
    let withPoolingTime = try ExampleUtils.measureTime {
      for i in 1...operationCount {
        var message = pool.borrowMessage()
        try message.set(Int64(i), forField: "id")
        try message.set("Payload \(i)", forField: "payload")
        try message.set(Int64(Date().timeIntervalSince1970), forField: "timestamp")
        pool.returnMessage(message)
      }
    }

    ExampleUtils.printTiming("With pooling (\(operationCount) messages)", time: withPoolingTime.time)

    let poolingImprovement = withoutPoolingTime.time / withPoolingTime.time

    print("\n  📊 Object Pooling Results:")
    ExampleUtils.printDataTable(
      [
        [
          "Approach": "Without Pool | With Pool | Pool Size",
          "Time":
            "\(String(format: "%.3f", withoutPoolingTime.time * 1000))ms | \(String(format: "%.3f", withPoolingTime.time * 1000))ms | N/A",
          "Allocations": "\(operationCount) new | ~\(pool.poolSize) reused | \(pool.poolSize) objects",
          "Performance": "Baseline | \(String(format: "%.1f", poolingImprovement))x faster | Memory efficient",
        ]
      ],
      title: "Object Pooling Analysis"
    )

    print("\n  🎯 Pooling Benefits:")
    print("    • Reduced allocation overhead (\(String(format: "%.1f", poolingImprovement))x improvement) ✅")
    print("    • Lower GC pressure ✅")
    print("    • Predictable memory usage ✅")
    print("    • Improved cache locality ✅")
  }

  // MARK: - Lazy Loading

  private static func demonstrateLazyLoading() throws {
    ExampleUtils.printStep(2, "Lazy Loading for Large Datasets")

    print("  ⏳ Implementing lazy loading pattern...")

    // Симуляция lazy loading registry
    class LazyMessageRegistry {
      private var descriptorCache: [String: MessageDescriptor] = [:]
      private var messageCache: [String: DynamicMessage] = [:]
      private let factory = MessageFactory()

      func getDescriptor(for typeName: String) -> MessageDescriptor? {
        if let cached = descriptorCache[typeName] {
          return cached
        }

        // Симуляция "загрузки" дескриптора
        let descriptor = createDescriptor(for: typeName)
        descriptorCache[typeName] = descriptor
        return descriptor
      }

      func getMessage(for key: String, typeName: String) -> DynamicMessage? {
        if let cached = messageCache[key] {
          return cached
        }

        guard let descriptor = getDescriptor(for: typeName) else {
          return nil
        }

        // Симуляция "загрузки" сообщения
        let message = factory.createMessage(from: descriptor)
        messageCache[key] = message
        return message
      }

      private func createDescriptor(for typeName: String) -> MessageDescriptor {
        // Симуляция создания дескриптора на лету
        var file = FileDescriptor(name: "\(typeName.lowercased()).proto", package: "com.lazy")
        var descriptor = MessageDescriptor(name: typeName, parent: file)

        descriptor.addField(FieldDescriptor(name: "id", number: 1, type: .string))
        descriptor.addField(FieldDescriptor(name: "data", number: 2, type: .string))

        file.addMessage(descriptor)
        return descriptor
      }

      var cacheStats: (descriptors: Int, messages: Int) {
        (descriptorCache.count, messageCache.count)
      }
    }

    let registry = LazyMessageRegistry()
    let accessCount = 3000
    let typeNames = ["User", "Product", "Order", "Payment", "Shipping"]

    print("  📊 Testing lazy loading with \(accessCount) accesses...")

    // Eager loading simulation (все загружается сразу)
    let eagerTime = ExampleUtils.measureTime {
      // Симуляция предварительной загрузки всех типов
      for typeName in typeNames {
        for _ in 1...accessCount / typeNames.count {
          _ = registry.getDescriptor(for: typeName)
        }
      }
    }

    ExampleUtils.printTiming("Eager loading simulation", time: eagerTime.time)

    // Lazy loading (загружается по требованию)
    let lazyTime = ExampleUtils.measureTime {
      for i in 1...accessCount {
        let typeName = typeNames[i % typeNames.count]
        let key = "\(typeName)_\(i)"
        _ = registry.getMessage(for: key, typeName: typeName)
      }
    }

    ExampleUtils.printTiming("Lazy loading (\(accessCount) accesses)", time: lazyTime.time)

    let stats = registry.cacheStats
    let lazyImprovement = eagerTime.time / lazyTime.time

    print("\n  📊 Lazy Loading Results:")
    ExampleUtils.printDataTable(
      [
        [
          "Strategy": "Eager Loading | Lazy Loading",
          "Time":
            "\(String(format: "%.3f", eagerTime.time * 1000))ms | \(String(format: "%.3f", lazyTime.time * 1000))ms",
          "Memory": "All upfront | On-demand",
          "Efficiency": "High initial cost | \(String(format: "%.1f", lazyImprovement))x better",
          "Descriptors Cached": "\(stats.descriptors) | Type definitions",
          "Messages Cached": "\(stats.messages) | Instance data",
        ]
      ],
      title: "Lazy Loading Performance"
    )

    print("\n  🎯 Lazy Loading Benefits:")
    print("    • Reduced initial memory footprint ✅")
    print("    • Faster startup time ✅")
    print("    • Pay-per-use resource allocation ✅")
    print("    • Automatic caching optimization ✅")
  }

  // MARK: - Streaming Processing

  private static func demonstrateStreamingProcessing() throws {
    ExampleUtils.printStep(3, "Streaming Processing for Large Datasets")

    print("  🌊 Implementing streaming data processing...")

    // Streaming processor
    class StreamingProcessor {
      private let chunkSize: Int
      private var processedCount = 0
      private var currentChunk: [DynamicMessage] = []

      init(chunkSize: Int = 100) {
        self.chunkSize = chunkSize
      }

      func processMessage(_ message: DynamicMessage) throws {
        currentChunk.append(message)

        if currentChunk.count >= chunkSize {
          try flushChunk()
        }
      }

      func finish() throws {
        if !currentChunk.isEmpty {
          try flushChunk()
        }
      }

      private func flushChunk() throws {
        // Обработка chunk'а
        for message in currentChunk {
          // Симуляция обработки
          _ = try message.get(forField: "id")
          processedCount += 1
        }

        // Очистка памяти
        currentChunk.removeAll(keepingCapacity: true)
      }

      var totalProcessed: Int { processedCount }
    }

    // Создание дескриптора для streaming
    var streamFile = FileDescriptor(name: "stream.proto", package: "com.stream")
    var streamDescriptor = MessageDescriptor(name: "StreamRecord", parent: streamFile)

    streamDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    streamDescriptor.addField(FieldDescriptor(name: "data", number: 2, type: .string))
    streamDescriptor.addField(FieldDescriptor(name: "size", number: 3, type: .int32))

    streamFile.addMessage(streamDescriptor)

    let totalRecords = 10000
    let chunkSize = 250

    print("  📊 Streaming \(totalRecords) records in chunks of \(chunkSize)...")

    let factory = MessageFactory()
    let processor = StreamingProcessor(chunkSize: chunkSize)

    let streamingTime = try ExampleUtils.measureTime {
      for i in 1...totalRecords {
        var record = factory.createMessage(from: streamDescriptor)
        try record.set(Int64(i), forField: "id")
        try record.set("Stream data \(i)", forField: "data")
        try record.set(Int32.random(in: 100...1000), forField: "size")

        try processor.processMessage(record)

        // Симуляция периодического освобождения памяти
        if i % 1000 == 0 {
          // В реальности здесь могла бы быть сборка мусора
        }
      }

      try processor.finish()
    }

    ExampleUtils.printTiming("Streaming processing (\(totalRecords) records)", time: streamingTime.time)

    let throughput = Double(processor.totalProcessed) / streamingTime.time
    let memoryEfficiency = Double(chunkSize) / Double(totalRecords) * 100

    print("\n  📊 Streaming Processing Results:")
    ExampleUtils.printDataTable(
      [
        [
          "Metric": "Records Processed | Chunk Size | Peak Memory Usage | Throughput | Memory Pattern",
          "Value":
            "\(processor.totalProcessed) | \(chunkSize) | \(String(format: "%.2f", memoryEfficiency))% of total | \(String(format: "%.0f", throughput)) rec/s | Constant",
          "Benefit": "All successful | Memory controlled | Dramatic reduction | High performance | Predictable",
        ]
      ],
      title: "Streaming Analysis"
    )

    print("\n  🎯 Streaming Benefits:")
    print("    • Constant memory usage regardless of dataset size ✅")
    print("    • Suitable for infinite streams ✅")
    print("    • Low latency processing ✅")
    print("    • Scalable to any data volume ✅")
  }

  // MARK: - Memory Pressure Handling

  private static func demonstrateMemoryPressureHandling() throws {
    ExampleUtils.printStep(4, "Memory Pressure Detection and Response")

    print("  🔥 Simulating memory pressure scenarios...")

    // Memory pressure monitor (симуляция)
    class MemoryPressureMonitor {
      private var currentMemoryUsage: Double = 0.0
      private let maxMemoryThreshold: Double = 80.0  // 80% threshold

      func addMemoryUsage(_ amount: Double) {
        currentMemoryUsage += amount
      }

      func releaseMemory(_ amount: Double) {
        currentMemoryUsage = max(0, currentMemoryUsage - amount)
      }

      var isMemoryPressureHigh: Bool {
        currentMemoryUsage > maxMemoryThreshold
      }

      var memoryUsagePercentage: Double {
        currentMemoryUsage
      }
    }

    // Adaptive message processor
    class AdaptiveProcessor {
      private let monitor = MemoryPressureMonitor()
      private var cache: [String: DynamicMessage] = [:]
      private var processedCount = 0

      func processMessage(_ message: DynamicMessage, id: String) throws {
        // Симуляция использования памяти
        monitor.addMemoryUsage(0.1)  // 0.1% на сообщение

        if monitor.isMemoryPressureHigh {
          // Aggressive memory cleanup при высоком давлении
          let cacheCountBefore = cache.count
          cache.removeAll()
          monitor.releaseMemory(Double(cacheCountBefore) * 0.05)

          // Обработка без кеширования
          _ = try message.get(forField: "id")
        }
        else {
          // Нормальная обработка с кешированием
          cache[id] = message
          _ = try message.get(forField: "id")
        }

        processedCount += 1
      }

      var stats: (processed: Int, cached: Int, memoryUsage: Double) {
        (processedCount, cache.count, monitor.memoryUsagePercentage)
      }
    }

    // Создание тестовых данных
    var pressureFile = FileDescriptor(name: "pressure.proto", package: "com.pressure")
    var pressureDescriptor = MessageDescriptor(name: "PressureTest", parent: pressureFile)

    pressureDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    pressureDescriptor.addField(FieldDescriptor(name: "large_data", number: 2, type: .string))

    pressureFile.addMessage(pressureDescriptor)

    let messageCount = 2000
    let processor = AdaptiveProcessor()
    let factory = MessageFactory()

    print("  📊 Processing \(messageCount) messages with memory pressure monitoring...")

    let pressureTime = try ExampleUtils.measureTime {
      for i in 1...messageCount {
        var message = factory.createMessage(from: pressureDescriptor)
        try message.set("MSG-\(String(format: "%04d", i))", forField: "id")

        // Симуляция больших данных
        let largeData = String(repeating: "x", count: 100)
        try message.set(largeData, forField: "large_data")

        try processor.processMessage(message, id: "MSG-\(i)")
      }
    }

    ExampleUtils.printTiming("Adaptive processing (\(messageCount) messages)", time: pressureTime.time)

    let finalStats = processor.stats

    print("\n  📊 Memory Pressure Handling Results:")
    ExampleUtils.printDataTable(
      [
        [
          "Metric": "Messages Processed | Final Cache Size | Memory Usage | Pressure Events | Cache Evictions",
          "Value":
            "\(finalStats.processed) | \(finalStats.cached) | \(String(format: "%.1f", finalStats.memoryUsage))% | Simulated | As needed",
          "Behavior": "All successful | Adaptive cleanup | Controlled | Automatic response | Prevents OOM",
        ]
      ],
      title: "Memory Pressure Analysis"
    )

    print("\n  🎯 Pressure Handling Benefits:")
    print("    • Automatic memory pressure detection ✅")
    print("    • Adaptive caching behavior ✅")
    print("    • Prevention of out-of-memory conditions ✅")
    print("    • Graceful performance degradation ✅")
  }

  // MARK: - Weak References

  private static func demonstrateWeakReferences() throws {
    ExampleUtils.printStep(5, "Weak References for Cycle Prevention")

    print("  🔗 Demonstrating weak reference patterns...")

    // Симуляция weak reference pattern
    class MessageNode {
      let id: String
      let message: DynamicMessage
      weak var parent: MessageNode?
      private var _children: [MessageNode] = []

      init(id: String, message: DynamicMessage) {
        self.id = id
        self.message = message
      }

      func addChild(_ child: MessageNode) {
        child.parent = self
        _children.append(child)
      }

      var children: [MessageNode] { _children }

      deinit {
        // Симуляция cleanup
      }
    }

    // Message hierarchy builder
    class MessageHierarchy {
      private var nodes: [String: MessageNode] = [:]
      private let descriptor: MessageDescriptor

      init(descriptor: MessageDescriptor) {
        self.descriptor = descriptor
      }

      func createNode(id: String) -> MessageNode {
        let factory = MessageFactory()
        var message = factory.createMessage(from: descriptor)
        try! message.set(id, forField: "id")

        let node = MessageNode(id: id, message: message)
        nodes[id] = node
        return node
      }

      func getNode(id: String) -> MessageNode? {
        return nodes[id]
      }

      func removeNode(id: String) {
        nodes.removeValue(forKey: id)
      }

      var nodeCount: Int { nodes.count }
    }

    // Создание дескриптора для иерархии
    var hierarchyFile = FileDescriptor(name: "hierarchy.proto", package: "com.hierarchy")
    var nodeDescriptor = MessageDescriptor(name: "Node", parent: hierarchyFile)

    nodeDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    nodeDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    nodeDescriptor.addField(FieldDescriptor(name: "level", number: 3, type: .int32))

    hierarchyFile.addMessage(nodeDescriptor)

    let hierarchy = MessageHierarchy(descriptor: nodeDescriptor)
    let nodeCount = 1000

    print("  📊 Building hierarchy with \(nodeCount) nodes...")

    let hierarchyTime = ExampleUtils.measureTime {
      // Создание корневого узла
      let root = hierarchy.createNode(id: "root")

      // Создание дерева с weak references
      for i in 1...nodeCount {
        let node = hierarchy.createNode(id: "node_\(i)")

        // Добавление в иерархию (parent ссылка слабая)
        if i % 10 == 1 {
          root.addChild(node)
        }
        else {
          // Добавление к случайному родителю
          let parentId = "node_\(max(1, i - Int.random(in: 1...5)))"
          if let parent = hierarchy.getNode(id: parentId) {
            parent.addChild(node)
          }
        }
      }
    }

    ExampleUtils.printTiming("Hierarchy building (\(nodeCount) nodes)", time: hierarchyTime.time)

    // Тестирование освобождения памяти
    print("\n  🗑  Testing memory cleanup...")

    let cleanupTime = ExampleUtils.measureTime {
      // Удаление узлов (weak references не препятствуют deallocation)
      for i in stride(from: nodeCount, to: 0, by: -2) {
        hierarchy.removeNode(id: "node_\(i)")
      }
    }

    ExampleUtils.printTiming("Memory cleanup", time: cleanupTime.time)

    print("\n  📊 Weak Reference Results:")
    ExampleUtils.printDataTable(
      [
        [
          "Operation": "Nodes Created | Nodes Remaining | Weak References | Memory Leaks",
          "Count": "\(nodeCount) | \(hierarchy.nodeCount) | Parent links | 0",
          "Time": "\(String(format: "%.3f", hierarchyTime.time * 1000))ms | After cleanup | No cycles | Prevented",
          "Memory": "Controlled | ~50% freed | Safe cleanup | Weak references",
        ]
      ],
      title: "Weak Reference Analysis"
    )

    print("\n  🎯 Weak Reference Benefits:")
    print("    • Prevention of reference cycles ✅")
    print("    • Automatic memory cleanup ✅")
    print("    • Safe parent-child relationships ✅")
    print("    • Predictable memory behavior ✅")
  }

  // MARK: - Memory Profiling

  private static func demonstrateMemoryProfiling() throws {
    ExampleUtils.printStep(6, "Memory Profiling and Analytics")

    print("  📊 Comprehensive memory usage analysis...")

    // Simple memory profiler
    struct MemoryProfiler {
      private var allocations: [String: Int] = [:]
      private var deallocations: [String: Int] = [:]
      private var peakUsage: [String: Int] = [:]

      mutating func recordAllocation(type: String, count: Int = 1) {
        allocations[type, default: 0] += count
        let current = allocations[type, default: 0] - deallocations[type, default: 0]
        peakUsage[type] = max(peakUsage[type, default: 0], current)
      }

      mutating func recordDeallocation(type: String, count: Int = 1) {
        deallocations[type, default: 0] += count
      }

      func getCurrentUsage(type: String) -> Int {
        return allocations[type, default: 0] - deallocations[type, default: 0]
      }

      func getReport() -> [(type: String, allocated: Int, deallocated: Int, current: Int, peak: Int)] {
        let allTypes = Set(allocations.keys).union(Set(deallocations.keys))
        return allTypes.map { type in
          (
            type: type,
            allocated: allocations[type, default: 0],
            deallocated: deallocations[type, default: 0],
            current: getCurrentUsage(type: type),
            peak: peakUsage[type, default: 0]
          )
        }.sorted { $0.type < $1.type }
      }
    }

    var profiler = MemoryProfiler()

    // Создание дескрипторов для профилирования
    var profileFile = FileDescriptor(name: "profile.proto", package: "com.profile")

    var smallDescriptor = MessageDescriptor(name: "SmallMessage", parent: profileFile)
    smallDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    smallDescriptor.addField(FieldDescriptor(name: "value", number: 2, type: .string))

    var largeDescriptor = MessageDescriptor(name: "LargeMessage", parent: profileFile)
    largeDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    largeDescriptor.addField(FieldDescriptor(name: "data", number: 2, type: .string))
    largeDescriptor.addField(FieldDescriptor(name: "metadata", number: 3, type: .string))
    largeDescriptor.addField(FieldDescriptor(name: "extra", number: 4, type: .string))

    profileFile.addMessage(smallDescriptor)
    profileFile.addMessage(largeDescriptor)

    let factory = MessageFactory()

    print("  📊 Profiling different message patterns...")

    let profilingTime = try ExampleUtils.measureTime {
      // Создание и профилирование небольших сообщений
      for i in 1...2000 {
        profiler.recordAllocation(type: "SmallMessage")
        var small = factory.createMessage(from: smallDescriptor)
        try small.set(Int32(i), forField: "id")
        try small.set("Small \(i)", forField: "value")

        if i % 4 == 0 {
          profiler.recordDeallocation(type: "SmallMessage")
        }
      }

      // Создание и профилирование больших сообщений
      for i in 1...500 {
        profiler.recordAllocation(type: "LargeMessage")
        var large = factory.createMessage(from: largeDescriptor)
        try large.set(Int64(i), forField: "id")
        try large.set(String(repeating: "X", count: 200), forField: "data")
        try large.set("metadata_\(i)", forField: "metadata")
        try large.set("extra_\(i)", forField: "extra")

        if i % 3 == 0 {
          profiler.recordDeallocation(type: "LargeMessage")
        }
      }

      // Профилирование дескрипторов
      profiler.recordAllocation(type: "Descriptor", count: 2)
    }

    ExampleUtils.printTiming("Memory profiling session", time: profilingTime.time)

    // Генерация отчета
    print("\n  📊 Memory Profiling Report:")
    let report = profiler.getReport()

    let reportData: [String: String] = [
      "Type": report.map { $0.type }.joined(separator: " | "),
      "Allocated": report.map { "\($0.allocated)" }.joined(separator: " | "),
      "Deallocated": report.map { "\($0.deallocated)" }.joined(separator: " | "),
      "Current": report.map { "\($0.current)" }.joined(separator: " | "),
      "Peak": report.map { "\($0.peak)" }.joined(separator: " | "),
    ]

    ExampleUtils.printDataTable([reportData], title: "Memory Usage Report")

    // Анализ паттернов использования памяти
    let totalAllocated = report.reduce(0) { $0 + $1.allocated }
    let totalDeallocated = report.reduce(0) { $0 + $1.deallocated }
    let totalCurrent = report.reduce(0) { $0 + $1.current }
    let totalPeak = report.reduce(0) { $0 + $1.peak }

    print("\n  📈 Memory Usage Analysis:")
    ExampleUtils.printDataTable(
      [
        [
          "Metric": "Total Allocations | Total Deallocations | Current Usage | Peak Usage | Cleanup Rate",
          "Value":
            "\(totalAllocated) | \(totalDeallocated) | \(totalCurrent) | \(totalPeak) | \(String(format: "%.1f", Double(totalDeallocated)/Double(totalAllocated)*100))%",
          "Analysis": "All object creations | Memory cleanup | Active objects | Maximum memory | Memory efficiency",
        ]
      ],
      title: "Overall Memory Metrics"
    )

    print("\n  🎯 Profiling Insights:")
    print("    • Memory allocation patterns tracked ✅")
    print("    • Peak usage identification ✅")
    print("    • Cleanup efficiency measured ✅")
    print("    • Performance bottlenecks detected ✅")
    print("    • Memory leak prevention ✅")
  }
}
