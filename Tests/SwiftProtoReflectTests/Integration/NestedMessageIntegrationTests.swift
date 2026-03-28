//
// NestedMessageIntegrationTests.swift
//
// Integration tests verifying cross-module interaction between
// Serialization (JSONDeserializer/JSONSerializer) and Registry (TypeRegistry)
// for nested message deserialization.
//

import XCTest

@testable import SwiftProtoReflect

final class NestedMessageIntegrationTests: XCTestCase {

  // MARK: - End-to-End: Registry + JSON Serialization Round-trip

  func test_endToEnd_registerFileAndRoundTripNestedMessages() throws {
    var file = FileDescriptor(name: "integration.proto", package: "integration")

    var address = MessageDescriptor(name: "Address", parent: file)
    address.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    address.addField(FieldDescriptor(name: "city", number: 2, type: .string))
    address.addField(FieldDescriptor(name: "zip", number: 3, type: .string))
    file.addMessage(address)

    var person = MessageDescriptor(name: "Person", parent: file)
    person.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    person.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
    person.addField(FieldDescriptor(name: "home", number: 3, type: .message, typeName: "integration.Address"))
    person.addField(FieldDescriptor(name: "work", number: 4, type: .message, typeName: "integration.Address"))
    file.addMessage(person)

    var team = MessageDescriptor(name: "Team", parent: file)
    team.addField(FieldDescriptor(name: "team_name", number: 1, type: .string))
    team.addField(
      FieldDescriptor(
        name: "members",
        number: 2,
        type: .message,
        typeName: "integration.Person",
        isRepeated: true
      )
    )
    file.addMessage(team)

    let registry = TypeRegistry()
    try registry.registerFile(file)

    let serializer = JSONSerializer()
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: registry)
    )

    var homeAddr = DynamicMessage(descriptor: file.messages["Address"]!)
    try homeAddr.set("123 Main St", forField: "street")
    try homeAddr.set("Springfield", forField: "city")
    try homeAddr.set("62701", forField: "zip")

    var workAddr = DynamicMessage(descriptor: file.messages["Address"]!)
    try workAddr.set("456 Oak Ave", forField: "street")
    try workAddr.set("Shelbyville", forField: "city")
    try workAddr.set("62702", forField: "zip")

    var alice = DynamicMessage(descriptor: file.messages["Person"]!)
    try alice.set("Alice", forField: "name")
    try alice.set(Int32(30), forField: "age")
    try alice.set(homeAddr, forField: "home")
    try alice.set(workAddr, forField: "work")

    var bob = DynamicMessage(descriptor: file.messages["Person"]!)
    try bob.set("Bob", forField: "name")
    try bob.set(Int32(25), forField: "age")

    var originalTeam = DynamicMessage(descriptor: file.messages["Team"]!)
    try originalTeam.set("Engineering", forField: "team_name")
    try originalTeam.set([alice, bob] as [Any], forField: "members")

    let jsonData = try serializer.serialize(originalTeam)
    let deserialized = try deserializer.deserialize(jsonData, using: file.messages["Team"]!)

    XCTAssertEqual(originalTeam, deserialized)
  }

  // MARK: - DescriptorPool + JSONDeserializer

  func test_descriptorPoolWithJSONDeserializer_resolvesNestedTypes() throws {
    let pool = DescriptorPool(includeBuiltinDescriptors: false)

    var file = FileDescriptor(name: "pool_test.proto", package: "pool")

    var innerMsg = MessageDescriptor(name: "Inner", parent: file)
    innerMsg.addField(FieldDescriptor(name: "data", number: 1, type: .string))
    file.addMessage(innerMsg)

    var outerMsg = MessageDescriptor(name: "Outer", parent: file)
    outerMsg.addField(FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "pool.Inner"))
    file.addMessage(outerMsg)

    try pool.addFileDescriptor(file)

    let registry = TypeRegistry()
    try registry.registerFile(file)

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: registry)
    )

    let data = """
      {"inner": {"data": "from pool"}}
      """.data(using: .utf8)!

    let outerDescriptor = pool.findMessageDescriptor(named: "pool.Outer")!
    let result = try deserializer.deserialize(data, using: outerDescriptor)

    let inner = try result.get(forField: "inner") as? DynamicMessage
    XCTAssertNotNil(inner)
    XCTAssertEqual(FieldAccessor(inner!).getValue("data", as: String.self), "from pool")
  }

  // MARK: - Map<String, Message> Round-trip Through Registry

  func test_mapWithMessageValues_roundTripThroughRegistry() throws {
    var file = FileDescriptor(name: "map_test.proto", package: "maptest")

    var metric = MessageDescriptor(name: "Metric", parent: file)
    metric.addField(FieldDescriptor(name: "value", number: 1, type: .double))
    metric.addField(FieldDescriptor(name: "unit", number: 2, type: .string))
    file.addMessage(metric)

    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "maptest.Metric")
    let mapEntry = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    var dashboard = MessageDescriptor(name: "Dashboard", parent: file)
    dashboard.addField(
      FieldDescriptor(
        name: "metrics",
        number: 1,
        type: .message,
        typeName: "maptest.Dashboard.MetricsEntry",
        isMap: true,
        mapEntryInfo: mapEntry
      )
    )
    file.addMessage(dashboard)

    let registry = TypeRegistry()
    try registry.registerFile(file)

    let serializer = JSONSerializer()
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: registry)
    )

    var cpuMetric = DynamicMessage(descriptor: file.messages["Metric"]!)
    try cpuMetric.set(75.5, forField: "value")
    try cpuMetric.set("%", forField: "unit")

    var memMetric = DynamicMessage(descriptor: file.messages["Metric"]!)
    try memMetric.set(8192.0, forField: "value")
    try memMetric.set("MB", forField: "unit")

    var original = DynamicMessage(descriptor: file.messages["Dashboard"]!)
    try original.setMapEntry(cpuMetric, forKey: "cpu" as AnyHashable, inField: "metrics")
    try original.setMapEntry(memMetric, forKey: "memory" as AnyHashable, inField: "metrics")

    let jsonData = try serializer.serialize(original)
    let deserialized = try deserializer.deserialize(jsonData, using: file.messages["Dashboard"]!)

    XCTAssertEqual(original, deserialized)
  }
}
