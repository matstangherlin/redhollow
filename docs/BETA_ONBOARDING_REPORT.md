# Beta — Onboarding Report (Capítulo Zero)

Data: 2026-07-13. Passagem de onboarding **sem tutorial textual excessivo** e **sem sistemas novos**.

Princípio: ensinar pelo **cenário**, **telegraphs** e **encontros controlados**. Caixas só onde a narrativa já exige (Elias / props).

## Curva de ensino

### Rua — introdução / baixa pressão

| Lição | Como é ensinado | Mudança nesta passada |
| --- | --- | --- |
| Interação | Elias + props (estátua, medalhão, placa) | Objetivos encurtados (“Fale com Elias.”) |
| Combate melee | Cult Brawler solo | HP↓, CD↑, telegraph↑ — vitória curta e legível |
| Dodge / counter | Label no chão + telegraph do hook | Texto curto: “Observe o telegraph…” (sem listar teclas no mundo) |
| Projétil | Gunslinger em rota elevada opcional | “Altitude — projétil físico”; reload mais longo |
| Prioridade | Duo atrás do gate do pistoleiro | “Dois alvos — foque o mais próximo” |

Overlay de controles no boot: **5.5 s**, linhas enxutas; referência completa permanece em **Pausa → Controles**.

### Igreja — combinação / Red Brand / arena

| Lição | Como é ensinado | Mudança |
| --- | --- | --- |
| Combinação de arquétipos | Arena do pátio | Spawns **escalonados 1.7 s** — um de cada vez |
| Leitura sob pressão | Mensagem de arena | “Um de cada vez — leia o telegraph” |
| Red Brand | Coração Rubro → barreira | Label “Coração Rubro → [U] na barreira”; cache 45 energia |
| Checkpoint | Igreja | Mantido (cura vida; Brand restaurada no subterrâneo) |

### Catacumbas — tensão / boss / finale

| Lição | Como é ensinado | Mudança |
| --- | --- | --- |
| Preparação | Guide + checkpoint (vida + Brand) | Guide: “Checkpoint primeiro — depois Rusk.” |
| Boss | Telegraphs Rusk (ver balance report) | Mais startup, menos slam-lock, fase 2 clara |
| Finale | Sequência Cap. Zero existente | Sem caixas novas |

## Regras aplicadas

| Regra | Cumprimento |
| --- | --- |
| Não tutorial textual demais | Overlay curto; prompts de mundo ≤ 1 linha |
| Não explicar tudo por caixas | Ensino via telegraphs + HP/CD |
| Usar cenário | Labels espaciais nos encontros |
| Usar telegraphs | Startup aumentados nos arquétipos intro |
| Encontros controlados | Solo → opcional → duo gateado → Penitente → arena stagger |
| Evitar dificuldade punitiva | Dano e HP reduzidos; reload/vuln alongados |
| Não permitir spam trivial | CD inimigo + hitstun boss |
| Sem domínio avançado no Cap. Zero | Counter útil; charge/slam não exigem tech |

## Objetivos (HUD)

Textos enxutos em `data/narrative/chapter_zero_objectives.json` — verbos curtos, sem parágrafo.

Proxy de compreensão no recorder: `objective_completed.understood_proxy` (dwell ≥ 8 s e ≤ 2 mortes naquele objetivo).

## Checklist de playtest de onboarding

- [ ] Jogador chega ao 1º combatente sem precisar abrir o menu de controles.
- [ ] Counter acontece naturalmente no brawler (telegraph visível).
- [ ] Pistoleiro opcional pode ser ignorado sem softlock da rua principal (exceto duo gate).
- [ ] Arena: o 2º/3º inimigo chega depois do primeiro contato, não no mesmo frame.
- [ ] Jogador encontra [U] no cenário da barreira após o Coração.
- [ ] Checkpoint subterrâneo antes de Rusk é óbvio.
- [ ] Vitória média em Rusk: 2–5 tentativas.

## Referências

- `docs/BETA_BALANCE_REPORT.md` — números e justificativas.
- `docs/CHAPTER_ZERO_BALANCE.md` — folha viva de encontro.
- `scripts/debug/beta_playtest_recorder.gd` — métricas.
