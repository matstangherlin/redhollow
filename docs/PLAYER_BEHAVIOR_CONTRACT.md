# Player Behavior Contract — Vertical Slice baseline

Comportamentos que **devem permanecer verdadeiros** após refatoração de `player.gd`. Validados por `scripts/player/player_regression_tests.gd` (48 casos) e suítes de fluxo.

Complementa `PLAYER_PUBLIC_API.md`. Valores numéricos vêm dos `@export` atuais — **não alterar** sem atualizar testes.

## Movimento

### Horizontal, aceleração e desaceleração

- Input A/D produz `velocity.x` positivo/negativo convergindo para `±max_run_speed` (240 px/s).
- Chão: aceleração `ground_acceleration` (1800); desaceleração `ground_deceleration` (2200).
- Ar: `air_acceleration` (1100) / `air_deceleration` (650).

### Gravidade e queda

- Gravidade 1800 px/s² até `max_fall_speed` (900).
- No chão com `velocity.y > 0`, vertical zera antes de gravidade.

### Pulo, coyote, buffer, corte variável

- Pulo no chão: `velocity.y = jump_velocity` (-560); estado `JUMP` ou `FALL`.
- Coyote: 0.10 s após sair do chão.
- Jump buffer: 0.12 s; dispara ao pousar se coyote ativo.
- Soltar pulo cedo: `velocity.y *= jump_cut_multiplier` (0.45).

### Facing

- `set_facing_direction(±1)` atualiza `facing_direction`, `%Visual.scale.x`, `%DirectionMarker`.
- **CharacterBody2D.scale** permanece `(1, 1)` — espelhamento só em `%Visual`.

### Recuperação por queda

- Se `global_position.y > fall_recovery_y` → teleporte `spawn_position`, zera velocidade/timers, cancela combate.
- `apply_area_settings({"fall_recovery_y": X})` altera limiar por área.

## Ataques

### Combo (ordem fixa)

1. **Calder Straight** (`calder_straight`) — startup 0.08 / active 0.08 / recovery 0.18 s  
2. **Body Hook** (`body_hook`) — 0.11 / 0.09 / 0.22 s  
3. **Red Knuckle** (`red_knuckle`) — finisher; emite `combo_completed`

### Fases e buffer

- Fases: `STARTUP → ACTIVE → RECOVERY → NONE`.
- Hitbox ativa só em `ACTIVE`.
- Buffer de combo: `attack_input_buffer_time` (0.35 s) durante janela de cancel (`cancel_window_start/end` nos `.tres`).
- Finisher sem janela de cancel.

### Acerto único e interrupção

- `max_hits_per_target == 1` por padrão; `clear_hit_targets` ao iniciar ataque.
- `interrupt_attack()` limpa `current_attack` e estados de defesa/Brand.
- Dano → `HURT` + interrupção; morte → `DEAD`.

## Defesa

### Esquiva

- Fases startup / active / recovery; cooldown 0.28 s.
- Invulnerabilidade entre `invulnerability_start` (0.02 s) e `invulnerability_end` (0.13 s) do elapsed.
- Sinais: `dodge_started`, `dodge_finished`.

### Counter

- Fases: startup → **window** (0.12 s) → recovery.
- `try_counter_hit`: aceito só na window com `AttackData.counterable == true`.
- Rejeição: cedo (startup), tarde (pós-window), não counterable.
- Sucesso → counter attack + hitstop + screen shake.

## Provocação

- Duração 0.90 s; cooldown 1.20 s após término.
- Vulnerabilidade (não invulnerável) entre 0.14 s e 0.68 s elapsed.
- Sinais `taunt_started`, `taunt_performed`; frase não vazia de `taunt_phrases`.
- Bloqueia `can_interact_now`.

## Red Brand Breaker

- Carga requer energia ≥ `min_energy_to_charge` (config `.tres`).
- Lv1 após 0.22 s; Lv2 após 0.55 s (config).
- Custos: 30 (lv1) / 60 (lv2) via `AttackData.red_brand_cost`.
- Energia insuficiente → downgrade ou cancel.
- Sinais: `brand_breaker_charge_started`, `_updated`, `_cancelled`, `_released`.
- Lv2 mantém tags `red_brand_breaker` + `barrier_break` para barreiras Vermilite.

## Locks de gameplay

| Lock | Efeito |
| --- | --- |
| Diálogo (`GameplayLockManager.DIALOGUE`) | Sem ataque/dodge/counter/taunt/Brand; gravidade continua; `INTERACT` |
| Transição (`AREA_TRANSITION`) | Idem diálogo |
| Morte (`DEATH`) | `can_interact_now` false; lock via `_on_player_died` |
| Dois locks | Coexistem; `clear_input_locks()` limpa todos |
| Desbloqueio parcial | `exit_dialogue_mode()` não remove lock de transição |

## Dano e morte

- `HealthComponent.damaged` → `interrupt_attack(HURT)` se não morto.
- `HealthComponent.died` → `interrupt_attack(DEAD)` + lock DEATH.
- `apply_checkpoint` / `apply_save_state` restauram posição, vida, Brand e limpam combate ativo.

## Contratos com sistemas externos

### Câmera

- `request_shake(intensity, duration)` em counter e Brand breaker.

### Diálogo

- `DialogueController` → `enter_dialogue_mode()`.
- Player não avança diálogo; bloqueia combate durante lock.

### Save / checkpoint

- `apply_save_state`: `checkpoint_position`, `player_current_health`, `player_max_health`, `red_brand_energy`.
- `capture_persistence_state()` para SaveManager (sem paths `Components/...`).
- Não serializa combo/dodge/counter mid-action.

### Estilo (`StyleManager`)

- Escuta sinais do player e hits; player **não** chama StyleManager diretamente.

### Hitstop

- `request_hitstop(duration)`; **não** altera `Engine.time_scale` permanentemente nem pausa árvore sozinho.

### Progressão

- Indireta via checkpoint/save; player não referencia `ProgressionComponent`.

## Visual vs gameplay

- Ocultar `%BodyVisual` / `%BrandHand` **não** impede ataque (hitbox independente).
- Colisão do `CharacterBody2D` independente de escala visual.

## Não testável automaticamente (headless)

| Comportamento | Motivo |
| --- | --- |
| Feeling subjetivo de combo/dodge | Requer playtest humano |
| Input Map `is_action_just_pressed` confiável | Testes usam precondições + adaptadores |
| Screen shake visual | Sem viewport assert |
| Animações futuras (`AnimatedSprite2D`) | Ainda placeholder Polygon2D |
| Integração câmera follow/limites | Requer cena completa + `AreaRoot` |
| Barreira destruível in-world | Coberto indiretamente por tags lv2; destruição em testes de mundo |
| Respawn completo pós-morte na demo | Fluxo morte/respawn P0 dívida — lock testado, respawn UX manual |
| Red Brand HUD pulse | UI separada |

## Execução dos testes

```bash
godot --headless --path . --script res://scripts/player/player_regression_tests.gd
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

Suite `player_regression_tests`: **48** casos; falha se qualquer assertion ou erro inesperado no console.
