# Modular Kit — Assets necessários

Assets finais para substituir placeholders do kit da rua. Exportar em pixel art 16px grid.

## Atlas principal

| Arquivo | Tamanho sugerido | Conteúdo |
| --- | --- | --- |
| `art/environments/chapter_zero/street_tileset_atlas.png` | 128×64 mín. | terra, madeira, pedra, transições, autotile |

## Módulos (PNG individuais)

Pasta: `art/environments/chapter_zero/modules/`

| Arquivo | Footprint | Prioridade |
| --- | ---: | --- |
| `street_mod_dirt_ground.png` | 64×16 | P0 |
| `street_mod_wood_sidewalk.png` | 64×16 | P0 |
| `street_mod_platform.png` | 48×16 | P0 |
| `street_mod_roof.png` | 64×32 | P1 |
| `street_mod_wall_wood.png` | 16×48 | P0 |
| `street_mod_wall_stone.png` | 16×48 | P0 |
| `street_mod_door.png` | 32×64 | P0 |
| `street_mod_window.png` | 24×24 | P1 |
| `street_mod_balcony.png` | 64×32 | P1 |
| `street_mod_lamp_post.png` | 24×96 | P1 |
| `street_mod_fence.png` | 64×32 | P1 |
| `street_mod_barrel.png` | 24×24 | P2 |
| `street_mod_crate.png` | 24×24 | P2 |
| `street_mod_wagon.png` | 96×64 | P1 |
| `street_mod_sign.png` | 48×24 | P1 |
| `street_mod_lantern.png` | 24×48 | P1 |
| `street_mod_stairs.png` | 48×48 | P1 |
| `street_mod_blocked_entrance.png` | 32×64 | P2 |
| `street_mod_secret_passage.png` | 32×48 | P2 |
| `street_mod_vermilite_barrier.png` | 28×128 | P1 |

## Background (salas kit)

| Arquivo | Uso |
| --- | --- |
| `street_bg_kit_skyline.png` | Parallax LayerBackground |

## Cenas já criadas (placeholders)

Props em `scenes/environment/modules/kit_*.tscn` — substituir `ArtPlaceholderSlot` por sprites quando PNGs existirem.

## Ordem de produção

1. Atlas tileset (terra + madeira + pedra + autotile)
2. Paredes + chão + calçada
3. Porta, escada, plataforma
4. Props médios (carroça, poste, cerca)
5. Lampião + VFX luz
6. Módulos gameplay (barreira, passagem — arte sobre prefabs existentes)

## Import

- Filtro: **Nearest**
- Mipmaps: **off**
- Grid: **16 px**
