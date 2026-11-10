# Proposal

## Why

Утверждённое отображаемое название проекта — `Hide And Seek: Ultimate`, но до изменения часть AMXX metadata, документации и релизных материалов использовала устаревшее сокращённое написание.

## What Changes

- Заменить отображаемое название проекта на точное `Hide And Seek: Ultimate` в metadata AMXX-плагина, заголовке README, описании release CLI, заголовке GitHub Release и контексте OpenSpec.
- Переименовать GitHub-репозиторий `iwonz/amxx-hns` в `iwonz/amxx-hns-ultimate`, обновить управляемые проектом ссылки и `origin` текущего checkout на новый canonical URL.
- Добавить регрессионную проверку канонического названия и отсутствия старого варианта в активных продуктовых поверхностях.
- Добавить регрессионную проверку canonical GitHub Releases URL и отсутствия старого repository path в активной документации.
- Сохранить технические идентификаторы `hns.sma`, `hns.amxx`, `hns.cfg`, `hns.txt`, префикс Cvar `hns_`, пути ресурсов и имена релизных assets для обратной совместимости; меняется только GitHub repository slug.
- Изменение не добавляет и не меняет Cvar, чат-команды, assets или language keys и не затрагивает игровую механику.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `core-boundaries`: зафиксировать каноническое отображаемое название, canonical GitHub repository URL и стабильность технических HNS-идентификаторов.

## Impact

Затрагиваются GitHub repository settings, локальный `origin`, `src/scripting/hns.sma`, `README.md`, `scripts/release.py`, `.github/workflows/release.yml`, `openspec/config.yaml`, `tests/` и основная спецификация `core-boundaries`. Для владельцев серверов изменение совместимо: пути установки, имена файлов, Cvar, команды, конфигурация и ресурсы не меняются. В `amxx plugins` и новых GitHub Releases будет отображаться новое название, а управляемые ссылки будут вести на `https://github.com/iwonz/amxx-hns-ultimate`; существующие собранные релизы не переименовываются.
