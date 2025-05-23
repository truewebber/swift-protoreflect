import XCTest

@testable import SwiftProtoReflect

final class SwiftProtoReflectTests: XCTestCase {
  func testVersionNotEmpty() {
    XCTAssertFalse(SwiftProtoReflect.version.isEmpty, "Version should not be empty")
  }

  func testInitialize() {
    // Проверка, что метод не вызывает исключений
    XCTAssertNoThrow(SwiftProtoReflect.initialize(), "Initialize should not throw")

    // Проверка с передачей опций
    let options: [String: Any] = ["debug": true, "logLevel": "verbose"]
    XCTAssertNoThrow(SwiftProtoReflect.initialize(options: options), "Initialize with options should not throw")
  }

  static var allTests = [
    ("testVersionNotEmpty", testVersionNotEmpty),
    ("testInitialize", testInitialize),
  ]
}
