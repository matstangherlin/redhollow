# Red Hollow — Known Issues

Issues conhecidos após gate de estabilização (2026-07-11). Classificação: **P0** bloqueia release beta; **P1** corrigir antes de escalar conteúdo; **P2** manutenção; **P3** cosmético/documentação.

## Gate build local beta (2026-07-11)

| Item | Status |
| --- | --- |
| Versão alvo | `0.2.0-beta.1` |
| Commit base documentado | `1c8e89d` (+ working tree extensa não commitada) |
| Test runner 17 suítes | **7 PASS / 10 FAIL** (headless `--script`) |
| Release QA-approved | **Não** — ver KI-005, KI-004 |
| Playthrough menu→fim | **Pendente assinatura manual** |
| Export presets | `export_presets.cfg` criado |

## P0 — Bloqueadores de release beta

### KI-005 — Test runner headless falha em subprocess (10/17 suítes)

- **Área:** `test_runner.gd`, suítes que instanciam `player.tscn`
- **Sintoma:** Autoloads (`SettingsManager`, `InputDeviceManager`) não disponíveis quando Godot executa `--script` como entrypoint; compilação de `player.gd` falha em subprocess.
- **Impacto:** Gate automatizado **não** passa; **não** marcar release como aprovada só com runner verde.
- **Mitigação:** Validar na **build exportada** + checklist manual; suítes isoladas que não montam player passam (save, gunslinger, chain, encounters, visual, feedback).
- **Direção:** Bootstrapping de autoloads no runner ou ProjectSettings em test harness dedicado.

*Nenhum outro P0 gameplay confirmado na build exportada neste gate.*

## P1 — Corrigir antes de escalar conteúdo / ship beta

### KI-001 — Fluxo morte/respawn não consolidado

- **Área:** Player, `health_component.gd`, locks
- **Sintoma:** Morte aplica lock `DEATH` e interrompe combate; não há serviço único de respawn (checkpoint automático, overlay, reset de HUD/chefe).
- **Workaround:** **R** (spawn), **F7** (reset demo), **F9** (load), **Esc** (panic unlock).
- **Cobertura auto:** `player_regression_tests` (death lock), `gameplay_lock_tests` (morte durante hitstop).
- **Manual pendente:** cenários 13–15 do gate (morte antes/depois checkpoint, morte no boss).

### KI-002 — Spawn de inimigos na arena durante flush de física

- **Área:** `combat_arena_controller.gd` — `_spawn_configured_enemies` em `body_entered`
- **Sintoma:** Headless emite `Can't change this state while flushing queries` (36 ocorrências **permitidas** em `combat_arena_tests`).
- **Risco:** Possível instabilidade de colisão em runtime real; requer validação manual na arena da igreja.
- **Direção:** `call_deferred` para spawn ou ativação pós-frame.

### KI-003 — Working tree com refatoração não commitada

- **Área:** Git — controllers player, `GameServices`, acoplamentos
- **Sintoma:** Último commit `1c8e89d` (input/movimento); demais refatorações só local.
- **Risco:** Baseline de equipe divergente; regressão difícil de rastrear.
- **Ação:** Commit + tag de gate antes de iniciar produção artística em paralelo.

### KI-004 — Gate manual completo não assinado

- **Área:** QA / `VERTICAL_SLICE_TEST_PLAN.md`
- **Sintoma:** Checklist de 20 passos + stress tests não executados por agente automatizado neste gate.
- **Ação:** Playthrough humano obrigatório antes de declarar beta **shippable**.

## P2 — Manutenção

### KI-101 — Panic unlock (Esc) ainda ativo

- **Arquivos:** `game.gd`, `GameplayLockManager.enable_debug_panic_unlock`
- **Risco:** Mascara softlocks reais durante QA.

### KI-102 — Auto-load desativado na greybox

- **Arquivo:** `vertical_slice_greybox.tscn` — `SaveManager.auto_load_on_ready = false`
- **Intencional** na demo; beta exige decisão D-013 (`DECISIONS.md`).

### KI-103 — Controllers ainda usam `_player.call("_is_*")` internamente

- **Arquivos:** `player_*_controller.gd`
- **Risco:** Acoplamento residual pós-refatoração; API pública parcial (`is_player_dodging`).

### KI-104 — Hitstop via grupo em `hitbox_component` / barreira

- **Padrão:** `get_nodes_in_group("hitstop_controller")` + `call`
- **Direção:** Referência via `GameServices` ou sinal único na shell.

### KI-105 — Debug overlay acoplado ao player (F)

- **Arquivo:** `PlayerDebugView`, `%DebugLabel`
- **Beta:** Desligável em release build.

## P3 — Baixa prioridade

### KI-201 — Cenas legado `*_test.tscn` vs `vertical_slice_*`

- Consolidar nomenclatura quando áreas legadas forem aposentadas.

### KI-202 — Suporte a reconexão de controle / foco de janela

- Não implementado; stress test manual marcado N/A.

### KI-203 — Warnings esperados em suítes de save/diálogo

- Save corrompido e dialogue id ausente são **injetados** pelos testes (allowlist).

## Histórico de reclassificação (gate 2026-07-11)

| Issue antigo (TECH_DEBT) | Nova classificação | Motivo |
| --- | --- | --- |
| SaveManager paths internos | **Resolvido** | `export_save_state` / `PlayerStateSnapshot` |
| StyleManager `$StyleHud` rígido | **Resolvido** | `bind_style_hud()` opcional |
| AreaTransition rebinding por grupos | **Resolvido** | `GameServices.on_area_loaded` |
| Arena fail-safe silencioso | **Resolvido** | `arena_integrity_failed` + abort |
| Testes com runtime errors | **P2** | 0 unexpected; allowlist documentada |

Ver `STABILIZATION_REPORT.md` para evidências do gate.
