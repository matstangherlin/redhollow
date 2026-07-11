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
- O combate deve parecer físico, agressivo e responsivo.

### Regra sobrenatural (precisa)

- Calder **não** utiliza magia tradicional.
- **Não existe** sistema genérico de magia elemental.
- A Red Brand é **predominantemente física** e de curta distância.
- Manifestações sobrenaturais são **permitidas** quando ligadas diretamente a:
  - Mol-Khar;
  - Vermilite;
  - pactos;
  - transformação corporal;
  - alma;
  - plano espiritual;
  - **Ressonância Rubra**.

**Não utilizar** poderes genéricos sem relação com o universo:

- bolas de fogo comuns;
- gelo elemental;
- magia arcana genérica;
- voo sem justificativa;
- raios mágicos sem conexão narrativa.

## Documentação oficial

Consulte antes de implementar conteúdo, arte ou narrativa:

| Documento | Uso |
| --- | --- |
| `docs/GDD_RED_HOLLOW.md` | Visão de jogo e pilares |
| `docs/NARRATIVE_BIBLE.md` | Cânone narrativo |
| `docs/ART_BIBLE.md` | Direção visual e pixel art |
| `docs/UI_BIBLE.md` | Interface e HUD |
| `docs/ARCHITECTURE.md` | Arquitetura real e alvo |
| `docs/CURRENT_IMPLEMENTATION.md` | Inventário do que existe hoje |
| `docs/DECISIONS.md` | Decisões de produto e arquitetura |
| `docs/ROADMAP.md` | Fases concluídas e próximas |
| `docs/BETA_DEMO_SCOPE.md` | Escopo da beta pública |
| `docs/FINAL_GAME_SCOPE.md` | Escopo do jogo completo |
| `docs/TECH_DEBT.md` | Dívida técnica conhecida |
| `docs/CONTENT_PRODUCTION_PLAN.md` | Ordem de produção de conteúdo |
| `docs/VISUAL_REFERENCE_RULES.md` | Uso de moodboards e referências |
| `docs/TEST_MATRIX.md` | Testes manuais e headless |
| `docs/VERTICAL_SLICE_TEST_PLAN.md` | Roteiro da demonstração técnica |
| `docs/HEADLESS_TESTING.md` | Runner e critérios de suítes |

## Estado atual do repositório

O projeto **não está vazio**. Existe uma demonstração técnica jogável (greybox) com sistemas reais.

**Baseline protegida:** tag `greybox-vertical-slice-v0.1` (`ae65a5084c1cbece80672a67d4bc0a6b4d40e5df`).  
**Branch de trabalho:** `beta-foundation`.

**Main scene:** `res://scenes/demo/vertical_slice_greybox.tscn`

**Implementado e razoavelmente funcional** (detalhe em `CURRENT_IMPLEMENTATION.md`):

- movimento lateral, pulo, combo, esquiva, counter, provocação;
- hitbox/hurtbox e ataques orientados por Resource;
- estilo, Red Brand, barreira destrutível;
- diálogo, interação, checkpoint;
- save/load **manual** (F8/F9);
- três áreas e transição (rua → igreja → subterrâneo);
- arena, Cult Brawler, mini-chefe Deacon Rusk;
- HUD estilo, HUD chefe, overlay de conclusão;
- `GameplayLockManager`, testes headless (`test_runner.gd`).

**Implementado com dívida técnica** (ver `docs/TECH_DEBT.md`):

- `player.gd` monolítico (~1700 linhas no baseline);
- acoplamento por grupos e chamadas dinâmicas;
- SaveManager captura vida/Red Brand via paths internos (baseline);
- panic unlock (Esc) como escape hatch;
- auto-load de save **desativado** na vertical slice (`auto_load_on_ready = false`);
- fluxo morte/respawn não consolidado.

**Planejado para beta** (`BETA_DEMO_SCOPE.md`): arte final Capítulo Zero, catacumbas, três inimigos visuais, set pieces Mol-Khar/Arcturus, UI mapa/diário/pausa.

**Planejado para jogo final** (`FINAL_GAME_SCOPE.md`): barões, Palácio Rubro, Mol-Khar completo, finais.

### Salvamento na demo atual

- **F8** salva; **F9** carrega manualmente.
- **Não há auto-load** ao iniciar a vertical slice greybox.
- Checkpoint no subterrâneo grava save ao ativar.

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
- Evite scripts gigantes; refatoração do jogador documentada em `TECH_DEBT.md`.
- Separe entrada, movimento, combate, interface, salvamento e narrativa quando possível.
- Use composição quando ela for mais apropriada que herança.
- Use máquinas de estados para jogador, inimigos e chefes.
- Use Resources para dados configuráveis.
- Use sinais para reduzir acoplamento entre sistemas.
- Não use `get_node` com caminhos frágeis espalhados pelo projeto.
- Use referências exportadas, grupos, sinais ou componentes quando apropriado.
- Autoloads devem ser raros; a vertical slice usa shell persistente na main scene.

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
- Estados atuais: idle, run, jump, fall, attack, dodge, counter, taunt, hurt, dead, interact.
- A lógica de movimento não deve depender de sprites definitivos.
- Escala de facing aplica-se a `%Visual`, não ao `CharacterBody2D` inteiro.

## Combate

- Hitboxes e hurtboxes separadas.
- Ataques orientados por `AttackData` Resource.
- Timing em **segundos** no código atual.
- Combate: socos, chutes, esquivas, counters, provocações, Red Brand Breaker.
- Manifestações sobrenaturais conforme regra sobrenatural acima.

## Física

- Use `_physics_process` para lógica física.
- Evite comportamento dependente da taxa de quadros.
- Colisões previsíveis; documente mudanças em layers/masks.

## Interface

- Interface com `Control` e `CanvasLayer` quando apropriado.
- HUD não deve depender de detalhes internos do jogador.
- Direção visual: `docs/UI_BIBLE.md`.

## Salvamento

- Use `user://` para arquivos de salvamento.
- Save com versão (`SaveData.CURRENT_SAVE_VERSION`).
- Não salve referências de nós ou IDs temporários.
- Valide dados antes de carregar.
- Arquivo corrompido não deve encerrar o jogo.

## Verificação

Depois de cada alteração:

- procure erros de sintaxe e referências quebradas;
- verifique árvore de cenas, sinais, collision layers/masks;
- execute testes headless quando possível:

```bash
godot --headless --path . --script res://scripts/tests/test_runner.gd
```

- informe erros encontrados;
- liste arquivos criados/modificados e testes manuais.

## Git

- Verifique git status antes de alterações maiores.
- Não faça commit automaticamente, salvo quando solicitado.
- Não descarte alterações existentes do usuário.
- Não use comandos destrutivos como `git reset --hard` sem autorização explícita.
- Tag de restauração greybox: `greybox-vertical-slice-v0.1`.
