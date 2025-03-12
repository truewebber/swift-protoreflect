import Foundation
import SwiftProtobuf

/// Handles serialization and deserialization of Protocol Buffer messages using the binary wire format.
///
/// This class provides methods for converting between `ProtoMessage` instances and binary wire format data,
/// leveraging SwiftProtobuf's wire format implementation where possible.
///
/// Protocol Buffers use a binary wire format with different encoding types for different field types:
/// - wireTypeVarint (0): Used for int32, int64, uint32, uint64, sint32, sint64, bool, enum
/// - wireTypeFixed64 (1): Used for fixed64, sfixed64, double (8 bytes)
/// - wireTypeLengthDelimited (2): Used for string, bytes, embedded messages, packed repeated fields
/// - wireTypeStartGroup (3): Used for groups (deprecated in proto3)
/// - wireTypeEndGroup (4): Used for groups (deprecated in proto3)
/// - wireTypeFixed32 (5): Used for fixed32, sfixed32, float (4 bytes)
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

  // Wire type constants
  public static let wireTypeVarint: Int = 0
  public static let wireTypeFixed64: Int = 1
  public static let wireTypeLengthDelimited: Int = 2
  public static let wireTypeStartGroup: Int = 3
  public static let wireTypeEndGroup: Int = 4
  public static let wireTypeFixed32: Int = 5

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

    // Create a new message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    
    // Unmarshal the data into the message
    do {
      try unmarshal(data: data, to: message)
      return message
    } catch {
      return nil
    }
  }

  /// Deserializes protobuf wire format data into an existing ProtoMessage.
  ///
  /// - Parameters:
  ///   - data: The serialized data.
  ///   - message: The message to populate with deserialized data.
  /// - Throws: An error if deserialization fails.
  public static func unmarshal(data: Data, to message: ProtoDynamicMessage) throws {
    var dataStream = data
    let messageDescriptor = message.descriptor()

    // Track repeated fields to collect all values
    var repeatedFields: [Int: [ProtoValue]] = [:]

    // Track map fields to collect all entries
    var mapFields: [Int: [String: ProtoValue]] = [:]

    while !dataStream.isEmpty {
      // Decode the field key
      let (fieldKey, fieldKeyBytes) = decodeVarint(dataStream)
      guard let fieldKey = fieldKey else {
        throw ProtoWireFormatError.invalidFieldKey
      }

      if fieldKeyBytes > dataStream.count {
        break  // End of data
      }

      dataStream.removeFirst(fieldKeyBytes)

      // Extract field number and wire type from fieldKey
      let fieldNumber = Int(fieldKey >> 3)
      let wireType = Int(fieldKey & 0x07)

      // Special handling for START_GROUP and END_GROUP wire types
      if wireType == wireTypeStartGroup {
        // For START_GROUP, we need to find the matching END_GROUP
        var nestedGroups = 1

        while nestedGroups > 0 && !dataStream.isEmpty {
          // Read the next field key
          let (nextFieldKey, nextFieldKeyBytes) = decodeVarint(dataStream)
          guard let nextFieldKey = nextFieldKey else {
            throw ProtoWireFormatError.invalidFieldKey
          }

          if nextFieldKeyBytes > dataStream.count {
            throw ProtoWireFormatError.truncatedMessage
          }

          dataStream.removeFirst(nextFieldKeyBytes)

          // Extract wire type from field key
          let nextWireType = Int(nextFieldKey & 0x07)

          if nextWireType == wireTypeStartGroup {
            nestedGroups += 1
          }
          else if nextWireType == wireTypeEndGroup {
            nestedGroups -= 1

            // If we've found the matching END_GROUP for the outermost group, we're done
            if nestedGroups == 0 {
              break
            }
          }
          else {
            // Skip this field
            if !skipField(wireType: nextWireType, data: &dataStream) {
              throw ProtoWireFormatError.truncatedMessage
            }
          }
        }

        // If we couldn't find the matching END_GROUP, throw an error
        if nestedGroups != 0 {
          throw ProtoWireFormatError.truncatedMessage
        }

        // Continue to the next field
        continue
      }

      if wireType == wireTypeEndGroup {
        // END_GROUP should only be encountered when processing a START_GROUP
        // If we encounter it here, it's an error
        throw ProtoWireFormatError.wireTypeMismatch
      }

      // Find the field descriptor using the field number
      guard let fieldDescriptor = messageDescriptor.field(number: fieldNumber) else {
        // Skip unknown fields
        if !skipField(wireType: wireType, data: &dataStream) {
          throw ProtoWireFormatError.truncatedMessage
        }
        continue
      }

      // Check if the wire type matches the expected wire type for the field type
      let expectedWireType = determineWireType(for: fieldDescriptor.type)
      if wireType != expectedWireType {
        // Wire type mismatch, skip the field
        if !skipField(wireType: wireType, data: &dataStream) {
          throw ProtoWireFormatError.truncatedMessage
        }
        continue
      }

      // Decode the value based on wire type and field type
      if let value = try decodeField(fieldDescriptor: fieldDescriptor, wireType: wireType, data: &dataStream) {
        // Handle map fields (which are encoded as repeated message fields)
        if fieldDescriptor.isMap && fieldDescriptor.type == .message && fieldDescriptor.messageType != nil {
          if case .messageValue(let mapEntryMessage) = value {
            let keyField = mapEntryMessage.descriptor().field(number: 1)
            let valueField = mapEntryMessage.descriptor().field(number: 2)

            let keyValue = keyField.flatMap { mapEntryMessage.get(field: $0) }
            let valueValue = valueField.flatMap { mapEntryMessage.get(field: $0) }

            if case .stringValue(let key)? = keyValue {
              // Add the key-value pair to the map field collection
              var entries = mapFields[fieldNumber] ?? [:]
              entries[key] = valueValue
              mapFields[fieldNumber] = entries
            }
          }
        }
        // Handle repeated fields
        else if fieldDescriptor.isRepeated {
          // Add the value to the repeated field collection
          var values = repeatedFields[fieldNumber] ?? []
          values.append(value)
          repeatedFields[fieldNumber] = values
        }
        // Handle regular fields
        else {
          message.set(field: fieldDescriptor, value: value)
        }
      }
    }

    // Set all repeated fields
    for (fieldNumber, values) in repeatedFields {
      if let fieldDescriptor = messageDescriptor.field(number: fieldNumber) {
        message.set(field: fieldDescriptor, value: .repeatedValue(values))
      }
    }

    // Set all map fields
    for (fieldNumber, entries) in mapFields {
      if let fieldDescriptor = messageDescriptor.field(number: fieldNumber) {
        message.set(field: fieldDescriptor, value: .mapValue(entries))
      }
    }
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
    // Handle map fields (do this check first)
    if field.isMap {
      if case .mapValue(let entries) = value, let entryDescriptor = field.messageType {
        // Map fields are encoded as repeated message entries
        for (key, mapValue) in entries {
          // Create a message for each map entry
          let entryMessage = ProtoDynamicMessage(descriptor: entryDescriptor)

          // Set the key and value fields
          if let keyField = entryDescriptor.field(number: 1) {
            entryMessage.set(field: keyField, value: .stringValue(key))
          }

          if let valueField = entryDescriptor.field(number: 2) {
            entryMessage.set(field: valueField, value: mapValue)
          }

          // Encode the entry message
          try encodeIndividualField(field: field, value: .messageValue(entryMessage), to: &data)
        }
        return
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }
    }

    // Handle repeated fields
    if field.isRepeated {
      if case .repeatedValue(let values) = value {
        for individualValue in values {
          try encodeIndividualField(field: field, value: individualValue, to: &data)
        }
        return
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }
    }

    // Handle regular fields
    try encodeIndividualField(field: field, value: value, to: &data)
  }

  /// Encodes an individual field value to the wire format.
  ///
  /// - Parameters:
  ///   - field: The field descriptor.
  ///   - value: The field value.
  ///   - data: The data buffer to append to.
  /// - Throws: An error if encoding fails.
  private static func encodeIndividualField(field: ProtoFieldDescriptor, value: ProtoValue, to data: inout Data) throws
  {
    // Encode the field key (field number + wire type)
    let fieldNumber = field.number
    let wireType = determineWireType(for: field.type)
    let fieldKey = UInt64(fieldNumber << 3 | wireType)
    data.append(encodeVarint(fieldKey))

    // Encode the field value based on the field type
    switch field.type {
    case .int32, .int64, .uint32, .uint64, .bool:
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

    case .sint32:
      if case .intValue(let intValue) = value {
        // Use zigzag encoding for sint32
        let zigzagValue = encodeZigZag32(Int32(intValue))
        data.append(encodeVarint(UInt64(zigzagValue)))
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .sint64:
      if case .intValue(let intValue) = value {
        // Use zigzag encoding for sint64
        let zigzagValue = encodeZigZag64(Int64(intValue))
        data.append(encodeVarint(UInt64(zigzagValue)))
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
      else if case .enumValue(_, let number, _) = value {
        data.append(encodeVarint(UInt64(number)))
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

      if valueBytes > data.count {
        throw ProtoWireFormatError.truncatedMessage
      }

      guard let value = varintValue else {
        throw ProtoWireFormatError.malformedVarint
      }

      data.removeFirst(valueBytes)

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

    case .sint32:
      // Varint wire type (0) with zigzag encoding
      let (varintValue, valueBytes) = decodeVarint(data)
      if valueBytes >= data.count {
        throw ProtoWireFormatError.truncatedMessage
      }
      data.removeFirst(valueBytes)

      guard let value = varintValue else {
        throw ProtoWireFormatError.malformedVarint
      }

      // Decode zigzag value
      let decodedValue = decodeZigZag32(UInt32(truncatingIfNeeded: value))
      return .intValue(Int(decodedValue))

    case .sint64:
      // Varint wire type (0) with zigzag encoding
      let (varintValue, valueBytes) = decodeVarint(data)
      if valueBytes >= data.count {
        throw ProtoWireFormatError.truncatedMessage
      }
      data.removeFirst(valueBytes)

      guard let value = varintValue else {
        throw ProtoWireFormatError.malformedVarint
      }

      // Decode zigzag value
      let decodedValue = decodeZigZag64(value)
      return .intValue(Int(decodedValue))

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
        if let messageType = fieldDescriptor.messageType {
          // Create a new message for the message field
          let nestedMessage = ProtoDynamicMessage(descriptor: messageType)

          // Unmarshal the nested message
          do {
            try unmarshal(data: Data(valueData), to: nestedMessage)
            return .messageValue(nestedMessage)
          }
          catch {
            throw ProtoWireFormatError.invalidMessageType
          }
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
  public static func skipField(wireType: Int, data: inout Data) -> Bool {
    switch wireType {
    case wireTypeVarint:  // Varint
      let (_, valueBytes) = decodeVarint(data)
      if valueBytes >= data.count {
        return false
      }
      data.removeFirst(valueBytes)
      return true

    case wireTypeFixed64:  // Fixed 64-bit
      if data.count < 8 {
        return false
      }
      data.removeFirst(8)
      return true

    case wireTypeLengthDelimited:  // Length-delimited
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

    case wireTypeStartGroup:  // START_GROUP
      // For START_GROUP, we need to find the matching END_GROUP
      // This is a simplified implementation that just skips until we find any END_GROUP
      // A more robust implementation would track nesting and match field numbers
      var nestedGroups = 1

      while nestedGroups > 0 && !data.isEmpty {
        // Read the next field key
        let (fieldKey, fieldKeyBytes) = decodeVarint(data)
        guard let fieldKey = fieldKey else {
          return false
        }

        if fieldKeyBytes >= data.count {
          return false
        }

        data.removeFirst(fieldKeyBytes)

        // Extract wire type from fieldKey
        let wireType = Int(fieldKey & 0x07)

        if wireType == wireTypeStartGroup {
          nestedGroups += 1
        }
        else if wireType == wireTypeEndGroup {
          nestedGroups -= 1
          if nestedGroups == 0 {
            // We found the matching END_GROUP
            return true
          }
        }
        else {
          // Skip this field
          if !skipField(wireType: wireType, data: &data) {
            return false
          }
        }
      }

      // If we couldn't find the matching END_GROUP, return false
      return false

    case wireTypeEndGroup:  // END_GROUP
      // END_GROUP should only be encountered when processing a START_GROUP
      // If we encounter it here, it's an error
      return false

    case wireTypeFixed32:  // Fixed 32-bit
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
    // Check if the message is already a SwiftProtobuf message
    if let swiftProtoMessage = message as? SwiftProtobuf.Message {
      return swiftProtoMessage
    }
    
    // Check if the message has a SwiftProtobuf descriptor
    if message.descriptor().originalDescriptorProto() != nil {
      // For now, we don't have a way to create a SwiftProtobuf message from a descriptor at runtime
      // This would require code generation or reflection capabilities that SwiftProtobuf doesn't provide
      // In a future version, we could implement this using the SwiftProtobuf runtime API if it becomes available
    }
    
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

  /// Encodes a signed 32-bit integer using zigzag encoding.
  ///
  /// Zigzag encoding maps signed integers to unsigned integers so that numbers with small absolute values
  /// have small encoded values, for efficient varint encoding.
  ///
  /// - Parameter value: The signed 32-bit integer to encode.
  /// - Returns: The zigzag-encoded unsigned 32-bit integer.
  public static func encodeZigZag32(_ value: Int32) -> UInt32 {
    return UInt32((value << 1) ^ (value >> 31))
  }

  /// Decodes a zigzag-encoded 32-bit integer.
  ///
  /// - Parameter value: The zigzag-encoded unsigned 32-bit integer.
  /// - Returns: The decoded signed 32-bit integer.
  public static func decodeZigZag32(_ value: UInt32) -> Int32 {
    // Corrected implementation to avoid arithmetic issues
    return Int32(bitPattern: (value >> 1)) ^ -Int32(bitPattern: value & 1)
  }

  /// Encodes a signed 64-bit integer using zigzag encoding.
  ///
  /// Zigzag encoding maps signed integers to unsigned integers so that numbers with small absolute values
  /// have small encoded values, for efficient varint encoding.
  ///
  /// - Parameter value: The signed 64-bit integer to encode.
  /// - Returns: The zigzag-encoded unsigned 64-bit integer.
  public static func encodeZigZag64(_ value: Int64) -> UInt64 {
    return UInt64((value << 1) ^ (value >> 63))
  }

  /// Decodes a zigzag-encoded 64-bit integer.
  ///
  /// - Parameter value: The zigzag-encoded unsigned 64-bit integer.
  /// - Returns: The decoded signed 64-bit integer.
  public static func decodeZigZag64(_ value: UInt64) -> Int64 {
    // Corrected implementation to avoid arithmetic issues
    return Int64(bitPattern: (value >> 1)) ^ -Int64(bitPattern: value & 1)
  }

  /// Determines the wire type for a given field type.
  ///
  /// - Parameter fieldType: The field type.
  /// - Returns: The corresponding wire type.
  public static func determineWireType(for fieldType: ProtoFieldType) -> Int {
    switch fieldType {
    case .int32, .int64, .uint32, .uint64, .sint32, .sint64, .bool, .enum:
      return wireTypeVarint
    case .fixed64, .sfixed64, .double:
      return wireTypeFixed64
    case .string, .bytes, .message:
      return wireTypeLengthDelimited
    case .group:
      return wireTypeStartGroup
    case .fixed32, .sfixed32, .float:
      return wireTypeFixed32
    default:
      return wireTypeVarint  // Default to varint
    }
  }
}

/// Errors that can occur during wire format encoding and decoding.
public enum ProtoWireFormatError: Error {
  /// Indicates that a type mismatch occurred during encoding or decoding.
  case typeMismatch

  /// Indicates that the wire type doesn't match the expected wire type for the field type.
  case wireTypeMismatch

  /// Indicates that the field type is not supported.
  case unsupportedType

  /// Indicates that a message was truncated.
  case truncatedMessage

  /// Indicates that a varint is malformed.
  case malformedVarint

  /// Indicates that a string is not valid UTF-8.
  case invalidUtf8String

  /// Indicates that a message type is invalid or missing.
  case invalidMessageType

  /// Indicates that a field key is invalid.
  case invalidFieldKey
}
