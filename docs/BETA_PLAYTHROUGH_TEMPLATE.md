# Beta Playthrough Template — Capítulo Zero

Use este formulário em **cada** sessão humana de playthrough completa.

**Status deste template:** em branco — preenchimento **manual obrigatório**.  
**Não marque aprovado automaticamente.**

---

## Assinatura da sessão

| Campo | Valor |
| --- | --- |
| Data | _______________ |
| Versão (`GameVersion`) | _______________ |
| Commit (git short) | _______________ |
| Build (debug/release) | _______________ |
| Duração total | _______________ |
| Dispositivo | Teclado / Gamepad / Ambos |
| Resolução | _______________ |
| UI scale | _______________ |
| Tester | _______________ |
| Resultado | `PASS` / `PASS COM RESTRIÇÕES` / `FAIL` / `INCOMPLETO` |
| Bloqueadores P0 | _______________ |
| Observações | _______________ |

**Assinatura manual:** _______________________________ **Data:** _____________

---

## Rota canônica (checklist)

Marque `[x]` somente após o passo ser jogado e avaliado.

| # | Passo | OK | Notas |
| --- | --- | --- | --- |
| 1 | Menu principal carrega | [ ] | |
| 2 | Novo Jogo (confirmação se já houver save) | [ ] | |
| 3 | Elias — diálogo e objetivo avançam | [ ] | |
| 4 | Saloon — leitura / interact sem softlock | [ ] | |
| 5 | Estátua — observação / flag | [ ] | |
| 6 | Primeiro combate (Cult Brawler) | [ ] | |
| 7 | Rota opcional (Gunslinger) | [ ] | |
| 8 | Segredo da rua | [ ] | |
| 9 | Arena da rua | [ ] | |
| 10 | Duo (Brawler + Gunslinger) | [ ] | |
| 11 | Transição para igreja | [ ] | |
| 12 | Chain Penitent | [ ] | |
| 13 | Arena da igreja | [ ] | |
| 14 | Red Brand (cache / carga) | [ ] | |
| 15 | Barreira Vermilite | [ ] | |
| 16 | Transição para catacumbas | [ ] | |
| 17 | Checkpoint subterrâneo | [ ] | |
| 18 | Diário / página do parceiro | [ ] | |
| 19 | Deacon Rusk — fase 1 | [ ] | |
| 20 | Deacon Rusk — fase 2 | [ ] | |
| 21 | Finale / overlay de encerramento | [ ] | |
| 22 | Retorno ao menu | [ ] | |
| 23 | Continuar restaura progresso coerente | [ ] | |

---

## Stress (marcar o que foi exercitado)

| Cenário | OK | Notas |
| --- | --- | --- |
| Morrer antes do checkpoint | [ ] | |
| Morrer depois do checkpoint | [ ] | |
| Morrer no boss | [ ] | |
| Pausar durante combate | [ ] | |
| Pausar durante diálogo | [ ] | |
| Pausar durante hitstop | [ ] | |
| Salvar em cada área (checkpoint / debug F8) | [ ] | |
| Carregar em cada área (Continuar / F9 debug) | [ ] | |
| Alternar teclado ↔ gamepad | [ ] | |
| Alt-tab / perder foco | [ ] | |
| Mudar resolução / UI scale | [ ] | |
| Entrar/sair rápido de arena | [ ] | |
| Interagir repetidamente | [ ] | |
| Tentar saída bloqueada durante arena/boss | [ ] | |

---

## Artefato do recorder (debug)

Se a build for debug, anexe ou cite:

| Campo | Valor |
| --- | --- |
| Arquivo `user://playtests/*.jsonl` | _______________ |
| `session_id` | _______________ |
| Eventos observados (amostra) | _______________ |

Painel debug: **F10** (desligado por padrão).

---

## Critérios de resultado

| Resultado | Quando usar |
| --- | --- |
| `PASS` | Rota 1–23 completa sem bloqueadores; stress críticos OK |
| `PASS COM RESTRIÇÕES` | Completou com bugs P1/P2 documentados em `BETA_BUG_LOG.md` |
| `FAIL` | Bloqueador P0 impede rota canônica |
| `INCOMPLETO` | Sessão interrompida antes do passo 23 |

Copie a assinatura preenchida para `BETA_PLAYTHROUGH_REPORT.md` após a sessão.
