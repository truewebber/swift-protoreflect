/**
 * 🔧 SwiftProtoReflect Example: Binary Data Operations
 *
 * Описание: Продвинутые операции с binary данными Protocol Buffers - bytes поля, hex encoding, data manipulation
 * Ключевые концепции: Data fields, Binary encoding, Hex manipulation, Data integrity, Custom data formats
 * Сложность: 🚀 Продвинутый
 * Время выполнения: < 15 секунд
 *
 * Что изучите:
 * - Работа с bytes полями в динамических сообщениях
 * - Binary data encoding и декодирование (hex, base64)
 * - Data integrity проверки (checksums, hashing)
 * - Кастомные binary протоколы поверх Protocol Buffers
 * - Performance оптимизации для больших binary данных
 * - Data compression и decompression техники
 *
 * Запуск:
 *   swift run BinaryData
 */

// CommonCrypto imports for hashing
import CommonCrypto
import Compression
import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct BinaryDataExample {
  static func main() throws {
    ExampleUtils.printHeader("Advanced Binary Data Operations")

    try step1UbytesFieldsHandling()
    try step2UdataEncodingFormats()
    try step3UdataIntegrityChecks()
    try step4UcustomBinaryProtocols()
    try step5UdataCompressionTechniques()

    ExampleUtils.printSuccess("Binary data операции успешно изучены!")

    ExampleUtils.printNext([
      "Далее попробуйте: swift run Streaming - потоковая обработка данных",
      "Или изучите: compression.swift - продвинутые техники сжатия",
      "Сравните: json-conversion.swift - human-readable форматы",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1UbytesFieldsHandling() throws {
    ExampleUtils.printStep(1, "Работа с bytes полями")

    // Создаем сообщение с bytes полями
    var (binaryMessage, _) = try createBinaryMessage()

    // Различные типы binary данных
    let textData = "Hello, Binary World! 🌍".data(using: .utf8)!
    let imageHeader = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])  // PNG header
    let cryptoKey = generateRandomData(length: 32)  // 256-bit key
    let configData = try createConfigData()

    // Заполняем binary поля
    try binaryMessage.set("Binary Demo", forField: "name")
    try binaryMessage.set(textData, forField: "payload")
    try binaryMessage.set(imageHeader, forField: "file_header")
    try binaryMessage.set(cryptoKey, forField: "encryption_key")
    try binaryMessage.set(configData, forField: "config_blob")

    print("  📦 Создано сообщение с binary данными:")
    binaryMessage.prettyPrint()

    // Анализ binary данных
    print("  🔍 Анализ binary полей:")
    print("    📄 Text data: \(textData.count) bytes (\(ExampleUtils.formatDataPreview(textData)))")
    print("    🖼  Image header: \(imageHeader.count) bytes (\(ExampleUtils.formatDataPreview(imageHeader)))")
    print("    🔐 Crypto key: \(cryptoKey.count) bytes (\(ExampleUtils.formatDataPreview(cryptoKey)))")
    print("    ⚙️  Config blob: \(configData.count) bytes (\(ExampleUtils.formatDataPreview(configData)))")

    // Сериализация и анализ
    let serializer = BinarySerializer()
    let binaryData = try serializer.serialize(binaryMessage)

    print("  📊 Serialization результаты:")
    print("    Total size: \(ExampleUtils.formatDataSize(binaryData.count))")
    print(
      "    Overhead: \(String(format: "%.1f%%", calculateOverhead(original: textData.count + imageHeader.count + cryptoKey.count + configData.count, serialized: binaryData.count)))"
    )

    // Проверка десериализации
    let deserializer = BinaryDeserializer()
    let restoredMessage = try deserializer.deserialize(binaryData, using: binaryMessage.descriptor)

    // Проверка integrity binary данных
    try verifyBinaryDataIntegrity(original: binaryMessage, restored: restoredMessage)
  }

  private static func step2UdataEncodingFormats() throws {
    ExampleUtils.printStep(2, "Data encoding форматы")

    let originalData = "Binary encoding demonstration with special chars: ñáéíóú 🚀💻🔥".data(using: .utf8)!

    print("  📄 Original data: \(originalData.count) bytes")
    print("    Raw: \(String(data: originalData, encoding: .utf8) ?? "Invalid UTF-8")")

    // Различные encoding форматы
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

    print("  🔄 Encoding форматы:")
    for (format, encoded) in encodingFormats {
      let preview = encoded.count > 80 ? String(encoded.prefix(77)) + "..." : encoded
      print("    \(format): \(preview)")
      print(
        "      Size: \(encoded.count) chars (\(String(format: "%.1fx", Double(encoded.count) / Double(originalData.count))) expansion)"
      )
    }

    // Тестирование round-trip encoding
    print("  🔄 Round-trip encoding тесты:")

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

    // Создаем сообщение с encoded данными
    var (encodedMessage, _) = try createEncodedMessage()
    try encodedMessage.set("Encoding Demo", forField: "title")
    try encodedMessage.set(hexEncoded, forField: "hex_data")
    try encodedMessage.set(base64Encoded, forField: "base64_data")
    try encodedMessage.set(String(originalData.count), forField: "original_size")

    print("  📋 Encoded message:")
    encodedMessage.prettyPrint()
  }

  private static func step3UdataIntegrityChecks() throws {
    ExampleUtils.printStep(3, "Data integrity проверки")

    let testData = generateRandomData(length: 1024)  // 1KB test data

    print("  🔒 Data integrity демонстрация:")
    print("    Test data: \(ExampleUtils.formatDataSize(testData.count))")

    // Различные checksum алгоритмы
    let checksums = [
      ("Simple Sum", calculateSimpleChecksum(testData)),
      ("CRC-32", String(calculateCRC32(testData), radix: 16).uppercased()),
      ("MD5", calculateMD5(testData)),
      ("SHA-256", calculateSHA256(testData)),
    ]

    print("  🔍 Checksum результаты:")
    for (algorithm, checksum) in checksums {
      print("    \(algorithm): \(checksum)")
    }

    // Создаем сообщение с integrity данными
    var (integrityMessage, _) = try createIntegrityMessage()
    try integrityMessage.set("Integrity Test", forField: "name")
    try integrityMessage.set(testData, forField: "data")
    try integrityMessage.set(checksums[2].1, forField: "md5_hash")  // MD5
    try integrityMessage.set(checksums[3].1, forField: "sha256_hash")  // SHA-256
    try integrityMessage.set(Int64(testData.count), forField: "data_size")

    // Сериализация
    let serializer = BinarySerializer()
    let serializedData = try serializer.serialize(integrityMessage)

    print("  📦 Integrity message: \(ExampleUtils.formatDataSize(serializedData.count))")

    // Симуляция data corruption
    print("  🧪 Data corruption simulation:")

    var corruptedData = testData
    corruptedData[512] = corruptedData[512] &+ 1  // Flip one bit

    let originalMD5 = calculateMD5(testData)
    let corruptedMD5 = calculateMD5(corruptedData)

    print("    Original MD5:  \(originalMD5)")
    print("    Corrupted MD5: \(corruptedMD5)")
    print("    Integrity: \(originalMD5 == corruptedMD5 ? "❌ CORRUPTED" : "✅ DETECTED")")

    // Проверка восстановленных данных
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

  private static func step4UcustomBinaryProtocols() throws {
    ExampleUtils.printStep(4, "Кастомные binary протоколы")

    print("  🔧 Построение custom protocol поверх Protocol Buffers...")

    // Создаем custom protocol header
    let protocolHeader = createCustomProtocolHeader(
      version: 1,
      messageType: 0x42,
      flags: 0x01,
      sequenceNumber: 12345
    )

    // Payload data
    let payloadData = "Custom protocol payload with binary data".data(using: .utf8)!

    // Создаем сообщение для custom protocol
    var (protocolMessage, _) = try createProtocolMessage()
    try protocolMessage.set("CustomProtocol", forField: "protocol_name")
    try protocolMessage.set(protocolHeader, forField: "header")
    try protocolMessage.set(payloadData, forField: "payload")
    try protocolMessage.set(Int32(payloadData.count), forField: "payload_size")

    print("  📊 Custom protocol структура:")
    print("    Header: \(protocolHeader.count) bytes (\(ExampleUtils.formatDataPreview(protocolHeader)))")
    print("    Payload: \(payloadData.count) bytes")
    print("    Total: \(protocolHeader.count + payloadData.count) bytes")

    // Анализ протокольной структуры
    analyzeProtocolHeader(protocolHeader)

    // Сериализация custom protocol
    let serializer = BinarySerializer()
    let protocolData = try serializer.serialize(protocolMessage)

    print("  📦 Serialized protocol: \(ExampleUtils.formatDataSize(protocolData.count))")

    // Демонстрация protocol parsing
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

  private static func step5UdataCompressionTechniques() throws {
    ExampleUtils.printStep(5, "Data compression техники")

    // Создаем большой dataset для компрессии
    let largeText = """
      This is a large text data for compression demonstration. 
      We repeat this text multiple times to simulate real-world scenarios.
      Compression algorithms work better with repetitive patterns and redundant data.
      Protocol Buffers can benefit significantly from compression, especially for large datasets.
      """.replacingOccurrences(of: "\n", with: " ")

    let repeatedText = String(repeating: largeText + " ", count: 50)  // ~25KB
    let originalData = repeatedText.data(using: .utf8)!

    print("  📊 Compression analysis:")
    print("    Original size: \(ExampleUtils.formatDataSize(originalData.count))")

    // Различные compression algorithms
    let compressionTests = [
      ("LZFSE", try compressData(originalData, algorithm: COMPRESSION_LZFSE)),
      ("LZ4", try compressData(originalData, algorithm: COMPRESSION_LZ4)),
      ("ZLIB", try compressData(originalData, algorithm: COMPRESSION_ZLIB)),
    ]

    var bestCompression: (String, Data) = ("None", originalData)

    for (algorithm, compressedData) in compressionTests {
      let ratio = Double(compressedData.count) / Double(originalData.count)
      let savings = (1.0 - ratio) * 100

      print(
        "    \(algorithm): \(ExampleUtils.formatDataSize(compressedData.count)) (\(String(format: "%.1f%%", savings)) saved)"
      )

      if compressedData.count < bestCompression.1.count {
        bestCompression = (algorithm, compressedData)
      }
    }

    print("    Best: \(bestCompression.0) compression")

    // Создаем сообщение с compressed data
    var (compressedMessage, _) = try createCompressedMessage()
    try compressedMessage.set("Compression Demo", forField: "title")
    try compressedMessage.set(bestCompression.1, forField: "compressed_data")
    try compressedMessage.set(bestCompression.0, forField: "compression_algorithm")
    try compressedMessage.set(Int64(originalData.count), forField: "original_size")
    try compressedMessage.set(Int64(bestCompression.1.count), forField: "compressed_size")

    // Test decompression
    print("  🔄 Decompression test:")

    let algorithm: compression_algorithm =
      bestCompression.0 == "LZFSE" ? COMPRESSION_LZFSE : bestCompression.0 == "LZ4" ? COMPRESSION_LZ4 : COMPRESSION_ZLIB

    do {
      let decompressedData = try decompressData(
        bestCompression.1,
        algorithm: algorithm,
        originalSize: originalData.count
      )
      let integrity = originalData == decompressedData

      print("    Decompression: \(integrity ? "✅ SUCCESS" : "❌ FAILED")")
      print("    Size match: \(decompressedData.count) bytes (expected: \(originalData.count))")

      if let decompressedText = String(data: decompressedData, encoding: .utf8) {
        print("    Text preview: \(String(decompressedText.prefix(100)))...")
      }
      else {
        print("    Text preview: Unable to decode as UTF-8")
      }

      // Additional integrity checks
      if !integrity {
        print("    🔍 Integrity analysis:")
        print("      Original size: \(originalData.count) bytes")
        print("      Decompressed size: \(decompressedData.count) bytes")

        if decompressedData.count == originalData.count {
          // Same size but different content - check where they differ
          var differences = 0
          for i in 0..<min(originalData.count, decompressedData.count) where originalData[i] != decompressedData[i] {
            differences += 1
            if differences <= 5 {  // Show first 5 differences
              print("      Diff at byte \(i): \(originalData[i]) → \(decompressedData[i])")
            }
          }
          print("      Total differences: \(differences) bytes")
        }
        else {
          print("      Size mismatch - truncated or corrupted data")
        }
      }

    }
    catch {
      print("    Decompression: ❌ ERROR - \(error.localizedDescription)")
    }

    // Protocol Buffers + Compression benchmark
    print("  📈 Protocol Buffers + Compression benchmark:")

    let serializer = BinarySerializer()
    let serializedData = try serializer.serialize(compressedMessage)

    let protobufCompressed = try compressData(serializedData, algorithm: COMPRESSION_LZFSE)
    let totalSavings = (1.0 - Double(protobufCompressed.count) / Double(serializedData.count)) * 100

    print("    Protobuf size: \(ExampleUtils.formatDataSize(serializedData.count))")
    print("    Compressed: \(ExampleUtils.formatDataSize(protobufCompressed.count))")
    print("    Additional savings: \(String(format: "%.1f%%", totalSavings))")
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
    print("  🔍 Binary data integrity проверка:")

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
    // Using CommonCrypto for MD5 (for demonstration purposes only)
    // Note: MD5 is deprecated but used here for educational comparison
    let hash = data.withUnsafeBytes { bytes in
      var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
      CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
      return digest
    }
    return hash.map { String(format: "%02x", $0) }.joined()
  }

  private static func calculateSHA256(_ data: Data) -> String {
    // Using CommonCrypto for SHA256
    let hash = data.withUnsafeBytes { bytes in
      var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
      CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
      return digest
    }
    return hash.map { String(format: "%02x", $0) }.joined()
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
    print("    Header структура (8 bytes):")
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

  // Compression functions
  private static func compressData(_ data: Data, algorithm: compression_algorithm) throws -> Data {
    return try data.withUnsafeBytes { bytes in
      let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
      defer { buffer.deallocate() }

      let compressedSize = compression_encode_buffer(
        buffer,
        data.count,
        bytes.bindMemory(to: UInt8.self).baseAddress!,
        data.count,
        nil,
        algorithm
      )

      guard compressedSize > 0 else {
        throw NSError(domain: "Compression", code: 1, userInfo: [NSLocalizedDescriptionKey: "Compression failed"])
      }

      return Data(bytes: buffer, count: compressedSize)
    }
  }

  private static func decompressData(_ data: Data, algorithm: compression_algorithm, originalSize: Int) throws -> Data {
    return try data.withUnsafeBytes { bytes in
      // Use original size + some buffer for safety
      let bufferSize = max(originalSize * 2, data.count * 8)  // Generous buffer
      let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
      defer { buffer.deallocate() }

      let decompressedSize = compression_decode_buffer(
        buffer,
        bufferSize,
        bytes.bindMemory(to: UInt8.self).baseAddress!,
        data.count,
        nil,
        algorithm
      )

      guard decompressedSize > 0 else {
        throw NSError(
          domain: "Decompression",
          code: 1,
          userInfo: [
            NSLocalizedDescriptionKey: "Decompression failed",
            "CompressedSize": data.count,
            "BufferSize": bufferSize,
            "Algorithm": String(describing: algorithm),
          ]
        )
      }

      return Data(bytes: buffer, count: decompressedSize)
    }
  }

  // Legacy method for backward compatibility
  private static func decompressData(_ data: Data, algorithm: compression_algorithm) throws -> Data {
    return try decompressData(data, algorithm: algorithm, originalSize: data.count * 4)
  }
}
