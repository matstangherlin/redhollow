# Art Vertical Slice Gate — Trecho North Star Final (X 100–900)

**Data do gate:** 2026-07-13  
**Escopo:** somente o trecho sample **X = 100–900** (`StreetFinalSampleSpec`)  
**Modo avaliado:** `final_candidate` (+ comparação greybox / north_star)  
**Cenas:** `street_final_sample_test.tscn`, `street_art_test.tscn`, demo rua art  
**Artefatos:** `NORTH_STAR_FINAL_SAMPLE.md`, `NORTH_STAR_FINAL_ASSETS.md`, `NORTH_STAR_FINAL_PERFORMANCE.md`, `NORTH_STAR_COMPARISON_CHECKLIST.md`  
**Regra desta sessão:** **não expandir arte** até o resultado deste gate.

> Gate anterior da rua completa (piloto): histórico **APROVADO COM AJUSTES** (molde técnico).  
> Este documento é o **gate formal do trecho “final candidate”** — não substitui a falta de PNG aprovados.

---

## Veredito formal

### **APROVADO COMO MOLDE FINAL** (layout / composição / pipeline)

| Dimensão | Resultado |
| --- | --- |
| Molde espacial + 9 distritos na rua completa | **APROVADO** |
| Arte PNG beta-ready | **NÃO** — placeholders `draft` only |
| Igreja / catacumbas | **Fora de escopo** — não alterar |
| Expandir PNG finais | Permitido **somente na rua** Cap. Zero |

> O trecho sample (X 100–900) validou o molde. A aplicação full-street está em `StreetFinalMoldComposer` (`docs/STREET_FINAL_MOLD.md`).  
> Geometria procedural **não** é `integrated` no manifesto.

---

## Faixa e conteúdo sob teste

| Campo | Valor |
| --- | ---: |
| X min / max | **100 / 900** |
| Largura | **800 px** |
| Calder spawn | 120 |
| Elias / saloon / lamp | 260 / 300 / 180 |
| Segredo / estátua / PlatformA | 480 / 520 / 560 |
| Cult Brawler sample | 740 (`CultBrawlerFinalSample` só em final_candidate) |
| Brawler produção | 1280 (fora do trecho; preservado) |

---

## Avaliação técnica

| Critério | Status | Evidência |
| --- | --- | --- |
| Gameplay preservado | **PASS** | `player_regression_tests` PASS; AttackData intocado |
| Colisão preservada | **PASS** | `street_art_toggle_tests` 5/5; Solids inalterados no composer |
| Hitboxes corretas | **PASS** | `cult_brawler_tests` PASS; sample não altera `cult_brawler_hook.tres` |
| 60 FPS | **PENDENTE** | Overlay **P** existe; tabela em `NORTH_STAR_FINAL_PERFORMANCE.md` vazia |
| Sem stutter | **PENDENTE** | `first_frame_ms` no monitor — sem assinatura humana |
| Sem refs quebradas | **PASS** | suítes street/sample/region carregam |
| Sem asset ausente crítico (build) | **PASS** com ressalva | Fallbacks procedurais; sheets PNG ausentes (esperado) |
| Sem warnings repetitivos | **PASS** auto | Suites street sem spam; warning único em missings Calder/Brawler sheets |
| Sem leak novo | **PASS** auto | Sample remove `FinalSampleRoot` + brawler ao sair do modo |
| Igreja / catacumbas | **PASS** | Não modificadas neste gate |

### Suítes desta sessão (headless)

| Suite | Resultado |
| --- | --- |
| `street_final_sample_tests` | **3/3 PASS** |
| `street_art_toggle_tests` | **5/5 PASS** |
| `street_beta_complete_tests` | **5/5 PASS** |
| `region_visual_tests` | **6/6 PASS** |
| `cult_brawler_tests` | **PASS** |
| `player_regression_tests` | **PASS** |

---

## Avaliação visual (1–5)

Notas do gate técnico/direção (sem playtest externo). Escala: 1 = falha · 3 = molde · 5 = beta final.

| Critério | Nota | Comentário |
| --- | ---: | --- |
| Faroeste | **3** | Saloon/pôr do sol/terra; ainda geométrico |
| Anime | **2** | Calder/Elias greybox ou procedural; Brawler pilot |
| Decadência | **3** | Madeira rachada / prédios; falta pixel dirt |
| Culto | **3** | Coração Ordem + estátua + marca Brawler |
| Vermilite | **2** | Veia + luz sample; sem crystal art |
| Terror religioso | **2** | Estátua + hint Mol no céu; tom ainda “western soft” |
| Identidade original | **2** | Paleta Red Hollow OK; leitura “jogo final” não |
| Profundidade | **3** | Parallax 12 camadas; sample não muda fundo muito |
| Iluminação | **3** | Lantern + Vermilite + tema regional |
| Legibilidade | **3** | Deck platform + cues; misturado com greybox props |
| Qualidade personagens | **2** | Sem sheets finais Calder/Brawler/Elias |
| Qualidade cenário | **2** | Explicitamente procedural candidate |
| Peso dos golpes | **3** | Feedback pipelines PASS; arte de impacto pendente |
| UI | **3** | HUD V2; cobertura de ação a validar em playtest |

