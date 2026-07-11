# Red Hollow — Technical Debt

Dívida técnica conhecida. Baseline histórica: tag `greybox-vertical-slice-v0.1` (`ae65a5084c1cbece80672a67d4bc0a6b4d40e5df`).  
**Gate de estabilização:** 2026-07-11 — ver `STABILIZATION_REPORT.md`, `KNOWN_ISSUES.md`.

Prioridade:

- **P0** — bloqueia release beta ou causa perda/corrupção de progresso sem recuperação
- **P1** — corrigir antes de escalar conteúdo ou ship beta
- **P2** — manutenção; aumenta custo se ignorado
- **P3** — cosmético / documentação

## P0 — Bloqueadores

*Nenhum P0 confirmado pelo gate automatizado de 2026-07-11 (10/10 suítes, 0 unexpected issues).*

Itens abaixo eram P0 históricos; reclassificados após refatoração e testes.

## P1 — Antes de escalar conteúdo / ship beta

### Fluxo de morte e respawn não consolidado (KI-001)

- **Arquivos:** `player.gd`, `health_component.gd`, `game.gd`
- **Problema:** morte aplica lock DEATH; não há serviço único de respawn (checkpoint automático, overlay, reset HUD/chefe).
- **Workaround:** **R**, **F7**, **F9**, **Esc** (panic).
- **Cobertura auto:** `player_regression_tests`, `gameplay_lock_tests` (morte durante hitstop).
- **Direção:** `PlayerRespawn` ou serviço único na shell.

### Arena — spawn durante flush de física (KI-002)

- **Arquivo:** `combat_arena_controller.gd` — `_spawn_configured_enemies`
- **Problema:** headless emite `Can't change this state while flushing queries` (36 erros **permitidos** em `combat_arena_tests`).
- **Risco:** instabilidade de colisão em runtime real.
- **Direção:** `call_deferred` para spawn ou ativação pós-frame.

### Refatoração local não commitada (KI-003)

- **Estado:** commit base `1c8e89d`; controllers + `GameServices` só no working tree.
- **Risco:** baseline de equipe divergente.
- **Ação:** commit + tag de gate antes de produção artística paralela.

### Playthrough manual completo pendente (KI-004)

- **Problema:** checklist 20 passos + stress tests não assinados neste gate.
- **Ação:** humano segue `VERTICAL_SLICE_TEST_PLAN.md` antes de declarar beta shippable.

### `player.gd` ainda coordena demais

- **Estado:** ~791 linhas (baseline ~1700); combate/defesa/taunt/brand extraídos para controllers.
- **Restante:** locks, save API, proxies de teste, orquestração.
- **Direção:** continuar extração conforme `PLAYER_BEHAVIOR_CONTRACT.md`.

## P2 — Manutenção

### Locks e hitstop — panic unlock (KI-101)

- **Estado:** `GameplayLockManager` + tokens OK; hitstop não altera `Engine.time_scale`.
- **Problema:** **Esc** / `enable_debug_panic_unlock` em `game.gd` ainda ativos.
- **Direção:** remover em builds release; auditar softlocks reais.

### Auto-load desativado na vertical slice (KI-102)

- **Cena:** `vertical_slice_greybox.tscn` — `SaveManager.auto_load_on_ready = false`
- **Intencional** na demo; beta exige decisão D-013 (`DECISIONS.md`).

### Controllers — `_player.call("_is_*")` residual (KI-103)

- **Arquivos:** `player_*_controller.gd`
- **Direção:** expandir API pública tipada no player.

### Hitstop via grupo (KI-104)

- **Padrão:** `get_nodes_in_group("hitstop_controller")` + `call` em hitbox/barreira.
- **Direção:** referência via `GameServices` ou sinal único.

### Debug acoplado ao gameplay (KI-105)

- **Arquivo:** `PlayerDebugView`, overlay **F**
- **Direção:** desligável em release.

### Grupos como fallback secundário

- **Estado:** `GameServices` + sinais `area_loaded`/`area_unloaded` são primários pós-refatoração.
- **Restante:** grupos em hitstop, alguns binds legados.
- **Direção:** reduzir gradualmente.

### Scripts médios crescendo

- `deacon_rusk.gd`, `area_transition_manager.gd`, `vertical_slice_controller.gd`

### Cenas `*_test` vs `vertical_slice_*` (KI-201)

- Consolidar nomenclatura quando áreas legadas forem aposentadas.

## Resolvido (gate 2026-07-11)

| Item | Solução |
| --- | --- |
| SaveManager paths internos | `export_save_state` / `import_save_state` + `PlayerStateSnapshot` |
| StyleManager `$StyleHud` rígido | `bind_style_hud()` opcional |
| AreaTransition rebinding por grupos | `GameServices.on_area_loaded` / `on_area_unloaded` |
| Arena fail-safe silencioso | `arena_integrity_failed` + abort |
| Zero unexpected runtime errors | 10/10 suítes PASS; allowlist documentada em `TEST_MATRIX.md` |
| Monolito player ~1700 linhas | Parcial: 791 linhas + 6 controllers dedicados |

## Funcionalidades congeladas durante refatoração

Não alterar comportamento sem teste completo:

- combo e janelas de cancel/buffer;
- diálogo + cooldown reopen (250 ms);
- transição rua → igreja → subterrâneo;
- arena dois Cult Brawlers;
- barreira + `BarrierRegistry`;
- Deacon Rusk fases/stagger;
- F7 reset demo, F8/F9 save/load;
- `auto_load_on_ready = false` na greybox.

## Ordem recomendada de pagamento

1. Commit + tag gate; playthrough manual (KI-003, KI-004)
2. P1: morte/respawn; arena spawn deferred (KI-001, KI-002)
3. P1: continuar split player se necessário
4. Decisão auto-load para beta (`DECISIONS.md` D-013)
5. P2: panic unlock, hitstop via serviço, debug release
6. P2 conforme capacidade

Ver `ARCHITECTURE.md`, `CONTENT_PRODUCTION_PLAN.md`, `DECISIONS.md`, `STABILIZATION_REPORT.md`.
