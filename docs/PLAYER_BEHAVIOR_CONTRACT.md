# Player Behavior Contract — Vertical Slice baseline

Contratos comportamentais que **devem permanecer verdadeiros** após refatorações. Validados por `scripts/player/player_regression_tests.gd` e suítes de fluxo.

## Movimento

### Aceleração e desaceleração

- No chão, com input horizontal, `velocity.x` converge para `±max_run_speed` (240 px/s) usando `ground_acceleration` (1800).
- Sem input no chão, `velocity.x` decai até 0 usando `ground_deceleration` (2200).
- No ar, aceleração/desaceleração usam `air_acceleration` (1100) e `air_deceleration` (650).

### Pulo, queda e gravidade

- Pulo no chão define `velocity.y = jump_velocity` (-560) e estado `JUMP`.
- Gravidade aplica até `max_fall_speed` (900).
- Soltar `jump` cedo reduz `velocity.y` por `jump_cut_multiplier` (0.45).

### Coyote time e jump buffer

- Ao sair do chão, `coyote_time_remaining` inicia em `coyote_time` (0.10 s); pulo ainda permitido enquanto > 0.
- Pressionar `jump` antes de pousar preenche `jump_buffer_remaining` (0.12 s); ao tocar chão, pulo dispara se buffer ativo.

### Facing

- `set_facing_direction(±1)` atualiza `facing_direction` e espelha `%Visual` / `%DirectionMarker`.
- Dodge usa `facing_direction` como direção padrão.

### Recuperação de queda

- Se `global_position.y > fall_recovery_y`, o jogador teleporta para `spawn_position`, zera velocidade/timers e cancela combate ativo.
- `apply_area_settings({"fall_recovery_y": X})` altera o limiar por área (demo: 1320; underground VS: 1280).

## Combate

### Combo de três golpes

- Sequência: `calder_straight` → `body_hook` → `red_knuckle`.
- Cada ataque passa por fases `STARTUP → ACTIVE → RECOVERY`.
- Golpes 1–2 possuem janela de cancelamento (`cancel_window_start/end`); o 3º é finisher sem cancel.
- Buffer de combo: `attack_input_buffer_time` (0.35 s) durante janela de cancelamento.
- Após finisher, emite `combo_completed`.

### Hitbox e alvo único

- Hitbox ativa só em `AttackPhase.ACTIVE`.
- `HitboxComponent` respeita `max_hits_per_target` do `AttackData` (default 1).
- Forma/tamanho vêm de `AttackData.hitbox_size` e `hitbox_offset`, não do Polygon2D.

### Interrupção

- `interrupt_attack()` cancela ataque, dodge, counter, taunt e carga Brand.
- Dano (`HealthComponent.damaged`) interrompe para `HURT`.
- Morte interrompe para `DEAD`.

### Counter

- Input `counter` inicia fases: startup → **window** → recovery.
- `try_counter_hit()` só funciona na window com ataque `counterable`.
- Sucesso dispara counter attack (`calder_counter.tres`), hitstop e screen shake.

### Esquiva

- Input `dodge` no chão; fases startup/active/recovery; cooldown 0.28 s.
- Invulnerabilidade entre `invulnerability_start` (0.02 s) e `invulnerability_end` (0.13 s) do elapsed.

### Provocação

- Input `taunt` no chão (estados permitidos); duração 0.90 s; cooldown 1.20 s.
- Vulnerabilidade entre `taunt_vulnerable_start` (0.14 s) e `taunt_vulnerable_end` (0.68 s).

### Red Brand Breaker

- Input `special` (segurar) inicia carga se `RedBrandComponent` tem ≥ `min_energy_to_charge` (30 no `.tres` atual).
- Lv1 após 0.22 s; Lv2 após 0.55 s.
- Soltar dispara ataque correspondente e consome energia.
- Emite sinais `brand_breaker_*`.

## Locks de input

| Lock | Efeito |
| --- | --- |
| Diálogo | Sem ataque/dodge/counter/taunt/Brand; gravidade continua; estado `INTERACT` |
| Transição | Idêntico ao diálogo |
| Morte | `can_interact_now()` false; combate bloqueado |
| Dois locks | Ambos podem estar true; `clear_input_locks()` limpa os dois |
| Fora de ordem | `exit_dialogue_mode()` / `exit_transition_mode()` independentes; `clear_input_locks()` força reset |

Reconciliação automática: se controller de diálogo não está ativo, locks de diálogo são limpos; idem transição via `AreaTransitionManager.is_transitioning`.

## Contratos com sistemas externos

### Câmera (`camera_controller` group)

- Player solicita shake em counter success e Brand breaker via `request_shake(intensity, duration)`.
- Câmera segue `target_path` (demo: `../Player`); Player **não** controla limites de área diretamente.

### Diálogo (`dialogue_controller` group)

- `DialogueController` chama `enter_dialogue_mode()` / destrava via `clear_input_locks()` ou `exit_dialogue_mode()`.
- Player bloqueia `interact` durante combate/locks via `can_interact_now()`.

### Save (`SaveManager`)

- `apply_save_state()` restaura `checkpoint_position`, `player_current_health`, `player_max_health`, `red_brand_energy`.
- `apply_checkpoint()` usado em checkpoints da vertical slice.
- Save **não** serializa estado de combo/dodge/counter.

### Red Brand (`RedBrandComponent`)

- Player lê/consome via `can_consume`, `consume_energy`, `set_energy`, `reset_energy`.
- Breaker consome custo do `AttackData.red_brand_cost` ou config fallback.

### StyleManager (`style_manager` group)

- StyleManager escuta sinais do Player (`combo_completed`, `dodge_*`, `counter_*`, `taunt_*`, `brand_breaker_released`) e hits do hitbox.
- Player **não** chama StyleManager diretamente.

### Hitstop (`hitstop_controller` group)

- Player chama `request_hitstop(duration)` em counter; hitbox também pode solicitar.
- **Contrato crítico:** hitstop **não** pausa árvore nem altera `Engine.time_scale` permanentemente.
- Player força `Engine.time_scale = 1.0` e unpause se detectar soft-lock.

## Fluxo vertical slice (referência)

1. **Street** — spawn `(120, 848)`, diálogo Elias, brawler, exit church.
2. **Church** — arena cultistas, cache Brand, barreira `CultRedBarrier`, exit underground.
3. **Underground** — checkpoint, Deacon Rusk, conclusão demo.
4. **Reset F7** — `VerticalSliceController.return_to_start()` limpa save, locks, hitstop, barreiras, Brand, style.

Contratos de fluxo detalhados em `scripts/demo/vertical_slice_regression_tests.gd`.
