# Proposal

## Why

Ядро всё ещё использует ряд совместимых, но устаревших для целевого AMX Mod X 1.10 решений: ручную отправку `SayText`, `register_cvar`, неполный disconnect-forward и хрупкое ручное выполнение `Ham_TakeDamage`. Одновременно поставляемый `hns.cfg` содержит неверные имена четырёх Cvar CT fade, а частые Fakemeta callbacks выполняют лишние native-вызовы.

## What Changes

- Исправить в поставляемом CP1251-конфиге имена `hns_ct_timer_fade_screen_r`, `hns_ct_timer_fade_screen_g`, `hns_ct_timer_fade_screen_b` и `hns_ct_timer_fade_screen_alpha`, чтобы настройки CT countdown действительно применялись и не изменяли fall-down fade.
- Сохранить существующие chat keys, команды и видимый текст, но заменить ручной `SayText` на штатный `client_print_color`; перенести управляющие коды цветов `^1`, `^3`, `^4` непосредственно в RU/EN dictionary.
- Перевести все существующие Cvar с `register_cvar` на `create_cvar`, добавить допустимые границы и привязать часто читаемые числовые, float- и строковые значения через `bind_pcvar_*` без переименования Cvar.
- Заменить deprecated `client_disconnect` на гарантированно парный `client_disconnected`, использовать штатный `user_silentkill`, типизированный `register_event_ex`, именованные team/Fakemeta-константы и кешированный message id `ScreenFade`.
- Заменить ручной вызов оригинального `Ham_TakeDamage` из pre-hook на совместимую пару pre/post hooks: фактическая потеря HP вычисляется после обычного damage pipeline, а HNS-эффекты применяются только при положительном уроне живому игроку.
- Сократить работу частых `FM_EmitSound`, `FM_CmdStart`, `FM_Think` и countdown callbacks: дешёвые фильтры выполняются раньше, значения Cvar читаются из bound-переменных, а лишние bot/HLTV-проверки после `get_players(..., "ch")` удаляются.
- Сохранить AMX Mod X 1.10, текущие имена Cvar, команды, assets и language keys; новые Cvar, команды, ресурсы и публичный plugin API не добавляются.
- Вне scope остаются DHUD/HUD-миграция, magic pdata offset buyzone, ReAPI/ReHLDS/ReGameDLL, изменение механик Flashbang и новые игровые возможности.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `configuration-and-localization`: исправляется поставляемая CT fade-конфигурация, задаётся валидация Cvar и штатное хранение chat color-кодов в словаре.
- `fall-damage-and-recovery`: урон больше не выполняется вручную из pre-hook; обратная связь и autoheal используют фактическую потерю HP после стандартного damage pipeline и не запускаются для погибшего игрока.
- `team-and-player-flow`: очистка player state гарантируется для всех disconnect-сценариев, включая оборванное подключение.

## Impact

- Pawn: `src/scripting/hns.sma`, `src/scripting/hns/definitions.inc`, `src/scripting/hns/ui.inc`, `src/scripting/hns/countdown.inc`, `src/scripting/hns/equipment.inc`, `src/scripting/hns/fall_damage.inc`, `src/scripting/hns/team_flow.inc` и затронутые callbacks в соседних модулях.
- Ресурсы: `src/configs/hns.cfg` сохраняет CP1251; `src/data/lang/hns.txt` сохраняет UTF-8 и прежний набор RU/EN ключей.
- Документация и контракты: README, regression tests и перечисленные main specs обновляются до фактического поведения.
- Совместимость: обязательные модули и минимальная платформа не меняются; ReAPI и сторонние include не появляются.
