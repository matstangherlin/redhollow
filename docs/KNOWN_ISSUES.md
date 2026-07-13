# Red Hollow — Known Issues

Issues conhecidos após commit de baseline **`4babadc`** (2026-07-13, auditoria pós–world map / street art / visual PILOT).  
Classificação: **P0** bloqueia release beta ou produção artística final; **P1** corrigir antes de escalar conteúdo / ship; **P2** manutenção; **P3** cosmético/documentação.

## Gate beta (commit `4babadc`)

| Item | Status |
| --- | --- |
| Versão alvo | `0.2.0-beta.1` |
| Commit baseline | `4babadc9a1c16b838aba541f89c17d5c9174f21a` |
| Main scene | `res://scenes/product/main_menu.tscn` |
| Test runner | **23 suítes** em `test_runner.gd` |
| Bootstrap | `test_bootstrap.tscn` via `--main-scene` (autoloads carregados) |
| Gate automatizado | **23/23 PASS**, exit 0 (~51 s, 2026-07-13) |
| Playthrough menu→fim | **Pendente assinatura manual** (KI-004) |
| Produção artística final | **Bloqueada** — ver G1–G4 em `VISUAL_FOUNDATION_BASELINE.md` |
| Molde técnico visual | **Liberado** — ver `ART_VERTICAL_SLICE_GATE.md` |
| Export preset | Criado (`export_presets.cfg`) |
| Build gerada | Script existe; artefato **não versionado** |
| Build testada | **Não assinado** |
| Release QA-approved | **Não** |

---

## P0 — Bloqueadores

### KI-004 — Gate manual completo não assinado

- **Área:** QA / `VERTICAL_SLICE_TEST_PLAN.md`
- **Sintoma:** Checklist (menu → Capítulo Zero → conclusão) + stress tests não executados/assinados neste gate.
- **Impacto:** Não declarar beta **shippable** nem arte final **ready** só com runner verde.
- **Ação:** Playthrough humano obrigatório.

### KI-ART-G1 — Plataformas invisíveis em modo street art

- **Área:** `vertical_slice_street_art.tscn`, `StreetArtArea`
- **Sintoma:** `PlatformVisual` em `Solids/` oculto com arte ativa; rota elevada fica invisível.
- **Gate:** `ART_VERTICAL_SLICE_GATE.md` P0.
- **Bloqueia:** arte final da rua; **não bloqueia** molde técnico para igreja/catacumbas.

### KI-ART-G2 — Labels debug visíveis em modo art

- **Área:** rua art (`AreaLabel`, `TileHint`, `SecretLabel`, etc.)
- **Sintoma:** Poluição visual; viola Art Bible para build de gate.
- **Ação:** Flag `show_debug_labels` ou ocultar em release/gate.

---

## P1 — Corrigir antes de escalar conteúdo / ship beta

### KI-001 — Fluxo morte/respawn parcialmente consolidado

- **Área:** `RespawnService`, `player.gd`, `health_component.gd`
- **Estado no commit:** `RespawnService` commitado; auto-respawn ~0,65 s; tecla **R**; testes `player_respawn_tests` **6/6 PASS**.
- **Ainda ausente:** overlay de morte final, reset chefe documentado em todos cenários, playtest manual cenários 13–15.
- **Workaround:** **R**, **F7**, **F9**, **Esc** (panic unlock).
- **Classificação:** P1 até playtest manual completo.

### KI-002 — Spawn de inimigos na arena durante flush de física

- **Área:** `combat_arena_controller.gd` — `_spawn_configured_enemies` em `body_entered`
- **Sintoma:** Headless pode emitir `Can't change this state while flushing queries`.
- **Estado:** Erro **não corrigido** em produção; allowlist em `combat_arena_tests` (`living_enemy_despawned` integrity test).
- **Risco:** Possível instabilidade de colisão em runtime real; validação manual na arena da igreja.
- **Direção:** `call_deferred` para spawn ou ativação pós-frame.

### KI-006 — Fluxo product shell não validado manualmente

