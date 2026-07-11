# Red Hollow - Test Matrix

## Uso

Esta matriz define testes manuais e tecnicos para cada sistema quando ele existir. No estado inicial do projeto, muitos itens ainda ficam como nao aplicaveis. Cada nova tarefa deve atualizar ou executar os testes relacionados.

Legenda sugerida:

- Pass: comportamento correto.
- Fail: comportamento incorreto.
- Blocked: sistema ainda inexistente ou erro impede teste.
- N/A: nao aplicavel para a etapa atual.

## Matriz

| Area | Teste | Procedimento | Resultado esperado |
| --- | --- | --- | --- |
| Inicializacao | Abrir projeto | Abrir o projeto pela Godot 4.x indicada pelo projeto. | Projeto abre sem erros criticos. |
| Inicializacao | Main scene | Executar o projeto. | Main scene carrega quando existir; se nao existir, o estado deve ser documentado. |
| Inicializacao | Arquivos gerados | Verificar `git status --ignored`. | `.godot/` permanece ignorada. |
| Inicializacao | FPS base | Rodar uma sala simples no Windows. | Mantem alvo tecnico de 60 FPS em cenario basico. |
| Movimento | Direita/esquerda | Pressionar acoes de mover para os dois lados. | Calder move em um unico plano 2D lateral. |
| Movimento | Parada | Soltar direcional durante corrida. | Personagem desacelera ou para conforme design, sem deslize inesperado. |
| Movimento | Virada | Alternar direcao rapidamente. | Orientacao visual e hitboxes respeitam a direcao. |
| Movimento | Taxa de quadros | Testar com variacao de FPS quando possivel. | Movimento nao depende da taxa de quadros. |
| Colisao | Piso | Cair sobre plataforma. | Jogador pousa sem atravessar. |
| Colisao | Parede | Caminhar contra parede. | Jogador bloqueia corretamente, sem tremer de forma excessiva. |
| Colisao | Cantos | Pular perto de bordas/cantos. | Sem prender, teleportar ou atravessar colisao. |
| Colisao | Layers/masks | Revisar interacoes de jogador, inimigos e mundo. | Colisoes batem com a documentacao. |
| Pulo | Pulo do chao | Pressionar pulo no chao. | Jogador sobe e entra em estado de pulo. |
| Pulo | Queda | Sair de uma plataforma. | Jogador entra em queda e pousa corretamente. |
| Pulo | Bloqueio no ar | Tentar pular sem estar autorizado. | Nao gera pulo extra salvo se houver habilidade documentada. |
| Pulo | Responsividade | Testar pulo em sequencia. | Entrada responde sem atraso perceptivel indevido. |
| Camera | Seguimento | Mover pelo nivel. | Camera acompanha sem esconder o jogador. |
| Camera | Limites | Ir aos extremos da sala. | Camera respeita limites configurados. |
| Camera | Transicao | Trocar de area. | Camera ajusta limites/posicao sem corte incoerente. |
| Camera | Impacto | Acionar hitstop ou shake, quando existir. | Feedback nao prejudica leitura do combate. |
| Ataques | Ataque basico | Pressionar acao de ataque. | Ataque corpo a corpo inicia e termina. |
| Ataques | Startup | Observar inicio do ataque. | Dano nao ocorre antes da janela ativa. |
| Ataques | Recovery | Atacar e tentar cancelar. | Cancelamentos obedecem regras definidas. |
| Ataques | Direcao | Atacar para esquerda e direita. | Golpe respeita orientacao de Calder. |
| Hitboxes | Separacao | Inspecionar jogador/inimigo. | Hitbox e hurtbox sao elementos separados. |
| Hitboxes | Acerto unico | Manter hitbox sobre mesmo alvo durante uma ativacao. | Mesmo alvo nao recebe multiplos hits acidentais. |
| Hitboxes | Alvo invalido | Sobrepor hitbox a objeto nao atacavel. | Nenhum dano indevido ocorre. |
| Hitboxes | Hitstop | Acertar inimigo quando hitstop existir. | Pausa curta reforca impacto sem quebrar estado. |
| Inimigos | Spawn | Carregar sala com inimigo. | Inimigo aparece em posicao esperada. |
| Inimigos | Dano recebido | Acertar inimigo. | Vida reduz e feedback ocorre. |
| Inimigos | Morte | Reduzir vida a zero. | Inimigo morre/remove sem erros. |
| Inimigos | Ataque | Entrar no alcance do inimigo. | Ataque inimigo e legivel e justo. |
| Esquiva | Ativacao | Pressionar esquiva. | Calder entra em dodge. |
| Esquiva | Janela defensiva | Esquivar durante ataque inimigo. | Dano e evitado somente dentro da janela definida. |
| Esquiva | Recuperacao | Esquivar e tentar agir imediatamente. | Recovery respeita design. |
| Esquiva | Sem voo | Usar esquiva perto de bordas. | Esquiva nao vira voo ou movimento aereo ilimitado. |
| Counter | Timing correto | Acionar counter na janela correta. | Counter responde e pune ataque valido. |
| Counter | Timing errado | Acionar fora da janela. | Falha tem risco claro. |
| Counter | Alvos | Testar contra ataques diferentes. | Apenas ataques permitidos podem ser counterados. |
| Counter | Estilo | Counter bem sucedido. | Estilo aumenta conforme regra. |
| Estilo | Variedade | Alternar ataques e defesas. | Estilo sobe por variedade. |
| Estilo | Repeticao | Repetir a mesma acao segura. | Estilo nao escala indefinidamente. |
| Estilo | Dano recebido | Receber dano. | Estilo reduz, trava ou reage conforme regra. |
| Estilo | HUD | Alterar estilo. | HUD atualiza por sinal ou interface clara. |
| Red Brand | Recurso | Ganhar e gastar recurso. | Valor atualiza corretamente. |
| Red Brand | Golpe reforcado | Usar ataque da Red Brand. | Ataque fisico de curta distancia fica mais forte. |
| Red Brand | Restricoes | Tentar usar como magia/voo/projetil. | Sistema nao produz magia tradicional, voo ou projetil magico. |
| Red Brand | Feedback | Ativar recurso. | Feedback visual/sonoro e legivel com placeholder. |
| Dialogo | Trigger | Entrar em gatilho de dialogo. | Dialogo inicia uma vez ou conforme regra. |
| Dialogo | Avanco | Avancar linhas. | Texto progride e termina. |
| Dialogo | Controle | Finalizar dialogo. | Controle retorna ao jogador. |
| Dialogo | Dados invalidos | Chamar id inexistente. | Erro e tratado sem encerrar jogo. |
| Checkpoint | Ativacao | Tocar/interagir com checkpoint. | Checkpoint ativo e registrado. |
| Checkpoint | Retorno | Forcar respawn. | Calder retorna ao checkpoint ativo. |
| Checkpoint | Multiplos | Ativar outro checkpoint. | Novo checkpoint substitui anterior quando aplicavel. |
| Checkpoint | Feedback | Ativar checkpoint. | Jogador recebe confirmacao clara. |
| Salvamento | Criar save | Salvar progresso. | Arquivo e criado em `user://`. |
| Salvamento | Versao | Inspecionar dados salvos. | Save possui campo de versao. |
| Salvamento | Carregar | Reiniciar e carregar. | Estado essencial retorna corretamente. |
| Salvamento | Arquivo corrompido | Carregar arquivo invalido. | Jogo nao encerra; usa fallback seguro. |
| Troca de areas | Entrada | Entrar em passagem. | Nova area carrega. |
| Troca de areas | Posicao | Voltar pela passagem. | Jogador aparece em ponto coerente. |
| Troca de areas | Estado | Trocar area durante estado normal. | Vida, habilidades e progressao persistem. |
| Troca de areas | Camera/HUD | Trocar area. | Camera e HUD continuam consistentes. |

## Checklist por Tarefa

Depois de cada alteracao de jogo, registrar:

- arquivos criados e modificados;
- testes da matriz executados;
- erros encontrados;
- se a Godot foi executada pelo terminal;
- se collision layers e masks foram alteradas;
- se sinais e referencias foram verificados.