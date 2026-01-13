//
// WireFormat.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation

/// Wire type for Protocol Buffers encoding.
public enum WireType: UInt32, Equatable, Sendable {
  case varint = 0
  case fixed64 = 1
  case lengthDelimited = 2
  case startGroup = 3  // Deprecated
  case endGroup = 4  // Deprecated
  case fixed32 = 5
}
