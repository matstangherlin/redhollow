# Red Hollow — Stabilization Gate Report

**Data:** 2026-07-13
**Repositório:** `matstangherlin/redhollow`
**Branch:** `main`
**Commit auditado:** `4f20f76e5f505f36eacdb9866d7d7e33404c15f3` (`4f20f76`)
**Versão:** `0.2.0-beta.1`
**Godot:** 4.7 stable
**Main scene:** `res://scenes/product/main_menu.tscn`
**Gameplay entry:** `res://scenes/demo/vertical_slice_greybox.tscn`

## Veredito formal

# BASELINE DE CÓDIGO ESTABELECIDO — GATE DE RELEASE REPROVADO

`4f20f76` passa a ser o baseline canônico da beta porque contém as três áreas North Star e corrige o crash das catacumbas. O estado não pode ser promovido a release:

1. o runner registra **30** suítes, não 23/27;
2. o resultado agregado é **25 PASS / 4 FAIL / 1 TIMEOUT**;
3. o runner completo não termina quando `modular_kit_tests` trava;
4. o playthrough manual não foi assinado;
5. a build local existente é de um commit antigo e não foi aprovada;
6. a arte continua procedural/pilot, sem assets finais.

## 1. Pré-condições

| Verificação | Resultado |
| --- | --- |
| HEAD | `4f20f76e5f505f36eacdb9866d7d7e33404c15f3` — PASS |
| Branch | `main` — PASS |
| Remote | `https://github.com/matstangherlin/redhollow.git` — PASS |
| Tracked changes antes da auditoria | Nenhuma |
| Working tree limpa | **Não** — 18 arquivos untracked preexistentes |
| `.godot/`, `.import/` | Ignoradas |
| Builds/exports | Ignorados |
| Source art pesada | Calder protegido; Cult Brawler com gap de ignore |

## 2. Execução do gate

### 2.1 Comandos

O wrapper solicitado foi tentado primeiro:

```powershell
.\tools\test_all.ps1
```

Resultado: bloqueado pela política local de execução (`PSSecurityException`). Foi usado o comando portável documentado, com o executável Godot 4.7 e `--log-file` isolado.

### 2.2 Quantidade real

Contagem direta das entradas do array `SUITES` em `scripts/tests/test_runner.gd`: **30**.

### 2.3 Resultado agregado auditado

| Métrica | Resultado |
| --- | --- |
| Suítes registradas | 30 |
| Aprovadas | 25 |
| Falhas | 4 |
| Timeouts | 1 |
| Unexpected issues parsed | 1 |
| Allowed issues parsed | 13 |
| Leaks observados | 43 objetos; 6 resources (`world_map_graph_tests`) |
| Exit do lote crítico isolado | 1 |
| Exit atribuído ao timeout | 124 |
| Exit do runner completo | **Ausente** — runner travou e não retornou summary |
| Duração runner completo | >300 s antes de interrupção controlada |
| Duração das 13 críticas | 51,2 s |
| Duração da sonda modular | >180 s; processo não encerrou sozinho |

### 2.4 Suítes com problema

| Suíte | Resultado | Evidência |
| --- | --- | --- |
| `vertical_slice_verification` | FAIL | 5/7; 2 alvos antigos de igreja greybox |
| `vertical_slice_regression_tests` | FAIL | 12/14; retornos ainda esperam cenas greybox |
| `content_registry_tests` | FAIL | 17/18; `street scene allowed` |
| `world_map_graph_tests` | FAIL | 9/10; `Area not available in this build`; 1 unexpected warning |
| `modular_kit_tests` | TIMEOUT | >180 s; impede término do runner |

### 2.5 Warnings permitidos

| Suíte | Allowed | Motivo |
| --- | ---: | --- |
| `dialogue_tests` | 2 | ID de diálogo ausente injetado |
| `save_tests` | 7 | JSON corrompido/backup injetados |
| `combat_arena_tests` | 1 | integridade `living_enemy_despawned` injetada |
| `product_shell_tests` | 1 | save corrompido em inspeção |
| `player_visual_pipeline_tests` | 1 | fallback de clip ausente |
| `feedback_system_tests` | 1 | câmera sem target no fixture |
| **Total** | **13** | |

O processo pai também emite os erros conhecidos de autoload ausente (`SettingsManager`, `InputDeviceManager`). Eles não são contabilizados pelo parser das suítes e permanecem abertos como KI-108.

## 3. Suítes críticas isoladas

