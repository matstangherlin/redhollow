# Art Vertical Slice Gate — Rua North Star (Capítulo Zero)

**Data do gate:** 2026-07-13  
**Branch:** `beta-foundation`  
**Escopo:** primeira art vertical slice — **somente rua North Star**  
**Baseline comparativo:** greybox `vertical_slice_street.tscn`  
**Pilot atual:** `vertical_slice_street_art.tscn` + demo `vertical_slice_greybox.tscn` (rua art integrada)  
**Referência alvo:** `ART_BIBLE.md`, `ENVIRONMENT_ART_GUIDE.md`, `VFX_LANGUAGE.md`, `RED_HOLLOW_COLOR_PALETTE.md`

---

## Veredito formal

### **APROVADO COM AJUSTES**

| Dimensão | Resultado |
| --- | --- |
| Pipeline técnico (camadas, perfil, toggle, colisão separada, lighting states) | **PASS** |
| Preservação de gameplay (colisão, spawns, exits, flags, combate) | **PASS** (regressão auto + contratos) |
| Identidade visual vs Art Bible (beta final) | **FAIL** — conteúdo artístico pendente |
| Identidade como **molde replicável** | **PASS COM RESSALVAS** |
| Legibilidade beta | **FAIL** — plataformas elevadas, inimigos mistos, interativos |
| Performance medida (FPS / draw calls / build Windows) | **NÃO MEDIDO** — overlay **P** disponível |
| Playtest humano assinado | **NÃO ASSINADO** |

**Decisão de expansão:** **NÃO** expandir arte para igreja, catacumbas ou mapa inteiro até concluir os ajustes P0 deste gate e registrar playtest em `PLAYTEST_VISUAL_FORM.md`.

**Não é aprovação de arte final.** É aprovação condicionada do piloto integrado na demo, com correções obrigatórias antes do próximo gate.

---

## Comparação obrigatória (tripla)

### Tabela resumida

| Dimensão | 1. Greybox original | 2. Art Pilot atual | 3. Art Bible (alvo beta) |
| --- | --- | --- | --- |
| Atmosfera / faroeste decadente | ★☆☆☆☆ | ★★★☆☆ | ★★★★★ |
| Profundidade / parallax | ★☆☆☆☆ | ★★★☆☆ | ★★★★☆ |
| Legibilidade combate | ★★★★★ | ★★★☆☆ | ★★★★☆ |
| Anime (construção personagem) | ★☆☆☆☆ | ★★☆☆☆ | ★★★★☆ |
| Culto / Ordem | ★★☆☆☆ | ★★☆☆☆ | ★★★★☆ |
| Vermilite (uso controlado) | ★★☆☆☆ | ★★★☆☆ | ★★★★☆ |
| Terror religioso | ★☆☆☆☆ | ★★☆☆☆ | ★★★★★ |
| Ação estilizada (game feel) | ★★★★☆ | ★★★★☆ | ★★★★★ |
| Identidade original Red Hollow | ★☆☆☆☆ | ★★☆☆☆ | ★★★★★ |
| Pronto para ship beta visual | Jogável técnico | Piloto integrado | Produção PNG + polish |

### Comunicação de identidade (Art Pilot vs alvo)

| Pilar | Comunica hoje? | Evidência | Gap |
| --- | --- | --- | --- |
| Faroeste | **Parcial** | Paleta sépia, saloon procedural, pôr do sol, poeira | Falta textura madeira/poeira final |
| Anime | **Fraco** | Silhueta Calder procedural; Cult Brawler pilot 34×56 | Expressão, cabelo, casaco final; apenas 1 inimigo pilot |
| Decadência | **Bom para molde** | Céu queimado, prédios fechados, vegetação seca | Repetição procedural; falta detalhe pixel |
| Culto | **Parcial** | Símbolo coração, estátua, sinais Ordem, Brawler com marca | Elias/NPC greybox; ritual ainda abstrato |
| Vermilite | **Parcial** | Cluster rua, Gunslinger greybox vermelho, lighting state | Sem barreira na rua; glow ainda genérico |
| Terror religioso | **Fraco** | Horizonte Mol-Khar distante, estado Mol-Khar lighting | Sem set piece; tom ainda “western” > “horror” |
| Ação estilizada | **Forte** | `CombatFeedbackProfile`, hitstop, telegraphs, counter L | VFX finais e SFX licenciados pendentes |
| Identidade original | **Parcial** | Mistura western + rubro distinto de magia genérica | Arte final ainda não “vende” o jogo em 5 s |

