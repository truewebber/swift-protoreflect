//
// _WellKnownTypes.swift
// SwiftProtoReflect
//
// Internal WKT foundation types.
// Public counterparts live in Public/WellKnownTypes.swift.
//

import Foundation

// MARK: - _WellKnownTypeNames

internal struct _WellKnownTypeNames {
  internal static let timestamp = WellKnownTypeNames.timestamp
  internal static let duration = WellKnownTypeNames.duration
  internal static let empty = WellKnownTypeNames.empty
  internal static let fieldMask = WellKnownTypeNames.fieldMask
  internal static let structType = WellKnownTypeNames.structType
  internal static let value = WellKnownTypeNames.value
  internal static let any = WellKnownTypeNames.any
  internal static let listValue = WellKnownTypeNames.listValue
  internal static let nullValue = WellKnownTypeNames.nullValue
}

// MARK: - _WellKnownSupportPhase

internal enum _WellKnownSupportPhase: Int, CaseIterable, Sendable {
  case critical = 1
  case important = 2
  case advanced = 3
}

// MARK: - _WellKnownTypesRegistryStorage

/// Plain value-type storage for `WellKnownTypesRegistry`.
///
/// All mutations are serialised by actor isolation in `WellKnownTypesRegistry`.
internal struct _WellKnownTypesRegistryStorage {
  var handlers: [String: WellKnownTypeHandler.Type]

  internal init(handlers: [String: WellKnownTypeHandler.Type] = [:]) {
    self.handlers = handlers
  }
}
