# Catacumbas Beta Completa — North Star (Capítulo Zero)

Transformação visual das catacumbas no pipeline North Star aprovado. Greybox original preservado em `vertical_slice_underground.tscn`.

**Data:** 2026-07-13

---

## Progressão visual (5 estágios)

| # | Zona | Faixa X | Leitura |
|---|------|---------|---------|
| 1 | Infraestrutura humana | 0–240 | Escoramento madeira, pedra de mina |
| 2 | Túneis da Ordem | 220–480 | Correntes, velas, símbolos |
| 3 | Ruínas antigas | 460–720 | Raízes, ossos discretos, glifos |
| 4 | Prisão de Mol-Khar | 700–960 | Vermilite na pedra, altar ritual |
| 5 | Manifestação espiritual | 940–1200 | Estátua colossal, arena Rusk, finale |

---

## Identidade

- Pedra, madeira de sustentação, túneis arqueados
- Vermilite integrada à pedra (veios + glow)
- Velas, correntes, altares, símbolos Ordem
- Vestígios discretos (ossos, sem gore explícito)
- Arquitetura pré-cidade (arco antigo parallax)
- Mol-Khar: sombra + vermelho interno — **sem forma completa**
- Palácio Rubro: **não revelado**

---

## Gameplay preservado

| Elemento | Posição |
|----------|---------|
| Checkpoint | x=220 |
| Pista parceiro (diário) | x=420 |
| Deacon Rusk + boss encounter | x=780, arena 60–1140 |
| Estátua olhos (`chapter_zero_statue_eyes`) | gameplay |
| Passagem oculta (`chapter_zero_hidden_passage`) | x=1080 |
| Exit igreja | x=40 |

---

## Deacon Rusk — cenário

- Piso arena marcado (60–1140)
- Posts de arena para leitura de mobilidade
- Iluminação Vermilite na câmara da prisão
- Espaço vertical livre para telegraphs
- HUD boss inalterado (shell existente)

---

## Encerramento beta (8 passos)

`chapter_zero_finale.gd` + hooks visuais em `Layer12_FinaleHooks`:

| Passo | Visual |
|-------|--------|
| 2 | `chapter_zero_finale_red_brand_glow` |
| 3 | Olhos estátua (`chapter_zero_statue_eyes`) |
| 4 | `chapter_zero_finale_mol_shadow` |
| 6 | `chapter_zero_finale_arcturus` |
| 7 | Passagem aberta + label |
| 8 | Overlay tela final beta |

---

## Assets novos

### Pipeline (código)

- `underground_north_star_layout.gd`
- `underground_north_star_variants.gd`
- `underground_north_star_factory.gd`
- `underground_beta_composer.gd`
- `underground_art_presentation.gd`
- `underground_art_area.gd`
- `chapter_zero_underground_theme_factory.gd`
- `chapter_zero_underground_profile.tres`
- `underground_beta_complete_tests.gd`

### Set pieces PNG

| Asset | Path |
|-------|------|
| Estátua colossal | `art/environments/chapter_zero/underground_colossal_statue.png` |
| Altar ritual | `art/environments/chapter_zero/underground_ritual_altar.png` |
| Passagem oculta | `art/environments/chapter_zero/underground_hidden_passage.png` |
| Sombra Mol-Khar | `art/environments/chapter_zero/underground_mol_shadow.png` |

### Kit modular (`underground_mod_*`)

timber, chain, candle, root, bone, vermilite, altar, colossal_statue, passage

### Reuso kit rua

Nenhum obrigatório — catacumbas usa kit próprio.

---

## Testes

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

Suítes: `underground_beta_complete_tests`, `beta_integration_smoke_tests`, `world_map_graph_tests`

### Checklist manual (beta completa)

- [ ] Rua → igreja → catacumbas (transições)
- [ ] Luta Deacon Rusk (fase 1 e 2)
- [ ] Morte / respawn / checkpoint F8/F9
- [ ] VFX combate + iluminação `'` (4 estados)
- [ ] Performance `P` ≥60 FPS
- [ ] Sequência finale 8 passos
- [ ] Retorno menu / overlay conclusão

---

## Estimativa arte final

| Fase | Horas |
|------|-------|
| Set pieces + kit PNG | 18–28 h |
| Finale VFX polish | 2–3 h |
| Deacon Rusk sheets | 4–5 h |
| Tileset pedra/catacumba | 6–10 h |
| **Total** | **~30–46 h** |

---

## Integração

- `WorldGraphFactory.SCENE_UNDERGROUND` → art scene
- `vertical_slice_church_art.tscn` exit → underground art
- `chapter_zero_bell_before_nightfall.tres` atualizado
- Escala contínua com rua/igreja (`ground_surface_y=876`)
