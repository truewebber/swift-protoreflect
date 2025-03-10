import Foundation
import SwiftProtobuf

/// Handles serialization and deserialization of Protocol Buffer messages using the binary wire format.
///
/// This class provides methods for converting between `ProtoMessage` instances and binary wire format data,
/// leveraging SwiftProtobuf's wire format implementation where possible.
///
/// Example:
/// ```swift
/// // Serializing a message
/// let data = ProtoWireFormat.marshal(message: dynamicMessage)
///
/// // Deserializing a message
/// let message = ProtoWireFormat.unmarshal(data: data, messageDescriptor: personDescriptor)
/// ```
public struct ProtoWireFormat {

  /// Serializes a ProtoMessage into protobuf wire format.
  ///
  /// - Parameter message: The message to serialize.
  /// - Returns: The serialized data, or nil if serialization fails.
  public static func marshal(message: ProtoMessage) -> Data? {
    var data = Data()

    // If the message has a SwiftProtobuf descriptor, try to use SwiftProtobuf's serialization
    if let swiftProtoMessage = convertToSwiftProtoMessage(message) {
      do {
        return try swiftProtoMessage.serializedData()
      }
      catch {
        // Fall back to manual serialization if SwiftProtobuf serialization fails
      }
    }

    // Manual serialization
    let descriptor = message.descriptor()
    for field in descriptor.fields {
      if let value = message.get(field: field) {
        do {
          try encodeField(field: field, value: value, to: &data)
        }
        catch {
          // Skip fields that can't be encoded
          continue
        }
      }
    }

    return data
  }

  /// Deserializes protobuf wire format data into a ProtoMessage.
  ///
  /// - Parameters:
  ///   - data: The serialized data.
  ///   - messageDescriptor: The descriptor for the message type.
  /// - Returns: The deserialized message, or nil if deserialization fails.
  public static func unmarshal(data: Data, messageDescriptor: ProtoMessageDescriptor) -> ProtoMessage? {
    // If the message has a SwiftProtobuf descriptor, try to use SwiftProtobuf's deserialization
    if messageDescriptor.originalDescriptorProto() != nil {
      // This would be the place to use SwiftProtobuf's deserialization if we had a way to
      // create a SwiftProtobuf message from a descriptor at runtime
      // For now, we'll use our manual deserialization
    }

    // Manual deserialization
    var dataStream = data
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    while !dataStream.isEmpty {
      // Decode the field key
      let (fieldKey, fieldKeyBytes) = decodeVarint(dataStream)
      guard let fieldKey = fieldKey else {
        return nil  // Return nil if fieldKey is invalid
      }

      if fieldKeyBytes >= dataStream.count {
        break  // End of data
      }

      dataStream.removeFirst(fieldKeyBytes)

      // Extract field number and wire type from fieldKey
      let fieldNumber = Int(fieldKey >> 3)
      let wireType = Int(fieldKey & 0x07)

      // Find the field descriptor using the field number
      guard let fieldDescriptor = messageDescriptor.field(number: fieldNumber) else {
        // Skip unknown fields
        if !skipField(wireType: wireType, data: &dataStream) {
          return nil  // Return nil if field skipping fails
        }
        continue
      }

      // Decode the value based on wire type and field type
      do {
        if let value = try decodeField(fieldDescriptor: fieldDescriptor, wireType: wireType, data: &dataStream) {
          message.set(field: fieldDescriptor, value: value)
        }
      }
      catch {
        // Skip fields that can't be decoded
        if !skipField(wireType: wireType, data: &dataStream) {
          return nil  // Return nil if field skipping fails
        }
      }
    }

    return message
  }

  // MARK: - Field Encoding

