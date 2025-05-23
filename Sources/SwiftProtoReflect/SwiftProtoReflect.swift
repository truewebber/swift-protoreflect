/// SwiftProtoReflect
///
/// Библиотека для динамической работы с Protocol Buffers сообщениями в Swift
/// без предварительно скомпилированных .pb файлов.
///
/// Основные компоненты:
/// - Descriptor: Система дескрипторов протобаф сообщений
/// - DynamicMessage: Динамическое представление и манипуляция сообщениями
/// - Serialization: Сериализация/десериализация сообщений

import Foundation
import SwiftProtobuf

/// Главная точка входа в библиотеку
public enum SwiftProtoReflect {
  /// Текущая версия библиотеки
  public static let version = "0.1.0"

  /// Инициализация библиотеки с возможностью настройки
  public static func initialize(options: [String: Any] = [:]) {
    // Будет реализовано в будущем
  }
}
