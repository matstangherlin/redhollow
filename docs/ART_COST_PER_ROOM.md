# Art Cost Per Room — Red Hollow Capítulo Zero

Estimativas para planejamento de produção.  
**Gate vigente (trecho final sample X 100–900):** `ART_VERTICAL_SLICE_GATE.md` — veredito **REPROVADO** (2026-07-13).  
**Unidade:** person-day (pd) = 8 h de artista pixel art experiente.  
**USD:** faixa indie remoto LATAM/EU 2026 ($400–550/pd).

---

## Leitura de custo após gate do trecho

| Pergunta | Resposta |
| --- | --- |
| O sample `final_candidate` reduz custo? | **Não.** É `PLACEHOLDER_CANDIDATE`; não substitui PNG. |
| Custo/sala inviável? | **Não** — envelope Cap. Zero permanece ~38–42 pd / $15k–23k. |
| O que muda no plano? | Priorizar **chão + saloon + plataforma** no trecho 100–900 antes do restante da rua. |
| Expandir igreja/catacumbas? | **Não** enquanto o gate do trecho estiver REPROVADO. |

### Fatia trecho vs rua completa (ambiente)

| Fatia | Assets alvo | pd arte est. |
| --- | ---: | ---: |
| Trecho 100–900 (P0) | ~8–10 | **3.5–4.5** |
| Resto 900–2400 | ~9–11 | ~3.0 |
| Rua total ambiente | 19 | **~6.5** |

---

## Resumo por sala

| Sala | Ambiente (arte) | Personagens locais | Integração Godot | **Total pd** | **USD indie** |
| --- | ---: | ---: | ---: | ---: | ---: |
| **Rua North Star** (piloto — em curso) | 6.5 | 5–7 | 2.0 | **13.5–15.5** | **$5.4k–8.5k** |
| **Igreja** (bloqueada) | 7.5 | 2.5–3 | 1.0 | **11–12** | **$4.4k–6.6k** |
| **Catacumbas** (bloqueada) | 8.0 | 4–5 | 1.0 | **13–14** | **$5.2k–7.7k** |
| **Capítulo Zero total** | 22 | 12–15 | 4 | **38–42** | **$15k–23k** |

*Rua inclui maior fatia do Calder (10 clips P0 + integração). Igreja/catacumbas reutilizam Calder completo e pipeline lighting.*

---

## Custo por sala — detalhe (rua North Star)

### Ambiente (19 assets PNG alvo)

| Categoria | Assets | pd est. |
| --- | ---: | ---: |
| Tilesets chão + calçada | 2 | 0.75 |
| Plataformas elevadas (3 variantes) | 3 | 0.5 |
| Parallax (céu, montanhas, cidade, mid) | 4 | 2.5 |
| Estruturas gameplay (saloon, fechado) | 2 | 1.25 |
| Props (wagon, barrels, fence, statue, signs, lamp) | 7 | 1.35 |
| VFX ambiente (dust, lantern glow) | 2 | 0.25 |
| Interativos leitura (exit, props, cache) | 3 | 0.5 |
| **Subtotal ambiente** | **19** | **~6.5** |

### Integração técnica (dev — não arte)

| Tarefa | pd est. |
| --- | ---: |
| Pipeline camadas + perfil (feito) | 0 |
| RegionVisualController + tema (feito) | 0 |
| Slots PNG + import rules | 0.5 |
| Gate P0 (plataformas, props, performance) | 0.75 |
| Playtest + fixes | 0.75 |
| **Subtotal integração rua** | **2.0** |

---

## Custo por personagem

| Personagem | Estado gate 2026-07-13 | Clips / frames | Restante arte | pd restante | USD |
| --- | --- | ---: | ---: | ---: | ---: |
| **Calder Knox** | Piloto procedural 10 clips | 22 total (~85 fr) | 12 clips + sheets 40×72 | **6–7** | **$2.4k–3.8k** |
| **Cult Brawler** | Pilot procedural 12 clips integrado | 12 (~34 fr) | Sheets PNG finais | **1.5–2** | **$600–1.1k** |
| **Vermilite Gunslinger** | Greybox | ~5 (~24 fr) | Pipeline + sheets | **2–3** | **$800–1.6k** |
| **Elias NPC** | Greybox polígono | 4–6 fr | Retrato + overworld | **0.5–1** | **$200–550** |
| **Chain Penitent** | Greybox (igreja) | ~6 (~30 fr) | Bloqueado | **2.5–3** | **$1k–1.6k** |
| **Deacon Rusk** | Greybox (catacumbas) | ~10 (~55 fr) | Bloqueado | **4–5** | **$1.6k–2.7k** |

