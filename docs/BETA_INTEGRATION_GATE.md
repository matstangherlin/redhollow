# Beta Integration Gate — Red Hollow `0.2.0-beta.1`

**Data da execução:** 2026-07-12  
**Branch de trabalho:** `beta-foundation`  
**Main scene:** `res://scenes/product/main_menu.tscn`  
**Manifesto ativo:** `res://resources/content/manifests/beta_demo.tres`  
**Capítulo:** `chapter_zero_bell_before_nightfall` (Capítulo Zero)

---

## Veredito

### **PASS COM RESTRIÇÕES**

| Critério | Resultado |
| --- | --- |
| Smoke test de integração (`beta_integration_smoke_tests`) | **22/22 PASS** |
| Runner headless (20 suítes) | **19/20 PASS** |
| Playthrough manual menu → fim | **Não assinado** (P0) |
| Export Windows QA | **Não assinado** |

**Não é PASS pleno** porque permanecem bloqueadores P0 de assinatura manual (KI-004) e 1 falha automatizada em `player_regression_tests`.

---

## Escopo validado

Este gate verifica que os sistemas do commit atual funcionam **em conjunto** no perfil `beta_demo`, sem adicionar conteúdo, arte final ou inimigos novos.

### Fluxo principal (passos 1–29)

| # | Passo | Automação | Status |
| --- | --- | --- | --- |
| 1 | Abrir o jogo | Cena `main_menu.tscn` como main scene | **AUTO PASS** |
| 2 | Menu principal | Nós `NewGameButton`, `ContinueButton`, `OptionsButton` | **AUTO PASS** |
| 3 | Novo Jogo | `GameBootState.set_new_game()` / `consume_boot_mode()` | **AUTO PASS** |
| 4 | Confirmar novo jogo (save existente) | `ConfirmationDialog` presente | **AUTO PASS** |
| 5 | Loading screen | Cena `loading_screen.tscn` carrega | **AUTO PASS** |
| 6 | Manifesto `beta_demo` | `ContentRegistry.activate_from_path` | **AUTO PASS** |
| 7 | Capítulo Zero | `chapter_zero_bell_before_nightfall` resolvido | **AUTO PASS** |
| 8 | Iniciar na rua | `starting_area_id = vs_greybox_street` | **AUTO PASS** |
| 9 | Objetivo inicial | `cz_obj_opening` em objectives JSON | **AUTO PASS** |
| 10 | Conversar com Elias | Diálogo `cz_elias_opening` + evento `cz_evt_met_elias` | **AUTO PASS** (contrato) |
| 11 | Estátua | Evento `cz_evt_statue` + flag | **AUTO PASS** (contrato) |
| 12 | Pista do parceiro | Evento `cz_evt_partner_clue` | **AUTO PASS** (contrato) |
| 13 | Brawler | Cena `cult_brawler.tscn` + nó `CultBrawlerStreet` | **AUTO PASS** |
| 14 | Gunslinger | Cena `vermilite_gunslinger.tscn` + nó street | **AUTO PASS** |
| 15 | Brawler + Gunslinger | Nós `DuoBrawler` / `DuoGunslinger` | **AUTO PASS** (contrato cena) |
| 16 | Distrito da igreja | Área `vertical_slice_church.tscn` + transição | **AUTO PASS** |
| 17 | Chain Penitent | Cena + nó `ChainPenitentAlcove` | **AUTO PASS** |
| 18 | Arena combinada | `combat_arena.tscn` + `ChurchYardArena` | **AUTO PASS** (15/15 arena tests) |
| 19 | Red Brand | Nós `RedBrandCache` / `RedBrandPassage` | **AUTO PASS** (contrato cena) |
| 20 | Barreira | `red_barrier.tscn` + `CultRedBarrier` | **AUTO PASS** |
| 21 | Subterrâneo | `vertical_slice_underground.tscn` | **AUTO PASS** |
| 22 | Checkpoint | `vs_underground_checkpoint` no ChapterData | **AUTO PASS** (contrato) |
| 23 | Página do parceiro | Diálogo `cz_partner_diary_page` + evento | **AUTO PASS** (contrato) |
| 24 | Deacon Rusk | `deacon_rusk.tscn` + `boss_encounter.tscn` | **AUTO PASS** (7/7 boss tests) |
| 25 | Sequência final | `ChapterZeroFinale` (8 passos) | **AUTO PASS** (nó presente) |
| 26 | Encerramento beta | `CompletionOverlay` | **AUTO PASS** (nó presente) |
| 27 | Retornar ao menu | Pausa → Main Menu (cena presente) | **MANUAL** |
| 28 | Continuar por save | `SaveManager.inspect_slot` + boot CONTINUE | **AUTO PASS** (schema); **MANUAL** (sessão real) |
| 29 | Novo Jogo substituindo save | Confirmação + overwrite | **MANUAL** |

