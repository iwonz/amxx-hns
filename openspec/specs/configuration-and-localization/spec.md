# Configuration And Localization Specification

## Purpose

Спецификация фиксирует загрузку Cvar, ресурсов и словарей, поставляемые значения, кодировки и известные расхождения конфигурационного файла.

## Requirements

### Requirement: Автоматическая загрузка hns.cfg

Плагин SHALL выполнить `exec <amxx_configsdir>/hns.cfg` в `plugin_cfg`.

#### Scenario: Конфигурация установлена

- **WHEN** AMX Mod X вызывает `plugin_cfg`
- **THEN** команды из `hns.cfg` применяются без ручного добавления exec в `server.cfg`

#### Scenario: Конфигурация отсутствует

- **WHEN** файл не найден или отдельная команда отсутствует
- **THEN** соответствующий Cvar сохраняет зарегистрированное кодом fallback-значение

### Requirement: Реестр Cvar раунда и звуков

Плагин SHALL регистрировать и поддерживать следующие Cvar: `hns_timer`, `hns_timer_immortal`, `hns_timer_immortal_delay`, `hns_timer_antiflash_ct`, `hns_cd_sound`, `hns_win_sound_mode`, `hns_win_sound_hiders`, `hns_win_sound_seekers`, `hns_ct_timer_fade_screen`, `hns_ct_timer_fade_screen_r`, `hns_ct_timer_fade_screen_g`, `hns_ct_timer_fade_screen_b`, `hns_ct_timer_fade_screen_alpha`.

#### Scenario: Установлен поставляемый hns.cfg

- **WHEN** конфигурация выполнена
- **THEN** эффективные поставляемые значения равны `10`, `1`, `3.0`, `1`, `1`, `3`, `radio/terwin.wav`, `radio/ctwin.wav`, `1`, `0`, `0`, `0`, `150` соответственно, кроме описанного ниже расхождения имён цветовых строк

### Requirement: Реестр Cvar экипировки и Flashbang

Плагин SHALL регистрировать `hns_hegrenade_mode`, `hns_flashbang_mode`, `hns_flashbang_count`, `hns_flashbang_failure_chance`, `hns_flashbang_failure_notify`, `hns_smokegrenade_mode`, `hns_flash_flasher`, `hns_flash_teammate`, `hns_tr_fake_knife_mode`.

#### Scenario: Установлен поставляемый hns.cfg

- **WHEN** конфигурация выполнена
- **THEN** значения равны `0`, `1`, `2`, `90`, `1`, `1`, `0`, `0`, `2` соответственно

#### Scenario: hns.cfg отсутствует

- **WHEN** используется только регистрация кода
- **THEN** fallback `hns_flashbang_failure_chance` равен `0`, а fallback `hns_tr_fake_knife_mode` равен `1`

### Requirement: Реестр Cvar падения и лечения

Плагин SHALL регистрировать `hns_autoheal`, `hns_autoheal_mode`, `hns_autoheal_max_hp`, `hns_autoheal_delay`, `hns_falldown_show_dmg`, `hns_falldown_play_sound`, `hns_falldown_fadescreen`, `hns_falldown_fadescreen_r`, `hns_falldown_fadescreen_g`, `hns_falldown_fadescreen_b`, `hns_falldown_fadescreen_alpha`.

#### Scenario: Установлен поставляемый hns.cfg

- **WHEN** конфигурация выполнена полностью
- **THEN** значения равны `1`, `3`, `65`, `1.5`, `1`, `1`, `1`, `255`, `0`, `0`, `80` соответственно

#### Scenario: hns.cfg отсутствует

- **WHEN** используется только регистрация кода
- **THEN** fallback `hns_autoheal_max_hp` равен `60`

### Requirement: Реестр Cvar игроков и карты

