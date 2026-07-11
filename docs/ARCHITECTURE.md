# Red Hollow - Architecture

## Objetivo

Este documento propoe uma arquitetura inicial para Red Hollow como metroidvania de acao 2D em Godot 4.x, usando GDScript, cenas reutilizaveis, Resources configuraveis e acoplamento baixo por sinais. Ele descreve a direcao desejada, mas nao representa implementacao existente.

## Estrutura de Pastas Proposta

```text
scenes/
  main/
  levels/
  player/
  enemies/
  bosses/
  combat/
  ui/
scripts/
  player/
  enemies/
  combat/
  components/
  state_machines/
  ui/
  save/
  progression/
resources/
  attacks/
  enemies/
  player/
  dialogue/
  progression/
data/
  dialogue/
  localization/
ui/
audio/
art/
tests/
docs/
```

A estrutura deve crescer por necessidade real. Nao criar pastas vazias sem uma tarefa que va usa-las.

## Main Scene

A main scene deve ser o ponto de entrada do jogo. Responsabilidades recomendadas:

- carregar o nivel inicial;
- instanciar ou conter o jogador;
- conter CanvasLayer/HUD quando necessario;
- conectar sinais de alto nivel;
- manter inicializacao previsivel.

A main scene nao deve concentrar toda a logica do jogo.

## Cenas Reutilizaveis

Cenas devem ser pequenas e testaveis:

- Player: personagem jogavel com componentes filhos.
- EnemyBase: base de inimigos simples.
- Hitbox2D: Area2D para dano ativo.
- Hurtbox2D: Area2D para recebimento de dano.
- CameraRig2D: camera e limites por area.
- Checkpoint: ponto de retorno e salvamento.
- DialogueTrigger: gatilho de dialogo.
- HUD: interface desacoplada do jogador.

Cenas de area devem compor plataformas, portas, checkpoints, inimigos e triggers sem duplicar logica central.

## Jogador

O jogador deve usar CharacterBody2D. Movimento, combate e apresentacao visual devem ficar separados quando possivel.

Responsabilidades sugeridas:

- PlayerController: orquestra estado atual e componentes.
- PlayerMovement: calcula velocidade, pulo, queda, aceleracao e atrito.
- PlayerCombat: inicia ataques, counters, esquivas e Red Brand.
- PlayerStats: vida, recursos, estilo e estados de dano.
- PlayerVisuals: sprite, animacao provisoria e feedback visual.
- PlayerInput: traduz Input Map em intencoes do jogador.

O personagem deve continuar funcional com graficos provisorios e sem depender de sprites finais.

## Componentes

Componentes devem encapsular responsabilidades pequenas:

- HealthComponent: vida, dano, cura e morte.
- HitboxComponent: aplica dados de ataque a alvos validos.
- HurtboxComponent: recebe contato de hitboxes.
- KnockbackComponent: calcula impulso fisico.
- StyleComponent: registra variedade, risco e pontuacao de estilo.
- RedBrandComponent: controla recurso, ativacoes e efeitos fisicos.
- InteractionComponent: detecta interacoes.

Componentes devem se comunicar por sinais ou interfaces claras, evitando caminhos frageis com get_node espalhado.

## Maquinas de Estados

Usar maquinas de estados para jogador, inimigos e chefes.

Estados iniciais do jogador:

- idle;
- run;
- jump;
- fall;
- attack;
- dodge;
- counter;
- hurt;
- dead;
- interact.

Cada estado deve ter entrada, atualizacao, saida e regras claras de transicao. O objetivo e impedir condicionais gigantes dentro de um unico script.

## Hitbox e Hurtbox

Hitboxes e hurtboxes devem ser separadas.

Hitbox:

- deve ser Area2D ou componente equivalente;
- carrega dados do ataque ativo;
- respeita direcao do personagem;
- mantem lista de alvos ja atingidos durante a ativacao;
- emite sinal quando acerta.

Hurtbox:

- recebe hitboxes;
- valida alvo, invulnerabilidade e time/faccao;
- encaminha dano para HealthComponent;
- emite sinal de dano recebido.

## Dados de Ataques com Resource

Ataques devem ser orientados por dados usando Resource. Um AttackData pode conter:

- id;
- nome interno;
- dano;
- startup;
- active frames;
- recovery;
- hitstun;
- knockback;
- hitstop;
- ganho de estilo;
- custo ou ganho de Red Brand;
- tags, como punch, kick, grab, counter ou red_brand.