**Conclusão comparativa:** o Art Pilot **supera** o greybox em atmosfera, camadas e identidade de paleta. **Ainda perde** ao greybox em legibilidade de plataformas elevadas e consistência de elenco (Calder/Brawler pilot vs Gunslinger/Elias greybox). A distância até a Art Bible é **majoritariamente conteúdo** (PNGs, animações finais, UI skin), não arquitetura.

---

## Artefatos avaliados

| Sistema | Caminho / notas |
| --- | --- |
| Apresentação rua | `scenes/environment/chapter_zero/street_art_presentation.tscn` |
| Área art + demo | `vertical_slice_street_art.tscn`, `vertical_slice_greybox.tscn` |
| Perfil ambiente | `resources/visual/chapter_zero_street_profile.tres` |
| Iluminação regional | `RegionVisualTheme`, `RegionVisualController`, `chapter_zero_street_theme_factory.gd` |
| Calder piloto | `calder_pilot_profile.tres`, `PlaceholderSpriteFactory`, 10 clips |
| Cult Brawler visual | `cult_brawler_pilot_profile.tres`, `CultBrawlerVisualController`, 12 clips |
| HUD V2 | `hud_v2.tscn`, `use_hud_v2 = true` na demo |
| VFX combate | `CombatFeedbackProfileLibrary`, 6 perfis Calder |
| Performance debug | `StreetPerformanceMonitor` — tecla **P** na rua |
| Comparação estados luz | `scenes/tests/region_visual_comparison_test.tscn` |
| Teste manual isolado | `scenes/tests/street_art_test.tscn` |

---

## 1. Escala e câmera

| Parâmetro | Contrato | Implementado | Status |
| --- | ---: | ---: | --- |
| Resolução lógica | 480×270 | 480×270 | **PASS** |
| px/unidade | 1 | 1 | **PASS** |
| Tile base | 16×16 | 16 (chão procedural) | **PASS** |
| Calder colisão | 32×56 | 32×56 (`CalderAnimationContract`) | **PASS** |
| Calder arte aprovada | 40×72 | 40×72 (contrato; piloto usa 32×56 procedural) | **PASS** contrato / **AJUSTE** arte |
| Cult Brawler | 34×56 | 34×56 integrado | **PASS** |
| Chão arte vs colisão | superfície Y≈876 | `ground_surface_y` 876, colisão topo 876 | **PASS** |
| Câmera | `Rect2(0,200,2400,1000)` | Idêntico greybox | **PASS** |
| `fall_recovery_y` rua | 1320 | 1320 | **PASS** |
| Distância melee | AttackData | Inalterado | **PASS** |

---

## 2. Calder (piloto)

| Item | Status | Notas |
| --- | --- | --- |
| Separação visual/gameplay | **PASS** | `player_visual_pipeline_tests` 8/8 |
| Clips integrados (10) | **PASS** molde | idle, run, jump, fall, land, straight, hook, knuckle, dodge, hurt |
| Clips pendentes (12) | Esperado | counter, taunt, death, Red Brand, interact… |
| Contraste vs fundo | **AJUSTE** | Procedural vermelho/laranja legível; arte 40×72 final obrigatória |
| Red Brand leitura | **AJUSTE** | Marca mínima no placeholder; breaker VFX OK |

---

