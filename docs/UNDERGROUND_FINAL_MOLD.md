# Underground Final Mold — Cap. Zero catacombs

**Status:** molde final aplicado às catacumbas (0–1200) + encerramento Cap. Zero.  
**Não** altera rua/igreja.  
**Não** revela Mol-Khar completo nem Palácio Rubro.

## Progressão visual (5 estágios)

| # | Zona | X |
| ---: | --- | --- |
| 1 | Infraestrutura humana | 0–240 |
| 2 | Túneis da Ordem | 220–480 |
| 3 | Ruínas antigas | 460–720 |
| 4 | Prisão de Mol-Khar | 700–960 |
| 5 | Manifestação espiritual | 940–1200 |

## Set pieces / boss arena

Timber · arcos Ordem · glifos · altar · `MoldBossArena` (piso limpo + rim fase 2) · estátua · sombra tease · passagem.

Gameplay preservado: checkpoint, Deacon, encounter, diary, exits, Solids.

## Deacon Rusk (visual)

Clips: idle, reposition, punch_combo, charge, counterable_attack, ground_attack, armor_attack, hurt, stagger, phase_transition, death.  
IA/AttackData **congelados**. Frame 42×72; colisão greybox 42×68.

## Finale (8 beats)

1 tremor · 2 Red Brand · 3 olhos · 4 sombra Mol · 5 voz · 6 silhueta Arcturus · 7 passagem · 8 tela final + **Voltar ao menu**.

## Código

| Peça | Path |
| --- | --- |
| Spec | `underground_final_mold_spec.gd` |
| Composer | `underground_final_mold_composer.gd` |
| Area | `underground_art_area.gd` |
| Deacon visual | `scripts/visual/enemies/deacon_rusk_*` |
| Finale | `chapter_zero_finale.gd` |

## QA

Boss P1/P2 · counter · morte · respawn · checkpoint · save/load · finale · menu · Continuar · performance (**P**).
