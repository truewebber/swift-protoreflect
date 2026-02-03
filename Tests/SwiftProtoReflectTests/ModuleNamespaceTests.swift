import SwiftProtoReflect
import XCTest

/// Tests to ensure module namespace is not polluted or shadowed by type names.
///
/// These tests verify that:
/// - No type in the module has the same name as the module itself
/// - All public types are accessible with fully qualified names
/// - External consumers can use the library without namespace conflicts
/// - Module name doesn't shadow type names or vice versa
///
/// This prevents namespace collision issues where a public type with the same
/// name as the module would make other module types inaccessible.
final class ModuleNamespaceTests: XCTestCase {

  // MARK: - Core Type Accessibility

  func testAllCoreTypesAccessibleWithModulePrefix() {
    // Verify all core types can be accessed with fully qualified names
    let factory: SwiftProtoReflect.MessageFactory = MessageFactory()
    let registry: SwiftProtoReflect.TypeRegistry = TypeRegistry()
    let pool: SwiftProtoReflect.DescriptorPool = DescriptorPool()

    XCTAssertNotNil(factory)
    XCTAssertNotNil(registry)
    XCTAssertNotNil(pool)
  }

  func testValidationTypesAccessibleWithModulePrefix() {
    // Verify validation-related types are accessible
    let result: SwiftProtoReflect.ValidationResult = ValidationResult(isValid: true, errors: [])
    let error: SwiftProtoReflect.ValidationError = .missingRequiredField(fieldName: "test")

    XCTAssertTrue(result.isValid)
    if case .missingRequiredField(let name) = error {
      XCTAssertEqual(name, "test")
    }
    else {
      XCTFail("Wrong error type")
    }
  }

  func testDescriptorTypesAccessibleWithModulePrefix() {
    // Verify all descriptor types are accessible
    let fileDesc: SwiftProtoReflect.FileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let msgDesc: SwiftProtoReflect.MessageDescriptor = MessageDescriptor(name: "Test", parent: fileDesc)
    let fieldDesc: SwiftProtoReflect.FieldDescriptor = FieldDescriptor(name: "field", number: 1, type: .string)
    let enumDesc: SwiftProtoReflect.EnumDescriptor = EnumDescriptor(name: "TestEnum", parent: fileDesc)
    let serviceDesc: SwiftProtoReflect.ServiceDescriptor = ServiceDescriptor(name: "Service", parent: fileDesc)

    XCTAssertEqual(fileDesc.name, "test.proto")
    XCTAssertEqual(msgDesc.name, "Test")
    XCTAssertEqual(fieldDesc.name, "field")
    XCTAssertEqual(enumDesc.name, "TestEnum")
    XCTAssertEqual(serviceDesc.name, "Service")
  }

  func testDynamicMessageAccessibleWithModulePrefix() {
    // Verify DynamicMessage type can be referenced
    let descriptor = MessageDescriptor(
      name: "Test",
      parent: FileDescriptor(name: "test.proto", package: "test")
    )
    let factory = MessageFactory()
    let message = factory.createMessage(from: descriptor)

    let typedMessage: SwiftProtoReflect.DynamicMessage = message
    XCTAssertEqual(typedMessage.descriptor.name, "Test")
  }

  // MARK: - Serialization Types

  func testSerializerTypesAccessibleWithModulePrefix() {
    // Verify all serializer types are accessible
    let binarySerializer: SwiftProtoReflect.BinarySerializer = BinarySerializer()
    let jsonSerializer: SwiftProtoReflect.JSONSerializer = JSONSerializer()
    let binaryDeserializer: SwiftProtoReflect.BinaryDeserializer = BinaryDeserializer()
    let jsonDeserializer: SwiftProtoReflect.JSONDeserializer = JSONDeserializer()

    XCTAssertNotNil(binarySerializer)
    XCTAssertNotNil(jsonSerializer)
    XCTAssertNotNil(binaryDeserializer)
    XCTAssertNotNil(jsonDeserializer)
  }

