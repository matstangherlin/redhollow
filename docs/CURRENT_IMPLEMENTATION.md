# Red Hollow — Current Implementation

Inventário do que **existe no repositório** no commit de baseline beta.

**Baseline commit:** `4babadc9a1c16b838aba541f89c17d5c9174f21a` (`4babadc`) — *Add world map graph, street art slice, and visual pilot pipeline.*  
**Commit anterior beta:** `e07ba0ecb8502d7a368017f1764599155e3e87bf` (`e07ba0e`)  
**Tag histórica greybox:** `greybox-vertical-slice-v0.1` (`ae65a5084c1cbece80672a67d4bc0a6b4d40e5df`).  
**Versão alvo:** `0.2.0-beta.1`  
**Engine:** Godot **4.7**

## Legenda de maturidade

| Termo | Significado |
| --- | --- |
| **Infra criada** | Arquivos/cenas/scripts existem; comportamento end-to-end não comprovado |
| **Integração concluída** | Sistema ligado ao fluxo jogável com evidência (teste auto ou manual documentado) |
| **Integração não validada** | Código presente; falta playthrough ou suíte confiável |
| **Conteúdo provisório** | Greybox, JSON stub, placeholder procedural — jogável mas não final |
| **Conteúdo final** | Arte/copy/narrativa prontos para ship beta |

Tags rápidas: **OK** funcional | **DEBT** dívida | **BETA** escopo beta pendente | **FINAL** jogo completo

---

## Configuração do projeto

| Item | Valor |
| --- | --- |
| Main scene | `res://scenes/product/main_menu.tscn` |
| Gameplay entry | `res://scenes/demo/vertical_slice_greybox.tscn` (via menu / boot) |
| FPS alvo | 60 |
| Autoloads | `SettingsManager`, `GameBootState`, `InputDeviceManager`, `InputSetup` |

---

## Tabela de status (commit `4babadc` — auditoria 2026-07-13)

| Sistema | Implementado | Testado auto | Testado manual | Dívida | Bloqueia beta | Próximo passo |
| --- | --- | --- | --- | --- | --- | --- |
| **Main menu + boot** | Integração concluída | Sim (`product_shell_tests` 10/10) | Pendente | Sim — fluxo menu→jogo não assinado | Sim (gate QA) | Playthrough menu→Capítulo Zero |
| **Opções / settings** | Integração concluída | Parcial (`product_shell_tests`) | Pendente | Sim | Não direto | Validar persistência + a11y |
| **Pausa** | Integração concluída | Parcial (smoke beta) | Pendente | Sim | Não direto | Testar pausa combate/diálogo/arena |
| **Product shell** | Integração concluída | Sim (`vertical_slice_regression`, smoke beta) | Pendente | Sim | Não direto | Assinar fluxo completo |
| **World map (grafo + overlay)** | Integração concluída | Sim (`world_map_graph_tests` 10/10) | Pendente | Baixa | Não | UI final + playtest tecla **M** |
| **Descoberta de áreas (save)** | Integração concluída | Sim (world map tests) | Pendente | Baixa | Não | Validar persistência F8/F9 |
| **RespawnService** | Integração concluída | Sim (`player_respawn_tests` 6/6) | Pendente | Média | Não direto | Playtest morte 13–15 |
| **Health pickups** | Infra criada | Indireto (smoke beta) | Pendente | Baixa | Não | Tuning + arte |
| **Street art (molde)** | Integração concluída | Sim (`street_art_toggle_tests` 4/4) | Pendente | Sim (G1/G2 art) | Arte final sim | Corrigir plataformas/labels debug |
| **Kit modular cenário** | Integração concluída | Sim (`modular_kit_tests` 7/7) | Pendente | Baixa | Não | Salas igreja/catacumbas |
| **Pipeline visual PILOT** | Integração concluída | Sim (`player_visual_pipeline_tests` 8/8) | Pendente | Sim — sprites finais ausentes | Arte final sim | Produzir sprites Cap. Zero |
| **Player — movimento/combate** | Integração concluída | Sim (`player_regression_tests` 48/48) | Pendente | Sim (`player.gd` ~800 linhas) | Não (runner verde) | Playtest manual |
| **test_runner (23 suítes)** | Integração concluída | **Gate PASS** 23/23, exit 0 | N/A | Leaks P2 (KI-107) | Não | Commitar correções auditoria |
| **Build Windows** | Infra criada | Não | Não | — | Sim (release) | Smoke após playtest manual |

