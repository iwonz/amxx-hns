# Design

## Context

См. `proposal.md` — Why. Проект компилируется под AMX Mod X 1.10 и остаётся vanilla AMXX-плагином без ReAPI. Код уже разделён на внутренние `.inc`, но регистрация Cvar и engine hooks сосредоточена в `hns.sma`; `hns.cfg` поставляется в CP1251, `hns.txt` — в UTF-8.

Изменение затрагивает частые пути: `FM_CmdStart` вызывается на user command, `FM_EmitSound` — на engine sound, `FM_Think` — на entity think, `ScreenFade` — на message, countdown — раз в секунду для каждого человека. Любая дополнительная работа в них должна быть ограничена константным числом дешёвых проверок.

## Goals / Non-Goals

**Goals:**

- Использовать штатные API AMX Mod X 1.10 там, где они полностью заменяют пользовательский transport или deprecated forward.
- Сохранить текущие имена Cvar, команды, RU/EN keys, assets и vanilla-зависимости.
- Сделать Cvar state автоматически обновляемым без повторных `get_pcvar_*` в runtime callbacks.
- Оставить стандартный damage pipeline совместимым с hooks других плагинов.
- Разделить реализацию на независимые проверяемые коммиты в порядке: CT config, chat, Cvar, lifecycle/helpers, fall damage, hot paths.

**Non-Goals:**

- Не менять DHUD/HUD transport, buyzone pdata, Flashbang-механику, task delays или состав выдаваемого оружия.
- Не добавлять ReAPI, ReHLDS, ReGameDLL, `engine` либо сторонние include.
- Не вводить новые Cvar, команды, звуки, language keys или публичные natives/forwards.

## Decisions

### 1. Исправлять CT fade как самостоятельный config commit

Четыре строки первой fade-секции будут переименованы с `hns_falldown_fadescreen_*` на `hns_ct_timer_fade_screen_*`, не меняя значения `0/0/0/150`. Нижняя fall-down секция сохранит `hns_falldown_fadescreen_*` и `255/0/0/80`. Файл после правки снова кодируется в CP1251 и проверяется `iconv`.

Альтернатива — сохранить известное расхождение и документировать ручное добавление Cvar — отклонена, потому что поставляемая настройка должна управлять подписанной механикой.

### 2. Сохранить `ChatColorKey`, но удалить собственный SayText transport

`ChatColorKey` остаётся единой точкой добавления `HNS_CHAT_PREFIX` и dictionary lookup. Внутри будет один `client_print_color(id, id, ...)`: recipient как sender сохраняет прежний team color. `SendChatColor`, ручной message buffer и `replace_all` удаляются. В обоих языках `!n/!t/!g` заменяются штатными `^1/^3/^4`; набор keys и placeholders не меняется.

Альтернатива — оставить маркеры и только заменить финальную отправку — сохраняет лишние форматирование и три прохода по строке, поэтому отклонена.

### 3. Регистрировать Cvar через `create_cvar` и хранить runtime state в bound globals

Каждый числовой или float Cvar получает именованную global-переменную и `bind_pcvar_num`/`bind_pcvar_float`. Короткие строки флагов иммунитета получают `bind_pcvar_string`. Runtime callbacks читают эти globals, поэтому изменение Cvar администратором применяется автоматически без `get_pcvar_*`.

Границы задаются по существующему контракту:

- boolean: `0..1`;
- team/mode: `0..3`, fake knife: `0..2`, Flashbang count: `0..2`;
- countdown: `1..10`, failure chance: `0..100`, RGB/alpha: `0..255`;
- delays и autoheal amount: нижняя граница `0`, без искусственной верхней границы.

Win sound paths не bind к runtime playback buffer: они должны быть прочитаны и precache в `plugin_precache`. Изменение такого Cvar после загрузки карты не должно заставлять плагин воспроизводить непрекешированный ресурс. `hns_remove_doors` и `hns_remove_breakables` продолжают регистрироваться и bind в `plugin_precache`, потому что используются во время entity spawn.

Альтернатива — оставить pcvar handles и кешировать значения вручную — требует change hooks и создаёт две конкурирующие копии состояния.

### 4. Обновить lifecycle и helpers без изменения игрового результата

`client_disconnected(id, bool:drop, message[], maxlen)` заменяет deprecated `client_disconnect` и вызывает существующий `fnRemovePlayerTasks` до сброса player arrays. Он гарантированно парен с `client_connect`, включая отменённое подключение.

