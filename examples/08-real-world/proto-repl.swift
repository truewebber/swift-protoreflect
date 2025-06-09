/**
 * 🖥️ SwiftProtoReflect Example: Interactive Protocol Buffers REPL
 *
 * Описание: Production-ready интерактивная REPL для исследования Protocol Buffers сообщений
 * Ключевые концепции: Interactive Shell, Command Processing, Dynamic Schema Exploration, Real-time Validation
 * Сложность: 🏢 Expert
 * Время выполнения: Интерактивный режим
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct ProtoREPLExample {
  static func main() throws {
    ExampleUtils.printHeader("Interactive Protocol Buffers REPL")

    print("🚀 Starting Interactive Protocol Buffers REPL...")
    print("   Type 'help' for available commands")
    print("   Type 'exit' to quit")
    print()

    let repl = ProtoREPL()
    try repl.run()
  }
}

// MARK: - REPL Implementation

class ProtoREPL {
  private var context: REPLContext
  private var running = true
  private var commandHistory: [String] = []

  init() {
    self.context = REPLContext()
    setupBuiltinSchemas()
  }

  func run() throws {
    print("🔧 ProtoREPL v1.0 - Interactive Protocol Buffers Explorer")
    printWelcomeMessage()

    while running {
      print("\n\u{001B}[36mproto>\u{001B}[0m ", terminator: "")

      guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
        !input.isEmpty
      else {
        continue
      }

      commandHistory.append(input)

      do {
        try processCommand(input)
      }
      catch {
        print("❌ Error: \(error.localizedDescription)")
      }
    }

    print("\n👋 Thanks for using ProtoREPL!")
  }

  private func processCommand(_ input: String) throws {
    let components = input.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
    guard let command = components.first else { return }

    let args = components.count > 1 ? String(components[1]) : ""

    switch command.lowercased() {
    case "help", "h":
      showHelp()
    case "exit", "quit", "q":
      running = false
    case "schemas", "ls":
      listSchemas()
    case "create", "new":
      try createMessage(args)
    case "set":
      try setField(args)
    case "get":
      try getField(args)
    case "show", "print":
      showCurrentMessage()
    case "validate":
      try validateCurrentMessage()
    case "serialize":
      try serializeMessage(format: args.isEmpty ? "binary" : args)
    case "load":
      try loadSchema(args)
    case "clear":
      clearContext()
    case "history":
      showHistory()
    case "inspect":
      try inspectSchema(args)
    case "search":
      try searchFields(args)
    case "demo":
      try runDemo()
    case "benchmark":
      try runBenchmark()
    default:
      print("❓ Unknown command: \(command). Type 'help' for available commands.")
    }
  }

  // MARK: - Command Implementations

  private func showHelp() {
    print(
      """
      📖 Available Commands:

      🔍 Schema Management:
        schemas, ls              - List available schemas
        inspect <schema>         - Inspect schema details
        load <name>             - Load custom schema

      📝 Message Operations:
        create <schema>         - Create new message
        set <field> <value>     - Set field value
        get <field>            - Get field value
        show, print            - Display current message
        search <pattern>       - Search fields by pattern

      ✅ Validation & Serialization:
        validate               - Validate current message
        serialize [format]     - Serialize (binary/json)

      🛠 Utilities:
        clear                  - Clear current context
        history               - Show command history
        demo                  - Run interactive demo
        benchmark             - Performance benchmarks
        help, h               - Show this help
        exit, quit, q         - Exit REPL

      💡 Examples:
        > create User
        > set name "John Doe"
        > set email "john@example.com" 
        > show
        > validate
        > serialize json
      """
    )
  }

  private func listSchemas() {
    let schemas = context.getAvailableSchemas()
    print("📋 Available Schemas (\(schemas.count)):")

    for (index, schema) in schemas.enumerated() {
      let fieldCount = schema.fields.count
      let indicator = context.currentSchema?.name == schema.name ? "👉" : "  "
      print("\(indicator) \(index + 1). \(schema.name) (\(fieldCount) fields)")
    }

    if schemas.isEmpty {
      print("   No schemas loaded. Use 'load <name>' to load a schema.")
    }
  }

  private func createMessage(_ schemaName: String) throws {
    guard !schemaName.isEmpty else {
      print("Usage: create <schema_name>")
      return
    }

    guard let schema = context.findSchema(schemaName) else {
      print("❌ Schema '\(schemaName)' not found. Use 'schemas' to list available schemas.")
      return
    }

    let factory = MessageFactory()
    let message = factory.createMessage(from: schema)

    context.setCurrentMessage(message, schema: schema)
    print("✅ Created new '\(schemaName)' message")
    print("💡 Use 'set <field> <value>' to populate fields")
  }

  private func setField(_ args: String) throws {
    guard let (field, value) = parseFieldValue(args) else {
      print("Usage: set <field> <value>")
      return
    }

    guard var message = context.currentMessage else {
      print("❌ No current message. Use 'create <schema>' first.")
      return
    }

    // Parse value based on field type
    let parsedValue = try parseValueForField(field, value: value, schema: context.currentSchema!)

    try message.set(parsedValue, forField: field)
    context.currentMessage = message

    print("✅ Set \(field) = \(value)")
  }

  private func getField(_ fieldName: String) throws {
    guard !fieldName.isEmpty else {
      print("Usage: get <field>")
      return
    }

    guard let message = context.currentMessage else {
      print("❌ No current message. Use 'create <schema>' first.")
      return
    }

    if try message.hasValue(forField: fieldName) {
      let value = try message.get(forField: fieldName)
      print("📄 \(fieldName): \(formatValue(value))")
    }
    else {
      print("📄 \(fieldName): <not set>")
    }
  }

  private func showCurrentMessage() {
    guard let message = context.currentMessage,
      let schema = context.currentSchema
    else {
      print("❌ No current message. Use 'create <schema>' first.")
      return
    }

    print("📋 Current Message (\(schema.name)):")
    printMessageDetails(message)

    // Show field statistics
    let totalFields = schema.fields.count
    let setFields = schema.fields.values.filter { field in
      do {
        return try message.hasValue(forField: field.name)
      }
      catch {
        return false
      }
    }.count

    print("📊 Progress: \(setFields)/\(totalFields) fields set (\(setFields * 100 / totalFields)%)")
  }

  private func validateCurrentMessage() throws {
    guard let message = context.currentMessage,
      let schema = context.currentSchema
    else {
      print("❌ No current message to validate.")
      return
    }

    let validator = MessageValidator()
    let result = validator.validate(message, schema: schema)

    if result.isValid {
      print("✅ Message is valid!")
    }
    else {
      print("❌ Validation failed:")
      for error in result.errors {
        print("  • \(error)")
      }
    }

    if !result.warnings.isEmpty {
      print("⚠️  Warnings:")
      for warning in result.warnings {
        print("  • \(warning)")
      }
    }
  }

  private func serializeMessage(format: String) throws {
    guard let message = context.currentMessage else {
      print("❌ No current message to serialize.")
      return
    }

    switch format.lowercased() {
    case "binary", "bin":
      let serializer = BinarySerializer()
      let data = try serializer.serialize(message)
      print("📦 Binary (\(data.count) bytes): \(formatDataPreview(data))")

    case "json":
      let serializer = JSONSerializer()
      let jsonData = try serializer.serialize(message)
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("📄 JSON (\(jsonData.count) bytes):")
        print(jsonString)
      }

    default:
      print("❓ Unknown format '\(format)'. Use 'binary' or 'json'.")
    }
  }

  private func loadSchema(_ name: String) throws {
    // Simulate loading custom schema
    print("🔄 Loading schema '\(name)'...")

    switch name.lowercased() {
    case "product":
      let schema = createProductSchema()
      context.addSchema(schema)
      print("✅ Loaded Product schema")
    case "order":
      let schema = createOrderSchema()
      context.addSchema(schema)
      print("✅ Loaded Order schema")
    default:
      print("❓ Unknown schema '\(name)'. Available: product, order")
    }
  }

  private func clearContext() {
    context.clear()
    print("🧹 Context cleared")
  }

  private func showHistory() {
    print("📜 Command History:")
    for (index, command) in commandHistory.enumerated() {
      print("  \(index + 1). \(command)")
    }
  }

  private func inspectSchema(_ name: String) throws {
    guard !name.isEmpty else {
      print("Usage: inspect <schema_name>")
      return
    }

    guard let schema = context.findSchema(name) else {
      print("❌ Schema '\(name)' not found.")
      return
    }

    print("🔍 Schema: \(schema.name)")
    print("🏷  Fields (\(schema.fields.count)):")

    for field in schema.fields.values.sorted(by: { $0.number < $1.number }) {
      let optional = field.isRepeated ? " (repeated)" : ""
      print("  \(field.number). \(field.name): \(field.type)\(optional)")
    }
  }

  private func searchFields(_ pattern: String) throws {
    guard !pattern.isEmpty else {
      print("Usage: search <pattern>")
      return
    }

    let schemas = context.getAvailableSchemas()
    var foundFields: [(schema: String, field: String, type: FieldType)] = []

    for schema in schemas {
      for field in schema.fields.values where field.name.localizedCaseInsensitiveContains(pattern) {
        foundFields.append((schema.name, field.name, field.type))
      }
    }

    if foundFields.isEmpty {
      print("🔍 No fields matching '\(pattern)' found.")
    }
    else {
      print("🔍 Found \(foundFields.count) fields matching '\(pattern)':")
      for (schema, field, type) in foundFields {
        print("  \(schema).\(field): \(type)")
      }
    }
  }

  private func runDemo() throws {
    print("🎬 Running interactive demo...")

    // Create a user message step by step
    try processCommand("create User")
    Thread.sleep(forTimeInterval: 1)

    try processCommand("set name \"Demo User\"")
    Thread.sleep(forTimeInterval: 1)

    try processCommand("set email \"demo@example.com\"")
    Thread.sleep(forTimeInterval: 1)

    try processCommand("set age 25")
    Thread.sleep(forTimeInterval: 1)

    try processCommand("show")
    Thread.sleep(forTimeInterval: 1)

    try processCommand("validate")
    Thread.sleep(forTimeInterval: 1)

    try processCommand("serialize json")

    print("🎉 Demo completed!")
  }

  private func runBenchmark() throws {
    print("⚡ Running performance benchmarks...")

    // Create test message
    try processCommand("create User")

    // Field setting benchmark
    let (_, fieldSetTime) = try ExampleUtils.measureTime {
      for i in 0..<1000 {
        try context.currentMessage?.set("User\(i)", forField: "name")
      }
    }

    // Serialization benchmark
    let (_, serializationTime) = try ExampleUtils.measureTime {
      let serializer = BinarySerializer()
      for _ in 0..<1000 {
        _ = try serializer.serialize(context.currentMessage!)
      }
    }

    print("📊 Benchmark Results:")
    print("  Field operations: \(String(format: "%.1f", 1000 / fieldSetTime)) ops/sec")
    print("  Serialization: \(String(format: "%.1f", 1000 / serializationTime)) ops/sec")
  }

  // MARK: - Helper Methods

  private func setupBuiltinSchemas() {
    context.addSchema(createUserSchema())
    context.addSchema(createCompanySchema())
  }

  private func printWelcomeMessage() {
    print(
      """

      📖 Welcome to ProtoREPL! Here's what you can do:

      1️⃣  List schemas: 'schemas'
      2️⃣  Create message: 'create User'
      3️⃣  Set fields: 'set name "John"'
      4️⃣  View message: 'show'
      5️⃣  Validate: 'validate'
      6️⃣  Serialize: 'serialize json'

      💡 Type 'demo' for an interactive demonstration
      🆘 Type 'help' for all available commands
      """
    )
  }

  private func parseFieldValue(_ args: String) -> (field: String, value: String)? {
    let components = args.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
    guard components.count == 2 else { return nil }

    let field = String(components[0])
    var value = String(components[1])

    // Remove quotes if present
    if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
      value = String(value.dropFirst().dropLast())
    }

    return (field, value)
  }

  private func parseValueForField(_ fieldName: String, value: String, schema: MessageDescriptor) throws -> Any {
    guard let field = schema.fields.values.first(where: { $0.name == fieldName }) else {
      throw REPLError.unknownField(fieldName)
    }

    switch field.type {
    case .string:
      return value
    case .int32:
      guard let intValue = Int32(value) else {
        throw REPLError.invalidValue("Expected integer for field \(fieldName)")
      }
      return intValue
    case .int64:
      guard let longValue = Int64(value) else {
        throw REPLError.invalidValue("Expected long integer for field \(fieldName)")
      }
      return longValue
    case .bool:
      return ["true", "yes", "1"].contains(value.lowercased())
    case .double:
      guard let doubleValue = Double(value) else {
        throw REPLError.invalidValue("Expected decimal number for field \(fieldName)")
      }
      return doubleValue
    case .float:
      guard let floatValue = Float(value) else {
        throw REPLError.invalidValue("Expected float number for field \(fieldName)")
      }
      return floatValue
    default:
      return value
    }
  }

  private func formatValue(_ value: Any?) -> String {
    guard let value = value else { return "nil" }

    switch value {
    case let string as String:
      return "\"\(string)\""
    case let data as Data:
      return "Data(\(data.count) bytes)"
    case let array as [Any]:
      return "[\(array.count) items]"
    default:
      return "\(value)"
    }
  }
}

// MARK: - REPL Context

class REPLContext {
  private var schemas: [MessageDescriptor] = []
  var currentMessage: DynamicMessage?
  var currentSchema: MessageDescriptor?

  func addSchema(_ schema: MessageDescriptor) {
    schemas.append(schema)
  }

  func getAvailableSchemas() -> [MessageDescriptor] {
    return schemas
  }

  func findSchema(_ name: String) -> MessageDescriptor? {
    return schemas.first { $0.name == name }
  }

  func setCurrentMessage(_ message: DynamicMessage, schema: MessageDescriptor) {
    currentMessage = message
    currentSchema = schema
  }

  func clear() {
    currentMessage = nil
    currentSchema = nil
  }
}

// MARK: - Validation

struct MessageValidator {
  func validate(_ message: DynamicMessage, schema: MessageDescriptor) -> ValidationResult {
    var errors: [String] = []
    var warnings: [String] = []

    // Basic validation
    for field in schema.fields.values {
      do {
        if try message.hasValue(forField: field.name) {
          let value = try message.get(forField: field.name)

          // Type-specific validation
          switch field.type {
          case .string:
            if let str = value as? String, str.isEmpty {
              warnings.append("Field '\(field.name)' is empty")
            }
          case .int32:
            if let num = value as? Int32, num < 0 {
              warnings.append("Field '\(field.name)' has negative value")
            }
          default:
            break
          }
        }
      }
      catch {
        errors.append("Error validating field '\(field.name)': \(error)")
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors, warnings: warnings)
  }

  struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
  }
}

// MARK: - Errors

enum REPLError: Error, LocalizedError {
  case unknownField(String)
  case invalidValue(String)
  case schemaNotFound(String)

  var errorDescription: String? {
    switch self {
    case .unknownField(let field):
      return "Unknown field: \(field)"
    case .invalidValue(let message):
      return "Invalid value: \(message)"
    case .schemaNotFound(let schema):
      return "Schema not found: \(schema)"
    }
  }
}

// MARK: - Schema Definitions

private func createUserSchema() -> MessageDescriptor {
  var fileDescriptor = FileDescriptor(name: "user.proto", package: "example")
  var userMessage = MessageDescriptor(name: "User", parent: fileDescriptor)

  userMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
  userMessage.addField(FieldDescriptor(name: "email", number: 2, type: .string))
  userMessage.addField(FieldDescriptor(name: "age", number: 3, type: .int32))
  userMessage.addField(FieldDescriptor(name: "active", number: 4, type: .bool))
  userMessage.addField(FieldDescriptor(name: "score", number: 5, type: .double))

  fileDescriptor.addMessage(userMessage)
  return userMessage
}

private func createCompanySchema() -> MessageDescriptor {
  var fileDescriptor = FileDescriptor(name: "company.proto", package: "example")
  var companyMessage = MessageDescriptor(name: "Company", parent: fileDescriptor)

  companyMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
  companyMessage.addField(FieldDescriptor(name: "employee_count", number: 2, type: .int32))
  companyMessage.addField(FieldDescriptor(name: "revenue", number: 3, type: .double))
  companyMessage.addField(FieldDescriptor(name: "public", number: 4, type: .bool))

  fileDescriptor.addMessage(companyMessage)
  return companyMessage
}

private func createProductSchema() -> MessageDescriptor {
  var fileDescriptor = FileDescriptor(name: "product.proto", package: "example")
  var productMessage = MessageDescriptor(name: "Product", parent: fileDescriptor)

  productMessage.addField(FieldDescriptor(name: "id", number: 1, type: .string))
  productMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
  productMessage.addField(FieldDescriptor(name: "price", number: 3, type: .double))
  productMessage.addField(FieldDescriptor(name: "in_stock", number: 4, type: .bool))
  productMessage.addField(FieldDescriptor(name: "quantity", number: 5, type: .int32))

  fileDescriptor.addMessage(productMessage)
  return productMessage
}

private func createOrderSchema() -> MessageDescriptor {
  var fileDescriptor = FileDescriptor(name: "order.proto", package: "example")
  var orderMessage = MessageDescriptor(name: "Order", parent: fileDescriptor)

  orderMessage.addField(FieldDescriptor(name: "order_id", number: 1, type: .string))
  orderMessage.addField(FieldDescriptor(name: "customer_name", number: 2, type: .string))
  orderMessage.addField(FieldDescriptor(name: "total_amount", number: 3, type: .double))
  orderMessage.addField(FieldDescriptor(name: "item_count", number: 4, type: .int32))
  orderMessage.addField(FieldDescriptor(name: "shipped", number: 5, type: .bool))

  fileDescriptor.addMessage(orderMessage)
  return orderMessage
}

// MARK: - Helper Functions

private func printMessageDetails(_ message: DynamicMessage) {
  let schema = message.descriptor
  print("    Message: \(schema.name)")
  for field in schema.fields.values.sorted(by: { $0.number < $1.number }) {
    do {
      if try message.hasValue(forField: field.name) {
        let value = try message.get(forField: field.name)
        print("      \(field.name): \(value ?? "nil")")
      }
      else {
        print("      \(field.name): <not set>")
      }
    }
    catch {
      print("      \(field.name): <error reading value>")
    }
  }
}

private func formatDataPreview(_ data: Data) -> String {
  let maxBytes = 8
  let bytes = data.prefix(maxBytes)
  let hexString = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
  let suffix = data.count > maxBytes ? "..." : ""
  return "0x\(hexString)\(suffix)"
}
