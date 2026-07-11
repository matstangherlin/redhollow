# Red Hollow - Naming Conventions

## Objetivo

Padronizar nomes para que cenas, scripts, Resources, sinais, grupos e input sejam previsiveis. O codigo deve usar ingles. Documentacao pode permanecer em portugues.

## Regras Gerais

- Usar nomes claros em ingles para codigo, cenas, nos e recursos.
- Evitar abreviacoes obscuras.
- Preferir nomes de dominio: `Player`, `Hitbox`, `Checkpoint`, `RedBrand`.
- Nao renomear arquivos, cenas, nos, recursos ou acoes existentes sem autorizacao.

## Cenas

Formato de arquivo: `snake_case.tscn`.

Exemplos:

- `main.tscn`
- `test_room.tscn`
- `player.tscn`
- `basic_enemy.tscn`
- `checkpoint.tscn`
- `dialogue_box.tscn`

Cenas reutilizaveis devem ter nomes por responsabilidade, nao por implementacao temporaria.

## Scripts

Formato de arquivo: `snake_case.gd`.

Exemplos:

- `player_controller.gd`
- `player_movement.gd`
- `player_combat.gd`
- `state_machine.gd`
- `hitbox_component.gd`
- `hurtbox_component.gd`
- `save_manager.gd`

Scripts devem evitar crescer demais. Quando um script acumular responsabilidades, considerar separar em componentes antes de refatorar de forma ampla.

## Classes

Classes com `class_name` devem usar PascalCase.

Exemplos:

- `PlayerController`
- `PlayerMovement`
- `AttackData`
- `EnemyData`
- `HitboxComponent`
- `HurtboxComponent`
- `StateMachine`
- `SaveManager`

Usar `class_name` apenas quando a classe precisar ser reutilizada pelo editor ou por outros scripts de forma clara.

## Nós

Nomes de nós na árvore devem usar PascalCase quando representarem entidades ou componentes principais.

Exemplos:

- `Player`
- `CollisionShape2D`
- `Hitbox`
- `Hurtbox`
- `HealthComponent`
- `CameraRig`
- `HUD`
- `DialogueTrigger`

Nós auxiliares podem usar nomes descritivos, mas nunca depender de nomes genericos como `Node2D`, `Area2D2` ou `Sprite` se isso dificultar manutencao.

## Sinais

Sinais devem usar snake_case, nomeados como eventos no passado ou mudanca de estado.

Exemplos:

- `health_changed`
- `damage_received`
- `died`
- `attack_started`
- `attack_hit`
- `style_changed`
- `red_brand_changed`
- `checkpoint_activated`
- `ability_unlocked`
- `dialogue_finished`
- `area_changed`

Payloads devem ser pequenos e estaveis. Evitar passar Nodes quando um id ou Resource for suficiente.

## Ações de Entrada

Acoes do Input Map devem usar snake_case com prefixo por contexto quando isso ajudar.

Acoes basicas propostas:

- `move_left`
- `move_right`
- `move_up`
- `move_down`
- `jump`
- `attack_light`
- `attack_heavy`
- `dodge`
- `counter`
- `taunt`
- `interact`
- `red_brand`
- `pause`

Nao criar acoes especificas demais antes de existir necessidade. Nao renomear acoes existentes sem autorizacao.

## Resources

Arquivos Resource devem usar snake_case e sufixo que indique o tipo quando util.

Exemplos:

- `jab_attack_data.tres`
- `roundhouse_attack_data.tres`
- `basic_enemy_data.tres`
- `calder_base_stats.tres`
- `red_brand_upgrade_data.tres`
- `dialogue_intro_data.tres`

Classes Resource devem usar PascalCase:

- `AttackData`
- `EnemyData`
- `PlayerStatsData`
- `DialogueData`
- `AbilityData`

## Variáveis

Variaveis devem usar snake_case.

Exemplos:

- `move_speed`
- `jump_velocity`
- `current_health`
- `max_health`
- `current_style`
- `red_brand_energy`
- `active_attack`
- `facing_direction`

Usar tipagem estatica quando melhorar seguranca e clareza:

```gdscript
var move_speed: float = 220.0
var current_health: int = 100
```

## Funções

Funcoes devem usar snake_case e verbos claros.

Exemplos:

- `apply_damage()`
- `start_attack()`
- `finish_attack()`
- `can_dodge()`
- `activate_checkpoint()`
- `unlock_ability()`
- `load_save()`
- `write_save()`

Funcoes privadas podem usar prefixo `_`:

- `_update_movement()`
- `_enter_state()`
- `_handle_attack_hit()`

Callbacks da Godot mantem nomes da engine, como `_ready`, `_physics_process` e `_process`.

## Grupos

Grupos devem usar snake_case e plural quando representarem colecoes.

Exemplos:

- `players`
- `enemies`
- `damageable`
- `interactables`
- `checkpoints`
- `area_transitions`
- `camera_bounds`

Usar grupos para consultas intencionais, nao como substituto de arquitetura.

## Collision Layers

Collision layers e masks devem ter nomes documentados quando forem configuradas no projeto.

Proposta inicial:

| Layer | Nome | Uso |
| --- | --- | --- |
| 1 | world | Piso, paredes e colisao do ambiente. |
| 2 | player | Corpo fisico do jogador. |
| 3 | enemies | Corpos fisicos de inimigos. |
| 4 | player_hitbox | Hitboxes ofensivas do jogador. |
| 5 | enemy_hitbox | Hitboxes ofensivas de inimigos. |
| 6 | player_hurtbox | Hurtbox do jogador. |
| 7 | enemy_hurtbox | Hurtboxes de inimigos. |
| 8 | interactables | Checkpoints, portas e objetos interativos. |
| 9 | triggers | Dialogos, troca de area e volumes logicos. |

Nao alterar collision layers e masks sem documentar o motivo, os nomes e o impacto nos testes.

## Prefixos e Sufixos Uteis

- `*_data`: Resource de configuracao.
- `*_component`: script ou node de componente.
- `*_state`: estado de maquina de estados.
- `*_trigger`: area que dispara evento.
- `*_manager`: sistema amplo; usar com moderacao.

## Exemplos Coerentes

```text
scenes/player/player.tscn
scripts/player/player_controller.gd
scripts/player/player_movement.gd
scripts/combat/hitbox_component.gd
resources/attacks/jab_attack_data.tres
resources/enemies/basic_enemy_data.tres
```

Esses nomes deixam claro o papel de cada arquivo sem depender de arte final ou implementacoes temporarias.