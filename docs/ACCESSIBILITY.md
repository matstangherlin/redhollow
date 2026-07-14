# Red Hollow — Accessibility

Opções de acessibilidade persistidas em `user://settings.json` (seção `accessibility`).

## Opções disponíveis

| Campo | Tipo | Default | Efeito atual |
| --- | --- | --- | --- |
| `screen_shake_intensity` | float 0–1 | 1.0 | Multiplica intensidade em `CameraController.request_shake()` — **0 elimina shake** |
| `reduced_flashes` | bool | false | Reduz flashes fullscreen e intensidade de VFX (`CombatVfxSpawner`) |
| `reduced_particles` | bool | false | Multiplicador ~0.4 no spawn de partículas |
| `telegraph_contrast` | float 0.5–2 | 1.0 | Escala amount/alpha de telegraphs |
| `text_speed` | float 0.25–3 | 1.0 | Velocidade do typewriter em `DialogueBox` |
| `instant_text` | bool | false | Mostra linha de diálogo completa imediatamente |
| `subtitle_size` | float 0.75–2 | 1.0 | Escala fonte do corpo/speaker do diálogo |
| `vibration_enabled` | bool | true | `Input.start_joy_vibration` + `vibrate_handheld` |
| `red_brand_hold_mode` | bool | true | **Ativo** — `true` = segurar U/RT; `false` = alternar |
| `simplified_commands` | bool | false | Preparação futura — UI desabilitada |
| `reduced_distortion` / `reduced_extreme_contrast` / `disable_chromatic_aberration` | bool | false | Aplicados em `RegionVisualController` |

## Diálogo / legendas

- Typewriter honra `text_speed` e `instant_text`.
- Primeiro [E] com typewriter em andamento → completa a linha; segundo avança.
- `subtitle_size` escala o texto do dialogue box (legenda de combate narrativo).
- Prompts de avanço seguem `InputDeviceManager` (teclado/gamepad).

## Red Brand — hold vs toggle

Implementado em `PlayerRedBrandController`.

## Volume

Sliders Master / Music / SFX / Voice / UI / Ambience em Opções → buses em `default_bus_layout.tres`.

## Escala UI

`video.ui_scale` → `Window.content_scale_factor` (0.75–2.0).

## Teste manual (apresentação)

1. Shake 0% — combate sem tremor.
2. Flashes/partículas reduzidos — VFX mais suaves.
3. Instant text + subtitle size — diálogo.
4. Vibração off — gamepad sem rumble.
5. Music slider — beds de menu/área audíveis.
6. Prompts — trocar teclado/gamepad no diálogo.

Ver `SETTINGS_FORMAT.md` e `docs/BETA_PRESENTATION_PASS.md`.