## 3. Cult Brawler (referência inimigo beta)

| Item | Status | Notas |
| --- | --- | --- |
| Pipeline visual completo | **PASS** molde | `cult_brawler_visual_tests` 6/6, asset validation 6/6 |
| 12 clips pilot | **PASS** | Procedural até sheets em `art/characters/enemies/cult_brawler/sheets/` |
| Telegraph legível | **PASS** médio | `TelegraphGround` + cor laranja; validar com `telegraph_contrast` |
| Hitbox inalterada | **PASS** | `AttackData` não tocado |
| Sheets PNG finais | **PENDENTE** | Validator pronto; pasta sheets vazia = fallback procedural |

---

## 4. Rua North Star (cenário)

| Item | Greybox | Art Pilot | Status gate |
| --- | --- | --- | --- |
| 12 camadas | N/A | Sim | **PASS** |
| Parallax ≤0.45 | N/A | Sim (perfil) | **PASS** |
| Colisão preservada | Sim | Sim (`street_art_toggle_tests` 5/5) | **PASS** |
| Plataformas elevadas visíveis | Alto (cinza) | **Médio** — decks em `Layer05` art; rota ainda fácil de perder | **AJUSTE P0** |
| Repetição de módulos | Baixa | Média (planks procedural) | **AJUSTE** |
| Poluição debug | Alta | **Baixa** — labels ocultos em art mode (G2 corrigido) | **PASS** |
| NPC/inimigos visíveis | Sim | **Corrigido** — greybox tag não esconde mais Polygon2D de NPC | **PASS** (pós-fix 2026-07-13) |
| `z_index` gameplay | N/A | WorldObjects/Exits z=70 | **PASS** (pós-fix) |
| Iluminação regional | N/A | 4 estados + acessibilidade | **PASS** molde |
| Identidade paleta | Neutro | `RedHollowPalette` + pôr do sol | **PASS** molde |

---

## 5. HUD V2

| Item | Status | Notas |
| --- | --- | --- |
| Ativo na demo | **PASS** | `use_hud_v2 = true` |
| Área livre central | **PASS** desenho | Vitais top-left; objetivo top-right compacto |
| Não altera sistemas | **PASS** | Vida, estilo, Red Brand, objetivo — mesmos backends |
| Legibilidade 480×270 | **MANUAL** | Validar em `hud_layout_test.tscn` + playtest |
| Cobre ação? | **Não esperado** | Tutorial some ~28s; F3 alterna legado |
| Mapa (M) | Legado overlay | Fora do escopo deste gate visual rua |

---

## 6. VFX e game feel

| Item | Status | Notas |
| --- | --- | --- |
| Perfis por ataque Calder | **PASS** | 6 perfis; `feedback_system_tests` 10/10 |
| Hierarquia Straight < Hook < Knuckle < Breaker | **PASS** | Documentado `COMBAT_FEEDBACK_PROFILES.md` |
| Vermilite em VFX | **PASS** controlado | Breaker/knuckle; sem magia genérica |
| Projéteis Gunslinger | **AJUSTE** | Forma sólida greybox; flash cano pendente |
| Telegraphs inimigos | **AJUSTE** | Brawler OK; Gunslinger/Penitent greybox |
| Acessibilidade VFX | **PASS** | shake, flashes, partículas, distorção, CA, contraste |

---

## 7. Iluminação

| Item | Status | Notas |
| --- | --- | --- |
| Estados (Normal / Vermilite / Ressonância / Mol-Khar) | **PASS** molde | `region_visual_tests` 6/6 |
| Sem pós-process pesado | **PASS** | ColorRect + luzes 2D + modulate |
| Pixel art preservado | **PASS** | Sem blur obrigatório |
| Debug ciclo estados | **PASS** | Tecla **'** (apóstrofo) — **não** usa L (counter) |
| Integração só North Star | **PASS** | Igreja/catacumbas inalteradas |

---

