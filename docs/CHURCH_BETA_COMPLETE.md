# Distrito da Igreja — North Star (Capítulo Zero)

Transformação visual do distrito da igreja no mesmo pipeline North Star da rua. Catacumbas **não** alteradas.

**Data:** 2026-07-13

---

## Identidade visual (vs rua)

| Aspecto | Rua | Igreja |
|---------|-----|--------|
| Materiais | Madeira, terra, pó | Pedra ritual, cobblestone |
| Silhuetas | Horizontal, saloon | Vertical, torre, espinho |
| Altura | Fachadas ~112px | Fachadas ~140–156px + torre 200px |
| Iluminação | Pôr do sol quente | Lua fria, lanternas baixas |
| Densidade | Props comerciais | Símbolos, guardas, velas |
| Símbolos | Coração disperso | Coração em altar, estátua, banners |
| Música | Vento + madeira | Sino + sussurro (`AmbientAudioController`) |
| Ambiente | Poeira, movimento | Névoa, ameaça contida |

Mol-Khar: estado `mol_khar` usa silhueta e vermelho interno **sem** revelação completa.

---

## Distritos (6)

| # | Zona | Faixa X | Gameplay |
|---|------|---------|----------|
| 1 | Chegada da rua | 0–180 | Exit rua, spawn `from_street` |
| 2 | Alcova do Penitente | 160–420 | Chain Penitent |
| 3 | Praça da Ordem | 400–720 | Checkpoint, documento Ordem |
| 4 | Pátio da arena | 700–1120 | Arena (Brawler + Gunslinger + Penitent) |
| 5 | Corredor Red Brand | 1100–1400 | Passagem U, cache, barreira cult |
| 6 | Portão subterrâneo | 1380–1800 | Exit catacumbas, atalho rua |

---

## Set pieces preparados

| Peça | Procedural | Slot PNG |
|------|------------|----------|
| Sino | `BellTowerStructure` | `church_bell_tower.png`, `church_mod_bell.png` |
| Entrada principal | `MainChurchEntrance` | `church_main_entrance.png`, `church_mod_entrance.png` |
| Estátua | `OrderStatueLarge` | `church_order_statue.png`, `church_mod_statue.png` |
| Altar externo | `ExternalAltar` | `church_external_altar.png`, `church_mod_altar.png` |
| Portão cult | `CultGateVisual` | `church_cult_gate.png`, `church_mod_gate.png` |
| Passagem subterrânea | `UndergroundPassageVisual` | `church_underground_passage.png`, `church_mod_passage.png` |

Igreja ao fundo: parallax `DistantChurchNave` + `DistantChurchSpire` (silhueta, sem Mol-Khar).

---

## Assets novos

### Scripts / recursos

- `scripts/visual/church_north_star_layout.gd`
- `scripts/visual/church_north_star_variants.gd`
- `scripts/visual/church_north_star_factory.gd`
- `scripts/visual/church_beta_composer.gd`
- `scripts/visual/church_art_presentation.gd`
- `scripts/visual/church_art_area.gd`
- `scripts/visual/church_beta_complete_tests.gd`
- `scripts/visual/lighting/chapter_zero_church_theme_factory.gd`
- `resources/visual/chapter_zero_church_profile.tres`
- `scenes/environment/chapter_zero/church_art_presentation.tscn`
- `scenes/areas/vertical_slice_church_art.tscn`

### PNGs esperados (arte final)

**Set pieces:** `art/environments/chapter_zero/church_*.png` (6 arquivos)

**Kit modular estendido:** `art/environments/chapter_zero/modules/church_mod_*.png` (7 módulos)

**Reuso kit rua:** lantern, fence, sign (`street_mod_*`)

---

## Validação

### Automática

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

Suíte: `church_beta_complete_tests` — distritos, camadas, markers, gameplay, continuidade rua↔igreja, mapa.

### Manual

- [ ] Transição rua → igreja (spawn `from_street`, câmera 1800px)
- [ ] Arena: Brawler + Gunslinger + Penitent
- [ ] Portas/barreiras/atalho/backtracking
- [ ] Diálogo documento + Vermilite reaction
- [ ] Mapa: nó `vs_greybox_church` visitável
- [ ] Performance: tecla `P` no monitor (meta 60 FPS)
- [ ] Gamepad: combate + interação + Red Brand hold

### Continuidade

- Mesma escala: `pixels_per_unit=1`, `ground_surface_y=876`, Calder 40×72
- `WorldGraphFactory.SCENE_CHURCH` → `vertical_slice_church_art.tscn`
- Exit rua → igreja art; exit igreja → rua art; underground → igreja art

---

## Estimativa arte final (igreja)

| Fase | Horas |
|------|-------|
| Set pieces PNG (6) | 18–28 h |
| Kit church_mod (7) | 14–24 h |
| Tileset pedra/praça | 6–10 h |
| Polish luz + partículas | 4–8 h |
| **Total** | **~42–70 h** |

---

## Arquivos de integração atualizados

- `scripts/world/world_graph_factory.gd`
- `resources/content/chapters/chapter_zero_bell_before_nightfall.tres`
- `scenes/areas/vertical_slice_street_art.tscn` (exit igreja)
- `scenes/areas/vertical_slice_underground.tscn` (retorno igreja)
- `scripts/world/world_map_graph_tests.gd`
- `scripts/tests/test_runner.gd`

Greybox original preservado: `vertical_slice_church.tscn` (inalterado).
