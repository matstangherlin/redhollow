# Red Hollow — Visual Scale Study

**Data:** 2026-07-13  
**Objetivo:** Decidir escala de sprite de Calder **antes** da produção de arte final.  
**Laboratório:** `scenes/tests/visual_scale_lab.tscn`  
**Script:** `scripts/visual/visual_scale_lab.gd`  
**Perfis:** `resources/visual/scale_profiles/`

> **Proteção:** colisão gameplay (32×56), `AttackData`, movimento e `player.tscn` **não foram alterados**. O laboratório é isolado e **não** é main scene.

---

## Como abrir

1. Godot 4.7 → **Project → Run** não use; abra a cena diretamente: `scenes/tests/visual_scale_lab.tscn`
2. Pressione **F6** (Run Current Scene) ou instancie a cena no editor.
3. Use o painel superior esquerdo + preview à direita (simula viewport 1152×648 ou 1920×1080).

### Controles

| Tecla | Ação |
| --- | --- |
| **1 / 2 / 3** | Seleciona escala 32×56, 40×72, 48×80 |
| **4 / 5 / 6** | Câmera atual (1.0), aproximada (1.12), intermediária (1.28) |
| **Tab** | Alterna layout lado a lado ↔ foco em uma escala |
| **R** | Alterna referência de resolução 1152×648 ↔ 1920×1080 |
| **H** | Mostra/oculta mock de HUD compacto no preview |
| **P** | Mostra/oculta marcador de projétil |
| **A / D** ou setas | Pan da câmera do laboratório |

### Legenda visual

| Cor / elemento | Significado |
| --- | --- |
| Silhueta vermelha | Calder (visual apenas) |
| Retângulo **verde** | Colisão gameplay **fixa** 32×56 (não escala) |
| Retângulo **amarelo** | Hitbox real de `calder_straight.tres` (gameplay) |
| Fantasma rosado | Deacon Rusk (~1.29× altura Calder) |
| Props | Tamanho de ambiente **fixo** (tile 16 px) — porta, barril, saloon, etc. |

---

## Candidatos comparados

| Perfil | Canvas | Fator vs baseline | Custo animação relativo |
| --- | --- | ---: | ---: |
| `scale_32x56` | 32 × 56 | 1.00× | 1.00× |
| `scale_40x72` | 40 × 72 | 1.29× altura | 1.61× |
| `scale_48x80` | 48 × 80 | 1.43× altura | 2.14× |

Inimigos escalam **visualmente** com a altura de Calder (`CHARACTER_SCALE_GUIDE` como referência). Hitboxes de inimigos permanecem greybox até revisão explícita.

---

## Métricas por combinação (referência 1152×648)

Valores calculados pelo laboratório (`visual_scale_lab.gd`). Zoom reduz área visível proporcionalmente.

### Escala 32 × 56

| Zoom | Calder % tela | Chars/largura | Alcance ataque | Espaço chefe | Red Brand (px tela) | Risco colisão |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 1.00 | ~8.6% | ~26.5 | 56 px | ~528 px | ~12 | 0 px |
| 1.12 | ~9.7% | ~23.7 | 56 px | ~462 px | ~13 | 0 px |
| 1.28 | ~11.1% | ~20.7 | 56 px | ~394 px | ~15 | 0 px |

### Escala 40 × 72

| Zoom | Calder % tela | Chars/largura | Alcance ataque | Espaço chefe | Red Brand (px tela) | Risco colisão |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 1.00 | ~11.1% | ~20.2 | 56 px | ~504 px | ~14 | +8× +16 px |
| 1.12 | ~12.4% | ~18.0 | 56 px | ~438 px | ~16 | +8× +16 px |
| 1.28 | ~14.2% | ~15.8 | 56 px | ~370 px | ~18 | +8× +16 px |

### Escala 48 × 80

| Zoom | Calder % tela | Chars/largura | Alcance ataque | Espaço chefe | Red Brand (px tela) | Risco colisão |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 1.00 | ~12.3% | ~18.0 | 56 px | ~496 px | ~16 | +16× +24 px |
| 1.12 | ~13.8% | ~16.1 | 56 px | ~430 px | ~18 | +16× +24 px |
| 1.28 | ~15.8% | ~14.1 | 56 px | ~362 px | ~20 | +16× +24 px |

### Referência 1920×1080 (zoom 1.0)

| Escala | Calder % tela | Chars/largura | Detalhe px/frame |
| --- | ---: | ---: | ---: |
| 32×56 | ~5.2% | ~44.3 | 1 792 |
| 40×72 | ~6.7% | ~33.8 | 2 880 |
| 48×80 | ~7.4% | ~30.0 | 3 840 |

---

## Análise qualitativa

