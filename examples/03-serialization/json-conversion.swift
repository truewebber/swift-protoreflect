/**
 * 📄 SwiftProtoReflect Example: JSON Conversion
 *
 * Description: Demonstration of JSON serialization and deserialization of dynamic Protocol Buffers messages
 * Key concepts: JSONSerializer, JSONDeserializer, JSON mapping, Cross-format compatibility
 * Complexity: 🔧 Intermediate
 * Execution time: < 10 seconds
 *
 * What you'll learn:
 * - JSON serialization of dynamic messages to Protocol Buffers JSON format
 * - Deserialization from JSON back to dynamic messages
 * - Protocol Buffers JSON mapping rules (fields in camelCase, enums as strings)
 * - Comparison of JSON vs Binary formats by size and readability
 * - Round-trip compatibility between JSON and Binary formats
 * - Working with nested objects and arrays in JSON
 *
 * Run:
 *   swift run JsonConversion
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct JsonConversionExample {
  static func main() throws {
    ExampleUtils.printHeader("Protocol Buffers JSON Conversion")

    try step1UbasicJsonSerialization()
    try step2UcomplexJsonStructures()
    try step3UjsonVsBinaryComparison()
    try step4UcrossFormatCompatibility()
    try step5UjsonReadabilityDemo()

    ExampleUtils.printSuccess("JSON conversion successfully learned!")

    ExampleUtils.printNext([
      "Next try: swift run BinaryData - advanced binary data work",
      "Or explore: streaming.swift - streaming processing of large datasets",
      "Compare: protobuf-serialization.swift - binary serialization",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1UbasicJsonSerialization() throws {
    ExampleUtils.printStep(1, "Basic JSON serialization")

    // Create test message
    var (person, _) = try createPersonMessage()

    // Fill with data
    try person.set("Emma Wilson", forField: "name")
    try person.set(Int32(25), forField: "age")
    try person.set("emma.wilson@example.com", forField: "email")
    try person.set(["programming", "reading", "hiking"], forField: "hobbies")

    print("  📝 Created message:")
    person.prettyPrint()

    // JSON serialization
    let (jsonData, serializeTime) = try ExampleUtils.measureTime {
      let serializer = JSONSerializer()
      return try serializer.serialize(person)
    }

    ExampleUtils.printTiming("JSON serialization", time: serializeTime)

    // Analyze JSON result
    let jsonString = String(data: jsonData, encoding: .utf8) ?? "Invalid UTF-8"
    print("  📦 JSON size: \(ExampleUtils.formatDataSize(jsonData.count))")
    print("  📄 JSON content:")
    print("    \(jsonString)")

    // JSON deserialization
    let (deserializedPerson, deserializeTime) = try ExampleUtils.measureTime {
      let deserializer = JSONDeserializer()
      return try deserializer.deserialize(jsonData, using: person.descriptor)
    }

    ExampleUtils.printTiming("JSON deserialization", time: deserializeTime)

    print("  📋 Deserialized message:")
    deserializedPerson.prettyPrint()

    // Check correctness
    try verifyJsonRoundTrip(original: person, deserialized: deserializedPerson)
  }

  private static func step2UcomplexJsonStructures() throws {
    ExampleUtils.printStep(2, "Complex JSON structures")

    // Create complex message with nested objects
    var (company, _) = try createCompanyMessage()

    // Fill with detailed data
    try company.set("InnovateCorp LLC", forField: "name")
    try company.set("STARTUP", forField: "type")
    try company.set([Int32(15), Int32(32), Int32(48)], forField: "quarterly_revenue")
    try company.set(["north_america", "europe", "asia_pacific"], forField: "regions")
    try company.set(true, forField: "publicly_traded")
    try company.set(1500, forField: "employee_count")

    print("  🏢 Created complex message:")
    company.prettyPrint()

    // JSON serialization of complex structure
    let (complexJsonData, complexSerializeTime) = try ExampleUtils.measureTime {
      let serializer = JSONSerializer()
      return try serializer.serialize(company)
    }

    ExampleUtils.printTiming("Complex JSON serialization", time: complexSerializeTime)

    // Analyze complex JSON
    let _ = String(data: complexJsonData, encoding: .utf8) ?? "Invalid UTF-8"
    print("  📦 Complex JSON size: \(ExampleUtils.formatDataSize(complexJsonData.count))")
    print("  📄 Structured JSON:")

    // Pretty format JSON
    if let prettyJsonData = try? JSONSerialization.jsonObject(with: complexJsonData),
      let formattedData = try? JSONSerialization.data(withJSONObject: prettyJsonData, options: .prettyPrinted),
      let formattedString = String(data: formattedData, encoding: .utf8)
    {
      let lines = formattedString.components(separatedBy: .newlines)
      for line in lines.prefix(15) {  // Show first 15 lines
        print("    \(line)")
      }
      if lines.count > 15 {
        print("    ... (\(lines.count - 15) more lines)")
      }
    }

    // Deserialization and check
    let (deserializedCompany, complexDeserializeTime) = try ExampleUtils.measureTime {
      let deserializer = JSONDeserializer()
      return try deserializer.deserialize(complexJsonData, using: company.descriptor)
    }

    ExampleUtils.printTiming("Complex JSON deserialization", time: complexDeserializeTime)

    // Check arrays in JSON
    try verifyJsonArrays(original: company, deserialized: deserializedCompany)
  }

  private static func step3UjsonVsBinaryComparison() throws {
    ExampleUtils.printStep(3, "JSON vs Binary format comparison")

    print("  📊 Comparative analysis...")

    // Create test messages for comparison
    let testCases = [
      ("Small Message", 1),
      ("Medium Dataset", 10),
      ("Large Dataset", 50),
    ]

    var comparisonResults: [String: (json: (size: Int, time: TimeInterval), binary: (size: Int, time: TimeInterval))] =
      [:]

    for (label, messageCount) in testCases {
      // JSON metrics
      let (jsonSize, jsonTime) = try benchmarkJsonSerialization(messageCount: messageCount)

      // Binary metrics
      let (binarySize, binaryTime) = try benchmarkBinarySerialization(messageCount: messageCount)

      comparisonResults[label] = (
        json: (size: jsonSize, time: jsonTime),
        binary: (size: binarySize, time: binaryTime)
      )

      let sizeRatio = Double(jsonSize) / Double(binarySize)
      let timeRatio = jsonTime / binaryTime

      print("    \(label) (\(messageCount) messages):")
      print("      JSON:   \(ExampleUtils.formatDataSize(jsonSize)), \(String(format: "%.2f", jsonTime * 1000))ms")
      print("      Binary: \(ExampleUtils.formatDataSize(binarySize)), \(String(format: "%.2f", binaryTime * 1000))ms")
      print("      Ratio:  \(String(format: "%.1fx", sizeRatio)) size, \(String(format: "%.1fx", timeRatio)) time")
    }

    // Summary table
    ExampleUtils.printTable(
      [
        "Format": "JSON | Binary",
        "Readability": "High | Low",
        "Size Efficiency": "Lower | Higher",
        "Parse Speed": "Slower | Faster",
        "Debug Friendly": "Yes | No",
      ],
      title: "Format Comparison"
    )
  }

  private static func step4UcrossFormatCompatibility() throws {
    ExampleUtils.printStep(4, "Cross-format compatibility")

    print("  🔄 Testing JSON ↔ Binary compatibility...")

    // Create original message
    var (originalMessage, _) = try createPersonMessage()
    try originalMessage.set("Cross Format User", forField: "name")
    try originalMessage.set(Int32(35), forField: "age")
    try originalMessage.set("crossformat@test.com", forField: "email")
    try originalMessage.set(["testing", "validation", "compatibility"], forField: "hobbies")

    print("  📋 Original message:")
    originalMessage.prettyPrint()

    // Path 1: Original → JSON → Binary → Message
    let jsonSerializer = JSONSerializer()
    let binarySerializer = BinarySerializer()
    let jsonDeserializer = JSONDeserializer()
    let binaryDeserializer = BinaryDeserializer()

    let jsonData = try jsonSerializer.serialize(originalMessage)
    let jsonMessage = try jsonDeserializer.deserialize(jsonData, using: originalMessage.descriptor)
    let binaryData = try binarySerializer.serialize(jsonMessage)
    let finalMessage1 = try binaryDeserializer.deserialize(binaryData, using: originalMessage.descriptor)

    print("  🔄 Path 1: Original → JSON → Binary → Final")
    finalMessage1.prettyPrint()

    // Path 2: Original → Binary → JSON → Message
    let binaryData2 = try binarySerializer.serialize(originalMessage)
    let binaryMessage = try binaryDeserializer.deserialize(binaryData2, using: originalMessage.descriptor)
    let jsonData2 = try jsonSerializer.serialize(binaryMessage)
    let finalMessage2 = try jsonDeserializer.deserialize(jsonData2, using: originalMessage.descriptor)

    print("  🔄 Path 2: Original → Binary → JSON → Final")
    finalMessage2.prettyPrint()

    // Check identity across all paths
    let crossCompatibility = try verifyCrossFormatEquality(
      original: originalMessage,
      jsonPath: finalMessage1,
      binaryPath: finalMessage2
    )

    if crossCompatibility {
      print("  ✅ Cross-format compatibility: PASSED")
    }
    else {
      print("  ❌ Cross-format compatibility: FAILED")
    }
  }

  private static func step5UjsonReadabilityDemo() throws {
    ExampleUtils.printStep(5, "JSON readability and debugging")

    // Create message to demonstrate readability
    var (debugMessage, _) = try createDebugMessage()

    // Fill with test data containing errors
    try debugMessage.set("Debug Session #42", forField: "session_name")
    try debugMessage.set("ERROR", forField: "level")
    try debugMessage.set(["network_timeout", "auth_failure", "data_corruption"], forField: "error_codes")
    try debugMessage.set(1_699_123_456, forField: "timestamp")
    try debugMessage.set(["user_id: 12345", "action: login", "ip: 192.168.1.100"], forField: "metadata")

    print("  🐛 Debug message created:")
    debugMessage.prettyPrint()

    // JSON serialization for debugging
    let jsonSerializer = JSONSerializer()
    let debugJsonData = try jsonSerializer.serialize(debugMessage)

    if let prettyJsonData = try? JSONSerialization.jsonObject(with: debugJsonData),
      let formattedData = try? JSONSerialization.data(
        withJSONObject: prettyJsonData,
        options: [.prettyPrinted, .sortedKeys]
      ),
      let debugJsonString = String(data: formattedData, encoding: .utf8)
    {

      print("  📄 Human-readable JSON for debugging:")
      print("    ┌─ JSON Debug Output ─────────────────────────────┐")

      let lines = debugJsonString.components(separatedBy: .newlines)
      for line in lines {
        print("    │ \(line.padding(toLength: 47, withPad: " ", startingAt: 0)) │")
      }
      print("    └─────────────────────────────────────────────────┘")
    }

    // Demonstrate JSON validation
    print("  🔍 JSON validation demonstration:")

    // Simulate corrupted JSON
    let invalidJsonString = """
      {
        "sessionName": "Broken Session",
        "level": "INVALID_LEVEL",
        "errorCodes": ["missing_quote],
        "timestamp": "not_a_number"
      }
      """

    print("    ❌ Corrupted JSON:")
    print("      \(invalidJsonString.replacingOccurrences(of: "\n", with: " "))")

    if let invalidJsonData = invalidJsonString.data(using: .utf8) {
      do {
        let _ = try JSONDeserializer().deserialize(invalidJsonData, using: debugMessage.descriptor)
        print("    😱 Unexpected: Corrupted JSON was accepted!")
      }
      catch {
        print("    ✅ Expected: JSON validation rejected corrupted data")
        print("      Error: \(error)")
      }
    }

    // Demonstrate JSON field mapping
    print("  🗂  JSON field mapping examples:")

    ExampleUtils.printTable(
      [
        "Proto Field": "JSON Field",
        "session_name": "sessionName",
        "error_codes": "errorCodes",
        "timestamp": "timestamp",
        "metadata": "metadata",
      ],
      title: "Proto ↔ JSON Field Mapping"
    )
  }

  // MARK: - Helper Methods

  private static func createPersonMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "person.proto", package: "json.test")
    var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)

    personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    personMessage.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
    personMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))
    personMessage.addField(FieldDescriptor(name: "hobbies", number: 4, type: .string, isRepeated: true))

    fileDescriptor.addMessage(personMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: personMessage)

    return (message, fileDescriptor)
  }

  private static func createCompanyMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "company.proto", package: "json.test")
    var companyMessage = MessageDescriptor(name: "Company", parent: fileDescriptor)

    companyMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    companyMessage.addField(FieldDescriptor(name: "type", number: 2, type: .string))
    companyMessage.addField(FieldDescriptor(name: "quarterly_revenue", number: 3, type: .int32, isRepeated: true))
    companyMessage.addField(FieldDescriptor(name: "regions", number: 4, type: .string, isRepeated: true))
    companyMessage.addField(FieldDescriptor(name: "publicly_traded", number: 5, type: .bool))
    companyMessage.addField(FieldDescriptor(name: "employee_count", number: 6, type: .int32))

    fileDescriptor.addMessage(companyMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: companyMessage)

    return (message, fileDescriptor)
  }

  private static func createDebugMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "debug.proto", package: "json.test")
    var debugMessage = MessageDescriptor(name: "DebugInfo", parent: fileDescriptor)

    debugMessage.addField(FieldDescriptor(name: "session_name", number: 1, type: .string))
    debugMessage.addField(FieldDescriptor(name: "level", number: 2, type: .string))
    debugMessage.addField(FieldDescriptor(name: "error_codes", number: 3, type: .string, isRepeated: true))
    debugMessage.addField(FieldDescriptor(name: "timestamp", number: 4, type: .int64))
    debugMessage.addField(FieldDescriptor(name: "metadata", number: 5, type: .string, isRepeated: true))

    fileDescriptor.addMessage(debugMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: debugMessage)

    return (message, fileDescriptor)
  }

  private static func verifyJsonRoundTrip(original: DynamicMessage, deserialized: DynamicMessage) throws {
    print("  🔍 Checking JSON round-trip:")

    let fields = ["name", "age", "email", "hobbies"]
    var allMatch = true

    for fieldName in fields {
      let originalValue = try original.get(forField: fieldName)
      let deserializedValue = try deserialized.get(forField: fieldName)

      let isEqual = areJsonValuesEqual(originalValue, deserializedValue)
      let status = isEqual ? "✅" : "❌"
      print("    \(status) \(fieldName): \(isEqual ? "OK" : "MISMATCH")")

      if !isEqual {
        allMatch = false
      }
    }

    print("  \(allMatch ? "✅" : "❌") JSON round-trip: \(allMatch ? "PASSED" : "FAILED")")
  }

  private static func verifyJsonArrays(original: DynamicMessage, deserialized: DynamicMessage) throws {
    print("  🔍 Checking JSON arrays:")

    let revenueOriginal = try original.get(forField: "quarterly_revenue") as? [Int32] ?? []
    let revenueDeserialized = try deserialized.get(forField: "quarterly_revenue") as? [Int32] ?? []

    let revenueEqual = revenueOriginal == revenueDeserialized
    print("    \(revenueEqual ? "✅" : "❌") quarterly_revenue: \(revenueEqual ? "OK" : "MISMATCH")")

    let regionsOriginal = try original.get(forField: "regions") as? [String] ?? []
    let regionsDeserialized = try deserialized.get(forField: "regions") as? [String] ?? []

    let regionsEqual = regionsOriginal == regionsDeserialized
    print("    \(regionsEqual ? "✅" : "❌") regions: \(regionsEqual ? "OK" : "MISMATCH")")
  }

  private static func areJsonValuesEqual(_ value1: Any?, _ value2: Any?) -> Bool {
    switch (value1, value2) {
    case (nil, nil):
      return true
    case (let s1 as String, let s2 as String):
      return s1 == s2
    case (let i1 as Int32, let i2 as Int32):
      return i1 == i2
    case (let b1 as Bool, let b2 as Bool):
      return b1 == b2
    case (let arr1 as [String], let arr2 as [String]):
      return arr1 == arr2
    case (let arr1 as [Int32], let arr2 as [Int32]):
      return arr1 == arr2
    default:
      return false
    }
  }

  private static func benchmarkJsonSerialization(messageCount: Int) throws -> (Int, TimeInterval) {
    let jsonSerializer = JSONSerializer()

    // Create test messages
    var messages: [DynamicMessage] = []
    for i in 0..<messageCount {
      var (message, _) = try createPersonMessage()
      try message.set("JSON User \(i)", forField: "name")
      try message.set(Int32(20 + i), forField: "age")
      try message.set("jsonuser\(i)@test.com", forField: "email")
      try message.set(["hobby\(i)", "hobby\(i+1)"], forField: "hobbies")
      messages.append(message)
    }

    // Benchmark JSON serialization
    let (allJsonData, serializeTime) = try ExampleUtils.measureTime {
      var combinedSize = 0
      for message in messages {
        let messageData = try jsonSerializer.serialize(message)
        combinedSize += messageData.count
      }
      return combinedSize
    }

    return (allJsonData, serializeTime)
  }

  private static func benchmarkBinarySerialization(messageCount: Int) throws -> (Int, TimeInterval) {
    let binarySerializer = BinarySerializer()

    // Create test messages
    var messages: [DynamicMessage] = []
    for i in 0..<messageCount {
      var (message, _) = try createPersonMessage()
      try message.set("Binary User \(i)", forField: "name")
      try message.set(Int32(20 + i), forField: "age")
      try message.set("binaryuser\(i)@test.com", forField: "email")
      try message.set(["hobby\(i)", "hobby\(i+1)"], forField: "hobbies")
      messages.append(message)
    }

    // Benchmark Binary serialization
    let (allBinaryData, serializeTime) = try ExampleUtils.measureTime {
      var combinedSize = 0
      for message in messages {
        let messageData = try binarySerializer.serialize(message)
        combinedSize += messageData.count
      }
      return combinedSize
    }

    return (allBinaryData, serializeTime)
  }

  private static func verifyCrossFormatEquality(
    original: DynamicMessage,
    jsonPath: DynamicMessage,
    binaryPath: DynamicMessage
  ) throws -> Bool {
    let fields = ["name", "age", "email", "hobbies"]
    
    for fieldName in fields {
      let originalValue = try original.get(forField: fieldName)
      let jsonValue = try jsonPath.get(forField: fieldName)
      let binaryValue = try binaryPath.get(forField: fieldName)
      
      if !areJsonValuesEqual(originalValue, jsonValue) || !areJsonValuesEqual(originalValue, binaryValue) {
        return false
      }
    }
    
    return true
  }
}
