# Red Hollow — Test Matrix

Matriz auditada para o baseline `4f20f76e5f505f36eacdb9866d7d7e33404c15f3` (`main`, 2026-07-13).

Runner: `scripts/tests/test_runner.gd`
Bootstrap de suítes: `res://scenes/tests/test_bootstrap.tscn`
Godot: 4.7

## Resultado geral

| Métrica | Resultado |
| --- | --- |
| Entradas contadas diretamente em `SUITES` | **30** |
| PASS | **19** |
| FAIL | **10** |
| TIMEOUT | **1** |
| Unexpected issues parsed | **23** |
| Allowed issues parsed | **13** |
| Gate | **FAIL** |
| Exit do runner completo | Não retornou; travou em `region_visual_tests` |
| Exit externo do timeout | 124 |
| Duração runner completo | >300 s antes de interrupção controlada |
| Physics flush errors | **0** |

O wrapper `.\tools\test_all.ps1` foi bloqueado pela Execution Policy local. A auditoria usou a invocação portável documentada com o Godot 4.7.

## As 30 suítes

| # | Suíte | Asserts | Unexpected | Allowed | Estado |
| ---: | --- | ---: | ---: | ---: | --- |
| 1 | `vertical_slice_verification` | 5/7 | 4 | 0 | **FAIL** |
| 2 | `dialogue_tests` | 3/3 | 0 | 2 | PASS |
| 3 | `save_tests` | 5/5 | 0 | 7 | PASS |
| 4 | `area_transition_tests` | 6/6 | 0 | 0 | PASS |
| 5 | `combat_arena_tests` | 22/22 | 0 | 1 | PASS |
| 6 | `cult_brawler_tests` | 4/4 | 0 | 0 | PASS |
| 7 | `deacon_rusk_tests` | 7/7 | 0 | 0 | PASS |
| 8 | `gameplay_lock_tests` | 10/10 | 0 | 0 | PASS |
| 9 | `player_regression_tests` | 49/49 | 0 | 0 | PASS |
| 10 | `vertical_slice_regression_tests` | 12/14 | 4 | 0 | **FAIL** |
| 11 | `product_shell_tests` | 10/10 | 0 | 1 | PASS |
| 12 | `narrative_chapter_zero_tests` | 6/6 | 4 | 0 | **FAIL** |
| 13 | `vermilite_gunslinger_tests` | 4/4 | 0 | 0 | PASS |
| 14 | `chain_penitent_tests` | 3/3 | 0 | 0 | PASS |
| 15 | `enemy_encounter_tests` | 6/6 | 0 | 0 | PASS |
| 16 | `player_visual_pipeline_tests` | 8/8 | 0 | 1 | PASS |
| 17 | `calder_asset_validation_tests` | 6/6 | 0 | 0 | PASS |
| 18 | `cult_brawler_asset_validation_tests` | 6/6 | 0 | 0 | PASS |
| 19 | `cult_brawler_visual_tests` | 6/6 | 0 | 0 | PASS |
| 20 | `feedback_system_tests` | 10/10 | 0 | 1 | PASS |
| 21 | `player_respawn_tests` | 8/8 | 0 | 0 | PASS |
| 22 | `content_registry_tests` | 17/18 | 0 | 0 | **FAIL** |
| 23 | `beta_integration_smoke_tests` | 22/22 | 4 | 0 | **FAIL** |
| 24 | `street_art_toggle_tests` | 4/5 | 1 | 0 | **FAIL** |
| 25 | `street_beta_complete_tests` | 5/5 | 2 | 0 | **FAIL** |
| 26 | `church_beta_complete_tests` | 5/6 | 1 | 0 | **FAIL** |
| 27 | `underground_beta_complete_tests` | 5/6 | 2 | 0 | **FAIL** |
| 28 | `region_visual_tests` | não iniciou | parse/bootstrap | 0 | **TIMEOUT 60 s** |
| 29 | `modular_kit_tests` | 7/7 | 0 | 0 | PASS isolado |
| 30 | `world_map_graph_tests` | 9/10 | 1 | 0 | **FAIL** |

## Falhas detalhadas

### `vertical_slice_verification`

- exit 1;
- 2 asserções ainda exigem `vertical_slice_church.tscn`;
- a integração atual aponta para `vertical_slice_church_art.tscn`.

### `vertical_slice_regression_tests`

- exit 1;
- retorno igreja→rua e catacumbas→igreja ainda esperam cenas greybox;
- a suíte crítica foi executada separadamente e reproduziu a falha.

### `content_registry_tests`

- exit 1;
- falha `street scene allowed`;
- manifest/registry/teste precisam concordar com a rua North Star canônica.

