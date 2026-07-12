# Art Production Backlog — Red Hollow Capítulo Zero

Backlog derivado do gate `ART_VERTICAL_SLICE_GATE.md` (2026-07-12).  
**Status do molde:** APROVADO COMO MOLDE — produção pode seguir este documento.

Ordem: **rua (referência) → igreja → catacumbas** — uma sala por vez, gate por sala.

---

## Resumo executivo

| Métrica | Rua (referência) | Igreja (estimativa) | Catacumbas (estimativa) | **Total Ch. Zero** |
| --- | ---: | ---: | ---: | ---: |
| Assets ambiente (PNG únicos) | 19 | 24 | 22 | **~65** |
| Props com slot | 11 | 14 | 10 | **~35** |
| Sheets parallax | 4 | 3 | 3 | **10** |
| Tilesets | 2 | 3 | 2 | **7** |
| VFX ambiente | 2 | 3 | 4 | **9** |
| Animações Calder (restantes) | — | — | — | **12 clips** |
| Animações inimigos (3 arquétipos) | 2 na rua | 1 | 1 | **~22 clips** |
| Animações Deacon Rusk | — | — | 1 boss | **~10 clips** |
| **Custo estimado (arte)** | 3–5 pd | 4–6 pd | 4–6 pd | **11–17 pd** |
| **Custo estimado (USD indie)** | $1.2k–2.5k | $1.6k–3k | $1.6k–3k | **$4.4k–8.5k** |

*pd = person-days de artista pixel art experiente (8 h). USD = faixa mercado indie LATAM/EU remoto 2026.*

---

## Gate P0 — correções técnicas (código, sem arte nova)

| ID | Tarefa | Esforço | Bloqueia |
| --- | --- | ---: | --- |
| G1 | Plataformas visíveis em modo art | 0.5 pd dev | Beta visual rua |
| G2 | Ocultar labels debug em modo art | 0.25 pd dev | Capturas gate |
| G3 | Medição performance + registro | 0.25 pd QA | Integração demo |
| G4 | Playtest manual assinado rua art | 0.5 pd QA | Próximo gate |

**Total P0 técnico:** ~1.5 pd (dev + QA).

---

## Backlog — Rua (`vs_greybox_street`)

### Ambiente (19 assets)

Fonte canônica: `STREET_ART_MISSING_ASSETS.md`.

| Prioridade | Asset | Tipo | pd est. |
| --- | --- | --- | ---: |
| P0 | `street_ground_tileset.png` | Tileset 16px | 0.5 |
| P0 | `street_sidewalk_tileset.png` | Tileset 16px | 0.25 |
| P0 | Plataformas elevadas (3 variantes ou tile único) | Tile/sprite | 0.5 |
| P1 | `street_bg_sky_sunset.png` | Parallax | 0.5 |
| P1 | `street_bg_mountains.png` | Parallax | 0.5 |
| P1 | `street_bg_city_silhouette.png` | Parallax | 0.75 |
| P1 | `street_bg_mid_buildings.png` | Parallax | 0.75 |
| P1 | `street_saloon.png` | Prop 192×128 | 0.75 |
| P1 | `street_closed_building.png` | Prop 160×112 | 0.5 |
| P2 | `street_wagon.png` | Prop | 0.25 |
| P2 | `street_barrels.png` | Prop | 0.15 |
| P2 | `street_fence.png` | Prop | 0.25 |
| P2 | `street_statue_small.png` | Prop (Ordem) | 0.25 |
| P2 | `street_sign_saloon.png` | Prop | 0.15 |
| P2 | `street_sign_order.png` | Prop | 0.15 |
| P2 | `street_lamp_post.png` | Prop ×3 instâncias | 0.35 |
| P2 | `dust_mote.png` | VFX 8×8 | 0.1 |
| P2 | `lantern_glow.png` | VFX luz | 0.15 |
| P2 | Interativos leitura (exit, cache, story prop) | 3 sprites | 0.5 |

**Subtotal rua ambiente:** ~6.5 pd arte + 1.5 pd integração Godot.

### Personagens na rua

| Prioridade | Entrega | Clips / frames | pd est. |
| --- | --- | --- | ---: |
| P0 | Calder — 10 sheets piloto → PNG final | 38 frames | 3–4 |
| P1 | Cult Brawler visual | idle, run, jab, punish, hurt, death (~28 fr) | 2–3 |
| P1 | Vermilite Gunslinger visual | idle, aim, shoot, hurt, death (~24 fr) | 2–3 |
| P2 | Elias NPC (retrato + overworld mínimo) | 4–6 fr | 0.5–1 |

---

## Backlog — Igreja (`vs_greybox_church`)

*Só iniciar após gate rua P0 + primeiro PNG de chão integrado.*

| Categoria | Assets estimados | pd est. |
| --- | ---: | ---: |
| Tilesets pedra + pátio | 3 | 1.5 |
| Parallax (torre, cruzes, névoa) | 3 | 2 |
| Props (altar menor, bancos, portão arena, barreira frame) | 14 | 3 |
| VFX (cera, incense, barreira pulso) | 3 | 1 |
| Iluminação (vitral fake, tochas) | integrado | 0.5 |
| **Molde técnico** | clonar rua → `church_art_presentation` | 0.5 dev |

| Personagens | pd est. |
| --- | ---: |
| Chain Penitent visual | 2.5–3 |
| Arena props destrutíveis (greybox → art) | 1 |

**Subtotal igreja:** ~4–6 pd arte + 1 pd dev/integração.

---

## Backlog — Catacumbas (`vs_greybox_underground`)

