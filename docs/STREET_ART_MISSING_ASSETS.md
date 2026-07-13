# Street Art — Assets faltantes

Inventário para substituir silhuetas **procedurais north-star** por PNG final. A cena já é jogável e legível sem estes arquivos.

**Status geral:** 0 PNG reais em `art/environments/chapter_zero/` — tudo é procedural + slots invisíveis.

## Implementado agora (procedural original)

| Elemento | Camada | Notas |
| --- | --- | --- |
| Céu pôr do sol + sol + glow Mol-Khar | Sky | substituível por `street_bg_sky_sunset.png` |
| Montanhas + cicatriz mina | FarMountains | `street_bg_mountains.png` |
| Cidade distante + torre + fumaça | DistantTown | `street_bg_city_silhouette.png` |
| Prédios médios parallax | MidgroundBuildings | `street_bg_mid_buildings.png` |
| Terra + calçada + plataformas | GameplayGround | tilesets abaixo |
| Saloon + abandonado + toldo | GameplayStructures | PNG props grandes |
| Postes, carroça, barris, cercas, estátua, coração, Vermilite | Props | ver tabela props |
| Marcadores interactáveis | Interactables | opcional — apenas debug visual |
| Luzes + partículas | Lighting/Atmosphere | `lantern_glow.png`, `dust_mote.png` |

## Tilesets e chão

| Arquivo | Dimensão | Grid | Status |
| --- | --- | --- | --- |
| `street_ground_tileset.png` | 256×48 mín. | 16×16 | **faltando** — terra procedural |
| `street_sidewalk_tileset.png` | 128×16 mín. | 16×16 | **faltando** — tábuas procedural |

## Background parallax (PNG final)

| Arquivo | Dimensão sugerida | Camada | Status |
| --- | --- | --- | --- |
| `street_bg_sky_sunset.png` | 480×120 | Sky | faltando |
| `street_bg_mountains.png` | 640×180 | FarMountains | faltando |
| `street_bg_city_silhouette.png` | 800×200 | DistantTown | faltando |
| `street_bg_mid_buildings.png` | 960×220 | MidgroundBuildings | faltando |

## Props (slots reservados — substituem procedural)

| slot_id | Arquivo | Footprint | Status |
| --- | --- | ---: | --- |
| `saloon` | `street_saloon.png` | 192×128 | procedural + slot |
| `closed_building` | `street_closed_building.png` | 160×112 | procedural + slot |
| `wagon` | `street_wagon.png` | 96×64 | procedural + slot |
| `barrels` | `street_barrels.png` | 48×40 | procedural + slot |
| `fence` | `street_fence.png` | 128×48 | procedural + slot |
| `statue` | `street_statue_small.png` | 32×56 | procedural + slot |
| `sign_saloon` | `street_sign_saloon.png` | 64×32 | procedural + slot |
| `sign_order` | `street_sign_order.png` | 56×28 | faltando PNG |
| `lamp_post` | `street_lamp_post.png` | 24×96 | procedural + slot |
| `crates` | `street_crates.png` | 48×36 | só procedural |
| `vermilite_ore` | `street_vermilite_cluster.png` | 24×32 | só procedural |
| `dry_bush` | `street_dry_bush.png` | 24×20 | só procedural |
| `heart_symbol` | `street_heart_symbol.png` | 20×16 | só procedural |
| `church_distant` | `street_church_spire_far.png` | 64×120 | só procedural |

## VFX / atmosfera

| Arquivo | Uso | Status |
| --- | --- | --- |
| `art/vfx/dust_mote.png` | partículas 8×8 | procedural color |
| `art/vfx/lantern_glow.png` | PointLight2D 32×32 | default Godot |
| `art/vfx/leaf_dry.png` | folhas secas | procedural color |
| `art/vfx/smoke_wisp.png` | fumaça distante | procedural color |

## Import

Nearest · mipmaps off · Lossless — ver `ASSET_IMPORT_RULES.md`.

## Ordem de produção

1. Chão + calçada (tileset)
2. Parallax (céu → montanhas → cidade → mid)
3. Saloon + prédio abandonado
4. Props médios + postes
5. VFX glow/dust
6. Polimento Vermilite + placas

## Assets reais encontrados

*Nenhum PNG de rua versionado em `art/environments/chapter_zero/`.*
