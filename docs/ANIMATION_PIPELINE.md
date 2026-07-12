# Red Hollow — Animation Pipeline

Pipeline de animação 2D para substituir greybox **sem alterar gameplay**. Complementa `VISUAL_PRESENTATION_CONTRACT.md`.

## Princípio central

| Camada | Fonte de verdade |
| --- | --- |
| **Combate** | `AttackData` (startup / active / recovery, dano, hitbox, knockback, hitstop) |
| **Movimento** | `CharacterBody2D`, exports em controllers |
| **Visual** | `PlayerVisualController` + `AnimatedSprite2D` (cosmético) |

**AnimationPlayer / AnimatedSprite2D nunca** definem quando a hitbox liga ou desliga.

## Arquitetura Calder

```
Player (CharacterBody2D)          ← lógica, colisão, estado
├── CollisionShape2D            ← 32×56 (protegido)
├── VisualDebugOverlay          ← debug bounds (F)
├── Components/                 ← hitbox, hurtbox, health, Red Brand
├── Controllers/
│   ├── PlayerAttackController  ← AttackData timing
│   ├── PlayerMovementController
│   ├── PlayerPresentationController  ← feedback greybox (cores)
│   └── PlayerVisualController  ← sprite substituível
└── Visual/
    ├── BodyVisual / BrandHand  ← PLACEHOLDER (Polygon2D)
    └── SpriteVisual            ← PILOT / FINAL (AnimatedSprite2D)
```

## Contrato de assets (`CalderAnimationContract`)

| Parâmetro | Valor |
| --- | --- |
| Canvas por frame | **32 × 56 px** |
| Personagem (silhueta) | **~32 × 56 px** |
| Pivot | **centro inferior** (16, 56) no frame |
| Pés | `CharacterBody2D.position` (origin gameplay) |
| `%SpriteVisual.offset` | **(0, -28)** |
| Facing padrão | **direita** (+1) via `Visual.scale.x` |
| Organização | **arquivos separados por animação** (piloto) ou atlas por grupo (final) |
| Ordem dos frames | **esquerda → direita** no PNG horizontal |

Código: `scripts/visual/calder_animation_contract.gd`

## Modos visuais (`PlayerVisualProfile.VisualMode`)

| Modo | Uso | Gameplay |
| --- | --- | --- |
| `PLACEHOLDER` | Greybox atual (padrão em `player.tscn`) | Inalterado |
| `PILOT` | 10 animações piloto (procedural ou sheets) | Inalterado |
| `FINAL` | Arte definitiva importada | Inalterado |

Perfis em `resources/visual/`. Trocar perfil no nó `PlayerVisualController` ou via cena de teste.

## Animações piloto integradas (primeiro passo)

| ID clip | Frames | FPS | Loop | Arquivo esperado | Status |
| --- | ---: | ---: | --- | --- | --- |
| `idle` | 6 | 8 | Sim | `art/characters/calder/calder_idle_sheet.png` | procedural |
| `run` | 6 | 12 | Sim | `calder_run_sheet.png` | procedural |
| `jump_rise` | 2 | 10 | Não | `calder_jump_rise_sheet.png` | procedural |
| `fall` | 2 | 8 | Sim | `calder_fall_sheet.png` | procedural |
| `land` | 3 | 10 | Não | `calder_land_sheet.png` | procedural |
| `straight` | 4 | 14 | Não | `calder_straight_sheet.png` | procedural |
| `body_hook` | 4 | 12 | Não | `calder_body_hook_sheet.png` | procedural |
| `red_knuckle` | 5 | 10 | Não | `calder_red_knuckle_sheet.png` | procedural |
| `dodge` | 4 | 14 | Não | `calder_dodge_sheet.png` | procedural |
| `hurt` | 2 | 10 | Não | `calder_hurt_sheet.png` | procedural |

Tabela completa de produção (22 clips alvo): ver seção abaixo.

## Lista de animações Calder (produção completa)

