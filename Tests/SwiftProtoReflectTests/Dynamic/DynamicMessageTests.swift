//
// DynamicMessageTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-23
//

import XCTest

@testable import SwiftProtoReflect

final class DynamicMessageTests: XCTestCase {
  // MARK: - Properties

  // Тестовые дескрипторы
  private var fileDescriptor: FileDescriptor!
  private var personMessage: MessageDescriptor!
  private var addressMessage: MessageDescriptor!
  private var enumDescriptor: EnumDescriptor!

  // MARK: - Setup

  override func setUp() {
    super.setUp()

    // Создаем тестовый файловый дескриптор
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")

    // Создаем дескриптор перечисления PhoneType
    enumDescriptor = EnumDescriptor(name: "PhoneType", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "MOBILE", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "HOME", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "WORK", number: 2))

    // Добавляем перечисление в файл
    fileDescriptor.addEnum(enumDescriptor)

    // Создаем дескриптор сообщения Address
    addressMessage = MessageDescriptor(name: "Address", parent: fileDescriptor)
    addressMessage.addField(
      FieldDescriptor(
        name: "street",
        number: 1,
        type: .string
      )
    )
    addressMessage.addField(
      FieldDescriptor(
        name: "city",
        number: 2,
        type: .string
      )
    )
    addressMessage.addField(
      FieldDescriptor(
        name: "zip_code",
        number: 3,
        type: .string
      )
    )

    // Добавляем сообщение Address в файл
    fileDescriptor.addMessage(addressMessage)

