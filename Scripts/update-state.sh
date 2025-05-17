#!/bin/bash

# Скрипт для обновления PROJECT_STATE.md на основе последних изменений

# Получение последнего коммита
LAST_COMMIT=$(git log -1 --pretty=%B)
COMMIT_DATE=$(git log -1 --pretty=%ad --date=short)

# Обновление секции "Последние обновления" в PROJECT_STATE.md
sed -i '' "/^## Последние обновления/a\\
- $COMMIT_DATE: $LAST_COMMIT" PROJECT_STATE.md

echo "PROJECT_STATE.md обновлен"
