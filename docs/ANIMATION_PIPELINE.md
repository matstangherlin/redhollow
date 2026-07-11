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
├── Components/                   ← hitbox, hurtbox, health, Red Brand
├── Controllers/
│   ├── PlayerAttackController    ← AttackData timing
│   ├── PlayerMovementController
│   ├── PlayerPresentationController  ← feedback greybox (cores)
│   └── PlayerVisualController    ← sprite substituível
└── Visual/
    ├── BodyVisual / BrandHand    ← PLACEHOLDER (Polygon2D)
    └── SpriteVisual              ← PILOT / FINAL (AnimatedSprite2D)
```

## Modos visuais (`PlayerVisualProfile.VisualMode`)

| Modo | Uso | Gameplay |
| --- | --- | --- |
| `PLACEHOLDER` | Greybox atual (padrão) | Inalterado |
| `PILOT` | Validação pipeline (4 animações procedurais) | Inalterado |
| `FINAL` | Arte definitiva importada | Inalterado |

Perfis em `resources/visual/`. Trocar perfil no nó `PlayerVisualController` da cena `player.tscn`.

## Lista de animações Calder (produção)

| ID | Uso | Loop | Prioridade beta |
| --- | --- | --- | --- |
| `idle` | Repouso | Sim | Piloto ✓ |
| `run` | Corrida | Sim | Piloto ✓ |
| `turn` | Virada rápida | Não | P1 |
| `jump_start` | Impulso | Não | Agrupado em `jump` no piloto |
| `jump_rise` | Subida | Sim curto | Piloto ✓ (`jump`) |
| `fall` | Queda | Sim | Piloto ✓ (`jump`) |
| `land` | Pouso | Não | P1 |
| `straight` | Soco reto combo 1 | Não | Piloto ✓ |
| `body_hook` | Gancho combo 2 | Não | P1 |
| `red_knuckle` | Combo 3 | Não | P1 |
| `dodge` | Esquiva | Não | P1 |
| `counter_window` | Janela counter | Sim curto | P2 |
| `counter_attack` | Golpe counter | Não | P2 |
| `taunt_01` / `taunt_02` | Provocação | Não | P2 |
| `hurt` | Dano | Não | P1 |
| `knockdown` | Queda longa | Não | P2 |
| `death` | Morte | Não | P1 |
| `respawn` | Retorno checkpoint | Não | P2 |
| `interact` | Examinar / falar | Não | P2 |
| `red_brand_charge` | Carga breaker | Sim | P1 |
| `red_brand_breaker` | Impacto breaker | Não | P1 |

## Sincronização animação ↔ ataque

1. `PlayerAttackController` avança fases com timers de `AttackData`.
2. `HitboxComponent.activate()` ocorre na fase **ACTIVE** — não no frame 3 da animação.
3. `PlayerVisualController.refresh_from_player()` escolhe clip por:
   - `attack_id` → mapa em `PlayerVisualProfile.attack_animation_map`;
   - senão, estado (`idle` / `run` / `jump`).
4. Animação pode ser mais curta ou longa que o combate; **desync aceitável** se hitbox respeitar AttackData.
5. Para polish final: adicionar **eventos de marca** nos spritesheets (ver `ASSET_IMPORT_RULES.md`) — ainda disparados pelo controller, não pelo AnimationPlayer.

## Piloto atual (validação)

Suíte: `scripts/visual/player_visual_pipeline_tests.gd`

Headless: usa fixture isolado (`visual_test_player_stub.gd`) — não depende de autoloads nem de `player.tscn` completo.

Animações procedurais: `PlaceholderSpriteFactory.create_calder_pilot_sprite_frames()`

Perfil: `resources/visual/calder_pilot_profile.tres`

## Como trocar placeholder → piloto → final

Ver seções finais de `ASSET_IMPORT_RULES.md` e `CHARACTER_SCALE_GUIDE.md`.

### Placeholder → Piloto (teste local)

1. Abrir `scenes/player/player.tscn`.
2. Em `PlayerVisualController`, assign `calder_pilot_profile.tres`.
3. Rodar jogo — `%BodyVisual` oculto, `%SpriteVisual` visível.
4. Executar testes headless do pipeline.

### Piloto → Final

1. Importar spritesheet conforme `ASSET_IMPORT_RULES.md`.
2. Criar `SpriteFrames` em `art/characters/calder/` ou `resources/visual/`.
3. Duplicar perfil → `calder_final_profile.tres`, `visual_mode = FINAL`, `sprite_frames_path` apontando ao recurso.
4. Preencher `attack_animation_map` para todos os `attack_id`.
5. Manter `AttackData` existente; ajustar **apenas** offsets visuais se necessário (não hitbox).

## VFX e áudio

VFX seguem `VFX_LANGUAGE.md` em nós irmãos de `%Visual`, não dentro da hitbox.

Áudio: bus `Combat`, `Player`, `UI` — triggers via controllers ou Animation **event markers** espelhando fases de AttackData (futuro).

## Testes obrigatórios antes de arte completa

- [ ] Pipeline piloto passa headless.
- [ ] Ocultar sprite não quebra movimento/combo (regressão player).
- [ ] `calder_straight` hitbox idêntica com placeholder e sprite.
- [ ] Facing via `%Visual.scale.x` preservado.

## Documentos relacionados

- `ART_BIBLE.md`, `CHARACTER_SCALE_GUIDE.md`, `ASSET_IMPORT_RULES.md`, `VFX_LANGUAGE.md`, `VISUAL_PRESENTATION_CONTRACT.md`
