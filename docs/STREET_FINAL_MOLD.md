# Street Final Mold — Cap. Zero full street

**Status:** molde final **aprovado** aplicado à rua completa (0–2400).  
**Não** altera igreja nem catacumbas.  
**Não** marca PNG placeholder como `integrated`.

## Distritos (preservados)

| # | Distrito | X |
| ---: | --- | --- |
| 1 | Entrada | 0–220 |
| 2 | Elias | 200–420 |
| 3 | Saloon | 240–520 |
| 4 | Estátua e pista | 460–620 |
| 5 | Segredo elevado | 520–760 |
| 6 | Rota opcional | 760–1180 |
| 7 | Arena | 1180–1520 |
| 8 | Beco do duo | 1500–2080 |
| 9 | Saída para igreja | 2040–2400 |

## Código

| Peça | Path |
| --- | --- |
| Layout + mold facades/props | `street_north_star_layout.gd` |
| Composer full street | `street_final_mold_composer.gd` |
| Toggle | `street_art_area.gd` modo `final_candidate` |
| Variantes kit | `street_north_star_variants.gd` |

## Narrativa ambiental

Desaparecimentos (posters) · Ordem (corações/sinais) · mineração · pobreza · medo · resistência · parceiro · Vermilite · seta igreja.

## Como ver

`street_art_test.tscn` ou demo → **F** até `FINAL MOLD (full street 0–2400)` · **P** perf.

## QA checklist

- [ ] Rota principal spawn→igreja  
- [ ] Rota opcional / plataformas  
- [ ] Segredo / PlatformA  
- [ ] Arena Brawler  
- [ ] Gunslinger opcional  
- [ ] Prompts Elias/saloon/statue  
- [ ] Mapa  
- [ ] Save / respawn  
- [ ] Controle  
- [ ] Performance ≥55 FPS (**P**)

## Manifesto

Lotes `draft` por distrito — ver `data/art/beta_asset_manifest.json` (`env_street_mold_district_*`).  
Existência de geometria ≠ `approved`/`integrated`.
