# Beta Playthrough Report — Capítulo Zero

**Estado:** aguardando playthrough humano.  
**Não aprovado automaticamente.**

Use `BETA_PLAYTHROUGH_TEMPLATE.md` durante a sessão e consolide aqui ao final.

---

## Assinatura (manual)

| Campo | Valor |
| --- | --- |
| Data | _pendente_ |
| Versão | `0.2.0-beta.1` |
| Commit | _preencher após sessão_ |
| Duração | _pendente_ |
| Resultado | **INCOMPLETO** — sem assinatura humana |
| Bloqueadores | _nenhum registrado (sessão não executada)_ |
| Observações | Instrumentação local (`BetaPlaytestRecorder`) disponível em debug. Sem arte / balance / conteúdo novos nesta preparação. |

**Assinatura do tester:** _______________________________ **Data:** _____________

---

## Escopo da sessão

Fluxo obrigatório:

```
Menu → Novo Jogo → Rua → Igreja → Catacumbas → Deacon Rusk → Encerramento → Menu → Continuar
```

Sem adição de conteúdo. Sem mudança de arte. Sem balanceamento pré-teste.

---

## Instrumentação local (debug)

| Item | Detalhe |
| --- | --- |
| Recorder | `scripts/debug/beta_playtest_recorder.gd` |
| Painel | `scripts/debug/beta_playtest_debug_panel.gd` (F10, off por padrão) |
| Destino | `user://playtests/*.jsonl` |
| Rede | **Nenhuma** — sem telemetria online |
| PII | **Não** coleta dados pessoais |

Eventos registrados (quando debug): início/fim de sessão, versão, commit, dispositivo, resolução, área, objetivo, checkpoint, morte, respawn, arena start/complete, boss start/defeat, diálogo start/end, save/load, integridade, softlock recovery, conclusão da beta, duração.

---

## Checklist consolidado

| # | Passo | Status |
| --- | ---: | --- |
| 1–23 | Rota canônica | _não executada_ |
| Stress | Ver template | _não executado_ |

Detalhe passo a passo: copiar da sessão em `BETA_PLAYTHROUGH_TEMPLATE.md`.  
Bugs: `BETA_BUG_LOG.md`.

---

## Como executar a sessão

1. Abrir o projeto no Godot 4.7 (debug).
2. Rodar main scene (`main_menu.tscn`).
3. Opcional: F10 para painel de playtest.
4. Seguir o template 1–23 + stress desejado.
5. Ao terminar, copiar assinatura e resultado para este relatório.
6. Anexar caminho do `.jsonl` se gerado.

---

## Decisão pós-sessão

| Campo | Valor |
| --- | --- |
| Aprovado para QA externo? | _somente após assinatura_ |
| Requer reteste? | _pendente_ |
| Próximo passo | Playthrough humano + preenchimento deste doc |