  /// Encodes a field value to the wire format.
  ///
  /// - Parameters:
  ///   - field: The field descriptor.
  ///   - value: The field value.
  ///   - data: The data buffer to append to.
  /// - Throws: An error if encoding fails.
  public static func encodeField(field: ProtoFieldDescriptor, value: ProtoValue, to data: inout Data) throws {
    // Encode the field key (field number + wire type)
    let fieldNumber = field.number
    let wireType = determineWireType(for: field.type)
    let fieldKey = UInt64(fieldNumber << 3 | wireType)
    data.append(encodeVarint(fieldKey))

    // Encode the field value based on the field type
    switch field.type {
    case .int32, .int64, .sint32, .sint64, .uint32, .uint64, .bool:
      if case .intValue(let intValue) = value {
        data.append(encodeVarint(UInt64(intValue)))
      }
      else if case .uintValue(let uintValue) = value {
        data.append(encodeVarint(UInt64(uintValue)))
      }
      else if case .boolValue(let boolValue) = value {
        data.append(encodeVarint(UInt64(boolValue ? 1 : 0)))
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .fixed32, .sfixed32:
      if case .intValue(let intValue) = value {
        var v = UInt32(bitPattern: Int32(intValue))
        data.append(contentsOf: withUnsafeBytes(of: &v) { Array($0) })
      }
      else if case .uintValue(let uintValue) = value {
        var v = UInt32(uintValue)
        data.append(contentsOf: withUnsafeBytes(of: &v) { Array($0) })
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .fixed64, .sfixed64:
      if case .intValue(let intValue) = value {
        var v = UInt64(bitPattern: Int64(intValue))
        data.append(contentsOf: withUnsafeBytes(of: &v) { Array($0) })
      }
      else if case .uintValue(let uintValue) = value {
        var v = UInt64(uintValue)
        data.append(contentsOf: withUnsafeBytes(of: &v) { Array($0) })
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .float:
      if case .floatValue(let floatValue) = value {
        var v = floatValue
        data.append(contentsOf: withUnsafeBytes(of: &v) { Array($0) })
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .double:
      if case .doubleValue(let doubleValue) = value {
        var v = doubleValue
        data.append(contentsOf: withUnsafeBytes(of: &v) { Array($0) })
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .string:
      if case .stringValue(let stringValue) = value {
        let stringData = stringValue.data(using: .utf8) ?? Data()
        data.append(encodeVarint(UInt64(stringData.count)))
        data.append(stringData)
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .bytes:
      if case .bytesValue(let bytesValue) = value {
        data.append(encodeVarint(UInt64(bytesValue.count)))
        data.append(bytesValue)
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .message:
      if case .messageValue(let messageValue) = value, let messageData = marshal(message: messageValue) {
        data.append(encodeVarint(UInt64(messageData.count)))
        data.append(messageData)
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .enum:
      if case .intValue(let intValue) = value {
        data.append(encodeVarint(UInt64(intValue)))
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    default:
      throw ProtoWireFormatError.unsupportedType
    }
  }

  // MARK: - Field Decoding

  /// Decodes a field value from the wire format.
  ///
  /// - Parameters:
  ///   - fieldDescriptor: The field descriptor.
  ///   - wireType: The wire type.
  ///   - data: The data buffer to read from.
  /// - Returns: The decoded field value, or nil if decoding fails.
  /// - Throws: An error if decoding fails.
  private static func decodeField(fieldDescriptor: ProtoFieldDescriptor, wireType: Int, data: inout Data) throws
    -> ProtoValue?
  {
    // Verify that the wire type matches the expected wire type for the field type
    let expectedWireType = determineWireType(for: fieldDescriptor.type)
    if wireType != expectedWireType {
      throw ProtoWireFormatError.wireTypeMismatch
    }

    switch fieldDescriptor.type {
    case .int32, .int64, .uint32, .uint64, .bool, .enum:
      // Varint wire type (0)
      let (varintValue, valueBytes) = decodeVarint(data)
      if valueBytes >= data.count {
        throw ProtoWireFormatError.truncatedMessage
      }
      data.removeFirst(valueBytes)

      guard let value = varintValue else {
        throw ProtoWireFormatError.malformedVarint
      }

      switch fieldDescriptor.type {
      case .int32, .int64:
        return .intValue(Int(Int64(bitPattern: value)))
      case .uint32, .uint64:
        return .uintValue(UInt(value))
      case .bool:
        return .boolValue(value != 0)
      case .enum:
        return .intValue(Int(value))
      default:
        throw ProtoWireFormatError.unsupportedType
      }

    case .fixed32, .sfixed32, .float:
      // Fixed 32-bit wire type (5)
      if data.count < 4 {
        throw ProtoWireFormatError.truncatedMessage
      }

      let bytes = data.prefix(4)
      data.removeFirst(4)

      switch fieldDescriptor.type {
      case .fixed32:
        let value = bytes.withUnsafeBytes { $0.load(as: UInt32.self) }
        return .uintValue(UInt(value))
      case .sfixed32:
        let value = bytes.withUnsafeBytes { $0.load(as: Int32.self) }
        return .intValue(Int(value))
      case .float:
        let value = bytes.withUnsafeBytes { $0.load(as: Float.self) }
        return .floatValue(value)
      default:
        throw ProtoWireFormatError.unsupportedType
      }

    case .fixed64, .sfixed64, .double:
      // Fixed 64-bit wire type (1)
      if data.count < 8 {
        throw ProtoWireFormatError.truncatedMessage
      }

      let bytes = data.prefix(8)
      data.removeFirst(8)

      switch fieldDescriptor.type {
      case .fixed64:
        let value = bytes.withUnsafeBytes { $0.load(as: UInt64.self) }
        return .uintValue(UInt(value))
      case .sfixed64:
        let value = bytes.withUnsafeBytes { $0.load(as: Int64.self) }
        return .intValue(Int(value))
      case .double:
        let value = bytes.withUnsafeBytes { $0.load(as: Double.self) }
        return .doubleValue(value)
      default:
        throw ProtoWireFormatError.unsupportedType
      }

    case .string, .bytes, .message:
      // Length-delimited wire type (2)
      let (lengthVarint, lengthBytes) = decodeVarint(data)
      if lengthBytes >= data.count {
        throw ProtoWireFormatError.truncatedMessage
      }
      data.removeFirst(lengthBytes)

      guard let length = lengthVarint else {
        throw ProtoWireFormatError.malformedVarint
      }

      if UInt64(data.count) < length {
        throw ProtoWireFormatError.truncatedMessage
      }

      let valueData = data.prefix(Int(length))
      data.removeFirst(Int(length))

      switch fieldDescriptor.type {
      case .string:
        if let stringValue = String(data: valueData, encoding: .utf8) {
          return .stringValue(stringValue)
        }
        else {
          throw ProtoWireFormatError.invalidUtf8String
        }
      case .bytes:
        return .bytesValue(Data(valueData))
      case .message:
        if let messageType = fieldDescriptor.messageType,
          let nestedMessage = unmarshal(data: Data(valueData), messageDescriptor: messageType)
        {
          return .messageValue(nestedMessage)
        }
        else {
          throw ProtoWireFormatError.invalidMessageType
        }
      default:
        throw ProtoWireFormatError.unsupportedType
      }

    default:
      throw ProtoWireFormatError.unsupportedType
    }
  }

  // MARK: - Helper Methods

  /// Skips a field with the given wire type.
  ///
  /// - Parameters:
  ///   - wireType: The wire type.
  ///   - data: The data buffer to read from.
  /// - Returns: `true` if the field was successfully skipped, `false` otherwise.
  private static func skipField(wireType: Int, data: inout Data) -> Bool {
    switch wireType {
    case 0:  // Varint
      let (_, valueBytes) = decodeVarint(data)
      if valueBytes >= data.count {
        return false
      }
      data.removeFirst(valueBytes)
      return true

    case 1:  // Fixed 64-bit
      if data.count < 8 {
        return false
      }
      data.removeFirst(8)
      return true

    case 2:  // Length-delimited
      let (lengthVarint, lengthBytes) = decodeVarint(data)
      if lengthBytes >= data.count {
        return false
      }
      data.removeFirst(lengthBytes)

      guard let length = lengthVarint else {
        return false
      }

      if UInt64(data.count) < length {
        return false
      }

      data.removeFirst(Int(length))
      return true

    case 5:  // Fixed 32-bit
      if data.count < 4 {
        return false
      }
      data.removeFirst(4)
      return true

    default:
      return false
    }
  }

  /// Attempts to convert a ProtoMessage to a SwiftProtobuf message.
  ///
  /// - Parameter message: The ProtoMessage to convert.
  /// - Returns: A SwiftProtobuf message, or nil if conversion is not possible.
  private static func convertToSwiftProtoMessage(_ message: ProtoMessage) -> SwiftProtobuf.Message? {
    // This would be the place to implement conversion from our dynamic message to a SwiftProtobuf message
    // For now, we'll return nil and use our manual serialization
    return nil
  }

  /// Encodes a varint value to the wire format.
  ///
  /// - Parameter value: The value to encode.
  /// - Returns: The encoded data.
  public static func encodeVarint(_ value: UInt64) -> Data {
    var result = Data()
    var v = value
    while v >= 0x80 {
      result.append(UInt8(v & 0x7F | 0x80))
      v >>= 7
    }
    result.append(UInt8(v))
    return result
  }

  /// Decodes a varint value from the wire format.
  ///
  /// - Parameter data: The data to decode from.
  /// - Returns: A tuple containing the decoded value and the number of bytes consumed, or nil if decoding fails.
  public static func decodeVarint(_ data: Data) -> (UInt64?, Int) {
    var value: UInt64 = 0
    var shift: UInt64 = 0
    var consumedBytes = 0

    for byte in data {
      value |= UInt64(byte & 0x7F) << shift
      shift += 7
      consumedBytes += 1
      if byte & 0x80 == 0 {
        return (value, consumedBytes)
      }

      // Prevent overflow
      if shift >= 64 {
        return (nil, consumedBytes)
      }
    }

    return (nil, consumedBytes)  // Return nil if varint decoding fails
  }

  /// Determines the wire type for a field type.
  ///
  /// - Parameter fieldType: The field type.
  /// - Returns: The corresponding wire type.
  public static func determineWireType(for fieldType: ProtoFieldType) -> Int {
    switch fieldType {
    case .int32, .int64, .uint32, .uint64, .sint32, .sint64, .bool, .enum:
      return 0  // Varint wire type
    case .fixed64, .sfixed64, .double:
      return 1  // Fixed 64-bit wire type
    case .string, .bytes, .message:
      return 2  // Length-delimited wire type
    case .fixed32, .sfixed32, .float:
      return 5  // Fixed 32-bit wire type
    default:
      return 0  // Default to varint
    }
  }
}

/// Errors that can occur during wire format encoding and decoding.
public enum ProtoWireFormatError: Error {
  /// Indicates that the field type doesn't match the value type.
  case typeMismatch

  /// Indicates that the wire type doesn't match the expected wire type for the field type.
  case wireTypeMismatch

  /// Indicates that the field type is not supported.
  case unsupportedType

  /// Indicates that the message is truncated.
  case truncatedMessage

  /// Indicates that a varint is malformed.
  case malformedVarint

  /// Indicates that a string is not valid UTF-8.
  case invalidUtf8String

  /// Indicates that a message type is invalid or missing.
  case invalidMessageType
}
