# Red Hollow — Decisions Log

Registro de decisões de produto, narrativa e arquitetura. Atualizar quando uma decisão mudar.

## Produto e escopo

| ID | Decisão | Data / contexto | Status |
| --- | --- | --- | --- |
| D-001 | Main scene permanece `vertical_slice_greybox.tscn` até beta com arte final | Demo técnica 2026 | Ativa |
| D-002 | Beta pública = **Capítulo Zero — O Sino Antes do Anoitecer** (30–45 min) | Planejamento beta | Ativa |
| D-003 | Jogo final = metroidvania completo com barões, Palácio Rubro, Mol-Khar | `FINAL_GAME_SCOPE.md` | Ativa |
| D-004 | Tag `greybox-vertical-slice-v0.1` marca baseline antes estabilização beta | Restauração 2026 | Ativa |
| D-005 | Branch `beta-foundation` para trabalho pós-tag | Restauração 2026 | Ativa |

## Salvamento

| ID | Decisão | Motivo | Status |
| --- | --- | --- | --- |
| D-010 | `SaveManager.auto_load_on_ready = false` na greybox | Evitar load de saves incompatíveis (ex.: cenas de teste) | Ativa |
| D-011 | F8 / F9 para save/load manual na demo | QA e debug sem auto-load | Ativa |
| D-012 | Checkpoint auto-grava ao ativar | Progresso seguro no subterrâneo | Ativa |
| D-013 | Reavaliar auto-load apenas após validação de área + API estável do player | `TECH_DEBT.md` P1 | Pendente beta |

## Arquitetura

| ID | Decisão | Motivo | Status |
| --- | --- | --- | --- |
| D-020 | Shell persistente (player/câmera/managers) + swap de área em `WorldHost` | Evitar recriar player a cada área | Ativa |
| D-021 | Sem autoloads de gameplay na vertical slice | Orquestração na main scene | Ativa |
| D-022 | `GameplayLockManager` com tokens para diálogo/transição/morte/hitstop | Substituir hacks de `Engine.time_scale` | Implementado (baseline) |
| D-023 | Hitstop não congela `Engine.time_scale` global | Auditoria Prompt 26 | Implementado (baseline) |
| D-024 | Panic unlock (Esc) mantido como escape hatch | Softlocks em greybox | Ativa, revisar pós-beta |
| D-025 | Refatorar `player.gd` em componentes (input, movimento, estado, apresentação, debug) | `TECH_DEBT.md` | Em andamento (working tree) |
| D-026 | Save via API pública do player (`capture_persistence_state`) | Remover paths `Components/...` | Em andamento (working tree) |

## Combate e sobrenatural

| ID | Decisão | Status |
| --- | --- | --- |
| D-030 | Combate corpo a corpo; ataques via `AttackData` Resource | Ativa |
| D-031 | Calder **não** usa magia tradicional / elemental genérica | Ativa |
| D-032 | Red Brand = amplificação física + ligação a Mol-Khar | Ativa |
| D-033 | Manifestações sobrenaturais permitidas quando ligadas a Mol-Khar, Vermilite, pactos, corpo, alma, plano espiritual, Ressonância Rubra | Ativa |
| D-034 | Proibido: bolas de fogo, gelo, arco genérico, voo livre, raios sem vínculo narrativo | Ativa |

## Narrativa (cânone)

| ID | Decisão | Doc |
| --- | --- | --- |
| D-040 | Red Hollow construída sobre prisão/altar ancestral | `NARRATIVE_BIBLE.md` |
| D-041 | Mol-Khar não controla mentes; usa **Ressonância Rubra** | Ativa |
| D-042 | Vermilite escapa da prisão; mineração enfraquece selo | Ativa |
| D-043 | Ordem: “A dor é a verdadeira salvação.” | Ativa |
| D-044 | Arcturus sabe que Mol-Khar é real; após 1ª derrota → **Arcturus, Arauto de Mol-Khar** | FINAL (não beta) |
| D-045 | Beta **não** revela: luta completa Arcturus, Palácio Rubro, Mol-Khar físico completo, todos barões, final | Ativa |

## Arte e referências

| ID | Decisão | Doc |
| --- | --- | --- |
| D-050 | Pixel art detalhada + iluminação dramática | `ART_BIBLE.md` |
| D-051 | Moodboards só para tom — sem cópia de layout/asset | `VISUAL_REFERENCE_RULES.md` |
| D-052 | Corrupção ambiental por camadas, não duplicação manual de mapas | `ARCHITECTURE.md` |

## Testes

| ID | Decisão | Status |
| --- | --- | --- |
| D-060 | `test_runner.gd` executa 10 suítes; exit code ≠ 0 falha CI | Ativa |
| D-061 | Erros/warnings inesperados no console falham suíte | Ativa |
| D-062 | Erros conhecidos de arena headless declarados como allowed | Ativa até fix produção |

## Histórico

| Decisão revogada | Substituída por |
| --- | --- |
| Hitstop via `Engine.time_scale = 0` | HitstopController local (D-023) |
| Locks só via flags no player | GameplayLockManager (D-022) |
| Documentação descrevendo “protótipo vazio” | `CURRENT_IMPLEMENTATION.md` (2026) |