| ID | Uso | Loop | Prioridade | Status |
| --- | --- | --- | --- | --- |
| `idle` | Repouso | Sim | P0 | piloto ✓ |
| `run` | Corrida | Sim | P0 | piloto ✓ |
| `turn` | Virada rápida | Não | P1 | pendente |
| `jump_start` | Impulso | Não | P1 | pendente |
| `jump_rise` | Subida | Não | P0 | piloto ✓ |
| `fall` | Queda | Sim | P0 | piloto ✓ |
| `land` | Pouso | Não | P0 | piloto ✓ |
| `straight` | Soco reto combo 1 | Não | P0 | piloto ✓ |
| `body_hook` | Gancho combo 2 | Não | P0 | piloto ✓ |
| `red_knuckle` | Combo 3 | Não | P0 | piloto ✓ |
| `dodge` | Esquiva | Não | P0 | piloto ✓ |
| `counter_window` | Janela counter | Sim curto | P2 | pendente |
| `counter_attack` | Golpe counter | Não | P2 | pendente |
| `taunt_01` / `taunt_02` | Provocação | Não | P2 | pendente |
| `hurt` | Dano | Não | P0 | piloto ✓ |
| `knockdown` | Queda longa | Não | P2 | pendente |
| `death` | Morte | Não | P1 | pendente |
| `respawn` | Retorno checkpoint | Não | P2 | pendente |
| `interact` | Examinar / falar | Não | P2 | pendente |
| `red_brand_charge` | Carga breaker | Sim | P1 | pendente |
| `red_brand_breaker` | Impacto breaker | Não | P1 | pendente |

## Sincronização animação ↔ ataque

1. `PlayerAttackController` avança fases com timers de `AttackData`.
2. `HitboxComponent.activate()` ocorre na fase **ACTIVE** — não no frame da animação.
3. `PlayerVisualController.refresh_from_player()` escolhe clip por:
   - `attack_id` → `PlayerVisualProfile.attack_animation_map`;
   - senão, estado → `state_animation_map` ou heurística (`jump_rise` / `fall` / `land`).
4. Animação pode ser mais curta ou longa que o combate; **desync aceitável** se hitbox respeitar AttackData.
5. **Eventos visuais** (`visual_event` signal): `footstep`, `dust`, `swing_trail`, `contact_visual`, `impact_visual`, `sound` — cosméticos apenas; definidos em `CalderAnimationContract.VISUAL_EVENT_FRAMES`.

## Fallback

| Situação | Comportamento |
| --- | --- |
| Perfil `PLACEHOLDER` | Polygon2D greybox |
| `SpriteFrames` ausente | Procedural pilot completo |
| Clip individual ausente | Procedural só daquele clip |
| Clip não encontrado em runtime | `idle` + `push_warning` (uma vez) |
| Build export | Sem erro; warnings no editor/console |

Builder: `CalderSpriteFramesBuilder.build_for_profile()`

## Debug visual (tecla F)

Com `debug_toggle` (F):

- Label: estado, fase de ataque, **visual_mode**, **animation**, **anim_frame**
- Overlay: collision, hurtbox, hitbox, sprite bounds, pivot, linha de chão
- Hitbox/hurtbox debug draw (existente)

## Piloto atual (validação)

Suíte: `scripts/visual/player_visual_pipeline_tests.gd`

Cena manual: `scenes/tests/calder_visual_pilot_test.tscn` — **F** alterna PLACEHOLDER ↔ PILOT.

Animações procedurais: `PlaceholderSpriteFactory.create_calder_pilot_sprite_frames()`

Perfil piloto: `resources/visual/calder_pilot_profile.tres`

## Como trocar placeholder → piloto → final

### Placeholder → Piloto (teste local)

1. Abrir `scenes/tests/calder_visual_pilot_test.tscn` **ou** `player.tscn`.
2. Em `PlayerVisualController`, assign `calder_pilot_profile.tres`.
3. `%BodyVisual` oculto, `%SpriteVisual` visível.
4. Gameplay, colisão e combo **inalterados**.

### Piloto → Final

1. Exportar PNGs conforme contrato em `art/characters/calder/`.
2. Opção A: `SpriteFrames` em `resources/visual/calder_final_frames.tres`.
3. Opção B: sheets individuais — builder monta automaticamente.
4. Perfil `calder_final_profile.tres`: `visual_mode = FINAL`, `use_procedural_pilot_frames = false`.
5. Preencher `attack_animation_map` e `state_animation_map`.
6. **Não** alterar `AttackData` para casar animação.

## Testes obrigatórios

```powershell
$env:RH_TEST_SUITE="res://scripts/visual/player_visual_pipeline_tests.gd"
godot --headless --main-scene res://scenes/tests/test_bootstrap.tscn

godot --headless --path . --script res://scripts/tests/test_runner.gd
```

- [ ] Pipeline piloto passa headless (8 asserts)
- [ ] Regressão player passa
- [ ] `calder_straight` hitbox idêntica placeholder vs sprite
- [ ] Facing via `%Visual.scale.x` preservado

## Documentos relacionados

- `ART_BIBLE.md`, `CHARACTER_SCALE_GUIDE.md`, `ASSET_IMPORT_RULES.md`, `VFX_LANGUAGE.md`, `VISUAL_PRESENTATION_CONTRACT.md`
