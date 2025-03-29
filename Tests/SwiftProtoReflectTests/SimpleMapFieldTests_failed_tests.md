# SimpleMapFieldTests - Неуспешные тесты

## testManualMapFieldSerialization
### Сравнение с protoc
- Тест не проверяет все возможные типы ключей и значений для map fields
- Не проверяет корректность wire format для разных типов map entries
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Код теста, который требует доработки:
```swift
func testManualMapFieldSerialization() {
    // Create field descriptors for the map entry
    let keyFieldDescriptor = ProtoFieldDescriptor(
      name: "key",
      number: 1,
      type: .string,
      isRepeated: false,
      isMap: false
    )

    let valueFieldDescriptor = ProtoFieldDescriptor(
      name: "value",
      number: 2,
      type: .string,
      isRepeated: false,
      isMap: false
    )

    // Create a message descriptor for the map entry
    let entryDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage.StringMapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Create a field descriptor for a map field
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "string_map",
      number: 1,
      type: .message(entryDescriptor),
      isRepeated: true,
      isMap: true,
      messageType: entryDescriptor
    )

    // Create a message descriptor with the map field
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [mapFieldDescriptor],
      enums: [],
      nestedMessages: [entryDescriptor]
    )

    // Create a dynamic message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Create a map with entries
    var mapEntries: [String: ProtoValue] = [:]
    mapEntries["key1"] = .stringValue("value1")
    mapEntries["key2"] = .stringValue("value2")

    // Set the map field using mapValue
    message.set(field: mapFieldDescriptor, value: .mapValue(mapEntries))

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message with map entries")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with map entries")
      return
    }

    // The deserialized message should have a map field
    let mapValue = deserializedMessage.get(field: mapFieldDescriptor)
    XCTAssertNotNil(mapValue, "Map field should be present in unmarshalled message")

    if let mapValue = mapValue {
      // Check if it was deserialized as a map
      if case .mapValue(let entries) = mapValue {
        XCTAssertEqual(entries.count, 2, "Map should have 2 entries")
        XCTAssertEqual(entries["key1"]?.getString(), "value1", "Value for key 'key1' should be 'value1'")
        XCTAssertEqual(entries["key2"]?.getString(), "value2", "Value for key 'key2' should be 'value2'")
      }
      // Or as a repeated field (which is also valid)
      else if case .repeatedValue(let repeatedEntries) = mapValue {
        XCTAssertEqual(repeatedEntries.count, 2, "Should have 2 entries")

        // Extract keys and values from the repeated entries
        var extractedMap: [String: String] = [:]
        for entry in repeatedEntries {
          if case .messageValue(let entryMsg) = entry,
            let key = entryMsg.get(field: keyFieldDescriptor)?.getString(),
            let value = entryMsg.get(field: valueFieldDescriptor)?.getString()
          {
            extractedMap[key] = value
          }
        }

        XCTAssertEqual(extractedMap.count, 2, "Should have 2 key-value pairs")
        XCTAssertEqual(extractedMap["key1"], "value1", "Value for key 'key1' should be 'value1'")
        XCTAssertEqual(extractedMap["key2"], "value2", "Value for key 'key2' should be 'value2'")
      }
      else {
        XCTFail("Field value should be a map value or repeated value, but got \(mapValue)")
      }
    }
}
```

### Сравнение со спецификацией
- Не проверяет все типы ключей и значений, поддерживаемые protobuf для map fields
- Не проверяет корректность wire format для разных типов map entries
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Рекомендации по исправлению:
  1. Добавить тесты для всех поддерживаемых типов ключей (string, int32, int64, uint32, uint64, bool)
  2. Добавить тесты для всех поддерживаемых типов значений (string, int32, int64, uint32, uint64, bool, message, enum)
  3. Добавить проверку wire format для каждого типа map entry
  4. Добавить тесты для edge cases (пустые значения, максимальные значения для числовых типов)

