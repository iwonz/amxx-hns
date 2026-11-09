# Tasks

## 1. Единая SemVer-версия

- [x] 1.1 Добавить в `tests/test_release_versioning.py` падающие тесты единственного источника версии, полного SemVer 2.0.0, стабильной/prerelease/build версии, невалидных ведущих нулей и точного совпадения `v<SemVer>`; подтвердить ожидаемое падение командой `python3 -B -m unittest tests.test_release_versioning -v`.
- [x] 1.2 Добавить `src/scripting/hns/version.inc` с `HNS_VERSION "1.0.0"`, подключить его в `hns.sma`, удалить самостоятельную строку `VERSION "1.0"` и реализовать команды `version`/`verify-tag` в stdlib-only `scripts/release.py`; проверить `python3 scripts/release.py version`, `python3 scripts/release.py verify-tag --tag v1.0.0` и `python3 -B -m unittest tests.test_release_versioning -v`.
- [x] 1.3 Скомпилировать изменённый Pawn-код официальным AMX Mod X 1.10.0.5487 командой `./amxxpc /workspace/src/scripting/hns.sma -iinclude -o/workspace/build/hns.amxx` в Linux/i386 окружении с проверенными base+cstrike archives и убедиться, что компилятор завершился без errors/warnings.
- [x] 1.4 Зафиксировать источник версии, helper validation и тесты отдельным атомарным commit; проверить, что `git show --stat --oneline HEAD` содержит только изменения группы 1.

## 2. Проверяемая релизная упаковка

- [x] 2.1 До реализации добавить падающие тесты упаковки с временным `.amxx`: точные пути ZIP, побайтовое сохранение `hns.cfg`/`hns.txt`/звуков, имя `hns-v<SemVer>.zip`, отдельный `hns.amxx`, корректный `SHA256SUMS` и отказ при отсутствии обязательного ресурса; подтвердить целевое падение `python3 -B -m unittest tests.test_release_versioning -v`.
- [x] 2.2 Реализовать команду `python3 scripts/release.py package --plugin build/hns.amxx --output-dir build/release` с явным allowlist deployable-файлов и итоговой самопроверкой архива; убедиться, что тесты проходят и `unzip -l build/release/hns-v1.0.0.zip` показывает требуемую структуру относительно `cstrike`.
- [x] 2.3 Зафиксировать упаковщик и его тесты отдельным атомарным commit; проверить область изменений через `git show --stat --oneline HEAD`.

## 3. GitHub Release automation

- [x] 3.1 До workflow добавить падающие regression tests его контракта: tag-only trigger, read-only build job, отдельный `contents: write` publish job, concurrency, pinned official AMXX URLs/SHA-256, вызов локального helper, обязательные tests/OpenSpec/compile gates, передача неизменных artifacts и `gh release create --verify-tag --generate-notes`; подтвердить целевое падение `python3 -B -m unittest tests.test_release_versioning -v`.
- [x] 3.2 Сначала добавить падающий regression test отсутствия legacy `#include <dhudmessage>`, затем удалить этот include и добавить `.github/workflows/release.yml` с закреплёнными commit SHA официальных GitHub Actions, build/publish jobs, AMX Mod X 1.10.0.5487 compilation и условной prerelease-публикацией; проверить workflow-тесты и прогнать локально все команды build job, не выполняя `gh release create`.
- [x] 3.3 Зафиксировать workflow и его regression tests отдельным атомарным commit; проверить область изменений через `git show --stat --oneline HEAD`.
- [x] 3.4 Добавить падающий regression test, запрещающий `${{ runner.* }}` в job-level `env`; перенести временные пути toolchain в shell-step через `$RUNNER_TEMP`, проверить workflow `actionlint 1.7.7`, убедиться через GitHub API, что он распознан под именем `Release`, и зафиксировать исправление отдельным commit до создания тега.
- [x] 3.5 По логу failed run `v1.0.0` добавить regression test рабочего каталога компилятора; запускать `./amxxpc` из `$AMXX_SCRIPTING`, локально воспроизвести GitHub-команду, повысить PATCH-версию до `1.0.1`, повторить все gates и подтвердить успешный build job неизменяемого тега `v1.0.1`, не перемещая опубликованный `v1.0.0`.
- [x] 3.6 По логу publish job `v1.0.1` добавить regression test явного `--repo "$GITHUB_REPOSITORY"` для `gh release create` без checkout; повысить PATCH-версию до `1.0.2`, повторить gates и выпустить Release `v1.0.2`, не перемещая `v1.0.0` и `v1.0.1`.

## 4. Документация и интеграция

- [x] 4.1 До правки README расширить documentation tests требованиями к ссылке на Releases, единому файлу версии, правилам MAJOR/MINOR/PATCH, prerelease и точной последовательности `commit → push → annotated tag → push tag`; подтвердить целевое падение `python3 -B -m unittest tests.test_project_docs -v`.
- [x] 4.2 Обновить `README.md`: убрать вручную дублируемую текущую версию, описать установку готового Release archive, проверку `SHA256SUMS`, изменение версии, локальные release-helper команды и выпуск тега; проверить `python3 -B -m unittest tests.test_project_docs -v` и разрешение всех локальных Markdown-ссылок.
- [x] 4.3 Выполнить полный gate `python3 -B -m unittest discover -s tests -v`, `npx --yes @fission-ai/openspec@1.14.2 validate --all --strict`, `git diff --check` и повторную компиляцию официальным AMX Mod X 1.10.0.5487; дополнительно открыть собранный ZIP и сверить оба SHA-256 с `SHA256SUMS`.
- [x] 4.4 Зафиксировать README и documentation tests отдельным атомарным commit; проверить итоговую историю и чистое состояние через `git log --oneline -5` и `git status --short`.

## Workflow follow-up

- Синхронизировать delta `release-versioning` в основные specs, обновить ожидаемый capability inventory в documentation tests, повторить все gates и архивировать `add-semver-release-automation` отдельным commit.
- Отправлены implementation commits в `origin/master`; опубликованные failed-теги `v1.0.0` и `v1.0.1` оставлены неизменными, исправленный annotated tag `v1.0.2` создан на проверенном commit `670f40d`.
- GitHub Actions run `v1.0.2` завершён успешно; стабильный Release указывает на правильный commit и содержит `hns-v1.0.2.zip`, `hns.amxx`, `SHA256SUMS` с валидными суммами и полным deployable-архивом из 15 файлов.
