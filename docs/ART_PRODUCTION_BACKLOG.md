# Art Production Backlog — Red Hollow Capítulo Zero

Backlog derivado do gate `ART_VERTICAL_SLICE_GATE.md` (**2026-07-13**).  
**Veredito:** **APROVADO COM AJUSTES** — molde técnico válido nas três áreas Capítulo Zero (rua, igreja, catacumbas).

Ordem: **rua → igreja → catacumbas** — concluída em código procedural + slots PNG.

---

## Resumo executivo

| Métrica | Rua (referência) | Igreja (estimativa) | Catacumbas (estimativa) | **Total Ch. Zero** |
| --- | ---: | ---: | ---: | ---: |
| Assets ambiente (PNG únicos) | 19 | 24 | 22 | **~65** |
| Props com slot | 11 | 14 | 10 | **~35** |
| Sheets parallax | 4 | 3 | 3 | **10** |
| Tilesets | 2 | 3 | 2 | **7** |
| VFX ambiente | 2 | 3 | 4 | **9** |
| Animações Calder (restantes) | 12 clips | — | — | **12 clips** |
| Animações inimigos (arte PNG) | Brawler sheets | Chain | Rusk | **~21 clips novos** |
| **Custo estimado (arte)** | 11–13 pd | 4–6 pd | 4–6 pd | **38–42 pd** |
| **Custo estimado (USD indie)** | $5.4k–8.5k | $4.4k–6.6k | $5.2k–7.7k | **$15k–23k** |

*Detalhe de custo: `ART_COST_PER_ROOM.md`.*

---

## Concluído no repo (não re-fazer)

| Entrega | Status |
| --- | --- |
| Pipeline 12 camadas + `StreetArtArea` toggle | ✅ |
| `ChurchArtArea` + apresentação igreja | ✅ 2026-07-13 |
| `UndergroundArtArea` + apresentação catacumbas | ✅ 2026-07-13 |
| Demo usa `vertical_slice_street_art.tscn` | ✅ |
| Calder `PlayerVisualController` + 10 clips procedural | ✅ |
| Cult Brawler visual pipeline (12 clips procedural) | ✅ |
| `CombatFeedbackProfile` (6 perfis) | ✅ |
| HUD V2 na demo (`use_hud_v2`) | ✅ |
| Iluminação regional North Star (4 estados) | ✅ |
| Fix NPC visível + z_index gameplay + tecla **'** luz | ✅ 2026-07-13 |
| Testes: `street_art_toggle` 5/5, `region_visual` 6/6, brawler visual 6/6 | ✅ |

---

## Gate P0 — obrigatório antes de igreja/catacumbas

| ID | Tarefa | Esforço | Status |
| --- | --- | ---: | --- |
| G1 | Rota elevada legível (plataformas art) | 0.75 pd | 🔲 |
| G2 | Ocultar labels debug em art mode | 0.25 pd | ✅ |
| G3 | Medição performance + registro (`PLAYTEST_VISUAL_FORM`) | 0.25 pd | 🔲 |
| G4 | Playtest 4 perfis assinado | 1 pd | 🔲 |
| G5 | Sprites mínimos exit + story props (3) | 0.5 pd arte | 🔲 |
| G6 | Gunslinger visual pilot ou contorno | 1–2 pd arte | 🔲 |
| G7 | Regression tests → `street_art` canônico | 0.25 pd dev | 🔲 |
| G8 | Primeiro PNG chão integrado | 0.75 pd | 🔲 |

**Total P0 restante:** ~4.5 pd (dev + arte + QA).

---

## Backlog — Rua (`vs_greybox_street`)

### Ambiente (19 assets)

Fonte: `STREET_ART_MISSING_ASSETS.md` + slots em `street_art_presentation.gd`.

| Prioridade | Asset | Tipo | pd est. | Status |
| --- | --- | --- | ---: | --- |
| P0 | `street_ground_tileset.png` | Tileset 16px | 0.5 | 🔲 |
| P0 | Plataformas elevadas (3 variantes) | Tile/sprite | 0.5 | 🔲 |
| P0 | `street_sidewalk_tileset.png` | Tileset 16px | 0.25 | 🔲 |
| P1 | `street_bg_sky_sunset.png` | Parallax | 0.5 | procedural OK |
| P1 | `street_bg_mountains.png` | Parallax | 0.5 | procedural OK |
| P1 | `street_bg_city_silhouette.png` | Parallax | 0.75 | procedural OK |
| P1 | `street_saloon.png` | Prop 192×128 | 0.75 | slot vazio |
| P1 | `street_closed_building.png` | Prop 160×112 | 0.5 | slot vazio |
| P2 | Props wagon/barrels/fence/statue/signs/lamp | 7 props | 1.5 | slots |
| P2 | `dust_mote.png`, `lantern_glow.png` | VFX | 0.25 | 🔲 |
| P2 | Interativos leitura (exit, cache, prop) | 3 sprites | 0.5 | 🔲 |