Se valores forem descritos em frames, a conversao para tempo deve ser consistente e documentada. Nao misturar frames e segundos sem criterio.

## Inimigos

Inimigos devem ser compostos por:

- CharacterBody2D quando precisarem de movimento fisico;
- maquina de estados;
- HealthComponent;
- HurtboxComponent;
- CombatComponent quando atacarem;
- EnemyData Resource para valores configuraveis.

Inimigos simples devem testar apenas uma ideia por vez: perseguir, atacar, bloquear, fugir, contra-atacar ou pressionar espaco.

## Chefes

Chefes devem usar a mesma base de componentes, com maquinas de estados ou fases dedicadas. Cada fase deve ser testavel isoladamente. Ataques de chefe podem ser simbolicos e religiosos, mas nao devem virar magia generica ou projeteis magicos.

## Camera

A camera deve ser 2D, previsivel e ajustavel por area.

Responsabilidades:

- seguir o jogador com suavidade controlada;
- respeitar limites de sala/area;
- suportar pequenos shakes de impacto;
- evitar esconder plataformas ou inimigos importantes;
- nao depender de arte final.

## HUD

A HUD deve usar Control e CanvasLayer quando apropriado. Ela nao deve ler detalhes internos do jogador diretamente. Preferir sinais ou um adaptador de estado.

Elementos possiveis:

- vida;
- recurso da Red Brand;
- indicador de estilo;
- prompts de interacao;
- texto curto de dialogo.

## Dialogos

Dialogos devem ser dirigidos por dados sempre que possivel.

Proposta:

- DialogueData Resource ou JSON validado;
- DialogueRunner para fluxo;
- DialogueBox como Control;
- triggers em cena que chamam dialogos por id.

Dialogos devem ser curtos no prototipo e nao bloquear testes de combate por muito tempo.

## Salvamento

Salvar em `user://`. O save deve possuir versao e validacao antes de carregar.

Nao salvar:

- referencias de Node;
- paths temporarios;
- IDs instaveis;
- objetos arbitrarios serializados sem validacao.

Salvar:

- versao do save;
- area atual;
- checkpoint ativo;
- habilidades desbloqueadas;
- flags de progressao;
- vida/recurso quando fizer sentido.

Arquivo corrompido nao deve encerrar o jogo.

## Checkpoints

Checkpoints devem ser entidades simples e reutilizaveis.

Responsabilidades:

- definir posicao de retorno;
- emitir sinal ao serem ativados;
- opcionalmente restaurar vida/recurso;
- informar o sistema de save/progressao.

Checkpoint nao deve conhecer detalhes internos de todos os sistemas.

## Gerenciamento de Progressao

Progressao deve controlar habilidades, portas, atalhos e flags narrativas. Usar um ProgressionManager apenas se houver necessidade global real.

Alternativas preferidas antes de Autoload:

- Resources de dados;
- sinais entre cena atual e controlador de nivel;
- componentes locais;
- grupos para consultas especificas.

## Depuracao

Ferramentas de depuracao devem ajudar o prototipo sem virar dependencia do jogo.

Possibilidades:

- overlay de estado do jogador;
- visualizacao de hitboxes/hurtboxes;
- log de transicoes de estado;
- reset rapido de sala;
- teleporte de teste controlado.

Recursos de debug devem poder ser desligados.

## Sinais

Sinais recomendados:

- health_changed(current, maximum);
- died();
- damage_received(amount, source);
- attack_started(attack_id);
- attack_hit(target, attack_id);
- style_changed(value, rank);
- red_brand_changed(current, maximum);
- checkpoint_activated(checkpoint_id);
- ability_unlocked(ability_id);
- dialogue_started(dialogue_id);
- dialogue_finished(dialogue_id);
- area_changed(area_id).

Usar nomes em snake_case e payloads pequenos.

## Autoloads Estritamente Necessarios

Autoloads devem ser raros. Candidatos aceitaveis somente quando a necessidade aparecer:

- SaveManager: se save precisar persistir entre trocas de cena.
- ProgressionManager: se habilidades e flags globais forem usadas por varias areas.
- AudioManager: se musica e mixagem precisarem sobreviver a troca de cenas.
- SceneLoader: se houver transicoes consistentes entre areas.

Nao criar um Autoload que concentre todo o jogo. Se um sistema pode viver na main scene ou em componentes locais, preferir essa opcao no inicio.