Собственный `fnUserSilentKill` заменяется штатным `user_silentkill`. События `HLTV`, `DeathMsg`, `CurWeapon` регистрируются через `register_event_ex` с `RegisterEventFlags`; числовые T/CT/spectator и Fakemeta return values заменяются именованными константами. `ScreenFade` message id получается один раз в `plugin_init` и используется и для hook registration, и для отправки.

Task namespaces и cleanup paths не меняются: `TASK_AUTOHEAL`, `TASK_REVIVE`, `TASK_AFK_REVIVE`, `TASK_FORCE_JOIN`, `TASK_GIVE_WEAPONS` по-прежнему удаляются на disconnect и/или round end.

### 5. Измерять fall damage парой Ham pre/post hooks

Для `Ham_TakeDamage` регистрируются pre и post callbacks. Pre-hook только для `DMG_FALL` запоминает HP пострадавшего и возвращает `HAM_IGNORED`. Оригинальная игра и остальные плагины применяют damage обычным путём. Post-hook снова проверяет `DMG_FALL`, живое/подключённое состояние и вычисляет `saved health - current health`.

При положительной потере HP живому игроку отдельный helper выполняет прежние независимые HUD, sound, ScreenFade и autoheal решения. При нулевом уроне или смерти эффекты и новая autoheal task не создаются. Pending health очищается при новом подключении/disconnect, чтобы переиспользованный id не наследовал измерение.

Альтернатива — сохранить `ExecuteHam` внутри pre-hook — может обходить или менять ожидаемый порядок hooks других плагинов и потому отклонена.

### 6. В частых forwards сначала выполнять самые дешёвые фильтры

`FM_EmitSound` сначала отбрасывает не-player entity и любой sound кроме knife deploy, затем проверяет bound fake-knife mode и команду. `FM_CmdStart` сначала проверяет bound mode и alive/team state, а weapon/buttons читает только для подходящего T. Возвраты используют `FMRES_*`.

`FM_Think` сохраняет timer branch, а flash branch сначала проверяет диапазон entity и tracked bit; `pev_valid`, `pev_dmgtime` и owner читаются только для отмеченной Flashbang. Countdown использует уже отфильтрованный `get_players(..., "ch")` без повторных `is_user_bot`/`is_user_hltv` и bound fade/sound values.

Альтернатива — перейти на `Ham_Think` grenade или ReAPI grenade hooks — требует отдельного runtime-совместимого изменения и не входит в этот change.

### 7. Проверять каждый смысловой коммит тестом и компиляцией

Перед каждой реализацией добавляется статическая regression-проверка, наблюдается её ожидаемое падение, затем вносится минимальная правка. После каждого смыслового блока запускаются целевые unit tests и компиляция официальным `amxxpc` 1.10; перед завершением — полный unittest, strict OpenSpec validation, `git diff --check`, CP1251 validation и полная Pawn-компиляция.

## Risks / Trade-offs

- [AMXX bounds меняют поведение явно некорректных значений] → диапазоны соответствуют уже документированным режимам; valid shipped values не меняются, invalid-value scenarios фиксируются тестами.
- [Runtime-изменение sound-path Cvar может не совпасть с precache buffer] → sound buffers намеренно не bind; README сохраняет требование смены карты для новых ресурсов.
- [Pre/post health snapshot может быть испорчен вложенным damage другого плагина] → snapshot используется только для одного синхронного `DMG_FALL` pipeline и очищается после post; runtime smoke-test падения остаётся необходимым при развёртывании.
- [Замена chat markers может повредить локализацию] → RU/EN keys и placeholders сравниваются тестом, а отсутствие `!n/!t/!g` и наличие native color codes проверяются отдельно.
- [Большой Cvar commit затрагивает много callbacks] → он не смешивается с lifecycle/fall/hot-path рефакторингом и должен компилироваться отдельным коммитом.

## Migration Plan

1. Установить новый `hns.amxx`, исправленный `hns.cfg` и обновлённый `hns.txt` одновременно.
2. Если используется пользовательский `hns.cfg`, переименовать только четыре Cvar CT fade; fall-down Cvar оставить без изменения.
3. Сменить карту или перезапустить сервер, чтобы заново выполнить precache и загрузить конфигурацию.
4. Проверить цветной чат, CT countdown fade, `/afk`/`/play`, смертельное и несмертельное падение, fake knife modes `0..2`.

Rollback выполняется возвратом предыдущих `hns.amxx`, `hns.cfg` и `hns.txt` как единого набора с последующей сменой карты.
