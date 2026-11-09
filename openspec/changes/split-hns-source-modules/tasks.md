# Tasks

## Обязательная проверка Pawn-шагов

Для каждого task, который меняет Pawn-исходники, выполнить обе команды до коммита:

```sh
python3 -B -m unittest discover -s tests -v
docker run --rm --platform linux/386 -v "$PWD":/workspace -v /private/tmp/amxx-review.bHHaQa:/amxx -w /amxx/dist/addons/amxmodx/scripting i386/ubuntu:20.04 ./amxxpc /workspace/src/scripting/hns.sma -iinclude -o/tmp/hns.amxx
```

## 1. Safety net

- [x] 1.1 Зафиксировать исходную зелёную точку командами `python3 -B -m unittest discover -s tests -v` и указанной выше компиляцией AMX Mod X 1.10, не продолжать рефакторинг при ошибке.
- [x] 1.2 Обновить `tests/test_hns_source.py` и `tests/test_project_docs.py`, чтобы `SOURCE` включал `hns.sma` и все `src/scripting/hns/*.inc`; добавить проверку подключения каждого найденного include в composition root и проверить task командой `python3 -B -m unittest discover -s tests -v`.

## 2. Shared source foundation

- [x] 2.1 Извлечь общие константы, task ID, Cvar enum и handles в guarded `hns/definitions.inc`, не меняя значения или порядок enum; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.
- [x] 2.2 Извлечь slot-scoped массивы состояния в guarded `hns/player_state.inc`, сохранив прежнюю инициализацию/cleanup в `client_connect` и `client_disconnect`; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.
- [x] 2.3 Извлечь HUD/chat/ScreenFade helpers и HUD sync state в guarded `hns/ui.inc` без изменения message payload и локализации; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.

## 3. Leaf gameplay modules

- [x] 3.1 Извлечь map entity filtering и buyzone handling вместе с их состоянием в guarded `hns/map_rules.inc`, сохранив `FM_Spawn`/`StatusIcon` регистрацию и возвратные коды; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.
- [x] 3.2 Извлечь fall damage feedback и autoheal callbacks в guarded `hns/fall_damage.inc`, сохранив Ham hook, task ID, delay и cleanup; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.
- [x] 3.3 Извлечь spawn equipment и fake knife callbacks в guarded `hns/equipment.inc`, сохранив Ham/Fakemeta hooks и task semantics; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.

## 4. Lifecycle modules

- [x] 4.1 Извлечь AFK, autojoin, manual team change, role swap и player-count helpers в guarded `hns/team_flow.inc`, сохранив команды, message hooks, task scheduling и slot cleanup; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.
- [x] 4.2 Извлечь round end, win message/audio suppression и win sound config/precache в guarded `hns/round.inc`, сохранив порядок side effects и precache timing; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.
- [ ] 4.3 Извлечь countdown, freeze/unfreeze и countdown revive callbacks вместе с их состоянием в guarded `hns/countdown.inc`, оставив общий `FM_Think` dispatcher в `hns.sma`; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.
- [ ] 4.4 Извлечь flashbang entity tracking, failure notification и ScreenFade policy вместе с их состоянием в guarded `hns/flashbang.inc`, сохранив один общий `FM_Think` и все частые callback без дополнительной работы; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.

## 5. Documentation and integration

- [ ] 5.1 Обновить README: описать composition root, назначение внутренних модулей, требование хранить каталог `hns/` рядом с `hns.sma` и компилировать только `hns.sma`; проверить task командой `python3 -B -m unittest discover -s tests -v` и оформить отдельный коммит.
- [ ] 5.2 Зафиксировать в source regression test полный ожидаемый набор внутренних модулей и отсутствие публичного plugin API; выполнить обязательную проверку Pawn-шагов и оформить отдельный коммит.
- [ ] 5.3 Выполнить свежую интеграционную проверку командами `python3 -B -m unittest discover -s tests -v`, указанной выше компиляцией AMX Mod X 1.10, `/Users/i.zimin/.npm/_npx/8aea7483029d0f87/node_modules/.bin/openspec validate --all --strict` и `git diff --check`; проверить, что не добавлены `.amxx`, временные файлы и незапланированные изменения `hns.cfg`, `hns.txt` или основных specs.

## Workflow follow-up

- После проверки синхронизировать change; delta specs отсутствуют из-за `skip_specs: true`.
- Архивировать change через OpenSpec workflow и проверить архивированное состояние.
