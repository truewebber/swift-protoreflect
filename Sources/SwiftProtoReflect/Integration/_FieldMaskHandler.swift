//
// _FieldMaskHandler.swift
// SwiftProtoReflect
//
// Internal FieldMask handler — scaffolding for future actor migration (OPE-300).
// Public counterpart lives in Public/WellKnownTypeHandlers.swift.
//

import Foundation

// MARK: - _FieldMaskHandler

internal struct _FieldMaskHandler {

  // MARK: - _FieldMaskValue

  internal struct _FieldMaskValue {
    internal let paths: [String]
  }
}
