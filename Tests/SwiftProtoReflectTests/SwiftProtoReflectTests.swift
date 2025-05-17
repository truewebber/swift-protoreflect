import XCTest
@testable import SwiftProtoReflect

final class SwiftProtoReflectTests: XCTestCase {
  func testVersionNotEmpty() {
    XCTAssertFalse(SwiftProtoReflect.version.isEmpty, "Version should not be empty")
  }
  
  static var allTests = [
    ("testVersionNotEmpty", testVersionNotEmpty),
  ]
}