## Отсутствующие тесты
### testMapFieldWithDifferentKeyTypes
- Описание: Тест для проверки map fields с разными типами ключей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода теста:
```swift
func testMapFieldWithDifferentKeyTypes() {
    // Test with string key
    let stringKeyDescriptor = ProtoFieldDescriptor(
        name: "key",
        number: 1,
        type: .string,
        isRepeated: false,
        isMap: false
    )
    
    // Test with int32 key
    let int32KeyDescriptor = ProtoFieldDescriptor(
        name: "key",
        number: 1,
        type: .int32,
        isRepeated: false,
        isMap: false
    )
    
    // Test with bool key
    let boolKeyDescriptor = ProtoFieldDescriptor(
        name: "key",
        number: 1,
        type: .bool,
        isRepeated: false,
        isMap: false
    )
    
    // Create value descriptor
    let valueDescriptor = ProtoFieldDescriptor(
        name: "value",
        number: 2,
        type: .string,
        isRepeated: false,
        isMap: false
    )
    
    // Test each key type
    let keyTypes = [
        ("string", stringKeyDescriptor),
        ("int32", int32KeyDescriptor),
        ("bool", boolKeyDescriptor)
    ]
    
    for (keyType, keyDescriptor) in keyTypes {
        let entryDescriptor = ProtoMessageDescriptor(
            fullName: "TestMessage.\(keyType.capitalized)MapEntry",
            fields: [keyDescriptor, valueDescriptor],
            enums: [],
            nestedMessages: []
        )
        
        let mapFieldDescriptor = ProtoFieldDescriptor(
            name: "\(keyType)_map",
            number: 1,
            type: .message(entryDescriptor),
            isRepeated: true,
            isMap: true,
            messageType: entryDescriptor
        )
        
        let messageDescriptor = ProtoMessageDescriptor(
            fullName: "TestMessage",
            fields: [mapFieldDescriptor],
            enums: [],
            nestedMessages: [entryDescriptor]
        )
        
        let message = ProtoDynamicMessage(descriptor: messageDescriptor)
        
        // Create test entries based on key type
        var mapEntries: [ProtoValue: ProtoValue] = [:]
        switch keyType {
        case "string":
            mapEntries[.stringValue("key1")] = .stringValue("value1")
        case "int32":
            mapEntries[.int32Value(1)] = .stringValue("value1")
        case "bool":
            mapEntries[.boolValue(true)] = .stringValue("value1")
        default:
            break
        }
        
        // Set and verify map field
        let setResult = message.set(field: mapFieldDescriptor, value: .mapValue(mapEntries))
        XCTAssertTrue(setResult, "Setting \(keyType) map field should succeed")
        
        let mapValue = message.get(field: mapFieldDescriptor)
        XCTAssertNotNil(mapValue, "\(keyType) map field value should not be nil")
        
        if case .mapValue(let entries)? = mapValue {
            XCTAssertEqual(entries.count, 1, "\(keyType) map should have 1 entry")
            // Verify value based on key type
            switch keyType {
            case "string":
                XCTAssertEqual(entries[.stringValue("key1")]?.getString(), "value1")
            case "int32":
                XCTAssertEqual(entries[.int32Value(1)]?.getString(), "value1")
            case "bool":
                XCTAssertEqual(entries[.boolValue(true)]?.getString(), "value1")
            default:
                break
            }
        }
    }
}
```

### testMapFieldWithDifferentValueTypes
- Описание: Тест для проверки map fields с разными типами значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода теста:
```swift
func testMapFieldWithDifferentValueTypes() {
    // Create key descriptor
    let keyDescriptor = ProtoFieldDescriptor(
        name: "key",
        number: 1,
        type: .string,
        isRepeated: false,
        isMap: false
    )
    
    // Test different value types
    let valueTypes = [
        ("string", ProtoFieldType.string),
        ("int32", ProtoFieldType.int32),
        ("int64", ProtoFieldType.int64),
        ("uint32", ProtoFieldType.uint32),
        ("uint64", ProtoFieldType.uint64),
        ("bool", ProtoFieldType.bool)
    ]
    
    for (valueType, protoType) in valueTypes {
        let valueDescriptor = ProtoFieldDescriptor(
            name: "value",
            number: 2,
            type: protoType,
            isRepeated: false,
            isMap: false
        )
        
        let entryDescriptor = ProtoMessageDescriptor(
            fullName: "TestMessage.String\(valueType.capitalized)MapEntry",
            fields: [keyDescriptor, valueDescriptor],
            enums: [],
            nestedMessages: []
        )
        
        let mapFieldDescriptor = ProtoFieldDescriptor(
            name: "string_\(valueType)_map",
            number: 1,
            type: .message(entryDescriptor),
            isRepeated: true,
            isMap: true,
            messageType: entryDescriptor
        )
        
        let messageDescriptor = ProtoMessageDescriptor(
            fullName: "TestMessage",
            fields: [mapFieldDescriptor],
            enums: [],
            nestedMessages: [entryDescriptor]
        )
        
        let message = ProtoDynamicMessage(descriptor: messageDescriptor)
        
        // Create test entries based on value type
        var mapEntries: [ProtoValue: ProtoValue] = [:]
        let key = ProtoValue.stringValue("key1")
        
        switch valueType {
        case "string":
            mapEntries[key] = .stringValue("value1")
        case "int32":
            mapEntries[key] = .int32Value(1)
        case "int64":
            mapEntries[key] = .int64Value(1)
        case "uint32":
            mapEntries[key] = .uint32Value(1)
        case "uint64":
            mapEntries[key] = .uint64Value(1)
        case "bool":
            mapEntries[key] = .boolValue(true)
        default:
            break
        }
        
        // Set and verify map field
        let setResult = message.set(field: mapFieldDescriptor, value: .mapValue(mapEntries))
        XCTAssertTrue(setResult, "Setting string-\(valueType) map field should succeed")
        
        let mapValue = message.get(field: mapFieldDescriptor)
        XCTAssertNotNil(mapValue, "string-\(valueType) map field value should not be nil")
        
        if case .mapValue(let entries)? = mapValue {
            XCTAssertEqual(entries.count, 1, "string-\(valueType) map should have 1 entry")
            // Verify value based on value type
            switch valueType {
            case "string":
                XCTAssertEqual(entries[key]?.getString(), "value1")
            case "int32":
                XCTAssertEqual(entries[key]?.getInt32(), 1)
            case "int64":
                XCTAssertEqual(entries[key]?.getInt64(), 1)
            case "uint32":
                XCTAssertEqual(entries[key]?.getUInt32(), 1)
            case "uint64":
                XCTAssertEqual(entries[key]?.getUInt64(), 1)
            case "bool":
                XCTAssertEqual(entries[key]?.getBool(), true)
            default:
                break
            }
        }
    }
}
```

