//
// ServiceClientTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-25
//

import GRPC
import NIOCore
import NIOPosix
import XCTest

@testable import SwiftProtoReflect

final class ServiceClientTests: XCTestCase {

  // MARK: - Test Properties

  private var eventLoopGroup: EventLoopGroup!
  private var channel: GRPCChannel!
  private var serviceClient: ServiceClient!
  private var typeRegistry: TypeRegistry!
  private var messageFactory: MessageFactory!

  // MARK: - Setup & Teardown

  override func setUp() {
    super.setUp()

    eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    // Create mock channel for testing
    channel = try! GRPCChannelPool.with(
      target: .host("localhost", port: 9999),
      transportSecurity: .plaintext,
      eventLoopGroup: eventLoopGroup
    )

    typeRegistry = TypeRegistry()
    messageFactory = MessageFactory()
    serviceClient = ServiceClient(
      channel: channel,
      messageFactory: messageFactory,
      typeRegistry: typeRegistry
    )
  }

  override func tearDown() {
    try? channel.close().wait()
    try? eventLoopGroup.syncShutdownGracefully()

    serviceClient = nil
    typeRegistry = nil
    messageFactory = nil
    channel = nil
    eventLoopGroup = nil

    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testServiceClientInitialization() {
    // Given & When
    let client = ServiceClient(channel: channel)

    // Then
    XCTAssertNotNil(client)
  }

  func testServiceClientInitializationWithCustomComponents() {
    // Given
    let customRegistry = TypeRegistry()
    let customFactory = MessageFactory()

    // When
    let client = ServiceClient(
      channel: channel,
      messageFactory: customFactory,
      typeRegistry: customRegistry
    )

    // Then
    XCTAssertNotNil(client)
  }

  // MARK: - CallOptions Tests

  func testCallOptionsInitialization() {
    // Given & When
    let options = ServiceClient.CallOptions()

    // Then
    XCTAssertNil(options.timeout)
    XCTAssertTrue(options.metadata.isEmpty)
  }

  func testCallOptionsWithCustomValues() {
    // Given
    let timeout = TimeAmount.seconds(30)
    let metadata = ["authorization": "Bearer token", "user-id": "123"]

    // When
    let options = ServiceClient.CallOptions(timeout: timeout, metadata: metadata)

    // Then
    XCTAssertEqual(options.timeout, timeout)
    XCTAssertEqual(options.metadata, metadata)
  }

  // MARK: - UnaryCallResult Tests

  func testUnaryCallResultInitialization() {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let message = messageFactory.createMessage(from: messageDescriptor)

    // When
    let result = ServiceClient.UnaryCallResult(response: message)

    // Then
    XCTAssertEqual(result.response.descriptor.name, "TestMessage")
    XCTAssertTrue(result.metadata.isEmpty)
    XCTAssertTrue(result.trailingMetadata.isEmpty)
  }

  func testUnaryCallResultWithMetadata() {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let message = messageFactory.createMessage(from: messageDescriptor)
    let metadata = ["response-id": "abc123"]
    let trailingMetadata = ["status": "ok"]

    // When
    let result = ServiceClient.UnaryCallResult(
      response: message,
      metadata: metadata,
      trailingMetadata: trailingMetadata
    )

    // Then
    XCTAssertEqual(result.metadata, metadata)
    XCTAssertEqual(result.trailingMetadata, trailingMetadata)
  }

  // MARK: - Helper Methods Tests

  func testGetMethodTypeForAllCombinations() async {
    // Given
    let testCases: [(Bool, Bool, String)] = [
      (false, false, "unary"),
      (true, false, "client streaming"),
      (false, true, "server streaming"),
      (true, true, "bidirectional streaming"),
    ]

    for (clientStreaming, serverStreaming, expectedType) in testCases {
      // When
      let method = ServiceDescriptor.MethodDescriptor(
        name: "TestMethod",
        inputType: "test.Request",
        outputType: "test.Response",
        clientStreaming: clientStreaming,
        serverStreaming: serverStreaming
      )

      // Then - verify through public methods that use getMethodType
      let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
      var serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)
      serviceDescriptor.addMethod(method)

      // Create test message
      var messageDescriptor = MessageDescriptor(name: "Request", parent: fileDescriptor)
      messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

      let request = messageFactory.createMessage(from: messageDescriptor)

      // For non-unary methods, expect invalidMethodType error
      if expectedType != "unary" {
        do {
          _ = try await serviceClient.unaryCall(
            service: serviceDescriptor,
            method: "TestMethod",
            request: request
          )
          XCTFail("Expected invalidMethodType error for \(expectedType)")
        }
        catch let error as ServiceClientError {
          if case .invalidMethodType(_, let expected, let actual) = error {
            XCTAssertEqual(expected, "unary")
            XCTAssertEqual(actual, expectedType)
          }
          else {
            XCTFail("Expected invalidMethodType error, got \(error)")
          }
        }
        catch {
          XCTFail("Unexpected error: \(error)")
        }
      }
    }
  }

