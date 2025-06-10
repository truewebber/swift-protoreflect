/**
 * 🎯 SwiftProtoReflect Example: Field Types Demo
 *
 * Description: Demonstration of all Protocol Buffers scalar field types
 * Key concepts: FieldType, scalar types, repeated fields, map fields
 * Complexity: 🔰 Beginner
 * Execution time: < 10 seconds
 *
 * What you'll learn:
 * - All Protocol Buffers scalar types
 * - Repeated fields (arrays)
 * - Map fields (key-value)
 * - Enum fields
 * - Field type validation
 *
 * Run:
 *   swift run FieldTypes
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct FieldTypesExample {
  static func main() throws {
    ExampleUtils.printHeader("Protocol Buffers Field Types - All field types")

    try step1UscalarTypes()
    try step2UrepeatedFields()
    try step3UmapFields()
    try step4UenumFields()
    try step5UvalidationDemo()

    ExampleUtils.printSuccess("You learned all basic Protocol Buffers field types!")

    ExampleUtils.printNext([
      "Next: simple-message.swift - creating more complex messages",
      "Also explore: basic-descriptors.swift - working with metadata",
      "Advanced: nested-messages.swift - nested messages",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1UscalarTypes() throws {
    ExampleUtils.printStep(1, "Protocol Buffers scalar types")

    let (messageDescriptor, _) = try createAllTypesMessage()
    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    // Set values for all scalar types
    try message.set(42.5, forField: "double_field")  // double
    try message.set(Float(3.14), forField: "float_field")  // float
    try message.set(Int32(100), forField: "int32_field")  // int32
    try message.set(Int64(1000), forField: "int64_field")  // int64
    try message.set(UInt32(200), forField: "uint32_field")  // uint32
    try message.set(UInt64(2000), forField: "uint64_field")  // uint64
    try message.set(Int32(-50), forField: "sint32_field")  // sint32 (ZigZag)
    try message.set(Int64(-500), forField: "sint64_field")  // sint64 (ZigZag)
    try message.set(UInt32(300), forField: "fixed32_field")  // fixed32
    try message.set(UInt64(3000), forField: "fixed64_field")  // fixed64
    try message.set(Int32(-75), forField: "sfixed32_field")  // sfixed32
    try message.set(Int64(-750), forField: "sfixed64_field")  // sfixed64
    try message.set(true, forField: "bool_field")  // bool
    try message.set("Hello Protocol Buffers!", forField: "string_field")  // string
    try message.set(Data("Binary data".utf8), forField: "bytes_field")  // bytes

    print("  ✅ All scalar values set")

    // Read and check values - split complex expression for compiler
    let scalarData: [String: Any] = [
      "double": try message.get(forField: "double_field") as? Double ?? 0,
      "float": try message.get(forField: "float_field") as? Float ?? 0,
      "int32": try message.get(forField: "int32_field") as? Int32 ?? 0,
      "int64": try message.get(forField: "int64_field") as? Int64 ?? 0,
      "uint32": try message.get(forField: "uint32_field") as? UInt32 ?? 0,
      "uint64": try message.get(forField: "uint64_field") as? UInt64 ?? 0,
    ]

    let moreScalarData: [String: Any] = [
      "sint32": try message.get(forField: "sint32_field") as? Int32 ?? 0,
      "sint64": try message.get(forField: "sint64_field") as? Int64 ?? 0,
      "bool": try message.get(forField: "bool_field") as? Bool ?? false,
      "string": try message.get(forField: "string_field") as? String ?? "",
    ]

    // Combine data and show table
    var allScalarData = scalarData
    for (key, value) in moreScalarData {
      allScalarData[key] = value
    }

    ExampleUtils.printTable(allScalarData, title: "Scalar values")

    if let bytesData = try message.get(forField: "bytes_field") as? Data {
      let bytesString = String(data: bytesData, encoding: .utf8) ?? "binary"
      print("  📦 bytes_field: \(bytesString) (\(bytesData.count) bytes)")
    }
  }

  private static func step2UrepeatedFields() throws {
    ExampleUtils.printStep(2, "Repeated fields (arrays)")

    let (messageDescriptor, _) = try createRepeatedFieldsMessage()
    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    // Set repeated fields
    try message.set([Int32(1), Int32(2), Int32(3), Int32(4), Int32(5)], forField: "repeated_int32")
    try message.set(["apple", "banana", "cherry", "date"], forField: "repeated_string")
    try message.set([true, false, true, false], forField: "repeated_bool")
    try message.set([1.1, 2.2, 3.3], forField: "repeated_double")

    print("  ✅ Repeated fields set")

    // Read repeated fields
    if let numbers = try message.get(forField: "repeated_int32") as? [Int32] {
      print("  🔢 repeated_int32: \(numbers)")
    }

    if let strings = try message.get(forField: "repeated_string") as? [String] {
      print("  📝 repeated_string: \(strings)")
    }

    if let bools = try message.get(forField: "repeated_bool") as? [Bool] {
      print("  ☑️  repeated_bool: \(bools)")
    }

    if let doubles = try message.get(forField: "repeated_double") as? [Double] {
      print("  🔀 repeated_double: \(doubles)")
    }

    let totalElements = (try? message.get(forField: "repeated_int32") as? [Int32])?.count ?? 0
    print("  📊 Total elements in repeated_int32: \(totalElements)")
  }

  private static func step3UmapFields() throws {
    ExampleUtils.printStep(3, "Map fields (key-value) - simplified demonstration")

    let (messageDescriptor, _) = try createMapFieldsMessage()
    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    // Since Map fields require complex setup in Protocol Buffers,
    // show concept through regular fields
    try message.set("key1=value1,key2=value2,key3=value3", forField: "map_string_int32")
    try message.set("10=ten,20=twenty,30=thirty", forField: "map_int32_string")
    try message.set("enabled=true,disabled=false", forField: "map_string_bool")

    print("  ✅ Map-like data set (as strings for demonstration)")

    // Read map-like fields
    if let stringIntMap = try message.get(forField: "map_string_int32") as? String {
      print("  🗝  map_string_int32: \(stringIntMap)")
    }

    if let intStringMap = try message.get(forField: "map_int32_string") as? String {
      print("  🔑 map_int32_string: \(intStringMap)")
    }

    if let stringBoolMap = try message.get(forField: "map_string_bool") as? String {
      print("  ✅ map_string_bool: \(stringBoolMap)")
    }

    ExampleUtils.printInfo("Note: Real Map fields require special descriptor configuration")
  }

  private static func step4UenumFields() throws {
    ExampleUtils.printStep(4, "Enum fields")

    let (messageDescriptor, fileDescriptor) = try createEnumFieldsMessage()
    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    // Enum in Protocol Buffers is represented as int32
    try message.set(Int32(1), forField: "status")  // ACTIVE = 1
    try message.set(Int32(2), forField: "priority")  // HIGH = 2

    print("  ✅ Enum fields set")

    // Read enum fields
    if let status = try message.get(forField: "status") as? Int32 {
      let statusName = getStatusName(status)
      print("  📊 status: \(status) (\(statusName))")
    }

    if let priority = try message.get(forField: "priority") as? Int32 {
      let priorityName = getPriorityName(priority)
      print("  ⚡ priority: \(priority) (\(priorityName))")
    }

    // Show all available enum values
    if let statusEnum = fileDescriptor.enums.values.first(where: { $0.name == "Status" }) {
      print("  📋 Available Status values:")
      for value in statusEnum.allValues() {
        print("    \(value.name) = \(value.number)")
      }
    }
  }

  private static func step5UvalidationDemo() throws {
    ExampleUtils.printStep(5, "Type validation and error demonstration")

    let (messageDescriptor, _) = try createAllTypesMessage()
    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    print("  🧪 Testing type validation:")

    // Correct types
    do {
      try message.set("Valid string", forField: "string_field")
      print("  ✅ Correct string type: OK")
    }
    catch {
      print("  ❌ Error with correct type: \(error)")
    }

    // Wrong types (will be handled by library)
    do {
      try message.set(123, forField: "string_field")  // int instead of string
      print("  ⚠️  Attempt to set int in string field: accepted (possible auto-conversion)")
    }
    catch {
      print("  ✅ Correctly rejected wrong type: \(error)")
    }

    // Non-existent field
    do {
      try message.set("test", forField: "nonexistent_field")
      print("  ❌ Unexpectedly accepted non-existent field")
    }
    catch {
      print("  ✅ Correctly rejected non-existent field")
    }

    // Check field types
    print("\n  📋 Field type information:")
    let fieldsToShow = Array(messageDescriptor.fields.values.prefix(5))
    for field in fieldsToShow {
      print("    \(field.name): \(field.type)")
    }
  }

  // MARK: - Helper Methods

  private static func createAllTypesMessage() throws -> (MessageDescriptor, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "types.proto", package: "example")
    var messageDescriptor = MessageDescriptor(name: "AllTypes", parent: fileDescriptor)

    // Add all scalar types
    messageDescriptor.addField(FieldDescriptor(name: "double_field", number: 1, type: .double))
    messageDescriptor.addField(FieldDescriptor(name: "float_field", number: 2, type: .float))
    messageDescriptor.addField(FieldDescriptor(name: "int32_field", number: 3, type: .int32))
    messageDescriptor.addField(FieldDescriptor(name: "int64_field", number: 4, type: .int64))
    messageDescriptor.addField(FieldDescriptor(name: "uint32_field", number: 5, type: .uint32))
    messageDescriptor.addField(FieldDescriptor(name: "uint64_field", number: 6, type: .uint64))
    messageDescriptor.addField(FieldDescriptor(name: "sint32_field", number: 7, type: .sint32))
    messageDescriptor.addField(FieldDescriptor(name: "sint64_field", number: 8, type: .sint64))
    messageDescriptor.addField(FieldDescriptor(name: "fixed32_field", number: 9, type: .fixed32))
    messageDescriptor.addField(FieldDescriptor(name: "fixed64_field", number: 10, type: .fixed64))
    messageDescriptor.addField(FieldDescriptor(name: "sfixed32_field", number: 11, type: .sfixed32))
    messageDescriptor.addField(FieldDescriptor(name: "sfixed64_field", number: 12, type: .sfixed64))
    messageDescriptor.addField(FieldDescriptor(name: "bool_field", number: 13, type: .bool))
    messageDescriptor.addField(FieldDescriptor(name: "string_field", number: 14, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "bytes_field", number: 15, type: .bytes))

    fileDescriptor.addMessage(messageDescriptor)
    return (messageDescriptor, fileDescriptor)
  }

  private static func createRepeatedFieldsMessage() throws -> (MessageDescriptor, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "repeated.proto", package: "example")
    var messageDescriptor = MessageDescriptor(name: "RepeatedTypes", parent: fileDescriptor)

    messageDescriptor.addField(FieldDescriptor(name: "repeated_int32", number: 1, type: .int32, isRepeated: true))
    messageDescriptor.addField(FieldDescriptor(name: "repeated_string", number: 2, type: .string, isRepeated: true))
    messageDescriptor.addField(FieldDescriptor(name: "repeated_bool", number: 3, type: .bool, isRepeated: true))
    messageDescriptor.addField(FieldDescriptor(name: "repeated_double", number: 4, type: .double, isRepeated: true))

    fileDescriptor.addMessage(messageDescriptor)
    return (messageDescriptor, fileDescriptor)
  }

  private static func createMapFieldsMessage() throws -> (MessageDescriptor, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "maps.proto", package: "example")
    var messageDescriptor = MessageDescriptor(name: "MapTypes", parent: fileDescriptor)

    // Simplified demonstration of map concept through regular string fields
    messageDescriptor.addField(FieldDescriptor(name: "map_string_int32", number: 1, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "map_int32_string", number: 2, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "map_string_bool", number: 3, type: .string))

    fileDescriptor.addMessage(messageDescriptor)
    return (messageDescriptor, fileDescriptor)
  }

  private static func createEnumFieldsMessage() throws -> (MessageDescriptor, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "enums.proto", package: "example")

    // Create Status enum
    var statusEnum = EnumDescriptor(name: "Status", parent: fileDescriptor)
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "INACTIVE", number: 2))

    // Create Priority enum
    var priorityEnum = EnumDescriptor(name: "Priority", parent: fileDescriptor)
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "LOW", number: 0))
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "MEDIUM", number: 1))
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "HIGH", number: 2))

    fileDescriptor.addEnum(statusEnum)
    fileDescriptor.addEnum(priorityEnum)

    // Create message with enum fields
    var messageDescriptor = MessageDescriptor(name: "EnumMessage", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "status", number: 1, type: .int32))  // enum as int32
    messageDescriptor.addField(FieldDescriptor(name: "priority", number: 2, type: .int32))  // enum as int32

    fileDescriptor.addMessage(messageDescriptor)
    return (messageDescriptor, fileDescriptor)
  }

  private static func getStatusName(_ value: Int32) -> String {
    switch value {
    case 0: return "UNKNOWN"
    case 1: return "ACTIVE"
    case 2: return "INACTIVE"
    default: return "INVALID"
    }
  }

  private static func getPriorityName(_ value: Int32) -> String {
    switch value {
    case 0: return "LOW"
    case 1: return "MEDIUM"
    case 2: return "HIGH"
    default: return "INVALID"
    }
  }
}
