# Red Hollow — Architecture

Arquitetura Godot 4.7 / GDScript. Descreve **implementado**, **dívida** e **alvo**.

Baseline: tag `greybox-vertical-slice-v0.1`. Inventário: `CURRENT_IMPLEMENTATION.md`.

## Legenda

| Tag | Significado |
| --- | --- |
| **[implemented]** | Funciona na demo greybox |
| **[implemented-debt]** | Funciona com dívida (`TECH_DEBT.md`) |
| **[planned-beta]** | Capítulo Zero |
| **[planned-final]** | Jogo completo |
| **[target]** | Direção desejada |

## Main scene e shell

**[implemented]** `res://scenes/demo/vertical_slice_greybox.tscn`

```text
vertical_slice_greybox (game.gd)
├── HitstopController          [implemented-debt]
├── GameplayLockManager        [implemented]
├── StyleManager → StyleHud    [implemented-debt]
├── BossHealthHud
├── RedBrandDirector
├── ProgressionSystem
├── DialogueSystem
├── SaveManager                auto_load_on_ready = false
├── AreaTransitionManager      [implemented-debt]
├── VerticalSliceController
├── WorldHost                  ← área atual (swap)
├── Player                     [implemented-debt]
└── CameraController
```

`scenes/core/game.tscn` — referência de shell; greybox replica o padrão.

**[target]** Orquestração menor em `game.gd`; panic unlock removido quando locks forem suficientes.

## Troca de áreas

**[implemented]** `AreaTransitionManager` — swap filho em `WorldHost`, não `change_scene_to_file()` por passagem.

Fluxo: exit → lock transição → pausa → remove área → instancia `AreaRoot` → spawn → câmera → rebind (save, style, Red Brand, diálogo) → unlock.

**[implemented]** Disponibilidade de áreas centralizada em `ContentRegistry` — exits e restore de save consultam o manifesto ativo; áreas fora do perfil **não são carregadas**.

Áreas Capítulo Zero (registradas em `ChapterData`):

- `vertical_slice_street.tscn` → `vs_greybox_street`
- `vertical_slice_church.tscn` → `vs_greybox_church`
- `vertical_slice_underground.tscn` → `vs_greybox_underground`

Legado teste: `street_test`, `church_entrance_test`, `underground_test` (fora do manifesto).

Ver `AREA_TRANSITIONS.md`.

## Arquitetura de conteúdo (data-driven)

**[implemented]** Capítulo Zero é parte do jogo final via **um único projeto**, **um Player**, **uma shell** — sem duplicar sistemas nem copiar mapas para demo.

```text
ContentManifest (beta_demo | full_game)
└── ChapterData[]
    ├── AreaData[]           → scene_path, area_id, checkpoints
    ├── BossData[]           → boss_id, encounter_id, completion_flag
    ├── EncounterData[]      → arena packs, enemy_groups
    ├── AbilityData[]        → unlock gates
    ├── ObjectiveData[]      → template (JSON ou embedded)
    └── WorldEventData[]     → eventos + condições

ContentRegistry (runtime gate)
├── is_chapter_available()
├── can_load_area_scene()
├── get_starting_area_scene()
└── is_save_compatible_with_manifest()
```

| Resource | Script | Papel |
| --- | --- | --- |
| `ContentManifest` | `content_manifest.gd` | Perfil do produto (`beta_demo`, `full_game`) |
| `ChapterData` | `chapter_data.gd` | Capítulo / ato narrativo |
| `AreaData` | `area_data.gd` | Área jogável + cena |
| `ObjectiveData` | `objective_data.gd` | Objetivos com estados (`ObjectiveState`) |
| `WorldEventData` | `world_event_data.gd` | Eventos com condições |
| `BossData` / `EncounterData` | `boss_data.gd`, `encounter_data.gd` | Chefes e encontros |
| `AbilityData` / `CollectibleData` | `ability_data.gd`, `collectible_data.gd` | Progressão futura |

Manifestos:

- `resources/content/manifests/beta_demo.tres` — só Capítulo Zero; `beta_end_chapter_id` = fim da beta
- `resources/content/manifests/full_game.tres` — Capítulo Zero jogável + stubs Atos I–IV + Mol-Khar

**Regra:** nenhum `if demo:` espalhado — consultar `ContentRegistry.get_active()`.

