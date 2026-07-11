# Player Public API — Red Hollow (Vertical Slice baseline)

Documentação da superfície pública de `scripts/player/player.gd` e da cena `scenes/player/player.tscn` **antes de refatorações**. Refatorações não devem alterar estes contratos sem atualizar testes e docs.

## Identidade

| Item | Valor |
| --- | --- |
| Script | `res://scripts/player/player.gd` |
| Cena | `res://scenes/player/player.tscn` |
| Tipo raiz | `CharacterBody2D` |
| Grupo | `player` (registrado em `_ready`) |

## Sinais emitidos

| Sinal | Payload | Quando |
| --- | --- | --- |
| `counter_success` | `attack_data: Resource`, `attacker: Node` | Hurtbox aciona counter bem-sucedido |
| `combo_completed` | — | Terceiro golpe do combo concluído |
| `dodge_started` | — | Esquiva inicia fase ativa |
| `dodge_finished` | — | Esquiva termina recovery |
| `counter_resolved` | `result: String` | Counter resolve (`success`, `miss_window`, `not_counterable`, etc.) |
| `taunt_performed` | `phrase: String`, `context: Dictionary` | Provocação concluída |
| `taunt_started` | `phrase: String`, `line_id: StringName` | Provocação inicia |
| `brand_breaker_charge_started` | — | Carga do Red Brand Breaker inicia |
| `brand_breaker_charge_updated` | `charge_time: float`, `preview_level: int` | Nível de preview muda |
| `brand_breaker_charge_cancelled` | — | Carga cancelada |
| `brand_breaker_released` | `level: int`, `cost: float` | Breaker liberado |

## Métodos públicos

### Interação e locks

| Método | Retorno | Contrato |
| --- | --- | --- |
| `can_interact_now()` | `bool` | `false` se morto, `HURT`, `INTERACT`, atacando, esquivando, counter, taunt ou carregando Brand |
| `is_in_dialogue()` | `bool` | Reflete `_dialogue_locked` |
| `is_in_transition()` | `bool` | Reflete `_transition_locked` |
| `enter_dialogue_mode()` | `void` | Trava diálogo, interrompe combate, zera velocidade, estado `INTERACT` |
| `exit_dialogue_mode()` | `void` | Destrava diálogo; volta a `IDLE` se estava em `INTERACT` |
| `enter_transition_mode()` | `void` | Trava transição, interrompe combate, zera velocidade, estado `INTERACT` |
| `exit_transition_mode()` | `void` | Destrava transição; volta a `IDLE` se estava em `INTERACT` |
| `clear_input_locks()` | `void` | Limpa dialogue + transition locks e velocidade |
| `get_interaction_debug_info()` | `Dictionary` | `{id, distance, priority}` do `InteractionDetector` |

### Movimento e orientação

| Método | Retorno | Contrato |
| --- | --- | --- |
| `set_facing_direction(direction: int)` | `void` | Ignora `0`; normaliza para `-1`/`1`; atualiza `%DirectionMarker` |
| `get_spawn_position()` | `Vector2` | Posição de respawn/recuperação |
| `set_spawn_position(position: Vector2)` | `void` | Define spawn usado por fall recovery |

### Combate

| Método | Retorno | Contrato |
| --- | --- | --- |
| `can_cancel_attack()` | `bool` | `true` dentro da janela de cancelamento do ataque atual |
| `interrupt_attack(next_state: int = HURT)` | `void` | Cancela ataque, dodge, counter, taunt e carga Brand |
| `try_counter_hit(attack_data, _hitbox, attacker)` | `bool` | Só aceita durante `CounterPhase.WINDOW` com `AttackData.counterable == true` |

### Persistência e área

| Método | Retorno | Contrato |
| --- | --- | --- |
| `apply_area_settings(settings: Dictionary)` | `void` | Aplica `fall_recovery_y` quando presente |
| `apply_checkpoint(pos, restore_health, restore_red_brand)` | `void` | Teleporta, limpa combate/timers; opcionalmente restaura vida e Brand |
| `apply_save_state(save_data: Dictionary)` | `void` | Destrava locks; restaura posição, vida, Brand; limpa combate ativo |