### Personagens na rua

| Prioridade | Entrega | Clips | pd est. | Status |
| --- | --- | ---: | ---: | --- |
| P0 | Calder sheets 40×72 (10 clips piloto → PNG) | 38 fr | 3–4 | procedural OK |
| P0 | Cult Brawler sheets finais | 34 fr | 1.5–2 | pipeline OK |
| P1 | Vermilite Gunslinger visual | ~24 fr | 2–3 | greybox |
| P2 | Elias overworld | 4–6 fr | 0.5–1 | greybox |

---

## Backlog — Igreja (`vs_greybox_church`)

**Molde técnico:** ✅ `vertical_slice_church_art.tscn` — ver `CHURCH_BETA_COMPLETE.md`

| Categoria | Assets | pd est. | Status |
| --- | ---: | ---: | --- |
| Set pieces PNG | 6 + 7 kit | 14–24 h | 🔲 slots |
| Chain Penitent visual | ~30 fr | 2.5–3 | procedural |
| VFX barreira / cera | 3 | 1 | 🔲 |

---

## Backlog — Catacumbas (`vs_greybox_underground`)

**Molde técnico:** ✅ `vertical_slice_underground_art.tscn` — ver `UNDERGROUND_BETA_COMPLETE.md`

| Categoria | Assets | pd est. | Status |
| --- | ---: | ---: | --- |
| Set pieces PNG | 4 + 9 kit | 18–28 h | 🔲 slots |
| Finale VFX (olhos, sombra, Arcturus) | 3 | 2–3 | hooks ✅ |
| Deacon Rusk visual | ~55 fr | 4–5 | procedural |
| Boss arena polish | 1 | 1 | procedural ring ✅ |

---

## Animações — inventário atualizado

### Calder

| Status | Clips | Frames ~ |
| --- | ---: | ---: |
| Integrado (procedural) | 10 | 38 |
| Restantes produção | **12** | ~47 |
| **Total alvo** | 22 | ~85 |

### Inimigos

| Inimigo | Pipeline | Clips | Arte PNG |
| --- | --- | ---: | --- |
| Cult Brawler | ✅ completo | 12 | 🔲 sheets |
| Gunslinger | greybox | 5 | 🔲 |
| Chain Penitent | greybox | 6 | 🔲 bloqueado |
| Deacon Rusk | greybox | 10 | 🔲 bloqueado |

---

## Ordem de produção (atualizada)

```
Fase 0 — Gate P0 rua (G1, G3, G4, G5, G6, G8)     ← VOCÊ ESTÁ AQUI
    ↓
Fase 1 — PNG chão + plataformas + sheets Brawler + Calder P0 PNG
    ↓
Fase 2 — Parallax P1 + props + Gunslinger visual
    ↓
Fase 3 — Gate rua “beta visual ready” + playtest assinado
    ↓
Fase 4 — Molde igreja (código) + ambiente + Chain Penitent
    ↓
Fase 5 — Catacumbas + Rusk + estátua
    ↓
Fase 6 — Calder P1/P2 + HUD skin + build Windows QA
```

---

## Definição de pronto por asset

- [ ] PNG em `art/` com import Nearest (`ASSET_IMPORT_RULES.md`)
- [ ] Substitui slot ou tile documentado
- [ ] Silhueta legível em captura 480×270
- [ ] Paleta `ART_BIBLE.md` / `RED_HOLLOW_COLOR_PALETTE.md`
- [ ] Hitbox debug (F) inalterada após personagem
- [ ] Regressão headless aplicável passa
- [ ] Entrada em playtest form ou checklist de área

---

## Não produzir agora

- Arte final igreja/catacumbas antes de P0 rua
- Mapa artístico final
- Variante corrupção full-screen (usar `RegionVisualController` por estado)
- Todos arquétipos `ART_BIBLE.md`
- Expansão de cidades além Capítulo Zero

---

## Documentos relacionados

| Documento | Uso |
| --- | --- |
| `ART_VERTICAL_SLICE_GATE.md` | Veredito formal |
| `ART_COST_PER_ROOM.md` | Estimativas pd/USD |
| `PLAYTEST_VISUAL_FORM.md` | Checklist humano |
| `CULT_BRAWLER_VISUAL_SPEC.md` | Inimigo referência |
| `STREET_ART_VERTICAL_SLICE.md` | Arquitetura camadas |
| `CONTENT_PRODUCTION_PLAN.md` | Fases produto |
