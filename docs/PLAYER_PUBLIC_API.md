# Player Public API — Red Hollow

Superfície pública de `scripts/player/player.gd` e `scenes/player/player.tscn`. **Baseline de regressão** antes e durante refatoração. Alterações exigem atualização de `player_regression_tests.gd` e deste documento.

Tag de referência: `greybox-vertical-slice-v0.1`.

## Identidade

| Item | Valor |
| --- | --- |
| Script | `res://scripts/player/player.gd` |
| Cena | `res://scenes/player/player.tscn` |
| Tipo raiz | `CharacterBody2D` |
| Grupo | `player` (`PLAYER_GROUP`, registrado em `_ready`) |
| Grupos consultados | `gameplay_lock_manager`, `camera_controller`, `hitstop_controller` |

## Sinais emitidos

| Sinal | Payload | Quando |
| --- | --- | --- |
| `counter_success` | `attack_data`, `attacker` | Counter bem-sucedido (hurtbox) |
| `combo_completed` | — | Finisher do combo (índice 2) concluído |
| `dodge_started` | — | Esquiva entra fase ativa |
| `dodge_finished` | — | Esquiva termina recovery |
| `counter_resolved` | `result: String` | `success`, `miss`, `miss_window`, `not_counterable`, `pending`, etc. |
| `taunt_performed` | `phrase`, `context: Dictionary` | Provocação inicia (contexto inclui `line_id`, duração, janelas) |
| `taunt_started` | `phrase`, `line_id: StringName` | Provocação inicia |
| `brand_breaker_charge_started` | — | Carga Red Brand Breaker inicia |
| `brand_breaker_charge_updated` | `charge_time`, `preview_level` | Preview de nível muda |
| `brand_breaker_charge_cancelled` | — | Carga cancelada |
| `brand_breaker_released` | `level`, `cost` | Breaker liberado |

### Sinais consumidos (componentes filhos)

| Origem | Sinal | Handler |
| --- | --- | --- |
| `HealthComponent` | `damaged`, `died` | `_on_player_damaged`, `_on_player_died` |
| `HitboxComponent` | `hit_landed` | `_on_hit_landed` |
| `HurtboxComponent` | `hit_countered` | `_on_hit_countered` |

## Métodos públicos (preservar)

### Interação e locks

| Método | Retorno | Contrato |
| --- | --- | --- |
| `can_interact_now()` | `bool` | `false` se lock gameplay, morto, combate ativo, esquiva, counter, taunt ou carga Brand |
| `is_in_dialogue()` | `bool` | `GameplayLockManager` lock DIALOGUE ou token legado |
| `is_in_transition()` | `bool` | Lock AREA_TRANSITION ou token legado |
| `enter_dialogue_mode()` | `void` | Adquire lock; `interrupt_attack(INTERACT)`; zera velocidade |
| `exit_dialogue_mode()` | `void` | Libera lock diálogo |
| `enter_transition_mode()` | `void` | Adquire lock transição |
| `exit_transition_mode()` | `void` | Libera lock transição |
| `clear_input_locks()` | `void` | Libera todos locks do owner + tokens legados |
| `get_interaction_debug_info()` | `Dictionary` | `{id, distance, priority}` |

### Movimento e orientação

| Método | Retorno | Contrato |
| --- | --- | --- |
| `set_facing_direction(direction: int)` | `void` | Normaliza ±1; espelha `%Visual` e `%DirectionMarker` (não o body) |
| `get_spawn_position()` | `Vector2` | Spawn / fall recovery |
| `set_spawn_position(position: Vector2)` | `void` | Define spawn |

### Combate

| Método | Retorno | Contrato |
| --- | --- | --- |
| `can_cancel_attack()` | `bool` | Dentro da janela de cancel do `AttackData` atual |
| `interrupt_attack(next_state = HURT)` | `void` | Cancela ataque, dodge, counter, taunt, Brand |
| `try_counter_hit(attack_data, hitbox, attacker)` | `bool` | Só na `CounterPhase.WINDOW` com `counterable == true` |

### Persistência e área

| Método | Retorno | Contrato |
| --- | --- | --- |
| `apply_area_settings(settings)` | `void` | Aplica `fall_recovery_y` |
| `apply_checkpoint(pos, restore_health, restore_red_brand)` | `void` | Teleporta; limpa combate; restaura opcional |
| `apply_save_state(save_data)` | `void` | Destrava locks; restaura posição, vida, Brand |
| `capture_persistence_state()` | `Dictionary` | `{spawn_position, max_health, current_health, red_brand_energy}` |
| `get_health_component()` | `Node` | `%HealthComponent` |
| `get_red_brand_component()` | `RedBrandComponent` | `%RedBrandComponent` |

## Propriedades consultadas externamente