**Média aproximada:** ~2.6 / 5 — abaixo do limiar de molde final.

---

## Critérios de reprovação (check)

| Critério (“não aprovar quando…”) | Ativo? |
| --- | --- |
| Personagem some no fundo | **Risco** — Calder procedural/vermelho; playtest pendente |
| Cenário parece procedural | **SIM** — `PLACEHOLDER_CANDIDATE` |
| HUD cobre ação | **Não provado** — layout V2; playtest pendente |
| Plataforma não é percebida | **Risco médio** — edge highlight existe; humano pendente |
| Assets não compartilham estilo | **SIM** — pilot + greybox + polígonos sample |
| Resolução inconsistente | **Parcial** — contrato 40×72/34×56 vs placeholder 32×56 |
| Arte parece de jogos diferentes | **SIM** — mistura de fidelidades |
| Performance cai | **Desconhecido** — não medido |
| Custo/sala inviável | **Não** — estimativa Cap. Zero ainda ~38–42 pd (`ART_COST_PER_ROOM.md`) |

---

## Testes humanos (obrigatório — incompleto)

Perfis exigidos: desenvolvedor · pessoa nova no projeto · jogador 2D de ação.

| Perfil | Sessão | Formulário | Assinatura |
| --- | --- | --- | --- |
| Desenvolvedor | ☐ | `PLAYTEST_VISUAL_FORM.md` § Final Sample | — |
| Nunca viu o projeto | ☐ | idem | — |
| Jogador 2D ação | ☐ | idem | — |

### Perguntas (devem ser respondidas pelos 3)

1. Quem é o personagem jogável?  
2. Qual é a rota principal?  
3. O que parece interativo?  
4. O inimigo está preparando um ataque?  
5. A plataforma elevada está visível?  
6. A cidade parece faroeste?  
7. Existe algo religioso ou ameaçador?  
8. A Red Brand é perceptível?  
9. Os golpes parecem pesados?  
10. A pessoa continuaria jogando?

**Estado:** nenhuma resposta assinada neste gate → bloqueia qualquer aprovação.

---

## Comparação rápida dos 3 modos

| | Greybox | North Star | Final candidate (100–900) |
| --- | --- | --- | --- |
| Legibilidade combate | Alta | Média | Média+ |
| Atmosfera | Baixa | Média | Média+ |
| Parece arte final? | Não | Não | **Não** |
| Custo GPU extra | — | Base | +2 lights + ~31 particles |

---

## P0 antes do próximo gate (sem expandir regiões)

| ID | Ação | Bloqueia |
| --- | --- | --- |
| FS1 | Playtest 3 perfis + preencher perguntas 1–10 | Reaprovação |
| FS2 | Medir FPS/stutter (**P**) no trecho; preencher tabela performance | Reaprovação |
| FS3 | Pelo menos 1 PNG real aprovado no trecho (chão ou saloon) via manifesto | “parece procedural” |
| FS4 | Sheets Calder P0 **ou** Brawler sheets validados (existência ≠ approved) | Personagens |
| FS5 | Harmonizar Elias/Gunslinger opcional no trecho (mesmo nível visual) | Estilo misto |

Igreja / catacumbas / rua 900–2400: **congeladas para arte nova**.

---

## Assinatura

| Campo | Valor |
| --- | --- |
| **Classificação** | **REPROVADO** |
| Molde espacial do trecho (layout) | Útil — **não** aprovado como molde final |
| Arte beta-ready do trecho | **NÃO** |
| Expandir arte | **NÃO** |

| Papel | Nome | Data | Assinatura |
| --- | --- | --- | --- |
| Direção arte | | 2026-07-13 | |
| Dev lead | | 2026-07-13 | auto-gate técnico |
| QA / playtest | | | **pendente** |

---

## Histórico — gate rua piloto (referência)

O gate técnico da rua North Star completa permanece documentado abaixo como contexto (veredito anterior **APROVADO COM AJUSTES** para pipeline). O veredito **deste ficheiro a partir de 2026-07-13 (final sample)** é **REPROVADO**.

### Artefatos de pipeline (ainda válidos)

| Sistema | Caminho |
| --- | --- |
| Sample spec / composer | `street_final_sample_spec.gd`, `street_final_sample_composer.gd` |
| Área + 3 modos | `street_art_area.gd` |
| Perf | `street_performance_monitor.gd` |
| Apresentação 12 camadas | `street_art_presentation.gd` |

### Escala e combate (ainda PASS)

Contratos: Calder colisão 32×56, arte alvo 40×72; Brawler 34×56; hitboxes via AttackData; regressões player/brawler PASS nesta sessão.

---

## Documentos relacionados

| Documento | Uso |
| --- | --- |
| `PLAYTEST_VISUAL_FORM.md` | Formulário humano (secção Final Sample) |
| `ART_PRODUCTION_BACKLOG.md` | Backlog pós-reprovação |
| `ART_COST_PER_ROOM.md` | Custo / inviabilidade |
| `NORTH_STAR_FINAL_*.md` | Spec, assets, perf, checklist |
| `BETA_ASSET_MANIFEST.md` | Existência ≠ approved |
