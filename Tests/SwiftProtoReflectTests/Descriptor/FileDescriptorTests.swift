//
// FileDescriptorTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-17
//

import XCTest

@testable import SwiftProtoReflect

/// Тесты для компонента FileDescriptor.
///
/// # TODO: Расширение тестов.
/// - Добавить проверку свойств вложенных объектов (не только имени, но и других атрибутов).
/// - Проверять корректность полного пути для вложенных типов.
/// - Проверить работу с OneOf полями.
/// - Тестировать циклические зависимости между сообщениями.
/// - Проверить обработку импортированных типов.
final class FileDescriptorTests: XCTestCase {
  // MARK: - Properties

  var fileDescriptor: FileDescriptor!

  // MARK: - Setup

  override func setUp() {
    super.setUp()
    fileDescriptor = FileDescriptor(
      name: "person.proto",
      package: "example.person",
      dependencies: ["google/protobuf/timestamp.proto"],
      options: ["java_package": "com.example.person"]
    )
  }

  override func tearDown() {
    fileDescriptor = nil
    super.tearDown()
  }

  // MARK: - Tests

  func testInitialization() {
    XCTAssertEqual(fileDescriptor.name, "person.proto")
    XCTAssertEqual(fileDescriptor.package, "example.person")
    XCTAssertEqual(fileDescriptor.dependencies, ["google/protobuf/timestamp.proto"])
    XCTAssertEqual(fileDescriptor.options["java_package"] as? String, "com.example.person")
    XCTAssertTrue(fileDescriptor.messages.isEmpty)
    XCTAssertTrue(fileDescriptor.enums.isEmpty)
    XCTAssertTrue(fileDescriptor.services.isEmpty)
  }

  func testInitializationWithDefaults() {
    let descriptor = FileDescriptor(name: "empty.proto", package: "test")
    XCTAssertEqual(descriptor.name, "empty.proto")
    XCTAssertEqual(descriptor.package, "test")
    XCTAssertTrue(descriptor.dependencies.isEmpty)
    XCTAssertTrue(descriptor.options.isEmpty)
  }

  func testInitializationWithEmptyPackage() {
    let descriptor = FileDescriptor(name: "no_package.proto", package: "")
    XCTAssertEqual(descriptor.name, "no_package.proto")
    XCTAssertEqual(descriptor.package, "")
  }

  /// Тестирует добавление сообщения в файл.
  ///
  /// # TODO: Дополнить тест.
  /// - Проверять типы полей сообщения.
  /// - Проверять номера полей.
  /// - Проверять опции полей.
  func testAddMessage() {
    let personMessage = MessageDescriptor(name: "Person")
    fileDescriptor.addMessage(personMessage)

    XCTAssertEqual(fileDescriptor.messages.count, 1)
    XCTAssertTrue(fileDescriptor.hasMessage(named: "Person"))
    XCTAssertEqual(fileDescriptor.messages["Person"]?.name, "Person")
  }

  func testAddMessageReplacement() {
    // Добавляем первое сообщение
    let personMessage1 = MessageDescriptor(name: "Person")
    fileDescriptor.addMessage(personMessage1)

    // Добавляем второе сообщение с тем же именем
    let personMessage2 = MessageDescriptor(name: "Person")
    fileDescriptor.addMessage(personMessage2)

    // Проверяем, что количество сообщений не изменилось (произошла замена)
    XCTAssertEqual(fileDescriptor.messages.count, 1)
  }

  /// Тестирует добавление перечисления в файл.
  ///
  /// # TODO: Дополнить тест.
  /// - Проверять значения перечисления.
  /// - Проверять опции перечисления.
  /// - Проверять опции для отдельных значений.
  func testAddEnum() {
    let genderEnum = EnumDescriptor(name: "Gender")
    fileDescriptor.addEnum(genderEnum)

    XCTAssertEqual(fileDescriptor.enums.count, 1)
    XCTAssertTrue(fileDescriptor.hasEnum(named: "Gender"))
    XCTAssertEqual(fileDescriptor.enums["Gender"]?.name, "Gender")
  }

  func testAddEnumReplacement() {
    // Добавляем первое перечисление
    let enum1 = EnumDescriptor(name: "Status")
    fileDescriptor.addEnum(enum1)

    // Добавляем второе перечисление с тем же именем
    let enum2 = EnumDescriptor(name: "Status")
    fileDescriptor.addEnum(enum2)

    // Проверяем, что количество перечислений не изменилось (произошла замена)
    XCTAssertEqual(fileDescriptor.enums.count, 1)
  }

