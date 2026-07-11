# Red Hollow — Test Matrix

Matriz de testes manuais e headless. Para roteiro passo a passo da demo greybox, use [VERTICAL_SLICE_TEST_PLAN.md](VERTICAL_SLICE_TEST_PLAN.md).

## Legenda

| Resultado | Significado |
| --- | --- |
| **Pass** | Comportamento correto |
| **Fail** | Comportamento incorreto |
| **Blocked** | Sistema ausente ou erro impede teste |
| **N/A** | Não aplicável na etapa |

## Estado dos sistemas (repositório atual)

| Sistema | Estado | Notas |
| --- | --- | --- |
| Main scene greybox | Implementado | `vertical_slice_greybox.tscn` |
| Movimento / pulo | Implementado | |
| Combo / dodge / counter / taunt | Implementado | |
| Estilo + HUD | Implementado | |
| Red Brand + Breaker | Implementado | |
| Diálogo | Implementado | Cooldown reopen 250 ms |
| Áreas (3) | Implementado | street → church → underground |
| Arena | Implementado | |
| Barreira persistente | Implementado | Registry + save |
| Checkpoint | Implementado | Auto-save ao ativar |
| Save/load | Implementado | **Manual:** F8 / F9 |
| Auto-load ao boot | Desativado | `auto_load_on_ready = false` na greybox |
| Deacon Rusk | Implementado | |
| Conclusão demo | Implementado | Overlay + flag |
| Pixel art final | Planejado beta | |
| Mapa / diário UI | Planejado beta | |

## Comandos headless (portáveis)

Executar na raiz do projeto. Substituir `godot` pelo executável da Godot 4.7 no PATH, se necessário.

```bash
godot --headless --path . --script res://scripts/demo/vertical_slice_verification.gd
godot --headless --path . --script res://scripts/dialogue/dialogue_tests.gd
godot --headless --path . --script res://scripts/save/save_tests.gd
godot --headless --path . --script res://scripts/world/area_transition_tests.gd
godot --headless --path . --script res://scripts/world/combat_arena_tests.gd
godot --headless --path . --script res://scripts/enemies/cult_brawler_tests.gd
godot --headless --path . --script res://scripts/enemies/deacon_rusk_tests.gd
```

**Nota:** algumas suítes passam com warnings/erros de runtime em fixtures incompletas — tratar como dívida (`TECH_DEBT.md`). Meta: zero erros no console.

## Demonstração vertical slice (greybox)

| Área | Teste | Procedimento | Resultado esperado |
| --- | --- | --- | --- |
| Demo | Main scene | Executar projeto | Carrega `vertical_slice_greybox.tscn` |
| Demo | Fluxo completo | `VERTICAL_SLICE_TEST_PLAN.md` | Marcos em 10–20 min |
| Demo | Reinício | **R** | Retorna spawn/checkpoint sem softlock |
| Demo | Voltar ao início | **F7** | Rua inicial; progresso resetado |
| Demo | Salvar | **F8** | Arquivo em `user://saves/` |
| Demo | Carregar | **F9** | Estado restaurado (não auto no boot) |
| Demo | Conclusão | Derrotar Deacon Rusk | Overlay de demonstração concluída |
| Demo | Verificação headless | `vertical_slice_verification.gd` | Mensagem de sucesso |
| Demo | Panic recovery | **Esc** | Destrava diálogo/locks se travado |

## Matriz geral

| Área | Teste | Procedimento | Resultado esperado | Estado |
| --- | --- | --- | --- | --- |
| Inicialização | Abrir projeto | Godot 4.7 | Sem erros críticos | Implementado |
| Inicialização | Main scene | Executar | Greybox carrega | Implementado |
| Inicialização | `.godot/` | `git status --ignored` | Ignorada | Implementado |
| Inicialização | FPS | Sala simples Windows | ~60 FPS | Implementado |
| Movimento | Direita/esquerda | A/D | Plano 2D lateral | Implementado |
| Movimento | Parada | Soltar direcional | Desacelera previsível | Implementado |
| Movimento | Virada | Alternar direção | Hitbox/orientação corretas | Implementado |
| Colisão | Piso / parede | Plataformas | Sem atravessar | Implementado |
| Pulo | Chão / queda | Espaço | Pulo e pouso | Implementado |
| Câmera | Seguimento / limites | Extremos da área | Limites respeitados | Implementado |
| Câmera | Troca de área | Exit entre áreas | Limites atualizados | Implementado |
| Ataques | Combo | J | Três golpes encadeáveis | Implementado |
| Ataques | Startup / recovery | Observar fases | Dano só na janela ativa | Implementado |
| Hitboxes | Separação | Inspecionar cena | Hitbox ≠ hurtbox | Implementado |
| Hitboxes | Acerto único | Um swing | Sem multi-hit acidental | Implementado |
| Hitboxes | Hitstop | Acertar inimigo | Feedback sem softlock | Implementado-debt |
| Esquiva | K | Durante ataque inimigo | I-frames na janela | Implementado |
| Counter | L | Telegraph amarelo | Counter em ataques counterable | Implementado |
| Estilo | Variedade / repetição | Combo + repetição | Sobe com variedade; penaliza spam | Implementado |
| Red Brand | U (segurar/soltar) | Após cristal | Breaker destrói barreira | Implementado |
| Red Brand | Restrições | — | Sem magia/voo/projétil | Implementado |
| Diálogo | E com Elias | Avançar e sair | Controles liberados | Implementado |
| Diálogo | Reabertura | Fechar e mover | Não reabre no mesmo frame | Implementado |
| Checkpoint | E no subterrâneo | Ativar | Visual ativo + save | Implementado |
| Salvamento | F8 / F9 | Salvar e recarregar | Área, barreira, chefe consistentes | Implementado |
| Salvamento | Corrompido | Arquivo inválido | Fallback sem crash | Implementado |
| Salvamento | Boot | Iniciar jogo frio | **Não** auto-carrega na greybox | Por design atual |
| Troca de áreas | Exits | Rua ↔ igreja ↔ sub | Spawn correto | Implementado |
| Arena | Ativação | Zona igreja | Portas fecham; 2 inimigos | Implementado |
| Arena | Conclusão | Derrotar todos | Portas abrem; flag set | Implementado |
| Chefe | Deacon Rusk | Zona subterrâneo | HUD, fase 2, vitória | Implementado |
| UI beta | Mapa / diário | — | — | Planejado |
| Arte final | Pixel art | — | — | Planejado beta |

## Checklist por tarefa

Depois de cada alteração de jogo, registrar:

- arquivos criados e modificados;
- testes executados (manual + headless aplicáveis);
- erros no console (incluir warnings em testes);
- se a Godot foi executada pelo terminal;
- se collision layers/masks mudaram;
- se sinais e referências foram verificados.

## Documentos relacionados

- `VERTICAL_SLICE_TEST_PLAN.md` — roteiro jogável
- `BETA_DEMO_SCOPE.md` — critérios da beta
- `TECH_DEBT.md` — falhas conhecidas de teste e runtime