### Fórmula rápida por inimigo novo (após Brawler referência)

| Fase | pd |
| --- | ---: |
| Concept + silhueta | 0.25 |
| Sprite base + 6 clips combate | 2.0 |
| Clips extras (hurt, death, telegraph) | 0.5–1.0 |
| Integração + validator | 0.25 dev |
| **Total arquétipo padrão** | **~3 pd arte** |

---

## Quantidade de assets — beta Capítulo Zero

| Categoria | Quantidade estimada |
| --- | ---: |
| PNG ambiente únicos | **~65** |
| Props com slot documentado | **~35** |
| Sheets parallax | **10** |
| Tilesets 16 px | **7** |
| VFX ambiente (poeira, glow, barreira) | **9** |
| UI skin final (fora sala) | **~15** elementos |
| SFX licenciados substituindo placeholder | **~40** one-shots |

---

## Animações restantes

| Personagem / sistema | Integrado | Restante | Frames ~rest. |
| --- | ---: | ---: | ---: |
| Calder | 10 clips | **12 clips** | **~47** |
| Cult Brawler | 12 clips (procedural) | **0 clips** (só arte PNG) | **0** novos |
| Gunslinger | 0 visual | **5 clips** | **~24** |
| Chain Penitent | 0 visual | **6 clips** | **~30** |
| Deacon Rusk | 0 visual | **10 clips** | **~55** |
| **Total clips novos beta** | — | **~33** | **~156 frames** |

*Substituir procedural por PNG não conta como clip novo — conta como retrabalho de arte nos mesmos IDs.*

---

## VFX e UI (pacotes transversais)

| Pacote | Itens | pd | USD |
| --- | ---: | ---: | ---: |
| Telegraphs + impactos (`VFX_LANGUAGE.md`) | ~12 | 2–3 | $800–1.6k |
| HUD beta skin (`UI_BIBLE.md`) | ~15 | 3–4 | $1.2k–2.2k |
| Barreira Vermilite + checkpoint estados | 4 | 0.5 | $200–275 |

---

## O que já está pago (investimento até o gate)

| Entrega | Valor equivalente evitado |
| --- | --- |
| Pipeline 12 camadas + toggle | ~2 pd dev |
| Calder visual controller + 10 clips procedural | ~1.5 pd arte + 1 pd dev |
| Cult Brawler pipeline completo (12 clips) | ~2 pd arte + 0.5 pd dev |
| Lighting regional (4 estados) | ~1 pd dev |
| CombatFeedbackProfile (6 perfis) | ~0.5 pd dev |
| HUD V2 estrutural | ~1 pd dev |
| Testes headless visuais (5 suítes) | ~1 pd dev |

**Total infra já no repo:** ~10–11 pd equivalentes — **não repetir** ao estimar igreja/catacumbas (custo de molde ~0.5 pd/sala).

---

## Regras de orçamento

1. **Não iniciar igreja/catacumbas** até o gate do trecho final sample deixar de ser REPROVADO (FS1–FS5) e P0 rua G1/G3/G4 fecharem.  
2. **Reutilizar** `EnvironmentVisualProfile` + `RegionVisualTheme` — não duplicar lógica por sala.  
3. **Um atlas por área** quando possível (≤2048 px, `ASSET_IMPORT_RULES.md`).  
4. **Cult Brawler** é template — próximos inimigos devem custar ≤3 pd arte cada.  
5. Registrar desvio >20% no próximo gate.  
6. **Existência ≠ approved** — manifesto `draft`/`missing` não conta como custo pago de arte final.

---

## Documentos relacionados

- `ART_VERTICAL_SLICE_GATE.md` — veredito e P0  
- `ART_PRODUCTION_BACKLOG.md` — ordem de execução  
- `CONTENT_PRODUCTION_PLAN.md` — fases produto  
- `STREET_ART_MISSING_ASSETS.md` — lista PNG rua
