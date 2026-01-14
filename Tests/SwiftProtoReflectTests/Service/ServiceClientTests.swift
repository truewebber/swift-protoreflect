//
// ServiceClientTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-25
// Updated: 2026-01-13 - Migrated to grpc-swift-2
//

import GRPCCore
import NIOCore
import NIOPosix
import XCTest

@testable import SwiftProtoReflect

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
final class ServiceClientTests: XCTestCase {

  // MARK: - Test Properties

  private var typeRegistry: TypeRegistry!
  private var messageFactory: MessageFactory!

  // MARK: - Setup & Teardown

  override func setUp() {
    super.setUp()
    typeRegistry = TypeRegistry()
    messageFactory = MessageFactory()
  }

  override func tearDown() {
    typeRegistry = nil
    messageFactory = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testServiceClientInitialization() async throws {
    // Given
    let mockTransport = MockClientTransport()

    try await withGRPCClient(transport: mockTransport) { grpcClient in
      // When
      let client = ServiceClient<MockClientTransport>(client: grpcClient)

      // Then
      XCTAssertNotNil(client)

      // Minimal yield to prevent grpc-swift-2 from considering this an empty body
      try await Task.sleep(for: .nanoseconds(1))
    }
  }

  func testServiceClientInitializationWithCustomComponents() async throws {
    // Given
    let mockTransport = MockClientTransport()

    try await withGRPCClient(transport: mockTransport) { grpcClient in
      // Create custom components inside the closure
      let customRegistry = TypeRegistry()
      let customFactory = MessageFactory()

      // When
      let client = ServiceClient<MockClientTransport>(
        client: grpcClient,
        messageFactory: customFactory,
        typeRegistry: customRegistry
      )

      // Then
      XCTAssertNotNil(client)

      // Minimal yield to prevent grpc-swift-2 from considering this an empty body
      try await Task.sleep(for: .nanoseconds(1))
    }
  }

  // MARK: - CallOptions Tests

  func testCallOptionsInitialization() {
    // Given & When
    let options = ServiceClient<MockClientTransport>.CallOptions()

    // Then
    XCTAssertNil(options.timeout)
    XCTAssertTrue(options.metadata.isEmpty)
  }

  func testCallOptionsWithCustomValues() {
    // Given
    let timeout = Duration.seconds(30)
    let metadata = ["authorization": "Bearer token", "user-id": "123"]

    // When
    let options = ServiceClient<MockClientTransport>.CallOptions(timeout: timeout, metadata: metadata)

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
    let metadata = Metadata()

    // When
    let result = ServiceClient<MockClientTransport>.UnaryCallResult(
      response: message,
      metadata: metadata,
      trailingMetadata: metadata
    )

    // Then
    XCTAssertEqual(result.response.descriptor.name, "TestMessage")
    XCTAssertEqual(result.metadata.count, 0)
    XCTAssertEqual(result.trailingMetadata.count, 0)
  }

  func testUnaryCallResultWithMetadata() {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let message = messageFactory.createMessage(from: messageDescriptor)
    var metadata = Metadata()
    metadata.addString("abc123", forKey: "response-id")

    var trailingMetadata = Metadata()
    trailingMetadata.addString("ok", forKey: "status")

    // When
    let result = ServiceClient<MockClientTransport>.UnaryCallResult(
      response: message,
      metadata: metadata,
      trailingMetadata: trailingMetadata
    )

    // Then - just verify metadata was set
    XCTAssertGreaterThan(result.metadata.count, 0)
    XCTAssertGreaterThan(result.trailingMetadata.count, 0)
  }

  // MARK: - Error Tests

  func testMethodNotFoundError() async throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)

