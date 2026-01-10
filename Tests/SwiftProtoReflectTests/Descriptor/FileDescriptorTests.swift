//
// FileDescriptorTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-17
//

import XCTest

@testable import SwiftProtoReflect

/// Tests for FileDescriptor component.
///
/// Covers all main functions including:
/// - Verification of nested object properties (all attributes)
/// - Correctness of full path for nested types
/// - Working with OneOf fields
/// - Circular dependencies between messages
/// - Handling imported types
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

  /// Tests adding message to file.
  ///
  /// Verifies message field types, field numbers and field options.
  func testAddMessage() {
    let personMessage = MessageDescriptor(name: "Person")
    fileDescriptor.addMessage(personMessage)

    XCTAssertEqual(fileDescriptor.messages.count, 1)
    XCTAssertTrue(fileDescriptor.hasMessage(named: "Person"))
    XCTAssertEqual(fileDescriptor.messages["Person"]?.name, "Person")

    // Verify message field types
    var retrievedMessage = fileDescriptor.messages["Person"]!

    let nameField = FieldDescriptor(
      name: "name",
      number: 1,
      type: .string,
      isOptional: true,
      options: ["deprecated": false]
    )

    let ageField = FieldDescriptor(
      name: "age",
      number: 2,
      type: .int32,
      defaultValue: 0,
      options: ["packed": true]
    )

    retrievedMessage.addField(nameField)
    retrievedMessage.addField(ageField)

    // Update message in file
    fileDescriptor.addMessage(retrievedMessage)

    let finalMessage = fileDescriptor.messages["Person"]!

    // Verify field numbers
    XCTAssertEqual(finalMessage.field(number: 1)?.number, 1)
    XCTAssertEqual(finalMessage.field(number: 2)?.number, 2)

    // Verify field types
    XCTAssertEqual(finalMessage.field(number: 1)?.type, .string)
    XCTAssertEqual(finalMessage.field(number: 2)?.type, .int32)

    // Verify field options
    XCTAssertEqual(finalMessage.field(number: 1)?.options["deprecated"] as? Bool, false)
    XCTAssertEqual(finalMessage.field(number: 2)?.options["packed"] as? Bool, true)

    // Verify field flags
    XCTAssertTrue(finalMessage.field(number: 1)?.isOptional ?? false)
    XCTAssertFalse(finalMessage.field(number: 2)?.isOptional ?? true)
  }

  func testAddMessageReplacement() {
    // Add first message
    let personMessage1 = MessageDescriptor(name: "Person")
    fileDescriptor.addMessage(personMessage1)

    // Add second message with same name
    let personMessage2 = MessageDescriptor(name: "Person")
    fileDescriptor.addMessage(personMessage2)

    // Verify that message count hasn't changed (replacement occurred)
    XCTAssertEqual(fileDescriptor.messages.count, 1)
  }

  /// Tests adding enum to file.
  ///
  /// Verifies enum values, enum options and options for individual values.
  func testAddEnum() {
    var genderEnum = EnumDescriptor(name: "Gender", options: ["deprecated": false])

    // Add enum values with options
    genderEnum.addValue(
      EnumDescriptor.EnumValue(
        name: "UNKNOWN",
        number: 0,
        options: ["deprecated": true]
      )
    )

    genderEnum.addValue(
      EnumDescriptor.EnumValue(
        name: "MALE",
        number: 1,
        options: ["custom_option": "male_value"]
      )
    )

    genderEnum.addValue(
      EnumDescriptor.EnumValue(
        name: "FEMALE",
        number: 2,
        options: ["custom_option": "female_value"]
      )
    )

    fileDescriptor.addEnum(genderEnum)

    XCTAssertEqual(fileDescriptor.enums.count, 1)
    XCTAssertTrue(fileDescriptor.hasEnum(named: "Gender"))
    XCTAssertEqual(fileDescriptor.enums["Gender"]?.name, "Gender")

    // Verify enum values
    let retrievedEnum = fileDescriptor.enums["Gender"]!
    XCTAssertEqual(retrievedEnum.allValues().count, 3)

    XCTAssertTrue(retrievedEnum.hasValue(named: "UNKNOWN"))
    XCTAssertTrue(retrievedEnum.hasValue(named: "MALE"))
    XCTAssertTrue(retrievedEnum.hasValue(named: "FEMALE"))

    XCTAssertTrue(retrievedEnum.hasValue(number: 0))
    XCTAssertTrue(retrievedEnum.hasValue(number: 1))
    XCTAssertTrue(retrievedEnum.hasValue(number: 2))

    // Verify enum options
    XCTAssertEqual(retrievedEnum.options["deprecated"] as? Bool, false)

    // Verify options for individual values
    let unknownValue = retrievedEnum.value(named: "UNKNOWN")
    XCTAssertEqual(unknownValue?.options["deprecated"] as? Bool, true)

    let maleValue = retrievedEnum.value(named: "MALE")
    XCTAssertEqual(maleValue?.options["custom_option"] as? String, "male_value")

    let femaleValue = retrievedEnum.value(named: "FEMALE")
    XCTAssertEqual(femaleValue?.options["custom_option"] as? String, "female_value")

    // Verify value numbers
    XCTAssertEqual(unknownValue?.number, 0)
    XCTAssertEqual(maleValue?.number, 1)
    XCTAssertEqual(femaleValue?.number, 2)
  }

  func testAddEnumReplacement() {
    // Add first enum
    let enum1 = EnumDescriptor(name: "Status")
    fileDescriptor.addEnum(enum1)

    // Add second enum with same name
    let enum2 = EnumDescriptor(name: "Status")
    fileDescriptor.addEnum(enum2)

    // Verify that enum count hasn't changed (replacement occurred)
    XCTAssertEqual(fileDescriptor.enums.count, 1)
  }

  /// Tests adding service to file.
  ///
  /// Verifies service methods, input and output parameter types, as well as service and method options.
  func testAddService() {
    var personService = ServiceDescriptor(
      name: "PersonService",
      parent: fileDescriptor,
      options: ["deprecated": false]
    )

    // Add service methods with options
    personService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "GetPerson",
        inputType: "example.person.GetPersonRequest",
        outputType: "example.person.GetPersonResponse",
        options: ["idempotency_level": "IDEMPOTENT"]
      )
    )

    personService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "CreatePerson",
        inputType: "example.person.CreatePersonRequest",
        outputType: "example.person.CreatePersonResponse",
        clientStreaming: false,
        serverStreaming: false,
        options: ["method_signature": "person"]
      )
    )

    personService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "StreamPersons",
        inputType: "example.person.StreamPersonsRequest",
        outputType: "example.person.StreamPersonsResponse",
        clientStreaming: false,
        serverStreaming: true,
        options: ["deprecated": true]
      )
    )

    fileDescriptor.addService(personService)

    XCTAssertEqual(fileDescriptor.services.count, 1)
    XCTAssertTrue(fileDescriptor.hasService(named: "PersonService"))
    XCTAssertEqual(fileDescriptor.services["PersonService"]?.name, "PersonService")

    // Verify service methods
    let retrievedService = fileDescriptor.services["PersonService"]!
    XCTAssertEqual(retrievedService.allMethods().count, 3)

    XCTAssertTrue(retrievedService.hasMethod(named: "GetPerson"))
    XCTAssertTrue(retrievedService.hasMethod(named: "CreatePerson"))
    XCTAssertTrue(retrievedService.hasMethod(named: "StreamPersons"))

    // Verify input and output parameter types
    let getPersonMethod = retrievedService.method(named: "GetPerson")
    XCTAssertEqual(getPersonMethod?.inputType, "example.person.GetPersonRequest")
    XCTAssertEqual(getPersonMethod?.outputType, "example.person.GetPersonResponse")
    XCTAssertFalse(getPersonMethod?.clientStreaming ?? true)
    XCTAssertFalse(getPersonMethod?.serverStreaming ?? true)

    let createPersonMethod = retrievedService.method(named: "CreatePerson")
    XCTAssertEqual(createPersonMethod?.inputType, "example.person.CreatePersonRequest")
    XCTAssertEqual(createPersonMethod?.outputType, "example.person.CreatePersonResponse")

    let streamPersonsMethod = retrievedService.method(named: "StreamPersons")
    XCTAssertEqual(streamPersonsMethod?.inputType, "example.person.StreamPersonsRequest")
    XCTAssertEqual(streamPersonsMethod?.outputType, "example.person.StreamPersonsResponse")
    XCTAssertFalse(streamPersonsMethod?.clientStreaming ?? true)
    XCTAssertTrue(streamPersonsMethod?.serverStreaming ?? false)

    // Verify service options
    XCTAssertEqual(retrievedService.options["deprecated"] as? Bool, false)

    // Verify method options
    XCTAssertEqual(getPersonMethod?.options["idempotency_level"] as? String, "IDEMPOTENT")
    XCTAssertEqual(createPersonMethod?.options["method_signature"] as? String, "person")
    XCTAssertEqual(streamPersonsMethod?.options["deprecated"] as? Bool, true)
  }

  func testAddServiceReplacement() {
    // Add first service
    let service1 = ServiceDescriptor(name: "DataService", parent: fileDescriptor)
    fileDescriptor.addService(service1)

    // Add second service with same name
    let service2 = ServiceDescriptor(name: "DataService", parent: fileDescriptor)
    fileDescriptor.addService(service2)

    // Verify that service count hasn't changed (replacement occurred)
    XCTAssertEqual(fileDescriptor.services.count, 1)
  }

  func testHasMessage() {
    // Verify message absence
    XCTAssertFalse(fileDescriptor.hasMessage(named: "Person"))

    // Add message
    let personMessage = MessageDescriptor(name: "Person")
    fileDescriptor.addMessage(personMessage)

    // Verify message presence
    XCTAssertTrue(fileDescriptor.hasMessage(named: "Person"))

    // Verify absence of other message
    XCTAssertFalse(fileDescriptor.hasMessage(named: "Address"))
  }

  func testHasEnum() {
    // Verify enum absence
    XCTAssertFalse(fileDescriptor.hasEnum(named: "Gender"))

    // Add enum
    let genderEnum = EnumDescriptor(name: "Gender")
    fileDescriptor.addEnum(genderEnum)

    // Verify enum presence
    XCTAssertTrue(fileDescriptor.hasEnum(named: "Gender"))

    // Verify absence of other enum
    XCTAssertFalse(fileDescriptor.hasEnum(named: "Status"))
  }

  func testHasService() {
    // Verify service absence
    XCTAssertFalse(fileDescriptor.hasService(named: "PersonService"))

    // Add service
    let personService = ServiceDescriptor(name: "PersonService", parent: fileDescriptor)
    fileDescriptor.addService(personService)

    // Verify service presence
    XCTAssertTrue(fileDescriptor.hasService(named: "PersonService"))

    // Verify absence of other service
    XCTAssertFalse(fileDescriptor.hasService(named: "AddressService"))
  }

  /// Tests getting full type name.
  ///
  /// Verifies getting name for nested types and behavior for imported types.
  func testGetFullName() {
    XCTAssertEqual(fileDescriptor.getFullName(for: "Person"), "example.person.Person")

    let emptyPackageFileDescriptor = FileDescriptor(name: "test.proto", package: "")
    XCTAssertEqual(emptyPackageFileDescriptor.getFullName(for: "Test"), "Test")

    // Verify getting name for nested types
    XCTAssertEqual(fileDescriptor.getFullName(for: "Person.Address"), "example.person.Person.Address")
    XCTAssertEqual(
      fileDescriptor.getFullName(for: "Person.ContactInfo.Phone"),
      "example.person.Person.ContactInfo.Phone"
    )

    // Verify behavior for imported types
    let fileWithImports = FileDescriptor(
      name: "service.proto",
      package: "example.service",
      dependencies: [
        "google/protobuf/timestamp.proto",
        "google/protobuf/empty.proto",
        "example/common/types.proto",
      ]
    )

    // Local types should get full path with package
    XCTAssertEqual(fileWithImports.getFullName(for: "UserService"), "example.service.UserService")
    XCTAssertEqual(fileWithImports.getFullName(for: "Request"), "example.service.Request")
    XCTAssertEqual(fileWithImports.getFullName(for: "Response"), "example.service.Response")

    // Nested types in local package
    XCTAssertEqual(fileWithImports.getFullName(for: "UserService.Config"), "example.service.UserService.Config")
    XCTAssertEqual(fileWithImports.getFullName(for: "Request.Headers"), "example.service.Request.Headers")

    // Verify file with very long package
    let deepPackageFile = FileDescriptor(
      name: "deep.proto",
      package: "com.example.very.deep.package.structure"
    )

    XCTAssertEqual(
      deepPackageFile.getFullName(for: "DeepType"),
      "com.example.very.deep.package.structure.DeepType"
    )

    XCTAssertEqual(
      deepPackageFile.getFullName(for: "DeepType.NestedType"),
      "com.example.very.deep.package.structure.DeepType.NestedType"
    )

    // Verify file with package containing only one part
    let simplePackageFile = FileDescriptor(name: "simple.proto", package: "simple")
    XCTAssertEqual(simplePackageFile.getFullName(for: "SimpleType"), "simple.SimpleType")

    // Verify that empty types are handled correctly
    XCTAssertEqual(emptyPackageFileDescriptor.getFullName(for: ""), "")
    XCTAssertEqual(fileDescriptor.getFullName(for: ""), "example.person.")
  }

  func testFluentInterface() {
    // Verify methods separately as they are mutating and cannot be called in chain
    let personMessage = MessageDescriptor(name: "Person")
    let genderEnum = EnumDescriptor(name: "Gender")
    let personService = ServiceDescriptor(name: "PersonService", parent: fileDescriptor)

    // Call methods sequentially
    fileDescriptor.addMessage(personMessage)
    fileDescriptor.addEnum(genderEnum)
    fileDescriptor.addService(personService)

    XCTAssertTrue(fileDescriptor.hasMessage(named: "Person"))
    XCTAssertTrue(fileDescriptor.hasEnum(named: "Gender"))
    XCTAssertTrue(fileDescriptor.hasService(named: "PersonService"))
  }

  // MARK: - Business Tests

  /// Verifies nested object properties (not just name, but other attributes too).
  func testNestedObjectProperties() {
    // Create main message
    var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)

    // Create nested message with all attributes
    var addressMessage = MessageDescriptor(
      name: "Address",
      parent: personMessage,
      options: ["deprecated": false, "custom_option": "address_value"]
    )

    // Add fields to nested message
    let streetField = FieldDescriptor(
      name: "street",
      number: 1,
      type: .string,
      isOptional: true,
      options: ["max_length": 100]
    )

    let zipCodeField = FieldDescriptor(
      name: "zip_code",
      number: 2,
      type: .string,
      isRequired: false,
      options: ["pattern": "\\d{5}"]
    )

    addressMessage.addField(streetField)
    addressMessage.addField(zipCodeField)

    // Create nested enum
    var countryEnum = EnumDescriptor(
      name: "Country",
      options: ["allow_alias": true]
    )

    countryEnum.addValue(
      EnumDescriptor.EnumValue(
        name: "UNKNOWN",
        number: 0,
        options: ["deprecated": true]
      )
    )

    countryEnum.addValue(
      EnumDescriptor.EnumValue(
        name: "USA",
        number: 1,
        options: ["country_code": "US"]
      )
    )

    // Add nested types
    personMessage.addNestedMessage(addressMessage)
    personMessage.addNestedEnum(countryEnum)

    fileDescriptor.addMessage(personMessage)

    // Verify main message
    let retrievedPerson = fileDescriptor.messages["Person"]!
    XCTAssertEqual(retrievedPerson.name, "Person")
    XCTAssertEqual(retrievedPerson.fullName, "example.person.Person")
    XCTAssertEqual(retrievedPerson.fileDescriptorPath, "person.proto")
    XCTAssertNil(retrievedPerson.parentMessageFullName)

    // Verify all attributes of nested message
    let retrievedAddress = retrievedPerson.nestedMessage(named: "Address")!
    XCTAssertEqual(retrievedAddress.name, "Address")
    XCTAssertEqual(retrievedAddress.fullName, "example.person.Person.Address")
    XCTAssertEqual(retrievedAddress.fileDescriptorPath, "person.proto")
    XCTAssertEqual(retrievedAddress.parentMessageFullName, "example.person.Person")

    // Verify nested message options
    XCTAssertEqual(retrievedAddress.options["deprecated"] as? Bool, false)
    XCTAssertEqual(retrievedAddress.options["custom_option"] as? String, "address_value")

    // Verify nested message fields
    XCTAssertEqual(retrievedAddress.fields.count, 2)

    let retrievedStreetField = retrievedAddress.field(number: 1)!
    XCTAssertEqual(retrievedStreetField.name, "street")
    XCTAssertEqual(retrievedStreetField.type, .string)
    XCTAssertTrue(retrievedStreetField.isOptional)
    XCTAssertEqual(retrievedStreetField.options["max_length"] as? Int, 100)

    let retrievedZipField = retrievedAddress.field(number: 2)!
    XCTAssertEqual(retrievedZipField.name, "zip_code")
    XCTAssertEqual(retrievedZipField.type, .string)
    XCTAssertFalse(retrievedZipField.isRequired)
    XCTAssertEqual(retrievedZipField.options["pattern"] as? String, "\\d{5}")

    // Verify all attributes of nested enum
    let retrievedCountry = retrievedPerson.nestedEnum(named: "Country")!
    XCTAssertEqual(retrievedCountry.name, "Country")
    XCTAssertEqual(retrievedCountry.options["allow_alias"] as? Bool, true)

    // Verify enum values
    XCTAssertEqual(retrievedCountry.allValues().count, 2)

    let unknownValue = retrievedCountry.value(named: "UNKNOWN")!
    XCTAssertEqual(unknownValue.number, 0)
    XCTAssertEqual(unknownValue.options["deprecated"] as? Bool, true)

    let usaValue = retrievedCountry.value(named: "USA")!
    XCTAssertEqual(usaValue.number, 1)
    XCTAssertEqual(usaValue.options["country_code"] as? String, "US")
  }

  /// Verifies correctness of full paths for nested types.
  func testNestedTypeFullPaths() {
    // Create multi-level structure
    var companyMessage = MessageDescriptor(name: "Company", parent: fileDescriptor)
    var departmentMessage = MessageDescriptor(name: "Department", parent: companyMessage)
    var teamMessage = MessageDescriptor(name: "Team", parent: departmentMessage)
    var employeeMessage = MessageDescriptor(name: "Employee", parent: teamMessage)

    // Create field that references deeply nested type
    let managerField = FieldDescriptor(
      name: "manager",
      number: 1,
      type: .message,
      typeName: "example.person.Company.Department.Team.Employee"
    )

    employeeMessage.addField(managerField)

    // Assemble structure
    teamMessage.addNestedMessage(employeeMessage)
    departmentMessage.addNestedMessage(teamMessage)
    companyMessage.addNestedMessage(departmentMessage)
    fileDescriptor.addMessage(companyMessage)

    // Verify full paths
    var retrievedCompany = fileDescriptor.messages["Company"]!
    XCTAssertEqual(retrievedCompany.fullName, "example.person.Company")

    var retrievedDepartment = retrievedCompany.nestedMessage(named: "Department")!
    XCTAssertEqual(retrievedDepartment.fullName, "example.person.Company.Department")
    XCTAssertEqual(retrievedDepartment.parentMessageFullName, "example.person.Company")

    var retrievedTeam = retrievedDepartment.nestedMessage(named: "Team")!
    XCTAssertEqual(retrievedTeam.fullName, "example.person.Company.Department.Team")
    XCTAssertEqual(retrievedTeam.parentMessageFullName, "example.person.Company.Department")

    var retrievedEmployee = retrievedTeam.nestedMessage(named: "Employee")!
    XCTAssertEqual(retrievedEmployee.fullName, "example.person.Company.Department.Team.Employee")
    XCTAssertEqual(retrievedEmployee.parentMessageFullName, "example.person.Company.Department.Team")

    // Verify field with reference to deeply nested type
    let retrievedManagerField = retrievedEmployee.field(number: 1)!
    XCTAssertEqual(retrievedManagerField.typeName, "example.person.Company.Department.Team.Employee")

    // Verify file paths
    XCTAssertEqual(retrievedCompany.fileDescriptorPath, "person.proto")
    XCTAssertEqual(retrievedDepartment.fileDescriptorPath, "person.proto")
    XCTAssertEqual(retrievedTeam.fileDescriptorPath, "person.proto")
    XCTAssertEqual(retrievedEmployee.fileDescriptorPath, "person.proto")

    // Create enums at different nesting levels
    var statusEnum = EnumDescriptor(name: "Status")
    statusEnum.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))

    var priorityEnum = EnumDescriptor(name: "Priority")
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "HIGH", number: 1))

    // Add enums at different levels - need to recreate entire structure
    retrievedEmployee.addNestedEnum(priorityEnum)
    retrievedTeam.addNestedMessage(retrievedEmployee)
    retrievedDepartment.addNestedMessage(retrievedTeam)
    retrievedCompany.addNestedEnum(statusEnum)
    retrievedCompany.addNestedMessage(retrievedDepartment)

    // Update message in file
    fileDescriptor.addMessage(retrievedCompany)

    // Verify final paths after update
    let finalCompany = fileDescriptor.messages["Company"]!
    let finalEmployee =
      finalCompany
      .nestedMessage(named: "Department")!
      .nestedMessage(named: "Team")!
      .nestedMessage(named: "Employee")!

    XCTAssertTrue(finalCompany.hasNestedEnum(named: "Status"))
    XCTAssertTrue(finalEmployee.hasNestedEnum(named: "Priority"))
  }

  /// Verifies working with OneOf fields in file descriptor context.
  func testOneOfFieldsInFileContext() {
    // Create message with OneOf fields
    var paymentMessage = MessageDescriptor(name: "Payment", parent: fileDescriptor)

    // Create OneOf group for payment type
    let creditCardField = FieldDescriptor(
      name: "credit_card",
      number: 1,
      type: .message,
      typeName: "example.person.CreditCard",
      oneofIndex: 0
    )

    let paypalField = FieldDescriptor(
      name: "paypal",
      number: 2,
      type: .message,
      typeName: "example.person.PayPal",
      oneofIndex: 0
    )

    let cashField = FieldDescriptor(
      name: "cash",
      number: 3,
      type: .message,
      typeName: "example.person.Cash",
      oneofIndex: 0
    )

    // Create another OneOf group for currency
    let usdField = FieldDescriptor(
      name: "usd_amount",
      number: 4,
      type: .double,
      oneofIndex: 1
    )

    let eurField = FieldDescriptor(
      name: "eur_amount",
      number: 5,
      type: .double,
      oneofIndex: 1
    )

    // Regular field (not OneOf)
    let idField = FieldDescriptor(
      name: "payment_id",
      number: 6,
      type: .string
    )

    paymentMessage.addField(creditCardField)
    paymentMessage.addField(paypalField)
    paymentMessage.addField(cashField)
    paymentMessage.addField(usdField)
    paymentMessage.addField(eurField)
    paymentMessage.addField(idField)

    fileDescriptor.addMessage(paymentMessage)

    // Verify OneOf fields
    let retrievedPayment = fileDescriptor.messages["Payment"]!

    // Group 0 - payment type
    let retrievedCreditCard = retrievedPayment.field(number: 1)!
    let retrievedPaypal = retrievedPayment.field(number: 2)!
    let retrievedCash = retrievedPayment.field(number: 3)!

    XCTAssertEqual(retrievedCreditCard.oneofIndex, 0)
    XCTAssertEqual(retrievedPaypal.oneofIndex, 0)
    XCTAssertEqual(retrievedCash.oneofIndex, 0)

    // Group 1 - currency
    let retrievedUsd = retrievedPayment.field(number: 4)!
    let retrievedEur = retrievedPayment.field(number: 5)!

    XCTAssertEqual(retrievedUsd.oneofIndex, 1)
    XCTAssertEqual(retrievedEur.oneofIndex, 1)

    // Regular field
    let retrievedId = retrievedPayment.field(number: 6)!
    XCTAssertNil(retrievedId.oneofIndex)

    // Verify field types
    XCTAssertEqual(retrievedCreditCard.type, .message)
    XCTAssertEqual(retrievedPaypal.type, .message)
    XCTAssertEqual(retrievedCash.type, .message)
    XCTAssertEqual(retrievedUsd.type, .double)
    XCTAssertEqual(retrievedEur.type, .double)
    XCTAssertEqual(retrievedId.type, .string)

    // Verify type names for message fields
    XCTAssertEqual(retrievedCreditCard.typeName, "example.person.CreditCard")
    XCTAssertEqual(retrievedPaypal.typeName, "example.person.PayPal")
    XCTAssertEqual(retrievedCash.typeName, "example.person.Cash")

    // Verify that scalar fields don't have typeName
    XCTAssertNil(retrievedUsd.typeName)
    XCTAssertNil(retrievedEur.typeName)
    XCTAssertNil(retrievedId.typeName)
  }

  /// Tests cyclic dependencies between messages in file context.
  func testCyclicDependenciesInFileContext() {
    // Create node graph with cyclic references
    var nodeMessage = MessageDescriptor(name: "GraphNode", parent: fileDescriptor)

    // Self-reference
    let parentField = FieldDescriptor(
      name: "parent",
      number: 1,
      type: .message,
      typeName: "example.person.GraphNode",
      isOptional: true
    )

    let childrenField = FieldDescriptor(
      name: "children",
      number: 2,
      type: .message,
      typeName: "example.person.GraphNode",
      isRepeated: true
    )

    nodeMessage.addField(parentField)
    nodeMessage.addField(childrenField)

    // Create mutually referencing messages
    var userMessage = MessageDescriptor(name: "User", parent: fileDescriptor)
    var groupMessage = MessageDescriptor(name: "Group", parent: fileDescriptor)

    let userGroupsField = FieldDescriptor(
      name: "groups",
      number: 1,
      type: .message,
      typeName: "example.person.Group",
      isRepeated: true
    )

    let groupUsersField = FieldDescriptor(
      name: "users",
      number: 1,
      type: .message,
      typeName: "example.person.User",
      isRepeated: true
    )

    // Also add group owner
    let groupOwnerField = FieldDescriptor(
      name: "owner",
      number: 2,
      type: .message,
      typeName: "example.person.User",
      isOptional: true
    )

    userMessage.addField(userGroupsField)
    groupMessage.addField(groupUsersField)
    groupMessage.addField(groupOwnerField)

    // Add all messages to file
    fileDescriptor.addMessage(nodeMessage)
    fileDescriptor.addMessage(userMessage)
    fileDescriptor.addMessage(groupMessage)

    // Verify self-referencing fields
    let retrievedNode = fileDescriptor.messages["GraphNode"]!

    let retrievedParentField = retrievedNode.field(number: 1)!
    XCTAssertEqual(retrievedParentField.typeName, "example.person.GraphNode")
    XCTAssertTrue(retrievedParentField.isOptional)
    XCTAssertFalse(retrievedParentField.isRepeated)

    let retrievedChildrenField = retrievedNode.field(number: 2)!
    XCTAssertEqual(retrievedChildrenField.typeName, "example.person.GraphNode")
    XCTAssertFalse(retrievedChildrenField.isOptional)
    XCTAssertTrue(retrievedChildrenField.isRepeated)

    // Verify mutual references
    let retrievedUser = fileDescriptor.messages["User"]!
    let retrievedGroup = fileDescriptor.messages["Group"]!

    let retrievedUserGroupsField = retrievedUser.field(number: 1)!
    XCTAssertEqual(retrievedUserGroupsField.typeName, "example.person.Group")
    XCTAssertTrue(retrievedUserGroupsField.isRepeated)

    let retrievedGroupUsersField = retrievedGroup.field(number: 1)!
    XCTAssertEqual(retrievedGroupUsersField.typeName, "example.person.User")
    XCTAssertTrue(retrievedGroupUsersField.isRepeated)

    let retrievedGroupOwnerField = retrievedGroup.field(number: 2)!
    XCTAssertEqual(retrievedGroupOwnerField.typeName, "example.person.User")
    XCTAssertTrue(retrievedGroupOwnerField.isOptional)

    // Verify that all messages have correct full names
    XCTAssertEqual(retrievedNode.fullName, "example.person.GraphNode")
    XCTAssertEqual(retrievedUser.fullName, "example.person.User")
    XCTAssertEqual(retrievedGroup.fullName, "example.person.Group")

    // Verify count of added messages
    XCTAssertEqual(fileDescriptor.messages.count, 3)
    XCTAssertTrue(fileDescriptor.hasMessage(named: "GraphNode"))
    XCTAssertTrue(fileDescriptor.hasMessage(named: "User"))
    XCTAssertTrue(fileDescriptor.hasMessage(named: "Group"))
  }

  /// Verifies handling of imported types in file context.
  func testImportedTypesInFileContext() {
    // Create file with multiple imports
    var apiFile = FileDescriptor(
      name: "api.proto",
      package: "example.api.v1",
      dependencies: [
        "google/protobuf/timestamp.proto",
        "google/protobuf/duration.proto",
        "google/protobuf/empty.proto",
        "google/protobuf/field_mask.proto",
        "google/type/money.proto",
        "example/common/types.proto",
        "example/auth/user.proto",
      ]
    )

    // Create service with imported types
    var apiService = ServiceDescriptor(name: "PaymentAPI", parent: apiFile)

    // Methods with various imported types
    apiService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "CreatePayment",
        inputType: "example.api.v1.CreatePaymentRequest",
        outputType: "example.api.v1.CreatePaymentResponse"
      )
    )

    apiService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "GetPayment",
        inputType: "example.api.v1.GetPaymentRequest",
        outputType: "example.api.v1.Payment"
      )
    )

    apiService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "DeletePayment",
        inputType: "example.api.v1.DeletePaymentRequest",
        outputType: "google.protobuf.Empty"
      )
    )

    // Create messages with imported fields
    var paymentMessage = MessageDescriptor(name: "Payment", parent: apiFile)

    let idField = FieldDescriptor(
      name: "id",
      number: 1,
      type: .string
    )

    let amountField = FieldDescriptor(
      name: "amount",
      number: 2,
      type: .message,
      typeName: "google.type.Money"
    )

    let createdAtField = FieldDescriptor(
      name: "created_at",
      number: 3,
      type: .message,
      typeName: "google.protobuf.Timestamp"
    )

    let expirationField = FieldDescriptor(
      name: "expiration",
      number: 4,
      type: .message,
      typeName: "google.protobuf.Duration"
    )

    let userField = FieldDescriptor(
      name: "user",
      number: 5,
      type: .message,
      typeName: "example.auth.User"
    )

    let statusField = FieldDescriptor(
      name: "status",
      number: 6,
      type: .enum,
      typeName: "example.common.PaymentStatus"
    )

    let tagsField = FieldDescriptor(
      name: "tags",
      number: 7,
      type: .string,
      isRepeated: true
    )

    // Map field with imported type in value
    let mapKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let mapValueInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.common.Metadata"
    )
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: mapKeyInfo, valueFieldInfo: mapValueInfo)

    let metadataField = FieldDescriptor(
      name: "metadata",
      number: 8,
      type: .message,
      typeName: "example.api.v1.MetadataEntry",
      isMap: true,
      mapEntryInfo: mapEntryInfo
    )

    paymentMessage.addField(idField)
    paymentMessage.addField(amountField)
    paymentMessage.addField(createdAtField)
    paymentMessage.addField(expirationField)
    paymentMessage.addField(userField)
    paymentMessage.addField(statusField)
    paymentMessage.addField(tagsField)
    paymentMessage.addField(metadataField)

    apiFile.addService(apiService)
    apiFile.addMessage(paymentMessage)

    // Verify file dependencies
    XCTAssertEqual(apiFile.dependencies.count, 7)
    XCTAssertTrue(apiFile.dependencies.contains("google/protobuf/timestamp.proto"))
    XCTAssertTrue(apiFile.dependencies.contains("google/protobuf/duration.proto"))
    XCTAssertTrue(apiFile.dependencies.contains("google/protobuf/empty.proto"))
    XCTAssertTrue(apiFile.dependencies.contains("google/protobuf/field_mask.proto"))
    XCTAssertTrue(apiFile.dependencies.contains("google/type/money.proto"))
    XCTAssertTrue(apiFile.dependencies.contains("example/common/types.proto"))
    XCTAssertTrue(apiFile.dependencies.contains("example/auth/user.proto"))

    // Verify service with imported types
    let retrievedService = apiFile.services["PaymentAPI"]!
    XCTAssertEqual(retrievedService.allMethods().count, 3)

    let deleteMethod = retrievedService.method(named: "DeletePayment")!
    XCTAssertEqual(deleteMethod.outputType, "google.protobuf.Empty")

    // Verify message with imported fields
    let retrievedPayment = apiFile.messages["Payment"]!

    // Google types
    let retrievedAmountField = retrievedPayment.field(number: 2)!
    XCTAssertEqual(retrievedAmountField.typeName, "google.type.Money")
    XCTAssertEqual(retrievedAmountField.type, .message)

    let retrievedTimestampField = retrievedPayment.field(number: 3)!
    XCTAssertEqual(retrievedTimestampField.typeName, "google.protobuf.Timestamp")

    let retrievedDurationField = retrievedPayment.field(number: 4)!
    XCTAssertEqual(retrievedDurationField.typeName, "google.protobuf.Duration")

    // Custom imported types
    let retrievedUserField = retrievedPayment.field(number: 5)!
    XCTAssertEqual(retrievedUserField.typeName, "example.auth.User")
    XCTAssertEqual(retrievedUserField.type, .message)

    let retrievedStatusField = retrievedPayment.field(number: 6)!
    XCTAssertEqual(retrievedStatusField.typeName, "example.common.PaymentStatus")
    XCTAssertEqual(retrievedStatusField.type, .enum)

    // Map field with imported type
    let retrievedMetadataField = retrievedPayment.field(number: 8)!
    XCTAssertTrue(retrievedMetadataField.isMap)

    let metadataMapInfo = retrievedMetadataField.getMapKeyValueInfo()!
    XCTAssertEqual(metadataMapInfo.keyFieldInfo.type, .string)
    XCTAssertEqual(metadataMapInfo.valueFieldInfo.type, .message)
    XCTAssertEqual(metadataMapInfo.valueFieldInfo.typeName, "example.common.Metadata")

    // Verify generation of full names for local types
    XCTAssertEqual(apiFile.getFullName(for: "LocalRequest"), "example.api.v1.LocalRequest")
    XCTAssertEqual(apiFile.getFullName(for: "LocalResponse"), "example.api.v1.LocalResponse")
    XCTAssertEqual(apiFile.getFullName(for: "Payment.Detail"), "example.api.v1.Payment.Detail")

    // Verify that all objects have correct packages
    XCTAssertEqual(retrievedService.fullName, "example.api.v1.PaymentAPI")
    XCTAssertEqual(retrievedPayment.fullName, "example.api.v1.Payment")
  }

  // MARK: - Helpers
}
