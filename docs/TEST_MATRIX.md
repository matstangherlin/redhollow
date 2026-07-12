# Red Hollow — Test Matrix

Matriz de testes manuais e headless. Roteiro: [VERTICAL_SLICE_TEST_PLAN.md](VERTICAL_SLICE_TEST_PLAN.md). Runner: [HEADLESS_TESTING.md](HEADLESS_TESTING.md). Gate: [STABILIZATION_REPORT.md](STABILIZATION_REPORT.md).

**Baseline commit:** `e07ba0ecb8502d7a368017f1764599155e3e87bf`

## Legenda

| Resultado | Significado |
| --- | --- |
| **Pass** | Comportamento correto |
| **Fail** | Comportamento incorreto |
| **Blocked** | Erro impede teste |
| **Pending** | Não executado neste gate |
| **N/A** | Não aplicável |

---

## Gate automatizado (commit `e07ba0e`)

### Resumo

| Métrica | Resultado |
| --- | --- |
| Suítes registradas | **18** |
| Comando | `godot --headless --path . --script res://scripts/tests/test_runner.gd` |
| Invocação suítes | Subprocesso `--script` |
| Gate | **FAIL** (exit code 1) |
| PASS estimado | **~8 / 18** |
| FAIL estimado | **~10 / 18** |
| Causa | Autoloads ausentes no subprocesso (KI-005) |

### Suítes (18)

| Suíte | Script | Tendência commit | Notas |
| --- | --- | --- | --- |
| vertical_slice_verification | `scripts/demo/vertical_slice_verification.gd` | FAIL | Valida autoloads + demo |
| dialogue_tests | `scripts/dialogue/dialogue_tests.gd` | FAIL | Monta player + diálogo |
| save_tests | `scripts/save/save_tests.gd` | **PASS** | |
| area_transition_tests | `scripts/world/area_transition_tests.gd` | FAIL | Monta player |
| combat_arena_tests | `scripts/world/combat_arena_tests.gd` | FAIL | Arena + player |
| cult_brawler_tests | `scripts/enemies/cult_brawler_tests.gd` | FAIL | Monta player |
| deacon_rusk_tests | `scripts/enemies/deacon_rusk_tests.gd` | FAIL | Monta player |
| gameplay_lock_tests | `scripts/core/gameplay_lock_tests.gd` | FAIL | Monta player |
| player_regression_tests | `scripts/player/player_regression_tests.gd` | FAIL | 48 assertions |
| vertical_slice_regression_tests | `scripts/demo/vertical_slice_regression_tests.gd` | **PASS** | |
| product_shell_tests | `scripts/product/product_shell_tests.gd` | FAIL | `GameBootState` global |
| narrative_chapter_zero_tests | `scripts/narrative/narrative_chapter_zero_tests.gd` | FAIL | Monta demo |
| vermilite_gunslinger_tests | `scripts/enemies/vermilite_gunslinger_tests.gd` | **PASS** | |
| chain_penitent_tests | `scripts/enemies/chain_penitent_tests.gd` | **PASS** | |
| enemy_encounter_tests | `scripts/demo/enemy_encounter_tests.gd` | **PASS** | |
| player_visual_pipeline_tests | `scripts/visual/player_visual_pipeline_tests.gd` | **PASS** | |
| feedback_system_tests | `scripts/feedback/feedback_system_tests.gd` | **PASS** | |
| content_registry_tests | `scripts/content/content_registry_tests.gd` | **PASS** | |

**Meta pós-estabilização:** 18/18 PASS, exit 0, 0 unexpected issues.

### Comandos

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

Windows:

```powershell
& "C:\Path\To\Godot_v4.7-stable_win64.exe" --headless --path . --script res://scripts/tests/test_runner.gd
```

Após adicionar `class_name`:

```bash
godot --headless --path . --import
```

### Warnings / errors permitidos (allowlist)

Válidos quando a suíte **executa até o fim**:

| Suíte | Tipo | Motivo |
| --- | --- | --- |
| dialogue_tests | WARNING | `missing_dialogue_id` injetado |
| save_tests | ERROR/WARNING | JSON corrompido / backup recovery |
| combat_arena_tests | ERROR | Physics flush (`Can't change this state while flushing queries`) |

---

## Manual — product shell + Capítulo Zero

| # | Passo | Auto parcial | Gate manual |
| --- | --- | --- | --- |
| 0 | Boot → main menu | product_shell (runner fail) | **Pending** |
| 0b | Opções / créditos / novo jogo | — | **Pending** |
| 1 | Rua — Elias, estátua, medalhão, brawler | narrative + regression parcial | **Pending** |
| 2 | Objetivo HUD | narrative (runner fail) | **Pending** |
| 3 | Igreja — arena, documento, Vermilite | regression nós | **Pending** |
| 4 | Barreira → catacumbas | area_transition (runner fail) | **Pending** |
| 5 | Checkpoint → diário parceiro | narrative flags | **Pending** |
| 6 | Deacon Rusk — `cz_deacon_intro` | deacon_rusk (runner fail) | **Pending** |
| 7 | Finale 8 passos | manual | **Pending** |
| 8 | Conclusão beta / overlay | completion controller | **Pending** |
| 9 | Pausa in-game | — | **Pending** |
| 13 | Morte pré-checkpoint | death lock (runner fail) | **Pending** |
| 14 | Morte pós-checkpoint | auto-respawn parcial | **Pending** |
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

## Estado dos sistemas (commit `e07ba0e`)

| Sistema | Estado | Notas |
| --- | --- | --- |
| Main scene menu | Infra criada | `main_menu.tscn` |
| Gameplay greybox | Integração concluída | Via boot |
| Autoloads product | OK runtime normal | Falham no runner `--script` |
| ContentRegistry | Integração concluída | Teste auto PASS |
| 18 suítes runner | Infra criada | Gate FAIL |
| Auto-load boot | **Desativado** | `auto_load_on_ready = false` |
| Pixel art / mapa / diário final | Planejado beta | HUD objetivo provisório |

---

## Documentos relacionados

`VERTICAL_SLICE_TEST_PLAN.md`, `BETA_DEMO_SCOPE.md`, `TECH_DEBT.md`, `KNOWN_ISSUES.md`, `STABILIZATION_REPORT.md`, `HEADLESS_TESTING.md`
