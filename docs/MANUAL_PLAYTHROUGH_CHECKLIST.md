# Manual Playthrough Checklist — Beta `0.2.0-beta.1`

Use este roteiro para fechar **KI-004** e converter o gate de **PASS COM RESTRIÇÕES** em **PASS**.

**Como registrar:** marque `[x]` quando o passo passar; anote bugs na coluna **Notas**.  
**Classificação por passo:** OK / BUG / BLOQUEADO.

**Build testada:** _______________  
**Data:** _______________  
**Testador:** _______________  
**Dispositivo:** Teclado / Gamepad _______________

---

## A. Boot e menu

| # | Passo | OK | Notas |
| --- | --- | --- | --- |
| A1 | Abrir o jogo — main scene é o menu (sem crash) | [ ] | |
| A2 | Menu principal visível com título e botões | [ ] | |
| A3 | **Novo Jogo** sem save existente inicia direto | [ ] | |
| A4 | Criar save (jogar até F8 ou checkpoint) e voltar ao menu | [ ] | |
| A5 | **Novo Jogo** com save — diálogo de confirmação aparece | [ ] | |
| A6 | Confirmar overwrite — save anterior substituído | [ ] | |
| A7 | Cancelar overwrite — permanece no menu | [ ] | |
| A8 | **Continuar** desabilitado sem save válido | [ ] | |
| A9 | **Continuar** com save válido — loading → greybox | [ ] | |
| A10 | Loading screen aparece durante transição | [ ] | |
| A11 | **Opções** abre e fecha sem travar menu | [ ] | |
| A12 | **Créditos** abre e fecha | [ ] | |
| A13 | **Sair** encerra (ou volta ao editor em dev) | [ ] | |

---

## B. Settings (opções)

Testar no menu **e** na pausa in-game.

| # | Passo | OK | Notas |
| --- | --- | --- | --- |
| B1 | Alterar **resolução** — aplica e persiste após reinício | [ ] | |
| B2 | Alternar **fullscreen** / janela / borderless | [ ] | |
| B3 | Alternar **VSync** | [ ] | |
| B4 | Ajustar volumes (master, música, SFX, voz, UI, ambiente) | [ ] | |
| B5 | Reduzir **screen shake** — perceptível em combate | [ ] | |
| B6 | Ativar **flashes reduzidos** — menos piscadas em hit/estilo | [ ] | |
| B7 | Alterar **velocidade do texto** / texto instantâneo | [ ] | |
| B8 | Conectar **gamepad** — prompts mudam para botões | [ ] | |
| B9 | Voltar ao teclado — prompts de teclado restaurados | [ ] | |
| B10 | **Último dispositivo** usado reflete na UI de prompts | [ ] | |

---

## C. Fluxo Capítulo Zero — Rua

| # | Passo | OK | Notas |
| --- | --- | --- | --- |
| C1 | Início na **rua** (`vertical_slice_street`) | [ ] | |
| C2 | HUD de **objetivo** mostra abertura (Elias) | [ ] | |
| C3 | Falar com **Elias** — diálogo completa, flag avança | [ ] | |
| C4 | Investigar **estátua** — diálogo/flag | [ ] | |
| C5 | Coletar **pista do parceiro** (medalhão) | [ ] | |
| C6 | Derrotar **Brawler** isolado (`CultBrawlerStreet`) | [ ] | |
| C7 | Objetivo avança após brawler | [ ] | |
| C8 | Enfrentar **Gunslinger** opcional — projéteis funcionam | [ ] | |
| C9 | Derrotar **duo** Brawler + Gunslinger no beco | [ ] | |
| C10 | Transição para **distrito da igreja** | [ ] | |

---

## D. Igreja

| # | Passo | OK | Notas |
| --- | --- | --- | --- |
| D1 | Área da igreja carrega sem erro | [ ] | |
| D2 | Derrotar **Chain Penitent** no alcove | [ ] | |
| D3 | Entrar na **arena combinada** — gates fecham | [ ] | |
| D4 | Três arquetipos spawnam (Brawler, Gunslinger, Penitent) | [ ] | |
| D5 | Saídas bloqueadas durante arena | [ ] | |
| D6 | Derrotar os três — arena conclui, gates abrem | [ ] | |
| D7 | Sem duplicar inimigos ao sair/entrar rápido na zona | [ ] | |
| D8 | Obter **Red Brand** no cache | [ ] | |
| D9 | Ler **documento da Ordem** | [ ] | |
| D10 | Segurar interação na **passagem Red Brand** | [ ] | |
| D11 | **Destruir barreira** Vermilite com Red Brand Breaker | [ ] | |
| D12 | Descer ao **subterrâneo** | [ ] | |

---

