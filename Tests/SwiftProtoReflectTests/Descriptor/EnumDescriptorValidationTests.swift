//
// EnumDescriptorValidationTests.swift
// SwiftProtoReflectTests
//

import XCTest

@testable import SwiftProtoReflect

final class EnumDescriptorValidationTests: XCTestCase {

  // MARK: - validateProto3 Tests

  func test_validate_hasZeroValue_noErrors() {
    var e = EnumDescriptor(name: "Status", fullName: "test.Status")
    e.addValue(.init(name: "UNKNOWN", number: 0))
    e.addValue(.init(name: "ACTIVE", number: 1))

    let errors = e.validateProto3()
    XCTAssertTrue(errors.isEmpty, "Expected no errors, got: \(errors)")
  }

  func test_validate_missingZeroValue_returnsError() {
    var e = EnumDescriptor(name: "Status", fullName: "test.Status")
    e.addValue(.init(name: "ACTIVE", number: 1))
    e.addValue(.init(name: "INACTIVE", number: 2))

    let errors = e.validateProto3()
    XCTAssertFalse(errors.isEmpty)
    XCTAssertTrue(errors.first?.contains("0") == true, "Error should mention missing zero value")
  }

  func test_validate_onlyZeroValue_valid() {
    var e = EnumDescriptor(name: "Status", fullName: "test.Status")
    e.addValue(.init(name: "UNKNOWN", number: 0))

    let errors = e.validateProto3()
    XCTAssertTrue(errors.isEmpty)
  }

  func test_validate_zeroNotFirst_butExists_valid() {
    var e = EnumDescriptor(name: "Status", fullName: "test.Status")
    e.addValue(.init(name: "ACTIVE", number: 1))
    e.addValue(.init(name: "UNKNOWN", number: 0))

    let errors = e.validateProto3()
    XCTAssertTrue(errors.isEmpty)
  }

  func test_validate_negativeValues_withZero_valid() {
    var e = EnumDescriptor(name: "Status", fullName: "test.Status")
    e.addValue(.init(name: "NEG", number: -1))
    e.addValue(.init(name: "UNKNOWN", number: 0))
    e.addValue(.init(name: "POS", number: 1))

    let errors = e.validateProto3()
    XCTAssertTrue(errors.isEmpty)
  }

  func test_validate_negativeValues_withoutZero_error() {
    var e = EnumDescriptor(name: "Status", fullName: "test.Status")
    e.addValue(.init(name: "NEG", number: -1))
    e.addValue(.init(name: "POS", number: 1))

    let errors = e.validateProto3()
    XCTAssertFalse(errors.isEmpty)
  }

  func test_validate_emptyEnum_error() {
    let e = EnumDescriptor(name: "Empty", fullName: "test.Empty")

    let errors = e.validateProto3()
    XCTAssertFalse(errors.isEmpty)
  }

  func test_validate_duplicateNumbers_noExtraError() {
    var e = EnumDescriptor(name: "Status", fullName: "test.Status")
    e.addValue(.init(name: "A", number: 0))
    e.addValue(.init(name: "B", number: 0))

    let errors = e.validateProto3()
    XCTAssertTrue(errors.isEmpty, "Zero value exists (via alias), should be valid")
  }

  func test_validate_largeEnum_withZero_valid() {
    var e = EnumDescriptor(name: "Big", fullName: "test.Big")
    for i in 0..<100 {
      e.addValue(.init(name: "V\(i)", number: i))
    }

    let errors = e.validateProto3()
    XCTAssertTrue(errors.isEmpty)
  }

  func test_validate_largeEnum_withoutZero_error() {
    var e = EnumDescriptor(name: "Big", fullName: "test.Big")
    for i in 1...100 {
      e.addValue(.init(name: "V\(i)", number: i))
    }

    let errors = e.validateProto3()
    XCTAssertFalse(errors.isEmpty)
  }

  func test_validate_maxInt32Value_withZero_valid() {
    var e = EnumDescriptor(name: "Extreme", fullName: "test.Extreme")
    e.addValue(.init(name: "UNKNOWN", number: 0))
    e.addValue(.init(name: "MAX", number: Int(Int32.max)))

    let errors = e.validateProto3()
    XCTAssertTrue(errors.isEmpty)
  }

  func test_validate_minInt32Value_withoutZero_error() {
    var e = EnumDescriptor(name: "Extreme", fullName: "test.Extreme")
    e.addValue(.init(name: "MIN", number: Int(Int32.min)))

    let errors = e.validateProto3()
    XCTAssertFalse(errors.isEmpty)
  }
}
