# Red Hollow — Vertical Slice Test Plan

Demonstração técnica jogável: `vertical_slice_greybox.tscn`  
Duração estimada: **10–20 minutos** (primeiro jogador).

## Controles da demonstração

| Tecla | Ação |
| --- | --- |
| A / D | Mover |
| Espaço | Pular |
| J | Ataque / combo |
| K | Esquiva |
| L | Counter |
| T | Provocação |
| U (segurar/soltar) | Red Brand Breaker carregado |
| E | Interagir / avançar diálogo |
| R | Reiniciar posição na área (spawn/checkpoint) |
| F7 | Voltar ao início da demonstração |
| F8 | Salvar |
| F9 | Carregar |

## Roteiro completo (início ao fim)

### 1. Rua inicial
1. Inicie o projeto (`vertical_slice_greybox` é a main scene).
2. Confirme spawn em posição inicial (x≈120).
3. Verifique HUD de estilo (canto superior) e barra Red Brand sem cobrir o centro da ação.
4. Caminhe pela rua e leia o rótulo de área.

**Esperado:** movimento fluido, câmera segue Calder, limites da área respeitados.

### 2. Elias e diálogo
1. Aproxime-se de Elias (cor azul-acinzentada).
2. Pressione **E** para iniciar diálogo.
3. Avance todas as linhas com **E**.
4. Ao terminar, tente mover/atacar imediatamente.

**Esperado:** diálogo sobre igreja/cultistas; controles liberados após o fim.

### 3. Seção de plataforma
1. Avance até plataformas cinza elevadas.
2. Pule entre PlatformA → B → C → retorno ao chão.
3. Se cair, confirme recuperação por queda (teleporte ao spawn) sem softlock.

**Esperado:** plataformas alcançáveis; sem ficar preso permanentemente.

### 4. Cult Brawler (rua)
1. Enfrente o Cult Brawler após as plataformas.
2. Teste combo (J), esquiva (K) e counter (L) em ataque telegrafado.
3. Derrote o inimigo e observe ganho de estilo.

**Esperado:** hitbox/hurtbox corretos; morte do inimigo; estilo sobe.

### 5. Transição para igreja
1. Siga até a saída **→ Igreja** (extremo direito).
2. Confirme spawn coerente na igreja (`from_street`).

**Esperado:** transição de área sem perder player/câmera/HUD.

### 6. Arena (dois Cult Brawlers)
1. Entre na zona de ativação da arena (~x=720).
2. Confirme mensagem **Combate iniciado** e portas fechadas.
3. Tente sair pela esquerda/direita durante combate — deve bloquear.
4. Derrote os dois inimigos.
5. Confirme **Arena concluída**, portas abertas e bônus de estilo.

**Esperado:** arena não reativa após conclusão.

### 7. Red Brand para golpe carregado
1. Interaja com o cristal vermelho (**Absorver Coração Rubro**) após arena.
2. Confirme energia ≥ 30 (mínimo para carregar Breaker).
3. Segure **U** e solte para Red Brand Breaker.

**Esperado:** cristal só disponível após arena; energia suficiente para teste.

### 8. Barreira vermelha
1. Aproxime-se da barreira rubra antes do subterrâneo.
2. Use Red Brand Breaker para destruir.
3. Atravesse a passagem liberada.

**Esperado:** barreira some; saída para subterrâneo acessível.

### 9. Área subterrânea
1. Entre em **→ Subterrâneo**.
2. Confirme ambiente mais escuro e câmera com novos limites.

**Esperado:** transição correta; atmosfera distinta.

### 10. Checkpoint
1. Ative checkpoint verde com **E**.
2. Visual muda para estado ativo (amarelo).
3. Pressione **F8** para salvar.

**Esperado:** checkpoint registrado; feedback visual.

### 11. Mini-chefe Deacon Rusk
1. Avance até zona do chefe (~x=520).
2. Confirme HUD do chefe (nome + barra de vida).
3. Observe telegraphs (amarelo = counterable, vermelho = não counterable).
4. Teste fase 2 abaixo de 50% HP.
5. Derrote Deacon Rusk.

**Esperado:** `boss_defeated`; saída desbloqueada; overlay de conclusão.

### 12. Mensagem final
1. Leia overlay **Demonstração Técnica Concluída**.
2. Pressione **F7** para voltar ao início.

**Esperado:** mensagem clara; reinício limpo na rua.

## Testes de persistência

1. Após destruir barreira e ativar checkpoint, salve (**F8**).
2. Feche e reabra o jogo.
3. Carregue (**F9**) ou aguarde auto-load.

**Esperado:**
- Área e posição restauradas.
- Barreira permanece destruída.
- Checkpoint visual ativo.
- Arena/chefe concluídos não reativam indevidamente.

## Testes de recuperação

| Cenário | Procedimento | Esperado |
| --- | --- | --- |
| Reinício de área | **R** após tomar dano | Volta ao spawn/checkpoint |
| Voltar ao início | **F7** | Rua inicial, progresso resetado |
| Queda | Cair do mapa | Recuperação automática |
| Diálogo | Terminar conversa | Controles liberados |

## Verificação automatizada (headless)

```powershell
& "C:\Users\Stan\Documents\Godot_v4.7-stable_win64.exe" --headless --path "C:\Users\Stan\Documents\red-hollow" --script res://scripts/demo/vertical_slice_verification.gd
```

Execute também os testes de sistema existentes (diálogo, save, áreas, arena, Deacon Rusk) antes de release da demo.

## Critérios de aceite

- [ ] Fluxo completo jogável em 10–20 min.
- [ ] Todos os sistemas obrigatórios exercitados pelo menos uma vez.
- [ ] Nenhum softlock conhecido.
- [ ] Save/checkpoint/barreira/chefe consistentes após reload.
- [ ] HUD e diálogo não bloqueiam gameplay indevidamente.
