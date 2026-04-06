# SwiftProtoReflect — Public API

---

## Sources/SwiftProtoReflect/Descriptor/DescriptorOption.swift
 - public enum DescriptorOption: Equatable, Sendable
 - case bool(Bool)
 - case int(Int)
 - case string(String)
 - case float(Float)
 - case double(Double)
 - case bytes(Data)
 - public var asAny: Any

---

## Sources/SwiftProtoReflect/Descriptor/DescriptorParent.swift
 - public protocol DescriptorParent: Sendable
 - var descriptorFullNamePrefix: String { get }
 - var descriptorFilePath: String? { get }
 - var descriptorSyntax: String { get }
 - var descriptorParentMessageFullName: String? { get }
 - extension FileDescriptor: DescriptorParent
 - public var descriptorFullNamePrefix: String
 - public var descriptorFilePath: String?
 - public var descriptorSyntax: String
 - public var descriptorParentMessageFullName: String?
 - extension MessageDescriptor: DescriptorParent
 - public var descriptorFullNamePrefix: String
 - public var descriptorFilePath: String?
 - public var descriptorSyntax: String
 - public var descriptorParentMessageFullName: String?

---

## Sources/SwiftProtoReflect/Descriptor/FieldDescriptor.swift
 - public struct FieldDescriptor: Equatable, Sendable
 - public let name: String
 - public let jsonName: String
 - public let number: Int
 - public let type: FieldType
 - public let typeName: String?
 - public let isRepeated: Bool
 - public let isOptional: Bool
 - public let isRequired: Bool
 - public let isMap: Bool
 - public let oneofIndex: Int?
 - public let proto3Optional: Bool
 - public let mapEntryInfo: MapEntryInfo?
 - public let defaultValue: DescriptorOption?
 - public let isPacked: Bool?
 - public let options: [String: DescriptorOption]
 - public init(name: String, number: Int, type: FieldType, typeName: String? = nil, jsonName: String? = nil, isRepeated: Bool = false, isOptional: Bool = false, isRequired: Bool = false, isMap: Bool = false, oneofIndex: Int? = nil, proto3Optional: Bool = false, mapEntryInfo: MapEntryInfo? = nil, defaultValue: DescriptorOption? = nil, isPacked: Bool? = nil, options: [String: DescriptorOption] = [:])
 - public func getFullTypeName() -> String?
 - public func isScalarType() -> Bool
 - public func isNumericType() -> Bool
 - public func getMapKeyValueInfo() -> MapEntryInfo?
 - public func effectiveIsPacked(syntax: String) -> Bool
 - public static func == (lhs: FieldDescriptor, rhs: FieldDescriptor) -> Bool
 - public enum FieldType: Equatable, Sendable
 - case double
 - case float
 - case int32
 - case int64
 - case uint32
 - case uint64
 - case sint32
 - case sint64
 - case fixed32
 - case fixed64
 - case sfixed32
 - case sfixed64
 - case bool
 - case string
 - case bytes
 - case message
 - case enum
 - case group
 - public final class MapEntryInfo: Equatable, Sendable
 - public let keyFieldInfo: KeyFieldInfo
 - public let valueFieldInfo: ValueFieldInfo
 - public init(keyFieldInfo: KeyFieldInfo, valueFieldInfo: ValueFieldInfo)
 - public static func == (lhs: MapEntryInfo, rhs: MapEntryInfo) -> Bool
 - public struct KeyFieldInfo: Equatable, Sendable
 - public let name: String
 - public let number: Int
 - public let type: FieldType
 - public init(name: String, number: Int, type: FieldType)
 - public struct ValueFieldInfo: Equatable, Sendable
 - public let name: String
 - public let number: Int
 - public let type: FieldType
 - public let typeName: String?
 - public init(name: String, number: Int, type: FieldType, typeName: String? = nil)

---

## Sources/SwiftProtoReflect/Descriptor/EnumDescriptor.swift
 - public struct EnumDescriptor: Equatable, Sendable
 - public struct EnumValue: Equatable, Sendable
 - public let name: String
 - public let number: Int
 - public let options: [String: DescriptorOption]
 - public init(name: String, number: Int, options: [String: DescriptorOption] = [:])
 - public static func == (lhs: EnumValue, rhs: EnumValue) -> Bool
 - public let name: String
 - public let fullName: String
 - public var fileDescriptorPath: String?
 - public var parentMessageFullName: String?
 - public private(set) var valuesByName: [String: EnumValue]
 - public private(set) var valuesByNumber: [Int: EnumValue]
 - public let options: [String: DescriptorOption]
 - public init(name: String, fullName: String, options: [String: DescriptorOption] = [:])
 - public init(name: String, parent: (any DescriptorParent)? = nil, options: [String: DescriptorOption] = [:])
 - @available(*, deprecated) public init(name: String, parent: Any?, options: [String: DescriptorOption] = [:])
 - @discardableResult public mutating func addValue(_ value: EnumValue) -> Self
 - public func hasValue(named name: String) -> Bool
 - public func hasValue(number: Int) -> Bool
 - public func value(named name: String) -> EnumValue?
 - public func value(number: Int) -> EnumValue?
 - public func allValues() -> [EnumValue]
 - public func validateProto3() -> [String]
 - public func validateProto2() -> [String]
 - public static func == (lhs: EnumDescriptor, rhs: EnumDescriptor) -> Bool