  func testSerializationOptionsAccessibleWithModulePrefix() {
    // Verify options types are accessible
    let serOpts: SwiftProtoReflect.SerializationOptions = SerializationOptions()
    let deserOpts: SwiftProtoReflect.DeserializationOptions = DeserializationOptions()
    let jsonSerOpts: SwiftProtoReflect.JSONSerializationOptions = JSONSerializationOptions()
    let jsonDeserOpts: SwiftProtoReflect.JSONDeserializationOptions = JSONDeserializationOptions()

    XCTAssertNotNil(serOpts)
    XCTAssertNotNil(deserOpts)
    XCTAssertNotNil(jsonSerOpts)
    XCTAssertNotNil(jsonDeserOpts)
  }

  // MARK: - Error Types

  func testAllErrorTypesAccessibleWithModulePrefix() {
    // Verify all error types can be accessed
    let _: SwiftProtoReflect.ValidationError.Type = ValidationError.self
    let _: SwiftProtoReflect.JSONDeserializationError.Type = JSONDeserializationError.self
    let _: SwiftProtoReflect.JSONSerializationError.Type = JSONSerializationError.self
    let _: SwiftProtoReflect.SerializationError.Type = SerializationError.self
    let _: SwiftProtoReflect.DeserializationError.Type = DeserializationError.self
    let _: SwiftProtoReflect.DynamicMessageError.Type = DynamicMessageError.self
    let _: SwiftProtoReflect.RegistryError.Type = RegistryError.self
    let _: SwiftProtoReflect.DescriptorPoolError.Type = DescriptorPoolError.self
    let _: SwiftProtoReflect.StaticMessageBridgeError.Type = StaticMessageBridgeError.self
    let _: SwiftProtoReflect.DescriptorBridgeError.Type = DescriptorBridgeError.self
    let _: SwiftProtoReflect.WellKnownTypeError.Type = WellKnownTypeError.self

    XCTAssertTrue(true, "All error types are accessible")
  }

  func testErrorTypesCanBeInstantiatedWithModulePrefix() {
    // Verify error types can be created and used
    let validationError: SwiftProtoReflect.ValidationError = .missingRequiredField(fieldName: "field")
    let jsonError: SwiftProtoReflect.JSONDeserializationError = .invalidJSONStructure(
      expected: "object",
      actual: "array"
    )

    if case .missingRequiredField(let name) = validationError {
      XCTAssertEqual(name, "field")
    }
    if case .invalidJSONStructure = jsonError {
      XCTAssertTrue(true)
    }
  }

  // MARK: - Well-Known Type Handlers

  func testWellKnownTypeHandlersAccessibleWithModulePrefix() {
    // Verify well-known type handlers are accessible
    let timestampHandler: SwiftProtoReflect.TimestampHandler.Type = TimestampHandler.self
    let durationHandler: SwiftProtoReflect.DurationHandler.Type = DurationHandler.self
    let anyHandler: SwiftProtoReflect.AnyHandler.Type = AnyHandler.self
    let structHandler: SwiftProtoReflect.StructHandler.Type = StructHandler.self
    let emptyHandler: SwiftProtoReflect.EmptyHandler.Type = EmptyHandler.self
    let valueHandler: SwiftProtoReflect.ValueHandler.Type = ValueHandler.self
    let fieldMaskHandler: SwiftProtoReflect.FieldMaskHandler.Type = FieldMaskHandler.self

    XCTAssertEqual(timestampHandler.handledTypeName, "google.protobuf.Timestamp")
    XCTAssertEqual(durationHandler.handledTypeName, "google.protobuf.Duration")
    XCTAssertEqual(anyHandler.handledTypeName, "google.protobuf.Any")
    XCTAssertEqual(structHandler.handledTypeName, "google.protobuf.Struct")
    XCTAssertEqual(emptyHandler.handledTypeName, "google.protobuf.Empty")
    XCTAssertEqual(valueHandler.handledTypeName, "google.protobuf.Value")
    XCTAssertEqual(fieldMaskHandler.handledTypeName, "google.protobuf.FieldMask")
  }

