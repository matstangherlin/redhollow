# North Star — Final Sample Performance

Medição do trecho X **100–900** vs North Star completo. Alvo projeto: **60 FPS** Windows.

## Como medir

1. Abrir `scenes/tests/street_final_sample_test.tscn` (F6).
2. Modo **FINAL CANDIDATE** (default) ou ciclar com **F**.
3. Toggle overlay **P**.
4. Andar spawn → saloon → plataforma → brawler sample; anotar pior FPS e stutter inicial.

Código: `scripts/visual/street_performance_monitor.gd` → `get_snapshot()`.

## Métricas no overlay

| Métrica | Fonte |
| --- | --- |
| FPS | `Engine.get_frames_per_second()` |
| Frame time | `Performance.TIME_PROCESS` |
| Physics time | `Performance.TIME_PHYSICS_PROCESS` |
| Draw calls | `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` |
| Primitives | `RENDER_TOTAL_PRIMITIVES_IN_FRAME` |
| Memória | `MEMORY_STATIC` |
| Luzes / partículas | contagem na presentation |
| Textura ~MB | estimativa Sprite2D RGBA |
| Stutter inicial | frame time do 1º `_process` |

## Orçamento sample (candidato)

| Item | Orçamento soft | Notas |
| --- | ---: | --- |
| FPS | ≥ 60 | Mesmo viewport 1152×648 |
| Luzes PointLight2D adicionais | ≤ 2 | lantern + vermilite |
| GPUParticles extras | 3 sistemas / ≤ ~31 partículas | dust+paper+smoke |
| Draw calls delta vs North Star | observar | polygons candidatos |
| Texturas PNG novas | 0 | procedural only |

## Baseline documental

Registrar aqui após playtest humano (não auto-aprovar):

| Modo | FPS | Frame ms | Draw calls | Lights | Particles | Mem MB | Stutter0 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| greybox | — | — | — | — | — | — | — |
| north_star | — | — | — | — | — | — | — |
| final_candidate | — | — | — | — | — | — | — |

Headless **não** substitui medição de GPU no editor/export Windows.
