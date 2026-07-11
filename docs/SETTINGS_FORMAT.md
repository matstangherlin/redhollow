# Red Hollow — Settings Format

Arquivo: **`user://settings.json`**

Separado do save de campanha (`user://saves/slot_01.save.json`).

## Versão

```json
{
  "settings_version": 1
}
```

Versão atual: **`1`** (`SettingsData.CURRENT_SETTINGS_VERSION`).

Validação: `SettingsData.validate()`. Arquivo inválido → defaults + warning no log.

## Schema completo

```json
{
  "settings_version": 1,
  "video": {
    "display_mode": "windowed",
    "resolution": { "x": 1920, "y": 1000 },
    "vsync": true,
    "max_fps": 60,
    "ui_scale": 1.0
  },
  "audio": {
    "master": 1.0,
    "music": 1.0,
    "sfx": 1.0,
    "voice": 1.0,
    "ui": 1.0,
    "ambience": 1.0
  },
  "accessibility": {
    "screen_shake_intensity": 1.0,
    "reduced_flashes": false,
    "telegraph_contrast": 1.0,
    "text_speed": 1.0,
    "instant_text": false,
    "subtitle_size": 1.0,
    "vibration_enabled": true,
    "red_brand_hold_mode": true,
    "simplified_commands": false
  }
}
```

## Campos — vídeo

| Campo | Valores | Notas |
| --- | --- | --- |
| `display_mode` | `windowed`, `fullscreen`, `borderless` | `borderless` → `WINDOW_MODE_FULLSCREEN` |
| `resolution` | `{x, y}` int | Aplicado em modo janela |
| `vsync` | bool | |
| `max_fps` | int; `0` = sem limite | `Engine.max_fps` |
| `ui_scale` | float 0.75–2 | `Window.content_scale_factor` |

## Campos — áudio

Volumes lineares `0.0`–`1.0`. Buses: Master, Music, SFX, Voice, UI, Ambience.

Chaves JSON em minúsculas (`master`, `music`, …).

## Campos — acessibilidade

Ver `ACCESSIBILITY.md`.

## Escrita atômica

`SettingsManager.save_settings()`:

1. Escreve `user://settings.json.tmp`
2. Remove destino anterior
3. Renomeia temp → final

## Migração

Settings com `settings_version` menor que a atual: `merge_with_defaults()` preserva valores conhecidos.

Settings com versão **maior** que a engine: rejeitados → defaults.

## API

| Método | Uso |
| --- | --- |
| `SettingsManager.load_settings()` | Boot autoload |
| `SettingsManager.save_settings()` | Ao sair de Opções |
| `SettingsManager.apply_all()` | Reaplica vídeo/áudio |
| `SettingsManager.set_*_field()` | Mudança individual + apply |

## Relação com save de campanha

`SaveData.settings` no slot de campanha permanece no schema por compatibilidade, mas **preferências do jogador vivem somente em `user://settings.json`**.

Não copiar settings do slot para `SettingsManager` no load de campanha.
