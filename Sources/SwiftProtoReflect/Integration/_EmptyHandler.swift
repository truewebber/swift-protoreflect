//
// _EmptyHandler.swift
// SwiftProtoReflect
//
// Internal Empty handler — scaffolding for future actor migration (OPE-300).
// Public counterpart lives in Public/WellKnownTypeHandlers.swift.
//

import Foundation

// MARK: - _EmptyHandler

internal struct _EmptyHandler {

  // MARK: - _EmptyValue

  internal struct _EmptyValue: Sendable {
    internal static let instance = _EmptyValue()
  }
}
