# Red Hollow — Paleta e iluminação regional

Documentação canônica dos grupos de cor e estados visuais por região. Implementação: `scripts/visual/lighting/`.

## Grupos de cor (`RedHollowPalette`)

### Base do faroeste

| Token | Uso |
| --- | --- |
| `WOOD_DARK` / `WOOD_MID` | Fachadas, saloon, vigas |
| `EARTH_DARK` / `EARTH_MID` | Chão, estrada, poeira compactada |
| `DUST_WARM` | Partículas, véu de entardecer |
| `LEATHER` | Couro, correias, coldre |
| `METAL_COOL` / `STONE_GREY` | Ferragens, calçamento |
| `FABRIC_TAN` | Lonas, toldos desbotados |
| `SUNSET_ORANGE` / `SUNSET_SKY_*` | Luz principal e céu |

### Ordem do Coração Rubro

| Token | Uso |
| --- | --- |
| `ORDER_BLACK` | Vestes, sombras rituais |
| `ORDER_BURNT_RED` / `ORDER_DEEP_RED` | Símbolos, tintas, banners |
| `ORDER_AGED_CREAM` | Pergaminos, cera |
| `ORDER_RITUAL_STONE` | Altares, degraus |

### Vermilite

| Token | Uso |
| --- | --- |
| `VERMILITE_SATURATED` | Cristais, barreiras, telegraphs |
| `VERMILITE_CORE` | Núcleo brilhante local |
| `VERMILITE_HALO` | Halo controlado (PointLight2D, motes) |
| `VERMILITE_SHADOW` | Sombra rubra sob fontes |

### Mol-Khar

| Token | Uso |
| --- | --- |
| `MOL_STONE_BLACK` | Pedra viva, silhueta |
| `MOL_INNER_RED` | Luz interna contida |
| `MOL_VOID` | Ausência de cor / fill escuro |
| `MOL_ABNORMAL_SHADOW` | Véu de silhueta narrativa |

## Recursos

| Classe | Arquivo | Função |
| --- | --- | --- |
| `RegionVisualTheme` | `scripts/visual/lighting/region_visual_theme.gd` | Tema por região + 4 estados de iluminação |
| `EnvironmentRegionTheme` | `scripts/environment/region_visual_theme.gd` | Herança de kit/distrito (stubs futuros) |
| `LightingProfile` | `lighting_profile.gd` | Modulate, luzes, partículas, vignette |
| `CorruptionVisualState` | `corruption_visual_state.gd` | Enum + perfil por estado |
| `RegionVisualController` | `region_visual_controller.gd` | Aplica perfis com tween |
| `ChapterZeroStreetThemeFactory` | `chapter_zero_street_theme_factory.gd` | Tema North Star |

## Estados visuais

| Estado | Leitura | Regras |
| --- | --- | --- |
| **Normal** | Cidade decadente ao pôr do sol | Sem domínio vermelho na tela |
| **Vermilite próxima** | Brilho local + motes | 1–2 fontes; sem bloom fullscreen |
| **Ressonância Rubra** | Ambiente dessaturado | Vermelho em elementos marcados |
| **Aparição Mol-Khar** | Escurecimento + silhueta | Luz vermelha contida; distorção leve |

## Integração atual

- **Somente** `vertical_slice_street_art.tscn` / `StreetArtPresentation`.
- Tecla **'** (apóstrofo) na rua art: cicla estados (debug playtest).
- Cena de comparação: `scenes/tests/region_visual_comparison_test.tscn`.

## Acessibilidade

Opções em **Configurações → Acessibilidade** (via `LightingProfile.apply_accessibility`):

- Flashes reduzidos → energia Vermilite e motes
- Partículas reduzidas → poeira e motes
- Distorção reduzida → véu e CA
- Contraste extremo reduzido → vignette
- Desativar aberração cromática

## Performance

- Sem blur obrigatório; overlays são `ColorRect` leves.
- Luzes 2D existentes; sem pós-process pesado.
- Headless: `build_lighting` / `build_atmosphere` permanecem vazios (inalterado).

## Testes

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

Suite: `region_visual_tests`.
