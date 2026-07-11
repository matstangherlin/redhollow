# Red Hollow — Technical Debt

Dívida técnica conhecida no repositório. Atualizar quando itens forem resolvidos.

Legenda de prioridade:

- **P0** — bloqueia beta estável ou mascarar bugs graves
- **P1** — corrigir antes de adicionar conteúdo em escala
- **P2** — pode esperar, mas aumenta custo de manutenção

## P0 — Bloqueadores de beta

### Player monolítico

- **Arquivo:** `scripts/player/player.gd` (~1700+ linhas)
- **Problema:** entrada, movimento, combate, Red Brand, locks, respawn, debug e save-restore no mesmo script.
- **Risco:** regressões em qualquer feature nova.
- **Direção:** extrair `PlayerInput`, `PlayerMovement`, `PlayerCombat`, `PlayerRedBrand`, `PlayerInteractionLock`, `PlayerRespawn`.

### Recuperação global (panic unlock)

- **Arquivos:** `scripts/core/game.gd`, `scripts/player/player.gd`, `scripts/demo/vertical_slice_controller.gd`, `scripts/dialogue/dialogue_controller.gd`
- **Problema:** `Esc`, `_panic_unlock()`, `clear_input_locks()` e resets de arena/diálogo/hitstop corrigem softlocks mas mascaram causas raiz.
- **Direção:** `GameplayLockManager` com tokens, ownership e timeout auditável.

### Hitstop e time scale

- **Arquivos:** `scripts/core/hitstop_controller.gd`, `scripts/core/game.gd`, `scripts/player/player.gd`
- **Problema:** hitstop antigo congelava `Engine.time_scale`; hoje há resets repetidos que impedem freeze mas não modelam feedback de forma limpa.
- **Direção:** hitstop como efeito local (shake, pause seletivo, frame hold visual) sem depender de `Engine.time_scale` global.

### Testes headless com runtime errors

- **Scripts:** `dialogue_tests.gd`, `area_transition_tests.gd`, suítes que montam nós fora da árvore completa
- **Problema:** testes imprimem “passed” com erros de `get_tree()` nulo ou nós faltando (`StyleHud`).
- **Direção:** fixtures mínimas de cena ou falhar teste quando houver erro no console.

## P1 — Antes de escalar conteúdo

### Acoplamento por grupos

- Uso extensivo de `get_nodes_in_group`, `get_first_node_in_group`, `has_method` + `call`.
- **Risco:** ordem de inicialização, renome de grupo, múltiplas instâncias.
- **Direção:** interfaces tipadas, sinais, referências exportadas na shell scene.

### SaveManager e paths internos

- **Arquivo:** `scripts/save/save_manager.gd`
- **Problema:** captura estado via `Components/HealthComponent` e grupos.
- **Direção:** API explícita no player (`export_save_state` / `import_save_state`).

### AreaTransitionManager rebinding

- **Arquivo:** `scripts/world/area_transition_manager.gd`
- **Problema:** após troca de área, percorre grupos para rebind de save, style, Red Brand, diálogo.
- **Direção:** contrato `on_area_loaded(area)` na shell ou barramento de eventos.

### StyleManager e cena

- **Arquivo:** `scripts/style/style_manager.gd`
- **Problema:** depende de `$StyleHud` e introspecção de métodos privados do player (`_is_dodging`).
- **Direção:** sinais públicos do player; HUD opcional em testes.

### Auto-load desativado na vertical slice

- **Cena:** `vertical_slice_greybox.tscn` — `SaveManager.auto_load_on_ready = false`
- **Estado:** intencional para evitar saves quebrados de arena; load apenas com **F9** ou após decisão de arquitetura.
- **Beta:** reavaliar auto-load com validação de área e versão de save.

### Combat arena fail-safe

- **Arquivo:** `scripts/world/combat_arena_controller.gd`
- **Problema:** completa arena se inimigos somem — útil contra softlock, pode esconder bug de despawn.
- **Direção:** log explícito + telemetria em debug; remover fail-safe em build final se estável.

## P2 — Manutenção

- Documentação de áreas de teste (`street_test`, `church_entrance_test`) vs vertical slice (`vertical_slice_*`) — consolidar nomenclatura.
- `player.gd` debug label enorme — mover para overlay opcional.
- Duplicação de lógica de reset entre `game.gd`, `vertical_slice_controller.gd` e `dialogue_controller.gd`.
- Falta de pasta `tests/` dedicada; testes vivem como scripts `--script` soltos.

## Funcionalidades congeladas durante refatoração

Não alterar comportamento destes fluxos sem teste completo:

- combo e cancel windows;
- diálogo + cooldown de reabertura (`REOPEN_BLOCK_MS`);
- transição rua → igreja → subterrâneo;
- arena dois Cult Brawlers;
- barreira + registry persistente;
- Deacon Rusk fases e stagger;
- F7 reset demo, F8/F9 save/load.

## Ordem recomendada de pagamento

1. Testes que falham com erro no console
2. Gameplay lock manager
3. Hitstop sem `Engine.time_scale` global
4. Split de `player.gd`
5. Contratos de rebinding na troca de área
6. Save/load e auto-load para beta

Ver também `ARCHITECTURE.md` (estado alvo) e `CONTENT_PRODUCTION_PLAN.md` (não adicionar mapas grandes antes de P0/P1 críticos).
