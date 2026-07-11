# Capítulo Zero — Balanceamento inicial (greybox)

Métricas alvo para demonstração jogável (30–45 min, jogador novo). Valores provisórios — ajustar após playtest.

## Duração estimada

| Segmento | Tempo |
| --- | ---: |
| Abertura + rua (exploração, Elias, props) | 8–12 min |
| Encontros 1–3 (brawler, gunslinger, duo) | 8–12 min |
| Distrito igreja (penitente, arena, Red Brand) | 10–14 min |
| Catacumbas + Rusk + finale | 8–10 min |
| **Total** | **34–48 min** |

## Encontros (ordem)

| # | Composição | Área | HP inimigo (aprox.) |
| --- | --- | --- | ---: |
| 1 | Cult Brawler ×1 | Rua (principal) | 14 |
| 2 | Vermilite Gunslinger ×1 | Rua (rota opcional elevada) | 12 |
| 3 | Brawler + Gunslinger | Rua (beco, após pistoleiro) | 14 + 12 |
| 4 | Chain Penitent ×1 | Igreja (alcova lateral) | 18 |
| 5 | Brawler + Gunslinger + Penitent | Arena do pátio | 14 + 12 + 18 |
| 6 | Deacon Rusk | Catacumbas | (chefe existente) |

## Inimigos

| Arquétipo | Papel | Dano médio / hit | Notas |
| --- | --- | ---: | --- |
| Cult Brawler | Introdução melee | ~5 | Counterable, telegraph 0.48s |
| Vermilite Gunslinger | Distância, projétil físico | ~4/tiro | Recarga vulnerável ~1.15s; chicote corpo a corpo counterable |
| Chain Penitent | Controle de espaço | ~6 sweep / ~4 hook | Vulnerável ~0.85s após errar |
| Deacon Rusk | Chefe | (baseline) | ~3–5 min esperados |

## Jogador

| Métrica | Valor demo |
| --- | ---: |
| Vida máxima | 12 |
| Checkpoints | 2 (igreja opcional + catacumbas) |
| Cura por checkpoint | Sim (igreja: parcial; catacumbas: vida + Red Brand) |
| Red Brand | Coração Rubro pós-arena penitente; barreira [U] |
| Mortes esperadas (jogador novo) | 1–3 antes do chefe |

## Dificuldade

- **Meta:** desafiadora mas justa; telegraphs legíveis; nunca mais de 2 inimigos ativos fora da arena.
- **Arena combinada:** 3 inimigos sequenciais no spawn, leitura 2D preservada (distâncias 620/780/940).
- **Não** punir com múltiplos projéteis simultâneos na beta greybox.

## Ganho de Red Brand (estimado)

| Fonte | Ganho relativo |
| --- | --- |
| Combo / variedade | Moderado |
| Coração Rubro (cache) | Marco narrativo (~cheio parcial) |
| Checkpoint catacumbas | Restaura energia |

## Playtest checklist

- [ ] Encontro 1 ensina melee + counter
- [ ] Encontro 2 ensina esquiva de projétil
- [ ] Encontro 3 exige priorização de alvo
- [ ] Penitente pune rush, recompensa leitura
- [ ] Arena combina os três arquétipos sem softlock
- [ ] Fluxo completo ≤ 45 min sem pressa
