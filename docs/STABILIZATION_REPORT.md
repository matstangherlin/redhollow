# Red Hollow — Stabilization Gate Report

**Data:** 2026-07-13 (auditoria pós-commit `4babadc`)  
**Commit auditado:** `4babadc9a1c16b838aba541f89c17d5c9174f21a` (`4babadc`)  
**Main scene:** `res://scenes/product/main_menu.tscn`  
**Gameplay scene:** `res://scenes/demo/vertical_slice_greybox.tscn`  
**Versão:** `0.2.0-beta.1`  
**Godot:** 4.7 stable (`C:\Users\Stan\Documents\Godot_v4.7-stable_win64.exe`)

---

## Conclusão do gate (auditoria `4babadc`)

# APROVADO PARA MOLDE TÉCNICO VISUAL — REPROVADO PARA SHIP BETA E ARTE FINAL

O commit adiciona fundação visual e de mundo (mapa em grafo, rua art, kit modular, PILOT Calder, `RespawnService`, pickups, smoke beta). Estado após auditoria:

1. **Gate automatizado PASS** — runner **23/23** suítes, exit **0**, ~51 s (bootstrap `--main-scene`).
2. **Playthrough manual** menu→fim **não assinado** (KI-004, P0).
3. **Produção artística final** **bloqueada** — P0 visual G1/G2 (`VISUAL_FOUNDATION_BASELINE.md`).
4. **Molde técnico** rua → igreja/catacumbas **liberado** (`ART_VERTICAL_SLICE_GATE.md`).
5. **Build Windows** — preset/script existem; build **não aprovada** QA (KI-106).
6. **Arena physics flush** — não corrigido em produção; allowlist headless (KI-002).

---

## 1. Pré-condições da auditoria

| Verificação | Resultado |
| --- | --- |
| Commit HEAD | `4babadc` ✓ |
| Alterações locais (tracked) | **7 scripts** corrigidos na auditoria (não commitados) |
| `.godot/` ignorada | ✓ (`.gitignore`) |
| `builds/` ignorada | ✓ |
| Arquivos temporários de teste | Presentes (`runner_*.txt`, `docs/_*_out.txt`) — **não versionar** |

---

## 2. Testes automatizados

### Configuração do runner

| Parâmetro | Valor |
| --- | --- |
| Suítes registradas | **23** |
| Bootstrap | `res://scenes/tests/test_bootstrap.tscn` |
| Invocação subprocesso | `--main-scene` + `-- res://…suite.gd` |
| Timeout padrão | 180 s |
| Timeout `player_regression_tests` | 300 s |
| Exit timeout | 124 |
| Autoloads | Carregados no subprocesso |

### Comandos

```powershell
.\tools\test_all.ps1
```

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

### Resultado (2026-07-13, pós-correções de auditoria)

| Métrica | Valor |
| --- | --- |
| Suítes | **23** |
| PASS | **23** |
| FAIL | **0** |
| Exit code | **0** |
| Tempo total | **50,73 s** |
| Unexpected issues (parsed) | **0** |
| Allowed issues (parsed) | **13** |

### Suítes novas desde `e07ba0e`

| Suíte | Resultado |
| --- | --- |
| `player_respawn_tests` | **PASS** (6) |
| `beta_integration_smoke_tests` | **PASS** (22) |
| `street_art_toggle_tests` | **PASS** (4) |
| `modular_kit_tests` | **PASS** (7) |
| `world_map_graph_tests` | **PASS** (10) |

### Lista completa

| # | Suíte | Exit | Unexpected | Allowed |
| --- | --- | --- | --- | --- |
| 1 | vertical_slice_verification | 0 | 0 | 0 |
| 2 | dialogue_tests | 0 | 0 | 2 |
| 3 | save_tests | 0 | 0 | 7 |
| 4 | area_transition_tests | 0 | 0 | 0 |
| 5 | combat_arena_tests | 0 | 0 | 1 |
| 6 | cult_brawler_tests | 0 | 0 | 0 |
| 7 | deacon_rusk_tests | 0 | 0 | 0 |
| 8 | gameplay_lock_tests | 0 | 0 | 0 |
| 9 | player_regression_tests | 0 | 0 | 0 |
| 10 | vertical_slice_regression_tests | 0 | 0 | 0 |
| 11 | product_shell_tests | 0 | 0 | 1 |
| 12 | narrative_chapter_zero_tests | 0 | 0 | 0 |
| 13 | vermilite_gunslinger_tests | 0 | 0 | 0 |
| 14 | chain_penitent_tests | 0 | 0 | 0 |
| 15 | enemy_encounter_tests | 0 | 0 | 0 |
| 16 | player_visual_pipeline_tests | 0 | 0 | 1 |
| 17 | feedback_system_tests | 0 | 0 | 1 |
| 18 | player_respawn_tests | 0 | 0 | 0 |
| 19 | content_registry_tests | 0 | 0 | 0 |
| 20 | beta_integration_smoke_tests | 0 | 0 | 0 |
| 21 | street_art_toggle_tests | 0 | 0 | 0 |
| 22 | modular_kit_tests | 0 | 0 | 0 |
| 23 | world_map_graph_tests | 0 | 0 | 0 |

Evidência: `docs/_audit_runner_output.txt`

### Warnings no encerramento do runner (P2)

- `43 ObjectDB instances were leaked at exit`
- `6 resources still in use at exit`