Boot: `GameBootState` carrega manifesto → `game.gd` ativa registry → `AreaTransitionManager`, `NarrativeDirector`, `DialogueController`, `SaveManager` e `VerticalSliceController` leem paths/flags do capítulo ativo.

Diálogo: `DialogueLibrary` já suporta `locale` por arquivo JSON (`dialogues_pt_br.json`).

Objetivos: estados implícitos em `ObjectiveTracker` (`LOCKED` → `ACTIVE` → `COMPLETED`); template em JSON ou `ObjectiveData` embedded.

Chefes: mesma base (`BossEncounterController`, `AttackData`, IA inimigo) — `BossData` só registra IDs e flags.

## Jogador

**[implemented]** `CharacterBody2D` + componentes combate:

- `HealthComponent`, `HitboxComponent`, `HurtboxComponent`
- `RedBrandComponent`, `InteractionDetector`

**[implemented-debt]** Lógica central em `player.gd` (~1700 linhas baseline).

**[target]** Componentes (refatoração documentada):

| Módulo | Responsabilidade |
| --- | --- |
| PlayerInputController | Input map, buffers, locks |
| PlayerMovementController | Física horizontal, pulo, gravidade |
| PlayerStateCoordinator | Estados alto nível |
| PlayerPresentationController | Visual; `%Visual` scale, não body |
| PlayerDebugView | Overlay debug; off em release |

Player permanece **coordenador**; combate/hitbox ficam no script principal até split futuro.

## Combate

**[implemented]** `AttackData`, hitbox/hurtbox, fases startup/active/recovery, hitstop request, estilo, Red Brand Breaker.

## Inimigos

**[implemented]** Cult Brawler, Deacon Rusk, dummies de teste.

**[planned-beta]** Três arquétipos visuais sobre IA existente.

## Sistemas na shell

| Sistema | Estado |
| --- | --- |
| `GameplayLockManager` | [implemented] tokens diálogo/transição/morte/hitstop |
| `HitstopController` | [implemented-debt] sem `Engine.time_scale` global |
| `StyleManager` | [implemented-debt] acoplado a StyleHud |
| `SaveManager` | [implemented-debt] F8/F9; paths internos player |
| `DialogueController` | [implemented] |
| `BarrierRegistry` | [implemented] |
| `CombatArenaController` | [implemented-debt] fail-safe se inimigos somem |
| `BossEncounterController` | [implemented] |

## Salvamento

**[implemented]** `SaveData` v1, validação, backup, escrita atômica.

Persiste: área, posição, vida, Red Brand, flags, checkpoints, barreiras.

Campos opcionais v1 (content architecture): `content_manifest_id`, `chapter_id` — ver `SAVE_COMPATIBILITY.md`.

Restore de área validado via `ContentRegistry.can_load_area_scene()` (não carrega mundo inteiro).

**Importante:** `auto_load_on_ready = false` na greybox — **sem** load automático ao abrir o jogo. F9 manual.

**[target]** `capture_persistence_state()` no player; auto-load beta com validação de área.

## Corrupção ambiental

**[planned-beta]** Uma variante curta Capítulo Zero.

**[target]** Camadas substituíveis em `AreaRoot` — ver `ARCHITECTURE.md` seção anterior em `NARRATIVE_BIBLE.md`.

## Testes

**[implemented]**

| Artefato | Função |
| --- | --- |
| `scripts/tests/test_runner.gd` | 18 suítes, exit code |
| `content_registry_tests.gd` | Manifesto beta/full, gate de áreas, save policy |
| `scripts/tests/test_helpers.gd` | Fixtures, allowlist |
| `scripts/tests/runtime_error_monitor.gd` | Erros/warnings inesperados |
| `player_regression_tests.gd` | 26 contratos player |
| `gameplay_lock_tests.gd` | Locks + hitstop |
| `vertical_slice_regression_tests.gd` | Fluxo demo |

Comandos: `TEST_MATRIX.md`, `HEADLESS_TESTING.md`.

## Depuração

**[implemented]** F debug hitboxes; R respawn; F7 reset demo; F8/F9 save/load; Esc panic unlock.

**[target]** Debug desligável em release (`PlayerDebugView.enabled_in_debug_builds`).

## Documentos relacionados

- `TECH_DEBT.md`, `DECISIONS.md`, `CURRENT_IMPLEMENTATION.md`
- `PLAYER_PUBLIC_API.md`, `PLAYER_BEHAVIOR_CONTRACT.md` — contratos regressão