*Demais linhas da tabela `e07ba0e` permanecem válidas salvo onde indicado acima (arena KI-002, save OK, inimigos OK, etc.).*

---

## Tabela de status legada (commit `e07ba0e` — referência histórica)
| **Opções / settings** | Infra criada (`options_menu`, `SettingsManager`, `SettingsData`) | Parcial (mesma falha runner) | Pendente | Sim | Não direto | Validar persistência + a11y em runtime |
| **Pausa** | Infra criada (`pause_menu`, `ProductShell`) | Não confiável no runner atual | Pendente | Sim | Não direto | Testar pausa durante combate/diálogo/arena |
| **Créditos / loading / confirmação** | Infra criada (cenas UI) | Não | Pendente | Sim | Não | Integrar no roteiro manual |
| **Product shell (greybox)** | Integração concluída (`game.gd`, `GameServices`, `ProductShell`) | Parcial (`vertical_slice_regression_tests` passa isolado) | Pendente | Sim | Não direto | Assinar fluxo completo com menu |
| **ContentManifest + Registry** | Integração concluída (`ContentRegistry`, manifests) | Sim (`content_registry_tests`) | Não | Baixa | Não | Expandir áreas no manifest conforme arte |
| **Capítulo Zero — dados** | Conteúdo provisório (JSON, stubs Atos, `chapter_zero_*`) | Sim (`narrative_chapter_zero_tests` falha no runner `--script`) | Pendente | Sim | Não direto | Balanceamento + copy final |
| **NarrativeDirector + objetivos** | Integração concluída | Falha runner `--script` | Pendente | Sim | Não direto | Gate manual passos 1–8 |
| **ObjectiveHud + story props** | Infra criada | Parcial | Pendente | Sim | Não | Arte UI + validação in-game |
| **Finale Cap. Zero (8 passos)** | Conteúdo provisório (`chapter_zero_finale.gd`) | Não | Pendente | Sim | Não direto | Playtest encerramento beta |
| **Player — movimento/combate** | Integração concluída (controllers) | Falha runner `--script` (`player_regression_tests`) | Pendente | Sim (`player.gd` ~800 linhas) | Sim (via KI-005 runner) | Estabilizar runner; depois regressão manual |
| **Player — morte/respawn** | Parcial — auto-respawn ~0,65 s + **R**; sem serviço unificado | Parcial (death lock auto; respawn manual pendente) | Pendente | Sim (KI-001) | Sim (ship) | Serviço respawn + cenários 13–15 |
| **Pipeline visual Calder** | Infra criada (profiles PLACEHOLDER/PILOT/FINAL) | Sim (`player_visual_pipeline_tests`) | Não | Sim — arte final ausente | Não | Produzir sprites Cap. Zero |
| **Feedback combate (VFX/camera/shake)** | Integração concluída | Sim (`feedback_system_tests`) | Pendente | Baixa | Não | Tuning + SFX final |
| **Áudio procedural placeholder** | Conteúdo provisório (`placeholder_audio_factory`) | Parcial | Pendente | Sim | Não | Substituir por assets licenciados |
| **3 áreas + transição** | Integração concluída | Falha runner `--script` (`area_transition_tests`) | Pendente | Baixa | Não direto | Runner + playtest backtracking |
| **Arena + Cult Brawler** | Integração concluída | Falha runner `--script` (`combat_arena_tests`) | Pendente | Sim (KI-002 physics flush) | Não direto | Deferred spawn; validar igreja manual |
| **Deacon Rusk** | Integração concluída | Falha runner `--script` (`deacon_rusk_tests`) | Pendente | Média | Não direto | Runner + boss playtest |
| **Vermilite Gunslinger** | Conteúdo provisório (greybox) | Sim (`vermilite_gunslinger_tests`) | Pendente | Sim — balance/arte | Não | Arte + tuning encontro |
| **Chain Penitent** | Conteúdo provisório (greybox) | Sim (`chain_penitent_tests`) | Pendente | Sim — balance/arte | Não | Arte + tuning encontro |
| **Projétil físico** | Infra criada | Indireto (gunslinger tests) | Pendente | Sim | Não | VFX + colisão em todos encontros |
| **Diálogo + interação** | Integração concluída | Falha runner `--script` (`dialogue_tests`) | Pendente | Baixa | Não direto | Estabilizar runner |
| **Save F8/F9 + checkpoint** | Integração concluída | Sim (`save_tests`) | Pendente | Sim (auto-load off) | Não direto | Decisão D-013 + testes boot |
| **Auto-load ao boot** | **Desativado** (`game.gd` / greybox `auto_load_on_ready = false`) | N/A | Pendente | Sim (intencional) | Sim (decisão produto) | Decidir política beta |
| **HUD estilo + vida + chefe** | Integração concluída | Parcial | Pendente | Baixa | Não | Skin final `UI_BIBLE` |
| **test_runner (18 suítes)** | Infra criada | **Gate FAIL** (~8/18 com `--script`; ver `KNOWN_ISSUES.md`) | N/A | Sim (KI-005 P0) | **Sim** | Bootstrap `--main-scene` + 18/18 PASS |
| **Export Windows preset** | Infra criada (`export_presets.cfg`) | Não | Não | — | Não | QA após runner verde |
| **Build script** | Infra criada (`tools/build_windows.ps1`) | Não | Não | — | Não | Gerar build após gate |
| **Build Windows gerada** | Possível localmente; **não versionada** em `builds/` | Não | Não | — | Sim (release) | Build + smoke test |
| **Build Windows aprovada** | **Não** | Não | Não | — | **Sim** | Runner verde + playthrough manual |

