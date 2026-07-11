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

Áreas vertical slice:

- `vertical_slice_street.tscn`
- `vertical_slice_church.tscn`
- `vertical_slice_underground.tscn`

Legado teste: `street_test`, `church_entrance_test`, `underground_test`.

Ver `AREA_TRANSITIONS.md`.

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

**Importante:** `auto_load_on_ready = false` na greybox — **sem** load automático ao abrir o jogo. F9 manual.

**[target]** `capture_persistence_state()` no player; auto-load beta com validação de área.

## Corrupção ambiental

**[planned-beta]** Uma variante curta Capítulo Zero.

**[target]** Camadas substituíveis em `AreaRoot` — ver `ARCHITECTURE.md` seção anterior em `NARRATIVE_BIBLE.md`.

## Testes

**[implemented]**

| Artefato | Função |
| --- | --- |
| `scripts/tests/test_runner.gd` | 10 suítes, exit code |
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