  // MARK: - Bridge Types

  func testBridgeTypesAccessibleWithModulePrefix() {
    // Verify bridge types are accessible
    let staticBridge: SwiftProtoReflect.StaticMessageBridge.Type = StaticMessageBridge.self
    let descriptorBridge: SwiftProtoReflect.DescriptorBridge.Type = DescriptorBridge.self

    XCTAssertNotNil(staticBridge)
    XCTAssertNotNil(descriptorBridge)
  }

  // MARK: - Enum Types

  func testEnumTypesAccessibleWithModulePrefix() {
    // Verify public enums are accessible
    let fieldType: SwiftProtoReflect.FieldType = .string
    let wireType: SwiftProtoReflect.WireType = .varint

    XCTAssertEqual(fieldType, .string)
    XCTAssertEqual(wireType, .varint)
  }

  // MARK: - Struct/Helper Types

  func testHelperTypesAccessibleWithModulePrefix() {
    // Verify helper struct types are accessible
    let _: SwiftProtoReflect.FieldAccessor.Type = FieldAccessor.self
    let _: SwiftProtoReflect.WellKnownTypeNames.Type = WellKnownTypeNames.self
    let _: SwiftProtoReflect.WellKnownTypeDetector.Type = WellKnownTypeDetector.self

    XCTAssertTrue(true, "All helper types are accessible")
  }

  // MARK: - Typealias Support

  func testTypealiasWorksWithModulePrefix() {
    // Verify typealiases can be created using module prefix
    typealias CustomValidationResult = SwiftProtoReflect.ValidationResult
    typealias CustomValidationError = SwiftProtoReflect.ValidationError
    typealias CustomMessageFactory = SwiftProtoReflect.MessageFactory

    let result: CustomValidationResult = ValidationResult(isValid: true, errors: [])
    let error: CustomValidationError = .missingRequiredField(fieldName: "test")
    let factory: CustomMessageFactory = MessageFactory()

    XCTAssertTrue(result.isValid)
    XCTAssertNotNil(error)
    XCTAssertNotNil(factory)
  }

  // MARK: - Real-World Usage Patterns

  func testFullWorkflowWithQualifiedNames() throws {
    // Verify complete workflow works with fully qualified names
    let fileDesc: SwiftProtoReflect.FileDescriptor = FileDescriptor(
      name: "user.proto",
      package: "example"
    )

    var messageDesc: SwiftProtoReflect.MessageDescriptor = MessageDescriptor(
      name: "User",
      parent: fileDesc
    )

    let nameField: SwiftProtoReflect.FieldDescriptor = FieldDescriptor(
      name: "name",
      number: 1,
      type: .string
    )

    messageDesc.addField(nameField)

    let factory: SwiftProtoReflect.MessageFactory = MessageFactory()
    var message: SwiftProtoReflect.DynamicMessage = factory.createMessage(from: messageDesc)

    try message.set("Alice", forField: "name")

    let serializer: SwiftProtoReflect.BinarySerializer = BinarySerializer()
    let data = try serializer.serialize(message)

    XCTAssertFalse(data.isEmpty)

    let deserializer: SwiftProtoReflect.BinaryDeserializer = BinaryDeserializer()
    let deserializedMessage = try deserializer.deserialize(data, using: messageDesc)

    let name = try deserializedMessage.get(forField: "name") as? String
    XCTAssertEqual(name, "Alice")
  }

