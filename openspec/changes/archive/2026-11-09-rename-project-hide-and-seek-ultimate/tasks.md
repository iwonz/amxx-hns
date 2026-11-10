# Tasks

## 1. Каноническое название

- [x] 1.1 Добавить в `tests/test_project_docs.py` регрессионный тест точного имени `Hide And Seek: Ultimate` в Pawn metadata, README, release CLI, release workflow и OpenSpec context, а также canonical Releases URL `https://github.com/iwonz/amxx-hns-ultimate/releases`; до изменения источников запустить `python3 -B -m unittest tests.test_project_docs.ProjectDocumentationTests.test_canonical_project_identity -v` и подтвердить ожидаемое падение на старых значениях.
- [x] 1.2 Заменить отображаемое имя в `src/scripting/hns.sma`, `README.md`, `scripts/release.py`, `.github/workflows/release.yml` и `openspec/config.yaml`, а ссылку Releases в README перевести на новый repository path, не меняя технические HNS-идентификаторы; проверить результат командой `python3 -B -m unittest tests.test_project_docs.ProjectDocumentationTests.test_canonical_project_identity -v`.
- [x] 1.3 Проверить совместимость документации и release packaging командой `python3 -B -m unittest tests.test_project_docs tests.test_release_versioning -v`; тесты должны подтверждать прежние имена `hns.amxx`, `hns.cfg`, `hns.txt`, `hns_` Cvar, путей ресурсов и release assets.

## 2. Переименование GitHub-репозитория

- [x] 2.1 Выполнить preflight командами `gh auth status`, `gh repo view iwonz/amxx-hns --json nameWithOwner,url` и `gh repo view iwonz/amxx-hns-ultimate --json nameWithOwner,url`; подтвердить административный доступ к исходному репозиторию и отсутствие target-репозитория, не выполняя переименование при занятом slug или недостаточных правах.
- [x] 2.2 Переименовать GitHub-репозиторий командой `gh repo rename amxx-hns-ultimate --repo iwonz/amxx-hns --yes`, затем проверить результат командами `gh repo view iwonz/amxx-hns-ultimate --json nameWithOwner,url` и `git ls-remote https://github.com/iwonz/amxx-hns-ultimate.git HEAD`.
- [x] 2.3 Переключить текущий checkout командой `git remote set-url origin https://github.com/iwonz/amxx-hns-ultimate.git` и проверить оба направления командой `git remote -v`; fetch и push URL должны точно совпадать с новым canonical remote.

## 3. Интеграционная проверка

- [x] 3.1 Запустить полный regression suite командой `python3 -B -m unittest discover -s tests -v` и устранить все падения, связанные с изменением.
- [x] 3.2 Скомпилировать `src/scripting/hns.sma` официальным AMX Mod X 1.10.0.5487: из каталога `addons/amxmodx/scripting` официального toolchain выполнить `./amxxpc "/Users/i.zimin/Desktop/amxx-hns/src/scripting/hns.sma" -iinclude -o"/Users/i.zimin/Desktop/amxx-hns/build/hns.amxx"`; зафиксировать фактически использованный путь и версию компилятора и убедиться, что сборка завершилась без ошибок.
- [x] 3.3 Выполнить `npx --yes @fission-ai/openspec@1.14.2 validate --all --strict`, `git diff --check`, `rg -n -F 'Hide N'' Seek: Ultimate' src/scripting/hns.sma README.md scripts/release.py .github/workflows/release.yml openspec/config.yaml` и `rg -n 'github\.com/iwonz/amxx-hns(?:\.git|/|$)' README.md tests`; validation и diff check должны пройти, а обе команды `rg` не должны найти старые значения на активных поверхностях.

## Workflow follow-up

- Синхронизировать delta `core-boundaries` с основной спецификацией после успешной реализации и проверок.
- Архивировать change после проверки синхронизированной спецификации.
