# Red Hollow — Game Design Document

Documento de visão de jogo. Para cânone detalhado, ver `NARRATIVE_BIBLE.md`. Para escopo de entrega, ver `BETA_DEMO_SCOPE.md` e `FINAL_GAME_SCOPE.md`.

## Visão

Red Hollow é um metroidvania de ação 2D em visão lateral sobre entrar, sobreviver e reabrir uma cidade decadente tomada por barões, cultos e promessas quebradas. Combina exploração interligada, combate corpo a corpo técnico e humor agressivo durante lutas, com horror psicológico e religioso como camada de mistério.

**Arte final:** pixel art detalhada com faroeste decadente e iluminação dramática (`ART_BIBLE.md`).

O jogador controla **Calder Knox**, ex-caçador de recompensas marcado pela **Red Brand** após um ritual incompleto. A marca amplifica força, reflexos e ligação a **Mol-Khar** — não é magia tradicional.

## Estado do projeto (resumo)

| Categoria | Exemplos |
| --- | --- |
| **Implementado e testado** | Movimento, combo, esquiva, counter, provocação, estilo, Red Brand, diálogo, áreas, arena, barreira, save F8/F9, Deacon Rusk, conclusão demo |
| **Implementado com dívida** | `player.gd` monolítico, panic unlock, acoplamento por grupos, auto-load desativado na greybox |
| **Planejado beta** | Arte final Capítulo Zero, mapa/objetivos/diário, três inimigos visuais, set pieces Mol-Khar/Arcturus |
| **Planejado jogo final** | Cidade completa, barões, Palácio Rubro, progressão ampla |

Main scene atual: `res://scenes/demo/vertical_slice_greybox.tscn`  
Engine: Godot **4.7**

## Pilares

- Ação 2D responsiva: 60 FPS no Windows.
- Combate físico: socos, chutes, esquivas, counters, provocações, Red Brand.
- Exploração interligada: atalhos, backtracking, progresso por habilidades e flags.
- Identidade: faroeste decadente, anime nos personagens, violência estilizada, humor de combate, terror religioso.
- Vermilite e corrupção como linguagem visual e narrativa controlada.

## Público

Jogadores de metroidvanias de ação, chefes exigentes e domínio mecanico. Acessível no básico; alto teto de skill.

## Referências

Inspiração de qualidade (ex.: intensidade de God Hand) sem copiar golpes, UI, história ou visual. Moodboards só para tom — ver `VISUAL_REFERENCE_RULES.md`.

## Identidade própria

Red Hollow não é fantasia medieval nem jogo de magia elemental. A Red Brand distorce limites físicos do corpo. Manifestações sobrenaturais existem quando ligadas a Mol-Khar, Vermilite, pactos, dor ou plano espiritual.

## Ambientação

Cidade de faroeste alternativo em decomposição: trilhos, saloons, capelas, minas, cemitérios, instalações industriais, ruínas cerimoniais. Símbolos religiosos deformados, cartazes, máquinas velhas, rituais.

## História (cânone)

Calder retorna a Red Hollow por rumores de desaparecimentos e culpa não resolvida. A **Ordem do Coração Rubro** venera **Mol-Khar, O Devorador de Promessas**.

A **Ressonância Rubra** de Mol-Khar amplifica desejos, ambição, medo e culpa — nunca controle direto da mente. A **Vermilite** minada enfraquece o selo e espalha essa influência.

Detalhes: `NARRATIVE_BIBLE.md`.

## Personagens

- **Calder Knox** — protagonista; Red Brand na mão direita.
- **Mol-Khar** — antagonista; presença ritual e psicológica.
- **Ordem do Coração Rubro** — culto dominante.
- **Elias** — contato na rua (demo atual).
- **Deacon Rusk** — executor; chefe do Capítulo Zero.
- **Barões** — Silas Crow, Rosa La Serpiente, Arcturus Vale, Magnus Vane (jogo final).

## Combate

Corpo a corpo, técnico, agressivo. Suporta:

- socos e chutes (combo);
- esquivas e counters;
- provocações;
- Red Brand Breaker carregado;
- chefes com telegraphs e fases.

Ataques orientados por `AttackData` Resource. Hitbox e hurtbox separadas.

**Não implementar:** magia elemental genérica, voo, projéteis mágicos.

## Exploração

Cidade interligada em 2D lateral, um plano. Portas, barreiras, checkpoints, atalhos. Troca de áreas via shell persistente (`ARCHITECTURE.md`).

## Progressão

Habilidades físicas e técnicas da Red Brand. Flags narrativas e barreiras destruídas persistem no save. Exemplos futuros: esquiva aprimorada, quebra de barreiras, impulso, counters específicos.

## Red Brand

Marca na mão direita. Funções:

- golpes reforçados;
- absorção de energia (Coração Rubro / Vermilite);
- destruição de barreiras do culto;
- atingir manifestações espirituais;
- ligação crescente com Mol-Khar.

Limites: sem voo, sem feitiços, sem substituir skill do jogador.

## Sistema de estilo

Recompensa variedade, risco e domínio. Ranks: DUST → IRON → VERMILION → CRIMSON → HOLLOW. Implementado em `StyleManager` + HUD.

## Provocações

Identidade de Calder; ganho de estilo em risco; falas contextuais. Implementado no player.

## Chefes

Padrões legíveis, pressão alta, fases testáveis. Deacon Rusk implementado na demo técnica.

## Narrativa no gameplay

Ambiental e dialogada; diálogos curtos; JSON em `data/dialogues/`. Não bloquear combate com exposição longa.

## Escopos de entrega

| Entrega | Documento |
| --- | --- |
| Demo técnica greybox (atual) | `VERTICAL_SLICE_TEST_PLAN.md` |
| Beta pública Capítulo Zero | `BETA_DEMO_SCOPE.md` |
| Jogo completo | `FINAL_GAME_SCOPE.md` |

A demo técnica **já superou** o “primeiro protótipo” descrito em versões antigas deste GDD (save, boss, múltiplas áreas, estilo, Red Brand).
