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
  /// - Parameters:
  ///   - message: The message to serialize.
  ///   - options: Options for controlling the serialization process.
  /// - Returns: The serialized data.
  /// - Throws: `ProtoWireFormatError` if validation fails or serialization encounters an error.
  public static func marshal(message: ProtoMessage, options: SerializationOptions = SerializationOptions()) throws -> Data {
    // Validate the message if required
    if options.validateFields {
      try validateMessage(message)
    }
    
    let estimatedSize = estimateMessageSize(message)
    var data: Data
    
    if options.useBufferPool {
      // Use buffer pool for memory allocation
      let buffer = BufferPool.shared.acquire(size: estimatedSize)
      defer { BufferPool.shared.release(buffer) }
      
      // Create a Data instance from the buffer
      data = Data(bytesNoCopy: buffer.data.baseAddress!,
                 count: buffer.data.count,
                 deallocator: .none)
      data.count = 0  // Reset for appending
    } else {
      // Allocate memory directly
      data = Data(capacity: estimatedSize)
    }

      // Marshal all fields
      for field in message.descriptor().fields {
        if let value = message.get(field: field) {
        // Skip fields with default values in proto3 if not preserving defaults
        if !options.preserveProto3Defaults && isProto3DefaultValue(value, for: field) {
          continue
        }
        
            try encodeField(field: field, value: value, to: &data)
          }
    }
    
    // Include unknown fields if not skipping them
    if !options.skipUnknownFields, let dynamicMessage = message as? ProtoDynamicMessage {
      let unknownFields = dynamicMessage.getUnknownFields()
      encodeUnknownFields(unknownFields, to: &data)
      }

      return data
  }
  
  /// Estimates the size of a serialized message.
  ///
  /// - Parameter message: The message to estimate.
  /// - Returns: The estimated size in bytes.
  private static func estimateMessageSize(_ message: ProtoMessage) -> Int {
    var size = 0
    
    // Estimate for each field
    for field in message.descriptor().fields {
      if let value = message.get(field: field) {
        size += estimateFieldSize(field: field, value: value)
      }
    }
    
    // Estimate for unknown fields
    if let dynamicMessage = message as? ProtoDynamicMessage {
      let unknownFields = dynamicMessage.getUnknownFields()
      for (_, dataArray) in unknownFields {
        for data in dataArray {
          size += data.count
        }
      }
    }
    
    // Add some buffer for good measure
    return max(size, 64) * 2  // Double it to be safe
  }
  
  /// Estimates the size of a serialized field.
  ///
  /// - Parameters:
  ///   - field: The field descriptor.
  ///   - value: The field value.
  /// - Returns: The estimated size in bytes.
  private static func estimateFieldSize(field: ProtoFieldDescriptor, value: ProtoValue) -> Int {
    // Size of field tag (varint field number + wire type)
    let tagSize = sizeOfVarint(UInt64(field.number << 3))
    
    if field.isRepeated {
      guard case .repeatedValue(let array) = value else { return tagSize }
      
      var elementSize = 0
      for element in array {
        elementSize += estimateValueSize(field: field, value: element)
      }
      
      return tagSize + elementSize
    }
    
    if field.isMap {
      guard case .mapValue(let map) = value else { return tagSize }
      
      var entriesSize = 0
      for (key, value) in map {
        // Each map entry is a nested message with key (field 1) and value (field 2)
        let keyTagSize = sizeOfVarint(1 << 3 | UInt64(wireTypeLengthDelimited))
        let keySize = sizeOfString(key)
        let valueTagSize = sizeOfVarint(2 << 3 | UInt64(determineWireType(for: field.type)))
        let valueSize = estimateValueSize(field: field, value: value)
        
        let entrySize = keyTagSize + keySize + valueTagSize + valueSize
        entriesSize += tagSize + sizeOfVarint(UInt64(entrySize)) + entrySize
      }
      
      return entriesSize
    }
    
    return tagSize + estimateValueSize(field: field, value: value)
  }
  
  /// Estimates the size of a serialized value.
  ///
  /// - Parameters:
  ///   - field: The field descriptor.
  ///   - value: The field value.
  /// - Returns: The estimated size in bytes.
  private static func estimateValueSize(field: ProtoFieldDescriptor, value: ProtoValue) -> Int {
    switch field.type {
    case .int32, .int64, .uint32, .uint64, .bool, .enum:
      if case .intValue(let intValue) = value {
        return sizeOfVarint(UInt64(bitPattern: Int64(intValue)))
      }
      if case .uintValue(let uintValue) = value {
        return sizeOfVarint(UInt64(uintValue))
      }
      if case .boolValue = value {
        return 1  // Boolean is 1 byte
      }
      if case .enumValue(_, let number, _) = value {
        return sizeOfVarint(UInt64(number))
      }
      return 1  // Default estimate
      
    case .sint32:
      if case .intValue(let intValue) = value {
        return sizeOfVarint(UInt64(encodeZigZag32(Int32(intValue))))
      }
      return 1  // Default estimate
      
    case .sint64:
      if case .intValue(let intValue) = value {
        return sizeOfVarint(UInt64(encodeZigZag64(Int64(intValue))))
      }
      return 1  // Default estimate
      
    case .fixed32, .sfixed32, .float:
      return 4  // Fixed 32-bit types always use 4 bytes
      
    case .fixed64, .sfixed64, .double:
      return 8  // Fixed 64-bit types always use 8 bytes
      
    case .string:
      if case .stringValue(let stringValue) = value {
        return sizeOfString(stringValue)
      }
      return 1  // Default estimate
      
    case .bytes:
      if case .bytesValue(let bytesValue) = value {
        return sizeOfBytes(bytesValue)
      }
      return 1  // Default estimate
      
    case .message:
      if case .messageValue(let messageValue) = value {
        let messageSize = estimateMessageSize(messageValue)
        return sizeOfVarint(UInt64(messageSize)) + messageSize
      }
      return 1  // Default estimate
      
    default:
      return 1  // Default estimate for unknown types
    }
  }
  
  /// Calculates the size of a varint.
  ///
  /// - Parameter value: The value to encode as a varint.
  /// - Returns: The size in bytes.
  private static func sizeOfVarint(_ value: UInt64) -> Int {
    var size = 1
    var v = value
    while v >= 0x80 {
      size += 1
      v >>= 7
    }
    return size
  }
  
  /// Calculates the size of a string.
  ///
  /// - Parameter value: The string to encode.
  /// - Returns: The size in bytes.
  private static func sizeOfString(_ value: String) -> Int {
    if let data = value.data(using: .utf8) {
      return sizeOfVarint(UInt64(data.count)) + data.count
    }
    return 1  // Default estimate
  }
  
  /// Calculates the size of binary data.
  ///
  /// - Parameter value: The data to encode.
  /// - Returns: The size in bytes.
  private static func sizeOfBytes(_ value: Data) -> Int {
    return sizeOfVarint(UInt64(value.count)) + value.count
  }
  
  /// Checks if a value is the proto3 default value for its field.
  ///
  /// - Parameters:
  ///   - value: The value to check.
  ///   - field: The field descriptor.
  /// - Returns: `true` if the value is the proto3 default, `false` otherwise.
  private static func isProto3DefaultValue(_ value: ProtoValue, for field: ProtoFieldDescriptor) -> Bool {
    switch value {
    case .intValue(let intValue):
      return intValue == 0
    case .uintValue(let uintValue):
      return uintValue == 0
    case .boolValue(let boolValue):
      return boolValue == false
    case .floatValue(let floatValue):
      return floatValue == 0.0
    case .doubleValue(let doubleValue):
      return doubleValue == 0.0
    case .stringValue(let stringValue):
      return stringValue.isEmpty
    case .bytesValue(let bytesValue):
      return bytesValue.isEmpty
    case .enumValue(_, let number, _):
      return number == 0
    case .messageValue(_):
      // For message fields, nil is the default, not an empty message
      // But since we're dealing with an actual message, it's not the default
      return false
    case .repeatedValue(let arrayValue):
      return arrayValue.isEmpty
    case .mapValue(let mapValue):
      return mapValue.isEmpty
    }
  }
  
  /// Encodes unknown fields to the output data.
  ///
  /// - Parameters:
  ///   - unknownFields: The unknown fields to encode.
  ///   - data: The data buffer to append to.
  private static func encodeUnknownFields(_ unknownFields: [Int: [Data]], to data: inout Data) {
    for (_, fieldDataArray) in unknownFields.sorted(by: { $0.key < $1.key }) {
      for fieldData in fieldDataArray {
        data.append(fieldData)
      }
    }
  }

  /// Deserializes protobuf wire format data into a ProtoMessage.
  ///
  /// - Parameters:
  ///   - data: The serialized data.
  ///   - messageDescriptor: The descriptor for the message type.
  ///   - options: Options for controlling the deserialization process.
  /// - Returns: The deserialized message, or nil if deserialization fails.
  public static func unmarshal(data: Data, messageDescriptor: ProtoMessageDescriptor, options: SerializationOptions = SerializationOptions()) -> ProtoMessage? {
    // Create a new message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    
    // Handle empty data
    if data.isEmpty {
        return message
    }
    
    // Create a mutable copy of the data
    var remainingData = data
    
    do {
        // Track recursion depth for nested messages
        var recursionDepth = 0
        let maxDepth = options.maxDepth
        
        // Used to track repeated and map fields
        var repeatedFields: [Int: [ProtoValue]] = [:]
        var mapFields: [Int: [String: ProtoValue]] = [:]
        
        // Initialize empty repeated fields
        for field in messageDescriptor.fields {
            if field.isRepeated {
                repeatedFields[field.number] = []
            }
        }
        
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
                // Unknown field, preserve it if not configured to skip
                if !options.skipUnknownFields {
                    // Capture field data based on wire type
                    var fieldData = Data()
                    
                    // Store the field key
                    fieldData.append(encodeVarint(key))
                    
                    // Skip over this field and preserve its data
                    if !captureUnknownField(wireType: wireType, data: &remainingData, into: &fieldData) {
                        return nil  // Truncated message
                    }
                    
                    message.setUnknownField(fieldNumber: fieldNumber, data: fieldData)
                } else {
                    // Just skip the field
                    if !skipField(wireType: wireType, data: &remainingData) {
                        return nil  // Failed to skip field
                    }
                }
                continue
            }
            
            // Check if the wire type matches the expected wire type for the field type
            let expectedWireType = determineWireType(for: fieldDescriptor.type)
            if wireType != expectedWireType {
                // Wire type mismatch, skip the field
                if !skipField(wireType: wireType, data: &remainingData) {
                    return nil  // Failed to skip field
                }
                continue
            }
            
            // Decode the field value
            let value = try decodeFieldValue(
                wireType: wireType,
                fieldDescriptor: fieldDescriptor,
                data: &remainingData,
                recursionDepth: &recursionDepth,
                maxDepth: maxDepth,
                options: options
            )
            
            // Handle different field types
            if fieldDescriptor.isRepeated {
                // Add to repeated field collection
                var values = repeatedFields[fieldDescriptor.number] ?? []
                values.append(value)
                repeatedFields[fieldDescriptor.number] = values
            } else if fieldDescriptor.isMap {
                // Handle map entry (which is encoded as a nested message)
                if case .messageValue(let mapEntryMessage) = value {
                    let keyField = mapEntryMessage.descriptor().field(number: 1)
                    let valueField = mapEntryMessage.descriptor().field(number: 2)
                    
                    let keyValue = keyField.flatMap { mapEntryMessage.get(field: $0) }
                    let valueValue = valueField.flatMap { mapEntryMessage.get(field: $0) }
                    
                    if case .stringValue(let key)? = keyValue {
                        // Add the key-value pair to the map field collection
                        var entries = mapFields[fieldDescriptor.number] ?? [:]
                        entries[key] = valueValue
                        mapFields[fieldDescriptor.number] = entries
                    }
                }
            } else {
                // Regular field
            message.set(field: fieldDescriptor, value: value)
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
        
        // Validate if configured
        if options.validateFields {
            if !message.validateFields() {
                return nil  // Validation failed
            }
        }
        
        return message
    }
    catch {
        return nil
    }
  }

  /// Captures an unknown field's data based on its wire type.
  ///
  /// - Parameters:
  ///   - wireType: The wire type.
  ///   - data: The data buffer to read from.
  ///   - fieldData: The destination buffer to append the field data to.
  /// - Returns: `true` if the field was successfully captured, `false` otherwise.
  private static func captureUnknownField(wireType: Int, data: inout Data, into fieldData: inout Data) -> Bool {
    switch wireType {
    case wireTypeVarint:  // Varint
        let (value, valueBytes) = decodeVarint(data)
        if valueBytes >= data.count || value == nil {
            return false
        }
        if let value = value {
            fieldData.append(encodeVarint(value))
        }
        data.removeFirst(valueBytes)
        return true
        
    case wireTypeFixed64:  // Fixed 64-bit
        if data.count < 8 {
            return false
        }
        fieldData.append(contentsOf: data.prefix(8))
        data.removeFirst(8)
        return true
        
    case wireTypeLengthDelimited:  // Length-delimited
        let (lengthValue, lengthBytes) = decodeVarint(data)
        if lengthBytes >= data.count || lengthValue == nil {
            return false
        }
        data.removeFirst(lengthBytes)
        
        let length = Int(lengthValue!)
        if length > data.count {
            return false
        }
        
        // Append length and data
        fieldData.append(encodeVarint(lengthValue!))
        fieldData.append(contentsOf: data.prefix(length))
        data.removeFirst(length)
        return true
        
    case wireTypeFixed32:  // Fixed 32-bit
        if data.count < 4 {
            return false
        }
        fieldData.append(contentsOf: data.prefix(4))
        data.removeFirst(4)
        return true
        
    default:
        return skipField(wireType: wireType, data: &data)  // Use skip for unsupported types
    }
  }
  
  /// Decodes a field value from the wire format.
  ///
  /// - Parameters:
  ///   - wireType: The wire type.
  ///   - fieldDescriptor: The field descriptor.
  ///   - data: The data buffer to read from.
  ///   - recursionDepth: The current recursion depth for nested messages.
  ///   - maxDepth: The maximum allowed recursion depth.
  ///   - options: The serialization options.
  /// - Returns: The decoded field value.
  /// - Throws: An error if decoding fails.
  private static func decodeFieldValue(
    wireType: Int,
    fieldDescriptor: ProtoFieldDescriptor,
    data: inout Data,
    recursionDepth: inout Int,
    maxDepth: Int,
    options: SerializationOptions
  ) throws -> ProtoValue {
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
        if options.validateUTF8 {
          guard let stringValue = String(data: valueData, encoding: .utf8) else {
            throw ProtoWireFormatError.invalidUtf8String
          }
          return .stringValue(stringValue)
        } else {
          // Skip UTF-8 validation if not required
          let stringValue = String(data: valueData, encoding: .utf8) ?? ""
          return .stringValue(stringValue)
        }

      case .bytes:
        return .bytesValue(Data(valueData))

      case .message:
        // Check recursion depth
        recursionDepth += 1
        if recursionDepth > maxDepth {
          throw ProtoWireFormatError.validationError(fieldName: fieldDescriptor.name, reason: "Maximum recursion depth exceeded")
        }
        
        guard let messageType = fieldDescriptor.messageType else {
          throw ProtoWireFormatError.invalidMessageType
        }
        
        // Recursively decode the nested message
        let nestedMessage = try decodeMessageData(Data(valueData), messageDescriptor: messageType, recursionDepth: &recursionDepth, options: options)
        
        // Decrement recursion depth after processing nested message
        recursionDepth -= 1
        
        return .messageValue(nestedMessage)

      default:
        throw ProtoWireFormatError.wireTypeMismatch
      }

    default:
      throw ProtoWireFormatError.unsupportedWireType
    }
  }
  
  /// Decodes message data into a ProtoMessage.
  ///
  /// - Parameters:
  ///   - data: The message data.
  ///   - messageDescriptor: The message descriptor.
  ///   - recursionDepth: The current recursion depth.
  ///   - options: The serialization options.
  /// - Returns: The decoded message.
  /// - Throws: An error if decoding fails.
  private static func decodeMessageData(
    _ data: Data,
    messageDescriptor: ProtoMessageDescriptor,
    recursionDepth: inout Int,
    options: SerializationOptions
  ) throws -> ProtoMessage {
    // Create a new message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    
    // Handle empty data
    if data.isEmpty {
      return message
    }
    
    // Create a mutable copy of the data
    var remainingData = data
    
    // Used to track repeated and map fields
    var repeatedFields: [Int: [ProtoValue]] = [:]
    var mapFields: [Int: [String: ProtoValue]] = [:]
    
    // Initialize empty repeated fields
    for field in messageDescriptor.fields {
      if field.isRepeated {
        repeatedFields[field.number] = []
      }
    }
    
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
        // Unknown field, preserve it if not configured to skip
        if !options.skipUnknownFields {
          // Capture field data based on wire type
          var fieldData = Data()
          
          // Store the field key
          fieldData.append(encodeVarint(key))
          
          // Skip over this field and preserve its data
          if !captureUnknownField(wireType: wireType, data: &remainingData, into: &fieldData) {
            throw ProtoWireFormatError.truncatedMessage
        }

        message.setUnknownField(fieldNumber: fieldNumber, data: fieldData)
        } else {
          // Just skip the field
          if !skipField(wireType: wireType, data: &remainingData) {
            throw ProtoWireFormatError.truncatedMessage
          }
        }
        continue
      }

      // Check if the wire type matches the expected wire type for the field type
      let expectedWireType = determineWireType(for: fieldDescriptor.type)
      if wireType != expectedWireType {
        // Wire type mismatch, skip the field
        if !skipField(wireType: wireType, data: &remainingData) {
          throw ProtoWireFormatError.truncatedMessage
        }
        continue
      }

      // Decode the field value
      let value = try decodeFieldValue(
        wireType: wireType,
        fieldDescriptor: fieldDescriptor,
        data: &remainingData,
        recursionDepth: &recursionDepth,
        maxDepth: options.maxDepth,
        options: options
      )
      
      // Handle different field types
      if fieldDescriptor.isRepeated {
        // Add to repeated field collection
        var values = repeatedFields[fieldDescriptor.number] ?? []
        values.append(value)
        repeatedFields[fieldDescriptor.number] = values
      } else if fieldDescriptor.isMap {
        // Handle map entry (which is encoded as a nested message)
          if case .messageValue(let mapEntryMessage) = value {
            let keyField = mapEntryMessage.descriptor().field(number: 1)
            let valueField = mapEntryMessage.descriptor().field(number: 2)

            let keyValue = keyField.flatMap { mapEntryMessage.get(field: $0) }
            let valueValue = valueField.flatMap { mapEntryMessage.get(field: $0) }

            if case .stringValue(let key)? = keyValue {
              // Add the key-value pair to the map field collection
            var entries = mapFields[fieldDescriptor.number] ?? [:]
              entries[key] = valueValue
            mapFields[fieldDescriptor.number] = entries
          }
        }
      } else {
        // Regular field
          message.set(field: fieldDescriptor, value: value)
      }
    }

    // Set all repeated fields
    for (fieldNumber, values) in repeatedFields {
      if let fieldDescriptor = messageDescriptor.field(number: fieldNumber),
         !values.isEmpty {
        message.set(field: fieldDescriptor, value: .repeatedValue(values))
      }
    }

    // Set all map fields
    for (fieldNumber, entries) in mapFields {
      if let fieldDescriptor = messageDescriptor.field(number: fieldNumber),
         !entries.isEmpty {
        message.set(field: fieldDescriptor, value: .mapValue(entries))
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
      
      if case .uintValue(let uintValue) = value {
        var v = UInt32(uintValue)
        var bytes = [UInt8](repeating: 0, count: 4)
        withUnsafeBytes(of: &v) { valueBytes in
          bytes.withUnsafeMutableBytes { target in
            target.copyMemory(from: valueBytes)
          }
        }
        data.append(contentsOf: bytes)
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

    case .fixed64, .sfixed64:
      let tag = (UInt64(field.number) << 3) | UInt64(wireTypeFixed64)
      data.append(encodeVarint(tag))
      
      if case .uintValue(let uintValue) = value {
        var v = UInt64(uintValue)
        var bytes = [UInt8](repeating: 0, count: 8)
        withUnsafeBytes(of: &v) { valueBytes in
          bytes.withUnsafeMutableBytes { target in
            target.copyMemory(from: valueBytes)
          }
        }
        data.append(contentsOf: bytes)
      }
      else {
        throw ProtoWireFormatError.typeMismatch
      }

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
    let messageData = try marshal(message: message)
    
    // 3. Write length
    data.append(encodeVarint(UInt64(messageData.count)))
    
    // 4. Write message data
    data.append(messageData)
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