---

## Sources/SwiftProtoReflect/Descriptor/FileDescriptor.swift
 - public struct FileDescriptor: Sendable
 - public let name: String
 - public let package: String
 - public let dependencies: [String]
 - public let syntax: String
 - public let options: [String: DescriptorOption]
 - public private(set) var messages: [String: MessageDescriptor]
 - public private(set) var enums: [String: EnumDescriptor]
 - public private(set) var services: [String: ServiceDescriptor]
 - public init(name: String, package: String, dependencies: [String] = [], syntax: String = "proto3", options: [String: DescriptorOption] = [:])
 - @discardableResult public mutating func addMessage(_ messageDescriptor: MessageDescriptor) -> Self
 - @discardableResult public mutating func addEnum(_ enumDescriptor: EnumDescriptor) -> Self
 - @discardableResult public mutating func addService(_ serviceDescriptor: ServiceDescriptor) -> Self
 - public func getFullName(for typeName: String) -> String
 - public func hasMessage(named name: String) -> Bool
 - public func hasEnum(named name: String) -> Bool
 - public func hasService(named name: String) -> Bool

---

## Sources/SwiftProtoReflect/Descriptor/MessageDescriptor.swift
 - public struct MessageDescriptor: Sendable
 - public let name: String
 - public let fullName: String
 - public var syntax: String
 - public var fileDescriptorPath: String?
 - public var parentMessageFullName: String?
 - public private(set) var fields: [Int: FieldDescriptor]
 - public private(set) var fieldsByName: [String: FieldDescriptor]
 - public private(set) var nestedMessages: [String: MessageDescriptor]
 - public private(set) var nestedEnums: [String: EnumDescriptor]
 - public private(set) var oneofDecls: [OneofDescriptor]
 - public private(set) var extensionRanges: [ExtensionRange]
 - public private(set) var extensions: [Int: FieldDescriptor]
 - public let options: [String: DescriptorOption]
 - public init(name: String, fullName: String, syntax: String = "proto3", options: [String: DescriptorOption] = [:])
 - public init(name: String, parent: (any DescriptorParent)? = nil, options: [String: DescriptorOption] = [:])
 - @available(*, deprecated) public init(name: String, parent: Any?, options: [String: DescriptorOption] = [:])
 - @discardableResult public mutating func addField(_ field: FieldDescriptor) -> Self
 - public func hasField(number: Int) -> Bool
 - public func hasField(named name: String) -> Bool
 - public func field(number: Int) -> FieldDescriptor?
 - public func field(named name: String) -> FieldDescriptor?
 - public func allFields() -> [FieldDescriptor]
 - @discardableResult public mutating func addOneofDecl(_ oneof: OneofDescriptor) -> Self
 - public func oneof(at index: Int) -> OneofDescriptor?
 - @discardableResult public mutating func addNestedMessage(_ message: MessageDescriptor) -> Self
 - @discardableResult public mutating func addNestedEnum(_ enumDescriptor: EnumDescriptor) -> Self
 - public func hasNestedMessage(named name: String) -> Bool
 - public func hasNestedEnum(named name: String) -> Bool
 - public func nestedMessage(named name: String) -> MessageDescriptor?
 - public func nestedEnum(named name: String) -> EnumDescriptor?
 - @discardableResult public mutating func addExtensionRange(_ range: ExtensionRange) -> Self
 - @discardableResult public mutating func addExtension(_ field: FieldDescriptor) -> Self
 - public func isExtensionNumber(_ number: Int) -> Bool
 - public struct ExtensionRange: Equatable, Hashable, Sendable
 - public let start: Int
 - public let end: Int
 - public init(start: Int, end: Int)

---

## Sources/SwiftProtoReflect/Descriptor/OneofDescriptor.swift
 - public struct OneofDescriptor: Equatable, Sendable
 - public let name: String
 - public let index: Int
 - public let options: [String: DescriptorOption]
 - public init(name: String, index: Int, options: [String: DescriptorOption] = [:])
 - public static func == (lhs: OneofDescriptor, rhs: OneofDescriptor) -> Bool

---

## Sources/SwiftProtoReflect/Descriptor/ServiceDescriptor.swift
 - public struct ServiceDescriptor: Equatable, Sendable
 - public struct MethodDescriptor: Equatable, Sendable
 - public let name: String
 - public let inputType: String
 - public let outputType: String
 - public let clientStreaming: Bool
 - public let serverStreaming: Bool
 - public let options: [String: DescriptorOption]
 - public init(name: String, inputType: String, outputType: String, clientStreaming: Bool = false, serverStreaming: Bool = false, options: [String: DescriptorOption] = [:])
 - public static func == (lhs: MethodDescriptor, rhs: MethodDescriptor) -> Bool
 - public let name: String
 - public let fullName: String
 - public var fileDescriptorPath: String?
 - public private(set) var methodsByName: [String: MethodDescriptor]
 - public let options: [String: DescriptorOption]
 - public init(name: String, fullName: String, options: [String: DescriptorOption] = [:])
 - public init(name: String, parent: FileDescriptor, options: [String: DescriptorOption] = [:])
 - @discardableResult public mutating func addMethod(_ method: MethodDescriptor) -> Self
 - public func hasMethod(named name: String) -> Bool
 - public func method(named name: String) -> MethodDescriptor?
 - public func allMethods() -> [MethodDescriptor]
 - public static func == (lhs: ServiceDescriptor, rhs: ServiceDescriptor) -> Bool

