# Red Hollow — Test Matrix

Matriz de testes manuais e headless. Roteiro greybox: [VERTICAL_SLICE_TEST_PLAN.md](VERTICAL_SLICE_TEST_PLAN.md). Runner: [HEADLESS_TESTING.md](HEADLESS_TESTING.md). Gate: [STABILIZATION_REPORT.md](STABILIZATION_REPORT.md).

## Legenda

| Resultado | Significado |
| --- | --- |
| **Pass** | Comportamento correto |
| **Fail** | Comportamento incorreto |
| **Blocked** | Erro impede teste |
| **Pending** | Não executado neste gate |
| **N/A** | Não aplicável |

## Gate de estabilização (2026-07-11)

### Automatizado

| Métrica | Resultado |
| --- | --- |
| Suítes | 11/11 **PASS** (meta pós-narrativa) |
| Exit code | **0** |
| Unexpected issues | **0** |
| Allowed issues | **45** |

| Suíte | Assertions | Allowed | Unexpected |
| --- | ---: | ---: | ---: |
| vertical_slice_verification | 6 | 0 | 0 |
| dialogue_tests | 3 | 2 | 0 |
| save_tests | 5 | 7 | 0 |
| area_transition_tests | 6 | 0 | 0 |
| combat_arena_tests | 7 | 36 | 0 |
| cult_brawler_tests | 4 | 0 | 0 |
| deacon_rusk_tests | 7 | 0 | 0 |
| gameplay_lock_tests | 10 | 0 | 0 |
| player_regression_tests | 48 | 0 | 0 |
| vertical_slice_regression_tests | 14 | 0 | 0 |
| narrative_chapter_zero_tests | 6 | 0 | 0 |
| vermilite_gunslinger_tests | 4 | 0 | 0 |
| chain_penitent_tests | 3 | 0 | 0 |
| player_visual_pipeline_tests | 5 | 0 | 0 |
| feedback_system_tests | 6 | 0 | 0 |
| product_shell_tests | — | — | — |

**Comando:**

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

Windows (Godot fora do PATH):

```powershell
& "C:\Path\To\Godot_v4.7-stable_win64.exe" --headless --path . --script res://scripts/tests/test_runner.gd
```

Após adicionar scripts com `class_name`:

```bash
godot --headless --path . --import
```

### Warnings / errors permitidos (allowlist)

| Suíte | Tipo | Qtd | Motivo |
| --- | --- | ---: | --- |
| dialogue_tests | WARNING | 2 | `missing_dialogue_id` injetado |
| save_tests | ERROR/WARNING | 7 | JSON corrompido / backup recovery injetado |
| combat_arena_tests | ERROR | 36 | Physics flush ao spawnar inimigos (`Can't change this state while flushing queries`) |

Estes **não** contam como falha de gate enquanto documentados. Meta futura: reduzir allowlist da arena a zero (KI-002).

### Manual — vertical slice (20 passos)

| # | Passo | Auto parcial | Gate manual |
| --- | --- | --- | --- |
| 1 | Rua — Elias, estátua, medalhão, brawler | regression + narrative | **Pending** |
| 2 | Objetivo HUD | narrative_chapter_zero_tests | **Pending** |
| 3 | Distrito igreja — arena, documento, Vermilite | regression nós | **Pending** |
| 4 | Barreira → catacumbas | area_transition | **Pending** |
| 5 | Checkpoint → diário parceiro | narrative flags | **Pending** |
| 6 | Deacon Rusk — intro `cz_deacon_intro` | deacon_rusk_tests | **Pending** |
| 7 | Finale 8 passos + passagem aberta | manual | **Pending** |
| 8 | Conclusão beta | completion controller | **Pending** |
| 13 | Morte pré-checkpoint | death lock auto | **Pending** |
| 14 | Morte pós-checkpoint | — | **Pending** |
| 15 | Morte no boss | — | **Pending** |
| 16 | Save (F8) | save_tests | **Pending** |
| 17 | Fechar jogo | — | **Pending** |
| 18 | Reabrir | auto_load=false | **Pending** |
| 19 | Load (F9) | save_tests | **Pending** |
| 20 | Reiniciar demo (F7) | regression parcial | **Pending** |

### Stress tests

| Cenário | Auto | Gate manual |
| --- | --- | --- |
| Spam ataque | combo/buffer parcial | **Pending** |
| Trocar direção durante ataque | parcial | **Pending** |
| Pausa durante hitstop | gameplay_lock_tests | **Pending** |
| Morrer durante hitstop | gameplay_lock_tests | **Pending** |
| Diálogo pós-combate | dialogue lock | **Pending** |
| Sair durante arena | — | **Pending** |
| Save em áreas diferentes | save_tests parcial | **Pending** |
| Load em área diferente | save_tests parcial | **Pending** |
| Barreira destruída + load | — | **Pending** |
| Boss derrotado + load | — | **Pending** |
| Reconectar controle | — | **N/A** |
| Alt-tab / foco janela | — | **Pending** |

