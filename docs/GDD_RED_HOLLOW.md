# Red Hollow — Game Design Document

Visão de jogo. Cânone: `NARRATIVE_BIBLE.md`. Escopo: `BETA_DEMO_SCOPE.md`, `FINAL_GAME_SCOPE.md`. Implementação: `CURRENT_IMPLEMENTATION.md`.

## Visão

Red Hollow é um metroidvania de ação 2D sobre sobreviver e reabrir uma cidade decadente tomada por barões, culto e promessas quebradas. Combate corpo a corpo técnico, humor agressivo no fighting, horror religioso como mistério.

**Arte final:** pixel art detalhada, faroeste decadente, iluminação dramática (`ART_BIBLE.md`).

**Protagonista:** **Calder Knox**, marcado pela **Red Brand** após ritual incompleto com **Mol-Khar, O Devorador de Promessas**.

## Estado do projeto

| Categoria | Exemplos |
| --- | --- |
| **Implementado e funcional** | Movimento, combo, dodge, counter, taunt, estilo, Red Brand, diálogo, 3 áreas, arena, barreira, save F8/F9, Cult Brawler, Deacon Rusk, HUDs, conclusão demo, locks, testes headless |
| **Implementado com dívida** | `player.gd` monolítico, paths save, rebinding área, panic unlock, morte/respawn |
| **Planejado beta** | Arte Capítulo Zero, catacumbas, 3 inimigos visuais, set pieces Mol-Khar/Arcturus, UI mapa/diário |
| **Planejado jogo final** | Barões, Palácio Rubro, Mol-Khar completo, finais |

Main scene: `res://scenes/demo/vertical_slice_greybox.tscn`  
Engine: Godot **4.7**  
Baseline: tag `greybox-vertical-slice-v0.1`

**A demo técnica greybox já existe e é jogável** — não tratar como protótipo vazio.

## Pilares

- Ação 2D responsiva (60 FPS Windows).
- Combate físico: socos, chutes, esquivas, counters, provocações, Red Brand.
- Exploração interligada, backtracking, progresso por habilidades e flags.
- Identidade: faroeste decadente, anime nos personagens, terror religioso, Vermilite.
- Ressonância Rubra — sem magia elemental genérica.

## Público

Metroidvanias de ação, chefes exigentes, domínio mecânico. Acessível no básico; alto teto de skill.

## Referências

Inspiração de qualidade sem copiar golpes, UI, história ou visual. Moodboards só para tom (`VISUAL_REFERENCE_RULES.md`).

## Ambientação

Red Hollow: faroeste alternativo sobre prisão/altar ancestral. Trilhos, saloons, capelas, minas, rituais, máquinas velhas.

## História (resumo)

Calder retorna por desaparecimentos e culpa. **Ordem do Coração Rubro** — “A dor é a verdadeira salvação.” Mineração de **Vermilite** enfraquece selo de Mol-Khar.

Detalhes: `NARRATIVE_BIBLE.md`.

## Personagens

| Nome | Papel |
| --- | --- |
| Calder Knox | Protagonista |
| Mol-Khar | Antagonista (Ressonância Rubra) |
| Elias | NPC rua (implementado) |
| Deacon Rusk | Mini-chefe (implementado) |
| Silas Crow, Rosa La Serpiente, Magnus Vane, Arcturus Vale | Barões (jogo final) |

## Combate

Corpo a corpo via `AttackData`. Hitbox/hurtbox separadas. Red Brand Breaker carregado.

**Não:** magia elemental genérica, voo, projéteis mágicos sem vínculo narrativo.

## Exploração

2D lateral, um plano. Shell persistente + troca de áreas (`ARCHITECTURE.md`).

## Red Brand

Força, reflexos, absorção Vermilite, barreiras, manifestações espirituais, ligação crescente a Mol-Khar se abusada.

## Estilo

Ranks DUST → HOLLOW. `StyleManager` + HUD — implementado.

## Provocações

Identidade Calder; estilo em risco — implementado.

## Chefes

Telegraphs, fases. Deacon Rusk — implementado na greybox.

## Narrativa no gameplay

Diálogos curtos; JSON `data/dialogues/`. Não bloquear combate com exposição longa.

## Escopos

| Entrega | Documento |
| --- | --- |
| Demo técnica greybox | `VERTICAL_SLICE_TEST_PLAN.md` |
| Beta Capítulo Zero | `BETA_DEMO_SCOPE.md` |
| Jogo completo | `FINAL_GAME_SCOPE.md` |
