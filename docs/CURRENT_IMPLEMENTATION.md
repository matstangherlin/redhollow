# Red Hollow — Current Implementation

Inventário do que **existe no repositório** na vertical slice técnica greybox.  
**Baseline tag:** `greybox-vertical-slice-v0.1` (`ae65a5084c1cbece80672a67d4bc0a6b4d40e5df`).  
**Commit base registrado:** `1c8e89d` (+ working tree com refatoração pós-gate, ver `STABILIZATION_REPORT.md`).  
**Gate estabilização:** 2026-07-11 — **APROVADO COM RESTRIÇÕES**.

Legenda:

| Tag | Significado |
| --- | --- |
| **OK** | Implementado e razoavelmente funcional |
| **DEBT** | Implementado com dívida técnica |
| **BETA** | Planejado para Capítulo Zero (beta) |
| **FINAL** | Planejado somente para o jogo final |

## Configuração do projeto

| Item | Valor | Tag |
| --- | --- | --- |
| Engine | Godot **4.7** (`config/features`) | OK |
| Main scene | `res://scenes/demo/vertical_slice_greybox.tscn` | OK |
| FPS alvo | 60 (`run/max_fps`) | OK |
| Autoloads de gameplay | Nenhum — shell persistente na main scene | OK |

## Shell e orquestração

| Sistema | Arquivo / cena | Tag |
| --- | --- | --- |
| Demo greybox (shell) | `vertical_slice_greybox.tscn`, `game.gd` | OK |
| `GameServices` | `game_services.gd` — bind tipado shell/área | OK |
| WorldHost (área dinâmica) | filho de greybox | OK |
| Vertical slice controller | `vertical_slice_controller.gd` | OK |
| Hitstop | `hitstop_controller.gd` | DEBT |
| Gameplay locks | `gameplay_lock_manager.gd` | OK |
| Panic unlock (Esc) | `game.gd` / demo | DEBT |

## Jogador (Calder Knox)

| Funcionalidade | Tag | Notas |
| --- | --- | --- |
| Movimento lateral | OK | `PlayerMovementController` |
| Pulo, coyote, buffer, queda variável | OK | |
| Combo 3 golpes | OK | `PlayerAttackController` + `AttackData` |
| Hitbox / hurtbox separadas | OK | |
| Esquiva com i-frames | OK | `PlayerDefenseController` |
| Counter com janela | OK | |
| Provocação | OK | `PlayerTauntController` |
| Red Brand Breaker (U) | OK | `PlayerRedBrandController` |
| Estados (idle…dead) | OK | `PlayerStateCoordinator` |
| Coordenador `player.gd` | DEBT | ~791 linhas (baseline ~1700) |
| Save API | OK | `export_save_state` / `import_save_state` |
| Debug overlay (F) | DEBT | `PlayerDebugView` |
| Morte / respawn consolidado | DEBT | Lock DEATH OK; serviço respawn ausente |

### Controllers player (working tree)

| Controller | Linhas (aprox.) | Responsabilidade |
| --- | ---: | --- |
| `PlayerInputController` | 166 | Entrada, buffers |
| `PlayerMovementController` | 132 | Física, coyote, recovery |
| `PlayerAttackController` | 242 | Combo, hitbox, counter ofensivo |
| `PlayerDefenseController` | 299 | Esquiva, counter defensivo, invuln |
| `PlayerTauntController` | 160 | Provocação |
| `PlayerRedBrandController` | 177 | Brand breaker |
| `PlayerStateCoordinator` | 45 | Estados alto nível |
| `PlayerPresentationController` | 89 | Cores provisórias |
| `PlayerVisualController` | — | Camada sprite substituível (PLACEHOLDER/PILOT/FINAL) |
| `PlayerDebugView` | 70 | Overlay debug |
| `PlayerStateSnapshot` | 25 | Contrato save |

### Pipeline visual 2D (preparação arte)

| Item | Caminho | Tag |
| --- | --- | --- |
| Perfil placeholder (padrão) | `resources/visual/calder_placeholder_profile.tres` | OK |
| Perfil piloto (4 animações) | `resources/visual/calder_pilot_profile.tres` | OK |
| Controller visual | `scripts/visual/player_visual_controller.gd` | OK |
| Factory piloto procedural | `scripts/visual/placeholder_sprite_factory.gd` | OK |
| Docs produção | `ART_BIBLE.md`, `ANIMATION_PIPELINE.md`, etc. | OK |
| Testes pipeline | `scripts/visual/player_visual_pipeline_tests.gd` | OK |
| Arte final importada | `art/characters/calder/` | BETA |

Gameplay e hitboxes **não** dependem de `%SpriteVisual`; greybox `%BodyVisual` permanece padrão até perfil `FINAL`.

## Feedback áudio/VFX (beta)

| Item | Caminho | Tag |
| --- | --- | --- |
| FeedbackSystem | `scenes/core/feedback_system.tscn` | OK |
| AudioManager (pools por bus) | `scripts/audio/audio_manager.gd` | OK |
| Placeholder audio procedural | `scripts/audio/placeholder_audio_factory.gd` | OK |
| Ambient layers por área | `scripts/audio/ambient_audio_controller.gd` | OK |
| CombatVfxSpawner | `scripts/feedback/combat_vfx_spawner.gd` | OK |
| CombatFeedbackDirector | `scripts/feedback/combat_feedback_director.gd` | OK |
| Camera punch zoom + a11y | `scripts/core/camera_controller.gd` | OK |
| Licenças/inventário áudio | `docs/AUDIO_ASSETS.md` | OK |
| Testes feedback | `scripts/feedback/feedback_system_tests.gd` | OK |

