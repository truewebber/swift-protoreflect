import XCTest
@testable import SwiftProtoReflect

class ProtoServiceDescriptorTests: XCTestCase {

    // Positive Test: Retrieve method descriptor by name
    func testGetMethodByName() {
        let method = ProtoMethodDescriptor(name: "TestMethod", inputType: createTestMessageDescriptor(), outputType: createTestMessageDescriptor())
        let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [method])
        let retrievedMethod = serviceDescriptor.method(named: "TestMethod")
        XCTAssertEqual(retrievedMethod?.name, "TestMethod")
    }

    // Negative Test: Retrieve non-existent method descriptor by name
    func testGetNonExistentMethod() {
        let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [])
        let method = serviceDescriptor.method(named: "NonExistentMethod")
        XCTAssertNil(method)
    }

    // Positive Test: Service descriptor validity
    func testValidServiceDescriptor() {
        let method = ProtoMethodDescriptor(name: "TestMethod", inputType: createTestMessageDescriptor(), outputType: createTestMessageDescriptor())
        let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [method])
        XCTAssertTrue(serviceDescriptor.isValid())
    }

    // Negative Test: Invalid service descriptor
    func testInvalidServiceDescriptor() {
        let serviceDescriptor = ProtoServiceDescriptor(name: "", methods: [])
        XCTAssertFalse(serviceDescriptor.isValid())
    }

    private func createTestMessageDescriptor() -> ProtoMessageDescriptor {
        return ProtoMessageDescriptor(fullName: "TestMessage", fields: [], enums: [], nestedMessages: [])
    }
}
