//
// _WireFormat.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation

internal enum _WireType: UInt32, Equatable, Sendable {
  case varint = 0
  case fixed64 = 1
  case lengthDelimited = 2
  case startGroup = 3
  case endGroup = 4
  case fixed32 = 5
}
