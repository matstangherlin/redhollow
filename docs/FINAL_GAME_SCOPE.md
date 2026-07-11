# Red Hollow — Final Game Scope

Visão de escopo do jogo completo. Distinto da beta (`BETA_DEMO_SCOPE.md`) e da demo técnica greybox já jogável.

## Visão

Metroidvania de ação 2D em pixel art detalhada. Calder explora Red Hollow, enfrenta barões e a Ordem, desvenda o ritual da Red Brand e o papel de Mol-Khar, enquanto a mineração de Vermilite enfraquece o selo da cidade.

## Pilares do produto final

- combate corpo a corpo técnico e estilizado;
- exploração interligada com backtracking;
- progressão por habilidades físicas e Red Brand;
- narrativa ambiental + diálogos curtos;
- terror religioso e faroeste decadente;
- humor agressivo de Calder sem anular ameaça.

## Estrutura macro

### Mundo

- cidade de Red Hollow em múltiplos distritos conectados;
- minas e instalações industriais;
- igrejas, catacumbas, ruínas cerimoniais;
- áreas com variantes de corrupção (Ressonância Rubra);
- atalhos e portas por habilidade/flag.

### Personagens e facções

- Calder Knox (protagonista);
- Ordem do Coração Rubro;
- Mol-Khar (presença crescente);
- barões: Silas Crow, Rosa La Serpiente, Arcturus Vale, Magnus Vane;
- inimigos regulares e elites por arquétipo (`ART_BIBLE.md`).

### Combate

- socos, chutes, agarrões, esquivas, counters, provocações;
- ataques da Red Brand e técnicas desbloqueáveis;
- chefes com fases testáveis;
- sistema de estilo com ranks;
- sem magia elemental genérica.

### Progressão

- habilidades de movimento e combate;
- upgrades da Red Brand ligados à narrativa;
- chaves narrativas, flags e barreiras;
- opcional: equipamentos simples no futuro — **não** loot aleatório pesado no escopo inicial.

### Narrativa

- arco principal: promessas, culpa e selo de Mol-Khar;
- side content ambiental e diário;
- confrontos com barões ao longo do mapa;
- clímax envolvendo Palácio Rubro e ritual (fora da beta).

### Interface

- HUD completo;
- mapa metroidvania;
- diário, objetivos, coleção de lore;
- menus de pausa, opções, Red Brand;
- conforme `UI_BIBLE.md` em evolução.

### Áudio

- trilha por distrito e estado de corrupção;
- SFX de combate pesado e legível;
- voz/locução: a definir; diálogos textuais no mínimo.

### Salvamento

- slots em `user://` com versão;
- checkpoint + progresso global;
- barreiras destruídas e flags persistentes;
- migração de versão de save documentada.

## O que já existe no repositório (base técnica)

| Área | Estado |
| --- | --- |
| Shell persistente + troca de áreas | Implementado |
| Player completo (combate) | Implementado (dívida em `TECH_DEBT.md`) |
| Save, progressão, barreiras | Implementado |
| Um arco demo (rua → igreja → subterrâneo → Rusk) | Implementado |
| Pixel art final | Planejado |
| Cidade completa | Planejado |
| Todos barões | Planejado |
| Palácio Rubro | Planejado |

## Fora do escopo do jogo (nunca)

- magia tradicional elemental;
- voo livre;
- projéteis mágicos genéricos;
- MMO, crafting infinito ou gacha;
- cópia de IPs de referência.

## Marcos de entrega sugeridos

1. **Beta** — Capítulo Zero (`BETA_DEMO_SCOPE.md`)
2. **Vertical slice visual** — uma área com arte final + um chefe
3. **Alpha de distrito** — múltiplas áreas interligadas
4. **Conteúdo completo** — cidade, barões, final

Detalhamento de produção em `CONTENT_PRODUCTION_PLAN.md`.
