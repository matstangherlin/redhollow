# Red Hollow — Architecture

Arquitetura do projeto Godot 4.7 em GDScript. Este documento descreve **o que está implementado** e **para onde evoluir**.

## Legenda de estado

| Tag | Significado |
| --- | --- |
| **[implemented]** | Existe no repositório e funciona na demo greybox |
| **[implemented-debt]** | Funciona, mas com dívida documentada em `TECH_DEBT.md` |
| **[planned-beta]** | Previsto para Capítulo Zero |
| **[planned-final]** | Previsto para o jogo completo |
| **[target]** | Direção arquitetural desejada |

## Main scene e shell persistente

**[implemented]** Main scene: `res://scenes/demo/vertical_slice_greybox.tscn`

Estrutura persistente (player, câmera e managers não são recriados a cada área):

```text
vertical_slice_greybox (game.gd)
├── HitstopController
├── StyleManager → StyleHud
├── BossHealthHud
├── RedBrandDirector
├── ProgressionSystem
├── DialogueSystem
├── SaveManager          (auto_load_on_ready = false na greybox)
├── AreaTransitionManager
├── VerticalSliceController
├── WorldHost            ← apenas a área atual
├── Player
└── CameraController
```

`scenes/core/game.tscn` existe como referência de shell; a demo greybox replica o mesmo padrão.

**[target]** Separar orquestração de `game.gd` em serviços menores sem concentrar panic recovery.

## Troca de áreas

**[implemented]** `AreaTransitionManager` troca cenas filhas em `WorldHost` — não usa `change_scene_to_file()` para cada passagem.

Fluxo:

1. `AreaExit` emite trigger
2. Player entra em `enter_transition_mode()`
3. Pausa curta (`transition_pause_seconds`)
4. Área atual removida; nova instanciada (`AreaRoot`)
5. Spawn em `AreaSpawnPoint` por `spawn_id`
6. Câmera `configure_for_area`
7. Rebind: save checkpoints, style trackables, diálogo reset, Red Brand
8. Player `exit_transition_mode()` / `clear_input_locks`

Áreas da vertical slice:

- `vertical_slice_street.tscn`
- `vertical_slice_church.tscn`
- `vertical_slice_underground.tscn`

Áreas de teste legadas: `street_test`, `church_entrance_test`, `underground_test`.

Ver `AREA_TRANSITIONS.md`.

## Estrutura de pastas (atual)

```text
scenes/
  demo/           # vertical_slice_greybox
  core/           # game, camera, dialogue, progression, style
  player/
  enemies/
  areas/          # vertical_slice_* + test_*
  world/          # arena, barrier, boss_encounter
  ui/
  interactables/
  npcs/
scripts/
  player/         # player.gd (monolítico) [implemented-debt]
  combat/         # components, attack_data, red_brand
  core/           # game, camera, hitstop
  dialogue/
  demo/
  enemies/
  save/
  style/
  world/
  ui/
resources/combat/   # AttackData .tres
data/dialogues/     # dialogues_pt_br.json
docs/
```

**[planned-beta]** `art/`, `audio/` com assets finais versionados.

## Jogador

**[implemented]** `CharacterBody2D` + componentes filhos:

- `HealthComponent`, `HitboxComponent`, `HurtboxComponent`
- `RedBrandComponent`, `InteractionDetector`
- Estados: idle, run, jump, fall, attack, dodge, counter, taunt, hurt, dead, interact

**[implemented-debt]** Toda lógica em `scripts/player/player.gd`.

**[target]** Divisão:

| Módulo | Responsabilidade |
| --- | --- |
| PlayerInput | Input map, buffers |
| PlayerMovement | Velocidade, pulo, gravidade |
| PlayerCombat | Combo, fases de ataque |
| PlayerDefense | Dodge, counter, i-frames |
| PlayerRedBrand | Carga e release do Breaker |
| PlayerInteractionLock | Diálogo, transição |
| PlayerPresentation | Visual, animação |

## Componentes de combate

**[implemented]**

