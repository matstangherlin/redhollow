# Red Hollow - Roadmap

## Principios do Roadmap

- Uma funcionalidade por etapa.
- Cada fase deve terminar com teste manual claro.
- Graficos provisorios durante o prototipo.
- Manter o jogo inteiramente 2D, em visao lateral e em um unico plano.
- Nao implementar magia tradicional, projeteis magicos ou voo.
- Priorizar 60 FPS no Windows desde o inicio.

## Fase 0 - Base do Projeto

Objetivo: preparar o projeto para evoluir com seguranca.

Entregas:

- documentacao inicial;
- controle de versao;
- estrutura minima de pastas quando necessaria;
- convencoes de nomes;
- matriz de testes inicial.

Criterios de conclusao:

- repositório limpo;
- documentacao versionada;
- nenhum arquivo gerado da Godot versionado por engano.

## Fase 1 - Main Scene e Sala de Teste

Objetivo: ter uma cena inicial executavel e previsivel.

Entregas:

- main scene simples;
- sala de teste 2D com colisao provisoria;
- camera inicial;
- jogador instanciado com placeholder geometrico;
- configuracao de main scene em project.godot, se necessario.

Testes:

- projeto abre pela main scene;
- jogador aparece;
- sala carrega sem erros;
- camera mostra a area correta.

## Fase 2 - Movimento Base

Objetivo: validar movimento lateral em um unico plano.

Entregas:

- CharacterBody2D para o jogador;
- andar, parar e virar;
- aceleracao/atrito basicos;
- queda e gravidade;
- valores expostos para ajuste.

Testes:

- mover esquerda/direita;
- parar sem deslize excessivo;
- virar direcao corretamente;
- manter 60 FPS em sala simples.

## Fase 3 - Pulo e Colisao

Objetivo: tornar a movimentacao confiavel em plataformas simples.

Entregas:

- pulo;
- queda;
- colisao com piso e parede;
- limites da sala;
- pequenos ajustes de responsividade, se necessarios.

Testes:

- pular do chao;
- cair de plataforma;
- colidir com paredes;
- nao atravessar piso;
- comportamento independente da taxa de quadros.

## Fase 4 - Estado do Jogador

Objetivo: separar comportamento por estados claros.

Entregas:

- maquina de estados inicial;
- idle, run, jump e fall;
- transicoes observaveis em debug simples;
- isolamento entre entrada e movimento.

Testes:

- transicoes corretas entre estados;
- nenhum estado preso;
- movimento continua funcional.

## Fase 5 - Ataque Corpo a Corpo Basico

Objetivo: provar o primeiro ataque fisico.

Entregas:

- estado attack;
- hitbox separada;
- dados simples de ataque;
- startup, active e recovery documentados;
- feedback visual provisório.

Testes:

- ataque dispara;
- hitbox ativa no momento correto;
- movimento respeita estado de ataque;
- nao ha dano multiplo acidental no mesmo alvo.

## Fase 6 - Inimigo Simples

Objetivo: validar alvo de combate.

Entregas:

- inimigo placeholder;
- hurtbox separada;
- vida simples;
- reacao a dano;
- morte/remocao controlada.

Testes:

- inimigo recebe dano;
- inimigo nao quebra quando atacado repetidas vezes;
- hitbox do jogador acerta somente quando sobrepoe.

## Fase 7 - Esquiva e Counter

Objetivo: adicionar defesa tecnica sem ampliar escopo demais.

Entregas:

- estado dodge;
- estado counter;
- janelas claras;
- invulnerabilidade ou reducao de dano documentada;
- resposta de estilo para counter bem sucedido.

Testes:

- esquiva evita dano dentro da janela;
- counter exige timing;
- falha de counter tem custo ou risco;
- combate continua corpo a corpo.

## Fase 8 - Estilo e Provocacoes

Objetivo: tornar o combate expressivo.

Entregas:

- StyleComponent inicial;
- ganho por variedade e risco;
- provocacao simples;
- indicador visual minimo.

Testes:

- estilo sobe com acertos variados;
- estilo nao sobe infinitamente com repeticao trivial;
- provocacao funciona em condicao definida.

## Fase 9 - Red Brand Inicial

Objetivo: validar o poder fisico central sem magia.

Entregas:

- recurso da Red Brand;
- um ataque reforcado de curta distancia;
- custo/ganho de recurso;
- feedback visual provisorio.

Testes:

- Red Brand amplifica golpe fisico;
- nao cria projeteis magicos;
- nao permite voo;
- recurso atualiza corretamente.

## Fase 10 - Exploracao e Backtracking

Objetivo: provar metroidvania em escala pequena.

Entregas:

- duas ou tres salas conectadas;
- atalho;
- bloqueio por habilidade;
- retorno a area anterior com nova possibilidade.

Testes:

- transicao entre areas;
- camera ajusta limites;
- backtracking abre caminho novo;
- progresso nao depende de ordem quebrada.

## Fase 11 - Dialogo e Checkpoint

Objetivo: introduzir fluxo narrativo minimo e retorno seguro.

Entregas:

- caixa de dialogo simples;
- trigger de dialogo;
- checkpoint ativavel;
- retorno do jogador ao checkpoint em teste.

Testes:

- dialogo inicia e termina;
- checkpoint registra posicao;
- jogador retorna corretamente;
- dialogo nao bloqueia input permanentemente.

## Fase 12 - Salvamento Basico

Objetivo: persistir progresso minimo em `user://`.

Entregas:

- formato de save com versao;
- checkpoint ativo;
- habilidades liberadas;
- validacao de dados ao carregar.

Testes:

- salvar;
- carregar;
- lidar com arquivo ausente;
- lidar com arquivo corrompido sem encerrar o jogo.

## Fase 13 - Vertical Slice

Objetivo: consolidar uma fatia pequena e jogavel.

Entregas:

- trecho curto de exploracao;
- combate contra inimigo simples;
- uma habilidade de progressao;
- uma cena de dialogo curta;
- checkpoint e save basico;
- HUD minimo.

Testes:

- jogar do inicio ao fim sem usar editor;
- medir FPS em Windows;
- listar bugs restantes;
- definir proxima prioridade.