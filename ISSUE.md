# Bug: `DescriptorBridge` passes `parent: nil` for nested messages and enums, producing wrong `fullName`

## Summary

`DescriptorBridge.fromProtobufDescriptor` converts nested `Google_Protobuf_DescriptorProto`
objects into `MessageDescriptor` instances by calling itself recursively with `parent: nil`.
Because `MessageDescriptor.init(name:parent:)` sets `fullName = name` when `parent` is `nil`,
every nested type ends up with a **bare, unqualified** `fullName` instead of the correct
fully-qualified path.

The same issue applies to nested enums: `fromProtobufEnumDescriptor` is called without a
parent for enums nested inside a message.

This single defect has two separate downstream failures, described below.

---

## Root cause

**File:** `Sources/SwiftProtoReflect/Bridge/DescriptorBridge.swift`

```swift
// Line ~95-103
for nestedProto in protobufDescriptor.nestedType {
    let nestedMessage = try fromProtobufDescriptor(nestedProto, parent: nil)  // ← BUG: should be parent: messageDescriptor
    messageDescriptor.addNestedMessage(nestedMessage)
}

for enumProto in protobufDescriptor.enumType {
    let nestedEnum = try fromProtobufEnumDescriptor(enumProto)               // ← BUG: should be parent: messageDescriptor
    messageDescriptor.addNestedEnum(nestedEnum)
}
```

`fromProtobufDescriptor` signature only accepts `parent: FileDescriptor?`, so it cannot
currently receive a `MessageDescriptor` as parent. The fix requires widening the parameter
to `Any?` (matching `MessageDescriptor.init(name:parent:)`).

**Effect on `MessageDescriptor.init(name:parent:)`:**

```swift
// When parent == nil:
self.fullName = name      // e.g. "SearchFilters"   ← wrong
// When parent == MessageDescriptor with fullName "pkg.GetGroupedAdsRequest":
self.fullName = "pkg.GetGroupedAdsRequest.SearchFilters"   ← correct
```

---

## Failure 1 — `RegistryError.duplicateType` when registering a message with nested types

### When it happens

Any call to `TypeRegistry.registerMessage(_:)` or `DescriptorPool.addFileDescriptor(_:)` for
a message that has at least one nested message type.

### Why

`DescriptorPool.addMessageDescriptorRecursively` stores each descriptor keyed by its
`fullName`, then recurses into `nestedMessages`. Because nested messages carry a bare name
(e.g. `"Cursor"`), the pool also stores them independently under that short key.

When consumer code iterates `pool.allMessageTypeNames()` and registers each descriptor into
a `TypeRegistry`, the following sequence occurs:

1. Pool returns `["Cursor", "pkg.GetGroupedAdsResponse", …]` (both the nested type AND the
   parent are listed as separate entries).
2. Iteration reaches `"Cursor"` first → `registry.registerMessage(cursorDescriptor)` succeeds.
3. Iteration reaches `"pkg.GetGroupedAdsResponse"` →
   `registry.registerMessage(responseDescriptor)` calls
   `registerMessageRecursively` on the parent, which recurses into `nestedMessages` and
   tries to register `Cursor` again → **throws `RegistryError.duplicateType("Cursor")`**.

### Minimal repro

```swift
import SwiftProtoReflect

let proto = """
syntax = "proto3";
package pkg;
message GetGroupedAdsResponse {
  repeated Item items = 1;
  Cursor cursor = 2;
  message Cursor { string next_page_token = 1; }
  message Item   { string id = 1; }
}
"""

// Parse via SwiftProtoParser → DescriptorBridge → DescriptorPool
let pool = DescriptorPool(includeBuiltinDescriptors: false)
// … (add file descriptor) …

let registry = TypeRegistry()
for typeName in pool.allMessageTypeNames() {
    let descriptor = pool.findMessageDescriptor(named: typeName)!
    try registry.registerMessage(descriptor)   // 💥 duplicateType("Cursor")
}
```

### Error message

```
RegistryError: Type 'Cursor' is already registered
```

---

## Failure 2 — `JSONDeserializationError.nestedMessageDescriptorNotFound` (error code 16)

### When it happens

Calling `JSONDeserializer.deserializeFromJSONObject(_:using:)` on a message that contains a
field whose type is a **nested message** defined inside the same or a parent message.

### Why

`JSONDeserializer.convertJSONToMessage` resolves nested message descriptors from the
`TypeRegistry` using the value of `field.typeName`, which is the fully-qualified name that the
proto parser stores (e.g. `"pkg.GetGroupedAdsRequest.SearchFilters"`).

Because of Failure 1 above, consumers must either suppress `duplicateType` or work around
the ordering issue. In either case, the `TypeRegistry` ends up storing the nested descriptor
under its short `fullName` — `"SearchFilters"` — not the qualified name. The lookup fails:

```swift
// In JSONDeserializer:
guard let nestedDescriptor = registry.findMessage(named: typeName) else {
    throw JSONDeserializationError.nestedMessageDescriptorNotFound(
        fieldName: fieldName, typeName: typeName)   // 💥 typeName = "pkg.Req.SearchFilters"
}
// registry only has "SearchFilters" → not found
```

### Minimal repro

