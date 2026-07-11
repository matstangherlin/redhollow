# Red Hollow — Content Production Plan

Ordem recomendada de produção de conteúdo, alinhada ao estado técnico atual, à beta e ao jogo final.

## Princípios

1. **Não bloquear gameplay** — greybox permanece jogável até troca de arte por área.
2. **Uma área ou um inimigo por vez** — integração incremental.
3. **Pagar dívida P0** antes de mapas grandes (`TECH_DEBT.md`).
4. **Arte original** — seguir `VISUAL_REFERENCE_RULES.md`.

## Fase A — Fundação (concluída / em manutenção)

| Entrega | Estado |
| --- | --- |
| Demo técnica greybox jogável | Concluído |
| Combate core (player, hitbox, estilo, Red Brand) | Concluído |
| Transição de áreas + save | Concluído (load manual) |
| Deacon Rusk + arena | Concluído |
| Documentação canônica | Este ciclo |

## Fase B — Estabilização pré-beta

| # | Tarefa | Dependência |
| --- | --- | --- |
| B1 | Corrigir testes headless sem runtime errors | — |
| B2 | Gameplay lock manager (substituir panic unlock) | B1 |
| B3 | Hitstop/feedback sem `Engine.time_scale` global | B2 |
| B4 | Split inicial de `player.gd` (input + combat) | B2 |
| B5 | Decisão save auto-load para beta | B2 |

**Gate:** roteiro greybox completo sem softlock; testes headless limpos.

## Fase C — Arte vertical (Capítulo Zero)

Produzir em paralelo quando B estiver estável:

| # | Asset | Notas |
| --- | --- | --- |
| C1 | Calder — sprite base + animações combate | `ART_BIBLE.md` |
| C2 | Rua — camadas parallax | gameplay legível |
| C3 | Inimigo 1 (ex.: fanático) | substituir greybox |
| C4 | Igreja / distrito — exterior + arena | integrar barreira visual |
| C5 | Inimigo 2 + 3 | variedade mecânica |
| C6 | Elias NPC | diálogo |
| C7 | Subterrâneo + catacumbas | iluminação escura |
| C8 | Deacon Rusk — sprite + telegraphs | fases 1 e 2 |
| C9 | Barreira Vermilite VFX | destruição |
| C10 | Estátua Mol-Khar + aparição | set piece |
| C11 | Silhueta Arcturus | teaser |
| C12 | Variante corrupção (uma área) | camadas substituíveis |

## Fase D — UI beta

| # | Tarefa | Doc |
| --- | --- | --- |
| D1 | HUD vida + Red Brand + estilo (skin final) | `UI_BIBLE.md` |
| D2 | Mapa simples Capítulo Zero | `BETA_DEMO_SCOPE.md` |
| D3 | Objetivos + diário curto | `NARRATIVE_BIBLE.md` |
| D4 | Menu pausa + tela Red Brand (≤3 habilidades) | `UI_BIBLE.md` |
| D5 | Diálogo — painel pergaminho/madeira | `UI_BIBLE.md` |

## Fase E — Integração beta

| # | Tarefa |
| --- | --- |
| E1 | Substituir main scene ou ramo `beta_chapter_zero` com arte final |
| E2 | Roteiro 30–45 min balanceado |
| E3 | Áudio placeholder → SFX combate + ambiente |
| E4 | QA completo `TEST_MATRIX.md` + playtest externo |
| E5 | Build Windows beta |

## Fase F — Pós-beta (jogo final)

Ordem macro (não detalhar todos assets aqui):

1. Distrito adicional + primeiro barão jogável
2. Minas / Vermilite (Magnus Vane)
3. Sistema de mapa metroidvania completo
4. Mais habilidades Red Brand (com teto narrativo)
5. Palácio Rubro e confronto Mol-Khar
6. Polimento, localização, acessibilidade

Ver `FINAL_GAME_SCOPE.md`.

## O que não produzir agora

- todos os arquétipos de inimigo de uma vez;
- cidade inteira;
- UI de inventário complexo;
- duplicação manual de mapas corrompidos;
- assets copiados de moodboards.

## Checklist por entrega de arte

- [ ] Silhueta legível em resolução de gameplay
- [ ] Paleta conforme `ART_BIBLE.md`
- [ ] Sem cópia de referência (`VISUAL_REFERENCE_RULES.md`)
- [ ] Hitboxes alinhadas (debug toggle F)
- [ ] Teste manual na área integrada
- [ ] Commit apenas de assets licenciados/originais
