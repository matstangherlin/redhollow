# Red Hollow — Beta Release Checklist

Checklist para declarar build **local / closed-test** pronta.

**Build alvo:** `0.2.0-beta.rc1` — *Red Hollow — Chapter Zero Beta RC1*  
**Última avaliação:** **REPROVADA** — gate verde, playthrough/smoke ainda abertos (`docs/RC1_REPORT.md`)

## A. Automação (obrigatório)

- [x] `godot --headless --path . --script res://scripts/tests/test_runner.gd` executado
- [ ] Resultado registrado no `build-manifest.json` — packaging antigo ainda marca FAIL; reexportar
- [x] **Todas as suítes PASS** — **43/43** (`docs/_rc1_gate_fix_out.txt`)
- [x] **0 unexpected issues**
- [x] Export debug + release em `builds/windows/` (reexport pós-fix pendente)
- [x] Portable ZIP gerado

## B. Fluxo completo (manual — obrigatório)

| # | Fluxo | Teclado | Gamepad | OK |
| --- | --- | --- | --- | --- |
| 1 | Boot → menu principal | | | **não assinado** |
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
| Save inexistente | Continuar desabilitado; Novo Jogo OK | não assinado |
| Save corrompido | Menu avisa; Novo Jogo OK | headless only |
| Settings corrompido | Defaults; jogo inicia | headless only |
| Fechar durante save | Próximo load íntegro ou backup | não assinado |
| Perder foco / Alt+Tab | Retoma sem softlock | não assinado |
| Desconectar controle | Teclado funcional; prompts atualizam | não assinado |
| Mudar resolução / fullscreen | Sem UI quebrada permanente | não assinado |
| Duas sessões / dois ciclos | Estável | não assinado |
| Sair pelo menu / sistema | Limpo | não assinado |

## D. Performance (config referência)

Ver `PERFORMANCE_BUDGET.md`. Medir na **build release**.

- [ ] 60 FPS médio na config referência — **não medido RC1**
- [ ] Frame time p95 ≤ 20 ms em combate normal
- [ ] Boss Rusk sem queda grave sustentada

## E. Critérios de bloqueio (não aprovar se)

- [x] Qualquer **P0** aberto → **KI-004 + smoke/perf** → **bloqueia** (KI-005 fechado)
- [ ] Perda de save confirmada
- [ ] Softlock reproduzível
- [ ] Crash reproduzível
- [ ] Fluxo impossível
- [ ] Input persistente quebrado
- [ ] Queda grave de FPS (&lt; 45 sustained)

## F. Issues conhecidos aceitos (somente se ≤ P1)

Não aplicável enquanto P0 abertos. Ver `RC1_KNOWN_LIMITATIONS.md`.

## Assinatura

| Campo | Valor |
| --- | --- |
| Build | `0.2.0-beta.rc1` / `red-hollow-0.2.0-beta.rc1-release.exe` |
| Commit | `4f20f76` (+ tree suja no packaging) |
| Tester | automação RC1 packaging |
| Data | 2026-07-13 (local) / 2026-07-14 UTC |
| Aprovada para testers internos? | **Não** |
| Classificação | **REPROVADA** |
| Release marcada QA-approved? | **Não** (`qa_release_approved: false`) |
