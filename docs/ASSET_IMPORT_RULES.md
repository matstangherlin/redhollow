# Red Hollow — Asset Import Rules

Regras de importação Godot 4.7 para arte 2D definitiva. **Não baixar assets externos** sem autorização e licença.

## Formato de arquivo

| Tipo | Formato | Notas |
| --- | --- | --- |
| Sprites personagem | PNG 32-bit RGBA | Sem JPEG |
| Tilesets / cenário | PNG | Power-of-two opcional; preferir múltiplos de 16 |
| VFX | PNG sequência ou atlas | Fundo transparente |
| UI | PNG / SVG (UI estática) | SVG só UI, não personagens |

## Filtro e compressão (Import dock)

| Asset | Filter | Mipmaps | Compress |
| --- | --- | --- | --- |
| Pixel art personagem | **Nearest** | Off | Lossless / VRAM Compressed (Desktop) |
| Pixel art cenário | Nearest | Off | Lossless |
| VFX pequeno | Nearest | Off | Lossless |
| UI | Linear ou Nearest (pixel UI) | Off | Lossless |

**Nunca** usar filter Linear em sprites de personagem pixel art.

## Nomenclatura de arquivos

Padrão: `{categoria}_{subject}_{variant}_{detail}.{ext}`

Exemplos:

```
art/characters/calder/calder_idle_sheet.png
art/characters/calder/calder_run_sheet.png
art/characters/enemies/cult_brawler/cult_brawler_idle_sheet.png
art/environments/chapter_zero/street_bg_far.png
art/vfx/vfx_hit_spark_small.png
```

Spritesheets:

```
{char}_{anim}_sheet.png
Frame size fixo por animação (ex.: 32×56 idle/run).
```

## Organização de atlas

| Atlas | Conteúdo | Tamanho máx sugerido |
| --- | --- | --- |
| `calder_combat_sheet` | straight, hook, knuckle | 256×256 |
| `calder_locomotion_sheet` | idle, run, jump, land | 256×256 |
| `calder_defense_sheet` | dodge, counter, hurt | 256×256 |
| Por inimigo | idle + attacks | 128×128 |

Evitar mega-atlas > 1024×1024 na beta.

Godot: criar `SpriteFrames` resource em `resources/visual/` ou `art/.../frames/` apontando para regiões.

## SpriteFrames vs AnimationPlayer

- **Preferir `AnimatedSprite2D` + `SpriteFrames`** para personagens (pipeline atual).
- `AnimationPlayer` só para props/cenário/UV scroll — **não** para timing de hitbox do jogador.

## Como importar (passo a passo)

1. Colocar PNG em `art/...` conforme árvore em `art/README.md`.
2. Godot importa automaticamente; selecionar arquivo → aba **Import**:
   - Desmarcar mipmaps.
   - Filter: Nearest.
   - Repeat: Disabled (personagens).
3. Criar ou editar `SpriteFrames`:
   - Add animation (nome = ID em `ANIMATION_PIPELINE.md`).
   - Add frames from sprite sheet (grid fixo).
4. Salvar `.tres` em `resources/visual/calder_final_frames.tres`.
5. Criar `PlayerVisualProfile` duplicando `calder_pilot_profile.tres`:
   - `visual_mode = FINAL`
   - `sprite_frames_path = res://resources/visual/calder_final_frames.tres`
   - `use_procedural_pilot_frames = false`
   - Preencher `attack_animation_map`.
6. Assign perfil em `PlayerVisualController` na cena player **ou** via variant de cena beta.

## Como trocar placeholder

| De | Para | Ação |
| --- | --- | --- |
| Greybox | Piloto | Profile `calder_pilot_profile.tres` |
| Piloto | Final | Profile final + SpriteFrames importado |
| Final → Greybox (debug) | `calder_placeholder_profile.tres` | Restaura Polygon2D |

Greybox `%BodyVisual` / `%BrandHand` **permanecem na cena** — apenas ocultos quando sprite ativo.

## Como sincronizar animação e ataque

1. Identificar `attack_id` no `AttackData` (ex.: `calder_straight`).
2. Adicionar entrada em `PlayerVisualProfile.attack_animation_map`:
   ```json
   "calder_straight": "straight"
   ```
3. **Não** alterar `startup_time` / `active_time` / `recovery_time` para “casar” animação.
4. Ajustar frames **visuais** (anticipation, follow-through) dentro do clip.
5. Hitbox continua definida por `hitbox_size` e `hitbox_offset` no `.tres` de combate.
6. Rodar `player_regression_tests.gd` + `player_visual_pipeline_tests.gd`.

## Marcação opcional (frames-chave)

Em produção, marcar no metadata JSON lateral (não no jogo):

```json
{
  "straight": { "active_frame": 1, "notes": "hitbox aligns frame 1 visually only" }
}
```

Gameplay ignora este arquivo; serve para animadores.

## Proibido

- Imagens de referência de terceiros **dentro** do repositório/jogo.
- Copiar sprites de jogos existentes.
- Importar com filter Linear em pixel art.
- Usar bounds do sprite como hitbox.

## Documentos relacionados

- `ANIMATION_PIPELINE.md`, `CHARACTER_SCALE_GUIDE.md`, `NAMING_CONVENTIONS.md`
