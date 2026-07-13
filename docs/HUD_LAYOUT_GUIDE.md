# HUD Layout Guide — Red Hollow (V2 provisório)

Guia de layout e apresentação do HUD reorganizado. **Não substitui** `docs/UI_BIBLE.md` (direção visual final da beta). Este documento cobre a estrutura provisória **HUD V2**, pensada para legibilidade e área livre de cenário até a arte final de interface.

## Objetivo

- Reduzir ocupação visual e aparência de debug.
- Separar **vitais**, **estilo**, **objetivo** e **prompts** em regiões distintas.
- Manter os **mesmos sistemas** (vida, estilo, Red Brand, objetivo, mapa) — apenas reorganizar apresentação.
- Permitir validação paralela com o HUD legado.

## Arquivos

| Arquivo | Função |
| --- | --- |
| `scenes/ui/hud_v2.tscn` | Shell HUD V2 (Style + Objective + tutorial) |
| `scenes/ui/style_hud_v2.tscn` | Vitais (topo esquerdo) + cluster de estilo (topo direito) |
| `scenes/ui/objective_hud_v2.tscn` | Objetivo compacto (topo direito) |
| `scripts/ui/hud_shell_v2.gd` | Visibilidade e acesso aos sub-HUDs |
| `scripts/ui/hud_layout_controller.gd` | Alternância legado ↔ V2, rebind de managers |
| `scripts/ui/hud_theme_v2.gd` | Tema estrutural provisório (cores, painéis, barras) |
| `scripts/ui/controls_tutorial_overlay.gd` | Tutorial temporário de controles |
| `scenes/tests/hud_layout_test.tscn` | Cena isolada de validação visual |

### HUD legado (mantido)

- `scenes/style/style_hud.tscn`
- `scenes/ui/objective_hud.tscn`
- `VerticalSliceController/DemoHints` (lista permanente inferior — oculta quando V2 ativo)

## Layout V2

```
┌─────────────────────────────────────────────────────────────┐
│ [Vida + Red Brand]              [Objetivo curto + badge]    │
│  topo esquerdo                   topo direito               │
│                                 [Rank / score / mult] *     │
│                                  * visível em combate       │
│                                                             │
│                     ÁREA LIVRE DO CENÁRIO                   │
│                                                             │
│              [prompt E] ← perto do interativo               │
│                                                             │
│         [tutorial controles — some após ~28s]               │
└─────────────────────────────────────────────────────────────┘
```

### Canto superior esquerdo — Vitais

- Barra de vida (compacta) + valor numérico.
- Red Brand em barra menor logo abaixo.
- Sem painel lateral grande; `VitalsCluster` usa `PanelContainer` discreto.
- Nome/ícone de Calder **não** exibido por padrão (reservado para arte final).

### Canto superior direito — Objetivo

- Título curto + corpo com `autowrap`.
- Badge **“atualizado”** com fade temporário ao mudar o título.
- Não sobrepõe vitais (objetivo em `CanvasLayer` 9, estilo em 10).

### Sistema de estilo

- `StyleCluster`: rank grande, pontuação pequena, multiplicador, barra de progresso.
- **Exploração:** cluster oculto (rank `DUST` e sem combate recente).
- **Combate:** aparece após feedback de estilo ou `set_combat_highlight(true)`; fade após ~5 s sem ação.
- Rank acima de `DUST` mantém cluster visível com alpha reduzido.

### Prompts de interação

- Com HUD V2 ativo, `InteractionDetector` ancora o label no `interaction_anchor` do interativo (+ offset Y).
- Ocultos quando diálogo bloqueia interações (`DialogueController` / `is_in_dialogue`).
- Texto formatado por `InputDeviceManager` (teclado ou gamepad).

### Tutorial de controles

- Painel inferior central, some automaticamente após `intro_visible_seconds` (padrão 28 s).
- Referência completa disponível em **Pausa → Controles**.
- `notify_new_command_unlocked()` pode reexibir o tutorial (integração futura com progressão).
- Lista permanente em `DemoHints` fica oculta quando V2 está ativo.

## Tema provisório (`HudThemeV2`)

