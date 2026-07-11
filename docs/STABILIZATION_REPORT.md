# Red Hollow — Stabilization Gate Report

**Data:** 2026-07-11  
**Branch / commit base:** `main` @ `1c8e89d` (+ working tree local não commitada)  
**Main scene:** `res://scenes/demo/vertical_slice_greybox.tscn`  
**Godot:** 4.7 stable  
**Escopo:** Gate formal pós-refatoração (controllers player, `GameServices`, contratos save/área/estilo)

---

## Conclusão do gate

# APROVADO COM RESTRIÇÕES

O MVP técnico está **seguro para iniciar produção de conteúdo da beta** (arte, level dressing, diálogo final), desde que:

1. A refatoração local seja **commitada e taggeada** antes de virar baseline da equipe (KI-003).
2. Um **playthrough manual completo** (20 passos + stress) seja assinado por humano (KI-004).
3. **KI-001** (morte/respawn) e **KI-002** (arena physics) sejam resolvidos antes do **ship** da beta pública, não necessariamente antes de artes paralelas.

**Não há P0 confirmado** pelo gate automatizado. Por isso não se aplica “REPROVADO”. Restrições impedem “APROVADO” pleno sem ressalvas.

---

## 1. Testes automatizados

**Comando:**

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

**Resultado (2026-07-11):**

| Métrica | Valor |
| --- | --- |
| Suítes | 10 |
| Suítes PASS | **10** |
| Exit code | **0** |
| Unexpected issues | **0** |
| Allowed issues | 45 |
| Tempo | ~17.5 s |

| Suíte | Tests | Assertions | Unexpected |
| --- | ---: | ---: | ---: |
| vertical_slice_verification | 6 | 6 | 0 |
| dialogue_tests | 3 | 3 | 0 |
| save_tests | 5 | 5 | 0 |
| area_transition_tests | 6 | 6 | 0 |
| combat_arena_tests | 7 | 7 | 0 |
| cult_brawler_tests | 4 | 4 | 0 |
| deacon_rusk_tests | 7 | 7 | 0 |
| gameplay_lock_tests | 10 | 10 | 0 |
| player_regression_tests | 48 | 48 | 0 |
| vertical_slice_regression_tests | 13 | 13 | 0 |

**Critérios atendidos:**

- Exit code 0
- Zero script errors inesperados
- Zero runtime errors inesperados (parser monitor)
- Zero referências inválidas reportadas
- Zero nós obrigatórios ausentes (`player_regression_tests` scene contract)
- Zero `get_tree` nulos inesperados

---

## 2. Warnings / errors permitidos (documentados)

| Origem | Tipo | Quantidade | Motivo |
| --- | --- | ---: | --- |
| `dialogue_tests` | WARNING | 2 | ID `missing_dialogue_id` injetado |
| `save_tests` | ERROR/WARNING | 7 | JSON corrompido / backup recovery injetado |
| `combat_arena_tests` | ERROR | 36 | Physics flush ao spawnar inimigos em SceneTree isolado |

Nenhum destes conta como falha de gate (allowlist explícita nas suítes).

---

## 3. Auditoria por sistema

### Arquitetura

| Item | Estado pós-refatoração |
| --- | --- |
| Shell greybox | OK — `game.gd` + filhos persistentes |
| `GameServices` | OK — referências tipadas, bind área |
| `AreaTransitionManager` | OK — sinais `area_loaded` / `area_unloaded` |
| Troca de áreas | OK — headless 6/6 |
| Autoloads gameplay | Nenhum (intencional) |

### Player (~1057 linhas coordenador)

| Controller | Linhas | Responsabilidade |
| --- | ---: | --- |
| `PlayerInputController` | — | Entrada, buffers |
| `PlayerMovementController` | — | Física, coyote, recovery |
| `PlayerAttackController` | 332 | Combo, hitbox, counter ofensivo |
| `PlayerDefenseController` | 390 | Esquiva, counter defensivo |
| `PlayerTauntController` | 207 | Provocação |
| `PlayerRedBrandController` | 241 | Brand breaker |
| `PlayerStateCoordinator` | — | Estados alto nível |
| `PlayerPresentationController` | — | Cores provisórias |
| `PlayerDebugView` | — | Overlay F |

**Contratos:** `PLAYER_BEHAVIOR_CONTRACT.md`, `PLAYER_PUBLIC_API.md`, 48 casos regression.

### Locks

- `GameplayLockManager` + tokens: OK (10 testes)
- Diálogo, transição, morte, loading: cobertos em regression
- Panic Esc: DEBT (P2) — escape hatch ativo

### Hitstop

- Não altera `Engine.time_scale`; OK
- Counter, brand, barreira, hitbox: request via grupo
- Testes: `gameplay_lock_tests` (pause/death during hitstop), `player_regression_tests` hitstop contract

### Morte / respawn

- Morte → lock DEATH + `interrupt_attack(DEAD)`: OK (auto)
- Respawn unificado: **P1** — sem serviço dedicado (KI-001)
- Recuperação queda (`recover_if_out_of_arena`): OK (auto)
- R / F7 / F9: contrato verificado em `vertical_slice_regression_tests`

