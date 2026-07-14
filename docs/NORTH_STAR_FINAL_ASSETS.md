# North Star — Final Sample Assets

Inventário do trecho **X 100–900**. Nada aqui é arte PNG final aprovada.

## Política

| Regra | Estado |
| --- | --- |
| Assets próprios (procedural Godot) | Sim |
| Manifesto `approved`/`integrated` | **Não** — ainda `missing`/`concept`/`draft` |
| Placeholders identificados | Meta `PLACEHOLDER_CANDIDATE` em cada nó gerado |
| Internet / moodboard | Proibido |

## Por camada

| Camada | Conteúdo no sample |
| --- | --- |
| Céu | Sunset bloom amostral (`SampleSunsetBloom`) |
| Montanhas | Ridge North Star existente (visível na banda) |
| Cidade distante | Silhueta North Star |
| Midground | North Star mid buildings |
| Estruturas | Saloon candidate (siding, roof, door, cortina, placa + coração) |
| Plano jogável | Terra com fendas + boardwalk madeira |
| Props | Estátua pedra, lampião metal, deck plataforma |
| Iluminação | Lantern + Vermilite point lights (sample) |
| Atmosfera | Poeira, papel, fumaça (GPUParticles, amounts baixos) |
| Foreground | Sombra de poste (`ForegroundPostShadow`) |

## Materiais (diferenciação)

| Material | Como se lê |
| --- | --- |
| Madeira | Siding vertical, grão, pranchas, gaps no deck |
| Terra | Base + rachaduras |
| Pedra | Pedestal, corpo, fissura, capuz |
| Metal | Poste + rivets + gaiola do lampião |
| Tecido | Cortina na janela do saloon |
| Vermilite | Veia no chão + glow + luz |

## Atores

| ID | Tipo | X |
| --- | --- | ---: |
| Calder | jogador | 120 |
| Elias | NPC | 260 |
| CultBrawlerFinalSample | inimigo (modo final only) | 740 |
| CultBrawlerStreet | inimigo produção | 1280 |

## Manifesto (`data/art/beta_asset_manifest.json`)

Entrada de controlo:

- `env_street_final_sample_band` — status **`draft`** (candidato visual; não integrated)
- Slots PNG de rua (`env_street_*`) permanecem **`missing`/`concept`** até sheets reais + workflow de aprovação

Nenhum clip marcado `integrated` só por existir geometria procedural.
