# Red Hollow — Content Production Plan

Ordem de produção alinhada ao commit **`e07ba0e`** (beta foundation) e meta Capítulo Zero.

## Princípios

1. Greybox permanece jogável até troca de arte por área.
2. Uma área ou um inimigo por vez.
3. **P0 runner** antes de declarar build shippable; P1 gameplay antes de mapas grandes.
4. Arte original — `VISUAL_REFERENCE_RULES.md`, `ART_BIBLE.md`.
5. Existir arquivo ≠ integração validada (ver coluna “Validação”).

---

## Fase A — Fundação greybox ✅

| Entrega | Estado |
| --- | --- |
| Demo técnica jogbox | ✅ tag `greybox-vertical-slice-v0.1` |
| Combate core + Red Brand | ✅ |
| 3 áreas + save manual | ✅ |
| Tag greybox | ✅ |

---

## Fase B — Beta foundation ✅ / 🔧 (commit `e07ba0e`)

| # | Tarefa | Estado | Validação |
| --- | --- | --- | --- |
| B0 | ContentManifest + Registry + manifests | ✅ commitado | `content_registry_tests` PASS |
| B1 | Product shell (menu, opções, pausa, …) | 🔧 infra | Manual pendente |
| B2 | Capítulo Zero JSON + director + finale | 🔧 provisório | Runner fail |
| B3 | Gunslinger + Chain + projétil | 🔧 greybox | Testes unitários PASS |
| B4 | Feedback + áudio placeholder | 🔧 | `feedback_system_tests` PASS |
| B5 | Pipeline visual Calder | 🔧 | `player_visual_pipeline_tests` PASS |
| B6 | Player controllers split | 🔧 | Runner player fail |
| B7 | Export preset + build script | 🔧 | Build não aprovada |
| B8 | test_runner 18 suítes | 🔧 | Gate FAIL (KI-005) |

**Gate atual:** estabilizar runner → playthrough manual → build smoke.

---

## Fase B2 — Estabilização (próximo) 🎯

| # | Tarefa | Doc |
| --- | --- | --- |
| S1 | Runner bootstrap 18/18 PASS | KI-005 P0 |
| S2 | Playthrough menu→fim | KI-004 |
| S3 | Morte/respawn consolidado | KI-001 |
| S4 | Arena deferred spawn | KI-002 |
| S5 | Decisão auto-load | D-013 |

---

## Fase C — Arte Capítulo Zero 📋

| # | Asset | Pré-requisito |
| --- | --- | --- |
| C1 | Calder sprite + anim | Pipeline OK |
| C2 | Rua parallax | Área greybox estável |
| C3 | Inimigo arquétipo 1 visual | Encontro validado manual |
| C4 | Igreja + arena + barreira visual | Arena manual OK |
| C5 | Inimigos 2 e 3 visual | Balance provisório |
| C6 | Elias | Diálogo provisório OK |
| C7 | Subterrâneo / catacumbas | Transição manual OK |
| C8 | Deacon Rusk + telegraphs | Boss test manual |
| C9 | VFX barreira Vermilite | |
| C10 | Estátua + Mol-Khar set piece | Finale manual |
| C11 | Teaser Arcturus | |
| C12 | Variante corrupção (uma área) | |

**Nota:** C1–C12 produzem **conteúdo final**; substituem greybox incrementalmente.  
Controle de slots/status/aprovação: `data/art/beta_asset_manifest.json` — ver `docs/BETA_ASSET_MANIFEST.md` e `docs/ART_APPROVAL_WORKFLOW.md`. Existência de arquivo ≠ `approved`.

---

## Fase D — UI beta 📋

HUD skin, mapa, objetivos finais, diário, pausa polish, Red Brand (≤3 habilidades) — `UI_BIBLE.md`.

Infra pausa/menu **já existe**; fase D é **integração validada + arte**, não criar do zero.

---

## Fase E — Integração beta 📋

Roteiro 30–45 min, áudio produção, QA `TEST_MATRIX.md`, build Windows **aprovada**.

---

## Fase F — Jogo final 📋

Novos capítulos via `ContentRegistry` (sem duplicar shell):

1. `AreaData` + cena em `scenes/areas/`
2. `ChapterData` + JSON narrativa
3. Boss via `BossData`
4. Registrar em `full_game.tres`
5. QA headless + manual

Ver `FINAL_GAME_SCOPE.md`.

---

## Não produzir agora

Cidade inteira, todos arquétipos de uma vez, UI inventário complexo, assets de moodboard copiados.

---

## Checklist por entrega

- [ ] Silhueta legível em gameplay
- [ ] Paleta `ART_BIBLE.md`
- [ ] Hitboxes alinhadas (debug F)
- [ ] Teste manual na área integrada
- [ ] Regressão headless (quando suíte aplicável)

Ver `ROADMAP.md`, `BETA_DEMO_SCOPE.md`.
