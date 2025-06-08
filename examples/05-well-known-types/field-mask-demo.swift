/**
 * 🎯 SwiftProtoReflect Example: FieldMask Demo
 * 
 * Описание: Работа с google.protobuf.FieldMask для partial updates и field filtering
 * Ключевые концепции: FieldMaskHandler, FieldMaskValue, partial updates, field masking
 * Сложность: 🔧 Средний  
 * Время выполнения: < 15 секунд
 * 
 * Что изучите:
 * - Создание и управление масками полей (FieldMask)
 * - Set операции с масками (union, intersection, difference)
 * - Валидация путей полей и path notation
 * - Partial updates с применением масок полей
 * - Advanced field filtering и conditional updates
 * - Real-world сценарии использования FieldMask
 * 
 * Запуск: 
 *   swift run FieldMaskDemo
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct FieldMaskDemo {
    static func main() throws {
        ExampleUtils.printHeader("Google Protobuf FieldMask for Partial Updates")
        
        try demonstrateBasicUsage()
        try demonstrateSetOperations()
        try demonstratePathValidationAndCoverage()
        try demonstratePartialUpdates()
        try demonstrateAdvancedFieldFiltering()
        try demonstrateRealWorldScenarios()
        try demonstratePerformanceAnalysis()
        
        ExampleUtils.printSuccess("FieldMask demo завершена! Вы изучили все аспекты работы с google.protobuf.FieldMask.")
        
        ExampleUtils.printNext([
            "Далее изучите: struct-demo.swift - динамические JSON-like структуры",
            "Сравните: value-demo.swift - универсальные значения", 
            "Продвинутое: any-demo.swift - type erasure с Any"
        ])
    }
    
    // MARK: - Implementation Steps
    
    private static func demonstrateBasicUsage() throws {
        ExampleUtils.printStep(1, "Basic FieldMask Operations")
        
        // Создание масок полей различными способами
        print("  📝 Creating FieldMask instances:")
        
        // Способ 1: Из массива путей
        let basicMask = try FieldMaskHandler.FieldMaskValue(paths: ["name", "email", "age"])
        print("    • From array: \(basicMask)")
        
        // Способ 2: Из одного пути
        let singleMask = try FieldMaskHandler.FieldMaskValue(path: "profile.settings.theme")
        print("    • Single path: \(singleMask)")
        
        // Способ 3: Пустая маска
        let emptyMask = FieldMaskHandler.FieldMaskValue()
        print("    • Empty mask: \(emptyMask)")
        
        // Способ 4: Через convenience метод
        let convenienceMask = try ["user.name", "user.email", "metadata.version"].toFieldMaskValue()
        print("    • Convenience method: \(convenienceMask)")
        
        // Создание динамических сообщений
        print("\n  🏗  Converting to DynamicMessage:")
        let basicMessage = try FieldMaskHandler.createDynamic(from: basicMask)
        let _ = try FieldMaskHandler.createDynamic(from: singleMask)
        
        print("    • Basic mask message type: \(basicMessage.descriptor.name)")
        print("    • Fields count: \(basicMessage.descriptor.fields.count)")
        
        // Извлечение путей из сообщения
        let extractedPaths = try basicMessage.toFieldPaths()
        print("    • Extracted paths: \(extractedPaths)")
        
        // Round-trip тест
        let roundTripMask = try FieldMaskHandler.createSpecialized(from: basicMessage) as! FieldMaskHandler.FieldMaskValue
        let roundTripSuccess = roundTripMask == basicMask
        print("    • Round-trip test: \(roundTripSuccess ? "✅ SUCCESS" : "❌ FAILED")")
        
        // Тестирование contains и covers
        print("\n  🔍 Testing path matching:")
        let testPaths = ["name", "email", "profile", "profile.settings", "profile.settings.theme", "unknown"]
        
        var pathTestResults: [[String: String]] = []
        for path in testPaths {
            let basicContains = basicMask.contains(path)
            let basicCovers = basicMask.covers(path)
            let singleContains = singleMask.contains(path)
            let singleCovers = singleMask.covers(path)
            
            pathTestResults.append([
                "Path": path,
                "Basic Contains": basicContains ? "✅" : "❌",
                "Basic Covers": basicCovers ? "✅" : "❌",
                "Single Contains": singleContains ? "✅" : "❌",
                "Single Covers": singleCovers ? "✅" : "❌"
            ])
        }
        
        ExampleUtils.printDataTable(pathTestResults, title: "Path Matching Results")
    }
    
    private static func demonstrateSetOperations() throws {
        ExampleUtils.printStep(2, "Set Operations with FieldMasks")
        
        // Создаем тестовые маски для демонстрации set операций
        let userMask = try FieldMaskHandler.FieldMaskValue(paths: ["user.name", "user.email", "user.age"])
        let profileMask = try FieldMaskHandler.FieldMaskValue(paths: ["user.email", "profile.avatar", "profile.bio"])
        let metadataMask = try FieldMaskHandler.FieldMaskValue(paths: ["metadata.created", "metadata.updated", "user.name"])
        
        print("  🔄 Original masks:")
        print("    • User mask: \(userMask)")
        print("    • Profile mask: \(profileMask)")  
        print("    • Metadata mask: \(metadataMask)")
        
        // Union operations
        print("\n  ➕ Union operations:")
        let userProfileUnion = userMask.union(profileMask)
        let allFieldsUnion = userProfileUnion.union(metadataMask)
        
        print("    • User ∪ Profile: \(userProfileUnion)")
        print("    • All fields union: \(allFieldsUnion)")
        print("    • Union paths count: \(allFieldsUnion.paths.count)")
        
        // Intersection operations
        print("\n  ⛽ Intersection operations:")
        let userProfileIntersection = userMask.intersection(profileMask)
        let userMetadataIntersection = userMask.intersection(metadataMask)
        let profileMetadataIntersection = profileMask.intersection(metadataMask)
        
        print("    • User ∩ Profile: \(userProfileIntersection)")
        print("    • User ∩ Metadata: \(userMetadataIntersection)")
        print("    • Profile ∩ Metadata: \(profileMetadataIntersection)")
        
        // Adding and removing operations
        print("\n  ➕➖ Add/Remove operations:")
        let expandedUserMask = try userMask.adding("user.phone").adding("user.address")
        let reducedProfileMask = profileMask.removing("profile.bio")
        
        print("    • User + phone + address: \(expandedUserMask)")
        print("    • Profile - bio: \(reducedProfileMask)")
        
        // Comprehensive set operations table
        let setOperations = [
            ("User ∪ Profile", userProfileUnion.paths),
            ("User ∩ Profile", userProfileIntersection.paths),
            ("User ∩ Metadata", userMetadataIntersection.paths),
            ("User + phone + address", expandedUserMask.paths),
            ("Profile - bio", reducedProfileMask.paths),
            ("All fields union", allFieldsUnion.paths)
        ]
        
        var operationResults: [[String: String]] = []
        for (operation, paths) in setOperations {
            operationResults.append([
                "Operation": operation,
                "Paths Count": "\(paths.count)",
                "Sample Paths": paths.prefix(3).joined(separator: ", ") + (paths.count > 3 ? "..." : "")
            ])
        }
        
        ExampleUtils.printDataTable(operationResults, title: "Set Operations Summary")
    }
    
    private static func demonstratePathValidationAndCoverage() throws {
        ExampleUtils.printStep(3, "Path Validation and Coverage Analysis")
        
        // Тестируем различные пути на валидность
        let pathTestCases = [
            // Валидные пути
            ("user.name", true),
            ("profile.settings.theme", true),
            ("metadata.tags.0.name", true),
            ("contact_info.email_address", true),
            ("nested.very.deep.field.value", true),
            
            // Невалидные пути
            ("", false),
            ("user..name", false),
            (".profile", false),
            ("profile.", false),
            ("user name", false),
            ("user-name", false),
            ("user@email", false),
            ("user[0]", false)
        ]
        
        print("  ✅❌ Path validation tests:")
        var validationResults: [[String: String]] = []
        
        for (path, expectedValid) in pathTestCases {
            var actualValid = false
            var errorMessage = ""
            
            do {
                _ = try FieldMaskHandler.FieldMaskValue(path: path)
                actualValid = true
            } catch {
                actualValid = false
                errorMessage = error.localizedDescription
            }
            
            let testPassed = actualValid == expectedValid
            let status = testPassed ? "✅ PASS" : "❌ FAIL"
            
            validationResults.append([
                "Path": path.isEmpty ? "(empty)" : path,
                "Expected": expectedValid ? "Valid" : "Invalid",
                "Actual": actualValid ? "Valid" : "Invalid",
                "Status": status,
                "Error": errorMessage.isEmpty ? "-" : String(errorMessage.prefix(30))
            ])
        }
        
        ExampleUtils.printDataTable(validationResults, title: "Path Validation Results")
        
        // Демонстрируем coverage анализ
        print("\n  🎯 Coverage analysis:")
        let complexMask = try FieldMaskHandler.FieldMaskValue(paths: [
            "user",
            "profile.settings", 
            "metadata.tags.name",
            "contacts.email"
        ])
        
        let coverageTestPaths = [
            "user",              // Exact match
            "user.name",         // Child of user (covered)
            "user.email",        // Child of user (covered)
            "profile",           // Parent of profile.settings (not covered)
            "profile.settings",  // Exact match
            "profile.settings.theme", // Child of profile.settings (covered)
            "metadata",          // Parent of metadata.tags.name (not covered)
            "metadata.tags",     // Parent of metadata.tags.name (not covered)
            "metadata.tags.name", // Exact match
            "metadata.tags.id",  // Sibling of metadata.tags.name (not covered)
            "contacts",          // Parent of contacts.email (not covered)
            "contacts.email",    // Exact match
            "contacts.phone",    // Sibling of contacts.email (not covered)
            "unknown.field"      // Completely unrelated (not covered)
        ]
        
        var coverageResults: [[String: String]] = []
        for testPath in coverageTestPaths {
            let contains = complexMask.contains(testPath)
            let covers = complexMask.covers(testPath)
            
            var explanation = ""
            if contains {
                explanation = "Exact match"
            } else if covers {
                explanation = "Parent path covered"
            } else {
                explanation = "Not covered"
            }
            
            coverageResults.append([
                "Test Path": testPath,
                "Contains": contains ? "✅" : "❌",
                "Covers": covers ? "✅" : "❌",
                "Explanation": explanation
            ])
        }
        
        ExampleUtils.printDataTable(coverageResults, title: "Coverage Analysis")
        
        print("  💡 Coverage rules:")
        print("    • contains(): Exact path match")
        print("    • covers(): Path or any parent path matches")
        print("    • Parent paths cover all child paths")
        print("    • Sibling paths do not cover each other")
    }
    
    private static func demonstratePartialUpdates() throws {
        ExampleUtils.printStep(4, "Partial Updates with FieldMask")
        
        // Создаем исходное "сообщение пользователя" (симулируем через словарь)
        var userData: [String: Any] = [
            "user": [
                "name": "John Doe",
                "email": "john.doe@example.com",
                "age": 30,
                "phone": "+1-555-0123"
            ],
            "profile": [
                "avatar": "avatar1.jpg",
                "bio": "Software Developer",
                "settings": [
                    "theme": "dark",
                    "notifications": true,
                    "language": "en"
                ]
            ],
            "metadata": [
                "created": "2023-01-15T10:30:00Z",
                "updated": "2024-01-20T15:45:00Z",
                "version": 1
            ]
        ]
        
        print("  📋 Original user data:")
        ExampleUtils.printTable(flattenDictionary(userData, prefix: ""), title: "Current State")
        
        // Различные сценарии partial updates
        let updateScenarios: [(String, [String], [String: Any])] = [
            (
                "Basic profile update",
                ["user.name", "user.email"],
                ["user.name": "Jane Smith", "user.email": "jane.smith@example.com"]
            ),
            (
                "Settings configuration", 
                ["profile.settings.theme", "profile.settings.notifications"],
                ["profile.settings.theme": "light", "profile.settings.notifications": false]
            ),
            (
                "Metadata refresh",
                ["metadata.updated", "metadata.version"],
                ["metadata.updated": "2024-01-25T09:00:00Z", "metadata.version": 2]
            ),
            (
                "Complete profile overhaul",
                ["profile"],
                ["profile": [
                    "avatar": "new_avatar.jpg",
                    "bio": "Senior Software Engineer", 
                    "settings": [
                        "theme": "auto",
                        "notifications": false,
                        "language": "fr"
                    ]
                ]]
            )
        ]
        
        for (scenarioName, maskPaths, updates) in updateScenarios {
            print("\n  🔄 Scenario: \(scenarioName)")
            
            // Создаем маску полей
            let updateMask = try FieldMaskHandler.FieldMaskValue(paths: maskPaths)
            print("    • Field mask: \(updateMask)")
            
            // Симулируем применение partial update
            let beforeUpdateData = userData
            applyPartialUpdate(&userData, mask: updateMask, updates: updates)
            
            // Показываем что изменилось
            let changedFields = findChangedFields(before: beforeUpdateData, after: userData, mask: updateMask)
            if !changedFields.isEmpty {
                print("    • Changed fields:")
                for (field, change) in changedFields {
                    print("      - \(field): \(change)")
                }
            }
            
            print("    • Update result: ✅ Applied")
        }
        
        print("\n  📋 Final user data after all updates:")
        ExampleUtils.printTable(flattenDictionary(userData, prefix: ""), title: "Final State")
        
        // Демонстрируем защиту от нежелательных изменений
        print("\n  🛡  Protection demonstration:")
        let restrictiveMask = try FieldMaskHandler.FieldMaskValue(paths: ["user.name"])
        let maliciousUpdates: [String: Any] = [
            "user.name": "Updated Name",
            "user.email": "malicious@hacker.com",  // Should be ignored
            "metadata.version": 999,                // Should be ignored
            "profile.settings.theme": "hacked"      // Should be ignored
        ]
        
        let beforeProtection = userData
        applyPartialUpdate(&userData, mask: restrictiveMask, updates: maliciousUpdates)
        
        let actualChanges = findChangedFields(before: beforeProtection, after: userData, mask: restrictiveMask)
        print("    • Restrictive mask: \(restrictiveMask)")
        print("    • Attempted updates: \(maliciousUpdates.keys.joined(separator: ", "))")
        print("    • Actually changed: \(actualChanges.keys.joined(separator: ", "))")
        print("    • Protection effective: \(actualChanges.count == 1 && actualChanges.keys.first == "user.name" ? "✅ YES" : "❌ NO")")
    }
    
    private static func demonstrateAdvancedFieldFiltering() throws {
        ExampleUtils.printStep(5, "Advanced Field Filtering Techniques")
        
        // Создаем комплексную структуру данных для демонстрации
        let complexData: [String: Any] = [
            "public_info": [
                "name": "TechCorp Inc.",
                "website": "https://techcorp.com",
                "industry": "Technology"
            ],
            "sensitive_info": [
                "revenue": 5000000,
                "employee_count": 150,
                "secret_projects": ["Project X", "Project Y"]
            ],
            "user_preferences": [
                "notifications": [
                    "email": true,
                    "sms": false,
                    "push": true
                ],
                "privacy": [
                    "show_email": false,
                    "show_phone": false,
                    "public_profile": true
                ]
            ],
            "audit_log": [
                "last_login": "2024-01-25T09:00:00Z",
                "login_count": 1247,
                "security_events": []
            ]
        ]
        
        // Различные роли с разными уровнями доступа
        let accessRoles: [(String, [String], String)] = [
            ("Public API", [
                "public_info"
            ], "External API consumers"),
            
            ("User Dashboard", [
                "public_info.name",
                "user_preferences",
                "audit_log.last_login"
            ], "Authenticated users"),
            
            ("Manager View", [
                "public_info",
                "user_preferences",
                "audit_log",
                "sensitive_info.employee_count"
            ], "Management dashboard"),
            
            ("Admin Access", [
                "public_info",
                "sensitive_info",
                "user_preferences",
                "audit_log"
            ], "Full administrative access"),
            
            ("Privacy Compliant", [
                "public_info.name",
                "public_info.industry",
                "user_preferences.notifications"
            ], "GDPR-compliant minimal data")
        ]
        
        print("  🔐 Access control with FieldMask filtering:")
        
        for (roleName, allowedPaths, description) in accessRoles {
            print("\n    🎭 Role: \(roleName)")
            print("       Description: \(description)")
            
            let accessMask = try FieldMaskHandler.FieldMaskValue(paths: allowedPaths)
            let filteredData = filterDataWithMask(complexData, mask: accessMask)
            let filteredFieldsCount = countFields(filteredData)
            let originalFieldsCount = countFields(complexData)
            
            print("       Allowed paths: \(allowedPaths.count)")
            print("       Accessible fields: \(filteredFieldsCount)/\(originalFieldsCount)")
            
            // Показываем примеры доступных данных
            let flatFiltered = flattenDictionary(filteredData, prefix: "")
            if flatFiltered.count <= 5 {
                print("       Sample data: \(Array(flatFiltered.keys).sorted().joined(separator: ", "))")
            } else {
                let sample = Array(flatFiltered.keys).sorted().prefix(3).joined(separator: ", ")
                print("       Sample data: \(sample)... (\(flatFiltered.count) total)")
            }
        }
        
        // Динамическое построение масок на основе условий
        print("\n  🎛  Dynamic mask construction:")
        
        let privacySettings = complexData["user_preferences"] as! [String: Any]
        let privacy = privacySettings["privacy"] as! [String: Bool]
        
        var dynamicPaths: [String] = ["public_info.name"] // Всегда доступно
        
        // Условно добавляем поля на основе privacy настроек
        if privacy["show_email"] == true {
            dynamicPaths.append("contact.email")
        }
        
        if privacy["show_phone"] == true {
            dynamicPaths.append("contact.phone")
        }
        
        if privacy["public_profile"] == true {
            dynamicPaths.append("public_info")
            dynamicPaths.append("user_preferences.notifications")
        }
        
        let dynamicMask = try FieldMaskHandler.FieldMaskValue(paths: dynamicPaths)
        print("    • Privacy-based mask: \(dynamicMask)")
        print("    • Dynamic paths count: \(dynamicPaths.count)")
        print("    • Conditional access: ✅ Implemented")
    }
    
    private static func demonstrateRealWorldScenarios() throws {
        ExampleUtils.printStep(6, "Real-World FieldMask Scenarios")
        
        // Сценарий 1: API versioning и field evolution
        print("  📱 Scenario 1: API Versioning with FieldMask")
        
        let v1Fields = ["user.name", "user.email"]
        let v2Fields = ["user.name", "user.email", "user.phone", "profile.avatar"]
        let v3Fields = v2Fields + ["profile.bio", "metadata.preferences", "social.links"]
        
        let v1Mask = try FieldMaskHandler.FieldMaskValue(paths: v1Fields)
        let v2Mask = try FieldMaskHandler.FieldMaskValue(paths: v2Fields)
        let v3Mask = try FieldMaskHandler.FieldMaskValue(paths: v3Fields)
        
        // Backward compatibility analysis
        let v1v2Compatibility = v1Mask.intersection(v2Mask)
        let v2v3Compatibility = v2Mask.intersection(v3Mask)
        
        var versioningResults: [[String: String]] = []
        versioningResults.append([
            "Version": "v1",
            "Fields": "\(v1Fields.count)",
            "Sample": v1Fields.prefix(2).joined(separator: ", ")
        ])
        versioningResults.append([
            "Version": "v2", 
            "Fields": "\(v2Fields.count)",
            "Sample": v2Fields.prefix(2).joined(separator: ", ")
        ])
        versioningResults.append([
            "Version": "v3",
            "Fields": "\(v3Fields.count)",
            "Sample": v3Fields.prefix(2).joined(separator: ", ")
        ])
        versioningResults.append([
            "Version": "v1∩v2",
            "Fields": "\(v1v2Compatibility.paths.count)",
            "Sample": "Backward compatible fields"
        ])
        versioningResults.append([
            "Version": "v2∩v3",
            "Fields": "\(v2v3Compatibility.paths.count)",
            "Sample": "Backward compatible fields"
        ])
        
        ExampleUtils.printDataTable(versioningResults, title: "API Version Compatibility")
        
        // Сценарий 2: Микросервисы и данные между сервисами
        print("\n  🏢 Scenario 2: Microservices Data Sharing")
        
        let serviceEndpoints: [(String, [String])] = [
            ("user-service", ["user.name", "user.email", "user.phone"]),
            ("profile-service", ["profile.avatar", "profile.bio", "profile.settings"]),
            ("notification-service", ["user.email", "user.phone", "profile.settings.notifications"]),
            ("analytics-service", ["metadata.created", "metadata.updated", "user.age"]),
            ("audit-service", ["metadata", "audit_log"])
        ]
        
        var serviceMasks: [String: FieldMaskHandler.FieldMaskValue] = [:]
        for (service, fields) in serviceEndpoints {
            serviceMasks[service] = try FieldMaskHandler.FieldMaskValue(paths: fields)
        }
        
        // Анализ пересечений между сервисами
        let serviceNames = Array(serviceMasks.keys).sorted()
        print("    • Service data sharing analysis:")
        
        for i in 0..<serviceNames.count {
            for j in (i+1)..<serviceNames.count {
                let service1 = serviceNames[i]
                let service2 = serviceNames[j]
                let mask1 = serviceMasks[service1]!
                let mask2 = serviceMasks[service2]!
                let intersection = mask1.intersection(mask2)
                
                if !intersection.paths.isEmpty {
                    print("      - \(service1) ∩ \(service2): \(intersection.paths.joined(separator: ", "))")
                }
            }
        }
        
        // Сценарий 3: Database projection и query optimization
        print("\n  💾 Scenario 3: Database Query Optimization")
        
        let queryScenarios: [(String, [String], String)] = [
            ("User listing", ["user.name", "user.email"], "Fast index scan"),
            ("Profile preview", ["user.name", "profile.avatar"], "JOIN with profile table"),
            ("Full user data", ["user", "profile", "metadata"], "Multiple JOINs required"),
            ("Audit report", ["user.name", "metadata.created", "audit_log"], "Complex aggregation"),
            ("Mobile app sync", ["user.name", "profile.settings.notifications"], "Minimal bandwidth")
        ]
        
        var queryResults: [[String: String]] = []
        for (scenario, fields, optimization) in queryScenarios {
            let _ = try FieldMaskHandler.FieldMaskValue(paths: fields)
            let estimatedCost = calculateQueryCost(fields)
            
            queryResults.append([
                "Scenario": scenario,
                "Fields": "\(fields.count)",
                "Estimated Cost": "\(estimatedCost)",
                "Optimization": optimization
            ])
        }
        
        ExampleUtils.printDataTable(queryResults, title: "Database Query Planning")
    }
    
    private static func demonstratePerformanceAnalysis() throws {
        ExampleUtils.printStep(7, "Performance Analysis and Optimization")
        
        // Performance тестирование различных операций
        let performanceTestCases = [
            ("Small mask (5 paths)", 5),
            ("Medium mask (25 paths)", 25),
            ("Large mask (100 paths)", 100),
            ("Very large mask (500 paths)", 500)
        ]
        
        var performanceResults: [[String: String]] = []
        
        for (testName, pathCount) in performanceTestCases {
            // Генерируем тестовые пути
            let testPaths = (0..<pathCount).map { "field\($0).subfield\($0 % 10).value" }
            
            // Тестируем создание маски
            let (creationResult, creationTime) = ExampleUtils.measureTime {
                return try! FieldMaskHandler.FieldMaskValue(paths: testPaths)
            }
            
            // Тестируем set операции
            let secondMask = try! FieldMaskHandler.FieldMaskValue(paths: Array(testPaths.dropFirst(pathCount/2)))
            let (_, unionTime) = ExampleUtils.measureTime {
                return creationResult.union(secondMask)
            }
            
            let (_, intersectionTime) = ExampleUtils.measureTime {
                return creationResult.intersection(secondMask)
            }
            
            // Тестируем contains/covers операции
            let testQueryPaths = testPaths.prefix(10)
            let (_, queryTime) = ExampleUtils.measureTime {
                for path in testQueryPaths {
                    _ = creationResult.contains(path)
                    _ = creationResult.covers(path)
                }
            }
            
            // Тестируем сериализацию
            let (_, serializationTime) = ExampleUtils.measureTime {
                return try! FieldMaskHandler.createDynamic(from: creationResult)
            }
            
            performanceResults.append([
                "Test Case": testName,
                "Creation": String(format: "%.2f ms", creationTime * 1000),
                "Union": String(format: "%.2f ms", unionTime * 1000),
                "Intersection": String(format: "%.2f ms", intersectionTime * 1000),
                "Query (10x)": String(format: "%.2f ms", queryTime * 1000),
                "Serialization": String(format: "%.2f ms", serializationTime * 1000)
            ])
        }
        
        ExampleUtils.printDataTable(performanceResults, title: "Performance Benchmarks")
        
        // Memory usage analysis
        print("\n  💾 Memory usage patterns:")
        let largePathSet = (0..<1000).map { "very.long.field.path.number.\($0).with.multiple.segments.for.testing" }
        let _ = try FieldMaskHandler.FieldMaskValue(paths: largePathSet)
        
        let estimatedMemoryPerPath = 50 // Примерная оценка в байтах
        let totalEstimatedMemory = largePathSet.count * estimatedMemoryPerPath
        
        print("    • Large mask paths: \(largePathSet.count)")
        print("    • Average path length: \(largePathSet.map { $0.count }.reduce(0, +) / largePathSet.count) characters")
        print("    • Estimated memory usage: ~\(ExampleUtils.formatDataSize(totalEstimatedMemory))")
        
        // Best practices demonstration
        print("\n  📋 Performance best practices:")
        print("    • ✅ Use specific paths instead of broad parent paths when possible")
        print("    • ✅ Cache FieldMask instances for frequently used patterns")
        print("    • ✅ Prefer intersection over repeated contains() calls")
        print("    • ✅ Validate paths early to avoid runtime errors")
        print("    • ⚠️  Be careful with very large path sets (>1000 paths)")
        print("    • ⚠️  Union operations with large masks can be expensive")
        
        // Optimization tips
        let optimizationTips = [
            "Path caching": "Cache frequently used FieldMask instances",
            "Lazy evaluation": "Defer expensive operations until needed",
            "Path validation": "Validate paths at creation time, not during use",
            "Batch operations": "Group multiple path operations together",
            "Memory pooling": "Reuse FieldMask instances when possible"
        ]
        
        print("\n  🚀 Optimization strategies:")
        for (strategy, description) in optimizationTips {
            print("    • \(strategy): \(description)")
        }
    }
    
    // MARK: - Helper Functions
    
    /// Flattens nested dictionary to dot-notation paths
    private static func flattenDictionary(_ dict: [String: Any], prefix: String) -> [String: Any] {
        var result: [String: Any] = [:]
        
        for (key, value) in dict {
            let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
            
            if let nestedDict = value as? [String: Any] {
                let nestedFlat = flattenDictionary(nestedDict, prefix: fullKey)
                result.merge(nestedFlat) { _, new in new }
            } else {
                result[fullKey] = value
            }
        }
        
        return result
    }
    
    /// Simulates applying partial update with FieldMask
    private static func applyPartialUpdate(_ data: inout [String: Any], mask: FieldMaskHandler.FieldMaskValue, updates: [String: Any]) {
        for (updatePath, updateValue) in updates {
            if mask.covers(updatePath) {
                setNestedValue(&data, path: updatePath, value: updateValue)
            }
        }
    }
    
    /// Sets nested value using dot notation path
    private static func setNestedValue(_ dict: inout [String: Any], path: String, value: Any) {
        let components = path.split(separator: ".").map(String.init)
        guard !components.isEmpty else { return }
        
        if components.count == 1 {
            dict[components[0]] = value
            return
        }
        
        let key = components[0]
        let remainingPath = components.dropFirst().joined(separator: ".")
        
        if dict[key] == nil {
            dict[key] = [String: Any]()
        }
        
        if var nestedDict = dict[key] as? [String: Any] {
            setNestedValue(&nestedDict, path: remainingPath, value: value)
            dict[key] = nestedDict
        }
    }
    
    /// Finds changed fields between two data states
    private static func findChangedFields(before: [String: Any], after: [String: Any], mask: FieldMaskHandler.FieldMaskValue) -> [String: String] {
        let beforeFlat = flattenDictionary(before, prefix: "")
        let afterFlat = flattenDictionary(after, prefix: "")
        
        var changes: [String: String] = [:]
        
        for path in mask.paths {
            let beforeValue = beforeFlat[path]
            let afterValue = afterFlat[path]
            
            if !areEqual(beforeValue, afterValue) {
                let beforeStr = beforeValue.map { "\($0)" } ?? "nil"
                let afterStr = afterValue.map { "\($0)" } ?? "nil"
                changes[path] = "\(beforeStr) → \(afterStr)"
            }
        }
        
        return changes
    }
    
    /// Filters data dictionary using FieldMask
    private static func filterDataWithMask(_ data: [String: Any], mask: FieldMaskHandler.FieldMaskValue) -> [String: Any] {
        var result: [String: Any] = [:]
        let flatData = flattenDictionary(data, prefix: "")
        
        for (path, value) in flatData {
            if mask.covers(path) {
                setNestedValue(&result, path: path, value: value)
            }
        }
        
        return result
    }
    
    /// Counts total number of fields in nested dictionary
    private static func countFields(_ dict: [String: Any]) -> Int {
        return flattenDictionary(dict, prefix: "").count
    }
    
    /// Calculates estimated query cost based on field paths
    private static func calculateQueryCost(_ fields: [String]) -> Int {
        var cost = 0
        for field in fields {
            let depth = field.split(separator: ".").count
            cost += depth * 10  // Deeper paths are more expensive
        }
        return cost
    }
    
    /// Simple equality check for Any values
    private static func areEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (let l?, let r?):
            return "\(l)" == "\(r)" // Simple string comparison
        default:
            return false
        }
    }
}
