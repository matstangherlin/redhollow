# Red Hollow — Stabilization Gate Report

**Data:** 2026-07-11 (atualizado pós-commit beta foundation)  
**Commit baseline:** `e07ba0ecb8502d7a368017f1764599155e3e87bf` (`e07ba0e`)  
**Main scene:** `res://scenes/product/main_menu.tscn`  
**Gameplay scene:** `res://scenes/demo/vertical_slice_greybox.tscn`  
**Versão:** `0.2.0-beta.1`  
**Godot:** 4.7 stable

---

## Conclusão do gate (commit `e07ba0e`)

# REPROVADO PARA SHIP BETA — APROVADO PARA PRODUÇÃO DE CONTEÚDO COM RESTRIÇÕES

O commit consolida a **fundação beta** (menu, autoloads, content registry, Capítulo Zero provisório, inimigos greybox, feedback, export preset). Porém:

1. **Gate automatizado FAIL** — runner 18 suítes não passa com invocação `--script` (KI-005, P0).
2. **Playthrough manual** menu→fim **não assinado** (KI-004, P1).
3. **Build Windows** — preset/script existem; build **não aprovada** QA (KI-106).
4. **Morte/respawn** — melhoria parcial (auto-respawn); serviço unificado pendente (KI-001).
5. **Arena physics flush** — não corrigido; allowlist headless (KI-002).

**Produção de arte e level dressing** pode avançar em paralelo, desde que regressões sejam rastreadas após estabilização do runner.

---

## 1. Testes automatizados (estado no commit)

**Comando registrado:**

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

**Resultado no commit `e07ba0e`:**

| Métrica | Valor |
| --- | --- |
| Suítes registradas | **18** |
| Invocação subprocesso | `--script` (autoloads **não** disponíveis) |
| Gate | **FAIL** (exit code 1) |
| Suítes PASS (estimativa) | **~8** |
| Suítes FAIL (estimativa) | **~10** |

### Suítes registradas

| # | Suíte | Tendência no commit |
| --- | --- | --- |
| 1 | `vertical_slice_verification` | FAIL (autoload check / player deps) |
| 2 | `dialogue_tests` | FAIL |
| 3 | `save_tests` | PASS |
| 4 | `area_transition_tests` | FAIL |
| 5 | `combat_arena_tests` | FAIL |
| 6 | `cult_brawler_tests` | FAIL |
| 7 | `deacon_rusk_tests` | FAIL |
| 8 | `gameplay_lock_tests` | FAIL |
| 9 | `player_regression_tests` | FAIL |
| 10 | `vertical_slice_regression_tests` | PASS |
| 11 | `product_shell_tests` | FAIL |
| 12 | `narrative_chapter_zero_tests` | FAIL |
| 13 | `vermilite_gunslinger_tests` | PASS |
| 14 | `chain_penitent_tests` | PASS |
| 15 | `enemy_encounter_tests` | PASS |
| 16 | `player_visual_pipeline_tests` | PASS |
| 17 | `feedback_system_tests` | PASS |
| 18 | `content_registry_tests` | PASS |

**Causa raiz:** subprocessos `--script` não inicializam autoloads de `project.godot`. Suítes que montam `player.tscn` ou UI com globals falham.

**Meta de estabilização (próxima tarefa):** bootstrap `--main-scene`, 18/18 PASS, exit 0.

---

## 2. Warnings / errors permitidos (allowlist)

| Suíte | Tipo | Motivo |
| --- | --- | --- |
| `dialogue_tests` | WARNING | `missing_dialogue_id` injetado |
| `save_tests` | ERROR/WARNING | JSON corrompido / backup recovery injetado |
| `combat_arena_tests` | ERROR | Physics flush (`Can't change this state while flushing queries`) |

Válidos **somente** quando a suíte executa e declara allowlist. No gate FAIL atual, várias suítes nem chegam a concluir.

---

## 3. Auditoria por sistema (commit `e07ba0e`)

### Product shell

| Item | Estado |
| --- | --- |
| Main menu, opções, pausa, créditos, loading | Infra commitada — **manual pendente** |
| Autoloads settings/boot/input | OK em runtime normal (`--main-scene`) |
| Boot → greybox | Integrado — **não assinado** |

### Arquitetura conteúdo

| Item | Estado |
| --- | --- |
| `ContentRegistry` + manifests | OK — teste auto passa |
| Capítulo Zero data-driven | Conteúdo provisório — teste auto falha no runner atual |

### Player

| Item | Estado |
| --- | --- |
| Controllers (attack, defense, taunt, brand, …) | OK |
| `player.gd` coordenador | DEBT (~800 linhas) |
| Morte / respawn | Parcial — auto 0,65 s; serviço unificado P1 |

### Combate / inimigos

| Item | Estado |
| --- | --- |
| Cult Brawler, Rusk | OK greybox |
| Gunslinger, Chain Penitent | OK provisório — testes unitários passam |
| Arena | DEBT physics flush |

### Save

| Item | Estado |
| --- | --- |
| F8/F9, checkpoint, snapshot | OK — `save_tests` passa |
| Auto-load | **Off** intencional |

### Build Windows

| Etapa | Estado |
| --- | --- |
| Preset | Criado |
| Script `tools/build_windows.ps1` | Criado |
| Build gerada | Local possível; não no repo |
| Testada / aprovada | **Não** |

---

## 4. Teste manual (pendente)

Roteiro: `VERTICAL_SLICE_TEST_PLAN.md` + fluxo **menu → novo jogo → Capítulo Zero → conclusão → menu**.

| Área | Auto parcial | Manual |
| --- | --- | --- |
| Menu / boot | `product_shell_tests` (runner fail) | **Pendente** |
| Capítulo Zero completo | narrative + regression parcial | **Pendente** |
| Morte / respawn cenários 13–15 | death lock (runner fail) | **Pendente** |
| Build exportada smoke | — | **Pendente** |

---

## 5. Bugs classificados (resumo)

Ver `KNOWN_ISSUES.md`.

| ID | P | Título |
| --- | --- | --- |
| KI-005 | **P0** | Runner headless FAIL (18 suítes, `--script`) |
| KI-001 | P1 | Morte/respawn não consolidado (parcial) |
| KI-002 | P1 | Arena spawn physics flush |
| KI-004 | P1 | Playthrough manual pendente |
| KI-006 | P1 | Product shell não validado manualmente |
| KI-101–106 | P2 | Panic unlock, auto-load, acoplamentos, build |
| KI-201–203 | P3 | Nomenclatura, controle, warnings teste |

**KI-003 resolvido** — baseline commitada em `e07ba0e`.

---

## 6. Próximos passos (ordem)

1. Estabilizar runner — bootstrap + 18/18 PASS (P0).
2. Playthrough manual menu→fim + stress (P1).
3. Build Windows smoke após runner verde (P2).
4. P1 eng: respawn unificado; arena deferred spawn.
5. Produção arte Capítulo Zero em paralelo (restrições acima).

---

## 7. Assinaturas

| Papel | Status |
| --- | --- |
| Gate automatizado (commit `e07ba0e`) | **FAIL** |
| Gate manual | **PENDENTE** |
| Produção beta (arte/conteúdo) | **LIBERADA COM RESTRIÇÕES** |
| Ship beta pública | **BLOQUEADO** (P0 + P1 + build) |
