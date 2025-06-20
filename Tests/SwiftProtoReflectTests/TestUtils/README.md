# Test Utilities

Директория содержит вспомогательные утилиты для тестирования Protocol Buffers:

1. `TestHelpers.swift` - общие вспомогательные функции для тестов
   - Функции сравнения бинарных данных
   - Функции сравнения структур сообщений
   - Утилиты для создания типичных тестовых случаев

2. `CPPBridge.swift` - мост к C++ реализации Protocol Buffers для сравнения
   - Функции для запуска C++ protoc для генерации эталонных данных
   - Функции для вызова C++ сериализаторов/десериализаторов

3. `PerformanceMeasurement.swift` - утилиты для замеров производительности

4. `TestDescriptors.swift` - готовые дескрипторы для тестов

Эти утилиты используются в тестах для упрощения тестирования и обеспечения 
согласованности сравнения с эталонной C++ реализацией. 