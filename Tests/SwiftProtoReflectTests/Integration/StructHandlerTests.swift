/**
 * StructHandlerTests.swift
 * SwiftProtoReflectTests
 *
 * Тесты для StructHandler - обработчика google.protobuf.Struct
 */

import XCTest

@testable import SwiftProtoReflect

final class StructHandlerTests: XCTestCase {

  // MARK: - StructValue Tests

  func testStructValueInitialization() {
    // Пустая структура
    let emptyStruct = StructHandler.StructValue()
    XCTAssertTrue(emptyStruct.fields.isEmpty)
    XCTAssertEqual(emptyStruct.description, "Struct(empty)")

    // Структура с полями
    let fields: [String: StructHandler.ValueValue] = [
      "name": .stringValue("John"),
      "age": .numberValue(30),
      "active": .boolValue(true),
    ]
    let structValue = StructHandler.StructValue(fields: fields)
    XCTAssertEqual(structValue.fields.count, 3)
    XCTAssertEqual(structValue.getValue("name"), .stringValue("John"))
  }

  func testStructValueFromDictionary() throws {
    let dictionary: [String: Any] = [
      "name": "John",
      "age": 30,
      "active": true,
      "score": 95.5,
      "metadata": [
        "created": "2023-01-01",
        "tags": ["user", "active"],
      ],
    ]

    let structValue = try StructHandler.StructValue(from: dictionary)

    XCTAssertEqual(structValue.fields.count, 5)
    XCTAssertEqual(structValue.getValue("name"), .stringValue("John"))
    XCTAssertEqual(structValue.getValue("age"), .numberValue(30))
    XCTAssertEqual(structValue.getValue("active"), .boolValue(true))
    XCTAssertEqual(structValue.getValue("score"), .numberValue(95.5))

    // Проверяем вложенную структуру
    if case .structValue(let metadata) = structValue.getValue("metadata") {
      XCTAssertEqual(metadata.getValue("created"), .stringValue("2023-01-01"))
      if case .listValue(let tags) = metadata.getValue("tags") {
        XCTAssertEqual(tags.count, 2)
        XCTAssertEqual(tags[0], .stringValue("user"))
        XCTAssertEqual(tags[1], .stringValue("active"))
      }
      else {
        XCTFail("Expected list value for tags")
      }
    }
    else {
      XCTFail("Expected struct value for metadata")
    }
  }

  func testStructValueOperations() {
    let original = StructHandler.StructValue(fields: [
      "name": .stringValue("John"),
      "age": .numberValue(30),
    ])

    // Contains
    XCTAssertTrue(original.contains("name"))
    XCTAssertFalse(original.contains("email"))

    // Adding
    let withEmail = original.adding("email", value: .stringValue("john@example.com"))
    XCTAssertEqual(withEmail.fields.count, 3)
    XCTAssertEqual(withEmail.getValue("email"), .stringValue("john@example.com"))
    XCTAssertEqual(original.fields.count, 2)  // Original unchanged

    // Removing
    let withoutAge = original.removing("age")
    XCTAssertEqual(withoutAge.fields.count, 1)
    XCTAssertFalse(withoutAge.contains("age"))
    XCTAssertEqual(original.fields.count, 2)  // Original unchanged

    // Merging
    let other = StructHandler.StructValue(fields: [
      "age": .numberValue(31),  // Override
      "city": .stringValue("New York"),  // New field
    ])
    let merged = original.merging(other)
    XCTAssertEqual(merged.fields.count, 3)
    XCTAssertEqual(merged.getValue("age"), .numberValue(31))  // Overridden
    XCTAssertEqual(merged.getValue("city"), .stringValue("New York"))
  }

  func testStructValueToDictionary() {
    let structValue = StructHandler.StructValue(fields: [
      "name": .stringValue("John"),
      "age": .numberValue(30),
      "active": .boolValue(true),
      "score": .numberValue(95.5),
      "tags": .listValue([.stringValue("user"), .stringValue("active")]),
    ])

    let dictionary = structValue.toDictionary()

    XCTAssertEqual(dictionary["name"] as? String, "John")
    XCTAssertEqual(dictionary["age"] as? Double, 30)
    XCTAssertEqual(dictionary["active"] as? Bool, true)
    XCTAssertEqual(dictionary["score"] as? Double, 95.5)

    let tags = dictionary["tags"] as? [Any]
    XCTAssertEqual(tags?.count, 2)
    XCTAssertEqual(tags?[0] as? String, "user")
    XCTAssertEqual(tags?[1] as? String, "active")
  }