## Estados (`PlayerState`)

`IDLE`, `RUN`, `JUMP`, `FALL`, `ATTACK`, `DODGE`, `COUNTER`, `TAUNT`, `HURT`, `DEAD`, `INTERACT`.

Sub-fases internas expostas indiretamente via debug: `AttackPhase`, `DodgePhase`, `CounterPhase`, `BrandBreakerPhase`.

## Exports relevantes (baseline vertical slice)

### Movimento

| Export | Default | Unidade |
| --- | --- | --- |
| `max_run_speed` | 240 | px/s |
| `ground_acceleration` | 1800 | px/s² |
| `ground_deceleration` | 2200 | px/s² |
| `air_acceleration` | 1100 | px/s² |
| `air_deceleration` | 650 | px/s² |
| `gravity` | 1800 | px/s² |
| `max_fall_speed` | 900 | px/s |
| `jump_velocity` | -560 | px/s |
| `jump_cut_multiplier` | 0.45 | ratio |
| `coyote_time` | 0.10 | s |
| `jump_buffer_time` | 0.12 | s |
| `floor_snap_distance` | 6 | px |
| `fall_recovery_y` | 720 (1320 na demo) | px |

### Combate

| Export | Default |
| --- | --- |
| `attack_input_buffer_time` | 0.35 s |
| `combo_reset_time` | 0.45 s |
| `dodge_startup/duration/recovery/cooldown` | 0.04 / 0.13 / 0.14 / 0.28 s |
| `counter_startup/window/recovery/cooldown` | 0.05 / 0.12 / 0.28 / 0.35 s |
| `counter_hitstop_duration` | 0.065 s |
| `taunt_duration/cooldown` | 0.90 / 1.20 s |

## NodePaths e unique names

### `%` referenciados pelo script

`Visual`, `BodyVisual`, `DirectionMarker`, `Components`, `DebugLabel`, `HitboxComponent`, `HurtboxComponent`, `HealthComponent`, `RedBrandComponent`, `BrandHand`, `InteractionDetector`.

### NodePaths em componentes filhos

| Nó | Path exportado |
| --- | --- |
| `HurtboxComponent` | `owner_node_path = "../.."`, `health_component_path = "../HealthComponent"` |
| `HitboxComponent` | `owner_node_path = "../.."` |

## Resources (AttackData e config)

| Recurso | Caminho | Uso |
| --- | --- | --- |
| Combo 1 | `resources/combat/calder_straight.tres` | `calder_straight` |
| Combo 2 | `resources/combat/body_hook.tres` | `body_hook` |
| Combo 3 | `resources/combat/red_knuckle.tres` | `red_knuckle` (finisher) |
| Counter | `resources/combat/calder_counter.tres` | counter attack |
| Brand Lv1 | `resources/combat/red_brand_breaker_lv1.tres` | 30 energy |
| Brand Lv2 | `resources/combat/red_brand_breaker_lv2.tres` | 60 energy, tag `barrier_break` |
| Brand config | `resources/combat/red_brand_config.tres` | energia, thresholds de carga |

## Ações de entrada (`project.godot`)

`move_left`, `move_right`, `jump`, `attack`, `dodge`, `counter`, `interact`, `taunt`, `special` (Brand Breaker).

## Dependências externas (grupos)

| Grupo | Uso pelo Player |
| --- | --- |
| `dialogue_controller` | Reconcilia `_dialogue_locked` via `is_active` |
| `area_transition_manager` | Reconcilia `_transition_locked` via `is_transitioning` |
| `hitstop_controller` | `request_hitstop(duration)`, `force_release()` |
| `camera_controller` | `request_shake(intensity, duration)` |

## Consumidores do grupo `player`

`DialogueController`, `SaveManager`, `AreaTransitionManager`, `StyleManager`, `RedBrandDirector`, `CombatArenaController`, boss encounters, inimigos (AI), `Game`, `VerticalSliceController`, area exits.