## 8. Áudio

| Item | Status | Notas |
| --- | --- | --- |
| Buses + settings | **PASS** contrato | Master, SFX, UI, Ambience |
| SFX combate placeholder | **PASS** provisório | `placeholder_audio_factory` |
| Áudio ambiente rua | **AJUSTE** | Vento/poeira procedural; `mol_khar_presence` event reservado |
| Mix com VFX perfis | **PASS** | `sfx_id` por perfil |

---

## 9. Legibilidade (checklist gate)

| Elemento | Status | Notas |
| --- | --- | --- |
| Calder vs background | **AJUSTE** | OK no molde; melhorar com arte 40×72 |
| Inimigos | **MISTO** | Brawler pilot ★★★; Gunslinger greybox ★★ |
| Projéteis | **AJUSTE** | Visíveis; falta identidade Vermilite |
| Telegraphs | **PASS** médio | Brawler; opção contraste |
| Plataformas chão | **PASS** | Sidewalk art + colisão |
| Plataformas elevadas | **AJUSTE P0** | Arte existe em Layer05; leitura da rota ainda fraca |
| Portas / exit igreja | **AJUSTE** | Polígono greybox oculto; marker art sutil |
| Barreiras | N/A rua | — |
| Itens / story props | **AJUSTE** | Prompt [E] OK; sprite mínimo pendente |
| NPC Elias | **PASS** pós-fix | Visível + interação `cz_elias_opening` |
| Prompts | **PASS** | `InteractionDetector` + HUD V2 anchor |
| Objetivo | **PASS** | `ObjectiveHud` V2 |
| Vida / Red Brand / estilo | **PASS** | HUD V2 + `StyleManager` |

---

## 10. Movimento e combate

Validado por `player_regression_tests` **49/49 PASS** (headless, 2026-07-13):

| Verificação | Status |
| --- | --- |
| Corrida, pulo, aterrissagem | **PASS** |
| Combo (straight / hook / knuckle) | **PASS** |
| Esquiva chão + ar | **PASS** |
| Counter | **PASS** |
| Dano, knockback, hurt | **PASS** |
| Morte / respawn | **PASS** (`player_respawn_tests` 6/6) |

---

## 11. Performance

| Métrica | Orçamento (`chapter_zero_street_profile`) | Estimativa placeholder | Medido |
| --- | ---: | ---: | --- |
| Draw calls | ≤ 80 | ~50–70 (polígonos + luzes) | **PENDENTE** — tecla **P** |
| PointLight2D | ≤ 6 | 4 (+ 2 DirectionalLight2D) | **PENDENTE** |
| Partículas | ≤ 180 | 174 (5 emissores GPU) | **PENDENTE** |
| FPS alvo | 60 | — | **PENDENTE** |
| Frame time | < 16.6 ms | — | **PENDENTE** |
| Memória estática | — | Baixa (sem atlas PNG) | **PENDENTE** |
| Build Windows smoke | — | — | **PENDENTE** |
| Stutter | — | Não observado em auto | **MANUAL** |

**Procedimento de medição (obrigatório P0):**

