//
// _StructHandler.swift
// SwiftProtoReflect
//
// Internal Struct handler — scaffolding for future actor migration (OPE-300).
// Public counterpart lives in Public/WellKnownTypeHandlers.swift.
//

import Foundation

// MARK: - _StructHandler

internal struct _StructHandler {

  // MARK: - _StructValue

  internal struct _StructValue {
    /// Wrapped public value — avoids logic duplication during the migration phase.
    internal let pub: StructHandler.StructValue

    internal init(_ pub: StructHandler.StructValue) {
      self.pub = pub
    }
  }

  // MARK: - _ValueValue

  internal struct _ValueValue {
    /// Wrapped public value — avoids logic duplication during the migration phase.
    internal let pub: StructHandler.ValueValue

    internal init(_ pub: StructHandler.ValueValue) {
      self.pub = pub
    }
  }
}
