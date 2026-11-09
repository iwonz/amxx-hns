# Spec Delta

## MODIFIED Requirements

### Requirement: Реестр Cvar раунда и звуков

Плагин SHALL регистрировать и поддерживать следующие Cvar: `hns_timer`, `hns_timer_immortal`, `hns_timer_immortal_delay`, `hns_timer_antiflash_ct`, `hns_cd_sound`, `hns_win_sound_mode`, `hns_win_sound_hiders`, `hns_win_sound_seekers`, `hns_ct_timer_fade_screen`, `hns_ct_timer_fade_screen_r`, `hns_ct_timer_fade_screen_g`, `hns_ct_timer_fade_screen_b`, `hns_ct_timer_fade_screen_alpha`.

#### Scenario: Установлен поставляемый hns.cfg

- **WHEN** конфигурация выполнена
- **THEN** эффективные поставляемые значения равны `10`, `1`, `3.0`, `1`, `1`, `3`, `radio/terwin.wav`, `radio/ctwin.wav`, `1`, `0`, `0`, `0`, `150` соответственно

### Requirement: Словарь пользовательских сообщений

Плагин SHALL регистрировать `hns.txt` и получать все видимые игрокам тексты через AMX Mod X dictionary lookup.

#### Scenario: Русский или английский клиент

- **WHEN** игроку показывается чат, HUD или DHUD
- **THEN** используется соответствующий `[ru]` или `[en]` ключ без вшитой в Pawn пользовательской фразы

#### Scenario: Словарь изменяется

- **WHEN** добавляется или меняется format key
- **THEN** RU и EN содержат одинаковый набор ключей и совместимые placeholders

#### Scenario: В словаре используется цветной чат

- **WHEN** chat key содержит `^1`, `^3` или `^4`
- **THEN** AMX Mod X передаёт игроку default, team или green цвет без промежуточных пользовательских маркеров

## ADDED Requirements

### Requirement: Допустимые границы Cvar

Числовые Cvar SHALL ограничиваться диапазонами, поддерживаемыми соответствующей HNS-механикой, при регистрации в AMX Mod X 1.10.

#### Scenario: Указано значение ниже минимума

- **WHEN** администратор задаёт числовой Cvar ниже зарегистрированной нижней границы
- **THEN** эффективное значение ограничивается нижней границей

#### Scenario: Указано значение выше максимума

- **WHEN** администратор задаёт числовой Cvar выше зарегистрированной верхней границы
- **THEN** эффективное значение ограничивается верхней границей

#### Scenario: Указано допустимое значение

- **WHEN** администратор задаёт числовой Cvar внутри зарегистрированного диапазона
- **THEN** плагин использует заданное значение без дополнительного изменения

### Requirement: Корректные Cvar CT fade в поставляемом конфиге

Поставляемый `hns.cfg` SHALL задавать цвет countdown fade через `hns_ct_timer_fade_screen_r`, `hns_ct_timer_fade_screen_g`, `hns_ct_timer_fade_screen_b` и `hns_ct_timer_fade_screen_alpha`.

#### Scenario: Администратор меняет CT fade

- **WHEN** изменяются четыре строки CT countdown fade в поставляемом `hns.cfg`
- **THEN** countdown использует заданные R/G/B/alpha и значения fall-down fade не изменяются

#### Scenario: Используются поставляемые значения

- **WHEN** `hns.cfg` не изменялся после установки
- **THEN** CT countdown fade использует `0`, `0`, `0`, `150`, а fall-down fade использует `255`, `0`, `0`, `80`

## REMOVED Requirements

### Requirement: Известное расхождение CT fade в hns.cfg

**Reason**: Поставляемая конфигурация больше не содержит ошибочные имена `hns_falldown_fadescreen_*` в секции CT countdown.

**Migration**: Пользовательские конфиги должны переименовать четыре строки CT-секции в `hns_ct_timer_fade_screen_r`, `hns_ct_timer_fade_screen_g`, `hns_ct_timer_fade_screen_b` и `hns_ct_timer_fade_screen_alpha`; отдельная fall-down секция сохраняет прежние имена.
