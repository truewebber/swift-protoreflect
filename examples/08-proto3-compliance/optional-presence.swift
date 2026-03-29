/**
 * 🔍 SwiftProtoReflect Example: Proto3 Optional Presence Tracking
 *
 * Description: How proto3 optional keyword enables field presence tracking
 * Key concepts: proto3Optional, hasValue, distinguishing unset from zero
 * Complexity: 🔧 Intermediate
 * Execution time: < 5 seconds
 *
 * What you'll learn:
 * - Difference between regular proto3 fields and optional fields
 * - How proto3Optional tracks whether a field was explicitly set
 * - Distinguishing "unset" from "set to zero/empty"
 * - JSON serialization behavior for optional fields
 *
 * Run with:
 *   swift run OptionalPresence
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct OptionalPresenceExample {
  static func main() throws {
    ExampleUtils.printHeader("Proto3 Optional Field Presence")

    try demonstrateRegularVsOptional()
    try demonstratePresenceTracking()
    try demonstrateJsonBehavior()

    ExampleUtils.printSuccess(
      "Proto3 optional presence demo completed!"
    )

    ExampleUtils.printNext([
      "Next: unknown-fields.swift - unknown field preservation",
      "Also: json-canonical.swift - canonical JSON encoding",
      "See: syntax-and-defaults.swift - default values",
    ])
  }

  // MARK: - Regular vs Optional

  private static func demonstrateRegularVsOptional() throws {
    ExampleUtils.printStep(1, "Regular Field vs Optional Field")

    var desc = MessageDescriptor(name: "Config", fullName: "example.Config")
    desc.addField(FieldDescriptor(name: "timeout", number: 1, type: .int32))
    desc.addField(
      FieldDescriptor(name: "max_retries", number: 2, type: .int32, proto3Optional: true)
    )

    let msg = MessageFactory().createMessage(from: desc)

    let timeout = try msg.get(forField: "timeout")
    let maxRetries = try msg.get(forField: "max_retries")

    print("  Regular field 'timeout' (unset):       \(timeout.map { "\($0)" } ?? "nil")")
    print("  Optional field 'max_retries' (unset):   \(maxRetries.map { "\($0)" } ?? "nil")")

    ExampleUtils.printInfo(
      "Both return nil when unset. The difference shows when set to zero."
    )
  }

  // MARK: - Presence Tracking

  private static func demonstratePresenceTracking() throws {
    ExampleUtils.printStep(2, "Distinguishing Unset from Zero")

    var desc = MessageDescriptor(name: "Settings", fullName: "example.Settings")
    desc.addField(
      FieldDescriptor(name: "score", number: 1, type: .int32, proto3Optional: true)
    )
    desc.addField(
      FieldDescriptor(name: "label", number: 2, type: .string, proto3Optional: true)
    )

    let factory = MessageFactory()

    print("\n  --- Unset message ---")
    let unset = factory.createMessage(from: desc)
    print("    score: \(String(describing: try unset.get(forField: "score")))")
    print("    label: \(String(describing: try unset.get(forField: "label")))")
    print("    hasValue(score): \(try unset.hasValue(forField: "score"))")

    print("\n  --- Set to zero/empty ---")
    var zeroSet = factory.createMessage(from: desc)
    try zeroSet.set(Int32(0), forField: "score")
    try zeroSet.set("", forField: "label")
    print("    score: \(String(describing: try zeroSet.get(forField: "score")))")
    print("    label: \(String(describing: try zeroSet.get(forField: "label")))")
    print("    hasValue(score): \(try zeroSet.hasValue(forField: "score"))")

    print("\n  --- Set to non-zero ---")
    var nonZero = factory.createMessage(from: desc)
    try nonZero.set(Int32(42), forField: "score")
    try nonZero.set("hello", forField: "label")
    print("    score: \(String(describing: try nonZero.get(forField: "score")))")
    print("    label: \(String(describing: try nonZero.get(forField: "label")))")

    ExampleUtils.printInfo(
      "proto3 optional lets you distinguish 'field was not set' from 'field was set to zero'"
    )
  }

  // MARK: - JSON Behavior

  private static func demonstrateJsonBehavior() throws {
    ExampleUtils.printStep(3, "JSON Serialization with Optional Fields")

    var desc = MessageDescriptor(name: "Msg", fullName: "example.Msg")
    desc.addField(FieldDescriptor(name: "regular", number: 1, type: .int32))
    desc.addField(
      FieldDescriptor(name: "optional_val", number: 2, type: .int32, proto3Optional: true)
    )

    let factory = MessageFactory()
    let serializer = JSONSerializer(
      options: JSONSerializationOptions(includeDefaultValues: true)
    )

    var msg = factory.createMessage(from: desc)
    try msg.set(Int32(0), forField: "regular")

    let json = try serializer.serializeToJSONObject(msg)
    print("  JSON with includeDefaultValues=true:")
    print("    regular (set to 0):       \(json["regular"] ?? "absent")")
    print("    optional_val (not set):    \(json["optional_val"] ?? "absent")")

    ExampleUtils.printInfo(
      "includeDefaultValues emits zero for regular fields but omits unset optional fields"
    )
  }
}
