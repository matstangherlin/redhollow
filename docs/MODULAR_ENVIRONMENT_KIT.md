# Modular Environment Kit — Red Hollow

Sistema de cenários modulares para produzir o mapa **aos poucos**, com peças reutilizáveis. **Não** é uma cidade inteira nem uma cena gigante.

## Princípios

| Regra | Detalhe |
| --- | --- |
| Colisão separada | Arte em `LayerVisual` / props — colisão em `LayerCollision` ou `Solids/` |
| Área incremental | Salas pequenas instanciadas; mesmo kit, layouts diferentes |
| Gameplay preservado | `AreaRoot` contract: `Solids`, `Spawns`, `WorldObjects`, `Exits` |
| Herança visual | `RegionVisualTheme` + `AreaVisualProfile` para distritos futuros |
| Sem duplicar kit | Variações por tema/paleta, não cópia de todos os módulos |

## Arquitetura

```
EnvironmentKit (Resource)
├── tile_specs[]          ← atlas 16px, autotile, transições
├── modules[]             ← 20 módulos do kit da rua
└── atlas_path

PropCatalog (Resource)    ← props que exigem cena (.tscn)

AreaVisualProfile         ← perfil por área + kit_id + tema

ModularArea / KitModularRoom
├── ModularLayers/
│   ├── LayerCollision
│   ├── LayerGameplay
│   ├── LayerVisual
│   ├── LayerDecoration
│   ├── LayerForeground
│   ├── LayerBackground
│   ├── LayerLighting
│   └── LayerInteraction
├── Solids/               ← gameplay ground (AreaRoot)
├── Spawns/
├── WorldObjects/
└── ModuleMarkers/        ← EnvironmentModuleInstance
```

## Categorias de layer

| Categoria | Pasta | Conteúdo |
| --- | --- | --- |
| collision | `LayerCollision` | StaticBody2D de módulos com `has_collision` |
| gameplay | `LayerGameplay` | arenas, gates (prefabs) |
| visual | `LayerVisual` | tile strips, chão, calçada |
| decoration | `LayerDecoration` | barris, carroça, placas |
| foreground | `LayerForeground` | vigas, véu |
| background | `LayerBackground` | Parallax2D, skyline |
| lighting | `LayerLighting` | lampiões, PointLight2D |
| interaction | `LayerInteraction` | portas, props narrativos |

## Kit da Rua — módulos (20)

| module_id | Tipo | Categoria | Colisão | Cena |
| --- | --- | --- | --- | --- |
| `dirt_ground` | tile | visual | — | placeholder |
| `wood_sidewalk` | tile | visual | — | placeholder |
| `platform` | hybrid | collision | sim | placeholder |
| `roof` | tile | decoration | — | placeholder |
| `wall_wood` | hybrid | collision | sim | placeholder |
| `wall_stone` | hybrid | collision | sim | placeholder |
| `door` | prop | interaction | — | `kit_door.tscn` |
| `window` | prop | decoration | — | `kit_window.tscn` |
| `balcony` | prop | decoration | — | `kit_balcony.tscn` |
| `lamp_post` | prop | decoration | — | `kit_lamp_post.tscn` |
| `fence` | hybrid | collision | sim | `kit_fence.tscn` |
| `barrel` | prop | decoration | — | `kit_barrel.tscn` |
| `crate` | prop | decoration | — | `kit_crate.tscn` |
| `wagon` | prop | decoration | — | `kit_wagon.tscn` |
| `sign` | prop | decoration | — | `kit_sign.tscn` |
| `lantern` | prop | lighting | — | `kit_lantern.tscn` + luz |
| `stairs` | hybrid | collision | sim | `kit_stairs.tscn` |
| `blocked_entrance` | prefab | gameplay | — | `narrative_gate.tscn` |
| `secret_passage` | prefab | gameplay | — | `kit_secret_passage.tscn` |
| `vermilite_barrier` | prefab | gameplay | — | `red_barrier.tscn` |

Definições: `EnvironmentKitFactory` · Recurso: `resources/environment/kits/chapter_zero_street_kit.tres`

## Tiles

| Parâmetro | Valor |
| --- | --- |
| Tamanho base | **16 × 16 px** |
| Estrutura grande | **32 × 32 px** (2×2 tiles) |
| Atlas | `art/environments/chapter_zero/street_tileset_atlas.png` |
| Autotile | `autotile_stone_wall` (terrain set 0) |
| Transições | `dirt_to_wood` |
| Bordas / cantos | `border_ground`, `corner_stone` |
| Variações | índice em `EnvironmentTileSpec.variation_index` |
| Nomenclatura | `street_tile_{terrain}_{role}.png` ou região no atlas |
| Import | Nearest, sem mipmaps — `ASSET_IMPORT_RULES.md` |

