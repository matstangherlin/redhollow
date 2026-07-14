# Red Hollow — Technical Debt

Dívida técnica conhecida.  
**Baseline histórica greybox:** tag `greybox-vertical-slice-v0.1` (`ae65a5084c1cbece80672a67d4bc0a6b4d40e5df`).  
**Baseline beta foundation:** commit `e07ba0ecb8502d7a368017f1764599155e3e87bf` (`e07ba0e`).  
**Gate:** 2026-07-11 — ver `STABILIZATION_REPORT.md`, `KNOWN_ISSUES.md`.

Prioridade: **P0** bloqueia ship | **P1** antes de escalar/ship | **P2** manutenção | **P3** cosmético

---

## P0 — Bloqueadores

### Runner headless — 18 suítes FAIL com `--script` (KI-005)

- **Arquivos:** `scripts/tests/test_runner.gd`, suítes headless
- **Problema:** subprocessos `--script` não carregam autoloads; ~10/18 suítes falham.
- **Impacto:** gate CI/release beta **bloqueado**.
- **Direção:** bootstrap `--main-scene` + validação runtime autoloads; meta 18/18 PASS.

---

## P1 — Antes de escalar conteúdo / ship beta

### Morte/respawn parcial (KI-001)

- **Estado commit:** auto-respawn ~0,65 s + **R**; **sem** serviço unificado (overlay, boss reset, fluxo checkpoint).
- **Direção:** `PlayerRespawn` ou serviço na shell; playtest cenários 13–15.

### Playthrough manual pendente (KI-004)

- Menu → Capítulo Zero → conclusão não assinado.

### Product shell não validado (KI-006)

- Menu, opções, pausa, créditos existem; fluxo end-to-end **não** assinado.

### `player.gd` coordena demais

- ~800 linhas; combate extraído; restam locks, save, proxies, orquestração.

---

## P2 — Manutenção

| ID | Item |
| --- | --- |
| KI-101 | Panic unlock Esc |
| KI-102 | Auto-load off — D-013 **resolvida** (`BOOT_AND_SAVE_POLICY.md`) |
| KI-103 | `_player.call("_is_*")` residual |
| KI-104 | Hitstop via grupo |
| KI-105 | Debug overlay F |
| KI-106 | Build Windows não testada/aprovada |

Scripts médios: `deacon_rusk.gd`, `area_transition_manager.gd`, `vertical_slice_controller.gd`, `narrative_director.gd`.

---

## P3

- KI-201: cenas `*_test` vs `vertical_slice_*`
- KI-202: reconexão controle / foco
- KI-203: warnings injetados em testes (allowlist)

---

## Resolvido (commit `e07ba0e`)

| Item | Solução |
| --- | --- |
| Working tree não commitada (KI-003) | Commit `e07ba0e` |
| SaveManager paths internos | `PlayerStateSnapshot` |
| StyleManager HUD rígido | `bind_style_hud()` |
| AreaTransition rebinding | `GameServices` |
| Arena fail-safe silencioso | `arena_integrity_failed` |
| Monolito player ~1700 linhas | Controllers dedicados (~800 linhas restantes) |
| Menu/pausa “inexistentes” (doc) | Infra commitada; validação manual pendente |

## Resolvido localmente após `4f20f76` (sem commit)

| Item | Solução |
| --- | --- |
| Arena durante physics flush (KI-002) | FSM deferred, gates seguros, ownership explícito, reset de projéteis/inimigos, 22/22 testes de arena |
| Reset de arena/boss após morte | Retorna a `INACTIVE`, abre gates, oculta HUD do boss e exige saída antes da reentrada |

---

## Funcionalidades congeladas

Não alterar sem teste completo:

- combo, diálogo + cooldown 250 ms, transições 3 áreas, arena 2 brawlers, barreira, Rusk, F7/F8/F9, auto-load off.

---

## Ordem recomendada

1. P0: runner 18/18
2. P1: playthrough manual; respawn; arena deferred
3. P2: panic unlock, build smoke, hitstop via serviço
4. Arte/conteúdo em paralelo (restrições acima)

Ver `ARCHITECTURE.md`, `CONTENT_PRODUCTION_PLAN.md`, `DECISIONS.md`.
