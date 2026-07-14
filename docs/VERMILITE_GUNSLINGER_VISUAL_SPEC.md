# Vermilite Gunslinger — especificação visual (beta)

Produção visual alinhada ao molde do Cult Brawler. **AttackData** continua autoridade de combate. Munição é **slug física com ponta de Vermilite** — não magia genérica.

**Implementação:** `VermiliteGunslingerAnimationContract`, `VermiliteGunslingerVisualController`, `VermiliteGunslingerAssetValidator`  
**Profile:** `resources/visual/enemies/vermilite_gunslinger_pilot_profile.tres`  
**Sheets:** `art/characters/enemies/vermilite_gunslinger/sheets/`

---

## Contrato de frame

| Propriedade | Valor |
| --- | --- |
| Frame aprovado | **32 × 54 px** |
| Pivot | **(16, 54)** |
| `SpriteVisual.offset` | **(0, -27)** |
| Colisão corpo | **32 × 54** |
| Facing arte → gameplay | `Visual.scale.x = facing_direction` |

---

## Animações mínimas (8 clips)

| Clip | Uso |
| --- | --- |
| `idle` | IDLE |
| `aim` | AIM startup / telegraph |
| `fire` | SHOOT / whip active |
| `recoil` | RECOVERY |
| `reload` | RELOAD |
| `reposition` | REPOSITION / PATROL |
| `hurt` | HURT / knockback |
| `death` | DEAD |

Arquivo esperado: `vermilite_gunslinger_<clip>.png`.

---

## Telegraph

1. Linha de mira (`AimVisual` — permanece no modo sprite por acessibilidade)
2. Pose `aim`
3. Brilho do cano (`MuzzleGlow` / eventos `muzzle_charge` / `muzzle_flash`)
4. Som via `CombatFeedbackDirector`
5. Tempo legível (startup do AttackData ≠ duração da animação)
6. Projétil físico visível (`PhysicalProjectile` + ponta Vermilite)

---

## Status PNGs

Sheets de produção **ausentes** → fallback procedural pilot (`use_procedural_pilot_frames = true`). Manifesto marca `missing` / `draft`, **nunca** `integrated` sem arte aprovada.