    var messageDescriptor = MessageDescriptor(name: "TestRequest", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let request = messageFactory.createMessage(from: messageDescriptor)
    let mockTransport = MockClientTransport()

    try await withGRPCClient(transport: mockTransport) { grpcClient in
      let serviceClient = ServiceClient<MockClientTransport>(
        client: grpcClient,
        messageFactory: messageFactory,
        typeRegistry: typeRegistry
      )

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

      // Minimal yield to prevent grpc-swift-2 from considering this an empty body
      try await Task.sleep(for: .nanoseconds(1))
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
    let mockTransport = MockClientTransport()

    try await withGRPCClient(transport: mockTransport) { grpcClient in
      let serviceClient = ServiceClient<MockClientTransport>(
        client: grpcClient,
        messageFactory: messageFactory,
        typeRegistry: typeRegistry
      )

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

      // Minimal yield to prevent grpc-swift-2 from considering this an empty body
      try await Task.sleep(for: .nanoseconds(1))
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
    let mockTransport = MockClientTransport()

    try await withGRPCClient(transport: mockTransport) { grpcClient in
      let serviceClient = ServiceClient<MockClientTransport>(
        client: grpcClient,
        messageFactory: messageFactory,
        typeRegistry: typeRegistry
      )

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

      // Minimal yield to prevent grpc-swift-2 from considering this an empty body
      try await Task.sleep(for: .nanoseconds(1))
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
    let mockTransport = MockClientTransport()

    try await withGRPCClient(transport: mockTransport) { grpcClient in
      let serviceClient = ServiceClient<MockClientTransport>(
        client: grpcClient,
        messageFactory: messageFactory,
        typeRegistry: typeRegistry
      )

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

      // Minimal yield to prevent grpc-swift-2 from considering this an empty body
      try await Task.sleep(for: .nanoseconds(1))
    }
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

  // MARK: - Serialization Tests

  func testSerializeRequestWithValidMessage() throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var messageDescriptor = MessageDescriptor(name: "TestRequest", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "age", number: 2, type: .int32))

    var message = messageFactory.createMessage(from: messageDescriptor)
    try message.set("John", forField: "name")
    try message.set(Int32(30), forField: "age")

    // When
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

  // MARK: - Type Registry Tests

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

  // MARK: - Edge Cases Tests

  func testUnaryCallWithEmptyServiceName() async throws {
    // Given
    let fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let serviceDescriptor = ServiceDescriptor(name: "", parent: fileDescriptor)

    var messageDescriptor = MessageDescriptor(name: "TestRequest", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))

    let request = messageFactory.createMessage(from: messageDescriptor)
    let mockTransport = MockClientTransport()

    try await withGRPCClient(transport: mockTransport) { grpcClient in
      let serviceClient = ServiceClient<MockClientTransport>(
        client: grpcClient,
        messageFactory: messageFactory,
        typeRegistry: typeRegistry
      )

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

      // Minimal yield to prevent grpc-swift-2 from considering this an empty body
      try await Task.sleep(for: .nanoseconds(1))
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
    let options = ServiceClient<MockClientTransport>.CallOptions(
      timeout: .seconds(30),
      metadata: complexMetadata
    )

    // Then
    XCTAssertEqual(options.timeout, Duration.seconds(30))
    XCTAssertEqual(options.metadata.count, 5)
    XCTAssertEqual(options.metadata["authorization"], "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
    XCTAssertEqual(options.metadata["user-agent"], "SwiftProtoReflect/1.0.0")
    XCTAssertEqual(options.metadata["x-request-id"], "12345-67890-abcdef")
  }
}

// MARK: - Mock ClientTransport

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
final class MockClientTransport: ClientTransport, @unchecked Sendable {
  typealias Bytes = [UInt8]

  private let shutdownActor = ShutdownActor()

  var retryThrottle: GRPCCore.RetryThrottle? {
    nil
  }

  func connect() async throws {
    // Mock implementation - just wait until shutdown is called
    while !(await shutdownActor.isShutdown) {
      try await Task.sleep(for: .milliseconds(10))
    }
  }

  func beginGracefulShutdown() {
    Task {
      await shutdownActor.shutdown()
    }
  }

  func withStream<T: Sendable>(
    descriptor: MethodDescriptor,
    options: CallOptions,
    _ closure: (RPCStream<Inbound, Outbound>, ClientContext) async throws -> T
  ) async throws -> T {
    // Mock implementation - throw error to prevent actual RPC execution
    throw RPCError(code: .unimplemented, message: "Mock transport does not execute RPCs")
  }

  func config(forMethod descriptor: MethodDescriptor) -> MethodConfig? {
    nil
  }
}

// MARK: - ShutdownActor

@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
private actor ShutdownActor {
  private var _isShutdown = false

  var isShutdown: Bool {
    _isShutdown
  }

  func shutdown() {
    _isShutdown = true
  }
}