## E. Subterrâneo e chefe

| # | Passo | OK | Notas |
| --- | --- | --- | --- |
| E1 | Catacumbas carregam | [ ] | |
| E2 | Ativar **checkpoint** — save automático | [ ] | |
| E3 | Encontrar **página do diário** do parceiro | [ ] | |
| E4 | Diálogo **Deacon intro** dispara | [ ] | |
| E5 | Entrar na zona do **Deacon Rusk** — gates fecham | [ ] | |
| E6 | HUD de chefe aparece | [ ] | |
| E7 | Derrotar **Deacon Rusk** — fase 2, stagger, morte | [ ] | |
| E8 | Gates/saídas liberam após vitória | [ ] | |

---

## F. Finale e retorno

| # | Passo | OK | Notas |
| --- | --- | --- | --- |
| F1 | **Sequência final** (8 passos) executa sem travar | [ ] | |
| F2 | Overlay de **encerramento da beta** visível | [ ] | |
| F3 | Flag `cz_chapter_zero_completed` efetiva (objetivo final) | [ ] | |
| F4 | **Pausa** durante finale respeita lock de conclusão | [ ] | |
| F5 | Voltar ao **menu principal** (pausa ou overlay) | [ ] | |
| F6 | **Continuar** após finale — estado coerente | [ ] | |
| F7 | **Novo Jogo** após finale — confirmação + reset | [ ] | |

---

## G. Pause (stress)

| # | Cenário | OK | Notas |
| --- | --- | --- | --- |
| G1 | Pausa na **rua** (movimento para, UI abre) | [ ] | |
| G2 | Pausa durante **combate** | [ ] | |
| G3 | Pausa durante **diálogo** (se permitido) | [ ] | |
| G4 | Pausa durante **hitstop** | [ ] | |
| G5 | Pausa na **arena** ativa | [ ] | |
| G6 | Pausa no **boss** | [ ] | |
| G7 | **Retomar** restaura jogo | [ ] | |
| G8 | **Menu principal** na pausa — confirma e carrega menu | [ ] | |
| G9 | Opções dentro da pausa funcionam | [ ] | |

---

## H. Save / load

| # | Cenário | OK | Notas |
| --- | --- | --- | --- |
| H1 | **F8** grava save em jogo | [ ] | |
| H2 | **F9** carrega save manual | [ ] | |
| H3 | Checkpoint grava ao ativar | [ ] | |
| H4 | Continuar restaura área, posição, flags | [ ] | |
| H5 | Flags narrativas persistem (Elias, arena, boss) | [ ] | |
| H6 | Barreira destruída permanece destruída após load | [ ] | |
| H7 | Save corrompido (editar JSON) — jogo não crasha | [ ] | |
| H8 | Backup `.bak` recupera save se principal corrompido | [ ] | |
| H9 | Manifesto `beta_demo` no save após sessão | [ ] | |

---

## I. Morte e respawn

| # | Cenário | OK | Notas |
| --- | --- | --- | --- |
| I1 | Morte na rua — respawn coerente | [ ] | |
| I2 | Morte **antes** do checkpoint | [ ] | |
| I3 | Morte **depois** do checkpoint — respawn no checkpoint | [ ] | |
| I4 | Morte na **arena** — encontro reinicia, gates não prendem | [ ] | |
| I5 | Morte no **boss** — Rusk reseta, gates não prendem | [ ] | |
| I6 | Corpos mortos **não bloqueiam** passagem | [ ] | |
| I7 | Projéteis limpos no reset de arena/boss | [ ] | |

---

## J. Troca de área

| # | Cenário | OK | Notas |
| --- | --- | --- | --- |
| J1 | Rua ↔ Igreja — spawn correto | [ ] | |
| J2 | Igreja ↔ Subterrâneo — spawn correto | [ ] | |
| J3 | Sair da área com **arena ativa** — arena encerra, gates abrem | [ ] | |
| J4 | Transição durante combate (se possível) — sem duplicar inimigos | [ ] | |

---

## K. Regressões conhecidas (verificar explicitamente)

| # | Item | OK | Notas |
| --- | --- | --- | --- |
| K1 | Console sem `Can't change this state while flushing queries` na arena | [ ] | |
| K2 | Sem inimigos duplicados na arena | [ ] | |
| K3 | Sem conclusão prematura da arena | [ ] | |
| K4 | Esc (panic unlock) documentado se usado durante QA | [ ] | |

---

## Assinatura

| Campo | Valor |
| --- | --- |
| Resultado geral | PASS / PASS COM RESTRIÇÕES / FAIL |
| Bugs críticos (P0) | |
| Bugs maiores (P1) | |
| Observações | |

**Assinatura:** _________________________ **Data:** _____________
