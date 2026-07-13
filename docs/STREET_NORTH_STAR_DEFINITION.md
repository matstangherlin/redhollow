# Street North-Star Definition — Red Hollow

Definição da **rua-alvo** de Capítulo Zero: uma única sala que estabelece qualidade visual, pipeline técnico e ritmo de produção para o restante do jogo.

> **Escopo:** apenas a rua (`vs_greybox_street`). Igreja, catacumbas e mapa completo ficam fora desta entrega.

## Identidade visual

A rua deve comunicar, de forma **original**:

| Pilar | Tradução visual |
| --- | --- |
| Faroeste decadente | madeira gasta, tinta descascada, calçada irregular |
| Cidade mineradora | cicatriz de mina nas montanhas, fumaça distante, Vermilite |
| Pôr do sol | `CanvasModulate` quente, sol baixo, sombras longas |
| Poeira e isolamento | partículas de poeira, véu de poeira no foreground |
| Culto / Ordem | estátua pequena, placas, símbolo do Coração Rubro |
| Mol-Khar (distante) | brilho rubro no horizonte — sugestão, não dominância |
| Violência recente | prédio abandonado com janelas boarded, carroça solitária |

**Proibido:** copiar cenas, logos ou composições específicas de outros jogos; usar imagens do moodboard como texture source.

## Arquitetura de camadas (12)

| # | Nó | Conteúdo | z | Parallax |
| ---: | --- | --- | ---: | ---: |
| 1 | `Layer01_Sky` | gradiente, sol poente, glow Mol-Khar | -120 | 0.05 |
| 2 | `Layer02_FarMountains` | cordilheira + cicatriz de mina | -100 | 0.12 |
| 3 | `Layer03_DistantTown` | skyline, torre distante, fumaça | -80 | 0.22 |
| 4 | `Layer04_MidgroundBuildings` | fachadas parallax médias | -40 | 0.38 |
| — | `SunsetModulate` | grading global | — | — |
| 5 | `Layer05_GameplayGround` | terra, calçada, **plataformas de gameplay** | 0 | 1.0 |
| 6 | `Layer06_GameplayStructures` | saloon, prédio abandonado, toldo | 5 | 1.0 |
| 7 | `Layer07_Props` | postes, carroça, barris, cercas, vegetação seca, Vermilite | 10 | 1.0 |
| 8 | `Layer08_Interactables` | marcadores visuais discretos (sem alterar gameplay) | 12 | 1.0 |
| 9 | `Layer09_Lighting` | directional sunset + lanternas + janelas | 20 | — |
| 10 | `Layer10_Atmosphere` | poeira, detritos, folhas, fumaça, motes Vermilite | 50 | 1.0 |
| 11 | `Layer11_Foreground` | silhueta de varanda/cerca, véu de poeira | 40 | 1.05 |
| 12 | `Layer12_Debug` | `StreetPerformanceMonitor` (P no teste) | 90 | — |

**Colisão** permanece em `Solids/` — nunca desenhada na textura de arte.

## Cenário mínimo (checklist de conteúdo)

- [x] chão de terra procedural
- [x] calçada de madeira com tábuas
- [x] saloon com varanda e placa
- [x] prédio abandonado
- [x] telhados e toldo
- [x] portas e janelas (silhueta)
- [x] postes e lampiões
- [x] placas (saloon)
- [x] caixas e barris
- [x] carroça
- [x] cercas (médio + foreground)
- [x] vegetação seca
- [x] estátua da Ordem
- [x] símbolo Coração Rubro
- [x] Vermilite discreta (cristais + luz + partículas)
- [x] montanhas e cidade distante
- [x] plataformas elevadas visíveis (fix KI-ART-G1)

Slots PNG invisíveis reservam paths para arte final substituir silhuetas procedurais.

## Gameplay preservado

Sem alteração em:

- `Solids`, `Spawns`, `WorldObjects`, `Exits`
- Elias, pistas, combate, duo gate, segredo, igreja
- `area_id`, `camera_limits`, save, respawn, mapa, objetivo

## Alternância GREYBOX ↔ ART PILOT

| Controle | Ação |
| --- | --- |
| **F** (`debug_toggle`) | alterna greybox / art pilot |
| **P** | overlay de performance (art mode) |

Cenas: `vertical_slice_street.tscn` (greybox) · `vertical_slice_street_art.tscn` (art) · `street_art_test.tscn` (QA isolado).

## Performance alvo

| Métrica | Orçamento |
| --- | ---: |
| FPS | 60 |
| Frame time | ≤ 16.7 ms |
| Draw calls | ≤ 80 |
| Point lights | ≤ 6 |
| Partículas GPU | ≤ 180 |
| Stutter no 1º golpe | 0 (assets pré-carregados na cena) |

Medição: `StreetPerformanceMonitor` + Godot Debugger em build release.

## Pipeline de produção

1. **North-star procedural** (esta entrega) — valida composição, parallax, luz, gameplay overlay.
2. **PNG drop-in** — substituir slots documentados em `STREET_ART_MISSING_ASSETS.md`.
3. **TileMap** — chão/calçada em `street_ground_tileset.png` / `street_sidewalk_tileset.png`.
4. **Sign-off** — `STREET_ART_SCREENSHOT_CHECKLIST.md` + gate `ART_VERTICAL_SLICE_GATE.md`.

## Arquivos-chave

| Arquivo | Função |
| --- | --- |
| `scripts/visual/street_north_star_factory.gd` | Silhuetas procedurais originais |
| `scripts/visual/street_art_presentation.gd` | Montagem das 12 camadas |
| `scripts/visual/street_art_area.gd` | Toggle + oculta debug greybox |
| `scripts/visual/street_performance_monitor.gd` | Overlay FPS/draw calls |
| `resources/visual/chapter_zero_street_profile.tres` | Contrato resolução/performance |

## Documentos relacionados

`STREET_ART_VERTICAL_SLICE.md`, `STREET_ART_MISSING_ASSETS.md`, `STREET_ART_SCREENSHOT_CHECKLIST.md`, `PERFORMANCE_BUDGET.md`, `ART_BIBLE.md`, `ENVIRONMENT_ART_GUIDE.md`