## Estado dos sistemas

| Sistema | Estado | Notas |
| --- | --- | --- |
| Main scene greybox | Implementado | `vertical_slice_greybox.tscn` |
| `GameServices` | Implementado | Bind shell/área |
| Movimento / pulo | Implementado | Controllers |
| Combo / dodge / counter / taunt | Implementado | Controllers |
| Estilo + HUD | Implementado | HUD bind opcional |
| Red Brand + Breaker | Implementado | |
| Diálogo + interação | Implementado | Cooldown reopen 250 ms |
| 3 áreas + transição | Implementado | |
| Arena + Cult Brawler | Implementado | Physics flush allowlist |
| Barreira persistente | Implementado | |
| Checkpoint | Implementado | Auto-save ao ativar |
| Save/load manual | Implementado | **F8 / F9** + `PlayerStateSnapshot` |
| Auto-load ao boot | **Desativado** | `auto_load_on_ready = false` |
| Deacon Rusk + HUD chefe | Implementado | |
| Conclusão demo / Capítulo Zero | Implementado | Finale 8 passos + overlay |
| NarrativeDirector + objetivos | Implementado | JSON + HUD discreto |
| test_runner (11 suítes) | Implementado | Inclui `narrative_chapter_zero_tests` |
| Pixel art / mapa / diário UI | Planejado beta | |

## Comandos headless (portáveis)

Executar na **raiz do projeto**. Substituir `godot` pelo executável Godot 4.7 se necessário.

### Runner completo (recomendado)

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

### Suítes individuais

```bash
godot --headless --path . --script res://scripts/demo/vertical_slice_verification.gd
godot --headless --path . --script res://scripts/demo/vertical_slice_regression_tests.gd
godot --headless --path . --script res://scripts/dialogue/dialogue_tests.gd
godot --headless --path . --script res://scripts/save/save_tests.gd
godot --headless --path . --script res://scripts/world/area_transition_tests.gd
godot --headless --path . --script res://scripts/world/combat_arena_tests.gd
godot --headless --path . --script res://scripts/enemies/cult_brawler_tests.gd
godot --headless --path . --script res://scripts/enemies/deacon_rusk_tests.gd
godot --headless --path . --script res://scripts/player/player_regression_tests.gd
godot --headless --path . --script res://scripts/core/gameplay_lock_tests.gd
godot --headless --path . --script res://scripts/narrative/narrative_chapter_zero_tests.gd
godot --headless --path . --script res://scripts/product/product_shell_tests.gd
```

**Meta gate:** exit code `0`, zero issues **inesperados**. Allowed issues documentados acima.

## Demonstração vertical slice

| Área | Teste | Procedimento | Esperado |
| --- | --- | --- | --- |
| Demo | Main scene | Executar projeto | Greybox carrega |
| Demo | Fluxo completo | `VERTICAL_SLICE_TEST_PLAN.md` | 10–20 min |
| Demo | Reinício | **R** | Spawn/checkpoint |
| Demo | Voltar início | **F7** | Rua; progresso reset |
| Demo | Salvar | **F8** | `user://saves/` |
| Demo | Carregar | **F9** | Estado restaurado |
| Demo | Boot frio | Fechar e reabrir | **Não** auto-carrega |
| Demo | Conclusão | Derrotar Rusk | Finale Capítulo Zero + overlay beta |
| Demo | Panic | **Esc** | Destrava locks conhecidos |

## Matriz geral (resumo)

| Área | Teste | Estado |
| --- | --- | --- |
| Inicialização | Godot 4.7, main scene | Implementado |
| Movimento / pulo / câmera | A/D, espaço, limites | Implementado |
| Ataques / hitboxes | Combo J, fases | Implementado |
| Esquiva / counter | K / L | Implementado |
| Estilo / Red Brand | Variedade; U + barreira | Implementado |
| Diálogo | E com Elias | Implementado |
| Checkpoint + save | Subterrâneo; F8/F9 | Implementado |
| Transição áreas | Exits | Implementado |
| Arena | 2 brawlers | Implementado |
| Chefe | Deacon Rusk | Implementado |
| UI beta | Mapa, diário | Planejado |

## Checklist por tarefa

- arquivos criados/modificados;
- testes manual + headless aplicáveis;
- erros/warnings no console (classificar expected vs unexpected);
- collision layers/masks se alterados;
- sinais e referências verificados.

## Documentos relacionados

- `VERTICAL_SLICE_TEST_PLAN.md`, `BETA_DEMO_SCOPE.md`, `TECH_DEBT.md`, `KNOWN_ISSUES.md`, `STABILIZATION_REPORT.md`
