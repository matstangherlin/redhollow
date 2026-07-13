# Red Hollow — Visual Foundation Baseline

**Data da auditoria:** 2026-07-13  
**Commit auditado:** `4babadc9a1c16b838aba541f89c17d5c9174f21a` (`4babadc`) — *Add world map graph, street art slice, and visual pilot pipeline.*  
**Versão alvo:** `0.2.0-beta.1`  
**Engine:** Godot **4.7**

Este documento consolida o **baseline técnico visual** após o commit `4babadc`. Não substitui `ART_BIBLE.md` nem `ART_VERTICAL_SLICE_GATE.md`; registra contratos implementados, evidências de teste e critérios para iniciar produção artística.

---

## Veredito da auditoria visual

| Critério | Resultado |
| --- | --- |
| Pipeline PILOT Calder (10 animações + fallback) | **PASS** — `player_visual_pipeline_tests` 8/8 |
| Primeira rua artística (molde técnico) | **PASS** — `street_art_toggle_tests` 4/4 |
| Kit modular de cenário | **PASS** — `modular_kit_tests` 7/7 |
| Gameplay/colisão separados da apresentação | **PASS** (headless + contrato de cena) |
| Arte pixel final Capítulo Zero | **NÃO EXISTE** |
| Playtest manual assinado | **PENDENTE** (KI-004) |
| Performance medida (FPS / draw calls) | **PENDENTE** |

### Decisão

**Não declarar pronto para produção artística final** enquanto existirem P0 do gate visual (plataformas invisíveis em modo art, labels debug) e playtest manual pendente.

**Aprovado para molde técnico replicável** — igreja e catacumbas podem seguir o mesmo padrão (`EnvironmentVisualProfile` + `*_art_presentation` + área art), conforme `ART_VERTICAL_SLICE_GATE.md`.

---

## Contratos de escala

| Parâmetro | Valor canônico | Fonte |
| --- | ---: | --- |
| Resolução lógica | 480×270 | `chapter_zero_street_profile.tres` |
| Pixels por unidade | 1 | `EnvironmentVisualProfile` |
| Tile base | 16×16 | perfil + kit modular |
| Sprite Calder | 32×56 | `CalderAnimationContract` |
| Referência janela | 1920×1080 | perfil |
| Filtro textura | Nearest | perfil |

---

## Camadas — rua artística (`StreetArtPresentation`)

Ordem e nomes de nó (9 camadas + modulate):

| # | Constante | Nó | Parallax |
| --- | --- | --- | --- |
| 1 | `LAYER_SKY` | `Layer01_Sky` | sim |
| 2 | `LAYER_MOUNTAINS` | `Layer02_Mountains` | sim |
| 3 | `LAYER_CITY` | `Layer03_CitySilhouette` | sim |
| 4 | `LAYER_MID_BUILDINGS` | `Layer04_MidBuildings` | sim |
| 5 | `LAYER_PLAYFIELD` | `Layer05_Playfield` | não |
| 6 | `LAYER_PROPS` | `Layer06_Props` | não |
| 7 | `LAYER_LIGHTING` | `Layer07_Lighting` | não (omitido em headless) |
| 8 | `LAYER_FOREGROUND` | `Layer08_Foreground` | sim |
| 9 | `LAYER_ATMOSPHERE` | `Layer09_Atmosphere` | não (partículas omitidas em headless) |
| — | — | `SunsetModulate` | `CanvasModulate` |

**Toggle greybox ↔ art:** `vertical_slice_street.tscn` (greybox, demo principal) vs `vertical_slice_street_art.tscn` (`StreetArtArea`). Mesmo `area_id` (`vs_greybox_street`).

---

## Pipeline PILOT — Calder Knox

| Componente | Caminho |
| --- | --- |
| Contrato de animação | `scripts/visual/calder_animation_contract.gd` |
| Builder SpriteFrames | `scripts/visual/calder_sprite_frames_builder.gd` |
| Controller | `scripts/visual/player_visual_controller.gd` |
| Perfil piloto | `resources/visual/calder_pilot_profile.tres` |
| Factory procedural | `scripts/visual/placeholder_sprite_factory.gd` |
| Debug overlay | `scripts/visual/player_visual_debug_overlay.gd` (F) |

**Animações PILOT (10):** idle, run, jump, fall, attack_1, attack_2, dodge, hurt, death, taunt.

**Fallback:** clip ausente → idle + warning único (`missing animation clip`) — allowlist em `player_visual_pipeline_tests`.

**Hitboxes:** inalteradas — orientadas por `AttackData` Resources, não pelo visual.

---

## Kit modular de cenário

| Componente | Caminho |
| --- | --- |
| Catálogo | `scripts/environment/environment_kit.gd` + `environment_kit_factory.gd` |
| Resource | `resources/environment/kits/chapter_zero_street_kit.tres` |
| Assembler | `scripts/environment/environment_kit_assembler.gd` |
| Salas exemplo | `scenes/environment/modular/kit_room_saloon_front.tscn`, `kit_room_alley_corner.tscn` |
| Validador | `scripts/environment/environment_kit_validator.gd` |

**20 módulos** no kit da rua (tiles, props, gameplay prefabs). Tile 16 px.

---

## Mapa do mundo (overlay provisório)

| Componente | Caminho |
| --- | --- |
| Grafo beta | `resources/world/beta_world_graph.tres` |
| Serviço | `scripts/world/world_map_service.gd` |
| Estado descoberta | `scripts/world/world_map_state.gd` (persistido no save) |
| UI | `scripts/ui/world_map_view.gd` + `scenes/ui/world_map_overlay.tscn` |
| Tecla | **M** (overlay) |

---

## Issues visuais conhecidos (P0 art — não bloqueiam molde)

| ID | Descrição | Gate |
| --- | --- | --- |
| G1 | Plataformas elevadas invisíveis com arte ativa (`PlatformVisual` oculto) | `ART_VERTICAL_SLICE_GATE.md` |
| G2 | Labels debug visíveis (`AreaLabel`, `TileHint`, etc.) | idem |
| G3 | Performance não medida (draw calls, FPS) | medição local pendente |
| G4 | Playtest manual da sala art não assinado | KI-004 |

---

## Evidência automatizada (commit `4babadc` + correções de auditoria)

| Suíte | Resultado | Data |
| --- | --- | --- |
| `street_art_toggle_tests` | **4/4 PASS** | 2026-07-13 |
| `player_visual_pipeline_tests` | **8/8 PASS** | 2026-07-13 |
| `modular_kit_tests` | **7/7 PASS** | 2026-07-13 |
| Runner completo | **23/23 PASS**, exit 0, ~51 s | 2026-07-13 |

Comando:

```powershell
.\tools\test_all.ps1
```

---

## Critérios para iniciar produção artística (arte final)

Todos obrigatórios:

1. Runner headless **23/23 PASS** estável (meta atingida na auditoria).
2. Playthrough manual menu → fim **assinado** (KI-004).
3. Correções **G1** e **G2** aplicadas na rua art.
4. Medição performance na build Windows (G3).
5. Sem crash, softlock, save corrompendo, respawn quebrado ou arena presa em playtest manual.

---

## Documentos relacionados

`ART_BIBLE.md`, `ART_VERTICAL_SLICE_GATE.md`, `STREET_ART_VERTICAL_SLICE.md`, `ENVIRONMENT_ART_GUIDE.md`, `STABILIZATION_REPORT.md`, `KNOWN_ISSUES.md`