## Combate e feedback

| Sistema | Tag |
| --- | --- |
| `AttackData` Resource | OK |
| `HitboxComponent` / `HurtboxComponent` | OK |
| `HealthComponent` | OK |
| `StyleManager` + ranks DUST→HOLLOW | OK |
| `StyleHud` | OK |
| Hitstop request | DEBT |

## Red Brand e progressão

| Sistema | Tag |
| --- | --- |
| `RedBrandComponent` | OK |
| `RedBrandDirector` | OK |
| Cristal Coração Rubro (igreja) | OK |
| Barreira destrutível Vermilite | OK |
| `BarrierRegistry` persistente | OK |
| `ProgressionComponent` (flags, checkpoints) | OK |

## Mundo e exploração

| Área / feature | Cena | Tag |
| --- | --- | --- |
| Rua | `vertical_slice_street.tscn` | OK |
| Igreja / distrito | `vertical_slice_church.tscn` | OK |
| Subterrâneo | `vertical_slice_underground.tscn` | OK |
| Transição de áreas | `AreaTransitionManager` | OK |
| Rebind runtime | `GameServices` + sinais área | OK |
| Exits + spawn points | `AreaExit`, `AreaSpawnPoint` | OK |
| Plataformas (greybox) | street | OK |
| Backtracking rua ↔ igreja ↔ sub | OK | Curto na demo |
| Catacumbas ilustradas | BETA | Greybox subterrâneo existe |
| Corrupção ambiental (Ressonância Rubra) | BETA | |

## NPCs, diálogo, interação

| Elemento | Tag |
| --- | --- |
| `DialogueController` + JSON PT-BR | OK |
| Elias (rua) | OK |
| `InteractionDetector` | OK |
| Cooldown reabertura diálogo (250 ms) | OK |

## Arena e inimigos

| Elemento | Tag |
| --- | --- |
| `CombatArenaController` + gates | DEBT |
| Integridade despawn | OK | `arena_integrity_failed` |
| Cult Brawler (rua + arena) | OK |
| `enemy_dummy`, `enemy_attacker_test` | OK |
| Deacon Rusk (mini-chefe) | OK |
| `BossEncounterController` | OK |
| `BossHealthHud` | OK |
| Três arquétipos visuais beta | BETA |
| Silas / Rosa / Magnus / Arcturus jogáveis | FINAL |

## Save e checkpoint

| Feature | Tag | Notas |
| --- | --- | --- |
| `SaveManager` + `SaveData` v1 | OK | |
| `PlayerStateSnapshot` | OK | Contrato tipado |
| F8 salvar / F9 carregar | OK | Manual |
| Auto-load ao boot | — | **Desativado** (`auto_load_on_ready = false`) |
| Checkpoint subterrâneo | OK | Auto-save ao ativar |
| Backup `.bak`, validação JSON | OK | |

## UI e conclusão

| Elemento | Tag |
| --- | --- |
| HUD estilo | OK |
| HUD chefe | OK |
| Diálogo UI | OK |
| Overlay conclusão demo | OK |
| Mapa / diário / pausa beta | BETA |

## Narrativa na demo técnica

| Elemento | Tag |
| --- | --- |
| Elias + diálogo igreja/culto | OK |
| Cristal + barreira Vermilite | OK |
| Deacon Rusk executor | OK |
| Estátua Mol-Khar | BETA |
| Aparição breve Mol-Khar | BETA |
| Silhueta / voz Arcturus | BETA |
| Pista parceiro antigo de Calder | BETA |
| Gancho narrativo final capítulo | BETA |

## Testes automatizados

| Suíte | Tag | Gate 2026-07-11 |
| --- | --- | --- |
| `test_runner.gd` (10 suítes) | OK | 10/10 PASS |
| `vertical_slice_verification.gd` | OK | 6/6 |
| `player_regression_tests.gd` | OK | 48 assertions |
| `gameplay_lock_tests.gd` | OK | 10/10 |
| `vertical_slice_regression_tests.gd` | OK | 13/13 |
| Zero unexpected runtime errors | OK | 0 unexpected; 45 allowed documentados |

Ver `TEST_MATRIX.md`, `STABILIZATION_REPORT.md`.

## Arte e áudio

| Item | Tag |
| --- | --- |
| Greybox geométrico (Polygon2D) | OK |
| Pixel art final | BETA |
| Trilha / SFX final | BETA / FINAL |

## O que **não** existe ainda

- Cidade completa de Red Hollow
- Palácio Rubro
- Forma física completa de Mol-Khar
- Luta completa contra Arcturus
- Todos os barões como chefes jogáveis
- Auto-load seguro ao iniciar
- UI mapa/diário/pausa da beta
- Serviço unificado de respawn pós-morte

Ver `BETA_DEMO_SCOPE.md`, `FINAL_GAME_SCOPE.md`, `TECH_DEBT.md`, `KNOWN_ISSUES.md`.
