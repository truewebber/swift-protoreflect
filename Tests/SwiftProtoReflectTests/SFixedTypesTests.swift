import XCTest

@testable import SwiftProtoReflect

class SFixedTypesTests: XCTestCase {

  func testSFixed32WithIntValue() throws {
    // Создаем дескриптор сообщения с sfixed32 полем
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "SFixed32Message",
      fields: [
        ProtoFieldDescriptor(name: "sfixed32_field", number: 1, type: .sfixed32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Создаем сообщение и устанавливаем значение как intValue
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "sfixed32_field", value: .intValue(-42))

    // Сериализуем сообщение
    let data = try ProtoWireFormat.marshal(message: message)
    XCTAssertFalse(data.isEmpty, "Сериализованные данные не должны быть пустыми")

    // Десериализуем сообщение
    let deserializedMessage = try XCTUnwrap(
      ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage,
      "Не удалось десериализовать сообщение"
    )

    // Проверяем, что поле существует и имеет правильное значение
    XCTAssertTrue(deserializedMessage.has(fieldName: "sfixed32_field"), "sfixed32_field должно существовать")

    let value = try XCTUnwrap(deserializedMessage.get(fieldName: "sfixed32_field"), "sfixed32_field не должно быть nil")
    XCTAssertNotNil(value.getInt(), "sfixed32_field должно быть intValue")
    XCTAssertEqual(value.getInt(), -42, "sfixed32_field должно быть равно -42")
  }

  func testSFixed64WithIntValue() throws {
    // Создаем дескриптор сообщения с sfixed64 полем
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "SFixed64Message",
      fields: [
        ProtoFieldDescriptor(name: "sfixed64_field", number: 1, type: .sfixed64, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Создаем сообщение и устанавливаем значение как intValue
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "sfixed64_field", value: .intValue(-42))

    // Сериализуем сообщение
    let data = try ProtoWireFormat.marshal(message: message)
    XCTAssertFalse(data.isEmpty, "Сериализованные данные не должны быть пустыми")

    // Десериализуем сообщение
    let deserializedMessage = try XCTUnwrap(
      ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage,
      "Не удалось десериализовать сообщение"
    )

    // Проверяем, что поле существует и имеет правильное значение
    XCTAssertTrue(deserializedMessage.has(fieldName: "sfixed64_field"), "sfixed64_field должно существовать")

    let value = try XCTUnwrap(deserializedMessage.get(fieldName: "sfixed64_field"), "sfixed64_field не должно быть nil")
    XCTAssertNotNil(value.getInt(), "sfixed64_field должно быть intValue")
    XCTAssertEqual(value.getInt(), -42, "sfixed64_field должно быть равно -42")
  }

  func testRepeatedSFixedTypes() throws {
    // Создаем дескриптор сообщения с повторяющимися sfixed32 и sfixed64 полями
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "RepeatedSFixedMessage",
      fields: [
        ProtoFieldDescriptor(name: "repeated_sfixed32", number: 1, type: .sfixed32, isRepeated: true, isMap: false),
        ProtoFieldDescriptor(name: "repeated_sfixed64", number: 2, type: .sfixed64, isRepeated: true, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Создаем сообщение и устанавливаем значения
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Добавляем значения для repeated_sfixed32
    let sfixed32Values: [Int] = [-42, -1, 0, 1, 42, Int(Int32.min), Int(Int32.max)]
    message.set(
      fieldName: "repeated_sfixed32",
      value: .repeatedValue(sfixed32Values.map { .intValue($0) })
    )

    // Добавляем значения для repeated_sfixed64
    let sfixed64Values: [Int] = [-42, -1, 0, 1, 42, Int.min, Int.max]
    message.set(
      fieldName: "repeated_sfixed64",
      value: .repeatedValue(sfixed64Values.map { .intValue($0) })
    )

    // Сериализуем сообщение
    let data = try ProtoWireFormat.marshal(message: message)
    XCTAssertFalse(data.isEmpty, "Сериализованные данные не должны быть пустыми")

    // Десериализуем сообщение с включенной валидацией
    let options = SerializationOptions()
    // options.validateFields = false  // Уберем отключение валидации

    let deserializedMessage = try XCTUnwrap(
      ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor, options: options)
        as? ProtoDynamicMessage,
      "Не удалось десериализовать сообщение"
    )

    // Проверяем repeated_sfixed32
    let repeatedSFixed32 = try XCTUnwrap(
      deserializedMessage.get(fieldName: "repeated_sfixed32")?.getRepeated(),
      "repeated_sfixed32 должно быть repeatedValue"
    )
    XCTAssertEqual(repeatedSFixed32.count, sfixed32Values.count, "Количество элементов должно совпадать")

    for (index, value) in repeatedSFixed32.enumerated() {
      XCTAssertNotNil(value.getInt(), "Элемент должен быть intValue")
      XCTAssertEqual(value.getInt(), sfixed32Values[index], "Значение должно совпадать")
    }

    // Проверяем repeated_sfixed64
    let repeatedSFixed64 = try XCTUnwrap(
      deserializedMessage.get(fieldName: "repeated_sfixed64")?.getRepeated(),
      "repeated_sfixed64 должно быть repeatedValue"
    )
    XCTAssertEqual(repeatedSFixed64.count, sfixed64Values.count, "Количество элементов должно совпадать")

    for (index, value) in repeatedSFixed64.enumerated() {
      XCTAssertNotNil(value.getInt(), "Элемент должен быть intValue")
      XCTAssertEqual(value.getInt(), sfixed64Values[index], "Значение должно совпадать")
    }
  }

  func testMixedTypesMessage() throws {
    // Создаем дескриптор сообщения с разными типами полей
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "MixedTypesMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sfixed32_field", number: 2, type: .sfixed32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 3, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sfixed64_field", number: 4, type: .sfixed64, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Создаем сообщение и устанавливаем значения
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "int32_field", value: .intValue(42))
    message.set(fieldName: "sfixed32_field", value: .intValue(-42))
    message.set(fieldName: "string_field", value: .stringValue("Hello, world!"))
    message.set(fieldName: "sfixed64_field", value: .intValue(-9_223_372_036_854_775_807))  // close to Int64.min

    // Сериализуем сообщение
    let data = try ProtoWireFormat.marshal(message: message)
    XCTAssertFalse(data.isEmpty, "Сериализованные данные не должны быть пустыми")

    // Десериализуем сообщение
    let deserializedMessage = try XCTUnwrap(
      ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage,
      "Не удалось десериализовать сообщение"
    )

    // Проверяем поля
    XCTAssertEqual(deserializedMessage.get(fieldName: "int32_field")?.getInt(), 42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "sfixed32_field")?.getInt(), -42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "string_field")?.getString(), "Hello, world!")
    XCTAssertEqual(deserializedMessage.get(fieldName: "sfixed64_field")?.getInt(), -9_223_372_036_854_775_807)
  }
}
