# Deacon Rusk — especificação visual (Cap. Zero boss)

**IA e AttackData permanecem autoridade.** Pipeline igual Gunslinger/Penitent.

| Frame | 42 × 72 px |
| Pivot | (21, 72) |
| Offset | (0, -36) |
| Colisão | 42 × 68 (não alterar) |

## Clips

idle · reposition · punch_combo · charge · counterable_attack · ground_attack · armor_attack · hurt · stagger · phase_transition · death

## Telegraphs

- Counterable (punish sweep): `TelegraphVisual` âmbar
- Armor/charge: `WarningVisual` rubro
- Ground slam: `SlamVisual` no chão
- Fase 2: manto/armadura Vermilite no clip `phase_transition` / `armor_attack`

Sheets: `art/characters/enemies/deacon_rusk/sheets/` — ausentes → procedural pilot.