| Critério | 32×56 | 40×72 | 48×80 |
| --- | --- | --- | --- |
| Detalhe faroeste (chapéu, casaco) | Insuficiente | **Bom** | Excelente |
| Red Brand legível | Limite | **Bom** | Muito bom |
| Pixel art limpa | Máxima densidade | **Equilibrada** | Risco de blur se mal exportada |
| Espaço de combate | Máximo | **Bom** | Apertado (menos inimigos na tela) |
| Proporção vs props 16 px | Coerente | **Coerente** | Calder domina porta/saloon |
| Chefes grandes (Deacon) | Cabe bem | **Cabe bem** | Menos margem vertical com zoom |
| Cenário atmosférico | Personagem pequeno | **Personagem presente** | Personagem heroico demais |
| HUD compacto | Máximo espaço útil | **Bom** | Menos respiro superior |
| Custo produção animação | Baseline | **+61%** pixels/frame | **+114%** |
| Risco colisão ≠ sprite | Nenhum | Moderado | **Alto** |

---

## Modos de câmera

| Modo | Zoom | Uso |
| --- | ---: | --- |
| Atual | 1.00 | Baseline gameplay (`CameraController`) |
| Aproximada | 1.12 | Leve aproximação (leitura de expressão / mão) |
| Intermediária | 1.28 | Stress test — poucos inimigos visíveis, chefe ocupa mais tela |

---

## Recomendação

### **Escala recomendada para produção de sprites: 40 × 72 px por frame**

**Motivos:**

1. **Faroeste decadente legível** — chapéu, gola do casaco e silhueta em A invertido ganham ~6 px de altura útil na cabeça/ombros.
2. **Red Brand** — zona de mão passa de ~12 px para ~14 px no frame (+~16% na tela com zoom 1.0), suficiente para leitura em 1152×648.
3. **Combate corpo a corpo** — mantém ~18–20 “silhuetas” na largura visível; espaço para 2–3 inimigos + Calder sem poluição.
4. **Chefes** — Deacon ~92 px de altura visual ainda deixa ~370–500 px de céu/chão em 1152×648.
5. **Custo** — 1.61× pixels vs baseline é aceitável para beta Capítulo Zero; 48×80 (2.14×) escala custo sem ganho proporcional de gameplay.
6. **Cenário** — personagem não engole porta (32 px) nem barril (48 px); 48×80 faz Calder rivalizar com saloon de 192 px.

**Não aplicar automaticamente.** Aprovação humana + playtest manual após desenho de 1 sheet piloto (idle + straight + red_knuckle).

### Por que não manter 32×56

- Limite inferior para chapéu de cowboy e detalhe de sobretudo em pixel art **detalhada** (meta do `ART_BIBLE.md`).
- Red Brand em ~12 px é difícil de ler em monitores 1080p com stretch `expand`.

### Por que não subir para 48×80

- Ocupa ~15% da altura da tela @ zoom 1.28 — reduz leitura de telegraphs e projéteis.
- Desalinhamento visual vs colisão 32×56 (+16× +24 px) exige VFX de “extensão” da marca ou revisão de colisão.
- Custo de animação ~2× baseline para ~40% mais detalhe perceptível.

---

## Se a escala escolhida **não** for 32×56

Alterações necessárias (futuro — **não feitas nesta tarefa**):

| Área | Ação |
| --- | --- |
| `CalderAnimationContract` | Atualizar `CANVAS_SIZE`, `PIVOT`, `SPRITE_VISUAL_OFFSET` |
| `PlaceholderSpriteFactory` / sheets finais | Reexportar todos os PNG (`frames × largura`, altura nova) |
| `PlayerVisualController` | Revisar offset `%SpriteVisual` e escala |
| `EnvironmentVisualProfile` | `calder_sprite_size` |
| `CHARACTER_SCALE_GUIDE.md` / `ASSET_IMPORT_RULES.md` | Documentar nova escala canônica |
| Colisão gameplay | **Revisão de combate obrigatória** se sprite > 32×56 (hitbox hurtbox, alcance percebido) |
| Inimigos | Reescalar sprites; manter ou revisar hitboxes |
| Câmera | Possível ajuste `dead_zone_width/height`, `look_ahead_distance` |
| UI / HUD | Revalidar margens e mockups |
| Testes headless | Atualizar `player_visual_pipeline_tests`, `street_art_toggle_tests` |

---

## Arquivos do laboratório

| Arquivo | Função |
| --- | --- |
| `scenes/tests/visual_scale_lab.tscn` | Cena de estudo |
| `scripts/visual/visual_scale_lab.gd` | UI, métricas, toggles |
| `scripts/visual/visual_scale_profile.gd` | Resource de perfil |
| `scripts/visual/visual_scale_silhouette_factory.gd` | Silhuetas procedurais originais |
| `resources/visual/scale_profiles/*.tres` | Três candidatos |

---

## Documentos relacionados

`CHARACTER_SCALE_GUIDE.md`, `ART_BIBLE.md`, `VISUAL_FOUNDATION_BASELINE.md`, `ANIMATION_PIPELINE.md`, `ENVIRONMENT_ART_GUIDE.md`