---

## Sources/SwiftProtoReflect/Dynamic/DynamicMessage.swift
 - public struct DynamicMessage: Equatable, @unchecked Sendable
 - public let descriptor: MessageDescriptor
 - public private(set) var unknownFields: Data
 - public init(descriptor: MessageDescriptor)
 - @discardableResult public mutating func set(_ value: Any, forField fieldName: String) throws -> Self
 - @discardableResult public mutating func set(_ value: Any, forField fieldNumber: Int) throws -> Self
 - public func get(forField fieldName: String) throws -> Any?
 - public func get(forField fieldNumber: Int) throws -> Any?
 - public func hasValue(forField fieldName: String) throws -> Bool
 - public func hasValue(forField fieldNumber: Int) throws -> Bool
 - @discardableResult public mutating func clearField(_ fieldName: String) throws -> Self
 - @discardableResult public mutating func clearField(_ fieldNumber: Int) throws -> Self
 - public mutating func setUnknownFields(_ data: Data)
 - @discardableResult public mutating func addRepeatedValue(_ value: Any, forField fieldName: String) throws -> Self
 - @discardableResult public mutating func addRepeatedValue(_ value: Any, forField fieldNumber: Int) throws -> Self
 - @discardableResult public mutating func setMapEntry(_ value: Any, forKey key: AnyHashable, inField fieldName: String) throws -> Self
 - @discardableResult public mutating func setMapEntry(_ value: Any, forKey key: AnyHashable, inField fieldNumber: Int) throws -> Self
 - public static func == (lhs: DynamicMessage, rhs: DynamicMessage) -> Bool
 - public enum DynamicMessageError: Error, LocalizedError, Sendable
 - case fieldNotFound(fieldName: String)
 - case fieldNotFoundByNumber(fieldNumber: Int)
 - case typeMismatch(fieldName: String, expectedType: String, actualType: String)
 - case messageMismatch(fieldName: String, expectedType: String, actualType: String)
 - case notRepeatedField(fieldName: String)
 - case notMapField(fieldName: String)
 - case invalidMapKeyType(type: FieldType)
 - public var errorDescription: String?

---

## Sources/SwiftProtoReflect/Dynamic/FieldAccessor.swift
 - public struct FieldAccessor
 - public init(_ message: DynamicMessage)
 - public func getString(_ fieldName: String) -> String?
 - public func getString(_ fieldNumber: Int) -> String?
 - public func getInt32(_ fieldName: String) -> Int32?
 - public func getInt32(_ fieldNumber: Int) -> Int32?
 - public func getInt64(_ fieldName: String) -> Int64?
 - public func getInt64(_ fieldNumber: Int) -> Int64?
 - public func getUInt32(_ fieldName: String) -> UInt32?
 - public func getUInt32(_ fieldNumber: Int) -> UInt32?
 - public func getUInt64(_ fieldName: String) -> UInt64?
 - public func getUInt64(_ fieldNumber: Int) -> UInt64?
 - public func getFloat(_ fieldName: String) -> Float?
 - public func getFloat(_ fieldNumber: Int) -> Float?
 - public func getDouble(_ fieldName: String) -> Double?
 - public func getDouble(_ fieldNumber: Int) -> Double?
 - public func getBool(_ fieldName: String) -> Bool?
 - public func getBool(_ fieldNumber: Int) -> Bool?
 - public func getData(_ fieldName: String) -> Data?
 - public func getData(_ fieldNumber: Int) -> Data?
 - public func getMessage(_ fieldName: String) -> DynamicMessage?
 - public func getMessage(_ fieldNumber: Int) -> DynamicMessage?
 - public func getStringArray(_ fieldName: String) -> [String]?
 - public func getStringArray(_ fieldNumber: Int) -> [String]?
 - public func getInt32Array(_ fieldName: String) -> [Int32]?
 - public func getInt32Array(_ fieldNumber: Int) -> [Int32]?
 - public func getInt64Array(_ fieldName: String) -> [Int64]?
 - public func getInt64Array(_ fieldNumber: Int) -> [Int64]?
 - public func getMessageArray(_ fieldName: String) -> [DynamicMessage]?
 - public func getMessageArray(_ fieldNumber: Int) -> [DynamicMessage]?
 - public func getStringMap(_ fieldName: String) -> [String: String]?
 - public func getStringMap(_ fieldNumber: Int) -> [String: String]?
 - public func getStringToInt32Map(_ fieldName: String) -> [String: Int32]?
 - public func getStringToInt32Map(_ fieldNumber: Int) -> [String: Int32]?
 - public func getStringToMessageMap(_ fieldName: String) -> [String: DynamicMessage]?
 - public func getStringToMessageMap(_ fieldNumber: Int) -> [String: DynamicMessage]?
 - public func hasValue(_ fieldName: String) -> Bool
 - public func hasValue(_ fieldNumber: Int) -> Bool
 - public func fieldExists(_ fieldName: String) -> Bool
 - public func fieldExists(_ fieldNumber: Int) -> Bool
 - public func getFieldType(_ fieldName: String) -> FieldType?
 - public func getFieldType(_ fieldNumber: Int) -> FieldType?
 - public func getValue<T>(_ fieldName: String, as type: T.Type) -> T?
 - public func getValue<T>(_ fieldNumber: Int, as type: T.Type) -> T?
 - public struct MutableFieldAccessor
 - public init(_ message: inout DynamicMessage)
 - @discardableResult public mutating func setString(_ value: String, forField fieldName: String) -> Bool
 - @discardableResult public mutating func setString(_ value: String, forField fieldNumber: Int) -> Bool
 - @discardableResult public mutating func setInt32(_ value: Int32, forField fieldName: String) -> Bool
 - @discardableResult public mutating func setInt32(_ value: Int32, forField fieldNumber: Int) -> Bool
 - @discardableResult public mutating func setBool(_ value: Bool, forField fieldName: String) -> Bool
 - @discardableResult public mutating func setBool(_ value: Bool, forField fieldNumber: Int) -> Bool
 - @discardableResult public mutating func setMessage(_ value: DynamicMessage, forField fieldName: String) -> Bool
 - @discardableResult public mutating func setMessage(_ value: DynamicMessage, forField fieldNumber: Int) -> Bool
 - public func updatedMessage() -> DynamicMessage
 - extension DynamicMessage
 - public var fieldAccessor: FieldAccessor
 - public mutating func mutableFieldAccessor() -> MutableFieldAccessor

