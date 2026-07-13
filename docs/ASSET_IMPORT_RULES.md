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

Spritesheets (Calder) — **produção aprovada** (`docs/VISUAL_SCALE_STUDY.md`):

```
art/characters/calder/sheets/calder_{anim}_sheet.png
Frame size fixo: 40×72 px por frame.
Frames dispostos horizontalmente (frame 0 à esquerda).
```

Spritesheets placeholder (procedural interno): 32×56 até arte real substituir.

### Contrato Calder (obrigatório)

| Parâmetro | Valor produção | Valor placeholder |
| --- | --- | --- |
| Canvas | **40 × 72 px** por frame | 32 × 56 px |
| Personagem | silhueta ~40 × 72 | ~32 × 56 |
| Pivot | centro inferior `(20, 72)` | `(16, 56)` |
| Pés | offset sprite `(0, -36)` | `(0, -28)` |
| Facing padrão | olhando **direita** | idem |
| Filtro | **Nearest** | idem |
| Colisão gameplay | **32 × 56** (inalterada) | idem |

Ver checklist completo: `docs/CALDER_ASSET_CHECKLIST.md`.

### Piloto — arquivos esperados

| Animação | Arquivo | Frames | FPS |
| --- | --- | ---: | ---: |
| idle | `calder_idle_sheet.png` | 6 | 8 |
| run | `calder_run_sheet.png` | 6 | 12 |
| jump_start | `calder_jump_start_sheet.png` | 2 | 12 |
| jump_rise | `calder_jump_rise_sheet.png` | 2 | 10 |
| fall | `calder_fall_sheet.png` | 2 | 8 |
| land | `calder_land_sheet.png` | 3 | 10 |
| straight | `calder_straight_sheet.png` | 4 | 14 |
| body_hook | `calder_body_hook_sheet.png` | 4 | 12 |
| red_knuckle | `calder_red_knuckle_sheet.png` | 5 | 10 |
| dodge | `calder_dodge_sheet.png` | 4 | 14 |
| hurt | `calder_hurt_sheet.png` | 2 | 10 |

Largura do PNG = `frames × 40`. Altura = `72` (produção). Placeholder procedural permanece 32×56 internamente.

### Atlas (opcional — fase final)

| Atlas | Conteúdo | Tamanho máx sugerido |
| --- | --- | --- |
| `calder_locomotion_atlas.png` | idle, run, jump, land | 256×256 |
| `calder_combat_atlas.png` | straight, hook, knuckle | 256×256 |
| `calder_defense_atlas.png` | dodge, hurt | 128×128 |

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
| Piloto procedural | Piloto sheets | `use_procedural_pilot_frames = false` + PNGs em `art/characters/calder/` |
| Piloto | Final | Profile final + `SpriteFrames` ou sheets |
| Final → Greybox (debug) | `calder_placeholder_profile.tres` | Restaura Polygon2D |

Cena de teste: `scenes/tests/calder_visual_pilot_test.tscn` (F alterna modos).

Greybox `%BodyVisual` / `%BrandHand` **permanecem na cena** — apenas ocultos quando sprite ativo.

## Fallback em importação

- PNG ausente → clip procedural da mesma animação (`CalderSpriteFramesBuilder`).
- `push_warning` controlado (uma vez por contexto) — **não bloqueia build**.
- Clip ausente em runtime → substitui por `idle`.

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
