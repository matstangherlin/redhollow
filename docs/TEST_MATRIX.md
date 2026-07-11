# Red Hollow — Test Matrix

Matriz de testes manuais e headless. Roteiro greybox: [VERTICAL_SLICE_TEST_PLAN.md](VERTICAL_SLICE_TEST_PLAN.md). Runner: [HEADLESS_TESTING.md](HEADLESS_TESTING.md).

## Legenda

| Resultado | Significado |
| --- | --- |
| **Pass** | Comportamento correto |
| **Fail** | Comportamento incorreto |
| **Blocked** | Erro impede teste |
| **N/A** | Não aplicável |

## Estado dos sistemas

| Sistema | Estado | Notas |
| --- | --- | --- |
| Main scene greybox | Implementado | `vertical_slice_greybox.tscn` |
| Movimento / pulo | Implementado | |
| Combo / dodge / counter / taunt | Implementado | |
| Estilo + HUD | Implementado | |
| Red Brand + Breaker | Implementado | |
| Diálogo + interação | Implementado | Cooldown reopen 250 ms |
| 3 áreas + transição | Implementado | |
| Arena + Cult Brawler | Implementado | |
| Barreira persistente | Implementado | |
| Checkpoint | Implementado | Auto-save ao ativar |
| Save/load manual | Implementado | **F8 / F9** |
| Auto-load ao boot | **Desativado** | `auto_load_on_ready = false` |
| Deacon Rusk + HUD chefe | Implementado | |
| Conclusão demo | Implementado | |
| GameplayLockManager | Implementado | Testes dedicados |
| test_runner (10 suítes) | Implementado | |
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
```

**Meta:** exit code `0` e zero issues inesperados no console (`TECH_DEBT.md` P0). Arena headless ainda declara erros **permitidos** até fix de colisão deferred.

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
| Demo | Conclusão | Derrotar Rusk | Overlay conclusão |
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
- erros/warnings no console;
- collision layers/masks se alterados;
- sinais e referências verificados.

## Documentos relacionados

- `VERTICAL_SLICE_TEST_PLAN.md`, `BETA_DEMO_SCOPE.md`, `TECH_DEBT.md`