  func testSerializeRequestWithValidMessage() throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var messageDescriptor = MessageDescriptor(name: "TestRequest", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "age", number: 2, type: .int32))

    var message = messageFactory.createMessage(from: messageDescriptor)
    try message.set("John", forField: "name")
    try message.set(Int32(30), forField: "age")

    // When - test through public API that uses serializeRequest
    let serializer = BinarySerializer()
    let data = try serializer.serialize(message)

    // Then
    XCTAssertFalse(data.isEmpty)
    XCTAssertGreaterThan(data.count, 0)
  }

  func testDeserializeResponseWithValidData() throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var messageDescriptor = MessageDescriptor(name: "TestResponse", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "result", number: 1, type: .string))

    var originalMessage = messageFactory.createMessage(from: messageDescriptor)
    try originalMessage.set("success", forField: "result")

    // Serialize message
    let serializer = BinarySerializer()
    let data = try serializer.serialize(originalMessage)

    // When - deserialize back
    let deserializer = BinaryDeserializer()
    let deserializedMessage = try deserializer.deserialize(data, using: messageDescriptor)

    // Then
    XCTAssertEqual(deserializedMessage.descriptor.name, "TestResponse")
    let result = try deserializedMessage.get(forField: "result") as? String
    XCTAssertEqual(result, "success")
  }

  func testCreateGRPCCallOptionsWithTimeout() {
    // Given
    let timeout = TimeAmount.seconds(30)
    let options = ServiceClient.CallOptions(timeout: timeout)

    // When - test options creation
    XCTAssertEqual(options.timeout, timeout)

    // Then - verify that options are correctly created
    XCTAssertNotNil(options.timeout)
    XCTAssertEqual(options.timeout, .seconds(30))
  }

  func testCreateGRPCCallOptionsWithMetadata() {
    // Given
    let metadata = ["authorization": "Bearer token", "user-id": "123"]
    let _ = ServiceClient.CallOptions(metadata: metadata)

    // When
    var grpcOptions = GRPC.CallOptions()
    for (key, value) in metadata {
      grpcOptions.customMetadata.add(name: key, value: value)
    }

    // Then
    XCTAssertEqual(grpcOptions.customMetadata.count, 2)
    XCTAssertTrue(grpcOptions.customMetadata.contains(name: "authorization"))
    XCTAssertTrue(grpcOptions.customMetadata.contains(name: "user-id"))
  }

  // MARK: - GRPCPayloadWrapper Tests

  func testGRPCPayloadWrapperInitialization() {
    // Given
    let testData = "Hello, World!".data(using: .utf8)!

    // When
    let wrapper = GRPCPayloadWrapper(data: testData)

    // Then
    XCTAssertEqual(wrapper.data, testData)
  }

  func testGRPCPayloadWrapperSerialization() throws {
    // Given
    let testData = "Test message".data(using: .utf8)!
    let wrapper = GRPCPayloadWrapper(data: testData)
    var buffer = ByteBuffer()

    // When
    try wrapper.serialize(into: &buffer)

    // Then
    let serializedData = Data(buffer: buffer)
    XCTAssertEqual(serializedData, testData)
  }

  func testGRPCPayloadWrapperDeserialization() throws {
    // Given
    let testData = "Test message".data(using: .utf8)!
    var buffer = ByteBuffer()
    buffer.writeData(testData)

    // When
    let wrapper = try GRPCPayloadWrapper(serializedByteBuffer: &buffer)

    // Then
    XCTAssertEqual(wrapper.data, testData)
  }

  func testGRPCPayloadWrapperRoundTrip() throws {
    // Given
    let originalData = "Round trip test".data(using: .utf8)!
    let originalWrapper = GRPCPayloadWrapper(data: originalData)

    // When - serialize
    var buffer = ByteBuffer()
    try originalWrapper.serialize(into: &buffer)

    // Then - deserialize
    let deserializedWrapper = try GRPCPayloadWrapper(serializedByteBuffer: &buffer)
    XCTAssertEqual(deserializedWrapper.data, originalData)
  }

  func testGRPCPayloadWrapperWithEmptyData() throws {
    // Given
    let emptyData = Data()
    let wrapper = GRPCPayloadWrapper(data: emptyData)

    // When
    var buffer = ByteBuffer()
    try wrapper.serialize(into: &buffer)
    let deserializedWrapper = try GRPCPayloadWrapper(serializedByteBuffer: &buffer)

    // Then
    XCTAssertEqual(deserializedWrapper.data, emptyData)
    XCTAssertTrue(deserializedWrapper.data.isEmpty)
  }

  func testGRPCPayloadWrapperWithLargeData() throws {
    // Given
    let largeData = Data(repeating: 0xFF, count: 10000)
    let wrapper = GRPCPayloadWrapper(data: largeData)

    // When
    var buffer = ByteBuffer()
    try wrapper.serialize(into: &buffer)
    let deserializedWrapper = try GRPCPayloadWrapper(serializedByteBuffer: &buffer)

    // Then
    XCTAssertEqual(deserializedWrapper.data, largeData)
    XCTAssertEqual(deserializedWrapper.data.count, 10000)
  }

  // MARK: - Error Validation Tests

  func testMethodNotFoundError() async throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)

    var messageDescriptor = MessageDescriptor(name: "TestRequest", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let request = messageFactory.createMessage(from: messageDescriptor)

    // When & Then
    do {
      _ = try await serviceClient.unaryCall(
        service: serviceDescriptor,
        method: "NonExistentMethod",
        request: request
      )
      XCTFail("Expected methodNotFound error")
    }
    catch let error as ServiceClientError {
      if case .methodNotFound(let methodName, let serviceName) = error {
        XCTAssertEqual(methodName, "NonExistentMethod")
        XCTAssertEqual(serviceName, "TestService")
      }
      else {
        XCTFail("Expected methodNotFound error, got \(error)")
      }
    }
  }

  func testInvalidMethodTypeError() async throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)

    // Add streaming method
    let streamingMethod = ServiceDescriptor.MethodDescriptor(
      name: "StreamingMethod",
      inputType: "test.TestRequest",
      outputType: "test.TestResponse",
      clientStreaming: true,
      serverStreaming: false
    )
    serviceDescriptor.addMethod(streamingMethod)

    var messageDescriptor = MessageDescriptor(name: "TestRequest", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let request = messageFactory.createMessage(from: messageDescriptor)

    // When & Then
    do {
      _ = try await serviceClient.unaryCall(
        service: serviceDescriptor,
        method: "StreamingMethod",
        request: request
      )
      XCTFail("Expected invalidMethodType error")
    }
    catch let error as ServiceClientError {
      if case .invalidMethodType(let methodName, let expected, let actual) = error {
        XCTAssertEqual(methodName, "StreamingMethod")
        XCTAssertEqual(expected, "unary")
        XCTAssertEqual(actual, "client streaming")
      }
      else {
        XCTFail("Expected invalidMethodType error, got \(error)")
      }
    }
  }

  func testTypeMismatchError() async throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)

    // Add unary method
    let unaryMethod = ServiceDescriptor.MethodDescriptor(
      name: "TestMethod",
      inputType: "test.ExpectedRequest",
      outputType: "test.TestResponse"
    )
    serviceDescriptor.addMethod(unaryMethod)

    // Create message with wrong type
    var wrongMessageDescriptor = MessageDescriptor(name: "WrongRequest", parent: fileDescriptor)
    wrongMessageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let wrongRequest = messageFactory.createMessage(from: wrongMessageDescriptor)

    // When & Then
    do {
      _ = try await serviceClient.unaryCall(
        service: serviceDescriptor,
        method: "TestMethod",
        request: wrongRequest
      )
      XCTFail("Expected typeMismatch error")
    }
    catch let error as ServiceClientError {
      if case .typeMismatch(let expected, let actual) = error {
        XCTAssertEqual(expected, "test.ExpectedRequest")
        XCTAssertEqual(actual, "test.WrongRequest")
      }
      else {
        XCTFail("Expected typeMismatch error, got \(error)")
      }
    }
  }

  func testTypeNotFoundError() async throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)

    // Add unary method with non-existent response type
    let unaryMethod = ServiceDescriptor.MethodDescriptor(
      name: "TestMethod",
      inputType: "test.TestRequest",
      outputType: "test.NonExistentResponse"
    )
    serviceDescriptor.addMethod(unaryMethod)

    var messageDescriptor = MessageDescriptor(name: "TestRequest", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let request = messageFactory.createMessage(from: messageDescriptor)

    // When & Then
    do {
      _ = try await serviceClient.unaryCall(
        service: serviceDescriptor,
        method: "TestMethod",
        request: request
      )
      XCTFail("Expected typeNotFound error")
    }
    catch let error as ServiceClientError {
      if case .typeNotFound(let typeName) = error {
        XCTAssertEqual(typeName, "test.NonExistentResponse")
      }
      else {
        XCTFail("Expected typeNotFound error, got \(error)")
      }
    }
  }

  // MARK: - Serialization Error Tests

  func testSerializationErrorHandling() {
    // Given
    let underlyingError = NSError(
      domain: "SerializationError",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Test serialization error"]
    )
    let serializationError = ServiceClientError.serializationError(underlying: underlyingError)

    // When & Then
    XCTAssertTrue(serializationError.description.contains("Serialization error"))
    XCTAssertTrue(serializationError.description.contains("Test serialization error"))
  }

  func testDeserializationErrorHandling() {
    // Given
    let underlyingError = NSError(
      domain: "DeserializationError",
      code: 2,
      userInfo: [NSLocalizedDescriptionKey: "Test deserialization error"]
    )
    let deserializationError = ServiceClientError.deserializationError(underlying: underlyingError)

    // When & Then
    XCTAssertTrue(deserializationError.description.contains("Deserialization error"))
    XCTAssertTrue(deserializationError.description.contains("Test deserialization error"))
  }

  func testGRPCErrorHandling() {
    // Given
    let underlyingError = NSError(
      domain: "GRPCError",
      code: 3,
      userInfo: [NSLocalizedDescriptionKey: "Test gRPC error"]
    )
    let grpcError = ServiceClientError.grpcError(underlying: underlyingError)

    // When & Then
    XCTAssertTrue(grpcError.description.contains("gRPC error"))
    XCTAssertTrue(grpcError.description.contains("Test gRPC error"))
  }

  // MARK: - Validation Tests

  func testValidateRequestTypeWithMatchingType() async throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var messageDescriptor = MessageDescriptor(name: "TestRequest", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let request = messageFactory.createMessage(from: messageDescriptor)
    let expectedType = "test.TestRequest"

    // When & Then - verify through public API
    // Create service with correct type
    var serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)
    let method = ServiceDescriptor.MethodDescriptor(
      name: "TestMethod",
      inputType: expectedType,
      outputType: "test.TestResponse"
    )
    serviceDescriptor.addMethod(method)

    // Register types in registry
    try typeRegistry.registerMessage(messageDescriptor)

    // Create response type
    var responseDescriptor = MessageDescriptor(name: "TestResponse", parent: fileDescriptor)
    responseDescriptor.addField(FieldDescriptor(name: "result", number: 1, type: .string))
    try typeRegistry.registerMessage(responseDescriptor)

    // Test will pass until gRPC call stage (which will fail, but type validation will pass)
    do {
      _ = try await serviceClient.unaryCall(
        service: serviceDescriptor,
        method: "TestMethod",
        request: request
      )
    }
    catch {
      // Expect gRPC error, but not type validation error
      XCTAssertFalse(error is ServiceClientError, "Should not be a ServiceClientError for type validation")
    }
  }

  func testGetResponseDescriptorWithValidType() throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var responseDescriptor = MessageDescriptor(name: "TestResponse", parent: fileDescriptor)
    responseDescriptor.addField(FieldDescriptor(name: "result", number: 1, type: .string))

    // Register type in registry
    try typeRegistry.registerMessage(responseDescriptor)

    // When
    let foundDescriptor = typeRegistry.findMessage(named: "test.TestResponse")

    // Then
    XCTAssertNotNil(foundDescriptor)
    XCTAssertEqual(foundDescriptor?.name, "TestResponse")
    XCTAssertEqual(foundDescriptor?.fullName, "test.TestResponse")
  }

  // MARK: - Error Description Tests

  func testServiceClientErrorDescriptions() {
    // Given & When & Then
    let methodNotFoundError = ServiceClientError.methodNotFound(methodName: "test", serviceName: "service")
    XCTAssertEqual(methodNotFoundError.description, "Method 'test' not found in service 'service'")

    let invalidMethodTypeError = ServiceClientError.invalidMethodType(
      methodName: "test",
      expected: "unary",
      actual: "streaming"
    )
    XCTAssertEqual(invalidMethodTypeError.description, "Method 'test' has type 'streaming', expected 'unary'")

    let typeMismatchError = ServiceClientError.typeMismatch(expected: "TypeA", actual: "TypeB")
    XCTAssertEqual(typeMismatchError.description, "Type mismatch: expected 'TypeA', got 'TypeB'")

    let typeNotFoundError = ServiceClientError.typeNotFound(typeName: "MissingType")
    XCTAssertEqual(typeNotFoundError.description, "Type 'MissingType' not found in registry")

    let serializationError = ServiceClientError.serializationError(underlying: NSError(domain: "test", code: 1))
    XCTAssertTrue(serializationError.description.contains("Serialization error"))

    let deserializationError = ServiceClientError.deserializationError(underlying: NSError(domain: "test", code: 2))
    XCTAssertTrue(deserializationError.description.contains("Deserialization error"))

    let grpcError = ServiceClientError.grpcError(underlying: NSError(domain: "grpc", code: 3))
    XCTAssertTrue(grpcError.description.contains("gRPC error"))
  }

  // MARK: - Edge Cases Tests

  func testUnaryCallWithEmptyServiceName() async throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let serviceDescriptor = ServiceDescriptor(name: "", parent: fileDescriptor)

    var messageDescriptor = MessageDescriptor(name: "TestRequest", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let request = messageFactory.createMessage(from: messageDescriptor)

    // When & Then
    do {
      _ = try await serviceClient.unaryCall(
        service: serviceDescriptor,
        method: "TestMethod",
        request: request
      )
      XCTFail("Expected methodNotFound error")
    }
    catch let error as ServiceClientError {
      if case .methodNotFound(let methodName, let serviceName) = error {
        XCTAssertEqual(methodName, "TestMethod")
        XCTAssertEqual(serviceName, "")
      }
      else {
        XCTFail("Expected methodNotFound error, got \(error)")
      }
    }
  }

  func testUnaryCallWithComplexMetadata() {
    // Given
    let complexMetadata = [
      "authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
      "user-agent": "SwiftProtoReflect/1.0.0",
      "x-request-id": "12345-67890-abcdef",
      "content-type": "application/grpc+proto",
      "grpc-timeout": "30S",
    ]

    // When
    let options = ServiceClient.CallOptions(
      timeout: .seconds(30),
      metadata: complexMetadata
    )

    // Then
    XCTAssertEqual(options.timeout, .seconds(30))
    XCTAssertEqual(options.metadata.count, 5)
    XCTAssertEqual(options.metadata["authorization"], "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
    XCTAssertEqual(options.metadata["user-agent"], "SwiftProtoReflect/1.0.0")
    XCTAssertEqual(options.metadata["x-request-id"], "12345-67890-abcdef")
  }
}

// MARK: - Private Extensions for Testing

extension ServiceClientTests {

  /// Creates a test GRPCPayloadWrapper for internal testing.
  fileprivate func createTestGRPCPayloadWrapper(with data: Data) -> GRPCPayloadWrapper {
    return GRPCPayloadWrapper(data: data)
  }
}

// MARK: - GRPCPayloadWrapper Testing Extension

/// Extension for testing GRPCPayloadWrapper
extension GRPCPayloadWrapper {
  /// Initializer for testing.
  init(testData: Data) {
    self.init(data: testData)
  }
}