---

## Sources/SwiftProtoReflect/Dynamic/MessageFactory.swift
 - public struct MessageFactory: @unchecked Sendable
 - public init()
 - public func createMessage(from descriptor: MessageDescriptor) -> DynamicMessage
 - public func createMessage(from descriptor: MessageDescriptor, with fieldValues: [String: Any]) throws -> DynamicMessage
 - public func createMessage(from descriptor: MessageDescriptor, with fieldValues: [Int: Any]) throws -> DynamicMessage
 - public func clone(_ message: DynamicMessage) throws -> DynamicMessage
 - public func validate(_ message: DynamicMessage) -> ValidationResult
 - @available(*, deprecated) public func validate(_ message: DynamicMessage, syntax: String) -> ValidationResult
 - public struct ValidationResult
 - public let isValid: Bool
 - public let errors: [ValidationError]
 - public init(isValid: Bool, errors: [ValidationError])
 - public enum ValidationError: Error, Equatable
 - case missingRequiredField(fieldName: String)
 - case nestedMessageValidationFailed(fieldName: String, nestedErrors: [ValidationError])
 - case repeatedFieldValidationFailed(fieldName: String, index: Int, nestedErrors: [ValidationError])
 - case mapFieldValidationFailed(fieldName: String, key: String, nestedErrors: [ValidationError])
 - case validationError(fieldName: String, error: Error)
 - public static func == (lhs: ValidationError, rhs: ValidationError) -> Bool
 - public var errorDescription: String?

---

## Sources/SwiftProtoReflect/Registry/DescriptorPool.swift
 - public class DescriptorPool: @unchecked Sendable
 - public init(includeBuiltinDescriptors: Bool = true)
 - public func addFileDescriptor(_ fileDescriptor: FileDescriptor) throws
 - public func findFileDescriptor(named fileName: String) -> FileDescriptor?
 - public func findMessageDescriptor(named fullName: String) -> MessageDescriptor?
 - public func findEnumDescriptor(named fullName: String) -> EnumDescriptor?
 - public func findServiceDescriptor(named fullName: String) -> ServiceDescriptor?
 - public func findFieldDescriptor(named fullName: String) -> FieldDescriptor?
 - public func findFileContainingSymbol(_ symbolName: String) -> FileDescriptor?
 - public func createMessage(forType typeName: String) -> DynamicMessage?
 - public func createMessage(forType typeName: String, fieldValues: [String: Any]) throws -> DynamicMessage?
 - public func allMessageTypeNames() -> [String]
 - public func allEnumTypeNames() -> [String]
 - public func allServiceNames() -> [String]
 - public func allFileNames() -> [String]
 - public func findDependencies(for typeName: String) throws -> [String]
 - public func clear()
 - public enum DescriptorPoolError: Error, Equatable
 - case duplicateFile(String)
 - case duplicateSymbol(String)
 - case symbolNotFound(String)
 - case invalidDescriptor(String)
 - public var errorDescription: String?

---

## Sources/SwiftProtoReflect/Registry/TypeRegistry.swift
 - public class TypeRegistry: @unchecked Sendable
 - public init()
 - public convenience init(fileDescriptors: [FileDescriptor]) throws
 - public func registerFile(_ fileDescriptor: FileDescriptor) throws
 - public func registerMessage(_ messageDescriptor: MessageDescriptor) throws
 - public func registerEnum(_ enumDescriptor: EnumDescriptor) throws
 - public func registerService(_ serviceDescriptor: ServiceDescriptor) throws
 - public func findFile(named fileName: String) -> FileDescriptor?
 - public func findMessage(named fullName: String) -> MessageDescriptor?
 - public func findEnum(named fullName: String) -> EnumDescriptor?
 - public func findService(named fullName: String) -> ServiceDescriptor?
 - public func syntaxForType(_ fullName: String) -> String?
 - public func findExtension(forMessage messageFullName: String, fieldNumber: Int) -> FieldDescriptor?
 - public func hasFile(named fileName: String) -> Bool
 - public func hasMessage(named fullName: String) -> Bool
 - public func hasEnum(named fullName: String) -> Bool
 - public func hasService(named fullName: String) -> Bool
 - public func allFiles() -> [FileDescriptor]
 - public func allMessages() -> [MessageDescriptor]
 - public func allEnums() -> [EnumDescriptor]
 - public func allServices() -> [ServiceDescriptor]
 - public func resolveDependencies(for fullName: String) throws -> [String]
 - public func clear()
 - public func removeFile(named fileName: String) -> Bool
 - public enum RegistryError: Error, Equatable
 - case duplicateFile(String)
 - case duplicateType(String)
 - case typeNotFound(String)
 - public var errorDescription: String?

