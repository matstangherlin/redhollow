# Red Hollow — Current Implementation

Inventário do que **existe no repositório** na vertical slice técnica greybox.  
**Baseline commit:** `ae65a5084c1cbece80672a67d4bc0a6b4d40e5df` (tag `greybox-vertical-slice-v0.1`).  
**Branch de trabalho:** `beta-foundation`.

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
| WorldHost (área dinâmica) | filho de greybox | OK |
| Vertical slice controller | `vertical_slice_controller.gd` | OK |
| Hitstop | `hitstop_controller.gd` | DEBT |
| Gameplay locks | `gameplay_lock_manager.gd` | DEBT |
| Panic unlock (Esc) | `game.gd` / demo | DEBT |

## Jogador (Calder Knox)

| Funcionalidade | Tag | Notas |
| --- | --- | --- |
| Movimento lateral | OK | A/D, aceleração/desaceleração |
| Pulo, coyote, buffer, queda variável | OK | |
| Combo 3 golpes | OK | `AttackData` Resources |
| Hitbox / hurtbox separadas | OK | |
| Esquiva com i-frames | OK | |
| Counter com janela | OK | |
| Provocação | OK | Frases rotativas |
| Red Brand Breaker (U) | OK | Carga + release |
| Estados (idle…dead) | OK | Enum em `player.gd` |
| Monolito `player.gd` | DEBT | ~1700 linhas no baseline |
| Debug overlay (F) | DEBT | Acoplado ao gameplay |
| Morte / respawn consolidado | DEBT | Recuperação por queda OK; fluxo de morte incompleto |

## Combate e feedback

| Sistema | Tag |
| --- | --- |
| `AttackData` Resource | OK |
| `HitboxComponent` / `HurtboxComponent` | OK |
| `HealthComponent` | OK |
| `StyleManager` + ranks DUST→HOLLOW | DEBT |
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
| Transição de áreas | `AreaTransitionManager` | DEBT |
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
| Cult Brawler (rua + arena) | OK |
| `enemy_dummy`, `enemy_attacker_test` | OK |
| Deacon Rusk (mini-chefe) | OK |
| `BossHealthHud` | OK |
| Três arquétipos visuais beta | BETA |
| Silas / Rosa / Magnus / Arcturus jogáveis | FINAL |

## Save e checkpoint

| Feature | Tag | Notas |
| --- | --- | --- |
| `SaveManager` + `SaveData` v1 | DEBT | |
| F8 salvar / F9 carregar | OK | Manual |
| Auto-load ao boot | — | **Desativado** (`auto_load_on_ready = false`) |
| Checkpoint subterrâneo | OK | Auto-save ao ativar |
| Backup `.bak`, validação JSON | OK | |
| Captura via paths internos do player | DEBT | Ver `TECH_DEBT.md` |

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

| Suíte | Tag |
| --- | --- |
| `test_runner.gd` (10 suítes) | OK |
| `vertical_slice_verification.gd` | OK |
| `player_regression_tests.gd` | OK |
| `gameplay_lock_tests.gd` | OK |
| `vertical_slice_regression_tests.gd` | OK |
| Zero runtime errors em todas suítes | DEBT | Arena headless ainda declara erros permitidos |

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

Ver `BETA_DEMO_SCOPE.md`, `FINAL_GAME_SCOPE.md`, `TECH_DEBT.md`.
