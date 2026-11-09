# Spec Delta

## MODIFIED Requirements

### Requirement: Целевая платформа

Проект SHALL оставаться Pawn-плагином для Counter-Strike 1.6 и компилироваться официальным `amxxpc` AMX Mod X 1.10 со стандартными include `amxmodx`, `fakemeta`, `hamsandwich`, `fun`, `cstrike`. DHUD natives SHALL использовать объявления из `amxmodx.inc` без зависимости от legacy `dhudmessage.inc`.

#### Scenario: Чистая сборка

- **WHEN** `src/scripting/hns.sma` компилируется AMX Mod X 1.10 с официальными include
- **THEN** создаётся loadable `.amxx` без обязательной зависимости от ReAPI, ReHLDS или сторонних include

#### Scenario: Сборка официальным release toolchain

- **WHEN** исходник компилируется base+cstrike-пакетами официального AMX Mod X 1.10.0.5487
- **THEN** компиляция не требует отсутствующего в этих пакетах `dhudmessage.inc`