    // Создаем дескриптор сообщения Person
    personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)

    // Добавляем простые поля
    personMessage.addField(
      FieldDescriptor(
        name: "name",
        number: 1,
        type: .string
      )
    )
    personMessage.addField(
      FieldDescriptor(
        name: "id",
        number: 2,
        type: .int32
      )
    )
    personMessage.addField(
      FieldDescriptor(
        name: "email",
        number: 3,
        type: .string,
        isOptional: true
      )
    )

    // Добавляем поле для вложенного сообщения
    personMessage.addField(
      FieldDescriptor(
        name: "address",
        number: 4,
        type: .message,
        typeName: "test.Address"
      )
    )

    // Добавляем поле enum
    personMessage.addField(
      FieldDescriptor(
        name: "phone_type",
        number: 5,
        type: .enum,
        typeName: "test.PhoneType"
      )
    )

    // Добавляем repeated поле
    personMessage.addField(
      FieldDescriptor(
        name: "phone_numbers",
        number: 6,
        type: .string,
        isRepeated: true
      )
    )

    // Добавляем map поле
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    personMessage.addField(
      FieldDescriptor(
        name: "attributes",
        number: 7,
        type: .message,
        typeName: "map<string, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )

    // Добавляем oneof поля
    personMessage.addField(
      FieldDescriptor(
        name: "work_email",
        number: 8,
        type: .string,
        oneofIndex: 1
      )
    )
    personMessage.addField(
      FieldDescriptor(
        name: "personal_email",
        number: 9,
        type: .string,
        oneofIndex: 1
      )
    )

    // Добавляем сообщение Person в файл
    fileDescriptor.addMessage(personMessage)
  }

  override func tearDown() {
    fileDescriptor = nil
    personMessage = nil
    addressMessage = nil
    enumDescriptor = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testInitialization() {
    // Создаем экземпляр DynamicMessage
    let message = DynamicMessage(descriptor: personMessage)

    // Проверяем, что дескриптор установлен правильно
    XCTAssertEqual(message.descriptor.name, "Person")
    XCTAssertEqual(message.descriptor.fullName, "test.Person")

    // Проверяем, что значения пусты
    XCTAssertFalse(try message.hasValue(forField: "name"))
    XCTAssertNil(try message.get(forField: "name"))
  }

  // MARK: - Field Access Tests

  func testSetAndGetScalarFields() {
    var message = DynamicMessage(descriptor: personMessage)

    // Устанавливаем и получаем строковое поле
    do {
      try message.set("John Doe", forField: "name")
      XCTAssertTrue(try message.hasValue(forField: "name"))
      XCTAssertEqual(try message.get(forField: "name") as? String, "John Doe")

      // Устанавливаем и получаем числовое поле
      try message.set(Int32(123), forField: "id")
      XCTAssertTrue(try message.hasValue(forField: "id"))
      XCTAssertEqual(try message.get(forField: "id") as? Int32, 123)

      // Используем номер поля вместо имени
      try message.set("john.doe@example.com", forField: 3)  // email
      XCTAssertTrue(try message.hasValue(forField: 3))
      XCTAssertEqual(try message.get(forField: 3) as? String, "john.doe@example.com")
    }
    catch {
      XCTFail("Не должно быть исключений при установке/получении полей: \(error)")
    }
  }

  func testNestedMessageField() {
    var message = DynamicMessage(descriptor: personMessage)
    var addressMsg = DynamicMessage(descriptor: addressMessage)

    do {
      // Заполняем адрес
      try addressMsg.set("123 Main St", forField: "street")
      try addressMsg.set("Anytown", forField: "city")
      try addressMsg.set("12345", forField: "zip_code")

      // Устанавливаем адрес в Person
      try message.set(addressMsg, forField: "address")

      // Проверяем, что адрес установлен
      XCTAssertTrue(try message.hasValue(forField: "address"))

      // Получаем и проверяем адрес
      let retrievedAddress = try message.get(forField: "address") as? DynamicMessage
      XCTAssertNotNil(retrievedAddress)
      XCTAssertEqual(try retrievedAddress?.get(forField: "street") as? String, "123 Main St")
      XCTAssertEqual(try retrievedAddress?.get(forField: "city") as? String, "Anytown")
      XCTAssertEqual(try retrievedAddress?.get(forField: "zip_code") as? String, "12345")
    }
    catch {
      XCTFail("Не должно быть исключений при работе с вложенными сообщениями: \(error)")
    }
  }

  func testEnumField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Устанавливаем enum по номеру
      try message.set(Int32(1), forField: "phone_type")  // HOME
      XCTAssertTrue(try message.hasValue(forField: "phone_type"))
      XCTAssertEqual(try message.get(forField: "phone_type") as? Int32, 1)

      // Устанавливаем enum по имени
      try message.set("WORK", forField: "phone_type")
      XCTAssertTrue(try message.hasValue(forField: "phone_type"))
      XCTAssertEqual(try message.get(forField: "phone_type") as? String, "WORK")
    }
    catch {
      XCTFail("Не должно быть исключений при работе с enum полями: \(error)")
    }
  }

  func testRepeatedField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Добавляем телефонные номера по одному
      try message.addRepeatedValue("+1-555-1234", forField: "phone_numbers")
      try message.addRepeatedValue("+1-555-5678", forField: "phone_numbers")

      // Проверяем, что поле установлено
      XCTAssertTrue(try message.hasValue(forField: "phone_numbers"))

      // Получаем массив и проверяем его содержимое
      let phoneNumbers = try message.get(forField: "phone_numbers") as? [String]
      XCTAssertNotNil(phoneNumbers)
      XCTAssertEqual(phoneNumbers?.count, 2)
      XCTAssertEqual(phoneNumbers?[0], "+1-555-1234")
      XCTAssertEqual(phoneNumbers?[1], "+1-555-5678")

      // Устанавливаем массив целиком
      let newNumbers = ["+1-555-9876", "+1-555-4321"]
      try message.set(newNumbers, forField: "phone_numbers")

      // Проверяем обновленный массив
      let updatedNumbers = try message.get(forField: "phone_numbers") as? [String]
      XCTAssertNotNil(updatedNumbers)
      XCTAssertEqual(updatedNumbers?.count, 2)
      XCTAssertEqual(updatedNumbers?[0], "+1-555-9876")
      XCTAssertEqual(updatedNumbers?[1], "+1-555-4321")
    }
    catch {
      XCTFail("Не должно быть исключений при работе с repeated полями: \(error)")
    }
  }

  func testMapField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Добавляем записи в map по одной
      try message.setMapEntry("Developer", forKey: "role", inField: "attributes")
      try message.setMapEntry("John", forKey: "first_name", inField: "attributes")

      // Проверяем, что поле установлено
      XCTAssertTrue(try message.hasValue(forField: "attributes"))

      // Получаем map и проверяем его содержимое
      let attributes = try message.get(forField: "attributes") as? [String: String]
      XCTAssertNotNil(attributes)
      XCTAssertEqual(attributes?.count, 2)
      XCTAssertEqual(attributes?["role"], "Developer")
      XCTAssertEqual(attributes?["first_name"], "John")

      // Устанавливаем map целиком
      let newAttributes = ["department": "Engineering", "level": "Senior"]
      try message.set(newAttributes, forField: "attributes")

      // Проверяем обновленный map
      let updatedAttributes = try message.get(forField: "attributes") as? [String: String]
      XCTAssertNotNil(updatedAttributes)
      XCTAssertEqual(updatedAttributes?.count, 2)
      XCTAssertEqual(updatedAttributes?["department"], "Engineering")
      XCTAssertEqual(updatedAttributes?["level"], "Senior")
    }
    catch {
      XCTFail("Не должно быть исключений при работе с map полями: \(error)")
    }
  }

  func testOneofField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Устанавливаем первый oneof
      try message.set("work@example.com", forField: "work_email")
      XCTAssertTrue(try message.hasValue(forField: "work_email"))
      XCTAssertFalse(try message.hasValue(forField: "personal_email"))
      XCTAssertEqual(try message.get(forField: "work_email") as? String, "work@example.com")

      // Устанавливаем второй oneof - должен очистить первый
      try message.set("personal@example.com", forField: "personal_email")
      XCTAssertFalse(try message.hasValue(forField: "work_email"))
      XCTAssertTrue(try message.hasValue(forField: "personal_email"))
      XCTAssertEqual(try message.get(forField: "personal_email") as? String, "personal@example.com")

      // Очищаем oneof поле
      try message.clearField("personal_email")
      XCTAssertFalse(try message.hasValue(forField: "personal_email"))
      XCTAssertFalse(try message.hasValue(forField: "work_email"))
    }
    catch {
      XCTFail("Не должно быть исключений при работе с oneof полями: \(error)")
    }
  }

  func testClearField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Устанавливаем значения
      try message.set("John Doe", forField: "name")
      try message.set(Int32(123), forField: "id")

      // Проверяем, что значения установлены
      XCTAssertTrue(try message.hasValue(forField: "name"))
      XCTAssertTrue(try message.hasValue(forField: "id"))

      // Очищаем одно поле
      try message.clearField("name")

      // Проверяем результат
      XCTAssertFalse(try message.hasValue(forField: "name"))
      XCTAssertTrue(try message.hasValue(forField: "id"))

      // Устанавливаем значение снова
      try message.set("Jane Doe", forField: "name")
      XCTAssertTrue(try message.hasValue(forField: "name"))
      XCTAssertEqual(try message.get(forField: "name") as? String, "Jane Doe")
    }
    catch {
      XCTFail("Не должно быть исключений при очистке полей: \(error)")
    }
  }

  // MARK: - Type Validation Tests

  func testTypeValidation() {
    var message = DynamicMessage(descriptor: personMessage)

    // Проверяем ошибку при установке значения с неправильным типом
    XCTAssertThrowsError(try message.set(123, forField: "name")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }

      if case .typeMismatch(let fieldName, let expectedType, _) = dynamicError {
        XCTAssertEqual(fieldName, "name")
        XCTAssertEqual(expectedType, "String")
      }
      else {
        XCTFail("Ожидалась ошибка typeMismatch")
      }
    }

    // Проверяем ошибку при установке неправильного типа вложенного сообщения
    let wrongMessage = DynamicMessage(descriptor: personMessage)  // Person вместо Address
    XCTAssertThrowsError(try message.set(wrongMessage, forField: "address")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }

      if case .messageMismatch(let fieldName, let expectedType, let actualType) = dynamicError {
        XCTAssertEqual(fieldName, "address")
        XCTAssertEqual(expectedType, "test.Address")
        XCTAssertEqual(actualType, "test.Person")
      }
      else {
        XCTFail("Ожидалась ошибка messageMismatch")
      }
    }
  }

  func testNonExistentFieldAccess() {
    let message = DynamicMessage(descriptor: personMessage)

    // Проверяем ошибку при доступе к несуществующему полю по имени
    XCTAssertThrowsError(try message.get(forField: "non_existent")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }

      if case .fieldNotFound(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "non_existent")
      }
      else {
        XCTFail("Ожидалась ошибка fieldNotFound")
      }
    }

    // Проверяем ошибку при доступе к несуществующему полю по номеру
    XCTAssertThrowsError(try message.get(forField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }

      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      }
      else {
        XCTFail("Ожидалась ошибка fieldNotFoundByNumber")
      }
    }
  }

  // MARK: - Equatable Tests

  func testEquatable() {
    var message1 = DynamicMessage(descriptor: personMessage)
    var message2 = DynamicMessage(descriptor: personMessage)

    // Пустые сообщения должны быть равны
    XCTAssertEqual(message1, message2)

    do {
      // Добавляем одинаковые данные
      try message1.set("John Doe", forField: "name")
      try message2.set("John Doe", forField: "name")

      // Сообщения с одинаковыми данными должны быть равны
      XCTAssertEqual(message1, message2)

      // Изменяем одно поле в message2
      try message2.set("Jane Doe", forField: "name")

      // Сообщения с разными данными не должны быть равны
      XCTAssertNotEqual(message1, message2)

      // Устанавливаем одинаковые данные снова
      try message2.set("John Doe", forField: "name")
      XCTAssertEqual(message1, message2)

      // Добавляем дополнительное поле в message1
      try message1.set(Int32(123), forField: "id")

      // Сообщения должны отличаться, если у одного есть поле, а у другого нет
      XCTAssertNotEqual(message1, message2)

      // Добавляем то же поле в message2
      try message2.set(Int32(123), forField: "id")

      // Сообщения должны быть равны снова
      XCTAssertEqual(message1, message2)
    }
    catch {
      XCTFail("Не должно быть исключений при тестировании Equatable: \(error)")
    }
  }

  func testEquatableWithComplexFields() {
    var message1 = DynamicMessage(descriptor: personMessage)
    var message2 = DynamicMessage(descriptor: personMessage)

    do {
      // Настраиваем сложные поля
      var address1 = DynamicMessage(descriptor: addressMessage)
      try address1.set("123 Main St", forField: "street")
      try address1.set("Anytown", forField: "city")

      var address2 = DynamicMessage(descriptor: addressMessage)
      try address2.set("123 Main St", forField: "street")
      try address2.set("Anytown", forField: "city")

      // Устанавливаем адреса
      try message1.set(address1, forField: "address")
      try message2.set(address2, forField: "address")

      // Сообщения с одинаковыми вложенными сообщениями должны быть равны
      XCTAssertEqual(message1, message2)

      // Изменяем одно поле в address2
      try address2.set("456 Oak St", forField: "street")

      // Обновляем address в message2
      try message2.set(address2, forField: "address")

      // Сообщения с разными вложенными сообщениями не должны быть равны
      XCTAssertNotEqual(message1, message2)

      // Устанавливаем одинаковые repeated поля
      let phoneNumbers = ["+1-555-1234", "+1-555-5678"]
      try message1.set(phoneNumbers, forField: "phone_numbers")
      try message2.set(phoneNumbers, forField: "phone_numbers")

      // Сообщения все еще не должны быть равны из-за разных адресов
      XCTAssertNotEqual(message1, message2)

      // Исправляем адрес в message2
      address2 = DynamicMessage(descriptor: addressMessage)
      try address2.set("123 Main St", forField: "street")
      try address2.set("Anytown", forField: "city")
      try message2.set(address2, forField: "address")

      // Теперь сообщения должны быть равны
      XCTAssertEqual(message1, message2)
    }
    catch {
      XCTFail("Не должно быть исключений при тестировании Equatable для сложных полей: \(error)")
    }
  }

  // MARK: - Comprehensive Type Tests

  func testAllScalarTypes() {
    // Создаем сообщение со всеми скалярными типами полей
    var message = MessageDescriptor(name: "AllTypes", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "double_value", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "float_value", number: 2, type: .float))
    message.addField(FieldDescriptor(name: "int32_value", number: 3, type: .int32))
    message.addField(FieldDescriptor(name: "int64_value", number: 4, type: .int64))
    message.addField(FieldDescriptor(name: "uint32_value", number: 5, type: .uint32))
    message.addField(FieldDescriptor(name: "uint64_value", number: 6, type: .uint64))
    message.addField(FieldDescriptor(name: "sint32_value", number: 7, type: .sint32))
    message.addField(FieldDescriptor(name: "sint64_value", number: 8, type: .sint64))
    message.addField(FieldDescriptor(name: "fixed32_value", number: 9, type: .fixed32))
    message.addField(FieldDescriptor(name: "fixed64_value", number: 10, type: .fixed64))
    message.addField(FieldDescriptor(name: "sfixed32_value", number: 11, type: .sfixed32))
    message.addField(FieldDescriptor(name: "sfixed64_value", number: 12, type: .sfixed64))
    message.addField(FieldDescriptor(name: "bool_value", number: 13, type: .bool))
    message.addField(FieldDescriptor(name: "string_value", number: 14, type: .string))
    message.addField(FieldDescriptor(name: "bytes_value", number: 15, type: .bytes))

    fileDescriptor.addMessage(message)

    var dynamicMessage = DynamicMessage(descriptor: message)

    do {
      // Устанавливаем значения всех типов
      try dynamicMessage.set(Double(3.14159), forField: "double_value")
      try dynamicMessage.set(Float(2.71828), forField: "float_value")
      try dynamicMessage.set(Int32(42), forField: "int32_value")
      try dynamicMessage.set(Int64(1_234_567_890_123), forField: "int64_value")
      try dynamicMessage.set(UInt32(4_294_967_295), forField: "uint32_value")
      try dynamicMessage.set(UInt64(18_446_744_073_709_551_615), forField: "uint64_value")
      try dynamicMessage.set(Int32(-123), forField: "sint32_value")
      try dynamicMessage.set(Int64(-9_876_543_210), forField: "sint64_value")
      try dynamicMessage.set(UInt32(42), forField: "fixed32_value")
      try dynamicMessage.set(UInt64(42), forField: "fixed64_value")
      try dynamicMessage.set(Int32(-42), forField: "sfixed32_value")
      try dynamicMessage.set(Int64(-42), forField: "sfixed64_value")
      try dynamicMessage.set(true, forField: "bool_value")
      try dynamicMessage.set("Hello, world!", forField: "string_value")
      try dynamicMessage.set(Data("binary data".utf8), forField: "bytes_value")

      // Проверяем все установленные значения
      XCTAssertEqual(try dynamicMessage.get(forField: "double_value") as? Double, 3.14159)
      XCTAssertEqual(try dynamicMessage.get(forField: "float_value") as? Float, 2.71828)
      XCTAssertEqual(try dynamicMessage.get(forField: "int32_value") as? Int32, 42)
      XCTAssertEqual(try dynamicMessage.get(forField: "int64_value") as? Int64, 1_234_567_890_123)
      XCTAssertEqual(try dynamicMessage.get(forField: "uint32_value") as? UInt32, 4_294_967_295)
      XCTAssertEqual(try dynamicMessage.get(forField: "uint64_value") as? UInt64, 18_446_744_073_709_551_615)
      XCTAssertEqual(try dynamicMessage.get(forField: "sint32_value") as? Int32, -123)
      XCTAssertEqual(try dynamicMessage.get(forField: "sint64_value") as? Int64, -9_876_543_210)
      XCTAssertEqual(try dynamicMessage.get(forField: "fixed32_value") as? UInt32, 42)
      XCTAssertEqual(try dynamicMessage.get(forField: "fixed64_value") as? UInt64, 42)
      XCTAssertEqual(try dynamicMessage.get(forField: "sfixed32_value") as? Int32, -42)
      XCTAssertEqual(try dynamicMessage.get(forField: "sfixed64_value") as? Int64, -42)
      XCTAssertEqual(try dynamicMessage.get(forField: "bool_value") as? Bool, true)
      XCTAssertEqual(try dynamicMessage.get(forField: "string_value") as? String, "Hello, world!")
      XCTAssertEqual(try dynamicMessage.get(forField: "bytes_value") as? Data, Data("binary data".utf8))

      // Проверяем преобразование Int в Int32/Int64 типы
      try dynamicMessage.set(Int(42), forField: "int32_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "int32_value") as? Int32, 42)

      try dynamicMessage.set(Int(42), forField: "int64_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "int64_value") as? Int64, 42)

      // Проверяем преобразование UInt в UInt32/UInt64 типы
      try dynamicMessage.set(UInt(42), forField: "uint32_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "uint32_value") as? UInt32, 42)

      try dynamicMessage.set(UInt(42), forField: "uint64_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "uint64_value") as? UInt64, 42)

      // Проверяем NSNumber для числовых типов
      let doubleNumber = NSNumber(value: 3.14159)
      try dynamicMessage.set(doubleNumber, forField: "double_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "double_value") as? Double, 3.14159)

      let floatNumber = NSNumber(value: 2.71828 as Float)
      try dynamicMessage.set(floatNumber, forField: "float_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "float_value") as? Float, 2.71828)
    }
    catch {
      XCTFail("Не должно быть исключений при работе со скалярными типами: \(error)")
    }

    // Проверяем ошибки типов для разных полей
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "double_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "float_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "int32_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "int64_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "uint32_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "uint64_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a boolean", forField: "bool_value"))
    XCTAssertThrowsError(try dynamicMessage.set(42, forField: "string_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not binary data", forField: "bytes_value"))

    // Проверяем ошибки для значений Int32 выходящих за диапазон
    XCTAssertThrowsError(try dynamicMessage.set(Int(Int32.max) + 1, forField: "int32_value"))
    XCTAssertThrowsError(try dynamicMessage.set(Int(Int32.min) - 1, forField: "int32_value"))

    // Проверяем ошибки для значений UInt32 выходящих за диапазон
    XCTAssertThrowsError(try dynamicMessage.set(UInt(UInt32.max) + 1, forField: "uint32_value"))
  }

  func testComplexMapFieldOperations() {
    // Создаем сообщение с различными типами map полей
    var messageDesc = MessageDescriptor(name: "MapTypes", parent: fileDescriptor)

    // Map string -> string
    let stringMapKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let stringMapValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let stringMapEntryInfo = MapEntryInfo(keyFieldInfo: stringMapKeyInfo, valueFieldInfo: stringMapValueInfo)
    messageDesc.addField(
      FieldDescriptor(
        name: "string_map",
        number: 1,
        type: .message,
        typeName: "map<string, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: stringMapEntryInfo
      )
    )

    // Map int32 -> string
    let int32MapKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let int32MapValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let int32MapEntryInfo = MapEntryInfo(keyFieldInfo: int32MapKeyInfo, valueFieldInfo: int32MapValueInfo)
    messageDesc.addField(
      FieldDescriptor(
        name: "int32_map",
        number: 2,
        type: .message,
        typeName: "map<int32, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: int32MapEntryInfo
      )
    )

    // Map bool -> int32
    let boolMapKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .bool)
    let boolMapValueInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let boolMapEntryInfo = MapEntryInfo(keyFieldInfo: boolMapKeyInfo, valueFieldInfo: boolMapValueInfo)
    messageDesc.addField(
      FieldDescriptor(
        name: "bool_map",
        number: 3,
        type: .message,
        typeName: "map<bool, int32>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: boolMapEntryInfo
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message = DynamicMessage(descriptor: messageDesc)

    do {
      // Проверяем операции с string -> string map
      try message.setMapEntry("value1", forKey: "key1", inField: "string_map")
      try message.setMapEntry("value2", forKey: "key2", inField: "string_map")

      let stringMap = try message.get(forField: "string_map") as? [String: String]
      XCTAssertEqual(stringMap?["key1"], "value1")
      XCTAssertEqual(stringMap?["key2"], "value2")

      // Перезаписываем значение
      try message.setMapEntry("new_value", forKey: "key1", inField: "string_map")
      let updatedStringMap = try message.get(forField: "string_map") as? [String: String]
      XCTAssertEqual(updatedStringMap?["key1"], "new_value")

      // Проверяем операции с int32 -> string map
      try message.setMapEntry("value1", forKey: Int32(1), inField: "int32_map")
      try message.setMapEntry("value2", forKey: Int32(2), inField: "int32_map")
      try message.setMapEntry("value3", forKey: 3, inField: "int32_map")  // Используем Int вместо Int32

      let int32Map = try message.get(forField: "int32_map") as? [AnyHashable: String]
      XCTAssertEqual(int32Map?[Int32(1)] as? String, "value1")
      XCTAssertEqual(int32Map?[Int32(2)] as? String, "value2")
      XCTAssertEqual(int32Map?[Int32(3)] as? String, "value3")

      // Проверяем операции с bool -> int32 map
      try message.setMapEntry(Int32(100), forKey: true, inField: "bool_map")
      try message.setMapEntry(Int32(200), forKey: false, inField: "bool_map")

      let boolMap = try message.get(forField: "bool_map") as? [Bool: Int32]
      XCTAssertEqual(boolMap?[true], 100)
      XCTAssertEqual(boolMap?[false], 200)

      // Очищаем map поле
      try message.clearField("string_map")
      XCTAssertFalse(try message.hasValue(forField: "string_map"))

      // Устанавливаем целый словарь
      let newMap = ["new1": "value1", "new2": "value2", "new3": "value3"]
      try message.set(newMap, forField: "string_map")

      let finalMap = try message.get(forField: "string_map") as? [String: String]
      XCTAssertEqual(finalMap?.count, 3)
      XCTAssertEqual(finalMap?["new1"], "value1")
      XCTAssertEqual(finalMap?["new2"], "value2")
      XCTAssertEqual(finalMap?["new3"], "value3")

    }
    catch {
      XCTFail("Не должно быть исключений при работе с map полями: \(error)")
    }

    // Проверяем ошибки типов для map полей
    XCTAssertThrowsError(try message.setMapEntry(42, forKey: "key", inField: "string_map"))
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: 42, inField: "string_map"))
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: true, inField: "string_map"))
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "key", inField: "non_existent_map"))
    XCTAssertThrowsError(try message.set("not a map", forField: "string_map"))
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "key", inField: "name"))  // не map поле
  }

  func testRepeatedFieldOperations() {
    // Сообщение с разными repeated полями
    var messageDesc = MessageDescriptor(name: "RepeatedTypes", parent: fileDescriptor)
    messageDesc.addField(
      FieldDescriptor(
        name: "repeated_string",
        number: 1,
        type: .string,
        isRepeated: true
      )
    )
    messageDesc.addField(
      FieldDescriptor(
        name: "repeated_int32",
        number: 2,
        type: .int32,
        isRepeated: true
      )
    )
    messageDesc.addField(
      FieldDescriptor(
        name: "repeated_message",
        number: 3,
        type: .message,
        typeName: "test.Address",
        isRepeated: true
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message = DynamicMessage(descriptor: messageDesc)

    do {
      // Добавляем строковые элементы
      try message.addRepeatedValue("first", forField: "repeated_string")
      try message.addRepeatedValue("second", forField: "repeated_string")
      try message.addRepeatedValue("third", forField: "repeated_string")

      var strings = try message.get(forField: "repeated_string") as? [String]
      XCTAssertEqual(strings?.count, 3)
      XCTAssertEqual(strings?[0], "first")
      XCTAssertEqual(strings?[1], "second")
      XCTAssertEqual(strings?[2], "third")

      // Заменяем массив целиком
      let newStrings = ["new1", "new2"]
      try message.set(newStrings, forField: "repeated_string")

      strings = try message.get(forField: "repeated_string") as? [String]
      XCTAssertEqual(strings?.count, 2)
      XCTAssertEqual(strings?[0], "new1")
      XCTAssertEqual(strings?[1], "new2")

      // Добавляем Int32 элементы
      try message.addRepeatedValue(Int32(10), forField: "repeated_int32")
      try message.addRepeatedValue(Int32(20), forField: "repeated_int32")
      try message.addRepeatedValue(Int(30), forField: "repeated_int32")  // Используем Int вместо Int32

      let repeatedInt32 = try message.get(forField: "repeated_int32") as? [Any]
      XCTAssertEqual(repeatedInt32?.count, 3)
      XCTAssertEqual(repeatedInt32?[0] as? Int32, 10)
      XCTAssertEqual(repeatedInt32?[1] as? Int32, 20)

      // Int может сохраняться как Int или Int32, проверяем оба варианта
      if let value = repeatedInt32?[2] as? Int32 {
        XCTAssertEqual(value, 30)
      }
      else if let value = repeatedInt32?[2] as? Int {
        XCTAssertEqual(value, 30)
      }
      else {
        XCTFail("Значение должно быть Int32 или Int")
      }

      // Добавляем вложенные сообщения
      var address1 = DynamicMessage(descriptor: addressMessage)
      try address1.set("123 Main St", forField: "street")
      try address1.set("New York", forField: "city")

      var address2 = DynamicMessage(descriptor: addressMessage)
      try address2.set("456 Oak Ave", forField: "street")
      try address2.set("San Francisco", forField: "city")

      try message.addRepeatedValue(address1, forField: "repeated_message")
      try message.addRepeatedValue(address2, forField: "repeated_message")

      let addresses = try message.get(forField: "repeated_message") as? [DynamicMessage]
      XCTAssertEqual(addresses?.count, 2)

      let addr1 = addresses?[0]
      XCTAssertEqual(try addr1?.get(forField: "street") as? String, "123 Main St")
      XCTAssertEqual(try addr1?.get(forField: "city") as? String, "New York")

      let addr2 = addresses?[1]
      XCTAssertEqual(try addr2?.get(forField: "street") as? String, "456 Oak Ave")
      XCTAssertEqual(try addr2?.get(forField: "city") as? String, "San Francisco")

      // Очищаем repeated поле
      try message.clearField("repeated_string")
      XCTAssertFalse(try message.hasValue(forField: "repeated_string"))

    }
    catch {
      XCTFail("Не должно быть исключений при работе с repeated полями: \(error)")
    }

    // Проверяем ошибки типов для repeated полей
    XCTAssertThrowsError(try message.addRepeatedValue(42, forField: "repeated_string"))
    XCTAssertThrowsError(try message.addRepeatedValue("string", forField: "repeated_int32"))
    XCTAssertThrowsError(
      try message.addRepeatedValue(DynamicMessage(descriptor: personMessage), forField: "repeated_message")
    )
    XCTAssertThrowsError(try message.addRepeatedValue("value", forField: "name"))  // не repeated поле
    XCTAssertThrowsError(try message.set("not an array", forField: "repeated_string"))

    // Проверяем ошибки типов элементов в массиве
    let mixedArray: [Any] = ["string", 42, true]
    XCTAssertThrowsError(try message.set(mixedArray, forField: "repeated_string"))
  }

  func testDefaultValues() {
    // Создаем сообщение с полями со значениями по умолчанию
    var messageDesc = MessageDescriptor(name: "DefaultValues", parent: fileDescriptor)
    messageDesc.addField(
      FieldDescriptor(
        name: "string_with_default",
        number: 1,
        type: .string,
        defaultValue: "default"
      )
    )
    messageDesc.addField(
      FieldDescriptor(
        name: "int32_with_default",
        number: 2,
        type: .int32,
        defaultValue: Int32(42)
      )
    )
    messageDesc.addField(
      FieldDescriptor(
        name: "bool_with_default",
        number: 3,
        type: .bool,
        defaultValue: true
      )
    )
    messageDesc.addField(
      FieldDescriptor(
        name: "string_without_default",
        number: 4,
        type: .string
      )
    )

    fileDescriptor.addMessage(messageDesc)

    let message = DynamicMessage(descriptor: messageDesc)

    do {
      // Получаем значения по умолчанию
      if let defaultStr = try message.get(forField: "string_with_default") as? String {
        XCTAssertEqual(defaultStr, "default")
      }

      if let defaultInt = try message.get(forField: "int32_with_default") as? Int32 {
        XCTAssertEqual(defaultInt, 42)
      }

      if let defaultBool = try message.get(forField: "bool_with_default") as? Bool {
        XCTAssertEqual(defaultBool, true)
      }

      // Поле без значения по умолчанию должно вернуть nil
      XCTAssertNil(try message.get(forField: "string_without_default"))

      // hasValue должно вернуть false, так как значение не было явно установлено
      XCTAssertFalse(try message.hasValue(forField: "string_with_default"))
      XCTAssertFalse(try message.hasValue(forField: "int32_with_default"))
      XCTAssertFalse(try message.hasValue(forField: "bool_with_default"))
      XCTAssertFalse(try message.hasValue(forField: "string_without_default"))
    }
    catch {
      XCTFail("Не должно быть исключений при работе со значениями по умолчанию: \(error)")
    }
  }

  func testComprehensiveEquatable() {
    // Создаем тест для метода areValuesEqual и сравнения разных типов полей
    var message = MessageDescriptor(name: "EquatableTest", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "double_value", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "float_value", number: 2, type: .float))
    message.addField(FieldDescriptor(name: "int32_value", number: 3, type: .int32))
    message.addField(FieldDescriptor(name: "int64_value", number: 4, type: .int64))
    message.addField(FieldDescriptor(name: "uint32_value", number: 5, type: .uint32))
    message.addField(FieldDescriptor(name: "uint64_value", number: 6, type: .uint64))
    message.addField(FieldDescriptor(name: "bool_value", number: 7, type: .bool))
    message.addField(FieldDescriptor(name: "string_value", number: 8, type: .string))
    message.addField(FieldDescriptor(name: "bytes_value", number: 9, type: .bytes))
    message.addField(FieldDescriptor(name: "enum_value", number: 10, type: .enum, typeName: "test.PhoneType"))

    fileDescriptor.addMessage(message)

    var msg1 = DynamicMessage(descriptor: message)
    var msg2 = DynamicMessage(descriptor: message)

    do {
      // Double
      try msg1.set(1.0, forField: "double_value")
      try msg2.set(1.0, forField: "double_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(2.0, forField: "double_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(1.0, forField: "double_value")
      XCTAssertEqual(msg1, msg2)

      // Float
      try msg1.set(Float(1.0), forField: "float_value")
      try msg2.set(Float(1.0), forField: "float_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(Float(2.0), forField: "float_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(Float(1.0), forField: "float_value")
      XCTAssertEqual(msg1, msg2)

      // Int32
      try msg1.set(Int32(10), forField: "int32_value")
      try msg2.set(Int32(10), forField: "int32_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(Int32(20), forField: "int32_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(Int32(10), forField: "int32_value")
      XCTAssertEqual(msg1, msg2)

      // Int64
      try msg1.set(Int64(1000), forField: "int64_value")
      try msg2.set(Int64(1000), forField: "int64_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(Int64(2000), forField: "int64_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(Int64(1000), forField: "int64_value")
      XCTAssertEqual(msg1, msg2)

      // UInt32
      try msg1.set(UInt32(10), forField: "uint32_value")
      try msg2.set(UInt32(10), forField: "uint32_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(UInt32(20), forField: "uint32_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(UInt32(10), forField: "uint32_value")
      XCTAssertEqual(msg1, msg2)

      // UInt64
      try msg1.set(UInt64(1000), forField: "uint64_value")
      try msg2.set(UInt64(1000), forField: "uint64_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(UInt64(2000), forField: "uint64_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(UInt64(1000), forField: "uint64_value")
      XCTAssertEqual(msg1, msg2)

      // Bool
      try msg1.set(true, forField: "bool_value")
      try msg2.set(true, forField: "bool_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(false, forField: "bool_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(true, forField: "bool_value")
      XCTAssertEqual(msg1, msg2)

      // String
      try msg1.set("test", forField: "string_value")
      try msg2.set("test", forField: "string_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set("different", forField: "string_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set("test", forField: "string_value")
      XCTAssertEqual(msg1, msg2)

      // Bytes
      let data1 = Data("binary".utf8)
      let data2 = Data("different".utf8)

      try msg1.set(data1, forField: "bytes_value")
      try msg2.set(data1, forField: "bytes_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(data2, forField: "bytes_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(data1, forField: "bytes_value")
      XCTAssertEqual(msg1, msg2)

      // Enum (как число)
      try msg1.set(Int32(0), forField: "enum_value")
      try msg2.set(Int32(0), forField: "enum_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(Int32(1), forField: "enum_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(Int32(0), forField: "enum_value")
      XCTAssertEqual(msg1, msg2)

      // Enum (как строка)
      try msg1.set("MOBILE", forField: "enum_value")
      try msg2.set("MOBILE", forField: "enum_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set("HOME", forField: "enum_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set("MOBILE", forField: "enum_value")
      XCTAssertEqual(msg1, msg2)

      // Сравнение разных типов enum - должны быть не равны
      try msg1.set(Int32(0), forField: "enum_value")
      try msg2.set("MOBILE", forField: "enum_value")
      XCTAssertNotEqual(msg1, msg2)
    }
    catch {
      XCTFail("Не должно быть исключений при проверке Equatable: \(error)")
    }
  }

  func testErrorDescriptions() {
    // Проверка локализованных описаний ошибок
    let fieldNameError = DynamicMessageError.fieldNotFound(fieldName: "test_field")
    XCTAssertEqual(fieldNameError.errorDescription, "Поле с именем 'test_field' не найдено")

    let fieldNumberError = DynamicMessageError.fieldNotFoundByNumber(fieldNumber: 42)
    XCTAssertEqual(fieldNumberError.errorDescription, "Поле с номером 42 не найдено")

    let typeMismatchError = DynamicMessageError.typeMismatch(
      fieldName: "test_field",
      expectedType: "String",
      actualValue: 42
    )
    XCTAssertTrue(typeMismatchError.errorDescription?.contains("Несоответствие типа для поля 'test_field'") ?? false)
    XCTAssertTrue(typeMismatchError.errorDescription?.contains("ожидается String") ?? false)

    let messageMismatchError = DynamicMessageError.messageMismatch(
      fieldName: "message_field",
      expectedType: "test.Person",
      actualType: "test.Address"
    )
    XCTAssertTrue(
      messageMismatchError.errorDescription?.contains("Несоответствие типа сообщения для поля 'message_field'") ?? false
    )
    XCTAssertTrue(messageMismatchError.errorDescription?.contains("ожидается test.Person") ?? false)
    XCTAssertTrue(messageMismatchError.errorDescription?.contains("получено test.Address") ?? false)

    let notRepeatedError = DynamicMessageError.notRepeatedField(fieldName: "test_field")
    XCTAssertEqual(notRepeatedError.errorDescription, "Поле 'test_field' не является repeated полем")

    let notMapError = DynamicMessageError.notMapField(fieldName: "test_field")
    XCTAssertEqual(notMapError.errorDescription, "Поле 'test_field' не является map полем")

    let invalidMapKeyTypeError = DynamicMessageError.invalidMapKeyType(type: .double)
    XCTAssertEqual(invalidMapKeyTypeError.errorDescription, "Недопустимый тип ключа double для map поля")
  }
}
