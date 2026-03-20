//
// OneofDescriptorTests.swift
// SwiftProtoReflectTests
//
// Created: 2026-03-20
//

import XCTest

@testable import SwiftProtoReflect

final class OneofDescriptorTests: XCTestCase {

  // MARK: - OPE-221 (T-OD-01…09)

  func test_oneofDescriptor_whenCreatedWithNameAndIndex_hasEmptyOptions_TOD01() {
    let descriptor = OneofDescriptor(name: "contact", index: 0)
    XCTAssertEqual(descriptor.name, "contact")
    XCTAssertEqual(descriptor.index, 0)
    XCTAssertTrue(descriptor.options.isEmpty)
  }

  func test_oneofDescriptor_whenCreatedWithOptionsDictionary_storesOptions_TOD02() {
    let descriptor = OneofDescriptor(name: "x", index: 0, options: ["key": .bool(true)])
    XCTAssertEqual(descriptor.options["key"], .bool(true))
  }

  func test_oneofDescriptor_whenNameAndIndexMatch_areEqual_TOD03() {
    XCTAssertEqual(
      OneofDescriptor(name: "contact", index: 0),
      OneofDescriptor(name: "contact", index: 0)
    )
  }

  func test_oneofDescriptor_whenOptionsDifferButNameIndexMatch_areEqual_TOD04() {
    let a = OneofDescriptor(name: "x", index: 0, options: ["k": .int(1)])
    let b = OneofDescriptor(name: "x", index: 0, options: [:])
    XCTAssertEqual(a, b)
  }

  func test_oneofDescriptor_whenNamesDiffer_areNotEqual_TOD05() {
    XCTAssertNotEqual(
      OneofDescriptor(name: "contact", index: 0),
      OneofDescriptor(name: "payment", index: 0)
    )
  }

  func test_oneofDescriptor_whenIndicesDiffer_areNotEqual_TOD06() {
    XCTAssertNotEqual(
      OneofDescriptor(name: "contact", index: 0),
      OneofDescriptor(name: "contact", index: 1)
    )
  }

  func test_oneofDescriptor_whenNameIsEmpty_storesEmptyString_TOD07() {
    let descriptor = OneofDescriptor(name: "", index: 0)
    XCTAssertEqual(descriptor.name, "")
  }

  func test_oneofDescriptor_whenNameIsVeryLong_preservesFullLength_TOD08() {
    let long = String(repeating: "z", count: 10_000)
    let descriptor = OneofDescriptor(name: long, index: 0)
    XCTAssertEqual(descriptor.name.count, 10_000)
    XCTAssertEqual(descriptor.name, long)
  }

  func test_oneofDescriptor_conformsToSendable_TOD09() {
    let descriptor = OneofDescriptor(name: "contact", index: 0)
    let _: any Sendable = descriptor
  }

  func testInitialization() {
    let descriptor = OneofDescriptor(
      name: "contact",
      index: 0,
      options: ["deprecated": .bool(true)]
    )

    XCTAssertEqual(descriptor.name, "contact")
    XCTAssertEqual(descriptor.index, 0)
    XCTAssertEqual(descriptor.options.count, 1)
    XCTAssertEqual(descriptor.options["deprecated"], .bool(true))
  }

  func testDefaultOptions() {
    let descriptor = OneofDescriptor(name: "payload", index: 1)

    XCTAssertEqual(descriptor.name, "payload")
    XCTAssertEqual(descriptor.index, 1)
    XCTAssertTrue(descriptor.options.isEmpty)
  }

  func testEquality() {
    let lhs = OneofDescriptor(name: "contact", index: 0)
    let rhs = OneofDescriptor(name: "contact", index: 0, options: ["deprecated": .bool(true)])

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
