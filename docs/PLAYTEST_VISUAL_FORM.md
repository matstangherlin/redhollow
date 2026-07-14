# Playtest Visual Form — Trecho North Star Final + Rua

Formulário para gate `ART_VERTICAL_SLICE_GATE.md`.  
**Versão:** 2026-07-13 (final sample X 100–900)  
**Veredito gate vigente:** **REPROVADO** (playtests abaixo ainda não assinados)  
**Build testada:** _______________  
**Resolução:** _______________  
**Dispositivo:** Teclado / Controle  
**Modo visual:** greybox / north_star / **final_candidate**  
**HUD:** V2 / Legado (F3)  
**Acessibilidade ativa:** shake ___ / flashes ___ / partículas ___ / distorção ___

---

## Escopo desta sessão

| Item | Valor |
| --- | --- |
| Faixa X | **100–900** |
| Cena recomendada | `scenes/tests/street_final_sample_test.tscn` (F6) |
| Toggle | **F** = greybox → north_star → final_candidate |
| Perf | **P** |

**Regra:** não expandir arte / não “corrigir” visual durante a sessão — só observar e anotar.

---

## Perfis obrigatórios (mínimo 3)

| Perfil | Quill | Sessão feita? | Assinatura |
| --- | --- | :---: | --- |
| A — Desenvolvedor | Conhece o projeto | ☐ | |
| B — Nunca viu o projeto | Sem briefing de lore | ☐ | |
| C — Jogador 2D de ação | Metroidvania / beat 'em up | ☐ | |

---

## Perguntas obrigatórias (responder nos 3 perfis)

| # | Pergunta | A | B | C |
| ---: | --- | --- | --- | --- |
| 1 | Quem é o personagem jogável? | | | |
| 2 | Qual é a rota principal? | | | |
| 3 | O que parece interativo? | | | |
| 4 | O inimigo está preparando um ataque? | | | |
| 5 | A plataforma elevada está visível? | | | |
| 6 | A cidade parece faroeste? | | | |
| 7 | Existe algo religioso ou ameaçador? | | | |
| 8 | A Red Brand é perceptível? | | | |
| 9 | Os golpes parecem pesados? | | | |
| 10 | A pessoa continuaria jogando? (1–5) | | | |

---

## Instruções para o facilitador

1. Preferir `street_final_sample_test.tscn` no modo **FINAL CANDIDATE**.  
2. Duração: **10–20 min** no trecho (spawn → Elias → saloon → plataforma → Brawler sample).  
3. Perfil B: não explicar controles além de “ação 2D”.  
4. Registrar FPS com **P** (repouso + combate no X~740).  
5. Não pular perguntas 1–10.

---

## Perfil A — Desenvolvedor

### Checklist técnico (trecho)

| # | Item | OK | Falha | Notas |
| ---: | --- | :---: | :---: | --- |
| A1 | Elias visível e interativo | ☐ | ☐ | |
| A2 | Saloon interativo | ☐ | ☐ | |
| A3 | PlatformA perceptível | ☐ | ☐ | |
| A4 | CultBrawlerFinalSample no modo final | ☐ | ☐ | |
| A5 | CultBrawlerStreet (1280) ainda existe se explorar além | ☐ | ☐ | |
| A6 | Counter **L** / Esquiva **K** | ☐ | ☐ | |
| A7 | HUD não cobre centro | ☐ | ☐ | |
| A8 | Save F8/F9 (debug) | ☐ | ☐ | |
| A9 | Overlay **P**: FPS ≥ 55 | ☐ | ☐ | |
| A10 | Sem warnings spam no debugger | ☐ | ☐ | |
| A11 | Toggle F cicla 3 modos sem crash | ☐ | ☐ | |

**Observações:** _______________________________________________

---

## Perfil B — Nunca viu o projeto

| # | Item | OK | Falha | Notas |
| ---: | --- | :---: | :---: | --- |
| B1 | Identificou o jogável sem dica | ☐ | ☐ | |
| B2 | Achou algo para falar / examinar | ☐ | ☐ | |
| B3 | Percebeu inimigo | ☐ | ☐ | |
| B4 | Percebeu telegraph de ataque | ☐ | ☐ | |
| B5 | Subiu ou notou plataforma | ☐ | ☐ | |
| B6 | Descreveu “faroeste” espontaneamente | ☐ | ☐ | |
| B7 | Mencionou culto / religião / ameaça | ☐ | ☐ | |
| B8 | Quis continuar após 10 min | ☐ | ☐ | |

**Citações / dúvidas:** _______________________________________________

---

## Perfil C — Jogador 2D de ação

| # | Item | OK | Falha | Notas |
| ---: | --- | :---: | :---: | --- |
| C1 | Timing de ataque vs telegraph legível | ☐ | ☐ | |
| C2 | Golpes “pesados” vs floaty | ☐ | ☐ | |
| C3 | Contraste Calder vs fundo | ☐ | ☐ | |
| C4 | HUD atrapalha? | ☐ | ☐ | |
| C5 | Comparou com outro beat 'em up 2D | ☐ | ☐ | |
| C6 | Continuaria? (1–5) | ☐ | ☐ | |

**Observações:** _______________________________________________

---

## Notas 1–5 (após cada sessão — média dos 3)

| Critério | A | B | C | Média |
| --- | :---: | :---: | :---: | :---: |
| Faroeste | | | | |
| Anime | | | | |
| Decadência | | | | |
| Culto | | | | |
| Vermilite | | | | |
| Terror religioso | | | | |
| Identidade original | | | | |
| Profundidade | | | | |
| Iluminação | | | | |
| Legibilidade | | | | |
| Qualidade personagens | | | | |
| Qualidade cenário | | | | |
| Peso dos golpes | | | | |
| UI | | | |

---

## Performance (FS2 / G3)

| Cenário | FPS | Frame ms | Draw calls | Partículas | Luzes | Mem MB | Stutter0 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Final candidate repouso | | | | | | | |
| Combate Brawler sample | | | | | | | |
| North Star (mesmo trecho) | | | | | | | |
| Greybox | | | | | | | |

**Stutter perceptível?** Sim / Não — quando: _______________

---

## Consolidação

| Métrica | Valor |
| --- | --- |
| Sessões A/B/C | ☐ ☐ ☐ |
| Média “continuaria” (perg. 10) | |
| Critérios de reprovação observados | procedural / estilo misto / HUD / plataforma / perf / outro: ___ |
| Recomendação humana | APROVADO COMO MOLDE FINAL / APROVADO COM AJUSTES / **REPROVADO** |

### Assinaturas

| Papel | Nome | Data |
| --- | --- | --- |
| Facilitador | | |
| QA | | |
| Direção | | |

---

## Anexos

- [ ] Screenshot final_candidate (trecho)  
- [ ] Screenshot combate sample  
- [ ] Screenshot **P**  
- [ ] Screenshot plataforma  
- [ ] Notas de bugs / KI