---

## Product shell e autoloads

| Sistema | Caminho | Notas |
| --- | --- | --- |
| Main menu | `scenes/product/main_menu.tscn` | Entry point do projeto |
| Loading | `scenes/ui/loading_screen.tscn` | Infra — transição não validada manualmente |
| Opções | `scenes/ui/options_menu.tscn` + `SettingsManager` | Persistência em `user://settings.json` |
| Pausa | `scenes/ui/pause_menu.tscn` + `ProductShell` | Integrado na greybox; pausa in-game pendente QA |
| Créditos | `scenes/ui/credits_screen.tscn` | Infra |
| Confirmação | `scenes/ui/confirmation_dialog.tscn` | Infra |
| Boot state | `game_boot_state.gd` | NEW_GAME / CONTINUE / manifest |
| Input | `input_device_manager.gd`, `input_setup.gd` | Prompts gamepad/teclado |

## Shell de gameplay (greybox)

| Sistema | Caminho | Tag |
| --- | --- | --- |
| Demo greybox | `vertical_slice_greybox.tscn`, `game.gd` | OK |
| `GameServices` | `game_services.gd` | OK |
| `AreaTransitionManager` | `area_transition_manager.gd` | OK |
| `GameplayLockManager` | `gameplay_lock_manager.gd` | OK |
| Panic unlock (Esc) | `game.gd` | DEBT |

## Jogador (Calder Knox)

Controllers dedicados: input, movimento, ataque, defesa, provocação, Red Brand, estado, apresentação, visual, debug.

| Funcionalidade | Tag | Notas |
| --- | --- | --- |
| Movimento / combo / esquiva / counter / taunt / Brand | OK | Controllers + `AttackData` |
| Coordenador `player.gd` | DEBT | ~800 linhas; orquestração residual |
| Morte / respawn | OK | `RespawnService` + auto 0,65 s + **R**; testes 6/6 |
| Pipeline visual | OK | PILOT 10 animações + fallback; arte final BETA |

## Arquitetura de conteúdo

| Item | Caminho | Tag |
| --- | --- | --- |
| `ContentManifest` | `scripts/content/content_manifest.gd` | OK |
| `ContentRegistry` | `scripts/content/content_registry.gd` | OK |
| Manifest beta | `resources/content/manifests/beta_demo.tres` | OK |
| Manifest jogo final | `resources/content/manifests/full_game.tres` | OK |
| Capítulo Zero | `resources/content/chapters/chapter_zero_bell_before_nightfall.tres` | Conteúdo provisório |

## World map e descoberta

| Item | Caminho | Tag |
| --- | --- | --- |
| `WorldGraph` beta | `resources/world/beta_world_graph.tres` | OK |
| `WorldMapService` | `scripts/world/world_map_service.gd` | OK |
| `WorldMapState` (save) | `scripts/world/world_map_state.gd` | OK |
| Overlay UI (**M**) | `scenes/ui/world_map_overlay.tscn` | OK (provisório) |
| Grafo jogo completo | `resources/world/full_game_world_graph.tres` | Infra (stub) |

## Street art e ambiente visual

