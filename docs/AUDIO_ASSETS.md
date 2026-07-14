# Red Hollow — Audio Assets & Licenses

Inventário de áudio da passagem de apresentação da beta. **Nenhum asset externo baixado.**

Versão do registro: `0.2.0-beta.1-presentation` (`AudioAssetRegistry.VERSION`).

## Política

- Placeholders atuais = síntese procedural original (`PlaceholderAudioFactory`).
- **Não** usar músicas/SFX sem licença.
- Substituição por `.wav`/`.ogg`: `register_stream` + documentar nesta tabela **antes** de marcar como integrado.
- Biblioteca completa pré-carregada em `_ready` — **sem** load de áudio no primeiro golpe / durante combate.

## Registro (origem / licença / autor / arquivo / versão)

Gerado pelo código canônico em `scripts/audio/audio_asset_registry.gd`.

| ID | Origem | Licença | Autor | Arquivo | Versão | Notas |
| --- | --- | --- | --- | --- | --- | --- |
| `footstep` | PlaceholderAudioFactory | Original Red Hollow | Red Hollow / project code | `placeholder_audio_factory.gd` | 0.2.0-beta.1-presentation | passos |
| `punch` / `kick` | idem | Original Red Hollow | idem | idem | idem | golpes |
| `impact_flesh` / `impact_stone` / `impact_vermilite` | idem | Original Red Hollow | idem | idem | idem | impactos |
| `counter` | idem | Original Red Hollow | idem | idem | idem | counter |
| `red_brand_charge` / `red_brand_breaker` | idem | Original Red Hollow | idem | idem | idem | Red Brand |
| `gunshot` | idem | Original Red Hollow | idem | idem | idem | tiro |
| `chain` | idem | Original Red Hollow | idem | idem | idem | corrente |
| `door` | idem | Original Red Hollow | idem | idem | idem | portas |
| `checkpoint` | idem | Original Red Hollow | idem | idem | idem | checkpoint |
| `barrier_hit` / `barrier_break` | idem | Original Red Hollow | idem | idem | idem | barreira |
| `ambience_bell` | idem | Original Red Hollow | idem | idem | idem | sino |
| `ambience_wind` | idem | Original Red Hollow | idem | idem | idem | vento |
| `ambience_wood` | idem | Original Red Hollow | idem | idem | idem | madeira |
| `ambience_mines` | idem | Original Red Hollow | idem | idem | idem | catacumbas |
| `boss_hit` / `boss_stinger` | idem | Original Red Hollow | idem | idem | idem | boss |
| `ambience_mol_khar` | idem | Original Red Hollow | idem | idem | idem | Mol-Khar |
| `ui_*` / `dialogue_blip` | idem | Original Red Hollow | idem | idem | idem | UI |
| `music_menu` | music bed procedural | Original Red Hollow | idem | idem | idem | menu |
| `music_street` | idem | Original Red Hollow | idem | idem | idem | rua |
| `music_church` | idem | Original Red Hollow | idem | idem | idem | igreja |
| `music_catacombs` | idem | Original Red Hollow | idem | idem | idem | catacumbas |
| `music_deacon_rusk` | idem | Original Red Hollow | idem | idem | idem | Deacon Rusk |
| `music_finale` | idem | Original Red Hollow | idem | idem | idem | finale |

## Música — slots

`MusicController` (`scripts/audio/music_controller.gd`) no bus **Music**:

| Slot | Quando |
| --- | --- |
| menu | Main menu |
| street | Áreas de rua |
| church | Distito da igreja |
| catacombs | Subterrâneo |
| deacon_rusk | Encounter Deacon |
| finale | Capítulo Zero finale |

Beds são **drones originais** (não trilha licenciada de terceiros). Slider Music em Opções afeta o bus.

## Substituição por assets finais

```gdscript
AudioManager.register_stream(AudioEventId.PUNCH, preload("res://audio/sfx/punch_01.wav"))
MusicController.register_stream(MusicSlotId.MENU, preload("res://audio/music/menu_loop.ogg"))
```

Documentar licença nesta tabela antes do commit do arquivo.

## Atribuições externas

| Asset | Autor | Licença | URL |
| --- | --- | --- | --- |
| *(nenhum ainda)* | — | — | — |

## Docs relacionadas

- `docs/BETA_PRESENTATION_PASS.md`
- `docs/VFX_LANGUAGE.md`
- `docs/ACCESSIBILITY.md`
- `docs/PERFORMANCE_BUDGET.md`
