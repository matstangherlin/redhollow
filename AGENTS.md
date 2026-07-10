# Red Hollow — instruções do projeto

## Engine e linguagem

- O projeto usa Godot 4.x.
- A linguagem principal é GDScript.
- Não use C#.
- O jogo é um metroidvania de ação 2D em visão lateral.
- O jogador se move em um único plano 2D.
- O desempenho alvo é 60 FPS no Windows.
- Antes de usar APIs específicas, verifique a versão atual da Godot indicada pelo projeto.

## Identidade do jogo

- O jogo se chama Red Hollow.
- O protagonista é Calder Knox.
- A ambientação mistura faroeste alternativo, anime, ação estilizada, humor durante o combate e terror religioso.
- A Red Brand amplifica capacidades físicas.
- Não implemente magia tradicional.
- Não implemente bolas de fogo, voo ou poderes genéricos de fantasia.
- O combate deve parecer físico, agressivo e responsivo.

## Regras de edição

- Analise o projeto antes de alterar qualquer arquivo.
- Implemente somente uma funcionalidade por tarefa.
- Não realize refatorações gerais sem autorização.
- Não renomeie cenas, nós, scripts, recursos ou ações de entrada existentes sem autorização.
- Não apague código funcional para substituí-lo por placeholders.
- Não modifique arquivos não relacionados à tarefa.
- Não reestruture toda a árvore de cenas sem explicar antes.
- Não altere project.godot sem necessidade.
- Sempre explique alterações realizadas em project.godot.
- Não edite arquivos dentro da pasta .godot.
- Não edite arquivos .import manualmente.
- Não use assets externos sem autorização e sem verificar licença.
- Use formas geométricas e gráficos provisórios durante o protótipo.

## Arquitetura

- Use tipagem estática em GDScript sempre que isso melhorar segurança e clareza.
- Use nomes claros em inglês para código, cenas, nós e recursos.
- Use snake_case para variáveis e funções.
- Use PascalCase para classes com class_name.
- Evite scripts gigantes.
- Separe entrada, movimento, combate, interface, salvamento e narrativa.
- Use composição quando ela for mais apropriada que herança.
- Use máquinas de estados para jogador, inimigos e chefes.
- Use Resources para dados configuráveis.
- Use sinais para reduzir acoplamento entre sistemas.
- Não use get_node com caminhos frágeis espalhados pelo projeto.
- Use referências exportadas, grupos, sinais ou componentes quando apropriado.
- Não espalhe variáveis globais pelo projeto.
- Autoloads devem ser usados apenas para sistemas realmente globais.
- Um Autoload não deve concentrar todo o jogo em um único script.

## Estrutura recomendada

- scenes/
- scripts/
- resources/
- data/
- ui/
- audio/
- art/
- tests/
- docs/

## Jogador

- O jogador deve usar CharacterBody2D.
- Movimento, combate e apresentação visual devem permanecer separados quando possível.
- O jogador deve possuir estados claros.
- Estados futuros incluem idle, run, jump, fall, attack, dodge, counter, hurt, dead e interact.
- A lógica de movimento não deve depender de sprites definitivos.
- O personagem deve continuar funcional com gráficos provisórios.

## Combate

- Hitboxes e hurtboxes devem ser separadas.
- Use Area2D ou componentes equivalentes apropriados.
- Ataques devem ser orientados por dados.
- Cada ataque deve poder definir dano, startup, active frames, recovery, hitstun, knockback, hitstop e ganho de estilo.
- Uma hitbox não deve atingir o mesmo alvo várias vezes acidentalmente.
- Ataques devem respeitar a direção do personagem.
- O combate deve suportar socos, chutes, agarrões, esquivas, counters, provocações e ataques da Red Brand.
- O sistema deve permitir expansão sem reescrever todo o jogador.

## Física

- Use _physics_process para lógica física.
- Evite comportamento dependente da taxa de quadros.
- Quando valores forem apresentados em frames, converta-os de forma consistente para tempo ou use um sistema claramente documentado.
- Não misture diretamente frames e segundos sem explicar.
- Colisões devem ser previsíveis.
- Não altere collision layers e masks sem documentar.

## Interface

- Interface deve usar Control e CanvasLayer quando apropriado.
- HUD não deve depender diretamente de detalhes internos do jogador.
- Use sinais ou interfaces claras para atualização de vida, estilo e Red Brand.

## Salvamento

- Use user:// para arquivos de salvamento.
- O save deve possuir versão.
- Não salve referências de nós ou IDs temporários.
- Valide dados antes de carregar.
- Arquivo corrompido não deve encerrar o jogo.
- Não implemente serialização insegura de objetos arbitrários.

## Verificação

Depois de cada alteração:

- procure erros de sintaxe;
- procure referências quebradas;
- verifique a árvore de cenas;
- verifique sinais conectados;
- verifique collision layers e masks;
- execute a Godot pelo terminal quando possível;
- informe erros encontrados;
- liste todos os arquivos criados e modificados;
- liste testes manuais na Godot;
- não considere a tarefa concluída sem apresentar os testes.

## Git

- Verifique git status antes de alterações maiores.
- Não faça commit automaticamente, salvo quando solicitado.
- Não descarte alterações existentes do usuário.
- Não use comandos destrutivos como git reset --hard sem autorização explícita.