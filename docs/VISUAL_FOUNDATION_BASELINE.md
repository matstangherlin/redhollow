# Red Hollow — Visual Foundation Baseline

**Data:** 2026-07-13
**Commit:** `4f20f76e5f505f36eacdb9866d7d7e33404c15f3` (`4f20f76`)
**Branch:** `main`
**Versão:** `0.2.0-beta.1`
**Engine:** Godot 4.7

Este documento define o baseline visual técnico existente. Ele não declara arte final nem aprovação de release.

## Veredito

| Critério | Estado |
| --- | --- |
| Pipeline visual Calder | **Integrado / PILOT** |
| Validator Calder | **PASS 6/6** |
| Pipeline Cult Brawler | **Integrado / PILOT** |
| Validator e teste Cult Brawler | **PASS 6/6 + 6/6** |
| HUD V2 | Integrado; QA visual manual pendente |
| `CombatFeedbackProfile` | Integrado; assets finais pendentes |
| Iluminação regional | **PASS 6/6** |
| Rua North Star | Integração técnica **PASS 5/5** |
| Igreja North Star | Integração técnica **PASS 6/6** |
| Catacumbas North Star | Integração técnica **PASS 6/6**; crash corrigido |
| Arte pixel final Capítulo Zero | **AUSENTE** |
| Performance em build atual | **NÃO MEDIDA** |
| Playtest visual assinado | **PENDENTE** |

### Decisão

O baseline aprova a arquitetura de apresentação, factories, profiles, slots, fallbacks, validators e separação gameplay/visual. Ele **não aprova produção final como concluída**, nem permite chamar as áreas de “final art”.

## O que `4f20f76` acrescenta ao baseline anterior

- rua North Star consolidada em 9 distritos;
- distrito da igreja North Star em 6 zonas;
- catacumbas North Star em 5 estágios;
- HUD V2 integrado;
- pipeline Calder e Cult Brawler;
- temas de iluminação regional;
- perfis de feedback de combate;
- validators de assets;
- hooks visuais do finale do Capítulo Zero;
- correção do crash da apresentação deferred das catacumbas.

## Status por área

| Área | Cena canônica de arte | Apresentação | Teste | Situação real |
| --- | --- | --- | --- | --- |
| Rua | `vertical_slice_street_art.tscn` | `StreetArtPresentation` | 5/5 PASS | procedural/pilot; PNGs finais pendentes |
| Igreja | `vertical_slice_church_art.tscn` | `ChurchArtPresentation` | 6/6 PASS | procedural/pilot; PNGs finais pendentes |
| Catacumbas | `vertical_slice_underground_art.tscn` | `UndergroundArtPresentation` | 6/6 PASS | procedural/pilot; crash corrigido; PNGs finais pendentes |

Os documentos `*_BETA_COMPLETE.md` descrevem completude de layout e integração técnica. Não representam completude artística.

## Contratos visuais

| Contrato | Valor / regra |
| --- | --- |
| Resolução lógica | 480×270 |
| Pixels por unidade | 1 |
| Tile base | 16×16 |
| Escala contínua das áreas | `ground_surface_y` compatível |
| Calder alvo artístico | 40×72 por frame |
| Gameplay vs apresentação | colisão, hitboxes e spawns independem de sprites finais |
| Textura | nearest/pixel art |
| FPS alvo Windows | 60 |
| Vermilite | uso controlado, não magia elemental genérica |

## Pipelines de personagem

### Calder

| Componente | Estado |
| --- | --- |
| `CalderAnimationContract` | Integrado |
| `PlayerVisualController` | Integrado |
| perfil PILOT/fallback | Integrado |
| teste de pipeline | 8/8 PASS; 1 warning permitido de fallback |
| validator de assets | 6/6 PASS |
| sheets finais | Ausentes |

### Cult Brawler

| Componente | Estado |
| --- | --- |
| `CultBrawlerVisualController` | Integrado |
| perfil PILOT/fallback | Integrado |
| teste visual | 6/6 PASS |
| asset validation | 6/6 PASS |
| sheets finais | Ausentes |
| source art ignore | **Incompleto** — pasta source aceita arquivos pesados |

## Ambiente e iluminação

- cada área tem profile e presentation dedicados;
- os quatro estados regionais são suportados;
- gameplay nodes permanecem acima da apresentação;
- as catacumbas criam a apresentação com `call_deferred`;
- hooks do finale incluem Mol-Khar, Arcturus, olhos da estátua e passagem oculta;
- performance monitors existem para uso manual, mas não há assinatura de métricas.

## Evidência automatizada visual

| Suíte | Resultado |
| --- | --- |
| `player_visual_pipeline_tests` | 8/8 PASS |
| `calder_asset_validation_tests` | 6/6 PASS |
| `cult_brawler_asset_validation_tests` | 6/6 PASS |
| `cult_brawler_visual_tests` | 6/6 PASS |
| `feedback_system_tests` | 10/10 PASS |
| `street_art_toggle_tests` | 5/5 PASS |
| `street_beta_complete_tests` | 5/5 PASS |
| `church_beta_complete_tests` | 6/6 PASS |
| `underground_beta_complete_tests` | 6/6 PASS |
| `region_visual_tests` | 6/6 PASS |

Essas suítes visuais passam, mas o gate global permanece vermelho por quatro falhas e um timeout descritos em `TEST_MATRIX.md`.

## Catacumbas — baseline visual corrigido

Critérios confirmados:

1. cena art carrega com exit 0;
2. `UndergroundArtArea` entra na árvore;
3. `UndergroundArtPresentation` aparece após apply deferred;
4. camadas, controller regional e hooks do finale são construídos;
5. gameplay nodes essenciais permanecem;
6. não há crash ou `NodePath` inválido;
7. negative control sem apresentação falha como esperado.

## Gaps antes de arte final

### P0 de release/QA

- gate global 30/30 ainda não passa;
- playthrough visual não assinado;
- build de `4f20f76` não existe;
- 60 FPS, frame time e draw calls não medidos.

### P1 visual

- legibilidade de plataformas, exits, props e telegraphs precisa de playtest humano;
- sheets finais de Calder e inimigos ausentes;
- tilesets, set pieces e módulos PNG finais ausentes;
- HUD V2 precisa de validação em resoluções alvo;
- regra de ignore do source art do Cult Brawler precisa ser adicionada.

### P2

- fallbacks procedurais devem permanecer até substituição validada;
- warnings permitidos não podem ocultar assets finais ausentes em release;
- formulários de playtest ainda não foram assinados.

## Próximos gates

1. estabilização técnica: 30/30, sem timeout, exit 0;
2. playthrough das três áreas e finale;
3. build Windows atual + medição de performance;
4. aprovação de legibilidade/HUD;
5. somente então produção e integração de arte final em lotes validados.

## Escopo congelado

Até esses gates serem concluídos, não adicionar novas regiões, inimigos, habilidades, chefes, inventário, equipamentos, árvore de habilidades, arte final em massa ou novas mecânicas.
