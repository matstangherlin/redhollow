# Visual Presentation Contract — Provisional art baseline

Contrato que separa **gameplay** de **apresentação visual provisória** na vertical slice. Objetivo: permitir substituir arte pixel/Vermilite futura sem reescrever combate ou movimento.

## Princípio

Gameplay depende de:

- `CharacterBody2D` + `CollisionShape2D` (corpo)
- `%HitboxComponent` / `%HurtboxComponent` + shapes
- `AttackData` (timings, hitbox size/offset, dano, knockback)
- Exports de movimento/combate em `player.gd`
- Máquina de estados e timers

Gameplay **não deve depender** de:

- Cor ou escala de `%BodyVisual` (`Polygon2D`)
- Cor ou escala de `%BrandHand` (`Polygon2D`)
- Cor de `ArrowVisual` em `%DirectionMarker`
- `%InteractionPromptLabel` / `%DebugLabel`
- Sprites ou animações ainda inexistentes
- HUD de estilo provisório (`StyleHud`)

## Elementos provisórios atuais

| Nó | Tipo | Uso atual | Substituível? |
| --- | --- | --- | --- |
| `%BodyVisual` | Polygon2D | Feedback dodge/counter/taunt via `color`/`scale` | Sim — gameplay continua |
| `%BrandHand` | Polygon2D | Feedback carga Brand via cor | Sim |
| `%DirectionMarker` | Node2D + Polygon2D | Indicador de facing | Sim |
| `%DebugLabel` | Label | Debug F1 | Sim |
| `%InteractionPromptLabel` | Label | Prompt [E] | Sim |

## Feedback visual vs lógica

Estas mudanças visuais existem hoje mas **não alteram hitboxes ou colisão**:

- Dodge: `DODGE_BODY_COLOR`, `DODGE_BODY_SCALE`
- Counter: cores por fase (`COUNTER_WINDOW_BODY_COLOR`, etc.)
- Taunt: `TAUNT_BODY_COLOR`
- Brand charge: `DEFAULT/CHARGING/MAX_CHARGE_BRAND_HAND_COLOR`

Refatoração de arte pode mover esse feedback para AnimationPlayer/Sprite2D **desde que** colisões e AttackData permaneçam a fonte de verdade combat.

## Colisões protegidas (baseline)

| Shape | Tamanho | Layer/Mask |
| --- | --- | --- |
| Corpo | 32×56 | default CharacterBody2D |
| Hurtbox | 34×58 | layer 32, mask 16 |
| Hitbox | 44×28 (base; AttackData redimensiona) | layer 8, mask 64 |

## AttackData como fonte combat

Hitbox ativa usa:

```gdscript
attack_data.hitbox_size
attack_data.hitbox_offset * facing_direction
```

Não usar bounds do Polygon2D para dano ou alcance.

## Testes de regressão visual

`player_regression_tests.gd` verifica:

- Ocultar `%BodyVisual` e `%BrandHand` não impede movimento, pulo ou ataque.
- Hitbox continua ativável com shape de AttackData.
- Colisão do corpo permanece independente da escala visual.

## Diretrizes para arte futura

1. Manter `%HitboxComponent`, `%HurtboxComponent`, `%HealthComponent`, `%RedBrandComponent` na árvore.
2. Preservar unique names usados pelo script.
3. Não acoplar lógica de estado a nomes de animação; preferir sinais/API pública.
4. UI definitiva escuta StyleManager/Player via sinais — Player não referencia HUD final.