---

## Sources/SwiftProtoReflect/Bridge/DescriptorBridge.swift
 - public struct DescriptorBridge
 - public init()
 - public func toProtobufDescriptor(from messageDescriptor: MessageDescriptor) throws -> Google_Protobuf_DescriptorProto
 - public func fromProtobufDescriptor(_ protobufDescriptor: Google_Protobuf_DescriptorProto, parent: (any DescriptorParent)? = nil) throws -> MessageDescriptor
 - @available(*, deprecated) public func fromProtobufDescriptor(_ protobufDescriptor: Google_Protobuf_DescriptorProto, parent: FileDescriptor? = nil) throws -> MessageDescriptor
 - public func toProtobufFieldDescriptor(from fieldDescriptor: FieldDescriptor) throws -> Google_Protobuf_FieldDescriptorProto
 - public func fromProtobufFieldDescriptor(_ protobufDescriptor: Google_Protobuf_FieldDescriptorProto, syntax: String = "proto3") throws -> FieldDescriptor
 - public func toProtobufEnumDescriptor(from enumDescriptor: EnumDescriptor) throws -> Google_Protobuf_EnumDescriptorProto
 - public func fromProtobufEnumDescriptor(_ protobufDescriptor: Google_Protobuf_EnumDescriptorProto, parent: (any DescriptorParent)? = nil) throws -> EnumDescriptor
 - @available(*, deprecated) public func fromProtobufEnumDescriptor(_ protobufDescriptor: Google_Protobuf_EnumDescriptorProto, parent: Any?) throws -> EnumDescriptor
 - public func toProtobufFileDescriptor(from fileDescriptor: FileDescriptor) throws -> Google_Protobuf_FileDescriptorProto
 - public func fromProtobufFileDescriptor(_ protobufDescriptor: Google_Protobuf_FileDescriptorProto) throws -> FileDescriptor
 - public func toProtobufServiceDescriptor(from serviceDescriptor: ServiceDescriptor) throws -> Google_Protobuf_ServiceDescriptorProto
 - public func fromProtobufServiceDescriptor(_ protobufDescriptor: Google_Protobuf_ServiceDescriptorProto, parent: FileDescriptor? = nil) throws -> ServiceDescriptor
 - public enum DescriptorBridgeError: Error, LocalizedError
 - case unsupportedFieldType(Int)
 - case conversionFailed(String)
 - case missingRequiredField(String)
 - case invalidDescriptorStructure(String)
 - public var errorDescription: String?

---

## Sources/SwiftProtoReflect/Bridge/StaticMessageBridge.swift
 - public struct StaticMessageBridge
 - public init()
 - public func toDynamicMessage<T: SwiftProtobuf.Message>(from staticMessage: T, using descriptor: MessageDescriptor) throws -> DynamicMessage
 - public func toDynamicMessage<T: SwiftProtobuf.Message>(from staticMessage: T) throws -> DynamicMessage
 - public func toStaticMessage<T: SwiftProtobuf.Message>(from dynamicMessage: DynamicMessage, as messageType: T.Type) throws -> T
 - public func toDynamicMessages<T: SwiftProtobuf.Message>(from staticMessages: [T], using descriptor: MessageDescriptor) throws -> [DynamicMessage]
 - public func toStaticMessages<T: SwiftProtobuf.Message>(from dynamicMessages: [DynamicMessage], as messageType: T.Type) throws -> [T]
 - public func isCompatible<T: SwiftProtobuf.Message>(staticMessage: T, with descriptor: MessageDescriptor) -> Bool
 - public func isCompatible<T: SwiftProtobuf.Message>(dynamicMessage: DynamicMessage, with messageType: T.Type) -> Bool
 - public enum StaticMessageBridgeError: Error, LocalizedError
 - case incompatibleTypes(staticType: String, descriptorType: String)
 - case serializationFailed(underlying: Error)
 - case deserializationFailed(underlying: Error)
 - case descriptorCreationFailed(messageType: String)
 - case unsupportedMessageType(String)
 - public var errorDescription: String?
 - extension DynamicMessage
 - public func toStaticMessage<T: SwiftProtobuf.Message>(as messageType: T.Type) throws -> T
 - extension SwiftProtobuf.Message
 - public func toDynamicMessage(using descriptor: MessageDescriptor) throws -> DynamicMessage
 - public func toDynamicMessage() throws -> DynamicMessage

---

