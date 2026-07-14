# Art Production Backlog — Red Hollow Capítulo Zero

Backlog derivado do gate `ART_VERTICAL_SLICE_GATE.md` (**2026-07-13**).

**Veredito vigente (trecho North Star → rua completa):** **APROVADO COMO MOLDE FINAL**  
**Arte PNG beta-ready:** **NÃO**  
**Expandir arte:** rua Cap. Zero apenas — **igreja / catacumbas ainda NÃO**

Ordem permitida até reaprovação: **somente correções P0 do trecho sample + playtest**.

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

*Detalhe: `ART_COST_PER_ROOM.md`.*

---

## Concluído no repo (infra — ≠ arte final)

| Entrega | Status |
| --- | --- |
| Pipeline 12 camadas + toggle greybox / north_star / final_candidate | ✅ |
| Final sample band X 100–900 (`StreetFinalSampleComposer`) | ✅ candidato procedural |
| Church / Underground art areas | ✅ (sem PNG final) |
| Calder / Cult Brawler visual pipelines | ✅ fallback procedural |
| HUD V2 + lighting regional | ✅ |
| Testes street sample / toggle / beta / region / brawler / player | ✅ |

---

## Gate Final Sample — P0 (bloqueia reaprovação)

| ID | Tarefa | Esforço | Status |
| --- | --- | ---: | --- |
| FS1 | Playtest 3 perfis + perguntas 1–10 assinadas | 1 pd QA | 🔲 |
| FS2 | Medir FPS/stutter (**P**) no trecho; preencher tabela | 0.25 pd | 🔲 |
| FS3 | ≥1 PNG real aprovado no trecho (chão ou saloon) no manifesto | 0.75–1.25 pd | 🔲 |
| FS4 | Sheets Calder P0 **ou** Brawler (review→approved) | 1.5–3 pd | 🔲 |
| FS5 | Harmonizar Elias / Gunslinger opcional no trecho | 1–2 pd | 🔲 |

---

## Gate P0 rua (legado — ainda aberto)

| ID | Tarefa | Esforço | Status |
| --- | --- | ---: | --- |
| G1 | Rota elevada legível | 0.75 pd | 🔲 parcial (edge sample) |
| G2 | Ocultar labels debug em art mode | 0.25 pd | ✅ |
| G3 | Medição performance + registro | 0.25 pd | 🔲 |
| G4 | Playtest assinado | 1 pd | 🔲 |
| G5 | Sprites mínimos exit + story props | 0.5 pd | 🔲 |
| G6 | Gunslinger visual pilot | 1–2 pd | 🔲 |
| G7 | Regression tests → street_art canônico | 0.25 pd | 🔲 |
| G8 | Primeiro PNG chão integrado | 0.75 pd | 🔲 |

---

## Backlog — Rua (prioridade = trecho 100–900)

| Prioridade | Asset | Status |
| --- | --- | --- |
| P0 | `street_ground_tileset.png` | 🔲 |
| P0 | plataforma PlatformA | 🔲 |
| P0 | `street_saloon.png` | slot vazio |
| P0 | lamp / statue | slots vazios |
| P1 | parallax / sidewalk | procedural OK / 🔲 |
| P2 | props X>900 | 🔒 após reaprovação |

### Personagens

| Prioridade | Entrega | Status |
| --- | --- | --- |
| P0 | Calder sheets 40×72 (pacote piloto) | 🔲 missing |
| P0 | Cult Brawler sheets 34×56 | 🔲 missing |
| P1 | Elias / Gunslinger visual | 🔲 |

---

## Bloqueados até reaprovação do trecho

| Área | Motivo |
| --- | --- |
| Igreja (arte PNG / polish) | Gate REPROVADO |
| Catacumbas (arte PNG / polish) | Gate REPROVADO |
| Rua X>900 como “final” | Sample não aprovado |

---

## Documentos relacionados

- `ART_VERTICAL_SLICE_GATE.md` — **REPROVADO**
- `ART_COST_PER_ROOM.md`
- `PLAYTEST_VISUAL_FORM.md`
- `NORTH_STAR_FINAL_SAMPLE.md`
- `BETA_ASSET_MANIFEST.md`
