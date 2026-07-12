# Street Art — Assets faltantes

Lista de arquivos finais esperados para substituir placeholders da rua. **Não usar imagens externas.** Exportar em pixel art conforme `ASSET_IMPORT_RULES.md`.

## Tilesets e chão

| Arquivo esperado | Dimensão | Grid | Notas |
| --- | --- | --- | --- |
| `art/environments/chapter_zero/street_ground_tileset.png` | 256×48 mín. | 16×16 | Terra compactada + borda |
| `art/environments/chapter_zero/street_sidewalk_tileset.png` | 128×16 mín. | 16×16 | Madeira desgastada |

## Background (parallax sheets)

| Arquivo | Dimensão sugerida | Camada |
| --- | --- | --- |
| `street_bg_sky_sunset.png` | 480×120 | Céu |
| `street_bg_mountains.png` | 640×180 | Montanhas |
| `street_bg_city_silhouette.png` | 800×200 | Silhueta |
| `street_bg_mid_buildings.png` | 960×220 | Prédios médios |

## Props (slots na cena)

| slot_id | Arquivo | Footprint (px) | Posição aprox. |
| --- | --- | ---: | --- |
| `saloon` | `street_saloon.png` | 192×128 | (320, 848) |
| `closed_building` | `street_closed_building.png` | 160×112 | (720, 848) |
| `wagon` | `street_wagon.png` | 96×64 | (1080, 860) |
| `barrels` | `street_barrels.png` | 48×40 | (1240, 868) |
| `fence` | `street_fence.png` | 128×48 | (1480, 864) |
| `statue` | `street_statue_small.png` | 32×56 | (520, 848) |
| `sign_saloon` | `street_sign_saloon.png` | 64×32 | (280, 780) |
| `sign_order` | `street_sign_order.png` | 56×28 | (1680, 790) |
| `lamp_post` | `street_lamp_post.png` | 24×96 | ×3 postes |

## VFX / atmosfera

| Arquivo | Uso |
| --- | --- |
| `art/vfx/dust_mote.png` | 8×8 — partícula GPUParticles2D |
| `art/vfx/lantern_glow.png` | 32×32 — textura PointLight2D |

## Import

- Filtro: **Nearest**
- Compress: Lossless ou VRAM compact (sem blur)
- Mipmaps: **off** para pixel art

## Ordem de produção sugerida

1. Chão + calçada (tileset)
2. Saloon + prédio fechado (silhueta forte)
3. Background parallax (céu → montanhas → cidade)
4. Props médios (carroça, cercas, barris)
5. Postes + placas + lampiões
6. Estátua pequena
7. VFX poeira e glow
