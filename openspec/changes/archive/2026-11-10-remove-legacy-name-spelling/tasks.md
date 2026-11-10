# Tasks

## 1. Очистка legacy-написания

- [x] 1.1 В `tests/test_project_docs.py` собирать legacy-имя из двух строковых частей, сохранив отрицательную regression-проверку; выполнить `python3 -B -m unittest tests.test_project_docs.ProjectDocumentationTests.test_canonical_project_identity -v` и убедиться, что `rg -n -F 'Hide N'' Seek: Ultimate' tests/test_project_docs.py` не находит полного написания.
- [x] 1.2 Нормализовать четыре найденных Markdown-вхождения в `openspec/changes/archive/`, сохранив смысл исторических proposal/design/tasks; выполнить `rg -n --hidden --glob '!.git/**' -F 'Hide N'' Seek: Ultimate' .` и подтвердить отсутствие результатов во всём checkout.

## 2. Интеграционная проверка

- [x] 2.1 Запустить `python3 -B -m unittest discover -s tests -v` и подтвердить прохождение полного regression suite после изменения тестовой строки и архивов.
- [x] 2.2 Выполнить `node /Users/i.zimin/.npm/_npx/8aea7483029d0f87/node_modules/@fission-ai/openspec/bin/openspec.js validate --all --strict`, `git diff --check` и повторный глобальный поиск `rg -n --hidden --glob '!.git/**' -F 'Hide N'' Seek: Ultimate' .`; validation и diff check должны пройти, а поиск не должен вернуть совпадений. Компиляция Pawn не требуется, поскольку `src/scripting/**` не изменяется.

## Workflow follow-up

- Архивировать change без синхронизации specs после успешной реализации и проверок.
