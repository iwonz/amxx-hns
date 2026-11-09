# Design

## Context

См. мотивацию в `proposal.md`. Сейчас `hns.sma` одновременно хранит регистрацию плагина, общие данные и реализацию всех игровых подсистем. Pawn `#include` выполняет текстовую композицию на этапе компиляции, поэтому код можно разделить физически, не создавая дополнительные runtime-плагины и межплагинные вызовы.

`plugin_init`, `plugin_precache`, `plugin_cfg`, клиентский lifecycle и общий `FM_Think` связывают несколько подсистем. Они должны остаться видимыми в точке композиции, чтобы порядок регистрации и общие cleanup-пути были очевидны.

## Goals / Non-Goals

**Goals:**

- оставить `src/scripting/hns.sma` единственной точкой компиляции и получить один `hns.amxx`;
- разнести состояние и callbacks по внутренним feature-oriented include-файлам;
- сохранить сигнатуры функций, имена callbacks, task ID, порядок регистрации hooks/Cvar и наблюдаемое поведение;
- обеспечить статическим тестам целостное представление составного Pawn-исходника и отдельно проверять, что каждый внутренний include подключён точкой композиции;
- сохранять собираемость и зелёные тесты после каждого извлечения.

**Non-Goals:**

- публичный AMXX API, natives, forwards или include для сторонних плагинов;
- несколько независимо загружаемых `.amxx`;
- исправление замеченных логических дефектов, переименование callbacks, изменение Cvar или оптимизация поведения;
- изменение `hns.cfg`, `hns.txt`, ресурсов или основных capability specs.

## Decisions

### 1. Компиляционная композиция вместо нескольких runtime-плагинов

`hns.sma` будет подключать внутренние файлы через quoted includes вида `#include "hns/countdown.inc"`. Официальный `amxxpc` 1.10 продолжит компилировать только `hns.sma`.

Альтернатива — разделить ядро на несколько `.amxx` — потребовала бы определить межплагинный API, порядок загрузки, владение состоянием и failure semantics. Это изменило бы `core-boundaries` и не является безопасным структурным рефакторингом.

### 2. Feature-oriented модули с минимальным общим слоем

Целевая структура:

- `definitions.inc` — общие константы, task ID, Cvar enum и handles;
- `player_state.inc` — состояние слотов игроков, очищаемое в client lifecycle;
- `ui.inc` — chat/DHUD/ScreenFade helpers и общий HUD sync object;
- `map_rules.inc` — удаление map entities и отключение buyzone;
- `fall_damage.inc` — fall damage feedback и autoheal;
- `equipment.inc` — выдача оружия и fake knife hooks;
- `team_flow.inc` — AFK, autojoin, запрет ручной смены команды и swap ролей;
- `round.inc` — завершение раунда, win messages и win sounds;
- `countdown.inc` — старт раунда, countdown, freeze/unfreeze и revive во время countdown;
- `flashbang.inc` — отслеживание grenade entity, failure policy и фильтрация ScreenFade.

Каждый include получает guard. Состояние, принадлежащее одной подсистеме, переносится вместе с её callbacks. Действительно общие lifecycle dispatchers остаются в `hns.sma`; искусственный generic `utils.inc` не создаётся.

Pawn требует объявить глобальный символ до его первого текстового использования. Поэтому `countdown.inc` подключается перед `flashbang.inc`, а round-start callback сбрасывает flash state через `fnResetFlashbangRoundState()`. Дополнительный вызов выполняется один раз в начале раунда; частый `ScreenFade` продолжает читать countdown state напрямую без нового runtime-вызова.

Альтернатива — разделить файл по техническим типам (`events.inc`, `messages.inc`, `forwards.inc`) — сохраняет сильную связанность одной игровой функции между несколькими файлами и хуже поддерживает будущие изменения по feature.

### 3. `hns.sma` остаётся composition root

В корневом файле остаются стандартные AMXX includes, plugin metadata, внутренние includes, `plugin_init`, `plugin_precache`, `plugin_cfg`, `client_connect`, `client_disconnect`, общий `fwdThink` и кросс-функциональный task cleanup. Регистрация событий, сообщений, Ham hooks и Fakemeta forwards не меняет порядок.

