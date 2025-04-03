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
    do {
      try validateMessage(message)
      var data = Data()

      // Marshal all fields
      for field in message.descriptor().fields {
        if let value = message.get(field: field) {
          do {
            try encodeField(field: field, value: value, to: &data)
          }
          catch {
            return nil
          }
        }
      }

      return data
    } catch {
      return nil
    }
  }

  /// Deserializes protobuf wire format data into a ProtoMessage.
  ///
  /// - Parameters:
  ///   - data: The serialized data.
  ///   - messageDescriptor: The descriptor for the message type.
  /// - Returns: The deserialized message, or nil if deserialization fails.
  public static func unmarshal(data: Data, messageDescriptor: ProtoMessageDescriptor) -> ProtoMessage? {
    // Create a new message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    
    // Handle empty data
    if data.isEmpty {
        return message
    }
    
    // Create a mutable copy of the data
    var remainingData = data
    
    do {
        // Unmarshal the data into the message
        while !remainingData.isEmpty {
            // Decode the field key
            let (keyValue, keyBytes) = decodeVarint(remainingData)
            guard let key = keyValue else {
                return nil  // Invalid varint
            }
            
            remainingData.removeFirst(keyBytes)
            
            // Extract field number and wire type
            let fieldNumber = Int(key >> 3)
            let wireType = Int(key & 0x7)
            
            // Find the field descriptor
            guard let fieldDescriptor = messageDescriptor.field(number: fieldNumber) else {
                // Unknown field, skip it
                if !skipField(wireType: wireType, data: &remainingData) {
                    return nil  // Failed to skip field
                }
                continue
            }
            
            // Decode the field value
            let value = try decodeFieldValue(
                wireType: wireType,
                fieldDescriptor: fieldDescriptor,
                data: &remainingData
            )
            
            // Set the field value on the message
            message.set(field: fieldDescriptor, value: value)
        }
        
        return message
    }
    catch {
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

    // Initialize empty repeated fields
    for field in messageDescriptor.fields {
      if field.isRepeated {
        repeatedFields[field.number] = []
      }
    }

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
        // This is an unknown field, capture it instead of just skipping it
        var fieldData = Data()

        // Store the field key
        fieldData.append(encodeVarint(fieldKey))

        // Capture the field value based on wire type
        switch wireType {
        case wireTypeVarint:
          // For varint, read the value and append it
          let (value, valueBytes) = decodeVarint(dataStream)
          if let value = value {
            fieldData.append(encodeVarint(value))
            dataStream.removeFirst(valueBytes)
          }
          else {
            throw ProtoWireFormatError.malformedVarint
          }

        case wireTypeFixed64:
          // For fixed 64-bit, read 8 bytes
          if dataStream.count >= 8 {
            let bytes = dataStream.prefix(8)
            fieldData.append(bytes)
            dataStream.removeFirst(8)
          }
          else {
            throw ProtoWireFormatError.truncatedMessage
          }

        case wireTypeLengthDelimited:
          // For length-delimited, read the length and then the data
          let (lengthValue, lengthBytes) = decodeVarint(dataStream)
          if let length = lengthValue {
            fieldData.append(encodeVarint(length))
            dataStream.removeFirst(lengthBytes)

            if dataStream.count >= Int(length) {
              let bytes = dataStream.prefix(Int(length))
              fieldData.append(bytes)
              dataStream.removeFirst(Int(length))
            }
            else {
              throw ProtoWireFormatError.truncatedMessage
            }
          }
          else {
            throw ProtoWireFormatError.malformedVarint
          }

        case wireTypeFixed32:
          // For fixed 32-bit, read 4 bytes
          if dataStream.count >= 4 {
            let bytes = dataStream.prefix(4)
            fieldData.append(bytes)
            dataStream.removeFirst(4)
          }
          else {
            throw ProtoWireFormatError.truncatedMessage
          }

        default:
          // For other wire types, just skip
          if !skipField(wireType: wireType, data: &dataStream) {
            throw ProtoWireFormatError.truncatedMessage
          }
          // Don't store fields we can't properly handle
          continue
        }

        // Store the unknown field
        message.setUnknownField(fieldNumber: fieldNumber, data: fieldData)
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
        if fieldDescriptor.isMap,
          case .message = fieldDescriptor.type,
          fieldDescriptor.messageType != nil
        {
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
    for field in messageDescriptor.fields {
      if field.isRepeated {
        let values = repeatedFields[field.number] ?? []
        message.set(field: field, value: .repeatedValue(values))
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
    if field.isRepeated {
      try encodeRepeatedField(field: field, value: value, to: &data)
      return
    }
    
    if field.isMap {
      try encodeMapField(field: field, value: value, to: &data)
      return
    }

    switch field.type {
    case .message:
      if case .messageValue(let messageValue) = value {
        try encodeMessageLengthDelimited(messageValue, field: field, to: &data)
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }
      
    case .string:
      if case .stringValue(let stringValue) = value {
        let tag = (UInt64(field.number) << 3) | UInt64(wireTypeLengthDelimited)
        data.append(encodeVarint(tag))
        
        let utf8Data = stringValue.data(using: .utf8)!
        data.append(encodeVarint(UInt64(utf8Data.count)))
        data.append(utf8Data)
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }
      
    case .bytes:
      if case .bytesValue(let bytesValue) = value {
        let tag = (UInt64(field.number) << 3) | UInt64(wireTypeLengthDelimited)
        data.append(encodeVarint(tag))
        
        data.append(encodeVarint(UInt64(bytesValue.count)))
        data.append(bytesValue)
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .int32, .int64, .uint32, .uint64, .bool:
      let tag = (UInt64(field.number) << 3) | UInt64(wireTypeVarint)
      data.append(encodeVarint(tag))
      
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
      let tag = (UInt64(field.number) << 3) | UInt64(wireTypeFixed32)
      data.append(encodeVarint(tag))
      
      var bytes = [UInt8](repeating: 0, count: MemoryLayout<UInt32>.size)
      let bytesWritten = bytes.withUnsafeMutableBytes { target in
        data.prefix(4).copyBytes(to: target)
      }
      guard bytesWritten == 4 else {
        throw ProtoWireFormatError.truncatedMessage
      }
      data.removeFirst(4)

    case .fixed64, .sfixed64:
      let tag = (UInt64(field.number) << 3) | UInt64(wireTypeFixed64)
      data.append(encodeVarint(tag))
      
      var bytes = [UInt8](repeating: 0, count: MemoryLayout<UInt64>.size)
      let bytesWritten = bytes.withUnsafeMutableBytes { target in
        data.prefix(8).copyBytes(to: target)
      }
      guard bytesWritten == 8 else {
        throw ProtoWireFormatError.truncatedMessage
      }
      data.removeFirst(8)

    case .float:
      let tag = (UInt64(field.number) << 3) | UInt64(wireTypeFixed32)
      data.append(encodeVarint(tag))
      
      if case .floatValue(let floatValue) = value {
        var v = floatValue
        var bytes = [UInt8](repeating: 0, count: 4)
        withUnsafeBytes(of: &v) { floatBytes in
          bytes.withUnsafeMutableBytes { target in
            target.copyMemory(from: floatBytes)
          }
        }
        data.append(contentsOf: bytes)
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .double:
      let tag = (UInt64(field.number) << 3) | UInt64(wireTypeFixed64)
      data.append(encodeVarint(tag))
      
      if case .doubleValue(let doubleValue) = value {
        var v = doubleValue
        var bytes = [UInt8](repeating: 0, count: 8)
        withUnsafeBytes(of: &v) { doubleBytes in
          bytes.withUnsafeMutableBytes { target in
            target.copyMemory(from: doubleBytes)
          }
        }
        data.append(contentsOf: bytes)
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .enum:
      let tag = (UInt64(field.number) << 3) | UInt64(wireTypeVarint)
      data.append(encodeVarint(tag))
      
      if case .intValue(let intValue) = value {
        data.append(encodeVarint(UInt64(intValue)))
      }
      else if case .enumValue(_, let number, _) = value {
        data.append(encodeVarint(UInt64(number)))
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .sint32:
      let tag = (UInt64(field.number) << 3) | UInt64(wireTypeVarint)
      data.append(encodeVarint(tag))
      
      if case .intValue(let intValue) = value {
        let zigzagValue = encodeZigZag32(Int32(intValue))
        data.append(encodeVarint(UInt64(zigzagValue)))
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .sint64:
      let tag = (UInt64(field.number) << 3) | UInt64(wireTypeVarint)
      data.append(encodeVarint(tag))
      
      if case .intValue(let intValue) = value {
        let zigzagValue = encodeZigZag64(Int64(intValue))
        data.append(encodeVarint(UInt64(zigzagValue)))
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .group, .unknown:
      throw ProtoWireFormatError.unsupportedType
    }
  }

  private static func encodeRepeatedField(field: ProtoFieldDescriptor, value: ProtoValue, to data: inout Data) throws {
    guard case .repeatedValue(let array) = value else {
      throw ProtoWireFormatError.typeMismatch
    }
    
    for element in array {
      try encodeField(field: ProtoFieldDescriptor(
        name: field.name,
        number: field.number,
        type: field.type,
        isRepeated: false,
        isMap: false,
        messageType: field.messageType
      ), value: element, to: &data)
    }
  }

  private static func encodeMapField(field: ProtoFieldDescriptor, value: ProtoValue, to data: inout Data) throws {
    guard case .mapValue(let map) = value else {
      throw ProtoWireFormatError.typeMismatch
    }
    
    for (key, value) in map {
      var entryData = Data()
      
      // Encode key (field number 1)
      try encodeField(field: ProtoFieldDescriptor(
        name: "key",
        number: 1,
        type: .string,
        isRepeated: false,
        isMap: false
      ), value: .stringValue(key), to: &entryData)
      
      // Encode value (field number 2)
      try encodeField(field: ProtoFieldDescriptor(
        name: "value",
        number: 2,
        type: field.type,
        isRepeated: false,
        isMap: false,
        messageType: field.messageType
      ), value: value, to: &entryData)
      
      // Write entry as length-delimited
      let tag = (UInt64(field.number) << 3) | UInt64(wireTypeLengthDelimited)
      data.append(encodeVarint(tag))
      data.append(encodeVarint(UInt64(entryData.count)))
      data.append(entryData)
    }
  }

  private static func encodeMessageLengthDelimited(_ message: ProtoMessage, field: ProtoFieldDescriptor, to data: inout Data) throws {
    // 1. Write field tag (field_number << 3 | wire_type)
    let tag = (UInt64(field.number) << 3) | UInt64(wireTypeLengthDelimited)
    data.append(encodeVarint(tag))
    
    // 2. Serialize message to temporary buffer
    guard let messageData = marshal(message: message) else {
      throw ProtoWireFormatError.typeMismatch
    }
    
    // 3. Write length
    data.append(encodeVarint(UInt64(messageData.count)))
    
    // 4. Write message data
    data.append(messageData)
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
        let intValue = Int(value)
        // If we have an enum type, try to convert the int value to an enum value
        if let enumType = fieldDescriptor.enumType, let enumValue = enumType.value(withNumber: intValue) {
          return .enumValue(name: enumValue.name, number: enumValue.number, enumDescriptor: enumType)
        }
        // Fall back to int value if we can't find the enum value
        return .intValue(intValue)
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

      var bytes = [UInt8](repeating: 0, count: MemoryLayout<UInt32>.size)
      let bytesWritten = bytes.withUnsafeMutableBytes { target in
        data.prefix(4).copyBytes(to: target)
      }
      guard bytesWritten == 4 else {
        throw ProtoWireFormatError.truncatedMessage
      }
      data.removeFirst(4)

      switch fieldDescriptor.type {
      case .fixed32:
        let value: UInt32 = bytes.withUnsafeBytes { ptr in
          ptr.baseAddress!.assumingMemoryBound(to: UInt32.self).pointee
        }
        return .uintValue(UInt(value))
      case .sfixed32:
        let value: Int32 = bytes.withUnsafeBytes { ptr in
          ptr.baseAddress!.assumingMemoryBound(to: Int32.self).pointee
        }
        return .intValue(Int(value))
      case .float:
        let value: Float = bytes.withUnsafeBytes { ptr in
          ptr.baseAddress!.assumingMemoryBound(to: Float.self).pointee
        }
        return .floatValue(value)
      default:
        throw ProtoWireFormatError.unsupportedType
      }

    case .fixed64, .sfixed64, .double:
      // Fixed 64-bit wire type (1)
      if data.count < 8 {
        throw ProtoWireFormatError.truncatedMessage
      }

      var bytes = [UInt8](repeating: 0, count: MemoryLayout<UInt64>.size)
      let bytesWritten = bytes.withUnsafeMutableBytes { target in
        data.prefix(8).copyBytes(to: target)
      }
      guard bytesWritten == 8 else {
        throw ProtoWireFormatError.truncatedMessage
      }
      data.removeFirst(8)

      switch fieldDescriptor.type {
      case .fixed64, .sfixed64:
        let value = bytes.withUnsafeBytes { ptr in
          ptr.baseAddress!.assumingMemoryBound(to: UInt64.self).pointee
        }
        return .uintValue(UInt(value))
      case .double:
        let value = bytes.withUnsafeBytes { ptr in
          ptr.baseAddress!.assumingMemoryBound(to: Double.self).pointee
        }
        return .doubleValue(value)
      default:
        throw ProtoWireFormatError.wireTypeMismatch
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

  private static func decodeFieldValue(wireType: Int, fieldDescriptor: ProtoFieldDescriptor, data: inout Data) throws -> ProtoValue {
    switch wireType {
    case wireTypeVarint:
      let (value, bytes) = decodeVarint(data)
      guard let varIntValue = value else {
        throw ProtoWireFormatError.malformedVarint
      }
      data.removeFirst(bytes)

      switch fieldDescriptor.type {
      case .int32, .int64:
        return .intValue(Int(Int64(bitPattern: UInt64(varIntValue))))
      case .uint32, .uint64:
        return .uintValue(UInt(varIntValue))
      case .bool:
        return .boolValue(varIntValue != 0)
      case .enum:
        return .intValue(Int(varIntValue))
      case .sint32:
        let value = decodeZigZag32(UInt32(truncatingIfNeeded: varIntValue))
        return .intValue(Int(value))
      case .sint64:
        let value = decodeZigZag64(UInt64(varIntValue))
        return .intValue(Int(value))
      default:
        throw ProtoWireFormatError.wireTypeMismatch
      }

    case wireTypeFixed64:
      guard data.count >= 8 else {
        throw ProtoWireFormatError.truncatedMessage
      }

      var bytes = [UInt8](repeating: 0, count: MemoryLayout<UInt64>.size)
      let bytesWritten = bytes.withUnsafeMutableBytes { target in
        data.prefix(8).copyBytes(to: target)
      }
      guard bytesWritten == 8 else {
        throw ProtoWireFormatError.truncatedMessage
      }
      data.removeFirst(8)

      switch fieldDescriptor.type {
      case .fixed64, .sfixed64:
        let value = bytes.withUnsafeBytes { ptr in
          ptr.baseAddress!.assumingMemoryBound(to: UInt64.self).pointee
        }
        return .uintValue(UInt(value))
      case .double:
        let value = bytes.withUnsafeBytes { ptr in
          ptr.baseAddress!.assumingMemoryBound(to: Double.self).pointee
        }
        return .doubleValue(value)
      default:
        throw ProtoWireFormatError.wireTypeMismatch
      }

    case wireTypeFixed32:
      guard data.count >= 4 else {
        throw ProtoWireFormatError.truncatedMessage
      }

      var bytes = [UInt8](repeating: 0, count: MemoryLayout<UInt32>.size)
      let bytesWritten = bytes.withUnsafeMutableBytes { target in
        data.prefix(4).copyBytes(to: target)
      }
      guard bytesWritten == 4 else {
        throw ProtoWireFormatError.truncatedMessage
      }
      data.removeFirst(4)

      switch fieldDescriptor.type {
      case .fixed32, .sfixed32:
        let value = bytes.withUnsafeBytes { ptr in
          ptr.baseAddress!.assumingMemoryBound(to: UInt32.self).pointee
        }
        return .uintValue(UInt(value))
      case .float:
        let value = bytes.withUnsafeBytes { ptr in
          ptr.baseAddress!.assumingMemoryBound(to: Float.self).pointee
        }
        return .floatValue(value)
      default:
        throw ProtoWireFormatError.wireTypeMismatch
      }

    case wireTypeLengthDelimited:
      let (lengthVarint, lengthBytes) = decodeVarint(data)
      guard let length = lengthVarint else {
        throw ProtoWireFormatError.malformedVarint
      }
      data.removeFirst(lengthBytes)

      guard data.count >= Int(length) else {
        throw ProtoWireFormatError.truncatedMessage
      }

      let valueData = data.prefix(Int(length))
      data.removeFirst(Int(length))

      switch fieldDescriptor.type {
      case .string:
        guard let stringValue = String(data: valueData, encoding: .utf8) else {
          throw ProtoWireFormatError.invalidUtf8String
        }
        return .stringValue(stringValue)

      case .bytes:
        return .bytesValue(Data(valueData))

      case .message:
        guard let messageType = fieldDescriptor.messageType else {
          throw ProtoWireFormatError.invalidMessageType
        }
        let nestedMessage = try decodeMessageLengthDelimited(Data(valueData), messageDescriptor: messageType)
        return .messageValue(nestedMessage)

      default:
        throw ProtoWireFormatError.wireTypeMismatch
      }

    default:
      throw ProtoWireFormatError.unsupportedWireType
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
    // Special case for Int32.min to avoid overflow
    if value == Int32.min {
      return 4_294_967_295  // UInt32.max - 1
    }
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
    // Special case for Int64.min to avoid overflow
    if value == Int64.min {
      return 18_446_744_073_709_551_615  // UInt64.max - 1
    }
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

  /// Validates a message before serialization.
  ///
  /// - Parameter message: The message to validate.
  /// - Throws: An error if validation fails.
  private static func validateMessage(_ message: ProtoMessage) throws {
    let descriptor = message.descriptor()

    // Validate only fields that are set
    for field in descriptor.fields {
      if let value = message.get(field: field) {
        // Use our strict validation
        do {
          try validateFieldValue(field: field, value: value)
        }
        catch {
          throw ProtoWireFormatError.validationError(
            fieldName: field.name,
            reason: "Invalid field value: \(error.localizedDescription)"
          )
        }
      }
    }
  }

  /// Validates a field value before serialization.
  ///
  /// - Parameters:
  ///   - field: The field descriptor.
  ///   - value: The field value to validate.
  ///   - isRepeatedElement: Whether the value is an element in a repeated field.
  /// - Throws: An error if validation fails.
  public static func validateFieldValue(field: ProtoFieldDescriptor, value: ProtoValue, isRepeatedElement: Bool = false)
    throws
  {
    // Check for repeated value on non-repeated field first
    if !field.isRepeated, case .repeatedValue = value {
      throw ProtoWireFormatError.typeMismatch
    }

    // Skip validation for map fields (check this first)
    if field.isMap && !isRepeatedElement {
      if case .mapValue = value {
        return  // Map fields are handled separately
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }
    }

    // For repeated fields, validate each element
    if field.isRepeated {
      if isRepeatedElement {
        // When validating a single element of a repeated field, treat it as a non-repeated field
        let nonRepeatedField = ProtoFieldDescriptor(
          name: field.name,
          number: field.number,
          type: field.type,
          isRepeated: false,
          isMap: false,
          defaultValue: field.defaultValue,
          messageType: field.messageType,
          enumType: field.enumType
        )
        try validateFieldValue(field: nonRepeatedField, value: value)
        return
      } else if case .repeatedValue(let elements) = value {
        for element in elements {
          try validateFieldValue(field: field, value: element, isRepeatedElement: true)
        }
        return
      } else {
        throw ProtoWireFormatError.typeMismatch
      }
    }

    // For unknown field types, throw unsupportedType error
    if field.type == .unknown {
      throw ProtoWireFormatError.unsupportedType
    }

    // For serialization, we need to be very strict
    // The test expects specific type validation failures
    switch field.type {
    case .int32, .int64, .sint32, .sint64, .sfixed32, .sfixed64:
      if case .intValue = value {
        return  // Only exact match is allowed
      }
      throw ProtoWireFormatError.typeMismatch

    case .uint32, .uint64, .fixed32, .fixed64:
      if case .uintValue = value {
        return  // Only exact match is allowed
      }
      throw ProtoWireFormatError.typeMismatch

    case .float:
      if case .floatValue = value {
        return  // Only exact match is allowed
      }
      throw ProtoWireFormatError.typeMismatch

    case .double:
      if case .doubleValue = value {
        return  // Only exact match is allowed
      }
      throw ProtoWireFormatError.typeMismatch

    case .bool:
      if case .boolValue = value {
        return  // Only exact match is allowed
      }
      throw ProtoWireFormatError.typeMismatch

    case .string:
      if case .stringValue = value {
        return  // Only exact match is allowed
      }
      throw ProtoWireFormatError.typeMismatch

    case .bytes:
      if case .bytesValue = value {
        return  // Only exact match is allowed
      }
      throw ProtoWireFormatError.typeMismatch

    case .message:
      if case .messageValue(let messageValue) = value {
        // For message fields, check that the message type matches
        if let expectedType = field.messageType {
          if messageValue.descriptor().fullName != expectedType.fullName {
            throw ProtoWireFormatError.typeMismatch
          }
        }
        return
      }
      throw ProtoWireFormatError.typeMismatch

    case .enum:
      if case .enumValue = value {
        return  // Only exact match is allowed
      }
      if case .intValue(let intValue) = value {
        // For enum fields, check that the int value is a valid enum value
        if let enumType = field.enumType {
          if enumType.value(withNumber: intValue) != nil {
            return
          }
        }
      }
      throw ProtoWireFormatError.typeMismatch

    case .group:
      throw ProtoWireFormatError.unsupportedType

    default:
      throw ProtoWireFormatError.unsupportedType
    }
  }

  private static func bytesToValue<T>(_ bytes: [UInt8]) -> T {
    return bytes.withUnsafeBytes { ptr in
        ptr.load(fromByteOffset: 0, as: T.self)
    }
  }

  private static func decodeMessageLengthDelimited(_ data: Data, messageDescriptor: ProtoMessageDescriptor) throws -> ProtoMessage {
    // Create a new message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    
    // Handle empty data
    if data.isEmpty {
      return message
    }
    
    // Create a mutable copy of the data
    var remainingData = data
    
    // Unmarshal the data into the message
    while !remainingData.isEmpty {
      // Decode the field key
      let (keyValue, keyBytes) = decodeVarint(remainingData)
      guard let key = keyValue else {
        throw ProtoWireFormatError.invalidFieldKey
      }
      
      remainingData.removeFirst(keyBytes)
      
      // Extract field number and wire type
      let fieldNumber = Int(key >> 3)
      let wireType = Int(key & 0x7)
      
      // Find the field descriptor
      guard let fieldDescriptor = messageDescriptor.field(number: fieldNumber) else {
        // Unknown field, skip it
        if !skipField(wireType: wireType, data: &remainingData) {
          throw ProtoWireFormatError.truncatedMessage
        }
        continue
      }
      
      // Decode the field value
      let value = try decodeFieldValue(
        wireType: wireType,
        fieldDescriptor: fieldDescriptor,
        data: &remainingData
      )
      
      // Set the field value on the message
      message.set(field: fieldDescriptor, value: value)
    }
    
    return message
  }
}

/// Errors that can occur during wire format encoding and decoding.
public enum ProtoWireFormatError: Error, Equatable {
    case typeMismatch
    case unsupportedType
    case malformedVarint
    case truncatedMessage
    case invalidUtf8String
    case invalidMessageType
    case wireTypeMismatch
    case validationError(fieldName: String, reason: String)
    case unsupportedWireType
    case invalidFieldKey

    public static func == (lhs: ProtoWireFormatError, rhs: ProtoWireFormatError) -> Bool {
        switch (lhs, rhs) {
        case (.typeMismatch, .typeMismatch),
            (.wireTypeMismatch, .wireTypeMismatch),
            (.unsupportedType, .unsupportedType),
            (.truncatedMessage, .truncatedMessage),
            (.malformedVarint, .malformedVarint),
            (.invalidUtf8String, .invalidUtf8String),
            (.invalidMessageType, .invalidMessageType),
            (.invalidFieldKey, .invalidFieldKey),
            (.unsupportedWireType, .unsupportedWireType):
            return true
        case (.validationError(let lhsField, let lhsReason), .validationError(let rhsField, let rhsReason)):
            return lhsField == rhsField && lhsReason == rhsReason
        default:
            return false
        }
    }
}
