# Red Hollow — Art workspace

Estrutura para arte 2D definitiva. **Greybox permanece válido** até substituição por perfil `FINAL`.

```
art/
  characters/
    calder/           # spritesheets, atlas, export slices
    enemies/          # brawler, gunslinger, penitent, bosses
  environments/
    chapter_zero/     # rua, igreja, catacumbas
  props/
  vfx/
  ui/
  placeholders/       # gerados ou provisórios (piloto)
```

Não commitar PSDs gigantes sem LFS. Ver `docs/ASSET_IMPORT_RULES.md`.

## Calder — sheets piloto esperados

Colocar em `art/characters/calder/` (32×56 px por frame, horizontal):

- `calder_idle_sheet.png` (6 frames)
- `calder_run_sheet.png` (6 frames)
- `calder_jump_rise_sheet.png` (2 frames)
- `calder_fall_sheet.png` (2 frames)
- `calder_land_sheet.png` (3 frames)
- `calder_straight_sheet.png` (4 frames)
- `calder_body_hook_sheet.png` (4 frames)
- `calder_red_knuckle_sheet.png` (5 frames)
- `calder_dodge_sheet.png` (4 frames)
- `calder_hurt_sheet.png` (2 frames)

Contrato completo: `scripts/visual/calder_animation_contract.gd`

## Kit modular de cenário

Pasta de módulos: `art/environments/chapter_zero/modules/`  
Atlas: `art/environments/chapter_zero/street_tileset_atlas.png`  
Documentação: `docs/MODULAR_ENVIRONMENT_KIT.md`