| Token | Uso |
| --- | --- |
| Fundo `#0F0D0D` ~88% | Painéis |
| Borda vermelha escura | Contorno discreto |
| Texto creme | Títulos e leitura principal |
| Vermilite | Destaques, multiplicador, badge |
| Dourado / amarelo queimado | Rank e barra de estilo |
| Verde | Vida |
| Vermelho intenso | Red Brand |

Fontes: padrão do sistema Godot (sem assets externos).

## Responsividade

- **Anchors + `MarginContainer`** (`SafeMargins`, 12 px base) em todos os clusters.
- Resoluções alvo: **1152×648**, **1280×720**, **1920×1080**.
- **Escala de UI:** `SettingsManager` → `video.ui_scale` → `content_scale_factor` na raiz (Opções).
- Janela e fullscreen: sem posições absolutas frágeis nos cantos; clusters ancorados aos cantos com margens.
- Teste manual de escala: `scenes/tests/hud_layout_test.tscn` (cenário “resolução pequena” reduz escala local).

## Alternância legado ↔ V2

| Mecanismo | Detalhe |
| --- | --- |
| Export `use_hud_v2` | Em `HudLayoutController` na cena principal (padrão: `false`) |
| **F3** em runtime | Alterna se `allow_runtime_toggle = true` |
| Rebind automático | `StyleManager`, `RedBrandDirector`, `NarrativeDirector` |

Integração na vertical slice: nós `HudV2` + `HudLayoutController` em `vertical_slice_greybox.tscn`.

## Acessibilidade

- Contraste texto creme sobre fundo escuro.
- Escala de UI nas Opções (75%–200%).
- Flashes de objetivo moderados (pulse de cor, sem strobe).
- Legendas de interação respeitam `InputDeviceManager` (troca teclado/gamepad).
- Redução de flashes globais: `SettingsManager` acessibilidade (inalterada).

## API preservada

`StyleHudV2` e `ObjectiveHudV2` estendem as classes legadas e mantêm:

- `%` unique names de barras e labels.
- `bind_style_manager`, `bind_health_component`, `bind_red_brand_component`.
- `update_objective(objective_id, title, text)`.

`HudLayoutController`:

- `get_active_style_hud()` / `get_active_objective_hud()`
- `is_using_hud_v2()`

## Testes

### Cena isolada

```text
F6 → scenes/tests/hud_layout_test.tscn
```

| Tecla | Ação |
| --- | --- |
| Espaço | Cicla cenários mock |
| H | Reexibe tutorial |
| O | Dispara pulse de objetivo |
| C | Destaca cluster de estilo (combate) |

### Checklist manual (vertical slice)

Com **F3** para alternar HUD V2:

- [ ] Exploração — cantos livres, tutorial some
- [ ] Combate — cluster de estilo aparece
- [ ] Arena — vitais legíveis, sem sobreposição
- [ ] Diálogo — prompts ocultos
- [ ] Boss — `BossHealthHud` independente (inalterado)
- [ ] Pausa — Controles mostra referência
- [ ] Mapa — overlay não conflita com cantos
- [ ] Morte — HUD legível / locks respeitados
- [ ] Objetivo atualizado — badge temporário
- [ ] Red Brand cheia — barra compacta
- [ ] Vida baixa — valores numéricos legíveis
- [ ] 1152×648 e 1920×1080 — margens e wrap OK
- [ ] Escala UI 125% nas Opções

### Headless

```powershell
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

Cenas novas não quebram o runner existente; validação visual permanece manual.

## Próximos passos (fora deste escopo)

- Arte final conforme `UI_BIBLE.md`.
- Remover HUD legado após sign-off de playtest.
- Integrar `notify_new_command_unlocked()` com `ProgressionSystem`.
- Ícones de input em sprite sheet licenciado.

## Decisões

- HUD V2 **não** altera `StyleManager`, `HealthComponent`, `RedBrandDirector` nem `NarrativeDirector`.
- Toggle **F3** é provisório para QA; export ou setting persistente pode substituir depois.
- `DemoHints` permanece na cena até remoção explícita do legado.
