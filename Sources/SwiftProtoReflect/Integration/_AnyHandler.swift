//
// _AnyHandler.swift
// SwiftProtoReflect
//
// Internal Any handler — scaffolding for future actor migration (OPE-300).
// Public counterpart lives in Public/WellKnownTypeHandlers.swift.
//

import Foundation

// MARK: - _AnyHandler

internal struct _AnyHandler {

  // MARK: - _AnyValue

  internal struct _AnyValue {
    internal let typeUrl: String
    internal let value: Data
  }
}
