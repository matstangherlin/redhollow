# Red Hollow — Accessibility

Opções de acessibilidade persistidas em `user://settings.json` (seção `accessibility`).

## Opções disponíveis

| Campo | Tipo | Default | Efeito atual |
| --- | --- | --- | --- |
| `screen_shake_intensity` | float 0–1 | 1.0 | Multiplica intensidade em `CameraController.request_shake()` |
| `reduced_flashes` | bool | false | Reservado — reduz flashes futuros (combate/VFX) |
| `telegraph_contrast` | float 0.5–2 | 1.0 | Reservado — telegraphs de inimigos |
| `text_speed` | float 0.25–3 | 1.0 | Reservado — velocidade de typewriter |
| `instant_text` | bool | false | Reservado — diálogo instantâneo |
| `subtitle_size` | float 0.75–2 | 1.0 | Reservado — escala de legendas |
| `vibration_enabled` | bool | true | Reservado — háptico gamepad |
| `red_brand_hold_mode` | bool | true | **Ativo** — `true` = segurar U/RT; `false` = alternar |
| `simplified_commands` | bool | false | **Preparação futura** — UI desabilitada |

## Red Brand — hold vs toggle

Implementado em `PlayerRedBrandController`:

- **Segurar (default):** soltar U/RT libera o breaker.
- **Alternar:** segundo pressionamento libera a carga.

Alterável em Opções → Acessibilidade.

## Screen shake

`SettingsManager.get_screen_shake_multiplier()` aplicado na câmera. Valor `0` elimina shake.

## UI

Menu Opções → seção **Acessibilidade** (scroll junto com vídeo/áudio).

## Roadmap beta

- Wire `reduced_flashes` a VFX Vermilite
- Wire `telegraph_contrast` a telegraphs de Deacon/Cult Brawler
- Wire `text_speed` / `instant_text` a `DialogueBox`
- Wire `subtitle_size` a HUD de diálogo
- Wire `vibration_enabled` a `Input.start_joy_vibration`

## Teste manual

1. Opções → Screen shake 0% — combate não deve tremer câmera.
2. Red Brand toggle — desmarcar “Segurar”; pressionar U duas vezes para carregar/liberar.
3. Reiniciar jogo — settings persistem.

Ver `SETTINGS_FORMAT.md` para schema JSON.
