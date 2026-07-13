# Rua Beta Completa — North Star (Capítulo Zero)

Documento de entrega da transformação da rua inicial da beta no padrão North Star aprovado no gate da vertical slice.

**Escopo:** `vertical_slice_street_art.tscn` apenas. Igreja e catacumbas **não** alteradas.

**Data:** 2026-07-13

---

## Salas / distritos (9)

| # | Distrito | Faixa X | Conteúdo gameplay |
|---|----------|---------|-------------------|
| 1 | Entrada da cidade | 0–220 | Spawn default, placa `TownEntranceSign` |
| 2 | Encontro com Elias | 200–420 | NPC Elias, bark Calder |
| 3 | Saloon | 240–520 | Fachada saloon, `SaloonFacade` interact |
| 4 | Estátua e pista | 460–620 | `NightStatue`, coração Ordem |
| 5 | Segredo elevado | 520–760 | PlatformA, cartucho, bulletin, `SecretCache` |
| 6 | Rota opcional | 760–1180 | PlatformB/C, Gunslinger, atalho |
| 7 | Arena da rua | 1180–1520 | Cult Brawler, tutorial dodge/counter |
| 8 | Beco do duo | 1500–2080 | Duo gate + Brawler + Gunslinger |
| 9 | Saída para igreja | 2040–2400 | Medalhão parceiro, porta igreja, exit `cz_met_elias` |

---

## Assets

### Pipeline procedural (ativo)

| Sistema | Arquivo |
|---------|---------|
| Layout distritos | `scripts/visual/street_north_star_layout.gd` |
| Variações fachada | `scripts/visual/street_north_star_variants.gd` |
| Compositor beta | `scripts/visual/street_beta_composer.gd` |
| Factory North Star | `scripts/visual/street_north_star_factory.gd` |
| Apresentação 12 camadas | `scripts/visual/street_art_presentation.gd` |
| Ponte kit visual | `scripts/visual/street_kit_visual_bridge.gd` |

### Kit modular (slots PNG — drop-in)

| Módulo | Path esperado |
|--------|---------------|
| sign | `art/environments/chapter_zero/modules/street_mod_sign.png` |
| balcony | `street_mod_balcony.png` |
| door | `street_mod_door.png` |
| window | `street_mod_window.png` |
| barrel | `street_mod_barrel.png` |
| crate | `street_mod_crate.png` |
| fence | `street_mod_fence.png` |
| lantern | `street_mod_lantern.png` |
| wagon | `street_mod_wagon.png` |
| lamp_post | `street_mod_lamp_post.png` |

### Set pieces (slots existentes em presentation)

| Slot | Path esperado |
|------|---------------|
| Saloon | `art/environments/chapter_zero/street_saloon.png` |
| Closed building | `street_closed_building.png` |
| Wagon, barrels, fence, statue, signs, lamp | `street_*.png` |

### Gameplay aprovado (inalterado em lógica)

- Calder (pilot visual)
- Cult Brawler (visual completo)
- HUD V2 (`use_hud_v2`)
- `CombatFeedbackProfile` (6 perfis)
- `RegionVisualController` + `chapter_zero_street_profile.tres`
- Diálogos novos: `cz_street_entrance_sign`, `cz_saloon_facade`

---

## Variações implementadas

| Categoria | Implementação |
|-----------|---------------|
| Fachada | 4 paletas de parede (`StreetNorthStarVariants.wall_color_for_variant`) |
| Telhado | 3 silhuetas (platô, cume, meia-água) |
| Porta | 3 offsets horizontais |
| Janela | 2–3 posições por fachada; glow ou obturador |
| Varanda | Em fachadas variantes pares |
| Placa | Entrada, saloon, ordem (decal + kit sign) |
| Piso | Faixas de tint por distrito + tábuas alternadas |
| Detritos | Crate, barrel, debris decals, wagon |
| Iluminação | 4 lanternas distrito + perfil regional 4 estados |
| Props | 10 narrative decals + kit slots + factory props |

### Narrativa ambiental (temas)

| Tema | Elementos |
|------|-----------|
| Desaparecimentos | Poster `missing_poster`, aviso alley |
| Domínio Ordem | Chalk heart, estátua, sign_order, church candles |
| Mineração | Mine scar (parallax), mine_cart_wheel, mining office |
| Pobreza | Debris crate, closed shops, saloon fechado |
| Medo | Poster vermelho, duo warning |
| Resistência | Scratch resistance, Elias square |
| Vermilite | Splinter decal, heart symbol, accent light |
| Passagem parceiro | Boot tracks, cartucho, medallion |

---

## Testes

### Automáticos

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

Suíte nova: `street_beta_complete_tests` (5 asserts).

### Manuais (checklist)

- [ ] Navegação: spawn → igreja sem soft-lock
- [ ] Câmera: limites 0–2400, parallax sem jitter
- [ ] Combate: Brawler arena, Gunslinger opcional, duo gate
- [ ] Diálogo: Elias, entrada, saloon, estátua, cartucho, medalhão
- [ ] Segredo: plataforma elevada + cartucho + flag
- [ ] Objetivo: exit bloqueado até `cz_met_elias`
- [ ] Save F8 / load F9
- [ ] Respawn `fall_recovery_y`
- [ ] Mapa (se ativo na greybox shell)
- [ ] Performance ≥60 FPS Windows (medir — P0 gate G3)
- [ ] Gamepad: mover, atacar, esquiva, counter, interagir

---

## Estimativa de produção (arte final)

| Fase | Escopo | Tempo estimado |
|------|--------|----------------|
| **A — Bloqueio** | 9 distritos greybox validados (este entregável) | feito (código) |
| **B — Kit PNG** | 10 módulos × ~2–4 h | 20–40 h |
| **C — Set pieces** | Saloon, closed, wagon, statue, signs | 24–32 h |
| **D — Chão tile** | Primeiro tileset rua 16px (G8 gate) | 8–12 h |
| **E — Iluminação polish** | Light masks, vermilite bloom | 6–10 h |
| **F — QA playtest** | Form `PLAYTEST_VISUAL_FORM.md` | 4–6 h |

**Total arte final rua beta:** ~62–100 h (1 artista pixel, sem contar Calder/inimigos já aprovados).

**Total até jogável greybox North Star completo:** entrega atual (procedural + slots).

---

## Arquivos criados/modificados

| Arquivo | Ação |
|---------|------|
| `scripts/visual/street_north_star_layout.gd` | criado |
| `scripts/visual/street_north_star_variants.gd` | criado |
| `scripts/visual/street_kit_visual_bridge.gd` | criado |
| `scripts/visual/street_beta_composer.gd` | criado |
| `scripts/visual/street_beta_complete_tests.gd` | criado |
| `scripts/visual/street_art_presentation.gd` | modificado |
| `scripts/visual/street_north_star_factory.gd` | modificado |
| `scenes/areas/vertical_slice_street_art.tscn` | modificado |
| `data/dialogues/dialogues_pt_br.json` | modificado |
| `scripts/tests/test_runner.gd` | modificado |
| `docs/STREET_BETA_COMPLETE.md` | criado |
