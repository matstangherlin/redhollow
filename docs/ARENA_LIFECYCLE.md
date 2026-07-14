# Red Hollow — ciclo de vida das arenas

Contrato vigente na working tree baseada em `4f20f76e5f505f36eacdb9866d7d7e33404c15f3`. A implementação cobre a arena comum da igreja e o encontro de Deacon Rusk. A rua continua sendo um encontro aberto, sem redesenho ou conversão artificial para arena fechada.

## Objetivos

- nenhuma alteração de colisão ou de árvore durante physics flush;
- uma solicitação de ativação produz no máximo um encontro;
- roster e projéteis são descartados de modo determinístico no reset;
- somente inimigos explicitamente pertencentes ao controlador contam;
- morte, reload e troca de área nunca deixam gates ou HUD presos;
- conclusão e contagem de mortes são idempotentes;
- panic unlock permanece ferramenta de QA, não etapa do fluxo normal.

## Estados

```text
INACTIVE
  -> ACTIVATION_REQUESTED
  -> CLOSING_GATES
  -> SPAWNING
  -> ACTIVE
  -> COMPLETED

ACTIVATION_REQUESTED | CLOSING_GATES | SPAWNING | ACTIVE
  -> RESETTING
  -> INACTIVE
```

| Estado | Gates/exits | Roster | Aceita ativação |
| --- | --- | --- | --- |
| `INACTIVE` | abertos | vazio/boss dormente | sim, salvo trava de reentrada |
| `ACTIVATION_REQUESTED` | abertos | inalterado | não |
| `CLOSING_GATES` | fechamento solicitado deferred | inalterado | não |
| `SPAWNING` | fechados | criação segura em idle | não |
| `ACTIVE` | fechados | rastreado | não |
| `RESETTING` | abertos | descarte deferred | não |
| `COMPLETED` | abertos | encerrado | não |

## Fronteira de física

`body_entered` chama somente `request_activation(body)`. Essa chamada valida Calder, muda o estado lógico para `ACTIVATION_REQUESTED`, desarma o monitor e agenda a continuação.

A continuação segue esta ordem:

1. aguarda `physics_frame`;
2. entra em `CLOSING_GATES` por `call_deferred`;
3. aguarda outra `physics_frame`;
4. entra em `SPAWNING` por `call_deferred`;
5. adiciona o roster ou ativa o boss fora do callback de física;
6. entra em `ACTIVE`.

`CombatArenaGate.set_closed()` apenas atualiza o estado desejado e agenda `_apply_requested_state()`. Layer, mask e visual são aplicados no callback deferred. `AreaExit` já aplica `monitoring` com `set_deferred`.

Corpos derrotados usam `CorpseCollisionHelper`: layer, mask e shape são desabilitados com operações deferred. Assim, cadáveres deixam de bloquear sem modificar o PhysicsServer no callback de morte.

## Exclusão mútua e gerações

Cada ativação/reset incrementa `_lifecycle_generation`. Toda continuação assíncrona recebe a geração esperada e aborta se:

- o controlador saiu da SceneTree;
- a área está descarregando;
- outra operação invalidou a geração;
- o estado já não corresponde à etapa esperada.

Dois `body_entered` no mesmo frame, entrada/saída rápida e callbacks atrasados não conseguem criar um segundo roster.

Após reset por morte ou falha de integridade, `_activation_requires_exit` impede reativação causada pela simples reabertura do monitor enquanto Calder ainda sobrepõe a zona. Uma saída real do player libera a próxima entrada.

## Ownership e integridade

Todo inimigo instanciado recebe:

- `combat_arena_id`: identificador estável da arena;
- `combat_arena_owner_id`: `instance_id` do controlador que criou o inimigo.

Ambos precisam coincidir. Parentesco com o container não concede ownership. Inimigos de outra área ou inseridos manualmente não contam.

Uma morte é registrada por `instance_id` uma única vez. A arena só conclui quando:

- está em `ACTIVE`;
- o número de IDs derrotados alcança o roster criado;
- não resta inimigo pertencente à arena vivo;
- não houve falha de integridade;
- a conclusão ainda não foi commitada.

Se um inimigo pertencente à arena sai da árvore vivo, o controlador emite `arena_integrity_failed`, registra warning e entra em `RESETTING`. Despawn indevido nunca reduz o requisito de mortes e nunca conclui a arena.

## Reset e descarregamento

Reset por morte de Calder:

1. invalida operações pendentes;
2. entra em `RESETTING` e abre gates/exits;
3. aguarda fronteira de física;
4. remove projéteis cujo owner pertence à arena;
5. executa `queue_free()` somente nos inimigos explicitamente pertencentes;
6. limpa tracking;
7. aguarda nova fronteira;
8. retorna a `INACTIVE` e rearma o monitor com trava de reentrada.

No boss, o mesmo fluxo também:

- restaura vida e fase de Deacon Rusk;
- restaura colisão deferred;
- mantém Rusk dormente até nova entrada;
- remove projéteis do boss;
- desvincula e oculta `BossHealthHud`.

`on_area_unloading()` invalida a geração, abre gates, limpa runtime e não rearma a área antiga. Uma nova cena cria um novo controlador e, ao receber serviços, restaura `COMPLETED` pela flag de progressão sem spawn. Isso evita duplicação em troca de área e save/load.

## Evidência automatizada — 2026-07-13

| Suíte | Resultado | Cobertura principal |
| --- | --- | --- |
| `combat_arena_tests` | 22/22 PASS | ativação, gate deferred, sinais duplicados, entrada/saída, ownership, cadáveres, despawn, projéteis, reset, reload, conclusão, dois ciclos |
| `player_respawn_tests` | 8/8 PASS | morte de Calder, gates, boss dormente, HUD, Rusk sem duplicação |
| `enemy_encounter_tests` | 6/6 PASS | rua, igreja, catacumbas e contrato dos estados/cenas |
| `deacon_rusk_tests` | 7/7 PASS | comportamento do boss após a mudança de reset |
| `area_transition_tests` | 6/6 PASS | transições e encerramento de área |

Resultado específico de arenas: zero assertion failures, zero unexpected issues, zero physics-flush errors, zero leaks nas suítes específicas. `combat_arena_tests` permite somente o warning produzido deliberadamente pelo teste de despawn vivo; não existe allowlist para physics flush.

O runner global continua FAIL por KI-005/KI-115 e `world_map_graph_tests`, fora do ciclo de arena. O playtest visual das arenas não foi assinado nesta rodada porque a automação da janela foi interrompida por entrada local do usuário.

## Checklist manual pendente

- entrar na arena da igreja e observar fechamento após a entrada, sem hitch/erro;
- morrer durante o encontro e confirmar gates abertos no respawn;
- sair e reentrar, confirmando um único roster;
- salvar/carregar antes, durante e depois da arena;
- trocar de área com encontro ativo e retornar;
- repetir dois ciclos em sessões consecutivas;
- ativar Deacon Rusk, morrer e confirmar HUD oculto/gates abertos;
- reentrar e confirmar uma única instância de Rusk;
- concluir boss e confirmar HUD encerrado e gates abertos;
- revisar console: nenhuma ocorrência de `Can't change this state while flushing queries`.