- **Área:** `main_menu.tscn`, boot, opções, pausa, créditos, loading, mapa (**M**)
- **Sintoma:** Infraestrutura e smoke headless passam; existência de cena **não prova** fluxo completo.
- **Ação:** Roteiro manual dedicado menu→greybox→menu.

---

## P2 — Manutenção

### KI-101 — Panic unlock (Esc) ainda ativo

- **Arquivos:** `game.gd`, `GameplayLockManager.enable_debug_panic_unlock`
- **Risco:** Mascara softlocks reais durante QA.

### KI-102 — Auto-load desativado na sessão de gameplay

- **Arquivo:** `game.gd` — `save_manager.auto_load_on_ready = false`
- **Intencional** na demo/greybox; beta exige decisão D-013 (`DECISIONS.md`).

### KI-103 — Controllers ainda usam `_player.call("_is_*")` internamente

- **Direção:** Expandir API pública tipada.

### KI-104 — Hitstop via grupo em `hitbox_component` / barreira

- **Direção:** Referência via `GameServices` ou sinal único.

### KI-105 — Debug overlay acoplado ao player (F)

- **Beta:** Desligável em release build.

### KI-106 — Build Windows não aprovada

- Preset + script existem; smoke test e playtest na build exportada **pendentes**.

### KI-107 — Vazamento de objetos no encerramento do runner

- **Sintoma:** Ao fim de `test_runner.gd`: `43 ObjectDB instances were leaked`, `6 resources still in use`.
- **Impacto:** Não bloqueia gate (exit 0); dívida de teardown em suítes com cenas montadas.
- **Direção:** `queue_free` / `free` explícito em fixtures; revisar `world_map_graph_tests`.

### KI-108 — Warnings de compilação no processo pai do runner

- **Sintoma:** Processo `test_runner.gd` emite erros `SettingsManager` / `InputDeviceManager` not found ao pré-carregar scripts (sem autoloads no processo pai).
- **Impacto:** Cosmético — subprocessos via bootstrap passam.
- **Direção:** Opcional — entrypoint do runner como cena com autoloads.

---

## P3 — Baixa prioridade

### KI-201 — Cenas legado `*_test.tscn` vs `vertical_slice_*`

- Consolidar nomenclatura quando áreas legadas forem aposentadas.

### KI-202 — Reconexão de controle / foco de janela

- Não implementado; stress test manual N/A.

### KI-203 — Warnings esperados em suítes de save/diálogo/feedback/visual

- Save corrompido, dialogue id ausente, integrity arena, camera target ausente, clip animação ausente — **injetados ou esperados** (allowlist).

---

## Resolvido / reclassificado (auditoria `4babadc`)

| Issue | Estado | Motivo |
| --- | --- | --- |
| **KI-005** — Runner headless FAIL (`--script` sem autoloads) | **Resolvido** | Bootstrap `--main-scene` + **23/23 PASS** (2026-07-13) |
| **KI-003** — Working tree não commitada | Resolvido (histórico) | Baseline `e07ba0e` commitada |
| `player_regression_tests` DEATH lock | **Corrigido** (auditoria) | Fixture `RespawnService` + `set_death_vulnerability` |
| `world_map_graph_tests` transição street→church | **Corrigido** (auditoria) | Flag `cz_met_elias` + timer curto |
| `street_art_toggle_tests` parse/hang | **Corrigido** (auditoria) | `_parallax(layer_name)` + testes offline |
| `modular_kit_tests` factory | **Corrigido** (auditoria) | Args `_add_module` alinhados em `environment_kit_factory.gd` |
| `player_visual_pipeline_tests` warning clip | **Corrigido** (auditoria) | Allowlist `missing animation clip` |
| 18 suítes (doc desatualizado) | **Corrigido** | Runner registra **23** suítes |
| Menu/pausa “inexistentes” | Reclassificado | Infra commitada; validação manual pendente (KI-006) |

**Correções de auditoria ainda não commitadas** — ver `git status` (7 scripts modificados).

Ver `STABILIZATION_REPORT.md`, `TEST_MATRIX.md`, `VISUAL_FOUNDATION_BASELINE.md`.