| Propriedade | Consumidores |
| --- | --- |
| `global_position`, `velocity` | SaveManager, AreaTransitionManager, câmera, inimigos |
| `facing_direction` | Hitbox, InteractionDetector, testes |
| `current_state` | StyleManager (via introspecção), testes |
| `fall_recovery_y` | AreaTransitionManager via `apply_area_settings` |
| `coyote_time_remaining`, `jump_buffer_remaining` | Testes (proxies para controllers) |
| `debug_visible` | Testes / debug (proxy `PlayerDebugView`) |

## Métodos chamados por outros sistemas (via `has_method` / `call`)

| Chamador | Método |
| --- | --- |
| `DialogueController` | `enter_dialogue_mode` |
| `AreaTransitionManager` | `enter_transition_mode`, `exit_transition_mode`, `set_spawn_position`, `apply_area_settings` |
| `SaveManager` | `apply_save_state`, `apply_checkpoint`, `capture_persistence_state`, `get_health_component`, `get_red_brand_component`, `get_spawn_position` |
| `InteractionDetector` | `can_interact_now`, `is_in_dialogue`, `set_facing_direction` |
| `HurtboxComponent` | `try_counter_hit` |
| `VerticalSliceController` | `apply_save_state`, `clear_input_locks` (via fluxo reset) |
| `StyleManager` | Conecta sinais; introspecção `_is_dodging` (dívida) |
| `RedBrandDirector` | Conecta sinais combo/Brand |
| Testes headless | `_start_attack_at_index`, `_apply_horizontal_movement`, `_try_buffered_jump`, etc. |

## Enums públicos (preservar nomes e ordem)

`PlayerState`, `AttackPhase`, `DodgePhase`, `CounterPhase`, `BrandBreakerPhase` — usados em testes via `PlayerScript.*`.

## Nós esperados (`player.tscn`)

### Unique names (`%`)

| Nó | Tipo | Uso |
| --- | --- | --- |
| `Visual` | Node2D | Facing (scale.x) |
| `BodyVisual` | Polygon2D | Placeholder corpo |
| `BrandHand` | Polygon2D | Placeholder mão Brand |
| `DirectionMarker` | Node2D | Indicador direção |
| `Components` | Node2D | Container combate |
| `HealthComponent` | Node | Vida |
| `RedBrandComponent` | Node | Energia Brand |
| `HurtboxComponent` | Area2D | Recebe dano |
| `HitboxComponent` | Area2D | Dano ativo |
| `InteractionDetector` | Node | Interação |
| `DebugLabel` | Label | Overlay debug |
| `InteractionPromptLabel` | Label | Prompt [E] |

### Controllers (refatoração em andamento)

| Nó | Script |
| --- | --- |
| `Controllers/PlayerInputController` | Entrada, buffers |
| `Controllers/PlayerMovementController` | Física locomotion |
| `Controllers/PlayerStateCoordinator` | Estados alto nível |
| `Controllers/PlayerPresentationController` | Visual placeholder |
| `Controllers/PlayerDebugView` | Debug overlay |

## Resources

| Recurso | Caminho | ID |
| --- | --- | --- |
| Combo 1 | `calder_straight.tres` | `calder_straight` |
| Combo 2 | `body_hook.tres` | `body_hook` |
| Combo 3 | `red_knuckle.tres` | `red_knuckle` |
| Counter | `calder_counter.tres` | — |
| Brand Lv1 | `red_brand_breaker_lv1.tres` | custo 30 |
| Brand Lv2 | `red_brand_breaker_lv2.tres` | custo 60, tags `barrier_break` |
| Brand config | `red_brand_config.tres` | thresholds carga |

## Input Map

`move_left`, `move_right`, `jump`, `attack`, `dodge`, `counter`, `interact`, `taunt`, `special`, `debug_toggle`, `debug_reset`.

## Dependências externas

| Sistema | Integração |
| --- | --- |
| **Câmera** | `camera_controller.request_shake` (counter, Brand breaker) |
| **Hitstop** | `hitstop_controller.request_hitstop`; via `GameplayLockManager` |
| **Diálogo** | `enter_dialogue_mode` / locks |
| **Estilo** | Sinais `combo_completed`, `dodge_*`, `counter_*`, `taunt_*`, `brand_breaker_released` |
| **Save** | `apply_save_state`, `apply_checkpoint`, `capture_persistence_state` |
| **Progressão** | Indireta via SaveManager/checkpoint (player não chama ProgressionComponent) |
| **Red Brand director** | Sinais Brand + hits |

## Adaptadores de teste (internos, preservar até refatoração completa)

| Método | Uso headless |
| --- | --- |
| `_apply_horizontal_movement(dir, delta)` | Aceleração sem Input confiável |
| `_try_buffered_jump()` | Coyote/buffer com precondições setadas |
| `_start_attack_at_index(i)` | Fases de combo |
| `_start_ground_dodge`, `_start_counter`, `_start_taunt`, `_start_brand_charge` | Defesa/Brand |

Ver `docs/HEADLESS_TESTING.md`.