```swift
import SwiftProtoReflect

// Proto with a nested message field
let proto = """
syntax = "proto3";
package pkg;
message GetGroupedAdsRequest {
  message SearchFilters { string title = 1; }
  SearchFilters search_filters = 1;
  int32 limit = 2;
}
"""
// … parse, build pool & registry as above (suppressing duplicateType) …

let registry = TypeRegistry()
// registerMessage stores "SearchFilters", not "pkg.GetGroupedAdsRequest.SearchFilters"

let json: [String: Any] = [
    "search_filters": ["title": "test"],
    "limit": 10
]
let deserializer = JSONDeserializer(
    options: JSONDeserializationOptions(typeRegistry: registry))
let descriptor = pool.findMessageDescriptor(named: "pkg.GetGroupedAdsRequest")!

try deserializer.deserializeFromJSONObject(json, using: descriptor)
// 💥 nestedMessageDescriptorNotFound(fieldName: "search_filters",
//    typeName: "pkg.GetGroupedAdsRequest.SearchFilters")
```

### Error message

```
SwiftProtoReflect.JSONDeserializationError error 16.
// error 16 = nestedMessageDescriptorNotFound
```

---

## Affected components

| Component | Affected API | Symptom |
|---|---|---|
| `DescriptorBridge` | `fromProtobufDescriptor(_:parent:)` | Produces wrong `fullName` on every nested `MessageDescriptor` |
| `DescriptorBridge` | `fromProtobufEnumDescriptor(_:parent:)` (nested call) | Produces wrong `fullName` on every nested `EnumDescriptor` |
| `DescriptorPool` | `addFileDescriptor(_:)` / `allMessageTypeNames()` | Returns nested types under short keys; ordering-dependent `duplicateSymbol` |
| `TypeRegistry` | `registerMessage(_:)` / `findMessage(named:)` | Stores and looks up nested types under short names |
| `JSONDeserializer` | `deserializeFromJSONObject(_:using:)` | Fails for any message field whose type is a nested message |

---

## Proposed fix

### 1. Change `fromProtobufDescriptor` to accept `Any?` as parent

```swift
// DescriptorBridge.swift

public func fromProtobufDescriptor(
    _ protobufDescriptor: Google_Protobuf_DescriptorProto,
    parent: Any? = nil                          // was: FileDescriptor? = nil
) throws -> MessageDescriptor {
    var messageDescriptor = MessageDescriptor(
        name: protobufDescriptor.name,
        parent: parent
    )

    for nestedProto in protobufDescriptor.nestedType {
        // Pass messageDescriptor as parent so fullName is computed correctly
        let nestedMessage = try fromProtobufDescriptor(nestedProto, parent: messageDescriptor)
        messageDescriptor.addNestedMessage(nestedMessage)
    }

    for enumProto in protobufDescriptor.enumType {
        // Pass messageDescriptor as parent so fullName is computed correctly
        let nestedEnum = try fromProtobufEnumDescriptor(enumProto, parent: messageDescriptor)
        messageDescriptor.addNestedEnum(nestedEnum)
    }
    // … rest unchanged …
}
```

### 2. Verify call sites still compile

`fromProtobufFileDescriptor` calls `fromProtobufDescriptor(messageProto, parent: fileDescriptor)`.
`fileDescriptor` is a `FileDescriptor`, which is also `Any?` — no change needed there.

### 3. Expected result after fix

```swift
// Before fix
nestedDescriptor.fullName  // → "SearchFilters"

// After fix
nestedDescriptor.fullName  // → "pkg.GetGroupedAdsRequest.SearchFilters"
```

Both `DescriptorPool` and `TypeRegistry` will store and retrieve nested types under their
fully-qualified names, matching the `field.typeName` used by `JSONDeserializer`.

---

## Workaround (consumer side, until fixed in the library)

Until this is fixed in SwiftProtoReflect, consumers building a `TypeRegistry` for
`JSONDeserializer` should traverse `bridgedFileDescriptors` top-down and **reconstruct**
each `MessageDescriptor` with the correct qualified `fullName` before registering:

```swift
func rebuildMessageDescriptor(_ source: MessageDescriptor, qualifiedName: String) -> MessageDescriptor {
    var rebuilt = MessageDescriptor(name: source.name, fullName: qualifiedName, syntax: source.syntax)
    rebuilt.fileDescriptorPath = source.fileDescriptorPath
    for field in source.allFields() { rebuilt.addField(field) }
    for oneof in source.oneofDecls  { rebuilt.addOneofDecl(oneof) }
    for (_, e) in source.nestedEnums { rebuilt.addNestedEnum(e) }
    for (childName, child) in source.nestedMessages {
        let childQualified = "\(qualifiedName).\(childName)"
        rebuilt.addNestedMessage(rebuildMessageDescriptor(child, qualifiedName: childQualified))
    }
    return rebuilt
}

// Usage:
let registry = TypeRegistry()
for (_, fileDesc) in bridgedFileDescriptors where isInScope(fileDesc) {
    for (_, msg) in fileDesc.messages {
        try? registry.registerMessage(rebuildMessageDescriptor(msg, qualifiedName: msg.fullName))
    }
}
```

This workaround correctly handles arbitrarily deep nesting and does not require `try?`
suppression for `duplicateType`.

---

## Version

SwiftProtoReflect `5.2.0` (tag used in `TrueRPC-mini`).

Confirmed reproducible with the proto structure from
`semrush.services.eyeon.v0.starlink.Starlink` — any message that defines nested message
types as request/response filters, pagination cursors, or sub-objects triggers both failures.
