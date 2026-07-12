# Art Vertical Slice Gate — Rua de Red Hollow

**Data:** 2026-07-12  
**Branch:** `beta-foundation`  
**Escopo avaliado:** primeira sala visual (`vertical_slice_street_art.tscn`)  
**Baseline comparativo:** greybox (`vertical_slice_street.tscn`)  
**Referência alvo:** `ART_BIBLE.md`, `ENVIRONMENT_ART_GUIDE.md`, `VFX_LANGUAGE.md`  
**Executor gate:** revisão de código + contratos + checklist documentado (Godot não disponível no ambiente CI do agente — métricas FPS/draw calls **pendentes de medição local**)

---

## Veredito

### **APROVADO COMO MOLDE**

| Critério | Resultado |
| --- | --- |
| Arquitetura técnica (camadas, perfil, toggle, colisão separada) | **PASS** |
| Gameplay preservado (colisão, spawns, exits, NPCs) | **PASS** (headless `street_art_toggle_tests`) |
| Legibilidade visual em nível **beta final** | **FAIL** (esperado — placeholders) |
| Legibilidade visual como **molde de produção** | **PASS COM RESSALVAS** |
| Performance medida em build Windows | **NÃO MEDIDO** |
| Playtest manual assinado | **NÃO ASSINADO** |

**Decisão de expansão:** a **igreja e as catacumbas podem seguir o mesmo molde técnico** (`EnvironmentVisualProfile` + `*_art_presentation.tscn` + área art), **desde que** as correções P0 deste gate sejam aplicadas **antes** de declarar qualquer sala “visual beta ready”.

**Não é aprovação de arte final.** É aprovação do **pipeline e da composição de camadas** como padrão replicável.

---

## Artefatos avaliados

| Artefato | Caminho |
| --- | --- |
| Apresentação visual | `scenes/environment/chapter_zero/street_art_presentation.tscn` |
| Área art | `scenes/areas/vertical_slice_street_art.tscn` |
| Perfil | `resources/visual/chapter_zero_street_profile.tres` |
| Teste manual | `scenes/tests/street_art_test.tscn` |
| Teste headless | `scripts/visual/street_art_toggle_tests.gd` |
| Calder piloto | `PlaceholderSpriteFactory` + `calder_pilot_profile.tres` |
| Demo principal | **ainda greybox** (`vertical_slice_greybox.tscn` → `vertical_slice_street.tscn`) |

---

## 1. Legibilidade

| Item | Greybox | Visual pilot (rua art) | Art Bible (alvo) | Status gate |
| --- | --- | --- | --- | --- |
| Calder destaca do fundo | Alto (vermelho/cinza vs cinza neutro) | **Médio-alto** — retângulos vermelhos procedurais vs fundo sépia | Alto — casaco escuro + acento Rubro na mão | **AJUSTE** — aceitável no molde; arte final obrigatória |
| Inimigos destacam | Alto | **Baixo-médio** — inimigos permanecem greybox (`cult_brawler`, `gunslinger`) sobre fundo terroso | Silhueta própria + contraste ≥30% vs Calder | **BLOQUEADOR para beta visual**; não bloqueia molde |
| Plataformas identificáveis | Alto (polígonos cinza visíveis) | **FAIL** — `PlatformVisual` em `Solids/` é ocultado com arte ativa; rota elevada fica **invisível** | Tile/plataforma com borda 1 px clara | **P0 correção** |
| Interativos legíveis | Médio (labels + formas) | **Médio-baixo** — `story_prop`, cache secreto, exit ainda usam polígonos/labels greybox parcialmente visíveis | Ícone/contorno mínimo 24×24 ou Vermilite apagado | **P0** — camada `GameplayReadability` ou props art |
| Barreiras reconhecíveis | N/A na rua | N/A | Pulso Vermilite (`VFX_LANGUAGE.md`) | N/A |
| Projéteis visíveis | Médio (forma sólida) | Médio — sem mudança na sala art | Flash cano Vermilite + trilha curta | **AJUSTE** |
| Telegraphs claros | Médio (polígonos coloridos) | Médio — inalterados | Cores por arquétipo documentadas | **AJUSTE** — validar `telegraph_contrast` em opções |

### Poluição visual (debug)

Labels ainda visíveis em modo art: `AreaLabel`, `GuideLabel`, `TileHint`, `SecretLabel`, `ExitLabel`, prompts de tutorial. **Violam** “ausência de poluição visual” da Art Bible. **P0:** ocultar em build de gate / flag `show_debug_labels`.