### Settings

| Item | Automação | Status |
| --- | --- | --- |
| Resolução | `SettingsData.video.resolution` | **AUTO PASS** |
| Fullscreen / windowed | `SettingsData.video.display_mode` | **AUTO PASS** |
| VSync | `SettingsData.video.vsync` | **AUTO PASS** |
| Volume (master + buses) | `SettingsData.audio.*` | **AUTO PASS** |
| Screen shake | `accessibility.screen_shake_intensity` | **AUTO PASS** |
| Flashes reduzidos | `accessibility.reduced_flashes` | **AUTO PASS** |
| Texto (speed / instant) | `accessibility.text_speed`, `instant_text` | **AUTO PASS** |
| Gamepad | `InputDeviceManager`, mapeamentos `InputSetup` | **AUTO PASS** (contrato) |
| Último dispositivo | `InputDeviceManager.last_device_kind` | **AUTO PASS** |
| Aplicação em runtime / UX opções | — | **MANUAL** |

### Pause

| Cenário | Automação | Status |
| --- | --- | --- |
| Ação `pause` no InputMap | Sim | **AUTO PASS** |
| `PauseMenu` no shell | Sim | **AUTO PASS** |
| Pausa na rua / combate / diálogo / hitstop / arena / boss | — | **MANUAL** |
| Retorno ao menu / retomada | Cena presente | **MANUAL** |

### Save

| Cenário | Suíte | Status |
| --- | --- | --- |
| Save válido | `save_tests`, `product_shell_tests` | **PASS** |
| Save ausente | `save_tests`, smoke test | **PASS** |
| Save corrompido | `save_tests` | **PASS** |
| Backup | `save_tests` | **PASS** |
| Checkpoint (schema + flag) | smoke + narrative | **PASS** (contrato) |
| Continuar | `product_shell_tests` inspect | **PASS**; sessão real **MANUAL** |
| Manifesto beta no save | smoke test | **PASS** |
| Flags narrativas | objectives/events JSON | **PASS** |
| Objetivos | `narrative_chapter_zero_tests` | **PASS** |
| Barreira (`destroyed_barriers`) | smoke save payload | **PASS** |
| Boss (`boss_vs_deacon_rusk_defeated`) | ChapterData + events | **PASS** |

---

## Automação executada

### Smoke test dedicado

```
RH_TEST_SUITE=res://scripts/demo/beta_integration_smoke_tests.gd
godot --headless --main-scene res://scenes/tests/test_bootstrap.tscn
```

**Resultado:** 22/22 assertions, exit 0.

Valida: menu, manifesto, ChapterData, IDs de objetivos/eventos, áreas, cenas de inimigos/chefe, finale, save beta, schema de settings, pause/boot.

### Runner headless (20 suítes)

Comando:

```powershell
.\tools\test_all.ps1
# ou
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

| Suíte | Resultado | Assertions |
| --- | --- | --- |
| `vertical_slice_verification` | PASS | 7/7 |
| `dialogue_tests` | PASS | 3/3 |
| `save_tests` | PASS | 5/5 |
| `area_transition_tests` | PASS | 6/6 |
| `combat_arena_tests` | PASS | 15/15 |
| `cult_brawler_tests` | PASS | 4/4 |
| `deacon_rusk_tests` | PASS | 7/7 |
| `gameplay_lock_tests` | PASS | 10/10 |
| `player_regression_tests` | **FAIL** | 47/48 |
| `vertical_slice_regression_tests` | PASS | 14/14 |
| `product_shell_tests` | PASS | 10/10 |
| `narrative_chapter_zero_tests` | PASS | 6/6 |
| `vermilite_gunslinger_tests` | PASS | 4/4 |
| `chain_penitent_tests` | PASS | 3/3 |
| `enemy_encounter_tests` | PASS | 4/4 |
| `player_visual_pipeline_tests` | PASS | 5/5 |
| `feedback_system_tests` | PASS | 6/6 |
| `player_respawn_tests` | PASS | 6/6 |
| `content_registry_tests` | PASS | 18/18 |
| `beta_integration_smoke_tests` | PASS | 22/22 |

**Total:** 19 PASS / 1 FAIL — exit code ≠ 0 no runner completo.

### Correções aplicadas durante o gate (infra de teste)

| Arquivo | Correção |
| --- | --- |
| `narrative_chapter_zero_tests.gd` | `root.queue_free()` → `test_root.queue_free()` (hang do runner) |
| `product_shell_tests.gd` | Allowlist `Parse JSON failed` no teste de save corrompido |
| `deacon_rusk_tests.gd` | `process_frame` → `TestHelpers.await_frames` (sessão anterior) |
| `beta_integration_smoke_tests.gd` | **Novo** — smoke de integração beta |
| `test_runner.gd` | Registro da suíte `beta_integration_smoke_tests` (20 suítes) |

---

## Bloqueadores (P0)

| ID | Bloqueador | Impacto |
| --- | --- | --- |
| **KI-004** | Playthrough manual menu → Capítulo Zero → finale **não assinado** | Impede declarar beta shippable |
| **KI-005 (parcial)** | `player_regression_tests` falha: `RespawnService` ausente no fixture de morte | Runner não fecha 20/20 |

---

## Bugs e restrições (P1–P2)

| ID | Severidade | Descrição |
| --- | --- | --- |
| **KI-001** | P1 | Morte/respawn: `RespawnService` existe mas `player_regression_tests` não monta o serviço no fixture isolado |
| **KI-006** | P1 | Fluxo product shell (menu → greybox → menu) não validado manualmente neste gate |
| **KI-106** | P2 | Build Windows exportada não QA-aprovada |
| **Gap** | P2 | `save_profile_id` do manifesto não usado — slot fixo `slot_01` |
| **KI-101** | P2 | Panic unlock (Esc) ativo em `game.gd` — pode mascarar softlocks no QA manual |

### Resolvido neste ciclo

| ID | Status |
| --- | --- |
| **KI-002** | Arena deferred spawn — `combat_arena_tests` 15/15, zero physics flush |

---

## Artefatos

| Documento | Uso |
| --- | --- |
| `docs/MANUAL_PLAYTHROUGH_CHECKLIST.md` | Roteiro humano obrigatório para fechar KI-004 |
| `docs/TEST_MATRIX.md` | Matriz geral de testes |
| `docs/VERTICAL_SLICE_TEST_PLAN.md` | Plano da vertical slice |

---

## Próximo passo para PASS pleno

1. Executar e assinar `MANUAL_PLAYTHROUGH_CHECKLIST.md`.
2. Corrigir fixture de `player_regression_tests` para montar `RespawnService` (ou allowlist documentada se intencional).
3. Fechar runner **20/20** exit 0.
4. Smoke test em build exportada Windows (opcional mas recomendado para KI-106).
