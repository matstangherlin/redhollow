# Red Hollow — Beta Demo Scope

**Nome:** Capítulo Zero — O Sino Antes do Anoitecer  
**Versão alvo:** `0.2.0-beta.1`  
**Duração alvo:** 30–45 minutos  
**Plataforma inicial:** Windows, 60 FPS  
**Baseline commit:** `e07ba0ecb8502d7a368017f1764599155e3e87bf`

## Objetivo

Validar núcleo jogável, narrativa, combate, exploração curta e identidade visual — **sem** escopo de jogo completo.

**Entry point:** `res://scenes/product/main_menu.tscn`  
**Sessão de gameplay:** `res://scenes/demo/vertical_slice_greybox.tscn` (via boot)

---

## Estado por camada (commit `e07ba0e`)

| Camada | Estado | Nota |
| --- | --- | --- |
| Infraestrutura product shell | Criada | Menu, opções, pausa, créditos, loading — **fluxo não assinado manualmente** |
| Integração boot → greybox | Commitada | `GameBootState` + manifest `beta_demo` |
| Conteúdo Capítulo Zero | Provisório | JSON, diálogos `cz_*`, finale 8 passos |
| Inimigos beta (3 arquétipos) | Provisório greybox | Gunslinger + Chain + Brawler existem; **balance/arte final pendentes** |
| Arte final | Não produzida | Pipeline visual pronto; sprites finais pendentes |
| UI beta (mapa/diário skin) | Parcial | HUD objetivo provisório; mapa/diário finais pendentes |
| Testes auto gate | **FAIL** | 18 suítes; ~8 PASS no runner `--script` |
| Build Windows | Preset + script | Build **não aprovada** QA |

---

## Conteúdo pretendido

### Áreas

| Área | Função | Commit |
| --- | --- | --- |
| Rua | Chegada, Elias, primeiro combate | Greybox OK |
| Distrito igreja | Arena, cristal, barreira | Greybox OK |
| Interior / subterrâneo | Descida | Greybox OK |
| Catacumbas | Checkpoint, Rusk | Greybox OK |

### Personagens

- **Calder Knox** — jogável (controllers + pipeline visual provisório)
- **Elias** — NPC (greybox)
- **Deacon Rusk** — mini-chefe (greybox)

### Inimigos

| Inimigo | Estado commit | Arte/balance |
| --- | --- | --- |
| Cult Brawler | Integração OK | Provisório |
| Vermilite Gunslinger | Infra + encontros | Provisório |
| Chain Penitent | Infra + encontros | Provisório |
| Deacon Rusk | Integração OK | Provisório |

### Narrativa e set pieces

| Item | Estado |
| --- | --- |
| Diálogo Elias + IDs `cz_*` | Conteúdo provisório commitado |
| Objetivos / eventos JSON | Conteúdo provisório |
| Props (medalhão, diário, documento) | Infra commitada |
| Estátua / Mol-Khar / Arcturus (finale) | Conteúdo provisório — **playtest pendente** |
| Barreira Vermilite | Integração OK |
| Corrupção ambiental (Ressonância Rubra) | Planejado — validação pendente |

### Interface

| UI | Estado commit |
| --- | --- |
| HUD vida + Red Brand + estilo | Integração OK — skin final pendente |
| Objetivos (ObjectiveHud) | Provisório |
| Menu / opções / pausa / créditos | Infra criada — **não prova UX completa** |
| Mapa / diário finais | Planejado |
| Red Brand screen (≤3 habilidades) | Planejado |

---

## Sistemas reutilizados (greybox → beta)

| Sistema | Estado | Validação |
| --- | --- | --- |
| Movimento, combo, esquiva, counter, taunt | OK | Runner fail (player suites) |
| Red Brand + Breaker | OK | Idem |
| 3 áreas + transição | OK | Runner fail |
| Save F8/F9 + checkpoint | OK | `save_tests` PASS |
| Auto-load boot | **Off** | Intencional — D-013 |
| ContentRegistry | OK | `content_registry_tests` PASS |
| Feedback combate | OK | `feedback_system_tests` PASS |

---

## Build Windows (escopo separado)

| Etapa | Beta ship requer |
| --- | --- |
| `export_presets.cfg` | Criado ✅ |
| `tools/build_windows.ps1` | Criado ✅ |
| Build `.exe` gerada | Pendente smoke |
| Build jogada QA | **Obrigatório antes de ship** |
| Build aprovada | **Não** no commit atual |

---

## A beta **não** deve revelar

Arcturus completo, Palácio Rubro, Mol-Khar completo, todos barões, final principal.

---

## Critérios de aceite (ainda abertos)

- [ ] Fluxo 30–45 min jogador novo (manual).
- [ ] Menu → novo jogo → conclusão → menu (manual).
- [ ] Três inimigos + Rusk com arte legível.
- [ ] HUD/menus conforme `UI_BIBLE.md`.
- [ ] Sequência corrupção ambiental perceptível.
- [ ] Save/load estável após checkpoint.
- [ ] Nenhum softlock conhecido no roteiro.
- [ ] `test_runner.gd` **18/18 PASS**, exit 0.
- [ ] Build Windows smoke + playtest assinado.

---

## Relação com demo técnica

A greybox **permanece** núcleo de gameplay. O commit `e07ba0e` adiciona **product shell**, **content registry** e **camada narrativa Capítulo Zero provisória**. A beta substitui arte, expande UI e valida roteiro — **sem** reescrever combate do zero.

Ver `CURRENT_IMPLEMENTATION.md`, `CONTENT_PRODUCTION_PLAN.md`, `KNOWN_ISSUES.md`.
