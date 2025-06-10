//
// EnumDescriptor.swift
// SwiftProtoReflect
//
// Created: 2025-05-22
//

import Foundation
import SwiftProtobuf

/// EnumDescriptor.
///
/// Protocol Buffers enum descriptor that describes
/// enum values, their names, numeric values and options.
public struct EnumDescriptor: Equatable {
  // MARK: - Types

  /// Enum value with its name and options.
  public struct EnumValue: Equatable {
    /// Enum value name (e.g., "UNKNOWN").
    public let name: String

    /// Numeric value of the enum element.
    public let number: Int

    /// Enum value options.
    public let options: [String: Any]

    /// Creates a new enum value.
    ///
    /// - Parameters:
    ///   - name: Enum value name.
    ///   - number: Numeric value.
    ///   - options: Enum value options.
    public init(name: String, number: Int, options: [String: Any] = [:]) {
      self.name = name
      self.number = number
      self.options = options
    }

    // MARK: - Equatable

    public static func == (lhs: EnumValue, rhs: EnumValue) -> Bool {
      guard lhs.name == rhs.name && lhs.number == rhs.number else {
        return false
      }

      // Compare options: check keys and values
      let lhsKeys = Set(lhs.options.keys)
      let rhsKeys = Set(rhs.options.keys)

      guard lhsKeys == rhsKeys else {
        return false
      }

      // Check value matching for all keys
      for key in lhsKeys {
        let lhsValue = lhs.options[key]
        let rhsValue = rhs.options[key]

        // Check known value types
        if let lhsBool = lhsValue as? Bool, let rhsBool = rhsValue as? Bool {
          if lhsBool != rhsBool {
            return false
          }
        }
        else if let lhsInt = lhsValue as? Int, let rhsInt = rhsValue as? Int {
          if lhsInt != rhsInt {
            return false
          }
        }
        else if let lhsString = lhsValue as? String, let rhsString = rhsValue as? String {
          if lhsString != rhsString {
            return false
          }
        }
        else {
          // For other types, compare string representations
          if String(describing: lhsValue) != String(describing: rhsValue) {
            return false
          }
        }
      }

      return true
    }
  }

  // MARK: - Properties

  /// Enum name (e.g., "Status").
  public let name: String

  /// Full enum name including package (e.g., "example.Status").
  public let fullName: String

  /// Path to parent file (for reference resolution).
  public var fileDescriptorPath: String?

  /// Full name of parent message (if this is a nested enum).
  public var parentMessageFullName: String?

  /// List of enum values by name.
  public private(set) var valuesByName: [String: EnumValue] = [:]

  /// List of enum values by numeric value.
  public private(set) var valuesByNumber: [Int: EnumValue] = [:]

  /// Enum options.
  public let options: [String: Any]

  // MARK: - Initialization

  /// Creates a new EnumDescriptor instance.
  ///
  /// - Parameters:
  ///   - name: Enum name.
  ///   - fullName: Full enum name.
  ///   - options: Enum options.
  public init(
    name: String,
    fullName: String,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.options = options
  }

  /// Creates a new EnumDescriptor instance with a base name.
  ///
  /// Full name will be generated automatically based on parent file or message.
  ///
  /// - Parameters:
  ///   - name: Enum name.
  ///   - parent: Parent file or message.
  ///   - options: Enum options.
  public init(
    name: String,
    parent: Any? = nil,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.options = options

    if let parentMessage = parent as? MessageDescriptor {
      self.fullName = "\(parentMessage.fullName).\(name)"
      self.parentMessageFullName = parentMessage.fullName
      self.fileDescriptorPath = parentMessage.fileDescriptorPath
    }
    else if let fileDescriptor = parent as? FileDescriptor {
      self.fullName = fileDescriptor.getFullName(for: name)
      self.fileDescriptorPath = fileDescriptor.name
    }
    else {
      self.fullName = name
    }
  }

  // MARK: - Value Methods

  /// Adds an enum value.
  ///
  /// - Parameter value: Enum value to add.
  /// - Returns: Updated EnumDescriptor.
  @discardableResult
  public mutating func addValue(_ value: EnumValue) -> Self {
    valuesByName[value.name] = value
    valuesByNumber[value.number] = value
    return self
  }

  /// Checks if the enum contains the specified value by name.
  ///
  /// - Parameter name: Value name.
  /// - Returns: true if the value exists.
  public func hasValue(named name: String) -> Bool {
    return valuesByName[name] != nil
  }

  /// Checks if the enum contains the specified value by number.
  ///
  /// - Parameter number: Numeric value.
  /// - Returns: true if the value exists.
  public func hasValue(number: Int) -> Bool {
    return valuesByNumber[number] != nil
  }

  /// Gets an enum value by name.
  ///
  /// - Parameter name: Value name.
  /// - Returns: Enum value if it exists.
  public func value(named name: String) -> EnumValue? {
    return valuesByName[name]
  }

  /// Gets an enum value by numeric value.
  ///
  /// - Parameter number: Numeric value.
  /// - Returns: Enum value if it exists.
  public func value(number: Int) -> EnumValue? {
    return valuesByNumber[number]
  }

  /// Gets a list of all enum values ordered by numeric value.
  ///
  /// - Returns: Ordered list of enum values.
  public func allValues() -> [EnumValue] {
    return valuesByNumber.sorted { $0.key < $1.key }.map { $0.value }
  }

  // MARK: - Equatable

  public static func == (lhs: EnumDescriptor, rhs: EnumDescriptor) -> Bool {
    // Compare main properties
    guard
      lhs.name == rhs.name && lhs.fullName == rhs.fullName && lhs.fileDescriptorPath == rhs.fileDescriptorPath
        && lhs.parentMessageFullName == rhs.parentMessageFullName
    else {
      return false
    }

    // Compare enum values
    let lhsValuesByName = lhs.valuesByName
    let rhsValuesByName = rhs.valuesByName

    guard lhsValuesByName.count == rhsValuesByName.count else {
      return false
    }

    for (name, lhsValue) in lhsValuesByName {
      guard let rhsValue = rhsValuesByName[name], lhsValue == rhsValue else {
        return false
      }
    }

    // Compare options
    let lhsKeys = Set(lhs.options.keys)
    let rhsKeys = Set(rhs.options.keys)

    guard lhsKeys == rhsKeys else {
      return false
    }

    // Check value matching for all keys
    for key in lhsKeys {
      let lhsValue = lhs.options[key]
      let rhsValue = rhs.options[key]

      // Check known value types
      if let lhsBool = lhsValue as? Bool, let rhsBool = rhsValue as? Bool {
        if lhsBool != rhsBool {
          return false
        }
      }
      else if let lhsInt = lhsValue as? Int, let rhsInt = rhsValue as? Int {
        if lhsInt != rhsInt {
          return false
        }
      }
      else if let lhsString = lhsValue as? String, let rhsString = rhsValue as? String {
        if lhsString != rhsString {
          return false
        }
      }
      else {
        // For other types, compare string representations
        if String(describing: lhsValue) != String(describing: rhsValue) {
          return false
        }
      }
    }

    return true
  }
}