## Sources/SwiftProtoReflect/Serialization/WireFormat.swift
 - public enum WireType: UInt32, Equatable, Sendable
 - case varint = 0
 - case fixed64 = 1
 - case lengthDelimited = 2
 - case startGroup = 3
 - case endGroup = 4
 - case fixed32 = 5

---

## Sources/SwiftProtoReflect/Serialization/BinarySerializer.swift
 - public struct BinarySerializer: Sendable
 - public let options: SerializationOptions
 - public init(options: SerializationOptions = SerializationOptions())
 - public func serialize(_ message: DynamicMessage) throws -> Data
 - public struct SerializationOptions: Sendable
 - public let usePackedRepeated: Bool
 - public init(usePackedRepeated: Bool = true)
 - public enum SerializationError: Error, Equatable, Sendable
 - case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
 - case valueTypeMismatch(expected: String, actual: String)
 - case missingMapEntryInfo(fieldName: String)
 - case missingFieldValue(fieldName: String)
 - case unsupportedFieldType(type: String)
 - public var description: String

---

## Sources/SwiftProtoReflect/Serialization/BinaryDeserializer.swift
 - public struct BinaryDeserializer
 - public let options: DeserializationOptions
 - public init(options: DeserializationOptions)
 - @available(*, deprecated) public init()
 - public func deserialize(_ data: Data, using descriptor: MessageDescriptor) throws -> DynamicMessage
 - public struct DeserializationOptions
 - public let preserveUnknownFields: Bool
 - public let strictUTF8Validation: Bool
 - public let typeRegistry: TypeRegistry
 - public init(preserveUnknownFields: Bool = true, strictUTF8Validation: Bool = true, typeRegistry: TypeRegistry)
 - @available(*, deprecated) public init(preserveUnknownFields: Bool = true, strictUTF8Validation: Bool = true)
 - public enum DeserializationError: Error, Equatable
 - case truncatedVarint
 - case truncatedMessage
 - case invalidWireType(tag: UInt32)
 - case wireTypeMismatch(fieldName: String, expected: WireType, actual: WireType)
 - case invalidUTF8String
 - case malformedPackedField(fieldName: String)
 - case malformedMapEntry(fieldName: String)
 - case missingMapEntryInfo(fieldName: String)
 - case missingTypeName(fieldType: String)
 - case unsupportedNestedMessage(typeName: String)
 - case unsupportedFieldType(type: String)
 - public var description: String

---

## Sources/SwiftProtoReflect/Serialization/JSONSerializer.swift
 - public struct JSONSerializer
 - public let options: JSONSerializationOptions
 - public init(options: JSONSerializationOptions)
 - @available(*, deprecated) public init()
 - public func serialize(_ message: DynamicMessage) throws -> Data
 - public struct JSONSerializationOptions
 - public let useOriginalFieldNames: Bool
 - public let prettyPrinted: Bool
 - public let includeDefaultValues: Bool
 - public let useCanonicalWellKnownTypeEncoding: Bool
 - public let typeRegistry: TypeRegistry
 - public init(useOriginalFieldNames: Bool = false, prettyPrinted: Bool = false, includeDefaultValues: Bool = false, useCanonicalWellKnownTypeEncoding: Bool = true, typeRegistry: TypeRegistry)
 - @available(*, deprecated) public init(useOriginalFieldNames: Bool = false, prettyPrinted: Bool = false, includeDefaultValues: Bool = false)
 - public enum JSONSerializationError: Error, Equatable
 - case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
 - case valueTypeMismatch(expected: String, actual: String)
 - case missingMapEntryInfo(fieldName: String)
 - case missingFieldValue(fieldName: String)
 - case unsupportedFieldType(type: String)
 - case invalidMapKeyType(keyType: String)
 - case jsonWriteError(underlyingError: Error)
 - case unsupportedWellKnownTypeEncoding(typeName: String)
 - public var description: String
 - public static func == (lhs: JSONSerializationError, rhs: JSONSerializationError) -> Bool

---

## Sources/SwiftProtoReflect/Serialization/JSONDeserializer.swift
 - public struct JSONDeserializer
 - public let options: JSONDeserializationOptions
 - public init(options: JSONDeserializationOptions)
 - @available(*, deprecated) public init()
 - public func deserialize(_ data: Data, using descriptor: MessageDescriptor) throws -> DynamicMessage
 - public struct JSONDeserializationOptions
 - public let ignoreUnknownFields: Bool
 - public let strictTypeValidation: Bool
 - public let typeRegistry: TypeRegistry
 - public let maxNestingDepth: Int
 - public init(ignoreUnknownFields: Bool = true, strictTypeValidation: Bool = true, typeRegistry: TypeRegistry, maxNestingDepth: Int = 64)
 - @available(*, deprecated) public init(ignoreUnknownFields: Bool = true, strictTypeValidation: Bool = true, maxNestingDepth: Int = 64)
 - public enum JSONDeserializationError: Error, Equatable
 - case invalidJSON(underlyingError: Error)
 - case invalidJSONStructure(expected: String, actual: String)
 - case unknownField(fieldName: String, messageName: String)
 - case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
 - case valueTypeMismatch(fieldName: String, expected: String, actual: String)
 - case invalidNumberFormat(fieldName: String, value: String)
 - case numberOutOfRange(fieldName: String, value: Int64, expectedRange: String)
 - case invalidBase64(fieldName: String, value: String)
 - case invalidEnumValue(fieldName: String, value: String)
 - case invalidMapKeyFormat(fieldName: String, keyType: String, value: String)
 - case invalidMapKeyType(fieldName: String, keyType: String)
 - case invalidMapKey(fieldName: String, key: String)
 - case invalidArrayElement(fieldName: String, index: Int, underlyingError: Error)
 - case missingMapEntryInfo(fieldName: String)
 - case missingTypeName(fieldName: String)
 - case unsupportedNestedMessage(fieldName: String, typeName: String)
 - case nestedMessageDescriptorNotFound(fieldName: String, typeName: String)
 - case nestingDepthExceeded(maxDepth: Int)
 - case unsupportedFieldType(type: String)
 - case unsupportedWellKnownTypeDecoding(typeName: String)
 - public var description: String