### testMapFieldEdgeCases
- Описание: Тест для проверки edge cases в map fields
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода теста:
```swift
func testMapFieldEdgeCases() {
    // Create descriptors
    let keyDescriptor = ProtoFieldDescriptor(
        name: "key",
        number: 1,
        type: .string,
        isRepeated: false,
        isMap: false
    )
    
    let valueDescriptor = ProtoFieldDescriptor(
        name: "value",
        number: 2,
        type: .string,
        isRepeated: false,
        isMap: false
    )
    
    let entryDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage.StringMapEntry",
        fields: [keyDescriptor, valueDescriptor],
        enums: [],
        nestedMessages: []
    )
    
    let mapFieldDescriptor = ProtoFieldDescriptor(
        name: "string_map",
        number: 1,
        type: .message(entryDescriptor),
        isRepeated: true,
        isMap: true,
        messageType: entryDescriptor
    )
    
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [mapFieldDescriptor],
        enums: [],
        nestedMessages: [entryDescriptor]
    )
    
    // Test empty map
    let emptyMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    let emptyMap: [String: ProtoValue] = [:]
    let emptySetResult = emptyMessage.set(field: mapFieldDescriptor, value: .mapValue(emptyMap))
    XCTAssertTrue(emptySetResult, "Setting empty map should succeed")
    
    let emptyMapValue = emptyMessage.get(field: mapFieldDescriptor)
    XCTAssertNotNil(emptyMapValue, "Empty map field value should not be nil")
    if case .mapValue(let entries)? = emptyMapValue {
        XCTAssertEqual(entries.count, 0, "Empty map should have 0 entries")
    }
    
    // Test map with empty string key
    let emptyKeyMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    var emptyKeyMap: [String: ProtoValue] = [:]
    emptyKeyMap[""] = .stringValue("value1")
    let emptyKeySetResult = emptyKeyMessage.set(field: mapFieldDescriptor, value: .mapValue(emptyKeyMap))
    XCTAssertTrue(emptyKeySetResult, "Setting map with empty string key should succeed")
    
    let emptyKeyMapValue = emptyKeyMessage.get(field: mapFieldDescriptor)
    XCTAssertNotNil(emptyKeyMapValue, "Map with empty string key value should not be nil")
    if case .mapValue(let entries)? = emptyKeyMapValue {
        XCTAssertEqual(entries.count, 1, "Map with empty string key should have 1 entry")
        XCTAssertEqual(entries[""]?.getString(), "value1", "Value for empty string key should be 'value1'")
    }
    
    // Test map with empty string value
    let emptyValueMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    var emptyValueMap: [String: ProtoValue] = [:]
    emptyValueMap["key1"] = .stringValue("")
    let emptyValueSetResult = emptyValueMessage.set(field: mapFieldDescriptor, value: .mapValue(emptyValueMap))
    XCTAssertTrue(emptyValueSetResult, "Setting map with empty string value should succeed")
    
    let emptyValueMapValue = emptyValueMessage.get(field: mapFieldDescriptor)
    XCTAssertNotNil(emptyValueMapValue, "Map with empty string value should not be nil")
    if case .mapValue(let entries)? = emptyValueMapValue {
        XCTAssertEqual(entries.count, 1, "Map with empty string value should have 1 entry")
        XCTAssertEqual(entries["key1"]?.getString(), "", "Value for key 'key1' should be empty string")
    }
    
    // Test map with maximum number of entries
    let maxEntriesMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    var maxEntriesMap: [String: ProtoValue] = [:]
    for i in 0..<1000 { // Test with 1000 entries
        maxEntriesMap["key\(i)"] = .stringValue("value\(i)")
    }
    let maxEntriesSetResult = maxEntriesMessage.set(field: mapFieldDescriptor, value: .mapValue(maxEntriesMap))
    XCTAssertTrue(maxEntriesSetResult, "Setting map with maximum number of entries should succeed")
    
    let maxEntriesMapValue = maxEntriesMessage.get(field: mapFieldDescriptor)
    XCTAssertNotNil(maxEntriesMapValue, "Map with maximum number of entries should not be nil")
    if case .mapValue(let entries)? = maxEntriesMapValue {
        XCTAssertEqual(entries.count, 1000, "Map with maximum number of entries should have 1000 entries")
        // Verify some entries
        XCTAssertEqual(entries["key0"]?.getString(), "value0", "First entry should be preserved")
        XCTAssertEqual(entries["key999"]?.getString(), "value999", "Last entry should be preserved")
    }
}
``` 