| Componente | Função |
| --- | --- |
| `HitboxComponent` | Dano ativo, hitstop request, alvos únicos |
| `HurtboxComponent` | Recebe hit, encaminha counter/dano |
| `HealthComponent` | Vida, morte, invulnerabilidade |
| `AttackData` | Resource: timing, dano, knockback, tags, estilo |

Hitboxes/hurtboxes em `Node2D` filho (`Components`) para seguir o personagem.

## Inimigos e chefes

**[implemented]**

- `cult_brawler.gd` — IA patrulha/ataque
- `deacon_rusk.gd` — chefe em fases, stagger, super armor
- `enemy_dummy`, `enemy_attacker_test` — testes

**[planned-beta]** Três arquétipos visuais finais reutilizando padrões de IA existentes.

## Sistemas globais (na shell, não autoload)

| Sistema | Estado | Notas |
| --- | --- | --- |
| `StyleManager` | [implemented] | Grupos + sinais do player |
| `RedBrandDirector` | [implemented] | Energia e recompensas |
| `ProgressionComponent` | [implemented] | Flags, checkpoints, habilidades |
| `SaveManager` | [implemented-debt] | `user://saves`; F8/F9; auto-load off na greybox |
| `DialogueController` | [implemented] | JSON, cooldown reopen |
| `BarrierRegistry` | [implemented] | Barreiras destruídas persistentes |
| `CombatArenaController` | [implemented] | Spawn, gates, flags |
| `BossEncounterController` | [implemented] | Rusk + HUD |
| `HitstopController` | [implemented-debt] | Marcador; não congela simulação |

**[target]** Autoloads apenas se múltiplas roots precisarem do mesmo serviço (ex.: menu principal separado).

## Salvamento

**[implemented]** `SaveData` versão 1; validação; backup `.bak`; escrita atômica via temp.

Persiste: área, posição, vida, Red Brand, flags, checkpoints, barreiras destruídas.

**Importante:** na vertical slice greybox, `SaveManager.auto_load_on_ready = false` — carregamento manual (**F9**) ou após bind explícito.

**[planned-beta]** Auto-load seguro com validação de área compatível.

## Corrupção ambiental (Ressonância Rubra)

**[planned-beta]** Uma transformação curta no Capítulo Zero.

**[target]** Arquitetura sem duplicar mapas inteiros:

```text
AreaRoot
├── Layers_Normal (Node2D)
│   ├── background
│   ├── midground
│   └── foreground
├── Layers_Corrupted (Node2D, hidden by default)
│   └── ... variantes substituíveis
└── CorruptionController
    └── aplica: lighting, swap meshes, enemy table, particles
```

Técnicas:

- trocar visibilidade de camadas;
- `Resource` de variante por prop;
- shader/global modulate para iluminação;
- spawn table diferente por estado;
- **não** manter dois `.tscn` completos por área salvo exceção.

## HUD e UI

**[implemented]** `StyleHud`, `BossHealthHud`, `DialogueBox`, hints na demo.

**[planned-beta]** Mapa, objetivos, diário, menu pausa, tela Red Brand — `UI_BIBLE.md`.

## Diálogo

**[implemented]** `DialogueLibrary` + `dialogues_pt_br.json` + `DialogueController` + triggers em NPCs/interactables.

## Câmera

**[implemented]** `CameraController` — follow, limites por `AreaRoot.camera_limits`, shake.

## Depuração

**[implemented]** F toggle debug hitboxes; R respawn; F7 reset demo; F8/F9 save/load; Esc panic unlock.

**[target]** Debug overlay desligável em release.

## Sinais recomendados

Muitos já em uso: `health_changed`, `died`, `damaged`, `hit_landed`, `style_changed`, `dialogue_started/finished`, `area_changed`, `boss_defeated`, `arena_completed`.

## Testes

Scripts headless em `scripts/**/*_tests.gd` e `vertical_slice_verification.gd`. Comandos portáveis em `TEST_MATRIX.md`.

**[target]** Fixture de cena mínima para testes que hoje assumem árvore incompleta.

## Documentos relacionados

- `TECH_DEBT.md` — dívida e ordem de refatoração
- `AREA_TRANSITIONS.md` — fluxo de transição
- `BETA_DEMO_SCOPE.md` — próximo marco de entrega
