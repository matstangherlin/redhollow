# Red Hollow — Beta Demo Scope

**Nome:** Capítulo Zero — O Sino Antes do Anoitecer  
**Duração alvo:** 30–45 minutos  
**Plataforma inicial:** Windows, 60 FPS  
**Arte:** pixel art final ou próxima do final nas áreas listadas

## Objetivo da beta

Validar o núcleo jogável de Red Hollow com narrativa, combate, exploração curta e identidade visual definitiva — sem escopo de jogo completo.

## Conteúdo incluído

### Áreas (visual final)

| Área | Função |
| --- | --- |
| Rua inicial | Chegada, Elias, primeiro combate |
| Distrito da igreja | Arena, cristal Coração Rubro, barreira |
| Interior / subterrâneo | Checkpoint, descida |
| Catacumbas | Confronto com Deacon Rusk |

### Personagens

- **Calder Knox** (jogável)
- **Elias** (NPC)
- **Deacon Rusk** (mini-chefe)

### Inimigos (três tipos na beta)

Arquétipos visuais finais a partir de `ART_BIBLE.md` — por exemplo fanático, carrasco e um terceiro escolhido para variedade mecânica. A demo técnica greybox já valida **Cult Brawler** como base de comportamento.

### Narrativa e set pieces

- diálogo inicial com Elias;
- pequena **estátua de Mol-Khar**;
- **aparição** de Mol-Khar (manifestação curta, não boss completo);
- **silhueta de Arcturus Vale** (teaser);
- barreira de **Vermilite** destruível com Red Brand Breaker;
- **checkpoint** funcional;
- **uma transformação ambiental curta** por Ressonância Rubra (variante de camada, não mapa duplicado).

### Interface (beta)

- HUD (vida, Red Brand, estilo);
- mapa simples;
- objetivos do capítulo;
- diário curto;
- menu de pausa;
- tela Red Brand com **no máximo três** habilidades.

### Sistemas de gameplay esperados

Reutilizar e polir sistemas já existentes na vertical slice greybox:

| Sistema | Estado na base técnica |
| --- | --- |
| Movimento e plataforma | Implementado |
| Combo, esquiva, counter, provocação | Implementado |
| Estilo | Implementado |
| Red Brand + Breaker | Implementado |
| Diálogo | Implementado |
| Transição de áreas | Implementado |
| Arena | Implementado |
| Save / checkpoint | Implementado (load manual) |
| Barreiras persistentes | Implementado |
| Chefe Deacon Rusk | Implementado |

## Fora do escopo da beta

Não implementar na beta pública:

- árvore extensa de habilidades;
- equipamentos complexos ou loot aleatório;
- dezenas de colecionáveis;
- cidade inteira de Red Hollow;
- todos os barões jogáveis;
- Palácio Rubro completo;
- sistema final de crafting;
- magia elemental genérica;
- auto-load de save sem revisão de arquitetura (ver `TECH_DEBT.md`).

## Relação com a demo técnica atual

A main scene greybox (`vertical_slice_greybox.tscn`) é a **base jogável** com placeholders. A beta substitui arte, expande duração e adiciona UI/narrativa listadas acima, sem reescrever o núcleo de combate do zero.

## Critérios de aceite da beta

- [ ] Fluxo completo em 30–45 min para jogador novo.
- [ ] Três inimigos + Rusk com arte final legível.
- [ ] HUD e menus conforme `UI_BIBLE.md`.
- [ ] Uma sequência de corrupção ambiental perceptível.
- [ ] Save/load estável após checkpoint (manual ou auto conforme decisão pós-dívida técnica).
- [ ] Nenhum softlock conhecido no roteiro do capítulo.
- [ ] Testes em `TEST_MATRIX.md` executados para build de beta.
