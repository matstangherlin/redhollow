# Calder Knox — Asset Checklist

Checklist de importação e validação de spritesheets reais. **Não substitui** `ANIMATION_PIPELINE.md` nem `ASSET_IMPORT_RULES.md`.

## Escala oficial aprovada

| Parâmetro | Valor | Fonte |
| --- | --- | --- |
| Frame produção | **40 × 72 px** | `docs/VISUAL_SCALE_STUDY.md` |
| Colisão gameplay | **32 × 56 px** (inalterada) | `player.tscn` |
| Pivot produção | centro inferior `(20, 72)` | contrato visual |
| Offset sprite produção | `(0, -36)` | alinha pés ao origin |
| Placeholder procedural | **32 × 56 px** | até sheets reais existirem |
| Facing padrão | direita | frame 0 |

**Não usar outra escala** sem nova aprovação documentada.

## Estrutura de pastas

```
art/characters/calder/
├── source/      ← PSD/KRA (gitignored)
├── exported/    ← exports intermediários
├── sheets/      ← PNG finais do jogo
└── previews/    ← revisão visual
```

### Nomenclatura

```
art/characters/calder/sheets/calder_{animation}_sheet.png
```

Exemplo: `calder_idle_sheet.png`

Frames dispostos **horizontalmente** (frame 0 à esquerda).

Largura PNG = `frames × 40`. Altura = `72`.

## Animações piloto obrigatórias

| Animação | Arquivo | Frames | FPS | Loop |
| --- | --- | ---: | ---: | --- |
| idle | `calder_idle_sheet.png` | 6 | 8 | sim |
| run | `calder_run_sheet.png` | 6 | 12 | sim |
| jump_start | `calder_jump_start_sheet.png` | 2 | 12 | não |
| jump_rise | `calder_jump_rise_sheet.png` | 2 | 10 | não |
| fall | `calder_fall_sheet.png` | 2 | 8 | sim |
| land | `calder_land_sheet.png` | 3 | 10 | não |
| straight | `calder_straight_sheet.png` | 4 | 14 | não |
| body_hook | `calder_body_hook_sheet.png` | 4 | 12 | não |
| red_knuckle | `calder_red_knuckle_sheet.png` | 5 | 10 | não |
| dodge | `calder_dodge_sheet.png` | 4 | 14 | não |
| hurt | `calder_hurt_sheet.png` | 2 | 10 | não |

## Animações opcionais (produção futura)

`turn`, `counter_window`, `counter_attack`, `taunt_01`, `taunt_02`, `knockdown`, `death`, `respawn`, `interact`, `red_brand_charge`, `red_brand_breaker`

Contrato em `CalderAnimationContract.OPTIONAL_ANIMATION_IDS`.

## Import Godot (pixel art)

| Parâmetro | Valor |
| --- | --- |
| Filter | **Nearest** |
| Mipmaps | **Off** |
| Compress | **Lossless** (ou VRAM Uncompressed) |
| Alpha | RGBA, borda alpha fix |

Helper: `CalderSpriteImporter.get_recommended_import_params()`

## Validação automática

### Headless

```powershell
godot --headless --path . --main-scene res://scenes/tests/test_bootstrap.tscn -- res://scripts/visual/calder_asset_validation_tests.gd
```

### Cena isolada

F6 → `scenes/tests/calder_asset_validation_test.tscn`  
Tecla **R** revalida.

### Script

```gdscript
var report := CalderAssetValidator.validate_pilot_set()
print(CalderAssetValidator.format_report(report))
```

## Checks executados

| Check | Descrição |
| --- | --- |
| `width_divisible` | largura ÷ 40 = inteiro |
| `height_exact` | altura = 72 |
| `frame_count` | frames = tabela do contrato |
| `has_transparency` | pixels alpha < 1 existem |
| `facing_default_right` | massa opaca do frame 0 não inclina à esquerda |
| `feet_on_bottom` | bounds opacos encostam no rodapé do frame |
| `no_accidental_side_margin` | sem margem lateral excessiva |
| `import_settings` | Nearest, sem mipmaps, compressão adequada |

## Fallback (arquivo ausente)

1. `CalderSpriteFramesBuilder` usa placeholder procedural (32×56).
2. `CalderAnimationContract.warn_missing_once()` emite **um** warning por contexto.
3. Build e testes headless **não falham** por sheet ausente.
4. Gameplay (`AttackData`, hitbox, hurtbox, colisão) **inalterado**.

## Gameplay preservado

- `AttackData` controla startup / active / recovery — animação **não** é fonte de dano.
- `CollisionShape2D` 32×56 permanece.
- Hitbox / hurtbox inalteradas.
- Facing via `presentation_controller`, não via flip automático do sheet.
- Velocidade, cancelamento, hitstop — sem mudanças nesta tarefa.

## Debug visual

Com debug do jogador ativo (modo dev):

- frame atual, animação, facing, offset, pivot
- bounds do sprite, collision, hurtbox, hitbox
- linha de pés e seta de facing

Componente: `PlayerVisualDebugOverlay`

## Checklist manual de playtest

Após colocar sheets em `sheets/`:

- [ ] idle
- [ ] correr e parar
- [ ] virar (facing)
- [ ] pular (jump_start → jump_rise → fall → land)
- [ ] combo (straight / hook / knuckle)
- [ ] esquiva
- [ ] dano / hurt
- [ ] interrupção de animação
- [ ] câmera (sem jitter de bounds)
- [ ] plataformas (pés alinhados)
- [ ] transição de área
- [ ] respawn

Cena sugerida: `scenes/tests/calder_visual_pilot_test.tscn` (F alterna PILOT).

## Arquivos do pipeline

| Arquivo | Função |
| --- | --- |
| `scripts/visual/calder_animation_contract.gd` | Contrato, paths, specs |
| `scripts/visual/calder_asset_validator.gd` | Validação dimensional |
| `scripts/visual/calder_sprite_importer.gd` | Parâmetros de import |
| `scripts/visual/calder_sprite_frames_builder.gd` | Monta SpriteFrames + fallback |
| `scripts/visual/player_visual_controller.gd` | Estado → animação (visual only) |
| `scripts/visual/player_visual_debug_overlay.gd` | Overlay debug |
| `scenes/tests/calder_asset_validation_test.tscn` | UI de relatório |

## Fluxo recomendado para artista

1. Desenhar em **40×72** por frame, facing direita.
2. Exportar PNG RGBA para `sheets/`.
3. Abrir projeto Godot → Import dock → Nearest / Lossless.
4. Rodar validação (F6 test scene ou headless).
5. Em `calder_pilot_profile.tres`: `use_procedural_pilot_frames = false` quando **todos** os piloto obrigatórios passarem.
6. Playtest em `calder_visual_pilot_test.tscn` e vertical slice.

## Documentos relacionados

`VISUAL_SCALE_STUDY.md`, `ASSET_IMPORT_RULES.md`, `ANIMATION_PIPELINE.md`, `VISUAL_PRESENTATION_CONTRACT.md`, `CHARACTER_SCALE_GUIDE.md`
