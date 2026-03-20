import XCTest

@testable import SwiftProtoReflect

final class DescriptorOptionTests: XCTestCase {

  func testBoolCase() {
    let option = DescriptorOption.bool(true)
    if case .bool(let value) = option {
      XCTAssertTrue(value)
    }
    else {
      XCTFail("Expected .bool case")
    }
  }

  func testIntCase() {
    let option = DescriptorOption.int(42)
    if case .int(let value) = option {
      XCTAssertEqual(value, 42)
    }
    else {
      XCTFail("Expected .int case")
    }
  }

  func testStringCase() {
    let option = DescriptorOption.string("value")
    if case .string(let value) = option {
      XCTAssertEqual(value, "value")
    }
    else {
      XCTFail("Expected .string case")
    }
  }

  func testFloatCase() {
    let option = DescriptorOption.float(1.5)
    if case .float(let value) = option {
      XCTAssertEqual(value, 1.5, accuracy: 0.0001)
    }
    else {
      XCTFail("Expected .float case")
    }
  }

  func testEquality() {
    XCTAssertEqual(DescriptorOption.bool(true), DescriptorOption.bool(true))
    XCTAssertEqual(DescriptorOption.int(42), DescriptorOption.int(42))
    XCTAssertEqual(DescriptorOption.string("value"), DescriptorOption.string("value"))
    XCTAssertEqual(DescriptorOption.float(1.5), DescriptorOption.float(1.5))
  }

  func testInequality() {
    XCTAssertNotEqual(DescriptorOption.bool(true), DescriptorOption.bool(false))
    XCTAssertNotEqual(DescriptorOption.int(1), DescriptorOption.int(2))
    XCTAssertNotEqual(DescriptorOption.string("a"), DescriptorOption.string("b"))
    XCTAssertNotEqual(DescriptorOption.float(1.0), DescriptorOption.float(2.0))
    XCTAssertNotEqual(DescriptorOption.bool(true), DescriptorOption.int(1))
    XCTAssertNotEqual(DescriptorOption.string("1"), DescriptorOption.int(1))
  }
}
