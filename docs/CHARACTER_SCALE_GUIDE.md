# Red Hollow — Character Scale Guide

Escala canônica para personagens em pixel art. **Colisão de gameplay não escala com sprite.**

## Resolução lógica

| Parâmetro | Valor |
| --- | --- |
| Resolução base design | **480 × 270** (16:9) |
| Stretch Godot | `canvas_items` + `expand` (`project.godot`) |
| FPS alvo | 60 |
| Unidade Godot | **1 unidade = 1 pixel** na camada jogável |

Arte pode ser desenhada em 2× (960×540) para detalhe; exportar frames na **resolução gameplay** ou 2× com import `fix_size` documentado em `ASSET_IMPORT_RULES.md`.

## Pixels por unidade

- **Pixel art:** 1 px = 1 unidade Godot.
- **Tile referência:** 16×16 px (plataforma / bloco modular).
- **Personagem Calder:** ~**32×56 px** sprite (corpo), alinhado à colisão atual.

## Calder Knox — dimensões gameplay

| Elemento | Tamanho (px) | Notas |
| --- | ---: | --- |
| `CollisionShape2D` corpo | 32 × 56 | **Protegido** — não alterar sem revisar combate |
| Hurtbox | 34 × 58 | +1 px margem |
| Hitbox base | 44 × 28 | `AttackData` redimensiona |
| Altura visual sprite | 56 | Pés no origin |
| Largura visual sprite | 32 | Silhueta compacta |
| Olhos / cabeça | ~12 px zona superior | Legível em 480p |
| Red Brand (mão direita) | ~12 × 12 px zona | Overlay ou segunda layer |

## Inimigos — alturas alvo (sprite)

| Arquétipo | Altura sprite | Largura | Relação vs Calder |
| --- | ---: | ---: | --- |
| Cult Brawler | 56 | 34 | 1.0× altura |
| Vermilite Gunslinger | 54 | 32 | 0.96× (mesma linha de olhos) |
| Chain Penitent | 58 | 38 | 1.04× (mantos/correntes) |
| Deacon Rusk | 72 | 42 | ~1.29× (mini-chefe) |

Hitboxes de inimigos **permanecem** nos valores de greybox até revisão explícita.

## Pivô, origem e facing

| Regra | Valor |
| --- | --- |
| **Origin gameplay** | Pés de Calder = `CharacterBody2D.position` (centro horizontal do corpo) |
| **Pivot sprite** | Centro inferior do frame (32×56 → offset Y = **-28** em `%SpriteVisual`) |
| **Facing** | `Visual.scale.x = ±1` — **nunca** espelhar `CharacterBody2D` inteiro |
| **Direction marker** | Removível em arte final; era debug/greybox |

## Proporção corporal (Calder)

- Cabeça ~4–5 px altura visível (estilo anime compacto, não chibi).
- Ombros ~70% da largura do torso.
- Casaco longo: silhueta em A invertido; ponta do casaco ~4 px acima dos pés na idle.
- Pernas ~45% da altura total.

## Silhueta e contraste

- Calder: vermelho casaco / chapéu escuro — **separável** do fundo sépia.
- Inimigos: cada arquétipo ≥ **30% diferença** de massa vs Calder (largura ou altura).
- Contorno externo: 1 px cor mais escura que fill (opcional em ambientes escuros).

## Z-index personagens

| Layer | z_index |
| --- | ---: |
| Calder sprite | 0 (relativo a `%Visual`) |
| Red Brand overlay mão | +1 |
| VFX hit spark | +2 |
| Props interativos foreground | +3 (exceções por cena) |

## Substituir placeholder

1. Exportar PNG com pivô inferior central (32×56 canvas).
2. Importar com regras de `ASSET_IMPORT_RULES.md`.
3. Manter offset `%SpriteVisual` = `(0, -28)` até revisão de colisão aprovada.
4. Validar que pés alinham com sombra opcional no chão (±2 px).
5. Trocar perfil em `PlayerVisualController` — ver `ANIMATION_PIPELINE.md`.

## Contrato Calder (resumo)

| Campo | Valor |
| --- | --- |
| Canvas | 32 × 56 px |
| Pivot frame | (16, 56) — centro inferior |
| Origin gameplay | pés em `CharacterBody2D.position` |
| Sprite offset | `(0, -28)` em `%SpriteVisual` |
| Facing | `Visual.scale.x = ±1` |
| Clip piloto | 10 animações — ver `CalderAnimationContract` |

Código: `scripts/visual/calder_animation_contract.gd`

## Documentos relacionados

- `ANIMATION_PIPELINE.md`, `ART_BIBLE.md`, `VISUAL_PRESENTATION_CONTRACT.md`