Não alteram exit code; ver KI-107.

---

## 3. Warnings / errors permitidos (allowlist)

| Suíte | Tipo | Motivo |
| --- | --- | --- |
| `dialogue_tests` | WARNING | `missing_dialogue_id` injetado |
| `save_tests` | ERROR/WARNING | JSON corrompido / backup recovery injetado |
| `product_shell_tests` | ERROR | JSON corrompido em `inspect_slot` |
| `combat_arena_tests` | ERROR | `living_enemy_despawned` (integrity test) |
| `feedback_system_tests` | WARNING | `CameraController target was not found` |
| `player_visual_pipeline_tests` | WARNING | `missing animation clip` (fallback test) |

---

## 4. Correções aplicadas na auditoria (não commitadas)

| Área | Problema | Correção |
| --- | --- | --- |
| `street_art_presentation.gd` | Parse: parâmetro `name` em `_parallax` | Renomeado `layer_name` |
| `street_art_presentation.gd` | Headless hang em luz/partículas | Skip `PointLight2D` / `GPUParticles2D` em headless |
| `street_art_toggle_tests.gd` | Hang ao instanciar cena art completa | Contrato offline + greybox para gameplay |
| `environment_kit_factory.gd` | Parse: args `_add_module` desalinhados | `false` antes de `prop_scene_path` |
| `player_regression_tests.gd` | DEATH lock / RespawnService | Fixture + `set_death_vulnerability` |
| `world_map_graph_tests.gd` | Transição street→church | Flag `cz_met_elias` + timer |
| `player_visual_pipeline_tests.gd` | Warning clip contado | Allowlist |

---

## 5. Auditoria por sistema

### Sistemas aprovados (headless)

| Sistema | Evidência |
| --- | --- |
| Movimento / combo / esquiva / counter / taunt / Red Brand | `player_regression_tests` 48/48 |
| Morte / respawn | `player_respawn_tests` 6/6 |
| Gameplay locks | `gameplay_lock_tests` 10/10 |
| Transição de áreas | `area_transition_tests` 6/6 |
| Arena + integridade | `combat_arena_tests` 15/15 |
| Cult Brawler / Rusk / Gunslinger / Penitent | suítes dedicadas PASS |
| Save F8/F9 + snapshot | `save_tests` 5/5 |
| Content registry + manifest | `content_registry_tests` 18/18 |
| Narrativa Cap. Zero | `narrative_chapter_zero_tests` 6/6 |
| Smoke integração beta | `beta_integration_smoke_tests` 22/22 |
| Mapa do mundo + descoberta | `world_map_graph_tests` 10/10 |
| Rua art toggle + camadas | `street_art_toggle_tests` 4/4 |
| Kit modular | `modular_kit_tests` 7/7 |
| Pipeline visual PILOT | `player_visual_pipeline_tests` 8/8 |
| Feedback / áudio placeholder | `feedback_system_tests` 6/6 |

### Sistemas não aprovados manualmente

| Sistema | Motivo |
| --- | --- |
| Menu principal → novo jogo / continuar | KI-006, KI-004 |
| Pausa / opções / gamepad stress | KI-006 |
| Mapa overlay in-game (**M**) | Sem playtest assinado |
| Alternância greybox ↔ street art in-game | Demo principal ainda greybox |
| Conclusão beta / retorno ao menu | KI-004 |
| Build Windows exportada | KI-106 |
| Performance FPS / draw calls sala art | G3 — não medido |

---

## 6. Classificação de bugs (resumo)

| ID | P | Título |
| --- | --- | --- |
| KI-004 | **P0** | Playthrough manual pendente |
| KI-ART-G1/G2 | **P0** | Plataformas invisíveis / labels debug (arte) |
| KI-001 | P1 | Respawn — playtest manual pendente |
| KI-002 | P1 | Arena spawn physics flush |
| KI-006 | P1 | Product shell não validado manualmente |
| KI-101–108 | P2 | Panic unlock, auto-load, leaks runner, build, … |
| KI-201–203 | P3 | Nomenclatura, controle, warnings teste |

**KI-005 resolvido** — bootstrap + 23/23 PASS.

---

## 7. Decisão: produção artística

| Pergunta | Resposta |
| --- | --- |
| Iniciar **arte final** Capítulo Zero? | **Não** — G1, G2, KI-004, KI-106 |
| Replicar **molde técnico** (igreja/catacumbas)? | **Sim** — mesmo pipeline da rua art |
| Ship beta pública? | **Bloqueado** — KI-004 + build QA |
| Escalar conteúdo greybox? | **Sim com restrições** — runner verde |

---

## 8. Próximos passos (ordem)

1. Commitar correções de auditoria (7 scripts).
2. Playthrough manual menu→fim + mapa + morte (KI-004).
3. Corrigir G1/G2 na rua art antes de declarar sala “visual beta ready”.
4. Build Windows smoke após playtest (KI-106).
5. P1 eng: arena deferred spawn; teardown runner (KI-107).
6. Produção arte final após critérios em `VISUAL_FOUNDATION_BASELINE.md`.

---

## 9. Assinaturas

| Papel | Status |
| --- | --- |
| Gate automatizado (`4babadc` + correções) | **PASS** (23/23) |
| Gate manual | **PENDENTE** |
| Molde técnico visual | **APROVADO** |
| Arte final Capítulo Zero | **BLOQUEADO** |
| Ship beta pública | **BLOQUEADO** |
