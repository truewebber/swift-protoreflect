/**
 * DurationHandlerTests.swift
 * SwiftProtoReflectTests
 *
 * Tests for DurationHandler
 */

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class DurationHandlerTests: XCTestCase {

  // MARK: - DurationValue Tests

  func testDurationValueInitialization() {
    // Valid initialization
    XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 1_234_567_890, nanos: 123_456_789))
    XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 0, nanos: 0))
    XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: -1, nanos: -999_999_999))
    XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 5, nanos: 0))
    XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 0, nanos: 123_456_789))

    // Valid initialization with same signs
    XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 1, nanos: 500_000_000))
    XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: -1, nanos: -500_000_000))

    // Invalid nanoseconds (out of range)
    XCTAssertThrowsError(try DurationHandler.DurationValue(seconds: 0, nanos: 1_000_000_000)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, let reason) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Duration")
      XCTAssertTrue(reason.contains("nanos must be in range"))
    }

    XCTAssertThrowsError(try DurationHandler.DurationValue(seconds: 0, nanos: -1_000_000_000)) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }

    // Invalid sign combination
    XCTAssertThrowsError(try DurationHandler.DurationValue(seconds: 1, nanos: -500_000_000)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, let reason) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Duration")
      XCTAssertTrue(reason.contains("same sign"))
    }

    XCTAssertThrowsError(try DurationHandler.DurationValue(seconds: -1, nanos: 500_000_000)) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  func testDurationValueFromTimeInterval() {
    // Positive interval
    let positiveInterval: TimeInterval = 123.456789
    let positiveDuration = DurationHandler.DurationValue(from: positiveInterval)
    XCTAssertEqual(positiveDuration.seconds, 123)
    // Check nanoseconds with some tolerance
    XCTAssertTrue(abs(positiveDuration.nanos - 456_789_000) < 1000)

    // Negative interval
    let negativeInterval: TimeInterval = -123.456789
    let negativeDuration = DurationHandler.DurationValue(from: negativeInterval)
    XCTAssertEqual(negativeDuration.seconds, -123)
    XCTAssertTrue(abs(negativeDuration.nanos + 456_789_000) < 1000)

    // Zero interval
    let zeroDuration = DurationHandler.DurationValue(from: 0.0)
    XCTAssertEqual(zeroDuration.seconds, 0)
    XCTAssertEqual(zeroDuration.nanos, 0)

    // Only fractional part
    let fractionalDuration = DurationHandler.DurationValue(from: 0.123)
    XCTAssertEqual(fractionalDuration.seconds, 0)
    XCTAssertTrue(abs(fractionalDuration.nanos - 123_000_000) < 1000)
  }

  func testDurationValueToTimeInterval() {
    do {
      // Positive duration
      let positiveDuration = try DurationHandler.DurationValue(seconds: 123, nanos: 456_789_000)
      let positiveInterval = positiveDuration.toTimeInterval()
      XCTAssertEqual(positiveInterval, 123.456789, accuracy: 0.001)

      // Negative duration
      let negativeDuration = try DurationHandler.DurationValue(seconds: -123, nanos: -456_789_000)
      let negativeInterval = negativeDuration.toTimeInterval()
      XCTAssertEqual(negativeInterval, -123.456789, accuracy: 0.001)

      // Zero duration
      let zeroDuration = try DurationHandler.DurationValue(seconds: 0, nanos: 0)
      XCTAssertEqual(zeroDuration.toTimeInterval(), 0.0)

      // Only nanoseconds
      let nanosDuration = try DurationHandler.DurationValue(seconds: 0, nanos: 500_000_000)
      XCTAssertEqual(nanosDuration.toTimeInterval(), 0.5, accuracy: 0.001)
    }
    catch {
      XCTFail("Failed to create duration: \(error)")
    }
  }

  func testDurationValueRoundTrip() {
    let testIntervals: [TimeInterval] = [
      0.0,
      0.123456,
      123.456789,
      -123.456789,
      -0.123456,
      1.0,
      -1.0,
      3600.0,  // 1 hour
      -3600.0,
    ]

    for originalInterval in testIntervals {
      let duration = DurationHandler.DurationValue(from: originalInterval)
      let convertedInterval = duration.toTimeInterval()

      // Should be close within microseconds
      XCTAssertEqual(
        originalInterval,
        convertedInterval,
        accuracy: 0.001,
        "Round trip failed for interval: \(originalInterval)"
      )
    }
  }

  func testDurationValueZero() {
    let zero = DurationHandler.DurationValue.zero()
    XCTAssertEqual(zero.seconds, 0)
    XCTAssertEqual(zero.nanos, 0)
    XCTAssertEqual(zero.toTimeInterval(), 0.0)
  }

  func testDurationValueAbs() {
    do {
      // Positive duration stays positive
      let positive = try DurationHandler.DurationValue(seconds: 5, nanos: 123_456_789)
      let positiveAbs = positive.abs()
      XCTAssertEqual(positiveAbs.seconds, 5)
      XCTAssertEqual(positiveAbs.nanos, 123_456_789)

      // Negative duration becomes positive
      let negative = try DurationHandler.DurationValue(seconds: -5, nanos: -123_456_789)
      let negativeAbs = negative.abs()
      XCTAssertEqual(negativeAbs.seconds, 5)
      XCTAssertEqual(negativeAbs.nanos, 123_456_789)

      // Zero stays zero
      let zero = DurationHandler.DurationValue.zero()
      let zeroAbs = zero.abs()
      XCTAssertEqual(zeroAbs.seconds, 0)
      XCTAssertEqual(zeroAbs.nanos, 0)

      // Only negative nanoseconds
      let negativeNanos = try DurationHandler.DurationValue(seconds: 0, nanos: -123_456_789)
      let negativeNanosAbs = negativeNanos.abs()
      XCTAssertEqual(negativeNanosAbs.seconds, 0)
      XCTAssertEqual(negativeNanosAbs.nanos, 123_456_789)
    }
    catch {
      XCTFail("Failed to create duration: \(error)")
    }
  }

  func testDurationValueNegated() {
    do {
      // Positive becomes negative
      let positive = try DurationHandler.DurationValue(seconds: 5, nanos: 123_456_789)
      let negated = positive.negated()
      XCTAssertEqual(negated.seconds, -5)
      XCTAssertEqual(negated.nanos, -123_456_789)

      // Negative becomes positive
      let negative = try DurationHandler.DurationValue(seconds: -5, nanos: -123_456_789)
      let negatedNegative = negative.negated()
      XCTAssertEqual(negatedNegative.seconds, 5)
      XCTAssertEqual(negatedNegative.nanos, 123_456_789)

      // Double negation returns to original
      let doubleNegated = negated.negated()
      XCTAssertEqual(doubleNegated.seconds, positive.seconds)
      XCTAssertEqual(doubleNegated.nanos, positive.nanos)
    }
    catch {
      XCTFail("Failed to create duration: \(error)")
    }
  }

  func testDurationValueDescription() {
    do {
      // Zero duration
      let zero = DurationHandler.DurationValue.zero()
      XCTAssertEqual(zero.description, "0s")

      // Positive duration in seconds
      let positive = try DurationHandler.DurationValue(seconds: 5, nanos: 123_456_789)
      XCTAssertTrue(positive.description.contains("5.123s"))

      // Negative duration
      let negative = try DurationHandler.DurationValue(seconds: -5, nanos: -123_456_789)
      XCTAssertTrue(negative.description.contains("-5.123s"))

      // Milliseconds
      let millis = try DurationHandler.DurationValue(seconds: 0, nanos: 123_456_789)
      XCTAssertTrue(millis.description.contains("ms") || millis.description.contains("s"))

      // Very small values (nanoseconds)
      let nanos = try DurationHandler.DurationValue(seconds: 0, nanos: 123)
      XCTAssertTrue(nanos.description.contains("ns") || nanos.description.contains("ms"))
    }
    catch {
      XCTFail("Failed to create duration: \(error)")
    }
  }

  func testDurationValueEquality() {
    do {
      let duration1 = try DurationHandler.DurationValue(seconds: 5, nanos: 123_456_789)
      let duration2 = try DurationHandler.DurationValue(seconds: 5, nanos: 123_456_789)
      let duration3 = try DurationHandler.DurationValue(seconds: 5, nanos: 123_456_790)
      let duration4 = try DurationHandler.DurationValue(seconds: 6, nanos: 123_456_789)

      XCTAssertEqual(duration1, duration2)
      XCTAssertNotEqual(duration1, duration3)
      XCTAssertNotEqual(duration1, duration4)
    }
    catch {
      XCTFail("Failed to create durations: \(error)")
    }
  }

  // MARK: - Handler Implementation Tests

  func testHandlerBasicProperties() {
    XCTAssertEqual(DurationHandler.handledTypeName, "google.protobuf.Duration")
    XCTAssertEqual(DurationHandler.supportPhase, .critical)
  }

  func testCreateSpecializedFromMessage() throws {
    // Create duration message
    let durationMessage = try createDurationMessage(seconds: 5, nanos: 123_456_789)

    // Convert to specialized type
    let specialized = try DurationHandler.createSpecialized(from: durationMessage)

    guard let duration = specialized as? DurationHandler.DurationValue else {
      XCTFail("Expected DurationValue")
      return
    }

    XCTAssertEqual(duration.seconds, 5)
    XCTAssertEqual(duration.nanos, 123_456_789)
  }

  func testCreateSpecializedFromMessageWithMissingFields() throws {
    // Create message with only seconds
    let durationMessage = try createDurationMessage(seconds: 5, nanos: nil)

    let specialized = try DurationHandler.createSpecialized(from: durationMessage)

    guard let duration = specialized as? DurationHandler.DurationValue else {
      XCTFail("Expected DurationValue")
      return
    }

    XCTAssertEqual(duration.seconds, 5)
    XCTAssertEqual(duration.nanos, 0)  // Should have default value
  }

  func testCreateSpecializedFromMessageWithNegativeValues() throws {
    // Create negative message
    let negativeDurationMessage = try createDurationMessage(seconds: -5, nanos: -123_456_789)

    let specialized = try DurationHandler.createSpecialized(from: negativeDurationMessage)

    guard let duration = specialized as? DurationHandler.DurationValue else {
      XCTFail("Expected DurationValue")
      return
    }

    XCTAssertEqual(duration.seconds, -5)
    XCTAssertEqual(duration.nanos, -123_456_789)
  }

  func testCreateSpecializedFromInvalidMessage() throws {
    // Create message of wrong type
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotDuration", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try DurationHandler.createSpecialized(from: wrongMessage)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, _) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Duration")
    }
  }

  func testCreateDynamicFromSpecialized() throws {
    let duration = try DurationHandler.DurationValue(seconds: 5, nanos: 123_456_789)

    let dynamicMessage = try DurationHandler.createDynamic(from: duration)

    XCTAssertEqual(dynamicMessage.descriptor.fullName, "google.protobuf.Duration")

    let seconds = try dynamicMessage.get(forField: "seconds") as! Int64
    let nanos = try dynamicMessage.get(forField: "nanos") as! Int32

    XCTAssertEqual(seconds, 5)
    XCTAssertEqual(nanos, 123_456_789)
  }

  func testCreateDynamicFromNegativeSpecialized() throws {
    let negativeDuration = try DurationHandler.DurationValue(seconds: -5, nanos: -123_456_789)

    let dynamicMessage = try DurationHandler.createDynamic(from: negativeDuration)

    let seconds = try dynamicMessage.get(forField: "seconds") as! Int64
    let nanos = try dynamicMessage.get(forField: "nanos") as! Int32

    XCTAssertEqual(seconds, -5)
    XCTAssertEqual(nanos, -123_456_789)
  }

  func testCreateDynamicFromInvalidSpecialized() throws {
    let wrongSpecialized = "not a duration"

    XCTAssertThrowsError(try DurationHandler.createDynamic(from: wrongSpecialized)) { error in
      guard case WellKnownTypeError.conversionFailed(let from, let to, _) = error else {
        XCTFail("Expected conversionFailed error")
        return
      }
      XCTAssertEqual(from, "String")
      XCTAssertEqual(to, "DynamicMessage")
    }
  }

  func testValidate() throws {
    // Valid values
    let validDuration = try DurationHandler.DurationValue(seconds: 5, nanos: 123_456_789)
    XCTAssertTrue(DurationHandler.validate(validDuration))

    let negativeDuration = try DurationHandler.DurationValue(seconds: -5, nanos: -123_456_789)
    XCTAssertTrue(DurationHandler.validate(negativeDuration))

    let zeroDuration = DurationHandler.DurationValue.zero()
    XCTAssertTrue(DurationHandler.validate(zeroDuration))

    // Invalid values
    XCTAssertFalse(DurationHandler.validate("not a duration"))
    XCTAssertFalse(DurationHandler.validate(123))
    XCTAssertFalse(DurationHandler.validate(Date()))
    XCTAssertFalse(DurationHandler.validate(5.0))
  }

  func testRoundTripConversion() throws {
    let testCases = [
      try DurationHandler.DurationValue(seconds: 5, nanos: 123_456_789),
      try DurationHandler.DurationValue(seconds: -5, nanos: -123_456_789),
      try DurationHandler.DurationValue(seconds: 0, nanos: 123_456_789),
      try DurationHandler.DurationValue(seconds: 0, nanos: -123_456_789),
      DurationHandler.DurationValue.zero(),
    ]

    for originalDuration in testCases {
      // Convert to dynamic message and back
      let dynamicMessage = try DurationHandler.createDynamic(from: originalDuration)
      let convertedSpecialized = try DurationHandler.createSpecialized(from: dynamicMessage)

      guard let convertedDuration = convertedSpecialized as? DurationHandler.DurationValue else {
        XCTFail("Expected DurationValue")
        return
      }

      XCTAssertEqual(
        originalDuration,
        convertedDuration,
        "Round trip failed for: \(originalDuration)"
      )
    }
  }

  // MARK: - Convenience Extensions Tests

  func testTimeIntervalExtensions() {
    let testIntervals: [TimeInterval] = [0.0, 123.456, -123.456, 0.001, -0.001]

    for originalInterval in testIntervals {
      let durationValue = originalInterval.toDurationValue()
      let convertedInterval = TimeInterval(from: durationValue)

      XCTAssertEqual(
        originalInterval,
        convertedInterval,
        accuracy: 0.001,
        "Extension round trip failed for: \(originalInterval)"
      )
    }
  }

  func testDynamicMessageDurationExtension() throws {
    let testIntervals: [TimeInterval] = [0.0, 123.456, -123.456, 3600.0, -3600.0]

    for interval in testIntervals {
      let durationMessage = try DynamicMessage.durationMessage(from: interval)
      XCTAssertEqual(durationMessage.descriptor.fullName, "google.protobuf.Duration")

      let convertedInterval = try durationMessage.toTimeInterval()
      XCTAssertEqual(
        interval,
        convertedInterval,
        accuracy: 0.001,
        "Dynamic message extension failed for: \(interval)"
      )
    }
  }

  func testDynamicMessageToTimeIntervalWithInvalidMessage() throws {
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotDuration", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try wrongMessage.toTimeInterval()) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  // MARK: - Edge Cases Tests

  func testExtremeDurations() throws {
    // Very large positive duration
    let largeDuration = try DurationHandler.DurationValue(seconds: Int64.max / 2, nanos: 999_999_999)
    XCTAssertTrue(largeDuration.toTimeInterval() > 0)

    // Very large negative duration
    let largeNegativeDuration = try DurationHandler.DurationValue(seconds: Int64.min / 2, nanos: -999_999_999)
    XCTAssertTrue(largeNegativeDuration.toTimeInterval() < 0)

    // Maximum nanoseconds
    let maxNanos = try DurationHandler.DurationValue(seconds: 0, nanos: 999_999_999)
    XCTAssertEqual(maxNanos.nanos, 999_999_999)

    // Minimum nanoseconds
    let minNanos = try DurationHandler.DurationValue(seconds: 0, nanos: -999_999_999)
    XCTAssertEqual(minNanos.nanos, -999_999_999)
  }

  func testBoundaryNanos() throws {
    // Test boundary nanoseconds values
    let boundaries: [Int32] = [
      -999_999_999, -500_000_000, -1, 0, 1, 500_000_000, 999_999_999,
    ]

    for nanos in boundaries {
      XCTAssertNoThrow(
        try DurationHandler.DurationValue(seconds: 0, nanos: nanos),
        "Should accept boundary nanos value: \(nanos)"
      )
    }

    // Test out-of-bounds values
    let outOfBounds: [Int32] = [-1_000_000_000, 1_000_000_000]

    for nanos in outOfBounds {
      XCTAssertThrowsError(
        try DurationHandler.DurationValue(seconds: 0, nanos: nanos),
        "Should reject out-of-bounds nanos value: \(nanos)"
      )
    }
  }

  func testMixedSignValidation() throws {
    // Valid combinations (same signs or one zero)
    let validCombinations: [(Int64, Int32)] = [
      (0, 0),
      (1, 0),
      (0, 1),
      (-1, 0),
      (0, -1),
      (5, 123_456_789),
      (-5, -123_456_789),
    ]

    for (seconds, nanos) in validCombinations {
      XCTAssertNoThrow(
        try DurationHandler.DurationValue(seconds: seconds, nanos: nanos),
        "Should accept valid combination: seconds=\(seconds), nanos=\(nanos)"
      )
    }

    // Invalid combinations (different signs)
    let invalidCombinations: [(Int64, Int32)] = [
      (1, -123_456_789),
      (-1, 123_456_789),
      (5, -500_000_000),
      (-5, 500_000_000),
    ]

    for (seconds, nanos) in invalidCombinations {
      XCTAssertThrowsError(
        try DurationHandler.DurationValue(seconds: seconds, nanos: nanos),
        "Should reject invalid combination: seconds=\(seconds), nanos=\(nanos)"
      )
    }
  }

  // MARK: - Performance Tests

  func testConversionPerformance() {
    let interval: TimeInterval = 123.456789

    measure {
      for _ in 0..<1000 {
        let duration = DurationHandler.DurationValue(from: interval)
        _ = duration.toTimeInterval()
      }
    }
  }

  func testHandlerPerformance() throws {
    let durationMessage = try createDurationMessage(seconds: 5, nanos: 123_456_789)

    measure {
      for _ in 0..<100 {
        do {
          let specialized = try DurationHandler.createSpecialized(from: durationMessage)
          _ = try DurationHandler.createDynamic(from: specialized)
        }
        catch {
          XCTFail("Performance test failed: \(error)")
        }
      }
    }
  }

  func testAbsAndNegatedPerformance() throws {
    let duration = try DurationHandler.DurationValue(seconds: -5, nanos: -123_456_789)

    measure {
      for _ in 0..<10000 {
        _ = duration.abs()
        _ = duration.negated()
      }
    }
  }

  // MARK: - Registry Integration Tests

  func testRegistryIntegration() throws {
    let registry = WellKnownTypesRegistry.shared

    // Check that DurationHandler is registered
    let handler = registry.getHandler(for: WellKnownTypeNames.duration)
    XCTAssertNotNil(handler)
    XCTAssertTrue(handler is DurationHandler.Type)

    // Test through registry
    let duration = try DurationHandler.DurationValue(seconds: 5, nanos: 123_456_789)
    let dynamicMessage = try DurationHandler.createDynamic(from: duration)

    let specializedFromRegistry = try registry.createSpecialized(
      from: dynamicMessage,
      typeName: WellKnownTypeNames.duration
    )

    guard let convertedDuration = specializedFromRegistry as? DurationHandler.DurationValue else {
      XCTFail("Expected DurationValue from registry")
      return
    }

    XCTAssertEqual(duration, convertedDuration)
  }

  // MARK: - Helper Methods

  private func createDurationMessage(seconds: Int64, nanos: Int32?) throws -> DynamicMessage {
    // Create descriptor for Duration
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/duration.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "Duration",
      parent: fileDescriptor
    )

    let secondsField = FieldDescriptor(
      name: "seconds",
      number: 1,
      type: .int64
    )
    messageDescriptor.addField(secondsField)

    let nanosField = FieldDescriptor(
      name: "nanos",
      number: 2,
      type: .int32
    )
    messageDescriptor.addField(nanosField)

    fileDescriptor.addMessage(messageDescriptor)

    // Create message
    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    // Set fields
    try message.set(seconds, forField: "seconds")
    if let nanos = nanos {
      try message.set(nanos, forField: "nanos")
    }

    return message
  }
}
