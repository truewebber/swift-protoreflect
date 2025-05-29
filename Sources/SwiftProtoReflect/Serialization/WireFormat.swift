//
// WireFormat.swift
// SwiftProtoReflect
//
// Создан: 2025-05-25
//

import Foundation

/// Wire type для Protocol Buffers encoding.
public enum WireType: UInt32, Equatable {
  case varint = 0
  case fixed64 = 1
  case lengthDelimited = 2
  case startGroup = 3  // Устаревшее
  case endGroup = 4  // Устаревшее
  case fixed32 = 5
}