---

## Sources/SwiftProtoReflect/Integration/WellKnownTypes.swift
 - public struct WellKnownTypeNames
 - public static let timestamp: String
 - public static let duration: String
 - public static let empty: String
 - public static let fieldMask: String
 - public static let structType: String
 - public static let value: String
 - public static let any: String
 - public static let listValue: String
 - public static let nullValue: String
 - public static let doubleValue: String
 - public static let floatValue: String
 - public static let int64Value: String
 - public static let uint64Value: String
 - public static let int32Value: String
 - public static let uint32Value: String
 - public static let boolValue: String
 - public static let stringValue: String
 - public static let bytesValue: String
 - public static let wrapperTypes: Set<String>
 - public static let allTypes: Set<String>
 - public static let criticalTypes: Set<String>
 - public static let importantTypes: Set<String>
 - public static let advancedTypes: Set<String>
 - public struct WellKnownTypeDetector
 - public static func isWellKnownType(_ typeName: String) -> Bool
 - public static func getSupportPhase(for typeName: String) -> WellKnownSupportPhase?
 - public static func getSimpleName(for typeName: String) -> String?
 - public enum WellKnownSupportPhase: Int, CaseIterable, Sendable
 - case critical = 1
 - case important = 2
 - case advanced = 3
 - public var description: String
 - public var includedTypes: Set<String>
 - public protocol WellKnownTypeHandler
 - static var handledTypeName: String { get }
 - static var supportPhase: WellKnownSupportPhase { get }
 - static func createSpecialized(from message: DynamicMessage) throws -> Any
 - static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - static func validate(_ specialized: Any) -> Bool
 - public enum WellKnownTypeError: Error, Equatable, CustomStringConvertible
 - case unsupportedType(String)
 - case conversionFailed(from: String, to: String, reason: String)
 - case invalidData(typeName: String, reason: String)
 - case handlerNotFound(String)
 - case validationFailed(typeName: String, reason: String)
 - public var description: String
 - public final class WellKnownTypesRegistry: @unchecked Sendable
 - public static let shared: WellKnownTypesRegistry
 - public func register<T: WellKnownTypeHandler>(_ handlerType: T.Type)
 - public func getHandler(for typeName: String) -> WellKnownTypeHandler.Type?
 - public func createSpecialized(from message: DynamicMessage, typeName: String) throws -> Any
 - public func createDynamic(from specialized: Any, typeName: String) throws -> DynamicMessage
 - public func getRegisteredTypes() -> Set<String>
 - public func clear()
 - public func resetToDefaults()

---

## Sources/SwiftProtoReflect/Integration/AnyHandler.swift
 - public struct AnyHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public struct AnyValue: Equatable, CustomStringConvertible
 - public let typeUrl: String
 - public let value: Data
 - public init(typeUrl: String, value: Data) throws
 - public static func pack(_ message: DynamicMessage) throws -> AnyValue
 - public func unpack(to targetDescriptor: MessageDescriptor) throws -> DynamicMessage
 - public func getTypeName() -> String
 - public static func == (lhs: AnyValue, rhs: AnyValue) -> Bool
 - public var description: String
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - extension DynamicMessage
 - public func packIntoAny() throws -> DynamicMessage
 - public func unpackFromAny(to targetDescriptor: MessageDescriptor) throws -> DynamicMessage
 - public func isAnyOf(typeName: String) throws -> Bool
 - public func getAnyTypeName() throws -> String
 - extension AnyHandler.AnyValue
 - public func unpack(using registry: TypeRegistry) throws -> DynamicMessage

---

## Sources/SwiftProtoReflect/Integration/DurationHandler.swift
 - public struct DurationHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public struct DurationValue: Equatable, CustomStringConvertible
 - public let seconds: Int64
 - public let nanos: Int32
 - public init(seconds: Int64, nanos: Int32) throws
 - public init(from timeInterval: TimeInterval)
 - public func toTimeInterval() -> TimeInterval
 - public static func zero() -> DurationValue
 - public func abs() -> DurationValue
 - public func negated() -> DurationValue
 - public var description: String
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - extension TimeInterval
 - public init(from duration: DurationHandler.DurationValue)
 - public func toDurationValue() -> DurationHandler.DurationValue
 - extension DynamicMessage
 - public static func durationMessage(from timeInterval: TimeInterval) throws -> DynamicMessage
 - public func toTimeInterval() throws -> TimeInterval

---

