import XCTest

@testable import SwiftProtoReflect

extension XCTestCase {
  // Вспомогательные функции для безопасного вызова методов сериализации/десериализации

  /// Безопасная сериализация сообщения с обработкой исключений.
  func safeMarshal(message: ProtoMessage, file: StaticString = #filePath, line: UInt = #line) -> Data? {
    do {
      return try ProtoWireFormat.marshal(message: message)
    }
    catch {
      XCTFail("Failed to marshal message: \(error)", file: file, line: line)
      return nil
    }
  }

  /// Безопасная десериализация данных с обработкой исключений.
  func safeUnmarshal(
    data: Data,
    messageDescriptor: ProtoMessageDescriptor,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> ProtoMessage? {
    do {
      return try ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
    }
    catch {
      XCTFail("Failed to unmarshal message: \(error)", file: file, line: line)
      return nil
    }
  }

  /// Безопасная полная проверка сериализации и десериализации.
  func safeRoundTrip(message: ProtoMessage, file: StaticString = #filePath, line: UInt = #line) -> ProtoMessage? {
    guard let data = safeMarshal(message: message, file: file, line: line) else {
      return nil
    }

    return safeUnmarshal(data: data, messageDescriptor: message.descriptor(), file: file, line: line)
  }
}
