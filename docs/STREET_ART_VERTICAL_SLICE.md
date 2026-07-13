# Street Art Vertical Slice — Capítulo Zero

Documentação da **rua north-star** de Red Hollow. Esta sala é o padrão visual, técnico e produtivo para áreas futuras — **sem** substituir o greybox global da demo principal nem expandir igreja/catacumbas.

Ver visão completa: `docs/STREET_NORTH_STAR_DEFINITION.md`.

## Cenas e recursos

| Artefato | Caminho | Função |
| --- | --- | --- |
| Apresentação visual | `scenes/environment/chapter_zero/street_art_presentation.tscn` | 12 camadas de arte (sem colisão) |
| Factory north-star | `scripts/visual/street_north_star_factory.gd` | Silhuetas procedurais originais |
| Área art | `scenes/areas/vertical_slice_street_art.tscn` | Gameplay idêntico + arte |
| Greybox original | `scenes/areas/vertical_slice_street.tscn` | **Inalterado** na demo principal |
| Perfil visual | `resources/visual/chapter_zero_street_profile.tres` | `EnvironmentVisualProfile` |
| Performance | `scripts/visual/street_performance_monitor.gd` | Overlay debug (tecla P) |
| Teste manual | `scenes/tests/street_art_test.tscn` | Player + câmera + toggle F/P |
| Teste headless | `scripts/visual/street_art_toggle_tests.gd` | Contrato de camadas |

## Contrato de resolução

| Parâmetro | Valor | Fonte |
| --- | --- | --- |
| Resolução lógica | **480 × 270** | `ART_BIBLE.md` |
| Janela referência | **1920 × 1080** | `SettingsData` |
| Pixels / unidade | **1** | Gameplay |
| Tile base | **16 × 16 px** | `ENVIRONMENT_ART_GUIDE.md` |
| Calder (produção) | **40 × 72 px** | `VISUAL_SCALE_STUDY.md` |
| Colisão Calder | **32 × 56 px** | inalterada |
| Filtro | **Nearest** | import rules |
| Largura da rua | **2400 px** | `camera_limits` |
| Superfície chão arte | **Y = 876** | alinhada ao greybox |
| Parallax máx. | **≤ 0.45** | profile |

## Camadas (12 — back → front)

| # | Nó | z | Parallax |
| ---: | --- | ---: | ---: |
| 1 | `Layer01_Sky` | -120 | 0.05 |
| 2 | `Layer02_FarMountains` | -100 | 0.12 |
| 3 | `Layer03_DistantTown` | -80 | 0.22 |
| 4 | `Layer04_MidgroundBuildings` | -40 | 0.38 |
| — | `SunsetModulate` | — | — |
| 5 | `Layer05_GameplayGround` | 0 | 1.0 |
| 6 | `Layer06_GameplayStructures` | 5 | 1.0 |
| 7 | `Layer07_Props` | 7 | 1.0 |
| 8 | `Layer08_Interactables` | 12 | 1.0 |
| 9 | `Layer09_Lighting` | 20 | — |
| 10 | `Layer10_Atmosphere` | 50 | 1.0 |
| 11 | `Layer11_Foreground` | 40 | 1.05 |
| 12 | `Layer12_Debug` | 90 | — |

**Colisão** em `Solids/` — separada da arte.

## Gameplay preservado

- Diálogo Elias, pistas, combate, duo, segredo, saída igreja
- Plataformas elevadas (arte desenhada em `Layer05_GameplayGround`)
- `area_id = vs_greybox_street`, spawns, save, mapa, objetivo

## Alternância visual

| Tecla | Ação |
| --- | --- |
| **F** | GREYBOX ↔ ART PILOT |
| **P** | overlay performance (modo art) |

Labels de debug greybox (`AreaLabel`, `GuideLabel`, prompts) **ocultos** em art pilot.

## Orçamento de performance (street art pilot)

| Métrica | Orçamento | Estimativa north-star procedural |
| --- | ---: | ---: |
| FPS | 60 | 58–60 (GPU integrada média) |
| Frame time | ≤ 16.7 ms | ~12–15 ms |
| Draw calls | ≤ 80 | ~55–72 |
| PointLight2D | ≤ 6 | 5 |
| Partículas GPU | ≤ 180 | 174 (5 emissores) |
| Art layers | 12 | 12 |

Medir em **release** com `StreetPerformanceMonitor` (P) e Godot Debugger.

## Como esta sala vira molde

1. `EnvironmentVisualProfile` por área futura.
2. `*_art_presentation.tscn` + factory ou PNG slots.
3. `StreetArtArea` (ou equivalente) — toggle sem tocar colisão.
4. `ArtPlaceholderSlot` invisível para drop-in de PNG.
5. Migração: trocar cena no manifesto quando arte final passar gate.

## Testes

```powershell
# Headless
$env:RH_TEST_SUITE="res://scripts/visual/street_art_toggle_tests.gd"
godot --headless --path . --main-scene res://scenes/tests/test_bootstrap.tscn

# Manual
# F6 → scenes/tests/street_art_test.tscn
```

## Documentos relacionados

`STREET_NORTH_STAR_DEFINITION.md`, `STREET_ART_MISSING_ASSETS.md`, `STREET_ART_SCREENSHOT_CHECKLIST.md`, `PERFORMANCE_BUDGET.md`, `ART_VERTICAL_SLICE_GATE.md`
