# Red Hollow — Environment Art Guide

Diretrizes para cenários 2D de Red Hollow — Capítulo Zero e expansão futura.

## Estilo

- Pixel art detalhada, paleta terrosa dessaturada.
- Faroeste decadente + igreja corrupta + industrial mineiro.
- Profundidade por **camadas**, não por blur pesado.
- Gameplay primeiro: plataformas legíveis > ornamento.

## Resolução e tiles

| Parâmetro | Valor |
| --- | --- |
| Tile base | 16×16 px |
| Tile grande (estrutura) | 32×32 px |
| Altura plataforma padrão | 16–32 px |
| Resolução design | 480×270 |

## Camadas (back → front)

| Ordem | Nome | Parallax | z_index típico | Conteúdo |
| ---: | --- | ---: | ---: | --- |
| 0 | Sky / depth | 0.1 | -100 | céu, névoa |
| 1 | Far background | 0.2 | -80 | silhueta cidade, cruzes |
| 2 | Mid background | 0.4 | -50 | fachadas, colinas |
| 3 | Playfield structures | 1.0 | 0 | chão, paredes **com colisão** |
| 4 | Mid foreground | 1.0 | 10 | grades, vigas, altares |
| 5 | Gameplay props | 1.0 | 20 | portas, checkpoints, props |
| 6 | Near foreground | 1.05 | 40 | detalhes sem colisão |
| 7 | Atmospheric FX | 1.0 | 50 | poeira, cinzas |

**Parallax máximo recomendado:** 0.45 horizontal — evitar nausea e desalinhamento de combate.

## Capítulo Zero — áreas

| Área | Mood | Paleta | Notas |
| --- | --- | --- | --- |
| Rua Red Hollow | pó, ferro, entardecer | ocre, marrom, cinza | rotas principal + elevada |
| Distrito igreja | ordem, tensão | cinza pedra, cera | arena pátio, alcova penitente |
| Catacumbas | claustro, umidade | azul-cinza, vermelho distante | estátua colossal fundo |

Greybox atual usa `Polygon2D` + labels — substituir **camada a camada** por tilemap/sprites.

## Contraste para combate

- Plano jogável: valor médio 40–60% (HSV V).
- Fundo: 20–35%.
- Inimigos: ver `CHARACTER_SCALE_GUIDE.md`.
- Interativos (checkpoint, porta): borda 1 px clara ou ícone Vermilite mínimo.

## Props funcionais (não decorativos)

| Prop | Leitura visual |
| --- | --- |
| Checkpoint | crista Vermilite apagada → acesa |
| NarrativeGate | porta madeira + tranca Ordem |
| Red Brand passage | barreira rubra (`red_barrier`) |
| Story prop | contorno interativo 24×24 mínimo |

## Corrupção ambiental (Ressonância Rubra)

Variante por **swap de camada** (TileMap alternativo ou modulate), não duplicar level inteiro.

| Elemento | Normal | Corrompido |
| --- | --- | --- |
| Céu | sépia | vermelho profundo horizonte |
| Madeira | marrom | veias Vermilite |
| Estátuas | desgaste | olhos / rachaduras |
| Partículas | poeira | cinzas + faíscas rubras |

## Atlas cenário

```
art/environments/chapter_zero/
  street_tileset.png
  street_bg_far.png
  church_tileset.png
  church_interior.png
  underground_tileset.png
  underground_bg.png
```

Grid 16×16; margin/spacing 0 salvo bleed explícito.

## Colisão

- Colisão só em camada **Playfield structures**.
- Decorativo **nunca** collision layer 1 salvo props sólidos explícitos.
- Manter `fall_recovery_y` por área ao substituir geometria.

## Migração greybox → arte

1. Importar tileset (`ASSET_IMPORT_RULES.md`).
2. Recriar colisão em TileMap layer `Solids` antes de remover Polygon2D.
3. Manter spawns, exits, arenas nos mesmos IDs/nós.
4. Testar `area_transition_tests` + playtest manual.
5. Remover labels `GuideLabel` de debug por último.

## Documentos relacionados

- `ART_BIBLE.md`, `VFX_LANGUAGE.md`, `CHARACTER_SCALE_GUIDE.md`, `AREA_TRANSITIONS.md`
