# Red Hollow — Beta Release Checklist

Checklist para declarar build **local beta** pronta para testers internos.

**Build alvo:** `0.2.0-beta.1` — Capítulo Zero (*O Sino Antes do Anoitecer*)

## A. Automação (obrigatório)

- [ ] `godot --headless --path . --script res://scripts/tests/test_runner.gd` executado
- [ ] Resultado registrado no `build-manifest.json`
- [ ] **17/17 suítes PASS** (ou desvio documentado com owner)
- [ ] **0 unexpected issues** (allowed issues OK se documentadas)
- [ ] Export debug + release gerados em `builds/windows/`

## B. Fluxo completo (manual — obrigatório)

| # | Fluxo | Teclado | Gamepad | OK |
| --- | --- | --- | --- | --- |
| 1 | Boot → menu principal | | | |
| 2 | Novo jogo | | | |
| 3 | Continuar (com save válido) | | | |
| 4 | Pausa (Esc / Start) | | | |
| 5 | Opções (vídeo, áudio, acessibilidade) | | | |
| 6 | Diálogo (E / A) | | | |
| 7 | Arena igreja | | | |
| 8 | Morte do jogador | | | |
| 9 | Checkpoint subterrâneo | | | |
| 10 | Save manual (F8) / Load (F9) | | | |
| 11 | Barreira Vermilite | | | |
| 12 | Boss Deacon Rusk | | | |
| 13 | Conclusão Capítulo Zero (overlay) | | | |
| 14 | Retorno ao menu | | | |

## C. Robustez (manual)

| Cenário | Esperado | OK |
| --- | --- | --- |
| Save inexistente | Continuar desabilitado; Novo Jogo OK | |
| Save corrompido | Menu avisa; Novo Jogo OK | |
| Settings corrompido | Defaults; jogo inicia | |
| Fechar durante save | Próximo load íntegro ou backup | |
| Perder foco / Alt+Tab | Retoma sem softlock | |
| Desconectar controle | Teclado funcional; prompts atualizam | |
| Mudar resolução | Sem UI quebrada permanente | |
| Sair pelo menu | Volta ao main menu | |
| Sair pelo sistema | Processo encerra limpo | |

## D. Performance (config referência)

Ver `PERFORMANCE_BUDGET.md`. Medir na **build release**, não só editor.

- [ ] 60 FPS médio na config referência
- [ ] Frame time p95 ≤ 20 ms em combate normal
- [ ] Boss Rusk sem queda grave sustentada

## E. Critérios de bloqueio (não aprovar release se)

- [ ] Qualquer **P0** aberto
- [ ] Perda de save confirmada
- [ ] Softlock reproduzível
- [ ] Crash reproduzível
- [ ] Fluxo impossível (progressão bloqueada)
- [ ] Input persistente quebrado (teclado **e** gamepad)
- [ ] Queda grave de FPS (&lt; 45 sustained) na config referência

## F. Issues conhecidos aceitos para beta local (P1 documentados)

- [ ] KI-001 morte/respawn parcial — workaround documentado
- [ ] KI-004 gate manual assinado neste checklist
- [ ] Testes headless com autoload — validação na build exportada

## Assinatura

| Campo | Valor |
| --- | --- |
| Build | |
| Commit | |
| Tester | |
| Data | |
| Aprovada para testers internos? | Sim / Não |
| Release marcada QA-approved? | Sim / Não |
