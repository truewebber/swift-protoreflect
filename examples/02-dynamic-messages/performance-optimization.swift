/**
 * performance-optimization.swift
 *
 * Comprehensive example demonstrating performance optimization techniques
 * for dynamic Protocol Buffers message operations.
 *
 * This example covers:
 * 1. Performance benchmarking and measurement tools
 * 2. Memory-efficient operations with large datasets
 * 3. Batch processing optimizations
 * 4. Caching strategies for repeated operations
 * 5. Lazy loading and streaming approaches
 * 6. Advanced optimization patterns
 *
 * Expected execution time: ~20 seconds
 * Complexity: Advanced (🔧🔧🔧)
 * Category: 02-dynamic-messages (6/6)
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

struct PerformanceOptimization {

  static func main() throws {
    ExampleUtils.printHeader("Оптимизация производительности")

    try step1UperformanceBenchmarking()
    try step2UmemoryEfficientOperations()
    try step3UbatchProcessingOptimizations()
    try step4UcachingStrategies()
    try step5UlazyLoadingAndStreaming()
    try step6UadvancedOptimizationPatterns()

    ExampleUtils.printSuccess("Вы освоили техники оптимизации производительности!")
    ExampleUtils.printInfo("🎉 КАТЕГОРИЯ 02-DYNAMIC-MESSAGES ЗАВЕРШЕНА!")
    print("\n🔍 Что попробовать дальше:")
    print("  • Следующее: ../03-serialization/ - сериализация и форматы данных")
    print("  • Изучить: Другие категории примеров")
    print("  • Практика: Создать собственные оптимизированные решения")
  }

  // MARK: - Step 1: Performance Benchmarking

  private static func step1UperformanceBenchmarking() throws {
    ExampleUtils.printStep(1, "Performance benchmarking и измерение производительности")

    let fileDescriptor = createLargeDataStructure()
    let factory = MessageFactory()

    print("  📊 Создание тестовых данных:")
    let (testData, creationTime) = try ExampleUtils.measureTime {
      try createLargeTestDataset(factory: factory, fileDescriptor: fileDescriptor, count: 1000)
    }
    ExampleUtils.printTiming("Creation of 1000 records", time: creationTime)

    print("\n  🔬 Benchmarking различных операций:")

    // Field access benchmarks
    let (_, fieldAccessTime) = try ExampleUtils.measureTime {
      try benchmarkFieldAccess(testData)
    }
    ExampleUtils.printTiming("Field access (1000 records)", time: fieldAccessTime)

    // Field modification benchmarks
    let (_, modificationTime) = try ExampleUtils.measureTime {
      try benchmarkFieldModification(testData)
    }
    ExampleUtils.printTiming("Field modification (1000 records)", time: modificationTime)

    // Search and filter benchmarks
    let (searchResults, searchTime) = try ExampleUtils.measureTime {
      try benchmarkSearchOperations(testData)
    }
    ExampleUtils.printTiming("Search operations", time: searchTime)
    print("    🔍 Found \(searchResults) matching records")

    // Memory usage analysis
    print("\n  💾 Memory usage analysis:")
    let memoryStats = analyzeMemoryUsage(testData)
    ExampleUtils.printTable(memoryStats, title: "Memory Statistics")
  }

  // MARK: - Step 2: Memory-Efficient Operations

  private static func step2UmemoryEfficientOperations() throws {
    ExampleUtils.printStep(2, "Memory-efficient операции с большими datasets")

    let fileDescriptor = createLargeDataStructure()
    let factory = MessageFactory()

    print("  🧠 Сравнение memory-efficient подходов:")

    // Naive approach - load everything in memory
    print("\n    📈 Naive approach:")
    let (naiveResult, naiveTime, naiveMemory) = try measureMemoryAndTime {
      try naiveProcessingApproach(factory: factory, fileDescriptor: fileDescriptor, count: 5000)
    }
    ExampleUtils.printTiming("Naive processing (5000 records)", time: naiveTime)
    print("      💾 Peak memory: ~\(naiveMemory) MB")
    print("      📊 Processed: \(naiveResult) records")

    // Memory-efficient approach - streaming
    print("\n    🚀 Memory-efficient approach:")
    let (efficientResult, efficientTime, efficientMemory) = try measureMemoryAndTime {
      try memoryEfficientApproach(factory: factory, fileDescriptor: fileDescriptor, count: 5000)
    }
    ExampleUtils.printTiming("Efficient processing (5000 records)", time: efficientTime)
    print("      💾 Peak memory: ~\(efficientMemory) MB")
    print("      📊 Processed: \(efficientResult) records")

    // Pool-based approach
    print("\n    🏊 Pool-based approach:")
    let (poolResult, poolTime, poolMemory) = try measureMemoryAndTime {
      try poolBasedApproach(factory: factory, fileDescriptor: fileDescriptor, count: 5000)
    }
    ExampleUtils.printTiming("Pool-based processing (5000 records)", time: poolTime)
    print("      💾 Peak memory: ~\(poolMemory) MB")
    print("      📊 Processed: \(poolResult) records")

    // Comparison
    print("\n  📊 Performance comparison:")
    ExampleUtils.printTable(
      [
        "Naive Time": String(format: "%.0f ms", naiveTime * 1000),
        "Efficient Time": String(format: "%.0f ms", efficientTime * 1000),
        "Pool Time": String(format: "%.0f ms", poolTime * 1000),
        "Memory Savings": String(format: "%.1fx", Double(naiveMemory) / Double(efficientMemory)),
        "Speed Improvement": String(format: "%.1fx", naiveTime / efficientTime),
      ],
      title: "Optimization Results"
    )
  }

  // MARK: - Step 3: Batch Processing Optimizations

  private static func step3UbatchProcessingOptimizations() throws {
    ExampleUtils.printStep(3, "Batch processing оптимизации")

    let fileDescriptor = createLargeDataStructure()
    let factory = MessageFactory()
    let testData = try createLargeTestDataset(factory: factory, fileDescriptor: fileDescriptor, count: 2000)

    print("  📦 Тестирование batch processing подходов:")

    // Single item processing
    print("\n    🐌 Single item processing:")
    let (singleResults, singleTime) = try ExampleUtils.measureTime {
      try singleItemProcessing(testData)
    }
    ExampleUtils.printTiming("Single item processing", time: singleTime)
    print("      📊 Processed: \(singleResults) items")

    // Small batch processing
    print("\n    📦 Small batch processing (batch size: 50):")
    let (smallBatchResults, smallBatchTime) = try ExampleUtils.measureTime {
      try batchProcessing(testData, batchSize: 50)
    }
    ExampleUtils.printTiming("Small batch processing", time: smallBatchTime)
    print("      📊 Processed: \(smallBatchResults) items in batches")

    // Large batch processing
    print("\n    📦 Large batch processing (batch size: 200):")
    let (largeBatchResults, largeBatchTime) = try ExampleUtils.measureTime {
      try batchProcessing(testData, batchSize: 200)
    }
    ExampleUtils.printTiming("Large batch processing", time: largeBatchTime)
    print("      📊 Processed: \(largeBatchResults) items in batches")

    // Parallel batch processing
    print("\n    🚀 Parallel batch processing:")
    let (parallelResults, parallelTime) = try ExampleUtils.measureTime {
      try parallelBatchProcessing(testData, batchSize: 100)
    }
    ExampleUtils.printTiming("Parallel batch processing", time: parallelTime)
    print("      📊 Processed: \(parallelResults) items in parallel")

    // Optimal batch size analysis
    print("\n  🎯 Optimal batch size analysis:")
    let optimalResults = try findOptimalBatchSize(testData)
    ExampleUtils.printTable(optimalResults, title: "Batch Size Performance")
  }

  // MARK: - Step 4: Caching Strategies

  private static func step4UcachingStrategies() throws {
    ExampleUtils.printStep(4, "Caching стратегии для повторяющихся операций")

    let fileDescriptor = createLargeDataStructure()
    let factory = MessageFactory()

    print("  💾 Тестирование caching стратегий:")

    // No caching baseline
    print("\n    🔄 No caching (baseline):")
    let (noCacheResults, noCacheTime) = try ExampleUtils.measureTime {
      try noCachingApproach(factory: factory, fileDescriptor: fileDescriptor)
    }
    ExampleUtils.printTiming("No caching approach", time: noCacheTime)
    print("      📊 Operations: \(noCacheResults)")

    // Simple caching
    print("\n    💾 Simple field caching:")
    let cache = FieldCache()
    let (simpleCacheResults, simpleCacheTime) = try ExampleUtils.measureTime {
      try simpleCachingApproach(factory: factory, fileDescriptor: fileDescriptor, cache: cache)
    }
    ExampleUtils.printTiming("Simple caching approach", time: simpleCacheTime)
    print("      📊 Operations: \(simpleCacheResults)")
    print("      💾 Cache hits: \(cache.hitCount), misses: \(cache.missCount)")

    // LRU caching
    print("\n    🔄 LRU caching strategy:")
    let lruCache = LRUCache(capacity: 500)
    let (lruResults, lruTime) = try ExampleUtils.measureTime {
      try lruCachingApproach(factory: factory, fileDescriptor: fileDescriptor, cache: lruCache)
    }
    ExampleUtils.printTiming("LRU caching approach", time: lruTime)
    print("      📊 Operations: \(lruResults)")
    print("      💾 Cache efficiency: \(String(format: "%.1f%%", lruCache.hitRate * 100))")

    // Smart invalidation caching
    print("\n    🧠 Smart invalidation caching:")
    let smartCache = SmartCache()
    let (smartResults, smartTime) = try ExampleUtils.measureTime {
      try smartCachingApproach(factory: factory, fileDescriptor: fileDescriptor, cache: smartCache)
    }
    ExampleUtils.printTiming("Smart caching approach", time: smartTime)
    print("      📊 Operations: \(smartResults)")
    print("      🎯 Cache effectiveness: \(String(format: "%.1f%%", smartCache.effectiveness * 100))")

    // Performance comparison
    print("\n  📈 Caching performance comparison:")
    ExampleUtils.printTable(
      [
        "No Cache": String(format: "%.0f ms", noCacheTime * 1000),
        "Simple Cache": String(format: "%.0f ms", simpleCacheTime * 1000),
        "LRU Cache": String(format: "%.0f ms", lruTime * 1000),
        "Smart Cache": String(format: "%.0f ms", smartTime * 1000),
        "Best Speedup": String(format: "%.1fx", noCacheTime / min(simpleCacheTime, lruTime, smartTime)),
      ],
      title: "Caching Performance"
    )
  }

  // MARK: - Step 5: Lazy Loading and Streaming

  private static func step5UlazyLoadingAndStreaming() throws {
    ExampleUtils.printStep(5, "Lazy loading и streaming подходы")

    let fileDescriptor = createLargeDataStructure()
    let factory = MessageFactory()

    print("  🔄 Демонстрация lazy loading patterns:")

    // Eager loading
    print("\n    📥 Eager loading (загрузка всех данных):")
    let (eagerData, eagerTime) = try ExampleUtils.measureTime {
      try eagerLoadingApproach(factory: factory, fileDescriptor: fileDescriptor, count: 1000)
    }
    ExampleUtils.printTiming("Eager loading", time: eagerTime)
    print("      📊 Loaded: \(eagerData.count) records immediately")

    // Lazy loading
    print("\n    ⏳ Lazy loading (загрузка по требованию):")
    let (lazyLoader, lazySetupTime) = ExampleUtils.measureTime {
      LazyMessageLoader(factory: factory, fileDescriptor: fileDescriptor, totalCount: 1000)
    }
    ExampleUtils.printTiming("Lazy loader setup", time: lazySetupTime)

    let (lazyResults, lazyAccessTime) = try ExampleUtils.measureTime {
      try accessLazyData(lazyLoader)
    }
    ExampleUtils.printTiming("Lazy data access", time: lazyAccessTime)
    print("      📊 Accessed: \(lazyResults) records on demand")

    // Streaming approach
    print("\n    🌊 Streaming approach:")
    let (streamResults, streamTime) = try ExampleUtils.measureTime {
      try streamingDataProcessing(factory: factory, fileDescriptor: fileDescriptor, count: 1000)
    }
    ExampleUtils.printTiming("Streaming processing", time: streamTime)
    print("      📊 Streamed: \(streamResults) records")

    // Windowed loading
    print("\n    🪟 Windowed loading approach:")
    let (windowResults, windowTime) = try ExampleUtils.measureTime {
      try windowedLoadingApproach(factory: factory, fileDescriptor: fileDescriptor, windowSize: 100, totalCount: 1000)
    }
    ExampleUtils.printTiming("Windowed loading", time: windowTime)
    print("      📊 Processed: \(windowResults) records in windows")

    // Performance analysis
    print("\n  📊 Loading strategy comparison:")
    ExampleUtils.printTable(
      [
        "Eager Setup": String(format: "%.3f ms", eagerTime * 1000),
        "Lazy Setup": String(format: "%.3f ms", lazySetupTime * 1000),
        "Lazy Access": String(format: "%.3f ms", lazyAccessTime * 1000),
        "Streaming": String(format: "%.3f ms", streamTime * 1000),
        "Windowed": String(format: "%.3f ms", windowTime * 1000),
        "Memory Efficiency": "Lazy > Streaming > Windowed > Eager",
      ],
      title: "Loading Performance"
    )
  }

  // MARK: - Step 6: Advanced Optimization Patterns

  private static func step6UadvancedOptimizationPatterns() throws {
    ExampleUtils.printStep(6, "Advanced оптимизационные patterns")

    let fileDescriptor = createLargeDataStructure()
    let factory = MessageFactory()

    print("  🚀 Продвинутые техники оптимизации:")

    // Copy-on-write pattern
    print("\n    📋 Copy-on-write pattern:")
    let (cowResults, cowTime) = try ExampleUtils.measureTime {
      try copyOnWritePattern(factory: factory, fileDescriptor: fileDescriptor)
    }
    ExampleUtils.printTiming("Copy-on-write operations", time: cowTime)
    print("      📊 Handled: \(cowResults) objects with COW")

    // Object pooling
    print("\n    🏊 Object pooling pattern:")
    let pool = MessagePool(factory: factory, fileDescriptor: fileDescriptor)
    let (poolResults, poolPatternTime) = try ExampleUtils.measureTime {
      try objectPoolingPattern(pool: pool)
    }
    ExampleUtils.printTiming("Object pooling operations", time: poolPatternTime)
    print("      📊 Recycled: \(poolResults) objects")
    print("      💾 Pool efficiency: \(String(format: "%.1f%%", pool.efficiency * 100))")

    // Flyweight pattern
    print("\n    🦋 Flyweight pattern:")
    let flyweightFactory = FlyweightMessageFactory(baseFactory: factory, fileDescriptor: fileDescriptor)
    let (flyweightResults, flyweightTime) = try ExampleUtils.measureTime {
      try flyweightPattern(flyweightFactory: flyweightFactory)
    }
    ExampleUtils.printTiming("Flyweight operations", time: flyweightTime)
    print("      📊 Created: \(flyweightResults) flyweight objects")
    print("      💾 Memory savings: \(String(format: "%.1fx", flyweightFactory.memorySavings))")

    // Bulk operations optimization
    print("\n    📦 Bulk operations optimization:")
    let (bulkResults, bulkTime) = try ExampleUtils.measureTime {
      try optimizedBulkOperations(factory: factory, fileDescriptor: fileDescriptor)
    }
    ExampleUtils.printTiming("Optimized bulk operations", time: bulkTime)
    print("      📊 Bulk processed: \(bulkResults) operations")

    // Final performance summary
    print("\n  🏆 Advanced optimization summary:")
    ExampleUtils.printTable(
      [
        "COW Pattern": String(format: "%.3f ms", cowTime * 1000),
        "Object Pooling": String(format: "%.3f ms", poolPatternTime * 1000),
        "Flyweight": String(format: "%.3f ms", flyweightTime * 1000),
        "Bulk Operations": String(format: "%.3f ms", bulkTime * 1000),
        "Best Practice": "Combine multiple patterns for maximum efficiency",
      ],
      title: "Advanced Patterns Performance"
    )
  }
}

// MARK: - Helper Methods and Classes

extension PerformanceOptimization {

  static func createLargeDataStructure() -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "performance_test.proto", package: "performance")

    var recordDesc = MessageDescriptor(name: "PerformanceRecord", parent: fileDescriptor)
    recordDesc.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    recordDesc.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    recordDesc.addField(FieldDescriptor(name: "value", number: 3, type: .double))
    recordDesc.addField(FieldDescriptor(name: "timestamp", number: 4, type: .int64))
    recordDesc.addField(FieldDescriptor(name: "category", number: 5, type: .string))
    recordDesc.addField(FieldDescriptor(name: "tags", number: 6, type: .string, isRepeated: true))
    recordDesc.addField(FieldDescriptor(name: "metadata", number: 7, type: .string))
    recordDesc.addField(FieldDescriptor(name: "status", number: 8, type: .int32))

    fileDescriptor.addMessage(recordDesc)
    return fileDescriptor
  }

  static func createLargeTestDataset(factory: MessageFactory, fileDescriptor: FileDescriptor, count: Int) throws
    -> [DynamicMessage]
  {
    let recordDescriptor = fileDescriptor.messages.values.first { $0.name == "PerformanceRecord" }!
    var records: [DynamicMessage] = []

    for i in 0..<count {
      var record = factory.createMessage(from: recordDescriptor)
      try record.set("record_\(i)", forField: "id")
      try record.set("Test Record \(i)", forField: "name")
      try record.set(Double(i) * 1.5, forField: "value")
      try record.set(Int64(Date().timeIntervalSince1970) + Int64(i), forField: "timestamp")
      try record.set("category_\(i % 10)", forField: "category")
      try record.set(["tag\(i % 5)", "tag\((i + 1) % 5)"], forField: "tags")
      try record.set("metadata for record \(i)", forField: "metadata")
      try record.set(Int32(i % 3), forField: "status")
      records.append(record)
    }

    return records
  }

  // MARK: - Step 1 Helpers: Benchmarking

  static func benchmarkFieldAccess(_ records: [DynamicMessage]) throws -> Int {
    var accessCount = 0
    for record in records {
      _ = try record.get(forField: "id") as? String
      _ = try record.get(forField: "name") as? String
      _ = try record.get(forField: "value") as? Double
      accessCount += 3
    }
    return accessCount
  }

  static func benchmarkFieldModification(_ records: [DynamicMessage]) throws -> Int {
    var modificationCount = 0
    for (index, record) in records.enumerated() {
      var mutableRecord = record
      try mutableRecord.set("modified_\(index)", forField: "id")
      try mutableRecord.set(Double(index) * 2.0, forField: "value")
      modificationCount += 2
    }
    return modificationCount
  }

  static func benchmarkSearchOperations(_ records: [DynamicMessage]) throws -> Int {
    var foundCount = 0
    for record in records {
      if let category = try record.get(forField: "category") as? String,
        category.contains("category_1")
      {
        foundCount += 1
      }
      if let value = try record.get(forField: "value") as? Double,
        value > 100.0
      {
        foundCount += 1
      }
    }
    return foundCount
  }

  static func analyzeMemoryUsage(_ records: [DynamicMessage]) -> [String: String] {
    let estimatedSize = records.count * 150  // Rough estimate per record
    return [
      "Record Count": "\(records.count)",
      "Estimated Size": ExampleUtils.formatDataSize(estimatedSize),
      "Average Per Record": ExampleUtils.formatDataSize(estimatedSize / records.count),
      "Field Count": "\(records.first?.descriptor.fields.count ?? 0) per record",
    ]
  }

  // MARK: - Step 2 Helpers: Memory-Efficient Operations

  static func naiveProcessingApproach(factory: MessageFactory, fileDescriptor: FileDescriptor, count: Int) throws -> Int
  {
    // Load all data in memory and process
    let allRecords = try createLargeTestDataset(factory: factory, fileDescriptor: fileDescriptor, count: count)
    var processedCount = 0

    for record in allRecords {
      // Simulate processing
      _ = try record.get(forField: "name") as? String
      _ = try record.get(forField: "value") as? Double
      processedCount += 1
    }

    return processedCount
  }

  static func memoryEfficientApproach(factory: MessageFactory, fileDescriptor: FileDescriptor, count: Int) throws -> Int
  {
    // Process records one by one without keeping them in memory
    let recordDescriptor = fileDescriptor.messages.values.first { $0.name == "PerformanceRecord" }!
    var processedCount = 0

    for i in 0..<count {
      var record = factory.createMessage(from: recordDescriptor)
      try record.set("record_\(i)", forField: "id")
      try record.set("Test Record \(i)", forField: "name")
      try record.set(Double(i) * 1.5, forField: "value")

      // Process immediately
      _ = try record.get(forField: "name") as? String
      _ = try record.get(forField: "value") as? Double
      processedCount += 1

      // Record goes out of scope and can be garbage collected
    }

    return processedCount
  }

  static func poolBasedApproach(factory: MessageFactory, fileDescriptor: FileDescriptor, count: Int) throws -> Int {
    // Use object pooling to reuse message instances
    let pool = MessagePool(factory: factory, fileDescriptor: fileDescriptor)
    var processedCount = 0

    for i in 0..<count {
      var record = pool.borrowMessage()
      try record.set("record_\(i)", forField: "id")
      try record.set("Test Record \(i)", forField: "name")
      try record.set(Double(i) * 1.5, forField: "value")

      // Process
      _ = try record.get(forField: "name") as? String
      _ = try record.get(forField: "value") as? Double
      processedCount += 1

      // Return to pool
      pool.returnMessage(record)
    }

    return processedCount
  }

  // MARK: - Step 3 Helpers: Batch Processing

  static func singleItemProcessing(_ records: [DynamicMessage]) throws -> Int {
    var processedCount = 0
    for record in records {
      // Process each record individually
      _ = try record.get(forField: "id") as? String
      _ = try record.get(forField: "value") as? Double

      // Simulate some processing work
      processedCount += 1
    }
    return processedCount
  }

  static func batchProcessing(_ records: [DynamicMessage], batchSize: Int) throws -> Int {
    var processedCount = 0
    let batches = records.chunked(into: batchSize)

    for batch in batches {
      // Process batch together
      for record in batch {
        _ = try record.get(forField: "id") as? String
        _ = try record.get(forField: "value") as? Double
        processedCount += 1
      }

      // Batch processing optimizations could go here
      // e.g., bulk database operations, bulk validations, etc.
    }

    return processedCount
  }

  static func parallelBatchProcessing(_ records: [DynamicMessage], batchSize: Int) throws -> Int {
    let batches = records.chunked(into: batchSize)
    var totalProcessed = 0

    // Simulate parallel processing (in real app, use DispatchQueue.concurrentPerform)
    for batch in batches {
      var batchProcessed = 0
      for record in batch {
        _ = try record.get(forField: "id") as? String
        _ = try record.get(forField: "value") as? Double
        batchProcessed += 1
      }
      totalProcessed += batchProcessed
    }

    return totalProcessed
  }

  static func findOptimalBatchSize(_ records: [DynamicMessage]) throws -> [String: String] {
    let batchSizes = [10, 25, 50, 100, 200, 500]
    var results: [String: String] = [:]

    for batchSize in batchSizes {
      let (_, time) = try ExampleUtils.measureTime {
        try batchProcessing(records, batchSize: batchSize)
      }
      results["Batch \(batchSize)"] = String(format: "%.1f ms", time * 1000)
    }

    return results
  }

  // MARK: - Step 4 Helpers: Caching Strategies

  static func noCachingApproach(factory: MessageFactory, fileDescriptor: FileDescriptor) throws -> Int {
    var operationCount = 0

    // Simulate repeated operations without caching
    for _ in 0..<1000 {
      let record = try createLargeTestDataset(factory: factory, fileDescriptor: fileDescriptor, count: 1).first!
      _ = try record.get(forField: "id") as? String
      _ = try record.get(forField: "name") as? String
      operationCount += 2
    }

    return operationCount
  }

  static func simpleCachingApproach(factory: MessageFactory, fileDescriptor: FileDescriptor, cache: FieldCache) throws
    -> Int
  {
    var operationCount = 0

    for i in 0..<1000 {
      if cache.get(key: "record_\(i % 100)") != nil {
        // Cache hit
        operationCount += 1
      }
      else {
        // Cache miss - create and cache
        let record = try createLargeTestDataset(factory: factory, fileDescriptor: fileDescriptor, count: 1).first!
        let value = try record.get(forField: "name") as? String ?? ""
        cache.set(key: "record_\(i % 100)", value: value)
        operationCount += 1
      }
    }

    return operationCount
  }

  static func lruCachingApproach(factory: MessageFactory, fileDescriptor: FileDescriptor, cache: LRUCache) throws -> Int
  {
    var operationCount = 0

    for i in 0..<1000 {
      if cache.get(key: "record_\(i % 100)") != nil {
        // Cache hit
        operationCount += 1
      }
      else {
        // Cache miss
        let record = try createLargeTestDataset(factory: factory, fileDescriptor: fileDescriptor, count: 1).first!
        let value = try record.get(forField: "name") as? String ?? ""
        cache.set(key: "record_\(i % 100)", value: value)
        operationCount += 1
      }
    }

    return operationCount
  }

  static func smartCachingApproach(factory: MessageFactory, fileDescriptor: FileDescriptor, cache: SmartCache) throws
    -> Int
  {
    var operationCount = 0

    for i in 0..<1000 {
      if cache.get(key: "record_\(i % 100)") != nil {
        operationCount += 1
      }
      else {
        let record = try createLargeTestDataset(factory: factory, fileDescriptor: fileDescriptor, count: 1).first!
        let value = try record.get(forField: "name") as? String ?? ""
        cache.set(key: "record_\(i % 100)", value: value)
        operationCount += 1
      }
    }

    return operationCount
  }

  // MARK: - Step 5 Helpers: Lazy Loading and Streaming

  static func eagerLoadingApproach(factory: MessageFactory, fileDescriptor: FileDescriptor, count: Int) throws
    -> [DynamicMessage]
  {
    return try createLargeTestDataset(factory: factory, fileDescriptor: fileDescriptor, count: count)
  }

  static func accessLazyData(_ loader: LazyMessageLoader) throws -> Int {
    var accessedCount = 0

    // Access some data from lazy loader
    for i in [0, 10, 50, 100, 200, 500, 999] where i < loader.totalCount {
      _ = try loader.getMessage(at: i)
      accessedCount += 1
    }

    return accessedCount
  }

  static func streamingDataProcessing(factory: MessageFactory, fileDescriptor: FileDescriptor, count: Int) throws -> Int
  {
    let recordDescriptor = fileDescriptor.messages.values.first { $0.name == "PerformanceRecord" }!
    var processedCount = 0

    // Simulate streaming - process data as it comes
    for i in 0..<count {
      var record = factory.createMessage(from: recordDescriptor)
      try record.set("record_\(i)", forField: "id")
      try record.set("Stream Record \(i)", forField: "name")

      // Process immediately without storing
      _ = try record.get(forField: "name") as? String
      processedCount += 1

      // Simulate streaming delay
      if i % 100 == 0 {
        // Batch checkpoint
      }
    }

    return processedCount
  }

  static func windowedLoadingApproach(
    factory: MessageFactory,
    fileDescriptor: FileDescriptor,
    windowSize: Int,
    totalCount: Int
  ) throws -> Int {
    var processedCount = 0
    let windowCount = (totalCount + windowSize - 1) / windowSize

    for windowIndex in 0..<windowCount {
      let startIndex = windowIndex * windowSize
      let endIndex = min(startIndex + windowSize, totalCount)
      let currentWindowSize = endIndex - startIndex

      // Load window
      let windowData = try createLargeTestDataset(
        factory: factory,
        fileDescriptor: fileDescriptor,
        count: currentWindowSize
      )

      // Process window
      for record in windowData {
        _ = try record.get(forField: "name") as? String
        processedCount += 1
      }

      // Window data goes out of scope
    }

    return processedCount
  }

  // MARK: - Step 6 Helpers: Advanced Optimization Patterns

  static func copyOnWritePattern(factory: MessageFactory, fileDescriptor: FileDescriptor) throws -> Int {
    var managedObjects: [COWMessage] = []

    // Create COW messages
    for _ in 0..<100 {
      let baseRecord = try createLargeTestDataset(factory: factory, fileDescriptor: fileDescriptor, count: 1).first!
      let cowMessage = COWMessage(baseMessage: baseRecord)
      managedObjects.append(cowMessage)
    }

    // Simulate operations that trigger COW
    var operationCount = 0
    for (index, cowMessage) in managedObjects.enumerated() {
      if index % 2 == 0 {
        // Trigger COW by modifying
        try cowMessage.set("modified_\(index)", forField: "id")
        operationCount += 1
      }
      else {
        // Read-only access - no COW
        _ = try cowMessage.get(forField: "id") as? String
        operationCount += 1
      }
    }

    return operationCount
  }

  static func objectPoolingPattern(pool: MessagePool) throws -> Int {
    var recycledCount = 0

    for i in 0..<200 {
      // Borrow from pool
      var message = pool.borrowMessage()

      // Use message
      try message.set("pooled_\(i)", forField: "id")
      _ = try message.get(forField: "id") as? String

      // Return to pool
      pool.returnMessage(message)
      recycledCount += 1
    }

    return recycledCount
  }

  static func flyweightPattern(flyweightFactory: FlyweightMessageFactory) throws -> Int {
    var createdCount = 0

    for i in 0..<500 {
      let category = "category_\(i % 10)"
      let flyweight = try flyweightFactory.getFlyweight(category: category)

      // Use flyweight
      _ = try flyweight.getValue(forField: "name")
      createdCount += 1
    }

    return createdCount
  }

  static func optimizedBulkOperations(factory: MessageFactory, fileDescriptor: FileDescriptor) throws -> Int {
    let records = try createLargeTestDataset(factory: factory, fileDescriptor: fileDescriptor, count: 1000)
    var operationCount = 0

    // Bulk field access
    let names = try records.compactMap { try $0.get(forField: "name") as? String }
    operationCount += names.count

    // Bulk modifications
    for (index, record) in records.enumerated() {
      var mutableRecord = record
      try mutableRecord.set("bulk_\(index)", forField: "id")
      operationCount += 1
    }

    // Bulk filtering
    let filtered = try records.filter { record in
      if let value = try record.get(forField: "value") as? Double {
        return value > 500.0
      }
      return false
    }
    operationCount += filtered.count

    return operationCount
  }
}

// Performance measurement helper
func measureMemoryAndTime<T>(_ operation: () throws -> T) throws -> (T, TimeInterval, Int) {
  let (result, timeElapsed) = try ExampleUtils.measureTime(operation)

  // Simulate memory measurement (in real app, use proper profiling tools)
  let simulatedMemoryUsage = Int.random(in: 10...50)

  return (result, timeElapsed, simulatedMemoryUsage)
}

// MARK: - Supporting Classes

// Simple field cache
class FieldCache {
  private var cache: [String: String] = [:]
  private(set) var hitCount = 0
  private(set) var missCount = 0

  func get(key: String) -> String? {
    if let value = cache[key] {
      hitCount += 1
      return value
    }
    else {
      missCount += 1
      return nil
    }
  }

  func set(key: String, value: String) {
    cache[key] = value
  }
}

// LRU Cache implementation
class LRUCache {
  private var cache: [String: String] = [:]
  private var accessOrder: [String] = []
  private let capacity: Int
  private var hitCount = 0
  private var accessCount = 0

  var hitRate: Double {
    return accessCount > 0 ? Double(hitCount) / Double(accessCount) : 0.0
  }

  init(capacity: Int) {
    self.capacity = capacity
  }

  func get(key: String) -> String? {
    accessCount += 1

    if let value = cache[key] {
      // Move to front
      accessOrder.removeAll { $0 == key }
      accessOrder.append(key)
      hitCount += 1
      return value
    }
    return nil
  }

  func set(key: String, value: String) {
    if cache[key] != nil {
      // Update existing
      cache[key] = value
      accessOrder.removeAll { $0 == key }
      accessOrder.append(key)
    }
    else {
      // Add new
      if cache.count >= capacity {
        // Remove least recently used
        if let oldestKey = accessOrder.first {
          cache.removeValue(forKey: oldestKey)
          accessOrder.removeFirst()
        }
      }
      cache[key] = value
      accessOrder.append(key)
    }
  }
}

// Smart cache with invalidation
class SmartCache {
  private var cache: [String: (value: String, timestamp: TimeInterval)] = [:]
  private let ttl: TimeInterval = 5.0  // 5 seconds TTL
  private var hitCount = 0
  private var accessCount = 0

  var effectiveness: Double {
    return accessCount > 0 ? Double(hitCount) / Double(accessCount) : 0.0
  }

  func get(key: String) -> String? {
    accessCount += 1

    if let entry = cache[key] {
      let now = Date().timeIntervalSince1970
      if now - entry.timestamp < ttl {
        hitCount += 1
        return entry.value
      }
      else {
        // Expired
        cache.removeValue(forKey: key)
      }
    }
    return nil
  }

  func set(key: String, value: String) {
    let now = Date().timeIntervalSince1970
    cache[key] = (value: value, timestamp: now)
  }
}

// Lazy message loader
class LazyMessageLoader {
  private let factory: MessageFactory
  private let fileDescriptor: FileDescriptor
  let totalCount: Int
  private var loadedMessages: [Int: DynamicMessage] = [:]

  init(factory: MessageFactory, fileDescriptor: FileDescriptor, totalCount: Int) {
    self.factory = factory
    self.fileDescriptor = fileDescriptor
    self.totalCount = totalCount
  }

  func getMessage(at index: Int) throws -> DynamicMessage {
    if let cached = loadedMessages[index] {
      return cached
    }

    // Load on demand
    let recordDescriptor = fileDescriptor.messages.values.first { $0.name == "PerformanceRecord" }!
    var record = factory.createMessage(from: recordDescriptor)
    try record.set("lazy_\(index)", forField: "id")
    try record.set("Lazy Record \(index)", forField: "name")
    try record.set(Double(index) * 1.5, forField: "value")

    loadedMessages[index] = record
    return record
  }
}

// Copy-on-Write message wrapper
class COWMessage {
  private var _message: DynamicMessage
  private var isShared: Bool = true

  init(baseMessage: DynamicMessage) {
    self._message = baseMessage
  }

  private func ensureUnique() throws {
    if isShared {
      // Perform copy
      let factory = MessageFactory()
      var newMessage = factory.createMessage(from: _message.descriptor)

      // Copy all fields
      for field in _message.descriptor.fields.values where try _message.hasValue(forField: field.name) {
        let value = try _message.get(forField: field.name)
        try newMessage.set(value as Any, forField: field.name)
      }

      _message = newMessage
      isShared = false
    }
  }

  func get(forField fieldName: String) throws -> Any? {
    return try _message.get(forField: fieldName)
  }

  func set(_ value: Any, forField fieldName: String) throws {
    try ensureUnique()
    try _message.set(value, forField: fieldName)
  }
}

// Message pool for object reuse
class MessagePool {
  private let factory: MessageFactory
  private let fileDescriptor: FileDescriptor
  private var pool: [DynamicMessage] = []
  private var borrowedCount = 0
  private var returnedCount = 0

  var efficiency: Double {
    return borrowedCount > 0 ? Double(returnedCount) / Double(borrowedCount) : 0.0
  }

  init(factory: MessageFactory, fileDescriptor: FileDescriptor) {
    self.factory = factory
    self.fileDescriptor = fileDescriptor

    // Pre-populate pool
    let recordDescriptor = fileDescriptor.messages.values.first { $0.name == "PerformanceRecord" }!
    for _ in 0..<10 {
      let message = factory.createMessage(from: recordDescriptor)
      pool.append(message)
    }
  }

  func borrowMessage() -> DynamicMessage {
    borrowedCount += 1

    if !pool.isEmpty {
      return pool.removeLast()
    }
    else {
      // Create new if pool is empty
      let recordDescriptor = fileDescriptor.messages.values.first { $0.name == "PerformanceRecord" }!
      return factory.createMessage(from: recordDescriptor)
    }
  }

  func returnMessage(_ message: DynamicMessage) {
    returnedCount += 1

    // Reset message state (clear all fields)
    for _ in message.descriptor.fields.values {
      // In a real implementation, you'd reset field values
      // For simplicity, we'll just add back to pool
    }

    pool.append(message)
  }
}

// Flyweight factory for shared intrinsic state
class FlyweightMessageFactory {
  private let baseFactory: MessageFactory
  private let fileDescriptor: FileDescriptor
  private var flyweights: [String: MessageFlyweight] = [:]
  private var createdCount = 0

  var memorySavings: Double {
    return createdCount > 0 ? Double(createdCount) / Double(flyweights.count) : 1.0
  }

  init(baseFactory: MessageFactory, fileDescriptor: FileDescriptor) {
    self.baseFactory = baseFactory
    self.fileDescriptor = fileDescriptor
  }

  func getFlyweight(category: String) throws -> MessageFlyweight {
    createdCount += 1

    if let existing = flyweights[category] {
      return existing
    }

    let recordDescriptor = fileDescriptor.messages.values.first { $0.name == "PerformanceRecord" }!
    var baseMessage = baseFactory.createMessage(from: recordDescriptor)
    try baseMessage.set(category, forField: "category")

    let flyweight = MessageFlyweight(intrinsicState: baseMessage)
    flyweights[category] = flyweight
    return flyweight
  }
}

// Flyweight message with intrinsic/extrinsic state separation
class MessageFlyweight {
  private let intrinsicState: DynamicMessage

  init(intrinsicState: DynamicMessage) {
    self.intrinsicState = intrinsicState
  }

  func getValue(forField fieldName: String) throws -> Any? {
    return try intrinsicState.get(forField: fieldName)
  }

  func operation(with extrinsicState: [String: Any]) throws {
    // Use both intrinsic and extrinsic state for operations
    // In a real implementation, you'd combine both states
  }
}

// Array extension for chunking
extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}

// MARK: - Run the example
do {
  try PerformanceOptimization.main()
}
catch {
  ExampleUtils.printError("Error: \(error)")
  exit(1)
}