  // MARK: - ValueValue Tests

  func testValueValueFromBasicTypes() throws {
    // Null
    let nullValue = try StructHandler.ValueValue(from: NSNull())
    XCTAssertEqual(nullValue, .nullValue)

    // String
    let stringValue = try StructHandler.ValueValue(from: "hello")
    XCTAssertEqual(stringValue, .stringValue("hello"))

    // Bool
    let boolValue = try StructHandler.ValueValue(from: true)
    XCTAssertEqual(boolValue, .boolValue(true))

    // Numbers
    let intValue = try StructHandler.ValueValue(from: 42)
    XCTAssertEqual(intValue, .numberValue(42.0))

    let doubleValue = try StructHandler.ValueValue(from: 3.14)
    XCTAssertEqual(doubleValue, .numberValue(3.14))
  }

  func testValueValueFromCollections() throws {
    // Array
    let arrayValue = try StructHandler.ValueValue(from: ["hello", 42, true])
    if case .listValue(let list) = arrayValue {
      XCTAssertEqual(list.count, 3)
      XCTAssertEqual(list[0], .stringValue("hello"))
      XCTAssertEqual(list[1], .numberValue(42.0))
      XCTAssertEqual(list[2], .boolValue(true))
    }
    else {
      XCTFail("Expected list value")
    }

    // Dictionary
    let dictValue = try StructHandler.ValueValue(from: ["name": "John", "age": 30])
    if case .structValue(let structVal) = dictValue {
      XCTAssertEqual(structVal.getValue("name"), .stringValue("John"))
      XCTAssertEqual(structVal.getValue("age"), .numberValue(30.0))
    }
    else {
      XCTFail("Expected struct value")
    }
  }

  func testValueValueToAny() {
    let nullValue = StructHandler.ValueValue.nullValue
    XCTAssertTrue(nullValue.toAny() is NSNull)

    let stringValue = StructHandler.ValueValue.stringValue("hello")
    XCTAssertEqual(stringValue.toAny() as? String, "hello")

    let boolValue = StructHandler.ValueValue.boolValue(true)
    XCTAssertEqual(boolValue.toAny() as? Bool, true)

    let numberValue = StructHandler.ValueValue.numberValue(42.0)
    XCTAssertEqual(numberValue.toAny() as? Double, 42.0)

    let listValue = StructHandler.ValueValue.listValue([.stringValue("a"), .numberValue(1)])
    let list = listValue.toAny() as? [Any]
    XCTAssertEqual(list?.count, 2)
    XCTAssertEqual(list?[0] as? String, "a")
    XCTAssertEqual(list?[1] as? Double, 1.0)
  }

  func testValueValueDescription() {
    XCTAssertEqual(StructHandler.ValueValue.nullValue.description, "null")
    XCTAssertEqual(StructHandler.ValueValue.stringValue("hello").description, "\"hello\"")
    XCTAssertEqual(StructHandler.ValueValue.boolValue(true).description, "true")
    XCTAssertEqual(StructHandler.ValueValue.numberValue(42.0).description, "42.0")

    let listValue = StructHandler.ValueValue.listValue([.stringValue("a"), .numberValue(1)])
    XCTAssertEqual(listValue.description, "[\"a\", 1.0]")
  }

