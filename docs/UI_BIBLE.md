# Red Hollow — UI Bible

Direção de interface para HUD, menus e fluxos de informação. A UI deve ser **original** e legível — não copiar layouts de moodboards.

## Materiais e tom

A interface deve parecer construída com:

- madeira escura;
- ferro enferrujado ou rebites;
- couro gasto;
- pergaminho e papel ritual;
- gravuras religiosas distorcidas;
- marcas de Vermilite em detalhes pontuais (não em tudo).

Tom: funcional no combate, sombrio fora dele, sem poluição visual no centro da ação.

## Hierarquia de leitura

1. Vida e ameaça imediata
2. Red Brand (recurso de poder)
3. Estilo / rank de combate
4. Objetivos e prompts contextuais
5. Mapa, diário e menus secundários

## Elementos principais

### HUD de combate (beta)

| Elemento | Função | Estado atual |
| --- | --- | --- |
| Vida | HP de Calder | Parcial — via componentes; HUD final planejado |
| Red Brand | Energia / carga | Implementado (barra provisória) |
| Estilo | Rank e pontuação | Implementado (`StyleHud`) |
| Boss | Nome + vida do chefe | Implementado (`BossHealthHud`) |
| Prompts | Interação, arena | Texto em labels / hints |
| Mapa simples | Área atual e marcos | Planejado para beta |
| Objetivos | Marco atual do capítulo | Planejado para beta |
| Diário curto | Entradas desbloqueadas | Planejado para beta |

### Menus

- **Pausa:** continuar, opções básicas, sair.
- **Red Brand:** tela dedicada com no máximo **três** habilidades na beta.
- **Mapa:** visão simplificada das áreas do Capítulo Zero.
- **Diário:** textos curtos ligados a flags narrativas.

## Diálogo

- Caixa com retrato (quando houver arte), nome do falante e corpo do texto.
- Avanço com **E**; não bloquear input após fechar.
- Estilo visual: pergaminho escuro ou painel de madeira com borda metálica.

Estado atual: `DialogueBox` com typewriter, escala de legenda e tema de apresentação provisório.

## Feedback de combate

- Números de estilo e mensagens de arena/chefe em labels temporários.
- Na beta: tipografia legível, duração curta, posição fixa fora da zona de perigo.

## Acessibilidade e legibilidade

- Contraste alto entre texto e fundo.
- Ícones com silhueta clara mesmo em 1080p e 720p.
- Vermilite em ícones de perigo/poder, não em todo o painel.
- Evitar texto sobre ação central; respeitar safe area da câmera.

## O que não fazer

- Copiar HUD, fontes ou layouts de referências externas.
- Cobrir o personagem com painéis grandes.
- Usar vermelho como cor dominante de toda a UI.
- Misturar estilo “sci-fi UI” ou fantasia medieval genérica.

## Referências cruzadas

- Paleta: `ART_BIBLE.md`
- Escopo de telas na beta: `BETA_DEMO_SCOPE.md`
- Moodboards: `VISUAL_REFERENCE_RULES.md`
