# Chain Penitent — especificação visual (beta)

Produção visual alinhada ao molde do Cult Brawler. **AttackData** continua autoridade de combate. Arma = **corrente metálica** com alcance legível — não VFX mágico genérico.

**Implementação:** `ChainPenitentAnimationContract`, `ChainPenitentVisualController`, `ChainPenitentAssetValidator`  
**Profile:** `resources/visual/enemies/chain_penitent_pilot_profile.tres`  
**Sheets:** `art/characters/enemies/chain_penitent/sheets/`

---

## Contrato de frame

| Propriedade | Valor |
| --- | --- |
| Frame aprovado | **38 × 58 px** |
| Pivot | **(19, 58)** |
| `SpriteVisual.offset` | **(0, -29)** |
| Colisão corpo | **38 × 58** |

---

## Animações mínimas (9 clips)

| Clip | Uso |
| --- | --- |
| `idle` | IDLE / ALERT |
| `walk` | PATROL / APPROACH |
| `chain_startup` | SWEEP/HOOK startup |
| `chain_active` | SWEEP active |
| `chain_recovery` | recovery |
| `pull` | HOOK active |
| `hurt` | HURT |
| `stagger` | VULNERABLE / Breaker |
| `death` | DEAD |

Arquivo esperado: `chain_penitent_<clip>.png`.

---

## Telegraph

1. Corrente preparada (`ChainVisual` no startup)
2. Alcance (`TelegraphVisual` + `ReachMarker`)
3. Direção (facing)
4. Pose `chain_startup`
5. Som metálico (`chain_rattle` / feedback director)
6. Janela de esquiva = startup do AttackData (animação independente)

---

## Status PNGs

Sheets **ausentes** → fallback procedural. Manifesto `missing`/`draft` até arte final aprovada.
