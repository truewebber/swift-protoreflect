//
// _TimestampHandler.swift
// SwiftProtoReflect
//
// Internal Timestamp handler — scaffolding for future actor migration (OPE-300).
// Public counterpart lives in Public/WellKnownTypeHandlers.swift.
//

import Foundation

// MARK: - _TimestampHandler

internal struct _TimestampHandler {

  // MARK: - _TimestampValue

  internal struct _TimestampValue {
    internal let seconds: Int64
    internal let nanos: Int32
  }
}
