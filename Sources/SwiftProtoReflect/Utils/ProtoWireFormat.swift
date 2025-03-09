import Foundation

struct ProtoWireFormat {

	// Serializes a ProtoMessage into protobuf wire format.
	static func marshal(message: ProtoMessage) -> Data? {
		var data = Data()

		let descriptor = message.descriptor()
		for field in descriptor.fields {
			if let value = message.get(field: field) {
				// Encode the field key (field number + wire type)
				let fieldNumber = field.number
				let wireType = determineWireType(for: field.type)
				let fieldKey = UInt64(fieldNumber << 3 | wireType)
				data.append(encodeVarint(fieldKey))

				// Encode the field value based on the wire type
				switch value {
				case .intValue(let intValue):
					data.append(encodeVarint(UInt64(intValue)))
				// Add more cases for other types as needed
				default:
					break
				}
			}
		}
		return data
	}

	// Deserializes protobuf wire format data into a ProtoMessage.
	static func unmarshal(data: Data, messageDescriptor: ProtoMessageDescriptor) -> ProtoMessage? {
		var dataStream = data
		let message = ProtoDynamicMessage(descriptor: messageDescriptor)

		while !dataStream.isEmpty {
			// Decode the field key
			let (fieldKey, fieldKeyBytes) = decodeVarint(dataStream)
			guard let fieldKey = fieldKey else {
				return nil // Return nil if fieldKey is invalid
			}
			dataStream.removeFirst(fieldKeyBytes)

			// Extract field number and wire type from fieldKey
			let fieldNumber = Int(fieldKey >> 3)
			let wireType = Int(fieldKey & 0x07)

			// Find the field descriptor using the field number
			guard let fieldDescriptor = messageDescriptor.fields.first(where: { $0.number == fieldNumber }) else {
				return nil
			}

			// Decode the value based on wire type
			switch wireType {
			case 0: // Varint
				let (varintValue, valueBytes) = decodeVarint(dataStream)
				dataStream.removeFirst(valueBytes)
				if let intValue = varintValue {
					message.set(field: fieldDescriptor, value: .intValue(Int(intValue)))
				}
			// Add more cases for other wire types as needed
			default:
				break
			}
		}
		return message
	}

	// Helper functions: encode/decode varint, determine wire type
	private static func encodeVarint(_ value: UInt64) -> Data {
		var result = Data()
		var v = value
		while v >= 0x80 {
			result.append(UInt8(v & 0x7F | 0x80))
			v >>= 7
		}
		result.append(UInt8(v))
		return result
	}

	private static func decodeVarint(_ data: Data) -> (UInt64?, Int) {
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
		}
		return (nil, consumedBytes) // Return nil if varint decoding fails
	}

	private static func determineWireType(for fieldType: ProtoFieldType) -> Int {
		switch fieldType {
		case .int32, .int64, .uint32, .uint64, .bool:
			return 0 // Varint wire type
		case .string, .message:
			return 2 // Length-delimited wire type
		default:
			return 0
		}
	}
}