| Suíte | Asserts | Exit | Unexpected | Allowed | Resultado |
| --- | ---: | ---: | ---: | ---: | --- |
| `area_transition_tests` | 6/6 | 0 | 0 | 0 | PASS |
| `combat_arena_tests` | 15/15 | 0 | 0 | 1 | PASS |
| `player_respawn_tests` | 6/6 | 0 | 0 | 0 | PASS |
| `vertical_slice_regression_tests` | 12/14 | 1 | 0 | 0 | **FAIL** |
| `street_beta_complete_tests` | 5/5 | 0 | 0 | 0 | PASS |
| `church_beta_complete_tests` | 6/6 | 0 | 0 | 0 | PASS |
| `underground_beta_complete_tests` | 6/6 | 0 | 0 | 0 | PASS |
| `beta_integration_smoke_tests` | 22/22 | 0 | 0 | 0 | PASS |
| `player_visual_pipeline_tests` | 8/8 | 0 | 0 | 1 | PASS |
| `calder_asset_validation_tests` | 6/6 | 0 | 0 | 0 | PASS |
| `cult_brawler_visual_tests` | 6/6 | 0 | 0 | 0 | PASS |
| `region_visual_tests` | 6/6 | 0 | 0 | 0 | PASS |
| `world_map_graph_tests` | 9/10 | 1 | 1 | 0 | **FAIL** |

**Resumo crítico:** 11 PASS, 2 FAIL, 0 timeout.

## 4. Validação específica do crash das catacumbas

| # | Critério | Evidência | Resultado |
| --- | --- | --- | --- |
| 1 | `vertical_slice_underground_art.tscn` carrega | carga direta headless, exit 0 em 1,68 s | PASS |
| 2 | `UndergroundArtArea` entra na `SceneTree` | cena instanciada e adicionada ao root na suíte | PASS |
| 3 | apresentação deferred é criada | `call_deferred("_apply_visual_mode")`; não nula após 3 frames | PASS |
| 4 | checkpoint existe | `WorldObjects/UndergroundCheckpoint` | PASS |
| 5 | Deacon Rusk existe | `DeaconRusk` e `DeaconRuskEncounter` | PASS |
| 6 | exit para igreja existe | `Exits/ToChurchExit` → `vertical_slice_church_art.tscn` | PASS |
| 7 | hooks do finale existem | shadow Mol-Khar, silhueta Arcturus, statue eyes/hidden passage | PASS |
| 8 | sem erro de `NodePath` | carga direta e suíte sem erro | PASS |
| 9 | sem crash | exit 0, cena permaneceu na árvore | PASS |
| 10 | teste falha sem apresentação | sonda temporária desabilitou apresentação: exit 1 esperado | PASS |

A sonda temporária foi removida após a contraprova. Nenhum arquivo de gameplay foi alterado.

## 5. Estado das três áreas

| Área | Integração técnica | Teste dedicado | Arte final | Manual/performance |
| --- | --- | --- | --- | --- |
| Rua North Star | Completa para pilot procedural | 5/5 PASS | Ausente | Pendente |
| Igreja North Star | Completa para pilot procedural | 6/6 PASS | Ausente | Pendente |
| Catacumbas North Star | Completa; crash corrigido | 6/6 PASS + carga direta | Ausente | Pendente |

## 6. Build, arte e playthrough

### Build

- Presets Debug/Release e `tools/build_windows.ps1` existem.
- Há executáveis locais ignorados, mas o manifest aponta para `1c8e89d`, não `4f20f76`.
- O manifest registra runner FAIL e `qa_release_approved: false`.
- Resultado: **build do baseline atual pendente**.

### Arte

- Pipelines, profiles, factories, fallback procedural e validators existem.
- Não há conjunto final de sheets/PNGs para Calder, inimigos e ambientes.
- Resultado: **arte final não iniciada/aprovada**.

### Playthrough

- Não há assinatura manual do fluxo menu→fim.
- Performance, legibilidade, gamepad, save/reboot e retorno ao menu continuam pendentes.

## 7. Prioridades

### P0

1. restaurar gate 30/30 com término normal e exit 0;
2. assinar playthrough manual completo;
3. gerar e aprovar build Windows de `4f20f76` ou do commit de correção subsequente.

### P1

1. alinhar contratos legados às cenas North Star;
2. corrigir registry/world map;
3. eliminar hang do kit modular e tornar timeout efetivo;
4. limpar/normalizar artefatos untracked e proteger source art do Cult Brawler.

### P2

1. corrigir leaks de teardown;
2. remover ruído de autoload no processo pai;
3. revisar allowlists e panic unlock antes do release.

## 8. Decisão

| Gate | Estado |
| --- | --- |
| Baseline canônico de estabilização | **APROVADO: `4f20f76`** |
| Correção do crash das catacumbas | **APROVADA** |
| Gate automatizado | **REPROVADO** |
| Playthrough manual | **PENDENTE** |
| Build Windows atual | **REPROVADA / inexistente para o commit** |
| Arte final | **NÃO APROVADA** |
| Ship beta pública | **BLOQUEADO** |
