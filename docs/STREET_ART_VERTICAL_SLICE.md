# Street Art Vertical Slice — Capítulo Zero

Documentação da **primeira sala de arte** de Red Hollow: a rua inicial. Esta sala estabelece o padrão técnico e visual para igreja, catacumbas e demais áreas — **sem substituir** o greybox global nem o mapa completo.

## Cenas e recursos

| Artefato | Caminho | Função |
| --- | --- | --- |
| Apresentação visual | `scenes/environment/chapter_zero/street_art_presentation.tscn` | 9 camadas de arte (sem colisão) |
| Área art | `scenes/areas/vertical_slice_street_art.tscn` | Gameplay idêntico ao greybox + arte |
| Greybox original | `scenes/areas/vertical_slice_street.tscn` | **Inalterado** na demo principal |
| Perfil visual | `resources/visual/chapter_zero_street_profile.tres` | `EnvironmentVisualProfile` |
| Teste manual | `scenes/tests/street_art_test.tscn` | Player + câmera + toggle F |
| Teste headless | `scripts/visual/street_art_toggle_tests.gd` | Contrato de camadas e toggle |

## Contrato de resolução (confirmado — não alterado silenciosamente)

| Parâmetro | Valor | Fonte |
| --- | --- | --- |
| Resolução lógica | **480 × 270** | `ART_BIBLE.md`, `CHARACTER_SCALE_GUIDE.md` |
| Janela referência | **1920 × 1080** | `SettingsData` default |
| Pixels / unidade | **1 px = 1 unidade** | Gameplay |
| Tile base | **16 × 16 px** | `ENVIRONMENT_ART_GUIDE.md` |
| Calder (sprite) | **32 × 56 px** | Colisão protegida |
| Inimigos (altura sprite) | Brawler 56, Gunslinger 54, Penitent 58 | `CHARACTER_SCALE_GUIDE.md` |
| Filtro textura | **Nearest** | `project.godot` + import rules |
| Stretch | **canvas_items + expand** | `project.godot` |
| Largura da rua | **2400 px** | `camera_limits` da área |
| Superfície do chão (arte) | **Y = 876** | Alinhada ao greybox (`Ground` y=900, half-height 24) |
| Parallax máx. horizontal | **≤ 0.45** | `ENVIRONMENT_ART_GUIDE.md` |

## Camadas (ordem back → front)

| # | Nome | Nó | Tecnologia | z_index | Parallax |
| ---: | --- | --- | --- | ---: | ---: |
| 1 | Céu | `Layer01_Sky` | Parallax2D + Polygon2D | -120 | 0.05 |
| 2 | Montanhas distantes | `Layer02_Mountains` | Parallax2D + Polygon2D | -100 | 0.12 |
| 3 | Silhueta da cidade | `Layer03_CitySilhouette` | Parallax2D + Polygon2D | -80 | 0.22 |
| 4 | Prédios intermediários | `Layer04_MidBuildings` | Parallax2D + Polygon2D | -40 | 0.38 |
| — | Modulação pôr do sol | `SunsetModulate` | CanvasModulate | — | — |
| 5 | Plano jogável (visual) | `Layer05_Playfield` | Node2D + Polygon2D | 0 | 1.0 |
| 6 | Props | `Layer06_Props` | Node2D + `ArtPlaceholderSlot` | 10 | 1.0 |
| 7 | Iluminação | `Layer07_Lighting` | DirectionalLight2D + PointLight2D | 20 | — |
| 8 | Foreground | `Layer08_Foreground` | Parallax2D | 40 | 1.05 |
| 9 | Partículas atmosféricas | `Layer09_Atmosphere` | GPUParticles2D (poeira) | 50 | 1.0 |

**Colisão** permanece em `Solids/` (StaticBody2D) — **separada** da arte.

## Gameplay preservado

A variante art mantém:

- `Solids` (chão, plataformas)
- `Spawns`, `Exits`, `WorldObjects` (Elias, inimigos, props narrativos)
- `area_id = vs_greybox_street`
- `camera_limits`, `fall_recovery_y`

## Orçamento de performance (inicial)

| Métrica | Orçamento | Estimativa atual (placeholder) |
| --- | ---: | ---: |
| Draw calls | ≤ 80 | ~45–55 |
| PointLight2D | ≤ 6 | 3 lanternas |
| Partículas (GPU) | ≤ 180 | 120 |
| Atlas / textura máx. | 2048 px | 0 (placeholders vetoriais) |
| Camadas art | 9 | 9 |
| Parallax2D | ≤ 5 | 5 |

Medir em build Windows com **Debugger → Monitores** antes de arte final.

## Como esta sala vira molde

1. **Perfil** — cada área futura recebe um `EnvironmentVisualProfile` (igreja, catacumbas).
2. **Apresentação** — cena `*_art_presentation.tscn` só com camadas visuais.
3. **Área art** — script `StreetArtArea` (ou equivalente) troca greybox ↔ arte sem tocar colisão.
4. **Slots** — `ArtPlaceholderSlot` documenta path e footprint de cada asset final.
5. **Migração** — quando arte estiver pronta, trocar `vertical_slice_street.tscn` por `vertical_slice_street_art.tscn` no manifesto **ou** ativar `show_art_presentation` na área principal.

## Testes

### Headless

```powershell
$env:RH_TEST_SUITE="res://scripts/visual/street_art_toggle_tests.gd"
godot --headless --main-scene res://scenes/tests/test_bootstrap.tscn
```

### Manual

1. Abrir `scenes/tests/street_art_test.tscn`
2. F6 — mover com A/D, pular, atacar
3. **F** alterna greybox ↔ arte
4. Verificar colisão, Elias, inimigos, saída para igreja

## Documentos relacionados

- `STREET_ART_MISSING_ASSETS.md` — lista de PNGs finais
- `STREET_ART_SCREENSHOT_CHECKLIST.md` — capturas para QA arte
- `ENVIRONMENT_ART_GUIDE.md` — regras gerais de cenário
