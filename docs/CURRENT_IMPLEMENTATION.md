# Red Hollow — Current Implementation

Inventário formal do que existe no repositório no baseline de estabilização da beta.

**Baseline canônico:** `4f20f76e5f505f36eacdb9866d7d7e33404c15f3` (`4f20f76`) — *Fix underground area crash when entering catacombs.*
**Branch auditada:** `main`
**Data da auditoria:** 2026-07-13
**Versão:** `0.2.0-beta.1`
**Engine:** Godot 4.7

> `4f20f76` é o novo baseline de código e conteúdo da beta. Ele **não** é uma build aprovada para release: o gate automatizado não está verde, o playthrough manual não foi assinado e não existe build QA do commit atual.

## Configuração do projeto

| Item | Valor |
| --- | --- |
| Repositório | `matstangherlin/redhollow` |
| Main scene | `res://scenes/product/main_menu.tscn` |
| Gameplay entry | `res://scenes/demo/vertical_slice_greybox.tscn` (via menu/boot) |
| FPS alvo | 60 |
| Autoloads | `SettingsManager`, `GameBootState`, `InputDeviceManager`, `InputSetup` |
| Save manual | F8 salva; F9 carrega |
| Auto-load | Desativado na sessão greybox |

## Estado do checkout na auditoria

| Verificação | Resultado |
| --- | --- |
| HEAD esperado | **PASS** — `4f20f76e5f505f36eacdb9866d7d7e33404c15f3` |
| Branch esperada | **PASS** — `main` |
| Alterações tracked antes da auditoria | Nenhuma |
| Working tree limpa | **NÃO** — 18 arquivos não rastreados preexistentes de testes/auditorias |
| `.godot/` e `.import/` | Ignoradas |
| Builds/exportações | `build/`, `builds/`, `export/`, `exports/`, `dist/` ignorados |
| Source art Calder | Arquivos pesados em `art/characters/calder/source/` ignorados |
| Source art Cult Brawler | **Gap:** `.psd/.aseprite` em `art/characters/enemies/cult_brawler/source/` não estão ignorados |

Os 18 arquivos não rastreados preexistentes foram preservados. Esta auditoria alterou somente a documentação solicitada.

## Estado por sistema

| Sistema | Estado atual | Evidência / ressalva |
| --- | --- | --- |
| Product shell | Integrado | Menu, opções, pausa, créditos e loading existem; fluxo manual ainda pendente |
| Movimento e combate de Calder | Integrado | `player_regression_tests` 49/49 PASS |
| Respawn | Integrado | `player_respawn_tests` 6/6 PASS; cenários manuais ainda pendentes |
| Hitbox/hurtbox e `AttackData` | Integrado | Regressões de combate passam |
| Feedback de combate | Integrado/provisório | `CombatFeedbackProfile`; áudio/VFX finais pendentes |
| HUD V2 | Integrado | Backend preservado; validação visual humana pendente |
| Save/checkpoint | Integrado | Save manual; checkpoint das catacumbas presente |
| Conteúdo Capítulo Zero | Integrado/provisório | Dados, objetivos, diálogo e finale existem; copy/balance final pendentes |
| World map | Integrado, gate vermelho | Grafo/overlay existem; `world_map_graph_tests` falha 1/10 no backtracking rua→igreja |
| Rua North Star | Integrada, procedural/pilot | `street_beta_complete_tests` 5/5 PASS; arte PNG final e performance pendentes |
| Igreja North Star | Integrada, procedural/pilot | `church_beta_complete_tests` 6/6 PASS; arte PNG final e playtest pendentes |
| Catacumbas North Star | Integradas, procedural/pilot | Cena carrega sem crash; `underground_beta_complete_tests` 6/6 PASS |
| Calder visual pipeline | Integrado/pilot | Pipeline e validator passam; sheets finais ausentes |
| Beta asset manifesto | Integrado (controle) | `data/art/beta_asset_manifest.json` + `scripts/art/beta_asset_*.gd`; 105 slots, 0 approved/integrated; ver `docs/BETA_ASSET_MANIFEST.md` |
| Cult Brawler visual pipeline | Integrado/pilot | Teste visual passa; source art pesada não está protegida pelo `.gitignore` |
| Iluminação regional | Integrada | `region_visual_tests` 6/6 PASS |
| Content registry | Integrado, contrato desatualizado | `content_registry_tests` 17/18; expectativa da cena da rua não acompanha North Star |
| Kit modular | Integrado, teste travando | `modular_kit_tests` excede 180 s e não termina |
| Runner headless | **Gate FAIL** | 30 suítes: 25 PASS, 4 FAIL, 1 TIMEOUT |
| Build Windows atual | **Não existe** | Artefatos locais são do commit `1c8e89d`, não de `4f20f76` |
| Build QA-approved | **Não** | Manifest local antigo registra `qa_release_approved: false` |
| Playthrough menu→fim | **Não assinado** | Bloqueador de release |
| Arte final | **Não produzida** | Pipeline/fallback procedural não equivale a pixel art final |