Плагин SHALL регистрировать `hns_autojoin`, `hns_autojoin_immunity`, `hns_autojoin_immunity_flag`, `hns_change_team`, `hns_change_team_immunity`, `hns_change_team_immunity_flag`, `hns_afk_control`, `hns_afk_timer_revive`, `hns_remove_breakables`, `hns_remove_doors`.

#### Scenario: Установлен поставляемый hns.cfg

- **WHEN** конфигурация выполнена
- **THEN** первые восемь значений равны `1`, `1`, `t`, `0`, `1`, `t`, `1`, `1`

#### Scenario: Настройки удаления сущностей не указаны

- **WHEN** `hns.cfg` не содержит `hns_remove_breakables` и `hns_remove_doors`
- **THEN** оба Cvar используют fallback `1` и применяются во время precache/spawn сущностей

### Requirement: Загрузка звуков победы до precache

Плагин SHALL до `precache_sound` самостоятельно прочитать значения `hns_win_sound_hiders` и `hns_win_sound_seekers` из `hns.cfg`.

#### Scenario: Указан пользовательский путь

- **WHEN** непустой путь длиной до 63 символов присутствует в конфиге до загрузки карты
- **THEN** он precache и затем регистрируется как значение Cvar

#### Scenario: Обе роли используют один путь

- **WHEN** пути полностью совпадают
- **THEN** один и тот же файл не precache повторно

### Requirement: Встроенные звуковые ресурсы

Плагин SHALL precache `hns/countdown/1.wav` … `hns/countdown/10.wav` и `hns/falldown/1.wav` на каждой карте.

#### Scenario: Отсутствует обязательный WAV

- **WHEN** сервер не содержит один из файлов по ожидаемому пути
- **THEN** загрузка карты может завершиться ошибкой precache и установка считается неполной

#### Scenario: Присутствует start asset

- **WHEN** установлен `hns/start/1.wav`
- **THEN** текущее ядро не precache и не воспроизводит этот файл

### Requirement: Словарь пользовательских сообщений

Плагин SHALL регистрировать `hns.txt` и получать все видимые игрокам тексты через AMX Mod X dictionary lookup.

#### Scenario: Русский или английский клиент

- **WHEN** игроку показывается чат, HUD или DHUD
- **THEN** используется соответствующий `[ru]` или `[en]` ключ без вшитой в Pawn пользовательской фразы

#### Scenario: Словарь изменяется

- **WHEN** добавляется или меняется format key
- **THEN** RU и EN содержат одинаковый набор ключей и совместимые placeholders

### Requirement: Кодировки ресурсов

Репозиторий SHALL хранить `src/configs/hns.cfg` в CP1251, а Pawn, lang, Markdown, YAML и Python — в UTF-8.

#### Scenario: Агент меняет hns.cfg

- **WHEN** конфигурация редактируется
- **THEN** CP1251 сохраняется и декодирование `iconv -f CP1251 -t UTF-8` остаётся успешным

### Requirement: Известное расхождение CT fade в hns.cfg

Текущее состояние SHALL учитывать, что строки R/G/B/alpha в секции CT countdown поставляемого `hns.cfg` ошибочно используют имена `hns_falldown_fadescreen_*`, а корректные `hns_ct_timer_fade_screen_r`, `hns_ct_timer_fade_screen_g`, `hns_ct_timer_fade_screen_b` и `hns_ct_timer_fade_screen_alpha` зарегистрированы только кодом.

#### Scenario: Администратор меняет подписанные CT-строки без исправления имён

- **WHEN** изменяются только существующие четыре строки секции
- **THEN** они не меняют CT countdown fade и позже перекрываются настоящей fall-down секцией

#### Scenario: Добавлены корректные Cvar

- **WHEN** администратор явно задаёт `hns_ct_timer_fade_screen_r`, `hns_ct_timer_fade_screen_g`, `hns_ct_timer_fade_screen_b` и `hns_ct_timer_fade_screen_alpha`
- **THEN** countdown использует заданные значения
