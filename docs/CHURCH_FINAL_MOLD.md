# Church Final Mold — Cap. Zero church district

**Status:** molde final **aprovado** aplicado à igreja completa (0–1800).  
**Não** altera catacumbas.  
**Não** marca PNG placeholder como `integrated`.

## Identidade

Pedra ritual · verticalidade · torre / sino · praça · estátuas · banners · velas · portão · entrada subterrânea · presença forte da Ordem.

## Distritos (preservados)

| # | Distrito | X |
| ---: | --- | --- |
| 1 | Chegada da rua | 0–180 |
| 2 | Alcova do Penitente | 160–420 |
| 3 | Praça da Ordem | 400–720 |
| 4 | Pátio da arena | 700–1120 |
| 5 | Corredor Red Brand | 1100–1400 |
| 6 | Portão subterrâneo | 1380–1800 |

## Set pieces (mold overlays)

| Peça | Nó mold | Gameplay permanece |
| --- | --- | --- |
| Torre do sino | `Mold_BellTower` | — |
| Entrada principal | `Mold_MainEntrance` | — |
| Estátua | `Mold_OrderStatue` | — |
| Altar externo | `Mold_ExternalAltar` | — |
| Portão | `Mold_CultGate` | `CultRedBarrier` |
| Passagem subterrânea | `Mold_UndergroundPassage` | `ToUndergroundExit` |

## Código

| Peça | Path |
| --- | --- |
| Spec / modes | `church_final_mold_spec.gd` |
| Layout + mold data | `church_north_star_layout.gd` |
| Composer | `church_final_mold_composer.gd` |
| Toggle | `church_art_area.gd` modo `final_candidate` |

Reutiliza: `StreetKitVisualBridge`, `StreetPerformanceMonitor`, `RegionVisualController`, palette, pipelines inimigos/HUD.

## Gameplay preservado

Chain Penitent · arena combinada · checkpoint · documento · barreira · passagem Red Brand · atalhos · backtracking · saída catacumbas.

## Como ver

Demo church art → modo `FINAL MOLD (church 0–1800)` · **P** perf · **'** estados de região.

## QA checklist

- [ ] Rota rua → igreja → catacumbas  
- [ ] Visibilidade / legibilidade set pieces  
- [ ] Arena + telegraphs  
- [ ] Penitent + projéteis (se presentes)  
- [ ] Red Brand passage / barreira  
- [ ] Save / checkpoint  
- [ ] Mapa  
- [ ] Transições  
- [ ] Performance ≥55 FPS (**P**)

## Manifesto

Lotes `draft` `env_church_mold_district_*` + `env_church_final_mold_full`.  
Existência de geometria ≠ `approved`/`integrated`.
