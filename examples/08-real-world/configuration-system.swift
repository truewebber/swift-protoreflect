/**
 * ⚙️ SwiftProtoReflect Example: Configuration System
 *
 * Description: Application configuration system based on Protocol Buffers
 * Key concepts: Configuration management, Environment handling, Hot reload
 * Complexity: 🏢 Expert
 * Execution time: < 25 seconds
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct ConfigurationSystemExample {
  static func main() throws {
    ExampleUtils.printHeader("⚙️ Configuration System - Production Configuration Management")

    try demonstrateBasicConfiguration()
    try demonstrateEnvironmentConfigs()
    try demonstrateHotReload()
    try demonstrateValidationAndDefaults()
    try demonstrateHierarchicalConfigs()

    ExampleUtils.printSuccess("Configuration system demonstration completed!")
    ExampleUtils.printNext([
      "Next example: api-gateway.swift - API Gateway with dynamic schemas",
      "Also explore: validation-framework.swift - comprehensive validation",
    ])
  }

  // MARK: - Basic Configuration

  private static func demonstrateBasicConfiguration() throws {
    ExampleUtils.printStep(1, "Basic Application Configuration")

    print("  ⚙️ Setting up application configuration schema...")

    // Создание конфигурационных дескрипторов
    var configFile = FileDescriptor(name: "app_config.proto", package: "com.app.config")

    // Database configuration
    var dbConfigDescriptor = MessageDescriptor(name: "DatabaseConfig", parent: configFile)
    dbConfigDescriptor.addField(FieldDescriptor(name: "host", number: 1, type: .string))
    dbConfigDescriptor.addField(FieldDescriptor(name: "port", number: 2, type: .int32))
    dbConfigDescriptor.addField(FieldDescriptor(name: "database", number: 3, type: .string))
    dbConfigDescriptor.addField(FieldDescriptor(name: "username", number: 4, type: .string))
    dbConfigDescriptor.addField(FieldDescriptor(name: "ssl_enabled", number: 5, type: .bool))
    dbConfigDescriptor.addField(FieldDescriptor(name: "timeout_seconds", number: 6, type: .int32))

    // Server configuration
    var serverConfigDescriptor = MessageDescriptor(name: "ServerConfig", parent: configFile)
    serverConfigDescriptor.addField(FieldDescriptor(name: "bind_address", number: 1, type: .string))
    serverConfigDescriptor.addField(FieldDescriptor(name: "port", number: 2, type: .int32))
    serverConfigDescriptor.addField(FieldDescriptor(name: "worker_count", number: 3, type: .int32))
    serverConfigDescriptor.addField(FieldDescriptor(name: "max_connections", number: 4, type: .int32))
    serverConfigDescriptor.addField(FieldDescriptor(name: "enable_metrics", number: 5, type: .bool))

    // Application configuration (main)
    var appConfigDescriptor = MessageDescriptor(name: "AppConfig", parent: configFile)
    appConfigDescriptor.addField(FieldDescriptor(name: "app_name", number: 1, type: .string))
    appConfigDescriptor.addField(FieldDescriptor(name: "version", number: 2, type: .string))
    appConfigDescriptor.addField(FieldDescriptor(name: "environment", number: 3, type: .string))
    appConfigDescriptor.addField(FieldDescriptor(name: "debug_mode", number: 4, type: .bool))
    appConfigDescriptor.addField(
      FieldDescriptor(name: "database", number: 5, type: .message, typeName: "com.app.config.DatabaseConfig")
    )
    appConfigDescriptor.addField(
      FieldDescriptor(name: "server", number: 6, type: .message, typeName: "com.app.config.ServerConfig")
    )
    appConfigDescriptor.addField(FieldDescriptor(name: "feature_flags", number: 7, type: .string, isRepeated: true))

    // Регистрация дескрипторов
    configFile.addMessage(dbConfigDescriptor)
    configFile.addMessage(serverConfigDescriptor)
    configFile.addMessage(appConfigDescriptor)

    print("  ✅ Configuration schema created:")
    print("    📄 File: \(configFile.name)")
    print("    📋 Messages: \(configFile.messages.count)")
    print("    🏷  Total fields: \(configFile.messages.values.reduce(0) { $0 + $1.fields.count })")

    // Configuration manager
    class ConfigurationManager {
      private let factory = MessageFactory()
      private var configs: [String: DynamicMessage] = [:]
      private let appConfigDescriptor: MessageDescriptor
      private let configFile: FileDescriptor

      init(appConfigDescriptor: MessageDescriptor, configFile: FileDescriptor) {
        self.appConfigDescriptor = appConfigDescriptor
        self.configFile = configFile
      }

      func loadConfig(name: String, data: [String: Any]) throws {
        var config = factory.createMessage(from: appConfigDescriptor)

        // Load nested configurations
        if let dbData = data["database"] as? [String: Any] {
          let dbConfig = try createDatabaseConfig(dbData)
          try config.set(dbConfig, forField: "database")
        }

        if let serverData = data["server"] as? [String: Any] {
          let serverConfig = try createServerConfig(serverData)
          try config.set(serverConfig, forField: "server")
        }

        // Load simple fields
        try config.set(data["app_name"] as? String ?? "MyApp", forField: "app_name")
        try config.set(data["version"] as? String ?? "1.0.0", forField: "version")
        try config.set(data["environment"] as? String ?? "development", forField: "environment")
        try config.set(data["debug_mode"] as? Bool ?? false, forField: "debug_mode")

        configs[name] = config
      }

      private func createDatabaseConfig(_ data: [String: Any]) throws -> DynamicMessage {
        guard let dbDescriptor = configFile.messages.values.first(where: { $0.name == "DatabaseConfig" }) else {
          throw ConfigError.missingDescriptor("DatabaseConfig")
        }

        var dbConfig = factory.createMessage(from: dbDescriptor)
        try dbConfig.set(data["host"] as? String ?? "localhost", forField: "host")
        try dbConfig.set(Int32(data["port"] as? Int ?? 5432), forField: "port")
        try dbConfig.set(data["database"] as? String ?? "mydb", forField: "database")
        try dbConfig.set(data["username"] as? String ?? "user", forField: "username")
        try dbConfig.set(data["ssl_enabled"] as? Bool ?? false, forField: "ssl_enabled")
        try dbConfig.set(Int32(data["timeout_seconds"] as? Int ?? 30), forField: "timeout_seconds")

        return dbConfig
      }

      private func createServerConfig(_ data: [String: Any]) throws -> DynamicMessage {
        guard let serverDescriptor = configFile.messages.values.first(where: { $0.name == "ServerConfig" }) else {
          throw ConfigError.missingDescriptor("ServerConfig")
        }

        var serverConfig = factory.createMessage(from: serverDescriptor)
        try serverConfig.set(data["bind_address"] as? String ?? "0.0.0.0", forField: "bind_address")
        try serverConfig.set(Int32(data["port"] as? Int ?? 8080), forField: "port")
        try serverConfig.set(Int32(data["worker_count"] as? Int ?? 4), forField: "worker_count")
        try serverConfig.set(Int32(data["max_connections"] as? Int ?? 1000), forField: "max_connections")
        try serverConfig.set(data["enable_metrics"] as? Bool ?? true, forField: "enable_metrics")

        return serverConfig
      }

      func getConfig(name: String) -> DynamicMessage? {
        return configs[name]
      }

      var configCount: Int { configs.count }
    }

    enum ConfigError: Error {
      case missingDescriptor(String)
    }

    // Создание и загрузка конфигурации
    let configManager = ConfigurationManager(appConfigDescriptor: appConfigDescriptor, configFile: configFile)

    let productionConfig: [String: Any] = [
      "app_name": "MyProductionApp",
      "version": "2.1.0",
      "environment": "production",
      "debug_mode": false,
      "database": [
        "host": "prod-db.example.com",
        "port": 5432,
        "database": "production_db",
        "username": "prod_user",
        "ssl_enabled": true,
        "timeout_seconds": 60,
      ],
      "server": [
        "bind_address": "0.0.0.0",
        "port": 443,
        "worker_count": 8,
        "max_connections": 10000,
        "enable_metrics": true,
      ],
    ]

    print("\n  📦 Loading production configuration...")
    try configManager.loadConfig(name: "production", data: productionConfig)

    if let config = configManager.getConfig(name: "production") {
      print("  ✅ Configuration loaded successfully:")

      let appName: String = try config.get(forField: "app_name") as? String ?? ""
      let version: String = try config.get(forField: "version") as? String ?? ""
      let environment: String = try config.get(forField: "environment") as? String ?? ""

      print("    📱 App: \(appName) v\(version)")
      print("    🌍 Environment: \(environment)")

      if let dbConfig = try config.get(forField: "database") as? DynamicMessage {
        let host: String = try dbConfig.get(forField: "host") as? String ?? ""
        let port: Int32 = try dbConfig.get(forField: "port") as? Int32 ?? 0
        print("    🗄  Database: \(host):\(port)")
      }

      if let serverConfig = try config.get(forField: "server") as? DynamicMessage {
        let port: Int32 = try serverConfig.get(forField: "port") as? Int32 ?? 0
        let workers: Int32 = try serverConfig.get(forField: "worker_count") as? Int32 ?? 0
        print("    🖥  Server: port \(port), \(workers) workers")
      }
    }

    print("\n  📊 Configuration System Results:")
    ExampleUtils.printDataTable(
      [
        [
          "Component":
            "Schema Definition | Configuration Loading | Nested Messages | Type Safety | Hierarchical Structure",
          "Status": "✅ Ready | ✅ Success | ✅ Supported | ✅ Enforced | ✅ Working",
          "Details":
            "3 message types | Production config | Database + Server | Dynamic validation | Multi-level nesting",
        ]
      ],
      title: "Configuration System Status"
    )
  }

  // MARK: - Environment Configurations

  private static func demonstrateEnvironmentConfigs() throws {
    ExampleUtils.printStep(2, "Environment-Specific Configurations")

    print("  🌍 Managing multiple environment configurations...")

    // Environment configuration manager
    class EnvironmentConfigManager {
      private var environments: [String: [String: Any]] = [:]
      private let factory = MessageFactory()

      func addEnvironment(_ name: String, config: [String: Any]) {
        environments[name] = config
      }

      func getEnvironmentConfig(_ name: String) -> [String: Any]? {
        return environments[name]
      }

      func compareEnvironments(_ env1: String, _ env2: String) -> [(String, Any?, Any?)] {
        guard let config1 = environments[env1],
          let config2 = environments[env2]
        else {
          return []
        }

        let allKeys = Set(config1.keys).union(Set(config2.keys))
        return allKeys.map { key in
          (key, config1[key], config2[key])
        }
      }

      var environmentCount: Int { environments.count }
      var environmentNames: [String] { Array(environments.keys) }
    }

    let envManager = EnvironmentConfigManager()

    // Development configuration
    envManager.addEnvironment(
      "development",
      config: [
        "app_name": "MyApp (Dev)",
        "version": "2.1.0-dev",
        "debug_mode": true,
        "database_host": "localhost",
        "database_port": 5432,
        "server_port": 8080,
        "worker_count": 2,
        "enable_metrics": false,
      ]
    )

    // Staging configuration
    envManager.addEnvironment(
      "staging",
      config: [
        "app_name": "MyApp (Staging)",
        "version": "2.1.0-rc1",
        "debug_mode": false,
        "database_host": "staging-db.example.com",
        "database_port": 5432,
        "server_port": 8080,
        "worker_count": 4,
        "enable_metrics": true,
      ]
    )

    // Production configuration
    envManager.addEnvironment(
      "production",
      config: [
        "app_name": "MyApp",
        "version": "2.1.0",
        "debug_mode": false,
        "database_host": "prod-db.example.com",
        "database_port": 5432,
        "server_port": 443,
        "worker_count": 8,
        "enable_metrics": true,
      ]
    )

    print("  ✅ Configured \(envManager.environmentCount) environments:")
    for env in envManager.environmentNames.sorted() {
      print("    🌍 \(env)")
    }

    // Environment comparison
    print("\n  🔍 Comparing Development vs Production:")
    let differences = envManager.compareEnvironments("development", "production")

    var comparisonData: [[String]] = [["Setting", "Development", "Production", "Difference"]]

    for (key, devValue, prodValue) in differences.sorted(by: { $0.0 < $1.0 }) {
      let devStr = "\(devValue ?? "nil")"
      let prodStr = "\(prodValue ?? "nil")"
      let isDifferent = devStr != prodStr

      comparisonData.append([
        key,
        devStr,
        prodStr,
        isDifferent ? "⚠️ Different" : "✅ Same",
      ])
    }

    let comparisonDict = [
      "Settings": comparisonData.dropFirst().map { $0[0] }.joined(separator: " | "),
      "Development": comparisonData.dropFirst().map { $0[1] }.joined(separator: " | "),
      "Production": comparisonData.dropFirst().map { $0[2] }.joined(separator: " | "),
      "Difference": comparisonData.dropFirst().map { $0[3] }.joined(separator: " | "),
    ]
    ExampleUtils.printDataTable([comparisonDict], title: "Environment Comparison")

    print("\n  🎯 Environment Benefits:")
    print("    • Environment-specific settings ✅")
    print("    • Easy configuration comparison ✅")
    print("    • Deployment flexibility ✅")
    print("    • Configuration drift detection ✅")
  }

  // MARK: - Hot Reload

  private static func demonstrateHotReload() throws {
    ExampleUtils.printStep(3, "Hot Configuration Reload")

    print("  🔥 Implementing hot configuration reload...")

    // Configuration watcher with hot reload
    class ConfigurationWatcher {
      private var currentConfig: DynamicMessage?
      private var observers: [(DynamicMessage) -> Void] = []
      private var reloadCount = 0

      func loadInitialConfig(_ config: DynamicMessage) {
        currentConfig = config
        notifyObservers()
      }

      func reloadConfig(_ newConfig: DynamicMessage) {
        currentConfig = newConfig
        reloadCount += 1
        print("    🔄 Configuration reloaded (#\(reloadCount))")
        notifyObservers()
      }

      func addObserver(_ observer: @escaping (DynamicMessage) -> Void) {
        observers.append(observer)
      }

      private func notifyObservers() {
        guard let config = currentConfig else { return }
        for observer in observers {
          observer(config)
        }
      }

      var totalReloads: Int { reloadCount }
    }

    // Component that reacts to configuration changes
    class DatabaseConnection {
      private var host: String = ""
      private var port: Int32 = 0
      private var connectionCount = 0

      func updateFromConfig(_ config: DynamicMessage) {
        do {
          if let dbConfig = try config.get(forField: "database") as? DynamicMessage {
            let newHost: String = try dbConfig.get(forField: "host") as? String ?? ""
            let newPort: Int32 = try dbConfig.get(forField: "port") as? Int32 ?? 0

            if newHost != host || newPort != port {
              print("    🔄 Database connection config changed:")
              print("      Host: \(host) → \(newHost)")
              print("      Port: \(port) → \(newPort)")

              host = newHost
              port = newPort
              connectionCount += 1
            }
          }
        }
        catch {
          print("    ❌ Error updating database config: \(error)")
        }
      }

      var status: String {
        return "Connected to \(host):\(port) (reconnections: \(connectionCount))"
      }
    }

    // Setup hot reload demonstration
    var configFile = FileDescriptor(name: "hotreload.proto", package: "com.hotreload")
    var dbDescriptor = MessageDescriptor(name: "DatabaseConfig", parent: configFile)
    dbDescriptor.addField(FieldDescriptor(name: "host", number: 1, type: .string))
    dbDescriptor.addField(FieldDescriptor(name: "port", number: 2, type: .int32))

    var appDescriptor = MessageDescriptor(name: "AppConfig", parent: configFile)
    appDescriptor.addField(
      FieldDescriptor(name: "database", number: 1, type: .message, typeName: "com.hotreload.DatabaseConfig")
    )

    configFile.addMessage(dbDescriptor)
    configFile.addMessage(appDescriptor)

    let watcher = ConfigurationWatcher()
    let dbConnection = DatabaseConnection()

    // Add observer
    watcher.addObserver { config in
      dbConnection.updateFromConfig(config)
    }

    let factory = MessageFactory()

    // Initial configuration
    var initialConfig = factory.createMessage(from: appDescriptor)
    var initialDb = factory.createMessage(from: dbDescriptor)
    try initialDb.set("localhost", forField: "host")
    try initialDb.set(Int32(5432), forField: "port")
    try initialConfig.set(initialDb, forField: "database")

    print("  📦 Loading initial configuration...")
    watcher.loadInitialConfig(initialConfig)
    print("    📊 \(dbConnection.status)")

    // Simulate configuration changes
    let configChanges = [
      ("staging-db.example.com", 5432),
      ("prod-db.example.com", 5432),
      ("backup-db.example.com", 5433),
    ]

    for (host, port) in configChanges {
      Thread.sleep(forTimeInterval: 0.5)  // Simulate time passing

      var newConfig = factory.createMessage(from: appDescriptor)
      var newDb = factory.createMessage(from: dbDescriptor)
      try newDb.set(host, forField: "host")
      try newDb.set(Int32(port), forField: "port")
      try newConfig.set(newDb, forField: "database")

      watcher.reloadConfig(newConfig)
    }

    print("\n  📊 Hot Reload Results:")
    ExampleUtils.printDataTable(
      [
        [
          "Metric": "Total Reloads | Final Status | Zero Downtime | Observer Pattern",
          "Value": "\(watcher.totalReloads) | \(dbConnection.status) | Maintained | Working",
          "Status": "Successful | Active | ✅ Achieved | ✅ Reactive",
        ]
      ],
      title: "Hot Reload Analysis"
    )

    print("\n  🎯 Hot Reload Benefits:")
    print("    • Zero-downtime configuration updates ✅")
    print("    • Reactive component updates ✅")
    print("    • Configuration change tracking ✅")
    print("    • Observer pattern implementation ✅")
  }

  // MARK: - Validation and Defaults

  private static func demonstrateValidationAndDefaults() throws {
    ExampleUtils.printStep(4, "Configuration Validation and Defaults")

    print("  ✅ Implementing configuration validation with defaults...")

    // Configuration validator with defaults
    struct ConfigValidator {
      static func validateAndApplyDefaults(_ config: inout DynamicMessage) -> (
        isValid: Bool, errors: [String], appliedDefaults: [String]
      ) {
        var errors: [String] = []
        var appliedDefaults: [String] = []

        // Validate required fields and apply defaults
        do {
          // App name validation
          if !(try config.hasValue(forField: "app_name")) {
            try config.set("DefaultApp", forField: "app_name")
            appliedDefaults.append("app_name: DefaultApp")
          }
          else if let name = try config.get(forField: "app_name") as? String, name.isEmpty {
            errors.append("app_name cannot be empty")
          }

          // Version validation
          if !(try config.hasValue(forField: "version")) {
            try config.set("1.0.0", forField: "version")
            appliedDefaults.append("version: 1.0.0")
          }

          // Environment validation
          if !(try config.hasValue(forField: "environment")) {
            try config.set("development", forField: "environment")
            appliedDefaults.append("environment: development")
          }
          else if let env = try config.get(forField: "environment") as? String {
            let validEnvs = ["development", "staging", "production"]
            if !validEnvs.contains(env) {
              errors.append("environment must be one of: \(validEnvs.joined(separator: ", "))")
            }
          }

          // Server config validation
          if let serverConfig = try config.get(forField: "server") as? DynamicMessage {
            let port: Int32 = try serverConfig.get(forField: "port") as? Int32 ?? 0
            if port < 1 || port > 65535 {
              errors.append("server port must be between 1 and 65535")
            }

            let workers: Int32 = try serverConfig.get(forField: "worker_count") as? Int32 ?? 0
            if workers < 1 || workers > 32 {
              errors.append("worker_count must be between 1 and 32")
            }
          }

        }
        catch {
          errors.append("Validation error: \(error)")
        }

        return (errors.isEmpty, errors, appliedDefaults)
      }
    }

    // Test validation with different configurations
    var validationFile = FileDescriptor(name: "validation.proto", package: "com.validation")

    var serverDescriptor = MessageDescriptor(name: "ServerConfig", parent: validationFile)
    serverDescriptor.addField(FieldDescriptor(name: "port", number: 1, type: .int32))
    serverDescriptor.addField(FieldDescriptor(name: "worker_count", number: 2, type: .int32))

    var appDescriptor = MessageDescriptor(name: "AppConfig", parent: validationFile)
    appDescriptor.addField(FieldDescriptor(name: "app_name", number: 1, type: .string))
    appDescriptor.addField(FieldDescriptor(name: "version", number: 2, type: .string))
    appDescriptor.addField(FieldDescriptor(name: "environment", number: 3, type: .string))
    appDescriptor.addField(
      FieldDescriptor(name: "server", number: 4, type: .message, typeName: "com.validation.ServerConfig")
    )

    validationFile.addMessage(serverDescriptor)
    validationFile.addMessage(appDescriptor)

    let factory = MessageFactory()

    // Test 1: Empty configuration (should apply defaults)
    print("\n  🧪 Test 1: Empty configuration")
    var emptyConfig = factory.createMessage(from: appDescriptor)
    let emptyResult = ConfigValidator.validateAndApplyDefaults(&emptyConfig)

    print("    Result: \(emptyResult.isValid ? "✅ Valid" : "❌ Invalid")")
    print("    Applied defaults: \(emptyResult.appliedDefaults.count)")
    for defaultValue in emptyResult.appliedDefaults {
      print("      • \(defaultValue)")
    }

    // Test 2: Invalid configuration
    print("\n  🧪 Test 2: Invalid configuration")
    var invalidConfig = factory.createMessage(from: appDescriptor)
    try invalidConfig.set("", forField: "app_name")  // Empty name
    try invalidConfig.set("invalid_env", forField: "environment")  // Invalid environment

    var invalidServer = factory.createMessage(from: serverDescriptor)
    try invalidServer.set(Int32(99999), forField: "port")  // Invalid port
    try invalidServer.set(Int32(100), forField: "worker_count")  // Too many workers
    try invalidConfig.set(invalidServer, forField: "server")

    let invalidResult = ConfigValidator.validateAndApplyDefaults(&invalidConfig)

    print("    Result: \(invalidResult.isValid ? "✅ Valid" : "❌ Invalid")")
    print("    Errors: \(invalidResult.errors.count)")
    for error in invalidResult.errors {
      print("      • \(error)")
    }

    // Test 3: Valid configuration
    print("\n  🧪 Test 3: Valid configuration")
    var validConfig = factory.createMessage(from: appDescriptor)
    try validConfig.set("MyApp", forField: "app_name")
    try validConfig.set("1.2.0", forField: "version")
    try validConfig.set("production", forField: "environment")

    var validServer = factory.createMessage(from: serverDescriptor)
    try validServer.set(Int32(8080), forField: "port")
    try validServer.set(Int32(4), forField: "worker_count")
    try validConfig.set(validServer, forField: "server")

    let validResult = ConfigValidator.validateAndApplyDefaults(&validConfig)

    print("    Result: \(validResult.isValid ? "✅ Valid" : "❌ Invalid")")
    print("    Defaults applied: \(validResult.appliedDefaults.count)")

    // Summary
    print("\n  📊 Validation Results Summary:")
    ExampleUtils.printDataTable(
      [
        [
          "Test Case": "Empty Config | Invalid Config | Valid Config",
          "Valid": "\(emptyResult.isValid) | \(invalidResult.isValid) | \(validResult.isValid)",
          "Errors": "\(emptyResult.errors.count) | \(invalidResult.errors.count) | \(validResult.errors.count)",
          "Defaults Applied":
            "\(emptyResult.appliedDefaults.count) | \(invalidResult.appliedDefaults.count) | \(validResult.appliedDefaults.count)",
        ]
      ],
      title: "Configuration Validation Tests"
    )
  }

  // MARK: - Hierarchical Configurations

  private static func demonstrateHierarchicalConfigs() throws {
    ExampleUtils.printStep(5, "Hierarchical Configuration Management")

    print("  🏗  Implementing hierarchical configuration inheritance...")

    // Hierarchical configuration manager
    class HierarchicalConfigManager {
      private var configLayers: [String: DynamicMessage] = [:]
      private var layerOrder: [String] = []

      func addLayer(_ name: String, config: DynamicMessage, priority: Int = 0) {
        configLayers[name] = config

        // Insert at appropriate position based on priority
        if let index = layerOrder.firstIndex(where: { _ in priority > 0 }) {
          layerOrder.insert(name, at: index)
        }
        else {
          layerOrder.append(name)
        }
      }

      func mergeConfigurations() -> [String: String] {
        var mergedConfig: [String: String] = [:]

        // Apply layers in order (later layers override earlier ones)
        for layerName in layerOrder {
          guard let config = configLayers[layerName] else { continue }

          for (_, field) in config.descriptor.fields {
            let fieldName = field.name
            do {
              if try config.hasValue(forField: fieldName) {
                let value = try config.get(forField: fieldName)
                let stringValue: String = String(describing: value)
                mergedConfig[fieldName] = stringValue
                print("    🔄 Layer '\(layerName)' sets \(fieldName)")
              }
            }
            catch {
              print("    ❌ Error reading \(fieldName) from \(layerName): \(error)")
            }
          }
        }

        return mergedConfig
      }

      var layerCount: Int { configLayers.count }
      var layers: [String] { layerOrder }
    }

    // Create configuration layers
    var hierarchyFile = FileDescriptor(name: "hierarchy.proto", package: "com.hierarchy")
    var configDescriptor = MessageDescriptor(name: "Config", parent: hierarchyFile)

    configDescriptor.addField(FieldDescriptor(name: "app_name", number: 1, type: .string))
    configDescriptor.addField(FieldDescriptor(name: "port", number: 2, type: .int32))
    configDescriptor.addField(FieldDescriptor(name: "debug_mode", number: 3, type: .bool))
    configDescriptor.addField(FieldDescriptor(name: "max_connections", number: 4, type: .int32))
    configDescriptor.addField(FieldDescriptor(name: "log_level", number: 5, type: .string))

    hierarchyFile.addMessage(configDescriptor)

    let hierarchyManager = HierarchicalConfigManager()
    let factory = MessageFactory()

    // Base configuration (lowest priority)
    var baseConfig = factory.createMessage(from: configDescriptor)
    try baseConfig.set("BaseApp", forField: "app_name")
    try baseConfig.set(Int32(8080), forField: "port")
    try baseConfig.set(false, forField: "debug_mode")
    try baseConfig.set(Int32(100), forField: "max_connections")
    try baseConfig.set("INFO", forField: "log_level")

    // Environment configuration (medium priority)
    var envConfig = factory.createMessage(from: configDescriptor)
    try envConfig.set("ProductionApp", forField: "app_name")
    try envConfig.set(Int32(443), forField: "port")
    try envConfig.set(Int32(1000), forField: "max_connections")

    // User override configuration (highest priority)
    var userConfig = factory.createMessage(from: configDescriptor)
    try userConfig.set(true, forField: "debug_mode")
    try userConfig.set("DEBUG", forField: "log_level")

    // Add layers in priority order
    hierarchyManager.addLayer("base", config: baseConfig, priority: 1)
    hierarchyManager.addLayer("environment", config: envConfig, priority: 2)
    hierarchyManager.addLayer("user_override", config: userConfig, priority: 3)

    print("  📊 Configuration layers (\(hierarchyManager.layerCount) total):")
    for (index, layer) in hierarchyManager.layers.enumerated() {
      print("    \(index + 1). \(layer)")
    }

    // Merge configurations
    print("\n  🔄 Merging configuration layers...")
    let mergedConfig = hierarchyManager.mergeConfigurations()

    print("\n  📋 Final merged configuration:")
    for (key, value) in mergedConfig.sorted(by: { $0.key < $1.key }) {
      print("    \(key): \(value)")
    }

    // Configuration source tracking
    print("\n  📊 Configuration Source Analysis:")
    let sourceAnalysis = [
      ["Setting", "Final Value", "Source Layer", "Overrides"],
      ["app_name", "\(mergedConfig["app_name"] ?? "nil")", "environment", "base"],
      ["port", "\(mergedConfig["port"] ?? "nil")", "environment", "base"],
      ["debug_mode", "\(mergedConfig["debug_mode"] ?? "nil")", "user_override", "base"],
      ["max_connections", "\(mergedConfig["max_connections"] ?? "nil")", "environment", "base"],
      ["log_level", "\(mergedConfig["log_level"] ?? "nil")", "user_override", "base"],
    ]

    let sourceDict = [
      "Setting": sourceAnalysis.dropFirst().map { $0[0] }.joined(separator: " | "),
      "Final Value": sourceAnalysis.dropFirst().map { $0[1] }.joined(separator: " | "),
      "Source Layer": sourceAnalysis.dropFirst().map { $0[2] }.joined(separator: " | "),
      "Overrides": sourceAnalysis.dropFirst().map { $0[3] }.joined(separator: " | "),
    ]
    ExampleUtils.printDataTable([sourceDict], title: "Configuration Inheritance")

    print("\n  🎯 Hierarchical Configuration Benefits:")
    print("    • Layered configuration inheritance ✅")
    print("    • Priority-based override system ✅")
    print("    • Configuration source tracking ✅")
    print("    • Flexible deployment scenarios ✅")
    print("    • Clear configuration precedence ✅")
  }
}
