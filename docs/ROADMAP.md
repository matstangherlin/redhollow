# Red Hollow — Roadmap

Roadmap alinhado ao repositório no commit **`e07ba0e`** (Godot 4.7, beta foundation).  
**Meta:** Capítulo Zero — O Sino Antes do Anoitecer (`0.2.0-beta.1`).

## Legenda

- ✅ Concluído
- 🔧 Concluído com dívida
- 🎯 Em andamento / próximo
- 📋 Planejado

---

## Histórico — greybox técnico (tag `greybox-vertical-slice-v0.1`)

| Fase | Entrega | Estado |
| --- | --- | --- |
| 0–15a | Movimento, combate, 3 áreas, save, arena, Rusk, locks, testes | ✅ / 🔧 |

Detalhe: `VERTICAL_SLICE_TEST_PLAN.md`, tag `ae65a508`.

---

## Entregue no commit `e07ba0e` ✅ / 🔧

| # | Entrega | Estado |
| --- | --- | --- |
| B0 | Product shell (menu, opções, pausa, créditos, loading) | 🔧 infra — manual pendente |
| B1 | Autoloads settings/boot/input | ✅ |
| B2 | ContentManifest + ContentRegistry + manifests | ✅ |
| B3 | Capítulo Zero data-driven (JSON, stubs, director) | 🔧 conteúdo provisório |
| B4 | Inimigos Gunslinger + Chain Penitent + projétil | 🔧 greybox |
| B5 | FeedbackSystem + áudio placeholder | 🔧 |
| B6 | Pipeline visual Calder (placeholder/pilot) | 🔧 |
| B7 | Player controllers (attack, defense, taunt, brand) | 🔧 |
| B8 | Export preset Windows + `build_windows.ps1` | 🔧 preset/script; build não aprovada |
| B9 | test_runner **18 suítes** | 🔧 gate FAIL (KI-005) |
| B10 | Auto-respawn parcial (~0,65 s) | 🔧 KI-001 |

---

## Roadmap ativo

### 1. Estabilização 🎯 (bloqueia ship)

| # | Entrega | Gate |
| --- | --- | --- |
| S1 | Runner 18/18 PASS (bootstrap autoloads) | exit 0 |
| S2 | Playthrough manual menu→fim | KI-004 |
| S3 | Build Windows smoke | KI-106 |
| S4 | Morte/respawn consolidado | KI-001 |
| S5 | Arena spawn deferred | KI-002 |

### 2. Produto beta 📋

| # | Entrega |
| --- | --- |
| P1 | Decisão auto-load (D-013) |
| P2 | Critérios aceite beta formalizados |
| P3 | Validar pausa/HUD/mapa/diário finais |

### 3. Conteúdo Capítulo Zero 📋

Ver `BETA_DEMO_SCOPE.md` — arte final, balanceamento, set pieces Mol-Khar/Arcturus.

### 4. Arte 📋

Pixel art Calder, ambientes, inimigos, Rusk — `CONTENT_PRODUCTION_PLAN.md` fase C.

### 5. Áudio 📋

Placeholder → produção licenciada.

### 6. QA / ship 📋

Runner verde + playtest + build aprovada.

### 7. Jogo final 📋

`FINAL_GAME_SCOPE.md` — barões, Palácio Rubro, Mol-Khar completo.

---

## Marcos

| Marco | Critério | Estado |
| --- | --- | --- |
| Tag greybox v0.1 | Demo técnica | ✅ |
| Commit beta foundation | `e07ba0e` | ✅ |
| Gate auto 18/18 | Runner PASS | 🎯 |
| Beta pública | 30–45 min, arte áreas-chave, QA | 📋 |
| Jogo completo | Escopo final | 📋 |

---

## Fora do roadmap imediato

Cidade inteira, Arcturus/Mol-Khar completos, magia elemental genérica, auto-load sem decisão D-013.
