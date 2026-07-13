# Red Hollow — Test Matrix

Matriz de testes manuais e headless. Roteiro: [VERTICAL_SLICE_TEST_PLAN.md](VERTICAL_SLICE_TEST_PLAN.md). Runner: [HEADLESS_TESTING.md](HEADLESS_TESTING.md). Gate: [STABILIZATION_REPORT.md](STABILIZATION_REPORT.md).

**Baseline commit (auditoria):** `4babadc9a1c16b838aba541f89c17d5c9174f21a` (`4babadc`)

## Legenda

| Resultado | Significado |
| --- | --- |
| **Pass** | Comportamento correto |
| **Fail** | Comportamento incorreto |
| **Blocked** | Erro impede teste |
| **Pending** | Não executado neste gate |
| **N/A** | Não aplicável |

---

## Gate automatizado (auditoria `4babadc`, 2026-07-13)

### Resumo

| Métrica | Resultado |
| --- | --- |
| Suítes registradas | **23** |
| Comando | `godot --headless --path . --script res://scripts/tests/test_runner.gd` |
| Invocação suítes | Bootstrap `--main-scene` + `-- res://…suite.gd` |
| Timeout padrão | 180 s (`player_regression_tests`: 300 s) |
| Exit timeout | 124 |
| Gate | **PASS** (exit code 0) |
| PASS | **23 / 23** |
| FAIL | **0** |
| Tempo total | ~51 s |
| Unexpected issues | 0 |
| Allowed issues | 13 |

### Suítes (23)

| # | Suíte | Script | Resultado | Asserts |
| --- | --- | --- | --- | --- |
| 1 | vertical_slice_verification | `scripts/demo/vertical_slice_verification.gd` | **PASS** | 7 |
| 2 | dialogue_tests | `scripts/dialogue/dialogue_tests.gd` | **PASS** | 3 |
| 3 | save_tests | `scripts/save/save_tests.gd` | **PASS** | 5 |
| 4 | area_transition_tests | `scripts/world/area_transition_tests.gd` | **PASS** | 6 |
| 5 | combat_arena_tests | `scripts/world/combat_arena_tests.gd` | **PASS** | 15 |
| 6 | cult_brawler_tests | `scripts/enemies/cult_brawler_tests.gd` | **PASS** | 4 |
| 7 | deacon_rusk_tests | `scripts/enemies/deacon_rusk_tests.gd` | **PASS** | 7 |
| 8 | gameplay_lock_tests | `scripts/core/gameplay_lock_tests.gd` | **PASS** | 10 |
| 9 | player_regression_tests | `scripts/player/player_regression_tests.gd` | **PASS** | 48 |
| 10 | vertical_slice_regression_tests | `scripts/demo/vertical_slice_regression_tests.gd` | **PASS** | 14 |
| 11 | product_shell_tests | `scripts/product/product_shell_tests.gd` | **PASS** | 10 |
| 12 | narrative_chapter_zero_tests | `scripts/narrative/narrative_chapter_zero_tests.gd` | **PASS** | 6 |
| 13 | vermilite_gunslinger_tests | `scripts/enemies/vermilite_gunslinger_tests.gd` | **PASS** | 4 |
| 14 | chain_penitent_tests | `scripts/enemies/chain_penitent_tests.gd` | **PASS** | 3 |
| 15 | enemy_encounter_tests | `scripts/demo/enemy_encounter_tests.gd` | **PASS** | 4 |
| 16 | player_visual_pipeline_tests | `scripts/visual/player_visual_pipeline_tests.gd` | **PASS** | 8 |
| 17 | feedback_system_tests | `scripts/feedback/feedback_system_tests.gd` | **PASS** | 6 |
| 18 | player_respawn_tests | `scripts/player/player_respawn_tests.gd` | **PASS** | 6 |
| 19 | content_registry_tests | `scripts/content/content_registry_tests.gd` | **PASS** | 18 |
| 20 | beta_integration_smoke_tests | `scripts/demo/beta_integration_smoke_tests.gd` | **PASS** | 22 |
| 21 | street_art_toggle_tests | `scripts/visual/street_art_toggle_tests.gd` | **PASS** | 4 |
| 22 | modular_kit_tests | `scripts/environment/modular_kit_tests.gd` | **PASS** | 7 |
| 23 | world_map_graph_tests | `scripts/world/world_map_graph_tests.gd` | **PASS** | 10 |

