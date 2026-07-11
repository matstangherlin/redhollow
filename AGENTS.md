# Red Hollow — instruções do projeto

## Engine e linguagem

- O projeto usa **Godot 4.7** (ver `config/features` em `project.godot`).
- A linguagem principal é GDScript.
- Não use C#.
- O jogo é um metroidvania de ação 2D em visão lateral.
- O jogador se move em um único plano 2D.
- O desempenho alvo é 60 FPS no Windows.
- Antes de usar APIs específicas, verifique a versão atual da Godot indicada pelo projeto.

## Identidade do jogo

- O jogo se chama **Red Hollow**.
- O protagonista é **Calder Knox**.
- A ambientação mistura faroeste decadente, anime na construção de personagens, ação estilizada, humor durante o combate e terror religioso.
- A arte final será **pixel art detalhada** com iluminação dramática (ver `docs/ART_BIBLE.md`).
- A **Red Brand** amplifica capacidades físicas e liga Calder a Mol-Khar; não é magia elemental genérica.
- A **Vermilite** é energia cristalizada ligada ao culto e à mineração; use-a com moderação visual (ver `docs/ART_BIBLE.md`).
- Não implemente magia tradicional, bolas de fogo, voo ou poderes genéricos de fantasia.
- O combate deve parecer físico, agressivo e responsivo.

## Documentação oficial

Consulte antes de implementar conteúdo, arte ou narrativa:

| Documento | Uso |
| --- | --- |
| `docs/GDD_RED_HOLLOW.md` | Visão de jogo e pilares |
| `docs/NARRATIVE_BIBLE.md` | Cânone narrativo |
| `docs/ART_BIBLE.md` | Direção visual e pixel art |
| `docs/UI_BIBLE.md` | Interface e HUD |
| `docs/ARCHITECTURE.md` | Arquitetura real e alvo |
| `docs/ROADMAP.md` | Fases concluídas e próximas |
| `docs/BETA_DEMO_SCOPE.md` | Escopo da beta pública |
| `docs/FINAL_GAME_SCOPE.md` | Escopo do jogo completo |
| `docs/TECH_DEBT.md` | Dívida técnica conhecida |
| `docs/CONTENT_PRODUCTION_PLAN.md` | Ordem de produção de conteúdo |
| `docs/VISUAL_REFERENCE_RULES.md` | Uso de moodboards e referências |
| `docs/TEST_MATRIX.md` | Testes manuais e headless |
| `docs/VERTICAL_SLICE_TEST_PLAN.md` | Roteiro da demonstração técnica atual |

## Estado atual do repositório

O projeto **não está vazio**. Existe uma demonstração técnica jogável (greybox) com sistemas reais.

**Main scene:** `res://scenes/demo/vertical_slice_greybox.tscn`

**Implementado e testado manualmente:**

- movimento, pulo, combo, esquiva, counter, provocação;
- hitbox/hurtbox e ataques orientados por Resource;
- estilo, Red Brand, barreira destrutível;
- diálogo, checkpoint, save/load manual;
- transição de áreas (rua → igreja → subterrâneo);
- arena, mini-chefe Deacon Rusk, overlay de conclusão.

**Implementado com dívida técnica** (ver `docs/TECH_DEBT.md`):

- `player.gd` monolítico;
- locks de input e recuperação global (`panic unlock`, `Engine.time_scale`);
- acoplamento por grupos e chamadas dinâmicas;
- auto-load de save **desativado** na vertical slice (`auto_load_on_ready = false`).

**Salvamento na demo atual:**

- **F8** salva; **F9** carrega manualmente.
- Não há auto-load ao iniciar a vertical slice greybox.

## Regras de edição

- Analise o projeto antes de alterar qualquer arquivo.
- Implemente somente uma funcionalidade por tarefa.
- Não realize refatorações gerais sem autorização.
- Não renomeie cenas, nós, scripts, recursos ou ações de entrada existentes sem autorização.
- Não apague código funcional para substituí-lo por placeholders.
- Não modifique arquivos não relacionados à tarefa.
- Não reestruture toda a árvore de cenas sem explicar antes.
- Não altere `project.godot` sem necessidade.
- Sempre explique alterações realizadas em `project.godot`.
- Não edite arquivos dentro da pasta `.godot`.
- Não edite arquivos `.import` manualmente.
- Não use assets externos sem autorização e sem verificar licença.
- Durante a fase greybox, formas geométricas provisórias permanecem aceitáveis até a arte final da beta substituí-las.