  /// Тестирует добавление сервиса в файл.
  ///
  /// # TODO: Дополнить тест.
  /// - Проверять методы сервиса.
  /// - Проверять типы входных и выходных параметров.
  /// - Проверять опции сервиса и методов.
  func testAddService() {
    let personService = ServiceDescriptor(name: "PersonService", parent: fileDescriptor)
    fileDescriptor.addService(personService)

    XCTAssertEqual(fileDescriptor.services.count, 1)
    XCTAssertTrue(fileDescriptor.hasService(named: "PersonService"))
    XCTAssertEqual(fileDescriptor.services["PersonService"]?.name, "PersonService")
  }

  func testAddServiceReplacement() {
    // Добавляем первый сервис
    let service1 = ServiceDescriptor(name: "DataService", parent: fileDescriptor)
    fileDescriptor.addService(service1)

    // Добавляем второй сервис с тем же именем
    let service2 = ServiceDescriptor(name: "DataService", parent: fileDescriptor)
    fileDescriptor.addService(service2)

    // Проверяем, что количество сервисов не изменилось (произошла замена)
    XCTAssertEqual(fileDescriptor.services.count, 1)
  }

  func testHasMessage() {
    // Проверяем отсутствие сообщения
    XCTAssertFalse(fileDescriptor.hasMessage(named: "Person"))

    // Добавляем сообщение
    let personMessage = MessageDescriptor(name: "Person")
    fileDescriptor.addMessage(personMessage)

    // Проверяем наличие сообщения
    XCTAssertTrue(fileDescriptor.hasMessage(named: "Person"))

    // Проверяем отсутствие другого сообщения
    XCTAssertFalse(fileDescriptor.hasMessage(named: "Address"))
  }

  func testHasEnum() {
    // Проверяем отсутствие перечисления
    XCTAssertFalse(fileDescriptor.hasEnum(named: "Gender"))

    // Добавляем перечисление
    let genderEnum = EnumDescriptor(name: "Gender")
    fileDescriptor.addEnum(genderEnum)

    // Проверяем наличие перечисления
    XCTAssertTrue(fileDescriptor.hasEnum(named: "Gender"))

    // Проверяем отсутствие другого перечисления
    XCTAssertFalse(fileDescriptor.hasEnum(named: "Status"))
  }

  func testHasService() {
    // Проверяем отсутствие сервиса
    XCTAssertFalse(fileDescriptor.hasService(named: "PersonService"))

    // Добавляем сервис
    let personService = ServiceDescriptor(name: "PersonService", parent: fileDescriptor)
    fileDescriptor.addService(personService)

    // Проверяем наличие сервиса
    XCTAssertTrue(fileDescriptor.hasService(named: "PersonService"))

    // Проверяем отсутствие другого сервиса
    XCTAssertFalse(fileDescriptor.hasService(named: "AddressService"))
  }

  /// Тестирует получение полного имени типа.
  ///
  /// # TODO: Дополнить тест.
  /// - Проверить получение имени для вложенных типов.
  /// - Проверить поведение для импортированных типов.
  func testGetFullName() {
    XCTAssertEqual(fileDescriptor.getFullName(for: "Person"), "example.person.Person")

    let emptyPackageFileDescriptor = FileDescriptor(name: "test.proto", package: "")
    XCTAssertEqual(emptyPackageFileDescriptor.getFullName(for: "Test"), "Test")
  }

  func testFluentInterface() {
    // Проверяем методы отдельно, так как они mutating и не могут вызываться цепочкой
    let personMessage = MessageDescriptor(name: "Person")
    let genderEnum = EnumDescriptor(name: "Gender")
    let personService = ServiceDescriptor(name: "PersonService", parent: fileDescriptor)

    // Вызываем методы последовательно
    fileDescriptor.addMessage(personMessage)
    fileDescriptor.addEnum(genderEnum)
    fileDescriptor.addService(personService)

    XCTAssertTrue(fileDescriptor.hasMessage(named: "Person"))
    XCTAssertTrue(fileDescriptor.hasEnum(named: "Gender"))
    XCTAssertTrue(fileDescriptor.hasService(named: "PersonService"))
  }

  // MARK: - Helpers
}
