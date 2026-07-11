# Red Hollow — Content Production Plan

Ordem de produção alinhada ao estado técnico (tag `greybox-vertical-slice-v0.1`), beta e jogo final.

## Princípios

1. Greybox permanece jogável até troca de arte por área.
2. Uma área ou um inimigo por vez.
3. Pagar **P0/P1** de `TECH_DEBT.md` antes de mapas grandes.
4. Arte original — `VISUAL_REFERENCE_RULES.md`, `ART_BIBLE.md`.

## Fase A — Fundação greybox ✅

| Entrega | Estado |
| --- | --- |
| Demo técnica jogável | Concluído |
| Combate core + Red Brand + estilo | Concluído |
| 3 áreas + transição + save manual | Concluído |
| Arena + Deacon Rusk + conclusão | Concluído |
| GameplayLockManager + test_runner | Concluído (dívida) |
| Tag `greybox-vertical-slice-v0.1` | Concluído |
| Documentação canônica atualizada | Este ciclo |

## Fase B — Estabilização pré-beta 🎯

| # | Tarefa | Doc |
| --- | --- | --- |
| B1 | Runtime errors headless → zero inesperados | `TECH_DEBT.md` P0 |
| B2 | Morte/respawn consolidado | P0 |
| B3 | Reduzir panic unlock | P0 |
| B4 | Split player + API save | P1 |
| B5 | Rebinding troca de área | P1 |
| B6 | Decisão auto-load beta | `DECISIONS.md` D-013 |

**Gate:** roteiro greybox sem softlock; `test_runner.gd` limpo.

## Fase C — Arte Capítulo Zero 📋

| # | Asset |
| --- | --- |
| C1 | Calder — sprite + anim combate |
| C2 | Rua — parallax |
| C3 | Inimigo arquétipo 1 |
| C4 | Igreja + arena + barreira visual |
| C5 | Inimigos 2 e 3 |
| C6 | Elias |
| C7 | Subterrâneo + catacumbas |
| C8 | Deacon Rusk + telegraphs |
| C9 | VFX barreira Vermilite |
| C10 | Estátua + aparição Mol-Khar |
| C11 | Teaser Arcturus |
| C12 | Variante corrupção (uma área) |

## Fase D — UI beta 📋

HUD skin, mapa, objetivos, diário, pausa, Red Brand (≤3 habilidades) — `UI_BIBLE.md`, `BETA_DEMO_SCOPE.md`.

## Fase E — Integração beta 📋

Roteiro 30–45 min, áudio placeholder→produção, QA `TEST_MATRIX.md`, build Windows.

## Fase F — Jogo final 📋

1. Prólogo ritual  
2. Arco Silas Crow  
3. Arco Rosa La Serpiente  
4. Arco Magnus Vane  
5. Arco Arcturus → Arauto  
6. Palácio Rubro  
7. Confronto Mol-Khar + finais  

Ver `FINAL_GAME_SCOPE.md`.

## Não produzir agora

- cidade inteira;
- todos arquétipos de uma vez;
- UI inventário complexo;
- mapas corrompidos duplicados manualmente;
- assets copiados de moodboards.

## Checklist por entrega de arte

- [ ] Silhueta legível em gameplay
- [ ] Paleta `ART_BIBLE.md`
- [ ] Sem cópia de referência
- [ ] Hitboxes alinhadas (debug F)
- [ ] Teste manual na área integrada
