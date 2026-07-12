# Red Hollow — Known Issues

Issues conhecidos após commit de baseline beta **`e07ba0e`** (2026-07-11).  
Classificação: **P0** bloqueia release beta; **P1** corrigir antes de escalar conteúdo / ship; **P2** manutenção; **P3** cosmético/documentação.

## Gate beta (commit `e07ba0e`)

| Item | Status |
| --- | --- |
| Versão alvo | `0.2.0-beta.1` |
| Commit baseline | `e07ba0ecb8502d7a368017f1764599155e3e87bf` |
| Main scene | `res://scenes/product/main_menu.tscn` |
| Test runner | **18 suítes** registradas em `test_runner.gd` |
| Gate automatizado (`--script` subprocess) | **~8 PASS / ~10 FAIL** — ver KI-005 |
| Playthrough menu→fim | **Pendente assinatura manual** (KI-004) |
| Export preset | Criado (`export_presets.cfg`) |
| Build gerada | Script existe; artefato **não versionado** |
| Build testada | **Não assinado** |
| Release QA-approved | **Não** |

---

## P0 — Bloqueadores de release beta

### KI-005 — Runner headless falha em subprocessos `--script` (autoloads ausentes)

- **Área:** `test_runner.gd`, suítes que instanciam `player.tscn`, `dialogue_system`, shell
- **Sintoma:** Com `--headless --path . --script res://…` como entrypoint do subprocesso, Godot **não** carrega autoloads (`SettingsManager`, `GameBootState`, `InputDeviceManager`, `InputSetup`). Scripts de produção que referenciam esses globals falham compilação/runtime no subprocesso.
- **Impacto:** Gate automatizado **não passa** no commit atual; exit code ≠ 0.
- **Suítes que tendem a passar** (sem dependência de autoload/player completo): `save_tests`, `vertical_slice_regression_tests`, `vermilite_gunslinger_tests`, `chain_penitent_tests`, `enemy_encounter_tests`, `player_visual_pipeline_tests`, `feedback_system_tests`, `content_registry_tests`.
- **Suítes que tendem a falhar:** demais 10, incluindo `player_regression_tests`, `dialogue_tests`, `product_shell_tests`, `narrative_chapter_zero_tests`, etc.
- **Mitigação atual:** Validar gameplay na **build exportada** + checklist manual; não declarar beta shippable só com runner verde.
- **Direção:** Executar suítes via `test_bootstrap.tscn` (`--main-scene`) com autoloads carregados; meta 18/18 PASS, exit 0.

---

## P1 — Corrigir antes de escalar conteúdo / ship beta

### KI-001 — Fluxo morte/respawn parcialmente endereçado (não consolidado)

- **Área:** `player.gd`, `health_component.gd`, locks
- **Estado no commit:** Existe **auto-respawn** após ~0,65 s (`DEATH_RESPAWN_DELAY`) e tecla **R** para forçar respawn se morto.
- **Ainda ausente:** serviço unificado (overlay, reset HUD/chefe, fluxo checkpoint automático documentado, cenários morte no boss).
- **Workaround:** **R**, **F7**, **F9**, **Esc** (panic unlock).
- **Cobertura auto:** death lock em `player_regression_tests` / `gameplay_lock_tests` — **indisponível no runner `--script` atual**.
- **Manual pendente:** cenários 13–15 do gate (morte antes/depois checkpoint, morte no boss).
- **Classificação:** P1 até playtest manual + serviço respawn unificado.

### KI-002 — Spawn de inimigos na arena durante flush de física

- **Área:** `combat_arena_controller.gd` — `_spawn_configured_enemies` em `body_entered`
- **Sintoma:** Headless emite `Can't change this state while flushing queries` (dezenas de ocorrências **permitidas** em `combat_arena_tests` quando runner executa).
- **Estado no commit:** Erro **não corrigido** em produção; allowlist documentada.
- **Risco:** Possível instabilidade de colisão em runtime real; requer validação manual na arena da igreja.
- **Direção:** `call_deferred` para spawn ou ativação pós-frame.

### KI-004 — Gate manual completo não assinado

- **Área:** QA / `VERTICAL_SLICE_TEST_PLAN.md`
- **Sintoma:** Checklist (menu → Capítulo Zero → conclusão) + stress tests não executados/assinados neste gate.
- **Ação:** Playthrough humano obrigatório antes de declarar beta **shippable**.

### KI-006 — Fluxo product shell não validado manualmente

- **Área:** `main_menu.tscn`, boot, opções, pausa, créditos, loading
- **Sintoma:** Infraestrutura commitada; existência de cena **não prova** fluxo completo (novo jogo, continuar, voltar ao menu, pausa in-game).
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

- **Arquivos:** `player_*_controller.gd`
- **Direção:** Expandir API pública tipada.

### KI-104 — Hitstop via grupo em `hitbox_component` / barreira

- **Direção:** Referência via `GameServices` ou sinal único.

### KI-105 — Debug overlay acoplado ao player (F)

- **Beta:** Desligável em release build.

### KI-106 — Build Windows não aprovada

- Preset + script existem; smoke test e playtest na build exportada **pendentes**.

---

## P3 — Baixa prioridade

### KI-201 — Cenas legado `*_test.tscn` vs `vertical_slice_*`

- Consolidar nomenclatura quando áreas legadas forem aposentadas.

### KI-202 — Reconexão de controle / foco de janela

- Não implementado; stress test manual N/A.

### KI-203 — Warnings esperados em suítes de save/diálogo

- Save corrompido e dialogue id ausente são **injetados** pelos testes (allowlist).

---

## Resolvido / reclassificado (commit `e07ba0e`)

| Issue | Estado | Motivo |
| --- | --- | --- |
| **KI-003** — Working tree não commitada | **Resolvido** | Baseline `e07ba0e` commitada (product shell, content registry, Cap. Zero, inimigos, feedback) |
| SaveManager paths internos | Resolvido | `export_save_state` / `PlayerStateSnapshot` |
| StyleManager HUD rígido | Resolvido | `bind_style_hud()` opcional |
| AreaTransition rebinding | Resolvido | `GameServices.on_area_loaded` |
| Arena fail-safe silencioso | Resolvido | `arena_integrity_failed` |
| Menu/pausa “inexistentes” | **Reclassificado** | Infra commitada; validação manual pendente (KI-006) |
| 17 suítes (doc desatualizado) | **Corrigido** | Runner registra **18** suítes |

Ver `STABILIZATION_REPORT.md`, `TEST_MATRIX.md`.
