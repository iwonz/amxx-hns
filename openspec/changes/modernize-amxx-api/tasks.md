# Tasks

## 1. Исправить поставляемую CT fade-конфигурацию

- [x] 1.1 Добавить regression test, требующий ровно по одной CT countdown и fall-down R/G/B/alpha строке с соответствующими значениями; запустить `python3 -B -m unittest discover -s tests -v` и подтвердить ожидаемое падение на текущем `hns.cfg`
- [x] 1.2 Переименовать четыре ошибочные строки CT-секции в CP1251 `src/configs/hns.cfg`, удалить описание известного расхождения из README, проверить `iconv -f CP1251 -t UTF-8 src/configs/hns.cfg >/dev/null` и зелёный `python3 -B -m unittest discover -s tests -v`
- [x] 1.3 Зафиксировать только config/test/README-изменения отдельным коммитом `Fix CT countdown fade configuration` после `git diff --check`

## 2. Перевести цветной чат на AMXX 1.10 API

- [x] 2.1 Добавить regression test на `client_print_color`, отсутствие ручного `SayText`/`replace_all` и штатные color codes в обоих языках; запустить `python3 -B -m unittest discover -s tests -v` и подтвердить ожидаемое падение
- [x] 2.2 Упростить `ChatColorKey`, удалить пользовательский chat transport и заменить `!n/!t/!g` на `^1/^3/^4` в RU/EN без изменения keys/placeholders; проверить зелёный `python3 -B -m unittest discover -s tests -v`
- [x] 2.3 Скомпилировать Pawn командой `docker run --rm --platform linux/386 -v "$PWD":/workspace -v /private/tmp/amxx-review.bHHaQa:/amxx -w /amxx/dist/addons/amxmodx/scripting i386/ubuntu:20.04 ./amxxpc /workspace/src/scripting/hns.sma -iinclude -o/tmp/hns.amxx` и зафиксировать изменение коммитом `Use native AMXX colored chat` после `git diff --check`

## 3. Перевести Cvar на create/bind API

- [x] 3.1 Обновить source/docs regression tests: извлекать Cvar из `create_cvar`, требовать границы и bound runtime state, запрещать `register_cvar`/`get_pcvar_*`; запустить `python3 -B -m unittest discover -s tests -v` и подтвердить ожидаемое падение
- [x] 3.2 Зарегистрировать существующие Cvar через `create_cvar`, добавить documented bounds, bound globals для runtime чисел/float/flag strings и сохранить precache-owned win sound buffers; обновить все runtime consumers и README без переименования Cvar
- [x] 3.3 Проверить зелёный `python3 -B -m unittest discover -s tests -v`, выполнить AMXX 1.10 docker-компиляцию из пункта 2.3 и зафиксировать изменение коммитом `Modernize Cvar registration and binding` после `git diff --check`

## 4. Обновить lifecycle, события и штатные helpers

- [x] 4.1 Добавить regression tests на `client_disconnected`, штатный `user_silentkill`, `register_event_ex`, именованные team/Fakemeta constants и кешированный `ScreenFade` id; запустить `python3 -B -m unittest discover -s tests -v` и подтвердить ожидаемое падение
- [x] 4.2 Реализовать lifecycle/helper/event/constants-миграцию с прежними task cleanup paths, обновить README и существующие tests, завязанные на `client_disconnect`
- [x] 4.3 Проверить зелёный `python3 -B -m unittest discover -s tests -v`, выполнить AMXX 1.10 docker-компиляцию из пункта 2.3 и зафиксировать изменение коммитом `Update AMXX lifecycle and helper APIs` после `git diff --check`

## 5. Сохранить стандартный fall-damage pipeline

- [x] 5.1 Добавить regression tests на парные Ham pre/post hooks, отсутствие `ExecuteHam`/`HAM_SUPERCEDE`, расчёт положительной фактической потери HP и запрет эффектов/autoheal после смерти; запустить `python3 -B -m unittest discover -s tests -v` и подтвердить ожидаемое падение
- [x] 5.2 Реализовать health snapshot и post-damage effects с очисткой player state, сохранив независимые HUD/sound/fade Cvar и единственную autoheal task; обновить README там, где описан fall damage
- [x] 5.3 Проверить зелёный `python3 -B -m unittest discover -s tests -v`, выполнить AMXX 1.10 docker-компиляцию из пункта 2.3 и зафиксировать изменение коммитом `Preserve standard fall damage pipeline` после `git diff --check`

## 6. Сократить работу частых Fakemeta callbacks

- [ ] 6.1 Добавить regression tests на дешёвые ранние фильтры `FM_EmitSound`/`FM_CmdStart`/flash `FM_Think` и отсутствие повторных bot/HLTV-проверок после `get_players(..., "ch")`; запустить `python3 -B -m unittest discover -s tests -v` и подтвердить ожидаемое падение
- [ ] 6.2 Переставить проверки и обращения к entity/player state в согласованном порядке без изменения fake-knife, Flashbang и countdown поведения
- [ ] 6.3 Проверить зелёный `python3 -B -m unittest discover -s tests -v`, выполнить AMXX 1.10 docker-компиляцию из пункта 2.3 и зафиксировать изменение коммитом `Reduce work in frequent Fakemeta callbacks` после `git diff --check`

## 7. Интеграционная проверка

- [ ] 7.1 Запустить `python3 -B -m unittest discover -s tests -v`, `npx --yes @fission-ai/openspec@1.14.2 validate --all --strict`, `iconv -f CP1251 -t UTF-8 src/configs/hns.cfg >/dev/null`, `git diff --check` и AMXX 1.10 docker-компиляцию из пункта 2.3; подтвердить отсутствие незакоммиченных продуктовых изменений и перечислить фактические коммиты

## Workflow follow-up

- Синхронизировать delta specs с main specs после реализации и повторной проверки.
- Архивировать `modernize-amxx-api` отдельным workflow-коммитом после выполнения требований review/verification.