Общий `fwdThink` продолжает различать timer entity и детонирующую flashbang. Разделять его на два зарегистрированных `FM_Think` forward нельзя: это добавило бы второй вызов на каждый entity think и изменило performance profile.

### 4. Тесты анализируют все части единого исходника

Python-тесты будут строить `SOURCE` из `hns.sma` и отсортированного набора `src/scripting/hns/*.inc`. Отдельный structural test проверит, что каждый найденный include явно подключён в `hns.sma`; поэтому забытый или осиротевший файл не сможет незаметно удовлетворить текстовую регрессионную проверку.

Тестовая агрегация нужна только для статического анализа. Истиной о реальной композиции остаётся успешная компиляция `hns.sma` официальным `amxxpc` 1.10.

### 5. Механическое извлечение без сопутствующих улучшений

Функции и объявления переносятся без изменения тела, сигнатуры или порядка side effects. Даже очевидные кандидаты на исправление фиксируются отдельно и не меняются в этом change. Каждый модуль извлекается отдельным коммитом; перед следующим шагом выполняются полный Python suite и AMXX-компиляция.

### 6. Hooks, tasks, precache и cleanup не меняются

Сохраняются все текущие AMXX events/messages, Ham hooks и Fakemeta forwards, включая `HLTV`, `Round_Start`, `DeathMsg`, `TextMsg`, `SendAudio`, `ShowMenu`, `VGUIMenu`, `StatusIcon`, `ScreenFade`, `Ham_TakeDamage`, `Ham_Spawn`, `FM_EmitSound`, `FM_CmdStart`, `FM_SetModel`, `FM_Think` и `FM_Spawn`.

Диапазоны `TASK_AUTOHEAL`, `TASK_REVIVE`, `TASK_AFK_REVIVE`, `TASK_FORCE_JOIN` и `TASK_GIVE_WEAPONS` сохраняются. `client_disconnect`, конец раунда и существующие helpers продолжают снимать те же задачи. Countdown/falldown/win sounds по-прежнему precache только в `plugin_precache`; порядок чтения `hns.cfg` для win sounds и precache не меняется.

### 7. Совместимость конфигурации и локализации

Ни один Cvar, default/fallback, config key, language key или placeholder не меняется. `hns.cfg` остаётся CP1251, `hns.txt` — UTF-8 с прежними RU/EN секциями. Новых player-facing строк нет.

## Risks / Trade-offs

- [Неверный include order или потерянное объявление] → переносить по одному модулю, запускать полный suite и официальную компиляцию после каждого шага.
- [Статический тест видит файл, который реально не подключён] → structural test сопоставляет каждый `hns/*.inc` с директивой в `hns.sma`.
- [Скрытое изменение порядка регистрации или side effects] → lifecycle и регистрации остаются в `hns.sma`, тела переносимых функций не редактируются.
- [Единое пространство имён Pawn сохраняет связанность] → считать `.inc` внутренними организационными границами; публичный API и реальное разделение runtime-компонентов оставить отдельному будущему change.
- [Больше файлов усложняет ручную сборку] → README явно укажет, что каталог `src/scripting/hns/` должен находиться рядом с `hns.sma`, а компилировать нужно только `hns.sma`.
- [Performance regression] → компиляционные includes не добавляют runtime-вызовов; общий `FM_Think` и все частые hooks сохраняют прежнее число регистраций и прежние тела.

## Migration Plan

1. Зафиксировать зелёную исходную точку тестами и компиляцией AMX Mod X 1.10.
2. Обновить тестовую загрузку составного исходника и добавить structural contract.
3. Последовательно извлечь общие определения/состояние и feature-модули, проверяя каждый отдельный коммит.
4. Обновить README для новой структуры исходников.
5. Выполнить полный suite, AMXX-компиляцию, strict OpenSpec validation и `git diff --check`.

Откат выполняется обычным revert конкретного extraction-коммита: поскольку каждый промежуточный commit компилируется и не меняет поведение, нет миграции серверных данных или конфигурации.