  func testComplexWorkflowWithValidation() throws {
    // Verify validation workflow with fully qualified names
    let file: SwiftProtoReflect.FileDescriptor = FileDescriptor(name: "user.proto", package: "app")
    var user: SwiftProtoReflect.MessageDescriptor = MessageDescriptor(name: "User", parent: file)

    let nameField: SwiftProtoReflect.FieldDescriptor = FieldDescriptor(name: "name", number: 1, type: .string)
    let ageField: SwiftProtoReflect.FieldDescriptor = FieldDescriptor(name: "age", number: 2, type: .int32)
    user.addField(nameField)
    user.addField(ageField)

    let factory: SwiftProtoReflect.MessageFactory = MessageFactory()
    var message: SwiftProtoReflect.DynamicMessage = factory.createMessage(from: user)

    try message.set("Bob", forField: "name")
    try message.set(Int32(25), forField: "age")

    let validationResult: SwiftProtoReflect.ValidationResult = factory.validate(message)
    XCTAssertTrue(validationResult.isValid)

    let serializer: SwiftProtoReflect.JSONSerializer = JSONSerializer()
    let jsonData = try serializer.serialize(message)
    XCTAssertFalse(jsonData.isEmpty)

    let deserializer: SwiftProtoReflect.JSONDeserializer = JSONDeserializer()
    let restored: SwiftProtoReflect.DynamicMessage = try deserializer.deserialize(jsonData, using: user)

    let restoredName = try restored.get(forField: "name") as? String
    let restoredAge = try restored.get(forField: "age") as? Int32

    XCTAssertEqual(restoredName, "Bob")
    XCTAssertEqual(restoredAge, 25)
  }

  // MARK: - Registry Integration

  func testRegistryTypesWithModulePrefix() {
    // Verify registry types work with module prefix
    let registry: SwiftProtoReflect.TypeRegistry = TypeRegistry()
    let pool: SwiftProtoReflect.DescriptorPool = DescriptorPool()

    XCTAssertNotNil(registry)
    XCTAssertNotNil(pool)
  }

  // MARK: - Namespace Pollution Prevention

  func testNoModuleLevelTypeWithModuleName() {
    // This test documents that no type in the module should have the same name
    // as the module itself to prevent namespace shadowing.
    //
    // Bad: public enum SwiftProtoReflect { ... } in module SwiftProtoReflect
    // Good: All types have unique names different from "SwiftProtoReflect"
    //
    // If this test compiles and all other tests pass, it means:
    // 1. No type shadows the module name
    // 2. All types are accessible with module prefix
    // 3. No namespace collision exists

    XCTAssertTrue(true, "Namespace is clean and collision-free")
  }

  func testExternalConsumerPatterns() throws {
    // Test common patterns external consumers might use

    // Pattern 1: Type aliases for convenience
    typealias Factory = SwiftProtoReflect.MessageFactory
    typealias Message = SwiftProtoReflect.DynamicMessage
    typealias Descriptor = SwiftProtoReflect.MessageDescriptor

    let factory: Factory = Factory()
    let fileDesc = FileDescriptor(name: "test.proto", package: "test")
    let descriptor: Descriptor = Descriptor(name: "Test", parent: fileDesc)
    let message: Message = factory.createMessage(from: descriptor)

    XCTAssertNotNil(message)

    // Pattern 2: Fully qualified names in declarations
    func processMessage(_ msg: SwiftProtoReflect.DynamicMessage) -> SwiftProtoReflect.ValidationResult {
      let factory: SwiftProtoReflect.MessageFactory = MessageFactory()
      return factory.validate(msg)
    }

    let result = processMessage(message)
    XCTAssertNotNil(result)

    // Pattern 3: Error handling with qualified names
    do {
      var mutableMessage = message
      try mutableMessage.set("value", forField: "nonexistent")
      XCTFail("Should throw error")
    }
    catch let error as SwiftProtoReflect.DynamicMessageError {
      // Error handling with qualified type name works
      XCTAssertNotNil(error)
    }
    catch {
      XCTFail("Wrong error type")
    }
  }
}
