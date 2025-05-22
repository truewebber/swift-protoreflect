/*
 * BinarySerializationTests.swift
 *
 * Тесты для проверки бинарной сериализации Protocol Buffers
 *
 * Тестовые случаи из плана:
 * - Test-BIN-001: Сериализация всех скалярных типов proto3 с точным соответствием байтовому представлению C++ protoc
 * - Test-BIN-002: Сериализация строк с различными кодировками, включая UTF-8 и многобайтовые символы
 * - Test-BIN-003: Сериализация вложенных сообщений с проверкой правильного представления wire format
 * - Test-BIN-004: Сериализация repeated полей с packed и non-packed форматами
 * - Test-BIN-005: Сериализация map полей с различными типами ключей и значений
 */

import XCTest
@testable import SwiftProtoReflect

// TO BE IMPLEMENTED 