| Categoria | Assets estimados | pd est. |
| --- | ---: | ---: |
| Tilesets umidade + pedra | 2 | 1 |
| Parallax (túnel, estátua colossal fundo) | 3 | 2.5 |
| Props (goteiras, ossos, checkpoint Vermilite, diário) | 10 | 2 |
| VFX (gota, névoa, pulso distante Rubro) | 4 | 1 |
| Set piece estátua Mol-Khar (silhueta) | 1 grande | 1.5 |
| **Molde técnico** | `underground_art_presentation` | 0.5 dev |

| Personagens | pd est. |
| --- | ---: |
| Deacon Rusk — sprite + telegraphs | 4–5 |
| Checkpoint ativo/inativo | 2 estados | 0.25 |

**Subtotal catacumbas:** ~4–6 pd arte + 1 pd dev/integração.

---

## Animações Calder — inventário completo

| Status | Clips | Frames aprox. |
| --- | ---: | ---: |
| **Piloto procedural (integrado)** | 10 | 38 |
| **Restantes produção** | 12 | ~47 |
| **Total alvo** | 22 | ~85 |

### Restantes (prioridade)

| ID | Prioridade | Frames est. | Uso |
| --- | --- | ---: | --- |
| `turn` | P1 | 2 | Virada |
| `jump_start` | P1 | 2 | Impulso |
| `death` | P1 | 6 | Morte |
| `red_brand_charge` | P1 | 4 | Breaker |
| `red_brand_breaker` | P1 | 6 | Breaker |
| `counter_window` | P2 | 3 | Counter |
| `counter_attack` | P2 | 4 | Counter |
| `taunt_01` / `taunt_02` | P2 | 4+4 | Provocação |
| `knockdown` | P2 | 4 | Queda longa |
| `respawn` | P2 | 4 | Checkpoint |
| `interact` | P2 | 3 | Examinar |

**Custo restante Calder:** ~4–5 pd (arte) + 0.5 pd integração.

---

## Animações inimigos — inventário

| Inimigo | Clips típicos | Frames est. | Onde aparece |
| --- | ---: | ---: | --- |
| Cult Brawler | 6 | ~28 | Rua, arena |
| Vermilite Gunslinger | 5 | ~24 | Rua elevada, duo |
| Chain Penitent | 6 | ~30 | Igreja alcova |
| Deacon Rusk | 10 | ~55 | Catacumbas boss |

**Total clips inimigos:** ~27  
**Total frames inimigos:** ~137  
**Custo:** ~9–12 pd arte.

---

## Custo por sala (referência rápida)

| Sala | Arte ambiente | Personagens locais | Integração | **Total pd** | **USD indie** |
| --- | ---: | ---: | ---: | ---: | ---: |
| **Rua** | 6.5 | 6–8 (Calder parcial + 2 inimigos + Elias) | 1.5 | **14–16** | **$5.5k–8k** |
| **Igreja** | 7.5 | 2.5–3 | 1 | **11–12** | **$4k–5.5k** |
| **Catacumbas** | 8 | 4–5 (Rusk) | 1 | **13–14** | **$5k–6.5k** |

*Rua inclui maior fatia do Calder (10 clips P0). Igreja/catacumbas reutilizam Calder completo.*

### Capítulo Zero completo (arte visual beta)

| Item | pd | USD indie |
| --- | ---: | ---: |
| 3 salas ambiente + props | 22 | $8k–12k |
| Calder 22 clips | 7–8 | $2.8k–4k |
| 4 personagens inimigos/NPC | 10–12 | $4k–5k |
| VFX pacote (`VFX_LANGUAGE.md`) | 3–4 | $1.2k–1.8k |
| Integração + QA arte | 4–5 | interno |
| **Total** | **46–51 pd** | **$16k–23k** |

---

## Ordem de produção recomendada

```
Fase 0 — Gate P0 técnico (G1–G4)
    ↓
Fase 1 — Rua chão + plataformas + Calder P0 (10 clips)
    ↓
Fase 2 — Rua parallax + props P1 + Brawler/Gunslinger
    ↓
Fase 3 — Gate rua “primeiro PNG” → aprovar igreja molde
    ↓
Fase 4 — Igreja ambiente + Chain Penitent + barreira VFX
    ↓
Fase 5 — Catacumbas + Rusk + estátua set piece
    ↓
Fase 6 — Calder P1/P2 + VFX telegraphs + integração demo
```

---

## Definição de pronto por asset

- [ ] PNG em `art/` com import Nearest (`ASSET_IMPORT_RULES.md`)
- [ ] Substitui slot ou tile documentado
- [ ] Silhueta legível em 480×270 captura
- [ ] Paleta `ART_BIBLE.md` (Vermilite ≤2 acentos por tela)
- [ ] Hitbox debug (F) inalterada após integração personagem
- [ ] Regressão headless aplicável passa
- [ ] Entrada em `STREET_ART_SCREENSHOT_CHECKLIST.md` ou equivalente da área

---

## Documentos relacionados

| Documento | Uso |
| --- | --- |
| `ART_VERTICAL_SLICE_GATE.md` | Veredito e correções |
| `STREET_ART_MISSING_ASSETS.md` | Lista PNG rua |
| `STREET_ART_VERTICAL_SLICE.md` | Arquitetura camadas |
| `CONTENT_PRODUCTION_PLAN.md` | Fase C integração |
| `ANIMATION_PIPELINE.md` | Clips Calder |
| `VFX_LANGUAGE.md` | Telegraphs e Vermilite |

---

## Não produzir agora

- Igreja/catacumbas **arte final** antes de G1–G4 na rua
- Cidade completa, todos arquétipos `ART_BIBLE.md`
- Mapa artístico final (mapa interligado usa provisório)
- Variante corrupção Ressonância Rubra (após uma área normal aprovada)
