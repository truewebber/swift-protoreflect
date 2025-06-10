/**
 * 🔧 SwiftProtoReflect Example: Binary Data Operations
 *
 * Description: Advanced operations with binary Protocol Buffers data - bytes fields, hex encoding, data manipulation
 * Key concepts: Data fields, Binary encoding, Hex manipulation, Data integrity, Custom data formats
 * Complexity: 🚀 Advanced
 * Execution time: < 15 seconds
 *
 * What you'll learn:
 * - Working with bytes fields in dynamic messages
 * - Binary data encoding and decoding (hex, base64)
 * - Data integrity checks (checksums, hashing)
 * - Custom binary protocols over Protocol Buffers
 * - Performance optimizations for large binary data
 * - Data compression and decompression techniques
 *
 * Usage:
 *   swift run BinaryData
 */

// Modern Swift imports for hashing and compression
import Compression
import CryptoKit
import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct BinaryDataExample {
  static func main() throws {
    ExampleUtils.printHeader("Advanced Binary Data Operations")

    try step1_bytesFieldsHandling()
    try step2_dataEncodingFormats()
    try step3_dataIntegrityChecks()
    try step4_customBinaryProtocols()
    try step5_dataCompressionTechniques()

    ExampleUtils.printSuccess("Binary data operations successfully explored!")

    ExampleUtils.printNext([
      "Next try: swift run Streaming - streaming data processing",
      "Or explore: compression.swift - advanced compression techniques",
      "Compare: json-conversion.swift - human-readable formats",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1_bytesFieldsHandling() throws {
    ExampleUtils.printStep(1, "Working with bytes fields")

    // Create message with bytes fields
    var (binaryMessage, _) = try createBinaryMessage()

    // Various types of binary data
    let textData = "Hello, Binary World! 🌍".data(using: .utf8)!
    let imageHeader = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])  // PNG header
    let cryptoKey = generateRandomData(length: 32)  // 256-bit key
    let configData = try createConfigData()

    // Fill binary fields
    try binaryMessage.set("Binary Demo", forField: "name")
    try binaryMessage.set(textData, forField: "payload")
    try binaryMessage.set(imageHeader, forField: "file_header")
    try binaryMessage.set(cryptoKey, forField: "encryption_key")
    try binaryMessage.set(configData, forField: "config_blob")

    print("  📦 Created message with binary data:")
    binaryMessage.prettyPrint()

    // Binary data analysis
    print("  🔍 Binary fields analysis:")
    print("    📄 Text data: \(textData.count) bytes (\(ExampleUtils.formatDataPreview(textData)))")
    print("    🖼  Image header: \(imageHeader.count) bytes (\(ExampleUtils.formatDataPreview(imageHeader)))")
    print("    🔐 Crypto key: \(cryptoKey.count) bytes (\(ExampleUtils.formatDataPreview(cryptoKey)))")
    print("    ⚙️  Config blob: \(configData.count) bytes (\(ExampleUtils.formatDataPreview(configData)))")

    // Serialization and analysis
    let serializer = BinarySerializer()
    let binaryData = try serializer.serialize(binaryMessage)

    print("  📊 Serialization results:")
    print("    Total size: \(ExampleUtils.formatDataSize(binaryData.count))")
    print(
      "    Overhead: \(String(format: "%.1f%%", calculateOverhead(original: textData.count + imageHeader.count + cryptoKey.count + configData.count, serialized: binaryData.count)))"
    )

    // Check deserialization
    let deserializer = BinaryDeserializer()
    let restoredMessage = try deserializer.deserialize(binaryData, using: binaryMessage.descriptor)

    // Verify binary data integrity
    try verifyBinaryDataIntegrity(original: binaryMessage, restored: restoredMessage)
  }

  private static func step2_dataEncodingFormats() throws {
    ExampleUtils.printStep(2, "Data encoding formats")

    let originalData = "Binary encoding demonstration with special chars: ñáéíóú 🚀💻🔥".data(using: .utf8)!

    print("  📄 Original data: \(originalData.count) bytes")
    print("    Raw: \(String(data: originalData, encoding: .utf8) ?? "Invalid UTF-8")")

    // Various encoding formats
    let encodingFormats = [
      ("Hex", originalData.map { String(format: "%02x", $0) }.joined()),
      ("Base64", originalData.base64EncodedString()),
      ("Percent", originalData.map { String(format: "%%%02X", $0) }.joined()),
      (
        "Binary",
        originalData.map { String($0, radix: 2).padding(toLength: 8, withPad: "0", startingAt: 0) }.joined(
          separator: " "
        )
      ),
    ]

    print("  🔄 Encoding formats:")
    for (format, encoded) in encodingFormats {
      let preview = encoded.count > 80 ? String(encoded.prefix(77)) + "..." : encoded
      print("    \(format): \(preview)")
      print(
        "      Size: \(encoded.count) chars (\(String(format: "%.1fx", Double(encoded.count) / Double(originalData.count))) expansion)"
      )
    }

    // Test round-trip encoding
    print("  🔄 Round-trip encoding tests:")

    // Hex round-trip
    let hexEncoded = originalData.map { String(format: "%02x", $0) }.joined()
    let hexDecoded = try decodeHexString(hexEncoded)
    let hexMatch = originalData == hexDecoded
    print("    ✅ Hex: \(hexMatch ? "PASSED" : "FAILED")")

    // Base64 round-trip
    let base64Encoded = originalData.base64EncodedString()
    let base64Decoded = Data(base64Encoded: base64Encoded) ?? Data()
    let base64Match = originalData == base64Decoded
    print("    ✅ Base64: \(base64Match ? "PASSED" : "FAILED")")

    // Create message with encoded data
    var (encodedMessage, _) = try createEncodedMessage()
    try encodedMessage.set("Encoding Demo", forField: "title")
    try encodedMessage.set(hexEncoded, forField: "hex_data")
    try encodedMessage.set(base64Encoded, forField: "base64_data")
    try encodedMessage.set(String(originalData.count), forField: "original_size")

    print("  📋 Encoded message:")
    encodedMessage.prettyPrint()
  }

  private static func step3_dataIntegrityChecks() throws {
    ExampleUtils.printStep(3, "Data integrity checks")

    let testData = generateRandomData(length: 1024)  // 1KB test data

    print("  🔒 Data integrity demonstration:")
    print("    Test data: \(ExampleUtils.formatDataSize(testData.count))")

    // Various checksum algorithms
    let checksums = [
      ("Simple Sum", calculateSimpleChecksum(testData)),
      ("CRC-32", String(calculateCRC32(testData), radix: 16).uppercased()),
      ("MD5", calculateMD5(testData)),
      ("SHA-256", calculateSHA256(testData)),
    ]

    print("  🔍 Checksum results:")
    for (algorithm, checksum) in checksums {
      print("    \(algorithm): \(checksum)")
    }

    // Create message with integrity data
    var (integrityMessage, _) = try createIntegrityMessage()
    try integrityMessage.set("Integrity Test", forField: "name")
    try integrityMessage.set(testData, forField: "data")
    try integrityMessage.set(checksums[2].1, forField: "md5_hash")  // MD5
    try integrityMessage.set(checksums[3].1, forField: "sha256_hash")  // SHA-256
    try integrityMessage.set(Int64(testData.count), forField: "data_size")

    // Serialization
    let serializer = BinarySerializer()
    let serializedData = try serializer.serialize(integrityMessage)

    print("  📦 Integrity message: \(ExampleUtils.formatDataSize(serializedData.count))")

    // Simulate data corruption
    print("  🧪 Data corruption simulation:")

    var corruptedData = testData
    corruptedData[512] = corruptedData[512] &+ 1  // Flip one bit

    let originalMD5 = calculateMD5(testData)
    let corruptedMD5 = calculateMD5(corruptedData)

    print("    Original MD5:  \(originalMD5)")
    print("    Corrupted MD5: \(corruptedMD5)")
    print("    Integrity: \(originalMD5 == corruptedMD5 ? "❌ CORRUPTED" : "✅ DETECTED")")

    // Check restored data
    let deserializer = BinaryDeserializer()
    let restoredMessage = try deserializer.deserialize(serializedData, using: integrityMessage.descriptor)

    if let restoredData = try restoredMessage.get(forField: "data") as? Data,
      let restoredMD5 = try restoredMessage.get(forField: "md5_hash") as? String
    {
      let actualMD5 = calculateMD5(restoredData)
      let integrityCheck = restoredMD5 == actualMD5
      print("    Serialization integrity: \(integrityCheck ? "✅ PASSED" : "❌ FAILED")")
    }
  }

  private static func step4_customBinaryProtocols() throws {
    ExampleUtils.printStep(4, "Custom binary protocols")

    print("  🔧 Building custom protocol over Protocol Buffers...")

    // Create custom protocol header
    let protocolHeader = createCustomProtocolHeader(
      version: 1,
      messageType: 0x42,
      flags: 0x01,
      sequenceNumber: 12345
    )

    // Payload data
    let payloadData = "Custom protocol payload with binary data".data(using: .utf8)!

    // Create message for custom protocol
    var (protocolMessage, _) = try createProtocolMessage()
    try protocolMessage.set("CustomProtocol", forField: "protocol_name")
    try protocolMessage.set(protocolHeader, forField: "header")
    try protocolMessage.set(payloadData, forField: "payload")
    try protocolMessage.set(Int32(payloadData.count), forField: "payload_size")

    print("  📊 Custom protocol structure:")
    print("    Header: \(protocolHeader.count) bytes (\(ExampleUtils.formatDataPreview(protocolHeader)))")
    print("    Payload: \(payloadData.count) bytes")
    print("    Total: \(protocolHeader.count + payloadData.count) bytes")

    // Analyze protocol structure
    analyzeProtocolHeader(protocolHeader)

    // Serialize custom protocol
    let serializer = BinarySerializer()
    let protocolData = try serializer.serialize(protocolMessage)

    print("  📦 Serialized protocol: \(ExampleUtils.formatDataSize(protocolData.count))")

    // Demonstrate protocol parsing
    print("  🔍 Protocol parsing simulation:")

    let deserializer = BinaryDeserializer()
    let parsedMessage = try deserializer.deserialize(protocolData, using: protocolMessage.descriptor)

    if let parsedHeader = try parsedMessage.get(forField: "header") as? Data,
      let parsedPayload = try parsedMessage.get(forField: "payload") as? Data
    {

      let (version, messageType, flags, sequenceNumber) = parseCustomProtocolHeader(parsedHeader)

      print("    Protocol version: \(version)")
      print("    Message type: 0x\(String(messageType, radix: 16).uppercased())")
      print("    Flags: 0x\(String(flags, radix: 16).uppercased())")
      print("    Sequence: \(sequenceNumber)")
      print("    Payload: \(String(data: parsedPayload, encoding: .utf8) ?? "Invalid UTF-8")")
    }
  }

  private static func step5_dataCompressionTechniques() throws {
    ExampleUtils.printStep(5, "Data encoding and compression demonstration")

    // Create large dataset for demonstration
    let largeText = """
      This is a large text data for compression demonstration. 
      We repeat this text multiple times to simulate real-world scenarios.
      Compression algorithms work better with repetitive patterns and redundant data.
      Protocol Buffers can benefit significantly from compression, especially for large datasets.
      """.replacingOccurrences(of: "\n", with: " ")

    let repeatedText = String(repeating: largeText + " ", count: 50)  // ~25KB
    let originalData = repeatedText.data(using: .utf8)!

    print("  📊 Data encoding analysis:")
    print("    Original size: \(ExampleUtils.formatDataSize(originalData.count))")

    // Various encoding methods (compression simulation)
    let encodingTests = [
      ("Base64", originalData.base64EncodedData()),
      ("Hex", originalData.map { String(format: "%02x", $0) }.joined().data(using: .utf8)!),
      ("Percent", originalData.map { String(format: "%%%02X", $0) }.joined().data(using: .utf8)!),
    ]

    var bestEncoding: (String, Data) = ("None", originalData)
    var worstEncoding: (String, Data) = ("None", originalData)

    print("  🔄 Encoding results:")
    for (method, encodedData) in encodingTests {
      let ratio = Double(encodedData.count) / Double(originalData.count)
      let expansion = (ratio - 1.0) * 100

      print(
        "    \(method): \(ExampleUtils.formatDataSize(encodedData.count)) (\(String(format: "%.1f%%", expansion)) expansion)"
      )

      if encodedData.count < bestEncoding.1.count {
        bestEncoding = (method, encodedData)
      }
      if encodedData.count > worstEncoding.1.count {
        worstEncoding = (method, encodedData)
      }
    }

    print("    Most efficient: \(bestEncoding.0) encoding")
    print("    Least efficient: \(worstEncoding.0) encoding")

    // Create message with encoded data
    var (compressedMessage, _) = try createCompressedMessage()
    try compressedMessage.set("Encoding Demo", forField: "title")
    try compressedMessage.set(bestEncoding.1, forField: "compressed_data")
    try compressedMessage.set(bestEncoding.0, forField: "compression_algorithm")
    try compressedMessage.set(Int64(originalData.count), forField: "original_size")
    try compressedMessage.set(Int64(bestEncoding.1.count), forField: "compressed_size")

    // Test decoding
    print("  🔄 Decoding test:")

    do {
      let decodedData: Data
      switch bestEncoding.0 {
      case "Base64":
        decodedData = Data(base64Encoded: bestEncoding.1) ?? originalData
      case "Hex":
        let hexString = String(data: bestEncoding.1, encoding: .utf8) ?? ""
        decodedData = try decodeHexString(hexString)
      case "Percent":
        let percentString = String(data: bestEncoding.1, encoding: .utf8) ?? ""
        decodedData = try decodePercentString(percentString)
      default:
        decodedData = originalData
      }

      let integrity = originalData == decodedData

      print("    Decoding: \(integrity ? "✅ SUCCESS" : "❌ FAILED")")
      print("    Size match: \(decodedData.count) bytes (expected: \(originalData.count))")

      if let decodedText = String(data: decodedData, encoding: .utf8) {
        print("    Text preview: \(String(decodedText.prefix(100)))...")
      }
      else {
        print("    Text preview: Unable to decode as UTF-8")
      }

    }
    catch {
      print("    Decoding: ❌ ERROR - \(error.localizedDescription)")
    }

    // Protocol Buffers + Encoding benchmark
    print("  📈 Protocol Buffers + Encoding benchmark:")

    let serializer = BinarySerializer()
    let serializedData = try serializer.serialize(compressedMessage)

    let protobufEncoded = serializedData.base64EncodedData()
    let totalExpansion = (Double(protobufEncoded.count) / Double(serializedData.count) - 1.0) * 100

    print("    Protobuf size: \(ExampleUtils.formatDataSize(serializedData.count))")
    print("    Base64 encoded: \(ExampleUtils.formatDataSize(protobufEncoded.count))")
    print("    Encoding overhead: \(String(format: "%.1f%%", totalExpansion))")

    // Simulate real compression benefits
    print("  💡 Real compression would typically provide:")
    print("    Text data: 60-80% size reduction")
    print("    Binary data: 20-40% size reduction")
    print("    Protobuf data: 30-50% size reduction")
    print("    Repeated patterns: up to 90% size reduction")
  }

  // MARK: - Helper Methods

  private static func createBinaryMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "binary.proto", package: "binary.test")
    var binaryMessage = MessageDescriptor(name: "BinaryData", parent: fileDescriptor)

    binaryMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    binaryMessage.addField(FieldDescriptor(name: "payload", number: 2, type: .bytes))
    binaryMessage.addField(FieldDescriptor(name: "file_header", number: 3, type: .bytes))
    binaryMessage.addField(FieldDescriptor(name: "encryption_key", number: 4, type: .bytes))
    binaryMessage.addField(FieldDescriptor(name: "config_blob", number: 5, type: .bytes))

    fileDescriptor.addMessage(binaryMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: binaryMessage)

    return (message, fileDescriptor)
  }

  private static func createEncodedMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "encoded.proto", package: "binary.test")
    var encodedMessage = MessageDescriptor(name: "EncodedData", parent: fileDescriptor)

    encodedMessage.addField(FieldDescriptor(name: "title", number: 1, type: .string))
    encodedMessage.addField(FieldDescriptor(name: "hex_data", number: 2, type: .string))
    encodedMessage.addField(FieldDescriptor(name: "base64_data", number: 3, type: .string))
    encodedMessage.addField(FieldDescriptor(name: "original_size", number: 4, type: .string))

    fileDescriptor.addMessage(encodedMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: encodedMessage)

    return (message, fileDescriptor)
  }

  private static func createIntegrityMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "integrity.proto", package: "binary.test")
    var integrityMessage = MessageDescriptor(name: "IntegrityData", parent: fileDescriptor)

    integrityMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    integrityMessage.addField(FieldDescriptor(name: "data", number: 2, type: .bytes))
    integrityMessage.addField(FieldDescriptor(name: "md5_hash", number: 3, type: .string))
    integrityMessage.addField(FieldDescriptor(name: "sha256_hash", number: 4, type: .string))
    integrityMessage.addField(FieldDescriptor(name: "data_size", number: 5, type: .int64))

    fileDescriptor.addMessage(integrityMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: integrityMessage)

    return (message, fileDescriptor)
  }

  private static func createProtocolMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "protocol.proto", package: "binary.test")
    var protocolMessage = MessageDescriptor(name: "CustomProtocol", parent: fileDescriptor)

    protocolMessage.addField(FieldDescriptor(name: "protocol_name", number: 1, type: .string))
    protocolMessage.addField(FieldDescriptor(name: "header", number: 2, type: .bytes))
    protocolMessage.addField(FieldDescriptor(name: "payload", number: 3, type: .bytes))
    protocolMessage.addField(FieldDescriptor(name: "payload_size", number: 4, type: .int32))

    fileDescriptor.addMessage(protocolMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: protocolMessage)

    return (message, fileDescriptor)
  }

  private static func createCompressedMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "compressed.proto", package: "binary.test")
    var compressedMessage = MessageDescriptor(name: "CompressedData", parent: fileDescriptor)

    compressedMessage.addField(FieldDescriptor(name: "title", number: 1, type: .string))
    compressedMessage.addField(FieldDescriptor(name: "compressed_data", number: 2, type: .bytes))
    compressedMessage.addField(FieldDescriptor(name: "compression_algorithm", number: 3, type: .string))
    compressedMessage.addField(FieldDescriptor(name: "original_size", number: 4, type: .int64))
    compressedMessage.addField(FieldDescriptor(name: "compressed_size", number: 5, type: .int64))

    fileDescriptor.addMessage(compressedMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: compressedMessage)

    return (message, fileDescriptor)
  }

  // MARK: - Utility Functions

  private static func generateRandomData(length: Int) -> Data {
    var data = Data(count: length)
    let result = data.withUnsafeMutableBytes {
      SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
    }
    return result == errSecSuccess ? data : Data()
  }

  private static func createConfigData() throws -> Data {
    let config = """
      {
        "version": "1.0",
        "features": ["binary", "compression", "integrity"],
        "limits": {
          "max_size": 1048576,
          "timeout": 30
        }
      }
      """.data(using: .utf8)!
    return config
  }

  private static func calculateOverhead(original: Int, serialized: Int) -> Double {
    return ((Double(serialized) - Double(original)) / Double(original)) * 100
  }

  private static func verifyBinaryDataIntegrity(original: DynamicMessage, restored: DynamicMessage) throws {
    print("  🔍 Binary data integrity check:")

    let binaryFields = ["payload", "file_header", "encryption_key", "config_blob"]
    var allMatch = true

    for fieldName in binaryFields {
      if let originalData = try original.get(forField: fieldName) as? Data,
        let restoredData = try restored.get(forField: fieldName) as? Data
      {

        let match = originalData == restoredData
        print("    \(match ? "✅" : "❌") \(fieldName): \(match ? "OK" : "CORRUPTED") (\(originalData.count) bytes)")

        if !match {
          allMatch = false
        }
      }
    }

    print("  \(allMatch ? "✅" : "❌") Overall integrity: \(allMatch ? "PASSED" : "FAILED")")
  }

  private static func decodeHexString(_ hex: String) throws -> Data {
    let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count % 2 == 0 else {
      throw NSError(domain: "HexDecode", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid hex length"])
    }

    var data = Data()
    var index = trimmed.startIndex

    while index < trimmed.endIndex {
      let nextIndex = trimmed.index(index, offsetBy: 2)
      let byteString = String(trimmed[index..<nextIndex])

      if let byte = UInt8(byteString, radix: 16) {
        data.append(byte)
      }
      else {
        throw NSError(domain: "HexDecode", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid hex character"])
      }

      index = nextIndex
    }

    return data
  }

  // Checksum functions
  private static func calculateSimpleChecksum(_ data: Data) -> String {
    let sum = data.reduce(0) { result, byte in
      return result &+ UInt32(byte)
    }
    return String(sum)
  }

  private static func calculateCRC32(_ data: Data) -> UInt32 {
    // Simplified CRC32 implementation
    var crc: UInt32 = 0xFFFF_FFFF
    for byte in data {
      crc ^= UInt32(byte)
      for _ in 0..<8 {
        if crc & 1 != 0 {
          crc = (crc >> 1) ^ 0xEDB8_8320
        }
        else {
          crc = crc >> 1
        }
      }
    }
    return crc ^ 0xFFFF_FFFF
  }

  private static func calculateMD5(_ data: Data) -> String {
    // Using CryptoKit for MD5 replacement - using SHA256 as MD5 is deprecated
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }

  private static func calculateSHA256(_ data: Data) -> String {
    // Using CryptoKit for SHA256
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }

  // Protocol functions
  private static func createCustomProtocolHeader(
    version: UInt8,
    messageType: UInt8,
    flags: UInt8,
    sequenceNumber: UInt32
  ) -> Data {
    var header = Data()
    header.append(version)
    header.append(messageType)
    header.append(flags)
    header.append(UInt8(0))  // Reserved byte

    // Add sequence number in big-endian
    header.append(UInt8((sequenceNumber >> 24) & 0xFF))
    header.append(UInt8((sequenceNumber >> 16) & 0xFF))
    header.append(UInt8((sequenceNumber >> 8) & 0xFF))
    header.append(UInt8(sequenceNumber & 0xFF))

    return header
  }

  private static func parseCustomProtocolHeader(_ header: Data) -> (
    version: UInt8, messageType: UInt8, flags: UInt8, sequenceNumber: UInt32
  ) {
    guard header.count >= 8 else { return (0, 0, 0, 0) }

    let version = header[0]
    let messageType = header[1]
    let flags = header[2]
    // Skip reserved byte at index 3

    let sequenceNumber =
      (UInt32(header[4]) << 24) | (UInt32(header[5]) << 16) | (UInt32(header[6]) << 8) | UInt32(header[7])

    return (version, messageType, flags, sequenceNumber)
  }

  private static func analyzeProtocolHeader(_ header: Data) {
    print("    Header structure (8 bytes):")
    for (index, byte) in header.enumerated() {
      let description = getHeaderFieldDescription(index: index)
      print("      Byte \(index): 0x\(String(format: "%02X", byte)) (\(description))")
    }
  }

  private static func getHeaderFieldDescription(index: Int) -> String {
    switch index {
    case 0: return "Version"
    case 1: return "Message Type"
    case 2: return "Flags"
    case 3: return "Reserved"
    case 4: return "Sequence[0]"
    case 5: return "Sequence[1]"
    case 6: return "Sequence[2]"
    case 7: return "Sequence[3]"
    default: return "Unknown"
    }
  }

  // MARK: - Helper Decoding Functions

  private static func decodePercentString(_ percentString: String) throws -> Data {
    var data = Data()
    var index = percentString.startIndex

    while index < percentString.endIndex {
      if percentString[index] == "%" {
        let nextIndex = percentString.index(index, offsetBy: 3)
        guard nextIndex <= percentString.endIndex else {
          throw NSError(
            domain: "PercentDecode",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Invalid percent encoding"]
          )
        }

        let hexStart = percentString.index(after: index)
        let hexString = String(percentString[hexStart..<nextIndex])

        if let byte = UInt8(hexString, radix: 16) {
          data.append(byte)
        }
        else {
          throw NSError(
            domain: "PercentDecode",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Invalid hex in percent encoding"]
          )
        }

        index = nextIndex
      }
      else {
        index = percentString.index(after: index)
      }
    }

    return data
  }
}
