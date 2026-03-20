//
// OneofDescriptorTests.swift
// SwiftProtoReflectTests
//
// Created: 2026-03-20
//

import XCTest

@testable import SwiftProtoReflect

final class OneofDescriptorTests: XCTestCase {

  func testInitialization() {
    let descriptor = OneofDescriptor(
      name: "contact",
      index: 0,
      options: ["deprecated": true]
    )

    XCTAssertEqual(descriptor.name, "contact")
    XCTAssertEqual(descriptor.index, 0)
    XCTAssertEqual(descriptor.options.count, 1)
    XCTAssertEqual(descriptor.options["deprecated"] as? Bool, true)
  }

  func testDefaultOptions() {
    let descriptor = OneofDescriptor(name: "payload", index: 1)

    XCTAssertEqual(descriptor.name, "payload")
    XCTAssertEqual(descriptor.index, 1)
    XCTAssertTrue(descriptor.options.isEmpty)
  }

  func testEquality() {
    let lhs = OneofDescriptor(name: "contact", index: 0)
    let rhs = OneofDescriptor(name: "contact", index: 0, options: ["deprecated": true])

    XCTAssertEqual(lhs, rhs)
  }

  func testInequalityDifferentName() {
    let lhs = OneofDescriptor(name: "contact", index: 0)
    let rhs = OneofDescriptor(name: "payload", index: 0)

    XCTAssertNotEqual(lhs, rhs)
  }

  func testInequalityDifferentIndex() {
    let lhs = OneofDescriptor(name: "contact", index: 0)
    let rhs = OneofDescriptor(name: "contact", index: 1)

    XCTAssertNotEqual(lhs, rhs)
  }
}
