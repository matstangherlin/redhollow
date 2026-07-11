# Red Hollow — Roadmap

Roadmap alinhado ao repositório real (Godot 4.7, vertical slice greybox jogável, tag `greybox-vertical-slice-v0.1`) e à meta **Capítulo Zero — O Sino Antes do Anoitecer**.

**Branch de trabalho:** `beta-foundation`.

## Legenda

- ✅ Concluído
- 🔧 Concluído com dívida
- 🎯 Em andamento / próximo
- 📋 Planejado

---

## Histórico — fases concluídas (greybox técnico)

Registro das fases originais do protótipo. **Não remover** — marcam o que já foi entregue antes da estabilização beta.

| Fase | Entrega | Estado |
| --- | --- | --- |
| 0 | Base projeto, git, convenções | ✅ |
| 1 | Main scene + shell persistente | ✅ |
| 2–3 | Movimento, pulo, colisão, recuperação queda | ✅ |
| 4 | Estados do jogador | 🔧 |
| 5 | Combo + AttackData + hitbox/hurtbox | ✅ |
| 6 | Cult Brawler + dummies de teste | ✅ |
| 7 | Esquiva + counter | ✅ |
| 8 | Estilo + provocações | ✅ |
| 9 | Red Brand + barreira | ✅ |
| 10 | Exploração rua → igreja → sub | ✅ |
| 11 | Diálogo + checkpoint | ✅ |
| 12 | Save versionado F8/F9 (auto-load off) | 🔧 |
| 13 | Arena + Deacon Rusk + conclusão demo | ✅ |
| 14 | Documentação canônica inicial | ✅ |
| 15a | GameplayLockManager + testes regressão | 🔧 |

Detalhe jogável: `VERTICAL_SLICE_TEST_PLAN.md`, `CURRENT_IMPLEMENTATION.md`.

---

## Roadmap ativo (pós-tag greybox)

### 1. Estabilização 🎯

| # | Entrega | Gate |
| --- | --- | --- |
| S1 | Zero runtime errors inesperados nos testes headless | `test_runner.gd` |
| S2 | Fluxo morte/respawn consolidado | Sem softlock |
| S3 | Reduzir/remover panic unlock onde locks cobrem | `TECH_DEBT.md` P0 |
| S4 | Allowlist arena headless → fix produção | Deferred collision |

### 2. Refatoração 📋

| # | Entrega |
| --- | --- |
| R1 | Split `player.gd` (input, movimento, estado, apresentação, debug) |
| R2 | API pública save no player |
| R3 | Contratos rebinding troca de área |
| R4 | StyleManager desacoplado do HUD |

### 3. Produto (decisões beta) 🎯

| # | Entrega |
| --- | --- |
| P1 | Decisão auto-load save (`DECISIONS.md` D-013) |
| P2 | Critérios aceite beta formalizados |
| P3 | ~~Branch/scene beta vs greybox~~ → **ContentManifest** (`beta_demo` / `full_game`) ✅ |

### 3b. Arquitetura de conteúdo ✅

| # | Entrega |
| --- | --- |
| C0 | Resources: Chapter, Area, Manifest, Boss, Encounter, Objective, Event |
| C1 | Capítulo Zero registrado — compatível com beta e jogo final |
| C2 | Manifestos `beta_demo.tres` + `full_game.tres` |
| C3 | Gate centralizado (`ContentRegistry`) — sem `if demo` espalhado |
| C4 | Testes `content_registry_tests.gd` |

### 4. Conteúdo da beta 📋

Capítulo Zero — ver `BETA_DEMO_SCOPE.md`:

- rua, igreja, subterrâneo/catacumbas;
- Elias, 3 arquétipos inimigos, Deacon Rusk;
- estátua + aparição Mol-Khar, teaser Arcturus;
- pista parceiro antigo; gancho final;
- backtracking curto; uma habilidade Red Brand destacada.

### 5. Arte 📋

Pixel art Calder, ambientes Capítulo Zero, inimigos, Rusk, set pieces — `CONTENT_PRODUCTION_PLAN.md` fase C, `ART_BIBLE.md`.

### 6. Áudio 📋

SFX combate, ambiente por área, stingers chefe, placeholder → produção.

### 7. QA 📋

`TEST_MATRIX.md` completo; playtest externo; regressão antes de build.

### 8. Build 📋

Windows 60 FPS; pacote beta Capítulo Zero; instruções save manual ou auto conforme S/P.

### 9. Jogo final 📋

Ver `FINAL_GAME_SCOPE.md`:

- prólogo;
- arcos Silas Crow, Rosa La Serpiente, Magnus Vane, Arcturus Vale;
- Palácio Rubro;
- confronto Mol-Khar;
- finais ligados à Red Brand e escolhas de Calder.

---

## O que não está no roadmap imediato

- cidade inteira antes da beta;
- luta completa Arcturus / forma física completa Mol-Khar;
- crafting complexo / loot aleatório;
- duplicação manual de mapas corrompidos;
- magia elemental genérica.

## Marcos

| Marco | Critério |
| --- | --- |
| **Tag greybox v0.1** | ✅ `greybox-vertical-slice-v0.1` |
| **Beta pública** | Capítulo Zero 30–45 min, arte final áreas-chave |
| **Alpha distrito** | Múltiplas áreas interligadas pós-beta |
| **Jogo completo** | Barões, Palácio Rubro, finais |
