# Red Hollow — VFX Language

Linguagem visual de efeitos para Red Hollow. Efeitos **não definem gameplay**; reagem a sinais de combate e narrativa.

## Princípios

- Físico e brutal — faíscas, poeira, sangue seco, estilhaços de pedra.
- Vermilite só quando ligado a Red Brand, barreiras, culto ou Mol-Khar.
- Sem magia elemental genérica (bolas de fogo, raios arcanos).
- Duração curta (3–12 frames) — legibilidade em 60 FPS.
- Spawn via controllers/sinais, não via AnimationPlayer de personagem.

## Categorias

| Categoria | Exemplos | Cor dominante |
| --- | --- | --- |
| Impacto físico | poeira, recuo, flash branco 1 frame | branco / sépia |
| Sangue / ferimento | spray discreto (beta moderada) | vermelho escuro |
| Vermilite | brilho antebraço, cristal, barreira quebrando | `#EB4820` family |
| Red Brand | pulso mão, onda curta breaker | vermelho + laranja |
| Ordem / ritual | cinza cera, fumaça incense | pálido / cinza |
| Mol-Khar (raro) | sombra, distorção, olhos estátua | preto + vermelho profundo |
| UI gameplay | telegraph inimigo | cor do arquétipo |

## Vermilite

**Quando usar:**

- Pistoleiro carrega tiro (muzzle flash Vermilite).
- Barreira `red_barrier` pulsa.
- Coração Rubro cache.
- Estátuas reagem.

**Quando não usar:**

- Poeira de corrida normal.
- Impacto de soco comum sem Red Brand.
- HUD genérico.

Intensidade: 1–2 fontes Vermilite por tela; nunca fullscreen glow constante.

## Red Brand

| Momento | VFX |
| --- | --- |
| Repouso | marca mínima mão direita (sprite base) |
| Carga breaker | partículas convergindo antebraço |
| Release | flash radial **curto** + faíscas |
| Barreira destroy | rachadura + burst Vermilite |

Sem aura corporal completa na beta.

## Telegraphs (inimigos)

| Inimigo | Telegraph visual | Cor |
| --- | --- | --- |
| Cult Brawler | polígono/amplitude braço | amarelo-laranja |
| Gunslinger | linha mira + flash cano | Vermilite |
| Chain Penitent | arco corrente amplo | vermelho pálido |
| Deacon Rusk | runas + pausa pesada | cera / sangue |

Telegraph **não altera** hitbox — apenas antecipa timing existente em `AttackData`.

## Símbolos da Ordem

- Coração Rubro vazio (silhueta).
- Correntes estilizadas.
- Cera derretida / velas.
- Uso: props, documentos, graffiti, estátuas pequenas.

Evitar cruz cristã literal não distorcida — usar simbolismo corrupto.

## Estátuas Mol-Khar

| Escala | Tratamento VFX |
| --- | --- |
| Pequena (rua) | nenhum glow; pedra opaca |
| Média (igreja) | olhos apagados até evento |
| Colossal (finale) | abertura olhos = 6–8 frames pulso Vermilite + sombra |

Mol-Khar **nunca** corpo completo na beta — só sombra/voz.

## Implementação técnica

```
Player/Visual/
  VfxAnchor (Node2D)
CombatVfxSpawner (grupo ou autoload futuro)
```

- GPUParticles2D ou AnimatedSprite2D one-shot.
- Pooling recomendado antes da beta pública.
- Layers: ver `ENVIRONMENT_ART_GUIDE.md` + `CHARACTER_SCALE_GUIDE.md`.

## Áudio pareado

| VFX | SFX bus |
| --- | --- |
| Impacto | Combat |
| Red Brand | Player + reverb curto |
| Vermilite | Combat + pitch down |
| Ambiente | Ambience |

## Documentos relacionados

- `ART_BIBLE.md`, `ENVIRONMENT_ART_GUIDE.md`, `ANIMATION_PIPELINE.md`