  func testValueValueUnsupportedType() {
    struct UnsupportedType {}
    let unsupported = UnsupportedType()

    XCTAssertThrowsError(try StructHandler.ValueValue(from: unsupported)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, _) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, WellKnownTypeNames.value)
    }
  }

  // MARK: - Handler Implementation Tests

  func testHandlerBasicProperties() {
    XCTAssertEqual(StructHandler.handledTypeName, "google.protobuf.Struct")
    XCTAssertEqual(StructHandler.supportPhase, .important)
  }

  func testCreateSpecializedFromMessage() throws {
    let structMessage = try createStructMessage(fields: [
      "name": "John",
      "age": 30,
      "active": true,
    ])

    let specialized = try StructHandler.createSpecialized(from: structMessage)

    guard let structValue = specialized as? StructHandler.StructValue else {
      XCTFail("Expected StructValue")
      return
    }

    XCTAssertEqual(structValue.fields.count, 3)
    XCTAssertEqual(structValue.getValue("name"), .stringValue("John"))
    XCTAssertEqual(structValue.getValue("age"), .numberValue(30.0))
    XCTAssertEqual(structValue.getValue("active"), .boolValue(true))
  }

  func testCreateSpecializedFromEmptyMessage() throws {
    let emptyMessage = try createStructMessage(fields: [:])

    let specialized = try StructHandler.createSpecialized(from: emptyMessage)

    guard let structValue = specialized as? StructHandler.StructValue else {
      XCTFail("Expected StructValue")
      return
    }

    XCTAssertTrue(structValue.fields.isEmpty)
  }

  func testCreateSpecializedFromInvalidMessage() throws {
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotStruct", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try StructHandler.createSpecialized(from: wrongMessage)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, _) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Struct")
    }
  }

  func testCreateDynamicFromSpecialized() throws {
    let structValue = try StructHandler.StructValue(from: [
      "name": "John",
      "age": 30,
      "active": true,
    ])

    let dynamicMessage = try StructHandler.createDynamic(from: structValue)

    XCTAssertEqual(dynamicMessage.descriptor.fullName, "google.protobuf.Struct")

    // Данные теперь хранятся как JSON в bytes поле
    let fieldsData = try dynamicMessage.get(forField: "fields") as! Data
    let fieldsObject = try JSONSerialization.jsonObject(with: fieldsData, options: [])
    let fields = fieldsObject as! [String: Any]

    XCTAssertEqual(fields["name"] as? String, "John")
    XCTAssertEqual(fields["age"] as? Double, 30.0)
    XCTAssertEqual(fields["active"] as? Bool, true)
  }

  func testCreateDynamicFromInvalidSpecialized() throws {
    let wrongSpecialized = "not a struct"

    XCTAssertThrowsError(try StructHandler.createDynamic(from: wrongSpecialized)) { error in
      guard case WellKnownTypeError.conversionFailed(let from, let to, _) = error else {
        XCTFail("Expected conversionFailed error")
        return
      }
      XCTAssertEqual(from, "String")
      XCTAssertEqual(to, "DynamicMessage")
    }
  }

  func testValidate() {
    let validStruct = StructHandler.StructValue()
    XCTAssertTrue(StructHandler.validate(validStruct))

    let invalidValue = "not a struct"
    XCTAssertFalse(StructHandler.validate(invalidValue))
  }

  // MARK: - Round-trip Tests

  func testRoundTripConversion() throws {
    let originalDict: [String: Any] = [
      "name": "John",
      "age": 30,
      "active": true,
      "score": 95.5,
      "metadata": [
        "created": "2023-01-01",
        "tags": ["user", "active"],
      ],
    ]

    // Dictionary -> StructValue -> DynamicMessage -> StructValue -> Dictionary
    let structValue1 = try StructHandler.StructValue(from: originalDict)
    let dynamicMessage = try StructHandler.createDynamic(from: structValue1)
    let structValue2 = try StructHandler.createSpecialized(from: dynamicMessage) as! StructHandler.StructValue
    let resultDict = structValue2.toDictionary()

    // Verify round-trip integrity
    XCTAssertEqual(resultDict["name"] as? String, "John")
    XCTAssertEqual(resultDict["age"] as? Double, 30.0)
    XCTAssertEqual(resultDict["active"] as? Bool, true)
    XCTAssertEqual(resultDict["score"] as? Double, 95.5)

    let metadata = resultDict["metadata"] as? [String: Any]
    XCTAssertEqual(metadata?["created"] as? String, "2023-01-01")
    let tags = metadata?["tags"] as? [Any]
    XCTAssertEqual(tags?.count, 2)
    XCTAssertEqual(tags?[0] as? String, "user")
    XCTAssertEqual(tags?[1] as? String, "active")
  }

  // MARK: - Registry Integration Tests

  func testRegistryIntegration() throws {
    let registry = WellKnownTypesRegistry.shared

    // Verify StructHandler is registered
    let registeredTypes = registry.getRegisteredTypes()
    XCTAssertTrue(registeredTypes.contains(WellKnownTypeNames.structType))

    let handler = registry.getHandler(for: WellKnownTypeNames.structType)
    XCTAssertNotNil(handler)

    // Test registry operations
    let structValue = try StructHandler.StructValue(from: ["test": "value"])
    let dynamicMessage = try registry.createDynamic(from: structValue, typeName: WellKnownTypeNames.structType)
    let specialized = try registry.createSpecialized(from: dynamicMessage, typeName: WellKnownTypeNames.structType)

    guard let resultStruct = specialized as? StructHandler.StructValue else {
      XCTFail("Expected StructValue")
      return
    }

    XCTAssertEqual(resultStruct.getValue("test"), .stringValue("value"))
  }

  // MARK: - Convenience Extensions Tests

  func testDictionaryExtensions() throws {
    let dictionary = ["name": "John", "age": 30] as [String: Any]
    let structValue = try dictionary.toStructValue()

    XCTAssertEqual(structValue.getValue("name"), .stringValue("John"))
    XCTAssertEqual(structValue.getValue("age"), .numberValue(30.0))
  }

  func testDynamicMessageExtensions() throws {
    // Test structMessage creation
    let fields = ["name": "John", "age": 30] as [String: Any]
    let message = try DynamicMessage.structMessage(from: fields)

    XCTAssertEqual(message.descriptor.fullName, WellKnownTypeNames.structType)

    // Test toFieldsDictionary
    let resultFields = try message.toFieldsDictionary()
    XCTAssertEqual(resultFields["name"] as? String, "John")
    XCTAssertEqual(resultFields["age"] as? Double, 30.0)

    // Test with non-struct message
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotStruct", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try wrongMessage.toFieldsDictionary()) { error in
      guard case WellKnownTypeError.invalidData(_, _) = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  // MARK: - Complex Nested Structure Tests

  func testComplexNestedStructure() throws {
    let complexDict: [String: Any] = [
      "user": [
        "name": "John Doe",
        "profile": [
          "age": 30,
          "preferences": [
            "theme": "dark",
            "notifications": true,
            "languages": ["en", "fr", "es"],
          ],
        ],
        "scores": [95.5, 87.2, 92.8],
      ],
      "metadata": [
        "version": 1,
        "created": "2023-01-01T10:00:00Z",
      ],
    ]

    let structValue = try StructHandler.StructValue(from: complexDict)

    // Verify deep nesting
    if case .structValue(let user) = structValue.getValue("user") {
      XCTAssertEqual(user.getValue("name"), .stringValue("John Doe"))

      if case .structValue(let profile) = user.getValue("profile") {
        XCTAssertEqual(profile.getValue("age"), .numberValue(30))

        if case .structValue(let preferences) = profile.getValue("preferences") {
          XCTAssertEqual(preferences.getValue("theme"), .stringValue("dark"))
          XCTAssertEqual(preferences.getValue("notifications"), .boolValue(true))

          if case .listValue(let languages) = preferences.getValue("languages") {
            XCTAssertEqual(languages.count, 3)
            XCTAssertEqual(languages[0], .stringValue("en"))
            XCTAssertEqual(languages[1], .stringValue("fr"))
            XCTAssertEqual(languages[2], .stringValue("es"))
          }
          else {
            XCTFail("Expected list value for languages")
          }
        }
        else {
          XCTFail("Expected struct value for preferences")
        }
      }
      else {
        XCTFail("Expected struct value for profile")
      }

      if case .listValue(let scores) = user.getValue("scores") {
        XCTAssertEqual(scores.count, 3)
        XCTAssertEqual(scores[0], .numberValue(95.5))
        XCTAssertEqual(scores[1], .numberValue(87.2))
        XCTAssertEqual(scores[2], .numberValue(92.8))
      }
      else {
        XCTFail("Expected list value for scores")
      }
    }
    else {
      XCTFail("Expected struct value for user")
    }

    // Test round-trip with complex structure
    let dynamicMessage = try StructHandler.createDynamic(from: structValue)
    let reconstructed = try StructHandler.createSpecialized(from: dynamicMessage) as! StructHandler.StructValue
    let resultDict = reconstructed.toDictionary()

    // Verify structure is preserved
    let resultUser = resultDict["user"] as? [String: Any]
    XCTAssertNotNil(resultUser)
    XCTAssertEqual(resultUser?["name"] as? String, "John Doe")
  }

  // MARK: - Helper Methods

  private func createStructMessage(fields: [String: Any]) throws -> DynamicMessage {
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/struct.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "Struct",
      parent: fileDescriptor
    )

    // Соответствует реализации StructHandler - bytes поле для JSON данных
    let fieldsField = FieldDescriptor(
      name: "fields",
      number: 1,
      type: .bytes  // JSON сериализованные данные
    )
    messageDescriptor.addField(fieldsField)

    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    if !fields.isEmpty {
      // Сериализуем поля в JSON как Data
      let jsonData = try JSONSerialization.data(withJSONObject: fields, options: [])
      try message.set(jsonData, forField: "fields")
    }

    return message
  }
}
