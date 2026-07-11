# Red Hollow — Beta Demo Scope

**Nome:** Capítulo Zero — O Sino Antes do Anoitecer  
**Duração alvo:** 30–45 minutos  
**Plataforma inicial:** Windows, 60 FPS  
**Arte:** pixel art final (ou próxima) nas áreas listadas  
**Base técnica:** vertical slice greybox (`vertical_slice_greybox.tscn`) — ver `CURRENT_IMPLEMENTATION.md`

## Objetivo

Validar núcleo jogável, narrativa, combate, exploração curta e identidade visual — **sem** escopo de jogo completo.

## Conteúdo pretendido

### Áreas

| Área | Função |
| --- | --- |
| Rua de Red Hollow | Chegada, Elias, primeiro combate |
| Distrito da igreja | Arena, cristal Coração Rubro, barreira |
| Interior / subterrâneo da igreja | Descida, atmosfera |
| Catacumbas | Checkpoint, confronto Deacon Rusk |

### Personagens

- **Calder Knox** (jogável)
- **Elias** (NPC guia)
- **Deacon Rusk** (mini-chefe)

### Inimigos

- **Três arquétipos** visuais finais (ex.: fanático, carrasco, terceiro variante mecânica)
- Base de IA: **Cult Brawler** já implementado na greybox

### Narrativa e set pieces

- diálogo inicial com Elias;
- **pequena rota de backtracking** entre áreas-chave;
- **uma habilidade** da Red Brand destacada no roteiro (Breaker já existe; beta pode nomear/encenar como marco);
- **pista** sobre o antigo parceiro de Calder;
- **estátua** de Mol-Khar;
- **aparição breve** da entidade (não boss completo);
- **referência, voz ou silhueta** de Arcturus Vale;
- barreira **Vermilite** destrutível;
- checkpoint funcional;
- **uma transformação ambiental curta** (Ressonância Rubra);
- **encerramento com gancho** narrativo para o jogo final.

### Interface

- HUD vida + Red Brand + estilo (skin final);
- mapa simples;
- objetivos do capítulo;
- diário curto;
- menu pausa;
- tela Red Brand com **no máximo três** habilidades.

### Sistemas reutilizados da greybox (já implementados)

| Sistema | Estado base |
| --- | --- |
| Movimento, pulo, plataforma | OK |
| Combo, esquiva, counter, provocação | OK |
| Estilo + HUD | OK |
| Red Brand + Breaker | OK |
| Diálogo + interação | OK |
| 3 áreas + transição | OK |
| Arena | OK |
| Save F8/F9 + checkpoint | OK (load manual) |
| Barreiras persistentes | OK |
| Deacon Rusk + HUD chefe | OK |
| Conclusão demo | OK (overlay — evoluir para gancho beta) |

## A beta **não** deve revelar

- luta completa contra **Arcturus**;
- **Palácio Rubro**;
- forma física **completa** de Mol-Khar;
- **todos** os barões jogáveis;
- **final** da história principal.

## Fora do escopo da beta

- árvore extensa de habilidades;
- equipamentos / loot aleatório complexo;
- dezenas de colecionáveis;
- cidade inteira de Red Hollow;
- crafting pesado;
- magia elemental genérica;
- auto-load sem revisão arquitetural (`TECH_DEBT.md`, `DECISIONS.md` D-013).

## Relação com a demo técnica

A greybox **já supera** um protótipo vazio: combate, três áreas, save, chefe e conclusão funcionam. A beta **substitui arte**, expande duração/narrativa/UI e adiciona set pieces listados — **sem** reescrever o núcleo de combate do zero.

## Critérios de aceite

- [ ] Fluxo 30–45 min para jogador novo.
- [ ] Três inimigos + Rusk com arte legível.
- [ ] HUD/menus conforme `UI_BIBLE.md`.
- [ ] Uma sequência de corrupção ambiental perceptível.
- [ ] Save/load estável após checkpoint.
- [ ] Nenhum softlock conhecido no roteiro.
- [ ] `TEST_MATRIX.md` + `test_runner.gd` na build de beta.
