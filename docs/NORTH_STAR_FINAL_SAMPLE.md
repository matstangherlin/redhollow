# North Star — Final Sample (rua)

Amostra visual **praticamente final** limitada a um trecho da rua do Capítulo Zero.  
**Não** finaliza a rua inteira. **Não** altera igreja nem catacumbas. **Não** cria novas regiões.

## Faixa X (explícita)

| Campo | Valor |
| --- | ---: |
| `SAMPLE_X_MIN` | **100** |
| `SAMPLE_X_MAX` | **900** |
| Largura | **800 px** (dentro de 600–900) |
| Camera crop | `Rect2(100, 200, 800, 1000)` |

Código: `scripts/visual/street_final_sample_spec.gd`

## Conteúdo do trecho

| Elemento | X | Notas |
| --- | ---: | --- |
| Calder (spawn) | 120 | `Spawns/DefaultSpawn` |
| Lampião | 180 | upgrade candidate + luz |
| Elias | 260 | NPC produção |
| Saloon | 300 | madeira/tecto/pano detalhados |
| Segredo / pista | 480 | chalk discreto + `SecretCache` |
| Estátua | 520 | pedra + coração da Ordem |
| Plataforma elevada | 560 | `PlatformA` + deck com bordas legíveis |
| Cult Brawler (sample) | 740 | `CultBrawlerFinalSample` **só** no modo final candidate |
| Cult Brawler (produção) | 1280 | permanece; fora do trecho |
| Montanhas / pôr do sol | parallax | bloom amostral no céu |

## Mood (leitura em poucos segundos)

Faroeste decadente · anime · Ordem do Coração Rubro · Vermilite · mistério · terror religioso · combate estilizado.

## Modos (toggle F)

1. **greybox** — polígonos de nível
2. **north_star** — procedural piloto completo (rua 2400)
3. **final_candidate** — North Star + upgrade **somente** na faixa 100–900

Cenas: `scenes/tests/street_art_test.tscn`, `scenes/tests/street_final_sample_test.tscn`

## Assets

- Somente arte procedural **própria** + placeholders claramente marcados `PLACEHOLDER_CANDIDATE`.
- Nenhum PNG de internet / moodboard.
- Manifesto: slots de rua **não** marcados `integrated` (ainda sem sheets aprovados).

## Performance

Overlay **P** → `StreetPerformanceMonitor` (FPS, frame time, draw calls, luzes, partículas, memória, estimativa de textura, stutter do 1º frame).  
Ver `docs/NORTH_STAR_FINAL_PERFORMANCE.md`.

## Veredito deste sample

Gate: **APROVADO COMO MOLDE FINAL** — molde aplicado à rua completa via `StreetFinalMoldComposer`.  
Ver `docs/STREET_FINAL_MOLD.md` e `docs/ART_VERTICAL_SLICE_GATE.md`.  
Igreja/catacumbas não tocadas. Procedural ≠ `integrated`.