### `world_map_graph_tests`

- exit 1;
- `Area not available in this build`;
- `Transition street -> church failed`;
- 1 warning inesperado;
- teardown reportou 43 objetos e 6 resources ainda ativos.

### Pipeline visual / `region_visual_tests`

- `region_visual_controller.gd` falha ao inferir os tipos de `blend_duration` e `base`;
- `region_visual_tests.gd` falha ao inferir `profile`;
- o bootstrap não instancia uma suíte válida e permanece aberto;
- timeout isolado controlado em 60 s, exit externo 124;
- as falhas se propagam às apresentações art e explicam as suítes visuais/narrativas vermelhas;
- `modular_kit_tests` passou isoladamente 7/7 em 0,22 s.

## Suítes críticas exigidas

| Suíte | Exit | Tempo de parede | Resultado |
| --- | ---: | ---: | --- |
| `area_transition_tests` | 0 | 0,51 s | PASS |
| `combat_arena_tests` | 0 | 13,11 s | PASS 22/22 |
| `player_respawn_tests` | 0 | 2,27 s | PASS 8/8 |
| `vertical_slice_regression_tests` | 1 | 1,65 s | **FAIL** |
| `street_beta_complete_tests` | 1 | 0,49 s | **FAIL visual** |
| `church_beta_complete_tests` | 1 | 0,49 s | **FAIL visual** |
| `underground_beta_complete_tests` | 1 | 0,38 s | **FAIL visual** |
| `beta_integration_smoke_tests` | 1 | 2,05 s | **FAIL visual** |
| `player_visual_pipeline_tests` | 0 | 0,15 s | PASS |
| `calder_asset_validation_tests` | 0 | 0,03 s | PASS |
| `cult_brawler_visual_tests` | 0 | 0,28 s | PASS |
| `region_visual_tests` | 124 externo | 60 s | **TIMEOUT após parse** |
| `world_map_graph_tests` | 1 | 0,25 s | **FAIL + leaks** |

**Resumo atual:** 6 PASS, 6 FAIL, 1 TIMEOUT. O subconjunto de arena (`combat_arena`, `player_respawn`, `enemy_encounter`, `deacon_rusk`) passou integralmente.

## Catacumbas — regressão de crash

| Caso | Automação | Estado |
| --- | --- | --- |
| Cena carrega | carga direta + suíte dedicada | PASS |
| `UndergroundArtArea` entra na árvore | `underground_beta_complete_tests` | PASS |
| Apresentação deferred aparece | espera 3 frames + `get_art_presentation()` | PASS |
| Checkpoint | node contract | PASS |
| Deacon Rusk + encounter | node contract | PASS |
| Exit para igreja art | target contract | PASS |
| Hooks do finale | presentation contract | PASS |
| Sem NodePath/crash | carga direta, exit 0 | PASS |
| Negative control sem apresentação | sonda temporária, exit 1 esperado | PASS |

## Warnings e erros permitidos

| Suíte | Quantidade | Motivo |
| --- | ---: | --- |
| `dialogue_tests` | 2 | diálogo ausente injetado |
| `save_tests` | 7 | corrupção/backup de save injetados |
| `combat_arena_tests` | 1 | despawn de inimigo no teste de integridade |
| `product_shell_tests` | 1 | slot corrompido injetado |
| `player_visual_pipeline_tests` | 1 | fallback de animação ausente |
| `feedback_system_tests` | 1 | câmera sem target no fixture |

Novas mensagens não devem ser adicionadas à allowlist sem causa e asserção explícitas.

## Matriz manual

| Fluxo | Estado |
| --- | --- |
| Boot → menu → novo jogo | Pending |
| Opções, créditos, pausa | Pending |
| Rua North Star completa | Pending |
| Igreja North Star + arena | Pending — automação 22/22; playtest visual interrompido por entrada local |
| Catacumbas + checkpoint + Rusk | Pending — boss/respawn 8/8; apresentação art bloqueada por KI-115 |
| Finale de 8 passos | Pending |
| Mapa e backtracking | Pending |
| Morte antes/depois do checkpoint e no boss | Pending |
| F8/F9 + reboot | Pending |
| Gamepad | Pending |
| Performance 60 FPS / frame time / draw calls | Pending |
| Build Windows de `4f20f76` | Pending |
| Retorno ao menu após conclusão | Pending |

## Critério para próximo gate

O gate só pode ser marcado PASS quando:

1. todas as 30 suítes encerram;
2. PASS 30/30;
3. unexpected issues = 0;
4. nenhum timeout;
5. exit code final = 0;
6. playthrough e build forem validados separadamente.
