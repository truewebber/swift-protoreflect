/*
 * JSONSerializationTests.swift
 *
 * Тесты для проверки JSON сериализации и десериализации Protocol Buffers
 *
 * Тестовые случаи из плана:
 * - Test-JSON-001: JSON сериализация всех типов данных с соответствием формату C++ protoc
 * - Test-JSON-002: Обработка специальных значений (Infinity, NaN, null) в JSON
 * - Test-JSON-003: Корректная JSON десериализация данных, созданных C++ protoc
 */

import XCTest
@testable import SwiftProtoReflect

// TO BE IMPLEMENTED 