## Sources/SwiftProtoReflect/Integration/EmptyHandler.swift
 - public struct EmptyHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public struct EmptyValue: Equatable, CustomStringConvertible, Sendable
 - public init()
 - public static let instance: EmptyValue
 - public var description: String
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - extension DynamicMessage
 - public static func emptyMessage() throws -> DynamicMessage
 - public func isEmpty() -> Bool
 - public func toEmpty() throws -> EmptyHandler.EmptyValue
 - extension EmptyHandler.EmptyValue
 - public static func from(_ void: Void) -> EmptyHandler.EmptyValue
 - public func toVoid()

---

## Sources/SwiftProtoReflect/Integration/FieldMaskHandler.swift
 - public struct FieldMaskHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public struct FieldMaskValue: Equatable, CustomStringConvertible
 - public let paths: [String]
 - public init(paths: [String]) throws
 - public init(path: String) throws
 - public init()
 - public func contains(_ path: String) -> Bool
 - public func covers(_ path: String) -> Bool
 - public func adding(_ path: String) throws -> FieldMaskValue
 - public func removing(_ path: String) -> FieldMaskValue
 - public func union(_ other: FieldMaskValue) -> FieldMaskValue
 - public func intersection(_ other: FieldMaskValue) -> FieldMaskValue
 - public static func empty() -> FieldMaskValue
 - public static func with(paths: [String]) throws -> FieldMaskValue
 - public var description: String
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - extension Array where Element == String
 - public func toFieldMaskValue() throws -> FieldMaskHandler.FieldMaskValue
 - extension DynamicMessage
 - public static func fieldMaskMessage(from paths: [String]) throws -> DynamicMessage
 - public func toFieldPaths() throws -> [String]

---

## Sources/SwiftProtoReflect/Integration/ListValueHandler.swift
 - public struct ListValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - public static func createListValueDescriptor() -> MessageDescriptor

---

## Sources/SwiftProtoReflect/Integration/StructHandler.swift
 - public struct StructHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public struct StructValue: Equatable, CustomStringConvertible
 - public let fields: [String: ValueValue]
 - public init(fields: [String: ValueValue] = [:])
 - public init(from dictionary: [String: Any]) throws
 - public static func empty() -> StructValue
 - public func contains(_ key: String) -> Bool
 - public func getValue(_ key: String) -> ValueValue?
 - public func adding(_ key: String, value: ValueValue) -> StructValue
 - public func removing(_ key: String) -> StructValue
 - public func merging(_ other: StructValue) -> StructValue
 - public func toDictionary() -> [String: Any]
 - public var description: String
 - public enum ValueValue: Equatable, CustomStringConvertible
 - case nullValue
 - case numberValue(Double)
 - case stringValue(String)
 - case boolValue(Bool)
 - case structValue(StructValue)
 - case listValue([ValueValue])
 - public init(from value: Any) throws
 - public func toAny() -> Any
 - public var description: String
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - extension Dictionary where Key == String, Value == Any
 - public func toStructValue() throws -> StructHandler.StructValue
 - extension DynamicMessage
 - public static func structMessage(from fields: [String: Any]) throws -> DynamicMessage
 - public func toFieldsDictionary() throws -> [String: Any]

---

## Sources/SwiftProtoReflect/Integration/StructProtoDescriptors.swift
 - public enum StructProtoDescriptors
 - public static let fileDescriptor: FileDescriptor
 - public static let structDescriptor: MessageDescriptor
 - public static let valueDescriptor: MessageDescriptor
 - public static let listValueDescriptor: MessageDescriptor
 - public static let nullValueEnum: EnumDescriptor

---

## Sources/SwiftProtoReflect/Integration/TimestampHandler.swift
 - public struct TimestampHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public struct TimestampValue: Equatable, CustomStringConvertible
 - public let seconds: Int64
 - public let nanos: Int32
 - public init(seconds: Int64, nanos: Int32) throws
 - public init(from date: Date)
 - public func toDate() -> Date
 - public static func now() -> TimestampValue
 - public var description: String
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - extension Date
 - public init(from timestamp: TimestampHandler.TimestampValue)
 - public func toTimestampValue() -> TimestampHandler.TimestampValue
 - extension DynamicMessage
 - public static func timestampMessage(from date: Date) throws -> DynamicMessage
 - public func toDate() throws -> Date

---

## Sources/SwiftProtoReflect/Integration/ValueHandler.swift
 - public struct ValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public typealias ValueValue = StructHandler.ValueValue
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - extension DynamicMessage
 - public static func valueMessage(from value: Any) throws -> DynamicMessage
 - public func toAnyValue() throws -> Any

---

## Sources/SwiftProtoReflect/Integration/WrapperHandlers.swift
 - public struct StringValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - public struct Int32ValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - public struct Int64ValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - public struct UInt32ValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - public struct UInt64ValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - public struct BoolValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - public struct FloatValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - public struct DoubleValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
 - public struct BytesValueHandler: WellKnownTypeHandler
 - public static let handledTypeName: String
 - public static let supportPhase: WellKnownSupportPhase
 - public static func createSpecialized(from message: DynamicMessage) throws -> Any
 - public static func createDynamic(from specialized: Any) throws -> DynamicMessage
 - public static func validate(_ specialized: Any) -> Bool
