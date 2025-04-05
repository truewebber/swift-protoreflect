import Foundation
import SwiftProtobuf

/// Examples demonstrating the usage of AnyProtoMessage protocol
public class AnyProtoMessageExample {
    
    /// Example of working with both SwiftProtobuf and dynamic messages uniformly
    public static func demonstrateUniformHandling() throws {
        // Create a dynamic message
        let personDescriptor = ProtoMessageDescriptor(
            fullName: "Person",
            fields: [
                ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
                ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false),
                ProtoFieldDescriptor(name: "emails", number: 3, type: .string, isRepeated: true, isMap: false)
            ],
            enums: [],
            nestedMessages: []
        )
        
        let dynamicPerson = DynamicMessage(descriptor: personDescriptor)
        dynamicPerson.setValue("John Doe", forField: 1)
        dynamicPerson.setValue(30, forField: 2)
        dynamicPerson.setRepeatedValues(["john@example.com", "doe@example.com"], forField: 3)
        
        /* COMMENTED - Need to implement Person message
        // Create a SwiftProtobuf message (assuming we have Person.proto generated)
        var swiftPerson = Person.with {
            $0.name = "Jane Doe"
            $0.age = 25
            $0.emails = ["jane@example.com"]
        }
        */
        
        // Function that works with any proto message
        func processMessage(_ message: AnyProtoMessage) throws {
            // Serialize to binary
            let data = try message.serializedData()
            print("Serialized size: \(data.count) bytes")
            
            // Convert to JSON
            let json = try message.jsonString()
            print("JSON representation: \(json)")
            
            // Create a new message with the merged data
            if let dynamicMessage = message as? DynamicMessage {
                let newMessage = DynamicMessage(descriptor: dynamicMessage.descriptor())
                // Use merging for consistency
                _ = try newMessage.merging(serializedData: data)
                print("Successfully created new message with merged data")
            } else {
                // For SwiftProtobuf messages (which are structs), use merging
                _ = try message.merging(serializedData: data)
                print("Successfully created new message with merged data")
            }
        }
        
        // Process both types of messages the same way
        print("Processing dynamic message:")
        try processMessage(dynamicPerson)
        
        /* COMMENTED - Need to implement Person message
        print("\nProcessing SwiftProtobuf message:")
        try processMessage(swiftPerson)
        */
    }
    
    /// Example of message conversion and modification
    public static func demonstrateMessageConversion() throws {
        /* COMMENTED - Need to implement Person message
        // Create a SwiftProtobuf message
        var original = Person.with {
            $0.name = "Alice"
            $0.age = 20
            $0.emails = ["alice@example.com"]
        }
        
        // Convert to binary
        let data = try original.serializedData()
        
        // Create a dynamic message from the same schema
        let personDescriptor = ProtoMessageDescriptor(
            fullName: "Person",
            fields: [
                ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
                ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false),
                ProtoFieldDescriptor(name: "emails", number: 3, type: .string, isRepeated: true, isMap: false)
            ],
            enums: [],
            nestedMessages: []
        )
        
        let dynamic = DynamicMessage(descriptor: personDescriptor)
        
        // Merge the SwiftProtobuf data into dynamic message
        dynamic = try dynamic.merging(serializedData: data)
        
        // Modify the dynamic message
        dynamic.setValue("Alice Smith", forField: 1) // Change name
        dynamic.addRepeatedValue("alice.smith@example.com", forField: 3) // Add email
        
        // Convert back to binary
        let modifiedData = try dynamic.serializedData()
        
        // Create a new SwiftProtobuf message from modified data
        // Use merging instead of merge for structs
        let modified = try Person().merging(serializedData: modifiedData)
        
        print("Original name: \(original.name)")
        print("Modified name: \(modified.name)")
        print("Original emails: \(original.emails)")
        print("Modified emails: \(modified.emails)")
        */
        
        // Simple placeholder example using only dynamic messages
        print("Message conversion example requires implementation of Person message type")
    }
    
    /// Example of generic message processing
    public static func demonstrateGenericProcessing() {
        /// Generic function to extract message metadata
        func extractMetadata<T: AnyProtoMessage>(_ message: T) -> [String: Any] {
            var metadata: [String: Any] = [:]
            
            // Try to get size
            if let data = try? message.serializedData() {
                metadata["size"] = data.count
            }
            
            // Try to get JSON representation
            if let json = try? message.jsonString() {
                metadata["json"] = json
            }
            
            // Add type information
            metadata["type"] = String(describing: type(of: message))
            
            return metadata
        }
        
        // Process different message types
        let dynamicMessage = DynamicMessage(descriptor: ProtoMessageDescriptor(
            fullName: "SimpleMessage",
            fields: [
                ProtoFieldDescriptor(name: "text", number: 1, type: .string, isRepeated: false, isMap: false)
            ],
            enums: [],
            nestedMessages: []
        ))
        dynamicMessage.setValue("Hello World", forField: 1)
        
        /* COMMENTED - Need to implement Person message
        var swiftMessage = Person.with {
            $0.name = "Test Person"
        }
        */
        
        let dynamicMetadata = extractMetadata(dynamicMessage)
        // let swiftMetadata = extractMetadata(swiftMessage)
        
        print("Dynamic message metadata: \(dynamicMetadata)")
        // print("Swift message metadata: \(swiftMetadata)")
    }
}