**Suítes novas vs `e07ba0e`:** 18–23 (respawn, smoke beta, street art, modular kit, world map).

### Comandos

```powershell
.\tools\test_all.ps1
```

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

Suíte isolada:

```powershell
& "C:\Path\To\Godot_v4.7-stable_win64.exe" --headless --path . `
  --main-scene res://scenes/tests/test_bootstrap.tscn -- res://scripts/world/world_map_graph_tests.gd
```

### Warnings / errors permitidos (allowlist)

| Suíte | Tipo | Motivo |
| --- | --- | --- |
| `dialogue_tests` | WARNING | `missing_dialogue_id` injetado |
| `save_tests` | ERROR/WARNING | JSON corrompido / backup recovery injetado |
| `product_shell_tests` | ERROR | JSON corrompido em `inspect_slot` |
| `combat_arena_tests` | ERROR | `living_enemy_despawned` (integrity test) |
| `feedback_system_tests` | WARNING | `CameraController target was not found` |
| `player_visual_pipeline_tests` | WARNING | `missing animation clip` (fallback test) |

### Warnings P2 (não falham gate)

| Origem | Motivo |
| --- | --- |
| Fim do `test_runner.gd` | ObjectDB leaks / resources in use (KI-107) |
| Processo pai do runner | Compile errors autoloads (KI-108) — cosmético |

---

## Manual — product shell + Capítulo Zero

| # | Passo | Auto | Gate manual |
| --- | --- | --- | --- |
| 0 | Boot → main menu | product_shell PASS | **Pending** |
| 0b | Opções / créditos / novo jogo / continuar | smoke beta parcial | **Pending** |
| 1 | Rua — Elias, estátua, medalhão, brawler | narrative + regression PASS | **Pending** |
| 2 | Objetivo HUD | narrative PASS | **Pending** |
| 3 | Igreja — arena, documento, Vermilite | combat_arena PASS | **Pending** |
| 4 | Barreira → catacumbas | area_transition PASS | **Pending** |
| 5 | Checkpoint → diário parceiro | narrative flags | **Pending** |
| 6 | Deacon Rusk — `cz_deacon_intro` | deacon_rusk PASS | **Pending** |
| 7 | Finale 8 passos | smoke beta parcial | **Pending** |
| 8 | Conclusão beta / overlay | completion controller | **Pending** |
| 9 | Pausa in-game | — | **Pending** |
| 10 | Mapa mundo (**M**) + descoberta | world_map_graph PASS | **Pending** |
| 11 | Greybox ↔ street art toggle | street_art_toggle PASS | **Pending** |
| 13 | Morte pré-checkpoint | player_respawn PASS | **Pending** |
| 14 | Morte pós-checkpoint | player_respawn PASS | **Pending** |
| 15 | Morte no boss | — | **Pending** |
| 16–20 | Save/load/reboot | save_tests PASS | **Pending** |

### Build Windows

| Etapa | Auto | Manual |
| --- | --- | --- |
| Export preset existe | N/A | Verificado no repo |
| `build_windows.ps1` | N/A | **Pending** execução |
| Smoke na `.exe` | N/A | **Pending** |
| QA-approved build | N/A | **Não** |

---

## Estado dos sistemas (commit `4babadc`)

| Sistema | Estado | Notas |
| --- | --- | --- |
| Main scene menu | Integração concluída | `main_menu.tscn` |
| Gameplay greybox | Integração concluída | Via boot; rua art paralela |
| Autoloads product | OK | Bootstrap carrega no runner |
| World map + descoberta | Integração concluída | Overlay provisório |
| RespawnService | Integração concluída | 6 testes |
| Street art molde | Integração concluída | 4 testes |
| Kit modular | Integração concluída | 7 testes |
| 23 suítes runner | **PASS** | Exit 0 |
| Auto-load boot | **Desativado** | `auto_load_on_ready = false` |
| Pixel art / mapa / diário final | Planejado beta | Overlay grafo provisório |

---

## Documentos relacionados

`VERTICAL_SLICE_TEST_PLAN.md`, `BETA_DEMO_SCOPE.md`, `TECH_DEBT.md`, `KNOWN_ISSUES.md`, `STABILIZATION_REPORT.md`, `VISUAL_FOUNDATION_BASELINE.md`, `HEADLESS_TESTING.md`
