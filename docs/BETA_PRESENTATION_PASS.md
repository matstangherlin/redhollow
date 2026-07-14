# Red Hollow — Passagem final de apresentação (beta)

Escopo: **polir o existente**, sem conteúdo de gameplay novo. Data: 2026-07-13. Versão áudio: `0.2.0-beta.1-presentation`.

## Áudio

- SFX prioritários re-sintetizados (passos, golpes, impactos, counter, Red Brand, tiro, corrente, portas, checkpoint, barreira, ambiences, boss, Mol-Khar, UI).
- Registro canônico: `AudioAssetRegistry` + `docs/AUDIO_ASSETS.md` (origem, licença, autor, arquivo, versão).
- `AudioEventId.DOOR`, `BOSS_HIT`, `BOSS_STINGER` adicionados.
- Pré-load em `AudioManager` / `MusicController` `_ready` — sem I/O de áudio no combate.

## Música

Slots no bus Music (beds originais procedurais — **sem** faixas sem licença):

menu · street · church · catacombs · Deacon Rusk · finale

Wiring: menu principal, troca de área, encounter Deacon, finale Cap. Zero.

## VFX

- Novos kinds: `gunshot`, `chain`, `vermilite`, `boss`, `mol_khar`.
- Telegraphs com contraste de acessibilidade; checkpoint/shockwave; trails de projétil; flashes respeitam `reduced_flashes`.

## UI

- Tema menu / pausa / diálogo / end card / boss HUD / mapa / bars HUD V2 alinhados à identidade madeira/ferro/Vermilite (`UiThemeHelper`, `HudThemeV2`).

## Acessibilidade

| Opção | Estado |
| --- | --- |
| Shake 0% | ativo (câmera) |
| Flashes / partículas reduzidos | ativo (VFX) |
| Volumes por bus | ativo |
| Legendas / subtítulo | `subtitle_size` no DialogueBox; voz Mol via cue |
| text_speed / instant_text | typewriter no DialogueBox |
| Escala UI | `ui_scale` |
| Gamepad prompts | InputDeviceManager |
| Vibração | `Input.start_joy_vibration` + handheld |

## Performance

- Pools de áudio/VFX reutilizados; streams gerados uma vez.
- Música crossfade sem reload.
- Monitor de área (P) permanece para QA de 60 FPS.

## Não feito (requer assets licenciados)

PNG/UI skin final, WAV/OGG de produção, trilha musical composta, captions dedicados separados do diálogo.