## Catacumbas — correção de crash

O commit `4f20f76` corrige o crash ao entrar em `vertical_slice_underground_art.tscn`. A auditoria confirmou:

- a cena carrega diretamente em headless com exit 0;
- a raiz entra na `SceneTree` como `UndergroundArtArea`;
- `_apply_visual_mode()` é chamado com `call_deferred` e cria `UndergroundArtPresentation`;
- checkpoint, Deacon Rusk, encounter e saída para a igreja existem;
- os hooks de finale são construídos;
- não houve erro de `NodePath` ou crash;
- a suíte falha quando a apresentação deferred é deliberadamente desabilitada (contraprova temporária, exit 1 esperado).

Detalhes e evidências: `STABILIZATION_REPORT.md` e `BETA_BASELINE_4F20F76.md`.

## Testes automatizados

O array `SUITES` em `scripts/tests/test_runner.gd` registra **30** entradas.

| Métrica | Resultado auditado |
| --- | --- |
| Suítes | 30 |
| PASS | 25 |
| FAIL | 4 |
| TIMEOUT | 1 (`modular_kit_tests`) |
| Unexpected issues parsed | 1 (`world_map_graph_tests`) |
| Allowed issues | 13 |
| Gate final | **FAIL / sem término normal do runner** |

Falhas:

- `vertical_slice_verification` — 5/7; expectativas ainda apontam para cenas greybox;
- `vertical_slice_regression_tests` — 12/14; expectativas ainda apontam para cenas greybox;
- `content_registry_tests` — 17/18; contrato de cena da rua desatualizado;
- `world_map_graph_tests` — 9/10, 1 warning inesperado; transição rua→igreja indisponível no fixture;
- `modular_kit_tests` — timeout >180 s.

## Áreas North Star

“Beta complete” nos documentos de área significa que layout, gameplay preservado, apresentação procedural, slots de assets e testes dedicados existem. **Não significa arte final pronta para ship.**

| Área | Layout | Teste dedicado | Arte final | Manual/performance |
| --- | --- | --- | --- | --- |
| Rua | 9 distritos | PASS 5/5 | Ausente | Pendente |
| Igreja | 6 zonas | PASS 6/6 | Ausente | Pendente |
| Catacumbas | 5 estágios | PASS 6/6 | Ausente | Pendente |

## Build Windows

Há artefatos locais ignorados em `builds/windows/`, porém o `build-manifest.json` informa:

- commit `1c8e89d4f25ce96446e84c76102bfce15366fb01`;
- data 2026-07-11;
- runner antigo FAIL (7/17);
- `qa_release_approved: false`.

Portanto, esses executáveis **não validam** `4f20f76`. A build do novo baseline continua pendente.

## Fora do baseline / sistemas congelados

Durante a estabilização de `4f20f76`, permanecem congelados:

- novas regiões;
- novos inimigos ou chefes;
- novas habilidades e mecânicas;
- inventário, equipamentos e árvore de habilidades;
- arte final;
- expansão de escopo do jogo completo.

O próximo trabalho deve corrigir apenas os gates objetivos registrados em `KNOWN_ISSUES.md`.