## Arquitetura

- Use tipagem estática em GDScript sempre que isso melhorar segurança e clareza.
- Use nomes claros em inglês para código, cenas, nós e recursos.
- Use snake_case para variáveis e funções.
- Use PascalCase para classes com `class_name`.
- Evite scripts gigantes; a refatoração do jogador é prioridade documentada em `docs/TECH_DEBT.md`.
- Separe entrada, movimento, combate, interface, salvamento e narrativa quando possível.
- Use composição quando ela for mais apropriada que herança.
- Use máquinas de estados para jogador, inimigos e chefes.
- Use Resources para dados configuráveis.
- Use sinais para reduzir acoplamento entre sistemas.
- Não use `get_node` com caminhos frágeis espalhados pelo projeto.
- Use referências exportadas, grupos, sinais ou componentes quando apropriado.
- Autoloads devem ser raros; a vertical slice atual usa shell persistente na main scene, sem autoloads de gameplay.

## Estrutura recomendada

- `scenes/`
- `scripts/`
- `resources/`
- `data/`
- `ui/`
- `audio/`
- `art/`
- `tests/`
- `docs/`

## Jogador

- O jogador deve usar `CharacterBody2D`.
- Movimento, combate e apresentação visual devem permanecer separados quando possível.
- Estados atuais no código: idle, run, jump, fall, attack, dodge, counter, taunt, hurt, dead, interact.
- A lógica de movimento não deve depender de sprites definitivos.
- O personagem deve continuar funcional com gráficos provisórios até a integração da pixel art.

## Combate

- Hitboxes e hurtboxes devem ser separadas.
- Ataques devem ser orientados por dados (`AttackData` Resource).
- Cada ataque deve poder definir dano, startup, active, recovery, hitstun, knockback, hitstop e ganho de estilo.
- Uma hitbox não deve atingir o mesmo alvo várias vezes acidentalmente.
- Ataques devem respeitar a direção do personagem.
- O combate deve suportar socos, chutes, esquivas, counters, provocações e ataques da Red Brand.
- Manifestações sobrenaturais só quando ligadas a Mol-Khar, Vermilite, pactos, alteração física, dor ou plano espiritual — nunca magia elemental genérica.

## Física

- Use `_physics_process` para lógica física.
- Evite comportamento dependente da taxa de quadros.
- Valores de ataque usam **segundos** no código atual; não misturar frames e segundos sem documentar.
- Colisões devem ser previsíveis.
- Não altere collision layers e masks sem documentar.

## Interface

- Interface deve usar `Control` e `CanvasLayer` quando apropriado.
- HUD não deve depender diretamente de detalhes internos do jogador.
- Direção visual da UI: `docs/UI_BIBLE.md`.

## Salvamento

- Use `user://` para arquivos de salvamento.
- O save deve possuir versão (`SaveData.CURRENT_SAVE_VERSION`).
- Não salve referências de nós ou IDs temporários.
- Valide dados antes de carregar.
- Arquivo corrompido não deve encerrar o jogo.

## Verificação

Depois de cada alteração:

- procure erros de sintaxe;
- procure referências quebradas;
- verifique a árvore de cenas;
- verifique sinais conectados;
- verifique collision layers e masks;
- execute testes headless quando possível (comandos portáveis em `docs/TEST_MATRIX.md`);
- informe erros encontrados;
- liste todos os arquivos criados e modificados;
- liste testes manuais na Godot;
- não considere a tarefa concluída sem apresentar os testes.

## Git

- Verifique git status antes de alterações maiores.
- Não faça commit automaticamente, salvo quando solicitado.
- Não descarte alterações existentes do usuário.
- Não use comandos destrutivos como `git reset --hard` sem autorização explícita.
