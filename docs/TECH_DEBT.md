# Red Hollow — Technical Debt

Dívida técnica conhecida. Baseline: tag `greybox-vertical-slice-v0.1` (`ae65a5084c1cbece80672a67d4bc0a6b4d40e5df`). Atualizar quando itens forem resolvidos.

Prioridade:

- **P0** — bloqueia beta estável ou mascara bugs graves
- **P1** — corrigir antes de escalar conteúdo
- **P2** — manutenção; aumenta custo se ignorado

## P0 — Bloqueadores

### Testes passam com runtime errors residuais

- **Estado:** melhorado com `test_runner.gd` + `runtime_error_monitor.gd`; 10 suítes passam no baseline.
- **Problema:** `combat_arena_tests` ainda declara erros permitidos (`Can't change this state while flushing queries`, warnings de inimigo removido).
- **Risco:** regressão real mascarada por allowlist.
- **Direção:** corrigir toggles de colisão com `call_deferred` na produção; reduzir allowlist até zero.

### Locks e hitstop — mecanismos globais de emergência

- **Estado:** `GameplayLockManager` + tokens implementados; hitstop não congela `Engine.time_scale`.
- **Problema:** `Esc` / panic unlock em `game.gd` e demo ainda existem como escape hatch.
- **Risco:** mascarar softlocks em vez de corrigi-los.
- **Direção:** auditar cada panic path; remover quando locks cobrirem 100% dos casos.

### Fluxo de morte e respawn não consolidado

- **Arquivos:** `player.gd`, `health_component.gd`, `game.gd`
- **Problema:** morte aplica lock DEATH; respawn por checkpoint/queda/recuperação não unifica estado de combate, locks e HUD.
- **Risco:** softlock ou estado inválido após morte na beta.
- **Direção:** `PlayerRespawn` ou serviço único: reset combate, locks, posição, vida, flags de chefe.

## P1 — Antes de escalar conteúdo

### `player.gd` concentra responsabilidades

- **Baseline:** ~1700 linhas — entrada, movimento, combate, Red Brand, locks, debug, save-restore.
- **Direção:** componentes `PlayerInputController`, `PlayerMovementController`, `PlayerStateCoordinator`, `PlayerPresentationController`, `PlayerDebugView` (refatoração em andamento no working tree).
- **Risco:** regressão em qualquer feature nova.

### Dependência excessiva de grupos e chamadas dinâmicas

- **Padrão:** `get_nodes_in_group`, `has_method` + `call`, strings de grupo espalhadas.
- **Risco:** ordem de init, renome, múltiplas instâncias.
- **Direção:** sinais, referências exportadas na shell, APIs tipadas.

### SaveManager depende de paths internos

- **Baseline:** `_capture_player_state` usa `Components/HealthComponent` e `Components/RedBrandComponent`.
- **Direção:** `capture_persistence_state()`, `get_health_component()`, `get_red_brand_component()` no player (parcialmente implementado no working tree, não no tag).

### StyleManager — dependência rígida de HUD

- **Problema:** espera `$StyleHud`; introspecção de métodos privados do player (`_is_dodging`).
- **Direção:** sinais públicos; HUD opcional em fixtures de teste.

### AreaTransitionManager — rebinding global frágil

- **Problema:** após swap de área, percorre grupos para save, style, Red Brand, diálogo, checkpoints.
- **Direção:** contrato `on_area_loaded(area)` na shell ou barramento de eventos tipado.

### Auto-load desativado na vertical slice

- **Cena:** `vertical_slice_greybox.tscn` — `SaveManager.auto_load_on_ready = false`
- **Intencional:** evitar load de saves incompatíveis; **F9** manual.
- **Beta:** auto-load só após validação de área + versão + API estável.

## P2 — Manutenção

| Item | Notas |
| --- | --- |
| Documentação desatualizada | Corrigido neste ciclo (`CURRENT_IMPLEMENTATION.md`, etc.) |
| Caminhos absolutos em docs de teste | Substituir por comandos portáveis (`TEST_MATRIX.md`) |
| Scripts médios crescendo | `deacon_rusk.gd`, `area_transition_manager.gd`, `vertical_slice_controller.gd` |
| Debug acoplado ao gameplay | Label enorme no player; mover para overlay desligável em release |
| Cenas `*_test` vs `vertical_slice_*` | Consolidar nomenclatura quando áreas legadas forem aposentadas |
| Duplicação de reset | `game.gd`, `vertical_slice_controller.gd`, `dialogue_controller.gd` |

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

1. P0 restante: morte/respawn; reduzir allowlist de runtime errors
2. P1: split player + API save; contratos de rebinding
3. P1: StyleManager desacoplado
4. Decisão auto-load para beta (`DECISIONS.md` D-013)
5. P2 conforme capacidade

Ver `ARCHITECTURE.md`, `CONTENT_PRODUCTION_PLAN.md`, `DECISIONS.md`.
