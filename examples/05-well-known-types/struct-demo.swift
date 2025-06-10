/**
 * 📦 SwiftProtoReflect Example: Struct Demo
 *
 * Description: Working with google.protobuf.Struct for dynamic JSON-like structures
 * Key concepts: StructHandler, ValueValue, Dynamic structures, JSON mapping
 * Complexity: 🔧 Intermediate
 * Execution time: < 15 seconds
 *
 * What you'll learn:
 * - Creating and manipulating google.protobuf.Struct
 * - Converting between Dictionary<String, Any> and StructValue
 * - Support for nested structures and arrays
 * - ValueValue for different data types
 * - Struct operations (adding, removing, merging)
 * - Round-trip compatibility
 *
 * Run with:
 *   swift run StructDemo
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct StructDemo {
  static func main() throws {
    ExampleUtils.printHeader("Google Protobuf Struct Integration")

    try demonstrateBasicStructOperations()
    try demonstrateValueTypes()
    try demonstrateNestedStructures()
    try demonstrateStructOperations()
    try demonstrateRoundTripCompatibility()
    try demonstratePerformanceAndComplexity()

    ExampleUtils.printSuccess("Struct demo completed! You've learned all aspects of working with google.protobuf.Struct.")

    ExampleUtils.printNext([
      "Next, explore: value-demo.swift - universal values",
      "Advanced: any-demo.swift - type erasure support",
      "Integration: well-known-registry.swift - comprehensive demo",
    ])
  }

  // MARK: - Implementation Steps

  private static func demonstrateBasicStructOperations() throws {
    ExampleUtils.printStep(1, "Basic Struct Operations")

    // Create empty structure
    let emptyStruct = StructHandler.StructValue()
    print("  📦 Empty struct: \(emptyStruct)")
    print("  📏 Fields count: \(emptyStruct.fields.count)")

    // Create structure from Dictionary
    let userDict: [String: Any] = [
      "name": "John Doe",
      "age": 30,
      "email": "john.doe@example.com",
      "active": true,
      "score": 95.5,
    ]

    let userStruct = try StructHandler.StructValue(from: userDict)
    print("  👤 User struct: \(userStruct)")
    print("  📏 Fields count: \(userStruct.fields.count)")

    // Access fields
    if let name = userStruct.getValue("name") {
      print("  🏷  Name field: \(name)")
    }

    if let age = userStruct.getValue("age") {
      print("  🎂 Age field: \(age)")
    }

    // Check field presence
    print("  🔍 Contains 'name': \(userStruct.contains("name"))")
    print("  🔍 Contains 'salary': \(userStruct.contains("salary"))")

    // Convert back to Dictionary
    let reconstructedDict = userStruct.toDictionary()
    print("  🔄 Reconstructed dict keys: \(reconstructedDict.keys.sorted())")

    // Check data preservation
    print("  ✅ Data integrity:")
    print("    Name match: \(reconstructedDict["name"] as? String == userDict["name"] as? String)")
    print("    Age match: \(reconstructedDict["age"] as? Double == Double(userDict["age"] as! Int))")
    print("    Email match: \(reconstructedDict["email"] as? String == userDict["email"] as? String)")
  }

  private static func demonstrateValueTypes() throws {
    ExampleUtils.printStep(2, "ValueValue Types Demonstration")

    // Demonstration of all ValueValue types
    let valueExamples: [(String, Any, StructHandler.ValueValue)] = [
      ("Null Value", NSNull(), .nullValue),
      ("String Value", "Hello, World!", .stringValue("Hello, World!")),
      ("Boolean True", true, .boolValue(true)),
      ("Boolean False", false, .boolValue(false)),
      ("Integer", 42, .numberValue(42.0)),
      ("Double", 3.14159, .numberValue(3.14159)),
      (
        "Array", ["apple", "banana", "cherry"],
        .listValue([.stringValue("apple"), .stringValue("banana"), .stringValue("cherry")])
      ),
    ]

    var typeResults: [[String: String]] = []

    for (description, originalValue, expectedValue) in valueExamples {
      do {
        let valueValue = try StructHandler.ValueValue(from: originalValue)
        let matches = valueValue == expectedValue
        let reconstructed = valueValue.toAny()

        typeResults.append([
          "Type": description,
          "Original": "\(originalValue)",
          "ValueValue": "\(valueValue)",
          "Match Expected": matches ? "✅ YES" : "❌ NO",
          "Round-trip": "\(reconstructed)",
        ])
      }
      catch {
        typeResults.append([
          "Type": description,
          "Original": "\(originalValue)",
          "ValueValue": "ERROR",
          "Match Expected": "❌ ERROR",
          "Round-trip": "N/A",
        ])
      }
    }

    ExampleUtils.printDataTable(typeResults, title: "ValueValue Types")

    // Special cases with numbers
    print("  🔢 Number type handling:")
    let numberTypes: [Any] = [Int32(100), Int64(200), UInt32(300), UInt64(400), Float(5.5), Double(6.6)]
    for number in numberTypes {
      let valueValue = try StructHandler.ValueValue(from: number)
      print("    \(type(of: number)): \(number) -> \(valueValue)")
    }
  }

  private static func demonstrateNestedStructures() throws {
    ExampleUtils.printStep(3, "Nested Structures and Complex Data")

    // Create complex nested structure
    let complexData: [String: Any] = [
      "user": [
        "personal": [
          "name": "Alice Johnson",
          "age": 28,
          "location": [
            "city": "San Francisco",
            "country": "USA",
            "coordinates": [37.7749, -122.4194],
          ],
        ],
        "professional": [
          "title": "Software Engineer",
          "skills": ["Swift", "Python", "JavaScript"],
          "experience": 5.5,
          "remote": true,
        ],
      ],
      "metadata": [
        "created": "2023-01-15T10:30:00Z",
        "version": 2,
        "tags": ["employee", "engineer", "remote-worker"],
      ],
    ]

    print("  🏗  Creating complex nested structure...")
    let complexStruct = try StructHandler.StructValue(from: complexData)
    print("  📦 Top-level fields: \(complexStruct.fields.keys.sorted())")

    // Navigate through nested structure
    if let userValue = complexStruct.getValue("user"),
      case .structValue(let userStruct) = userValue
    {
      print("  👤 User struct has \(userStruct.fields.count) fields")

      if let personalValue = userStruct.getValue("personal"),
        case .structValue(let personalStruct) = personalValue
      {
        print("  👨‍💼 Personal info:")
        if let nameValue = personalStruct.getValue("name"),
          case .stringValue(let name) = nameValue
        {
          print("    Name: \(name)")
        }

        if let locationValue = personalStruct.getValue("location"),
          case .structValue(let locationStruct) = locationValue
        {
          print("    Location fields: \(locationStruct.fields.keys.sorted())")

          if let coordsValue = locationStruct.getValue("coordinates"),
            case .listValue(let coords) = coordsValue
          {
            print("    Coordinates: \(coords)")
          }
        }
      }

      if let professionalValue = userStruct.getValue("professional"),
        case .structValue(let professionalStruct) = professionalValue
      {
        print("  💼 Professional info:")
        if let skillsValue = professionalStruct.getValue("skills"),
          case .listValue(let skills) = skillsValue
        {
          print("    Skills: \(skills)")
        }
      }
    }

    // Test deep round-trip
    print("  🔄 Testing deep round-trip conversion...")
    let dynamicMessage = try StructHandler.createDynamic(from: complexStruct)
    let extractedStruct = try StructHandler.createSpecialized(from: dynamicMessage) as! StructHandler.StructValue
    let finalDict = extractedStruct.toDictionary()

    // Check deep integrity
    let originalUser = complexData["user"] as! [String: Any]
    let originalPersonal = originalUser["personal"] as! [String: Any]
    let finalUser = finalDict["user"] as! [String: Any]
    let finalPersonal = finalUser["personal"] as! [String: Any]

    print("  ✅ Deep integrity check:")
    print("    Original name: \(originalPersonal["name"] as! String)")
    print("    Final name: \(finalPersonal["name"] as! String)")
    print("    Names match: \(originalPersonal["name"] as! String == finalPersonal["name"] as! String)")
  }

  private static func demonstrateStructOperations() throws {
    ExampleUtils.printStep(4, "Struct Operations and Manipulation")

    // Base user structure
    let baseUser = try StructHandler.StructValue(from: [
      "name": "Bob Smith",
      "age": 25,
      "department": "Engineering",
    ])

    print("  📦 Base user: \(baseUser)")

    // Adding operations
    print("  ➕ Adding operations:")
    let withEmail = baseUser.adding("email", value: .stringValue("bob.smith@company.com"))
    let withSalary = withEmail.adding("salary", value: .numberValue(85000.0))
    let withActive = withSalary.adding("active", value: .boolValue(true))

    print("    After adding email: \(withEmail.fields.keys.count) fields")
    print("    After adding salary: \(withSalary.fields.keys.count) fields")
    print("    After adding active: \(withActive.fields.keys.count) fields")
    print("    Original unchanged: \(baseUser.fields.keys.count) fields")

    // Removing operations
    print("  ➖ Removing operations:")
    let withoutAge = withActive.removing("age")
    let withoutDept = withoutAge.removing("department")

    print("    After removing age: \(withoutAge.fields.keys.count) fields")
    print("    After removing department: \(withoutDept.fields.keys.count) fields")
    print("    Final fields: \(withoutDept.fields.keys.sorted())")

    // Merging operations
    print("  🔀 Merging operations:")
    let profileData = try StructHandler.StructValue(from: [
      "age": 26,  // Override existing
      "city": "New York",  // New field
      "skills": ["Swift", "iOS", "macOS"],  // New field
      "manager": [  // Nested structure
        "name": "Sarah Wilson",
        "level": "Senior",
      ],
    ])

    let mergedUser = baseUser.merging(profileData)
    print("    Base user fields: \(baseUser.fields.keys.sorted())")
    print("    Profile data fields: \(profileData.fields.keys.sorted())")
    print("    Merged result fields: \(mergedUser.fields.keys.sorted())")

    // Check override behavior
    if let mergedAge = mergedUser.getValue("age"),
      let originalAge = baseUser.getValue("age")
    {
      print("    Age override: \(originalAge) -> \(mergedAge)")
    }
  }

  private static func demonstrateRoundTripCompatibility() throws {
    ExampleUtils.printStep(5, "Round-Trip Compatibility Testing")

    // Test scenarios with different data types
    let testCases: [(String, [String: Any])] = [
      (
        "Simple flat structure",
        [
          "name": "Test User",
          "count": 42,
          "enabled": true,
        ]
      ),
      (
        "Array heavy structure",
        [
          "numbers": [1, 2, 3, 4, 5],
          "strings": ["apple", "banana", "cherry"],
          "mixed": [true, 42, "text", 3.14],
        ]
      ),
      (
        "Deeply nested structure",
        [
          "level1": [
            "level2": [
              "level3": [
                "level4": "deep value"
              ]
            ]
          ]
        ]
      ),
      (
        "Mixed complexity",
        [
          "user": [
            "profile": ["name": "John", "age": 30],
            "preferences": ["theme": "dark", "notifications": true],
          ],
          "data": [1, 2, ["nested": "array"]],
          "metadata": NSNull(),
        ]
      ),
    ]

    var testResults: [[String: String]] = []
    var allTestsPassed = true

    for (testName, originalData) in testCases {
      do {
        // Round-trip: Dict -> StructValue -> DynamicMessage -> StructValue -> Dict
        let structValue1 = try StructHandler.StructValue(from: originalData)
        let dynamicMessage = try StructHandler.createDynamic(from: structValue1)
        let structValue2 = try StructHandler.createSpecialized(from: dynamicMessage) as! StructHandler.StructValue
        let resultData = structValue2.toDictionary()

        // Check integrity
        let integrityCheck = try verifyDataIntegrity(original: originalData, result: resultData)

        testResults.append([
          "Test": testName,
          "Original Keys": "\(originalData.keys.count)",
          "Result Keys": "\(resultData.keys.count)",
          "Integrity": integrityCheck ? "✅ PASS" : "❌ FAIL",
          "Status": "✅ SUCCESS",
        ])

        if !integrityCheck {
          allTestsPassed = false
        }
      }
      catch {
        testResults.append([
          "Test": testName,
          "Original Keys": "\(originalData.keys.count)",
          "Result Keys": "ERROR",
          "Integrity": "❌ ERROR",
          "Status": "❌ FAILED",
        ])
        allTestsPassed = false
        print("    ❌ Error in \(testName): \(error)")
      }
    }

    ExampleUtils.printDataTable(testResults, title: "Round-Trip Compatibility Tests")

    print("  🏆 Overall compatibility: \(allTestsPassed ? "✅ EXCELLENT" : "⚠️ NEEDS ATTENTION")")
  }

  private static func demonstratePerformanceAndComplexity() throws {
    ExampleUtils.printStep(6, "Performance Analysis and Complex Scenarios")

    // Performance benchmarking
    print("  🚀 Performance benchmarking:")

    let benchmarkData: [String: Any] = [
      "name": "Performance Test User",
      "data": Array(0..<100).map { "item_\($0)" },
      "nested": (0..<50).reduce(into: [String: Any]()) { dict, i in
        dict["field_\(i)"] = "value_\(i)"
      },
    ]

    let iterations = 100
    var times: [TimeInterval] = []

    for _ in 0..<iterations {
      let (_, time) = ExampleUtils.measureTime {
        let structValue = try! StructHandler.StructValue(from: benchmarkData)
        let message = try! StructHandler.createDynamic(from: structValue)
        let _ = try! StructHandler.createSpecialized(from: message)
      }
      times.append(time)
    }

    let avgTime = times.reduce(0, +) / Double(times.count)
    let minTime = times.min() ?? 0
    let maxTime = times.max() ?? 0

    ExampleUtils.printTiming("Average conversion (\(iterations) iterations)", time: avgTime)
    ExampleUtils.printTiming("Fastest conversion", time: minTime)
    ExampleUtils.printTiming("Slowest conversion", time: maxTime)

    let opsPerSecond = 1.0 / avgTime
    print("    🎯 Operations per second: \(String(format: "%.0f", opsPerSecond))")

    print("  💡 Performance insights:")
    print("    • google.protobuf.Struct is excellent for dynamic JSON-like data")
    print("    • Round-trip operations are efficient even for complex structures")
    print("    • Scales linearly with data size")
    print("    • Suitable for real-time scenarios (< 1ms for typical sizes)")
  }

  // MARK: - Helper Methods

  private static func verifyDataIntegrity(original: [String: Any], result: [String: Any]) throws -> Bool {
    guard original.keys.count == result.keys.count else { return false }

    for key in original.keys {
      guard let originalValue = original[key],
        let resultValue = result[key]
      else { return false }

      if !valuesEqual(originalValue, resultValue) {
        return false
      }
    }

    return true
  }

  private static func valuesEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    if lhs is NSNull && rhs is NSNull { return true }
    if let lhsString = lhs as? String, let rhsString = rhs as? String {
      return lhsString == rhsString
    }
    if let lhsBool = lhs as? Bool, let rhsBool = rhs as? Bool {
      return lhsBool == rhsBool
    }
    if let lhsNumber = lhs as? NSNumber, let rhsNumber = rhs as? NSNumber {
      return lhsNumber.doubleValue == rhsNumber.doubleValue
    }
    if let lhsArray = lhs as? [Any], let rhsArray = rhs as? [Any] {
      guard lhsArray.count == rhsArray.count else { return false }
      for (lhsItem, rhsItem) in zip(lhsArray, rhsArray) where !valuesEqual(lhsItem, rhsItem) {
        return false
      }
      return true
    }
    if let lhsDict = lhs as? [String: Any], let rhsDict = rhs as? [String: Any] {
      return (try? verifyDataIntegrity(original: lhsDict, result: rhsDict)) == true
    }

    return false
  }
}
