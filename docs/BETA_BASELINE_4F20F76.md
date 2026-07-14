# Red Hollow — Beta Baseline `4f20f76`

Documento formal do novo baseline de estabilização da beta.

## Identificação

| Campo | Valor |
| --- | --- |
| Repositório | `matstangherlin/redhollow` |
| Commit | `4f20f76e5f505f36eacdb9866d7d7e33404c15f3` |
| Commit curto | `4f20f76` |
| Branch | `main` |
| Versão | `0.2.0-beta.1` |
| Engine | Godot 4.7 |
| Main scene | `res://scenes/product/main_menu.tscn` |
| Gameplay entry | `res://scenes/demo/vertical_slice_greybox.tscn` |
| Data da auditoria | 2026-07-13 |

## Decisão de baseline

`4f20f76` é o **baseline canônico de código e conteúdo** para a próxima rodada de estabilização da beta. Ele contém rua, igreja e catacumbas North Star, HUD V2, pipelines visuais, iluminação regional, feedback profiles, validators e conteúdo do Capítulo Zero, além da correção do crash das catacumbas.

O baseline é um ponto de referência reproduzível, **não uma aprovação de release**.

## Estado Git e higiene

| Verificação | Estado |
| --- | --- |
| Commit atual esperado | PASS |
| Branch `main` | PASS |
| Alterações tracked prévias | Nenhuma |
| Working tree limpa | Não — 18 untracked preexistentes |
| `.godot/` ignorada | Sim |
| Builds ignoradas | Sim |
| Source art pesada ignorada | Parcial — Calder sim; Cult Brawler não |

## Suítes

Quantidade real contada diretamente em `scripts/tests/test_runner.gd`: **30**.

| Resultado | Quantidade |
| --- | ---: |
| PASS | 25 |
| FAIL | 4 |
| TIMEOUT | 1 |
| Unexpected issues parsed | 1 |
| Allowed issues | 13 |

### Falhas

- `vertical_slice_verification` — 5/7;
- `vertical_slice_regression_tests` — 12/14;
- `content_registry_tests` — 17/18;
- `world_map_graph_tests` — 9/10, 1 warning inesperado;
- `modular_kit_tests` — timeout >180 s.

### Exit e duração

| Execução | Resultado |
| --- | --- |
| Runner completo | Não retornou exit; travou em `modular_kit_tests` após >300 s |
| Timeout externo da suíte modular | 124 |
| Lote das 13 suítes críticas | exit 1, 51,2 s |
| Catacumbas — carga direta | exit 0, 1,68 s |

## Catacumbas

O bug corrigido por `4f20f76` está validado:

- `vertical_slice_underground_art.tscn` carrega;
- `UndergroundArtArea` entra na árvore;
- a apresentação deferred é criada;
- checkpoint existe;
- Deacon Rusk e encounter existem;
- saída para a igreja art existe;
- hooks do finale existem;
- não há erro de `NodePath`;
- não há crash;
- a contraprova sem apresentação falha com exit 1, como requerido.

## Áreas

| Área | Integração | Teste | Arte final | Manual |
| --- | --- | --- | --- | --- |
| Rua North Star | Integrada/pilot | 5/5 PASS | Ausente | Pendente |
| Igreja North Star | Integrada/pilot | 6/6 PASS | Ausente | Pendente |
| Catacumbas North Star | Integrada/pilot; crash corrigido | 6/6 PASS | Ausente | Pendente |

## P0

1. **Gate automatizado vermelho:** 4 falhas e 1 timeout.
2. **Playthrough manual ausente:** menu→fim, save, respawn, boss, finale e retorno ao menu não assinados.
3. **Build atual ausente:** executáveis locais são do commit `1c8e89d`, não deste baseline; QA false.

## P1

1. migrar contratos de transição greybox para as cenas North Star;
2. alinhar ContentRegistry/manifests com a rua canônica;
3. corrigir world map/backtracking no fixture ou contrato real;
4. eliminar o hang de `modular_kit_tests`;
5. tornar o timeout do runner capaz de encerrar subprocessos;
6. limpar/decidir os 18 untracked preexistentes;
7. proteger source art pesada do Cult Brawler no `.gitignore`.

## P2

1. corrigir leaks (43 objetos, 6 resources) do world map;
2. remover erros de autoload no processo pai do runner;
3. revisar allowlists e warning de integridade da arena;
4. decidir auto-load e remover panic unlock da configuração de release;
5. completar teardown e documentação de QA.

## Sistemas congelados

Até o gate técnico e manual ficar verde, não adicionar:

- novas regiões;
- novos inimigos;
- novas habilidades;
- novos chefes;
- inventário;
- equipamentos;
- árvore de habilidades;
- arte final;
- novas mecânicas.

Gameplay existente também permanece congelado, salvo correção de bug objetivo acompanhada de regressão.

## Próximos gates

1. **Gate A — automação:** 30/30 PASS, 0 timeout, 0 unexpected, exit 0.
2. **Gate B — reprodutibilidade:** working tree controlada e runner encerrando de forma determinística.
3. **Gate C — playthrough:** menu→fim, três áreas, Rusk, finale, save/respawn/backtracking e gamepad assinados.
4. **Gate D — build Windows:** gerar do commit aprovado, smoke, performance 60 FPS e QA.
5. **Gate E — visual:** legibilidade/HUD/performance aprovados antes da produção de arte final.

## Status final

| Declaração | Estado |
| --- | --- |
| Novo baseline de estabilização | **ESTABELECIDO — `4f20f76`** |
| Crash das catacumbas | **RESOLVIDO** |
| Gate automatizado | **FAIL** |
| Build release | **NÃO APROVADA** |
| Arte final | **NÃO APROVADA / AUSENTE** |
| Playthrough manual | **PENDENTE** |
| Ship beta | **BLOQUEADO** |
