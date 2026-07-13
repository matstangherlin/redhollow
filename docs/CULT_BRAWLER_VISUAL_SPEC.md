# Cult Brawler — especificação visual (beta reference enemy)

Primeiro inimigo visualmente completo da beta. Define o padrão para escala, animação, telegraph, reação, morte, VFX, áudio e legibilidade dos inimigos seguintes.

**Implementação:** `CultBrawlerAnimationContract`, `CultBrawlerVisualController`, `CultBrawlerAssetValidator`  
**Cena de teste:** `scenes/tests/cult_brawler_visual_test.tscn` (F6)  
**Sheets de produção:** `art/characters/enemies/cult_brawler/sheets/`

---

## Contrato de frame

| Propriedade | Valor | Notas |
| --- | --- | --- |
| Frame aprovado | **34 × 56 px** | Altura = colisão gameplay |
| Pivot | **(17, 56)** | Centro inferior — pés no chão |
| `SpriteVisual.offset` | **(0, -28)** | Alinha pés à base da colisão |
| Direção padrão (arte) | **Esquerda** | `Visual.scale.x = facing_direction` |
| Escala vs Calder (gameplay) | **1.0×** altura (56 px) | Mesma altura de colisão |
| Escala vs Calder (arte aprovada) | **0.78×** | Calder arte 72 px; Brawler 56 px |
| Colisão corpo | **34 × 56** | `CHARACTER_SCALE_GUIDE.md` |
| Hurtbox | **38 × 60** | Margem de 2 px |
| Hitbox hook | **46 × 28** | `cult_brawler_hook.tres` — não alterar |

### Silhueta alvo

| Elemento | Pixels (frame 34×56) |
| --- | --- |
| Largura do corpo | 34 (ombros ~30) |
| Altura do chapéu | 14 |
| Largura da aba | 28 |
| Alcance visual do ataque | 46 px à frente |
| Posição das mãos (idle) | ±8 px do centro, y≈28 |
| Marca do culto | Centro do peito, y≈30 |

### Área de ataque visual

- **Startup:** braço puxado para trás, brilho no chão à frente (`TelegraphGround` em x=24).
- **Active:** gancho estendido até ~46 px; frame de contato no meio do clip `attack_active`.
- **Recovery:** braço retorna; sem hitbox ativa.

O telegraph de gameplay (0,48 s startup) permanece em `AttackData`. As animações são **independentes** do timing de combate.

---

## Animações mínimas (12 clips)

| Clip | Loop | Frames | Uso |
| --- | --- | --- | --- |
| `idle` | sim | 6 | IDLE |
| `patrol` | sim | 6 | PATROL |
| `alert` | sim | 4 | ALERT |
| `approach` | sim | 6 | APPROACH |
| `attack_startup` | não | 5 | ATTACK phase startup |
| `attack_active` | não | 3 | ATTACK phase active |
| `attack_recovery` | não | 4 | RECOVERY |
| `hurt` | não | 3 | HURT / golpe leve |
| `heavy_hurt` | não | 4 | Body Hook |
| `knocked_back` | não | 4 | Red Knuckle / knockback |
| `stagger` | não | 5 | Red Brand Breaker |
| `death` | não | 8 | DEAD |

Arquivo esperado por clip: `cult_brawler_<clip>.png` em `sheets/`.

---

## Telegraph

Combinação obrigatória (não só cor):

1. **Pose** — `attack_startup` com wind-up e lean.
2. **Movimento** — bob/lean procedural ou frames de arte.
3. **Som** — via `CombatFeedbackDirector` + tags do ataque.
4. **Brilho discreto** — VFX `telegraph_counterable` (hook é counterable).
5. **Efeito no chão** — `TelegraphGround` + evento `ground_glow` no frame 4 do startup.
6. **Ícone** — somente se pose+áudio não forem legíveis (não usado no pilot).

Indica: direção (facing), alcance (~46 px), tempo (~startup), counterable (sim), impacto aproximado (frame 1 de `attack_active`).

---

## Reação a golpes (somente visual)

| Ataque Calder | Clip | Efeito visual |
| --- | --- | --- |
| Calder Straight | `hurt` | Flash leve, recoil 4 px |
| Body Hook | `heavy_hurt` | Flash médio, recoil 8 px |
| Red Knuckle | `knocked_back` | Flash forte, recoil 14 px |
| Red Brand Breaker | `stagger` | Vermilite no peito, recoil 14 px |

Gameplay (dano, knockback, hitstun) **não** é alterado — apenas `CultBrawlerVisualController.apply_hit_reaction()`.

---

## Morte

1. Hitbox desativada (`_on_died`).
2. Colisão de corpo desativada (`CorpseCollisionHelper`).
3. Animação `death` (8 frames) + hold no último frame.
4. Drop de vida via `HealthDropSpawner`.
5. Corpo permanece visível; não bloqueia caminho.
6. `died` não dispara duas vezes (testado em `cult_brawler_tests`).

---

## Fallback

Sem PNGs em `sheets/`:

- `CultBrawlerPlaceholderFactory` gera silhueta procedural (chapéu, marca, gancho).
- Gameplay inalterado.
- `push_warning` controlado via `CultBrawlerAnimationContract.warn_missing_once()`.

Modo `PLACEHOLDER` no profile restaura polígonos greybox originais.

---

## Checklist de produção

1. Exportar sheets 34×56, pivot inferior central, facing esquerda.
2. Nomear `cult_brawler_<clip>.png` conforme contrato.
3. Colocar em `art/characters/enemies/cult_brawler/sheets/`.
4. Abrir `cult_brawler_visual_test.tscn` — validar com [R].
5. Rodar headless: `cult_brawler_asset_validation_tests`, `cult_brawler_visual_tests`, `cult_brawler_tests`.
6. Teste manual: um Brawler, dois, Brawler+Gunslinger, combo, counter, esquiva, Red Brand, morte, respawn, arena, câmera, plataformas, 60 FPS.

---

## Testes headless

| Suite | Arquivo |
| --- | --- |
| Gameplay (baseline) | `scripts/enemies/cult_brawler_tests.gd` |
| Validação de assets | `scripts/visual/enemies/cult_brawler_asset_validation_tests.gd` |
| Pipeline visual | `scripts/visual/enemies/cult_brawler_visual_tests.gd` |

---

## Fora de escopo desta entrega

- Gunslinger, Chain Penitent, Deacon Rusk — não alterados.
- Timings de `cult_brawler_hook.tres` — congelados.
- IA e balanceamento — sem mudanças.