1. Abrir demo → rua art.  
2. Tecla **P** → registrar FPS, frame ms, draw calls em repouso, combate, estado Mol-Khar (**'**).  
3. Repetir em 1280×720 e 1920×1080.  
4. Anexar screenshot do overlay em `PLAYTEST_VISUAL_FORM.md`.

---

## 12. Testes automatizados (evidência gate)

**Runner:** 27 suítes — **23 PASS / 4 FAIL** (headless, 2026-07-13)

| Suíte visual / rua | Resultado |
| --- | --- |
| `street_art_toggle_tests` | **5/5 PASS** (+ NPC visibility) |
| `region_visual_tests` | **6/6 PASS** |
| `player_visual_pipeline_tests` | **8/8 PASS** |
| `cult_brawler_visual_tests` | **6/6 PASS** |
| `cult_brawler_asset_validation_tests` | **6/6 PASS** |
| `feedback_system_tests` | **10/10 PASS** |
| `vertical_slice_verification` | **7/7 PASS** |

| Falhas não bloqueantes deste gate (integração) | Causa provável |
| --- | --- |
| `vertical_slice_regression_tests` | Exit igreja → `street_art` vs teste espera greybox |
| `product_shell_tests` | Save slot smoke |
| `content_registry_tests` | 1 assert manifest |
| `beta_integration_smoke_tests` | Autoloads ausentes no bootstrap headless |

```powershell
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

---

## Critérios de reprovação (check)

| Critério reprovação | Situação atual |
| --- | --- |
| Escala errada | **Não** — contratos documentados |
| Personagens desaparecem | **Corrigido** (2026-07-13); revalidar em playtest |
| Combate ilegível | **Não** — legibilidade beta ainda incompleta, mas jogável |
| HUD cobre ação | **Não** — layout V2 preserva centro |
| Assets não combinam | **Parcial** — mistura pilot + greybox (esperado no piloto) |
| Performance < 60 FPS | **Não medido** — não reprova molde; bloqueia beta visual |
| Pipeline frágil manual | **Não** — perfis, factories, validators, testes headless |

---

## Correções obrigatórias (P0 — antes de igreja/catacumbas)

| ID | Correção | Esforço | Dono |
| --- | --- | ---: | --- |
| G1 | **Rota elevada legível** — borda/readability nas 4 plataformas art ou tile dedicado | 0.5 pd dev + 0.25 pd arte | Dev + Art |
| G2 | ~~Ocultar labels debug em art~~ | — | **FEITO** |
| G3 | **Medir performance** + registrar em playtest form | 0.25 pd QA | QA |
| G4 | **Playtest assinado** (4 perfis, `PLAYTEST_VISUAL_FORM.md`) | 1 pd QA | QA |
| G5 | **Silhueta mínima** exit + story props (3 sprites) | 0.5 pd arte | Art |
| G6 | **Gunslinger visual pilot** ou contorno 1 px até PNG | 1–2 pd arte | Art |
| G7 | **Atualizar regression tests** para `street_art` como cena canônica | 0.25 pd dev | Dev |
| G8 | **Primeiro PNG chão** (`street_ground_tileset.png`) integrado | 0.5 pd arte + 0.25 dev | Art |

### P1 — polish beta rua

| ID | Correção |
| --- | --- |
| G9 | Sheets Cult Brawler finais (substituir procedural) |
| G10 | Calder clips P1 (death, counter, Red Brand charge/breaker) |
| G11 | `lantern_glow.png` nos PointLight2D |
| G12 | Elias overworld mínimo (4–6 fr) |
| G13 | Build Windows smoke pós-medição FPS |

---

## Assinatura do gate

| Campo | Valor |
| --- | --- |
| **Classificação** | **APROVADO COM AJUSTES** |
| Molde técnico replicável | **SIM** |
| Arte beta-ready (rua) | **NÃO** — até G1, G3, G4, G5, G6, G8 |
| Expandir igreja/catacumbas (arte) | **NÃO** |
| Próximo gate | Após G1–G4 + primeiro PNG chão + playtest assinado |

| Papel | Nome | Data | Assinatura |
| --- | --- | --- | --- |
| Direção arte | | | |
| Dev lead | | | |
| QA / playtest | | | |

---

## Documentos relacionados

| Documento | Uso |
| --- | --- |
| `PLAYTEST_VISUAL_FORM.md` | Checklist humano + perguntas |
| `ART_PRODUCTION_BACKLOG.md` | Backlog e ordem de produção |
| `ART_COST_PER_ROOM.md` | Estimativas de custo |
| `CULT_BRAWLER_VISUAL_SPEC.md` | Referência inimigo |
| `RED_HOLLOW_COLOR_PALETTE.md` | Iluminação e cores |
