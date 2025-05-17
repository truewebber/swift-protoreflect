#!/bin/bash

# Скрипт для создания заготовок файлов для нового компонента модуля
# Использование: ./Scripts/setup-module.sh Descriptor FileDescriptor

MODULE=$1
COMPONENT=$2

if [ -z "$MODULE" ] || [ -z "$COMPONENT" ]; then
  echo "Использование: $0 <Имя модуля> <Имя компонента>"
  echo "Пример: $0 Descriptor FileDescriptor"
  exit 1
fi

# Проверяем существование модуля
MODULE_DIR="Sources/SwiftProtoReflect/$MODULE"
if [ ! -d "$MODULE_DIR" ]; then
  echo "Ошибка: Модуль $MODULE не существует"
  exit 1
fi

# Создаем файл исходного кода
SOURCE_FILE="$MODULE_DIR/$COMPONENT.swift"
echo "Создаю файл $SOURCE_FILE"

cat > "$SOURCE_FILE" << EOF
//
// $COMPONENT.swift
// SwiftProtoReflect
//
// Создан: $(date +%Y-%m-%d)
//

import Foundation
import SwiftProtobuf

/// $COMPONENT
///
/// [Описание компонента и его назначения]
public struct $COMPONENT {
  // MARK: - Properties
  
  // MARK: - Initialization
  
  /// Создает новый экземпляр $COMPONENT
  public init() {
    // TODO: Реализовать инициализацию
  }
  
  // MARK: - Methods
  
  // TODO: Добавить методы
}
EOF

# Создаем файл тестов
TEST_DIR="Tests/SwiftProtoReflectTests/$MODULE"
mkdir -p "$TEST_DIR"

TEST_FILE="$TEST_DIR/${COMPONENT}Tests.swift"
echo "Создаю файл тестов $TEST_FILE"

cat > "$TEST_FILE" << EOF
//
// ${COMPONENT}Tests.swift
// SwiftProtoReflectTests
//
// Создан: $(date +%Y-%m-%d)
//

import XCTest
@testable import SwiftProtoReflect

final class ${COMPONENT}Tests: XCTestCase {
  // MARK: - Properties
  
  // MARK: - Setup
  
  override func setUp() {
    super.setUp()
    // Настройка тестов
  }
  
  override func tearDown() {
    // Очистка после тестов
    super.tearDown()
  }
  
  // MARK: - Tests
  
  func testExample() {
    // TODO: Реализовать тесты
    XCTAssertTrue(true, "Placeholder test")
  }
  
  // MARK: - Helpers
}
EOF

echo "Обновляю README модуля"
README_FILE="$MODULE_DIR/_README.md"

# Добавляем компонент в список состояния модуля
sed -i '' "s/- \[ \] $COMPONENT/- \[x\] $COMPONENT/" "$README_FILE" || \
sed -i '' "/## Состояние модуля/a\\
- \[ \] $COMPONENT" "$README_FILE"

echo "Готово! Созданы файлы для компонента $COMPONENT в модуле $MODULE"
echo "Не забудь обновить PROJECT_STATE.md и сделать коммит!"
