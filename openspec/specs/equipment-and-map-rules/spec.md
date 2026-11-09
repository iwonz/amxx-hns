# Equipment And Map Rules Specification

## Purpose

Спецификация определяет выдачу оружия, ограничения ножа T, отключение покупки и очистку сущностей карты.

## Requirements

### Requirement: Набор оружия после spawn

Плагин SHALL через 0.1 секунды после успешного spawn удалить всё оружие игрока, выдать нож и настроенные гранаты.

#### Scenario: Игрок всё ещё жив и подключён

- **WHEN** задача выдачи выполняется для живого подключённого игрока
- **THEN** его инвентарь заменяется ножом и гранатами согласно Cvar

#### Scenario: Игрок изменил состояние

- **WHEN** до callback игрок умер или отключился
- **THEN** выдача не выполняется

### Requirement: Командные режимы гранат

Плагин SHALL трактовать `hns_hegrenade_mode`, `hns_flashbang_mode` и `hns_smokegrenade_mode` одинаково: `0` — никому, `1` — T, `2` — CT, `3` — обеим командам.

#### Scenario: Режим совпадает с командой

- **WHEN** значение равно id команды игрока или `3`
- **THEN** соответствующая граната выдаётся

#### Scenario: Количество Flashbang выше лимита

- **WHEN** `hns_flashbang_count` больше `2`
- **THEN** выдаётся не более двух Flashbang

### Requirement: Безопасный нож прячущихся

Плагин SHALL применять `hns_tr_fake_knife_mode` только к живым T с активным ножом.

#### Scenario: Режим 0

- **WHEN** режим равен `0`
- **THEN** атаки, модель и deploy-звук ножа T не меняются

#### Scenario: Режим 1

- **WHEN** режим равен `1`
- **THEN** кнопки основной и альтернативной атаки ножом T удаляются, а deploy-звук блокируется

#### Scenario: Режим 2

- **WHEN** режим равен `2`
- **THEN** дополнительно очищаются viewmodel и weaponmodel ножа T

### Requirement: Отключение buy zone

Плагин SHALL удалять состояние buyzone у игрока при появлении соответствующей StatusIcon.

#### Scenario: Клиент входит в buy zone

- **WHEN** игра пытается включить иконку `buyzone`
- **THEN** флаг покупки снимается из pdata игрока

### Requirement: Безусловная очистка objective-сущностей

Во время spawn сущностей плагин SHALL удалять `func_vip_safetyzone`, `func_escapezone`, `hostage_entity`, `monster_scientist`, `func_bomb_target`, `info_bomb_target` и `armoury_entity`.

#### Scenario: Карта содержит стандартную objective-сущность

- **WHEN** сущность одного из перечисленных classname создаётся
- **THEN** она удаляется до начала игры независимо от других Cvar

### Requirement: Настраиваемая очистка геометрии

Плагин SHALL удалять двери и разрушаемые объекты в зависимости от Cvar, прочитанных во время spawn сущностей.

#### Scenario: Удаление дверей включено

- **WHEN** `hns_remove_doors` ненулевой и создаётся `func_door` или `func_door_rotating`
- **THEN** сущность удаляется

#### Scenario: Удаление breakables включено

- **WHEN** `hns_remove_breakables` ненулевой и создаётся `func_breakable`
- **THEN** сущность удаляется

#### Scenario: Значение изменено после precache

- **WHEN** Cvar меняется после того, как сущности текущей карты уже созданы
- **THEN** ранее удалённые или сохранённые сущности текущей карты не пересоздаются
