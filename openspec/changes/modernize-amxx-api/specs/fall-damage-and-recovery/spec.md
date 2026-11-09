# Spec Delta

## MODIFIED Requirements

### Requirement: Единственное применение урона от падения

Плагин SHALL наблюдать `DMG_FALL` до и после стандартного `Ham_TakeDamage`, не вызывать оригинальный damage вручную и не блокировать обычный damage pipeline.

#### Scenario: Получен урон другого типа

- **WHEN** bits damage type не содержит `DMG_FALL`
- **THEN** pre/post callbacks возвращают `HAM_IGNORED` и не применяют HNS-эффекты

#### Scenario: Получен урон от падения

- **WHEN** damage type содержит `DMG_FALL`
- **THEN** pre-hook сохраняет исходное HP, стандартная игра применяет урон ровно один раз, а post-hook вычисляет фактическую потерю HP

### Requirement: Обратная связь о падении

Плагин SHALL независимо управлять HUD, звуком и ScreenFade после положительной фактической потери HP живым игроком.

#### Scenario: Показ урона включён

- **WHEN** `hns_falldown_show_dmg` равно `1`
- **THEN** живой пострадавший получает локализованный HUD с фактической потерей HP

#### Scenario: Звук включён

- **WHEN** `hns_falldown_play_sound` равно `1`
- **THEN** живому пострадавшему воспроизводится precache-звук `hns/falldown/1.wav`

#### Scenario: Затемнение включено

- **WHEN** `hns_falldown_fadescreen` равно `1`
- **THEN** живой пострадавший получает ScreenFade с `hns_falldown_fadescreen_r`, `hns_falldown_fadescreen_g`, `hns_falldown_fadescreen_b` и `hns_falldown_fadescreen_alpha`

#### Scenario: Падение не уменьшило HP

- **WHEN** post-hook вычислил нулевую или отрицательную потерю HP
- **THEN** HUD, звук, ScreenFade и autoheal не запускаются

#### Scenario: Падение смертельно

- **WHEN** после стандартного применения урона игрок больше не жив
- **THEN** HUD, звук, ScreenFade и autoheal не запускаются

### Requirement: Командный режим лечения

Плагин SHALL планировать лечение только живому игроку при `hns_autoheal = 1` и совпадении команды с `hns_autoheal_mode`.

#### Scenario: Режим команды разрешает лечение

- **WHEN** режим равен id команды живого пострадавшего или `3`
- **THEN** через `hns_autoheal_delay` планируется задача восстановления

#### Scenario: Режим не разрешает лечение

- **WHEN** режим не равен команде и не равен `3`
- **THEN** лечение не планируется

#### Scenario: Игрок погиб от падения

- **WHEN** post-hook выполняется для уже погибшего пострадавшего
- **THEN** задача восстановления не создаётся