**TileMapLayer:** usar em `LayerVisual` para chão/calçada quando atlas existir. Colisão em layer separado ou `Solids/`.

## Props — quando usar cena

| Critério | Usar `.tscn` | Usar TileMap / placeholder |
| --- | --- | --- |
| Luz | sim (`kit_lantern`) | — |
| Animação | sim (futuro) | — |
| Interação | sim (`kit_door`, gates) | — |
| Destruição | sim (`barrel` futuro) | — |
| Som | sim (via evento futuro) | — |
| Colisão especial | sim (`fence`, `stairs`) | — |
| Puramente visual | — | TileMapLayer ou `ArtPlaceholderSlot` |

Catálogo: `resources/environment/prop_catalogs/chapter_zero_street_props.tres`

## Regiões futuras (somente herança — não implementadas)

| Região | parent_theme | Extensão |
| --- | --- | --- |
| Centro | `chapter_zero_street` | pedra, variações de fachada |
| Igreja | `chapter_zero_street` | paleta cinza, menos madeira |
| Estação | `centro` | ferro, trilhos |
| Prisão | `estacao` | grades, pedra úmida |
| Mina | `chapter_zero_street` | rocha, Vermilite |
| Cemitério | `igreja` | névoa, cruzes |
| Mansão | `centro` | madeira nobre |
| Palácio Rubro | `mansao` | modulate corrupção |

Código: `RegionVisualTheme.get_future_region_stubs()`

## Ferramentas

| Ferramenta | Caminho | Função |
| --- | --- | --- |
| `EnvironmentKit` | `scripts/environment/environment_kit.gd` | catálogo de módulos |
| `PropCatalog` | `scripts/environment/prop_catalog.gd` | props com cena |
| `AreaVisualProfile` | `scripts/environment/area_visual_profile.gd` | perfil por área |
| `EnvironmentKitValidator` | `scripts/environment/environment_kit_validator.gd` | layers + colisão |
| `EnvironmentEditorHelper` | `scripts/environment/environment_editor_helper.gd` | validação no editor |
| `EnvironmentKitAssembler` | `scripts/environment/environment_kit_assembler.gd` | monta layers |

### Relatório de assets ausentes

```gdscript
var kit := EnvironmentKitFactory.create_street_kit()
var missing := EnvironmentKitValidator.find_missing_assets(kit)
```

## Fluxo para criar uma área

1. **Duplicar template** — `KitModularRoom` ou cena base com `ModularArea`.
2. **Assign kit** — `chapter_zero_street_kit.tres` (ou kit derivado futuro).
3. **Assign perfil** — `AreaVisualProfile` com `kit_id` + `region_theme_id`.
4. **Posicionar módulos** — `EnvironmentModuleInstance` em `ModuleMarkers/` ou template em `kit_modular_room.gd`.
5. **Gameplay** — `Solids/`, `Spawns/`, `Exits/` com IDs estáveis.
6. **Validar** — `EnvironmentKitValidator.validate_area()` ou Editor Helper.
7. **Registrar** — adicionar `AreaData` no manifesto do capítulo (quando área for jogável).
8. **Testar** — transições, colisão, câmera, backtracking.

## Salas de teste (mesmo kit)

| Sala | Cena | Largura | Módulos destacados |
| --- | --- | ---: | --- |
| Frente do Saloon | `kit_room_saloon_front.tscn` | 640 | saloon, varanda, plataforma |
| Canto do Beco | `kit_room_alley_corner.tscn` | 560 | escada, passagem secreta, barreira |

Teste manual: `scenes/tests/modular_kit_test.tscn`  
Headless: `scripts/environment/modular_kit_tests.gd`

**Confirmado no design:**
- Reutilização — barril, crate, lantern, fence em ambas
- Colisão — `Solids/Ground` + `LayerCollision` separado da arte
- Parallax — `LayerBackground/SkylineParallax`
- Câmera — `camera_limits` por sala
- Transição — `AreaExit` entre salas (teste local)
- Backtracking — saloon ↔ beco

## Performance (orçamento inicial por sala kit)

| Métrica | Alvo |
| --- | ---: |
| Draw calls | ≤ 60 |
| PointLight2D | ≤ 4 |
| Parallax2D | ≤ 2 |
| Módulos placeholder | ≤ 25 |

## Documentos relacionados

- `MODULAR_KIT_MISSING_ASSETS.md` — PNGs e atlas pendentes
- `ENVIRONMENT_ART_GUIDE.md`, `STREET_ART_VERTICAL_SLICE.md`, `ASSET_IMPORT_RULES.md`
