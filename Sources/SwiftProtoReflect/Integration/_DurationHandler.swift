//
// _DurationHandler.swift
// SwiftProtoReflect
//
// Internal Duration handler — scaffolding for future actor migration (OPE-300).
// Public counterpart lives in Public/WellKnownTypeHandlers.swift.
//

import Foundation

// MARK: - _DurationHandler

internal struct _DurationHandler {

  // MARK: - _DurationValue

  internal struct _DurationValue {
    internal let seconds: Int64
    internal let nanos: Int32
  }
}