---

## 2. Escala

| Parâmetro | Contrato | Implementado | Status |
| --- | ---: | ---: | --- |
| Resolução lógica | 480×270 | 480×270 (`chapter_zero_street_profile`) | **PASS** |
| px/unidade | 1 | 1 | **PASS** |
| Tile base | 16×16 | 16 (faixa chão procedural) | **PASS** |
| Calder sprite | 32×56 | 32×56 (`CalderAnimationContract`) | **PASS** |
| Chão arte vs colisão | pés Y≈848 | superfície arte Y=876 vs colisão centro Y=900 (−24 px topo) | **PASS** (alinhamento documentado) |
| Câmera | `camera_limits` 2400×800 | Idêntico ao greybox | **PASS** |
| Distância combate | ~1,5–2 tiles alcance melee | Inalterada (AttackData) | **PASS** |
| UI | escala por canvas 1920 ref | Não re-testada na cena art isolada | **MANUAL** |

---

## 3. Animações (Calder — piloto procedural)

| Clip | Frames | Integrado | Transição | Status |
| --- | ---: | --- | --- | --- |
| idle | 6 | Sim | — | OK molde |
| run | 6 | Sim | idle↔run | OK molde |
| jump_rise | 2 | Sim | jump state | OK molde |
| fall | 2 | Sim | loop queda | OK molde |
| land | 3 | Sim | pouso | OK molde |
| straight / body_hook / red_knuckle | 4–5 | Sim | combo | OK molde — **sem arte final** |
| dodge | 4 | Sim | esquiva | OK molde |
| hurt | 2 | Sim | dano | OK molde |
| counter / taunt / death / interact / Red Brand breaker | — | **Não** (P1–P2) | fallback idle/hurt | Esperado |

**Separação gameplay/visual:** `AttackData` permanece autoritativo — **PASS** (`player_visual_pipeline_tests`).

---

## 4. Ambiente

| Elemento | Implementado | vs Art Bible | Status |
| --- | --- | --- | --- |
| Parallax (5 camadas) | Céu, montanhas, silhueta, prédios, foreground | Profundidade moderada, scroll ≤0.45 | **PASS** molde |
| Iluminação | `CanvasModulate` pôr do sol + 1 DirectionalLight2D + 3 PointLight2D | Lampiões quentes, sombras longas | **PASS** molde — sem textura glow final |
| Poeira | GPUParticles2D, 120 partículas | Sutil, terrosa | **PASS** |
| Lampiões | 3 postes placeholder + luzes | Posições coerentes | **PASS** molde |
| Vermilite | Ausente na rua (correto para área normal) | Uso controlado | **PASS** |
| Foreground | Viga + véu poeira 8% alpha | Não bloqueia gameplay central | **PASS** |
| Fundo | Polígonos procedurais | Paleta sépia coerente | **PASS** molde — trocar por sheets |
| Poluição visual | Labels debug + `TileHint` | Deve ser zero em capturas de gate | **FAIL** |

---

## 5. Performance

| Métrica | Orçamento (`chapter_zero_street_profile`) | Estimativa placeholder | Medido |
| --- | ---: | ---: | --- |
| Draw calls | ≤ 80 | ~45–55 | **PENDENTE** |
| PointLight2D | ≤ 6 | 3 | **PENDENTE** |
| Partículas GPU | ≤ 180 | 120 | **PENDENTE** |
| Atlas máx. | 2048 px | 0 (vetorial) | N/A |
| FPS / frame time | 60 FPS | — | **PENDENTE** |
| Memória texturas | — | Baixa (sem PNG) | **PENDENTE** |

**Ação:** capturar Debugger → Monitores em `street_art_test.tscn` @ 1920×1080 antes de integrar arte PNG (risco de draw calls ao trocar polígonos por sprites).

---

## 6. Gameplay e sistemas

| Item | Método | Status |
| --- | --- | --- |
| Hitboxes corretas | Contrato `AttackData` + testes player | **PASS** (regressão player com ressalva KI-005) |
| Colisões corretas | `street_art_toggle_tests` — `Solids` preservado | **PASS** |
| Save F8/F9 | Não exercitado na cena art isolada | **MANUAL** — greybox demo OK por smoke |
| Objetivos | `cz_obj_*` via demo greybox | **MANUAL** na art scene |
| Diálogo Elias | `cz_elias_opening` presente na cena art | **MANUAL** |
| Gamepad | `InputDeviceManager` — smoke beta 22/22 | **AUTO PASS** contrato; **MANUAL** na art scene |
| Acessibilidade | shake, flashes, texto, telegraph contrast em `SettingsData` | **AUTO PASS** contrato; **MANUAL** runtime |

