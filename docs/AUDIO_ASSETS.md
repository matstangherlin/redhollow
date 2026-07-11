# Red Hollow — Audio Assets & Licenses

Inventário de áudio usado na infraestrutura beta. **Nenhum asset externo baixado.**

## Placeholders procedurais (atual)

| Event ID | Origem | Licença |
| --- | --- | --- |
| Todos em `AudioEventId` | `PlaceholderAudioFactory` — síntese procedural em GDScript | **Original Red Hollow** (código do projeto) |
| `footstep` … `ambience_mol_khar` | Tons/thumps/noise gerados em runtime (`AudioStreamWAV`) | **Original Red Hollow** |

Gerados em: `scripts/audio/placeholder_audio_factory.gd`  
Roteados por: `scripts/audio/audio_manager.gd`  
Buses: `default_bus_layout.tres` (Master, Music, SFX, Voice, UI, Ambience)

## VFX placeholders (atual)

| Tipo | Origem | Licença |
| --- | --- | --- |
| Partículas CPU (`CPUParticles2D`) | Cores procedurais em `CombatVfxSpawner` | **Original Red Hollow** |
| Flash overlay | `ColorRect` em `CombatVfxSpawner` | **Original Red Hollow** |
| Barreira existente | `red_barrier.tscn` GPUParticles2D greybox | **Original Red Hollow** |

## Substituição por assets finais

1. Exportar `.wav` ou `.ogg` para `audio/sfx/`, `audio/ui/`, `audio/ambience/`, `audio/voice/`.
2. Importar no Godot (ver `docs/ASSET_IMPORT_RULES.md`).
3. Registrar no runtime:

```gdscript
AudioManager.register_stream(AudioEventId.PUNCH, preload("res://audio/sfx/punch_01.wav"))
```

4. Documentar licença neste arquivo antes de commitar o asset.

## Requisitos de licença (produção)

- Preferir assets **originais** ou licenças **CC0 / CC-BY** com atribuição registrada abaixo.
- **Não** usar packs com restrição NC (non-commercial) sem revisão legal.
- **Não** usar samples de franquias protegidas (SFX reconhecíveis de outros jogos/filmes).
- Dublagem completa **fora do escopo** desta etapa; `Voice` bus reservada para blips/UI futuros.

## Atribuições externas

| Asset | Autor | Licença | URL |
| --- | --- | --- | --- |
| *(nenhum ainda)* | — | — | — |

## Documentação relacionada

- `docs/VFX_LANGUAGE.md` — linguagem visual
- `docs/ACCESSIBILITY.md` — screen shake, flashes reduzidos
- `docs/SETTINGS_FORMAT.md` — volumes por bus