### Save

- `export_save_state` / `import_save_state` + `PlayerStateSnapshot`: OK
- F8/F9, backup, JSON inválido: OK (save_tests)
- Auto-load boot: desativado (intencional)

### Transições

- 3 áreas vertical slice: OK (area_transition_tests + regression)
- Rebind via `GameServices`: OK

### Diálogo

- Controller + cooldown 250 ms: OK
- Lock input: OK (regression)

### Arenas / chefe

- Arena 2 brawlers: OK (combat_arena_tests)
- Integridade despawn: OK (`arena_integrity_failed`)
- Deacon Rusk: OK (deacon_rusk_tests 7/7)
- Boss HUD bind tipado: OK

### Red Brand / estilo / HUD

- Brand regression: 5 casos OK
- StyleManager bind opcional HUD: OK
- Taunt/contexto combate: OK

### Debug

- F toggle, F7 reset, label debug: OK (DEBT P2 para release)

---

## 4. Teste manual completo (20 passos)

**Status deste gate:** NÃO EXECUTADO por agente (requer runtime interativo).

| # | Passo | Auto parcial | Manual |
| --- | --- | --- | --- |
| 1 | Rua | regression nós | **Pendente** |
| 2 | Elias | dialogue_tests | **Pendente** |
| 3 | Plataformas | fall_recovery auto | **Pendente** |
| 4 | Cult Brawler rua | cult_brawler_tests | **Pendente** |
| 5 | Igreja | area_transition | **Pendente** |
| 6 | Arena | combat_arena_tests | **Pendente** |
| 7 | Red Brand | brand regression | **Pendente** |
| 8 | Barreira | barrier registry save | **Pendente** |
| 9 | Subterrâneo | underground nodes | **Pendente** |
| 10 | Checkpoint | checkpoint contract | **Pendente** |
| 11 | Deacon Rusk | deacon_rusk_tests | **Pendente** |
| 12 | Conclusão | completion controller | **Pendente** |
| 13 | Morte pré-checkpoint | death lock auto | **Pendente** |
| 14 | Morte pós-checkpoint | — | **Pendente** |
| 15 | Morte no boss | — | **Pendente** |
| 16–20 | Save/load/reboot/demo | save_tests parcial | **Pendente** |

**Roteiro:** `VERTICAL_SLICE_TEST_PLAN.md`

---

## 5. Stress tests

| Cenário | Cobertura automatizada | Manual |
| --- | --- | --- |
| Spam ataque | combo chain/buffer tests | Pendente |
| Trocar direção durante ataque | parcial (movement) | Pendente |
| Pausa durante hitstop | gameplay_lock_tests | Pendente |
| Morrer durante hitstop | gameplay_lock_tests | Pendente |
| Diálogo pós-combate | dialogue lock tests | Pendente |
| Sair durante arena | — | Pendente |
| Save em áreas diferentes | save_tests parcial | Pendente |
| Load área diferente | save_tests parcial | Pendente |
| Barreira destruída + load | — | Pendente |
| Boss derrotado + load | — | Pendente |
| Reconectar controle | N/A | N/A |
| Alt-tab / foco | N/A | Pendente |

---

## 6. Bugs classificados (resumo)

Ver `KNOWN_ISSUES.md` para detalhes.

| ID | P | Título |
| --- | --- | --- |
| KI-001 | P1 | Morte/respawn não consolidado |
| KI-002 | P1 | Arena spawn durante physics flush |
| KI-003 | P1 | Refatoração não commitada |
| KI-004 | P1 | Playthrough manual pendente |
| KI-101 | P2 | Panic unlock Esc |
| KI-102 | P2 | Auto-load desativado |
| KI-103 | P2 | `_player.call` residual nos controllers |
| KI-104 | P2 | Hitstop via grupo |
| KI-105 | P2 | Debug overlay |
| KI-201–203 | P3 | Nomenclatura, controle, warnings de teste |

---

## 7. Arquivos modificados no working tree (não commitados)

Inclui refatorações pós-`1c8e89d`: controllers player, `GameServices`, `PlayerStateSnapshot`, acoplamentos save/área/estilo/arena/boss, cenas `game.tscn` / `vertical_slice_greybox.tscn` / `player.tscn`.

---

## 8. Próximos passos recomendados

1. Commit + tag `stabilization-gate-2026-07-11` (ou similar).
2. Playthrough manual + stress (1 sessão, ~30–45 min).
3. P1: `PlayerRespawn` ou equivalente; arena spawn deferred.
4. Iniciar produção beta (arte Capítulo Zero) em paralelo com P1 eng.
5. Antes de beta pública: resolver KI-001/002, decisão auto-load, remover panic unlock de builds release.

---

## 9. Assinaturas

| Papel | Status |
| --- | --- |
| Gate automatizado | **PASS** (agente, 2026-07-11) |
| Gate manual | **PENDENTE** |
| Produção beta | **LIBERADA COM RESTRIÇÕES** |