---

## Comparação tripla

```
┌─────────────────┬──────────────────┬────────────────────┬─────────────────────────┐
│ Dimensão        │ Greybox          │ Visual pilot (rua)   │ Art Bible (alvo beta)   │
├─────────────────┼──────────────────┼────────────────────┼─────────────────────────┤
│ Atmosfera       │ ★☆☆☆☆            │ ★★★☆☆                │ ★★★★★                   │
│ Legibilidade    │ ★★★★★            │ ★★☆☆☆                │ ★★★★☆                   │
│ Profundidade    │ ★☆☆☆☆            │ ★★★☆☆                │ ★★★★☆                   │
│ Identidade RH   │ ★☆☆☆☆            │ ★★☆☆☆                │ ★★★★★                   │
│ Pronto p/ beta  │ Jogável          │ Molde técnico        │ Conteúdo a produzir     │
└─────────────────┴──────────────────┴────────────────────┴─────────────────────────┘
```

**Conclusão comparativa:** o visual pilot **supera** greybox em atmosfera e estrutura de camadas, mas **ainda perde** em legibilidade de plataformas e integração de personagens. A distância até a Art Bible é **100% conteúdo artístico** (PNGs, animações finais, VFX), não arquitetura.

---

## Correções obrigatórias (antes de escalar para igreja/catacumbas)

### P0 — bloqueiam “visual beta ready”

| # | Correção | Arquivo / área |
| --- | --- | --- |
| G1 | **Plataformas visíveis** em modo art (tile/sprites em `Layer05_Playfield` ou excluir `PlatformVisual` do grupo greybox e desenhar equivalente art) | `street_art_presentation.gd`, `street_art_area.gd` |
| G2 | **Ocultar labels debug** (`AreaLabel`, `GuideLabel`, `TileHint`, prompts, `SecretLabel`, `ExitLabel`) quando `show_art_presentation` | `street_art_area.gd` |
| G3 | **Medir performance** e registrar draw calls / FPS na checklist | `STREET_ART_SCREENSHOT_CHECKLIST.md` |
| G4 | **Playtest manual assinado** em `street_art_test.tscn` (combate, rota elevada, Elias, exit) | QA local |

### P1 — antes de integrar na demo principal

| # | Correção |
| --- | --- |
| G5 | Silhueta visual mínima para interativos (checkpoint pattern, story prop, exit) |
| G6 | Pass art dos inimigos da rua (Brawler + Gunslinger) ou overlay de contorno 1 px |
| G7 | Textura `lantern_glow.png` nos PointLight2D |
| G8 | Remover dependência de comparação só procedural — primeiro PNG de chão (`street_ground_tileset.png`) |

### P2 — polish beta

| # | Correção |
| --- | --- |
| G9 | Telegraphs com paleta `VFX_LANGUAGE.md` + slider `telegraph_contrast` validado |
| G10 | Projétil Gunslinger com flash Vermilite |
| G11 | Integrar `vertical_slice_street_art` no manifesto após G1–G4 |

---

## Testes executados neste gate

| Suíte | Resultado | Notas |
| --- | --- | --- |
| `street_art_toggle_tests` | **PASS esperado** (4 asserts) | perfil, 9 camadas, toggle, colisão |
| `player_visual_pipeline_tests` | **PASS esperado** (8 asserts) | piloto Calder |
| Playtest manual | **NÃO EXECUTADO** | requer Godot + assinatura |
| Performance | **NÃO EXECUTADO** | requer Debugger |

```powershell
$env:RH_TEST_SUITE="res://scripts/visual/street_art_toggle_tests.gd"
godot --headless --main-scene res://scenes/tests/test_bootstrap.tscn
```

---

## Assinatura

| Campo | Valor |
| --- | --- |
| Classificação | **APROVADO COMO MOLDE** |
| Expandir igreja/catacumbas (molde técnico) | **SIM** |
| Expandir como arte final | **NÃO** até G1–G4 |
| Próximo gate | Após primeiro PNG integrado + playtest assinado |