| Item | Caminho | Tag |
| --- | --- | --- |
| Perfil visual rua | `resources/visual/chapter_zero_street_profile.tres` | OK |
| Apresentação 9 camadas | `scripts/visual/street_art_presentation.gd` | OK |
| Área art | `scenes/areas/vertical_slice_street_art.tscn` | OK (molde) |
| Demo principal | `vertical_slice_greybox` → **greybox** street | Conteúdo provisório |
| Gate visual | `docs/ART_VERTICAL_SLICE_GATE.md` | Molde aprovado |

## Kit modular

| Item | Caminho | Tag |
| --- | --- | --- |
| `EnvironmentKit` | `scripts/environment/environment_kit.gd` | OK |
| Factory + 20 módulos | `scripts/environment/environment_kit_factory.gd` | OK |
| Salas exemplo | `scenes/environment/modular/kit_room_*.tscn` | OK |
| `PropCatalog` | `scripts/environment/prop_catalog.gd` | OK |

## Respawn e pickups

| Item | Caminho | Tag |
| --- | --- | --- |
| `RespawnService` | `scripts/player/respawn_service.gd` | OK |
| `HealthPickup` | `scripts/world/health_pickup.gd` | Infra criada |

## Combate, inimigos, feedback

| Sistema | Tag |
| --- | --- |
| Cult Brawler | OK (greybox) |
| Vermilite Gunslinger + projétil | OK (provisório) |
| Chain Penitent | OK (provisório) |
| Deacon Rusk + boss HUD | OK |
| FeedbackSystem + AudioManager placeholder | OK (provisório) |
| Combat arena | DEBT (physics flush KI-002) |

## Narrativa Capítulo Zero

| Item | Tag |
| --- | --- |
| Objetivos / eventos JSON | Conteúdo provisório |
| `NarrativeDirector` | Integração concluída |
| Diálogos `cz_*` | Conteúdo provisório |
| Props (medalhão, diário, etc.) | Infra criada |
| Finale 8 passos | Conteúdo provisório — não substitui QA narrativo |

## Save

| Feature | Tag | Notas |
| --- | --- | --- |
| F8/F9 manual | OK | |
| Checkpoint subterrâneo | OK | Auto-save ao ativar |
| Auto-load boot | **Off** | `SaveManager.auto_load_on_ready = false` em `game.gd` |
| `PlayerStateSnapshot` | OK | |

## Testes automatizados (commit `4babadc` — auditoria 2026-07-13)

| Métrica | Valor |
| --- | --- |
| Suítes registradas | **23** |
| Runner | `scripts/tests/test_runner.gd` |
| Bootstrap | `scenes/tests/test_bootstrap.tscn` (`--main-scene`, autoloads OK) |
| Gate | **PASS** — 23/23, exit 0, ~51 s |
| Timeout padrão | 180 s (`player_regression_tests`: 300 s) |
| Exit timeout | 124 |

Suítes novas vs `e07ba0e`: `player_respawn_tests`, `beta_integration_smoke_tests`, `street_art_toggle_tests`, `modular_kit_tests`, `world_map_graph_tests`.

Comando:

```powershell
.\tools\test_all.ps1
```

Ver `TEST_MATRIX.md`, `STABILIZATION_REPORT.md`, `docs/_audit_runner_output.txt`.

## Testes automatizados legado (commit `e07ba0e` — referência)

## Build Windows (estado separado)

| Etapa | Estado no commit |
| --- | --- |
| Preset criado | Sim — `export_presets.cfg` (Debug + Release) |
| Script build | Sim — `tools/build_windows.ps1` |
| Build gerada | Possível local; pasta `builds/` não versionada |
| Build testada (smoke) | **Não documentado / não assinado** |
| Build aprovada QA | **Não** |

## O que **não** existe ainda

- Cidade completa, Palácio Rubro, Mol-Khar/Arcturus jogáveis completos
- Arte pixel **final** Capítulo Zero (pipeline PILOT pronto; assets finais pendentes)
- Mapa/diário UI **final** (overlay grafo provisório existe; tecla **M**)
- Auto-load policy fechada para beta
- Playthrough manual menu→fim assinado (KI-004)
- Build Windows QA-approved
- Demo principal ainda em **greybox** (rua art é cena paralela)

Ver `BETA_DEMO_SCOPE.md`, `KNOWN_ISSUES.md`, `STABILIZATION_REPORT.md`, `TEST_MATRIX.md`, `VISUAL_FOUNDATION_BASELINE.md`.
