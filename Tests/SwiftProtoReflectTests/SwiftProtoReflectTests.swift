import XCTest

@testable import SwiftProtoReflect

final class SwiftProtoReflectTests: XCTestCase {
  func testVersionNotEmpty() {
    XCTAssertFalse(SwiftProtoReflect.version.isEmpty, "Version should not be empty")
  }

  func testInitialize() {
    // Check that the method does not throw exceptions
    XCTAssertNoThrow(SwiftProtoReflect.initialize(), "Initialize should not throw")

    // Check with options passed
    let options: [String: Any] = ["debug": true, "logLevel": "verbose"]
    XCTAssertNoThrow(SwiftProtoReflect.initialize(options: options), "Initialize with options should not throw")
  }

  static let allTests = [
    ("testVersionNotEmpty", testVersionNotEmpty),
    ("testInitialize", testInitialize),
  ]
}
