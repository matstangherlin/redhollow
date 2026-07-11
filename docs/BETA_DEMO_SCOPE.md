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

- **Cult Brawler** — pressão melee, counterable (existente)
- **Vermilite Gunslinger** — pistoleiro, projétil físico, recarga vulnerável (greybox)
- **Chain Penitent** — correntes, controle de espaço, vulnerável após errar (greybox)
- **Deacon Rusk** — mini-chefe (existente)

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

### Camada narrativa provisória (greybox — implementada)

Capítulo Zero — **O Sino Antes do Anoitecer** usa sistemas estabilizados com dados orientados por JSON:

| Componente | Caminho |
| --- | --- |
| Flags estáveis | `scripts/narrative/chapter_zero_flags.gd` |
| Objetivos | `data/narrative/chapter_zero_objectives.json` |
| Eventos | `data/narrative/chapter_zero_events.json` |
| Diretor | `scripts/narrative/narrative_director.gd` |
| HUD objetivo | `scenes/ui/objective_hud.tscn` |
| Encerramento (8 passos curtos) | `scripts/narrative/chapter_zero_finale.gd` |
| Props narrativos | `scenes/interactables/story_prop.tscn` |
| Diálogos | `data/dialogues/dialogues_pt_br.json` (IDs `cz_*`) |

**Pista do parceiro (provisória):** medalhão na rua + página de diário nas catacumbas. Não revela assassino, destino definitivo nem ligação completa com Mol-Khar.

**Duração alvo na greybox narrativa:** 30–45 minutos (jogador novo), com seis encontros escalonados, exploração opcional e balanceamento em `CHAPTER_ZERO_BALANCE.md`.

**Encerramento:** tremor subterrâneo, Red Brand reage, estátua colossal abre os olhos, sombra breve de Mol-Khar (nomeia Calder), silhueta de Arcturus, passagem revelada — beta termina. Mol-Khar completo, Arcturus jogável e Palácio Rubro **fora** do escopo.

## Critérios de aceite

- [ ] Fluxo 30–45 min para jogador novo.
- [ ] Três inimigos + Rusk com arte legível.
- [ ] HUD/menus conforme `UI_BIBLE.md`.
- [ ] Uma sequência de corrupção ambiental perceptível.
- [ ] Save/load estável após checkpoint.
- [ ] Nenhum softlock conhecido no roteiro.
- [ ] `TEST_MATRIX.md` + `test_runner.gd` na build de beta.
