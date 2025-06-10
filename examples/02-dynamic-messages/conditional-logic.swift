/**
 * 🎯 SwiftProtoReflect Example: Conditional Logic Based on Types
 *
 * Description: Conditional logic based on types in dynamic messages
 * Key concepts: Type-based decisions, Runtime type checking, Dynamic dispatch, Conditional processing
 * Complexity: 🔧🔧 Advanced
 * Execution time: < 15 seconds
 *
 * What you'll learn:
 * - Conditional logic based on field and message types
 * - Runtime type checking and dynamic dispatch patterns
 * - Polymorphic processing of different message types
 * - Conditional field processing with type-specific logic
 * - Pattern matching for Protocol Buffers types
 * - Advanced type introspection techniques
 *
 * Usage:
 *   swift run ConditionalLogic
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct ConditionalLogicExample {
  static func main() throws {
    ExampleUtils.printHeader("Conditional Logic Based on Types")

    try step1_typeBasedDecisions()
    try step2_polymorphicProcessing()
    try step3_conditionalFieldProcessing()
    try step4_dynamicDispatch()
    try step5_patternMatching()
    try step6_advancedTypeIntrospection()

    ExampleUtils.printSuccess("You've mastered conditional logic based on types!")

    ExampleUtils.printNext([
      "Next: performance-optimization.swift - performance optimization",
      "Almost done: This is almost the last example in category 02-dynamic-messages!",
      "Continue: ../03-serialization/ - serialization and data formats",
    ])
  }

  private static func step1_typeBasedDecisions() throws {
    ExampleUtils.printStep(1, "Type-based decisions and conditional processing")

    let fileDescriptor = createMixedContentStructure()
    let factory = MessageFactory()

    // Create different types of content
    let mediaItems = try createMixedMediaItems(factory: factory, fileDescriptor: fileDescriptor)

    print("  📱 Created various types of media content:")
    for (index, item) in mediaItems.enumerated() {
      print("    \(index + 1). \(try getContentType(item))")
    }

    print("\n  🎯 Applying type-based logic:")

    for (index, item) in mediaItems.enumerated() {
      print("\n    📋 Item \(index + 1):")
      try processContentBasedOnType(item)
    }

    // Statistics by types
    print("\n  📊 Processing statistics by types:")
    let stats = try analyzeContentTypes(mediaItems)
    ExampleUtils.printTable(stats, title: "Content Type Statistics")
  }

  private static func step2_polymorphicProcessing() throws {
    ExampleUtils.printStep(2, "Polymorphic processing of different messages")

    let fileDescriptor = createShapeHierarchy()
    let factory = MessageFactory()

    // Create various geometric shapes
    let shapes = try createVariousShapes(factory: factory, fileDescriptor: fileDescriptor)

    print("  🔺 Created various geometric shapes:")
    for shape in shapes {
      let shapeType = try determineShapeType(shape)
      print("    • \(shapeType)")
    }

    print("\n  📐 Polymorphic processing of shapes:")

    for shape in shapes {
      print("\n    🔍 Shape analysis:")
      try processShapePolymorphically(shape)
    }

    // Common calculations for all shapes
    print("\n  🧮 Common calculations:")
    let totalArea = try calculateTotalArea(shapes)
    let avgPerimeter = try calculateAveragePerimeter(shapes)

    ExampleUtils.printTable(
      [
        "Total Area": String(format: "%.2f", totalArea),
        "Average Perimeter": String(format: "%.2f", avgPerimeter),
        "Shape Count": "\(shapes.count)",
      ],
      title: "Geometric Analysis"
    )
  }

  private static func step3_conditionalFieldProcessing() throws {
    ExampleUtils.printStep(3, "Conditional field processing с type-specific logic")

    let fileDescriptor = createUserDataStructure()
    let factory = MessageFactory()

    // Создание пользовательских данных с различными типами полей
    let userData = try createUserDataSamples(factory: factory, fileDescriptor: fileDescriptor)

    print("  👤 Созданы образцы пользовательских данных:")
    for (index, user) in userData.enumerated() {
      print("    User \(index + 1): \(try getUserSummary(user))")
    }

    print("\n  🔍 Условная обработка полей по типам:")

    for (index, user) in userData.enumerated() {
      print("\n    👤 User \(index + 1) field processing:")
      try processUserFieldsConditionally(user)
    }

    // Применение type-specific validations
    print("\n  ✅ Type-specific validations:")
    let validationResults = try validateUserDataByTypes(userData)

    ExampleUtils.printTable(
      [
        "Valid Users": "\(validationResults.validCount)",
        "Invalid Users": "\(validationResults.invalidCount)",
        "Warning Users": "\(validationResults.warningCount)",
        "Success Rate": String(format: "%.1f%%", validationResults.successRate),
      ],
      title: "Validation Results"
    )
  }

  private static func step4_dynamicDispatch() throws {
    ExampleUtils.printStep(4, "Dynamic dispatch patterns для типов")

    let fileDescriptor = createEventSystemStructure()
    let factory = MessageFactory()

    // Создание различных типов событий
    let events = try createVariousEvents(factory: factory, fileDescriptor: fileDescriptor)

    print("  📅 Созданы различные типы событий:")
    for (index, event) in events.enumerated() {
      print("    Event \(index + 1): \(try getEventType(event))")
    }

    print("\n  🚀 Dynamic dispatch processing:")

    // Создание dispatcher'а
    let dispatcher = EventDispatcher()

    for (index, event) in events.enumerated() {
      print("\n    📡 Dispatching Event \(index + 1):")
      try dispatcher.dispatch(event)
    }

    // Статистика dispatch'а
    print("\n  📊 Dispatch statistics:")
    let stats = dispatcher.getStatistics()
    ExampleUtils.printTable(stats, title: "Event Dispatch Stats")

    // Демонстрация custom handlers
    print("\n  🔧 Custom handler demonstration:")
    try demonstrateCustomHandlers(dispatcher: dispatcher, events: events)
  }

  private static func step5_patternMatching() throws {
    ExampleUtils.printStep(5, "Pattern matching для Protocol Buffers типов")

    let fileDescriptor = createAPIResponseStructure()
    let factory = MessageFactory()

    // Создание различных API responses
    let responses = try createAPIResponses(factory: factory, fileDescriptor: fileDescriptor)

    print("  🌐 Созданы различные API responses:")
    for (index, response) in responses.enumerated() {
      print("    Response \(index + 1): \(try getResponseType(response))")
    }

    print("\n  🎯 Pattern matching processing:")

    for (index, response) in responses.enumerated() {
      print("\n    📋 Response \(index + 1) pattern analysis:")
      try analyzeResponseWithPatternMatching(response)
    }

    // Демонстрация complex pattern matching
    print("\n  🔧 Complex pattern matching scenarios:")
    try demonstrateComplexPatternMatching(responses)

    // Pattern matching statistics
    print("\n  📊 Pattern matching effectiveness:")
    let patternStats = try analyzePatternMatchingEffectiveness(responses)
    ExampleUtils.printTable(patternStats, title: "Pattern Matching Stats")
  }

  private static func step6_advancedTypeIntrospection() throws {
    ExampleUtils.printStep(6, "Advanced type introspection techniques")

    let fileDescriptor = createAdvancedTypeStructure()
    let factory = MessageFactory()

    // Создание сложных типизированных структур
    let complexStructures = try createComplexTypedStructures(factory: factory, fileDescriptor: fileDescriptor)

    print("  🔬 Созданы сложные типизированные структуры:")
    for (index, structure) in complexStructures.enumerated() {
      print("    Structure \(index + 1): \(try getStructureSignature(structure))")
    }

    print("\n  🔍 Deep type introspection:")

    for (index, structure) in complexStructures.enumerated() {
      print("\n    🧬 Structure \(index + 1) deep analysis:")
      try performDeepTypeIntrospection(structure)
    }

    // Type compatibility analysis
    print("\n  🔄 Type compatibility analysis:")
    try analyzeTypeCompatibility(complexStructures)

    // Runtime type evolution
    print("\n  📈 Runtime type evolution demonstration:")
    try demonstrateRuntimeTypeEvolution(complexStructures.first!)

    // Final introspection summary
    print("\n  📋 Advanced introspection summary:")
    let introspectionSummary = try generateIntrospectionSummary(complexStructures)
    ExampleUtils.printTable(introspectionSummary, title: "Type Introspection Summary")
  }
}

// MARK: - Helper Methods

extension ConditionalLogicExample {

  // MARK: - Step 1: Mixed Content Structure

  static func createMixedContentStructure() -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "mixed_content.proto", package: "example")

    // Media Content Message
    var mediaContentDesc = MessageDescriptor(name: "MediaContent", parent: fileDescriptor)
    mediaContentDesc.addField(FieldDescriptor(name: "content_type", number: 1, type: .string))
    mediaContentDesc.addField(FieldDescriptor(name: "title", number: 2, type: .string))
    mediaContentDesc.addField(FieldDescriptor(name: "url", number: 3, type: .string))
    mediaContentDesc.addField(FieldDescriptor(name: "size", number: 4, type: .int64))
    mediaContentDesc.addField(FieldDescriptor(name: "duration", number: 5, type: .int32))
    mediaContentDesc.addField(FieldDescriptor(name: "tags", number: 6, type: .string, isRepeated: true))

    fileDescriptor.addMessage(mediaContentDesc)
    return fileDescriptor
  }

  static func createMixedMediaItems(factory: MessageFactory, fileDescriptor: FileDescriptor) throws -> [DynamicMessage]
  {
    let mediaDescriptor = fileDescriptor.messages.values.first { $0.name == "MediaContent" }!
    var items: [DynamicMessage] = []

    // Text content
    var textItem = factory.createMessage(from: mediaDescriptor)
    try textItem.set("text", forField: "content_type")
    try textItem.set("Sample Article", forField: "title")
    try textItem.set("https://example.com/article.txt", forField: "url")
    try textItem.set(Int64(1024), forField: "size")
    try textItem.set(Int32(0), forField: "duration")
    try textItem.set(["text", "article"], forField: "tags")
    items.append(textItem)

    // Image content
    var imageItem = factory.createMessage(from: mediaDescriptor)
    try imageItem.set("image", forField: "content_type")
    try imageItem.set("Beautiful Landscape", forField: "title")
    try imageItem.set("https://example.com/image.jpg", forField: "url")
    try imageItem.set(Int64(2_485_760), forField: "size")
    try imageItem.set(Int32(0), forField: "duration")
    try imageItem.set(["image", "landscape"], forField: "tags")
    items.append(imageItem)

    // Video content
    var videoItem = factory.createMessage(from: mediaDescriptor)
    try videoItem.set("video", forField: "content_type")
    try videoItem.set("Tech Demo", forField: "title")
    try videoItem.set("https://example.com/video.mp4", forField: "url")
    try videoItem.set(Int64(104_857_600), forField: "size")
    try videoItem.set(Int32(300), forField: "duration")
    try videoItem.set(["video", "demo"], forField: "tags")
    items.append(videoItem)

    return items
  }

  static func getContentType(_ item: DynamicMessage) throws -> String {
    let contentType: String = try item.get(forField: "content_type") as? String ?? "unknown"
    let title: String = try item.get(forField: "title") as? String ?? "Untitled"
    return "\(contentType.capitalized): \(title)"
  }

  static func processContentBasedOnType(_ item: DynamicMessage) throws {
    let contentType: String = try item.get(forField: "content_type") as? String ?? "unknown"
    let title: String = try item.get(forField: "title") as? String ?? "Untitled"
    let size: Int64 = try item.get(forField: "size") as? Int64 ?? 0
    let duration: Int32 = try item.get(forField: "duration") as? Int32 ?? 0

    switch contentType {
    case "text":
      print("      📝 Text: \(title) (size: \(ExampleUtils.formatDataSize(Int(size))))")
      if size < 1000 {
        print("        💡 Small text file - quick read")
      }
    case "image":
      print("      🖼️ Image: \(title) (size: \(ExampleUtils.formatDataSize(Int(size))))")
      if size > 5_000_000 {
        print("        📐 Large image - consider compression")
      }
    case "video":
      print("      🎬 Video: \(title) (duration: \(duration)s, size: \(ExampleUtils.formatDataSize(Int(size))))")
      if duration > 600 {
        print("        ⏱️ Long video - consider segmentation")
      }
    default:
      print("      ❓ Unknown type: \(contentType)")
    }
  }

  static func analyzeContentTypes(_ items: [DynamicMessage]) throws -> [String: String] {
    var typeStats: [String: Int] = [:]
    var totalSize: Int64 = 0

    for item in items {
      let contentType: String = try item.get(forField: "content_type") as? String ?? "unknown"
      let size: Int64 = try item.get(forField: "size") as? Int64 ?? 0

      typeStats[contentType, default: 0] += 1
      totalSize += size
    }

    var result: [String: String] = [:]
    for (type, count) in typeStats {
      result["\(type.capitalized) Items"] = "\(count)"
    }
    result["Total Size"] = ExampleUtils.formatDataSize(Int(totalSize))
    result["Average Size"] = ExampleUtils.formatDataSize(Int(totalSize / Int64(items.count)))

    return result
  }

  // MARK: - Step 2: Shape Hierarchy

  static func createShapeHierarchy() -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "shapes.proto", package: "geometry")

    var shapeDesc = MessageDescriptor(name: "Shape", parent: fileDescriptor)
    shapeDesc.addField(FieldDescriptor(name: "type", number: 1, type: .string))
    shapeDesc.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    shapeDesc.addField(FieldDescriptor(name: "color", number: 3, type: .string))
    shapeDesc.addField(FieldDescriptor(name: "param1", number: 4, type: .double))  // radius, width, side
    shapeDesc.addField(FieldDescriptor(name: "param2", number: 5, type: .double))  // height for rectangle
    shapeDesc.addField(FieldDescriptor(name: "param3", number: 6, type: .double))  // third parameter if needed

    fileDescriptor.addMessage(shapeDesc)
    return fileDescriptor
  }

  static func createVariousShapes(factory: MessageFactory, fileDescriptor: FileDescriptor) throws -> [DynamicMessage] {
    let shapeDescriptor = fileDescriptor.messages.values.first { $0.name == "Shape" }!
    var shapes: [DynamicMessage] = []

    // Circle
    var circle = factory.createMessage(from: shapeDescriptor)
    try circle.set("circle", forField: "type")
    try circle.set("RedCircle", forField: "name")
    try circle.set("red", forField: "color")
    try circle.set(5.0, forField: "param1")  // radius
    shapes.append(circle)

    // Rectangle
    var rectangle = factory.createMessage(from: shapeDescriptor)
    try rectangle.set("rectangle", forField: "type")
    try rectangle.set("BlueRectangle", forField: "name")
    try rectangle.set("blue", forField: "color")
    try rectangle.set(8.0, forField: "param1")  // width
    try rectangle.set(12.0, forField: "param2")  // height
    shapes.append(rectangle)

    // Triangle (equilateral)
    var triangle = factory.createMessage(from: shapeDescriptor)
    try triangle.set("triangle", forField: "type")
    try triangle.set("GreenTriangle", forField: "name")
    try triangle.set("green", forField: "color")
    try triangle.set(6.0, forField: "param1")  // side length
    shapes.append(triangle)

    return shapes
  }

  static func determineShapeType(_ shape: DynamicMessage) throws -> String {
    let type: String = try shape.get(forField: "type") as? String ?? "unknown"
    let name: String = try shape.get(forField: "name") as? String ?? "Unknown"
    return "\(type.capitalized): \(name)"
  }

  static func processShapePolymorphically(_ shape: DynamicMessage) throws {
    let type: String = try shape.get(forField: "type") as? String ?? "unknown"
    let name: String = try shape.get(forField: "name") as? String ?? "Unknown"
    let color: String = try shape.get(forField: "color") as? String ?? "transparent"

    print("      🎨 Shape: \(name) (color: \(color))")

    let param1: Double = try shape.get(forField: "param1") as? Double ?? 0.0
    let param2: Double = try shape.get(forField: "param2") as? Double ?? 0.0

    switch type {
    case "circle":
      let radius = param1
      let area = Double.pi * radius * radius
      let perimeter = 2 * Double.pi * radius
      print(
        "        📐 Circle: radius=\(radius), area=\(String(format: "%.2f", area)), perimeter=\(String(format: "%.2f", perimeter))"
      )
    case "rectangle":
      let width = param1
      let height = param2
      let area = width * height
      let perimeter = 2 * (width + height)
      print(
        "        📐 Rectangle: \(width)x\(height), area=\(String(format: "%.2f", area)), perimeter=\(String(format: "%.2f", perimeter))"
      )
    case "triangle":
      let side = param1
      let area = (sqrt(3) / 4) * side * side
      let perimeter = 3 * side
      print(
        "        📐 Triangle: side=\(side), area=\(String(format: "%.2f", area)), perimeter=\(String(format: "%.2f", perimeter))"
      )
    default:
      print("        ❓ Unknown shape type")
    }
  }

  static func calculateTotalArea(_ shapes: [DynamicMessage]) throws -> Double {
    var totalArea: Double = 0.0

    for shape in shapes {
      let type: String = try shape.get(forField: "type") as? String ?? "unknown"
      let param1: Double = try shape.get(forField: "param1") as? Double ?? 0.0
      let param2: Double = try shape.get(forField: "param2") as? Double ?? 0.0

      switch type {
      case "circle":
        totalArea += Double.pi * param1 * param1
      case "rectangle":
        totalArea += param1 * param2
      case "triangle":
        totalArea += (sqrt(3) / 4) * param1 * param1
      default:
        break
      }
    }

    return totalArea
  }

  static func calculateAveragePerimeter(_ shapes: [DynamicMessage]) throws -> Double {
    var totalPerimeter: Double = 0.0

    for shape in shapes {
      let type: String = try shape.get(forField: "type") as? String ?? "unknown"
      let param1: Double = try shape.get(forField: "param1") as? Double ?? 0.0
      let param2: Double = try shape.get(forField: "param2") as? Double ?? 0.0

      switch type {
      case "circle":
        totalPerimeter += 2 * Double.pi * param1
      case "rectangle":
        totalPerimeter += 2 * (param1 + param2)
      case "triangle":
        totalPerimeter += 3 * param1
      default:
        break
      }
    }

    return shapes.isEmpty ? 0.0 : totalPerimeter / Double(shapes.count)
  }

  // MARK: - Step 3: User Data Structure

  static func createUserDataStructure() -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "user_data.proto", package: "users")

    var userDesc = MessageDescriptor(name: "User", parent: fileDescriptor)
    userDesc.addField(FieldDescriptor(name: "username", number: 1, type: .string))
    userDesc.addField(FieldDescriptor(name: "email", number: 2, type: .string))
    userDesc.addField(FieldDescriptor(name: "age", number: 3, type: .int32))
    userDesc.addField(FieldDescriptor(name: "user_type", number: 4, type: .int32))
    userDesc.addField(FieldDescriptor(name: "bio", number: 5, type: .string))
    userDesc.addField(FieldDescriptor(name: "created_timestamp", number: 6, type: .int64))

    fileDescriptor.addMessage(userDesc)
    return fileDescriptor
  }

  static func createUserDataSamples(factory: MessageFactory, fileDescriptor: FileDescriptor) throws -> [DynamicMessage]
  {
    let userDescriptor = fileDescriptor.messages.values.first { $0.name == "User" }!
    var users: [DynamicMessage] = []
    let timestamp = Int64(Date().timeIntervalSince1970)

    // User 1: Valid user
    var user1 = factory.createMessage(from: userDescriptor)
    try user1.set("ivan_petrov", forField: "username")
    try user1.set("ivan.petrov@example.com", forField: "email")
    try user1.set(Int32(28), forField: "age")
    try user1.set(Int32(0), forField: "user_type")  // Regular
    try user1.set("Software developer", forField: "bio")
    try user1.set(timestamp - 86400 * 365, forField: "created_timestamp")
    users.append(user1)

    // User 2: Premium user
    var user2 = factory.createMessage(from: userDescriptor)
    try user2.set("maria_design", forField: "username")
    try user2.set("maria@design-studio.com", forField: "email")
    try user2.set(Int32(24), forField: "age")
    try user2.set(Int32(1), forField: "user_type")  // Premium
    try user2.set("Design enthusiast", forField: "bio")
    try user2.set(timestamp - 86400 * 30, forField: "created_timestamp")
    users.append(user2)

    // User 3: Admin with invalid email
    var user3 = factory.createMessage(from: userDescriptor)
    try user3.set("admin", forField: "username")
    try user3.set("invalid-email", forField: "email")  // Invalid
    try user3.set(Int32(35), forField: "age")
    try user3.set(Int32(2), forField: "user_type")  // Admin
    try user3.set("System administrator", forField: "bio")
    try user3.set(timestamp - 86400 * 1000, forField: "created_timestamp")
    users.append(user3)

    return users
  }

  static func getUserSummary(_ user: DynamicMessage) throws -> String {
    let username: String = try user.get(forField: "username") as? String ?? "unknown"
    let email: String = try user.get(forField: "email") as? String ?? "no email"
    let userType: Int32 = try user.get(forField: "user_type") as? Int32 ?? 0

    let typeString =
      switch userType {
      case 0: "Regular"
      case 1: "Premium"
      case 2: "Admin"
      default: "Unknown"
      }

    return "\(username) (\(email), \(typeString))"
  }

  static func processUserFieldsConditionally(_ user: DynamicMessage) throws {
    let descriptor = user.descriptor

    for field in descriptor.fields.values.sorted(by: { $0.number < $1.number }) {
      guard let value = try? user.get(forField: field.name) else { continue }

      switch field.type {
      case .string:
        try processStringField(fieldName: field.name, value: value as! String)
      case .int32:
        try processInt32Field(fieldName: field.name, value: value as! Int32)
      case .int64:
        try processInt64Field(fieldName: field.name, value: value as! Int64)
      default:
        print("        🔍 Other field '\(field.name)': \(type(of: value))")
      }
    }
  }

  static func processStringField(fieldName: String, value: String) throws {
    print("        🔤 String field '\(fieldName)': \(value)")

    switch fieldName {
    case "email":
      let isValid = value.contains("@") && value.contains(".")
      print("          \(isValid ? "✅" : "❌") Email format \(isValid ? "valid" : "invalid")")
    case "username":
      let isValidLength = value.count >= 3 && value.count <= 20
      print("          \(isValidLength ? "✅" : "⚠️") Username length \(isValidLength ? "valid" : "invalid")")
    default:
      if value.isEmpty {
        print("          ⚠️ Empty string value")
      }
    }
  }

  static func processInt32Field(fieldName: String, value: Int32) throws {
    print("        🔢 Int32 field '\(fieldName)': \(value)")

    switch fieldName {
    case "age":
      if value >= 18 {
        print("          ✅ Adult user")
      }
      else if value >= 13 {
        print("          ⚠️ Minor user")
      }
      else {
        print("          ❌ Age too low")
      }
    case "user_type":
      let typeString =
        switch value {
        case 0: "Regular"
        case 1: "Premium"
        case 2: "Admin"
        default: "Unknown"
        }
      print("          🎭 User type: \(typeString)")
      if value >= 2 {
        print("          🔒 Privileged user")
      }
    default:
      break
    }
  }

  static func processInt64Field(fieldName: String, value: Int64) throws {
    print("        📅 Int64 field '\(fieldName)': \(value)")

    if fieldName == "created_timestamp" {
      let date = Date(timeIntervalSince1970: TimeInterval(value))
      let formatter = DateFormatter()
      formatter.dateStyle = .medium

      print("          📆 Created: \(formatter.string(from: date))")

      let daysAgo = Int(Date().timeIntervalSince1970 - TimeInterval(value)) / 86400
      if daysAgo < 30 {
        print("          🆕 New user")
      }
      else if daysAgo > 365 {
        print("          👑 Veteran user")
      }
    }
  }

  struct ValidationResults {
    let validCount: Int
    let invalidCount: Int
    let warningCount: Int
    let successRate: Double
  }

  static func validateUserDataByTypes(_ users: [DynamicMessage]) throws -> ValidationResults {
    var validCount = 0
    var invalidCount = 0
    var warningCount = 0

    for user in users {
      let username: String = try user.get(forField: "username") as? String ?? ""
      let email: String = try user.get(forField: "email") as? String ?? ""
      let age: Int32 = try user.get(forField: "age") as? Int32 ?? 0

      var isValid = true
      var hasWarnings = false

      if !email.contains("@") || !email.contains(".") {
        isValid = false
      }

      if username.count < 3 || username.count > 20 {
        isValid = false
      }

      if age < 13 {
        isValid = false
      }
      else if age < 18 {
        hasWarnings = true
      }

      if isValid {
        validCount += 1
        if hasWarnings {
          warningCount += 1
        }
      }
      else {
        invalidCount += 1
      }
    }

    let successRate = users.isEmpty ? 0.0 : Double(validCount) / Double(users.count) * 100

    return ValidationResults(
      validCount: validCount,
      invalidCount: invalidCount,
      warningCount: warningCount,
      successRate: successRate
    )
  }

  // MARK: - Step 4: Event System

  static func createEventSystemStructure() -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "events.proto", package: "events")

    var eventDesc = MessageDescriptor(name: "Event", parent: fileDescriptor)
    eventDesc.addField(FieldDescriptor(name: "event_id", number: 1, type: .string))
    eventDesc.addField(FieldDescriptor(name: "event_type", number: 2, type: .int32))
    eventDesc.addField(FieldDescriptor(name: "payload", number: 3, type: .string))
    eventDesc.addField(FieldDescriptor(name: "severity", number: 4, type: .string))
    eventDesc.addField(FieldDescriptor(name: "timestamp", number: 5, type: .int64))

    fileDescriptor.addMessage(eventDesc)
    return fileDescriptor
  }

  static func createVariousEvents(factory: MessageFactory, fileDescriptor: FileDescriptor) throws -> [DynamicMessage] {
    let eventDescriptor = fileDescriptor.messages.values.first { $0.name == "Event" }!
    var events: [DynamicMessage] = []
    let timestamp = Int64(Date().timeIntervalSince1970)

    // User event
    var userEvent = factory.createMessage(from: eventDescriptor)
    try userEvent.set("evt_001", forField: "event_id")
    try userEvent.set(Int32(0), forField: "event_type")  // User event
    try userEvent.set("user_login", forField: "payload")
    try userEvent.set("INFO", forField: "severity")
    try userEvent.set(timestamp, forField: "timestamp")
    events.append(userEvent)

    // System event
    var systemEvent = factory.createMessage(from: eventDescriptor)
    try systemEvent.set("evt_002", forField: "event_id")
    try systemEvent.set(Int32(1), forField: "event_type")  // System event
    try systemEvent.set("database_error", forField: "payload")
    try systemEvent.set("ERROR", forField: "severity")
    try systemEvent.set(timestamp - 60, forField: "timestamp")
    events.append(systemEvent)

    // Business event
    var businessEvent = factory.createMessage(from: eventDescriptor)
    try businessEvent.set("evt_003", forField: "event_id")
    try businessEvent.set(Int32(2), forField: "event_type")  // Business event
    try businessEvent.set("purchase_completed", forField: "payload")
    try businessEvent.set("INFO", forField: "severity")
    try businessEvent.set(timestamp - 120, forField: "timestamp")
    events.append(businessEvent)

    // Security event
    var securityEvent = factory.createMessage(from: eventDescriptor)
    try securityEvent.set("evt_004", forField: "event_id")
    try securityEvent.set(Int32(3), forField: "event_type")  // Security event
    try securityEvent.set("failed_login_attempt", forField: "payload")
    try securityEvent.set("HIGH", forField: "severity")
    try securityEvent.set(timestamp - 180, forField: "timestamp")
    events.append(securityEvent)

    return events
  }

  static func getEventType(_ event: DynamicMessage) throws -> String {
    let eventId: String = try event.get(forField: "event_id") as? String ?? "unknown"
    let eventType: Int32 = try event.get(forField: "event_type") as? Int32 ?? 0

    let typeString =
      switch eventType {
      case 0: "User Event"
      case 1: "System Event"
      case 2: "Business Event"
      case 3: "Security Event"
      default: "Unknown Event"
      }

    return "\(eventId) (\(typeString))"
  }

  static func demonstrateCustomHandlers(dispatcher: EventDispatcher, events: [DynamicMessage]) throws {
    dispatcher.addCustomHandler(eventType: 2) { event in
      print("      💰 Custom Business Handler: Processing transaction")
      let payload: String = try event.get(forField: "payload") as? String ?? ""
      if payload.contains("purchase") {
        print("        💳 Purchase transaction detected")
      }
    }

    dispatcher.addCustomHandler(eventType: 3) { event in
      print("      🔒 Custom Security Handler: Analyzing threat")
      let severity: String = try event.get(forField: "severity") as? String ?? ""
      if severity == "HIGH" {
        print("        🚨 High severity security event!")
      }
    }

    for event in events {
      let eventType: Int32 = try event.get(forField: "event_type") as? Int32 ?? 0
      if eventType == 2 || eventType == 3 {
        try dispatcher.dispatch(event)
      }
    }
  }

  // MARK: - Step 5: API Response Structure

  static func createAPIResponseStructure() -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "api_response.proto", package: "api")

    var responseDesc = MessageDescriptor(name: "APIResponse", parent: fileDescriptor)
    responseDesc.addField(FieldDescriptor(name: "status_code", number: 1, type: .int32))
    responseDesc.addField(FieldDescriptor(name: "message", number: 2, type: .string))
    responseDesc.addField(FieldDescriptor(name: "data", number: 3, type: .string))
    responseDesc.addField(FieldDescriptor(name: "error_code", number: 4, type: .string))
    responseDesc.addField(FieldDescriptor(name: "timestamp", number: 5, type: .int64))

    fileDescriptor.addMessage(responseDesc)
    return fileDescriptor
  }

  static func createAPIResponses(factory: MessageFactory, fileDescriptor: FileDescriptor) throws -> [DynamicMessage] {
    let responseDescriptor = fileDescriptor.messages.values.first { $0.name == "APIResponse" }!
    var responses: [DynamicMessage] = []
    let timestamp = Int64(Date().timeIntervalSince1970)

    // Success response
    var successResponse = factory.createMessage(from: responseDescriptor)
    try successResponse.set(Int32(200), forField: "status_code")
    try successResponse.set("OK", forField: "message")
    try successResponse.set("{\"users\": []}", forField: "data")
    try successResponse.set(timestamp, forField: "timestamp")
    responses.append(successResponse)

    // Error response
    var errorResponse = factory.createMessage(from: responseDescriptor)
    try errorResponse.set(Int32(400), forField: "status_code")
    try errorResponse.set("Bad Request", forField: "message")
    try errorResponse.set("INVALID_PARAMETERS", forField: "error_code")
    try errorResponse.set(timestamp - 30, forField: "timestamp")
    responses.append(errorResponse)

    // Server error response
    var serverErrorResponse = factory.createMessage(from: responseDescriptor)
    try serverErrorResponse.set(Int32(500), forField: "status_code")
    try serverErrorResponse.set("Internal Server Error", forField: "message")
    try serverErrorResponse.set("DATABASE_ERROR", forField: "error_code")
    try serverErrorResponse.set(timestamp - 60, forField: "timestamp")
    responses.append(serverErrorResponse)

    return responses
  }

  static func getResponseType(_ response: DynamicMessage) throws -> String {
    let statusCode: Int32 = try response.get(forField: "status_code") as? Int32 ?? 0
    let message: String = try response.get(forField: "message") as? String ?? "Unknown"
    return "\(statusCode) \(message)"
  }

  static func analyzeResponseWithPatternMatching(_ response: DynamicMessage) throws {
    let statusCode: Int32 = try response.get(forField: "status_code") as? Int32 ?? 0

    print("      🔍 Pattern analysis for status \(statusCode):")

    switch statusCode {
    case 200..<300:
      print("        ✅ Success pattern detected")
      if let data = try? response.get(forField: "data") as? String, !data.isEmpty {
        print("          📊 Contains response data")
      }
    case 300..<400:
      print("        🔄 Redirect pattern detected")
    case 400..<500:
      print("        ❌ Client Error pattern detected")
      if let errorCode = try? response.get(forField: "error_code") as? String {
        print("          💥 Error code: \(errorCode)")
      }
    case 500..<600:
      print("        🔥 Server Error pattern detected")
      print("          ↩️ Retry recommended")
    default:
      print("        ❓ Unknown status pattern")
    }
  }

  static func demonstrateComplexPatternMatching(_ responses: [DynamicMessage]) throws {
    var patterns: [String: Int] = [:]

    for response in responses {
      let statusCode: Int32 = try response.get(forField: "status_code") as? Int32 ?? 0

      let pattern =
        switch statusCode {
        case 200..<300: "Success"
        case 400..<500: "Client Error"
        case 500..<600: "Server Error"
        default: "Other"
        }

      patterns[pattern, default: 0] += 1
    }

    print("      📊 Pattern distribution:")
    for (pattern, count) in patterns.sorted(by: { $0.key < $1.key }) {
      print("        \(pattern): \(count) responses")
    }
  }

  static func analyzePatternMatchingEffectiveness(_ responses: [DynamicMessage]) throws -> [String: String] {
    var stats: [String: String] = [:]

    let matchedPatterns = responses.filter { response in
      if let statusCode = try? response.get(forField: "status_code") as? Int32 {
        return statusCode >= 200 && statusCode < 600
      }
      return false
    }.count

    let effectiveness = responses.isEmpty ? 0.0 : Double(matchedPatterns) / Double(responses.count) * 100

    stats["Matched Patterns"] = "\(matchedPatterns)"
    stats["Total Responses"] = "\(responses.count)"
    stats["Effectiveness"] = String(format: "%.1f%%", effectiveness)

    return stats
  }

  // MARK: - Step 6: Advanced Type Structure

  static func createAdvancedTypeStructure() -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "advanced_types.proto", package: "advanced")

    var structureDesc = MessageDescriptor(name: "ComplexStructure", parent: fileDescriptor)
    structureDesc.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    structureDesc.addField(FieldDescriptor(name: "type_signature", number: 2, type: .string))
    structureDesc.addField(FieldDescriptor(name: "version", number: 3, type: .int32))
    structureDesc.addField(FieldDescriptor(name: "metadata", number: 4, type: .string, isRepeated: true))
    structureDesc.addField(FieldDescriptor(name: "complexity_score", number: 5, type: .double))

    fileDescriptor.addMessage(structureDesc)
    return fileDescriptor
  }

  static func createComplexTypedStructures(factory: MessageFactory, fileDescriptor: FileDescriptor) throws
    -> [DynamicMessage]
  {
    let structureDescriptor = fileDescriptor.messages.values.first { $0.name == "ComplexStructure" }!
    var structures: [DynamicMessage] = []

    var structure1 = factory.createMessage(from: structureDescriptor)
    try structure1.set("struct_001", forField: "id")
    try structure1.set("SimpleType", forField: "type_signature")
    try structure1.set(Int32(1), forField: "version")
    try structure1.set(["metadata1", "metadata2"], forField: "metadata")
    try structure1.set(2.5, forField: "complexity_score")
    structures.append(structure1)

    return structures
  }

  static func getStructureSignature(_ structure: DynamicMessage) throws -> String {
    let id: String = try structure.get(forField: "id") as? String ?? "unknown"
    let typeSignature: String = try structure.get(forField: "type_signature") as? String ?? "Unknown"
    return "\(id) (\(typeSignature))"
  }

  static func performDeepTypeIntrospection(_ structure: DynamicMessage) throws {
    print("      🔬 Deep type analysis:")

    let descriptor = structure.descriptor
    print("        📋 Message type: \(descriptor.name)")
    print("        🏷️ Field count: \(descriptor.fields.count)")

    var stringFields = 0
    var numberFields = 0
    var arrayFields = 0

    for field in descriptor.fields.values {
      switch field.type {
      case .string:
        stringFields += 1
      case .int32, .int64, .double:
        numberFields += 1
      default:
        break
      }

      if field.isRepeated {
        arrayFields += 1
      }
    }

    print("        📝 String fields: \(stringFields)")
    print("        🔢 Number fields: \(numberFields)")
    print("        📋 Array fields: \(arrayFields)")
  }

  static func analyzeTypeCompatibility(_ structures: [DynamicMessage]) throws {
    print("      🔄 Type compatibility analysis:")

    let signatures = Set(structures.map { $0.descriptor.name })

    if signatures.count == 1 {
      print("        ✅ All structures are type-compatible")
    }
    else {
      print("        ⚠️ Multiple type signatures detected")
    }

    print("        📊 Unique types: \(signatures.count)")
  }

  static func demonstrateRuntimeTypeEvolution(_ structure: DynamicMessage) throws {
    print("      📈 Runtime type evolution:")
    print("        🔄 Original structure analysis completed")
    print("        🔧 Simulating field modifications...")
    print("        ➕ Virtual field computation")
    print("        📊 Type metadata updated")
    print("        ✅ Evolution completed")
  }

  static func generateIntrospectionSummary(_ structures: [DynamicMessage]) throws -> [String: String] {
    var summary: [String: String] = [:]

    let totalFields = structures.reduce(0) { total, structure in
      total + structure.descriptor.fields.count
    }

    let avgFields = structures.isEmpty ? 0.0 : Double(totalFields) / Double(structures.count)

    summary["Total Structures"] = "\(structures.count)"
    summary["Total Fields"] = "\(totalFields)"
    summary["Average Fields"] = String(format: "%.1f", avgFields)
    summary["Complexity"] = "Medium"

    return summary
  }
}

// MARK: - Event Dispatcher

class EventDispatcher {
  private var eventCounts: [String: Int] = [:]
  private var customHandlers: [Int32: (DynamicMessage) throws -> Void] = [:]

  func dispatch(_ event: DynamicMessage) throws {
    let eventId: String = try event.get(forField: "event_id") as? String ?? "unknown"
    let eventType: Int32 = try event.get(forField: "event_type") as? Int32 ?? 0

    let typeString =
      switch eventType {
      case 0: "User"
      case 1: "System"
      case 2: "Business"
      case 3: "Security"
      default: "Unknown"
      }

    eventCounts[typeString, default: 0] += 1

    print("      📡 Dispatching \(typeString) Event: \(eventId)")

    if let customHandler = customHandlers[eventType] {
      try customHandler(event)
      return
    }

    // Default processing
    let payload: String = try event.get(forField: "payload") as? String ?? ""
    let severity: String = try event.get(forField: "severity") as? String ?? ""

    print("        📋 Payload: \(payload)")
    print("        🔔 Severity: \(severity)")

    switch eventType {
    case 0:
      print("        👤 Processing user event")
    case 1:
      print("        🖥️ Processing system event")
    case 2:
      print("        💼 Processing business event")
    case 3:
      print("        🛡️ Processing security event")
    default:
      print("        ❓ Unknown event type")
    }
  }

  func addCustomHandler(eventType: Int32, handler: @escaping (DynamicMessage) throws -> Void) {
    customHandlers[eventType] = handler
  }

  func getStatistics() -> [String: String] {
    var stats: [String: String] = [:]

    for (type, count) in eventCounts {
      stats["\(type) Events"] = "\(count)"
    }

    let totalEvents = eventCounts.values.reduce(0, +)
    stats["Total Processed"] = "\(totalEvents)"
    stats["Custom Handlers"] = "\(customHandlers.count)"

    return stats
  }
}

// MARK: - Array Extension

extension Array where Element == String {
  func mostFrequent() -> String? {
    guard !isEmpty else { return nil }

    var counts: [String: Int] = [:]
    for element in self {
      counts[element, default: 0] += 1
    }

    return counts.max(by: { $0.value < $1.value })?.key
  }
}
